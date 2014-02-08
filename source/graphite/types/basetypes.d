/*
 *  BaseTypes.h
 *  openFrameworksLib
 *
 *  Created by zachary lieberman on 1/9/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */
module graphite.types.basetypes;


import graphite.utils.constants,
       graphite.r3.mesh,
       graphite.graphics.pixels,
       graphite.graphics.polyline,
       graphite.gl,
       graphite.math,
       graphite.types,
       graphite.utils.log,
       graphite.types.types,
       graphite.utils.typeclass;


import std.traits;


//class AbstractParameter;

//template<typename T>
//class Image_;

//typedef Image_<unsigned char> Image;
//typedef Image_<float> FloatImage;
//typedef Image_<unsigned short> ShortImage;

//class Path;
////class Polyline;
//class Fbo;
//class R3Primitive;
//class Mesh;
//class PolyRenderMode;
//class Image;
//class FloatImage;
//class ShortImage;
////typedef Pixels& PixelsRef;

//bool IsVFlipped();


//----------------------------------------------------------
// BaseDraws
//----------------------------------------------------------


interface IDrawable
{
    void draw(float x, float y);
    void draw(float x, float y, float w, float h);
    mixin(declOptionalMethod("void", "draw", ["in Point"]));
    mixin(declOptionalMethod("void", "draw", ["in Rectangle"]));
    mixin(declOptionalMethod("void", "draw", ["in Point", "float", "float"]));

    float height();
    float width();

    mixin(declOptionalMethod("void", "setAnchorPercent", ["float", "float"]));
    mixin(declOptionalMethod("void", "setAnchorPoint", ["float", "float"]));
    mixin(declOptionalMethod("void", "resetAnchor", []));
}


enum isDrawable(T) = isMemberOfTypeClass!(T, IDrawable);

unittest{
    static assert(isDrawable!IDrawable);
}


void draw(T)(auto ref T t, in Point p)
if(isDrawable!T)
{
    t.callOptional!("draw", (ref t, p){
        t.draw(p.x, p.y);
    })(p);
}


void draw(T)(auto ref T t, in Rectangle r)
if(isDrawable!T)
{
    t.callOptional!("draw", (ref t, r){
        t.draw(r.x, r.y, r.width, r.height);
    })(r);
}


void draw(T)(auto ref T t, in Point p, float w, float h)
if(isDrawable!T)
{
    t.callOptional!("draw", (ref t, p, w, h){
        t.draw(p.x, p.y, w, h);
    })(p, w, h);
}


void setAnchorPercent(T)(auto ref T t, float xPct, float yPct)
if(isDrawable!T)
{
    t.callOptional!("setAnchorPercent", (ref t, xPct, yPct){
        logger.writeln!"warning"("not implemented 'setAnchorPercent'");
    })(xPct, yPct);
}


void setAnchorPoint(T)(auto ref T t, float y, float y)
if(isDrawable!T)
{
    t.callOptional!("setAnchorPercent", (ref t, x, y){
        logger.writeln!"warning"("not implemented 'setAnchorPoint'");
    })(xPct, yPct);
}


void resetAnchor(T)(auto ref T t)
if(isDrawable!T)
{
    t.callOptional!("resetAnchor", (ref t){
        logger.writeln!"warning"("not implemented 'resetAnchor'");
    })();
}


//----------------------------------------------------------
// BaseUpdates
//----------------------------------------------------------
interface IUpdatable
{
    void update();
}

enum isUpdatable(T) = isMemberOfTypeClass!(T, IUpdatable);

unittest{
    static assert(isUpdatable!IUpdatable);
}


//----------------------------------------------------------
// BaseHasTexture
//----------------------------------------------------------
//class Texture;

interface IHasTexture
{
    ref Texture texture();
    void useTexture(bool bUseTex) @property;
}


enum hasTexture(T) = isMemberOfTypeClass!(T, IHasTexture);

unittest{
    static assert(hasTexture!IHasTexture);
}


//----------------------------------------------------------
// AbstractHasPixels
//----------------------------------------------------------
//interface AbstractHasPixels{
    //virtual ~AbstractHasPixels(){}
//}

enum hasAnyPixels(T) = is(typeof((T t){
        static void takePixelsRef(U)(ref Pixels!U){}
        takePixelsRef(t.pixels);
    }));

//----------------------------------------------------------
// BaseHasPixels
//----------------------------------------------------------
//template<typename T>
interface IHasPixels(T)
{
    ref Pixels!T pixels();
}


enum hasPixels(T, E) = isMemberOfTypeClass!(T, IHasPixels!E);

