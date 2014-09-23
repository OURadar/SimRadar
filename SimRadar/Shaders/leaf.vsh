uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

in vec3 inPosition;
in mat4 inOrientation;

out vec4 varColor;

void main (void)
{
	gl_Position = modelViewProjectionMatrix * inOrientation * vec4(inPosition, 1.0);

	varColor = drawColor;
}
