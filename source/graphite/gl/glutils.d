module graphite.gl.glutils;

import graphite.utils.constants,
       graphite.types.types,
       graphite.graphics.pixels,
       graphite.gl.shader,
       graphite.gl.glprogrammablerenderer,
       graphite.types.basetypes,
       graphite.gl.glapi;


enum PrimitiveMode{
    TRIANGLES,
    TRIANGLE_STRIP,
    TRIANGLE_FAN,
    LINES,
    LINE_STRIP,
    LINE_LOOP,
    POINTS
};

enum PolyRenderMode{
    POINTS,
    WIREFRAME,
    FILL
};

int ofGetGlInternalFormat(in Pixels!() pix);
int ofGetGlInternalFormat(in ShortPixels pix);
int ofGetGlInternalFormat(in FloatPixels pix);

//---------------------------------
// this is helpful for debugging ofTexture
string ofGetGlInternalFormatName(int glInternalFormat);
int ofGetGLFormatFromInternal(int glInternalFormat);
int ofGetGlTypeFromInternal(int glInternalFormat);

GLProgrammableRenderer ofGetGLProgrammableRenderer();
IGLRenderer ofGetGLRenderer();

int getGlFormat(T)(in ofPixels!T pixels)
{
    switch(pixels.getNumChannels())
    {
        case 4:
            return GL_RGBA;
            break;
        case 3:
            return GL_RGB;
            break;
        case 2:
version(TARGET_OPENGLES){}else{
            if(ofGetGLProgrammableRenderer())
                return GL_RG;
}
            return GL_LUMINANCE_ALPHA;
            break;

        case 1:
version(TARGET_OPENGLES){}else{
            if(ofGetGLProgrammableRenderer()){
                return GL_RED;
            }
}
            return GL_LUMINANCE;
            break;

        default:
            ofLogError("ofGLUtils") << "ofGetGlFormatAndType(): internal format not recognized, returning GL_RGBA";
            return GL_RGBA;
            break;
    }
}


//int ofGetGlType(const ofPixels pixels);
//int ofGetGlType(const ofShortPixels pixels);
//int ofGetGlType(const ofFloatPixels pixels);

ImageType ofGetImageTypeFromGLType(int glType);

GLuint ofGetGLPolyMode(PolyRenderMode m);

PolyRenderMode ofGetOFPolyMode(GLuint m);


GLuint ofGetGLPrimitiveMode(PrimitiveMode mode);

PrimitiveMode ofGetOFPrimitiveMode(GLuint mode);

int ofGetGLInternalFormatFromPixelFormat(PixelFormat pixelFormat);
int ofGetGLTypeFromPixelFormat(PixelFormat pixelFormat);
int ofGetNumChannelsFromGLFormat(int glFormat);
void ofSetPixelStorei(int w, int bpc, int numChannels);

string[] oglSupportedExtensions();
bool oglCheckExtension(string searchName);
bool olgSupportsNPOTTextures();

bool ofIsGLProgrammableRenderer();


static if(!TargetPlatform.isOpenGLES)
{
    //enum GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS            = GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT;
    //enum GL_FRAMEBUFFER_INCOMPLETE_FORMATS               = GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT;

    static if(!is(typeof(GL_UNSIGNED_INT_24_8)))
        enum GL_UNSIGNED_INT_24_8 = GL_UNSIGNED_INT_24_8_EXT;
}
else
{
    // ES1 - check if GL_FRAMEBUFFER is defined, if not assume ES1 is running.
    static if(!is(typeof(GL_FRAMEBUFFER)))
    {
        enum GL_FRAMEBUFFER                                  = GL_FRAMEBUFFER_OES;
        enum GL_RENDERBUFFER                                 = GL_RENDERBUFFER_OES;
        enum GL_DEPTH_ATTACHMENT                             = GL_DEPTH_ATTACHMENT_OES;
        enum GL_STENCIL_ATTACHMENT                           = GL_STENCIL_ATTACHMENT_OES;
        //enum GL_DEPTH_STENCIL_ATTACHMENT                   = GL_DEPTH_STENCIL_ATTACHMENT_OES;
        enum GL_DEPTH_COMPONENT                              = GL_DEPTH_COMPONENT16_OES;
        enum GL_STENCIL_INDEX                                = GL_STENCIL_INDEX8_OES;
        enum GL_FRAMEBUFFER_BINDING                          = GL_FRAMEBUFFER_BINDING_OES;
        enum GL_MAX_COLOR_ATTACHMENTS                        = GL_MAX_COLOR_ATTACHMENTS_OES;
        enum GL_MAX_SAMPLES                                  = GL_MAX_SAMPLES_OES;
        enum GL_READ_FRAMEBUFFER                             = GL_READ_FRAMEBUFFER_OES;
        enum GL_DRAW_FRAMEBUFFER                             = GL_DRAW_FRAMEBUFFER_OES;
        enum GL_WRITE_FRAMEBUFFER                            = GL_WRITE_FRAMEBUFFER_OES;
        enum GL_COLOR_ATTACHMENT0                            = GL_COLOR_ATTACHMENT0_OES;
        enum GL_FRAMEBUFFER_COMPLETE                         = GL_FRAMEBUFFER_COMPLETE_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT            = GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT    = GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS            = GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER           = GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER           = GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_OES;
        enum GL_FRAMEBUFFER_UNSUPPORTED                      = GL_FRAMEBUFFER_UNSUPPORTED_OES;
        enum GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE           = GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_OES;
        enum GL_DEPTH_COMPONENT16                            = GL_DEPTH_COMPONENT16_OES;
    }

    // ES2 + ES3 - GL_STENCIL_INDEX has been removed from gl header, and now replaced with GL_STENCIL_INDEX8.
    static if(!is(typeof(GL_STENCIL_INDEX)))
    {
        static if(!is(typeof(GL_STENCIL_INDEX8)))
            enum GL_STENCIL_INDEX                        = GL_STENCIL_INDEX8;
    }

    enum GL_FRAMEBUFFER_INCOMPLETE_FORMATS               = GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES;
    enum GL_UNSIGNED_INT_24_8                            = GL_UNSIGNED_INT_24_8_OES;

    enum GL_DEPTH24_STENCIL8                             = GL_DEPTH24_STENCIL8_OES;
    enum GL_DEPTH_STENCIL                                = GL_DEPTH24_STENCIL8_OES;
    enum GL_DEPTH_COMPONENT24                            = GL_DEPTH_COMPONENT24_OES;
    
    static if(is(typeof(GL_DEPTH_COMPONENT32_OES)))
        enum GL_DEPTH_COMPONENT32                        = GL_DEPTH_COMPONENT32_OES;
    
    version(TARGET_OF_IOS)
        static if(!is(typeof(GL_UNSIGNED_INT)))
            enum GL_UNSIGNED_INT                         = GL_UNSIGNED_INT_OES;
}
