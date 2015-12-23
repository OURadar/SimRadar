in vec2           varTextureCoord;
out vec4          fragColor;

uniform bool      pingPong;
uniform vec4      drawColor;
uniform sampler2D diffuseTexture;

//uniform float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
//uniform float weight[5] = float[] (0.25, 0.20, 0.12, 0.06, 0.03);
//uniform float weight[5] = float[] (0.20, 0.20, 0.20, 0.20, 0.20);
uniform float weight[5] = float[] (0.20, 0.16, 0.12, 0.08, 0.04);

void main (void)
{
    int i;
    vec2 point = 1.0 / textureSize(diffuseTexture, 0);
    vec2 offset = vec2(0.0, 0.0);
    fragColor = texture(diffuseTexture, varTextureCoord) * weight[0];
    if (pingPong) {
        for (i = 1; i < 5; i++) {
            offset.x = point.x * i;
            fragColor += texture(diffuseTexture, varTextureCoord + offset) * weight[i];
            fragColor += texture(diffuseTexture, varTextureCoord - offset) * weight[i];
        }
    } else {
        for (i = 1; i < 5; i++) {
            offset.y = point.y * i;
            fragColor += texture(diffuseTexture, varTextureCoord + offset) * weight[i];
            fragColor += texture(diffuseTexture, varTextureCoord - offset) * weight[i];
        }
    }
    fragColor *= drawColor;
}
