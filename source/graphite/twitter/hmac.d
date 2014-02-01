// Written in the D programming language.
/**
HMAC implemented by D.

Author: Kazuki Komatsu
Licence: NYSL
*/
module graphite.twitter.hmac;

import std.digest.sha;
import std.digest.md;


/**

*/
struct HMAC(Hash)if(isDigest!Hash)
{
    this(const(ubyte)[] key) pure nothrow @safe
    {
        _ipad.length = blockSize;
        _opad.length = blockSize;

        if(key.length > blockSize){
            _hash.start();
            _hash.put(key);
            _key = _hash.finish()[];
        }else
            _key = key;

        if(_key.length < blockSize)
            _key.length = blockSize;

        foreach(i; 0 .. blockSize){
            _ipad[i] = _key[i] ^ 0x36;
            _opad[i] = _key[i] ^ 0x5c;
        }

        this.start();
    }


    void start() pure nothrow @safe
    {
        _hash.start();
        _hash.put(_ipad);
    }


    void put(scope const(ubyte)[] input...) pure nothrow @safe
    {
        _hash.put(input);
    }


    auto finish() pure nothrow @safe
    {
        auto inner = _hash.finish();

        _hash.put(_opad);
        _hash.put(inner[]);
        auto result = _hash.finish();
        
        _hash.put(_ipad);   // this.start();

        return result;
    }


  private:
    Hash _hash;
    const(ubyte)[] _key;
    ubyte[] _ipad;
    ubyte[] _opad;

    static if(is(Hash == std.digest.sha.SHA1) || is(Hash == std.digest.md.MD5))
        enum blockSize = 64;
    else 
        enum blockSize = Hash.blockSize;
}

unittest{
    // HMAC-MD5 test case : http://www.ipa.go.jp/security/rfc/RFC2202JA.html
    import std.algorithm, std.range, std.array, std.digest.digest;

    auto hmac_md5 = HMAC!(MD5)(array(take(repeat(cast(ubyte)0x0b), 16)));
    put(hmac_md5, cast(ubyte[])"Hi There");
    assert(toHexString(hmac_md5.finish()) == "9294727A3638BB1C13F48EF8158BFC9D");

    hmac_md5 = HMAC!(MD5)(cast(ubyte[])"Jefe");
    put(hmac_md5, cast(ubyte[])"what do ya want for nothing?");
    assert(toHexString(hmac_md5.finish()) == "750C783E6AB0B503EAA86E310A5DB738");

    hmac_md5 = HMAC!(MD5)(array(take(repeat(cast(ubyte)0xaa), 16)));
    put(hmac_md5, array(take(repeat(cast(ubyte)0xdd), 50)));
    assert(toHexString(hmac_md5.finish()) == "56BE34521D144C88DBB8C733F0E8B3F6");

    hmac_md5 = HMAC!(MD5)(array(map!"cast(ubyte)a"(iota(1, 26))));
    put(hmac_md5, array(take(repeat(cast(ubyte)0xcd), 50)));
    assert(toHexString(hmac_md5.finish()) == "697EAF0ACA3A3AEA3A75164746FFAA79");

    hmac_md5 = HMAC!(MD5)(array(take(repeat(cast(ubyte)0x0c), 16)));
    put(hmac_md5, cast(ubyte[])"Test With Truncation");
    assert(toHexString(hmac_md5.finish()) == "56461EF2342EDC00F9BAB995690EFD4C");

    hmac_md5 = HMAC!(MD5)(array(take(repeat(cast(ubyte)0xaa), 80)));
    put(hmac_md5, cast(ubyte[])"Test Using Larger Than Block-Size Key - Hash Key First");
    assert(toHexString(hmac_md5.finish()) == "6B1AB7FE4BD7BF8F0B62E6CE61B9D0CD");

    hmac_md5 = HMAC!(MD5)(array(take(repeat(cast(ubyte)0xaa), 80)));
    put(hmac_md5, cast(ubyte[])"Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data");
    assert(toHexString(hmac_md5.finish()) == "6F630FAD67CDA0EE1FB1F562DB3AA53E");
}

unittest{
    // HMAC-SHA1 test case : http://www.ipa.go.jp/security/rfc/RFC2202JA.html
    import std.algorithm, std.range, std.array, std.digest.digest;

    auto hmac_sha1 = HMAC!(SHA1)(array(take(repeat(cast(ubyte)0x0b), 20)));
    put(hmac_sha1, cast(ubyte[])"Hi There");
    assert(toHexString(hmac_sha1.finish()) == "B617318655057264E28BC0B6FB378C8EF146BE00");

    hmac_sha1 = HMAC!(SHA1)(cast(ubyte[])"Jefe");
    put(hmac_sha1, cast(ubyte[])"what do ya want for nothing?");
    assert(toHexString(hmac_sha1.finish()) == "EFFCDF6AE5EB2FA2D27416D5F184DF9C259A7C79");

    hmac_sha1 = HMAC!(SHA1)(array(take(repeat(cast(ubyte)0xaa), 20)));
    put(hmac_sha1, array(take(repeat(cast(ubyte)0xdd), 50)));
    assert(toHexString(hmac_sha1.finish()) == "125D7342B9AC11CD91A39AF48AA17B4F63F175D3");

    hmac_sha1 = HMAC!(SHA1)(array(map!"cast(ubyte)a"(iota(1, 26))));
    put(hmac_sha1, array(take(repeat(cast(ubyte)0xcd), 50)));
    assert(toHexString(hmac_sha1.finish()) == "4C9007F4026250C6BC8414F9BF50C86C2D7235DA");

    hmac_sha1 = HMAC!(SHA1)(array(take(repeat(cast(ubyte)0x0c), 20)));
    put(hmac_sha1, cast(ubyte[])"Test With Truncation");
    assert(toHexString(hmac_sha1.finish()) == "4C1A03424B55E07FE7F27BE1D58BB9324A9A5A04");

    hmac_sha1 = HMAC!(SHA1)(array(take(repeat(cast(ubyte)0xaa), 80)));
    put(hmac_sha1, cast(ubyte[])"Test Using Larger Than Block-Size Key - Hash Key First");
    assert(toHexString(hmac_sha1.finish()) == "AA4AE5E15272D00E95705637CE8A3B55ED402112");

    hmac_sha1 = HMAC!(SHA1)(array(take(repeat(cast(ubyte)0xaa), 80)));
    put(hmac_sha1, cast(ubyte[])"Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data");
    assert(toHexString(hmac_sha1.finish()) == "E8E99D0F45237D786D6BBAA7965C7808BBFF1A91");
}



auto hmacOf(Hash)(in void[] key, in void[] input)
{
    auto hash = HMAC!Hash(cast(const(ubyte)[])key);
    hash.put(cast(const(ubyte)[])input);
    return hash.finish;
}
