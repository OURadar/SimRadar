//
//  GLText.h
//  SimRadar
//
//  Created by Boon Leng Cheong on 9/25/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <GLKit/GLKit.h>

@interface GLText : NSObject {
	
	GLuint texture;
	
	@private
	
	GLuint program;
	GLuint vao;
	GLuint vbo[4];
	
	GLint mvpUI;
	GLint colorUI;
	GLint textureUI;
	
	GLint positionAI;
	GLint textureCoordAI;
	
	float letterWidth[256];
}

@property (nonatomic, readonly) GLuint texture;

- (void)drawText:(const char *)string origin:(NSPoint)origin size:(float)size;

// Per client methods


@end
