#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in vec4      varColor;
out vec4     fragColor;
#else
varying vec4 varColor;
#endif

void main (void)
{
	#if __VERSION__ >= 140
	fragColor = varColor;
	#else
	gl_FragColor = varColor;
	#endif
}
