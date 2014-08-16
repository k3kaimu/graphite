module graphite.utils;


import std.datetime,
       std.file,
       std.path,
       std.string;


public import /*graphite.utils.constants,*/
              graphite.utils.log,
              graphite.utils.json
              //graphite.utils.noise,
              //graphite.utils.thread,
              //graphite.utils.matrixstack,
              //graphite.graphics.image
              ;

shared 



struct Chrono
{
  static:
    SysTime startTime;


    void resetElapsedTimeCounter() @property
    {
        startTime = Clock.currTime;
    }


    Duration elapsedTime() @property
    {
        return Clock.currTime - startTime;
    }


    auto elapsedTimeAsTotal(string units)() @property
    {
        return elapsedTime.total!units();
    }
}


/*
immutable shared string defaultDataPath;

shared static this()
{
  static if(TargetPlatform.isOSX)
    defaultDataPath = "../../../data";
  else static if(TargetPlatform.isAndroid)
    defaultDataPath = "sdcard/";
  else static if(TargetPlatform.isLinux || TargetPlatform.isWindows)
    defaultDataPath = buildPath([thisExePath(), "data/"]);
  else
    defaultDataPath = "data/";
}


alias defaultWorkingDir = std.file.getcwd;
*/





//void    ofResetElapsedTimeCounter();        // this happens on the first frame
//float   ofGetElapsedTimef();
//unsigned long long ofGetElapsedTimeMillis();
//unsigned long long ofGetElapsedTimeMicros();
//int     ofGetFrameNum();

//int     ofGetSeconds();
//int     ofGetMinutes();
//int     ofGetHours();

////number of seconds since 1970
//uint ofGetUnixTime();

//unsigned long long ofGetSystemTime( );          // system time in milliseconds;
//unsigned long long ofGetSystemTimeMicros( );            // system time in microseconds;

//        //returns 
//string ofGetTimestampString();
//string ofGetTimestampString(string timestampFormat);


//int     ofGetYear();
//int     ofGetMonth();
//int     ofGetDay();
//int     ofGetWeekday();

//void    ofLaunchBrowser(string url, bool uriEncodeQuery=false);

//void    ofEnableDataPath();
//void    ofDisableDataPath();
//string  ofToDataPath(string path, bool absolute=false);

//template<class T>
//void ofRandomize(vector<T>& values) {
//    random_shuffle(values.begin(), values.end());
//}

//template<class T, class BoolFunction>
//void ofRemove(vector<T>& values, BoolFunction shouldErase) {
//    values.erase(remove_if(values.begin(), values.end(), shouldErase), values.end());
//}

//template<class T>
//void ofSort(vector<T>& values) {
//    sort(values.begin(), values.end());
//}
//template<class T, class BoolFunction>
//void ofSort(vector<T>& values, BoolFunction compare) {
//    sort(values.begin(), values.end(), compare);
//}

//template <class T>
//uint ofFind(const vector<T>& values, const T& target) {
//    return distance(values.begin(), find(values.begin(), values.end(), target));
//}

//template <class T>
//bool ofContains(const vector<T>& values, const T& target) {
//    return ofFind(values, target) != values.size();
//}

//void ofSetWorkingDirectoryToDefault();

////set the root path that ofToDataPath will use to search for files relative to the app
////the path must have a trailing slash (/) !!!!
//void ofSetDataPathRoot( string root );

//template <class T>
//string ofToString(const T& value){
//    ostringstream out;
//    out << value;
//    return out.str();
//}

///// like sprintf "%4f" format, in this example precision=4
//template <class T>
//string ofToString(const T& value, int precision){
//    ostringstream out;
//    out << fixed << setprecision(precision) << value;
//    return out.str();
//}

///// like sprintf "% 4d" or "% 4f" format, in this example width=4, fill=' '
//template <class T>
//string ofToString(const T& value, int width, char fill ){
//    ostringstream out;
//    out << fixed << setfill(fill) << setw(width) << value;
//    return out.str();
//}

///// like sprintf "%04.2d" or "%04.2f" format, in this example precision=2, width=4, fill='0'
//template <class T>
//string ofToString(const T& value, int precision, int width, char fill ){
//    ostringstream out;
//    out << fixed << setfill(fill) << setw(width) << setprecision(precision) << value;
//    return out.str();
//}

