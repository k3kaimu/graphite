module graphite.math.quaternion;

import graphite.math.linear;

import std.format,
       std.functional,
       std.math,
       std.traits;


alias Quatf = Quaternion!float;


/**
四元数
*/
Quaternion!(CommonType!(A, B, C, D)) quaternion(A, B, C, D)(A a, B b, C c, D d) pure nothrow @safe
if(is(Quaternion!(CommonType!(A, B, C, D))))
{
    typeof(return) dst;

    dst.a = a;
    dst.b = b;
    dst.c = c;
    dst.d = d;

    return dst;
}


/// ditto
Quaternion!A quaternion(A)(A a) pure nothrow @safe
if(is(Quaternion!A))
{
    typeof(return) dst;

    dst.a = a;
    dst.b = 0;
    dst.c = 0;
    dst.d = 0;

    return dst;
}


/// ditto
Quaternion!(ElementType!V) quaternion(V)(V v)
if(isVector!V)
{
    typeof(return) dst;
    dst._vec4 = v;
    return dst;
}


/// ditto
Quaternion!(CommonType!(R, ElementType!V)) quaternion(R, V)(R r, V v)
if(is(Quaternion!(CommonType!(R, ElementType!V))))
{
    typeof(return) dst;

    dst.s = r;
    dst.v = v;

    return dst;
}


/// ditto
Quaternion!E quaternion(E)(E[] arr)
if(is(Quaternion!E))
in{
    assert(arr.length == 4);
}
body{
    typeof(return) dst;
    dst._vec4.array[] = arr[];

    return dst;
}


real toDeg(real rad) pure nothrow @safe
{
    return rad / PI * 180;
}


real toRad(real deg) pure nothrow @safe
{
    return deg / 180 * PI;
}



