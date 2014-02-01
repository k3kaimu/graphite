/**
Boost::uBlas目指そうと思ったけどuBlasそんなに使ったことないし、
じゃあ独自的な方向でいこうって感じのExpression Templateを使った行列ライブラリ。

特徴は
・ET使ってるから遅延評価してるらしい
・ET使ってるからコンパイラ酷使するらしい
・静的大きさと動的大きさの行列の両方を表現できるらしい
・identityとかonesとか、特殊な行列はそもそも大きさを持たないらしい
・疎行列とかそういう特殊行列も入れたいらしい
・そんな時間ない気がするらしい
・とにかく、現時点ではコア機能しか使えないらしい
・開発動機は「面白そう」。
・実行速度ってどうしたら速くなるのか開発者はしらないらしい
    開発者は趣味でプログラミングしてるから、本気で数値計算を勉強したこと無いらしい
・素直にBLAS, LAPACKをつかいましょう。

TODO:
共役転置

型としての行列の種別
    帯行列, 対称行列, エルミート行列, 疎行列,

高速化とか
・Blas


Author: Kazuki Komatsu

License: NYSL
*/

module graphite.math.linear;

import std.algorithm,
       std.array,
       std.ascii,
       std.conv,
       std.exception,
       std.format,
       std.functional,
       std.math,
       std.range,
       std.traits,
       std.typecons,
       std.string,
       std.typetuple;

version(unittest) import std.stdio;



/**
四則演算が定義されている型であればtrueとなる
*/
template isScalar(T)
{
    enum bool isScalar = is(typeof(
        (T a){
            {auto _t1 = a + a;}
            {auto _t1 = a - a;}
            {auto _t1 = a * a;}
            {auto _t1 = a / a;}

            bool b = a == a;
        }));
}

///
unittest{
    import std.bigint, std.numeric, std.typetuple;

    alias TT = TypeTuple!(ubyte, ushort, uint, ulong,
                           byte,  short,  int,  long,
                          float, double, real/*,
                          creal, cfloat, cdouble*/);

    foreach(T; TT)
    {
        static assert(isScalar!(T));
        static assert(isScalar!(const(T)));
        static assert(isScalar!(immutable(T)));
    }

    static assert(isScalar!BigInt);
    // static assert(isScalar!(CustomFloat!16)); In dmd2.064, isScalar!(CustomFloat!16) is true.
}


/**
行列の格納方式
*/
enum Major{
    row,
    column,
}

/**
デフォルトでの行列の格納方式は「行優先」です。
*/
enum defaultMajor = Major.row;

alias Msize_t = ptrdiff_t;

enum Msize_t wild = -2,
             dynamic = -1;

/**
行列型かどうかを判定します
*/
template isNarrowMatrix(T)
{
    enum bool isNarrowMatrix = is(typeof((const T m){
            size_t rsize = m.rows;
            size_t csize = m.cols;

            auto e = m[0, 0];
        }));
}

///
unittest{
    static struct S
    {
        enum rows = 1;
        enum cols = 1;

        auto opIndex(size_t i, size_t j) const
        {
            return i + j;
        }
    }

    static assert(isNarrowMatrix!S);
}

///
unittest{
    static struct S
    {
        enum rows = 0;
        enum cols = 0;

        auto opIndex(size_t i, size_t j) const
        {
            return i + j;
        }
    }

    static assert(isNarrowMatrix!S);
}

///
unittest{
    import std.bigint, std.typetuple;
    alias TT = TypeTuple!(ubyte, ushort, uint, ulong,
                           byte,  short,  int,  long,
                          float, double, real,
                          creal, cfloat, cdouble/*,*/
                          /*BigInt*/);

    static struct M(T, size_t r, size_t c)
    {
        enum rows = r;
        enum cols = c;

        auto opIndex(size_t i, size_t j) const {return T.init;}
    }

    foreach(T; TT)
    {
        static assert(isNarrowMatrix!(M!(T, 3, 3)));
        static assert(isNarrowMatrix!(M!(const(T), 3, 3)));
        static assert(isNarrowMatrix!(M!(immutable(T), 3, 3)));
    }
}


/**
行の大きさが静的な行列型かどうか判定します
*/
template hasStaticRows(T)
{
    enum bool hasStaticRows = is(typeof({
            enum rsize = T.rows;
            static assert(rsize > 0);
        }));
}


/**
列の大きさが静的な行列型かどうか判定します
*/
template hasStaticColumns(T)
{
    enum bool hasStaticColumns = is(typeof({
            enum csize = T.cols;
            static assert(csize > 0);
        }));
}


/**
大きさが静的なベクトル型かどうか判定します
*/
template hasStaticLength(T)
{
    enum bool hasStaticLength = is(typeof({
            enum size = T.length;
            static assert(size > 0);
        }));
}


/**
行の大きさが動的な行列型かどうか判定します
*/
template hasDynamicRows(T)
{
    enum bool hasDynamicRows = !is(typeof({
            enum rsize = T.rows;
        }));
}


/**
列の大きさが動的な行列型かどうか判定します
*/
template hasDynamicColumns(T)
{
    enum bool hasDynamicColumns = !is(typeof({
            enum csize = T.cols;
        }));
}


/**
大きさが動的なベクトル型かどうか判定します
*/
template hasDynamicLength(T)
{
    enum bool hasDynamicLength = !is(typeof({
            enum size = T.length;
        }));
}


/**
大きさが推論される行列が、推論結果を返す際の結果の型です。
*/
struct InferredResult
{
    bool isValid;
    size_t rows;
    size_t cols;
}


/**
大きさが推論される行列かどうか判定します
*/
template isInferableMatrix(T)
{
    enum bool isInferableMatrix = isNarrowMatrix!T && is(typeof((T t){
            static assert(T.rows == wild);
            static assert(T.cols == wild);

            enum InferredResult result = T.inferSize(wild, wild);

            static if(result.isValid)
            {
                enum inferredRows = result.rows;
                enum inferredCols = result.cols;
            }

            enum someValue = 4; //非負の整数
            static assert(!T.inferSize(wild, wild).isValid);
            static assert(T.inferSize(wild, someValue).isValid);
            static assert(T.inferSize(wild, someValue).isValid);
        }));
}


/**
ベクトル型かどうか判定します
*/
template isNarrowVector(V)
{
    enum isNarrowVector = isNarrowMatrix!V && !isInferableMatrix!V
                 && is(typeof((const V v){
                        static if(hasStaticRows!V)
                        {
                            static if(hasStaticColumns!V)
                                static assert(V.rows == 1 || V.cols == 1);
                            else
                                static assert(V.rows == 1);
                        }
                        else
                            static assert(V.cols == 1);

                        size_t size = v.length;

                        auto a = v[0, 0];
                        auto b = v[0];
                        static assert(is(typeof(a) == typeof(b)));
                    }));
}
unittest{
    static struct V
    {
        enum rows = 1;
        enum cols = 3;
        enum length = 3;

        auto opIndex(size_t i, size_t j) const {return j;}
        auto opIndex(size_t i) const {return i;}
    }

    static assert(isNarrowVector!V);
}


/**
ベクトル型かどうか判定します
*/
template isVector(V)
{
    enum isVector = is(typeof((const V v){
                        foreach(i; 0 .. v.length)
                            auto a = v[i];
                    }));
}
unittest{
    static struct V
    {
        enum length = 3;
        auto opIndex(size_t i) const {return i;}
    }

    static assert(isVector!V);
}


/**
ベクトルを、行列ベクトル型へ変換します
*/
auto toMatrixVector(Major major = defaultMajor, V)(V v)
if(isVector!V && !isNarrowVector!V)
{
    static struct Result()
    {
      static if(major == Major.row)
      {
        enum rows = 1;

        static if(hasStaticLength!V)
            enum cols = V.length;
        else
            @property size_t cols() const { return _v.length; }
      }
      else
      {
        enum cols = 1;

        static if(hasStaticLength!V)
            enum rows = V.length;
        else
            @property size_t rows() const { return _v.length; }
      }

        @property auto ref length() const { return _v.length; }
        alias opDollar = length;

        auto ref opIndex(size_t i) inout
        in{
            assert(i < length);
        }
        body{
            return _v[i];
        }


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _v[i+j];
        }


        mixin(defaultExprOps!(true));

      private:
        V _v;
    }


    return Result!()(v);
}


/**
行列型の要素の型を取得します
*/
template ElementType(A) if(isNarrowMatrix!A)
{
    alias typeof(A.init[0, 0]) ElementType;
}

///
unittest{
    static struct S
    {
        enum rows = 1;
        enum cols = 1;

        int opIndex(size_t, size_t) const
        {
            return 1;
        }
    }

    static assert(is(ElementType!S == int));
}


/**
その行列の要素がstd.algorithm.swapを呼べるかどうかをチェックします
*/
template hasLvalueElements(A)if(isNarrowMatrix!A)
{
    enum hasLvalueElements = is(typeof((A a){
            import std.algorithm : swap;

            swap(a[0, 0], a[0, 0]);
        }));
}

///
unittest{
    static struct M
    {
        enum rows = 1;
        enum cols = 1;

        ref int opIndex(size_t i, size_t j) inout
        {
            static int a;
            return a;
        }
    }

    static assert(hasLvalueElements!(M));
}


/**
A型の行列の要素にElementType!A型の値が代入可能かどうかをチェックします。
*/
template hasAssignableElements(A)if(isNarrowMatrix!A)
{
    enum hasAssignableElements = is(typeof((A a){
            ElementType!A e;
            a[0, 0] = e;
        }));
}
unittest{
    static struct M
    {
        enum rows = 1;
        enum cols = 1;

        auto opIndex(size_t i, size_t j) const
        {
            return i;
        }

        void opIndexAssign(typeof(this[0, 0]) a, size_t i, size_t j){}
    }

    static assert(hasAssignableElements!(M));
}


/**
aとbが等しいか、もしくはどちらかが0であるとtrueとなります。
2つの行列が演算可能かどうかを判定するのに使います。
*/
private bool isEqOrEitherEqX(alias pred = "a == b", T, X = T)(T a, T b, X x = 0)
{
    return binaryFun!pred(a, b) || a == x || b == x;
}

///
unittest{
    static assert(isEqOrEitherEqX(0, 0));
    static assert(isEqOrEitherEqX(1, 1));
    static assert(isEqOrEitherEqX(0, 1));
    static assert(isEqOrEitherEqX(1, 0));
}



/**
正しい演算かどうか判定します

Example:
----
static struct S(T, size_t r, size_t c){enum rows = r; enum cols = c; T opIndex(size_t i, size_t j) const {return T.init;}}
alias Static1x1 = S!(int, 1, 1);
alias Static1x2 = S!(int, 1, 2);
alias Static2x1 = S!(int, 2, 1);
alias Static2x2 = S!(int, 2, 2);

static struct D(T){size_t rows = 1, cols = 1; T opIndex(size_t i, size_t j) const {return T.init;}}
alias Dynamic = D!(int);

static struct I(T){
    enum rows = 0, cols = 0;
    T opIndex(size_t i, size_t j) const { return T.init; }
    static InferredResult inferSize(size_t rs, size_t cs){
        if(rs == 0 && cs == 0)
            return InferredResult(false, 0, 0);
        else if(rs == 0 || cs == 0)
            return InferredResult(true, max(rs, cs), max(rs, cs));
        else
            return InferredResult(true, rs, cs);
    }
}
alias Inferable = I!int;
static assert(Inferable.inferSize(1, 0).isValid);

alias T = Inferable;
static assert(T.rows == wild);
static assert(T.cols == wild);


static assert( isValidOperator!(Static1x1, "+", Static1x1));
static assert(!isValidOperator!(Static1x1, "+", Static1x2));
static assert( isValidOperator!(Static1x2, "+", Static1x2));
static assert(!isValidOperator!(Static1x2, "+", Static1x1));

static assert( isValidOperator!(Static1x1, "+", Dynamic));
static assert( isValidOperator!(Static1x2, "+", Dynamic));
static assert( isValidOperator!(Dynamic, "+", Static1x1));
static assert( isValidOperator!(Dynamic, "+", Static1x2));

static assert( isValidOperator!(Static1x1, "+", Inferable));
static assert( isValidOperator!(Static1x2, "+", Inferable));
static assert( isValidOperator!(Inferable, "+", Static1x1));
static assert( isValidOperator!(Inferable, "+", Static1x2));

static assert( isValidOperator!(Static1x1, "*", Static1x1));
static assert( isValidOperator!(Static1x1, "*", Static1x2));
static assert(!isValidOperator!(Static1x2, "*", Static1x2));
static assert(!isValidOperator!(Static1x2, "*", Static1x1));

static assert( isValidOperator!(Static1x1, "*", Dynamic));
static assert( isValidOperator!(Static1x2, "*", Dynamic));
static assert( isValidOperator!(Dynamic, "*", Static1x1));
static assert( isValidOperator!(Dynamic, "*", Static1x2));

static assert( isValidOperator!(Static1x1, "*", Inferable));
static assert( isValidOperator!(Static1x2, "*", Inferable));
static assert( isValidOperator!(Inferable, "*", Static1x1));
static assert( isValidOperator!(Inferable, "*", Static1x2));
----
*/
template isValidOperator(L, string op, R)
{
    static if(isNarrowMatrix!L && isNarrowMatrix!R)
        enum isValidOperator = is(typeof(mixin("L.init[0, 0] " ~ op ~ " R.init[0, 0]"))) && isValidOperatorImpl!(L, op, R);
    else static if(isNarrowMatrix!L)
        enum isValidOperator = is(typeof(mixin("L.init[0, 0] " ~ op ~ " R.init"))) && isValidOperatorImpl!(L, op, R);
    else static if(isNarrowMatrix!R)
        enum isValidOperator = is(typeof(mixin("L.init " ~ op ~ " R.init[0, 0]"))) && isValidOperatorImpl!(L, op, R);
    else
        static assert(0);
}


template isValidOperatorImpl(L, string op, R)
if(isNarrowMatrix!L && isNarrowMatrix!R && op != "*")
{
    struct Inferred(M, size_t r, size_t c)
    {
        enum size_t rows = M.inferSize(r, c).rows;
        enum size_t cols = M.inferSize(r, c).cols;

        auto opIndex(size_t i, size_t j) const { return ElementType!M.init; }
    }

    static if(op != "+" && op != "-")
        enum isValidOperatorImpl = false;
    else static if(isInferableMatrix!L && isInferableMatrix!R)
        enum isValidOperatorImpl = true;
    else static if(isInferableMatrix!L)
    {
        static if(hasStaticRows!R && hasStaticColumns!R)
            enum isValidOperatorImpl = L.inferSize(R.rows, R.cols).isValid && isValidOperatorImpl!(Inferred!(L, R.rows, R.cols), op, R);
        else static if(hasStaticRows!R)
            enum isValidOperatorImpl = L.inferSize(R.rows, wild).isValid && isValidOperatorImpl!(Inferred!(L, R.rows, wild), op, R);
        else static if(hasStaticColumns!R)
            enum isValidOperatorImpl = L.inferSize(wild, R.cols).isValid && isValidOperatorImpl!(Inferred!(L, wild, R.cols), op, R);
        else
            enum isValidOperatorImpl = true;
    }
    else static if(isInferableMatrix!R)
        enum isValidOperatorImpl = isValidOperatorImpl!(R, op, L);
    else
    {
        static if(hasStaticRows!L)
        {
            static if(hasStaticRows!R)
                enum _isValidR = L.rows == R.rows;
            else
                enum _isValidR = true;
        }
        else
            enum _isValidR = true;

        static if(hasStaticColumns!L)
        {
            static if(hasStaticColumns!R)
                enum _isValidC = L.cols == R.cols;
            else
                enum _isValidC = true;
        }
        else
            enum _isValidC = true;

        enum isValidOperatorImpl = _isValidR && _isValidC;
    }
}


