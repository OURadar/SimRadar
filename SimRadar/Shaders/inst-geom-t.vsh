uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;
uniform vec4 drawSize;

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

	//varColor = drawColor;
    varColor = texture(colormapTexture, vec2(inColor.x, drawColor.x));
    
    // Make debris closer to surface more transparent
    if (inTranslation.z < 25.0) {
        varColor.a *= inTranslation.z * 0.04;
    }
}
