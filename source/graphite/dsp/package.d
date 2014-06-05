module graphite.dsp;

enum isDSPElement(T, In, Out) = is(typeof((T t){
        In[] inData;

        // set
        t.output ~= delegate(Out[] outData){};

        t.put(inData);
    }));