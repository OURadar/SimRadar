//
//  GLOverlay.h
//
//  Created by Boon Leng Cheong on 12/26/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
//#import <OpenGL/gl3.h>
#import <GLKit/GLKit.h>
#import <Quartz/Quartz.h>

@interface GLOverlay : NSObject {
    
    GLuint textureName;

    float devicePixelRatio;
    
    @private
    
    GLuint program;
    GLuint vao;
    GLuint vbo[3];
    
    GLint mvpUI;
    GLint colorUI;
    GLint textureUI;
    
    GLint positionAI;
    GLint textureCoordAI;
    
    GLubyte *bitmap;
    GLsizei bitmapWidth, bitmapHeight;
}

- (id)initWithSize:(NSSize)size;

- (int)updateGLTexture;

- (void)drawAtRect:(NSRect)rect;

@end
