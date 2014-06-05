module graphite.graphics.polyline;

import graphite.types.point,
       graphite.utils.constants,
       graphite.types.rectangle,
       graphite.math,
       graphite.types.basetypes;

import std.container;

final class Polyline
{
    this();
    this(in Point[] verts);

    static Polyline fromRectangle(in Rectangle rect);

    /// remove all the points
    void clear();

    /// add a vertex
    void opOpAssign(string op : "~")(in Point p);
    void opOpAssign(string op : "~")(in Point[] p);

    //alias addVertices = opOpAssign!"~";
    //alias addVertex = opOpAssign!"~";

    // adds a straight line to the polyline
    //alias lineTo = opOpAssign!"~";
    //alias put = opOpAssign!"~";

    void insert(in Point p, size_t idx);

    // adds an arc to the polyline
    // if the arc doesn't start at the same point
    // the last vertex finished a straight line will
    // be created to join both
    void arc(in Point center, float radiusX, float radiusY, float angleBegin, float angleEnd, bool clockwise, int circleResolution = 20);
    
    void arc(in Point center, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20) {
        arc(center, radiusX,  radiusY,  angleBegin,  angleEnd, true,  circleResolution);
    }
    void arc(float x, float y, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20){
        arc(Point(x, y), radiusX, radiusY, angleBegin, angleEnd, true, circleResolution);
    }
    void arc(float x, float y, float z, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20){
        arc(Point(x, y, z), radiusX, radiusY, angleBegin, angleEnd, true, circleResolution);
    }
    void arcNegative(in Point center, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20) {
        arc(center, radiusX, radiusY, angleBegin, angleEnd, false, circleResolution);
    }
    void arcNegative(float x, float y, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20){
        arc(Point(x,y), radiusX, radiusY, angleBegin, angleEnd, false, circleResolution);
    }
    void arcNegative(float x, float y, float z, float radiusX, float radiusY, float angleBegin, float angleEnd, int circleResolution = 20){
        arc(Point(x, y, z), radiusX, radiusY, angleBegin, angleEnd, false, circleResolution);
    }
    
    
    // catmull-rom curve
    void curveTo(in Point to, int curveResolution = 20 );
    void curveTo(float x, float y, float z = 0,  int curveResolution = 20 ){
        curveTo(Point(x,y,z),curveResolution);
    }

    /// cubic bezier
    void bezierTo(in Point cp1, in Point cp2, in Point to, int curveResolution = 20);
    void bezierTo(float cx1, float cy1, float cx2, float cy2, float x, float y, int curveResolution = 20){
        bezierTo(Point(cx1,cy1),Point(cx2,cy2),Point(x,y),curveResolution);
    }
    void bezierTo(float cx1, float cy1, float cz1, float cx2, float cy2, float cz2, float x, float y, float z, int curveResolution = 20){
        bezierTo(Point(cx1,cy1,cz1),Point(cx2,cy2,cz2),Point(x,y,z),curveResolution);
    }

    /// quadratic bezier (lower resolution than cubic)
    void quadBezierTo(float cx1, float cy1, float cz1, float cx2, float cy2, float cz2, float x, float y, float z, int curveResolution = 20);
    void quadBezierTo(in Point p1, in Point p2, in Point p3,  int curveResolution = 20 ){
        quadBezierTo(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z,p3.x,p3.y,p3.z,curveResolution);
    }
    void quadBezierTo(float cx1, float cy1, float cx2, float cy2, float x, float y, int curveResolution = 20){
        quadBezierTo(cx1,cy1,0,cx2,cy2,0,x,y,0,curveResolution);
    }

    Polyline getSmoothed(int smoothingSize, float smoothingShape = 0) const;

    // resample a polyline based on the distance between the points
    Polyline getResampledBySpacing(float spacing) const;

    // resample a polyline based on the total point count
    Polyline getResampledByCount(int count) const;

    // get the bounding box of a polyline
    Rectangle getBoundingBox() const;
    
    // find the closest point 'target' on a polyline
    // optionally pass a pointer to/address of an unsigned int to get the index of the closest vertex
    Point getClosestPoint(in Point target) const;
    Point getClosestPoint(in Point target, uint nearestIndex) const;
    
    // check wheteher a point is inside the area enclosed by the polyline
    static bool inside(float x, float y, in Polyline polyline);
    static bool inside(in Point p, in Polyline polyline);

