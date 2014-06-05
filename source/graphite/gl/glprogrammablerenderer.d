module graphite.gl.glprogrammablerenderer;

import graphite.types.basetypes,
       graphite.types.rectangle,
       graphite.graphics.polyline,
       graphite.math,
       graphite.gl.shader,
       graphite.gl.glutils,
       graphite.graphics,
       graphite.utils.matrixstack,
       graphite.gl.fbo,
       graphite.r3.primitives,
       graphite.r3.mesh,
       graphite.graphics.image,
       graphite.utils.constants,
       graphite.types.color,
       graphite.gl.vbo,
       graphite.gl.vbomesh;

final class GLProgrammableRenderer : IGLRenderer
{
    this(bool useShapeColor = true);
    ~this();

    void setup();

    //enum string TYPE = "ProgrammableGL";  // use typeid
    //static string getType(){ return TYPE; }
    
    void startRender();
    void finishRender();

    void setCurrentFBO(ref Fbo fbo);
    
    void update();
    void draw(ref Mesh vertexData, bool useColors=true, bool useTextures=true, bool useNormals = true);
    void draw(ref Mesh vertexData, PolyRenderMode renderType, bool useColors=true, bool useTextures = true, bool useNormals=true);
    void draw(ref R3Primitive model, PolyRenderMode renderType);
    void draw(ref Polyline poly);
    void draw(ref Path path);
    void draw(ref Image!() image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);
    void draw(ref FloatImage image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);
    void draw(ref ShortImage image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);
    
    bool rendersPathPrimitives(){
        return false;
    }
    
    
    
    //--------------------------------------------
    // transformations
    void pushView();
    void popView();
    
    // setup matrices and viewport (upto you to push and pop view before and after)
    // if width or height are 0, assume windows dimensions (ofGetWidth(), ofGetHeight())
    // if nearDist or farDist are 0 assume defaults (calculated based on width / height)
    void viewport(Rectangle viewport);
    void viewport(float x = 0, float y = 0, float width = 0, float height = 0, bool vflip = isVFlipped());
    void setupScreenPerspective(float width = 0, float height = 0, float fov = 60, float nearDist = 0, float farDist = 0);
    void setupScreenOrtho(float width = 0, float height = 0, float nearDist = -1, float farDist = 1);
    void setOrientation(Orientation orientation, bool vFlip);
    Rectangle getCurrentViewport();
    Rectangle getNativeViewport();
    int getViewportWidth();
    int getViewportHeight();
    bool isVFlipped() const;
    
    void setCoordHandedness(HandednessType handedness);
    HandednessType getCoordHandedness();
    
    //our openGL wrappers
    void pushMatrix();
    void popMatrix();
    void translate(float x, float y, float z = 0);
    void translate(in Vec3f p);
    void scale(float xAmnt, float yAmnt, float zAmnt = 1);
    void rotate(float degrees, float vecX, float vecY, float vecZ);
    void rotateX(float degrees);
    void rotateY(float degrees);
    void rotateZ(float degrees);
    void rotate(float degrees);
    void matrixMode(MatrixMode mode);
    void loadIdentityMatrix ();
    void loadMatrix (in Matrix4x4f m);
    void loadMatrix (in float m);
    void multMatrix (in Matrix4x4f m);
    void multMatrix (in float m);
    
    Matrix4x4f getCurrentMatrix(MatrixMode matrixMode_) const;
    
    // screen coordinate things / default gl values
    void setupGraphicDefaults();
    void setupScreen();
    
    // drawing modes
    void setFillMode(FillFlag fill);
    FillFlag getFillMode();
    void setCircleResolution(int res);
    void setSphereResolution(int res);
    void setRectMode(RectMode mode);
    RectMode getRectMode();
    void setLineWidth(float lineWidth);
    void setDepthTest(bool depthTest);
    void setLineSmoothing(bool smooth);
    void setBlendMode(BlendMode blendMode);
    void enablePointSprites();
    void disablePointSprites();
    void enableAntiAliasing();
    void disableAntiAliasing();
    
    // color options
    void setColor(int r, int g, int b); // 0-255
    void setColor(int r, int g, int b, int a); // 0-255
    void setColor(in Color!() color);
    void setColor(in Color!() color, int _a);
    void setColor(int gray); // new set a color as grayscale with one argument
    void setHexColor( int hexColor ); // hex, like web 0xFF0033;
    
    // bg color
    ref FloatColor getBgColor();
    bool bClearBg();
    void background(in Color!() c);
    void background(float brightness);
    void background(int hexColor, float _a=255.0f);
    void background(int r, int g, int b, int a=255);
    
    void setBackgroundAuto(bool bManual);       // default is true
    
    void clear(float r, float g, float b, float a=0);
    void clear(float brightness, float a=0);
    void clearAlpha();
    
    
    // drawing
    void drawLine(float x1, float y1, float z1, float x2, float y2, float z2);
    void drawRectangle(float x, float y, float z, float w, float h);
    void drawTriangle(float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3);
    void drawCircle(float x, float y, float z, float radius);
    void drawEllipse(float x, float y, float z, float width, float height);
    void drawString(string text, float x, float y, float z, DrawBitmapMode mode);

    ref Shader getCurrentShader();

    void enableTextureTarget(int textureTarget);
    void disableTextureTarget(int textureTarget);

    void beginCustomShader(ref Shader shader);
    void endCustomShader();

    void setAttributes(bool vertices, bool color, bool tex, bool normals);
    void setAlphaBitmapText(bool bitmapText);

    ref Shader defaultTexColor();
    ref Shader defaultTexNoColor();
    ref Shader defaultTex2DColor();
    ref Shader defaultTex2DNoColor();
    ref Shader defaultNoTexColor();
    ref Shader defaultNoTexNoColor();
    ref Shader bitmapStringShader();
    ref Shader defaultUniqueShader();
    
private:


    Polyline circlePolyline;
version(TARGET_OPENGLES)
{
    ofMesh circleMesh;
    ofMesh triangleMesh;
    ofMesh rectMesh;
    ofMesh lineMesh;
    ofVbo meshVbo;
}
else
{
    VboMesh circleMesh;
    VboMesh triangleMesh;
    VboMesh rectMesh;
    VboMesh lineMesh;
    Vbo meshVbo;
    Vbo vertexDataVbo;
}

    void uploadCurrentMatrix();


    void startSmoothing();
    void endSmoothing();

    void beginDefaultShader();
    void uploadMatrices();
    void setDefaultUniforms();

    
    MatrixStack matrixStack;

    bool bBackgroundAuto;
    FloatColor bgColor;
    Color!() currentColor;
    
    FillFlag bFilled;
    bool bSmoothHinted;
    RectMode rectMode;
    
    Shader * currentShader;

    bool verticesEnabled, colorsEnabled, texCoordsEnabled, normalsEnabled, bitmapStringEnabled;
    bool usingCustomShader, settingDefaultShader;
    int currentTextureTarget;

    bool wrongUseLoggedOnce;
    bool uniqueShader;
};
