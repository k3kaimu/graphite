module graphite.r3.node;

import graphite;

abstract class Node
{
    this()
    {
        this.scale = 1;
    }


    //abstract ~this();


    void setParent(Node parent, bool bMaintainGlobalTransform = false);
    //{
    //    if(bMaintainGlobalTransform)
    //        this.transformMatrix = this.globalTransformMatrix;

    //    _parent = parent;
    //}


    void clearParent(bool bMaintainGlobalTransform = false);
    //{
    //    this.setParent(null, bMaintainGlobalTransform);
    //}


    Node getParent() const;
    //{
    //    return _parent;
    //}


    Node parent() @property const { return this.getParent(); }
    void parent(Node parent) @property { this.setParent(parent, false); }


    Vec3f getPosition() const { return _position; }
    Vec3f position() @property const { return this.getPosition(); };
    float getX() const { return _position.x; }
    float getY() const { return _position.y; }
    float getZ() const { return _position.z; }
    float x() @property const { return this.getX(); };
    float y() @property const { return this.getY(); };
    float z() @property const { return this.getZ(); };

    Vec3f getXAxis() const;
    Vec3f getYAxis() const;
    Vec3f getZAxis() const;
    Vec3f xAxis() @property const { return this.getXAxis(); };
    Vec3f yAxis() @property const { return this.getYAxis(); };
    Vec3f zAxis() @property const { return this.getZAxis(); };

    Vec3f getSideDir() const;
    Vec3f getLookAtDir() const;
    Vec3f getUpDir() const;
    Vec3f sideDir() @property const;
    Vec3f lookAtDir() @property const;
    Vec3f upDir() @property const;

    float getPitch() const;
    float getHeading() const;
    float getRoll() const;
    float pitch() @property const; /*{ return this.getPitch(); }*/
    float heading() @property const; /*{ return this.getHeading(); }*/
    float roll() @property const; /*{ return this.getRoll(); }*/

    Quatf getOrientationQuat() const; /*{ return _orientation; }*/
    Vec3f getOrientationEuler() const; /*{ return _orientation.euler; }*/
    
    Vec3f getScale() const;
    //{
    //    return _scale;
    //}

    Quatf orientationQuat() @property const; /*{ return this.getOrientationQuat(); }*/
    Vec3f orientationEuler() @property const; /*{ return this.getOrientationEuler(); }*/
    Vec3f scale() @property const; /*{ return this.getScale(); }*/

    ref Matrix4x4f getLocalTransformMatrix() const;
    ref Matrix4x4f localTransformMatrix() const @property; /*{ return this.getLocalTransformMatrix(); }*/

    Matrix4x4f getGlobalTransformMatrix() const;
    Vec3f getGlobalPosition() const;
    Quatf getGlobalOrientation() const;
    Vec3f getGlobalScale() const;
    Matrix4x4f globalTransformMatrix() const @property;/* { return this.getGlobalTransformMatrix(); }*/
    Vec3f globalPosition() const @property;// { return this.getGlobalPosition(); }
    Quatf globalOrientation() const @property;// { return this.getGlobalOrientation(); }
    Vec3f globalScale() const @property;// { return this.getGlobalScale(); }

    void setTransformMatrix(const ref Matrix4x4f m44);
    //{
    //    _localTransformMatrix = m44;

    //    ofQuaternion so;
    //    _localTransformMatrix.decompose(_position, _orientation, _scale, so);

    //    this.onPositionChanged();
    //    this.onOrientationChanged();
    //    this.onScaleChanged();
    //}


    //void transformMatrix(const ref Matrix4x4f m44) @property; { this.setTransformMatrix(m44); }

    //void setPosition(float px, float py, float pz);{ this.setPosition(Vec3f(px, py, pz)); }
    //void position(const ref Vec3f p) @property; { this.setPosition(p); }
    void setPosition(const ref Vec3f p);
    //{
    //    _position = p;
    //    _localTransformMatrix.setTranslation(position);
    //    onPositionChanged();
    //}


    void setGlobalPosition(float px, float py, float pz);//{ setGlobalPosition(Vec3f(px, py, pz)); }
    void globalPosition(const ref Vec3f p) @property;// { this.setGlobalPosition(p); }
    void setGlobalPosition(const ref Vec3f p);
    //{
    //    if(parent is null)
    //        this.setPosition(p);
    //    else
    //        this.setPosition(parent.globalTransformMatrix.inverse() * p);
    //}

