module graphite.utils.log;

import std.range;
import std.format;
import std.stdio;


struct LogElement
{
    Level lv;
    string id;
    string file;
    string line;
    string func;
    string msg;
}


enum Level
{
    verbose,
    notice,
    warning,
    error,
    fatalError,
    silent,
}


struct Logger
{
    void write(Level lv, T...)(T args)
    {
        if(lv >= _currLv){
            _orng.formattedWrite("[%s]<%s>{%s(%s): %s}: ", lv, _id, _file, _line, _func);

            foreach(ref e; args)
                _orng.formattedWrite("%s", e);
        }
    }


    void write(string lv, T...)(T args)
    {
        write!(mixin(`Level.` ~ lv))(args);
    }


    void writef(Level lv, T...)(in char[] format, T args)
    {
        if(lv >= _currLv){
            this.write!(lv)();
            _orng.formattedWrite(format, args);
        }
    }


    void writef(string lv, T...)(in char[] format, T args)
    {
        writef!(mixin(`Level.` ~ lv))(format, args);
    }


    void writeln(Level lv, T...)(T args)
    {
        this.write!(lv)(args, '\n');
    }


    void writeln(string lv, T...)(T args)
    {
        writeln!(mixin(`Level.` ~ lv))(args);
    }


    void writefln(Level lv, T...)(string format, T args)
    {
        this.writef!(lv)(format ~ '\n', args);
    }


    void writefln(string lv, T...)(string format, T args)
    {
        write!(mixin(`Level.` ~ lv))(format, args);
    }


    Level thrLv() @property
    {
        return _currLv;
    }


    void thrLv(Level level) @property
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


    void setEnv(string file, size_t line, string func)
    {
        _file = file;
        _line = line;
        _func = func;
    }


    string _id;
    OutputRange!dchar _orng;
    Level _currLv;

    string _file;
    size_t _line;
    string _func;
}


private Logger[] loggers;


static this()
{
    loggers ~= Logger("Global", null, Level.verbose);
    loggers[0].bindConsole;

    logger!"unittest".bindConsole();
    logger!"unittest".thrLv = Level.warning;
}


ref Logger originLogger(string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__)
{
    loggers[0].setEnv(file, line, fn);
    return loggers[0];
}


ref Logger logger(alias identifier = __MODULE__)(string file = __FILE__, size_t line = __LINE__, string fn = __PRETTY_FUNCTION__)
{
    static size_t index;

    if(index == 0){
        loggers ~= loggers[0];
        loggers[$-1]._id = identifier.stringof;
        index = loggers.length - 1;
    }

    loggers[index].setEnv(file, line, fn);
    return loggers[index];
}


auto allLogger() @property
{
    struct AllLogger
    {
        void thrLv(Level lv)
        {
            foreach(ref e; loggers)
                e.thrLv = lv;
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
    logger.bind(app);
    logger.thrLv = Level.warning;

    logger("file", 0, "func").write!("warning")("foo");
    assert(app.data == `[warning]<"graphite.utils.log">{file(0): func}: foo`);

    logger("file", 1, "func").write!("notice")("bar");
    assert(app.data == `[warning]<"graphite.utils.log">{file(0): func}: foo`);

    logger("f", 2, "p").write!("fatalError")("hoge");
    assert(app.data == `[warning]<"graphite.utils.log">{file(0): func}: foo[fatalError]<"graphite.utils.log">{f(2): p}: hoge`);
}

unittest
{
    import std.array;
    import std.stdio;

    // 使い方
    // logger!identifier()のデフォルト設定は、logger()から引き継がれる

    // 出力先を変更したい場合は、適当なOutputRangeをバインドする
    // isOutputRange!(R, dchar)を満たす型であればなんでも良い
    auto app = appender!string();   // 今回は便利なappender!string
    logger!"logTest".bind(app);     // std.stdio.stdoutでももちろん良い

    // logger!(identifier)のデフォルトの設定は、グローバル変数のloggers[0]から受け継がれる
    // 今回はlevelをnoticeにしてみる。
    logger!"logTest".thrLv = Level.notice;

    // ログに出力してみる
    logger!"logTest".writeln!"warning"("まじかよ…");        // こんな感じで使う
    //logger!"unittest".writefln!"verbose"("{%s}", app.data); // 例えばこんな感じ
}