template isValidOperatorImpl(L, string op, R)
if(isNarrowMatrix!L && isNarrowMatrix!R && op == "*")
{
    struct Inferred(M, size_t r, size_t c)
    if(r == wild || c == wild)
    {
        enum size_t rows = M.inferSize(r, c).rows;
        enum size_t cols = M.inferSize(r, c).cols;

        auto opIndex(size_t i, size_t j) const { return M.init[i, j]; }
    }


    static if(isInferableMatrix!L && isInferableMatrix!R)
        enum isValidOperatorImpl = false;
    else static if(isInferableMatrix!L)
    {
        static if(hasStaticRows!R)
            enum isValidOperatorImpl = isValidOperatorImpl!(Inferred!(L, wild, R.rows), op, R);
        else
            enum isValidOperatorImpl = true;
    }
    else static if(isInferableMatrix!R)
    {
        static if(hasStaticColumns!L)
            enum isValidOperatorImpl = isValidOperatorImpl!(L, op, Inferred!(R, L.cols, wild));
        else
            enum isValidOperatorImpl = true;
    }
    else
    {
        static if(hasStaticColumns!L && hasStaticRows!R)
            enum isValidOperatorImpl = L.cols == R.rows;
        else
            enum isValidOperatorImpl = true;
    }
}


template isValidOperatorImpl(L, string op, R)
if((isNarrowMatrix!L && !isNarrowMatrix!R) || (isNarrowMatrix!R && !isNarrowMatrix!L))
{
    static if(op != "+" && op != "-" && op != "*" && op != "/")
        enum isValidOperatorImpl = false;
    else
        enum isValidOperatorImpl = true;
}


unittest{
    static struct S(T, size_t r, size_t c){enum rows = r; enum cols = c; T opIndex(size_t i, size_t j) const {return T.init;}}
    alias Static1x1 = S!(int, 1, 1);
    alias Static1x2 = S!(int, 1, 2);
    alias Static2x1 = S!(int, 2, 1);
    alias Static2x2 = S!(int, 2, 2);

    static struct D(T){size_t rows = 1, cols = 1; T opIndex(size_t i, size_t j) const {return T.init;}}
    alias Dynamic = D!(int);

    static struct I(T){
        enum rows = wild;
        enum cols = wild;
        T opIndex(size_t i, size_t j) const { return T.init; }

        static InferredResult inferSize(Msize_t rs, Msize_t cs){
            if(rs == wild && cs == wild)
                return InferredResult(false, 0, 0);
            else if(rs == wild || cs == wild)
                return InferredResult(true, max(rs, cs), max(rs, cs));
            else
                return InferredResult(true, rs, cs);
        }
    }
    alias Inferable = I!int;
    static assert(Inferable.inferSize(1, wild).isValid);

    alias T = Inferable;
    static assert(T.rows == wild);
    static assert(T.cols == wild);


    static assert( isValidOperator!(Static1x1, "+", Static1x1));
    static assert(!isValidOperator!(Static1x1, "+", Static1x2));
    static assert( isValidOperator!(Static1x2, "+", Static1x2));
    static assert(!isValidOperator!(Static1x2, "+", Static1x1));

    static assert( isValidOperator!(Static1x1, "+", Dynamic));
    static assert( isValidOperator!(Static1x2, "+", Dynamic));
    static assert( isValidOperator!(Dynamic, "+", Static1x1));
    static assert( isValidOperator!(Dynamic, "+", Static1x2));

    static assert( isValidOperator!(Static1x1, "+", Inferable));
    static assert( isValidOperator!(Static1x2, "+", Inferable));
    static assert( isValidOperator!(Inferable, "+", Static1x1));
    static assert( isValidOperator!(Inferable, "+", Static1x2));

    static assert( isValidOperator!(Static1x1, "*", Static1x1));
    static assert( isValidOperator!(Static1x1, "*", Static1x2));
    static assert(!isValidOperator!(Static1x2, "*", Static1x2));
    static assert(!isValidOperator!(Static1x2, "*", Static1x1));

    static assert( isValidOperator!(Static1x1, "*", Dynamic));
    static assert( isValidOperator!(Static1x2, "*", Dynamic));
    static assert( isValidOperator!(Dynamic, "*", Static1x1));
    static assert( isValidOperator!(Dynamic, "*", Static1x2));

    static assert( isValidOperator!(Static1x1, "*", Inferable));
    static assert( isValidOperator!(Static1x2, "*", Inferable));
    static assert( isValidOperator!(Inferable, "*", Static1x1));
    static assert( isValidOperator!(Inferable, "*", Static1x2));
}


/**
式テンプレート演算子の種類
*/
enum ETOSpec : size_t
{
    none = 0,
    matrixAddMatrix = (1 << 0),
    matrixSubMatrix = (1 << 1),
    matrixMulMatrix = (1 << 2),
    matrixAddScalar = (1 << 3),
    scalarAddMatrix = (1 << 4),
    matrixSubScalar = (1 << 5),
    scalarSubMatrix = (1 << 6),
    matrixMulScalar = (1 << 7),
    scalarMulMatrix = (1 << 8),
    matrixDivScalar = (1 << 9),
    scalarDivMatrix = (1 << 10),
    addScalar = (1 << 11),
    subScalar = (1 << 12),
    mulScalar = (1 << 13),
    divScalar = (1 << 14),
    opEquals = (1 << 15),
    toString = (1 << 16),
    opAssign = (1 << 17),
    swizzle = (1 << 18),
    modifiedOperator = addScalar | subScalar | mulScalar | divScalar | opAssign,
    all = (1 << 19) -1,
}


/**
式テンプレートでの演算子の種類を返します
*/
template ETOperatorSpec(A, string op, B)
if(isValidOperator!(A, op, B))
{
    static if(isNarrowMatrix!A && isNarrowMatrix!B)
        enum ETOSpec ETOperatorSpec = op == "+" ? ETOSpec.matrixAddMatrix
                                                : (op == "-" ? ETOSpec.matrixSubMatrix
                                                             : ETOSpec.matrixMulMatrix);
    else static if(isScalar!A)
        enum ETOSpec ETOperatorSpec = op == "+" ? ETOSpec.scalarAddMatrix
                                                : (op == "-" ? ETOSpec.scalarSubMatrix
                                                             : (op == "*" ? ETOSpec.scalarMulMatrix
                                                                          : ETOSpec.scalarDivMatrix));
    else
        enum ETOSpec ETOperatorSpec = op == "+" ? ETOSpec.matrixAddScalar
                                                : (op == "-" ? ETOSpec.matrixSubScalar
                                                             : (op == "*" ? ETOSpec.matrixMulScalar
                                                                          : ETOSpec.matrixDivScalar));
}

///
unittest{
    static struct S(T, size_t r, size_t c){enum rows = r; enum cols = c; T opIndex(size_t i, size_t j) const {return T.init;}}
    alias Matrix2i = S!(int, 2, 2);

    static assert(ETOperatorSpec!(Matrix2i, "+", Matrix2i) == ETOSpec.matrixAddMatrix);
    static assert(ETOperatorSpec!(Matrix2i, "-", Matrix2i) == ETOSpec.matrixSubMatrix);
    static assert(ETOperatorSpec!(Matrix2i, "*", Matrix2i) == ETOSpec.matrixMulMatrix);
    static assert(ETOperatorSpec!(Matrix2i, "*", int) == ETOSpec.matrixMulScalar);
    static assert(ETOperatorSpec!(int, "*", Matrix2i) == ETOSpec.scalarMulMatrix);
}


/**
式テンプレートでの、式を表します
*/
struct MatrixExpression(Lhs, string s, Rhs)
if(isValidOperator!(Lhs, s, Rhs) && (isInferableMatrix!Lhs && isInferableMatrix!Rhs) || (isInferableMatrix!Lhs && !isNarrowMatrix!Rhs) || (!isNarrowMatrix!Lhs && isInferableMatrix!Rhs))
{
    enum rows = wild;
    enum cols = wild;
    enum etoSpec = ETOperatorSpec!(Lhs, s, Rhs);


    static InferredResult inferSize(Msize_t r, Msize_t c)
    {
        static if(isInferableMatrix!Lhs && isInferableMatrix!Rhs)
        {
            static assert(s != "*");
            auto rLhs = Lhs.inferSize(r, c);
            auto rRhs = Rhs.inferSize(r, c);

            bool b = rLhs.isValid && rRhs.isValid && rLhs.rows == rRhs.rows && rLhs.cols == rRhs.cols;
            return InferredResult(b, rLhs.rows, rLhs.cols);
        }
        else static if(isInferableMatrix!Lhs)
            return Lhs.inferSize(r, c);
        else
            return Rhs.inferSize(r, c);
    }


    auto opIndex(size_t i, size_t j) const
    {
      static if(etoSpec == ETOSpec.matrixAddMatrix)
        return this.lhs[i, j] + this.rhs[i, j];
      else static if(etoSpec == ETOSpec.matrixSubMatrix)
        return this.lhs[i, j] - this.rhs[i, j];
      else static if(etoSpec == ETOSpec.matrixMulMatrix)
      {
        static assert(0);
        return typeof(this.lhs[0, 0] + this.rhs[0, 0]).init;
      }
      else
      {
        static if(isNarrowMatrix!Lhs)
            return mixin("this.lhs[i, j] " ~ s ~ " this.rhs");
        else
            return mixin("this.lhs " ~ s ~ " this.rhs[i, j]");
      }
    }


    mixin(defaultExprOps!(true));

  private:
    Lhs lhs;
    Rhs rhs;
}


/// ditto
struct MatrixExpression(Lhs, string s, Rhs)
if(isValidOperator!(Lhs, s, Rhs) && !((isInferableMatrix!Lhs && isInferableMatrix!Rhs) || (isInferableMatrix!Lhs && !isNarrowMatrix!Rhs) || (!isNarrowMatrix!Lhs && isInferableMatrix!Rhs)))
{
    enum etoSpec = ETOperatorSpec!(Lhs, s, Rhs);


    static if(isNarrowMatrix!Lhs && isNarrowMatrix!Rhs)
    {
        static if(s == "*")
        {
            static if(hasStaticRows!Lhs)
            {
                enum rows = Lhs.rows;
                private enum staticrows = rows;
            }
            else static if(isInferableMatrix!Lhs && hasStaticRows!Rhs)
            {
                enum rows = Lhs.inferSize(wild, Rhs.rows).rows;
                private enum staticrows = rows;
            }
            else static if(hasDynamicRows!Lhs)
            {
                @property size_t rows() const { return this.lhs.rows; }
                private enum staticrows = wild;
            }
            else static if(isInferableMatrix!Lhs && hasDynamicRows!Rhs)
            {
                @property size_t rows() const { return this.lhs.inferSize(wild, rhs.rows).rows; }
                private enum staticrows = wild;
            }
            else
                static assert(0);


            static if(hasStaticColumns!Rhs)
            {
                enum cols = Rhs.cols;
                private enum staticcols = cols;
            }
            else static if(isInferableMatrix!Rhs && hasStaticColumns!Lhs)
            {
                enum cols = Rhs.inferSize(Lhs.cols, wild).cols;
                private enum staticcols = cols;
            }
            else static if(hasDynamicRows!Rhs)
            {
                @property size_t cols() const { return this.rhs.cols; }
                private enum staticcols = wild;
            }
            else static if(isInferableMatrix!Rhs && hasDynamicColumns!Lhs)
            {
                @property size_t cols() const { return this.rhs.inferSize(lhs.cols, wild).cols; }
                private enum staticcols = wild;
            }
            else
                static assert(0);
        }
        else
        {
            static if(hasStaticRows!Lhs)
            {
                enum rows = Lhs.rows;
                private enum staticrows = rows;
            }
            else static if(hasStaticRows!Rhs)
            {
                enum rows = Rhs.rows;
                private enum staticrows = rows;
            }
            else static if(hasDynamicRows!Lhs)
            {
                @property size_t rows() const { return this.lhs.rows; }
                private enum staticrows = wild;
            }
            else
            {
                @property size_t rows() const { return this.rhs.rows; }
                private enum staticrows = wild;
            }

            static if(hasStaticColumns!Lhs)
            {
                enum cols = Lhs.cols;
                private enum staticcols = cols;
            }
            else static if(hasStaticColumns!Rhs)
            {
                enum cols = Rhs.cols;
                private enum staticcols = cols;
            }
            else static if(hasDynamicColumns!Lhs)
            {
                @property size_t cols() const { return this.lhs.cols; }
                private enum staticcols = wild;
            }
            else
            {
                @property size_t cols() const { return this.rhs.cols; }
                private enum staticcols = wild;
            }
        }
    }
    else static if(isNarrowMatrix!Lhs)
    {
        static assert(!isInferableMatrix!Lhs);

        static if(hasStaticRows!Lhs)
        {
            enum rows = Lhs.rows;
            private enum staticrows = rows;
        }
        else
        {
            @property size_t rows() const { return this.lhs.rows; }
            private enum staticrows = wild;
        }

        static if(hasStaticColumns!Lhs)
        {
            enum cols = Lhs.cols;
            private enum staticcols = cols;
        }
        else
        {
            @property size_t cols() const { return this.lhs.cols; }
            private enum staticcols = wild;
        }
    }
    else
    {
        static assert(!isInferableMatrix!Rhs);

        static if(hasStaticRows!Rhs)
        {
            enum rows = Rhs.rows;
            private enum staticrsght = rows;
        }
        else
        {
            @property size_t rows() const { return this.rhs.rows; }
            private enum staticrsght = wild;
        }

        static if(hasStaticColumns!Rhs)
        {
            enum cols = Rhs.cols;
            private enum staticcsght = cols;
        }
        else
        {
            @property size_t cols() const { return this.rhs.cols; }
            private enum staticcsght = wild;
        }
    }


    auto opIndex(size_t i, size_t j) const
    in{
        assert(i < this.rows);
        assert(j < this.cols);
    }
    body{
      static if(etoSpec == ETOSpec.matrixAddMatrix)
        return this.lhs[i, j] + this.rhs[i, j];
      else static if(etoSpec == ETOSpec.matrixSubMatrix)
        return this.lhs[i, j] - this.rhs[i, j];
      else static if(etoSpec == ETOSpec.matrixMulMatrix)
      {
        Unqual!(typeof(this.lhs[0, 0] * this.rhs[0, 0])) sum = 0;

        static if(hasStaticColumns!Lhs)
            immutable cnt = Lhs.cols;
        else static if(hasStaticRows!Rhs)
            immutable cnt = Rhs.rows;
        else static if(hasDynamicColumns!Lhs)
            immutable cnt = this.lhs.cols;
        else
            immutable cnt = this.rhs.rows;

        foreach(k; 0 .. cnt)
            sum += this.lhs[i, k] * this.rhs[k, j];
        return sum;
      }
      else
      {
        static if(isNarrowMatrix!Lhs)
            return mixin("this.lhs[i, j] " ~ s ~ " this.rhs");
        else
            return mixin("this.lhs " ~ s ~ " this.rhs[i, j]");
      }
    }


    mixin(defaultExprOps!(false));

  private:
    Lhs lhs;
    Rhs rhs;
}


/// ditto
auto matrixExpression(string s, A, B)(auto ref A a, auto ref B b)
if(isValidOperator!(A, s, B))
{
    return MatrixExpression!(A, s, B)(a, b);
    static assert(isNarrowMatrix!(MatrixExpression!(A, s, B)));
}


