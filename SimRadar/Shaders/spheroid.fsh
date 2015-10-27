in vec4      varColor;
out vec4     fragColor;

uniform sampler2D drawTemplate1;

void main (void)
{
	//fragColor = vec4(varColor, 1.0);
	//fragColor = varColor;
    vec4 fragTexture = texture(drawTemplate1, gl_PointCoord);
    fragColor = fragTexture * varColor;
}
