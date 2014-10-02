//
//  GLText.h
//  SimRadar
//
//  A simple text painter for OpenGL context that was created with Core Profile 4
//
//  Synopsis:
//  Create a GLText object after an OpenGL context has been created. Create the
//  object together with other VAOs that are needed for rendering. This is the
//  stage the object creates a texture atlas that stores all the letters and send
//  the texture map into GPU memory.
//
//  Created by Boon Leng Cheong on 9/25/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <GLKit/GLKit.h>
#import <Quartz/Quartz.h>

#define GLTextMaxString  1024

enum {
    GLTextAlignmentLeft,
    GLTextAlignmentCenter,
    GLTextAlignmentRight
};
typedef char GLTextAlignment;

#pragma pack(push, 1)
#if defined(__STRICT_ANSI__)
struct _gltext_vertex
{
    float m[4];
};
typedef struct _gltext_vertex GLTextVertex;
#else
union _gltext_vertex
{
    struct { GLKVector2 vertex; GLKVector2 tex; };
    struct { float x, y, s, t; };
    float m[4];
};
typedef union _gltext_vertex GLTextVertex;
#endif
#pragma pack(pop)

@interface GLText : NSObject {
	
	GLuint texture;
    GLKMatrix4 modelViewProjection;
	
	@private
	
	GLuint program;
	GLuint vao;
	GLuint vbo[3];
	
	GLint mvpUI;
	GLint colorUI;
	GLint textureUI;
	
	GLint positionAI;
	GLint textureCoordAI;

    CGFloat pad;
    CGFloat baseSize;
	GLubyte *bitmap;
    GLsizei bitmapWidth, bitmapHeight;
    GLTextVertex textureAnchors[6];
    GLTextVertex *drawAnchors;
    NSRect textureCoord[256];
    NSSize symbolSize[256];
}

@property (nonatomic, readonly) GLuint texture;
@property (nonatomic) GLKMatrix4 modelViewProjection;

- (void)showTextureMap;
- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale;
- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale align:(GLTextAlignment)align;
- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha align:(GLTextAlignment)align;

// Per client methods


@end
