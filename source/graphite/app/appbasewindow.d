module graphite.app.appbasewindow;

import graphite.app.baseapp;

import graphite.types;

//#if defined(TARGET_LINUX) && !defined(TARGET_RASPBERRY_PI)
//#include <X11/Xlib.h>
//#endif
static if(TargetPlatform.isLinux && !TargetPlatform.isPaspberryPI)
    import x11.xlib;

abstract class AppBaseWindow{

    this(){};
    ~this(){};

    void setupOpenGL(int w, int h, int screenMode) {}
    void initializeWindow() {}
    void runAppViaInfiniteLoop(ofBaseApp * appPtr) {}

    void hideCursor() {}
    void showCursor() {}

    void    setWindowPosition(int x, int y) {}
    void    setWindowShape(int w, int h) {}

    ofPoint getWindowPosition() {return ofPoint(); }
    ofPoint getWindowSize(){return ofPoint(); }
    ofPoint getScreenSize(){return ofPoint(); }

    void            setOrientation(ofOrientation orientation){ }
    ofOrientation   getOrientation(){ return OF_ORIENTATION_DEFAULT; }
    bool    doesHWOrientation(){return false;}

    //this is used by ofGetWidth and now determines the window width based on orientation
    int     getWidth(){ return 0; }
    int     getHeight(){ return 0; }

    void    setWindowTitle(string title){}

    int     getWindowMode() {return 0;}

    void    setFullscreen(bool fullscreen){}
    void    toggleFullscreen(){}

    void    enableSetupScreen(){}
    void    disableSetupScreen(){}
    
    void    setVerticalSync(bool enabled){};

//#if defined(TARGET_LINUX) && !defined(TARGET_RASPBERRY_PI)
//    Display* getX11Display(){return NULL;}
//    Window  getX11Window() {return 0;}
//#endif

//#if defined(TARGET_LINUX) && !defined(TARGET_OPENGLES)
//    GLXContext getGLXContext(){return 0;}
//#endif

//#if defined(TARGET_LINUX) && defined(TARGET_OPENGLES)
//    EGLDisplay getEGLDisplay(){return 0;}
//    EGLContext getEGLContext(){return 0;}
//    EGLSurface getEGLSurface(){return 0;}
//#endif

//#if defined(TARGET_OSX)
//    void * getNSGLContext(){return NULL;}
//    void * getCocoaWindow(){return NULL;}
//#endif

//#if defined(TARGET_WIN32)
//    HGLRC getWGLContext(){return 0;}
//    HWND getWin32Window(){return 0;}
//#endif
};

