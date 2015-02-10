// Written in the D programming language.
/*
NYSL Version 0.9982

A. This software is "Everyone'sWare". It means:
  Anybody who has this software can use it as if he/she is
  the author.

  A-1. Freeware. No fee is required.
  A-2. You can freely redistribute this software.
  A-3. You can freely modify this software. And the source
      may be used in any software with no limitation.
  A-4. When you release a modified version to public, you
      must publish it with your name.

B. The author is not responsible for any kind of damages or loss
  while using or misusing this software, which is distributed
  "AS IS". No warranty of any kind is expressed or implied.
  You use AT YOUR OWN RISK.

C. Copyrighted to Kazuki KOMATSU

D. Above three clauses are applied both to source and binary
  form of this software.
*/

/**
このモジュールは、ロガーおよびログ出力を行いやすくするための機能を提供します。

Examples:
-------------
module foo;

import std.stdio;
import graphite.utils.logger;
import carbon.templates;

mixin defGlobalVariables!("logger", "logFile",
{
    auto file = File("foo.txt", "w");
    return tuple(.logger!(LogFormat.readable)(file), file);
});


void main()
{
    int a = 12;
    // 文字列として出力
    logger.writeln!"notice"("a is ", a);

    // 値をそのまま出力
    logger.trace!"notice"(a, a * 2, a * 3);

    // 例外の通知
    try logger.captureException(enforce(0));
    catch(Exception ex){
        writeln(ex);
        throw ex;
    }
}
-------------
*/
module graphite.utils.log;

import std.range;
import std.format;
import std.stdio;
import std.variant;
import std.json;

import graphite.utils.json;


/**
ログの重要度を表します
*/
enum Level
{
    verbose,    ///
    notice,     ///
    warning,    ///
    error,      ///
    fatalError, ///
    silent,     ///
}


/**
ログのフロントエンドとバックエンドでやりとりされるデータです。
*/
struct LogElement(T...)
{
    Level level;
    string id;
    string file;
    size_t line;
    string func;
    T msg;
}


/**
ロガー
*/
struct Logger(Backend)
if(isOutputRange!(Backend, LogElement!(Variant)))
{
    version(D_Ddoc)
    {
        /**
        ロガーに値を出力します。
        値は$(D LogElement!T)に格納され、バックエンドに渡されます。
        */
        void trace(Level lv, T...)(T args);
        void trace(string lv, T...)(T args);    /// ditto


        /**
        ロガーに文字列を出力します。
        文字列は$(D LogElement!string)に格納され、バックエンドに渡されます。
        */
        void writeln(Level lv, T...)(T args);
        void writeln(string lv, T...)(T args);                  /// ditto
        void writefln(Level lv, T...)(string format, T args);   /// ditto
        void writefln(Level lv, T...)(string format, T args);   /// ditto


        /**
        式を評価した結果例外やエラーが発生したら、ロガーにそれを出力します。
        例外は$(D LogElement!Ex)に格納され、エラーは$(D LogElement!Er)に格納され、バックエンドに渡されます。

        例外が発生しない場合、式の評価結果をそのまま返します。
        */
        auto ref T captureException(Ex = Exception, Er = Error, T)(lazy T dg);
    }

    alias instance this;

    LoggerImpl instance(string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__)
    {
        return LoggerImpl(&this, file, line, fn);
    }


    static struct LoggerImpl
    {
        @disable this(this);


        void trace(Level lv, T...)(T args)
        if(lv != Level.silent)
        {
            if(lv >= logger.thrLv){
                LogElement!T log;
                log.level = lv;
                log.id = logger._id;
                log.file = _file;
                log.line = _line;
                log.func = _func;
                log.msg = args;
                logger._b.put(log);
            }
        }


        void trace(string lv, T...)(T args)
        {
            trace!(mixin(`Level.` ~ lv))(args);
        }


        void writeln(Level lv, T...)(T args)
        {
            if(lv >= logger.thrLv){
                auto app = appender!string();
                foreach(i, U; T)
                    app.formattedWrite("%s", args[i]);
                trace!lv(app.data);
            }
        }


        void writeln(string lv, T...)(T args)
        {
            writeln!(mixin(`Level.` ~ lv))(args);
        }


        void writefln(Level lv, T...)(string format, T args)
        {
            if(lv >= logger.thrLv){
                auto app = appender!string();
                app.formattedWrite(format, args);
                trace!lv(app.data);
            }
        }


        void writefln(string lv, T...)(string format, T args)
        {
            writefln!(mixin(`Level.` ~ lv))(format, args);
        }


        auto ref T captureException(Ex = Exception, Er = Error, T)(lazy T dg)
        {
            try return dg();
            catch(Ex ex){
                trace!(Level.error)(ex);
                throw ex;
            }
            catch(Er er){
                trace!(Level.fatalError)(er);
                throw er;
            }
        }

        Logger* logger;

      private:
        string _file;
        size_t _line;
        string _func;
    }


    /**
    ログに出力するしきい値レベルを設定・取得します。

    Examples:
    ----------------
    logger.thrLv = Level.warning;
    logger.writeln!"notice"("このメッセージはログに残らない");
    logger.writeln!"warning"("ログに残るメッセージ");
    ----------------
    */
    Level thrLv() @property
    {
        return _thrLv;
    }


    /// ditto
    void thrLv(Level level) @property
    {
        this._thrLv = level;
    }


  static if(is(typeof(_b.writer)))
  {
    /**
    バックエンドが$(D writer)プロパティをもつ場合、その$(D writer)プロパティをそのまま返します。
    */
    auto ref writer() @property
    {
        return _b.writer;
    }
  }


  private:
    Backend _b;
    string _id;
    Level _thrLv;
}