/**
specに示された演算子をオーバーロードします。specはETOSpecで指定する必要があります。
*/
template ExpressionOperators(size_t spec, size_t rs, size_t cs)
{
    enum stringMixin = 
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        static if(is(typeof({enum _unused_ = this.rows;}))) static assert(rows != 0);
        static if(is(typeof({enum _unused_ = this.cols;}))) static assert(cols != 0);

        alias rlength = cols;
        alias clength = rows;
    } ~


    ( rs == 1 ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        alias cols length;
        alias length opDollar;


        auto ref opIndex(size_t i) inout
        in{
            assert(i < this.cols);
        }
        body{
            return this[0, i];
        }

      static if(is(typeof({this[0, 0] = this[0, 0];})))
      {
        auto ref opIndexAssign(S)(S value, size_t i)
        if(is(typeof(this[0, i] = value)))
        in{
            assert(i < this.cols);
        }
        body{
            return this[0, i] = value;
        }


        auto ref opIndexOpAssign(string op, S)(S value, size_t i)
        if(is(typeof(mixin("this[0, i] " ~ op ~ "= value"))))
        in{
            assert(i < this.cols);
        }
        body{
            return mixin("this[0, i] " ~ op ~ "= value");
        }
      }
    } : ( cs == 1 ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        alias rows length;
        alias length opDollar;


        auto ref opIndex(size_t i) inout
        in{
            assert(i < this.rows);
        }
        body{
            return this[i, 0];
        }

      static if(is(typeof({this[0, 0] = this[0, 0];})))
      {
        auto ref opIndexAssign(S)(S value, size_t i)
        if(is(typeof(this[i, 0] = value)))
        in{
            assert(i < this.rows);
        }
        body{
            return this[0, i] = value;
        }


        auto ref opIndexOpAssign(string op, S)(S value, size_t i)
        if(is(typeof(mixin("this[i, 0] " ~ op ~ "= value"))))
        in{
            assert(i < this.rows);
        }
        body{
            return mixin("this[i, 0] " ~ op ~ "= value");
        }
      }
    } : ""
    )) ~


    ((rs == 1 || cs == 1) && (spec & ETOSpec.opAssign) ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opAssign(Array)(Array arr)
        if(!isNarrowMatrix!Array && is(typeof(arr[size_t.init])) && isAssignable!(typeof(this[size_t.init]), typeof(arr[size_t.init])))
        {
            foreach(i; 0 .. this.length)
                this[i] = arr[i];
        }
    } : ""
    ) ~


    (rs == 1 && cs == 1 ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto det() const @property
        {
            return this[0, 0];
        }

        alias det this;


        auto ref opAssign(S)(S value)
        if(is(typeof(this[0, 0] = value)))
        {
            return this[0, 0] = value;
        }


        auto ref opOpAssign(S)(S value)
        if(is(typeof(mixin("this[0, 0] " ~ op ~ "= value"))))
        {
            return mixin("this[0, 0] " ~ op ~ "= value");
        }
    } : ""
    ) ~


    (spec & ETOSpec.opEquals ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        bool opEquals(Rhs)(auto ref const Rhs mat) const
        if(isNarrowMatrix!Rhs)
        {
            static assert(isValidOperator!(Unqual!(typeof(this)), "+", Rhs));

            static if(isInferableMatrix!Rhs)
            {
                auto result = Rhs.inferSize(this.rows, this.cols);
                if(!result.isValid)
                    return false;
            }
            else
            {
                if(this.rows != mat.rows)
                    return false;

                if(this.cols != mat.cols)
                    return false;
            }

            foreach(i; 0 .. this.rows)
                foreach(j; 0 .. this.cols)
                    if(this[i, j] != mat[i, j])
                        return false;
            return true;
        }
    } : ""
    ) ~


    (spec & ETOSpec.toString ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        @property
        void toString(scope void delegate(const(char)[]) sink, string formatString) const @system
        {
            sink.formattedWrite(formatString, this.toRange);
        }
    } : ""
    ) ~


    (spec & ETOSpec.opAssign ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opAssign(M)(M m)
        if(isNarrowMatrix!M && is(typeof(this[0, 0] = m[0, 0])) && isValidOperator!(typeof(this), "+", M))
        in{
            static if(isInferableMatrix!M)
                assert(m.inferSize(this.rows, this.cols).isValid);
            else
            {
                assert(m.rows == this.rows);
                assert(m.cols == this.cols);
            }
        }
        body{
            foreach(i; 0 .. this.rows)
                foreach(j; 0 .. this.cols)
                    this[i, j] = m[i, j];
        }

        void opAssign(X)(X m)
        if(!isNarrowMatrix!X && is(typeof(m[size_t.init][size_t.init])) && is(typeof(this[size_t.init, size_t.init] = m[size_t.init][size_t.init])))
        {
            foreach(i; 0 .. this.rows)
                foreach(j; 0 .. this.cols)
                    this[i, j] = m[i][j];
        }

        void opAssign(X)(X m)
        if(!isNarrowMatrix!X && is(typeof(m[size_t.init, size_t.init])) && is(typeof(this[size_t.init, size_t.init] = m[size_t.init, size_t.init])))
        {
            foreach(i; 0 .. this.rows)
                foreach(j; 0 .. this.cols)
                    this[i, j] = m[i, j];
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixAddMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "+", Rhs)(auto ref Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(isInferableMatrix!Rhs)
                assert(mat.inferSize(this.rows, this.cols).isValid);
            else
            {
                assert(mat.rows == this.rows);
                assert(mat.cols == this.cols);
            }
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"+"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixSubMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "-", Rhs)(auto ref Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(isInferableMatrix!Rhs)
                assert(mat.inferSize(this.rows, this.cols).isValid);
            else
            {
                assert(mat.rows == this.rows);
                assert(mat.cols == this.cols);
            }
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"-"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixMulMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "*", Rhs)(auto ref Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(isInferableMatrix!Rhs)
                assert(mat.inferSize(this.cols, wild).isValid);
            else
                assert(mat.rows == this.cols);
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"*"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixAddScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "+", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"+"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarAddMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "+", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"+"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixSubScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "-", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"-"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarSubMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "-", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"-"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixMulScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "*", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"*"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarMulMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "*", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"*"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixDivScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "/", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"/"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarDivMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "/", S)(S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"/"(s, this);
        }
    } : ""
    ) ~ 


    (spec & ETOSpec.addScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "+", S)(S scalar)
        if(is(typeof(this[0, 0] += scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] +=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.subScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "-", S)(S scalar)
        if(is(typeof(this[0, 0] -= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] -=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.mulScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "*", S)(S scalar)
        if(is(typeof(this[0, 0] *= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] *=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.divScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "/", S)(S scalar)
        if(is(typeof(this[0, 0] /= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] /=  scalar;
        }
    } : ""
    ) ~


    ((spec & ETOSpec.swizzle) && (rs == 1 || cs == 1) ? 
        (rs*cs >= 1 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref a() inout @property { return this[0]; }
            alias x = a;
            alias r = a;
            alias re = a;
        } : ""
        ) ~ 
        (rs*cs >= 2 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref b() inout @property { return this[1]; }
            alias y = b;
            alias im = b;
            alias i = b;
        } : ""
        ) ~ 
        (rs*cs >= 3 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref c() inout @property { return this[2]; }
            alias z = c;
            alias j = c;
        } : ""
        ) ~ 
        (rs*cs >= 4 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref d() inout @property { return this[3]; }
            alias k = d;
            alias w = d;
        } : ""
        ) ~ 
        (rs*cs >= 5 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref e() inout @property { return this[4]; }
        } : ""
        ) ~ 
        (rs*cs >= 6 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref f() inout @property { return this[5]; }
        } : ""
        ) ~ 
        (rs*cs >= 7 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref g() inout @property { return this[6]; }
        } : ""
        ) ~ 
        (rs*cs >= 8 ?
        format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
        q{
            auto ref h() inout @property { return this[7]; }
        } : ""
        ) : ""
    );


    mixin template templateMixin()
    {
        mixin(stringMixin);
    }
}


/// ditto
template ExpressionOperatorsInferable(size_t spec)
{
    enum stringMixin = 
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        bool opEquals(Rhs)(auto ref in Rhs mat) const
        if(isNarrowMatrix!Rhs && !is(Unqual!Rhs == typeof(this)) && !isInferableMatrix!(Rhs))
        {
            static assert(isValidOperator!(Unqual!(typeof(this)), "+", Rhs));

            if(!this.inferSize(mat.rows, mat.cols).isValid)
                return false;

            foreach(i; 0 .. mat.rows)
                foreach(j; 0 .. mat.cols)
                    if(this[i, j] != mat[i, j])
                        return false;
            return true;
        }
    } ~


    (spec & ETOSpec.matrixAddMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "+", Rhs)(auto ref const Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(!isInferableMatrix!Rhs)
                assert(this.inferSize(mat.rows, mat.cols).isValid);
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"+"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixSubMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "-", Rhs)(auto ref const Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(!isInferableMatrix!Rhs)
                assert(this.inferSize(mat.rows, mat.cols).isValid);
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"-"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixMulMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "*", Rhs)(auto ref const Rhs mat) const
        if(isNarrowMatrix!Rhs)
        in{
            static if(!isInferableMatrix!Rhs)
                assert(this.inferSize(wild, mat.rows).isValid);
        }
        body{
            static assert(isValidOperator!(typeof(this), op, Rhs));
            return matrixExpression!"*"(this, mat);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixAddScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "+", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"+"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarAddMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "+", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"+"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixSubScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "-", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"-"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarSubMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "-", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"-"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixMulScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "*", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"*"(this, s);
        }
    } : ""
    ) ~


    (spec & ETOSpec.scalarMulMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "*", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"*"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.matrixDivScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinary(string op : "/", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(typeof(this), op, S));
            return matrixExpression!"/"(this, s);
        }
    } : ""
    ) ~

    (spec & ETOSpec.scalarDivMatrix ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        auto opBinaryRight(string op : "/", S)(const S s) const
        if(isScalar!S)
        {
            static assert(isValidOperator!(S, op, typeof(this)));
            return matrixExpression!"/"(s, this);
        }
    } : ""
    ) ~


    (spec & ETOSpec.addScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "+", S)(const S scalar)
        if(isScalar!S && is(typeof(this[0, 0] += scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] +=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.subScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "-", S)(const S scalar)
        if(isScalar!S && is(typeof(this[0, 0] -= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] -=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.mulScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "*", S)(const S scalar)
        if(isScalar!S && is(typeof(this[0, 0] *= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] *=  scalar;
        }
    } : ""
    ) ~


    (spec & ETOSpec.divScalar ?
    format(`#line %s "%s"`, __LINE__+2, __FILE__) ~
    q{
        void opOpAssign(string op : "+", S)(const S scalar)
        if(isScalar!S && is(typeof(this[0, 0] /= scalar)))
        {
            foreach(r; 0 .. rows)
                foreach(c; 0 .. cols)
                    this[r, c] /=  scalar;
        }
    } : ""
    );


    mixin template templateMixin()
    {
        mixin(stringMixin);
    }
}


