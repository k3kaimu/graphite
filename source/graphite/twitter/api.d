module graphite.twitter.api;

import graphite.twitter;

import graphite.utils.channel;

import std.algorithm;
import std.array;
import std.base64;
import std.concurrency;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.exception;
import std.file;
import std.format;
import std.path;
import std.range;
import std.string;
import std.traits;
import std.typecons;
import std.uri;
import std.net.curl;


auto asRange(V, K)(V[K] aa)
if(is(V : K))
{
    return aa.byKey.zip(aa.repeat).map!"cast(typeof(a[0])[2])[a[0], a[1][a[0]]]"();
}


template nupler(alias fn, size_t N)
if(N >= 1)
{
    auto nupler(T)(in T arg)
    if((isDynamicArray!T || isStaticArray!T || isTuple!T))
    {
        static if(isDynamicArray!T)
        {
            T arr = arg.dup[0 .. N];
            foreach(ref e; arr)
                e = fn(e);
            return arr;
        }
        else static if(isStaticArray!T)
        {
            T arr = arg;
            foreach(ref e; arr[0 .. N])
                e = fn(e);
            return cast(typeof(arr[0])[N])arr[0 .. N];
        }
        else static if(isTuple!T)
        {
            T x = arg;
            foreach(ref e; x.tupleof)
                e = fn(e);
            return x;
        }
        else static assert(0);
    }
}


template toStaticArray(size_t N)
if(N >= 1)
{
    auto toStaticArray(T)(in T t)
    if(is(typeof(t[N-1])))
    {
      static if(isTuple!T)
        return cast(Unqual!(typeof(t[0]))[N])([t.tupleof][0 .. N]);
      else
      {
        Unqual!(typeof(t[0]))[N] dst;

        foreach(i; 0 .. N)
            dst[i] = t[i];

        return dst;
      }
    }
}


private alias nupler2(alias fn) = nupler!(fn, 2);
private alias toSA2 = toStaticArray!2;



struct ConsumerToken
{
    string key, secret;
}


struct AccessToken
{
    ConsumerToken consumer;
    string key, secret;
}


string oauthSignature(Tok, Rss)(in Tok token, string method, string url, Rss params)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken))
    && isInputRange!Rss && isSomeString!(typeof(params.front[0])) && isSomeString!(typeof(params.front[1])))
{
  static if(!isURLEncoded!Rss)
    return oauthSignature(token, method, url, params.map!(nupler2!encodeComponent).assumeURLEncoded);
  else
  {
    auto arr = params.map!toSA2.array();
    auto idx = new typeof(arr.front)*[arr.length];
    arr.makeIndex!"a[0] < b[0]"(idx);
    auto pairs = idx.map!`(*a)[0] ~ '=' ~ (*a)[1]`.join("&");

    static if(is(Tok : ConsumerToken))
    {
        immutable consumer = token.secret;
        immutable access = "";
    }
    else
    {
        immutable consumer = token.consumer.secret;
        immutable access = token.secret;
    }

    immutable key = [consumer, access].map!encodeComponent().join("&");
    immutable msg = format(`%-(%s&%)`, [    method,
                                            url,
                                            pairs].map!encodeComponent);

    return Base64.encode(hmacOf!SHA1(key, msg)[]);
  }
}


string oauthSignature(Tok, AAss)(in Tok token, string method, string url, in AAss params)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken)) && is(AAss : const(string[string])))
{
  static if(!isURLEncoded!AAss)
    return oauthSignature(token, token, method, url, params, params.dup.asRange.map!(nupler2!encodeComponent).assumeURLEncoded);
  else
    return oauthSignature(token, method, url, params.dup.asRange.assumeURLEncoded);
}


Return signedCall(Tok, Rss, Return)(in Tok token,
                               string method,
                               string url,
                               Rss param,
                               Return delegate(HTTP http, string url, string option) dlg)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken))
    && isInputRange!Rss && isSomeString!(typeof(param.front[0])) && isSomeString!(typeof(param.front[1])))
{
  static if(!isURLEncoded!Rss)
    return signedCall(token, method, url, param.map!(nupler2!encodeComponent).assumeURLEncoded, dlg);
  else
  {
    immutable optParams = param.map!"cast(typeof(a[0])[2])[a[0], a[1]]".array().assumeUnique;
    immutable oauthParams = {
      static if(is(Tok : ConsumerToken))
        immutable ck = token.key;
      else
        immutable ck = token.consumer.key;

        auto oauthParams = ["oauth_consumer_key":     ck,
                            "oauth_nonce":            Clock.currTime.toUnixTime.to!string,
                            "oauth_signature_method": "HMAC-SHA1",
                            "oauth_timestamp":        Clock.currTime.toUnixTime.to!string,
                            "oauth_version":          "1.0"].dup.asRange.map!(nupler2!encodeComponent).array;

      static if(is(Tok : AccessToken))
        oauthParams ~= "oauth_token".tuple(token.key).nupler2!encodeComponent.toSA2;

        oauthParams ~= "oauth_signature".tuple(oauthSignature(token, method, url, oauthParams.chain(optParams).assumeURLEncoded)).nupler2!encodeComponent.toSA2;

        return oauthParams.assumeUnique();
    }();

    immutable authorize = format("OAuth %(%-(%s=%),%)", oauthParams);
    immutable option = format("%(%-(%s=%)&%)", optParams);

    auto http = HTTP();
    http.verifyPeer(true);
    http.caInfo = `cacert.pem`;
    http.addRequestHeader("Authorization", authorize);
    return dlg(http, url, option);
  }
}


