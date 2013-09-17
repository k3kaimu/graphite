module graphite.r3.primitive;

import graphite;

class IPrimitive : r3.Node
{
    void mapTexCoords(float u1, float v1, float u2, float v2);
    void mapTexCoords(ref gl.Texture inTexture);

    ref r3.Mesh mesh() @property;

    ref math.Vec4f texCoords() @property;

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
    void draw();
    void draw(gl.PolyRenderMode);
    void drawNormals(float length, bool bFaceNormals = false);
    void drawAxes(float a_size);


  protected:

    void normalizeAndApplySavedTexCoords();

    math.Vec4f _texCoords;
    bool _usingVbo;
    r3.Mesh* _mesh;
    r3.Mesh _normalsMesh;

    utils.constant.IndexType[] indexcies(int startIndex, int endIndex) @property;
}