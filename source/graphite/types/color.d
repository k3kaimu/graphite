module graphite.types.color;


struct Color(PixelType)
{
    ref PixelType r() @property { return _r; }
    ref PixelType g() @property { return _g; }
    ref PixelType b() @property { return _b; }
    ref PixelType a() @property { return _a; }


    void r(real r) @property { _r = toPixelType(r); }
    void g(real g) @property { _g = toPixelType(g); }
    void b(real b) @property { _b = toPixelType(b); }
    void a(real a) @property { _a = toPixelType(a); }

    /**
    r: 0 ~ 1
    g: 0 ~ 1
    b: 0 ~ 1
    a: 0 ~ 1
    */
    static typeof(this) fromRGBA(real r, real g, real b, real a = 1.0)
    in{
        assert(0 <= r && r <= 1);
        assert(0 <= g && g <= 1);
        assert(0 <= b && b <= 1);
        assert(0 <= a && a <= 1);
    }
    body{
        typeof(this) dst;
        dst = Color!real(r, g, b, a);
        return dst;
    }


    static typeof(this) fromGray(real gray, real a = 1.0)
    in{
        assert(0 <= gray && gray <= 1);
        assert(0 <= a && a <= 1);
    }
    body{
        return fromRGBA(gray, gray, gray, a);
    }


    /**
    h: 0 ~ 1
    s: 0 ~ 1
    b: 0 ~ 1

    see: http://ja.wikipedia.org/wiki/HSV%E8%89%B2%E7%A9%BA%E9%96%93
    */
    static typeof(this) fromHSB(real h, real s, real b, real a = 1)
    in{
        assert(0 <= h && h <= 1);
        assert(0 <= s && s <= 1);
        assert(0 <= b && b <= 1);
        assert(0 <= a && a <= 1);
    }
    body{
        if(b == 0){
            return this(0, a);
        }else if(s == 0){
            return this(b, a);
        }else{
            immutable hi = floor(h * 6),
                      f = h * 6 - hi,
                      p = b * (1 - s),
                      q = b * (1 - f * s),
                      t = b * (1 - (1 - f) * s);

            if(hi.approxEqual(0))
                return this(b, t, p, a);
            else if(hi.approxEqual(1))
                return this(q, b, p, a);
            else if(hi.approxEqual(2))
                return this(p, b, t, a);
            else if(hi.approxEqual(3))
                return this(p, q, b);
            else if(hi.approxEqual(4))
                return this(t, p, b);
            else
                return this(b, p, q);
        }
    }


    static typeof(this) fromRGBAHex(uint Nbit = 8)(uint hex)
    {
        immutable mask = ~((~0) << Nbit);

        return fromRGBA(((hex32 >> (Nbit*3)) & mask) / (mask * 1.0),
                        ((hex32 >> (Nbit*2)) & mask) / (mask * 1.0),
                        ((hex32 >> (Nbit*1)) & mask) / (mask * 1.0),
                        ((hex32            ) & mask) / (mask * 1.0));
    }


    static typeof(this) fromRGBHex(uint Nbit = 8)(uint hex, real a = 1)
    {
        auto dst = fromRGBAHex!Nbit(hex << Nbit);
        dst.a = a;
        return dst;
    }


    // these are based on CSS named colors
    // http://www.w3schools.com/cssref/css_colornames.asp

    static const ofColor_<PixelType> white, gray, black, red, green, blue, cyan, magenta,
    yellow,aliceBlue,antiqueWhite,aqua,aquamarine,azure,beige,bisque,blanchedAlmond,
    blueViolet,brown,burlyWood,cadetBlue,chartreuse,chocolate,coral,cornflowerBlue,cornsilk,
    crimson,darkBlue,darkCyan,darkGoldenRod,darkGray,darkGrey,darkGreen,darkKhaki,
    darkMagenta,darkOliveGreen,darkorange,darkOrchid,darkRed,darkSalmon,darkSeaGreen,
    darkSlateBlue,darkSlateGray,darkSlateGrey,darkTurquoise,darkViolet,deepPink,
    deepSkyBlue,dimGray,dimGrey,dodgerBlue,fireBrick,floralWhite,forestGreen,fuchsia,
    gainsboro,ghostWhite,gold,goldenRod,grey,greenYellow,honeyDew,hotPink,indianRed,indigo,
    ivory,khaki,lavender,lavenderBlush,lawnGreen,lemonChiffon,lightBlue,lightCoral,
    lightCyan,lightGoldenRodYellow,lightGray,lightGrey,lightGreen,lightPink,lightSalmon,
    lightSeaGreen,lightSkyBlue,lightSlateGray,lightSlateGrey,lightSteelBlue,lightYellow,
    lime,limeGreen,linen,maroon,mediumAquaMarine,mediumBlue,mediumOrchid,mediumPurple,
    mediumSeaGreen,mediumSlateBlue,mediumSpringGreen,mediumTurquoise,mediumVioletRed,
    midnightBlue,mintCream,mistyRose,moccasin,navajoWhite,navy,oldLace,olive,oliveDrab,
    orange,orangeRed,orchid,paleGoldenRod,paleGreen,paleTurquoise,paleVioletRed,papayaWhip,
    peachPuff,peru,pink,plum,powderBlue,purple,rosyBrown,royalBlue,saddleBrown,salmon,
    sandyBrown,seaGreen,seaShell,sienna,silver,skyBlue,slateBlue,slateGray,slateGrey,snow,
    springGreen,steelBlue,blueSteel,tan,teal,thistle,tomato,turquoise,violet,wheat,whiteSmoke,
    yellowGreen;


