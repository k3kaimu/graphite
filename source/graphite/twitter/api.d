// Written in the D programming language.
/*
NYSL Version 0.9982

A. This software is "Everyone'sWare". It means:
  Anybody who has this software can use it as if he/she is
  the author.

  A-1. Freeware. No fee is required.
  A-2. You can freely redistribute this software.
  A-3. You can freely modify this software. And the source
      may be used in any software with no limitation.
  A-4. When you release a modified version to public, you
      must publish it with your name.

B. The author is not responsible for any kind of damages or loss
  while using or misusing this software, which is distributed
  "AS IS". No warranty of any kind is expressed or implied.
  You use AT YOUR OWN RISK.

C. Copyrighted to Kazuki KOMATSU

D. Above three clauses are applied both to source and binary
  form of this software.
*/

/**
このモジュールでは、Twitter-APIを叩きます。

Thanks: http://qiita.com/woxtu/items/9656d426f424286c6571
*/
module graphite.twitter.api;

import graphite.twitter;
import graphite.utils.json;

import core.thread;

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
import std.json;
import std.path;
import std.range;
import std.regex;
import std.string;
import std.traits;
import std.typecons;
import std.uri;
import std.net.curl;

import lock_free.dlist : AtomicDList;


private auto asRange(V, K)(V[K] aa)
if(is(V : K))
{
    return aa.byKey.zip(aa.repeat).map!"cast(typeof(a[0])[2])[a[0], a[1][a[0]]]"();
}


private template nupler(alias fn, size_t N)
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


private template toStaticArray(size_t N)
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


private string twEncodeComponent(string tw)
{
    enum re = ctRegex!`[\*"'\(\)!]`;

    static string func(T)(T m){
        char c = m.hit[0];
        return format("%%%X", c);
    }

    return tw.encodeComponent.replaceAll!func(re);
}


private string decodeHTMLEntity(string str)
{
    return str.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&");
}


private alias nupler2(alias fn) = nupler!(fn, 2);
private alias toSA2 = toStaticArray!2;


/**
コンシューマトークンを格納するための型です。

Example:
------------------
immutable cToken = ConsumerToken("key",
                                 "secret");

assert(cToken.key == "key");
assert(cToken.secret == "secret");
------------------
*/
struct ConsumerToken
{
    string key;     /// key
    string secret;  /// secret
}


/**
コンシューマトークンとアクセストークンを格納するための型です。

Example:
------------------
immutable consumerToken =
    ConsumerToken("consumer_key",
                  "consumer_secret");

immutable accessToken =
    AccessToken(consumerToken,
        "key",
        "secret");
------------------
*/
struct AccessToken
{
    ConsumerToken consumer; /// ConsumerToken
    string key;             /// key
    string secret;          /// secret
}



string oauthSignature(Tok, Rss)(in Tok token, string method, string url, Rss params)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken))
    && isInputRange!Rss && isSomeString!(typeof(params.front[0])) && isSomeString!(typeof(params.front[1])))
{
  static if(!isURLEncoded!Rss)
    return oauthSignature(token, method, url, params.map!(a => nupler2!twEncodeComponent(a)).assumeURLEncoded);
  else
  {
    auto arr = params.map!(a => toSA2(a)).array();
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

    immutable key = [consumer, access].map!(a => twEncodeComponent(a)) ().join("&");
    immutable msg = format(`%-(%s&%)`, [    method,
                                            url,
                                            pairs].map!(a => twEncodeComponent(a)));

    return Base64.encode(hmacOf!SHA1(key, msg)[]);
  }
}


private:

