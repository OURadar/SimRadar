//
//  common.h
//
//  Created by Boon Leng Cheong on 7/16/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#ifndef _bl_common_h
#define _bl_common_h

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#define EARTH_RADIUS_KM           6371.0

typedef struct sphericalCoordinate {
	double longitude, latitude, radius;
} SphericalCoordinate;

NS_INLINE SphericalCoordinate makeSphericalCoordinate(double longitude, double latitude, double radius) {
    SphericalCoordinate c;
	c.longitude = longitude;
	c.latitude = latitude;
	c.radius = radius;
    return c;
}


typedef struct cartesianCoordinate {
	float x, y, z;
} CartesianCoordinate;

NS_INLINE CartesianCoordinate makeCartesianCoordinate(float x, float y, float z) {
	CartesianCoordinate c;
	c.x = x;
	c.y = y;
	c.z = z;
    return c;
}


typedef struct view_param {
	GLKMatrix4 coreRotation;
	GLKMatrix4 siteRotation;
	float minRange;
	float maxRange;
	float range;
} GLViewParameter;

NS_INLINE GLViewParameter makeViewParameterIdentity(GLKMatrix4 coreRotation, GLKMatrix4 siteRotation, float range) {
	GLViewParameter c;
	c.coreRotation = coreRotation;
	c.siteRotation = siteRotation;
	c.minRange = 10.0f;
	c.maxRange = EARTH_RADIUS_KM;
	c.range = range;
	return c;
}


#if defined(__STRICT_ANSI__)
struct _attributed_vertex
{
    float m[8];
};
typedef struct _attributed_vertex AttributedVertex;
#else
union _attributed_vertex
{
	struct { GLKVector3 vertex; GLKVector3 normal; GLKVector2 tex; };
    struct { float x, y, z, u, v, w, s, t; };
    float m[8];
};
typedef union _attributed_vertex AttributedVertex;
#endif

NS_INLINE AttributedVertex makeMapAttributedVertex(float x, float y, float z, float u, float v, float w, float s, float t) {
	AttributedVertex c;
	c.x = x;
	c.y = y;
	c.z = z;
	c.u = u;
	c.v = v;
	c.z = z;
	c.s = s;
	c.t = t;
	return c;
}

enum {
	DRAW_SETUP_VBO_TYPE_VERTEX       = 1,
	DRAW_SETUP_VBO_TYPE_COLOR        = 2,
	DRAW_SETUP_VBO_TYPE_NORMAL       = 3,
	DRAW_SETUP_VBO_TYPE_TEXCOORD     = 4,
	DRAW_SETUP_VBO_TYPE_MODEL_MAT_1  = 5,
	DRAW_SETUP_VBO_TYPE_MODEL_MAT_2  = 6,
	DRAW_SETUP_VBO_TYPE_MODEL_MAT_3  = 7,
	DRAW_SETUP_VBO_TYPE_MODEL_MAT_4  = 8
};

#endif