/// ditto
struct Quaternion(S)
if(isScalar!S)
{
    this(E)(in Quaternion!E q)
    if(is(E : S))
    {
        this = q;
    }


    this()(in SCVector!(int, 4) m)
    {
        this._vec4 = m;
    }


    /// 
    ref inout(S) opIndex(size_t i) pure nothrow @safe inout
    in{
        assert(i < 4);
    }
    body{
        return _vec4[i];
    }


    ref inout(S) s() pure nothrow @safe @property inout { return _vec4[0]; }
    ref inout(S) i() pure nothrow @safe @property inout { return _vec4[1]; }
    ref inout(S) j() pure nothrow @safe @property inout { return _vec4[2]; }
    ref inout(S) k() pure nothrow @safe @property inout { return _vec4[3]; }


    alias a = s;
    alias b = i;
    alias c = j;
    alias d = k;

    alias w = a;
    alias x = b;
    alias y = c;
    alias z = d;


    @property
    auto v()() pure nothrow @safe inout
    {
        return _vec4.reference.swizzle.bcd;
    }


    @property
    void v(V)(in V v)
    {
        foreach(i; 0 .. 3)
            this._vec4[i+1] = v[i];
    }


    @property
    V asVec4(V = SCVector!(S, 4))() inout
    {
        V v = this._vec4;
        return v;
    }


    auto opUnary(string op : "-", E)(in Quaternion!E q) const
    {
        return typeof(return)(typeof(typeof(return).init._vec4)(this._vec4 * -1));
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "+", E)(in Quaternion!E q) const
    if(!is(CommonType!(S, E) == void))
    {
        return typeof(return)(typeof(typeof(return).init._vec4)(this._vec4 + q._vec4));
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "-", E)(in Quaternion!E q) const
    if(!is(CommonType!(S, E) == void))
    {
        return typeof(return)(typeof(typeof(return).init._vec4)(this._vec4 - q._vec4));
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "*", E)(in Quaternion!E q) const
    if(!is(CommonType!(S, E) == void))
    {
        return quaternion(this.s * q.s - this.v.dot(q.v), (this.s * q.v) + (q.s * this.v) + (this.v.cross(q.v)));
    }


    auto opBinary(string op : "/", E)(in Quaternion!E q) const
    if(isFloatingPoint!(CommonType!(S, E)))
    {
        return (this * q.conj) / q.sumOfSquare;
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "+", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst.a += s;
        return dst;
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op  : "-", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst.a -= s;
        return dst;
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "*", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst._vec4 *= s;
        return dst;
    }


    Quaternion!(CommonType!(S, E)) opBinary(string op : "/", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst._vec4 /= s;
        return dst;
    }


    Quaternion!(CommonType!(S, E)) opBinaryRight(string op : "+", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst.a += s;
        return dst;
    }


    Quaternion!(CommonType!(S, E)) opBinaryRight(string op : "-", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        return quaternion!(CommonType!(S, E))(s) - this;
    }


    Quaternion!(CommonType!(S, E)) opBinaryRight(string op : "*", E)(in E s) const
    if(!is(CommonType!(S, E) == void))
    {
        typeof(return) dst;
        dst = this;
        dst._vec4 *= s;
        return dst;
    }


    auto opBinaryRight(string op : "/", E)(in E s) const
    if(isFloatingPoint!(CommonType!(S, E)))
    {
        return s / this.sumOfSquare * this.conj;
    }


    void opAssign(E)(in Quaternion!E q)
    if(is(E : S))
    {
        this._vec4 = q._vec4;
    }


    void opAssign(E)(in E s)
    if(is(E : S))
    {
        this._vec4 = 0;
        this.a = s;
    }


    void opOpAssign(string op, E)(in Quaternion!E q)
    if(!is(CommonType!(S, E) == void))
    {
        this = mixin("this " ~ op ~ " q");
    }


    void opOpAssign(string op, E)(in E s)
    if(is(E : S))
    {
        this = mixin("this " ~ op ~ " s");
    }


    void toString(scope void delegate(const(char)[]) sink, string formatString) const
    {
        formattedWrite(sink, formatString, _vec4.array);
    }


    bool opEquals(E)(auto ref const Quaternion!E q) pure nothrow @safe const
    {
        foreach(i; 0 .. 4)
            if(this[i] != q[i])
                return false;
        return true;
    }


  private:
    SCVector!(S, 4) _vec4 = [1, 0, 0, 0].matrix!(4, 1);
}


