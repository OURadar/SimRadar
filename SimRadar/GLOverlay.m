//
//  GLOverlay.m
//
//  Theory of Operations
//
//  - Instantiate the class object at anytime since it is Core Graphic based
//  - Draw / update to the CG context after initialization (separate thread)
//  - During OpenGL rendering, call the method updateGLTexture
//  - Then, call the method drawAtRect:, which draws the rectangular overlay
//
//  Created by Boon Leng Cheong on 12/26/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "GLOverlay.h"

@implementation GLOverlay

- (id)initWithSize:(NSSize)size {
    self = [super init];
    if (self) {
        // Initialize a Core-graphic context of given size
        devicePixelRatio = [[NSScreen mainScreen] backingScaleFactor];
        bitmapWidth = 1024 * devicePixelRatio;
        bitmapHeight = 1024 * devicePixelRatio;
        bitmap = (GLubyte *)malloc(bitmapWidth * bitmapHeight * 4);
        
        
    }
    return self;
}

- (int)updateGLTexture {
    // Include vertex & fragment shader GLSL here
    return 0;
}


- (void)drawSomething {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // Create a bitmap canvas, draw all the symbols
    const float w = (float)bitmapWidth / devicePixelRatio;
    const float h = (float)bitmapHeight / devicePixelRatio;
    
    // Use Core Graphics to draw a texture atlas
    CGRect rect = CGRectMake(0.0f, 0.0f, (CGFloat)bitmapWidth, (CGFloat)bitmapHeight);
    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
    [image lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    // Black background
    CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0f);
    
    NSDictionary *labelAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont systemFontOfSize:10.0f], NSFontAttributeName,
                               [NSColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
                               nil];

    NSString *label = @"Hello There";
    
    [label sizeWithAttributes:labelAtts];
    
    [label drawAtPoint:CGPointMake(10.0, 10.0) withAttributes:labelAtts];


    [pool release];
}
- (void)drawAtRect:(NSRect)rect {
    
}

- (void)buildTexture {
    GLint ret;
    GLuint shader;
    
    // Create a program and attach a vertex shader and a fragment shader
    program = glCreateProgram();
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    // In-line source code of the vertex shader
    char *vertexShaderSource =
    "#version 410\n"
    "uniform mat4 uMVP;\n"
    "uniform vec4 uColor;\n"
    "layout(location = 0) in vec3 position;\n"
    "layout(location = 1) in vec2 texCoordV;\n"
    "out vec4 color;\n"
    "out vec2 texCoord;\n"
    "void main() {\n"
    "    gl_Position = uMVP * vec4(position, 1.0);\n"
    "    texCoord = texCoordV;\n"
    "    color = uColor;\n"
    "}\n";
    
    // In-line source code of the fragment shader
    char *fragmentShaderSource =
    "#version 410\n"
    "in vec4 color;\n"
    "in vec2 texCoord;\n"
    "out vec4 fragColor;\n"
    "uniform sampler2D uTexture;\n"
    "void main() {\n"
    "    fragColor = color * texture(uTexture, texCoord);\n"
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
    
    // Link and Validate
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
    
    // Now, we can use it
    glUseProgram(program);

    // Get the uniforms
    mvpUI = glGetUniformLocation(program, "uMVP");
    colorUI = glGetUniformLocation(program, "uColor");
    textureUI = glGetUniformLocation(program, "uTexture");
    
    // Get the attributes
    positionAI = glGetAttribLocation(program, "position");
    textureCoordAI = glGetAttribLocation(program, "texCoordV");
}


@end
