module graphite.utils.constants;

import core.stdc.stdint;
import std.stdio;


/// version of graphite
immutable graphiteVersion = [0, 0, 0];

immutable GRAPHITE_VERSION_MAJOR = 0;       /// ditto
immutable GRAPHITE_VERSION_MINOR = 8;       /// ditto
immutable GRAPHITE_VERSION_PATCH = 0;       /// ditto


template isVersion(string vs)
{
    enum isVersion = (){
        mixin(`version(` ~ vs ~ `) return true; else return false;`);
    }();
}


template isDebug(string vs)
{
    enum isDebug = (){
        mixin(`debug(` ~ vs ~ `) return true; return false;`);
    }();
}


/// enum ofLoopType
enum LoopType
{
    none = 0x01,
    palindrome,
    normal,
}


/// enum ofTargetPlatform
//enum TargetPlatform
//{
//    OSX,
//    WINGCC,
//    WINVS,
//    IOS,
//    IPHONE,
//    ANDROID,
//    LINUX,
//    LINUX64,
//    LINUXARMV6L, // arm v6 little endian
//    LINUXARMV7L, // arm v7 little endian
//}

//-------------------------------
//  find the system type --------
//-------------------------------

//      helpful:
//      http://www.ogre3d.org/docs/api/html/OgrePlatform_8h-source.html
version(isARM)
{
    immutable string _archString;

    shared static this()
    {
        _archString = system("uname -m");
    }
}


struct TargetPlatform
{
    @disable this();
    @disable this(this);

  static:
    enum isDMD = isVersion!"DigitalMars";
    enum isWin32 = isVersion!"Win32";
    enum isWin64 = isVersion!"Win64";
    enum isWindows = isVersion!"Windows";
    enum isDMC = isDMD && isWin32;
    enum isMSVC = isDMD && isWin64;
    enum isLDC = isVersion!"LDC";
    enum isGDC = isVersion!"GNU";
    enum isSDC = isVersion!"SDC";
    enum isLinux = isVersion!"linux";
    enum isOSX = isVersion!"OSX";
    enum isIOS = isVersion!"IOS";
    enum isAndroid = isVersion!"Android";
    enum isARM = isVersion!"ARM";
    enum isRaspberryPi = isVersion!"RaspberryPi";
    enum isX86 = isVersion!"X86";
    enum isX86_64 = isVersion!"X86_64";
    enum isPosix = isVersion!"Posix";

    enum isOpenGLES = isIOS || isAndroid || isARM;
    enum isOpenGL = !isOpenGLES;

  static if(isARM)
  {
    bool isARMv6L() @property
    {
        return _archString.canFind("armv6l");
    }


    bool isARMv7L() @property
    {
        return _archString.canFind("armv7l");
    }
  }

}


import graphite.deimos.tesselator;
alias TESSindex IndexType;


void EXIT_APP(int status, string file = __FILE__, size_t line = __LINE__)
{
    enforceEx!Throwable(0, new Throwable(format("Application was terminated with %s at %s(%s)", status, file, line), filen, line));
}


/+ OpenCVを使おう *****************************************************************+/
////------------------------------------------------ capture
//// check if any video capture system is already defined from the compiler
//#if !defined(OF_VIDEO_CAPTURE_GSTREAMER) && !defined(OF_VIDEO_CAPTURE_QUICKTIME) && !defined(OF_VIDEO_CAPTURE_DIRECTSHOW) && !defined(OF_VIDEO_CAPTURE_ANDROID) && !defined(OF_VIDEO_CAPTURE_IOS)
//    #ifdef TARGET_LINUX

//        #define OF_VIDEO_CAPTURE_GSTREAMER

//    #elif defined(TARGET_OSX)
//        //on 10.6 and below we can use the old grabber
//        #ifndef MAC_OS_X_VERSION_10_7
//            #define OF_VIDEO_CAPTURE_QUICKTIME
//        #else
//            #define OF_VIDEO_CAPTURE_QTKIT
//        #endif

