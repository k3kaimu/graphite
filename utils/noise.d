module graphite.utils.noise;

import graphite.math;

import std.random;
import std.range;
import std.array;
import std.format;
import std.math;


/// see https://github.com/Reputeless/PerlinNoise
/**
4次元以下のパーリンノイズとオクターブノイズを計算するためのクラス
*/
class PerlinNoise
{
    this(RandomGen)(ref RandomGen gen)
    {
        auto arr = p[0 .. 256];

        arr.put(iota(256));
        randomShuffle(arr, gen);
        p[256 .. $] = p[0 .. 256];
    }


    this()
    {
        this(rndGen);
    }


    /**
    4次元以下のパーリンノイズを計算します
    */
    real noise(size_t N)(real[N] x...) const pure nothrow @safe
    if(N >= 1 && N <= 4)
    {
        static string gen(string format)
        {
            auto app = appender!string();

            foreach(i; 0 .. N)
                app.formattedWrite(format, i);

            return app.data;
        }

        immutable flr = mixin('[' ~ gen(`floor(x[%s]), `) ~ ']');
        immutable xx = mixin('[' ~ gen(`(cast(immutable(int))(flr[%s])) & 255, `) ~ ']');
        immutable rem = mixin('[' ~ gen(`x[%1$s] - flr[%1$s], `) ~ ']');
        immutable fad = mixin('[' ~ gen(`fade(rem[%s]), `) ~ ']');

        static string[] genIndex(uint dim)
        {
            if(dim == 1)
                return ["xx[0]", "xx[0]+1"];
            else{
                auto bs = genIndex(dim-1);
                assert(bs.length == (1 << (dim-1)));
                
                string[] ss;
                foreach(e; bs)
                    ss ~= format(`p[%s]+xx[%s]`, e, dim-1);
                
                string[] dst = ss;
                foreach(e; ss)
                    dst ~= e ~ "+1";

                return dst;
            }
        }

        static string genTree(uint dim, uint maxDim, string[] idxs, size_t termNum)
        {
            auto app = appender!string();
            app.formattedWrite(`lerp(fad[%s]`, dim-1);

            if(dim == 1){
                foreach(i; 0 .. 2){
                    immutable trN = (termNum << 1) + i;
                    app.formattedWrite(`, grad(p[%s]`, idxs[trN]);
                    foreach(j; 0 .. maxDim)
                        app.formattedWrite(`, rem[%s]-%s`, j, (trN & (1 << j)) ? 1 : 0);
                    app ~= ")";
                }
            }else{
                foreach(i; 0 .. 2){
                    immutable trN = (termNum << 1) + i;
                    app ~= ", ";
                    app ~= genTree(dim-1, maxDim, idxs, trN);
                }
            }

            app ~= ')';
            return app.data;
        }

        return mixin(genTree(N, N, genIndex(N), 0));
    }


    /**
    4次元以下のオクターブノイズを計算します
    */
    real octaveNoise(size_t N)(int octaves, real[N] x...) const pure nothrow @safe
    {
        real result = 0,
             amp = 1;

        real[N] xx = x;

        foreach(i; 0 .. octaves){
            result += noise(xx);
            xx[] *= 2;
            amp *= 0.5;
        }

        return result;
    }


  private:
    int[512] p;

  static:
    real fade(real t) pure nothrow @safe
    {
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    real lerp(real t, real a, real b) pure nothrow @safe
    {
        return a + t * (b - a);
    }

    real grad(int hash, real x) pure nothrow @safe {
        immutable h = hash & 15,
                  u = 1.0 + (h & 7);
        return ((h&8) ? -u : u) * x;
    }

    real grad(int hash, real x, real y) pure nothrow @safe {
        immutable h = hash & 7,
                  u = h < 4 ? x : y,
                  v = h < 4 ? y : x;
        return ((h&1)? -u : u) + ((h&2)? -2.0f*v : 2.0f*v);
    }

    real grad(int hash, real x, real y , real z) pure nothrow @safe {
        immutable h = hash & 15,
                  u = h<8 ? x : y,
                  v = h<4 ? y : h==12||h==14 ? x : z;
        return ((h&1)? -u : u) + ((h&2)? -v : v);
    }

    real  grad(int hash, real x, real y, real z, real t) pure nothrow @safe {
        immutable h = hash & 31,
                  u = h < 24 ? x : y,
                  v = h < 16 ? y : z,
                  w = h < 8 ? z : t;

        return ((h&1)? -u : u) + ((h&2)? -v : v) + ((h&4)? -w : w);
    }
}