/**
バックエンドを指定してロガーを構築します。
どのような$(D T...)に対しても$(D isOuputRange!(R, LogElement!T))が$(D true)となるような出力レンジがバックエンドとなります。
*/
auto logger(alias id = __MODULE__, B)(B backend)
if(isOutputRange!(B, LogElement!Variant))
{
  static if(is(typeof(id) : string) && is(typeof({ enum _unused_ = id; })))
    enum idstr = id;
  else
    enum idstr = id.stringof;

    return Logger!B(backend, idstr, Level.verbose);
}

unittest {
    static struct Backend1(T)
    {
        LogElement!T[] logs;

        void put(U...)(LogElement!U log)
        {
          static if(U.length == 1 && is(U[0] == T))
            logs ~= log;
        }
    }

    import std.typecons;

    LogElement!string[] arr;
    auto b = Backend1!string(arr);
    auto logger = .logger(&b);
    logger.trace!"fatalError"("foo");     size_t instLine = __LINE__;
    assert(b.logs[0].level == Level.fatalError);
    assert(b.logs[0].id == __MODULE__);
    assert(b.logs[0].file == __FILE__);
    assert(b.logs[0].line == instLine);
    assert(b.logs[0].func == __PRETTY_FUNCTION__);
    assert(b.logs[0].msg[0] == "foo");

    logger.writefln!"warning"("%s is %s?", 124, "124"); instLine = __LINE__;
    assert(b.logs[1].level == Level.warning);
    assert(b.logs[1].id == __MODULE__);
    assert(b.logs[1].file == __FILE__);
    assert(b.logs[1].line == instLine);
    assert(b.logs[1].func == __PRETTY_FUNCTION__);
    assert(b.logs[1].msg[0] == "124 is 124?");

    logger.writeln!"notice"(124, " is " "124", "?"); instLine = __LINE__;
    assert(b.logs[2].level == Level.notice);
    assert(b.logs[2].id == __MODULE__);
    assert(b.logs[2].file == __FILE__);
    assert(b.logs[2].line == instLine);
    assert(b.logs[2].func == __PRETTY_FUNCTION__);
    assert(b.logs[2].msg[0] == "124 is 124?");
}

unittest {
    import std.exception;
    import std.conv;

    static struct Backend1
    {
        string[] logs;

        void put(U...)(LogElement!U log)
        {
            auto app = appender!string();

            foreach(i, E; U)
                app.formattedWrite("%s", log.msg[i]);

            logs ~= app.data;
        }
    }

    Backend1 b;
    auto logger = .logger(&b);

    string exStr;
    try logger.captureException(enforce(0));
    catch(Exception ex)
        exStr = ex.to!string();

    assert(b.logs[0] == exStr);
}


/**
出力レンジ、もしくは$(D std.stdio.File)を最終的な出力先としてロガーを構築します。
出力のフォーマットや形式は、$(D formattedWriter)によって決定されます。
ロガーに渡されたログは、$(D formattedWriter(w, log))によって$(D Writer w)に出力されます。
*/
auto logger(alias formattedWriter, alias id = __MODULE__, Writer)(Writer w)
if(is(typeof(backend!formattedWriter(w))))
{
    auto b = backend!formattedWriter(w);
    return .logger!id(b);
}


/**
ファイルを最終出力先とするようなバックエンドを構築します。
ファイルへの出力フォーマットや形式は、$(D formattedWriter(file.lockingTextWriter, log))により決定されます。
*/
auto backend(alias formattedWriter)(File file)
if(is(typeof(backend!formattedWriter(file.lockingTextWriter))))
{
    static struct Backend
    {
        void put(T...)(LogElement!T log)
        {
            auto w = _file.lockingTextWriter;
            formattedWriter(w, log);
        }

      private:
        File _file;
    }

    return Backend(file);
}


unittest
{
    import std.conv : to;
    import std.string : chomp;

    immutable filename = "unittest_file.txt";
    scope(exit)
            std.file.remove(filename);

    LogElement!() log;
    {
        auto b = backend!((ref w, log){ w.put(to!string(log)); })(File(filename, "w"));
        b.put(log);
    }

    {
        assert(chomp(std.file.readText(filename)) == to!string(log));
    }
}


/**
出力レンジを最終出力先とするようなバックエンドを構築します。
出力レンジの型および出力フォーマットや形式は、$(D formattedWriter(outputRange, log))により決定されます。
*/
auto backend(alias formattedWriter, Writer)(Writer w)
if(is(typeof((ref Writer w, LogElement!Variant log){ formattedWriter(w, log); })))
{
    static struct Backend
    {
        void put(T...)(LogElement!T log)
        {
            formattedWriter(_w, log);
        }


        ref Writer writer() @property
        {
            return _w;
        }


      private:
        Writer _w;
    }

    return Backend(w);
}


