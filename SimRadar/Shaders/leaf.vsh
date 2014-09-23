uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

in vec3 inPosition;
in vec3 inRotation;
in vec3 inTranslation;

out vec4 varColor;

void main (void)
{
	mat4 transformMatrix;
	vec3 c = cos(inRotation);
	vec3 s = sin(inRotation);
	
	transformMatrix[0] = vec4( c.z * c.y * c.x - s.z * s.x ,  s.z * c.y * c.x + c.z * s.x , -s.y * c.x , 0.0);
	transformMatrix[1] = vec4(-c.z * c.y * s.x - s.z * c.x , -s.z * c.y * s.x + c.z * c.x ,  s.y * s.x , 0.0);
	transformMatrix[2] = vec4( c.z * s.y                   ,  s.z * s.y                   ,  c.y       , 0.0);
	transformMatrix[3] = vec4(inTranslation, 1.0);
	
	gl_Position = modelViewProjectionMatrix * transformMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
