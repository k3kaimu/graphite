module graphite.events.type;


enum bool isEvent(T) = is(typeof((T t){
    static assert(T.isEvent);
}));


enum bool isEventManager(T, Event) = is(typeof((T t, Event e){
    t.send!Event(e);


    auto dg1 = delegate(Event e){};
    auto dg2 = delegate(Variant sender, Event e){};

    t ~= dg1;
    t.remove(dg1);

    t ~= dg2;
    t.remove(dg2);
}));


bool isEventReceiver(T, Event) = is(typeof((T t, Event e){
    auto dg = &(t.receive!Event);
    dg(e);
}));