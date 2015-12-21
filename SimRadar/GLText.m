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
@synthesize baseSize;
@synthesize modelViewProjection;

#pragma mark -
#pragma mark Life Cycle

- (id)initWithDevicePixelRatio:(GLfloat)ratio
{
    self = [super init];
    if (self) {
        baseSize = 72.0f;
        bitmapWidth = 1024 * ratio;
        bitmapHeight = 1024 * ratio;
        devicePixelRatio = ratio;
        bitmap = (GLubyte *)malloc(bitmapWidth * bitmapHeight * 4);
        drawAnchors = (GLTextVertex *)malloc(GLTextMaxString * 6 * sizeof(GLTextVertex));
        [self buildTexture];
    }
    return self;
}


- (id)init
{
    return [self initWithDevicePixelRatio:[[NSScreen mainScreen] backingScaleFactor]];
}


- (void)dealloc
{
    free(bitmap);
    free(drawAnchors);
    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods

- (void)buildTexture
{
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
    
    //NSLog(@"UI = %d %d %d   AI = %d %d", mvpUI, colorUI, textureUI, positionAI, textureCoordAI);
    
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
    
    // The font to use. Some parameters may need tweaking for different font.
    //    NSDictionary *labelAtts = [NSDictionary dictionaryWithObjectsAndKeys:
    //                               [NSFont fontWithName:@"Helvetica Neue Medium" size:baseSize], NSFontAttributeName,
    //                               [NSColor blueColor], NSForegroundColorAttributeName,
    //                               nil];
    NSDictionary *labelAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont systemFontOfSize:baseSize], NSFontAttributeName,
                               [NSColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f], NSForegroundColorAttributeName,
                               nil];
    
    pad = 4.0f;
    
    const CGFloat blurRadius = 3.5f * devicePixelRatio;
    const CGFloat doublePad = ceilf(pad + 2.0f * blurRadius);
    NSPoint point = NSMakePoint(0.5f + doublePad, 0.5f + doublePad);
    NSSize drawSize;
    CGFloat rowHeight = 0.0f;
    
    const float joffset = 8.0f;
    
    for (int i = 0; i < 256; i++) {
        NSString *label = [NSString stringWithFormat:@"%c", i];
        
        drawSize = [label sizeWithAttributes:labelAtts];
        
#ifdef DEBUG_GL_SPECIFIC_CHAR

        if (i == '2') {
            NSLog(@"drawSize = %.1f %.1f", drawSize.width, drawSize.height);
        }
        
#endif
        
        if (drawSize.width < devicePixelRatio) {
            symbolSize[i] = NSMakeSize(0.0f, 0.0f);
            continue;
        }
        
        if (point.x + drawSize.width + pad + doublePad > w) {
            point.x = 0.5f + doublePad;
            point.y += ceilf(rowHeight + 2.0f * pad + 1.0f);
            rowHeight = 0.0f;
        }
        
        if (i == 'j') {
            point.x += joffset;
        }
        [label drawAtPoint:point withAttributes:labelAtts];
        
        // Rectangles for letter spacing
        symbolSize[i].width = ceilf(drawSize.width);
        symbolSize[i].height = ceilf(drawSize.height);
        
        // Rectangle for drawing
        textureCoord[i].origin.x = (point.x - pad - 0.5f) / w;
        textureCoord[i].origin.y = (h - point.y + pad + 0.5f) / h;
        textureCoord[i].size.width = (symbolSize[i].width + 2.0f * pad) / w;
        textureCoord[i].size.height = (symbolSize[i].height + 2.0f * pad) / h;
        
        if (i == 'j') {
            textureCoord[i].origin.x -= joffset / w;
            textureCoord[i].size.width += joffset / w;
        }
        
#ifdef DEBUG_GL
        // Core Graphics framework uses points (not pixel)
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextSetStrokeColorWithColor(context, [NSColor redColor].CGColor);
        CGContextStrokeRect(context, NSMakeRect(textureCoord[i].origin.x * w + 0.5f,
                                                point.y - pad,
                                                textureCoord[i].size.width * w,
                                                textureCoord[i].size.height * h));
        CGContextSetStrokeColorWithColor(context, [NSColor greenColor].CGColor);
        CGContextStrokeRect(context, NSMakeRect(point.x,
                                                point.y,
                                                symbolSize[i].width,
                                                symbolSize[i].height));
#endif

        
        point.x += symbolSize[i].width + 2.0f * pad + 1.0f;
        rowHeight = MAX(rowHeight, drawSize.height);
    }
    
    [image unlockFocus];
    
    // NSImage to CIImage
    CIImage *letterMap = [[CIImage alloc] initWithBitmapImageRep:[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]];
    
    // A bunch of filtering / composing, like Photoshop
    CIImage *img;
    CIImage *result;
    CIImage *alphaMask;
    CIImage *textShadow;
    
    CIFilter *discFilter = [CIFilter filterWithName:@"CIDiscBlur"];
    CIFilter *multiplyFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
    CIFilter *sourceOverBlendFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    CIFilter *colorMatrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
    
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBiasVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:1.0f W:0.0f] forKey:@"inputRVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:1.0f W:0.0f] forKey:@"inputGVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:1.0f W:0.0f] forKey:@"inputBVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:1.0f W:0.0f] forKey:@"inputAVector"];
    [colorMatrixFilter setValue:letterMap forKey:kCIInputImageKey];
    alphaMask = [colorMatrixFilter valueForKey:kCIOutputImageKey];
    
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputRVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputGVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:1.0f] forKey:@"inputAVector"];
    [colorMatrixFilter setValue:alphaMask forKey:kCIInputImageKey];
    textShadow = [colorMatrixFilter valueForKey:kCIOutputImageKey];
    
    [discFilter setValue:[NSNumber numberWithFloat:blurRadius] forKey:kCIInputRadiusKey];
    [discFilter setValue:textShadow forKey:kCIInputImageKey];
    textShadow = [discFilter valueForKey:kCIOutputImageKey];
    
    [multiplyFilter setValue:textShadow forKey:kCIInputImageKey];
    [multiplyFilter setValue:textShadow forKey:kCIInputBackgroundImageKey];
    textShadow = [multiplyFilter valueForKey:kCIOutputImageKey];
    
    [discFilter setValue:[NSNumber numberWithFloat:0.5f * blurRadius] forKey:kCIInputRadiusKey];
    [discFilter setValue:alphaMask forKey:kCIInputImageKey];
    img = [discFilter valueForKey:kCIOutputImageKey];
    
    [sourceOverBlendFilter setValue:img forKey:kCIInputImageKey];
    [sourceOverBlendFilter setValue:textShadow forKey:kCIInputBackgroundImageKey];
    result = [sourceOverBlendFilter valueForKey:kCIOutputImageKey];
    
