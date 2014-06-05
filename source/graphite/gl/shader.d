module graphite.gl.shader;

import graphite.deimos.gl.glcorearb;
import graphite.gl.glapi;

import std.typecons;
import std.exception;
import std.stdio;
import std.string;
import std.file;
import std.algorithm;
import std.array;


alias VertexShader = typeof(vertexShader());
alias FragmentShader = typeof(fragmentShader());
alias GeometryShader = typeof(geometryShader(0, 0));
alias Shader = typeof(shader());


enum DefaultShaderAttribute
{
    color,
    position,
    normal,
    texcoord,
}


enum ShaderType : GLenum
{
    vertex = GL_VERTEX_SHADER,
    fragment = GL_FRAGMENT_SHADER,
    geometry = GL_GEOMETRY_SHADER,
}


void compileShader(ShaderType type)(GLuint shader, string src)
{
    const(char)* cstr = src.toStringz();

    gl.ShaderSource(shader, 1, &cstr, null);
    gl.CompileShader(shader);

    GLint result = GL_FALSE;
    gl.GetShaderiv(shader, GL_COMPILE_STATUS, &result);

    string pullLog()
    {
        int len = void;
        gl.GetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);

        if(len > 0){
            char[] msg = new char[len];
            gl.GetShaderInfoLog(shader, len, null, msg.ptr);
            return msg.assumeUnique();
        }else
            return "";
    }

    enforce(result == GL_TRUE, pullLog());

    string log = pullLog();
    debug(Shader) logger!Shader.writefln!"verbose"("%s shader compiled", type);
}


auto vertexShader() @property
{
    static struct VertexShaderImpl
    {
        ~this()
        {
            if(_shader)
               gl.DeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader;
        }


        static
        auto fromSrc(string src)
        {
            auto frag = newShader();
            frag._shader.compileShader!(ShaderType.vertex)(src);

            return frag;
        }


        static
        auto fromFile(File file)
        {
            return fromSrc(file.name.readText());
        }


        static
        auto newShader()
        {
            return RefCounted!VertexShaderImpl(enforce(gl.CreateShader(GL_VERTEX_SHADER), "failed creating fragment shader"));
        }


      private:
        GLuint _shader;
    }


    return VertexShaderImpl.newShader();
}


auto vertexShaderFromSrc(string src)
{
    auto vert = vertexShader();
    vert._shader.compileShader!(ShaderType.vertex)(src);

    return vert;
}


auto fragmentShader() @property
{
    static struct FragmentShaderImpl
    {
        ~this()
        {
            if(_shader)
                gl.DeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader;
        }


        static
        auto fromSrc(string src)
        {
            auto frag = newShader();
            frag._shader.compileShader!(ShaderType.fragment)(src);
            
            return frag;
        }


        static
        auto fromFile(File file)
        {
            return fromSrc(file.name.readText());
        }


        static
        auto newShader()
        {
            return RefCounted!FragmentShaderImpl(enforce(gl.CreateShader(GL_FRAGMENT_SHADER), "failed creating fragment shader"));
        }


      private:
        GLuint _shader;
    }


    return FragmentShaderImpl.newShader();
}


