#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

#if __VERSION__ >= 140
in vec3 inPosition;
out vec4 varColor;
#else
attribute vec3 inPosition;
varying vec4 varColor;
#endif

void main (void)
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
	gl_Position = modelViewProjectionMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