    uint hexRGB(uint Nbit = 8)() const /*@property*/;
    uint hexRGBA(uint Nbit = 8)() const /*@property*/;

    real hue() const @property
    {
        real h, s, b;
        getHsb(h, s, b);
        return h;
    }


    real saturation() const @property
    {
        immutable MAX = max(_r, _g, _b),
                  MIN = min(_r, _g, _b);

        return (MAX - MIN) / (MAX * 1.0);
    }


    real brightness() const @property
    {
        return toReal(max(_r, _g, _b));
    }


    real lightness() const @property
    {
        return (toReal(_r) + toReal(_g) + toReal(_b)) / 3;
    }


    void getHSB(F)(out F h, out F s, out F b) const
    {
      static if(!is(PixelType == real))
      {
        Color!real dst = this;
        dst.getHsb(h, s, b);
      }
      else
      {
        immutable MAX = max(_r, _g, _b),
                  MIN = min(_r, _g, _b);

        if(MAX == MIN){
            h = 0;
            s = 0;
            b = max;
            return;
        }

        if(_r == MAX)
            h = (_g - _b) / (MAX - MIN) * (1.0 / 6);
        else if(_g == MAX)
            h = (_b - _r) / (MAX - MIN) * (1.0 / 6) + (2.0 / 6);
        else /*if(_b == MAX)*/
            h = (_r - _g) / (MAX - MIN) * (1.0 / 6) + (4.0 / 6);

        if(h < 0)
            h += 1;

        s = (MAX - MIN) / MAX;
        b = MAX;
      }
    }


    void hue(string s = "cycle")(real angle)
    if(s == "cycle" || s == "deg" || s == "rad")
    {
      static if(s == "deg")
        hue!"cycle" = angle / 360;
      else static if(s == "rad")
        hue!"cycle" = angle / 2 / PI;
      else{
        real oldH, s, b;
        getHSB(oldH, s, b);
        this = fromHSB(h, s, b, _a.toReal);
      }
    }


    void saturation(real s) @property
    {
        real h, oldS, b;
        getHSB(h, oldS, b);
        this = fromHSB(h, s, b, _a.toReal);
    }


    void brightness(real b) @property
    {
        real h, s, oldB;
        getHSB(h, s, oldB);
        this = fromHSB(h, s, b, _a.toReal);
    }


    void opAssign(T)(in Color_!T color)
    if(is(T != PixelType))
    {
        immutable srcMax = color.limit,
                  dstMax = this.limit,
                  ratio = dstMax / srcMax;

        foreach(i; 0 .. 4)
            this.v[i] = this.clampOp!"*"(color.v[i], ratio);
    }


    void clampInPlace()
    {
        static if(isFloatingPoint!PixelType)
        {
            _r = _r.clamp(0.0, limit);
            _g = _g.clamp(0.0, limit);
            _b = _b.clamp(0.0, limit);
            _a = _a.clamp(0.0, limit);
        }
    }


    void invertInPlace()
    {
        _r = limit - _r;
        _g = limit - _g;
        _b = limit - _b;
    }


    void normalizeInPlace()
    {
        this /= this.brightness / limit;
    }


    void lerpInPlace(in Color!PixelType target, float amount)
    {
        immutable invAmount = 1 - amount;
        _r = invAmount * _r + amount * 
    }

    typeof(this) clamp() const
    {
        auto dst = this;
        dst.clampInPlace();
        return dst;
    }


    typeof(this) invert() const
    {

    }


    typeof(this) invert() const;
    typeof(this) normalize() const;
    typeof(this) lerp(const ofColor_<PixelType>& target, float amount) const;


    void opBinary;
    void opOpAssign;

    void toString(/**/);

  private:
    union{
        struct{
            PixelType _r = limit(),
                      _g = limit(),
                      _b = limit(),
                      _a = limit();
        }
        PixelType[4] _v;
    }


  static:
    PixelType clampOp(string op, A, B)(in A a, in B b)
    {
        return .clampOp!(op, PixelType)(a, b);
    }


    static real limit()
    {
      static if(isFloatingPoint!PixelType)
        return 1;
      else
        return PixelType.max;
    }


    static PixelType toPixelType(real f)
    {
        return cast(PixelType)(limit * f);
    }


    static real toReal(PixelType v)
    {
        return v / limit;
    }
}


private:
C clampOp(string op, C, A, B)(in A a, in B b)
{
    return clamp(mixin(`cast(real)a` ~ op ~ `cast(real)b`), 0, Color_!C.limit()).to!C;
}


A clampOp(string op, A, B)(in A a, in B b)
{
    return clamp(mixin(`cast(real)a` ~ op ~ `cast(real)b`), 0, Color_!A.limit()).to!A;
}