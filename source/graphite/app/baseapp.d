module graphite.app.baseapp;

import graphite.types.point,
       graphite.events,
       graphite.types.basetypes;

abstract class BaseApp : ISoundInput, ISoundOutput
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
    
    void dragEvent(ofDragInfo dragInfo) { }
    void gotMessage(ofMessage msg){ }

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

    void windowResized(ref ResizeInfo resize){
        windowResized(resize.width,resize.height);
    }

    void keyPressed( ref KeyInfo key ){
        keyPressed(key.key);
    }
    void keyReleased( ref KeyInfo key ){
        keyReleased(key.key);
    }

    void mouseMoved( ref MouseInfo mouse ){
        mouseX=mouse.x;
        mouseY=mouse.y;
        mouseMoved(mouse.x,mouse.y);
    }
    void mouseDragged( ref MouseEventInfo mouse ){
        mouseX=mouse.x;
        mouseY=mouse.y;
        mouseDragged(mouse.x,mouse.y,mouse.button);
    }
    void mousePressed( ref MouseEventInfo mouse ){
        mouseX=mouse.x;
        mouseY=mouse.y;
        mousePressed(mouse.x,mouse.y,mouse.button);
    }
    void mouseReleased(ref MouseEventInfo mouse){
        mouseX=mouse.x;
        mouseY=mouse.y;
        mouseReleased(mouse.x,mouse.y,mouse.button);
    }
    void windowEntry(ref EntryEventInfo entry){
        windowEntry(entry.state);
    }
    void dragged(ref DragInfo drag){
        dragEvent(drag);
    }
    void messageReceived(ref MessageInfo message){
        gotMessage(message);
    }
}