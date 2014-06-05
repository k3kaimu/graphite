// Written in D the D Programming Language
/**
任意の構造体やクラスをJSONに変換したり、その逆変換を行う
*/
module graphite.utils.json;

import std.algorithm;
import std.array;
import std.complex;
import std.conv;
import std.exception;
import std.json;
import std.process;
import std.range;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;
import std.variant;


private template _StaticIota(size_t M, size_t N)
if(M <= N)
{
    static if(M == N)
        alias _StaticIota = TypeTuple!();
    else
        alias _StaticIota = TypeTuple!(M, _StaticIota!(M+1, N));
}


class JSONException : Exception
{
    this(string msg, string file = null, size_t line = 0)
    {
        super(msg, file, line);
    }
}


template JSONEnv(alias overloads)
{
    /**

    */
    void fromJSONValue(T)(JSONValue json, ref T dst)
    {
        static if(is(typeof(overloads.fromJSONValueImpl(json, dst))))
            overloads.fromJSONValueImpl(json, dst);
        else static if(is(typeof(T.fromJSONValueImpl(json)) : T))
            dst = T.fromJSONValueImpl(json);
        else
            fromJSONValueImpl(json, dst);
    }


    ///
    JSONValue toJSONValue(T)(auto ref T t)
    {
        static if(is(typeof(overloads.toJSONValueImpl(t)) == JSONValue))
            return overloads.toJSONValueImpl(forward!t);
        else static if(is(typeof(t.toJSONValueImpl()) == JSONValue))
            return t.toJSONValueImpl();
        else
            return toJSONValueImpl(forward!t);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == typeof(null)))
    out(result){
        assert(result.type == JSON_TYPE.NULL);
    }
    body{
        return JSONValue(null);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == string))
    out(result){
        assert(result.type == JSON_TYPE.STRING);
    }
    body{
        return JSONValue(value);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isUnsigned!T && isIntegral!T)
    out(result){
        assert(result.type == JSON_TYPE.UINTEGER);
    }
    body{
        return JSONValue(value);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isSigned!T && isIntegral!T)
    out(result){
        assert(result.type == JSON_TYPE.INTEGER);
    }
    body{
        return JSONValue(value);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == bool))
    out(result){
        assert(result.type == JSON_TYPE.TRUE || result.type == JSON_TYPE.FALSE);
    }
    body{
        return JSONValue(value);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isFloatingPoint!T)
    out(result){
        assert(result.type == JSON_TYPE.FLOAT);
    }
    body{
        return JSONValue(value);
    }


    ///
    JSONValue toJSONValueImpl(R)(R range)
    if(isInputRange!R && !isSomeString!R)
    out(result){
        assert(result.type == JSON_TYPE.ARRAY);
    }
    body{
        auto app = appender!(JSONValue[])();

        app.put(range.map!(a => toJSONValue(a)));

        return JSONValue(app.data);
    }


    ///
    JSONValue toJSONValueImpl(AA)(AA aa)
    if(isAssociativeArray!AA)
    out(result){
        assert(result.type == JSON_TYPE.OBJECT);
    }
    body{
        JSONValue[string] dst;
        foreach(k, v; aa){
            static if(is(typeof(k) : string))
                dst[k] = toJSONValue(v);
            else
                dst[k.to!string()] = toJSONValue(v);
        }

        return JSONValue(dst);
    }



    private string createFromJSONValueExceptionMsg(T)(JSONValue json)
    {
        return "cannot convert to '" ~ T.stringof ~ "' from "`"` ~ toJSON(&json) ~ `"`;
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(is(T == typeof(null)))
    {
        enforceEx!JSONException(json.type == JSON_TYPE.NULL, createFromJSONValueExceptionMsg!T(json));
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(is(T == string))
    {
        enforceEx!JSONException(json.type == JSON_TYPE.STRING, createFromJSONValueExceptionMsg!T(json));
        dst = json.str;
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isIntegral!T && isUnsigned!T)
    {
        enforceEx!JSONException(json.type == JSON_TYPE.UINTEGER || json.type == JSON_TYPE.INTEGER, createFromJSONValueExceptionMsg!T(json));

        if(json.type == JSON_TYPE.UINTEGER)
            dst = json.uinteger.to!T();
        else
            dst = json.integer.to!T();
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isIntegral!T && isSigned!T)
    {
        enforceEx!JSONException(json.type == JSON_TYPE.INTEGER || json.type == JSON_TYPE.UINTEGER, createFromJSONValueExceptionMsg!T(json));

        if(json.type == JSON_TYPE.INTEGER)
            dst = json.integer.to!T();
        else
            dst = json.uinteger.to!T();
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(is(T == bool))
    {
        enforceEx!JSONException(json.type == JSON_TYPE.TRUE || json.type == JSON_TYPE.FALSE, createFromJSONValueExceptionMsg!T(json));
        dst = json.type == JSON_TYPE.TRUE;
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isFloatingPoint!T)
    {
        enforceEx!JSONException(json.type == JSON_TYPE.FLOAT
                             || json.type == JSON_TYPE.INTEGER
                             || json.type == JSON_TYPE.UINTEGER, createFromJSONValueExceptionMsg!T(json));
        
        if(json.type == JSON_TYPE.FLOAT)
            dst = json.floating;
        else if(json.type == JSON_TYPE.INTEGER)
            dst = json.integer;
        else
            dst = json.uinteger;
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isArray!T && !isSomeString!T)
    {
        enforceEx!JSONException(json.type == JSON_TYPE.ARRAY, createFromJSONValueExceptionMsg!T(json));

        T data = new T(json.array.length);

        foreach(i, e; json.array){
            typeof(data[i]) elem;
            fromJSONValue(e, elem);
            data[i] = elem;
        }

        dst = data;
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isInputRange!T && isOutputRange!(T, Unqual!(ElementType!T)) && !isArray!T)
    {
        enforceEx!JSONException(json.type == JSON_TYPE.ARRAY, createFromJSONValueExceptionMsg!T(json));

        foreach(e; json.array){
            alias Elem = Unqual!(ElementType!T);
            Elem elem;
            fromJSONValue(e, elem);
            dst.put(elem);
        }
    }


    ///
    void fromJSONValueImpl(T)(JSONValue json, ref T dst)
    if(isAssociativeArray!(T))
    {
        enforceEx!JSONException(json.type == JSON_TYPE.OBJECT, createFromJSONValueExceptionMsg!T(json));

        alias V = typeof(T.init.values[0]);
        alias K = typeof(T.init.keys[0]);

        foreach(k, v; json.object){
            V elem;
            fromJSONValue(v, elem);
            dst[k.to!K] = elem;
        }
    }
}


/**
任意のユーザー定義型をJSONでのObjectに変換する際に便利なテンプレート
*/
mixin template JSONObject(fields...)
if(fields.length && fields.length % 2 == 0)
{
    JSONValue toJSONValueImpl() @property
    {
        JSONValue[string] aa;

        foreach(i; _StaticIota!(0, fields.length))
        {
            static if(i % 2 == 0)
            {
                static assert(is(typeof(fields[i]) == string));

                static if(is(typeof(mixin(fields[i+1]))))
                    aa[fields[i]] = toJSONValue(mixin(fields[i+1]));
                else
                    aa[fields[i]] = toJSONValue(fields[i+1]);
            }
        }

        return JSONValue(aa);
    }


    private ref typeof(this) fromJSONValueImpl_(JSONValue jv)
    {
        foreach(i; _StaticIota!(0, fields.length))
        {
            static if(i % 2 == 0)
            {
                static if(is(typeof(&(fields[i+1]())) == U*, U))
                    fromJSONValue(jv.object[fields[i]], fields[i+1]());
                else static if(is(typeof(&(fields[i+1])) == U*, U))
                    fromJSONValue(jv.object[fields[i]], fields[i+1]);
                else static if(is(typeof(&(mixin(fields[i+1]))) == U*, U) &&
                               !is(typeof(&(mixin(fields[i+1]))) == V function(W), V, W...))
                {
                    fromJSONValue(jv.object[fields[i]], mixin(fields[i+1]));
                }
                else
                {
                    static if(is(typeof(fields[i+1]())))    // property
                        alias X = typeof({auto x = fields[i+1](); return x;}());
                    else static if(is(typeof(mixin(fields[i+1])())))    // property(string)
                        alias X = typeof(mixin(fields[i+1])());
                    else
                        alias X = ParameterTypeTuple!(fields[i+1])[0];

                    X x;
                    fromJSONValue(jv.object[fields[i]], x);

                    static if(is(typeof(mixin(fields[i+1]))))
                        mixin(fields[i+1]) = x;
                    else
                        fields[i+1](x);
                }
            }
        }


        return this;
    }


    static typeof(this) fromJSONValueImpl(JSONValue jv)
    {
        typeof(this) dst;
        dst.fromJSONValueImpl_(jv);
        return dst;
    }
}


///
unittest{
    // Custom JSON Convertor
    // ユーザーは、任意の型をJSONへ変換するための変換器を定義できる
    static struct CustomJSONConvertor
    {
        static { mixin JSONEnv!null _dummy; }

        static JSONValue toJSONValueImpl(string str)
        {
            return _dummy.toJSONValueImpl("Custom Convertor-String : " ~ str);
        }


        static void fromJSONValueImpl(JSONValue json, ref string str)
        {
            assert(json.type == JSON_TYPE.STRING, "Error");
            str = json.str.find(" : ").drop(3);
        }
    }


    // グローバルなsetterとgetterだと仮定
    static struct Foo
    {
        int gloF() @property { return _gloF; }
        void gloF(int a) @property { _gloF = a; }

        static int _gloF = 12345;
    }


    // グローバル変数だと仮定
    static string gloG = "global variable";


    // JSONへ変換したり、JSONから変換する対象のオブジェクト
    static struct S1
    {
        // JSON Convertorの定義
        // 通常はモジュールで定義すればよい
        static {
            mixin JSONEnv!CustomJSONConvertor;
        }


        // refで返すプロパティ
        ref real flt() @property
        {
            return _flt;
        }


        // getter
        int[] arr() @property
        {
            return _arr;
        }

        // setter
        void arr(int[] arr) @property
        {
            _arr = arr;
        }


        // JSONでのオブジェクトの定義
        mixin JSONObject!("intA", a,                // メンバ変数
                          "strB", "b",              // メンバ変数(文字列)
                          "fltC", flt,              // refを返すメンバ関数(プロパティ)
                          "arrD", "arr",            // setter, getter
                          "aasE", "aas",            // static setter, getter
                          "gloF", "Foo.init.gloF",  // global setter, getter
                          "gloG", gloG,             // グローバル変数など外部スコープの変数
                          );


      private:
        int a;
        string b;
        real _flt;
        int[] _arr;


      static:

        // staticなgetter
        int[int] aas() @property
        {
            return [1 : 2, 2 : 3, 3 : 4, 4 : 5];
        }


        // staticなsetter
        void aas(int[int] aa) @property
        {}
    }

    auto s1 = S1(12, "foo", 2.0, [1, 2, 3, 4]);
    auto jv = S1.toJSONValue(s1);

    auto jvtext = parseJSON(`{"gloF":12345,"strB":"Custom Convertor-String : foo","fltC":2,"gloG":"Custom Convertor-String : global variable","intA":12,"aasE":{"4":5,"1":2,"2":3,"3":4},"arrD":[1,2,3,4]}`);
    assert(toJSON(&jv) == toJSON(&jvtext));

    auto s2 = S1.fromJSONValueImpl(jv);
    auto s3 = S1.fromJSONValueImpl(jvtext);

    assert(s1 == s2);
    assert(s2 == s3);

    assert(Foo.init.gloF == 12345);
    assert(gloG == "global variable");
}


/**
JSON Objectを構築します
*/
struct JSONObjectType(alias jsonEnv, fields...)
if(fields.length && isValidJSONObjectTypeFields!fields)
{
    static {
        mixin JSONEnv!jsonEnv;
    }

    mixin(genStructField);
    mixin(`mixin JSONObject!(` ~ genMixinFields ~ `);`);

  private:
  static:
    string genStructField()
    {
        string dst;

        foreach(i; _StaticIota!(0, fields.length))
        {
            static if(i % 2 == 0)
            {
                dst ~= fields[i].stringof;  // type
                dst ~= " ";
                dst ~= fields[i+1];         // identifier
                dst ~= ";\n";
            }
        }

        return dst;
    }


    string genMixinFields()
    {
        string dst;

        foreach(i; _StaticIota!(0, fields.length))
        {
            static if(i % 2 == 0)
            {
                dst ~= `"` ~ fields[i+1] ~ `",`;     // tag
                dst ~= `"` ~ fields[i+1] ~ `",`;     // identifier
            }
        }

        return dst;
    }
}


unittest{
    JSONObjectType!(null,
                    int,        "intA",
                    string,     "strB",
                    float,      "fltC") jot;

    jot.intA = 12;
    jot.strB = "foo-bar";
    jot.fltC = 12.5;

    auto x = jot.toJSONValueImpl();
    auto y = parseJSON(`{"strB":"foo-bar","fltC":12.5,"intA":12}`);
    assert(toJSON(&x) == toJSON(&y));

    assert(typeof(jot).fromJSONValueImpl(x) == jot);
    assert(typeof(jot).fromJSONValueImpl(y) == jot);
}


private
template isValidJSONObjectTypeFields(fields...)
{
    //template isValidImpl(T, string name) { enum isValidImpl = true; }
    enum isValidImpl_(T, string name) = name.length;
    enum isValidImpl(X...) = is(typeof({static assert(isValidImpl_!X);}));

    static if(fields.length)
    {
        static if(fields.length % 2 == 0)
            enum isValidJSONObjectTypeFields = isValidImpl!(fields[0 .. 2])
                                            && isValidJSONObjectTypeFields!(fields[2 .. $]);
        else
            enum isValidJSONObjectTypeFields = false;
    }
    else
        enum isValidJSONObjectTypeFields = true;
}
