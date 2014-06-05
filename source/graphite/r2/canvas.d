module graphite.r2.canvas;

version(none):
struct PNGCanvas
{
    ~this()
    {
        cairo_surface_destroy(_surface);
    }


    RefCounted!CairoRenderer writer() @property
    {
        return RefCounted!CairoRenderer(_surface);
    }


  static
  {
    RefCounted!Canvas fromFile(string filename);
    RefCounted!Canvas fromBinary(void[] data);
  }

  private:
    cairo_surface_t* _surface;
    uint _w;
    uint _h;
}


struct DataCanvas(CanvasDataType type)
{
    ~this()
    {
        cairo_surface_destroy(_surface);
    }


    RefCounted!CairoRenderer writer() @property
    {
        return RefCounted!CairoRenderer(_surface);
    }


  static
  {
    RefCounted!DataCanvas create(size_t width, size_t height);
    RefCounted!DataCanvas create(size_t width, size_t height, void[] data)
    in{
        //assert(width * height * )
    }
    body{

    }
  }


    inout(void)[] data() pure nothrow @safe inout @property
    {
        return _data;
    }


  private:
    void[] _data;
}


struct CairoRenderer
{
    ~this()
    {
        cairo_destroy(_ctx);
    }

  private:
    cairo_t* _ctx;
}