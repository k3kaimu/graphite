module graphite.r3.node;

import graphite;

abstract class Node
{
    this()
    {
        this.scale = 1;
    }


    abstract ~this();


    void setParent(Node parent, bool bMaintainGlobalTransform = false)
    {
        if(bMaintainGlobalTransform)
            this.transformMatrix = this.globalTransformMatrix;

        _parent = parent;
    }


    void clearParent(bool bMaintainGlobalTransform = false)
    {
        this.setParent(null, bMaintainGlobalTransform);
    }


    Node getParent() const
    {
        return _parent;
    }


    Node parent() @property const { return this.getParent(); }
    void parent(Node parent) @property { this.setParent(parent, false); }


    math.Vec3f getPosition() const { return _position; }
    math.Vec3f position() @property const { return this.getPosition(); };
    float getX() const { return _position.x; }
    float getY() const { return _position.y; }
    float getZ() const { return _position.z; }
    float x() @property const { return this.getX(); };
    float y() @property const { return this.getY(); };
    float z() @property const { return this.getZ(); };

    math.Vec3f getXAxis() const;
    math.Vec3f getYAxis() const;
    math.Vec3f getZAxis() const;
    math.Vec3f xAxis() @property const { return this.setXAxis(); };
    math.Vec3f yAxis() @property const { return this.setYAxis(); };
    math.Vec3f zAxis() @property const { return this.setZAxis(); };

    math.Vec3f getSideDir() const;
    math.Vec3f getLookAtDir() const;
    math.Vec3f getUpDir() const;
    math.Vec3f sideDir() @property const;
    math.Vec3f lookAtDir() @property const;
    math.Vec3f upDir() @property const;

    float getPitch() const;
    float getHeading() const;
    float getRoll() const;
    float pitch() @property const { return this.setPitch(); }
    float heading() @property const { return this.setHeading(); }
    float roll() @property const { return this.setRoll(); }

    math.Quanternion getOrientationQuat() const { return _orientation; }
    math.Vec3f getOrientationEuler() const { return _orientation.euler; }
    
    math.Vec3f getScale() const 
    {
        return _scale;
    }

    math.Quanternion orientationQuat() @property const { return this.setorientationQuat(); }
    math.Vec3f orientationEuler() @property const { return this.setorientationEuler(); }
    math.Vec3f scale() @property const { return this.setscale(); }

    ref math.Matrix4x4 getLocalTransformMatrix() const;
    ref math.Matrix4x4 localTransformMatrix() const @property { return this.getLocalTransformMatrix(); }

    math.Matrix4x4 getGlobalTransformMatrix() const;
    math.Vec3f getGlobalPosition() const;
    math.Quanternion getGlobalOrientation() const;
    math.Vec3f getGlobalScale() const;
    math.Matrix4x4 globalTransformMatrix() const @property { return this.getGlobalTransformMatrix(); };
    math.Vec3f globalPosition() const @property { return this.getGlobalPosition(); };
    math.Quanternion globalOrientation() const @property { return this.getGlobalOrientation(); };
    math.Vec3f globalScale() const @property { return this.getGlobalScale(); };

    void setTransformMatrix(const ref math.Matrix4x4 m44)
    {
        _localTransformMatrix = m44;

        ofQuaternion so;
        _localTransformMatrix.decompose(_position, _orientation, _scale, so);

        this.onPositionChanged();
        this.onOrientationChanged();
        this.onScaleChanged();
    }


    void transformMatrix(const ref math.Matrix4x4 m44) @property { this.setTransformMatrix(m44); }

    void setPosition(float px, float py, float pz){ this.setPosition(math.Vec3f(px, py, pz)); }
    void position(const ref math.Vec3f p) @property { this.setPosition(p); }
    void setPosition(const ref math.Vec3f p)
    {
        _position = p;
        _localTransformMatrix.setTranslation(position);
        onPositionChanged();
    }


