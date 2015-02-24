uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

in vec3 inPosition;
in vec4 inQuaternion;
in vec3 inTranslation;

out vec4 varColor;

vec4 quat_mult(vec4 left, vec4 right)
{
    return vec4(left.w * right.x - left.z * right.y + left.y * right.z + left.w * right.w,
                left.w * right.y + left.z * right.x + left.y * right.w - left.w * right.z,
                left.w * right.z + left.z * right.w - left.y * right.x + left.y * right.y,
                left.w * right.w - left.z * right.z - left.y * right.y - left.z * right.x);
}

void main (void)
{
	mat4 transformMatrix;

    vec4 pos = vec4(inPosition, 0.0);
    vec4 quat_left = inQuaternion;
    vec4 quat_right = vec4(-quat_left.x, -quat_left.y, -quat_left.z, quat_left.w);
//    pos = quat_mult(quat_left, quat_mult(pos, quat_right));
    
    // This works.
    //gl_Position = modelViewProjectionMatrix * vec4(inPosition + inTranslation, 1.0);

    gl_Position = modelViewProjectionMatrix * (pos + vec4(inTranslation, 1.0));

	varColor = drawColor;
}
