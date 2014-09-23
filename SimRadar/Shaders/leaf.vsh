uniform mat4 modelViewProjectionMatrix;
uniform vec4 drawColor;

in vec3 inPosition;
in vec3 inRotation;
in vec3 inTranslation;

out vec4 varColor;

void main (void)
{
	mat4 transformMatrix = mat4(1.0);
	
	vec3 cos_angles = cos(inRotation);
	vec3 sin_angles = sin(inRotation);
	
//	transformMatrix[0][0] =  cos_angles.x;   transformMatrix[1][0] =  sin_angles.x;    transformMatrix[2][0] = 0.0f;
//	transformMatrix[0][1] = -sin_angles.x;   transformMatrix[1][0] =  cos_angles.x;    transformMatrix[2][0] = 0.0f;
//	transformMatrix[0][2] =  0.0f;           transformMatrix[1][0] =  0.0f;            transformMatrix[2][0] = 1.0f;
	
//	transformMatrix[3].x = inTranslation.x;
//	transformMatrix[3].y = inTranslation.y;
//	transformMatrix[3].z = inTranslation.z;
	
	transformMatrix[3].xyz = inTranslation;
	
	gl_Position = modelViewProjectionMatrix * transformMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
