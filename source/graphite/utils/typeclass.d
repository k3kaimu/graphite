module graphite.utils.typeclass;

import std.typecons;
import std.algorithm;
import std.traits;
import std.format;
import std.range;
import std.array;
import std.string;
import std.conv;


/**
型Tが、型クラスIに属しているかどうか判定します。
型Tが型クラスIに属するとは、IのすべてのメソッドをTが持っているということです。

たとえば、型Tが型Iを継承しているような場合には、型Tは型クラスIに所属していると言えます。

*/
template isMemberOfTypeClass(T, I)
if(is(I == interface))
{
    enum isMemberOfTypeClass = is(T : I) || is(typeof({
        static class TClass{
            T obj;
            mixin Proxy!obj;
        }


        TClass tc = new TClass;
        I i = tc.wrap!I;
    }));
}

///
unittest{
    static interface I{
        bool update();
        ref int x();

        ref int opIndex(size_t i); // operator overloading
        void opOpAssign(string op : "+")(int a);
    }

    static struct S{
        bool update() { return true; }
        ref int x() { return _a; }
        ref int opIndex(size_t i){ return x; }
        void opOpAssign(string op, X)(X x)if(op == "+"){}
        int _a;
    }

    static class C{
        bool update() { return false; }
        ref int x() { return _a; }
        ref int opIndex(size_t i){ return x; }
        void opOpAssign(string op : "+")(int a){}
        int _a;
    }

    // const, inout, pure, nothrow, @safe test
    static abstract class AC{
        bool update() pure nothrow @safe const;
        ref inout(int) x() pure nothrow @safe inout;
        ref inout(int) opIndex(size_t i) inout;
        void opOpAssign(string op : "+")(int a);
    }


    static interface II{
        bool update();
        ref int x();
        ref inout(int) opIndex(size_t i) inout;
        void opOpAssign(string op : "+")(int a);
    }


    static assert(isMemberOfTypeClass!(S, I));
    static assert(isMemberOfTypeClass!(C, I));
    static assert(isMemberOfTypeClass!(AC, I));
    static assert(isMemberOfTypeClass!(II, I));
}


/**
あるオブジェクトを、指定した型クラスのインスタンスに変換します。
*/
I toTypeClass(I, T)(T t)
if(isMemberOfTypeClass!(T, I))
{
  static if(is(T : I))
    return t;
  else
  {
    static class Result
    {
        private T _t;
        mixin Proxy!_t;
    }

    Result r = new Result;
    r._t = t;

    return r.wrap!I;
  }
}


unittest{
    static struct S 
    {
        ref int x() { return _a; }
        bool empty() { return true; }

      private:
        int _a;
    }


    static interface I 
    {
        ref int x();
        bool empty();
    }


    S* s = new S;
    auto tc = s.toTypeClass!I;

    s.x = 12;
    assert(tc.x == 12);
    assert(s.empty && tc.empty);
}


private string genOptionalMethodName(string name)
{
    return name ~ "OptionalDlg";
}



/**
Optionalなメソッドを定義します
*/
string declOptionalMethod(string ret, string name, string[] params, string opt = "")
{
    return format("%s delegate() %s(%s) %s;", ret, genOptionalMethodName(name), params.join(","), opt);
}


/**
optional-methodを宣言定義します
*/
string declDefOptionalMethod(string ret, string name, string[] params, string opt = "", bool impl = true)
{
  if(impl)
    return format("%s delegate() %s(%s) %s { return { return this.%s(%s); }; }",
                   ret, genOptionalMethodName(name),
                   params.zip(iota(params.length)).map!(a => a[0] ~ " _" ~ a[1].to!string).join(","),
                   opt,
                   name, iota(params.length).map!(a => "_" ~ a.to!string).join(","));
  else
    return format("%s delegate() %s(%s) %s { return null; }",
                   ret, genOptionalMethodName(name), params.join(","), opt);
}


/**
optional methodを呼び出します
*/
auto ref callOption(string name, alias callbackWhenNotFound = "a", T, U...)(auto ref T obj, auto ref U args)
{
    static if(is(typeof((){return mixin(`obj.` ~ name ~ `(forward!args)`);})))
        return mixin(`obj.` ~ name ~ `(forward!args)`);
    else static if(is(typeof({auto dlg = mixin(`obj.` ~ genOptionalMethodName(name) ~ `(forward!args)`);})))
    {
        if(auto dlg = mixin(`obj.` ~ genOptionalMethodName(name) ~ `(forward!args)`))
            return dlg();
        else{
            static typeof(return) ret;
            return naryFun!callbackWhenNotFound(forward!obj, forward!args);
        }
    }
    else
        static assert(0, `'T' does not have '` ~ name ~ `' as member.`);
}


