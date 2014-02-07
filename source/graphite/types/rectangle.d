module graphite.types.rectangle;

import graphite.math;
import graphite.types.point;
import graphite.utils.constants;


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
    this(Point pos, float w, float h)
    {
        _p = pos.vec.swizzle.xy;
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


    static typeof(this) fromCenter(in Point p, float w, float h)
    {
        return typeof(this)(p.x - w / 2, p.y - h / 2, w, h);
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
        _p = _p + c.vec.swizzle.xy;

        this._wh = [newW, newH];
    }


    void scaleTo(in Rectangle tarRect,
                 ScaleMode scaleMode = ScaleMode.fit)
    {
        final switch(scaleMode){
          case ScaleMode.fit:
            scaleTo(tarRect, AspectRatioMode.keep,
                             AlignHorz.center,
                             AlignVert.center);
            break;

          case ScaleMode.fill:
            scaleTo(tarRect, AspectRatioMode.keepByExpanding,
                             AlignHorz.center,
                             AlignVert.center);
            break;

          case ScaleMode.center:
            alignTo(tarRect, AlignHorz.center,
                             AlignVert.center);
            break;

          case ScaleMode.stretchToFill:
            scaleTo(tarRect, AspectRatioMode.ignore,
                             AlignHorz.center,
                             AlignVert.center);
            break;
        }
    }


    void scaleTo(in Rectangle tarRect,
                 AspectRatioMode subjectAspectRatioMode,
                 AlignHorz sharedHorzAnchor = AlignHorz.center,
                 AlignVert sharedVertAnchor = AlignVert.center)
    {
        scaleTo(tarRect,
                subjectAspectRatioMode,
                sharedHorzAnchor,
                sharedVertAnchor,
                sharedHorzAnchor,
                sharedVertAnchor);
    }




    void scaleTo(in Rectangle tarRect,
                 AspectRatioMode subjectAspectRatioMode,
                 AlignHorz modelHorzAnchor,
                 AlignVert modelVertAnchor,
                 AlignHorz subjectHorzAnchor,
                 AlignVert subjectVertAnchor)
    {
        immutable real tw = tarRect.width,
                       th = tarRect.height,
                       sw = this.width,
                       sh = this.height,
                       rw = tw / sw,
                       rh = th / sh;

        final switch(subjectAspectRatioMode)
        {
          case AspectRatioMode.keepByExpanding, AspectRatioMode.keep:
            if(subjectAspectRatioMode == AspectRatioMode.keepByExpanding){
                scale(.max(rw, rh));
            }else{
                scale(.min(rw, rh));
            }

            break;

          case AspectRatioMode.ignore:
            this._wh = tarRect._wh;
            break;
        }


        alignTo(tarRect,
                modelHorzAnchor,
                modelVertAnchor,
                subjectHorzAnchor,
                subjectVertAnchor);
    }


    void alignToHorz(float tarX,
                     AlignHorz thisHorzAnchor = AlignHorz.center)
    in{
        assert(thisHorzAnchor != AlignHorz.ignore);
    }
    body{
        translateX(tarX - this.horzAnchor(thisHorzAnchor));
    }


    void alignToHorz(in Rectangle tarRect,
                     AlignHorz sharedAnchor = AlignHorz.center)
    {
        alignToHorz(tarRect, sharedAnchor, sharedAnchor);
    }


    void alignToHorz(in Rectangle tarRect,
                     AlignHorz tarHorzAnchor,
                     AlignHorz thisHorzAnchor)
    in{
        assert(tarHorzAnchor != AlignHorz.ignore);
        assert(thisHorzAnchor != AlignHorz.ignore);
    }
    body{
        alignToHorz(tarRect.horzAnchor(tarHorzAnchor), thisHorzAnchor);
    }


    void alignToVert(float tarY,
                     AlignVert sharedAnchor = AlignVert.center)
    in{
        assert(sharedAnchor != AlignVert.ignore);
    }
    body{
        translateY(tarY - this.vertAnchor(sharedAnchor));
    }


    void alignToVert(in Rectangle tarRect,
                     AlignVert sharedAnchor = AlignVert.center)
    {
        alignToVert(tarRect, sharedAnchor, sharedAnchor);
    }


    void alignToVert(in Rectangle tarRect,
                     AlignVert tarVertAnchor,
                     AlignVert thisVertAnchor)
    in{
        assert(tarVertAnchor != AlignVert.ignore);
        assert(thisVertAnchor != AlignVert.ignore);
    }
    body{
        alignToVert(tarRect.vertAnchor(tarVertAnchor), thisVertAnchor);
    }


    void alignTo(in Point tarPoint,
                AlignHorz thisHorzAnchor = AlignHorz.center,
                AlignVert thisVertAnchor = AlignVert.center)
    {
        alignToHorz(tarPoint.x, thisHorzAnchor);
        alignToVert(tarPoint.y, thisVertAnchor);
    }


    void alignTo(in Rectangle tarRect,
                 AlignHorz sharedHorzAnchor = AlignHorz.center,
                 AlignVert sharedVertAnchor = AlignVert.center)
    {
        alignTo(tarRect,
                sharedHorzAnchor,
                sharedVertAnchor,
                sharedHorzAnchor,
                sharedVertAnchor);
    }

    void alignTo(in Rectangle tarRect,
                 AlignHorz tarHorzAnchor,
                 AlignVert tarVertAnchor,
                 AlignHorz thisHorzAnchor,
                 AlignVert thisVertAnchor)
    {
        alignToHorz(tarRect, tarHorzAnchor, thisHorzAnchor);
        alignToVert(tarRect, tarVertAnchor, thisVertAnchor);
    }


    bool inside(in Point p) const
    {
        return p.x > this.minX && p.y > this.minY &&
               p.x < this.maxY && p.y < this.maxY;
    }


    bool inside(in Rectangle rect) const
    {
        return this.minX < rect.maxX && this.maxX > rect.minX &&
               this.minY < rect.maxY && this.maxY > rect.minY;
    }


    bool inside(in Point p0, in Point p1) const
    {
        return inside(p0) && inside(p1);
    }



    bool intersects(in Rectangle rect) const
    {
        return this.minX < rect.maxX && this.maxX > rect.minX &&
               this.minY < rect.maxY && this.maxY > rect.minY;
    }


    bool intersects(in Point p0, in Point p1) const
    {
        Point p;

        return inside(p0) ||
               inside(p1) ||
               lineSegmentIntersection(p0, p1, topLeft, topRight, p) ||
               lineSegmentIntersection(p0, p1, topRight, bottomRight, p) ||
               lineSegmentIntersection(p0, p1, bottomRight, bottomLeft, p) ||
               lineSegmentIntersection(p0, p1, bottomLeft, topLeft, p);
    }


    void growToInclude(in Point p)
    {
        growToInclude(Rectangle(p, 0, 0));
    }


    void growToInclude(in Rectangle rect)
    {
        immutable x0 = .min(this.minX, rect.minX),
                  x1 = .max(this.maxX, rect.maxX),
                  y0 = .min(this.minY, rect.minY),
                  y1 = .max(this.maxY, rect.maxY);

        _p = [x0, y0];
        _wh = [x1 - x0, y1 - y0];
    }


    void growToInclude(in Point p0, in Point p1)
    {
        growToInclude(p0);
        growToInclude(p1);
    }


    Rectangle getIntersection(in Rectangle rect) const
    {
        immutable x0 = .max(this.minX, rect.minX),
                  x1 = .min(this.maxX, rect.maxX),
                  w = x1 - x0;

        if(w < 0)
            return Rectangle(0, 0, 0, 0);

        immutable y0 = .max(this.minY, rect.minY),
                  y1 = .min(this.maxY, rect.maxY),
                  h = y1 - y0;

        if(h < 0)
            return Rectangle(0, 0, 0, 0);

        return Rectangle(x0, y0, w, h);
    }


    Rectangle getUnion(in Rectangle rect) const
    {
        Rectangle r = this;
        r.growToInclude(rect);
        return r;
    }


    void standardize()
    {
        if(width < 0){
            x += width;
            width = -width;
        }

        if(height < 0){
            y += height;
            height = -height;
        }
    }
    

    Rectangle standardized() const @property
    {
        if(this.isStandardized)
            return this;
        else{
            Rectangle rect = this;
            rect.standardize();
            return rect;
        }
    }


    bool isStandardized() const @property
    {
        return width >= 0 && height >= 0;
    }


    float area() const @property
    {
        return abs(width * height);
    }


    float perimeter() const @property
    {
        return abs(width) * 2 + abs(height) * 2;
    }


    float aspectRatio() const @property
    {
        return abs(width / height);
    }


    bool empty() const @property
    {
        return width == 0 && height == 0;
    }


    Point min() const @property
    {
        return Point(minX, minY);
    }


    Point max() const @property
    {
        return Point(maxX, maxY);
    }


    float minX() const @property
    {
        return .min(x, x + width);
    }


    float maxX() const @property
    {
        return .max(x, x + width);
    }


    float minY() const @property
    {
        return .min(y, y + height);
    }


    float maxY() const @property
    {
        return .max(y, y + height);
    }


    float left()   const @property
    {
        return minX;
    }


    float right()  const @property
    {
        return maxX;
    }


    float top()    const @property
    {
        return minY;
    }


    float bottom() const @property
    {
        return maxY;
    }

    
    Point topLeft() const @property
    {
        return min;
    }

    Point topRight() const @property
    {
        return Point(right, top);
    }


    Point bottomLeft() const @property
    {
        return Point(left, bottom);
    }


    Point bottomRight() const @property
    {
        return max;
    }


    float horzAnchor(AlignHorz anchor) const
    in{
        assert(anchor != AlignHorz.ignore);
    }
    body{
        final switch(anchor)
        {
          case AlignHorz.left:
            return left;
          case AlignHorz.right:
            return right;
          case AlignHorz.center:
            return center.x;
          case AlignHorz.ignore:
            return 0.0;
        }
    }


    float vertAnchor(AlignVert anchor) const
    in{
        assert(anchor != AlignVert.ignore);
    }
    body{
        final switch(anchor)
        {
          case AlignVert.top:
            return top;
          case AlignVert.bottom:
            return bottom;
          case AlignVert.center:
            return center.y;
          case AlignVert.ignore:
            return 0.0;
        }
    }


    Point center() const @property
    {
        return Point(x + width / 2, y + height / 2);
    }


    Rectangle opBinary(string op : "+")(in Point p) const
    {
        Rectangle rect = this;
        rect._p = rect._p + p.vec.swizzle.xy;
    }


  private:
    Vec2f _p;
    Vec2f _wh;  // [width, height]
}