/**
全ての演算子をオーバーロードします。
*/
template defaultExprOps(bool isInferable = false)
{
    enum defaultExprOps = 
    isInferable ?
    q{
        mixin(ExpressionOperatorsInferable!(ETOSpec.all).stringMixin);
        //mixin(ExpressionOperatorsInferable!(ETOSpec.all & ~ETOSpec.opEquals & ~ETOSpec.toString).stringMixin);
        //mixin(ExpressionOperatorsInferable!(ETOSpec.modifiedOperator).stringMixin);
        //const{mixin(ExpressionOperatorsInferable!(ETOSpec.all & ~ETOSpec.modifiedOperator).stringMixin);}
        //immutable{mixin(ExpressionOperatorsInferable!(ETOSpec.all & ~ETOSpec.opEquals & ~ETOSpec.toString).stringMixin);}
    }
    :
    q{
        mixin(ExpressionOperators!(ETOSpec.all, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);
        //mixin(ExpressionOperators!(ETOSpec.all & ~ETOSpec.opEquals & ~ETOSpec.toString, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);
        //mixin(ExpressionOperators!(ETOSpec.modifiedOperator, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);
        //const{mixin(ExpressionOperators!(ETOSpec.all & ~ETOSpec.modifiedOperator, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);}
        //immutable{mixin(ExpressionOperators!(ETOSpec.all & ~ETOSpec.opEquals & ~ETOSpec.toString, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);}
    };
}


unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    static struct M(size_t rs, size_t cs)
    {
        enum rows = rs;
        enum cols = cs;

        size_t opIndex(size_t i, size_t j) inout {return i + j;}

        //inout:
        mixin(defaultExprOps!(false));
    }


    alias S3 = M!(3, 3);
    alias S23 = M!(2, 3);

    static assert(isNarrowMatrix!S3);
    static assert(hasStaticRows!S3);
    static assert(hasStaticColumns!S3);
    static assert(isNarrowMatrix!S23);
    static assert(hasStaticRows!S23);
    static assert(hasStaticColumns!S23);


    M!(1, 1) m11;
    static assert(isNarrowMatrix!(typeof(m11)));
    int valueM11 = m11;

    M!(3, 1) m31;
    M!(1, 3) m13;
    valueM11 = m13 * m31;


    // swizzle
    M!(1, 8) m18;
    assert(m18[0] == m18.a);
    assert(m18[1] == m18.b);
    assert(m18[2] == m18.c);
    assert(m18[3] == m18.d);
    assert(m18[4] == m18.e);
    assert(m18[5] == m18.f);
    assert(m18[6] == m18.g);
    assert(m18[7] == m18.h);

    assert(m18[0] == m18.r);
    assert(m18[1] == m18.i);
    assert(m18[2] == m18.j);
    assert(m18[3] == m18.k);

    assert(m18[0] == m18.x);
    assert(m18[1] == m18.y);
    assert(m18[2] == m18.z);
    assert(m18[3] == m18.w);

    assert(m18[0] == m18.re);
    assert(m18[1] == m18.im);


    static struct I{
        enum rows = wild;
        enum cols = wild;

        size_t opIndex(size_t i, size_t j) inout { return i == j ? 1  : 0;}

        static InferredResult inferSize(Msize_t r, Msize_t c)
        {
            if(r == wild && c == wild)
                return InferredResult(false);
            else if(r == c || r == wild || c == wild)
                return InferredResult(true, max(r, c), max(r, c));
            else
                return InferredResult(false);
        }

        mixin(defaultExprOps!(true));
    }

    static assert(isNarrowMatrix!I);
    static assert(isInferableMatrix!I);
    static assert( I.inferSize(wild, 1).isValid);
    static assert( I.inferSize(3, 3).isValid);
    static assert(!I.inferSize(1, 3).isValid);


    static struct D{
        size_t rows;
        size_t cols;

        size_t opIndex(size_t i, size_t j) inout {return i + j;}

        mixin(defaultExprOps!(false));
    }
    static assert(isNarrowMatrix!D);
    static assert(hasDynamicRows!D);
    static assert(hasDynamicColumns!D);


    S3 a;
    auto add = a + a;
    static assert(isNarrowMatrix!(typeof(add)));
    static assert(hasStaticRows!(typeof(add)));
    static assert(hasStaticColumns!(typeof(add)));
    assert(add[0, 0] == 0); assert(add[0, 1] == 2); assert(add[0, 2] == 4);
    assert(add[1, 0] == 2); assert(add[1, 1] == 4); assert(add[1, 2] == 6);
    assert(add[2, 0] == 4); assert(add[2, 1] == 6); assert(add[2, 2] == 8);

    auto mul = a * a;
    static assert(isNarrowMatrix!(typeof(mul)));
    static assert(hasStaticRows!(typeof(mul)));
    static assert(hasStaticColumns!(typeof(mul)));
    assert(mul[0, 0] == 5); assert(mul[0, 1] == 8); assert(mul[0, 2] ==11);
    assert(mul[1, 0] == 8); assert(mul[1, 1] ==14); assert(mul[1, 2] ==20);
    assert(mul[2, 0] ==11); assert(mul[2, 1] ==20); assert(mul[2, 2] ==29);

    auto sadd = a + 3;
    static assert(isNarrowMatrix!(typeof(sadd)));
    static assert(hasStaticRows!(typeof(sadd)));
    static assert(hasStaticColumns!(typeof(sadd)));
    assert(sadd[0, 0] == 3); assert(sadd[0, 1] == 4); assert(sadd[0, 2] == 5);
    assert(sadd[1, 0] == 4); assert(sadd[1, 1] == 5); assert(sadd[1, 2] == 6);
    assert(sadd[2, 0] == 5); assert(sadd[2, 1] == 6); assert(sadd[2, 2] == 7);

    // auto addMasS = a + m11;

    auto add5 = a + a + cast(const)(a) * 3;
    static assert(isNarrowMatrix!(typeof(add5)));
    static assert(hasStaticRows!(typeof(add5)));
    static assert(hasStaticColumns!(typeof(add5)));
    assert(add5 == a * 5);

    I i;
    auto addi = a + i;
    static assert(isNarrowMatrix!(typeof(addi)));
    static assert(hasStaticRows!(typeof(addi)));    static assert(typeof(addi).rows == 3);
    static assert(hasStaticColumns!(typeof(addi))); static assert(typeof(addi).cols == 3);
    assert(addi[0, 0] == 1); assert(addi[0, 1] == 1); assert(addi[0, 2] == 2);
    assert(addi[1, 0] == 1); assert(addi[1, 1] == 3); assert(addi[1, 2] == 3);
    assert(addi[2, 0] == 2); assert(addi[2, 1] == 3); assert(addi[2, 2] == 5);

    auto i2 = i * 2;
    static assert(isNarrowMatrix!(typeof(i2)));
    static assert(isInferableMatrix!(typeof(i2)));
    static assert( typeof(i2).inferSize(wild, 1).isValid);
    static assert( typeof(i2).inferSize(3, 3).isValid);
    static assert(!typeof(i2).inferSize(1, 3).isValid);

    auto addi2 = a + i2;
    static assert(isNarrowMatrix!(typeof(addi2)));
    static assert(hasStaticRows!(typeof(addi2)));    static assert(typeof(addi2).rows == 3);
    static assert(hasStaticColumns!(typeof(addi2))); static assert(typeof(addi2).cols == 3);
    assert(addi2[0, 0] == 2); assert(addi2[0, 1] == 1); assert(addi2[0, 2] == 2);
    assert(addi2[1, 0] == 1); assert(addi2[1, 1] == 4); assert(addi2[1, 2] == 3);
    assert(addi2[2, 0] == 2); assert(addi2[2, 1] == 3); assert(addi2[2, 2] == 6);

    static assert(!is(typeof(S23.init + i)));
    static assert(!is(typeof(i + S23.init)));
    assert(S23.init * i == S23.init);
    assert(i * S23.init == S23.init);


    import core.exception, std.exception;

    D d33 = D(3, 3);
    auto addsd = a + d33;
    static assert(isNarrowMatrix!(typeof(addsd)));
    static assert(hasStaticRows!(typeof(addsd)));
    static assert(hasStaticColumns!(typeof(addsd)));
    assert(addsd == a * 2);
    assert(addsd == d33 * 2);

    auto addsdr = d33 + a;
    static assert(isNarrowMatrix!(typeof(addsdr)));
    static assert(hasStaticRows!(typeof(addsdr)));
    static assert(hasStaticColumns!(typeof(addsdr)));
    assert(addsdr == addsd);
    assert(addsdr == addsd);

    version(Release){}else assert(collectException!AssertError(D(2, 3) + a));
    version(Release){}else assert(collectException!AssertError(D(2, 3) + i));
    assert(D(2, 3) * i == D(2, 3));

    version(Release){}else assert(collectException!AssertError(D(2, 3) + D(2, 2)));
    version(Release){}else assert(collectException!AssertError(D(2, 3) + D(3, 3)));
    assert((D(2, 3) + D(2, 3)).rows == 2);
    assert((D(2, 3) + D(2, 3)).cols == 3);
    assert((D(2, 3) * D(3, 4)).rows == 2);
    assert((D(2, 3) * D(3, 4)).cols == 4);

    auto mulds = d33 * 3;
    assert(mulds == d33 + d33 + d33);
}


/**
InferableMatrixをある大きさの行列へ固定します。
*/
auto congeal(size_t rs, size_t cs, A)(auto ref A mat)
if(isInferableMatrix!A && A.inferSize(rs, cs).isValid)
{
    static struct Result()
    {
        enum size_t rows = A.inferSize(rs, cs).rows;
        enum size_t cols = A.inferSize(rs, cs).cols;


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _mat[i, j];
        }


      static if(graphite.math.linear.hasAssignableElements!A)
      {
        void opIndexAssign(E)(E e, size_t i, size_t j)
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            _mat[i, j] = e;
        }
      }

        mixin(defaultExprOps!(false));

      private:
        A _mat;
    }

    return Result!()(mat);
}

///
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    static struct I{
        enum rows = wild;
        enum cols = wild;

        size_t opIndex(size_t i, size_t j) inout { return i == j ? 1  : 0;}

        static InferredResult inferSize(Msize_t r, Msize_t c)
        {
            if(r == wild && c == wild)
                return InferredResult(false);
            else if(isEqOrEitherEqX(r, c, wild))
                return InferredResult(true, max(r, c), max(r, c));
            else
                return InferredResult(false);
        }

        mixin(defaultExprOps!(true));
    }

    static assert(isNarrowMatrix!I);
    static assert(isInferableMatrix!I);
    static assert( I.inferSize(wild, 1).isValid);
    static assert( I.inferSize(3, 3).isValid);
    static assert(!I.inferSize(1, 3).isValid);

    I id;
    auto i3x3 = id.congeal!(3, 3)();
    static assert(isNarrowMatrix!(typeof(i3x3)));
    static assert(hasStaticRows!(typeof(i3x3)));
    static assert(hasStaticColumns!(typeof(i3x3)));
    static assert(i3x3.rows == 3);
    static assert(i3x3.cols == 3);
    assert(i3x3[0, 0] == 1);assert(i3x3[1, 0] == 0);assert(i3x3[2, 0] == 0);
    assert(i3x3[0, 1] == 0);assert(i3x3[1, 1] == 1);assert(i3x3[2, 1] == 0);
    assert(i3x3[0, 2] == 0);assert(i3x3[1, 2] == 0);assert(i3x3[2, 2] == 1);
}


/// ditto
auto congeal(A)(auto ref A mat, size_t r, size_t c)
if(isInferableMatrix!A)
in{
    assert(A.inferSize(r, c).isValid);
}
body{
    static struct Result()
    {
        @property size_t rows() const { return _rs; }
        @property size_t cols() const { return _cs; }

        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _mat[i, j];
        }


      static if(graphite.math.linear.hasAssignableElements!A)
      {
        void opIndexAssign(E)(E e, size_t i, size_t j)
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            _mat[i, j] = e;
        }
      }

        mixin(defaultExprOps!(false));

        size_t _rs, _cs;
        A _mat;
    }


    return Result!()(r, c, mat);
}


///
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    static struct I{
        enum rows = wild;
        enum cols = wild;

        size_t opIndex(size_t i, size_t j) inout { return i == j ? 1  : 0;}

        static InferredResult inferSize(Msize_t r, Msize_t c)
        {
            if(r == wild && c == wild)
                return InferredResult(false);
            else if(isEqOrEitherEqX(r, c, wild))
                return InferredResult(true, max(r, c), max(r, c));
            else
                return InferredResult(false);
        }

        mixin(defaultExprOps!(true));
    }

    static assert(isNarrowMatrix!I);
    static assert(isInferableMatrix!I);
    static assert( I.inferSize(wild, 1).isValid);
    static assert( I.inferSize(3, 3).isValid);
    static assert(!I.inferSize(1, 3).isValid);

    I id;
    auto i3x3 = id.congeal(3, 3);
    static assert(isNarrowMatrix!(typeof(i3x3)));
    static assert(hasDynamicRows!(typeof(i3x3)));
    static assert(hasDynamicColumns!(typeof(i3x3)));
    assert(i3x3.rows == 3);
    assert(i3x3.cols == 3);
    assert(i3x3[0, 0] == 1);assert(i3x3[1, 0] == 0);assert(i3x3[2, 0] == 0);
    assert(i3x3[0, 1] == 0);assert(i3x3[1, 1] == 1);assert(i3x3[2, 1] == 0);
    assert(i3x3[0, 2] == 0);assert(i3x3[1, 2] == 0);assert(i3x3[2, 2] == 1);
}


/**
DynamicMatrixをある大きさへ固定します。
*/
auto congeal(size_t rs, size_t cs, A)(auto ref A mat)
if(!isInferableMatrix!A && (hasDynamicRows!A || rs == A.rows) || (hasDynamicColumns!A || cs == A.cols))
in{
    assert(mat.rows == rs);
    assert(mat.cols == cs);
}
body{
    static struct Result()
    {
        enum rows = rs;
        enum cols = cs;


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _mat[i, j];
        }


        static if(graphite.math.linear.hasAssignableElements!A)
        {
          void opIndexAssign(E)(E e, size_t i, size_t j)
          in{
              assert(i < rows);
              assert(j < cols);
          }
          body{
              _mat[i, j] = e;
          }
        }


        mixin(defaultExprOps!(false));

      private:
        A _mat;
    }

    return Result!()(mat);
}


/// ditto
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    static struct D{
        size_t rows;
        size_t cols;

        size_t opIndex(size_t i, size_t j) inout {return i + j;}

        mixin(defaultExprOps!(false));
    }
    static assert(isNarrowMatrix!D);
    static assert(hasDynamicRows!D);
    static assert(hasDynamicColumns!D);

    D d3x3 = D(3, 3);
    auto s3x3 = d3x3.congeal!(3, 3)();
    static assert(isNarrowMatrix!(typeof(s3x3)));
    static assert(s3x3.rows == 3);
    static assert(s3x3.cols == 3);
    assert(s3x3[0, 0] == 0); assert(s3x3[1, 0] == 1); assert(s3x3[2, 0] == 2);
    assert(s3x3[0, 1] == 1); assert(s3x3[1, 1] == 2); assert(s3x3[2, 1] == 3);
    assert(s3x3[0, 2] == 2); assert(s3x3[1, 2] == 3); assert(s3x3[2, 2] == 4);
}


///
auto matrix(size_t rs, size_t cs, alias f, S...)(S sizes)
if(is(typeof(f(0, 0))) && S.length == ((rs == 0) + (cs == 0)) && (S.length == 0 || is(CommonType!S : size_t)))
{
    static struct Result()
    {
      static if(rs)
        enum rows = rs;
      else{
        private size_t _rs;
        @property size_t rows() const { return _rs; }
      }

      static if(cs)
        enum cols = cs;
      else{
        private size_t _cs;
        @property size_t cols() const { return _cs; }
      }


        auto ref opIndex(size_t i, size_t j) const
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return f(i, j);
        }


        mixin(defaultExprOps!(false));
    }

    static if(S.length == 0)
      return Result!()();
    else static if(S.length == 1)
      return Result!()(sizes[0]);
    else static if(S.length == 2)
      return Result!()(sizes[0], sizes[1]);
}


auto matrix(alias f)(size_t r, size_t c)
if(is(typeof(f(0, 0))))
{
    return matrix!(0, 0, f)(r, c);
}


unittest{
    auto m = matrix!(2, 3, (i, j) => i * 3 + j);
    static assert(isNarrowMatrix!(typeof(m)));
    static assert(hasStaticRows!(typeof(m)));
    static assert(hasStaticColumns!(typeof(m)));
    static assert(m.rows == 2);
    static assert(m.cols == 3);
    assert(m[0, 0] == 0); assert(m[0, 1] == 1); assert(m[0, 2] == 2);
    assert(m[1, 0] == 3); assert(m[1, 1] == 4); assert(m[1, 2] == 5);


    auto md = matrix!((i, j) => i * 3 + j)(2, 3);
    assert(m == md);
}


auto matrix(alias f)()
{
    static struct Result()
    {
        enum rows = wild;
        enum cols = wild;


        static InferredResult inferSize(Msize_t r, Msize_t c)
        {
            if(r == wild && c == wild)
                return  InferredResult(false);
            else if(r == wild || c == wild)
                return InferredResult(true, max(r, c), max(r, c));
            else
                return InferredResult(true, r, c);
        }


        auto ref opIndex(size_t i, size_t j) const { return f(i, j); }


        mixin(defaultExprOps!(true));
    }

      return Result!()();
}
unittest{
    auto mi = matrix!((i, j) => i * 3 + j);
    static assert(isInferableMatrix!(typeof(mi)));
    assert(mi == matrix!((i, j) => i * 3 + j)(2, 3));
}


/**
内部で2次元配列を持つ行列です
*/
struct DMatrix(T, Msize_t rs = dynamic, Msize_t cs = dynamic, Major mjr = Major.row)
{
    enum bool isColumnMajor = mjr == Major.column;
    enum bool isRowMajor    = mjr == Major.row;
    enum major = mjr;


    this(M)(auto ref M m)
    if(!is(M == typeof(this)))
    {
      static if(isNarrowMatrix!M)
        this.noAlias = m;
      else
        this.opAssign(m);
    }


    static if(rs != dynamic)
    {
        enum size_t rows = rs;
    }
    else
    {
        @property
        size_t rows() const
        {
          static if(cs == 1)
            return _array.length;
          else static if(isColumnMajor)
          {
            if(this.tupleof[0].length)
                return this.tupleof[0][0].length;
            else
                return 0;
          }
          else
            return this.tupleof[0].length;
        }


        @property
        void rows(size_t newSize)
        {
          static if(rs == 1)
            return _array.length;
          else static if(isColumnMajor)
          {
            foreach(ref e; _array)
              e.length = newSize;
          }
          else
            _array.length = newSize;
        }
    }

    static if(cs != dynamic)
    {
        enum size_t cols = cs;
    }
    else
    {
        @property
        size_t cols() const
        {
          static if(rs == 1)
            return _array.length;
          else static if(isRowMajor){
            if(this.tupleof[0].length)
                return this.tupleof[0][0].length;
            else
                return 0;
          }
          else
            return this.tupleof[0].length;
        }


        @property
        void cols(size_t newSize)
        {
          static if(rs == 1)
            return _array.length = newSize;
          else static if(isRowMajor)
          {
            foreach(ref e; _array)
              e.length = newSize;
          }
          else
            _array.length = newSize;
        }
    }


    auto ref opIndex(size_t i, size_t j) inout
    in{
        assert(i < rows);
        assert(j < cols);
    }
    body{
      static if(rs == 1 || cs == 1)
        return _array[i+j];
      else static if(isRowMajor)
        return _array[i][j];
      else
        return _array[j][i];
    }