unittest{
    static interface I
    {
        void foo();

        mixin(declOptionalMethod("int", "bar", []));
        mixin(declOptionalMethod("int", "hoge", ["int", "float"]));
        mixin(declOptionalMethod("int", "homu", ["int", "float"]));
    }


    static struct S
    {
        void foo(){}

        int bar(){ return 1; }
        mixin(declDefOptionalMethod("int", "bar", []));

        int hoge(int a, float f){ return a; }
        mixin(declDefOptionalMethod("int", "hoge", ["int", "float"]));

        mixin(declDefOptionalMethod("int", "homu", ["int", "float"], "", false));
    }

    static assert(isMemberOfTypeClass!(S, I));

    S s;
    assert(s.callOption!"bar"() == 1);
    assert(s.callOption!"hoge"(3, 4.5) == 3);
    assert(s.callOption!("homu", (s, a, b) => a + 12)(3, 4.5) == 15);
    
    I i = s.toTypeClass!I;
    assert(i.callOption!("bar", (i) => 4)() == 1);
    assert(i.callOption!("hoge", (i, a, b) => a + 12)(3, 4.5) == 3);
    assert(i.callOption!("homu", (s, a, b) => a + 12)(3, 4.5) == 15);
}


private:
import std.format;
import std.array;


template naryFun(alias fun)
if(is(typeof(fun) == string))
{
    auto ref naryFunAlphabet(T...)(auto ref T args)
    {
        static assert(T.length <= 26);
        mixin(createAliasAlphabet(T.length));
        return mixin(fun);
    }


    auto ref naryFunNumber(T...)(auto ref T args)
    {
        mixin(createAliasNumber(T.length));
        return mixin(fun);
    }


    auto ref naryFun(T...)(auto ref T args)
    {
      static if(is(typeof({naryFunNumber(forward!args);})))
        return naryFunNumber(forward!args);
      else
        return naryFunAlphabet(forward!args);
    }


    string createAliasAlphabet(size_t nparam)
    {
        auto app = appender!string();
        foreach(i; 0 .. nparam)
            app.formattedWrite("alias %s = args[%s];\n", cast(char)(i + 'a'), i);
        return app.data;
    }


    string createAliasNumber(size_t nparam)
    {
        auto app = appender!string();
        foreach(i; 0 .. nparam)
            app.formattedWrite("alias _%1$s = args[%1$s];\n", i);
        return app.data;
    }
}

/// ditto
template naryFun(alias fun)
if(!is(typeof(fun) == string))
{
    alias fun naryFun;
}

unittest
{
    alias naryFun!("a+b*c-d") test4;    // Creates a templated 4-args function test4(A, B, C, D)(A a, B b, C c, D d) { return a+b*c-d;}
    assert(test4(1,2,3,4) == 3);        // instantiate test4!(int, int, int, int)
    assert(test4(1.0,2.0,3,4) == 3.0);   // instantiate test4!(double, double, int, int)

    alias naryFun!("_0+_1*_2-_3") test4n;
    assert(test4n(1, 2, 3, 4) == 3);
    assert(test4n(1.0, 2.0, 3, 4) == 3.0);

    alias naryFun!"a+b" test3;      // You can create a fun with more args than necessary, if you wish
    assert(test3(1,2,100) == 3);        // without the 3, naryFun!"a+b" would create a binary function.
    assert(test3(1.0,2.0,100) == 3.0);

    alias naryFun!"sin(a)+cos(b)*c" testsincos; // functional.d imports a lot of other D modules, to have their functions accessible.

    alias naryFun!"tuple(a,a,a)" toTuple;
    assert(toTuple(1) == tuple(1,1,1));

    alias naryFun!"a.expand[1]" tuple1; // tuple1 will be created, but can be used only on types defining a .expand field.
    assert(tuple1(toTuple(1)) == 1);

    alias naryFun!"[b,a,c]" arrayTwister; // will return a static array
    assert(arrayTwister(0,1,2) == [1,0,2]);

    alias naryFun!"f" projection6; // 'a' -> 1 arg, 'b' -> binary, ..., 'f' -> 6-args function. In this case, returning only its sixth argument.
    assert(projection6(0,1,2,3,4,5) == 5);
    
    alias naryFun!"3" test0;                // A 0-arg function. It's exactly: int test0() { return 3;}
    assert(test0 == 3);                     // Constant return
    assert(test0() == 3);                   // But it's a function, not a constant.

    int foo(int a, int b) { return a*b;}
    alias naryFun!(foo) nfoo;           // function test
    assert(nfoo(2,3) == 6);

    int bar() { return 1;}
    alias naryFun!bar nbar;             // 0-arg function test
    assert(nbar == 1);
}