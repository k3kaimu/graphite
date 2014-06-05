module graphite.gl.texture;

import graphite.gl;
import graphite.math;
import graphite.types;
import graphite.graphics;
import graphite.utils.constants : TargetPlatform;
import graphite.r3.mesh;


//set whether OF uses ARB rectangular texture or the more traditonal GL_TEXTURE_2D
bool getUsingArbTex();
void enableArbTex();
void disableArbTex();


bool getUsingNormalizedTexCoords();
void enableNormalizedTexCoords();
void disableNormalizedTexCoords();


//***** add global functions to override texture settings
void detTextureWrap(GLfloat wrapS = GL_CLAMP_TO_EDGE, GLfloat wrapT = GL_CLAMP_TO_EDGE);
bool getUsingCustomTextureWrap();
void restoreTextureWrap();

void setMinMagFilters(GLfloat minFilter = GL_LINEAR, GLfloat maxFilter = GL_LINEAR);
bool getUsingCustomMinMagFilters();
void restoreMinMagFilters();
//*****

//Sosolimited: texture compression
enum TexCompression
{
    none,
    srgb,
    arb,
}

struct TextureData {
    uint textureID = 0;
    int textureTarget = !TargetPlatform.isOpenGLES ? GL_TEXTURE_RECTANGLE : GL_TEXTURE_2D;
    int glTypeInternal = !TargetPlatform.isOpenGLES ? GL_RGB8 : GL_RGB; // internalFormat, e.g., GL_RGB8.
    
    float tex_t = 0;
    float tex_u = 0;
    float tex_w = 0;
    float tex_h = 0;
    float width = 0, height = 0;
    
    bool bFlipTexture = false;
    TexCompression compressionType = TexCompression.none;
    bool bAllocated = false;
    bool bUseExternalTextureID = false; //if you need to assign ofTexture's id to an externally texture. 
    Matrix4x4f textureMatrix;
    bool useTextureMatrix = false;
}

//enable / disable the slight offset we add to ofTexture's texture coords to compensate for bad edge artifiacts
//enabled by default
void enableTextureEdgeHack();
void disableTextureEdgeHack();
bool isTextureEdgeHackEnabled();


class Texture{
    this();
    ~this();

    // -----------------------------------------------------------------------
    // glInternalFormat: the format the texture will have in the graphics card (specified on allocate)
    // http://www.opengl.org/wiki/Image_Format
    //
    // glFormat: format of the uploaded data, has to match the internal format although can change order
    // pixelType: type of the uploaded data, depends on the pixels on cpu memory.
    // http://www.opengl.org/wiki/Pixel_Transfer
    //
    // for most cases is not necessary to specify glFormat and pixelType on allocate
    // and if needed for some cases like depth textures it'll be automatically guessed
    // from the internal format if not specified
    void allocate(const ref TextureData textureData);
    void allocate(const ref TextureData textureData, int glFormat, int pixelType);
    void allocate(int w, int h, int glInternalFormat); //uses the currently set OF texture type - default ARB texture
    void allocate(int w, int h, int glInternalFormat, int glFormat, int pixelType); //uses the currently set OF texture type - default ARB texture
    void allocate(int w, int h, int glInternalFormat, bool bUseARBExtention); //lets you overide the default OF texture type
    void allocate(int w, int h, int glInternalFormat, bool bUseARBExtention, int glFormat, int pixelType); //lets you overide the default OF texture type
    void allocate(const ref Pixels!() pix);
    void allocate(const ref Pixels!() pix, bool bUseARBExtention); //lets you overide the default OF texture type
    void allocate(const ref ShortPixels pix);
    void allocate(const ref ShortPixels pix, bool bUseARBExtention); //lets you overide the default OF texture type
    void allocate(const ref FloatPixels pix);
    void allocate(const ref FloatPixels pix, bool bUseARBExtention); //lets you overide the default OF texture type
    void clear();

    void setUseExternalTextureID(GLuint externTexID); //allows you to point ofTexture's texture id to an externally allocated id. 
                                                      //its up to you to set the rest of the textData params manually. 

    // glFormat can be different to the internal format of the texture in each load
    // for example to a GL_RGBA texture we can upload a  GL_BGRA pixels
    // but the number of channels need to match according to the standard
    void loadData(const ubyte* data, int w, int h, int glFormat);
    void loadData(const ushort* data, int w, int h, int glFormat);
    void loadData(const float* data, int w, int h, int glFormat);
    void loadData(const ref Pixels!() pix);        
    void loadData(const ref ShortPixels pix);
    void loadData(const ref FloatPixels pix);
    void loadData(const Pixels!() pix, int glFormat);
    void loadData(const ref ShortPixels pix, int glFormat);
    void loadData(const ref FloatPixels pix, int glFormat);
    
    // in openGL3+ use 1 channel GL_R as luminance instead of red channel
    void setRGToRGBASwizzles(bool rToRGBSwizzles);


    void loadScreenData(int x, int y, int w, int h);

    //the anchor is the point the image is drawn around.
    //this can be useful if you want to rotate an image around a particular point.
    void setAnchorPercent(float xPct, float yPct); //set the anchor as a percentage of the image width/height ( 0.0-1.0 range )
    void setAnchorPoint(float x, float y); //set the anchor point in pixels
    void resetAnchor(); //resets the anchor to (0, 0)

    //using ofBaseDraws::draw;
    void draw(const ref Point p1, const ref Point p2, const ref Point p3, const ref Point p4);
    void draw(float x, float y);
    void draw(float x, float y, float z);
    void draw(float x, float y, float w, float h);
    void draw(float x, float y, float z, float w, float h);
    
    void drawSubsection(float x, float y, float w, float h, float sx, float sy);
    void drawSubsection(float x, float y, float z, float w, float h, float sx, float sy);
    void drawSubsection(float x, float y, float w, float h, float sx, float sy, float sw, float sh);
    void drawSubsection(float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);

    void readToPixels(ref Pixels!() pixels);
    void readToPixels(ref ShortPixels pixels);
    void readToPixels(ref FloatPixels pixels);

    //for the advanced user who wants to draw textures in their own way
    void bind();
    void unbind();
    
    // these are helpers to allow you to get points for the texture ala "glTexCoordf" 
    // but are texture type independent. 
    // use them for immediate or non immediate mode
    Point getCoordFromPoint(float xPos, float yPos);      
    Point getCoordFromPercent(float xPts, float yPts);        
    
    void setTextureWrap(GLint wrapModeHorizontal, GLint wrapModeVertical);
    void setTextureMinMagFilter(GLint minFilter, GLint maxFilter);

    void setCompression(TexCompression compression);

    bool bAllocated();
    bool isAllocated();

    ref TextureData getTextureData();
    const ref TextureData getTextureData() const;

    // reference to the actual textureData inside the smart pointer
    // for backwards compatibility
    TextureData texData;

    float getHeight();
    float getWidth();

protected:
    void loadData(const void * data, int w, int h, int glFormat, int glType);
    void enableTextureTarget();
    void disableTextureTarget();

    Point anchor;
    bool bAnchorIsPct;
    Mesh quad;
}