//    #elif defined (TARGET_WIN32)

//        // comment out this following line, if you'd like to use the
//        // quicktime capture interface on windows
//        // if not, we default to videoInput library for
//        // direct show capture...

//        #define OF_SWITCH_TO_DSHOW_FOR_WIN_VIDCAP

//        #ifdef OF_SWITCH_TO_DSHOW_FOR_WIN_VIDCAP
//            #define OF_VIDEO_CAPTURE_DIRECTSHOW
//        #else
//            #define OF_VIDEO_CAPTURE_QUICKTIME
//        #endif

//    #elif defined(TARGET_ANDROID)

//        #define OF_VIDEO_CAPTURE_ANDROID

//    #elif defined(TARGET_OF_IOS)

//        #define OF_VIDEO_CAPTURE_IOS

//    #endif
//#endif

/+ SDLを使おう ******************************************************************+/
////------------------------------------------------  video player
//// check if any video player system is already defined from the compiler
//#if !defined(OF_VIDEO_PLAYER_GSTREAMER) && !defined(OF_VIDEO_PLAYER_IOS) && !defined(OF_VIDEO_PLAYER_QUICKTIME)
//    #ifdef TARGET_LINUX
//        #define OF_VIDEO_PLAYER_GSTREAMER
//    #elif defined(TARGET_ANDROID)
//        #define OF_VIDEO_PLAYER_ANDROID
//    #else
//        #ifdef TARGET_OF_IOS
//            #define OF_VIDEO_PLAYER_IOS
//        #elif defined(TARGET_OSX)
//            //for 10.7 and 10.8 users we use QTKit for 10.6 users we use QuickTime
//            #ifndef MAC_OS_X_VERSION_10_7
//                #define OF_VIDEO_PLAYER_QUICKTIME
//            #else
//                #define OF_VIDEO_PLAYER_QTKIT
//            #endif
//        #elif !defined(TARGET_ANDROID)
//            #define OF_VIDEO_PLAYER_QUICKTIME
//        #endif
//    #endif
//#endif


/+ SDLを使おう ******************************************************************+/
////------------------------------------------------ soundstream
//// check if any soundstream api is defined from the compiler
//#if !defined(OF_SOUNDSTREAM_PORTAUDIO) && !defined(OF_SOUNDSTREAM_RTAUDIO) && !defined(OF_SOUNDSTREAM_ANDROID)
//    #if defined(TARGET_LINUX) || defined(TARGET_WIN32) || defined(TARGET_OSX)
//        #define OF_SOUNDSTREAM_RTAUDIO
//    #elif defined(TARGET_ANDROID)
//        #define OF_SOUNDSTREAM_ANDROID
//    #else
//        #define OF_SOUNDSTREAM_IOS
//    #endif
//#endif

/+ SDLを使おう ******************************************************************+/
////------------------------------------------------ soundplayer
//// check if any soundplayer api is defined from the compiler
//#if !defined(OF_SOUND_PLAYER_QUICKTIME) && !defined(OF_SOUND_PLAYER_FMOD) && !defined(OF_SOUND_PLAYER_OPENAL)
//  #ifdef TARGET_OF_IOS
//    #define OF_SOUND_PLAYER_IPHONE
//  #elif defined TARGET_LINUX
//    #define OF_SOUND_PLAYER_OPENAL
//  #elif !defined(TARGET_ANDROID)
//    #define OF_SOUND_PLAYER_FMOD
//  #endif
//#endif

//// comment out this line to disable all poco related code
//#define OF_USING_POCO


//we don't want to break old code that uses ofSimpleApp
//so we forward declare ofBaseApp and make ofSimpleApp mean the same thing
/*
class ofBaseApp;
typedef ofBaseApp ofSimpleApp;
*/
//alias ofBaseApp ofSimpleApp;

/// serial error codes
enum SerialErro
{
    noData = -2,            /// OF_SERIAL_NO_DATA
    error = -1,             /// OF_SERIAL_ERROR
}