#ifdef DEBUG_GL
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputRVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:1.0f Z:0.0f W:0.0f] forKey:@"inputGVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:1.0f Z:0.0f W:0.0f] forKey:@"inputAVector"];
    [colorMatrixFilter setValue:letterMap forKey:kCIInputImageKey];
    img = [colorMatrixFilter valueForKey:kCIOutputImageKey];
    
    [sourceOverBlendFilter setValue:img forKey:kCIInputImageKey];
    [sourceOverBlendFilter setValue:result forKey:kCIInputBackgroundImageKey];
    result = [sourceOverBlendFilter valueForKey:kCIOutputImageKey];
    
    [colorMatrixFilter setValue:[CIVector vectorWithX:1.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputRVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputGVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithX:1.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputAVector"];
    [colorMatrixFilter setValue:letterMap forKey:kCIInputImageKey];
    img = [colorMatrixFilter valueForKey:kCIOutputImageKey];
    
    [sourceOverBlendFilter setValue:img forKey:kCIInputImageKey];
    [sourceOverBlendFilter setValue:result forKey:kCIInputBackgroundImageKey];
    result = [sourceOverBlendFilter valueForKey:kCIOutputImageKey];
#endif
    
    result = [result imageByCroppingToRect:rect];
//        result = alphaMask;
    //    result = letterMap;
    
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCIImage:result];
    memcpy(bitmap, [bitmapImageRep bitmapData], bitmapWidth * bitmapHeight * 4);
    [bitmapImageRep release];
    
    [letterMap release];
    
    [image release];
    
    [pool release];
    
    GLTextVertex pos[] = {
        {0.0f, 0.0f, 0.0f, 0.0f},
        {1.0f, 0.0f, 1.0f, 0.0f},
        {0.0f, 1.0f, 0.0f, 1.0f},
        {1.0f, 0.0f, 1.0f, 0.0f},
        {0.0f, 1.0f, 0.0f, 1.0f},
        {1.0f, 1.0f, 1.0f, 1.0f}
    };
    for (int k = 0; k < 6; k++) {
        pos[k].x = (pos[k].x * w + 10.0f) / devicePixelRatio;
        pos[k].y = (pos[k].y * h + 10.0f) / devicePixelRatio;
        pos[k].t = (1.0f - pos[k].t);
    }
    memcpy(textureAnchors, pos, 6 * sizeof(GLTextVertex));
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bitmapWidth, bitmapHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmap);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    glGenBuffers(1, vbo);
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 6 * sizeof(GLTextVertex), textureAnchors, GL_STATIC_DRAW);
    glVertexAttribPointer(positionAI, 2, GL_FLOAT, GL_FALSE, sizeof(GLTextVertex), NULL);
    glEnableVertexAttribArray(positionAI);
    glVertexAttribPointer(textureCoordAI, 2, GL_FLOAT, GL_FALSE, sizeof(GLTextVertex), (void *)(2 * sizeof(float)));
    glEnableVertexAttribArray(textureCoordAI);
    
    glUniform4f(colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    
#ifdef DEBUG_GL
    NSLog(@"GLText vao = %d  vbo = %d  program = %d", vao, vbo[0], program);
#endif
}

