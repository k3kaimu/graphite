# ファイルの親子関係

Poco？！
そんなの気合で乗り切れ！

videoとsoundもSDLで乗り切れるよね？


## 推奨攻略モジュール

    3. (ofColor)
    4. ofTypes
    5. utils

    など


## パッケージ一覧

+ app
    - [ofAppBaseWindow]

        [ofPoint], ofTypes, ofAppEGLWindow, ofGraphics, ofAppRunner, ofUtils, ofFileUtils, (ofGLProgrammableRenderer)


    - ofAppEGLWindow(OpenGL ES用なので実装する必要なし)

        [opBaseApp], [ofAppBaseWindow], [ofThread], ofImage


    - ofAppGLFWWindow

        [ofConstants], [ofAppBaseWindow], [ofEvents], (ofPixels), [opBaseApp], (ofGLProgrammableRenderer) ofAppRunner


    - ofAppGlutWindow

        [ofConstants], [ofAppBaseWindow], [ofEvents], ofTypes, [opBaseApp], ofUtils, ofGraphics, ofAppRunner, (ofGLProgrammableRenderer)


    - ofAppNoWindow

        [ofConstants], [ofAppBaseWindow], (ofBaseTypes), [opBaseApp], ofGraphics


    - ofAppRunner

        [ofConstants], [ofPoint], (ofRectangle), ofTypes, [opBaseApp], [ofAppBaseWindow], ofSoundPlayer, ofSoundStream, ofImage, ofUtils, [ofEvents], ofMath, ofGraphics, ofGLRenderer, (ofGLProgrammableRenderer), ofTrueTypeFont, ofURLFileLoader, Poco/Net/SSLManager, ofQtUtils

    - [opBaseApp]

        [ofPoint], [ofEvents], (ofBaseTypes),


    - ofIcon

        null


+ communication

    - ofArduino

        [ofEvents], ofSerial, ofUtils


    - ofSerial

        [ofConstants], ofTypes, ofUtils


+ events

    - ofDelegate(Dのデリゲートでいいのかな？)

        Poco/AbstractPriorityDelegate


    - [ofEvents]

        [ofConstants], [ofPoint], [ofEventUtils], ofAppRunner, [opBaseApp], ofUtils, ofGraphics


    - [ofEventUtils]

        ofConstant, Poco/PriorityEvent, Poco/PriorityDelegate, ofDelegate


+ gl

    - (ofFbo)

        (ofTexture), [ofConstants], ofAppRunner, ofUtils, ofGraphics, ofGLRenderer,


    - (ofGLProgrammableRenderer)

        (ofBaseTypes), (ofPolyline), [ofMatrix4x4], (ofShader), ofGraphics, (ofMatrixStack), (ofMesh), ofPath, ofGraphics, ofAppRunner, ofBitmapFont, ofGLUtils, ofImage, (ofFbo), ofVbo, of3dPrimitives


    - ofGLRenderer

        (ofBaseTypes), (ofPolyline), [ofMatrix4x4], ofGraphics, (ofMatrixStack), (ofMesh), ofPath, ofAppRunner, of3dPrimitives, ofBitmapFont, ofGLUtils, ofImage, (ofFbo)


    - ofGLUtils

        ofConstans, ofTypes, (ofPixels), ofProgrammableRenderer, ofGraphics, (ofShader), (ofBaseTypes), ofRendererCollection


    - ofLight

        ofNode, (ofColor), of3dGraphics, [ofConstants], [ofLog], ofUtils,


    - ofMaterial

        (ofColor), [ofConstants],


    - (ofShader)

        [ofConstants], (ofBaseTypes), (ofTexture), [ofMatrix4x4], [ofAppBaseWindow],


    - (ofTexture)

        [ofPoint]s, (ofRectangle), (ofBaseTypes), [ofConstants], ofVboMesh, ofUtils, ofAppRunner, ofGraphics, (ofPixels), ofGLUtils,


    - ofVbo

        [ofConstants], [ofVec3f], (ofColor), ofUtils, (ofMesh), ofGLUtils, ofUtils, (ofShader), ofGLProgrammableRender


     - ofVboMesh

        (ofMesh), ofVbo, 


