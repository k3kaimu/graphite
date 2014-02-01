module graphite.utils.channel;

import core.atomic;

import std.exception;


/+
shared struct Mutex
{
    //this(){}

    void lock() pure nothrow @trusted
    {
        while(!cas(&_locked, false, true)){};
    }


    void unlock() pure nothrow @trusted
    {
        while(!cas(&_locked, true, false)){};
    }


  private:
    bool _locked;
}


unittest
{
    import core.thread;
    import std.stdio;

    shared(Mutex) mutex;
    int  numThreads = 10;
    int  numTries   = 10000;
    int  lockCount  = 0;

    void testFn()
    {
        for( int i = 0; i < numTries; ++i )
        {
            mutex.lock();
                ++lockCount;
            mutex.unlock();
        }
    }

    auto group = new ThreadGroup;

    import std.datetime;

    StopWatch sw;
    sw.start();
    for( int i = 0; i < numThreads; ++i )
        group.create( &testFn );

    group.joinAll();
    sw.stop();
    writefln("result : %s, time : %s[us]", lockCount, sw.peek.usecs);
    assert( lockCount == numThreads * numTries );
}
+/

/+
private synchronized class _Channel(T)
{
    this(){}


    void opAssign(shared(T)[] arr)
    {
        _vals ~= arr;
    }


    void opOpAssign(string s : "~")(shared(T)[] arr)
    {
        _vals ~= arr;
    }


    void opOpAssign(string s : "~")(shared(T) val)
    {
        _vals ~= val;
    }


    inout(shared(T))[] opSlice() inout pure nothrow @safe
    {
        return _vals;
    }


    inout(shared(T))[] opSlice(size_t a, size_t b) inout pure nothrow @safe
    {
        return _vals[a .. b];
    }


    void hangUp() pure nothrow @safe
    {
        _hangUp = true;
    }


    bool empty() const pure nothrow @safe @property
    {
        return _hangUp && _vals.length == 0;
    }


    inout(shared(T)) _front() inout pure nothrow @safe
    {
        assert(!empty);
        return _vals[0];
    }


    void _popFront() pure nothrow @safe
    {
        assert(!empty);
        _vals = _vals[1 .. $];
    }


  private:
    T[] _vals;
    bool _hangUp;
}


Channel!T channel(T)() @property pure nothrow @safe
{
    return Channel!T(new shared _Channel!T);
}


struct Channel(T)
{
    void opAssign(shared(T)[] arr)
    {
        synchronized(_chImpl)
            _chImpl = arr;
    }


    void opOpAssign(string s : "~")(shared(T)[] arr)
    {
        synchronized(_chImpl)
            _chImpl ~= arr;
    }


    void opOpAssign(string s : "~")(shared(T) val)
    {
        synchronized(_chImpl)
            _chImpl ~= val;
    }


    inout(shared(T))[] opSlice() inout pure @safe
    {
        synchronized(_chImpl)
            return _chImpl[];
    }


    inout(shared(T))[] opSlice(size_t a, size_t b) inout pure @safe
    {
        synchronized(_chImpl)
            return _chImpl[a .. b];
    }


    void hangUp()
    {
        synchronized(_chImpl)
            _chImpl.hangUp();
    }


    bool empty() const pure @safe @property
    {
        synchronized(_chImpl)
            return _chImpl.empty;
    }


    inout(shared(T)) front() inout pure @safe @property
    {
        //while({synchronized(_chImpl) return !_chImpl._hangUp;}() && empty){}
        //while(!empty && {synchronized(_chImpl) return _chImpl._vals.length == 0;}){}


        synchronized(_chImpl){
            enforce(!empty);
            return _chImpl._front;
        }
    }


    void popFront() pure @safe
    {
        while({synchronized(_chImpl) return !_chImpl._hangUp;}() && empty){}

        synchronized(_chImpl){
            enforce(!empty);
            _chImpl._popFront();
        }
    }


    auto save() inout pure @safe
    {
        return this[];
    }


  private:
    shared(_Channel!T) _chImpl;
}