/// 
unittest {
    assert(Quaternion!int.init == quaternion(1, 0, 0, 0));
    // 1 = [1; (0, 0, 0)]な四元数の作成
    auto q = quaternion(1);

    // 添字によるアクセス
    assert(q[0] == 1);
    assert(q[1] == 0);
    assert(q[2] == 0);
    assert(q[3] == 0);


    // 1 + 2i + 3j + 4k = [1; (2, 3, 4)]な四元数の作成
    q = quaternion(1, 2, 3, 4);
    assert(q[0] == 1);
    assert(q[1] == 2);
    assert(q[2] == 3);
    assert(q[3] == 4);

    // a, b, c, dによるアクセス
    assert(q.a == 1);
    assert(q.b == 2);
    assert(q.c == 3);
    assert(q.d == 4);

    // スカラー部であるs, ベクトル部であるvによるアクセス
    assert(q.s == 1);
    assert(q.v == [2, 3, 4].matrix!(3, 1));

    // v = (i, j, k)
    assert(q.i == 2);
    assert(q.j == 3);
    assert(q.k == 4);

    // opIndexやa, b, c, d, i, j, k, s, vへは代入可能
    q.s = 7;
    assert(q[0] == 7);

    // vはベクトルなので、ベクトルを代入可能
    q.v = [4, 5, 6].matrix!(3, 1);
    assert(q[1] == 4);
    assert(q[2] == 5);
    assert(q[3] == 6);

    // スカラー部とベクトル部による四元数の作成
    q = quaternion(8, [9, 10, 11].matrix!(3, 1));
    assert(q[0] == 8);
    assert(q[1] == 9);
    assert(q[2] == 10);
    assert(q[3] == 11);


    // 和
    q = quaternion(1, 2, 3, 4) + quaternion(2, 2, 2, 2);
    assert(q == quaternion(3, 4, 5, 6));

    q = q + 3;
    assert(q == quaternion(6, 4, 5, 6));

    q = 3 + q;
    assert(q == quaternion(9, 4, 5, 6));

    // 複合代入和
    q += q;
    assert(q == quaternion(18, 8, 10, 12));

    q += 3;
    assert(q == quaternion(21, 8, 10, 12));


    // 差
    q = quaternion(1, 2, 3, 4) - quaternion(2, 2, 2, 2);
    assert(q == quaternion(-1, 0, 1, 2));

    q = q - 3;
    assert(q == quaternion(-4, 0, 1, 2));

    q = 3 - q;
    assert(q == quaternion(7, 0, -1, -2));

    // 複合代入和
    q -= q;
    assert(q == quaternion(0, 0, 0, 0));

    q -= 3;
    assert(q == quaternion(-3, 0, 0, 0));


    // 積
    q = quaternion(1, 2, 3, 4) * quaternion(7, 6, 7, 8);
    assert(q == quaternion(-58, 16, 36, 32));

    q = quaternion(1, 2, 3, 4) * 4;
    assert(q == quaternion(4, 8, 12, 16));

    q = 4 * quaternion(1, 2, 3, 4);
    assert(q == quaternion(4, 8, 12, 16));

    q = quaternion(1, 2, 3, 4);
    q *= quaternion(7, 6, 7, 8);
    assert(q == quaternion(-58, 16, 36, 32));

    q = quaternion(1, 2, 3, 4);
    q *= 4;
    assert(q == quaternion(4, 8, 12, 16));


    // 商
    assert((quaternion(-58.0, 16, 36, 32) / quaternion(7, 6, 7, 8)).approxEqual(quaternion(1, 2, 3, 4)));
    assert(quaternion(4.0, 8, 12, 16) / 4 == quaternion(1, 2, 3, 4));
    assert((16.0 / quaternion(1.0, 2, 3, 4)).approxEqual(quaternion(16.0) / quaternion(1.0, 2, 3, 4)));
    auto p = quaternion(-58.0, 16, 36, 32);
    p /= quaternion(7, 6, 7, 8);
    assert(p.approxEqual(quaternion(1, 2, 3, 4)));

    p = quaternion(4.0, 8, 12, 16);
    p /= 4;
    assert(p.approxEqual(quaternion(1, 2, 3, 4)));
}


/**
四元数の各要素の自乗和を返します
*/
auto sumOfSquare(E)(in Quaternion!E q)
{
    return q.a ^^ 2 + q.b ^^ 2 + q.c ^^ 2 + q.d ^^ 2;
}


/**
四元数の絶対値を返します
*/
auto abs(E)(in Quaternion!E q)
if(isFloatingPoint!E)
{
  static if(isFloatingPoint!E)
    return sqrt(q.sumOfSquare);
  else
    return sqrt(cast(real)q.sumOfSquare);
}


/**
四元数の共役を返します
*/
Quaternion!E conj(E)(in Quaternion!E q) pure nothrow @safe
{
    typeof(return) dst;
    dst.s = q.s;
    dst.v = q.v * -1;
    return dst;
}


/**
approxEqualの四元数バージョン
*/
bool approxEqual(alias pred = std.math.approxEqual, E1, E2)(in Quaternion!E1 q1, in Quaternion!E2 q2)
{
    foreach(i; 0 .. 4)
        if(!binaryFun!pred(q1[i], q2[i]))
            return false;
    return true;
}


/**
正規化します
*/
void normalizeInPlace(E)(ref Quaternion!E q)
if(isFloatingPoint!E)
{
    q._vec4 /= q.sumOfSquare;
}


