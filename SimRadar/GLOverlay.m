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

// Some private functions
@interface GLOverlay()
- (void)buildShaders;
@end


@implementation GLOverlay

@synthesize modelViewProjection;

- (id)initWithRect:(NSRect)rect {
    self = [super init];
    if (self) {
        // Initialize a Core-graphic context of given size
        drawRect = rect;
        devicePixelRatio = [[NSScreen mainScreen] backingScaleFactor];
        bitmapWidth = rect.size.width * devicePixelRatio;
        bitmapHeight = rect.size.height * devicePixelRatio;
        bitmap = (GLubyte *)malloc(bitmapWidth * bitmapHeight * 4);
                
        [self buildShaders];
        
//        [self beginCanvas];
//        [self drawSomething];
//        [self endCanvas];
    }
    return self;
}


- (id)init {
    return [self initWithRect:NSMakeRect(20.0f, 60.0f, 380.0f, 405.0f)];
}


- (void)dealloc {
    free(bitmap);
    [super dealloc];
}


- (int)updateGLTexture {
    // Include vertex & fragment shader GLSL here
    return 0;
}


- (void)beginCanvas {
    // Create a separate pool for resources in this class so all of them are released when we are done drawing
    drawPool = [NSAutoreleasePool new];

    // Use Core Graphics to draw a texture atlas
    CGRect rect = CGRectMake(0.0f, 0.0f, drawRect.size.width, drawRect.size.height);
    image = [[NSImage alloc] initWithSize:rect.size];
    [image lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    NSColor *color1 = [NSColor colorWithWhite:0.0f alpha:0.65f];
    NSColor *color2 = [NSColor colorWithRed:1.0f green:0.8f blue:0.2f alpha:1.0f];
    NSColor *color3 = [NSColor colorWithRed:0.2f green:0.9f blue:1.0f alpha:1.0f];

    // Black translucent background
    rect = CGRectMake(0.0f, 0.0f, drawRect.size.width, drawRect.size.height - 13.0f);

    CGContextSetFillColorWithColor(context, color1.CGColor);
    CGContextFillRect(context, rect);

    rect = CGRectInset(rect, 1.5f, 1.5f);
//    CGContextSetStrokeColorWithColor(context, [NSColor whiteColor].CGColor);
//    CGContextSetLineWidth(context, 1.0f);
//    CGContextStrokeRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, color2.CGColor);
    CGContextStrokeRect(context, rect);
    
    NSDictionary *atts = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSFont boldSystemFontOfSize:20.0f], NSFontAttributeName,
                          color2, NSForegroundColorAttributeName,
                          nil];
    NSString *title = @"Basic Parameters";
    
    CGSize size = [title sizeWithAttributes:atts];
    
    rect = CGRectMake(20.0f, drawRect.size.height - size.height - 5.0f, ceilf(size.width), ceilf(size.height));
    rect = CGRectInset(rect, -8.0f, -4.0f);
    CGContextSetFillColorWithColor(context, color1.CGColor);
    CGContextClearRect(context, rect);
    CGContextFillRect(context, rect);

    [title drawAtPoint:CGPointMake(20.0f, drawRect.size.height - size.height - 2.0f) withAttributes:atts];
}

- (void)endCanvas {
//    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    [image unlockFocus];
    
    // A bunch of filtering / composing, like Photoshop can be inserted here
    
    CIImage *result = [[CIImage alloc] initWithBitmapImageRep:[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]];
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCIImage:result];
    memcpy(bitmap, [bitmapImageRep bitmapData], bitmapWidth * bitmapHeight * 4);
    [bitmapImageRep release];
    [result release];
    
    // All the CG resources are no longer needed from here on
    [drawPool release];
    
    // Allocate the texture to GPU
    float pos[] = {
        0.0f, 0.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        1.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f
    };
    for (int k = 0; k < 24; k += 4) {
        pos[k    ] = pos[k    ] * drawRect.size.width + drawRect.origin.x;        // x
        pos[k + 1] = pos[k + 1] * drawRect.size.height + drawRect.origin.y;       // y
        pos[k + 3] = (1.0f - pos[k + 3]);                                         // t
    }
    memcpy(textureAnchors, pos, 24 * sizeof(float));
    
    canvasNeedsUpdate = true;
}


- (void)drawSomething {
    NSDictionary *labelAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont systemFontOfSize:18.0f], NSFontAttributeName,
                               [NSColor colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
                               nil];

    NSString *label = @"Hello There\nI'm the new overlay for the renderer.";
    
    [label sizeWithAttributes:labelAtts];
    
    [label drawAtPoint:CGPointMake(10.0, 10.0) withAttributes:labelAtts];
}


- (void)draw {
    glBindVertexArray(vao);
    glUseProgram(program);
    if (canvasNeedsUpdate) {
        canvasNeedsUpdate = false;
        if (textureName) {
            glDeleteTextures(1, &textureName);
        }
        glGenTextures(1, &textureName);
        glBindTexture(GL_TEXTURE_2D, textureName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bitmapWidth, bitmapHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmap);
        glGenerateMipmap(GL_TEXTURE_2D);
        
        if (vbo[0]) {
            glDeleteBuffers(1, vbo);
        }
        glGenBuffers(1, vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, 24 * sizeof(float), textureAnchors, GL_STATIC_DRAW);
        glVertexAttribPointer(positionAI, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), NULL);
        glEnableVertexAttribArray(positionAI);
        glVertexAttribPointer(textureCoordAI, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)(2 * sizeof(float)));
        glEnableVertexAttribArray(textureCoordAI);
    }
    glUniformMatrix4fv(mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glBindTexture(GL_TEXTURE_2D, textureName);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


- (void)buildShaders {
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
    "layout(location = 0) in vec3 position;\n"
    "layout(location = 1) in vec2 texCoordV;\n"
    "out vec4 color;\n"
    "out vec2 texCoord;\n"
    "void main() {\n"
    "    gl_Position = uMVP * vec4(position, 1.0);\n"
    "    texCoord = texCoordV;\n"
    "}\n";
    
    // In-line source code of the fragment shader
    char *fragmentShaderSource =
    "#version 410\n"
    "in vec2 texCoord;\n"
    "out vec4 fragColor;\n"
    "uniform sampler2D uTexture;\n"
    "void main() {\n"
    "    fragColor = texture(uTexture, texCoord);\n"
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

    // Get the uniforms and attributes
    mvpUI = glGetUniformLocation(program, "uMVP");
    positionAI = glGetAttribLocation(program, "position");
    textureCoordAI = glGetAttribLocation(program, "texCoordV");
}


@end
