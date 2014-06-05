module graphite.utils.channel;

import core.atomic;
import core.sync.mutex;

import std.exception;


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


Channel!T channel(T)() pure nothrow @safe
{
    shared Channel!T ch;
    return ch;
}


unittest
{
    import core.thread;
    import std.stdio;

    //shared Channel!int ch/* = channel!int*/;
    shared ch = channel!int();
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