/// ditto
auto backend(alias formattedWriter, Writer)(Writer* w)
if(is(typeof(backend!formattedWriter(*w))) && !is(Unqual!Writer == File))
{
    static struct Backend
    {
        void put(T...)(LogElement!T log)
        {
            formattedWriter(*_w, log);
        }


        ref Writer writer() @property
        {
            return *_w;
        }


      private:
        Writer* _w;
    }


    return Backend(w);
}


struct LogFormat
{
    @disable this();
    @disable this(this);

  static:
    void readable(Sink, T...)(ref Sink sink, LogElement!T log)
    if(isOutputRange!(Sink, dchar))
    {
        sink.formattedWrite("[%s] @%s[%s(%s) in %s]", log.level, log.id, log.file, log.line, log.func);

      static if(T.length == 0)
        sink.put('\n');
      else static if(T.length == 1)
        sink.formattedWrite(": %s\n", log.msg);
      else{
        sink.put(": {");
        foreach(i, U; T){
            sink.formattedWrite("%s", log.msg[i]);

            if(i != T.length - 1)
                sink.put(", ");
        }
        sink.put("}\n");
      }
    }

    unittest {
        auto app = appender!string();
        readable(app, LogElement!()(Level.verbose, "ID", "FILE", 1111111, "FUNC"));
        assert(app.data == "[verbose] @ID[FILE(1111111) in FUNC]\n");

        app = appender!string();
        readable(app, LogElement!(string)(Level.verbose, "ID", "FILE", 123123, "FUNC", "FOOBAR"));
        assert(app.data == "[verbose] @ID[FILE(123123) in FUNC]: FOOBAR\n");

        app = appender!string();
        readable(app, LogElement!(string, int)(Level.verbose, "ID", "FILE", 123123, "FUNC", "FOOBAR", 323232));
        assert(app.data == `[verbose] @ID[FILE(123123) in FUNC]: {FOOBAR, 323232}`"\n");
    }


    void json(Sink, T...)(ref Sink sink, LogElement!T log)
    if(isOutputRange!(Sink, dchar))
    {
        Variant[string] v;

        v["level"] = log.level;
        v["id"] = log.id;
        v["file"] = log.file;
        v["line"] = log.line;
        v["func"] = log.func;
        v["msg"] = variantArray(log.msg);

        sink.formattedWrite("%s\n", JSONEnv!null.toJSONValue(v));
    }

    unittest {
        import std.string : chomp;

        auto app = appender!string();
        json(app, LogElement!()(Level.verbose, "ID", "FILE", 1111111, "FUNC"));
        JSONValue jv = parseJSON(chomp(app.data));
        assert(jv.type == JSON_TYPE.OBJECT);
        assert(jv["level"].str == "verbose");
        assert(jv["id"].str == "ID");
        assert(jv["file"].str == "FILE");
        assert(1111111 == (jv["line"].type == JSON_TYPE.UINTEGER ? jv["line"].uinteger : jv["line"].integer));
        assert(jv["func"].str == "FUNC");
        assert(jv["msg"].array.length == 0);

        app = appender!string();
        json(app, LogElement!(string)(Level.verbose, "ID", "FILE", 123123, "FUNC", "FOOBAR"));
        jv = parseJSON(chomp(app.data));
        assert(jv.type == JSON_TYPE.OBJECT);
        assert(jv["level"].str == "verbose");
        assert(jv["id"].str == "ID");
        assert(jv["file"].str == "FILE");
        assert(123123 == (jv["line"].type == JSON_TYPE.UINTEGER ? jv["line"].uinteger : jv["line"].integer));
        assert(jv["func"].str == "FUNC");
        assert(jv["msg"].array.length == 1);
        assert(jv["msg"][0].str == "FOOBAR");

        app = appender!string();
        json(app, LogElement!(string, int)(Level.verbose, "ID", "FILE", 123123, "FUNC", "FOOBAR", 323232));
        jv = parseJSON(chomp(app.data));
        assert(jv.type == JSON_TYPE.OBJECT);
        assert(jv["level"].str == "verbose");
        assert(jv["id"].str == "ID");
        assert(jv["file"].str == "FILE");
        assert(123123 == (jv["line"].type == JSON_TYPE.UINTEGER ? jv["line"].uinteger : jv["line"].integer));
        assert(jv["func"].str == "FUNC");
        assert(jv["msg"].array.length == 2);
        assert(jv["msg"][0].str == "FOOBAR");
        assert(323232 == (jv["msg"][1].type == JSON_TYPE.UINTEGER ? jv["msg"][1].uinteger : jv["msg"][1].integer));
    }
}


/**
std.stdio.Fileに書き込むLogger
*/
template FileLogger(alias formattedWriter)
{
    alias FileLogger = typeof(.logger!formattedWriter(std.stdio.stdin));
}
