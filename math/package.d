module graphite.math;

import core.bitop;

import std.math;
import std.random;
import std.traits;
import std.algorithm;
import std.functional;

import graphite.utils.noise;
import graphite.types.point;


public import graphite.math.matrix,
              graphite.math.quaternion;


/**
nextが1である場合に、next2Pow(num)はnumより大きく、かつ、最小の2の累乗数を返します。

もし、nextが0であれば、next2Powはnumより小さく、かつ、最大の2の累乗数を返します。
nextがm > 1の場合には、next2Pow(num, m)は、next2Pow(num) << (m - 1)を返します。
*/
size_t nextPow2(T)(T num, size_t next = 1)
if(isIntegral!T)
in{
    assert(num >= 1);
}
body{
    static size_t castToSize_t(X)(X value)
    {
      static if(is(X : size_t))
        return value;
      else
        return value.to!size_t();
    }

    return (cast(size_t)1) << (bsr(castToSize_t(num)) + next);
}

///
pure nothrow @safe unittest{
    assert(nextPow2(10) == 16);           // デフォルトではnext = 1なので、次の2の累乗数を返す
    assert(nextPow2(10, 0) == 8);         // next = 0だと、前の2の累乗数を返す
    assert(nextPow2(10, 2) == 32);        // next = 2なので、next2Pow(10) << 1を返す。
}


real random(Gen)(real max)
{
    return uniform!"[)"(0, max);
}


real random(real x, real y)
{
    return uniform!"[)"(min(x, y), max(x, y));
}


real normalize(real value, real min, real max) pure nothrow @safe
{
    return (value - min) / (max - min).clamp(0, 1);
}


real lerp(real value, real[2] input, real[2] output) pure nothrow @safe
{
    if((input[0] - input[1]).approxEqual(0)){
        debug logger!(graphite.math).writefln!"warning"("avoiding possible divide by zero, check input[0](%s) and input[0](%s)", inputMin, inputMax);
        return value - input[0] < value - input[1] ? output[0] : output[1];
    }else
        return (output[1] - output[0]) / (input[1] - input[0]) * (value - input[0]) + output[0];
}


real dist(real x1, real y1, real x2, real y2) pure nothrow @safe
{
    return ((x1 - x2) ^^ 2 + (y1 - y2) ^^ 2) ^^ 0.5;
}


real clamp(real value, real min, real max) pure nothrow @safe
{
    return value < min ? min : (value > max ? max : value);
}


alias sign = signbit;


bool isInRange(string bd = "[]")(float t, float min, float max) pure nothrow @safe
if(bd.length == 2 && (bd[0] == '[' || bd[1] == '(')
                  && (bd[1] == ']' || bd[1] == ')'))
{
    enum fst = bd[0] == '[' ? ">=" : ">";
    enum snd = bd[1] == ']' ? "<=" : "<";

    return mixin(`t` ~ fst ~ "min && t" ~ snd ~ "max");
}


real radToDeg(real radians) pure nothrow @safe
{
    return radians * (std.math.PI / 180);
}


real degToRad(real degrees) pure nothrow @safe
{
    return degrees / 180 * std.math.PI;
}


real lerp(real start, real stop, real amt) pure nothrow @safe
{
    return start + (stop - start) * amt;
}


real wrap(real value, real from, real to) pure nothrow @safe
{
    // algorithm from http://stackoverflow.com/a/5852628/599884
    if(from <= to){
        immutable cyc = to - from;
        if(cyc.approxEqual(0))
            return to;
        else
            return value - cyc * floor((value - from) / cyc);
    }else
        return wrap(value, to, from);
}


real wrapRadians(real angle, real from = -PI, real to = +PI) pure nothrow @safe
{
    return wrap(angle, from, to);
}


real wrapDegrees(real angle, real from = -180, real to = 180) pure nothrow @safe
{
    return wrap(angle, from, to);
}




real lerpDegrees(real currAngle, real target, real pct)
{
    return currAngle + angleDifferenceDegrees(currAngle, target) * pct;
}


real lerpRadians(real currAngle, real target, real pct)
{
    return currAngle + angleDifferenceRadians(currAngle, target) * pct;
}


private PerlinNoise _noiseEngine;

static this()
{
    _noiseEngine = new PerlinNoise();
}


@property
ref PerlinNoise noiseEngine() @safe 
{
    return _noiseEngine;
}


real noise(size_t N)(real[N] x...)
if(N >= 1 && N <= 4)
{
    real[N] xx = x;
    return _noiseEngine.noise(xx) * 0.5 + 0.5;
}


real signedNoise(size_t N)(real[N] x...)
if(N >= 1 && N <= 4)
{
    real[N] xx = x;
    return _noiseEngine.noise(xx);
}