string oauthSignature(Tok, AAss)(in Tok token, string method, string url, in AAss params)
if((is(Tok : ConsumerToken) || is(Tok : AccessToken)) && is(AAss : const(string[string])))
{
  static if(!isURLEncoded!AAss)
    return oauthSignature(token, token, method, url, params, params.dup.asRange.map!(a => nupler2!twEncodeComponent(a)).assumeURLEncoded);
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
    return signedCall(token, method, url, param.map!(a => nupler2!twEncodeComponent(a)).assumeURLEncoded, dlg);
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
                            "oauth_version":          "1.0"].dup.asRange.map!(a => nupler2!twEncodeComponent(a)).array;

      static if(is(Tok : AccessToken))
        oauthParams ~= "oauth_token".tuple(token.key).nupler2!twEncodeComponent.toSA2;

        oauthParams ~= "oauth_signature".tuple(oauthSignature(token, method, url, oauthParams.chain(optParams).assumeURLEncoded)).nupler2!twEncodeComponent.toSA2;

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
  static if(is(AAss == typeof(null)))
    return signedCall(token, method, url, null, dlg);
  else static if(!isURLEncoded!AAss)
    return signedCall(token, method, url, param.dup.asRange.map!(a => nupler2!twEncodeComponent(a)).assumeURLEncoded, dlg);
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
        return get((0 < option.length)? url ~ "?" ~ option: url, http).idup;
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
        return post(url, option, http).idup;
    });
}


string signedPostImage(Rss)(in AccessToken token, string url, string endPoint, in string[] filenames, Rss param)
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
            bin.put(cast(const(ubyte)[])format(`Content-Disposition: form-data; name="%s"; filename="%s"`"\r\n", endPoint, e.baseName));
            bin.put(cast(const(ubyte[]))"\r\n");
            bin.put(cast(const(ubyte)[])std.file.read(e));
            bin.put(cast(const(ubyte[]))"\r\n");
        }
        bin.put(cast(const(ubyte)[])format("--%s--\r\n", boundary));

        return post(url, bin.data, http).idup;
    });
  }
}


string signedPostImage(AAss)(in AccessToken token, string url, string endPoint, in string[] filenames, in AAss param)
if(is(AAss : const(string[string])) || is(AAss == typeof(null)))
{
  static if(is(AAss == typeof(null)))
    return signedPostImage(token, url, endPoint, filenames, (string[string]).init.asRange);
  else static if(isURLEncoded!AAss)
    return signedPostImage(token, url, endPoint, filenames, param.dup.asRange.map!(nupler2!decodeComponent));
  else
    return signedPostImage(token, url, endPoint, filenames, param.dup.asRange);
}


private void _spawnedFunc(in AccessToken token, string url, immutable(string[2])[] arr, shared(AtomicDList!string) ch)
{
    static struct TerminateMessage {}


    /*
    $(D_CODE std.net.HTTP.dup())のバグを直したものです。

    $(D_CODE HTTP.dup())では、`$( HTTP.clear(CurlOption.noprogress))`が呼ばれていますが、
    `$(D_CODE HTTP.clear)`メソッドはそのドキュメントにもある通り、ポインタを格納するオプションを初期化するためのメソッドです。
    $(D_CODE CurlOption.noprogress)は整数値のオプションなので、このコードは誤りです。

    またこの誤りにより、$(D_CODE HTTP.dup())が呼ばれる度に$(D_CODE CurlOption.noprogress)に$(D_CODE null)が設定され、
    結果的に$(D_CODE byLineAsync)などプログレスメーターが表示されるようになります。

    $(D_CODE BugFixedHTTP)では上記不具合を解決するために、強制的に$(D_CODE CurlOption.noprogress)オプションに$(D_CODE 1)を入れています。
    */
    static struct BugFixedHTTP
    {
        static BugFixedHTTP opCall(const(char)[] url)
        {
            return BugFixedHTTP(HTTP(url));
        }


        static BugFixedHTTP opCall()
        {
            return BugFixedHTTP(HTTP());
        }


        static BugFixedHTTP opCall(HTTP http)
        {
            //this.http = http;
            BugFixedHTTP bfhttp;
            bfhttp.http = http;
            return bfhttp;
        }


        BugFixedHTTP dup()
        {
            HTTP conn = http.dup;
            conn.handle.set(CurlOption.noprogress, 1);
            return BugFixedHTTP(conn);
        }


        string encoding() @property 
        {
            return http.tupleof[0].charset;
        }


        @property
        void onReceive(size_t delegate(ubyte[]) callback)
        {
            http.onReceive = delegate(ubyte[] data){
                size_t n = callback(data);

                // check terminate message
                receiveTimeout(dur!"msecs"(0), (TerminateMessage dummy){ n = 0; });
                return n;
            };
        }


        HTTP http;
        alias http this;
    }


    size_t cnt;
    while(1){
        try{
            if(cnt < 10)
                receiveTimeout(dur!"msecs"(250) * (1 << cnt), (bool dummy){});
            else
                break;

            signedCall(token, "GET", url, arr, delegate(HTTP http, string url, string option) {
                cnt = 0;  // init error count

                import std.stdio;
                auto bugFixedHttp = BugFixedHTTP(http);

                if(option.length > 0)
                        url ~= "?" ~ option;

                auto lines = byLineAsync(url, null, KeepTerminator.no, '\x0a', 10, bugFixedHttp);

                void finalize() { lines.tupleof[2].send(TerminateMessage.init); }

                try{
                    while(1){
                        if(lines.wait(dur!"msecs"(5000))){
                            ch.pushBack(lines.front.idup);
                            lines.popFront();
                        }

                        receiveTimeout(dur!"msecs"(0), (bool dummy){});
                    }
                }
                catch(OwnerTerminated){
                    finalize();
                    return;
                }
                catch(LinkTerminated){
                    finalize();
                    return;
                }
                catch(Exception ex){
                    finalize();
                    ch.pushBack(ex.to!string);
                }
            });
        }
        catch(OwnerTerminated){
            return;
        }
        catch(LinkTerminated){
            return;
        }
        catch(Exception ex)
            ch.pushBack(ex.to!string);

        ++cnt;
    }
}


