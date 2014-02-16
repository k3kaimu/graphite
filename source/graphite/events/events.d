module graphite.events.events;

import graphite.events.eventutils;
import graphite.types.point;

import std.array,
       std.format;

version(none):


struct Mouse
{
    enum Type { pressed, moved, released, dragged, }

  static:
    bool pressed(int button = -1);
    int x() @property;
    int y() @property;
    int previousX() @property;
    int previousY() @property;
}


struct KeyBoard
{
  static:
    bool pressed(int key = -1);
}


struct AppRuntime
{
  static:
    void exit();
    void setEscapeQuitsApp(bool bQuitOnEscape);
}


struct DragInfo
{
    string[] files;
    Point position;
}


struct EntryEventInfo
{
    int state;
}


struct KeyEventInfo
{
    enum Type{ pressed, released }
    Type type;
    int key;
}


struct MouseEventInfo
{
    enum Type{ pressed, moved, released, dragged }
    Type type;
    int button;
}


struct TouchEventInfo
{
    enum Type{down, up, move, doubleTap, cancel}
    Type type;

    int id;
    int time;
    int numTouches;
    float width, height;
    float angle;
    float minoraxis, majoraxis;
    float pressure;
    float xspeed, yspeed;
    float xaccel, yaccel;
}


struct AudioEventInfo
{
    float[] buffer;
    int nChannels;
}


struct ResizeEventInfo
{
    int width;
    int height;
}


class CoreEvents
{
    Event!(Variant) setup, update, draw, exit;

    Event!(EntryEventInfo) windowEntered;
    Event!(ResizeEventInfo) windowResized;

    Event!(KeyEventInfo) keyPressed, keyReleased;

    Event!(MouseEventInfo) mouseMoved, mouseDragged, mousePressed, mouseReleased;

    Event!(AudioEventInfo) audioReceived, audioRequested;

    Event!(TouchEventInfo) touchDown, touchUp, touchMoved, touchDoubleTap, touchCancelled;

    Event!(string) messageEvent;
    Event!(DragInfo) fileDragEvent;


    void disable()
    {
        setup.disable();
        update.disable();
        draw.disable();
        exit.disable();
        //windowEntered.disable();
        //windowResized.disable();
        keyPressed.disable();
        keyReleased.disable();
        mouseMoved.disable();
        mouseDragged.disable();
        mousePressed.disable();
        mouseReleased.disable();
        audioReceived.disable();
        audioRequested.disable();
        touchDown.disable();
        touchUp.disable();
        touchMoved.disable();
        touchDoubleTap.disable();
        touchCancelled.disable();
        messageEvent.disable();
        fileDragEvent.disable();
    }


    void enable()
    {
        setup.enable();
        update.enable();
        draw.enable();
        exit.enable();
        //windowEntered.enable();
        //windowResized.enable();
        keyPressed.enable();
        keyReleased.enable();
        mouseMoved.enable();
        mouseDragged.enable();
        mousePressed.enable();
        mouseReleased.enable();
        audioReceived.enable();
        audioRequested.enable();
        touchDown.enable();
        touchUp.enable();
        touchMoved.enable();
        touchDoubleTap.enable();
        touchCancelled.enable();
        messageEvent.enable();
        fileDragEvent.enable();
    }


    mixin(genMethods("MouseEvents", ["mouseMoved", "mouseDragged", "mousePressed", "mouseReleased"]));
    mixin(genMethods("KeyEvents", ["keyPressed", "keyReleased"]));
    mixin(genMethods("TouchEvents", ["touchDoubleTap", "touchDown", "touchMoved", "touchUp", "touchCancelled"]));
    //mixin(genMethods("GetMessage", ["messageEvent"]));
    //mixin(genMethods("DragEvents", ["fileDragEvent"]));


  private:
    string genMethods(string name, string[] slots)
    {
        return format(q{
            void connect%1$s(string method, ClassType)(ClassType obj)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".connect!method(obj);");
            }


            void connect%1$s(ClassType, Args...)(ClassType obj, void delegate(ClassType obj, Args) dg)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".connect(obj, dg);");
            }


            void strongConnect%1$s(Args...)(void delegate(ClassType obj, Args) dg)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".strongConnect(dg);");
            }


            void disconnect%1$s(string method, ClassType)(ClassType obj)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".disconnect!method(obj);");
            }


            void disconnect%1$s(ClassType, Args...)(ClassType obj, void delegate(ClassType obj, Args) dg)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".disconnect!method(obj, dg);");
            }


            void disconnect%1$s(ClassType)(ClassType obj)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".disconnect(obj);");
            }


            void strongDisconnect%1$s(Args...)(void delegate(Args) dg)
            {
                foreach(e; TypeTuple!(%2$(%s,%)))
                    mixin("this." ~ e ~ ".strongDisconnect(dg);");
            }
        }, name, slots);
    }
}


CoreEvents globalEvents() @property
{
    static CoreEvents events = new CoreEvents;
    return events;
}
