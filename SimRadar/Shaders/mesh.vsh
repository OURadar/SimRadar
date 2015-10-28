uniform mat4 modelViewProjectionMatrix;

in vec4 inPosition;
in vec2 inTextureCoord;

out vec2 varTextureCoord;

void main (void)
{
	gl_Position = modelViewProjectionMatrix * inPosition;

	varTextureCoord = inTextureCoord;
}
