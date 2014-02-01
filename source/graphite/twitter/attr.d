module graphite.twitter.attr;

import std.traits   : Unqual;

/**
すでにURLエンコードされてますよ
*/
struct URLEncoded(T)
{
    T t;
    alias t this;
}


auto assumeURLEncoded(T)(T t)
{
    return URLEncoded!T(t);
}


enum isURLEncoded(T) = is(Unqual!T : URLEncoded!U, U);


unittest {
    static assert(isURLEncoded!(URLEncoded!int));
    static assert(isURLEncoded!(URLEncoded!(string[string])));
    static assert(isURLEncoded!(const(URLEncoded!(const(string[string])))));
}


//struct As(string name, T)
//{
//    T t;

//    alias t this;
//}


//As!(name, T) as(string name, T)(T t)
//{
//    return typeof(return)(t);
//}