    void setOrientation(const ref Quatf q);
    //{
    //    _orientation = q;
    //    this.createMatrix();
    //    this.onOrientationChanged();
    //}

    void setOrientation(const ref Vec3f eulerAngles);
    //{
    //    this.setOrientation(math.Quaternion(eulerAngles.y, Vec3f(0, 1, 0), eulerAngles.x, Vec3f(1, 0, 0), eulerAngles.z, Vec3f(0, 0, 1)));
    //}

    void orientationQuat(const ref Quatf q) @property;// { this.setOrientation(q); }
    void orientationEuler(const ref Vec3f eulerAngles) @property;// { this.setOrientation(eulerAngles); }

    void setGlobalOrientation(const ref Quatf q);
    //{
    //    if(parent is null)
    //        this.setOrientation(q);
    //    else{
    //        math.Matrix4x4 invParent = _parent.globalTransformMatrix.inverse,
    //                       m44 = math.Matrix4x4(q) * invParent;
    //        this.setOrientation(m44.rotate);
    //    }
    //}

    void globalOrientation(const ref Quatf q) @property;// { this.setGlobalOrientation(q); }

    void setScale(float s);// { this.setScale(s, s, s); }
    void setScale(float sx, float sy, float sz);// { this.steScale(Vec3f(sx, sy, sz)); }
    void setScale(const ref Vec3f s);
    //{
    //    _scale = s;
    //    this.createMatrix();
    //    this.onScaleChanged();
    //}


    void scale(float s) @property;// { this.setScale(s); }
    //void scale(float sx, float sy, float sz) @property;
    void scale(const ref Vec3f s) @property;// { this.setScale(s); }

    void move(float x, float y, float z);//{ this.move(Vec3f(x, y, z)); }
    void move(const ref Vec3f offset);
    //{
    //    _position += offset;
    //    _localTransformMatrix.setTranslation(_position);
    //    this.onPositionChanged();
    //}


    void truck(float amount);//{ move(this.xAxis * amount); }
    void boom(float amount);//{ move(this.yAxis * amount); }
    void dolly(float amount);//{ move(this.zAxis * amount); }

    void tilt(float degree);//{ rotate(degree, this.xAxis); }
    void pan(float degree);//{ rotate(degree, this.yAxis); }
    void roll(float degree);//{ rotate(degree, this.zAxis); }
    void rotate(const ref Quatf q);
    //{
    //    _orientation *= q;
    //    this.createMatrix();
    //}

    void rotate(float degree, const ref Vec3f v);
    //{
    //    this.rotate(Quatf(degree, v));
    //}

    void rotate(float degree, float vx, float vy, float vz);
    //{
    //    this.rotate(Quatf(degree, Vec3f(vx, vy, vz)));
    //}

    void rotateAround(const ref Quatf q, const ref Vec3f point);
    //{
    //    this.setGlobalPosition((this.getGlobalPosition() - point) * q + point);
    //    this.onPositionChanged();
    //}

    void rotateAround(float degree, const ref Vec3f axis, const ref Vec3f point);
    //{
    //    this.rotateAround(Quatf(degree, axis), point);
    //}

    void lookAt(const ref Vec3f lookAtPosition, Vec3f upVector = Vec3f([0, 1, 0]));
    void lookAt(const ref Node lookAtNode, Vec3f upVector = Vec3f([0, 1, 0]));

    void orbit(float longitude, float latitude, float radius, Vec3f centerPoint = Vec3f([0, 0, 0]));
    void orbit(float longitude, float latitude, float radius, const ref Node centerNode);

    void transformGL() const;
    void restoreTransformGL() const;
    
    void resetTransform();
    
    abstract void customDraw();

    void draw();
    
  protected:
    Node _parent;
    
    void createMatrix();
    
    abstract void onPositionChanged() {}
    abstract void onOrientationChanged() {}
    abstract void onScaleChanged() {}

  private:
    Vec3f _position;
    Quatf _orientation;
    Vec3f _scale;
    
    Vec3f[3] _axis;
    
    Matrix4x4f _localTransformMatrix;
    // ofMatrix4x4 _globalTransformMatrix;
}