    mixin(ExpressionOperators!(ETOSpec.all & ~ETOSpec.opAssign, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);
    //mixin(defaultExprOps!(false));


    void opAssign(M)(auto ref M mat)
    if(!is(typeof(this) == M) && isValidOperator!(typeof(this), "+", M))
    in{
      static if(rs && hasDynamicRows!M)
        assert(this.rows == mat.rows);

      static if(cs && hasDynamicColumns!M)
        assert(this.cols == mat.cols);

      static if(isInferableMatrix!M)
        assert(mat.inferSize(this.rows, this.cols).isValid);
    }
    body
    {
      static if(isInferableMatrix!M)
      {
        immutable rl = this.rows,
                  cl = this.cols;
      }
      else
      {
        immutable rl = mat.rows,
                  cl = mat.cols;
      }

        immutable n = rl * cl;

        if(_buffer.length < n)
            _buffer.length = n;

        foreach(i; 0 .. rl)
            foreach(j; 0 .. cl)
            {
                static if(major == Major.row)
                    _buffer[i * cl + j] = mat[i, j];
                else
                    _buffer[j * rl + i] = mat[i, j];
            }

      static if(rs == dynamic)
        this.rows = rl;

      static if(cs == dynamic)
        this.cols = cl;

      static if(rs == 1 || cs == 1)
        _array[] = _buffer[0 .. n][];
      else{
        foreach(i; 0 .. _array.length)
            _array[i][] = _buffer[i * _array[0].length .. (i+1) * _array[0].length][];
      }
    }


    void opAssign(X)(X m)
    if(!isNarrowMatrix!X && isRandomAccessRange!X && (rs || !isInfinite!X)
                   && isRandomAccessRange!(std.range.ElementType!X)
                   && (cs || !isInfinite!(std.range.ElementType!X)))
    {
        if(m.length && m[0].length){
          static if(rs == dynamic){
            if(m.length != this.rows)
                this.rows = m.length;
          }
            
          static if(cs == dynamic){
            if(m[0].length != this.cols)
                this.cols = m[0].length;
          }

            foreach(i; 0 .. this.rows)
                foreach(j; 0 .. this.cols)
                    this[i, j] = m[i][j];
        }
    }


    void opAssign(X)(X m)
    if(!isNarrowMatrix!X && isRandomAccessRange!X && isAssignable!(T, std.range.ElementType!X))
    {
        foreach(i; 0 .. this.rows)
            foreach(j; 0 .. this.cols)
                this[i, j] = m[i * this.cols + j];
    }


  static if(rs == 1 || cs == 1)
  {
    void opAssign(Array)(Array arr)
    if(!isNarrowMatrix!Array && isAssignable!(T, typeof(arr[size_t.init])))
    {
        foreach(i; 0 .. this.length)
            this[i] = arr[i];
    }
  }


    @property
    void noAlias(M)(auto ref M mat)
    if(isValidOperator!(typeof(this), "+", M) && ((!rs || !hasStaticRows!M) ||    is(typeof({static assert(this.rows == M.rows);})))
                                              && ((!cs || !hasStaticColumns!M) || is(typeof({static assert(this.cols == M.cols);}))))
    in{
      static if(rs != dynamic)
        assert(this.rows == mat.rows);

      static if(cs != dynamic)
        assert(this.cols == mat.cols);
    }
    body{
      static if(is(typeof(this) == M))
        this = mat;
      else
      {
        immutable rl = mat.rows,
                  cl = mat.cols,
                  n = rl * cl;

      static if(is(typeof(_array) == T[]))
      {
        if(_array.length < n)
            _array.length = n;
      }
      else
      {
        immutable x = (major == Major.row) ? rl : cl,
                  y = (major == Major.row) ? cl : rl;

        if(_array.length < x)
            _array.length = x;

        foreach(ref e; _array)
            if(e.length < y)
                e.length = y;
      }

        static if(rs == dynamic)
          this.rows = rl;

        static if(cs == dynamic)
          this.cols = cl;

        foreach(i; 0 .. rl)
            foreach(j; 0 .. cl)
            {
              static if(rs == 1 || cs == 1)
                _array[i+j] = mat[i, j];
              else static if(major == Major.row)
                  _array[i][j] = mat[i, j];
              else
                  _array[j][i] = mat[i, j];
            }
      }
    }


    @property
    auto reference() inout
    {
        return this;
    }


  private:
  static if(rs == 1 || cs == 1)
  {
    T[] _array;
  }
  else
  {
    T[][] _array;
  }

  static:
    T[] _buffer;
}

unittest{
    DMatrix!float m = 
    [[1, 2, 3],
     [4, 5, 6]];

     assert(m.rows == 2);
     assert(m.cols == 3);

     assert(m[0, 0] == 1);
     assert(m[0, 1] == 2);
     assert(m[0, 2] == 3);
     assert(m[1, 0] == 4);
     assert(m[1, 1] == 5);
     assert(m[1, 2] == 6);
}


DMatrix!(T, r, c, mjr) matrix(T, Msize_t r = dynamic, Msize_t c = dynamic, Major mjr = Major.row, size_t N)(size_t[N] size...)
if(N == (r == dynamic) + (c == dynamic))
{
    typeof(return) dst;

    static if(r != dynamic)
        immutable size_t rs = r;
    else
        immutable size_t rs = size[0];

    static if(c != dynamic)
        immutable size_t cs = c;
    else
        immutable size_t cs = size[$-1];

    immutable h = mjr == Major.row ? rs : cs,
              w = mjr == Major.row ? cs : rs;

    static if(r == 1 || c == 1)
        dst._array = new T[h * w];
    else
        dst._array = new T[][](h, w);

    return dst;
}

unittest{
    foreach(major; TypeTuple!(Major.row, Major.column))
    {
        auto mr23 = matrix!(int, 2, 4, major)();
        static assert(isNarrowMatrix!(typeof(mr23)));
        static assert(hasStaticRows!(typeof(mr23)));
        static assert(hasStaticColumns!(typeof(mr23)));
        static assert(mr23.rows == 2);
        static assert(mr23.cols == 4);

        auto mr2_ = matrix!(int, 2, dynamic, major)(4);
        static assert(isNarrowMatrix!(typeof(mr2_)));
        static assert(hasStaticRows!(typeof(mr2_)));
        static assert(hasDynamicColumns!(typeof(mr2_)));
        static assert(mr2_.rows == 2);
        assert(mr2_.cols == 4);

        auto mr_2 = matrix!(int, dynamic, 2, major)(4);
        static assert(isNarrowMatrix!(typeof(mr_2)));
        static assert(hasDynamicRows!(typeof(mr_2)));
        static assert(hasStaticColumns!(typeof(mr_2)));
        assert(mr_2.rows == 4);
        static assert(mr_2.cols == 2);

        auto mr__ = matrix!(int, dynamic, dynamic, major)(2, 4);
        static assert(isNarrowMatrix!(typeof(mr__)));
        static assert(hasDynamicRows!(typeof(mr__)));
        static assert(hasDynamicColumns!(typeof(mr__)));
        assert(mr__.rows == 2);
        assert(mr__.cols == 4);
    }
}


DMatrix!(T, r, c, mjr) matrix(size_t r, size_t c, Major mjr = Major.row, T)(T[] arr)
if(r != 0 || c != 0)
in{
  static if(r != 0 && c != 0)
    assert(arr.length == r * c);
  else{
    assert(!(arr.length % r + c));
  }
}
body{
    static if(r == 1 || c == 1)
    {
      typeof(return) dst;
      dst._array = arr;
      return dst;
    }
    else
    {
      immutable rs = r == 0 ? arr.length / c : r;
      immutable cs = c == 0 ? arr.length / r : c;

      immutable h = mjr == Major.row ? rs : cs,
                w = mjr == Major.row ? cs : rs;

      typeof(return) dst;
      dst._array.length = h;
      foreach(i; 0 .. h)
        dst._array[i] = arr[i * w .. (i+1) * w];

      return dst;
    }
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}

    auto mr = matrix!(2, 3)([0, 1, 2, 3, 4, 5]);
    static assert(isNarrowMatrix!(typeof(mr)));
    static assert(hasStaticRows!(typeof(mr)));
    static assert(hasStaticColumns!(typeof(mr)));
    static assert(mr.rows == 2);
    static assert(mr.cols == 3);
    assert(mr[0, 0] == 0); assert(mr[0, 1] == 1); assert(mr[0, 2] == 2);
    assert(mr[1, 0] == 3); assert(mr[1, 1] == 4); assert(mr[1, 2] == 5);

    mr[0, 0] = 10;
    assert(mr[0, 0] == 10); assert(mr[0, 1] == 1); assert(mr[0, 2] == 2);
    assert(mr[1, 0] ==  3); assert(mr[1, 1] == 4); assert(mr[1, 2] == 5);

    mr = matrix!(2, 3, (i, j) => (i*3+j)*2);
    assert(mr[0, 0] == 0); assert(mr[0, 1] == 2); assert(mr[0, 2] == 4);
    assert(mr[1, 0] == 6); assert(mr[1, 1] == 8); assert(mr[1, 2] == 10);

    auto mc = matrix!(2, 3, Major.column)([0, 1, 2, 3, 4, 5]);
    static assert(isNarrowMatrix!(typeof(mc)));
    static assert(hasStaticRows!(typeof(mc)));
    static assert(hasStaticColumns!(typeof(mc)));
    static assert(mc.rows == 2);
    static assert(mc.cols == 3);
    assert(mc[0, 0] == 0); assert(mc[0, 1] == 2); assert(mc[0, 2] == 4);
    assert(mc[1, 0] == 1); assert(mc[1, 1] == 3); assert(mc[1, 2] == 5);

    mc[0, 0] = 10;
    assert(mc[0, 0] == 10); assert(mc[0, 1] == 2); assert(mc[0, 2] == 4);
    assert(mc[1, 0] ==  1); assert(mc[1, 1] == 3); assert(mc[1, 2] == 5);

    mc = matrix!(2, 3, (i, j) => (i*3+j)*2);
    assert(mc[0, 0] == 0); assert(mc[0, 1] == 2); assert(mc[0, 2] == 4);
    assert(mc[1, 0] == 6); assert(mc[1, 1] == 8); assert(mc[1, 2] == 10);
}


DMatrix!(T, wild, wild, mjr) matrix(Major mjr = Major.row, T)(T[] arr, size_t r, size_t c)
in{
  if(r != 0 && c != 0)
    assert(arr.length == r * c);
  else if(r != 0 || c != 0)
    assert(!(arr.length % (r + c)));
  else
    assert(0);
}
body{
    immutable rs = r == 0 ? arr.length / c : r;
    immutable cs = c == 0 ? arr.length / r : c;

    immutable h = mjr == Major.row ? rs : cs,
              w = mjr == Major.row ? rs : cs;

    typeof(return) dst;
    dst._array.length = h;
    foreach(i; 0 .. h)
      dst._array[i] = arr[i * w .. (i+1) * w];

    return dst;
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}

    auto mr = matrix!(2, 3)([0, 1, 2, 3, 4, 5]);
    static assert(isNarrowMatrix!(typeof(mr)));
    static assert(hasStaticRows!(typeof(mr)));
    static assert(hasStaticColumns!(typeof(mr)));
    static assert(mr.rows == 2);
    static assert(mr.cols == 3);
    assert(mr[0, 0] == 0); assert(mr[0, 1] == 1); assert(mr[0, 2] == 2);
    assert(mr[1, 0] == 3); assert(mr[1, 1] == 4); assert(mr[1, 2] == 5);


    auto mc = matrix!(2, 3, Major.column)([0, 1, 2, 3, 4, 5]);
    static assert(isNarrowMatrix!(typeof(mc)));
    static assert(hasStaticRows!(typeof(mc)));
    static assert(hasStaticColumns!(typeof(mc)));
    static assert(mc.rows == 2);
    static assert(mc.cols == 3);
    assert(mc[0, 0] == 0); assert(mc[0, 1] == 2); assert(mc[0, 2] == 4);
    assert(mc[1, 0] == 1); assert(mc[1, 1] == 3); assert(mc[1, 2] == 5);
}


auto matrix(Major mjr = Major.row, T, size_t N, size_t M)(ref T[M][N] arr)
{
  static if(mjr == Major.row)
    DMatrix!(T, N, M, mjr) dst;
  else
    DMatrix!(T, M, N, mjr) dst;

    dst._array.length = N;
    foreach(i; 0 .. N)
      dst._array[i] = arr[i];
    return dst;
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}

    int[3][2] arr = [[0, 1, 2], [3, 4, 5]];

    auto mr = matrix(arr);
    static assert(isNarrowMatrix!(typeof(mr)));
    static assert(hasStaticRows!(typeof(mr)));
    static assert(hasStaticColumns!(typeof(mr)));
    static assert(mr.rows == 2);
    static assert(mr.cols == 3);
    assert(mr[0, 0] == 0); assert(mr[0, 1] == 1); assert(mr[0, 2] == 2);
    assert(mr[1, 0] == 3); assert(mr[1, 1] == 4); assert(mr[1, 2] == 5);
}

auto matrix(Major mjr = Major.row, A)(A mat)
if(isNarrowMatrix!A && !isInferableMatrix!A)
{
  static if(hasStaticRows!A && hasStaticColumns!A)
    DMatrix!(ElementType!A, A.rows, A.cols, mjr) dst;
  else static if(hasStaticRows!A)
    DMatrix!(ElementType!A, A.rows, wild, mjr) dst;
  else static if(hasStaticColumns!A)
    DMatrix!(ElementType!A, wild, A.cols, mjr) dst;
  else
    DMatrix!(ElementType!A, wild, wild, mjr) dst;

    dst.noAlias = mat;
    return dst;
}


auto matrix(size_t rs, size_t cs = 0, Major mjr = Major.row, A)(A mat)
if(isInferableMatrix!A && A.inferSize(rs, cs).isValid)
{
    return mat.congeal!(rs, cs).matrix();
}


auto matrix(Major mjr = Major.row, A)(A mat, size_t r, size_t c = 0)
if(isInferableMatrix!A)
in{
  assert(A.inferSize(r, c).isValid);
}
body{
  return mat.congeal(r, c).matrix();
}


