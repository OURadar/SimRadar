#ifdef GL_ES
precision highp float;
#endif

uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;
uniform vec4 drawSize;
uniform bool pingPong;

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
	gl_Position = modelViewProjectionMatrix * vec4(inPosition.xyz, 1.0f);

    //varColor = texture(colormapTexture, vec2(inPosition.w * 250.0f, drawColor.x));
    varColor = texture(colormapTexture, vec2(inColor.x, drawColor.x));

    // The alpha component follows the drawColor's alpha
    varColor.w = drawColor.w;
    if (pingPong) {
        // Make smaller drops even more transparent
        varColor.w *= inColor.x;
        gl_PointSize = min(40.0f, 150.0f * (inColor.x + 0.5f) * sqrt(drawSize.x / gl_Position.z));
    } else {
        gl_PointSize = min(40.0f, 200.0f * sqrt(drawSize.x / gl_Position.z));
    }

//    gl_PointSize = 8000.0f * (inColor.x + 0.75f) * drawSize.x / gl_Position.z;
//    gl_PointSize = 5000.0f * (inColor.x + 1.0f) * drawSize.x / gl_Position.z;
//    gl_PointSize = 5000.0f * (inColor.x + 1.25f) * drawSize.x / gl_Position.z;
//    gl_PointSize = 10000.0f * drawSize.x / gl_Position.z;
//    gl_PointSize = 15000.0f * (inColor.x) * drawSize.x / gl_Position.z;
}