//template<class T>
//string ofToString(const vector<T>& values) {
//    stringstream out;
//    int n = values.size();
//    out << "{";
//    if(n > 0) {
//        for(int i = 0; i < n - 1; i++) {
//            out << values[i] << ", ";
//        }
//        out << values[n - 1];
//    }
//    out << "}";
//    return out.str();
//}

//template<class T>
//T ofFromString(const string & value){
//    T data;
//    stringstream ss;
//    ss << value;
//    ss >> data;
//    return data;
//}

//template<>
//string ofFromString(const string & value);

//template<>
//const char * ofFromString(const string & value);

//template <class T>
//string ofToHex(const T& value) {
//    ostringstream out;
//    // pretend that the value is a bunch of bytes
//    unsigned char* valuePtr = (unsigned char*) &value;
//    // the number of bytes is determined by the datatype
//    int numBytes = sizeof(T);
//    // the bytes are stored backwards (least significant first)
//    for(int i = numBytes - 1; i >= 0; i--) {
//        // print each byte out as a 2-character wide hex value
//        out << setfill('0') << setw(2) << hex << (int) valuePtr[i];
//    }
//    return out.str();
//}
//template <>
//string ofToHex(const string& value);
//string ofToHex(const char* value);

//int ofHexToInt(const string& intHexString);
//char ofHexToChar(const string& charHexString);
//float ofHexToFloat(const string& floatHexString);
//string ofHexToString(const string& stringHexString);

//int ofToInt(const string& intString);
//char ofToChar(const string& charString);
//float ofToFloat(const string& floatString);
//double ofToDouble(const string& doubleString);
//bool ofToBool(const string& boolString);

//template <class T>
//string ofToBinary(const T& value) {
//    ostringstream out;
//    const char* data = (const char*) &value;
//    // the number of bytes is determined by the datatype
//    int numBytes = sizeof(T);
//    // the bytes are stored backwards (least significant first)
//    for(int i = numBytes - 1; i >= 0; i--) {
//        bitset<8> cur(data[i]);
//        out << cur;
//    }
//    return out.str();
//}
//template <>
//string ofToBinary(const string& value);
//string ofToBinary(const char* value);

//int ofBinaryToInt(const string& value);
//char ofBinaryToChar(const string& value);
//float ofBinaryToFloat(const string& value);
//string ofBinaryToString(const string& value);


//string  graphiteVersionInfo() @property;
//{
//    return format("%s.%s.%s", GRAPHITE_VERSION_MAJOR,
//                              GRAPHITE_VERSION_MINOR,
//                              GRAPHITE_VERSION_PATCH);
//}


//alias graphiteVersionMajor = GRAPHITE_VERSION_MAJOR;
//alias graphiteVersionMinor = GRAPHITE_VERSION_MINOR;
//alias graphiteVersionPatch = GRAPHITE_VERSION_PATCH;

//void saveScreen(string filename);
//{
//    Image!() screen;
//    screen.allocate(getWidth(), getHeight(), IMAGE_COLOR);
//    screen.grabScreen(0, 0, getWidth(), getHeight());
//    screen.saveImage(filename);
//}

//void saveViewport(string filename);
//{
//    Image!() screen;
//    auto view = currentViewport();
//    screen.allocate(view.width, view.height, IMAGE_COLOR);
//    screen.grabScreen(0, 0, view.width, view.height);
//    screen.saveImage(filename);
//}


//private size_t _saveImageCounter;
//void saveFrame(bool bUseViewport = false);
//{
//    auto filename = _saveImageCounter.to!string ~ ".png";

//    if(bUseViewport)
//        saveViewport(filename);
//    else
//        saveScreen(filename);

//    ++_saveImageCounter;
//}

//--------------------------------------------------
//vector <string> ofSplitString(const string & source, const string & delimiter, bool ignoreEmpty = false, bool trim = false);
//string ofJoinString(vector <string> stringElements, const string & delimiter);
//void ofStringReplace(string& input, string searchStr, string replaceStr);
//bool ofIsStringInString(string haystack, string needle);
//int ofStringTimesInString(string haystack, string needle);

//string ofToLower(const string & src);
//string ofToUpper(const string & src);

//string ofVAArgsToString(const char * format, ...);
//string ofVAArgsToString(const char * format, va_list args);

//string ofSystem(string command);