#pragma mark -
#pragma mark Public Methods

- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale {
    [self drawText:string origin:origin scale:scale red:1.0f green:1.0f blue:1.0f alpha:1.0f align:GLTextAlignmentLeft];
}

- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale align:(GLTextAlignment)align {
    [self drawText:string origin:origin scale:scale red:1.0f green:1.0f blue:1.0f alpha:1.0f align:align];
}

- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    [self drawText:string origin:origin scale:scale red:red green:green blue:blue alpha:alpha align:GLTextAlignmentLeft];
}

- (void)drawText:(const char *)string origin:(NSPoint)origin scale:(float)scale red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha align:(GLTextAlignment)align {
    // Build the text origins
    int i, k;
    NSPoint point = origin;
    int count = MIN(GLTextMaxString, (int)strlen(string));
    
    if (align != GLTextAlignmentLeft) {
        CGFloat totalWidth = 0.0f;
        for (k=0; k<count; k++) {
            totalWidth += symbolSize[string[k]].width;
        }
        totalWidth *= scale;
        
        if (align == GLTextAlignmentRight) {
            point.x -= totalWidth;
        } else {
            point.x -= 0.5f * totalWidth;
        }
    }
    
    for (k=0; k<count; k++) {
        i = string[k];
        
        drawAnchors[6 * k    ].x = point.x;
        drawAnchors[6 * k    ].y = point.y;
        drawAnchors[6 * k    ].s = textureCoord[i].origin.x;
        drawAnchors[6 * k    ].t = textureCoord[i].origin.y;
        
        drawAnchors[6 * k + 1].x = point.x + (symbolSize[i].width + 2.0f * pad) * scale;
        drawAnchors[6 * k + 1].y = point.y;
        drawAnchors[6 * k + 1].s = textureCoord[i].origin.x + textureCoord[i].size.width;
        drawAnchors[6 * k + 1].t = textureCoord[i].origin.y;
        
        drawAnchors[6 * k + 2].x = point.x;
        drawAnchors[6 * k + 2].y = point.y + (symbolSize[i].height + 2.0f * pad) * scale;
        drawAnchors[6 * k + 2].s = textureCoord[i].origin.x;
        drawAnchors[6 * k + 2].t = textureCoord[i].origin.y - textureCoord[i].size.height;
        
        drawAnchors[6 * k + 3] = drawAnchors[6 * k + 1];
        drawAnchors[6 * k + 4] = drawAnchors[6 * k + 2];
        
        drawAnchors[6 * k + 5].x = drawAnchors[6 * k + 1].x;
        drawAnchors[6 * k + 5].y = drawAnchors[6 * k + 2].y;
        drawAnchors[6 * k + 5].s = drawAnchors[6 * k + 1].s;
        drawAnchors[6 * k + 5].t = drawAnchors[6 * k + 2].t;
        
        point.x += symbolSize[i].width * scale;
    }
    
    glBindVertexArray(vao);
    glUseProgram(program);
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, count * 6 * sizeof(GLTextVertex), drawAnchors, GL_STATIC_DRAW);
    glUniformMatrix4fv(mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform4f(colorUI, red, green, blue, alpha);
    glBindTexture(GL_TEXTURE_2D, texture);
    glDrawArrays(GL_TRIANGLES, 0, count * 6);
}


- (void)showTextureMap {
    glBindVertexArray(vao);
    glUseProgram(program);
    glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 6 * sizeof(GLTextVertex), textureAnchors, GL_STATIC_DRAW);
    glUniformMatrix4fv(mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform4f(colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBindTexture(GL_TEXTURE_2D, texture);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