unittest{
    static assert(hasPixels!(IHasPixels!ubyte, ubyte));
    static assert(hasPixels!(IHasPixels!ushort, ushort));
    static assert(hasPixels!(IHasPixels!float, float));
}


auto pixelsPtr(T)(auto ref T t)
if(hasPixels!T)
{
    return t.pixels.pixels;
}

enum hasPixels(T) = hasPixels!(T, ubyte);
enum hasFloatPixels(T) = hasPixels!(T, float);
enum hasShortPixels(T) = hasPixels!(T, ushort);

//alias BaseHasPixels_!ubyte BaseHasPixels;
//alias BaseHasPixels_!float BaseHasFloatPixels;
//alias BaseHasPixels_!ushort BaseHasShortPixels;

//----------------------------------------------------------
// AbstractImage    ->   to be able to put different types of images in vectors...
//----------------------------------------------------------
//interface AbstractImage : BaseDraws, BaseHasTexture {
    //virtual ~AbstractImage(){}
//}

interface IAnyImage : IDrawable, IHasTexture{}

enum isAnyImage(T) = isMemberOfTypeClass!(T, IAnyImage);

//----------------------------------------------------------
// BaseImage
//----------------------------------------------------------
//template<typename T>
//interface BaseImage_(T): AbstractImage, BaseHasPixels_!T
//{
//public:
    //virtual ~BaseImage_<T>(){};
//}
interface IImage(T) : IAnyImage, IHasPixels!T {}

enum isImage(T, U) = isMemberOfTypeClass!(T, IImage!U);

unittest{
    static assert(isAnyImage!(IImage!ubyte));
    static assert(isImage!(IImage!ubyte, ubyte));
    static assert(isAnyImage!(IImage!float));
    static assert(isImage!(IImage!float, float));
    static assert(isAnyImage!(IImage!ushort));
    static assert(isImage!(IImage!ushort, ushort));
}

enum isImage(T) = isImage!(T, ubyte);
enum isFloatImage(T) = isImage!(T, float);
enum isShortImage(T) = isImage!(T, ushort);

//----------------------------------------------------------
// BaseHasSoundStream
//----------------------------------------------------------

interface ISoundInput
{
    mixin(declOptionalMethod("void", "audioIn", ["float[]", "int", "int", "int", "ulong"]));
    mixin(declOptionalMethod("void", "audioIn", ["float[]", "int", "int"]));
    mixin(declOptionalMethod("void", "audioReceived", ["float[]", "int", "int"]));
}


enum isSoundInput(T) = isMemberOfTypeClass!(T, ISoundInput);


void audioIn(T)(auto ref T obj, float[] input, int bufferSize, int nChannels, int deviceID, ulong tickCount)
if(isSoundInput!T)
{
    obj.callOptional!("audioIn", (ref obj, input, bufferSize, nChannels, deviceID, tickCount){
        obj.audioIn(input, bufferSize, nChannels);
    })(input, bufferSize, nChannels, deviceID, tickCount);
}


void audioIn(T)(auto ref T obj, float[] input, int bufferSize, int nChannels)
if(isSoundInput!T)
{
    obj.callOptional!("audioIn", (ref obj, input, bufferSize, nChannels){
        obj.audioReceived(input, bufferSize, nChannels);
    })(input, bufferSize, nChannels);
}


void audioReceived(T)(auto ref T obj, float[] input, int bufferSize, int nChannels)
if(isSoundInput!T)
{
    obj.callOptional!("audioReceived", (ref obj, input, bufferSize, nChannels){
        logger.writeln!"warning"("not implemented 'audioReceived' of ", obj);
    })(input, bufferSize, nChannels);
}


unittest{
    static assert(isSoundInput!ISoundInput);
}

//----------------------------------------------------------
// BaseHasSoundStream
//----------------------------------------------------------
interface ISoundOutput
{
    mixin(declOptionalMethod("void", "audioOut", ["float[]", "int", "int", "int", "ulong"]));
    mixin(declOptionalMethod("void", "audioOut", ["float[]", "int", "int"]));
    mixin(declOptionalMethod("void", "audioRequested", ["float[]", "int", "int"]));
}


enum isSoundOutput(T) = isMemberOfTypeClass!(T, ISoundOutput);


void audioOut(T)(auto ref T obj, float[] input, int bufferSize, int nChannels, int deviceID, ulong tickCount)
if(isSoundOutput!T)
{
    obj.callOptional!("audioOut", (ref obj, input, bufferSize, nChannels, deviceID, tickCount){
        obj.audioOut(input, bufferSize, nChannels);
    })(input, bufferSize, nChannels, deviceID, tickCount);
}


