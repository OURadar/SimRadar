//
//  GLText.m
//  SimRadar
//
//  Created by Boon Leng Cheong on 9/25/14.
//  Copyright (c) 2014 Boon Leng Cheong. All rights reserved.
//

#import "GLText.h"

@interface GLText()
- (void)buildTexture;
@end


@implementation GLText

@synthesize texture;

#pragma mark -
#pragma mark Life Cycle

- (id)init
{
	self = [super init];
	if (self) {
		[self buildTexture];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

- (void)buildTexture
{
	GLint ret;
	GLuint shader;
	
	program = glCreateProgram();
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	
	char *vertexShaderSource =
	"#version 410\n"
	"uniform mat4 mvp;\n"
	"uniform vec4 uColor;\n"
	"in vec4 position;\n"
	"in vec2 texCoord;\n"
	"out vec4 color;\n"
	"out vec2 texUV;\n"
	"void main() {\n"
	"    gl_Position = mvp * position;\n"
	"    color = uColor;\n"
	"    texUV = texCoord;\n"
	"}\n";
	
	char *fragmentShaderSource =
	"#version 410\n"
	"in vec4 color;\n"
	"in vec2 texUV;\n"
	"out vec4 fragColor;\n"
	"uniform sampler2D uTexture;\n"
	"void main() {\n"
	"    vec4 fragTexture = texture(uTexture, texUV);\n"
	"    fragColor = fragTexture * color;\n"
	"}\n";

//	printf("-----------------\n%s\n-----------------\n", vertexShaderSource);
//	printf("-----------------\n%s\n-----------------\n", fragmentShaderSource);
	

	// Vertex
	shader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(shader, 1, (const GLchar **)&vertexShaderSource, NULL);
	glCompileShader(shader);
	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &ret);
	if (ret) {
		GLchar *log = (GLchar *)malloc(ret + 1);
		glGetShaderInfoLog(shader, ret, &ret, log);
		NSLog(@"Vertex shader compile log:%s", log);
		free(log);
	} else {
		glAttachShader(program, shader);
		glDeleteShader(shader);
	}
	
	// Fragment
	shader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(shader, 1, (const GLchar **)&fragmentShaderSource, NULL);
	glCompileShader(shader);
	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &ret);
	if (ret) {
		GLchar *log = (GLchar *)malloc(ret + 1);
		glGetShaderInfoLog(shader, ret, &ret, log);
		NSLog(@"Fragment shader compile log:%s", log);
		free(log);
	} else {
		glAttachShader(program, shader);
		glDeleteShader(shader);
	}
	
	glLinkProgram(program);

	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &ret);
	if (ret) {
		GLchar *log = (GLchar *)malloc(ret + 1);
		glGetProgramInfoLog(program, ret, &ret, log);
		NSLog(@"Link return:%s", log);
		free(log);
	}
	glGetProgramiv(program, GL_LINK_STATUS, &ret);
	if (ret == 0) {
		NSLog(@"Failed to link program");
		return;
	}
	
	glValidateProgram(program);

	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &ret);
	if (ret) {
		GLchar *log = (GLchar *)malloc(ret + 1);
		glGetProgramInfoLog(program, ret, &ret, log);
		NSLog(@"Program validate:%s", log);
		free(log);
	}
	
	glGetProgramiv(program, GL_VALIDATE_STATUS, &ret);
	if (ret == 0) {
		NSLog(@"Failed to validate program");
		return;
	}
	
	glUseProgram(program);
	
	// Get the uniforms
	mvpUI = glGetUniformLocation(program, "mvp");
	colorUI = glGetUniformLocation(program, "uColor");
	textureUI = glGetUniformLocation(program, "uTexture");
	
	// Get the attributes
	positionAI = glGetAttribLocation(program, "position");
	textureCoordAI = glGetAttribLocation(program, "texCoord");
	
	NSLog(@"UI = %d %d %d   AI = %d %d", mvpUI, colorUI, textureUI, positionAI, textureCoordAI);

	GLKMatrix4 idMat = GLKMatrix4Identity;
	glUniformMatrix4fv(mvpUI, 1, GL_FALSE, idMat.m);
	glUniform4f(colorUI, 1.0f, 1.0f, 1.0f, 1.0f);

	// Create a canvas, draw all the symbols
	
}

#pragma mark -
#pragma mark Public Methods

- (void)drawText:(const char *)string origin:(NSPoint)origin size:(float)size {
	
}

@end