public import std.math : PI, PI_2, abs;

immutable TWO_PI = PI * 2,
          M_TWO_PI = TWO_PI,
          FOUR_PI = PI * 2,
          HALF_PI = PI_2,
          DEG_TO_RAD = PI / 180,
          RAD_TO_DEG = 180 / PI;

alias ABS = abs;

public import std.algorithm : min, max;

alias MIN = min;
alias MAX = max;

auto CLAMP(A, B, C)(A val, B min, C max)
{
    if(val < min)
        return min;
    else if(val > max)
        return max;
    else
        return val;
}


/// enum ofFillFlag
enum FillFlag
{
    outline,        /// OF_OUTLINE
    filled,         /// OF_FILLED
}


/// enum ofWindowMode
enum WindowMode
{
    window,         /// OF_WINDOW
    fullscreen,     /// OF_FULLSCREAN
    gameMode,       /// OF_GAME_MODE
}


/// enum ofAspectRatioMode
enum AspectRatioMode
{
    ignore,                 /// OF_ASPECT_RATIO_IGNORE            = 0,
    keep,                   /// OF_ASPECT_RATIO_KEEP              = 1,
    keepByExpanding,        /// OF_ASPECT_RATIO_KEEP_BY_EXPANDING = 2,
}


/// enum ofAlignVert
enum AlignVert
{
    ignore = 0x0000,                 /// OF_ALIGN_VERT_IGNORE   = 0x0000,
    top    = 0x0010,                 /// OF_ALIGN_VERT_TOP      = 0x0010,
    bottom = 0x0020,                 /// OF_ALIGN_VERT_BOTTOM   = 0x0020,
    center = 0x0040,                 /// OF_ALIGN_VERT_CENTER   = 0x0040,
}


/// enum ofAlignHorz
enum AlignHorz
{
    ignore   = 0x0000,              /// OF_ALIGN_HORZ_IGNORE   = 0x0000
    left     = 0x0001,              /// OF_ALIGN_HORZ_LEFT     = 0x0001
    right    = 0x0002,              /// OF_ALIGN_HORZ_RIGHT    = 0x0002
    center   = 0x0004,              /// OF_ALIGN_HORZ_CENTER   = 0x0004
}


/// enum ofRectMode
enum RectMode
{
    corner = 0,                     /// OF_RECTMODE_CORNER=0,
    center = 1,                     /// OF_RECTMODE_CENTER=1
}


/// enum ofScaleMode
enum ScaleMode
{
    // ofScaleMode can usually be interpreted as a concise combination of
    // an ofAspectRatioMode, an ofAlignVert and an ofAlignHorz.
    
    // fits the SUBJECT rect INSIDE the TARGET rect.
    // Preserves SUBJECTS's aspect ratio.
    // Final Subject's Area <= Target's Area.
    // Subject's Center == Target's Center
    fit     = 0,                    /// OF_SCALEMODE_FIT     = 0,
    // FILLS the TARGET rect with the SUBJECT rect.
    // Preserves the SUBJECT's aspect ratio.
    // Subject's Area >= Target's Area.
    // Subject's Center == Target's Center
    fill    = 1,                    /// OF_SCALEMODE_FILL    = 1,
    // Preserves the SUBJECT's aspect ratio.
    // Subject's Area is Unchanged
    // Subject's Center == Target's Center
    center  = 2,                    /// OF_SCALEMODE_CENTER  = 2, // centers the subject
    // Can CHANGE the SUBJECT's aspect ratio.
    // Subject's Area == Target's Area
    // Subject's Center == Target's Center
    stretchToFill = 3,              /// OF_SCALEMODE_STRETCH_TO_FILL = 3, // simply matches the target dims
}