+ graphics

    - of3dGraphics

        [ofConstants], (ofColor), [ofPoint], [ofMatrix4x4], (ofRectangle), ofTypes, ofBaseType, ofGLRenderer, of3dPrimitives, ofGraphics, ofVboMesh


    - ofBitmapFont

        [ofCOnstants], (ofRectangle), ofGraphics


    - ofCairoRenderer

        cairo-features, cairo-pdf, cairo-svg, cairo, [ofMatrix4x4], ofBaseType, ofPath


    - ofGraphics

        [ofConstants], (ofColor), [ofPoint], [ofMatrix4x4], (ofRectangle), ofTypes, (ofBaseTypes)


    - ofImage

        ofFileUtils, (ofTexture), (ofPixels), (ofBaseTypes), [ofConstants], ofAppRunner, ofTypes, ofURLFileLoader, ofGraphics, FreeImage


    - ofPath

        [ofConstants], [ofPoint], (ofColor), (ofPolyline), ofBaseType, ofVboMesh, ofTessellator, ofGrapics


    - (ofPixels)


        [ofConstants], ofUtils, (ofColor), ofMath


    - (ofPolyline)

        [ofPoint], [ofConstants], (ofRectangle), (ofPolyline), ofGraphics


    - ofRendererCollection

        (ofBaseTypes), ofGLRenderer


    - ofTessellator

        [ofConstants], (ofMesh), ofTypes, (ofPolyline), [tesselator]


    - ofTrueTypeFont

        [ofPoint], (ofRectangle), [ofConstants], ofPath, (ofTexture), (ofMesh)


+ math

    - ofMath

        [ofPoint], [ofConstants], ofUtils, ofAppRunner, float, [ofNoise], (ofPolyline)


    - [ofMatrix3x3] [攻略済み]

        [ofConstants], 


    - [ofMatrix4x4] [攻略済み]

        [ofVec3f], [ofVec4f], [ofQuaternion], [ofConstants], 


    - [ofQuaternion] [攻略済み]

        [ofConstants], [ofVec3f], [ofVec4f], [ofMatrix4x4], ofMath


    - [ofVec2f] [攻略済み]

        [ofConstants], [ofVec3f], [ofVec4f]


    - [ofVec3f] [攻略済み]

        [ofVec2f], [ofVec4f], [ofConstants]


    - [ofVec4f] [攻略済み]

        [ofConstants], [ofVec2f], [ofVec3f]


    - [ofVectorMatrix] [攻略済み]

        [ofVec2f], [ofVec3f], [ofVec4f], [ofMatrix3x3], [ofMatrix4x4], [ofQuaternion]


+ r3

    - of3dPrimitives

        ofVboMesh, (ofRectangle), ofNode, ofRTexture, ofGraphics


    - of3dUtils

        [ofVectorMatrix], ofGraphics, of3dGraphics


    - ofCamera

        (ofRectangle), ofAppRunner, ofNode, [ofLog]


    - ofEasyCam

        ofCamera, [ofEvents], ofMath, ofUtils


    - (ofMesh)

        [ofVec3f], [ofVec2f], (ofColor), ofUtils, [ofConstants], ofGLUtils, (ofMesh), ofGraphics


    - ofNode

        ofVectorMath, of3dUtils, ofGraphics, ofMath, [ofLog], of3dGraphics


+ sound

    - ofBaseSoundPlayer

        [ofConstants]


    - ofBaseSoundStream

        [ofConstants]


    - ofFmodSoundPlayer

        [ofConstants], ofBaseSoundPlayer, fmod, fmod_error, ofUtils


    - ofOpenALSoundPlayer

        [ofConstants], ofBaseSoundPlayer, [ofEvents], [ofThread], OpenAL/al, OpenAL/alc, kiss_fft, kiss_fftr, sndfile, mpg123


    - ofPASoundStream

        [ofConstants], ofBaseSoundStream, ofTypes, portaudio, ofUtils, [ofEvents], [opBaseApp]


    - ofRtAudioSoundStream

        [ofConstants], ofBaseSoundStream, ofTypes, ofSoundStream, ofMath, ofUtils, RtAudio


    - ofSoundPlayer

        [ofConstants], ofTypes, ofUtils, 


    - ofSoundStream

        [ofConstants], ofBaseType, [opBaseApp], ofTypes, ofBaseSoundStream, ofAppRunner


