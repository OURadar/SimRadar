in vec4      varColor;
out vec4     fragColor;

uniform sampler2D drawTemplate2;

void main (void)
{
    vec4 fragTexture = texture(drawTemplate2, gl_PointCoord);
	fragColor = fragTexture * varColor;
}
