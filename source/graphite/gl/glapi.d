module graphite.gl.glapi;

import graphite.deimos.glfw.glfw3;
import graphite.deimos.gl.glcorearb;

import std.string;
import std.traits;
import std.range;

template _glLoader(string func)
{
    mixin(`alias Fptr = typeof(&graphite.deimos.gl.glcorearb.` ~ func ~ `);`);
    Fptr _func = null;
    
    auto _glLoader(ParameterTypeTuple!Fptr args)
    {
        if(_func is null)
            _func = cast(Fptr)glfwGetProcAddress(func.toStringz);
        return _func(args);
    }
}

string genFunctions(){
    string dst;
    foreach(s; __traits(allMembers, graphite.deimos.gl.glcorearb))
        static if(is(typeof(mixin(s)) == function))
            dst ~= `alias ` ~ s.drop(2) ~ ` = _glLoader!"` ~ s ~ `";`;
    return dst;
}

struct gl
{
    mixin(genFunctions());
}
