//
//  glUtil.h
//
//  Created by Boon Leng Cheong on 7/12/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#ifndef _glUtil_h
#define _glUtil_h

#if RADAR_IOS

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// The name of the VertexArrayObject are slightly different in
// OpenGLES, OpenGL Core Profile, and OpenGL Legacy
// The arguments are exactly the same across these APIs however
#define glBindVertexArray glBindVertexArrayOES
#define glGenVertexArrays glGenVertexArraysOES
#define glDeleteVertexArrays glDeleteVertexArraysOES

#else

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

#endif

#import <GLKit/GLKit.h>


static inline const char * GetGLErrorString(GLenum error)
{
	const char *str;
	switch( error )
	{
		case GL_NO_ERROR:
			str = "GL_NO_ERROR";
			break;
		case GL_INVALID_ENUM:
			str = "GL_INVALID_ENUM";
			break;
		case GL_INVALID_VALUE:
			str = "GL_INVALID_VALUE";
			break;
		case GL_INVALID_OPERATION:
			str = "GL_INVALID_OPERATION";
			break;
#if defined __gl_h_ || defined __gl3_h_
		case GL_OUT_OF_MEMORY:
			str = "GL_OUT_OF_MEMORY";
			break;
		case GL_INVALID_FRAMEBUFFER_OPERATION:
			str = "GL_INVALID_FRAMEBUFFER_OPERATION";
			break;
#endif
#if defined __gl_h_
		case GL_STACK_OVERFLOW:
			str = "GL_STACK_OVERFLOW";
			break;
		case GL_STACK_UNDERFLOW:
			str = "GL_STACK_UNDERFLOW";
			break;
		case GL_TABLE_TOO_LARGE:
			str = "GL_TABLE_TOO_LARGE";
			break;
#endif
		default:
			str = "(ERROR: Unknown Error Enum)";
			break;
	}
	return str;
}

// Make triangle-strips from lines
// This function is meant to make thick lines from a series of line.
// It works by extending a pair of vertices into two triangle strips
// Coordinates of line is assumed to be in (x, y, z) but the z component
// is not used for in method.
//
static inline int makeThickLineTriagleStrips(float *thickLine, float *thickColors, float *line, float *colors, GLuint size, GLfloat w, char closed)
{
	int i, j = 0;
	
	GLfloat bx, by, bz;      // begin
	GLfloat ex, ey, ez;      // end
	GLfloat dx, dy;          // delta's
	
	GLfloat a;               // along angle
	GLfloat dw = 0.5f * w;   // extend per side
	
	GLfloat x;               // cross angle
	GLfloat cx, sx;          // cosine & sine of x
	
	GLfloat br, bg, bb;
	GLfloat er, eg, eb;
	
	
	bx = line[0];    br = colors[0];
	by = line[1];    bg = colors[1];
	bz = line[2];    bb = colors[2];
	
	j = 0;
	i = 3;
	while (i < 3 * size) {
		ex = line[i];    er = colors[i];   i++;
		ey = line[i];    eg = colors[i];   i++;
		ez = line[i];    eb = colors[i];   i++;
		
		dx = ex - bx;
		dy = ey - by;
		
		a = atan2f(dy, dx);
		x = a - 0.5f * M_PI;  // use clockwise for point 1
		cx = cosf(x);
		sx = sinf(x);
		
		dx = dw * cx;
		dy = dw * sx;
		
		//
		// Here, let's exploit the fact that:
		//
		//   sin(a + 180) = -sin(a)
		//   cos(a + 180) = -cos(a)
		//
		//
		//	p1x = bx + dx;
		//	p1y = by + dy;
		//
		//	p2x = bx - dx;
		//	p2y = by - dy;
		//
		//	p3x = ex + dx;
		//	p3y = ey + dy;
		//
		//	p4x = ex - dx;
		//	p4y = ey - dy;
		
		thickLine[j] = bx + dx;    thickColors[j] = br;    j++;
		thickLine[j] = by + dy;    thickColors[j] = bg;    j++;
		thickLine[j] = bz;         thickColors[j] = bb;    j++;
		
		thickLine[j] = bx - dx;    thickColors[j] = br;    j++;
		thickLine[j] = by - dy;    thickColors[j] = bg;    j++;
		thickLine[j] = bz;         thickColors[j] = bb;    j++;
		
		thickLine[j] = ex + dx;    thickColors[j] = er;    j++;
		thickLine[j] = ey + dy;    thickColors[j] = eg;    j++;
		thickLine[j] = ez;         thickColors[j] = eb;    j++;
		
		thickLine[j] = ex - dx;    thickColors[j] = er;    j++;
		thickLine[j] = ey - dy;    thickColors[j] = eg;    j++;
		thickLine[j] = ez;         thickColors[j] = eb;    j++;
		
		bx = ex;    br = er;
		by = ey;    bg = eg;
		bz = ez;    bb = eb;
	}
	
	if (closed) {
		thickLine[j] = thickLine[0];    thickColors[j] = colors[0];    j++;
		thickLine[j] = thickLine[1];    thickColors[j] = colors[1];    j++;
		thickLine[j] = thickLine[2];    thickColors[j] = colors[2];    j++;
		
		thickLine[j] = thickLine[3];    thickColors[j] = colors[0];    j++;
		thickLine[j] = thickLine[4];    thickColors[j] = colors[1];    j++;
		thickLine[j] = thickLine[5];    thickColors[j] = colors[2];    j++;
	}
	
	return j;
}


#endif