/// enum ofImageType
enum ImageType
{
    grayscale      = 0x00,          /// OF_IMAGE_GRAYSCALE      = 0x00,
    color          = 0x01,          /// OF_IMAGE_COLOR          = 0x01,
    colorAlpha    = 0x02,           /// OF_IMAGE_COLOR_ALPHA    = 0x02,
    undefined      = 0x03,          /// OF_IMAGE_UNDEFINED      = 0x03
}


/// enum ofPixelFormat
enum PixelFormat
{
    mono,                           /// OF_PIXELS_MONO = 0, 
    rgb,                            /// OF_PIXELS_RGB,
    rgba,                           /// OF_PIXELS_RGBA,
    bgra,                           /// OF_PIXELS_BGRA,
    rgb565,                         /// OF_PIXELS_RGB565,
    unknown,                        /// OF_PIXELS_UNKNOWN
}

immutable MaxStyleHistory =    32;     /// #define     OF_MAX_STYLE_HISTORY    32
immutable MaxViewportHistory = 32;     /// #define     OF_MAX_VIEWPORT_HISTORY 32
immutable MaxCirclePTS = 1024;         /// #define     OF_MAX_CIRCLE_PTS 1024

// Blend Modes
/// enum ofBlendMode
enum BlendMode
{
    disabled,                       /// OF_BLENDMODE_DISABLED = 0,
    alpha,                          /// OF_BLENDMODE_ALPHA    = 1,
    add,                            /// OF_BLENDMODE_ADD      = 2,
    subtract,                       /// OF_BLENDMODE_SUBTRACT = 3,
    multiply,                       /// OF_BLENDMODE_MULTIPLY = 4,
    screen,                         /// OF_BLENDMODE_SCREEN   = 5
}


//this is done to match the iPhone defaults 
//we don't say landscape, portrait etc becuase iPhone apps default to portrait while desktop apps are typically landscape
/// enum ofOrientation
enum Orientation
{
    default_,                       /// OF_ORIENTATION_DEFAULT = 1, 
    _180,                           /// OF_ORIENTATION_180 = 2,
    _90Left,                        /// OF_ORIENTATION_90_LEFT = 3,
    _90Right,                       /// OF_ORIENTATION_90_RIGHT = 4,
    unknown,                        /// OF_ORIENTATION_UNKNOWN = 5
}

// gradient modes when using ofBackgroundGradient
/// enum ofGradientMode
enum GradientMode
{
    linear,                         /// OF_GRADIENT_LINEAR = 0,
    circular,                       /// OF_GRADIENT_CIRCULAR,
    bar,                            /// OF_GRADIENT_BAR
}

// these are straight out of glu, but renamed and included here
// for convenience
//
// we don't mean to wrap the whole glu library (or any other library for that matter)
// but these defines are useful to give people flexability over the polygonizer
//
// some info:
// http://glprogramming.com/red/images/Image128.gif
//
// also: http://glprogramming.com/red/chapter11.html
// (CSG ideas)

/// enum ofPolyWindingMode
enum PolyWindingMode
{
    odd,                            /// OF_POLY_WINDING_ODD             ,
    nonzero,                        /// OF_POLY_WINDING_NONZERO         ,
    positive,                       /// OF_POLY_WINDING_POSITIVE        ,
    negative,                       /// OF_POLY_WINDING_NEGATIVE        ,
    absGeqTwo,                      /// OF_POLY_WINDING_ABS_GEQ_TWO
}

immutable close = true;                 /// #define     OF_CLOSE                          (true)


/// enum ofHandednessType
enum HandednessType
{
    leftHanded,
    rightHanded
}


/// enum ofMatrixMode
enum MatrixMode
{
    modelview,
    projection,
    texture
}

//--------------------------------------------
//
//  Keyboard definitions
//
//  ok -- why this?
//  glut key commands have some annoying features,
//  in that some normal keys have the same value as special keys,
//  but we want ONE key routine, so we need to redefine several,
//  so that we get some normalacy across keys routines
//
//  (everything that comes through "glutSpecialKeyFunc" will get 256 added to it,
//  to avoid conflicts, before, values like "left, right up down" (ie, 104, 105, 106) were conflicting with
//  letters.. now they will be 256 + 104, 256 + 105....)