/**
要素がメモリ上に連続して存在するような行列
*/
struct SMatrix(T, size_t rs = 0, size_t cs = 0, Major mjr = Major.row)
if(rs != 0 && cs != 0)
{
    enum bool isColumnMajor = mjr == Major.column;
    enum bool isRowMajor    = mjr == Major.row;
    enum major = mjr;
    enum size_t rows = rs;
    enum size_t cols = cs;


    this(M)(auto ref M mat)
    if(!is(M == typeof(this)))
    {
      static if(isNarrowMatrix!M)
        this.noAlias = mat;
      else
        this.opAssign(mat);
    }


    auto ref opIndex(size_t i, size_t j) inout
    in{
        assert(i < rows);
        assert(j < cols);
    }
    body{
        static if(major == Major.row)
            return _array[i * cols + j];
        else
            return _array[j * rows + i];
    }


    @property
    auto array() pure nothrow @safe inout
    {
        return _array[];
    }


    void opAssign(M)(auto ref M mat)
    if(isValidOperator!(typeof(this), "+", M))
    {
        foreach(i; 0 .. rows)
            foreach(j; 0 .. cols)
            {
                static if(major == Major.row)
                    SMatrix._buffer[i * cols + j] = mat[i, j];
                else
                    SMatrix._buffer[j * rows + i] = mat[i, j];
            }
        
        _array[] = SMatrix._buffer[];
    }


    void opAssign(X)(X m)
    if(!isNarrowMatrix!X && is(typeof(m[size_t.init][size_t.init])) && isAssignable!(T, typeof(m[size_t.init][size_t.init])))
    {
        foreach(i; 0 .. this.rows)
            foreach(j; 0 .. this.cols)
                this[i, j] = m[i][j];
    }


    void opAssign(X)(X m)
    if(!isNarrowMatrix!X && is(typeof(m[size_t.init, size_t.init])) && isAssignable!(T, typeof(m[size_t.init, size_t.init])))
    {
        foreach(i; 0 .. this.rows)
            foreach(j; 0 .. this.cols)
                this[i, j] = m[i, j];
    }


  static if(rows == 1 || cols == 1)
  {
    void opAssign(Array)(Array arr)
    if(!isNarrowMatrix!Array && isAssignable!(T, typeof(arr[size_t.init])))
    {
        foreach(i; 0 .. this.length)
            this[i] = arr[i];
    }
  }


    @property
    void noAlias(M)(auto ref M mat)
    if(isValidOperator!(typeof(this), "+", M))
    {
        foreach(i; 0 .. rows)
            foreach(j; 0 .. cols)
            {
                static if(major == Major.row)
                    _array[i * cols + j] = mat[i, j];
                else
                    _array[j * rows + i] = mat[i, j];
            }
    }


    @property
    auto reference() inout pure nothrow @safe
    {
        //Issue: 9983 http://d.puremagic.com/issues/show_bug.cgi?id=9983
        //return matrix!(rows, cols)(_array[]);
        return _referenceImpl(this);
    }


    mixin(ExpressionOperators!(ETOSpec.all & ~ETOSpec.opAssign, mixin(is(typeof({enum _unused_ = rows;})) ? "this.rows" : "wild"), mixin(is(typeof({enum _unused_ = cols;})) ? "this.cols" : "wild")).stringMixin);
    //mixin(defaultExprOps!(false));


  private:
    T[rs * cs] _array;

  static:
    T[rs * cs] _buffer;


    // Workaround of issue 9983 http://d.puremagic.com/issues/show_bug.cgi?id=9983
    auto _referenceImpl(M)(ref M m) @trusted pure nothrow
    {
        static if(is(Q == immutable(Q)))
            return _referenceImplImmutable(cast(immutable(T)[])m._array[]);
        else static if(is(Q == const(Q)))
            return _referenceImplConst(cast(const(T)[])m._array[]);
        else
            return _referenceImplMutable(cast(T[])m._array[]);
    }


    auto _referenceImplMutable(E)(E[] arr)
    {
        return arr.matrix!(rows, cols);
    }


    auto _referenceImplConst(E)(const E[] arr)
    {
        return arr.matrix!(rows, cols);
    }


    auto _referenceImplImmutable(E)(immutable E[] arr)
    {
        return arr.matrix!(rows, cols);
    }
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 3, 3) m;
    m[0, 0] = 0; m[0, 1] = 1; m[0, 2] = 2;
    m[1, 0] = 1; m[1, 1] = 2; m[1, 2] = 3;
    m[2, 0] = 2; m[2, 1] = 3; m[2, 2] = 4;

    SMatrix!(int, 3, 3) m2 = m * m;
    m = m * m;
    assert(m == m2);
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 2, 2, Major.row) mr;    // 2x2, int型, 行優先
    assert(mr.array.equal([0, 0, 0, 0]));       // 初期化される

    mr[0, 1] = 1;
    mr[1, 0] = 2;
    mr[1, 1] = 3;
    assert(mr.array.equal([0, 1, 2, 3]));       // 行優先順


    SMatrix!(int, 2, 2, Major.column) mc; // 2x2, int型, 列優先
    assert(mc.array.equal([0, 0, 0, 0]));       // 初期化される

    mc[0, 1] = 1;
    mc[1, 0] = 2;
    mc[1, 1] = 3;
    assert(mc.array.equal([0, 2, 1, 3]));       // 列優先順


    SMatrix!(int, 2, 2, Major.row) minit = mc;
    assert(minit.array.equal([0, 1, 2, 3]));   // 全要素12で初期化されている
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 1, 3) m;
    m[0] = 3;
    assert(m[0] == 3);
    static assert(m.length == 3);
    assert(m[$-1] == 0);
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 2, 2) m;
    auto rm = m.reference;

    assert(rm + rm == m + m);
    assert(rm - rm == m - m);
    assert(rm * rm == m * m);

    m = [[1, 2], [2, 3]];

    SMatrix!(int, 2, 2) m2 = m;
    m.noAlias = m2 + m2;
    assert(m[0, 0] == 2);
}


unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    alias SRVector!(int, 3) R;
    R rv1;
    static assert(rv1.rows == 1);
    static assert(rv1.cols == 3);
    static assert(rv1.length  == 3);

    rv1[0] = 3;
    assert(rv1[0] == 3);
    assert(rv1[1] == 0);
    assert(rv1[2] == 0);
    rv1 += 3;
    assert(rv1[0] == 6);
    assert(rv1[1] == 3);
    assert(rv1[2] == 3);
    rv1[0] += 3;
    assert(rv1[0] == 9);
    assert(rv1[1] == 3);
    assert(rv1[2] == 3);

    SRVector!(int, 4) rv2;
    static assert(rv2.rows == 1);
    static assert(rv2.cols == 4);
    static assert(rv2.length  == 4);

    SCVector!(int, 3) cv1;
    static assert(cv1.rows == 3);
    static assert(cv1.cols == 1);
    static assert(cv1.length  == 3);

    SCVector!(int, 4) cv2;
    static assert(cv2.rows == 4);
    static assert(cv2.cols == 1);
    static assert(cv2.length  == 4);
}


///ditto
template SRVector(T, size_t size)
{
    alias SMatrix!(T, 1, size, Major.row) SRVector;
}

///ditto
template SCVector(T, size_t size)
{
    alias SMatrix!(T, size, 1, Major.column) SCVector;
}

///ditto
template SVector(T, size_t size)
{
    alias SCVector!(T, size) SVector;
}


/**
転置行列を返します。
*/
@property
auto transpose(A)(A mat)
if(isNarrowMatrix!A)
{
    static struct Transposed()
    {
      static if(isInferableMatrix!A)
      {
        enum size_t rows = wild;
        enum size_t cols = wild;

        static InferredResult inferSize(Msize_t rs, Msize_t cs)
        {
            return A.inferSize(cs, rs);
        }
      }
      else
      {
        static if(hasStaticColumns!A)
            enum size_t rows = A.cols;
        else
            @property auto ref rows() inout { return _mat.cols; }

        static if(hasStaticRows!A)
            enum size_t cols = A.rows;
        else
            @property auto ref cols() inout { return _mat.rows; }
      }


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _mat[j, i];
        }


      static if(graphite.math.linear.hasAssignableElements!A)
      {
        void opIndexAssign(E)(E e, size_t i, size_t j)
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            _mat[j, i] = e;
        }

        static if(isVector!A)
        {
            void opIndexAssign(E)(E e, size_t i)
            in{
                assert(i < this.length);
            }
            body{
                static if(is(typeof({static assert(rows == 1);})))
                    this[0 , i] = e;
                else
                    this[i, 0] = e;
            }
        }
      }

        mixin(defaultExprOps!(isInferableMatrix!A));


        auto ref transpose() @property inout
        {
            return _mat;
        }


      private:
        A _mat;
    }

    return Transposed!()(mat);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 2, 2) m;
    m = [[0, 1],
         [2, 3]];

    auto t = m.transpose;
    assert(t[0, 0] == 0);
    assert(t[0, 1] == 2);
    assert(t[1, 0] == 1);
    assert(t[1, 1] == 3);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SCVector!(int, 3) v;
    v[0] = 1; v[1] = 2; v[2] = 3;

    auto t = v.transpose;
    t[0] = 1;
    t[1] = 2;
    t[2] = 3;
    //t = [1, 2, 3];

    assert(t.rows == 1);
    assert(t.cols == 3);


    static assert(is(typeof(v) == typeof(t.transpose)));
}

/**

*/
auto toRange(A)(A mat)
if(isNarrowMatrix!A)
{
    static struct ToRange()
    {
        static struct Element()
        {
            @property auto ref front() { return _mat[_r, _cf]; }

            @property auto ref back() { return _mat[_r, _cb]; }

            auto ref opIndex(size_t i) { i += _cf; return _mat[_r, i]; }

            void popFront() { ++_cf; }
            void popBack() { --_cb; }

            @property bool empty() { return _cf == _cb; }
            @property size_t length() { return _cb - _cf; }
            alias opDollar = length;

            @property auto save() { return this; }

            auto opSlice() { return this.save; }
            auto opSlice(size_t i, size_t j) { return typeof(this)(_mat, _r, _cf + i, j); }


          private:
            A _mat;
            size_t _r;
            size_t _cf = 0;
            size_t _cb;
        }


        @property auto front() { return Element!()(this._mat, _rf, 0, this._mat.cols); }

        @property auto back() { return Element!()(this._mat, _rb, 0, this._mat.cols); }

        auto opIndex(size_t i) { i += _rf; return Element!()(this._mat, i, 0, this._mat.cols);}

        void popFront() { ++_rf; }
        void popBack() { --_rb; }

        @property bool empty() { return _rf == _rb; }
        @property size_t length() { return _rb - _rf; }
        alias opDollar = length;

        @property auto save() { return this; }

        auto opSlice() { return this.save; }
        auto opSlice(size_t i, size_t j) { return typeof(this)(_mat, _rf + i, j); }

      private:
        A _mat;
        size_t _rf = 0;
        size_t _rb;
    }


    return ToRange!()(mat, 0, mat.rows);
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 3, 3) rm33;
    rm33[0, 0] = 1; rm33[0, 1] = 2; rm33[0, 2] = 3;
    assert(equal!"equal(a, b)"(rm33.toRange, [[1, 2, 3], [0, 0, 0], [0, 0, 0]]));

    SMatrix!(int, 1, 1) rm11;
    assert(equal!"equal(a, b)"(rm11.toRange, [[0]]));
}


/**
行列をレンジにします
*/
auto toFlatten(A)(A mat)
if(isNarrowMatrix!A && !isInferableMatrix!A)
{
    alias ElementType!A E;

    static struct ToFlatten()
    {
        @property
        auto ref front()
        {
            return _mat[_f / _mat.cols, _f % _mat.cols];
        }


        @property
        auto ref back()
        {
            return _mat[_b / _mat.cols, _b % _mat.cols];
        }


        auto ref opIndex(size_t i) inout
        in{
            assert(_f + i < _b);
        }body{
            i += _f;
            return _mat[i / _mat.cols, i % _mat.cols];
        }


        static if(hasAssignableElements!A)
        {
            @property
            void front(E v)
            {
                _mat[_f / _mat.cols, _f % _mat.cols] = v;
            }


            @property
            void back(E v)
            {
                _mat[_b / _mat.cols, _b % _mat.cols] = v;
            }


            void opIndexAssign(E v, size_t i)
            in{
                assert(_f + i < _b);
            }
            body{
                i += _f;
                _mat[i / _mat.cols, i % _mat.cols] = v;
            }
        }


        @property
        bool empty() pure nothrow @safe const
        {
            return _f >= _b;
        }


        void popFront() pure nothrow @safe
        {
            _f++;
        }


        void popBack() pure nothrow @safe
        {
            _b--;
        }


        @property
        size_t length() pure nothrow @safe const
        {
            return _b - _f;
        }


        alias length opDollar;


        @property
        typeof(this) save() pure nothrow @safe
        {
            return this;
        }


    private:
        A _mat;
        size_t _f, _b;
    }

    return ToFlatten!()(mat, 0, mat.rows * mat.cols);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    SMatrix!(int, 3, 3, Major.row) rm33;
    rm33[0, 0] = 1; rm33[0, 1] = 2; rm33[0, 2] = 3;
    //writeln(rm33.array.length;)
    assert(rm33.array == [1, 2, 3, 0, 0, 0, 0, 0, 0]);

    alias Rt1 = typeof(toFlatten(rm33));
    static assert(isRandomAccessRange!(Rt1));
    static assert(std.range.hasLvalueElements!(Rt1));
    static assert(std.range.hasAssignableElements!(Rt1));
    static assert(hasLength!(Rt1));
    assert(equal(rm33.toFlatten, rm33.array));

    SMatrix!(int, 3, 3, Major.column) cm33;
    cm33[0, 0] = 1; cm33[0, 1] = 2; cm33[0, 2] = 3;
    assert(cm33.array == [1, 0, 0, 2, 0, 0, 3, 0, 0]);
    assert(equal(cm33.toFlatten, [1, 2, 3, 0, 0, 0, 0, 0, 0]));
}



/**
レンジから行列を作ります。
*/
auto toMatrix(size_t rs, size_t cs, Major mjr = Major.row, R)(R range)
if(isRandomAccessRange!R && isScalar!(Unqual!(std.range.ElementType!R)) && (mjr == Major.row ? (cs != wild) : (rs != wild)))
{
  //static if(mjr == Major.column)
    //return range.toMatrix!(cs, rs, Major.row).transpose;
  //else
  //{
    alias E = Unqual!(std.range.ElementType!R);

    static struct ToMatrix()
    {
      static if(rs != wild)
        enum size_t rows = rs;
      else
        auto ref rows() const @property
        {
            return _range.length / typeof(this).cols;
        }

      static if(cs != wild)
        enum size_t cols = cs;
      else
        auto ref cols() const @property
        {
            return _range.length / typeof(this).rows;
        }


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows || rows == 0);
            assert(j < cols || cols == 0);

          static if(hasLength!R && mjr == Major.row)
            assert(i * cols + j < this._range.length);

          static if(hasLength!R && mjr == Major.column)
            assert(j * rows + i < this._range.length);
        }
        body{
          static if(mjr == Major.row)
            return this._range[i * cols + j];
          else
            return this._range[j * rows + i];
        }


        mixin(defaultExprOps!(false));

      private:
        R _range;
    }

    return ToMatrix!()(range);
  //}
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto r = iota(4);
    auto mr = toMatrix!(2, 2)(r);
    assert(mr.toFlatten.equal([0, 1, 2, 3]));

    auto mc = r.toMatrix!(2, 2, Major.column);
    assert(mc.toFlatten.equal([0, 2, 1, 3]));
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto mem = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    auto mr = mem.toMatrix!(3, 3);
    static assert(isNarrowMatrix!(typeof(mr)));
    static assert(hasLvalueElements!(typeof(mr)));
    assert(mr.toFlatten.equal(mem[0 .. 9]));

    mem.length = 16;
    auto mc = mem.toMatrix!(4, 4, Major.column);
    static assert(isNarrowMatrix!(typeof(mr)));
    static assert(hasLvalueElements!(typeof(mr)));
    mc[3, 3] = 15;
    assert(mc.transpose.toFlatten.equal([0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
                                            0, 0, 0, 0, 0, 15]));
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto mem = [0, 1, 2, 3];
    auto r1 = mem.toMatrix!(wild, 1, Major.row);
    assert(equal(r1.toFlatten, mem[0 .. 4]));

    mem ~= [4, 5];
    auto r2 = mem.toMatrix!(wild, 2, Major.row);
    assert(r2[2, 0] == 4);
    assert(r2[2, 1] == 5);

    auto c1 = mem.toMatrix!(1, wild, Major.column);
    assert(equal(c1.toFlatten, mem));
}



