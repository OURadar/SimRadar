in vec2           varTextureCoord;
out vec4          fragColor;

uniform vec4      drawColor;
uniform sampler2D diffuseTexture;

void main (void)
{
    if (varTextureCoord.t == 0.0) {
        fragColor = drawColor;
    } else {
        fragColor = drawColor * texture(diffuseTexture, varTextureCoord);
    }
}