Return signedCall(Tok, AAss, Return)(in Tok token,
                                string method,
                                string url,
                             in AAss param,
                                Return delegate(HTTP http, string url, string option) dlg)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken)) && is(AAss : const(string[string])))
{
  static if(!isURLEncoded!AAss)
    return signedCall(token, method, url, param.dup.asRange.map!(nupler2!encodeComponent).assumeURLEncoded, dlg);
  else
    return signedCall(token, method, url, param.dup.asRange.assumeURLEncoded, dlg);
}


string signedGet(Tok, X)(in Tok token, string url, X param)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken))
    && (is(X == typeof(null)) || is(X : const(string[string])) || (isInputRange!X && isSomeString!(typeof(params.front[0])) && isSomeString!(typeof(params.front[1])))))
{
  static if(is(X == typeof(null)))
    return signedGet(token, url, (string[string]).init);
  else
    return signedCall(token, "GET", url, param, delegate(HTTP http, string url, string option){
        return get((0 < option.length)? url ~ "?" ~ option: url, http).assumeUnique();
    });
}


string signedPost(Tok, X)(in Tok token, string url, X param)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken))
    && (is(X == typeof(null)) || is(X : const(string[string])) || (isInputRange!X && isSomeString!(typeof(params.front[0])) && isSomeString!(typeof(params.front[1])))))
{
  static if(is(X == typeof(null)))
    return signedPost(token, url, (string[string]).init);
  else
    return signedCall(token, "POST", url, param, delegate(HTTP http, string url, string option) {
        return post(url, option, http).assumeUnique();
    });
}


string signedPostImage(Rss)(in AccessToken token, string url, in string[] filenames, Rss param)
if(isInputRange!Rss && isSomeString!(typeof(param.front[0])) && isSomeString!(typeof(param.front[1])))
{
  static if(isURLEncoded!Rss)
    return signedPostImage(token, url, filename, param.map!(nupler2!decodeComponent));
  else{
    return signedCall(token, "POST", url, (string[string]).init, delegate(HTTP http, string url, string /*option*/){
        immutable boundary = `cce6735153bf14e47e999e68bb183e70a1fa7fc89722fc1efdf03a917340`;   // 適当な文字列
        http.addRequestHeader("Content-Type", "mutipart/form-data; boundary=" ~ boundary);

        auto app = appender!(immutable(char)[])();
        foreach(e; param){
            immutable key = e[0],
                      value = e[1];

            app.formattedWrite("--%s\r\n", boundary);
            app.formattedWrite(`Content-Disposition: form-data; name="%s"`"\r\n", key);
            app.formattedWrite("\r\n");
            app.formattedWrite("%s\r\n", value);
        }


        auto bin = appender!(const(ubyte)[])(cast(const(ubyte[]))app.data);
        foreach(e; filenames){
            bin.put(cast(const(ubyte)[])format("--%s\r\n", boundary));
            bin.put(cast(const(ubyte)[])format("Content-Type: application/octet-stream\r\n"));
            bin.put(cast(const(ubyte)[])format(`Content-Disposition: form-data; name="media[]"; filename="%s"`"\r\n", e.baseName));
            bin.put(cast(const(ubyte[]))"\r\n");
            bin.put(cast(const(ubyte)[])std.file.read(e));
            bin.put(cast(const(ubyte[]))"\r\n");
        }
        bin.put(cast(const(ubyte)[])format("--%s--\r\n", boundary));

        return post(url, bin.data, http).assumeUnique();
    });
  }
}


string signedPostImage(AAss)(in AccessToken token, string url, in string[] filenames, in AAss param)
if(is(AAss : const(string[string])) || is(X == typeof(null)))
{
  static if(is(X == typeof(null)))
    return signedPostImage(token, url, filenames, (string[string]).init.asRange);
  else static if(isURLEncoded!AAss){
    return signedPostImage(token, url, filenames, param.dup.asRange.map!(nupler2!decodeComponent));
  }else
    return signedPostImage(token, url, filenames, param.dup.asRange);
}


private
struct UserStreamData(T, string file, size_t line)
{
    T data;
    alias data this;
}


auto userStreamData(string file, size_t line, T)(T data)
{
    return UserStreamData!(T, file, line)(data);
}


private void _spawnedFunc(string file, size_t line)(in AccessToken token, string url, immutable(string[2])[] arr, Channel!(immutable(ubyte)[]) ch)
{
    signedCall(token, "GET", url, arr, delegate(HTTP http, string url, string option) {
        try{
            scope(exit)
                ch.hangUp();

            http.method = HTTP.Method.get;
            http.url = url ~ ((option.length > 0) ? "?" ~ option : "");
            http.onReceive = (ubyte[] data)
            {
                ch ~= data.dup.assumeUnique;
                return data.length;
            };
            http.perform();
        }
        catch(Exception ex)
            std.stdio.writeln(ex);
    });
}


