uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

in vec3 inPosition;
out vec4 varColor;

void main (void)
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
	gl_Position = modelViewProjectionMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
