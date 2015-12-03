uniform mat4 modelViewMatrix;
uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;
uniform vec4 drawSize;

in vec4 inPosition;
out vec4 varColor;

void main (void)
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
    vec4 pos = vec4(inPosition.xyz, 1.0);
	gl_Position = modelViewProjectionMatrix * pos;

    //gl_PointSize =  - 20000.0 / (modelViewMatrix * pos).z;
    //gl_PointSize =  modelViewProjectionMatrix[3][3] * 200000.0 / (gl_Position.z * gl_Position.z);
    //gl_PointSize = 200.0 / (0.005 * gl_Position.z);
    //gl_PointSize = 25000000.0 / (gl_Position.z * gl_Position.w);
    //gl_PointSize = 40000.0 / gl_Position.w;
    //gl_PointSize = 40.0 * drawSize.w;
    gl_PointSize = 20000.0 * drawSize.w / gl_Position.z;

	varColor = drawColor;
}