auto toMatrix(Msize_t rs, Msize_t cs, Major mjr = Major.row, R)(R range)
if(isRandomAccessRange!R && isRandomAccessRange!(Unqual!(std.range.ElementType!R)) && isScalar!(Unqual!(std.range.ElementType!(Unqual!(std.range.ElementType!R)))))
{
    static struct ToMatrix()
    {
      static if(rs != dynamic)
        enum size_t rows = rs;
      else
        auto ref rows() const @property
        {
          static if(mjr == Major.row)
            return _range.length;
          else
            return _range[0].length;
        }


      static if(cs != dynamic)
        enum size_t cols = cs;
      else
        auto ref cols() const @property
        {
          static if(mjr == Major.column)
            return _range.length;
          else
            return _range[0].length;
        }


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows || rows == 0);
            assert(j < cols || cols == 0);

          static if(hasLength!R)
            assert((mjr == Major.row ? i : j) < _range.length);

          static if(hasLength!(Unqual!(std.range.ElementType!R)))
            assert((mjr == Major.row ? j : i) < _range[i].length);
        }
        body{
          static if(mjr == Major.row)
            return _range[i][j];
          else
            return _range[j][i];
        }

        mixin(defaultExprOps!(false));

      private:
        R _range;
    }
  
    return ToMatrix!()(range);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto arr = [[0, 1], [2, 3], [4, 5]];
    auto r1 = toMatrix!(3, 2, Major.row)(arr);
    static assert(isNarrowMatrix!(typeof(r1)));
    assert(equal!"equal(a, b)"(r1.toRange, arr));

    auto r2 = arr.toMatrix!(1, 1, Major.row);
    assert(r2[0] == 0);

    auto r3 = arr.toMatrix!(dynamic, 2, Major.row);
    assert(r3.congeal!(3, 2) == r1);

    auto r4 = arr.toMatrix!(2, dynamic, Major.row);
    assert(equal(r4.congeal!(2, 2)().toFlatten(), [0, 1, 2, 3]));

    auto r5 = arr.toMatrix!(dynamic, dynamic, Major.row);
    assert(r5 == r1);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto arr = [[0, 1], [2, 3], [4, 5]];
    auto r1 = arr.toMatrix!(2, 3, Major.column);
    assert(equal!"equal(a, b)"(r1.transpose.toRange, arr));
    assert(r1[0, 0] == 0); assert(r1[0, 1] == 2); assert(r1[0, 2] == 4);
    assert(r1[1, 0] == 1); assert(r1[1, 1] == 3); assert(r1[1, 2] == 5);

    auto r2 = arr.toMatrix!(1, 1, Major.column);
    assert(r2[0] == 0);

    auto r3 = arr.toMatrix!(dynamic, 3, Major.column);
    assert(r3 == r1);

    auto r4 = arr.toMatrix!(2, dynamic, Major.column);
    assert(equal(r4.transpose.toFlatten, [0, 1, 2, 3, 4, 5]));

    auto r5 = arr.toMatrix!(dynamic, dynamic, Major.column);
    assert(r5 == r1);
}


/**
単位行列
*/
@property
auto identity(E)()if(isScalar!E)
{
    static struct Identity()
    {
        enum rows = wild;
        enum cols = wild;


        static InferredResult inferSize(Msize_t i, Msize_t j)
        {
            if(i == wild && j == wild)
                return InferredResult(false);
            else if(i == wild || j == wild)
                return InferredResult(true, max(i, j), max(i, j));
            else if(i == j)
                return InferredResult(true, i, j);
            else
                return InferredResult(false);
        }


        E opIndex(size_t i, size_t j) inout
        {
            return (i == j) ? (cast(E)1) : (cast(E)0);
        }

        mixin(defaultExprOps!(true));
    }

    return Identity!()();
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto id = identity!int;

    static assert(typeof(id).inferSize(4, 4).isValid);
    static assert(!typeof(id).inferSize(1, 3).isValid);

    auto m1 = SMatrix!(int, 2, 2).init;
    m1.array[] = [0, 1, 2, 3];
    assert(equal((m1 * id).toFlatten, [0, 1, 2, 3]));

    auto id2 = id + id;
    static assert(isNarrowMatrix!(typeof(id2)));
    static assert(typeof(id2).inferSize(4, 4).isValid);

    auto id3 = id.congeal!(wild, 2) * id;
    static assert(id3.rows == 2);
    static assert(id3.cols == 2);
    assert(equal(id3.toFlatten, [1, 0, 0, 1]));

    auto ins = id2.congeal!(2, 2);
    static assert(isNarrowMatrix!(typeof(ins)));
    assert(equal(ins.toFlatten, [2, 0, 0, 2]));
}


/**
全要素が1な行列を返します。
*/
@property
auto ones(E)()if(isScalar!E)
{
    static struct Ones()
    {
        enum rows = wild;
        enum cols = wild;


        E opIndex(size_t i, size_t j) inout
        {
            return cast(E)1;
        }


        static InferredResult inferSize(Msize_t i, Msize_t j)
        {
            if(i == wild && j == wild)
                return InferredResult(false);
            else if(i == wild || j == wild)
                return InferredResult(true, max(i, j), max(i, j));
            else
                return InferredResult(true, i, j);
        }


        mixin(defaultExprOps!(true));
    }

    static assert(isNarrowMatrix!(Ones!()));

    return Ones!().init;
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto m1 = ones!float;
    assert(m1[0, 1] == 1);

    auto m3 = m1 * 3;
    assert(m3[0, 1] == 3);

    auto m9 = m3 * 3;
    assert(m9[0, 1] == 9);
}


/**
部分行列を返します
*/
auto sub(alias rArray, alias cArray, A)(A mat)
if(isArray!(typeof(rArray)) && isArray!(typeof(cArray)) && isNarrowMatrix!A && !isInferableMatrix!A
    && (hasDynamicRows!A || is(typeof({static assert(rArray.find!"a>=b"(A.rows).empty);})))
    && (hasDynamicColumns!A || is(typeof({static assert(cArray.find!"a>=b"(A.cols).empty);}))))
in{
    static if(hasDynamicRows!A)
        assert(rArray.find!"a>=b"(mat.rows).empty);
    static if(hasDynamicColumns!A)
        assert(cArray.find!"a>=b"(mat.cols).empty);
}
body{
  static if(rArray.length == 0 && cArray.length == 0)
    return mat;
  else
  {
    static struct Sub()
    {
      static if(rArray.length == 0)
        alias rows = _mat.rows;
      else
        enum rows = rArray.length;

      static if(cArray.length == 0)
        alias cols = _mat.cols;
      else
        enum cols = cArray.length;


        auto ref opIndex(size_t i, size_t j) inout
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
          static if(rArray.length && cArray.length)
            return _mat[rArray[i], cArray[j]];
          else static if(rArray.length)
            return _mat[rArray[i], j];
          else static if(cArray.length)
            return _mat[i, cArray[j]];
          else
            static assert(0);
        }


        mixin(defaultExprOps!(false));


      private:
        A _mat;
    }

    return Sub!()(mat);
  }
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto m1 = [[0, 1], [2, 3], [4, 5]].toMatrix!(3, 2, Major.row);
    auto s1 = m1.sub!([1, 2], [0]);
    static assert(s1.rows == 2);
    static assert(s1.cols == 1);

    assert(s1[0, 0] == 2);
    assert(s1[1, 0] == 4);


    auto m2 = [[0, 1], [2, 3], [4, 5]].toMatrix!(dynamic, dynamic, Major.row)();
    auto s2 = sub!((size_t[]).init, (size_t[]).init)(m2);
    assert(m1 == s2.congeal!(3, 2));


    auto m3 = identity!int.congeal!(2, 2)().sub!([0, 0, 0], [0, 0, 0])();
    assert(m3 == ones!int);
}


/**
swizzle : glm参照
*/
auto swizzle(A)(A mat) @property
if(isNarrowMatrix!A && !isInferableMatrix!A)
{
    static struct Swizzle()
    {
        auto opDispatch(string exp)()
        if((isVector!A ? (isSwizzleExp(exp) && isSwizzlable!A(exp)) : false) || (isSliceExp(exp) && isSlicable!(A, exp)))
        {
            static struct SwizzleResult()
            {
              static if(isSwizzleExp(exp))
              {
                static if(A.cols == 1)
                {
                  enum size_t rows = exp.length;
                  enum size_t cols = 1;
                }
                else
                {
                  enum size_t rows = 1;
                  enum size_t cols = exp.length;
                }


                auto ref opIndex(size_t i, size_t j) inout
                in{
                    assert((i+j) < (rows+cols-1));
                }
                body{
                    immutable size_t s = swizzleType(exp) == 'a' ? exp[i] - 'a' : (exp[i] == 'w' ? 3 : (exp[i] - 'x'));

                  static if(cols == 1)
                    return _mat[s, 0];
                  else
                    return _mat[0, s];
                }
              }
              else      // isSliceExp
              {
                private enum _swizzleExpSpec = spec(exp);
                enum size_t rows = mixin(_swizzleExpSpec.cs);
                enum size_t cols = mixin(_swizzleExpSpec.rs);


                auto ref opIndex(size_t i, size_t j) inout
                in{
                    assert(i < rows);
                    assert(j < cols);
                }
                body{
                    immutable size_t r = mixin(_swizzleExpSpec.rb) + i,
                                     c = mixin(_swizzleExpSpec.cb) + j;

                    return _mat[r, c];
                }
              }


                mixin(defaultExprOps!(false));

              private:
                A _mat;
            }


            return SwizzleResult!()(_mat);
        }

      private:
        A _mat;

      static:

        bool isSwizzleExp(string str) pure nothrow @safe
        {
            char d;
            foreach(c; str)
                if(!(('a' <= c && c <= 'h') || (c == 'x' || c == 'y' || c == 'z' || c == 'w')))
                    return false;
                else if('a' <= c && c <= 'h'){
                    if(d == char.init)
                        d = 'a';
                    else if(d != 'a')
                        return false;
                }else{
                    if(d == char.init)
                        d = 'x';
                    else if(d != 'x')
                        return false;
                }

            return true;
        }
        unittest{
            assert(isSwizzleExp("aaaaaaa"));
            assert(isSwizzleExp("aaaahaa"));
            assert(!isSwizzleExp("aaaaiaa"));
            assert(!isSwizzleExp("aaxa"));
            assert(isSwizzleExp("xxxx"));
            assert(isSwizzleExp("xyzw"));
            assert(!isSwizzleExp("xyza"));
        }


        // pure nothrow @safeにするため
        string find_(string str, char c) pure nothrow @safe
        {
            while(str.length && str[0] != c)
                str = str[1 .. $];
            return str;
        }


        string until_(string str, char c) pure nothrow @safe
        {
            foreach(i; 0 .. str.length)
                if(str[i] == c)
                    return str[0 .. i];

            return str;
        }


        // for matrix, format: r<bias>c<bias>m<row>x<cols>
        alias ExpSpec = Tuple!(string, "rb", string, "cb", string, "rs", string, "cs");


        ExpSpec spec(string exp) pure nothrow @safe
        {
            ExpSpec spec = ExpSpec("0", "0", "", "");
            {
                auto t = until_(until_(find_(exp, 'r'), 'c'), 'm');
                if(t.length > 1)        //r<Num>の形式なので、rを加えて1文字以上無いといけない
                    spec.rb = t[1 .. $];
            }

            {
                auto t = until_(find_(exp, 'c'), 'm');
                if(t.length > 1)        //c<Num>の形式なので、rを加えて1文字以上無いといけない
                    spec.cb = t[1 .. $];
            }

            {
                auto t = until_(find_(exp, 'm'), 'x');
                if(t.length > 1)        //m<Num>の形式なので、mを加えて1文字以上無いといけない
                    spec.rs = t[1 .. $];
            }

            {
                auto t = find_(exp, 'x');
                if(t.length > 1)
                    spec.cs = t[1 .. $];
            }
            return spec;
        }
        unittest{
            assert(spec("r1c1m1x1") == tuple("1", "1", "1", "1"));
            assert(spec("r1_100c21m5x5") == tuple("1_100", "21", "5", "5"));
            assert(spec("m1x2") == tuple("0", "0", "1", "2"));
        }


        bool isSliceExp(string exp) pure nothrow @safe
        {
            bool isAllDigit(string str) pure nothrow @safe
            {
                if(str.length == 0)
                    return false;

                foreach(c; str)
                    if(!(c.isDigit || c == '_'))
                        return false;
                return true;
            }

            auto sp = spec(exp);
            return (exp[0] == 'm' || exp[0] == 'r' || exp[0] == 'c') && isAllDigit(sp.rb) && isAllDigit(sp.cb) && isAllDigit(sp.rs) && isAllDigit(sp.cs);
        }
        unittest{
            assert(isSliceExp("r1c1m1x1"));
            assert(isSliceExp("r1_100c21m5x5"));
            assert(isSliceExp("m1x2"));
            assert(!isSliceExp("m2m1"));
            assert(!isSliceExp("_2mx1"));
            assert(isSliceExp("c1m1x1"));
        }


        // for vec
        char swizzleType(string exp) pure nothrow @safe
        {
            if('a' <= exp[0] && exp[0] <= 'h')
                return 'a';
            else
                return 'x';
        }
        unittest{
            assert(swizzleType("aaaaaaa") == 'a');
            assert(swizzleType("aaaahaa") == 'a');
            assert(swizzleType("xxxx") == 'x');
            assert(swizzleType("xyzv") == 'x');
        }


        bool isSwizzlable(T)(string exp) pure nothrow @safe
        {
            static if(isVector!T){
              enum size = T.length - 1;

              if(swizzleType(exp) == 'a'){
                  foreach(c; exp)
                      if(c > 'a' + size)
                          return false;
                  return true;
              }else{
                  foreach(c; exp)
                      if(c != 'x' && c != 'y' && c != 'z' && c != 'w')
                          return false;
                  return true;
              }
            }
            else
              return false;
        }
        unittest{
            alias V3 = SMatrix!(int, 1, 3);
            assert(isSwizzlable!V3("aaa"));
            assert(isSwizzlable!V3("abc"));
            assert(!isSwizzlable!V3("abd"));
            assert(isSwizzlable!V3("xyz"));
            assert(!isSwizzlable!V3("xyzv"));

            alias V4 = SMatrix!(int, 1, 4);
            assert(isSwizzlable!V4("xyzw"));
            assert(!isSwizzlable!V4("xyzv"));
        }


        bool isSlicable(T, string exp)() pure nothrow @safe
        {
          static if(isSliceExp(exp)){
            enum sp = spec(exp);
            return ((mixin(sp.rs) + mixin(sp.rb)) <= T.cols) && ((mixin(sp.cs) + mixin(sp.cb)) <= T.rows);
          }
          else
            return false;
        }
        unittest{
            alias M33 = SMatrix!(int, 3, 3);
            assert(isSlicable!(M33, "m3x3"));
            assert(isSlicable!(M33, "m1x3"));
            assert(isSlicable!(M33, "r1m2x3"));
            assert(isSlicable!(M33, "c1m2x2"));
        }
    }


    return Swizzle!()(mat);
}

unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto org = matrix!((i, j) => i * 3 + j)();
    SMatrix!(int, 4, 4) a = org;
    auto m = a.swizzle.m2x2;
    static assert(isNarrowMatrix!(typeof(m)));
    assert(m == org);


    auto m2 = a.swizzle.r1c1m2x2;
    static assert(isNarrowMatrix!(typeof(m2)));
    assert(m2 == matrix!((i, j) => (i+1)*3 + j + 1)());


    assert(a.swizzle.m1x4.swizzle.xyzw == a.swizzle.m1x4);
}