auto signedStreamGet(X)(in AccessToken token, string url, Duration waitTime, X param)
if(is(X == typeof(null)) || is(X : const(string[string])) || (isInputRange!X && isSomeString!(typeof(param.front[0])) && isSomeString!(typeof(param.front[1]))))
{
  static if(is(X == typeof(null)))
    return signedStreamGet(token, url, waitTime, (string[2][]).init.assumeURLEncoded);
  else static if(is(X : const(string[string])))
  {
    static if(isURLEncoded!X)
        return signedStreamGet(token, url, waitTime, param.dup.asRange.assumeURLEncoded);
    else
        return signedStreamGet(token, url, waitTime, param.dup.asRange.map!(a => nupler2!twEncodeComponent(a))().assumeURLEncoded);
  }
  else static if(!isURLEncoded!X)
    return signedStreamGet(token, url, param.map!(nupler2!twEncodeComponent).assumeURLEncoded);
  else
  {
    auto ch = new shared AtomicDList!string();
    auto tid = spawnLinked(&_spawnedFunc, token, url, param.array().assumeUnique, ch);

    static struct Result
    {
        string front() @property
        {
            if(!_cashed) popFront();

            return _frontCash;
        }


        enum bool empty = false;


        void popFront()
        {
            _cashed = false;
            while(!_cashed){
                if(auto p = _ch.popFront()){
                    _frontCash = *p;
                    _cashed = true;
                }
                else
                    core.thread.Thread.sleep(_wt);
            }
        }


        @property
        shared(AtomicDList!string) channel()
        {
            return _ch;
        }


        @property
        Tid tid() { return _tid; }


      private:
        Tid _tid;
        shared(AtomicDList!string) _ch;
        string _frontCash;
        bool _cashed;
        Duration _wt;
    }

    return Result(tid, ch, null, false, waitTime);
  }
}


public:

/**
Twitter-APIを扱うための型です。

Example:
---------------------------------------
import std.json;
import std.process;
import std.stdio;
import std.string;
import graphite.twitter;


immutable consumerToken =
    ConsumerToken("consumer_key",
                  "consumer_secret");

void main()
{
    // リクエストトークンの取得
    Twitter reqTok = Twitter(Twitter.oauth.requestToken(consumerToken, null));
    
    // ブラウザで認証してもらう
    browse(reqTok.callAPI!"oauth.authorizeURL"());

    // pinコードを入力してもらう
    write("please put pin-code: ");

    // pinコードからアクセストークンを取得
    Twitter accTok = Twitter(reqTok.callAPI!"oauth.accessToken"(readln().chomp()));

    // ツイート
    accTok.callAPI!"statuses.update"(["status": "Tweet by dlang-code"]);
}
---------------------------------------
*/
struct Twitter
{
    /**
    各APIを叩くためのメソッドです
    */
    auto callAPI(string name, T...)(auto ref T args) const
    {
        return mixin(`Twitter.` ~ name ~ `(_token, forward!args)`);
    }


    auto get(X)(string url, X param) const
    {
        return signedGet(_token, url, args);
    }


