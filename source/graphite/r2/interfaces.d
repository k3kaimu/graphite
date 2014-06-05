module graphite.r2.interfaces;

/**
ただのCairoのwrapper

このRendererの目的は、簡単なGUIの描画やテクスチャ生成など。
*/
final class CairoRenderer
{
    //void 
}



/**
OpenGL を使って2D描画するためのWrapper
*/
final class R2Renderer
{
    MatrixStack!ViewMatrix _vM;
}