/**
積の逆元
*/
auto inverse(E)(in Quaternion!E q)
{
  static if(!isFloatingPoint!S)
    return this.conj / cast(real)this.sumOfSquare;
  else
    return this.conj / this.sumOfSquare;
}


/**
スカラー部1, ベクトル部0な四元数
*/
auto zeroRotation(E = real)()
if(is(Quaternion!E))
{
    return Quaternion!E.init;
}


/**

*/
auto makeRotate(E = real)(E angle, E x, E y, E z) pure nothrow @safe
if(isFloatingPoint!E)
{
    enum epsilon = 0.0000001;

    immutable len = sqrt(x^^2 + y^^2 + z^^2);
    
    if(len < epsilon)
        return Quaternion!E.init;

    immutable cosHalf = cos(angle / 2),
              sinHalf = sin(angle / 2) / len;

    return quaternion(cosHalf, x * sinHalf,
                               y * sinHalf,
                               z * sinHalf);
}


auto makeRotate(E = real, V)(E angle, in V axis)
{
    return makeRotate!E(angle, axis[0], axis[1], axis[2]);
}


auto makeRotate(E = real, V1, V2, V3)(E angle1, in V1 axis1,
                                      E angle2, in V2 axis2,
                                      E angle3, in V3 axis3)
{
    return makeRotate(angle1, axis1) * makeRotate(angle2, axis2) * makeRotate(angle3, axis3);
}


/** Make a rotation Quat which will rotate vec1 to vec2

 This routine uses only fast geometric transforms, without costly acos/sin computations.
 It's exact, fast, and with less degenerate cases than the acos/sin method.

 For an explanation of the math used, you may see for example:
 http://logiciels.cnes.fr/MARMOTTES/marmottes-mathematique.pdf

 @note This is the rotation with shortest angle, which is the one equivalent to the
 acos/sin transform method. Other rotations exists, for example to additionally keep
 a local horizontal attitude.

 @author Nicolas Brodu
 */
Quaternion!E makeRotate(E = real, V1, V2)(in V1 from, in V2 to)
if(isFloatingPoint!E && is(typeof({SCVector!(E, 3) v; v = from; v = to;})))
{
    alias Vec = SCVector!(E, 3);

    Vec fromNormalized = from;
    Vec toNormalized = to;

    // This routine takes any vector as argument but normalized
    // vectors are necessary, if only for computing the dot product.
    // Too bad the API is that generic, it leads to performance loss.
    // Even in the case the 2 vectors are not normalized but same length,
    // the sqrt could be shared, but we have no way to know beforehand
    // at this point, while the caller may know.
    // So, we have to test... in the hope of saving at least a sqrt
    {
        immutable fromLen2 = fromNormalized.sumOfSquare;
        E fromLen;

        //if((fromLen2 < 1.0 - 1e-7) || (1.0 + 1e-7 < fromLen2)){
        if(!fromLen2.approxEqual(1.0, E.infinity, 1e-7)){
            fromLen = sqrt(fromLen2);
            fromNormalized /= fromLen;
        }else
            fromLen = 1.0;

        immutable toLen2 = to.sumOfSquare;

        if(!toLen2.approxEqual(1.0, E.infinity, 1e-7)){
            E toLen;

            //if((fromLen2 - 1e-7 < toLen2) && (toLen2 < fromLen2 + 1e-7))
            if(toLen2.approxEqual(fromLen2, E.infinity, 1e-7))
                toLen = fromLen;
            else
                toLen = sqrt(toLen2);

            toNormalized /= toLen;
        }
    }

    {
        // Now let's get into the real stuff
        // Use "dot product plus one" as test as it can be re-used later on

        immutable dotProdPlus1 = 1.0 + fromNormalized.dot(toNormalized);

        // Check for degenerate case of full u-turn. Use epsilon for detection
        if(dotProdPlus1 < 1e-7){

            // Get an orthogonal vector of the given vector
            // in a plane with maximum vector coordinates.
            // Then use it as quaternion axis with pi angle
            // Trick is to realize one value at least is >0.6 for a normalized vector.
            if(fromNormalized.x.abs < 0.6){
                immutable norm = sqrt(1.0 - fromNormalized.x ^^ 2);
                return Quaternion!E(0.0, 0.0, fromNormalized.z / norm, -fromNormalized.y / norm);
            }else if(fromNormalized.y.abs < 0.6){
                immutable norm = sqrt(1.0 - fromNormalized.y ^^ 2);
                return Quaternion!E(0.0, -fromNormalized.z / norm, 0.0, fromNormalized.x / norm);
            }else{
                immutable norm = sqrt(1.0 - fromNormalized.z ^^ 2);
                return Quaternion!E(0.0, fromNormalized.y / norm, -fromNormalized.x / norm, 0.0);
            }
        }else{
            // Find the shortest angle quaternion that transforms normalized vectors
            // into one other. Formula is still valid when vectors are colinear
            immutable s = sqrt(0.5 * dotProdPlus1);
            return Quaternion!E(s, fromNormalized.cross(toNormalized) / (2.0 * s));
        }
    }
}


