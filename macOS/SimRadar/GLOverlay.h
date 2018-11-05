//
//  GLOverlay.h
//
//  Created by Boon Leng Cheong on 12/26/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#ifndef GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED 1
#endif

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import <GLKit/GLKit.h>
#import <Quartz/Quartz.h>

@interface GLOverlay : NSObject {
    
    NSRect drawRect;
    
    GLuint textureName;

    float devicePixelRatio;
    GLKMatrix4 modelViewProjection;
    
    @private
    
    GLuint program;
    GLuint vao;
    GLuint vbo[3];
    
    GLint mvpUI;
    
    GLint positionAI;
    GLint textureCoordAI;
    
    GLubyte *bitmap;
    GLsizei bitmapWidth, bitmapHeight;
    float textureAnchors[24];            // 4 floats per vertex, need 6 vertices for a rect
    
    NSAutoreleasePool *drawPool;
    NSImage *image;
    
    BOOL canvasNeedsUpdate;
}

@property (nonatomic) GLKMatrix4 modelViewProjection;
@property (nonatomic) NSRect drawRect;

- (id)initWithRect:(NSRect)rect;

- (void)beginCanvas;
- (void)endCanvas;

- (void)draw;

@end
