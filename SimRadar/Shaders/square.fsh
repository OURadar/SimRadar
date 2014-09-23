in vec4      varColor;
out vec4     fragColor;

uniform sampler2D drawTexture;

void main (void)
{
	//fragColor = vec4(varColor, 1.0);
	//fragColor = varColor;
    vec4 fragTexture = texture(drawTexture, gl_PointCoord);
    fragColor = fragTexture * varColor;
}