/**
Quaternionの回転成分を返します
*/
auto rotation(E)(in Quaternion!E q) @property
{
    alias ReturnType = Tuple!(E, "angle",
                              SCVector!(E, 3), "axis");

    E x, y, z, angle;
    q.getRotate(angle, x, y, z);

    return ReturnType(angle, SCVector!(E, 3)([x, y, z]));
}


/**
Quaternionによって表される回転成分を取得します
*/
void getRotation(E, F)(in Quaternion!E q, out E angle, out E x, out E y, out E z)
{
    E sinHalfAngle = sqrt(q.x ^^ 2 + q.y ^^ 2 + q.z ^^ 2);

    angle = (atan2(sinHalfAngle, q.w) * 2).toDeg;

    if(sinHalfAngle){
        x = q.x / sinHalfAngle;
        y = q.y / sinHalfAngle;
        z = q.z / sinHalfAngle;
    }else{
        x = 0;
        y = 0;
        z = 1;
    }
}


/**
fromとtoのQuaternionを補間したQuaternionを返します
*/
Quaternion!E slerp(E, F)(float t, in Quaternion!E from, in Quaternion!F to)
{
    enum epsilon = 0.00001;

    auto quatTo = to,
         cosomega = from.asVec4.dot(to.asVec4);

    if(cosomega < 0){
        cosomega = -cosomega;
        quatTo = -to;
    }

    real scaleFrom, scaleTo;
    if((1 - cosomega) > epsilon){
        immutable omega = acos(cosomega),
                  sinOmega = sin(omega),
                  scaleFrom = sin((1.0 - t) * omega) / sinOmega,
                  scaleTo = sin(t * omega) / sinOmega;

        return from * scaleFrom + quatTo * scaleTo;
    }else
        return from * (1 - t) + to * t;
}


E[3] eulerAngle(E)(in Quaternion!E q) @property
{
    immutable test = q.x * q.y + q.z * q.w;

    real h, a, b;
    if(test > 0.499){
        h = 2 * atan2(q.x, q.w);
        a = std.math.PI / 2;
        b = 0;
    }else if(test < -0.499){
        h = -2 * atan2(q.x, q.w);
        a = - std.math.PI / 2;
        b = 0;
    }else{
        immutable yw = q.y * q.w,
                  xz = q.x * q.z,
                  xw = q.x * q.w,
                  yz = q.y * q.z,
                  xx = q.x ^^ 2,
                  yy = q.y ^^ 2,
                  zz = q.z ^^ 2;

        h = atan2(2 * (yw - xz), 1 - 2 * (yy + zz));
        a = asin(2 * test);
        b = atan2(2 * (xw - yz), 1 - 2 * (xx + zz));
    }

    return [a, h, b];
}