+ types

    - (ofBaseTypes)

        [ofPoint], (ofRectangle), [ofConstants], (ofColor), (ofMesh), (ofPixels), [ofMatrix4x4], ofTypes, ofUtils


    - (ofColor)

        ofMath, [ofConstants]


    - ofParameters

        [ofEvents], ofTypes, ofUtils, ofParameterGroup


    - ofParametersGroup

        Poco/Any, [ofConstants], [ofLog], ofParameter, ofUtils


    - [ofPoint] [攻略済み]

        [ofVec3f]


    - (ofRectangle)

        [ofConstants], [ofPoint], [ofLog]


    - ofTypes

        [ofConstants], (ofColor)


+ utils

    - [ofConstants] [攻略済み]

        (null)


    - ofFileUtils

        [ofConstants], Poco/File, ofUtils, mach-o/dyld


    - [ofLog] [攻略済み]

        [ofConstants], ofFileUtils, ofTypes, ofUtils


    - (ofMatrixStack)

        [ofConstants], (ofRectangle), ofGraphics, [ofMatrix4x4], (ofMatrixStack), [ofAppBaseWindow], (ofFbo)


    - [ofNoise] [攻略済み]

        (null)


    - ofSystemUtils

        [ofConstants], ofFileUtils, [ofLog], ofUtils, ofAppRunner, 


    - [ofThread] [攻略済み]

        [ofConstants], ofTypes, Poco/Thread, Poco/Runnable, [ofLog], ofUtils, 


    - ofURLFileLoader

        [ofThread], [ofEvents], ofFileUtils, ofURLFileLoader, ofAppRunner, ofUtils, Poco/Net/...


    - ofUtils

        [ofConstants], [ofLog], Poco/Path, ofUtils, ofImage, ofTypes, ofGraphics, ofAppRunner, Poco/String, Poco/LocalDateTime, Poco/DateTimeFormatter, Poco/URI


    - ofXml

        ofMain, Poco/DOM/...


+ video

    - ofDirectShowGrabber

        [ofConstants], (ofTexture), (ofBaseTypes), (ofPixels), videoInput, ofUtils,


    - ofGstUtils

        [ofConstants], (ofBaseTypes), (ofPixels), ofTypes, [ofEvents], [ofThread], ofUtils, gst, glib, glib-object


    - ofGstVieoGrabber

        ofGstUtils, ofTypes, ofGstVideoGrabber, gst


    - ofGstVideoPlayer

        ofGstUtils, gst


    - ofQTKitGrabber

        ofMain, QTKit/QTKit, QuickTime/QuickTime, Accelerate/Accelerate


    - ofQTKitMovieRenderer

        Cocoa/Cocoa, Quartz/Quartz, QTKit/QTKit, Accelerate/Accelerate


    - ofQTKitPlayer

        ofMain, ofQTKitMovieRenderer, Poco/String


    - ofQtUtils

        [ofConstants], ofUtils, ofGraphics, QuickTime/QuickTime, CoreServices/CoreServices, ApplicationServices/ApplicationServices, QTML, FixMath, QuickTImeComponents, TextUtils, MediaHandler


    - ofQuickTimeGrabber

        ofConstant, ofQtUtils, (ofTexture), ofBaseType, (ofPixels), ofUtils


    - ofQuickTimePlayer

        ofConstant, (ofBaseTypes), (ofPixels), ofQtUtils, ofUtils, 


    - ofVideoGrabber

        ofConstant, (ofTexture), (ofBaseTypes), (ofPixels), ofTypes, ofxiOSVideoGrabber, ofQuickTimeGrabber, ofQTKitGrabber, ofDirectShowGrabber, ofGstVideoGrabber, ofxAndroidVideoGrabber


    - ofVideoPlayer

        [ofConstants], (ofTexture), (ofBaseTypes), ofTypes, ofGstVideoPlayer, ofQuickTimePlayer, ofQTKitPlayer, ofxiOSVideoPlayer, ofxAndroidVideoPlayer, ofUtils, ofGraphics