module graphite.app.baseapp;

import std.variant;

import graphite.types.point,
       graphite.events,
       graphite.types.basetypes;


abstract class BaseApp/* : ISoundInput, ISoundOutput*/
{
    this()
    {
        mouseX = mouseY = 0;
    }

    void setup(){}
    void update(){}
    void draw(){}
    void exit(){}

    void windowResized(int w, int h){}

    void keyPressed( int key ){}
    void keyReleased( int key ){}

    void mouseMoved( int x, int y ){}
    void mouseDragged( int x, int y, int button ){}
    void mousePressed( int x, int y, int button ){}
    void mouseReleased(int x, int y, int button ){}
    
    void dragEvent(DragInfo dragInfo) { }
    void gotMessage(string msg){ }

    void windowEntry ( int state ) { }
    
    int mouseX, mouseY;         // for processing heads

    void setup(ref Variant args){
        setup();
    }
    void update(ref Variant args){
        update();
    }
    void draw(ref Variant args){
        draw();
    }
    void exit(ref Variant args){
        exit();
    }

    void windowResized(ref ResizeEventInfo resize){
        windowResized(resize.width,resize.height);
    }

    void keyPressed( ref KeyEventInfo key ){
        keyPressed(key.key);
    }
    void keyReleased( ref KeyEventInfo key ){
        keyReleased(key.key);
    }

    void mouseMoved( ref MouseEventInfo mouse ){
        mouseX = Mouse.x;
        mouseY = Mouse.y;
        mouseMoved(mouseX, mouseY);
    }
    void mouseDragged( ref MouseEventInfo mouse ){
        mouseX = Mouse.x;
        mouseY = Mouse.y;
        mouseDragged(mouseX, mouseY, mouse.button);
    }
    void mousePressed( ref MouseEventInfo mouse ){
        mouseX = Mouse.x;
        mouseY = Mouse.y;
        mousePressed(mouseX, mouseY, mouse.button);
    }
    void mouseReleased(ref MouseEventInfo mouse){
        mouseX = Mouse.x;
        mouseY = Mouse.y;
        mousePressed(mouseX, mouseY, mouse.button);
    }
    void windowEntry(ref EntryEventInfo entry){
        windowEntry(entry.state);
    }
    void dragged(ref DragInfo drag){
        dragEvent(drag);
    }
    void messageReceived(ref string message){
        gotMessage(message);
    }
}