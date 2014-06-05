module graphite.graphics.pixels;

import graphite.types;
import graphite.utils.constants;

//---------------------------------------
enum InterpolationMethod {
    nearestNeighbor  = 1,
    biLinear         = 2,
    biCubic          = 3
}


struct Pixels(PixelType = ubyte)
{
    this(typeof(null));
    ~this();
    this(this);
    void opAssign(const ref typeof(this));
    //ofPixels_(const ofPixels_<PixelType> & mom);
    //ofPixels_<PixelType>& operator=(const ofPixels_<PixelType> & mom);

    //template<typename SrcType>
    //ofPixels_(const ofPixels_<SrcType> & mom);
    this(SrcType)(const ref Pixels!SrcType mom);

    //template<typename SrcType>
    //ofPixels_<PixelType>& operator=(const ofPixels_<SrcType> & mom);
    void opAssign(SrcType)(const ref Pixels!SrcType mom);

    void allocate(int w, int h, int channels);
    void allocate(int w, int h, PixelFormat type);
    void allocate(int w, int h, ImageType type);

    void set(PixelType val);
    void set(int channel,PixelType val);
    void setFromPixels(const PixelType* newPixels, int w, int h, int channels);
    void setFromPixels(const PixelType* newPixels, int w, int h, ImageType type);
    void setFromExternalPixels(PixelType* newPixels, int w, int h, int channels);
    void setFromAlignedPixels(const PixelType* newPixels, int width, int height, int channels, int stride);
    void swap(ref typeof(this) pix);

    //From ofPixelsUtils
    // crop to a new width and height, this reallocates memory.
    void crop(int x, int y, int width, int height);
    // not in place
    
    void cropTo(ref typeof(this) toPix, int x, int y, int _width, int _height);

    // crop to a new width and height, this reallocates memory.
    void rotate90(int nClockwiseRotations);
    void rotate90To(ref typeof(this) dst, int nClockwiseRotations);
    void mirrorTo(ref typeof(this) dst, bool vertically, bool horizontal);
    void mirror(bool vertically, bool horizontal);
    bool resize(int dstWidth, int dstHeight, InterpolationMethod interpMethod = InterpolationMethod.nearestNeighbor);
    bool resizeTo(ref typeof(this) dst, InterpolationMethod interpMethod = InterpolationMethod.nearestNeighbor);
    bool pasteInto(ref typeof(this) dst, int x, int y);

    void swapRgb();

    void clear();

    inout(PixelType)* getPixels() inout;
    //const PixelType* getPixels() const;

    int getPixelIndex(int x, int y) const;
    Color!PixelType getColor(int x, int y) const;
    void setColor(int x, int y, const ref Color!PixelType color);
    void setColor(int index, const ref Color!PixelType color);
    void setColor(const ref Color!PixelType color);

    ref inout(PixelType) opIndex(size_t pos) inout;

    bool isAllocated() const;

    int getWidth() const;
    int getHeight() const;

    int getBytesPerPixel() const;
    int getBitsPerPixel() const;
    int getBytesPerChannel() const;
    int getBitsPerChannel() const;
    int getNumChannels() const;

    Pixels!PixelType getChannel(int channel) const;
    void setChannel(int channel, const Pixels!PixelType channelPixels);

    ImageType getImageType() const;
    void setImageType(ImageType imageType);
    void setNumChannels(int numChannels);

    int size() const;

private:
    float bicubicInterpolate(const float* patch, float x,float y, float x2,float y2, float x3,float y3);

    void copyFrom( const ref Pixels!PixelType mom );

    void copyFrom(SrcType)( const ref Pixels!SrcType mom );
    
    PixelType* pixels;
    int     width;
    int     height;

    int     channels; // 1, 3, 4 channels per pixel (grayscale, rgb, rgba)
    bool    bAllocated;
    bool    pixelsOwner;            // if set from external data don't delete it
}

alias FloatPixels = Pixels!(float);
alias ShortPixels = Pixels!(ushort);


//typedef ofPixels_<unsigned char> ofPixels;
//typedef ofPixels_<float> ofFloatPixels;
//typedef ofPixels_<unsigned short> ofShortPixels;


//typedef ofPixels& ofPixelsRef;
//typedef ofFloatPixels& ofFloatPixelsRef;
//typedef ofShortPixels& ofShortPixelsRef;

// sorry for these ones, being templated functions inside a template i needed to do it in the .h
// they allow to do things like:
//
// ofPixels pix;
// ofFloatPixels pixf;
// pix = pixf;

//template<typename PixelType>
//template<typename SrcType>
//ofPixels_<PixelType>::ofPixels_(const ofPixels_<SrcType> & mom){
//    bAllocated = false;
//    pixelsOwner = false;
//    channels = 0;
//    pixels = NULL;
//    width = 0;
//    height = 0;
//    copyFrom( mom );
//}

//template<typename PixelType>
//template<typename SrcType>
//ofPixels_<PixelType>& ofPixels_<PixelType>::operator=(const ofPixels_<SrcType> & mom){
//    copyFrom( mom );
//    return *this;
//}

//template<typename PixelType>
//template<typename SrcType>
//void ofPixels_<PixelType>::copyFrom(const ofPixels_<SrcType> & mom){
//    if(mom.isAllocated()){
//        allocate(mom.getWidth(),mom.getHeight(),mom.getNumChannels());

//        const float srcMax = ( (sizeof(SrcType) == sizeof(float) ) ? 1.f : numeric_limits<SrcType>::max() );
//        const float dstMax = ( (sizeof(PixelType) == sizeof(float) ) ? 1.f : numeric_limits<PixelType>::max() );
//        const float factor = dstMax / srcMax;

//        if(sizeof(SrcType) == sizeof(float)) {
//            // coming from float we need a special case to clamp the values
//            for(int i = 0; i < mom.size(); i++){
//                pixels[i] = CLAMP(mom[i], 0, 1) * factor;
//            }
//        } else{
//            // everything else is a straight scaling
//            for(int i = 0; i < mom.size(); i++){
//                pixels[i] = mom[i] * factor;
//            }
//        }
//    }
//}

//namespace std{
//template<typename PixelType>
//void swap(ofPixels_<PixelType> & src, ofPixels_<PixelType> & dst){
//    src.swap(dst);
//}
//}
