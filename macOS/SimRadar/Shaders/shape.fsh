#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
//in vec2      varTexcoord;
in vec4      varColor;
out vec4     fragColor;
#else
varying vec4 varColor;
#endif

//uniform sampler2D diffuseTexture;

void main (void)
{
	#if __VERSION__ >= 140
	//fragColor = texture(diffuseTexture, varTexcoord.st, 0.0);
	//fragColor = vec4(varColor, 1.0);
	fragColor = varColor;
	#else
	gl_FragColor = varColor;
	#endif
}
