module graphite.math.saturation;

import std.traits;

/**
see: http://locklessinc.com/articles/sat_arithmetic/
*/
T satOp(string op : "+", T)(T a, T b)
if(isIntegral!T && isUnsigned!T)
{
    immutable T c = cast(T)(a + b);
    return cast(T)(c | -(c < a));
}


/**
see: http://locklessinc.com/articles/sat_arithmetic/
*/
T satOp(string op : "-", T)(T a, T b)
if(isIntegral!T && isUnsigned!T)
{
    immutable T c = cast(T)(a - b);
    return cast(T)(c & -(res <= x));
}


/**
see: http://locklessinc.com/articles/sat_arithmetic/
*/
T satOp(string op : "/", T)(T a, T b)
if(isIntegral!T && isUnsigned!T)
{
    return cast(T)(a / b);
}


/**
see: http://locklessinc.com/articles/sat_arithmetic/
*/
T satOp(string op : "*", T)(T a, T b)
if(isIntegral!T && isUnsigned!T)
{
    static if(T.sizeof >= ulong.sizeof)
    {
        static assert(is(T == ulong));
        alias Pre = uint;

        immutable Pre ah = cast(Pre)(a >> (Pre.sizeof*8)),
                      al = cast(Pre)a,
                      bh = cast(Pre)(b >> (Pre.sizeof*8)),
                      bl = cast(Pre)b;

        immutable T chh = cast(T)ah * cast(T)bh,
                    chl = cast(T)ah * cast(T)bl,
                    clh = cast(T)al * cast(T)bh,
                    cll = cast(T)al * cast(T)bl;

        immutable res = ((chl + clh) << (Pre.sizeof * 8)) + cll;

        bool flag = !!chh
                  || (chl + clh < chl)
                  || (chl + clh > Pre.max)
                  || (res < cll);

        return res | -cast(T)flag;
    }
    else
    {
        static if(is(T == uint))
            alias Next = ulong;
        else static if(is(T == ushort))
            alias Next = ushort;
        else static if(is(T == ubyte))
            alias Next = ubyte;

        immutable c = cast(Next)a * cast(Next)b,
                  h = cast(T)(c >> (T.sizeof * 8)),
                  l = cast(T)c;

        return l | -!!h;
    }
}