auto signedStreamGet(X, string file = __FILE__, size_t line = __LINE__)
                           (in AccessToken token, string url, X param)
if(is(X == typeof(null)) || is(X : const(string[string])) || (isInputRange!X && isSomeString!(typeof(param.front[0])) && isSomeString!(typeof(param.front[1]))))
{
  static if(is(X == typeof(null)))
    return signedStreamGet(token, url, (string[2][]).init.assumeURLEncoded);
  else static if(is(X : const(string[string])))
  {
    static if(isURLEncoded!X)
        return signedStreamGet(token, url, param.dup.asRange.assumeURLEncoded);
    else
        return signedStreamGet(token, url, param.dup.asRange.map!(nupler2!encodeComponent)().assumeURLEncoded);
  }
  else static if(!isURLEncoded!X)
    return signedStreamGet(token, url, param.map!(nupler2!encodeComponent).assumeURLEncoded);
  else
  {
    auto ch = channel!(immutable(ubyte)[])();
    auto sender = spawn(&(_spawnedFunc!(file, line)), token, url, param.array().assumeUnique, ch);

    static struct Result
    {
        string front()
        {
            assert(!empty());
            return _lines[0].chomp();
        }


        void popFront() pure nothrow @safe
        {
            _lines = _lines[1 .. $];
        }


        bool empty()
        {
            bool checkEmpty() { return _lines.length == 0 || (_lines.length == 1 && !_lines[0].endsWith("\r\n")); }

            while(!_ch.empty && checkEmpty())
            {
                auto str = cast(string)_ch.front;
                _ch.popFront();

                if(!_lines.length)
                    _lines ~= str;
                else
                    _lines[$-1] ~= str;

                while(1){
                    auto sp = _lines[$-1].findSplit("\r\n");
                    if(!sp[1].empty){
                        _lines[$-1] = _lines[$-1][0 .. sp[0].length + 2];   // + \r\n (size is +2)
                        _lines ~= sp[2];
                    }else
                        break;
                }
            }

            return checkEmpty();
        }


      private:
        Channel!(immutable(ubyte)[]) _ch;
        string[] _lines;
    }

    return Result(ch);
  }
}


auto signedStreamPost(X)(in AccessToken token,
                                   string method,
                                   string url,
                                in X param)
if(is(X == typeof(null)) || is(X : const(string[string])) || (isInputRange!X && isSomeString!(typeof(params.front[0])) && isSomeString!(typeof(params.front[1]))))
{

}


AccessToken toToken(string s, ConsumerToken consumer)
{
    string[string] result;
    foreach (x; s.split("&").map!`a.split("=")`)
        result[x[0]] = x[1];

    return AccessToken(consumer, result["oauth_token"], result["oauth_token_secret"]);
}


struct Twitter
{
    auto callAPI(string name, T...)(auto ref T args) const
    {
        return mixin(`Twitter.` ~ name ~ `(_token, forward!args)`);
    }


  private:
    AccessToken _token;

  public:
  static:
    struct oauth
    {
      static:
        AccessToken requestToken(X)(in ConsumerToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/oauth/request_token`, null)
                   .toToken(token);
        }


        string authorizeURL(in AccessToken requestToken)
        {
            return `https://api.twitter.com/oauth/authorize?oauth_token=` ~ requestToken.key;
        }


        AccessToken accessToken(in AccessToken requestToken, string verifier)
        {
            return signedGet(requestToken, `https://api.twitter.com/oauth/access_token`, ["oauth_verifier" : verifier])
                   .toToken(requestToken.consumer);
        }
    }


    struct account
    {
      static:
        auto settings(in AccessToken token)
        {
            struct Result
            {
                bool always_use_https;
                bool discoverable_by_email;
                bool geo_enable;
                string language;
                bool protected_;

            }

            return signedGet(token, `https://api.twitter.com/1.1/account/settings.json`, null);
        }


        auto verifyCredentials(X)(in AccessToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/1.1/account/verify_credentials.json`, param);
        }
    }


    struct statuses
    {
      static:
        auto mentionsTimeline(X)(in AccessToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/1.1/statuses/mentions_timeline.json`, param);
        }


        auto userTimeline(X)(in AccessToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/1.1/statuses/user_timeline.json`, param);
        }


        auto homeTimeline(X)(in AccessToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/1.1/statuses/home_timeline.json`, param);
        }


        auto retweetsOfMe(X)(in AccessToken token, X param)
        {
            return signedGet(token, `https://api.twitter.com/1.1/statuses/retweets_of_me.json`, param);
        }


        auto update(X)(in AccessToken token, X param)
        {
            return signedPost(token, `https://api.twitter.com/1.1/statuses/update.json`, param);
        }


        auto updateWithMedia(X)(in AccessToken token, string[] filenames, X param)
        {
            return signedPostImage(token, `https://api.twitter.com/1.1/statuses/update_with_media.json`, filenames, param);
        }
    }
}
