module graphite.utils.log;

import std.range;
import std.format;
import std.stdio;

struct Logger
{
    enum Level
    {
        verbose,
        notice,
        warning,
        error,
        fatalError,
        silent,
    }


    void write(Level lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(T args)
    {
        if(lv >= _currLv){
            _orng.formattedWrite("[%s]<%s>{%s(%s): %s}: ", lv, _id, file, line, fn);

            foreach(ref e; args)
                _orng.formattedWrite("%s", e);
        }
    }


    void write(string lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(T args)
    {
        write!(mixin(`Level.` ~ lv), file, line, fn)(args);
    }


    void writef(Level lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(in char[] format, T args)
    {
        if(lv >= _currLv){
            this.write!(lv, file, line, fn)();
            _orng.formattedWrite(format, args);
        }
    }


    void writef(string lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(in char[] format, T args)
    {
        writef!(mixin(`Level.` ~ lv), file, line, fn)(format, args);
    }


    void writeln(Level lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(T args)
    {
        this.write!(lv, file, line, fn)(args, '\n');
    }


    void writeln(string lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(T args)
    {
        writeln!(mixin(`Level.` ~ lv), file, line, fn)(args);
    }


    void writefln(Level lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(string format, T args)
    {
        this.writef!(lv, file, line, fn)(format ~ '\n', args);
    }


    void writefln(string lv, string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__, T...)(string format, T args)
    {
        write!(mixin(`Level.` ~ lv), file, line, fn)(format, args);
    }


    Level currLevel() @property
    {
        return _currLv;
    }


    void currLevel(Level level) @property
    {
        this._currLv = level;
    }


    void bindFile(string filename)
    {
        bindFile(File(filename, "w"));
    }


    void bindFile(File f)
    {
        bind(f.lockingTextWriter);
    }


    void bindConsole()
    {
        bindFile(stdout);
    }


    void bind(Writer)(Writer range)
    {
        _orng = makeORng(range);
    }


  private:
    static auto makeORng(T)(T outputRange)
    {
        return outputRangeObject!dchar(outputRange);
    }

    string _id;
    OutputRange!dchar _orng;
    Level _currLv;
}


private Logger[] loggers;


static this()
{
    loggers ~= Logger("Global", null, Logger.Level.warning);
    loggers[0].bind(stdout.lockingTextWriter);
}


ref Logger logger() @property
{
    return loggers[0];
}


ref Logger logger(alias identifier)() @property
{
    static size_t index;

    if(index == 0){
        loggers ~= loggers[0];
        loggers[$-1]._id = __traits(identifier, identifier);
        index = loggers.length - 1;
    }

    return loggers[index];
}


auto allLogger() @property
{
    struct AllLogger
    {
        void currLevel(Logger.Level lv)
        {
            foreach(ref e; loggers)
                e.currLevel = lv;
        }


        void bindFile(string filename)
        {
            foreach(ref e; loggers)
                e.bindFile(filename);
        }


        void bindFile(File f)
        {
            foreach(ref e; loggers)
                e.bindFile(f);
        }


        void bindConsole()
        {
            foreach(ref e; loggers)
                e.bindConsole();
        }


        void bind(Writer)(Writer range)
        {
            foreach(ref e; loggers)
                e.bind(range);
        }
    }
}


unittest
{
    import std.array;

    auto app = appender!string();
    logger!(graphite.utils.log).bind(app);
    logger!(graphite.utils.log).currLevel = Logger.Level.warning;

    logger!(graphite.utils.log).write!("warning", "file", 0, "func")("foo");
    assert(app.data == `[warning]<log>{file(0): func}: foo`);

    logger!(graphite.utils.log).write!("notice", "file", 1, "func")("bar");
    assert(app.data == `[warning]<log>{file(0): func}: foo`);

    logger!(graphite.utils.log).write!("fatalError", "f", 2, "p")("hoge");
    assert(app.data == "[warning]<log>{file(0): func}: foo[fatalError]<log>{f(2): p}: hoge");

    logger!(graphite.utils.log).write!"warning"("foo");
    writeln(app.data);
}

unittest
{
    // 使い方
    // まず、適当なOutputRangeをバインドする
    // isOutputRange!(R, dchar)を満たす型であればなんでも良い
    auto app = appender!string();   // 今回は便利なappender!string
    logger!"logTest".bind(app);     // std.stdio.stdoutでももちろん良い

    // logger!(identifier)のデフォルトの設定は、グローバル変数のloggers[0]から受け継がれる
    // 今回はlevelをnoticeにしてみる。
    logger!"logTest".currLevel = Logger.Level.notice;

    // ログに出力してみる
    logger!"logTest".writeln!"warning"("まじかよ…");        // こんな感じで使う
    logger!"unittest".writefln!"verbose"("{%s}", app.data); // 例えばこんな感じ
}
