module graphite.types.basetypes;


enum VertexSetting
{
    none,
    useTex,
    useColor,
}


struct Vertex(VertexSetting info)
{
    Vec3f pos;
    Vec3f norm;

  static if(info == VertexInfo.useTex)
  {
    Vec2f tex;
  }
  else static if(info == VertexInfo.useColor)
  {
    Color4f color;
  }
}


alias VertexArray(VertexSetting info) = Vertex!info[];


enum isColor(T) = is(typeof((/*scope*/ ref T t){
    auto rgba = t.rgba!float();
    static assert(isVector!(typeof(rgba)));
    static assert(hasStaticLength!(typeof(rgba)));
    static assert(staticLenght!(typeof(rgba)) == 4);
    static assert(isFloatingPoint!(typeof(rgba[0])));
}));


enum isDrawable(T, R) = is(typeof((/*scope*/ ref T t, /*scope*/ ref R r){
    auto mM = t.modelMatrix;

    static assert(isModelMatrix!(typeof(m)));

    mM.draw(r);
}));


enum isParticularRenderer(T) = is(typeof((/*scope*/ ref T t){
    t.put(Vertex!(VertexInfo.none).init);     // put Vertex
    //t.renderer(exampleOfVBO);   // put VBO
    //t.renderer(exampleOfVertexArrray);  // put vertex array
}));


enum isGenericRenderer(T) = is(typeof((/*scope*/ ref T t){
    auto obj = exampleOfDrawable;
    {
        auto p = t.particular!(GeometryType.init);
        static assert(isParticularRenderer!(typeof(p)));
    }
}));


enum isAnimationRenderer(T) = isGenericRenderer!T && is(typeof((/*scope*/ ref T t){
    auto fr = t.startNewFrame();
    static assert(isGenericRenderer!(typeof(fr)));
}));


enum isRenderer(T) = isAnimationRenderer!T && is(typeof((/*scope*/ ref T t){
    auto vs = t.viewMatrix;
    auto ps = t.projectionMatrix;

    static assert(isMatrixStack!(typeof(v)));
    static assert(isMatrixStack!(is(typeof(p))));

    static assert(isViewMatrix!(typeof(v.front)));
    static assert(isProjectionMatrix!(typeof(p.front)));
}));