void audioOut(T)(auto ref T obj, float[] input, int bufferSize, int nChannels)
if(isSoundOutput!T)
{
    obj.callOptional!("audioOut", (ref obj, input, bufferSize, nChannels){
        obj.audioRequested(input, bufferSize, nChannels);
    })(input, bufferSize, nChannels);
}


void audioRequested(T)(auto ref T obj, float[] input, int bufferSize, int nChannels)
if(isSoundOutput!T)
{
    obj.callOptional!("audioRequested", (ref obj, input, bufferSize, nChannels){
        logger.writeln!"warning"("not implemented 'audioRequested' of ", obj);
    })(input, bufferSize, nChannels);
}


unittest{
    static assert(isSoundOutput!ISoundOutput);
}


//----------------------------------------------------------
// BaseVideo
//----------------------------------------------------------
interface IVideo : IHasPixels!ubyte, IUpdatable
{
    //~BaseVideo(){}
    bool isFrameNew();
    void close();
}


enum isVideo(T) = isMemberOfTypeClass!(T, IVideo);

unittest{
    static assert(isVideo!IVideo);
}


//----------------------------------------------------------
// BaseVideoDraws
//----------------------------------------------------------
interface IDrawableVideo : IVideo, IImage!ubyte {}


enum isDrawableVideo(T) = isMemberOfTypeClass!(T, IDrawableVideo);

//----------------------------------------------------------
// BaseVideoGrabber
//----------------------------------------------------------
interface IVideoGrabber : IVideo
{
    VideoDevice[]   listDevices();
    bool    initGrabber(int w, int h);

    float height() @property;
    float width() @property;
    
    bool pixelFormat(PixelFormat pixelFormat) @property;
    PixelFormat pixelFormat() @property;

    mixin(declOptionalMethod("ref Texture", "texture", []));

    //should implement!
    void verbose(bool bTalkToMe);
    void deviceid(int _deviceID);
    void desiredframerate(int framerate);
    void videoSettings();
}


enum isVideoGrabber = isMemberOfTypeClass!(IVideoGrabber, IVideo);

private static Texture _texture_private;

ref Texture texture(T)(auto ref T obj)
if(isVideoGrabber!T)
{
    return obj.callOptional!("texture", (ref obj){
        _texture_private = null;
        return _texture_private;
    })();
}


//----------------------------------------------------------
// BaseVideoPlayer
//----------------------------------------------------------
interface IVideoPlayer : IVideo
{
    bool                loadMovie(string name);
    
    void                play();
    void                stop();

    mixin(declOptionalMethod("ref Texture", "texture", [])); // if your videoplayer needs to implement seperate texture and pixel returns for performance, implement this function to return a texture instead of a pixel array. see iPhoneVideoGrabber for reference

    float               width();
    float               height();
    
    bool                isPaused();
    bool                isLoaded();
    bool                isPlaying();

    bool                pixelFormat(PixelFormat pixelFormat) @property;
    PixelFormat         pixelFormat() @property;

    //should implement!
    float               position();
    float               speed();
    float               duration();
    bool                isMovieDone();
    
    void                setPaused(bool bPause);
    void                setPosition(float pct);
    void                setVolume(float volume); // 0..1
    void                setLoopState(LoopType state);
    void                setSpeed(float speed);
    void                setFrame(int frame);  // frame 0 = first frame...
    
    int                 currentFrame();
    int                 totalNumFrames();
    LoopType            loopState();
    
    void                firstFrame();
    void                nextFrame();
    void                previousFrame();
}


enum isVideoPlayer(T) = isMemberOfTypeClass!(T, IVideoPlayer);


ref Texture texture(T)(auto ref T obj)
if(isVideoPlayer!T)
{
    return obj.callOptional!("texture", (ref obj){
        _texture_private = null;
        return _texture_private;
    })();
}



//----------------------------------------------------------
// base renderers
//----------------------------------------------------------
//class R3Primitive;

interface IRenderer
{
    ref string typeAsString() const;

    void update();

    void draw(ref Polyline poly);
    void draw(ref Path shape);
    void draw(ref Mesh vertexData, bool useColors, bool useTextures, bool useNormals);
    void draw(ref Mesh vertexData, PolyRenderMode renderType, bool useColors, bool useTextures, bool useNormals);
    void draw(ref R3Primitive model, PolyRenderMode renderType);
    void draw(ref Image image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);
    void draw(ref FloatImage image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);
    void draw(ref ShortImage image, float x, float y, float z, float w, float h, float sx, float sy, float sw, float sh);

