module graphite.r3.mesh;

import graphite.math,
       graphite.utils,
       graphite.gl,
       graphite.types.color;


class Mesh
{
    //Mesh();
    this(PrimitiveMode mode, in Vec3f[] verts);
    //virtual ~Mesh();
  final
  {
    void setMode(PrimitiveMode mode);
    PrimitiveMode getMode() const;
    
    void clear();

    void setupIndicesAuto();
    
    Vec3f getVertex(IndexType i) const;
    void addVertex(in Vec3f v);
    void addVertices(in Vec3f[] verts);
    //void addVertices(const Vec3f* verts, int amt);
    void removeVertex(IndexType index);
    void setVertex(IndexType index, in Vec3f v);
    void clearVertices();
    
    Vec3f getNormal(IndexType i) const;
    void addNormal(in Vec3f n);
    void addNormals(in Vec3f[] norms);
    //void addNormals(const Vec3f* norms, int amt);
    void removeNormal(IndexType index);
    void setNormal(IndexType index, in Vec3f n);
    void clearNormals();
    
    FloatColor getColor(IndexType i) const;
    void addColor(in FloatColor c);
    void addColors(in FloatColor[] cols);
    //void addColors(const FloatColor* cols, int amt);
    void removeColor(IndexType index);
    void setColor(IndexType index, in FloatColor c);
    void clearColors();
    
    Vec2f getTexCoord(IndexType i) const;
    void addTexCoord(in Vec2f t);
    void addTexCoords(in Vec2f[] tCoords);
    //void addTexCoords(const Vec2f* tCoords, int amt);
    void removeTexCoord(IndexType index);
    void setTexCoord(IndexType index, in Vec2f t);
    void clearTexCoords();
    
    IndexType getIndex(IndexType i) const;
    void addIndex(IndexType i);
    void addIndices(in IndexType[] inds);
    //void addIndices(const IndexType* inds, int amt);
    void removeIndex(IndexType index);
    void setIndex(IndexType index, IndexType val);
    void clearIndices();
    
    void addTriangle(IndexType index1, IndexType index2, IndexType index3);
    
    int getNumVertices() const;
    int getNumColors() const;
    int getNumNormals() const;
    int getNumTexCoords() const;
    int getNumIndices() const;
    
    Vec3f* getVerticesPointer();
    FloatColor* getColorsPointer();
    Vec3f* getNormalsPointer();
    Vec2f* getTexCoordsPointer();
    IndexType* getIndexPointer();
    
    const Vec3f* getVerticesPointer() const;
    const FloatColor* getColorsPointer() const;
    const Vec3f* getNormalsPointer() const;
    const Vec2f* getTexCoordsPointer() const;
    const IndexType* getIndexPointer() const;

    ref Vec3f[] getVertices();
    ref FloatColor[] getColors();
    ref Vec3f[] getNormals();
    ref Vec2f[] getTexCoords();
    ref IndexType[] getIndices();

    ref const(Vec3f[]) getVertices() const;
    ref const(FloatColor[]) getColors() const;
    ref const(Vec3f[]) getNormals() const;
    ref const(Vec2f[]) getTexCoords() const;
    ref const(IndexType[]) getIndices() const;

    ref int[] getFace(int faceId);
    
    Vec3f getCentroid() const;

    void setName(string name_);

    bool haveVertsChanged();
    bool haveColorsChanged();
    bool haveNormalsChanged();
    bool haveTexCoordsChanged();
    bool haveIndicesChanged();
    
    bool hasVertices() const;
    bool hasColors() const;
    bool hasNormals() const;
    bool hasTexCoords() const;
    bool hasIndices() const;
    
    void drawVertices();
    void drawWireframe();
    void drawFaces();
    void draw();

    void load(string path);
    void save(string path, bool useBinary = false) const;
  }
    void enableColors();
    void enableTextures();
    void enableNormals();
    void enableIndices();
    
    void disableColors();
    void disableTextures();
    void disableNormals();
    void disableIndices();
    
    bool usingColors() const;
    bool usingTextures() const;
    bool usingNormals() const;
    bool usingIndices() const;

  final
  {
    void append(Mesh mesh);
    
    void setColorForIndices( int startIndex, int endIndex, Color!() color );
    Mesh getMeshForIndices( int startIndex, int endIndex ) const;
    Mesh getMeshForIndices( int startIndex, int endIndex, int startVertIndex, int endVertIndex ) const;
    void mergeDuplicateVertices();
    // return a list of triangles that do not share vertices or indices //
    ref const(MeshFace[]) getUniqueFaces() const;
    Vec3f[] getFaceNormals( bool perVetex=false) const;
    void setFromTriangles(in MeshFace[] tris, bool bUseFaceNormal=false );
    void smoothNormals( float angle );
  }

    static Mesh plane(float width, float height, int columns=2, int rows=2, PrimitiveMode mode = PrimitiveMode.TRIANGLE_STRIP);
    static Mesh sphere(float radius, int res=12, PrimitiveMode mode = PrimitiveMode.TRIANGLE_STRIP);
    static Mesh icosahedron(float radius);
    static Mesh icosphere(float radius, int iterations=2);
    static Mesh cylinder(float radius, float height, int radiusSegments=12, int heightSegments=6, int numCapSegments=2, bool bCapped = true, PrimitiveMode mode=PrimitiveMode.TRIANGLE_STRIP);
    static Mesh cone(float radius, float height, int radiusSegments=12, int heightSegments=6, int capSegments=2, PrimitiveMode mode=PrimitiveMode.TRIANGLE_STRIP);
    static Mesh box(float width, float height, float depth, int resX=2, int resY=2, int resZ=2);
    static Mesh axis(float size=1.0);
    
    void draw(PolyRenderMode renderType);

private:

    Vec3f[] vertices;
    FloatColor[] colors;
    Vec3f[] normals;
    Vec2f[] texCoords;
    IndexType[] indices;

    // this variables are only caches and returned always as const
    // mutable allows to change them from const methods
    MeshFace[] faces;
    bool bFacesDirty;

    bool bVertsChanged, bColorsChanged, bNormalsChanged, bTexCoordsChanged, bIndicesChanged;
    PrimitiveMode mode;
    string name;
    
    bool useColors;
    bool useTextures;
    bool useNormals;
    bool useIndices;
    
//  ofMaterial *mat;
};

// this is always a triangle //
struct MeshFace {
public:
    //this();

    ref const(Vec3f) getFaceNormal() const;

    void setVertex( size_t idx, in Vec3f v );
    ref const(Vec3f) getVertex(size_t idx) const;

    void setNormal( size_t idx, in Vec3f n );
    ref const(Vec3f) getNormal(size_t idx) const;

    void setColor( size_t idx, in FloatColor color );
    ref const(FloatColor) getColor(size_t idx) const;

    void setTexCoord( size_t idx, in Vec2f tCoord );
    ref const(Vec2f) getTexCoord(size_t idx) const;

    void setHasColors( bool bColors );
    void setHasNormals( bool bNormals );
    void setHasTexcoords( bool bTexcoords );

    bool hasColors() const;
    bool hasNormals() const;
    bool hasTexcoords() const;

private:
    void calculateFaceNormal() const;
    bool bHasNormals, bHasColors, bHasTexcoords;

    // this variables are only caches and returned always as const
    // mutable allows to change them from const methods
    bool bFaceNormalDirty;
    Vec3f faceNormal;
    Vec3f vertices[3];
    Vec3f normals[3];
    FloatColor colors[3];
    Vec2f texCoords[3];
};