    auto post(X)(string url, X param) const
    {
        return signedPost(_token, url, args);
    }


    auto postImage(X)(string url, string endPoint, in string[] filenames, X param) const
    {
        return signedPostImage(_token, url, endPoint, filenames, args);
    }


  private:
    AccessToken _token;

  public:
  static:
    struct oauth
    {
        private static AccessToken toToken(string s, ConsumerToken consumer)
        {
            string[string] result;
            foreach (x; s.split("&").map!`a.split("=")`)
                result[x[0]] = x[1];

            return AccessToken(consumer, result["oauth_token"], result["oauth_token_secret"]);
        }

      static:
        /**
        リクエストトークンの取得

        Example:
        -----------------------------
        Twitter reqTok = Twitter(Twitter.oauth.requestToken(consumerToken, null));
        -----------------------------
        */
        AccessToken requestToken(X)(in ConsumerToken token, X param)
        {
            return toToken(signedGet(token, `https://api.twitter.com/oauth/request_token`, null)
                   , token);
        }


        /**
        ブラウザで認証してもらうためのURLを取得

        Example:
        -----------------------------
        string url = reqTok.callAPI!"oauth.authorizeURL"();
        -----------------------------
        */
        string authorizeURL(in AccessToken requestToken)
        {
            return `https://api.twitter.com/oauth/authorize?oauth_token=` ~ requestToken.key;
        }


        /**
        pinコードからアクセストークンを取得

        Example:
        -----------------------------
        string pin = readln().chomp();  // pin-code
        Twitter tw = Twitter(reqTok.callAPI!"oauth.accessToken"(pin));
        -----------------------------
        */
        AccessToken accessToken(in AccessToken requestToken, string verifier)
        {
            return toToken(signedGet(requestToken, `https://api.twitter.com/oauth/access_token`, ["oauth_verifier" : verifier]), 
                           requestToken.consumer);
        }
    }


    struct account
    {
      static:
        auto settings(in AccessToken token)
        {
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


        /**
        ツイートします。

        Example:
        ---------------------
        import std.array, std.format, std.json;

        // ツイート
        string tweet(Twitter tw, string msg)
        {
            return tw.callAPI!"statuses.update"(["status" : msg]);
        }


        // 画像も一緒にツイート
        string tweetWithMedia(Twitter tw, string msg, string[] imgFilePaths)
        {
            return tw.callAPI!"statuses.update"([
                "status" : msg,
                "media_ids" : format("%(%s,%)",
                                imgFilePaths.map!(a => parseJSON(tw.callAPI!"media.upload"(a))["media_id_string"].str))
            ]);
        }
        ---------------------
        */
        auto update(X)(in AccessToken token, X param)
        {
            return signedPost(token, `https://api.twitter.com/1.1/statuses/update.json`, param);
        }


        /**
        画像1枚と一緒にツイート

        Example:
        ------------------------
        string tweetWithMedia(Twitter tw, string msg, string imgFilePath)
        {
            return tw.callAPI!"statuses.updateWithMedia"(imgFilePath, ["status" : msg]);
        }
        ------------------------
        */
        auto updateWithMedia(X)(in AccessToken token, string filePath, X param)
        {
            string[1] filenames = [filePath];
            return signedPostImage(token, `https://api.twitter.com/1.1/statuses/update_with_media.json`, "media[]", filenames, param);
        }
    }


    struct media
    {
      static:
        /**
        画像をuploadします

        Example:
        -------------------------
        import std.json;

        // 画像をuploadして、画像のidを取得する
        string uploadImage(Twitter tw, string imgFilePath)
        {
            return parseJSON(tw.callAPI!"media.upload"(imgFilePath))["media_id_string"].str;
        }
        -------------------------
        */
        string upload(in AccessToken token, string filePath)
        {
            immutable url = `https://upload.twitter.com/1.1/media/upload.json`;
            string[1] filenames = [filePath];
            return signedPostImage(token, url, "media", filenames, null);
        }
    }


    struct userstream
    {
      static:
        /**
        Userstreamに接続します
        */
        auto user(X)(in AccessToken token, X params)
        {
            return signedStreamGet(token, `https://userstream.twitter.com/1.1/user.json`, dur!"seconds"(5), params);
        }
    }

}