unittest
{
    import core.thread;
    import std.stdio;

    Channel!int ch = channel!int;
    int  numThreads = 10;
    int  numTries   = 1000;

    void testFn()
    {
        foreach(i; 0 .. numTries)
            ch ~= i;
    }


    auto group = new ThreadGroup;

    foreach(i; 0 .. numThreads)
        group.create(&testFn);

    group.joinAll();
    ch.hangUp();

    size_t cnt;
    foreach(e; ch)
        ++cnt;

    writeln(cnt);
    assert(cnt == numThreads * numTries);
}
+/


/**
Lock free 
*/
/// from TDPL SharedList
shared struct Channel(T)
{
    shared struct Node
    {
        @property
        inout(shared(Node))* next() pure nothrow @safe inout
        {
            return clearlsb(_next);
        }


        bool removeAfter() pure nothrow @trusted
        {
            shared(Node)* thisNext, afterNext;

            // Step 1: set the lsb of _next for the node to delete
            do{
                thisNext = next;
                if (!thisNext) return false;
                afterNext = thisNext.next;
            }while(!cas(&thisNext._next, afterNext, setlsb(afterNext)));
        
            // Step 2: excise the node to delete
            if (!cas(&_next, thisNext, afterNext)){
                afterNext = thisNext._next;
                while (!haslsb(afterNext))
                    thisNext._next = thisNext._next.next;

                _next = afterNext;
            }
            return true;
        }


        void insertAfter(T value) pure nothrow @trusted
        {
            auto newNode = new shared Node(value);
            while(1){
                // Attempt to find an insertion point
                auto n = _next;
                while (n && haslsb(n))
                    n = n._next;

                // Found a possible insertion point, attempt insert
                shared(Node)* afterN = n._next;
                newNode._next = afterN;
                if (cas(&n._next, afterN, newNode))
                    break;
            }
        }


      private:
        T _payload;
        Node* _next;
    }


    void pushFront(T value)
    {
        auto n = new shared Node(value);
        shared(Node)* oldRoot;

        do{
            oldRoot = _root;
            n._next = oldRoot;
        }while(!cas(&_root, oldRoot, n));
    }


    shared(T)* popFront()
    {
        typeof(return) result;
        shared(Node)* oldRoot;

        do{
            oldRoot = _root;
            if (!oldRoot) return null;
            result = & oldRoot._payload;
        }while(!cas(&_root, oldRoot, oldRoot._next));
        return result;
    }


    void pushBack(T value)
    {
        if(_root is null)
            pushFront(value);
        else
            _root.insertAfter(value);
    }


    void opOpAssign(string op : "~")(T value)
    {
        this.pushBack(value);
    }


    void hangUp() pure nothrow @safe
    {
        _hangUp = true;
    }


    ref inout(shared(T)) front() @property inout pure nothrow @safe
    {
        return _root._payload;
    }


    bool empty() @property pure nothrow @safe const
    {
        return _hangUp && _root is null;
    }


  private:
    Node* _root;
    bool _hangUp;

  static:
    auto clearlsb(T)(inout shared(T)* p) @trusted
    {
        return cast(inout(shared(T)*))((cast(size_t)p) & ~1);
    }


    auto setlsb(T)(inout shared(T)* p) @trusted
    {
        return cast(inout(shared(T)*))((cast(size_t)p) | 1);
    }


    bool haslsb(T)(in shared T* p) @trusted
    {
        return (cast(size_t)p) & 1;
    }
}


unittest
{
    import core.thread;
    import std.stdio;

    shared Channel!int ch/* = channel!int*/;
    int  numThreads = 10;
    int  numTries   = 1000;

    void testFn()
    {
        foreach(i; 0 .. numTries)
            ch.opOpAssign!"~"(i);
    }


    auto group = new ThreadGroup;

    foreach(i; 0 .. numThreads)
        group.create(&testFn);

    group.joinAll();
    ch.hangUp();

    size_t cnt;
    foreach(e; ch)
        ++cnt;

    writeln(cnt);
    assert(cnt == numThreads * numTries);
}