auto geometryShader(GLenum inputType, GLenum outputType) @property
in{
    assert(![GL_POINTS, GL_LINES, GL_LINES_ADJACENCY, GL_TRIANGLES, GL_TRIANGLES_ADJACENCY]
           .find(inputType).empty);
    assert(![GL_POINTS, GL_LINE_STRIP, GL_TRIANGLE_STRIP]
           .find(outputType).empty);
}
body{
    static struct GeometryShaderImpl
    {
        ~this()
        {
            if(_shader)
                gl.DeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader;
        }


        GLenum inputType() const @property
        {
            return _inputT;
        }


        GLenum outputType() const @property
        {
            return _outputT;
        }


        GLint outputVertN() const @property
        {
            // see http://www.wakayama-u.ac.jp/~tokoi/lecture/gg/ggnote14.pdf
            auto vertN = maxOutputVertN(),
                 compN = maxOutputCompN();

            compN /= 12;
            if(vertN > compN) vertN = compN;
            return vertN;
        }


        static
        GLint maxOutputVertN() @property
        {
            GLint vertN;
            gl.GetIntegerv(GL_MAX_GEOMETRY_OUTPUT_VERTICES, &vertN);
            return vertN;
        }


        static
        GLint maxOutputCompN() @property
        {
            GLint comp;
            gl.GetIntegerv(GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS, &comp);
            return comp;
        }


        static
        auto newShader(GLenum inputType, GLenum outputType)
        {
            return RefCounted!GeometryShaderImpl(enforce(gl.CreateShader(GL_GEOMETRY_SHADER), "failed creating fragment shader"), inputType, outputType);
        }


        static
        auto fromSrc(GLenum inputType, GLenum outputType, string src)
        {
            auto dst = newShader(inputType, outputType);
            dst.glShader.compileShader!(ShaderType.geometry)(src);
        }


        static
        auto fromFile(GLenum inputType, GLenum outputType, File file)
        {
            return fromSrc(inputType, outputType, file.name.readText());
        }


      private:
        GLuint _shader;
        GLenum _inputT, _outputT;
    }


    return GeometryShaderImpl.newShader(inputType, outputType);
}



auto shader() @property
{
    static struct ShaderImpl
    {
        ~this()
        {
            if(_program)
                gl.DeleteProgram(_program);
        }


        void attach(VertexShader vert)
        in{
            assert(_vert.isNull);
        }
        body{
            _vert = vert;
        }


        void attach(FragmentShader frag)
        in{
            assert(_frag.isNull);
        }
        body{
            _frag = frag;
        }


        void attach(GeometryShader geom)
        in{
            assert(_geom.isNull);
        }
        body{
            _geom = geom;
        }


        void link(string[] varyings)
        {
            foreach(i, e; varyings){
                const(char)* cstr = e.toStringz();
                gl.TransformFeedbackVaryings(_program, 1, &cstr, GL_SEPARATE_ATTRIBS);
            }

            enforce(_vert.isLoaded);
            enforce(_frag.isLoaded);

            gl.AttachShader(_program, _vert.glShader);
            gl.AttachShader(_program, _frag.glShader);

            if(_geom.isLoaded)
                gl.AttachShader(_program, _geom.glShader);

            gl.LinkProgram(_program);


            string programInfoLog()
            {
                GLsizei bufSize;
                gl.GetProgramiv(_program, GL_INFO_LOG_LENGTH, &bufSize);

                if(bufSize > 1){
                    char[] infoLog = new char[bufSize];
                    GLsizei len;
                    gl.GetProgramInfoLog(_program, bufSize, &len, infoLog.ptr);
                    return infoLog.assumeUnique();
                }else
                    return "";
            }


            GLint status;
            gl.GetProgramiv(_program, GL_LINK_STATUS, &status);
            enforce(status == GL_TRUE, programInfoLog());

            debug(Shader) logger!Shader.writeln!"verbose"(programInfoLog);
            _isLinked = true;
        }


        bool isLoaded() const @property
        {
            return _isLinked;
        }


        auto vertexShader() inout @property
        {
            return _vert;
        }


        auto fragmentShader() inout @property
        {
            return _frag;
        }


        auto geometryShader() inout @property
        {
            return _geom;
        }


        void begin(){
            enforce(_isLinked, "couldn't begin, shader not loaded");
            gl.UseProgram(_program);
            //if(auto renderer = programmableRenderer)
            //    renderer.begin(this);
        }


        void end(){
            //if(_isLinked){
            //    if(auto renderer = programmableRenderer)

            //}
        }
        

      private:
        GLuint _program;
        bool _isLinked;
        Nullable!VertexShader _vert;
        Nullable!FragmentShader _frag;
        Nullable!GeometryShader _geom;
    }


    return RefCounted!ShaderImpl(enforce(gl.CreateProgram()));
}


//auto shader(VertexShader vert, FragmentShader frag, GeometryShader geom, string[] varyings)
