#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

uniform sampler2D colormapTexture;

#if __VERSION__ >= 140
in vec4 inPosition;
in vec4 inColor;
//in vec2 inTexcoord;
//out vec2 varTexcoord;
out vec4 varColor;
#else
attribute vec4 inPosition;
attribute vec4 inColor;
varying vec4 varColor;
#endif

void main (void)
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
	gl_Position = modelViewProjectionMatrix * vec4(inPosition.xyz, 1.0);

	//varTexcoord = inTexcoord;

	//varColor = inColor;
	//varColor = inColor * drawColor;
    varColor = texture(colormapTexture, vec2(inPosition.w, drawColor.x));
    varColor.w *= drawColor.w;
	//varColor = 0.3*drawColor + 0.7*inColor;
	//varColor = inColor - drawColor;
	//varColor = min(0.5*drawColor + 0.5*inColor, 1.0);
    
//    if (inPosition.z < 0.0) {
//        varColor *= 0.75;
//    }
}