/**
行ベクトルのランダムアクセスレンジ
*/
auto rowVectors(A)(A mat) @property
if(isNarrowMatrix!A && !isInferableMatrix!A)
{
    static struct RowVectors()
    {
        auto front() @property { return this.opIndex(0); }
        auto back() @property { return this.opIndex(_end-1); }
        void popFront() @property { ++_idx; }
        void popBack() @property { --_end; }
        bool empty() @property const { return _idx == _end; }
        auto save() @property { return this; }



        auto opIndex(size_t i)
        {
            static struct RowVectorByIndex()
            {
                alias rows = _m.rows;
                enum cols = 1;


                auto ref opIndex(size_t i, size_t j) inout
                in{
                    assert(i < rows);
                    assert(j < cols);
                }
                body{
                    return _m[i, _idx];
                }


                mixin(defaultExprOps!(false));


                size_t _idx;
                A _m;
            }


            return RowVectorByIndex!()(i + _idx, _m);
        }


        size_t length() const @property
        {
            return _end - _idx;
        }


        alias opDispatch = length;

      private:
        size_t _idx;
        size_t _end;
        A _m;
    }


    return RowVectors!()(0, mat.cols, mat);
}
unittest
{
    real[3][3] mStack = [[1, 2, 2],
                         [2, 1, 1],
                         [2, 2, 2]];

    auto r = matrix(mStack).rowVectors;

    static assert(isRandomAccessRange!(typeof(r)));

    foreach(i; 0 .. 3)
        foreach(j; 0 .. 3)
            assert(r[i][j] == mStack[j][i]);
}


/**
行ベクトルのランダムアクセスレンジ
*/
auto columnVectors(A)(A mat) @property
if(isNarrowMatrix!A && !isInferableMatrix!A)
{
    static struct ColumnVectors()
    {
        auto front() @property { return this.opIndex(0); }
        auto back() @property { return this.opIndex(_end-1); }
        void popFront() @property { ++_idx; }
        void popBack() @property { --_end; }
        bool empty() @property const { return _idx == _end; }
        auto save() @property { return this; }



        auto opIndex(size_t i)
        {
            static struct ColumnVectorByIndex()
            {
                enum rows = 1;
                alias cols = _m.cols;


                auto ref opIndex(size_t i, size_t j) inout
                in{
                    assert(i < rows);
                    assert(j < cols);
                }
                body{
                    return _m[_idx, j];
                }


                mixin(defaultExprOps!(false));


                size_t _idx;
                A _m;
            }

            return ColumnVectorByIndex!()(i + _idx, _m);
        }


        size_t length() const @property
        {
            return _end - _idx;
        }


        alias opDispatch = length;

      private:
        size_t _idx;
        size_t _end;
        A _m;
    }


    return ColumnVectors!()(0, mat.rows, mat);
}
unittest
{
    real[3][3] mStack = [[1, 2, 2],
                         [2, 1, 1],
                         [2, 2, 2]];

    auto r = matrix(mStack).columnVectors;

    static assert(isRandomAccessRange!(typeof(r)));

    foreach(i; 0 .. 3)
        foreach(j; 0 .. 3)
            assert(r[i][j] == mStack[i][j]);
}


/**
行列の跡(trace)を返します。正方行列についてのみ定義されます
*/
ElementType!A trace(A)(A mat)
if(isNarrowMatrix!A && !isInferableMatrix!A && (!(hasStaticRows!A && hasStaticColumns!A) || is(typeof({static assert(A.rows == A.cols);}))))
{
    alias ElementType!A T;
    T sum = cast(T)0;

    foreach(i; 0 .. mat.rows)
        sum += mat[i, i];

    return sum;
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto m = SMatrix!(int, 2, 2)();
    m[0, 0] = 0; m[0, 1] = 1;
    m[1, 0] = 2; m[1, 1] = 3;

    auto tr = m.trace;
    assert(tr == 3);
}


auto dot(V1, V2)(V1 vec1, V2 vec2)
if(isVector!V1 && isVector!V2 && (!(hasStaticLength!V1 && hasStaticLength!V2) || is(typeof({static assert(V1.length == V2.length);}))))
in{
    static if(!(hasStaticLength!V1 && hasStaticLength!V2))
    {
        assert(vec1.length == vec2.length);
    }
}
body{
    alias ElementType!V1 T;
    T sum = cast(T)0;

    foreach(i; 0 .. vec1.length)
        sum += vec1[i] * vec2[i];

    return sum;
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto rv = SRVector!(int, 3)(),
         cv = SCVector!(int, 3)();

    rv.array[] = [0, 1, 2];
    cv.array[] = [1, 2, 3];

    assert((rv * cv)[0] == 8);  //8
    assert(rv.dot(cv) == 8);
    assert(cv.dot(rv) == 8);

    assert(rv.dot(rv) == 5);
    assert(cv.dot(cv) == 14);
}


/**
ベクトル同士のクロス積
*/
auto cross(Major mjr = Major.column, V1, V2)(V1 vec1, V2 vec2)
if(isVector!V1 && isVector!V2 && (hasStaticLength!V1 && is(typeof({static assert(V1.length == 3);})))
                              && (hasStaticLength!V2 && is(typeof({static assert(V2.length == 3);}))))
in{
    assert(vec1.length == 3);
    assert(vec2.length == 3);
}
body{
    static struct CrossResult
    {
        enum rows = mjr == Major.row ? 1 : 3;
        enum cols = mjr == Major.row ? 3 : 1;


        auto opIndex(size_t i, size_t j) const
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            switch(i + j){
              case 0: return _v1[1] * _v2[2] - _v1[2] * _v2[1];
              case 1: return _v1[2] * _v2[0] - _v1[0] * _v2[2];
              case 2: return _v1[0] * _v2[1] - _v1[1] * _v2[0];
              default: assert(0);
            }
        }

        mixin(defaultExprOps!(false));

      private:
        V1 _v1;
        V2 _v2;
    }

    return CrossResult(vec1, vec2);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto rv = SVector!(int, 3)(),
         cv = SVector!(int, 3)();

    rv.array[] = [0, 1, 2];
    cv.array[] = [1, 2, 3];

    auto cp = rv.cross(cv);

    static assert(isVector!(typeof(cp)));
    static assert(hasStaticLength!(typeof(cp)));
    static assert(hasStaticRows!(typeof(cp)));
    static assert(hasStaticColumns!(typeof(cp)));

    assert(cp[0] == -1);
    assert(cp[1] == 2);
    assert(cp[2] == -1);
}


/**
直積
*/
auto cartesian(V1, V2)(V1 vec1, V2 vec2)
if(isVector!V1 && isVector!V2)
{
    static struct Cartesian()
    {
        alias rows = _vec1.length;
        alias cols = _vec2.length;


        auto opIndex(size_t i, size_t j) const
        in{
            assert(i < rows);
            assert(j < cols);
        }
        body{
            return _vec1[i] * _vec2[j];
        }


        mixin(defaultExprOps!(false));


      private:
        V1 _vec1;
        V2 _vec2;
    }


    return Cartesian!()(vec1, vec2);
}
unittest{
    //scope(failure) {writefln("Unittest failure :%s(%s)", __FILE__, __LINE__); stdout.flush();}
    //scope(success) {writefln("Unittest success :%s(%s)", __FILE__, __LINE__); stdout.flush();}


    auto v1 = [0, 1, 2, 3].toMatrix!(3, 1);
    auto v2 = [2, 3, 4, 5].toMatrix!(1, 2);

    assert(v1.cartesian(v2) == v1 * v2);
    static assert(hasStaticRows!(typeof(v1.cartesian(v2))));
    static assert(hasStaticColumns!(typeof(v1.cartesian(v2))));
}



/**
置換行列を作ります
*/
auto permutation(size_t size = wild, size_t)(const size_t[] pos) pure nothrow @safe
in{
    foreach(e; pos)
        assert(e < pos.length);

  static if(size != wild)
    assert(pos.length == size);
}
body{
    static struct Permutation
    {
      static if(size != wild)
        enum rows = size;
      else
        size_t rows() pure nothrow @safe const @property { return _pos.length; }

        alias cols = rows;


        auto opIndex(size_t i, size_t j) pure nothrow @safe const 
        {
            return _pos[i] == j ? 1 : 0;
        }


        mixin(defaultExprOps!(false));


        @property auto inverse() pure nothrow @safe const
        {
            static struct InvPermutation
            {
                static if(size != wild)
                enum rows = size;
              else
                size_t rows() pure nothrow @safe const @property { return _pos.length; }

                alias cols = rows;


                auto opIndex(size_t i, size_t j) pure nothrow @safe const
                {
                    return _pos[j] == i ? 1 : 0;
                }


                mixin(defaultExprOps!(false));


                @property auto inverse() pure nothrow @safe const
                {
                    return Permutation(_pos);
                }


              private:
                const(size_t)[] _pos;
            }


            return InvPermutation(_pos);
        }


        @property const(size_t)[] exchangeTable() pure nothrow @safe const
        {
            return _pos;
        }


      private:
        const(size_t)[] _pos;
    }


    return Permutation(pos);
}


template isPermutationMatrix(A)
{
    enum isPermutationMatrix = isNarrowMatrix!A && is(Unqual!(typeof(A.init.exchangeTable)) : size_t[]);
}



struct PLU(M)
if(isNarrowMatrix!M && !isInferableMatrix!M && isFloatingPoint!(ElementType!M))
{
  static if(hasStaticRows!M)
    alias rows = lu.rows;
  else
    @property size_t rows() pure nothrow @safe const { return piv.length; }

    alias cols = rows;

    size_t[] piv;
    bool isEvenP;
    M lu;


    auto p() pure nothrow @safe const
    {
        return permutation(piv);
    }



    auto l() pure nothrow @safe
    {
        static struct L()
        {
          static if(hasStaticRows!M)
            enum rows = M.rows;
          else static if(hasStaticColumns!M)
            enum rows = M.cols;
          else
            size_t rows() const  @property { return _lu.rows; }

            alias cols = rows;


            auto opIndex(size_t i, size_t j) const
            in{
                assert(i < rows);
                assert(j < cols);
            }
            body{
                if(i == j)
                    return 1;
                else if(i < j)
                    return 0;
                else
                    return _lu[i, j];
            }


            mixin(defaultExprOps!(false));


          private:
            M _lu;
        }


        return L!()(lu);
    }



    auto u() pure nothrow @safe
    {
        static struct U()
        {
          static if(hasStaticRows!M)
            enum rows = M.rows;
          else static if(hasStaticColumns!M)
            enum rows = M.cols;
          else
            size_t rows() const  @property { return _lu.rows; }

            alias cols = rows;


            auto opIndex(size_t i, size_t j) const
            in{
                assert(i < rows);
                assert(j < cols);
            }
            body{
                if(i > j)
                    return 0;
                else
                    return _lu[i, j];
            }


            mixin(defaultExprOps!(false));


          private:
            M _lu;
        }


        return U!()(lu);
    }


    /**
    Ax = bとなるxを解きます
    */
    auto solveInPlace(V)(V b)
    if(isVector!V && isFloatingPoint!(ElementType!V) && is(typeof({b[0] = real.init;})))
    in{
        assert(b.length == rows);
    }
    body{
        /*
        Ax = bの両辺にPをかけることにより
        PAx = Pbとなるが、LU分解によりPA = LUであるから、
        LUx = Pbである。

        ここで、y=Uxとなるyベクトルを考える。
        Ly = Pbである。
        Lは下三角行列なので、簡単にyベクトルは求まる。

        次に、Ux=yより、xベクトルを同様に求めれば良い
        */

        immutable size_t size = rows;

        // b <- Pb
        b = this.p * b;

        // Ly=Pbからyを求める
        foreach(i; 1 .. size)
            foreach(j; 0 .. i)
                b[i] -= lu[i, j] * b[j];

        // Ux=Py
        foreach_reverse(i; 0 .. size){
            foreach_reverse(j; i+1 .. size)
                b[i] -= lu[i, j] * b[j];

            b[i] /= lu[i, i];
        }
    }


    /**
    逆行列を求める
    */
    M inverse() @property
    {
        immutable size_t size = lu.rows;

        M m = identity!(ElementType!M)().congeal(size, size);

        foreach(i; 0 .. lu.cols)
            this.solveInPlace(m.rowVectors[i]);

        return m;
    }


    auto det() @property
    {
        ElementType!M dst = isEvenP ? 1 : -1;
        foreach(i; 0 .. rows)
            dst *= lu[i, i];

        return dst;
    }
}


/**
In-Placeで、行列をLU分解します。

"Numerical Recipes in C"
*/
PLU!(A) pluDecomposeInPlace(A)(A m)
if(isNarrowMatrix!A && isFloatingPoint!(ElementType!A) && hasLvalueElements!A && (!hasStaticRows!A || !hasStaticColumns!A || is(typeof({static assert(A.rows == A.cols);}))))
in{
    assert(m.rows == m.cols);
}
body{
    immutable size = m.rows;
    scope vv = new real[size];
    bool isEvenP;
    size_t[] idx = new size_t[size];

    foreach(i, ref e; idx)
        e = i;

    foreach(i; 0 .. size){
        real big = 0;

        foreach(j; 0 .. size){
            immutable temp = m[i, j].abs();
            if(temp > big)
                big = temp;
        }

        if(big == 0) enforce("Input matrix is a singular matrix");

        vv[i] = 1.0 / big;
    }


    foreach(j; 0 .. size){
        foreach(i; 0 .. j){
            real sum = m[i, j];
            foreach(k; 0 .. i) sum -= m[i, k] * m[k, j];
            m[i, j] = sum;
        }

        real big = 0;
        size_t imax;
        foreach(i; j .. size){
            real sum = m[i, j];
            foreach(k; 0 .. j) sum -= m[i, k] * m[k, j];
            m[i, j] = sum;

            immutable dum = vv[i] * sum.abs();
            if(dum >= big){
                big = dum;
                imax = i;
            }
        }

        if(j != imax){
            foreach(k; 0 .. size)
                swap(m[imax, k], m[j, k]);

            isEvenP = !isEvenP;
            vv[imax] = vv[j];

            swap(idx[j], idx[imax]);
        }

        //idx[j] = imax;

        //if(m[j, j] == 0) m[j, j] = 1.0E-20;

        if(j != size-1){
            immutable dum = 1 / m[j, j];
            foreach(i; j+1 .. size)
                m[i, j] *= dum;
        }
    }

    return PLU!A(idx, isEvenP, m);
}
unittest{
    real[3][3] mStack = [[1, 2, 2],
                         [2, 1, 1],
                         [2, 2, 2]];

    auto m = matrix(mStack);

    SMatrix!(real, 3, 3) org = m;
    auto plu = m.pluDecomposeInPlace();

    SMatrix!(real, 3, 3) result = plu.p.inverse * plu.l * plu.u;

    foreach(i; 0 .. 3) foreach(j; 0 .. 3)
        assert(approxEqual(result[i, j], org[i, j]));   // A = P^(-1)LU

    assert(approxEqual(plu.det, 0));
}

unittest{
    real[3][3] mStack = [[2, 4, 2],
                         [4, 10, 3],
                         [3, 7, 1]];

    auto m = mStack.matrix();

    SMatrix!(real, 3, 3) org = m;
    auto plu = m.pluDecomposeInPlace();

    auto v = matrix!(3, 1)(cast(real[])[8, 17, 11]);

    plu.solveInPlace(v);
    foreach(i; 0 .. 3)
        assert(approxEqual(v[i], 1));
}

unittest{
    real[3][3] mStack = [[2, 4, 2],
                         [4, 10, 3],
                         [3, 7, 1]];

    auto m = mStack.matrix();

    SMatrix!(real, 3, 3) org = m;
    auto plu = m.pluDecomposeInPlace();
    auto iden = org * plu.inverse;
    
    foreach(i; 0 .. 3)
        foreach(j; 0 .. 3)
            assert(approxEqual(iden[i, j], identity!real[i, j]));
}


/**
ベクトルのノルムを計算します
*/
auto norm(real N = 2, V)(V v)
{
    real sum = 0;
    foreach(i; 0 .. v.length)
        sum += v[i] ^^ N;
    return sum ^^ (1/N);
}
