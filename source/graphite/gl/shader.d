module graphite.gl.shader;

alias VertexShader = typeof(vertexShader());
alias FragmentShader = typeof(fragmentShader());
alias GeometryShader = typeof(geometryShader());
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
    gll!glShaderSource(shader, 1, &cstr, null);
    gll!glCompileShader(shader);

    GLint result = GL_FALSE;
    gll!glGetShaderiv(shader, GL_COMPILE_STATUS, &result);

    string pullLog()
    {
        int len = void;
        gll!glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);

        if(len > 0){
            char[] msg = new char[len];
            gll!glGetShaderInfoLog(shader, len, null, msg.ptr);
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
                gll!glDeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader;
        }


      private:
        GLuint _shader;
    }


    return RefCounted!VertexShaderImpl(enforce(gll!glCreateShader(GL_VERTEX_SHADER), "failed creating vertex shader"));
}


auto vertexShader(string src)
{
    auto vert = vertexShader();
    vert._shader.compileShader!(ShaderType.vertex)(src);

    return vert;
}


auto vertexShader(File file)
{
    return vertexShader(file.name.readText());
}


auto fragmentShader() @property
{
    static struct FragmentShaderImpl
    {
        ~this()
        {
            if(_shader)
                gll!glDeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader;
        }


      private:
        GLuint _shader;
    }


    return RefCounted!FragmentShaderImpl(enforce(gll!glCreateShader(GL_FRAGMENT_SHADER), "failed creating fragment shader"));
}


auto fragmentShader(string src)
{
    auto frag = fragmentShader();
    frag._shader.compileShader!(ShaderType.fragment)(src);

    return frag;
}


auto fragmentShader(File file)
{
    return return fragmentShader(file.name.readText());
}


auto geometryShader(GLenum intputType, GLenum outputType) @property
in{
    assert(![GL_POINTS, GL_LINES, GL_LINES_ADJACENCY, GL_TRAIANGLES, GL_TRAIANGLES_ADJACENCY]
           .find(inputType).empty);
    assert(![GL_POINTS, GL_LINE_STRIP, GL_TRIANGLE_STRIP]
           .find(inputType).empty);
}
body{
    static struct GeometryShader
    {
        ~this()
        {
            if(_shader)
                gll!glDeleteShader(_shader);
        }


        bool isLoaded() const @property
        {
            return _shader != 0;
        }


        GLuint glShader() const @property
        {
            return _shader
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
            glGetIntegerv(GL_MAX_GEOMETRY_OUTPUT_VERTICES, &vertN);
            return vertN;
        }


        static
        GLint maxOutputCompN() @property
        {
            GLint comp;
            glGetIntegerv(GL_MAX_GEOMETRY_TOTAL_COMPONENTS, &comp);
            return comp;
        }

      private:
        GLuint _shader;
        GLenum _inputT, _outputT;
    }


    auto g = RefCounted!GeometryShader(enforce(gll!glCreateShader(GL_GEOMETRY_SHADER), "failed creating fragment shader"), inputType, outputType, outVertN);
}


auto geometryShader(string src, GLenum inputType, GLenum outputType)
{
    auto geom = geometryShader(inputType, outputType);
    geom.compileShader!(ShaderType.geometry)(src);
}


auto geometryShader(File file, GLenum inputType, GLenum outputType)
{
    return geometryShader(file.name.readText(), inputType, outputType);
}



auto shader() @property
{
    static struct ShaderImpl
    {
        ~this()
        {
            if(_program)
                gll!glDeleteProgram(_program);
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
                gll!glTransformFeedbackVeryings(_program, 1, &cstr, GL_SEPARETE_ATTRIBS);
            }

            enforce(_vert.isLoaded);
            enforce(_frag.isLoaded);

            gll!glAttachShader(program, _vert);
            gll!glAttachShader(program, _frag);

            if(_geom.isLoaded)
                gll!glAttachShader(program, _geom);

            gll!glLinkProgram(program);


            string programInfoLog()
            {
                GLsizei bufSize;
                glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufSize);

                if(bufSize > 1){
                    char[] infoLog = new char[bufSize];
                    GLsizei len;
                    glGetProgramInfoLog(program, bufSize, &len, infoLog.ptr);
                    return infoLog.assumeUnique();
                }else
                    return "";
            }


            GLint status;
            glGetProgramiv(program, GL_LINK_STATUS, &status);
            enforce(status == GL_TRUE, programInfoLog());

            debug(Shader) logger!Shader.writeln!"verbose"(programInfoLog);
            _isLinked = true;
        }


        bool isLoaded() const @property
        {
            return _isLinked();
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
            gll!glUseProgram(program);
            if(auto renderer = programmableRenderer)
                renderer.begin(this);
        }


        void end(){
            if(_isLinked){
                if(auto renderer = programmableRenderer)

            }
        }
        

      private:
        GLuint _program;
        bool _isLinked;
        VertexShader _vert;
        FragmentShader _frag;
        GeometryShader _geom;
    }


    return RefCounted!ShaderImpl(enforce(gll!glCreateProgram()));
}


auto shader(VertexShader vert, FragmentShader frag, GeometryShader geom, string[] varyings)
