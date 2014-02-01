// Written in D the D Programming Language
/**
任意の構造体やクラスをJSONに変換したり、その逆変換を行う
*/
//module graphite.utils.json;

import std.algorithm;
import std.array;
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
    JSONValue toJSONValue(T)(T t)
    {
        static if(is(typeof(overloads.toJSONValueImpl(t)) == JSONValue))
            return overloads.toJSONValueImpl(t);
        else static if(is(typeof(t.toJSONValueImpl()) == JSONValue))
            return t.toJSONValueImpl();
        else
            return toJSONValueImpl(t);
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == typeof(null)))
    out(result){
        assert(result.type == JSON_TYPE.NULL);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.NULL;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == string))
    out(result){
        assert(result.type == JSON_TYPE.STRING);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.STRING;
        dst.str = value;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isUnsigned!T && isIntegral!T)
    out(result){
        assert(result.type == JSON_TYPE.UINTEGER);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.UINTEGER;
        dst.uinteger = value;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isSigned!T && isIntegral!T)
    out(result){
        assert(result.type == JSON_TYPE.INTEGER);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.INTEGER;
        dst.integer = value;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(is(T == bool))
    out(result){
        assert(result.type == JSON_TYPE.TRUE || result.type == JSON_TYPE.FALSE);
    }
    body{
        JSONValue dst = void;
        dst.type = value ? JSON_TYPE.TRUE : JSON_TYPE.FALSE;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(T)(T value)
    if(isFloatingPoint!T)
    out(result){
        assert(result.type == JSON_TYPE.FLOAT);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.FLOAT;
        dst.floating = value;

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(R)(R range)
    if(isInputRange!R && !isSomeString!R)
    out(result){
        assert(result.type == JSON_TYPE.ARRAY);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.ARRAY;
        dst.array = null;
        foreach(e; range)
            dst.array ~= toJSONValue(e);

        return dst;
    }


    ///
    JSONValue toJSONValueImpl(AA)(AA aa)
    if(isAssociativeArray!AA)
    out(result){
        assert(result.type == JSON_TYPE.OBJECT);
    }
    body{
        JSONValue dst = void;
        dst.type = JSON_TYPE.OBJECT;
        dst.object = null;

        foreach(k, v; value){
            static if(is(typeof(k) : string))
                dst.object[k] = toJSONValue(v);
            else
                dst.object[k.to!string()] = toJSONValue(v);
        }

        return dst;
    }



    private string createFromJSONValueExceptionMsg(T)(JSONValue json)
    {
        return "cannot convert to '" ~ T.stringof ~ "' from "`"` ~ toJSON(&json) ~ `"`;
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
        enforceEx!JSONException(json.type == JSON_TYPE.FLOAT, createFromJSONValueExceptionMsg!T(json));
        dst = json.floating;
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


mixin template JSONObject(fields...)
if(fields.length && fields.length % 2 == 0)
{
    JSONValue toJSONValueImpl() @property
    {
        JSONValue jv = void;
        jv.type = JSON_TYPE.OBJECT;
        jv.object = null;

        foreach(i; _StaticIota!(0, fields.length))
        {
            static if(i % 2 == 0)
            {
                static assert(is(typeof(fields[i]) == string));

                static if(is(typeof({jv.object[fields[i]] = toJSONValue(mixin(fields[i+1]));})))
                    jv.object[fields[i]] = toJSONValue(mixin(fields[i+1]));
                else
                    jv.object[fields[i]] = toJSONValue(fields[i+1]);
            }
        }

        return jv;
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
                else static if(is(typeof(&(mixin(fields[i+1]))) == U*, U))
                    fromJSONValue(jv.object[fields[i]], mixin(fields[i+1]));
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


unittest{
    import std.stdio;


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


    static struct S1
    {
        static {
            mixin JSONEnv!CustomJSONConvertor;
        }


        ref real flt() @property
        {
            return _flt;
        }


        int[] arr() @property
        {
            return _arr;
        }


        void arr(int[] arr) @property
        {
            _arr = arr;
        }


        mixin JSONObject!("intA", a,
                          "strB", "b",
                          "fltC", flt,          // property
                          "arrD", "arr",        // property
                          );


      private:
        int a;
        string b;
        real _flt;
        int[] _arr;
    }

    auto s1 = S1(12, "foo", 2.0, [1, 2, 3, 4]);
    auto jv = S1.toJSONValue(s1);
    auto str = toJSON(&jv);
    writeln(str);               // {"strB":"Custom Convertor-String : foo","fltC":2,"intA":12,"arrD":[1,2,3,4]}

    auto s2 = S1.fromJSONValueImpl(jv);
    writeln(s2);                // S1(12, "foo", 2, [1, 2, 3, 4])
}