enum KeyCode
{
    modifier     = 0x0100,
    return_       = 13,
    esc          = 27,
    tab          = 9,
    
    
    // http://www.openframeworks.cc/forum/viewtopic.php?t=494
    // some issues with keys across platforms:

    backspace = (){
        version(OSX)
            return 127;
        else
            return 8;
    }(),

    del = (){
        version(OSX)
            return 8;
        else
            return 127;
    }(),

    // zach - there are more of these keys, we can add them here...
    // these are keys that are not coming through "special keys"
    // via glut, but just other keys on your keyboard like

    f1           = (1 | modifier),
    f2           = (2 | modifier),
    f3           = (3 | modifier),
    f4           = (4 | modifier),
    f5           = (5 | modifier),
    f6           = (6 | modifier),
    f7           = (7 | modifier),
    f8           = (8 | modifier),
    f9           = (9 | modifier),
    f10          = (10 | modifier),
    f11          = (11 | modifier),
    f12          = (12 | modifier),
    left         = (100 | modifier),
    up           = (101 | modifier),
    right        = (102 | modifier),
    down         = (103 | modifier),
    pagUp      = (104 | modifier),
    pageDown    = (105 | modifier),
    home         = (106 | modifier),
    end          = (107 | modifier),
    insert       = (108 | modifier),
    control      = (0x200 | modifier),
    alt          = (0x400 | modifier),
    shift        = (0x800 | modifier),
    super_        = (0x1000 | modifier),
    leftShift   = (0x1 | shift),
    rightShift  = (0x2 | shift),
    leftControl = (0x1 | control),
    rightControl = (0x2 | control),
    leftAlt     = (0x1 | alt),
    rightAlt    = (0x2 | alt),
    leftSuper   = (0x1 | super_),
    rightSuper  = (0x2 | super_),
    leftCommand = leftSuper,
    rightCommand = rightSuper,

    command      = super_,
}


// not sure what to do in the case of non-glut apps....

enum MouseButton
{
     _1       = 0
    ,_2       = 1
    ,_3       = 2
    ,_4       = 3
    ,_5       = 4
    ,_6       = 5
    ,_7       = 6
    ,_8       = 7
    ,last     = _8
    ,left     = _1
    ,middle   = _2
    ,right    = _3
}

//--------------------------------------------
//console colors for our logger - shame this doesn't work with the xcode console

version(Windows){
    import std.c.windows.windows;

    enum ConsoleColor
    {
        restore = (0 | (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE) ),
        black = (0),
        red = (FOREGROUND_RED),
        green = (FOREGROUND_GREEN),
        yellow = (FOREGROUND_RED|FOREGROUND_GREEN),
        blue = (FOREGROUND_BLUE),
        purple = (FOREGROUND_RED | FOREGROUND_BLUE ),
        cyan = (FOREGROUND_GREEN | FOREGROUND_BLUE),
        white = (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE),
    }

}else{

    enum ConsoleColor
    {
        restore = (0),
        black = (30),
        red = (31),
        green = (32),
        yellow = (33),
        blue = (34),
        purple = (35),
        cyan = (36),
        white = (37),
    }
}



//--------------------------------------------
//ofBitmap draw mode
/// enum ofDrawBitmapMode
enum DrawBitmapMode
{
    simple,                 /// OF_BITMAPMODE_SIMPLE = 0,
    screen,                 /// OF_BITMAPMODE_SCREEN,
    viewport,               /// OF_BITMAPMODE_VIEWPORT,
    model,                  /// OF_BITMAPMODE_MODEL,
    modelBillboard,         /// OF_BITMAPMODE_MODEL_BILLBOARD
}


/// enum ofTextEncoding
enum TextEncoding
{
    UTF8,           /// OF_ENCODING_UTF8,
    ISO_8859_15,    /// OF_ENCODING_ISO_8859_15
}