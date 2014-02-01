module graphite.twitter.json;


JSONValue toJSONValueObject(T...)(T args)
if(T.length > 1 && T.length % 2 == 0)
{
    JSONValue jv = void;
    jv.type = JSON_TYPE.OBJECT;
    jv.object = null;

    foreach(i; staticIota!(T.length/2))
        jv[args[i*2]] = args[i*2+1].toJSONValue();

    return jv;
}


JSONValue toJSONValue(T : typeof(null))(T value)
{
    JSONValue dst = void;
    dst.type = JSON_TYPE.NULL;

    return dst;
}


JSONValue toJSONValue(T : string)(T value)
out(result){
    assert(result.type == JSON_TYPE.STRING);
}
body{
    JSONValue dst = void;
    dst.type = JSON_TYPE.STRING;
    dst.str = value;

    return dst;
}


JSONValue toJSONValue(T)(T value)
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



T fromJSONValue(T)(JSONValue json);



/+
package:

// for UDA
struct ObjectInJSON
{
    struct Name
    {
        string name;
    }
}


template isObjectInJSON(alias field)
{
    enum isObjectInJSON = staticIndexOf!(AsObjectInJSON, __traits(getAttributes, field)) != -1;
}


template getNameInJSONObject(alias field)
{
    template isAsObjectInJSONName(alias A)
    {
        static if(isExpressionTuple!A)
            enum isAsObjectInJSONName = is(typeof(A) == AsObjectInJSON.Name);
        else
            enum isAsObjectInJSONName = false;
    }

    enum idx = staticIndexOf!(isAsObjectInJSONName, __traits(getAttributes, field));

    static if(idx != -1)
        enum getNameInJSONObject = __traits(getAttributes, field)[idx].name;
    else
        enum getNameInJSONObject = field.stringof;
}


JSONValue toJSONValue(T)
+/