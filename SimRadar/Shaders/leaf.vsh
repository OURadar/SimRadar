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
	
//	transformMatrix[0] = vec4( c.z * c.y * c.x - s.z * s.x ,  s.z * c.y * c.x + c.z * s.x , -s.y * c.x , 0.0);
//	transformMatrix[1] = vec4(-c.z * c.y * s.x - s.z * c.x , -s.z * c.y * s.x + c.z * c.x ,  s.y * s.x , 0.0);
//	transformMatrix[2] = vec4( c.z * s.y                   ,  s.z * s.y                   ,  c.y       , 0.0);
//	transformMatrix[3] = vec4(inTranslation, 1.0);
	
//     TFM = Rz(alpha) Ry(beta) Rz(gamma)
//    
//         =            Rz(x)                    Ry(y)                       Rz(z)              Rcoord = Rx(-90deg)
//
//         = [ cos(x)  -sin(x)    0 ]  [  cos(y)   0    sin(y) ]  [ cos(z)  -sin(z)    0 ]  [   1       0        0   ]
//           [ sin(x)   cos(x)    0 ]  [    0      1      0    ]  [ sin(z)   cos(z)    0 ]  [   0    cos(t)  -sin(t) ]
//           [   0        0       1 ]  [ -sin(y)   0    cos(y) ]  [   0        0       1 ]  [   0    cos(t)  -sin(t) ]
//    
//         = [ cos(x)*cos(y)*cos(z) - sin(x)*sin(z), - cos(z)*sin(x) - cos(x)*cos(y)*sin(z), cos(x)*sin(y)]  [  1  0  0  ]
//           [ cos(x)*sin(z) + cos(y)*cos(z)*sin(x),   cos(x)*cos(z) - cos(y)*sin(x)*sin(z), sin(x)*sin(y)]  [  0  0  1  ]
//           [                       -cos(z)*sin(y),                          sin(y)*sin(z),        cos(y)]  [  0 -1  0  ]
//
//         = [ cos(x)*cos(y)*cos(z) - sin(x)*sin(z), -cos(x)*sin(y), - cos(z)*sin(x) - cos(x)*cos(y)*sin(z)]
//           [ cos(x)*sin(z) + cos(y)*cos(z)*sin(x), -sin(x)*sin(y),   cos(x)*cos(z) - cos(y)*sin(x)*sin(z)]
//           [                       -cos(z)*sin(y),        -cos(y),                          sin(y)*sin(z)]
//
//         = [   cos(x)*cos(y)*cos(z) - sin(x)*sin(z), cos(x)*sin(z) + cos(y)*cos(z)*sin(x), -cos(z)*sin(y)] T
//           [                         -cos(x)*sin(y),                       -sin(x)*sin(y),        -cos(y)]
//           [ - cos(z)*sin(x) - cos(x)*cos(y)*sin(z), cos(x)*cos(z) - cos(y)*sin(x)*sin(z),  sin(y)*sin(z)]
//
//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.x * s.z + c.y * c.z * s.x , -c.z * s.y ,  0.0);
//    transformMatrix[1] = vec4(                  -c.x * s.y ,                   -s.x * s.y ,       -c.y ,  0.0);
//    transformMatrix[2] = vec4(-c.z * s.x - c.x * c.y * s.z ,  c.x * c.z - c.y * s.x * s.z ,  s.y * s.z ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);
    
//    [ cos(x)*cos(y)*cos(z) - sin(x)*sin(z), cos(x)*sin(z) + cos(y)*cos(z)*sin(x), -cos(z)*sin(y)] T
//    [                        cos(x)*sin(y),                        sin(x)*sin(y),         cos(y)]
//    [ cos(z)*sin(x) + cos(x)*cos(y)*sin(z), cos(y)*sin(x)*sin(z) - cos(x)*cos(z), -sin(y)*sin(z)]

//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.x * s.z + c.y * c.z * s.x , -c.z * s.y ,  0.0);
//    transformMatrix[1] = vec4(                   c.x * s.y ,                    s.x * s.y ,        c.y ,  0.0);
//    transformMatrix[2] = vec4( c.z * s.x + c.x * c.y * s.z ,  c.y * s.x * s.z - c.x * c.z , -s.y * s.z ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);

    // (R3 * R2 * R1) .'
//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.z * s.x + c.x * c.y * s.z , -c.x * s.y ,  0.0);
//    transformMatrix[1] = vec4(-c.x * s.z - c.y * c.z * s.x ,  c.x * c.z - c.y * s.x * s.z ,  s.x * s.y ,  0.0);
//    transformMatrix[2] = vec4(                   c.z * s.y ,                    s.y * s.z ,        c.y ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);

    // (R1 * R2 * R3).'
//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.x * s.z + c.y * c.z * s.x , -c.z * s.y ,  0.0);
//    transformMatrix[1] = vec4(-c.z * s.x - c.x * c.y * s.z ,  c.x * c.z - c.y * s.x * s.z ,  s.y * s.z ,  0.0);
//    transformMatrix[2] = vec4(                   c.x * s.y ,                    s.x * s.y ,        c.y ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);
    
//    (R1 * R2 * R3 * R4).'   R4 = Rx(-90deg)
//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.x * s.z + c.y * c.z * s.x , -c.z * s.y ,  0.0);
//    transformMatrix[1] = vec4(                  -c.x * s.y ,                   -s.x * s.y ,       -c.y ,  0.0);
//    transformMatrix[2] = vec4(-c.z * s.x - c.x * c.y * s.z ,  c.x * c.z - c.y * s.x * s.z ,  s.y * s.z ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);

//    (R1 * R2 * R3 * R4).'   R4 = Rx(+90deg)
//    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.x * s.z + c.y * c.z * s.x , -c.z * s.y ,  0.0);
//    transformMatrix[1] = vec4(                   c.x * s.y ,                    s.x * s.y ,        c.y ,  0.0);
//    transformMatrix[2] = vec4( c.z * s.x + c.x * c.y * s.z ,  c.y * s.x * s.z - c.x * c.z , -s.y * s.z ,  0.0);
//    transformMatrix[3] = vec4(inTranslation, 1.0);

//    (R4 * R1 * R2 * R3).'   R4 = Rx(+90deg)
    transformMatrix[0] = vec4( c.x * c.y * c.z - s.x * s.z ,  c.z * s.y ,  c.x * s.z + c.y * c.z * s.x ,  0.0);
    transformMatrix[1] = vec4(-c.z * s.x - c.x * c.y * s.z , -s.y * s.z ,  c.x * c.z - c.y * s.x * s.z ,  0.0);
    transformMatrix[2] = vec4(                   c.x * s.y ,       -c.y ,                    s.x * s.y ,  0.0);
    transformMatrix[3] = vec4(inTranslation, 1.0);

    gl_Position = modelViewProjectionMatrix * transformMatrix * vec4(inPosition, 1.0);

	varColor = drawColor;
}
