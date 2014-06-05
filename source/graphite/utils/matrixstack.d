module graphite.utils.matrixstack;

import graphite.utils.constants,
       graphite.types.rectangle,
       graphite.graphics,
       graphite.math,
       graphite.app.appbasewindow,
       graphite.gl.fbo;

import std.typecons;

//class ofAppBaseWindow;
//class ofFbo;

struct MatrixStack
{
    this(in ref AppBaseWindow window);

    void setRenderSurface(in ref Fbo fbo);
    void setRenderSurface(in ref AppBaseWindow window);

    void setOrientation(Orientation orientation, bool vFlip);
    Orientation getOrientation() const;

    void viewport(float x = 0, float y = 0, float width = 0, float height = 0, bool vflip = isVFlipped());
    void nativeViewport(Rectangle viewport);
    Rectangle getCurrentViewport();
    Rectangle getNativeViewport();

    ref const(Matrix4x4f) getProjectionMatrix() const;
    ref const(Matrix4x4f) getModelViewMatrix() const;
    ref const(Matrix4x4f) getModelViewProjectionMatrix() const;
    ref const(Matrix4x4f) getTextureMatrix() const;
    ref const(Matrix4x4f) getCurrentMatrix() const;
    ref const(Matrix4x4f) getProjectionMatrixNoOrientation() const;
    ref const(Matrix4x4f) getOrientationMatrix() const;
    ref const(Matrix4x4f) getOrientationMatrixInverse() const;

    MatrixMode getCurrentMatrixMode() const;

    HandednessType getHandedness() const;

    bool isVFlipped() const;
    bool customMatrixNeedsFlip() const;

    void pushView();
    void popView();

    void pushMatrix();
    void popMatrix();
    void translate(float x, float y, float z = 0);
    void scale(float xAmnt, float yAmnt, float zAmnt = 1);
    void rotate(float degrees, float vecX, float vecY, float vecZ);
    void matrixMode(MatrixMode mode);
    void loadIdentityMatrix ();
    void loadMatrix (const float * m);
    void multMatrix (const float * m);

    void clearStacks();


private:
    bool vFlipped;
    Orientation orientation;
    Rectangle currentViewport;
    HandednessType handedness;
    Fbo* currentFbo;
    AppBaseWindow* currentWindow;

    MatrixMode currentMatrixMode;

    Matrix4x4f modelViewMatrix;
    Matrix4x4f projectionMatrix;
    Matrix4x4f textureMatrix;
    Matrix4x4f modelViewProjectionMatrix;
    Matrix4x4f orientedProjectionMatrix;
    Matrix4x4f orientationMatrix;
    Matrix4x4f orientationMatrixInverse;

    Matrix4x4f * currentMatrix;

    Rectangle[] viewportHistory;
    Matrix4x4f[] modelViewMatrixStack;
    Matrix4x4f[] projectionMatrixStack;
    Matrix4x4f[] textureMatrixStack;
    Tuple!(Orientation, bool)[] orientationStack;

    int getRenderSurfaceWidth() const;
    int getRenderSurfaceHeight() const;
    bool doesHWOrientation() const;
    void updatedRelatedMatrices();
}