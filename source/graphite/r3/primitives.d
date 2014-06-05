module graphite.r3.primitives;

import graphite;

class R3Primitive : Node
{
    void mapTexCoords(float u1, float v1, float u2, float v2);
    void mapTexCoords(ref Texture inTexture);

    ref Mesh mesh() @property;

    ref Vec4f texCoords() @property;

    bool hasScaling() @property;
    bool hasNormalsEnabled() @property;

    void enableNormals();
    void enableTexture();
    void enableColors();

    void disableNormals();
    void disbaleTexture();
    void disableColors();

    void removeMesh(int index);
    void removeTexture(int index);
    void clear();

    void drawVertices();
    void drawWireframe();
    void drawFaces();
    override void draw();
    void draw(PolyRenderMode);
    void drawNormals(float length, bool bFaceNormals = false);
    void drawAxes(float a_size);


  protected:

    void normalizeAndApplySavedTexCoords();

    Vec4f _texCoords;
    bool _usingVbo;
    Mesh* _mesh;
    Mesh _normalsMesh;

    IndexType[] indexcies(int startIndex, int endIndex) @property;
}