bool isInsidePoly(real x, real y, in Point[] polygon)
{
    return polyline(polygon).isContain(x, y);
}


bool isInsidePoly(Point p, in Point[] polygon)
{
    return polyline(polygon).isContain(p);
}


bool lineSegmentIntersection(Point line1Start, Point line1End, Point line2Start, Point line2End, out Point intersection)
{
    auto diffLA = line1End - line1Start,
         diffLB = line2End - line2Start;

    alias xymyx = binaryFun!"a.x * b.y - a.y * b.x";

    immutable cmpA = xymyx(diffLA, line1Start),
              cmpB = xymyx(diffLB, line2Start);

    if(((xymyx(diffLA, line2Start) < cmpA) ^ (xymyx(diffLA, line2End) < cmpA))
     && ((xymyx(diffLB, line1Start) < cmpB) ^ (xymyx(diffLB, line1End) < cmpB)))
    {
        intersection = (diffLB * cmpA - diffLA * cmpB) * -1 / xymyx(diffLA, diffLB);
        return true;
    }

    return false;
}


T bezierPoint(T)(T a, T b, T c, T d, real t)
{
    immutable tp = 1 - t;
    return a * tp ^^ 3
         + b * 3 * t * tp^^2
         + c * 3 * t^^2 * tp;
         + d * t^^3;
}


T curvePoint(T)(T a, T b, T c, T d, real t)
{
    immutable t2 = t ^^ 2,
              t3 = t2 * t;

    T p = b * 2
        + (-a + c) * t
        + (2 * a - 5 * b + 4 * c - d) * t2
        + (-a + 3 * b - 3 * c + d) * t3;

    p *= 0.5;
    return p;
}


T bezierTangent(T)(T a, T b, T c, T d, real t)
{
    return (d - a - c * 3 + b * 3) * (t^^2)*3
         + (a + c - b * 2) * t * 6
         - a * 3 + b * 3;
}


T curveTangent(T)(T a, T b, T c, T d, real t)
{
    auto v0 = (c - a) * 0.5,
         v1 = (d - b) * 0.5;

    return (b * 2 - c * 2 + v0 + v1) * 3 * t^^2
         + (c * 3 - b * 3 - v1 - v0 * 2) * 2 * t
         + v0;
}


private real angleDifferenceDegrees(real currAngle, real targetAngle)
{
    return wrapDegrees(targetAngle - currAngle);
}


private real angleDifferenceRadians(real currAngle, real targetAngle)
{
    return wrapRadians(targetAngle - currAngle);
}


T interpolateCosine(T)(T y1, T y2, real pct)
{
    immutable pct2 = (1 - cos(pct * PI)) / 2;
    return y1 * (1 - pct2) + y2 * pct2;
}


T interpolateCubic(T)(T y0, T y1, T y2, T y3, real pct)
{
    immutable pct2 = pct^^2;
    auto a0 = y3 - y2 - y0 + y1,
         a1 = y0 - y1 - a0,
         a2 = y2 - y0,
         a3 = y1;

    return a0 * pct * pct2
         + a1 * pct2
         + a2 * pct
         + a3;
}


T interpolateCatmullRom(T)(T y0, T y1, T y2, T y3, real pct)
{
    immutable pct2 = pct^^2;
    auto a0 = -0.5 * y0 + 1.5 * y1 - 1.5 * y2 + 0.5 * y3,
         a1 = y0 - 2.5 * y1 + 2 * y2 - 0.5 * y3,
         a2 = -0.5 * y0 + 0.5 * y2,
         a3 = y1;
    
    return a0 * pct * pct2
         + a1 * pct2
         + a2 * pct
         + a3;
}


T interpolateHermite(T)(T y0, T y1, T y2, T y3, real pct)
{
    immutable pct2 = pct^^2;
    auto c = (y2 - y0) * 0.5f,
         v = y1 - y2,
         w = c + v,
         a = w + v + (y3 - y1) * 0.5,
         b_neg = w + a;

    return a * pct2 * pct
         - b_neg * pct2
         + c * pct
         + y1;
}


T ofInterpolateHermite(T)(T y0, T y1, T y2, T y3, real pct, real tension, real bias)
{
    immutable pct2 = pct * pct,
              pct3 = pct2 * pct;

    auto m0 = (y1-y0) * (1+bias) * (1-tension) / 2 + (y2-y1) * (1-bias) * (1-tension) / 2,
         m1 = (y2-y1) * (1+bias) * (1-tension) / 2 + (y3-y2) * (1-bias) * (1-tension) / 2,
         a0 = 2 * pct3 - 3 * pct2 + 1,
         a1 = pct3 - 2 * pct2 + pct,
         a2 = pct3 - pct2,
         a3 = -2 * pct3 + 3 * pct2;

    return a0 * y1 + a1 * m0 + a2 * m1 + a3 * y2;
}
