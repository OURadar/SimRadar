uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;
uniform vec4 drawSize;
uniform bool pingPong;
uniform float lowZ;

uniform sampler2D colormapTexture;

in vec3 inPosition;
in vec4 inQuaternion;
in vec3 inTranslation;
in vec4 inColor;

out vec4 varColor;

vec4 quat_mult(vec4 left, vec4 right)
{
    return vec4(left.w * right.x - left.z * right.y + left.y * right.z + left.x * right.w,
                left.w * right.y + left.z * right.x + left.y * right.w - left.x * right.z,
                left.w * right.z + left.z * right.w - left.y * right.x + left.x * right.y,
                left.w * right.w - left.z * right.z - left.y * right.y - left.x * right.x);
}

void main (void)
{
	mat4 transformMatrix;

    vec4 pos = vec4(inPosition, 0.0);
    vec4 quat_left = inQuaternion;
    vec4 quat_right = vec4(-quat_left.x, -quat_left.y, -quat_left.z, quat_left.w);
    
    pos = pos * drawSize;
    pos = quat_mult(quat_mult(quat_left, pos), quat_right);

    gl_Position = modelViewProjectionMatrix * (pos + vec4(inTranslation, 1.0));

    if (pingPong) {
        varColor = texture(colormapTexture, vec2(inColor.x, drawColor.x));
        varColor.a = inColor.a;
    } else {
        varColor = drawColor;
    }
    
    // Make debris closer to surface more transparent
    float a = 1.0f;
    if (inTranslation.z < 0.1f * lowZ) {
        varColor.a = 0.2f;
    } else if (inTranslation.z < lowZ) {
        a = clamp((inTranslation.z - 0.1f * lowZ) / (0.9f * lowZ), 0.2f, 1.0f);
        varColor.a *= a;
    }
}
