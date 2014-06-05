module graphite.events.eventutils;

import std.algorithm,
       phobosx.signal,  //
       std.variant;


struct FiredContext
{
    Variant sender;
    string file;
    size_t line;
    string funcName;
    string prettyFuncName;
}


/+
struct Event(T...)
{
    struct EventManager
    {
        mixin Signal!(FiredContext, T);

        void opOpAssign(string s : "+")(slot_t dlg)
        {
            this.connect(dlg);
        }


        void opOpAssign(string s : "-")(slot_t dlg)
        {
            this.disconnect(dlg);
        }
    }


    ref EventManager beforeApp() @property
    {
        return _slot[0];
    }


    ref EventManager sameTimeApp() @property
    {
        return _slot[1];
    }


    ref EventManager afterApp() @property
    {
        return _slot[2];
    }


    void emit()(auto ref T args, string file = __FILE__, size_t line = __LINE__,
                                     string func = __FUNCTION__, string preFunc = __PRETTY_FUNCTION__)
    {
        emit(null, forward!args, file, line, func, preFunc);
    }


    void emit(S)(S sender, auto ref T args, string file = __FILE__, size_t line = __LINE__,
                                     string func = __FUNCTION__, string preFunc = __PRETTY_FUNCTION__)
    {
        FiredContext ctx;
        ctx.sender = sender;
        ctx.file = file;
        ctx.line = line;
        ctx.funcName = func;
        ctx.prettyFuncName = preFunc;

        emit(ctx, forward!args);
    }


  private:
    EventManager[3] _slot;    // [before_app, app, after_app]


    void emit()(FiredContext ctx, auto ref T args)
    {
        foreach(ref e; _slot)
            e.emit(ctx, forward!args);
    }
}
+/


struct Event(T...)
{
    //mixin(signal!(FiredContext, T)("beforeApp"));
    //mixin(signal!(FiredContext, T)("sameTimeApp"));
    //mixin(signal!(FiredContext, T)("afterApp"));
    ref RestrictedSignal!(FiredContext, T) beforeApp() { return _beforeApp;}
    private Signal!(FiredContext, T) _beforeApp;

    ref RestrictedSignal!(FiredContext, T) sameTimeApp() { return _sameTimeApp;}
    private Signal!(FiredContext, T) _sameTimeApp;

    ref RestrictedSignal!(FiredContext, T) afterApp() { return _afterApp;}
    private Signal!(FiredContext, T) _afterApp;


    void disable()
    {
        _disable = true;
    }


    void enable()
    {
        _disable = false;
    }


    void emit()(auto ref T args, string file = __FILE__, size_t line = __LINE__,
                                     string func = __FUNCTION__, string preFunc = __PRETTY_FUNCTION__)
    {
        emit(null, forward!args, file, line, func, preFunc);
    }


    void emit(S)(S sender, auto ref T args, string file = __FILE__, size_t line = __LINE__,
                                     string func = __FUNCTION__, string preFunc = __PRETTY_FUNCTION__)
    {
        FiredContext ctx;
        ctx.sender = sender;
        ctx.file = file;
        ctx.line = line;
        ctx.funcName = func;
        ctx.prettyFuncName = preFunc;

        emit(ctx, forward!args);
    }


  private:
    void emit()(FiredContext ctx, auto ref T args)
    {
        if(!_disable){
            _beforeApp.emit(ctx, forward!args);
            _sameTimeApp.emit(ctx, forward!args);
            _afterApp.emit(ctx, forward!args);
        }
    }


    bool _disable;
}


unittest
{
    auto event = Event!bool();

    event.sameTimeApp.strongConnect(delegate(FiredContext ctx, bool b){
        assert(b);
        assert(ctx.sender == null || ctx.sender.peek!(Event!bool));
    });

    event.emit(true);
}
