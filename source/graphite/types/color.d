module graphite.types.color;

import std.traits;
import std.algorithm;
import std.math;
import std.conv;

import graphite.math;


struct Color(PixelType = ubyte)
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
            return typeof(this).fromGray(0, a);
        }else if(s == 0){
            return typeof(this).fromGray(b, a);
        }else{
            immutable hi = floor(h * 6),
                      f = h * 6 - hi,
                      p = b * (1 - s),
                      q = b * (1 - f * s),
                      t = b * (1 - (1 - f) * s);

            if(hi.approxEqual(0))
                return typeof(this).fromRGBA(b, t, p, a);
            else if(hi.approxEqual(1))
                return typeof(this).fromRGBA(q, b, p, a);
            else if(hi.approxEqual(2))
                return typeof(this).fromRGBA(p, b, t, a);
            else if(hi.approxEqual(3))
                return typeof(this).fromRGBA(p, q, b, a);
            else if(hi.approxEqual(4))
                return typeof(this).fromRGBA(t, p, b, a);
            else
                return typeof(this).fromRGBA(b, p, q, a);
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

    //enum ofColor!PixelType white, gray, black, red, green, blue, cyan, magenta,
    //yellow,aliceBlue,antiqueWhite,aqua,aquamarine,azure,beige,bisque,blanchedAlmond,
    //blueViolet,brown,burlyWood,cadetBlue,chartreuse,chocolate,coral,cornflowerBlue,cornsilk,
    //crimson,darkBlue,darkCyan,darkGoldenRod,darkGray,darkGrey,darkGreen,darkKhaki,
    //darkMagenta,darkOliveGreen,darkorange,darkOrchid,darkRed,darkSalmon,darkSeaGreen,
    //darkSlateBlue,darkSlateGray,darkSlateGrey,darkTurquoise,darkViolet,deepPink,
    //deepSkyBlue,dimGray,dimGrey,dodgerBlue,fireBrick,floralWhite,forestGreen,fuchsia,
    //gainsboro,ghostWhite,gold,goldenRod,grey,greenYellow,honeyDew,hotPink,indianRed,indigo,
    //ivory,khaki,lavender,lavenderBlush,lawnGreen,lemonChiffon,lightBlue,lightCoral,
    //lightCyan,lightGoldenRodYellow,lightGray,lightGrey,lightGreen,lightPink,lightSalmon,
    //lightSeaGreen,lightSkyBlue,lightSlateGray,lightSlateGrey,lightSteelBlue,lightYellow,
    //lime,limeGreen,linen,maroon,mediumAquaMarine,mediumBlue,mediumOrchid,mediumPurple,
    //mediumSeaGreen,mediumSlateBlue,mediumSpringGreen,mediumTurquoise,mediumVioletRed,
    //midnightBlue,mintCream,mistyRose,moccasin,navajoWhite,navy,oldLace,olive,oliveDrab,
    //orange,orangeRed,orchid,paleGoldenRod,paleGreen,paleTurquoise,paleVioletRed,papayaWhip,
    //peachPuff,peru,pink,plum,powderBlue,purple,rosyBrown,royalBlue,saddleBrown,salmon,
    //sandyBrown,seaGreen,seaShell,sienna,silver,skyBlue,slateBlue,slateGray,slateGrey,snow,
    //springGreen,steelBlue,blueSteel,tan,teal,thistle,tomato,turquoise,violet,wheat,whiteSmoke,
    //yellowGreen;


    uint hexRGB(uint Nbit = 8)() const /*@property*/;
    uint hexRGBA(uint Nbit = 8)() const /*@property*/;

    real hue() const @property
    {
        real h, s, b;
        getHSB(h, s, b);
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
    if(isFloatingPoint!F)
    {
      static if(!isFloatingPoint!PixelType)
      {
        Color!real dst;
        dst = this;
        dst.getHSB(h, s, b);
      }
      else
      {
        immutable MAX = max(_r, _g, _b),
                  MIN = min(_r, _g, _b);

        if(MAX == MIN){
            h = 0;
            s = 0;
            b = MAX;
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
        this = fromHSB(h, s, b, toReal(_a));
    }


    void brightness(real b) @property
    {
        real h, s, oldB;
        getHSB(h, s, oldB);
        this = fromHSB(h, s, b, toReal(_a));
    }


    void opAssign(T)(in Color!T color)
    if(!is(T == PixelType))
    {
        immutable srcMax = color.limit!real,
                  dstMax = this.limit!real,
                  ratio = dstMax / srcMax;

        foreach(i; 0 .. 4)
            this._v[i] = clampOp!"*"(color._v[i], ratio);
    }


    void clampInPlace()
    {
        static if(isFloatingPoint!PixelType)
        {
            _r = .clamp(_r, 0.0, limit);
            _g = .clamp(_g, 0.0, limit);
            _b = .clamp(_b, 0.0, limit);
            _a = .clamp(_a, 0.0, limit);
        }
    }


    void invertInPlace()
    {
        _r = cast(PixelType)(limit!PixelType - _r);
        _g = cast(PixelType)(limit!PixelType - _g);
        _b = cast(PixelType)(limit!PixelType - _b);
    }


    void normalizeInPlace()
    {
        this /= this.brightness / limit;
    }


    void lerpInPlace(in Color!PixelType target, float amount)
    {
        immutable invAmount = 1 - amount;
        auto result = (1 - amount) * this._v + amount * target._v;

        foreach(i; 0 .. 4)
            this._v[i] = result[i].to!PixelType();
    }


    Unqual!(typeof(this)) clamp() const
    {
        Unqual!(typeof(this)) dst = this;
        dst.clampInPlace();
        return dst;
    }


    Unqual!(typeof(this)) invert() const
    {
        Unqual!(typeof(this)) dst = this;
        dst.invertInPlace();
        return dst;
    }


    Unqual!(typeof(this)) normalize() const
    {
        Unqual!(typeof(this)) dst = this;
        dst.normalizeInPlace();
        return dst;
    }


    Unqual!(typeof(this)) lerp(const ref Color!PixelType target, float amount) const
    {
        Unqual!(typeof(this)) dst = this;
        dst.lerpInPlace(target, amount);
        return dst;
    }


    void opOpAssign(string op)(in Color!PixelType c)
    if(op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach(i; 0 .. 3)
            this._vrgb[i] = clampOp!op(this._vrgb[i], c._vrgb[i]);
    }


    void opOpAssign(string op)(in float f)
    if(op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach(i; 0 .. 3)
            this._vrgb[i] = clampOp!op(this._vrgb[i], f);
    }


    Unqual!(typeof(this)) opBinary(string op)(in Color!PixelType c) const
    if(op == "+" || op == "-" || op == "*" || op == "/")
    {
        Unqual!(typeof(this)) dst = this;
        dst.opOpAssign!op(c);
        return dst;
    }


    Unqual!(typeof(this)) opBinary(string op)(in Color!PixelType c) const
    if(op == "+" || op == "-" || op == "*" || op == "/")
    {
        Unqual!(typeof(this)) dst = this;
        dst.opOpAssign!op(c);
        return dst;
    }


    ref SMatrix!(PixelType, 4, 1) asVec4() @property
    {
        return _v;
    }


    ref SMatrix!(PixelType, 3, 1) asVec3() @property
    {
        return _vrgb;
    }


    Color!T opCast(T : Color!T)()
    {
        Color!T dst;
        dst = this;
        return dst;
    }


    //void toString(/* */);

  private:
    union{
        struct{
            PixelType _r = limit!PixelType(),
                      _g = limit!PixelType(),
                      _b = limit!PixelType(),
                      _a = limit!PixelType();
        }
        SMatrix!(PixelType, 4, 1) _v;
        SMatrix!(PixelType, 3, 1) _vrgb;
    }


  static:
    PixelType clampOp(string op, A, B)(in A a, in B b)
    {
        return .clampOp!(op, PixelType)(a, b);
    }


    static T limit(T = real)()
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


alias FloatColor = Color!(float);
alias ShortColor = Color!(ushort);


private:
C clampOp(string op, C = A, A, B)(in A a, in B b)
{
    return clamp(mixin(`cast(real)a` ~ op ~ `cast(real)b`), 0.0, Color!C.limit!real()).to!C;
}


immutable Color!real gray = Color!real(1.0 / 2, 1.0 / 2, 1.0 / 2);
immutable Color!real white = Color!real(1.0, 1.0, 1.0);
immutable Color!real red = Color!real(1.0, 0, 0);
immutable Color!real green = Color!real(0, 1.0, 0);
immutable Color!real blue = Color!real(0, 0, 1.0);
immutable Color!real cyan = Color!real(0, 1.0, 1.0);
immutable Color!real magenta = Color!real(1.0, 0, 1.0);
immutable Color!real yellow = Color!real(1.0, 1.0, 0);
immutable Color!real black = Color!real(0, 0, 0);
immutable Color!real aliceBlue = Color!real(0.941176, 0.972549, 1);
immutable Color!real antiqueWhite = Color!real(0.980392, 0.921569, 0.843137);
immutable Color!real aqua = Color!real(0, 1, 1);
immutable Color!real aquamarine = Color!real(0.498039, 1, 0.831373);
immutable Color!real azure = Color!real(0.941176, 1, 1);
immutable Color!real beige = Color!real(0.960784, 0.960784, 0.862745);
immutable Color!real bisque = Color!real(1, 0.894118, 0.768627);
immutable Color!real blanchedAlmond = Color!real(1, 0.921569, 0.803922);
immutable Color!real blueViolet = Color!real(0.541176, 0.168627, 0.886275);
immutable Color!real brown = Color!real(0.647059, 0.164706, 0.164706);
immutable Color!real burlyWood = Color!real(0.870588, 0.721569, 0.529412);
immutable Color!real cadetBlue = Color!real(0.372549, 0.619608, 0.627451);
immutable Color!real chartreuse = Color!real(0.498039, 1, 0);
immutable Color!real chocolate = Color!real(0.823529, 0.411765, 0.117647);
immutable Color!real coral = Color!real(1, 0.498039, 0.313726);
immutable Color!real cornflowerBlue = Color!real(0.392157, 0.584314, 0.929412);
immutable Color!real cornsilk = Color!real(1, 0.972549, 0.862745);
immutable Color!real crimson = Color!real(0.862745, 0.0784314, 0.235294);
immutable Color!real darkBlue = Color!real(0, 0, 0.545098);
immutable Color!real darkCyan = Color!real(0, 0.545098, 0.545098);
immutable Color!real darkGoldenRod = Color!real(0.721569, 0.52549, 0.0431373);
immutable Color!real darkGray = Color!real(0.662745, 0.662745, 0.662745);
immutable Color!real darkGrey = Color!real(0.662745, 0.662745, 0.662745);
immutable Color!real darkGreen = Color!real(0, 0.392157, 0);
immutable Color!real darkKhaki = Color!real(0.741176, 0.717647, 0.419608);
immutable Color!real darkMagenta = Color!real(0.545098, 0, 0.545098);
immutable Color!real darkOliveGreen = Color!real(0.333333, 0.419608, 0.184314);
immutable Color!real darkorange = Color!real(1, 0.54902, 0);
immutable Color!real darkOrchid = Color!real(0.6, 0.196078, 0.8);
immutable Color!real darkRed = Color!real(0.545098, 0, 0);
immutable Color!real darkSalmon = Color!real(0.913725, 0.588235, 0.478431);
immutable Color!real darkSeaGreen = Color!real(0.560784, 0.737255, 0.560784);
immutable Color!real darkSlateBlue = Color!real(0.282353, 0.239216, 0.545098);
immutable Color!real darkSlateGray = Color!real(0.184314, 0.309804, 0.309804);
immutable Color!real darkSlateGrey = Color!real(0.184314, 0.309804, 0.309804);
immutable Color!real darkTurquoise = Color!real(0, 0.807843, 0.819608);
immutable Color!real darkViolet = Color!real(0.580392, 0, 0.827451);
immutable Color!real deepPink = Color!real(1, 0.0784314, 0.576471);
immutable Color!real deepSkyBlue = Color!real(0, 0.74902, 1);
immutable Color!real dimGray = Color!real(0.411765, 0.411765, 0.411765);
immutable Color!real dimGrey = Color!real(0.411765, 0.411765, 0.411765);
immutable Color!real dodgerBlue = Color!real(0.117647, 0.564706, 1);
immutable Color!real fireBrick = Color!real(0.698039, 0.133333, 0.133333);
immutable Color!real floralWhite = Color!real(1, 0.980392, 0.941176);
immutable Color!real forestGreen = Color!real(0.133333, 0.545098, 0.133333);
immutable Color!real fuchsia = Color!real(1, 0, 1);
immutable Color!real gainsboro = Color!real(0.862745, 0.862745, 0.862745);
immutable Color!real ghostWhite = Color!real(0.972549, 0.972549, 1);
immutable Color!real gold = Color!real(1, 0.843137, 0);
immutable Color!real goldenRod = Color!real(0.854902, 0.647059, 0.12549);
immutable Color!real grey = Color!real(0.501961, 0.501961, 0.501961);
immutable Color!real greenYellow = Color!real(0.678431, 1, 0.184314);
immutable Color!real honeyDew = Color!real(0.941176, 1, 0.941176);
immutable Color!real hotPink = Color!real(1, 0.411765, 0.705882);
immutable Color!real indianRed = Color!real (0.803922, 0.360784, 0.360784);
immutable Color!real indigo = Color!real (0.294118, 0, 0.509804);
immutable Color!real ivory = Color!real(1, 1, 0.941176);
immutable Color!real khaki = Color!real(0.941176, 0.901961, 0.54902);
immutable Color!real lavender = Color!real(0.901961, 0.901961, 0.980392);
immutable Color!real lavenderBlush = Color!real(1, 0.941176, 0.960784);
immutable Color!real lawnGreen = Color!real(0.486275, 0.988235, 0);
immutable Color!real lemonChiffon = Color!real(1, 0.980392, 0.803922);
immutable Color!real lightBlue = Color!real(0.678431, 0.847059, 0.901961);
immutable Color!real lightCoral = Color!real(0.941176, 0.501961, 0.501961);
immutable Color!real lightCyan = Color!real(0.878431, 1, 1);
immutable Color!real lightGoldenRodYellow = Color!real(0.980392, 0.980392, 0.823529);
immutable Color!real lightGray = Color!real(0.827451, 0.827451, 0.827451);
immutable Color!real lightGrey = Color!real(0.827451, 0.827451, 0.827451);
immutable Color!real lightGreen = Color!real(0.564706, 0.933333, 0.564706);
immutable Color!real lightPink = Color!real(1, 0.713726, 0.756863);
immutable Color!real lightSalmon = Color!real(1, 0.627451, 0.478431);
immutable Color!real lightSeaGreen = Color!real(0.12549, 0.698039, 0.666667);
immutable Color!real lightSkyBlue = Color!real(0.529412, 0.807843, 0.980392);
immutable Color!real lightSlateGray = Color!real(0.466667, 0.533333, 0.6);
immutable Color!real lightSlateGrey = Color!real(0.466667, 0.533333, 0.6);
immutable Color!real lightSteelBlue = Color!real(0.690196, 0.768627, 0.870588);
immutable Color!real lightYellow = Color!real(1, 1, 0.878431);
immutable Color!real lime = Color!real(0, 1, 0);
immutable Color!real limeGreen = Color!real(0.196078, 0.803922, 0.196078);
immutable Color!real linen = Color!real(0.980392, 0.941176, 0.901961);
immutable Color!real maroon = Color!real(0.501961, 0, 0);
immutable Color!real mediumAquaMarine = Color!real(0.4, 0.803922, 0.666667);
immutable Color!real mediumBlue = Color!real(0, 0, 0.803922);
immutable Color!real mediumOrchid = Color!real(0.729412, 0.333333, 0.827451);
immutable Color!real mediumPurple = Color!real(0.576471, 0.439216, 0.858824);
immutable Color!real mediumSeaGreen = Color!real(0.235294, 0.701961, 0.443137);
immutable Color!real mediumSlateBlue = Color!real(0.482353, 0.407843, 0.933333);
immutable Color!real mediumSpringGreen = Color!real(0, 0.980392, 0.603922);
immutable Color!real mediumTurquoise = Color!real(0.282353, 0.819608, 0.8);
immutable Color!real mediumVioletRed = Color!real(0.780392, 0.0823529, 0.521569);
immutable Color!real midnightBlue = Color!real(0.0980392, 0.0980392, 0.439216);
immutable Color!real mintCream = Color!real(0.960784, 1, 0.980392);
immutable Color!real mistyRose = Color!real(1, 0.894118, 0.882353);
immutable Color!real moccasin = Color!real(1, 0.894118, 0.709804);
immutable Color!real navajoWhite = Color!real(1, 0.870588, 0.678431);
immutable Color!real navy = Color!real(0, 0, 0.501961);
immutable Color!real oldLace = Color!real(0.992157, 0.960784, 0.901961);
immutable Color!real olive = Color!real(0.501961, 0.501961, 0);
immutable Color!real oliveDrab = Color!real(0.419608, 0.556863, 0.137255);
immutable Color!real orange = Color!real(1, 0.647059, 0);
immutable Color!real orangeRed = Color!real(1, 0.270588, 0);
immutable Color!real orchid = Color!real(0.854902, 0.439216, 0.839216);
immutable Color!real paleGoldenRod = Color!real(0.933333, 0.909804, 0.666667);
immutable Color!real paleGreen = Color!real(0.596078, 0.984314, 0.596078);
immutable Color!real paleTurquoise = Color!real(0.686275, 0.933333, 0.933333);
immutable Color!real paleVioletRed = Color!real(0.858824, 0.439216, 0.576471);
immutable Color!real papayaWhip = Color!real(1, 0.937255, 0.835294);
immutable Color!real peachPuff = Color!real(1, 0.854902, 0.72549);
immutable Color!real peru = Color!real(0.803922, 0.521569, 0.247059);
immutable Color!real pink = Color!real(1, 0.752941, 0.796078);
immutable Color!real plum = Color!real(0.866667, 0.627451, 0.866667);
immutable Color!real powderBlue = Color!real(0.690196, 0.878431, 0.901961);
immutable Color!real purple = Color!real(0.501961, 0, 0.501961);
immutable Color!real rosyBrown = Color!real(0.737255, 0.560784, 0.560784);
immutable Color!real royalBlue = Color!real(0.254902, 0.411765, 0.882353);
immutable Color!real saddleBrown = Color!real(0.545098, 0.270588, 0.0745098);
immutable Color!real salmon = Color!real(0.980392, 0.501961, 0.447059);
immutable Color!real sandyBrown = Color!real(0.956863, 0.643137, 0.376471);
immutable Color!real seaGreen = Color!real(0.180392, 0.545098, 0.341176);
immutable Color!real seaShell = Color!real(1, 0.960784, 0.933333);
immutable Color!real sienna = Color!real(0.627451, 0.321569, 0.176471);
immutable Color!real silver = Color!real(0.752941, 0.752941, 0.752941);
immutable Color!real skyBlue = Color!real(0.529412, 0.807843, 0.921569);
immutable Color!real slateBlue = Color!real(0.415686, 0.352941, 0.803922);
immutable Color!real slateGray = Color!real(0.439216, 0.501961, 0.564706);
immutable Color!real slateGrey = Color!real(0.439216, 0.501961, 0.564706);
immutable Color!real snow = Color!real(1, 0.980392, 0.980392);
immutable Color!real springGreen = Color!real(0, 1, 0.498039);
immutable Color!real steelBlue = Color!real(0.27451, 0.509804, 0.705882);
immutable Color!real blueSteel = Color!real(0.27451, 0.509804, 0.705882);
immutable Color!real tan = Color!real(0.823529, 0.705882, 0.54902);
immutable Color!real teal = Color!real(0, 0.501961, 0.501961);
immutable Color!real thistle = Color!real(0.847059, 0.74902, 0.847059);
immutable Color!real tomato = Color!real(1, 0.388235, 0.278431);
immutable Color!real turquoise = Color!real(0.25098, 0.878431, 0.815686);
immutable Color!real violet = Color!real(0.933333, 0.509804, 0.933333);
immutable Color!real wheat = Color!real(0.960784, 0.870588, 0.701961);
immutable Color!real whiteSmoke = Color!real(0.960784, 0.960784, 0.960784);
immutable Color!real yellowGreen = Color!real(0.603922, 0.803922, 0.196078);