    // non-static versions
    bool inside(float x, float y) const;
    bool inside(in Point p) const;

    void simplify(float tolerance=0.3f);

    /// points vector access
    size_t size() const;
    inout(Point) opIndex(size_t index) inout;
    void resize(size_t size);

    /// closed
    void setClosed(bool tf);
    bool isClosed() const;
    void close();

    bool hasChanged();
    void flagHasChanged();

    Point[] getVertices() inout;

    float getPerimeter() const;
    float getArea() const;
    Point getCentroid2D() const;

    void draw();
    
    // used for calculating the normals
    void setRightVector(Vec3f v = Vec3f([0, 0, -1]));
    Vec3f getRightVector() const;
    
    
    // get (interpolated) index at given length along the path
    // includes info on percentage along segment, e.g. ret=5.75 => 75% along the path between 5th and 6th points
    float getIndexAtLength(float f) const;
    
    // get (interpolated) index at given percentage along the path
    // includes info on percentage along segment, e.g. ret=5.75 => 75% along the path between 5th and 6th points
    float getIndexAtPercent(float f) const;

    // get length along path at index
    float getLengthAtIndex(int index) const;
    
    // get length along path at interpolated index (e.g. f=5.75 => 75% along the path between 5th and 6th points)
    float getLengthAtIndexInterpolated(float findex) const;
    
    // get point long the path at a given length (e.g. f=150 => 150 units along the path)
    Point getPointAtLength(float f) const;
    
    // get point along the path at a given percentage (e.g. f=0.25 => 25% along the path)
    Point getPointAtPercent(float f) const;
    
    // get point along the path at interpolated index (e.g. f=5.75 => 75% along the path between 5th and 6th points)
    Point getPointAtIndexInterpolated(float findex) const;

    // get angle (degrees) at index
    float getAngleAtIndex(int index) const;
    
    // get angle (degrees) at interpolated index (interpolated between neighboring indices)
    float getAngleAtIndexInterpolated(float findex) const;
    
    // get rotation vector at index (magnitude is sin of angle)
    Vec3f getRotationAtIndex(int index) const;
    
    // get rotation vector at interpolated index (interpolated between neighboring indices) (magnitude is sin of angle)
    Vec3f getRotationAtIndexInterpolated(float findex) const;
    
    // get tangent vector at index
    Vec3f getTangentAtIndex(int index) const;
    
    // get tangent vector at interpolated index (interpolated between neighboring indices)
    Vec3f getTangentAtIndexInterpolated(float findex) const;

    // get normal vector at index
    Vec3f getNormalAtIndex(int index) const;
    
    // get normal vector at interpolated index (interpolated between neighboring indices)
    Vec3f getNormalAtIndexInterpolated(float findex) const;
    
    // get wrapped index depending on whether poly is closed or not
    int getWrappedIndex(int index) const;
    
  private:
    void setCircleResolution(int res);
    float wrapAngle(float angleRad);

    Point[] points;
    Vec3f[] rightVector;
    
    // cache
    struct Cache
    {
        float[] lengths;    // cumulative lengths, stored per point (lengths[n] is the distance to the n'th point, zero based)
        Vec3f[] tangents;   // tangent at vertex, stored per point
        Vec3f[] normals;    //
        Vec3f[] rotations;   // rotation between adjacent segments, stored per point (cross product)
        float[] angles;    // angle (degrees) between adjacent segments, stored per point (asin(cross product))
        Point centroid2D;
        float area;
    }
    Cache* _cache;


    struct CurveCache
    {
        SList!Point curveVertices;
        Point[] circlePoints;
    }
    CurveCache* _curveCache;

    bool bClosed;
    bool bHasChanged;   // public API has access to this
    bool bCacheIsDirty;   // used only internally, no public API to read
    
    void updateCache(bool bForceUpdate = false) const;
    
    // given an interpolated index (e.g. 5.75) return neighboring indices and interolation factor (e.g. 5, 6, 0.75)
    void getInterpolationParams(float findex, ref int i1, ref int i2, ref float t) const;
    
    void calcData(int index, ref Vec3f tangent, ref float angle, ref Vec3f rotation, ref Vec3f normal) const;
}


Polyline polyline()
{
    return new Polyline();
}


Polyline polyline(in Point[] p)
{
    return new Polyline(p);
}


bool isInside(in Point p, Polyline pl)
{
    return Polyline.inside(p, pl);
}