    void setGlobalPosition(float px, float py, float pz){ setGlobalPosition(math.Vec3f(px, py, pz)); }
    void globalPosition(const ref math.Vec3f p) @property { this.setGlobalPosition(p); }
    void setGlobalPosition(const ref math.Vec3f p)
    {
        if(parent is null)
            this.setPosition(p);
        else
            this.setPosition(parent.globalTransformMatrix.inverse() * p);
    }

    void setOrientation(const ref math.Quanternion q)
    {
        _orientation = q;
        this.createMatrix();
        this.onOrientationChanged();
    }

    void setOrientation(const ref math.Vec3f eulerAngles)
    {
        this.setOrientation(math.Quaternion(eulerAngles.y, math.Vec3f(0, 1, 0), eulerAngles.x, math.Vec3f(1, 0, 0), eulerAngles.z, math.Vec3f(0, 0, 1)));
    }

    void orientationQuat(const ref math.Quanternion q) @property { this.setOrientation(q) };
    void orientationEuler(const ref math.Vec3f eulerAngles) @property { this.setOrientation(eulerAngles) };

    void setGlobalOrientation(const ref math.Quanternion q)
    {
        if(parent is null)
            this.setOrientation(q);
        else{
            math.Matrix4x4 invParent = _parent.globalTransformMatrix.inverse,
                           m44 = math.Matrix4x4(q) * invParent;
            this.setOrientation(m44.rotate);
        }
    }

    void globalOrientation(const ref math.Quanternion q) @property { this.setGlobalOrientation(q); }

    void setScale(float s) { this.setScale(s, s, s); }
    void setScale(float sx, float sy, float sz) { this.steScale(math.Vec3f(sx, sy, sz)); }
    void setScale(const ref math.Vec3f s)
    {
        _scale = s;
        this.createMatrix();
        this.onScaleChanged();
    }


    void scale(float s) @property { this.setScale(s); }
    //void scale(float sx, float sy, float sz) @property;
    void scale(const ref math.Vec3f s) @property { this.setScale(s); }

    void move(float x, float y, float z){ this.move(math.Vec3f(x, y, z)); }
    void move(const ref math.Vec3f offset)
    {
        _position += offset;
        _localTransformMatrix.setTranslation(_position);
        this.onPositionChanged();
    }


    void truck(float amount){ move(this.xAxis * amount); }
    void boom(float amount){ move(this.yAxis * amount); }
    void dolly(float amount){ move(this.zAxis * amount); }

    void tilt(float degree){ rotate(degree, this.xAxis); }
    void pan(float degree){ rotate(degree, this.yAxis); }
    void roll(float degree){ rotate(degree, this.zAxis); }
    void rotate(const ref math.Quanternion q)
    {
        _orientation *= q;
        this.createMatrix();
    }

    void rotate(float degree, const ref math.Vec3f v)
    {
        this.rotate(math.Quanternion(degree, v));
    }

    void rotate(float degree, float vx, float vy, float vz)
    {
        this.rotate(math.Quanternion(degree, math.Vec3f(vx, vy, vz)));
    }

    void rotateAround(const ref math.Quanternion q, const ref math.Vec3f point)
    {
        this.setGlobalPosition((this.getGlobalPosition() - point) * q + point);
        this.onPositionChanged();
    }

    void rotateAround(float degree, const ref math.Vec3f axis, const ref math.Vec3f point)
    {
        this.rotateAround(math.Quanternion(degree, axis), point);
    }

    void lookAt(const ref math.Vec3f lookAtPosition, math.Vec3f upVector = math.Vec3f(0, 1, 0));
    void lookAt(const ref r3.Node lookAtNode, math.Vec3f upVector = math.Vec3f(0, 1, 0));

    void orbit(float longitude, float latitude, float radius, math.Vec3f centerPoint = math.Vec3f(0, 0, 0));
    void orbit(float longitude, float latitude, float radius, const ref ofNode centerNode);

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
    ofVec3f _position;
    ofQuaternion _orientation;
    ofVec3f _scale;
    
    ofVec3f[3] _axis;
    
    ofMatrix4x4 _localTransformMatrix;
    // ofMatrix4x4 _globalTransformMatrix;
}