in vec4      varColor;
out vec4     fragColor;

uniform sampler2D drawTemplate1;

void main (void)
{
    vec4 fragTexture = texture(drawTemplate1, gl_PointCoord);
    fragColor = fragTexture * varColor;
}
