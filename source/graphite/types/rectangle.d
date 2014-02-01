module graphite.types.rectangle;

import graphite.math.matrix;

struct Rectangle
{
    /**
    this([px, py], w, h)と等価
    */
    this(float px, float py, float w, float h)
    {
        _p = [px, py];
        _wh = [w, h];
    }


    /**
    1つの位置ベクトルと、矩形の縦横の大きさを指定して作成
    */
    this(T)(T pos, float w, float h)
    if(is(typeof({_p = pos;})))
    {
        _p = pos;
        _wh = [w, h];
    }


    /**
    2つの位置ベクトルa, bによってできる矩形
    */
    this(X, Y)(X a, Y b)
    {
        immutable x0 = min(a.x, b.x),
                  x1 = max(a.x, b.x),
                  y0 = min(a.y, b.y),
                  y1 = max(a.y, b.y);

        _p = [x0, x1];
        _wh = [x1 - x0, y1 - y0];
    }


    auto ref position() inout @property
    {
        return _p;
    }


    auto ref x() inout @property
    {
        return _p[0];
    }


    auto ref y() inout @property
    {
        return _p[1];
    }


    auto ref width() inout @property
    {
        return _wh[0];
    }


    auto ref height() inout @property
    {
        return _wh[1];
    }


    auto ref size() inout @property
    {
        return _wh;
    }


    void translateX(float dx)
    {
        _p.x += dx;
    }


    void translateY(float dy)
    {
        _p.y += dy;
    }


    void translate(T)(T dp)
    if(is(typeof({_p = _p + dp;})))
    {
        _p = _p + dp;
    }


    void translate(float dx, float dy)
    {
        translate([dx, dy].toMatrix!(2, 1));
    }


    void scale(float s)
    {
        _wh *= s;
    }


    void scale(T)(T s)
    if(is(typeof(s[0], s[1])))
    {
        _wh[0] *= s[0];
        _wh[1] *= s[1];
    }


    void scale(string s : "width")(float s)
    {
        _wh[0] *= s;
    }


    void scale(string s : "height")(float s)
    {
        _wh[1] *= s;
    }


    void scaleFromCenter(float s)
    {
        scaleFromCenter(s, s);
    }


    void scaleFromCenter(float sX, float sY)
    {
        return scaleFromCenter([sX, sY].toMatrix!(2, 1));
    }


    void scaleFromCenter(T)(T s)
    if(is(typeof(s[0], s[1])))
    {
        if(s[0] == 1 && s[1] == 1)
            return;

        immutable newW = _wh[0] * s[0],
                  newH = _wh[1] * s[1];

        immutable c = this.center();

        _p = [newW, newH];
        _p *= -1 / 2.0;
        _p += c;

        _w = newW;
        _h = newH;
    }


  private:
    Vec2f _p;
    Vec2f _wh;  // [width, height]
}