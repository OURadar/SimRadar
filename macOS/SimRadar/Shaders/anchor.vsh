in vec4 inPosition;
out vec4 varColor;

uniform mat4 modelViewMatrix;
uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

void main (void)
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
    vec4 pos = vec4(inPosition.xyz, 1.0);

    gl_Position = modelViewProjectionMatrix * pos;

    gl_PointSize = 20000.0 * inPosition.w / gl_Position.z;

	varColor = drawColor;
}