    //--------------------------------------------
    // transformations
    mixin(declOptionalMethod("void", "pushView", []));
    mixin(declOptionalMethod("void", "popView", []));

    // setup matrices and viewport (upto you to push and pop view before and after)
    // if width or height are 0, assume windows dimensions (GetWidth(), GetHeight())
    // if nearDist or farDist are 0 assume defaults (calculated based on width / height)
    mixin(declOptionalMethod("void", "viewport", ["Rectangle"]));
    mixin(declOptionalMethod("void", "viewport", ["float", "float", "float", "float", "bool"]));
    mixin(declOptionalMethod("void", "setupScreenPerspective", ["float", "float", "float", "float", "float"]));
    mixin(declOptionalMethod("void", "setupScreenOrtho", ["float", "float", "float", "float"]));
    mixin(declOptionalMethod("void", "setOrientation", ["Orientation", "bool"]));
    mixin(declOptionalMethod("Rectangle", "currentViewport", []));
    mixin(declOptionalMethod("Rectangle", "nativeViewport", []));
    mixin(declOptionalMethod("int", "viewportWidth", []));
    mixin(declOptionalMethod("int", "viewportHeight", []));
    mixin(declOptionalMethod("bool", "isVFlipped", [], "const"));

    mixin(declOptionalMethod("void", "coordHandedness", ["HandednessType"]));
    mixin(declOptionalMethod("HandednessType", "coordHandedness", []));

    //our openGL wrappers
    mixin(declOptionalMethod("void", "pushMatrix", []));
    mixin(declOptionalMethod("void", "popMatrix", []));
    mixin(declOptionalMethod("ref Matrix4x4f", "currentMatrix", ["MatrixMode"]));
    mixin(declOptionalMethod("void", "translate", ["float", "float", "float"]));
    mixin(declOptionalMethod("void", "translate", ["const ref Point"]));
    mixin(declOptionalMethod("void", "scale", ["float", "float", "float"]));
    mixin(declOptionalMethod("void", "rotate", ["float", "float", "float", "float"]));
    mixin(declOptionalMethod("void", "rotateX", ["float"]));
    mixin(declOptionalMethod("void", "rotateY", ["float"]));
    mixin(declOptionalMethod("void", "rotateZ", ["float"]));
    mixin(declOptionalMethod("void", "rotate", ["float"]));
    mixin(declOptionalMethod("void", "matrixMode", ["MatrixMode"]));
    mixin(declOptionalMethod("void", "loadIdentityMatrix", []));
    mixin(declOptionalMethod("void", "loadMatrix", ["const ref Matrix4x4f"]));
    mixin(declOptionalMethod("void", "loadMatrix", ["const float*"]));
    mixin(declOptionalMethod("void", "multMatrix", ["const ref Matrix4x4f"]));
    mixin(declOptionalMethod("void", "multMatrix", ["const float*"]));
    
    // screen coordinate things / default gl values
    mixin(declOptionalMethod("void", "setupGraphicDefaults", []));
    mixin(declOptionalMethod("void", "setupScreen", []));

    // drawing modes
    void setRectMode(RectMode mode);
    RectMode getRectMode();
    void setFillMode(FillFlag fill);
    FillFlag getFillMode();
    void setLineWidth(float lineWidth);
    void setDepthTest(bool depthTest);
    void setBlendMode(BlendMode blendMode);
    void setLineSmoothing(bool smooth);
    mixin(declOptionalMethod("void", "setCircleResolution", ["int"]));
    mixin(declOptionalMethod("void", "enablePointSprites", []));
    mixin(declOptionalMethod("void", "disablePointSprites", []));
    mixin(declOptionalMethod("void", "enableAntiAliasing", []));
    mixin(declOptionalMethod("void", "disableAntiAliasing", []));

    // color options
    mixin(declOptionalMethod("void", "setColor", ["int", "int", "int"])); // 0-255
    mixin(declOptionalMethod("void", "setColor", ["int", "int", "int", "int"])); // 0-255
    mixin(declOptionalMethod("void", "setColor", ["const ref Color!()"]));
    mixin(declOptionalMethod("void", "setColor", ["const ref Color!()", "int"]));
    mixin(declOptionalMethod("void", "setColor", ["int"])); // new set a color as grayscale with one argument
    mixin(declOptionalMethod("void", "setHexColor", ["int"])); // hex, like web 0xFF0033;

