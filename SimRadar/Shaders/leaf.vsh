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
	
	//
	// x = alpha
	// y = beta
	// z = gamma
	//
	// TFM = Rz(gamma) Ry(beta) Rz(alpha)
	//
	//     =            Rz(z)                    Ry(y)                       Rz(x)
	//
	//     = [ cos(z)  -sin(z)    0 ]  [  cos(y)   0    sin(y) ]  [ cos(x)  -sin(x)    0 ]
	//       [ sin(z)   cos(z)    0 ]  [    0      1      0    ]  [ sin(x)   cos(x)    0 ]
	//       [   0        0       1 ]  [ -sin(y)   0    cos(y) ]  [   0        0       1 ]
	//
	//     = [ cos(z) cos(y) cos(x) - sin(z) sin(x)    -cos(z) cos(y) sin(x) - sin(z) cos(x)    cos(z) sin(y) ]
	//       [ sin(z) cos(y) cos(x) + cos(z) sin(x)    -sin(z) cos(y) sin(x) + cos(z) cos(x)    sin(z) sin(y) ]
	//       [           -sin(y) cos(x)                            sin(y) sin(x)                   cos(y)     ]
	//
	
	transformMatrix[0] = vec4( c.z * c.y * c.x - s.z * s.x ,  s.z * c.y * c.x + c.z * s.x , -s.y * c.x , 0.0);
	transformMatrix[1] = vec4(-c.z * c.y * s.x - s.z * c.x , -s.z * c.y * s.x + c.z * c.x ,  s.y * s.x , 0.0);
	transformMatrix[2] = vec4( c.z * s.y                   ,  s.z * s.y                   ,  c.y       , 0.0);
	transformMatrix[3] = vec4(inTranslation, 1.0);
	
	gl_Position = modelViewProjectionMatrix * transformMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