    // bg color
    ref FloatColor getBgColor();
    mixin(declOptionalMethod("bool", "bClearBg", []));
    mixin(declOptionalMethod("void", "background", ["const ref Color!()"]));
    mixin(declOptionalMethod("void", "background", ["float"]));
    mixin(declOptionalMethod("void", "background", ["int", "float"]));
    mixin(declOptionalMethod("void", "background", ["int", "int", "int", "int"]));

    mixin(declOptionalMethod("void", "setBackgroundAuto", ["bool"]));     // default is true

    mixin(declOptionalMethod("void", "clear", ["float", "float", "float", "float"]));
    mixin(declOptionalMethod("void", "clear", ["float", "float"]));
    mixin(declOptionalMethod("void", "clearAlpha", []));

    // drawing
    void drawLine(float x1, float y1, float z1, float x2, float y2, float z2);
    void drawRectangle(float x, float y, float z, float w, float h);
    void drawTriangle(float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3);
    void drawCircle(float x, float y, float z, float radius);
    void drawEllipse(float x, float y, float z, float width, float height);
    void drawString(string text, float x, float y, float z, DrawBitmapMode mode);


    // returns true if the renderer can render curves without decomposing them
    bool rendersPathPrimitives();
}


template defaultMethod(string name)
{
    auto ref defaultMethod(T, U...)(auto ref T obj, auto ref U args)
    {
        return obj.callOptional!(name, (ref T obj, U args){
            logger.writeln!"warning"("not implemented '" ~ name ~ "' of ", obj);

            alias Ret = typeof(mixin(`obj.` ~ name ~ "()")());
          static if(!is(Ret == void))
            return Ret.init;
        });
    }
}


alias pushView = defaultMethod!"pushView";
alias popView = defaultMethod!"popView";
alias viewport = defaultMethod!"viewport";
alias setupScreenPerspective = defaultMethod!"setupScreenPerspective";
alias setupScreenOrtho = defaultMethod!"setupScreenOrtho";
alias setOrientation = defaultMethod!"setOrientation";
alias currentViewport = defaultMethod!"currentViewport";
alias nativeViewport = defaultMethod!"nativeViewport";
alias viewportWidth = defaultMethod!"viewportWidth";
alias viewportHeight = defaultMethod!"viewportHeight";
alias isVFlipped = defaultMethod!"isVFlipped";
alias coordHandedness = defaultMethod!"coordHandedness";
alias pushMatrix = defaultMethod!"pushMatrix";
alias popMatrix = defaultMethod!"popMatrix";
alias getCurrentMatrix = defaultMethod!"currentMatrix";
alias translate = defaultMethod!"translate";
alias scale = defaultMethod!"scale";
alias rotate = defaultMethod!"rotate";
alias rotateX = defaultMethod!"rotateX";
alias rotateY = defaultMethod!"rotateY";
alias rotateZ = defaultMethod!"rotateZ";
alias matrixMode = defaultMethod!"matrixMode";
alias loadIdentityMatrix = defaultMethod!"loadIdentityMatrix";
alias loadMatrix = defaultMethod!"loadMatrix";
alias multMatrix = defaultMethod!"multMatrix";
alias setupGraphicDefaults = defaultMethod!"setupGraphicDefaults";
alias setupScreen = defaultMethod!"setupScreen";
alias setCircleResolution = defaultMethod!"setCircleResolution";
alias enablePointSprites = defaultMethod!"enablePointSprites";
alias disablePointSprites = defaultMethod!"disablePointSprites";
alias enableAntiAliasing = defaultMethod!"enableAntiAliasing";
alias disableAntiAliasing = defaultMethod!"disableAntiAliasing";
alias setColor = defaultMethod!"setColor";
alias setHexColor = defaultMethod!"setHexColor";
alias bClearBg = defaultMethod!"bClearBg";
alias background = defaultMethod!"background";
alias setBackgroundAuto = defaultMethod!"setBackgroundAuto";
alias clear = defaultMethod!"clear";
alias clearAlpha = defaultMethod!"clearAlpha";


enum isRenderer(T) = isTypeClass!(T, IRenderer);


interface IGLRenderer : IRenderer
{
    void setCurrentFBO(ref Fbo fbo);

    void enableTextureTarget(int textureTarget);
    void disableTextureTarget(int textureTarget);
}


//interface BaseSerializer
//{
    //virtual ~BaseSerializer(){}

    //void serialize(const ref AbstractParameter parameter);
    //void deserialize(ref AbstractParameter parameter);
//}


//interface BaseFileSerializer : BaseSerializer
//{
    //virtual ~BaseFileSerializer(){}

    //bool load(const ref string path);
    //bool save(const ref string path);
//}
