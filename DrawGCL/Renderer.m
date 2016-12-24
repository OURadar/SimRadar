//
//  Renderer.m
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import "Renderer.h"

@interface Renderer ()

- (void)makePrimitives;
- (void)attachShader:(NSString *)filename toProgram:(GLuint)program;
- (RenderResource)createRenderResourceFromVertexShader:(NSString *)vShader fragmentShader:(NSString *)fShader;
- (RenderResource)createRenderResourceFromProgram:(GLuint)program;
- (void)allocateFBO;
- (void)allocateVBO;
- (GLKTextureInfo *)loadTexture:(NSString *)filename;
- (void)measureFPS;
- (void)validateLineRenderer:(GLuint)number;
- (void)addLinesToLineRenderer:(GLfloat *)lines number:(GLuint)number;

@end

@implementation Renderer

@synthesize delegate;
@synthesize resetRange;
@synthesize resetModelRotate;
@synthesize width, height;

#pragma mark -
#pragma mark Properties

- (void)setSize:(CGSize)size
{
    width = (GLsizei)size.width;
    height = (GLsizei)size.height;
    
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
    
    aspectRatio = size.width / size.height;
    projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, RENDERER_NEAR_RANGE, RENDERER_FAR_RANGE);

    viewParametersNeedUpdate = true;
    fboNeedsUpdate = true;
}

- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size
{
    NSLog(@"grid @ (%.1f, %.1f, %.1f)  (%.1f, %.1f, %.1f)", origin[0], origin[1], origin[2], size[0], size[1], size[2]);
    
    GLfloat *pos = lineRenderer.positions + lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid] * 4;
    
    *pos++ = origin[0];
    *pos++ = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    
    *pos++  = origin[0];
    *pos++  = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2];
    *pos++ = 1.0f;
    *pos++ = origin[0] + size[0];
    *pos++ = origin[1] + size[1];
    *pos++ = origin[2] + size[2];
    *pos++ = 1.0f;
    
    vbosNeedUpdate = true;
}

- (void)setCenterPoisitionX:(GLfloat)x y:(GLfloat)y z:(GLfloat)z {
    modelCenter.x = x;
    modelCenter.y = y;
    modelCenter.z = z;
}

- (void)setColormapTitle:(char *)title tickLabels:(NSArray *)labels positions:(GLfloat *)positions; {
    colorbarTitle = title;
    colorbarTickPositions = positions;
    colorbarTickCount = (int)[labels count];
    for (int k = 0; k < colorbarTickCount; k++) {
        NSString *label = [labels objectAtIndex:k];
        strncpy(colorbarTickLabels[k], label.UTF8String, 16);
    }
    overlayNeedsUpdate = true;
}

#pragma mark -
#pragma mark Initializations & Deallocation

- (id)initWithDevicePixelRatio:(GLfloat)pixelRatio {
    self = [super init];
    if (self) {
        // View size in pixel counts
        width = 1;
        height = 1;
        spinModel = 5;
        aspectRatio = 1.0f;
        
        iframe = -1;
        
        resetRange = 5000.0f;
        resetModelRotate = GLKMatrix4Identity;
        //resetModelRotate = GLKMatrix4MakeRotation(1.0, 0.0f, 1.0f, 1.0f);
        
        hudModelViewProjection = GLKMatrix4Identity;
        
        // Add device pixel ratio here
        devicePixelRatio = pixelRatio;
        NSLog(@"Renderer initialized with pixel ratio = %.1f", devicePixelRatio);
        
        colorbarTitle = statusMessage[9];
        sprintf(statusMessage[9], "Nothing");
        
        [self validateLineRenderer:0];

        // View parameters
        [self resetViewParameters];
    }
    return self;
}


- (id)init {
    return [self initWithDevicePixelRatio:1.0f];
}


- (void)dealloc
{
    [textRenderer release];
    [tTextRenderer release];
    [fwTextRenderer release];
    
    if (lineRenderer.positions != NULL) {
        free(lineRenderer.positions);
        free(lineRenderer.segmentOrigins);
        free(lineRenderer.segmentLengths);
    }
    if (instancedGeometryRenderer.positions != NULL) {
        free(instancedGeometryRenderer.positions);
    }

    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods

- (void)attachShader:(NSString *)filename toProgram:(GLuint)program;
{
    if (program == 0) {
        NSLog(@"attachShader failed without program.");
        return;
    }
    
    GLenum shaderType = 0;
    
    // Get the shader type from filename suffix
    char *suffix = (char *)filename.UTF8String;
    suffix += strlen(suffix) - 3;
    
    if (!strncmp(suffix, "vsh", 3)) {
        shaderType = GL_VERTEX_SHADER;
    } else if (!strncmp(suffix, "fsh", 3)) {
        shaderType = GL_FRAGMENT_SHADER;
    } else {
        NSLog(@"Unknown shader type.");
        return;
    }
    
    //NSLog(@"%@ : %s", filename, suffix);
    
    // Load and setup shaders
    NSData *sourceData = [NSData dataWithContentsOfFile:filename];
    
    // Version string '#version 150\n' occupies 13 bytes, pad another one.
    GLchar *sourceString = malloc(sourceData.length + 14);
    
    // Make the vertex source using the supplied GLSL version
    snprintf(sourceString, sourceData.length + 14, "#version %.0f\n%s", GLSLVersion * 100.0f, (char *)sourceData.bytes);
    
    //printf("-----------------\n%s\n-----------------\n", sourceString);
    
    GLint iparam;
    
    GLuint shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, (const GLchar **)&sourceString, NULL);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &iparam);
    
    if (iparam) {
        GLchar *log = (GLchar *)malloc(iparam);
        glGetShaderInfoLog(shader, iparam, &iparam, log);
        NSLog(@"%s Shader compile log:%s",
              shaderType==GL_VERTEX_SHADER?"Vertex":
              (shaderType==GL_FRAGMENT_SHADER?"Fragment":"Unknown"),
              log);
        free(log);
    }
    
    free(sourceString);
    
    // Attach shader to the program
    glAttachShader(program, shader);
    
    // Delete it now since it has been attached
    glDeleteShader(shader);
}


- (void)getUniformsAndAttributes:(RenderResource *)resource
{
    const char verb = 0;
    
    glUseProgram(resource->program);
    
    // Get MV matrix location
    resource->mvUI = glGetUniformLocation(resource->program, "modelViewMatrix");
    if (resource->mvUI >= 0) {
        glUniformMatrix4fv(resource->mvUI, 1, GL_FALSE, GLKMatrix4Identity.m);
    } else if (verb) {
        NSLog(@"%s shader has no modelView Matrix %d", resource->vShaderName, resource->mvUI);
    }
    
    // Get MVP matrix location
    resource->mvpUI = glGetUniformLocation(resource->program, "modelViewProjectionMatrix");
    if (resource->mvpUI >= 0) {
        glUniformMatrix4fv(resource->mvpUI, 1, GL_FALSE, GLKMatrix4Identity.m);
    } else if (verb) {
        NSLog(@"%s shader has no modelViewProjection Matrix %d", resource->vShaderName, resource->mvpUI);
    }
    
    // Get color location
    resource->colorUI = glGetUniformLocation(resource->program, "drawColor");
    if (resource->colorUI >= 0) {
        glUniform4f(resource->colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    } else if (verb) {
        NSLog(@"%s shader has no drawColor %d", resource->vShaderName, resource->colorUI);
    }
    
    // Get size location
    resource->sizeUI = glGetUniformLocation(resource->program, "drawSize");
    if (resource->sizeUI >= 0) {
        //NSLog(@"%@ has drawSize", vShader);
        glUniform4f(resource->sizeUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }
    
    // Use drawTemplate1, drawTemplate2, etc. for various drawing shapes; All to TEXTURE0
    if ((resource->textureUI = glGetUniformLocation(resource->program, "drawTemplate1")) >= 0) {
        //resource->texture = [self loadTexture:@"texture_32.png"];
        //resource->texture = [self loadTexture:@"sphere1.png"];
        resource->texture = [self loadTexture:@"disc64.png"];
        resource->textureID = [resource->texture name];
        glUniform1i(resource->textureUI, 0);
    } else if ((resource->textureUI = glGetUniformLocation(resource->program, "drawTemplate2")) >= 0) {
        //resource->texture = [self loadTexture:@"sphere64.png"];
        resource->texture = [self loadTexture:@"spot64.png"];
        //resource->texture = [self loadTexture:@"disc64.png"];
        resource->textureID = [resource->texture name];
        glUniform1i(resource->textureUI, 0);
    } else if ((resource->textureUI = glGetUniformLocation(resource->program, "diffuseTexture")) >= 0) {
        resource->texture = [self loadTexture:@"colormap.png"];
        resource->textureID = [resource->texture name];
        glUniform1i(resource->textureUI, 0);
    }
    
    // Get colormap location
    resource->colormapUI = glGetUniformLocation(resource->program, "colormapTexture");
    if (resource->colormapUI >= 0) {
        resource->colormap = [self loadTexture:@"colormap.png"];
        resource->colormapID = [resource->colormap name];
        resource->colormapCount = resource->colormap.height;
        resource->colormapIndex = RENDERER_DEFAULT_BODY_COLOR_INDEX;
        glUniform1i(resource->colormapUI, 1);  // TEXTURE1 for colormap
        if (verb) {
            NSLog(@"Colormap has %d maps, each with %d colors", resource->colormap.height, resource->colormap.width);
        }
    }
    
    // Get ping pong location: Some shaders have a ping-pong mode of operations
    resource->pingPongUI = glGetUniformLocation(resource->program, "pingPong");
    if (resource->pingPongUI >= 0) {
        glUniform1i(resource->pingPongUI, 1);
    }
    
    // Get attributes
    resource->colorAI = glGetAttribLocation(resource->program, "inColor");
    resource->positionAI = glGetAttribLocation(resource->program, "inPosition");
    resource->rotationAI = glGetAttribLocation(resource->program, "inRotation");
    resource->quaternionAI = glGetAttribLocation(resource->program, "inQuaternion");
    resource->translationAI = glGetAttribLocation(resource->program, "inTranslation");
    resource->textureCoordAI = glGetAttribLocation(resource->program, "inTextureCoord");
    
    // Others
    resource->modelViewProjection = GLKMatrix4Identity;
    resource->modelViewProjectionOffOne = GLKMatrix4Identity;
    resource->modelViewProjectionOffTwo = GLKMatrix4Identity;
}


- (RenderResource)createRenderResourceFromProgram:(GLuint)program
{
    RenderResource resource;
    
    memset(&resource, 0, sizeof(RenderResource));
    
    glGenVertexArrays(1, &resource.vao);
    glBindVertexArray(resource.vao);
    
    resource.program = program;
    
    [self getUniformsAndAttributes:&resource];
    
    return resource;
}


- (RenderResource)createRenderResourceFromVertexShader:(NSString *)vShader fragmentShader:(NSString *)fShader
{
    GLint param;
    
    RenderResource resource;
    
    memset(&resource, 0, sizeof(RenderResource));
    
    glGenVertexArrays(1, &resource.vao);
    glBindVertexArray(resource.vao);
    
    resource.program = glCreateProgram();
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"Shaders" ofType:nil];
    if (vShader) {
        sprintf(resource.vShaderName, "_clone_");
        [self attachShader:[shaderPath stringByAppendingString:[NSString stringWithFormat:@"/%@", vShader]] toProgram:resource.program];
    }
    if (fShader) {
        sprintf(resource.fShaderName, "_clone_");
        [self attachShader:[shaderPath stringByAppendingString:[NSString stringWithFormat:@"/%@", fShader]] toProgram:resource.program];
    }
    
    // Link
    glLinkProgram(resource.program);
    
    glGetProgramiv(resource.program, GL_INFO_LOG_LENGTH, &param);
    if (param) {
        GLchar *log = (GLchar *)malloc(param);
        glGetProgramInfoLog(resource.program, param, &param, log);
        NSLog(@"Link return:%s", log);
        free(log);
    }
    
    glGetProgramiv(resource.program, GL_LINK_STATUS, &param);
    if (param == 0) {
        NSLog(@"Failed to link program");
        return resource;
    }
    
    glValidateProgram(resource.program);
    glGetProgramiv(resource.program, GL_INFO_LOG_LENGTH, &param);
    if (param) {
        GLchar *log = (GLchar *)malloc(param);
        glGetProgramInfoLog(resource.program, param, &param, log);
        NSLog(@"Program validate:%s", log);
        free(log);
    }
    
    glGetProgramiv(resource.program, GL_VALIDATE_STATUS, &param);
    if (param == 0) {
        NSLog(@"Failed to validate program");
        return resource;
    }
    
    [self getUniformsAndAttributes:&resource];
    
    return resource;
}


- (GLKTextureInfo *)loadTexture:(NSString *)filename
{
    NSDictionary* options = @{[NSNumber numberWithBool:YES] : GLKTextureLoaderOriginBottomLeft};
    
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Images" ofType:nil];
    GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, filename] options:options error:&error];
    if (texture == nil)
    {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
#ifdef DEBUG_GL
    else
    {
        NSLog(@"Texture with %d x %d pixels", texture.width, texture.height);
    }
#endif
    
    return texture;
}

- (void)makePrimitives
{
    // Basic 3D / 2D overlays
    
    [self validateLineRenderer:0];
    
    // lineRenderer is populated with basic segments:
    // 0 - a basic geometry for a rectangle: 4 for shaded area, 5 for outline
    // 1 - the simulation box, fixed with 24 vertices
    // 2 - anchor lines outlining a radar scan domain
    // 3 - etc.
    lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle] = 0;
    lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle] = 9;
    lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid] = 10;
    lineRenderer.segmentLengths[RendererLineSegmentSimulationGrid] = 24;
    lineRenderer.segmentNextOrigin = 34;
    lineRenderer.count = 2;
    
    GLfloat rect[] = {
        0.0f, 0.0f, 0.0f, 1.0f,   // First part is for the dark area
        0.0f, 1.0f, 0.0f, 1.0f,
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 1.0f,   // Second part is for the outline, z-component really doesn't matter
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };
    memcpy(lineRenderer.positions, rect, 9 * 4 * sizeof(GLfloat));
    
    // Instancing primitives
    
    GLfloat *pos;
    RenderPrimitive *prim;
    
    // Leaf
    
    prim = &primitives[0];
    pos = prim->vertices;
    pos[0]  =  0.0f;   pos[1]  =  0.0f;   pos[2]  =  1.0f;   pos[3]  = 0.0f;
    pos[4]  =  0.0f;   pos[5]  =  0.0f;   pos[6]  = -1.0f;   pos[7]  = 0.0f;
    pos[8]  =  0.0f;   pos[9]  = -2.0f;   pos[10] =  0.0f;   pos[11] = 0.0f;
    pos[12] =  0.0f;   pos[13] =  1.0f;   pos[14] =  0.0f;   pos[15] = 0.0f;
    pos[16] = -0.5f;   pos[17] =  1.0f;   pos[18] =  0.0f;   pos[19] = 0.0f;
    pos[20] =  0.0f;   pos[21] =  0.0f;   pos[22] =  0.0f;   pos[23] = 0.0f;
    prim->vertexSize = 24 * sizeof(GLfloat);
    for (int i = 0; i < 24; i++) {
        pos[i] *= 5.5f;
    }
    prim->instanceSize = 7;
    GLuint ind0[] = {5, 1, 2, 0, 5, 3, 4};
    memcpy(prim->indices, ind0, 7 * sizeof(GLuint));
    prim->drawMode = GL_LINE_STRIP;
    
    
    // Plate
    
    prim = &primitives[1];
    pos = prim->vertices;
    pos[0]  = -1.0f;   pos[1]  = -1.0f;   pos[2]  = -1.0f;   pos[3]  = 0.0f;
    pos[4]  =  1.0f;   pos[5]  = -1.0f;   pos[6]  = -1.0f;   pos[7]  = 0.0f;
    pos[8]  = -1.0f;   pos[9]  =  1.0f;   pos[10] = -1.0f;   pos[11] = 0.0f;
    pos[12] =  1.0f;   pos[13] =  1.0f;   pos[14] = -1.0f;   pos[15] = 0.0f;
    pos[16] = -1.0f;   pos[17] = -1.0f;   pos[18] =  1.0f;   pos[19] = 0.0f;
    pos[20] =  1.0f;   pos[21] = -1.0f;   pos[22] =  1.0f;   pos[23] = 0.0f;
    pos[24] = -1.0f;   pos[25] =  1.0f;   pos[26] =  1.0f;   pos[27] = 0.0f;
    pos[28] =  1.0f;   pos[29] =  1.0f;   pos[30] =  1.0f;   pos[31] = 0.0f;
    for (int i = 0; i < 8; i++) {
        pos[4 * i    ] *= 1.0f;
        pos[4 * i + 1] *= 6.0f;
        pos[4 * i + 2] *= 12.0f;
    }
    prim->vertexSize = 32 * sizeof(GLfloat);
    GLuint ind1[] = {
        0, 1, 1, 3, 3, 2, 2, 0,
        4, 5, 5, 7, 7, 6, 6, 4,
        0, 4, 1, 5, 3, 7, 2, 6
    };
    prim->instanceSize = sizeof(ind1) / sizeof(GLuint);
    memcpy(prim->indices, ind1, prim->instanceSize * sizeof(GLuint));
    prim->drawMode = GL_LINES;
    
    
    // Rectangular
    
    prim = &primitives[2];
    pos = prim->vertices;
    pos[0]  = -1.0f;   pos[1]  = -1.0f;   pos[2]  = -1.0f;   pos[3]  = 0.0f;
    pos[4]  =  1.0f;   pos[5]  = -1.0f;   pos[6]  = -1.0f;   pos[7]  = 0.0f;
    pos[8]  = -1.0f;   pos[9]  =  1.0f;   pos[10] = -1.0f;   pos[11] = 0.0f;
    pos[12] =  1.0f;   pos[13] =  1.0f;   pos[14] = -1.0f;   pos[15] = 0.0f;
    pos[16] = -1.0f;   pos[17] = -1.0f;   pos[18] =  1.0f;   pos[19] = 0.0f;
    pos[20] =  1.0f;   pos[21] = -1.0f;   pos[22] =  1.0f;   pos[23] = 0.0f;
    pos[24] = -1.0f;   pos[25] =  1.0f;   pos[26] =  1.0f;   pos[27] = 0.0f;
    pos[28] =  1.0f;   pos[29] =  1.0f;   pos[30] =  1.0f;   pos[31] = 0.0f;
    for (int i = 0; i < 8; i++) {
        pos[4 * i    ] *= 6.0f;
        pos[4 * i + 1] *= 3.0f;
        pos[4 * i + 2] *= 3.0f;
    }
    prim->vertexSize = 32 * sizeof(GLfloat);
    GLuint ind2[] = {
        0, 1, 1, 3, 3, 2, 2, 0,
        4, 5, 5, 7, 7, 6, 6, 4,
        0, 4, 1, 5, 3, 7, 2, 6
    };
    prim->instanceSize = sizeof(ind2) / sizeof(GLuint);
    memcpy(prim->indices, ind2, prim->instanceSize * sizeof(GLuint));
    prim->drawMode = GL_LINES;
    
    // Stick
    
    prim = &primitives[3];
    pos = prim->vertices;
    pos[0]  = -1.0f;   pos[1]  = -1.0f;   pos[2]  = -1.0f;   pos[3]  = 0.0f;
    pos[4]  =  1.0f;   pos[5]  = -1.0f;   pos[6]  = -1.0f;   pos[7]  = 0.0f;
    pos[8]  = -1.0f;   pos[9]  =  1.0f;   pos[10] = -1.0f;   pos[11] = 0.0f;
    pos[12] =  1.0f;   pos[13] =  1.0f;   pos[14] = -1.0f;   pos[15] = 0.0f;
    pos[16] = -1.0f;   pos[17] = -1.0f;   pos[18] =  1.0f;   pos[19] = 0.0f;
    pos[20] =  1.0f;   pos[21] = -1.0f;   pos[22] =  1.0f;   pos[23] = 0.0f;
    pos[24] = -1.0f;   pos[25] =  1.0f;   pos[26] =  1.0f;   pos[27] = 0.0f;
    pos[28] =  1.0f;   pos[29] =  1.0f;   pos[30] =  1.0f;   pos[31] = 0.0f;
    pos[32] =  0.0f;   pos[33] = -1.3f;   pos[34] =  0.0f;   pos[35] = 0.0f;
    pos[36] =  0.0f;   pos[37] =  1.1f;   pos[38] =  0.0f;   pos[39] = 0.0f;
    for (int i = 0; i < 10; i++) {
        pos[4 * i    ] *= 0.4f;
        pos[4 * i + 1] *= 8.0f;
        pos[4 * i + 2] *= 1.0f;
    }
    prim->vertexSize = 40 * sizeof(GLfloat);
    GLuint ind3[] = {
        0, 1, 1, 3, 3, 2, 2, 0,
        4, 5, 5, 7, 7, 6, 6, 4,
        0, 4, 1, 5, 3, 7, 2, 6,
        0, 8, 4, 8, 5, 8, 1, 8,
        2, 9, 3, 9, 7, 9, 6, 9
    };
    prim->instanceSize = sizeof(ind3) / sizeof(GLuint);
    memcpy(prim->indices, ind3, prim->instanceSize * sizeof(GLuint));
    prim->drawMode = GL_LINES;
}

- (void)measureFPS {
    int otic = itic;
    tics[itic] = [NSDate timeIntervalSinceReferenceDate];
    itic = itic == RENDERER_TIC_COUNT - 1 ? 0 : itic + 1;
    fps = (float)(RENDERER_TIC_COUNT - 1) / (tics[otic] - tics[itic]);
    sprintf(fpsString, "%c%.0f FPS", (iframe / 40) % 2 == 0 ? '_' : ' ', fps);
}

- (void)updateViewParameters {
    
    #ifdef DEBUG_INTERACTION
    NSLog(@"updateViewParameters:");
    #endif
    
    GLfloat near = 2.0f / range * modelCenter.y;
    
    unitsPerPixel = range / height / devicePixelRatio;
    pixelsPerUnit = 1.0f / unitsPerPixel;
    
    GLKMatrix4 mat;
    
    // Finally, world's z-axis (up) should be antenna's y-axis (up)
    modelView = GLKMatrix4MakeTranslation(0.0f, 0.0f, -modelCenter.y);
    modelView = GLKMatrix4Multiply(modelView, modelRotate);
    modelView = GLKMatrix4Translate(modelView, -modelCenter.x, -modelCenter.z, modelCenter.y);
    modelView = GLKMatrix4RotateX(modelView, -M_PI_2);
    
    projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, MIN(RENDERER_NEAR_RANGE, near), RENDERER_FAR_RANGE);
    modelViewProjection = GLKMatrix4Multiply(projection, modelView);
    
    GLfloat s = roundf(MAX(height * 0.25f, width * 0.2f));
    hudSize = CGSizeMake(s, s);
    hudOrigin = CGPointMake(width - hudSize.width - 30.5f, height - hudSize.height - 35.0f);
    hudProjection = GLKMatrix4MakeOrtho(0.0f, width, 0.0f, height, 0.0f, 1.0f);
    mat = GLKMatrix4MakeTranslation(hudOrigin.x, hudOrigin.y, 0.0f);
    mat = GLKMatrix4Scale(mat, hudSize.width, hudSize.height, 1.0f);
    hudModelViewProjection = GLKMatrix4Multiply(hudProjection, mat);
    
    float cx = roundf(0.25f * width);
    float cy = 45.0f;
    float cw = roundf(0.5f * width);
    float ch = 20.0f;
    
    mat = GLKMatrix4MakeTranslation(cx, cy, 0.0f);
    mat = GLKMatrix4Scale(mat, cw, ch, 1.0f);
    meshRenderer.modelViewProjection = GLKMatrix4Multiply(hudProjection, mat);
    
    mat = GLKMatrix4MakeTranslation(cx - 0.5f, cy - 0.5f, 0.0f);
    mat = GLKMatrix4Scale(mat, cw + 1.0f, ch + 1.0f, 1.0f);
    meshRenderer.modelViewProjectionOffOne = GLKMatrix4Multiply(hudProjection, mat);
    
    mat = GLKMatrix4MakeTranslation(cx - 1.5f, cy - 1.5f, 0.0f);
    mat = GLKMatrix4Scale(mat, cw + 3.0f, ch + 3.0f, 1.0f);
    meshRenderer.modelViewProjectionOffTwo = GLKMatrix4Multiply(hudProjection, mat);
    
    frameRenderer.modelViewProjection = GLKMatrix4MakeOrtho(0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f);
    
    mat = GLKMatrix4MakeTranslation(0.6f, 0.0f, 0.0f);
    mat = GLKMatrix4Scale(mat, 0.4f, 0.4f, 1.0f);
    frameRenderer.modelViewProjectionOffOne = GLKMatrix4Multiply(frameRenderer.modelViewProjection, mat);
    
    [textRenderer setModelViewProjection:hudProjection];
    [tTextRenderer setModelViewProjection:hudProjection];
    [fwTextRenderer setModelViewProjection:hudProjection];
}

- (void)allocateVBO {
    int i;

    // Mesh: colorbar
    glBindVertexArray(meshRenderer.vao);
    
    // Two VBOs for position and texture coordinates
    glDeleteBuffers(2, meshRenderer.vbo);
    glGenBuffers(2, meshRenderer.vbo);
    
    float texCoord[] = {
        0.0f, pointRenderer.colormapIndexNormalized,
        0.0f, pointRenderer.colormapIndexNormalized,
        1.0f, pointRenderer.colormapIndexNormalized,
        1.0f, pointRenderer.colormapIndexNormalized,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f
    };
    
    // position
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[0]);
    //NSLog(@"basic rect is length %u", lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle]);
    glBufferData(GL_ARRAY_BUFFER,
                 lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle] * 4 * sizeof(GLfloat),
                 &lineRenderer.positions[lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle]],
                 GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.positionAI);
    
    // textureCoord
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoord), texCoord, GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.textureCoordAI, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.textureCoordAI);

    GLuint vbos[RENDERER_MAX_VBO_GROUPS][8];
    for (i = 0; i < 1; i++) {
        vbos[i][0] = pointRenderer.vbo[0];
        vbos[i][1] = pointRenderer.vbo[1];
        vbos[i][2] = pointRenderer.vbo[2];
    }
    [delegate vbosAllocated:vbos];
    
    // Frame renderer VBOs
    float coord[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f
    };
    glBindVertexArray(frameRenderer.vao);
    
    glDeleteBuffers(2, frameRenderer.vbo);
    glGenBuffers(2, frameRenderer.vbo);
    
    glBindBuffer(GL_ARRAY_BUFFER, frameRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(GLfloat), &lineRenderer.positions[lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle]], GL_STATIC_DRAW);
    glVertexAttribPointer(frameRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(frameRenderer.positionAI);
    
    glBindBuffer(GL_ARRAY_BUFFER, frameRenderer.vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coord), coord, GL_STATIC_DRAW);
    glVertexAttribPointer(frameRenderer.textureCoordAI, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(frameRenderer.textureCoordAI);
    
    viewParametersNeedUpdate = true;
}

- (void)allocateFBO {
    GLenum status;
    
    glDeleteFramebuffersEXT(RENDERER_FBO_COUNT, frameBuffers);
    glGenFramebuffersEXT(RENDERER_FBO_COUNT, frameBuffers);
    glDeleteTextures(RENDERER_FBO_COUNT, frameBufferTextures);
    glGenTextures(RENDERER_FBO_COUNT, frameBufferTextures);
    GLvoid *zeros = (GLvoid *)malloc(width * devicePixelRatio * height * devicePixelRatio * 16);
    memset(zeros, 0, width * devicePixelRatio * height * devicePixelRatio * 16);
    for (int i = 0; i < RENDERER_FBO_COUNT; i++) {
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[i]);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        //        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width * devicePixelRatio, height * devicePixelRatio, 0, GL_RGBA, GL_BYTE, zeros);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16, width * devicePixelRatio, height * devicePixelRatio, 0, GL_RGBA, GL_UNSIGNED_SHORT, zeros);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, frameBufferTextures[i], 0);
        status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
        if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
            NSLog(@"Error setting up framebuffer");
        }
    }
    free(zeros);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}

#pragma mark -
#pragma mark Methods

// This method is called right after the OpenGL context is initialized
- (void)allocateVAO {
    // Get the GL version
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &GLSLVersion);
    
    NSLog(@"%s / %s / %.2f", glGetString(GL_RENDERER), glGetString(GL_VERSION), GLSLVersion);
    
    GLint v[4] = {0, 0, 0, 0};
    glGetIntegerv(GL_ALIASED_LINE_WIDTH_RANGE, v);
    glGetIntegerv(GL_SMOOTH_LINE_WIDTH_RANGE, &v[2]);
    NSLog(@"Aliased / smoothed line width: %d ... %d / %d ... %d", v[0], v[1], v[2], v[3]);
    
    // Set up VAO and shaders
    pointRenderer = [self createRenderResourceFromVertexShader:@"spheroid.vsh" fragmentShader:@"spheroid.fsh"];
    
    // Make body renderer's color a bit translucent
    glUniform4f(pointRenderer.colorUI, 1.0f, 1.0f, 1.0f, 0.75f);
    
    // Set default colormap index
    pointRenderer.colormapIndex = RENDERER_DEFAULT_BODY_COLOR_INDEX;
    pointRenderer.colormapIndexNormalized = ((GLfloat)pointRenderer.colormapIndex + 0.5f) / pointRenderer.colormapCount;
    
    // This is the renderer that uses GL instancing
    instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom.vsh" fragmentShader:@"inst-geom.fsh"];
    //instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom-t.vsh" fragmentShader:@"inst-geom.fsh"];
    glUniform4f(instancedGeometryRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    
    lineRenderer   = [self createRenderResourceFromVertexShader:@"line_sc.vsh" fragmentShader:@"line_sc.fsh"];
    meshRenderer   = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"mesh.fsh"];
    frameRenderer  = [self createRenderResourceFromProgram:meshRenderer.program];
    
    //NSLog(@"Each renderer uses %zu bytes", sizeof(RenderResource));
    
    textRenderer = [GLText new];
    tTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"Weird Science NBP" size:144.0f]];
    fwTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"White Rabbit" size:40.0f]];
    
    #ifdef DEBUG_GL
    NSLog(@"VAOs = pointRenderer:%d  instancedGeometryRenderer = %d  lineRenderer %d",
          pointRenderer.vao, instancedGeometryRenderer.vao, lineRenderer.vao);
    #endif
    
    [self allocateFBO];
    
    // Some OpenGL features
    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
    
    // Always use this clear color: I use 16-bit internal FBO texture format, so minimum can only be sqrt ( 1 / 65536 ) = 1 / 256
    glClearColor(0.0f, 0.0f, 0.0f, 4.0f / 256.0f);
    
    [self makePrimitives];
    
    // Tell the delegate that the OpenGL context is ready for sharing and set up renderer's body count
    [delegate glContextVAOPrepared];
}

- (void)resetViewParameters {
    range = resetRange;
    modelRotate = resetModelRotate;
    viewParametersNeedUpdate = true;
}

- (void)topView {
    modelRotate = GLKMatrix4MakeRotation(M_PI_2, 1.0f, 0.0f, 0.0f);
    viewParametersNeedUpdate = true;
}

- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy {
    modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(2.0f * dx / width), modelRotate);
    modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(2.0f * dy / height), modelRotate);
    viewParametersNeedUpdate = true;
}

- (void)magnify:(GLfloat)scale {
    range = MIN(RENDERER_FAR_RANGE, MAX(RENDERER_NEAR_RANGE, range * (1.0f - scale)));
    viewParametersNeedUpdate = true;
}

- (void)rotate:(GLfloat)angle {
    if (angle > 2.0 * M_PI) {
        angle -= 2.0 * M_PI;
    } else if (angle < -2.0 * M_PI) {
        angle += 2.0 * M_PI;
    }
    modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeZRotation(angle), modelRotate);
    viewParametersNeedUpdate = true;
}

- (void)startSpinModel {
    spinModel = 1;
}

- (void)stopSpinModel {
    spinModel = 0;
}

- (void)toggleSpinModel {
    spinModel = spinModel == 5 ? 0 : spinModel + 1;
}

- (void)toggleSpinModelReverse {
    spinModel = spinModel == 0 ? 5 : spinModel - 1;
}

- (void)cycleForwardColormap {
    pointRenderer.colormapIndex = pointRenderer.colormapIndex >= pointRenderer.colormapCount - 1 ? 0 : pointRenderer.colormapIndex + 1;
    pointRenderer.colormapIndexNormalized = ((GLfloat)pointRenderer.colormapIndex + 0.5f) / pointRenderer.colormapCount;
    statusMessageNeedsUpdate = true;
    colorbarNeedsUpdate = true;
}

- (void)cycleReverseColormap {
    pointRenderer.colormapIndex = pointRenderer.colormapIndex <= 0 ? pointRenderer.colormapCount - 1 : pointRenderer.colormapIndex - 1;
    pointRenderer.colormapIndexNormalized = ((GLfloat)pointRenderer.colormapIndex + 0.5f) / pointRenderer.colormapCount;
    statusMessageNeedsUpdate = true;
    colorbarNeedsUpdate = true;
}

- (void)validateLineRenderer:(GLuint)number {
    if (lineRenderer.positions == NULL) {
        lineRenderer.positions = (GLfloat *)malloc(4 * 1024 * sizeof(GLfloat));      // Start with 1024 vertices, should be more than enough
        lineRenderer.segmentOrigins = (GLuint *)malloc(1024 * sizeof(GLuint));
        lineRenderer.segmentLengths = (GLuint *)malloc(1024 * sizeof(GLuint));
        lineRenderer.segmentMax = 1024;
    }
    // To add: check if number can fit in the allocated buffer
    if (lineRenderer.segmentMax < lineRenderer.segmentNextOrigin + number) {
        size_t next_vertex_count = ((lineRenderer.segmentMax + number) / 1024) * 1024;
        NSLog(@"Expanding lineRenderer buffers to %zu vertices ...", next_vertex_count);
        lineRenderer.positions = (GLfloat *)realloc(lineRenderer.positions, 4 * next_vertex_count * sizeof(GLfloat));
        lineRenderer.segmentOrigins = (GLuint *)realloc(lineRenderer.segmentOrigins, next_vertex_count);
        lineRenderer.segmentLengths = (GLuint *)realloc(lineRenderer.segmentLengths, next_vertex_count);
        lineRenderer.segmentMax = (GLuint)next_vertex_count;
    }
}

- (void)addLinesToLineRenderer:(GLfloat *)lines number:(GLuint)count {
    [self validateLineRenderer:count];
    
    if (lineRenderer.count < 2) {
        NSLog(@"WARNING: addLinesToLineRenderer: should have at least count = 2, currently %u", lineRenderer.count);
    }
    
    memcpy(&lineRenderer.positions[lineRenderer.segmentNextOrigin * 4], lines, count * 4 * sizeof(GLfloat));
    
    lineRenderer.segmentOrigins[lineRenderer.count] = lineRenderer.segmentNextOrigin;
    lineRenderer.segmentLengths[lineRenderer.count] = count;
    lineRenderer.segmentNextOrigin = lineRenderer.segmentNextOrigin + count;
    lineRenderer.count++;
    
    vbosNeedUpdate = true;
}

#pragma mark -
#pragma mark Render

- (void)render
{
    //int i;
    int k;
    
    if (vbosNeedUpdate) {
        vbosNeedUpdate = false;
        [self allocateVBO];
    }
    
    if (spinModel) {
        //modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(0.001f * spinModel), modelRotate);
        modelRotate = GLKMatrix4Multiply(modelRotate, GLKMatrix4MakeYRotation(0.001f * spinModel));
        theta = theta + 0.005f;
        viewParametersNeedUpdate = true;
    }
    
    if (viewParametersNeedUpdate) {
        viewParametersNeedUpdate = false;
        [self updateViewParameters];
    }
    
    if (fboNeedsUpdate) {
        fboNeedsUpdate = false;
        [self allocateFBO];
    }
    
    // Breathing phase
#ifdef GEN_IMG
    phase = 0.425459064119661f * (exp(-cos(iframe * 0.01666666666667f)) - 0.36787944117144f);
#else
    phase = 0.425459064119661f * (exp(-cos([NSDate timeIntervalSinceReferenceDate])) - 0.36787944117144f);
#endif
    
    phase = 0.7f * phase + 0.3f;
    
#ifdef DEBUG_GL
    if (iframe == 0) {
        NSLog(@"First frame <==============================");
    }
#endif
    
    [self measureFPS];
    
    // Tell the delgate I'm about to draw
    [delegate willDrawScatterBody];
    
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
    
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[0]);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // The background scatter bodies
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
    glBindVertexArray(pointRenderer.vao);
    glUseProgram(pointRenderer.program);
    glUniform4f(pointRenderer.sizeUI, pixelsPerUnit * devicePixelRatio, 1.0f, 1.0f, 1.0f);
    glUniform4f(pointRenderer.colorUI, pointRenderer.colormapIndexNormalized, 1.0f, 1.0f, backgroundOpacity);
    glUniformMatrix4fv(pointRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform1i(pointRenderer.pingPongUI, fadeSmallScatterers);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, pointRenderer.textureID);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, pointRenderer.colormapID);
    glDrawArrays(GL_POINTS, 0, pointRenderer.count);
    //glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);
    
    
    // Simulation Grid
    glBindVertexArray(lineRenderer.vao);
    glUseProgram(lineRenderer.program);
    glUniformMatrix4fv(lineRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform4f(lineRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
    glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid], lineRenderer.segmentLengths[RendererLineSegmentSimulationGrid]);
    glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 0.0f, 1.0f);
    glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentAnchorLines], lineRenderer.segmentLengths[RendererLineSegmentAnchorLines]);
    
    // Restore to full view port
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
    
    // Restore to texture 0
    glActiveTexture(GL_TEXTURE0);
    
    glDisable(GL_DEPTH_TEST);
    
    glBlendFunc(GL_ONE, GL_ZERO);
    
    glBindVertexArray(frameRenderer.vao);
    
    // The framebuffer for final presentation
    glUseProgram(frameRenderer.program);
    glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
    glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    
    // Show the framebuffer on the window
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(frameRenderer.program);
    glBindTexture(GL_TEXTURE_2D, frameBufferTextures[ifbo]);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glClear(GL_DEPTH_BUFFER_BIT);
    
    //#ifdef DEBUG_GL
    [tTextRenderer showTextureMap];
    //#endif
    
    NSPoint origin = NSMakePoint(25.0f, height - tTextRenderer.pointSize * 0.5f - 35.0f);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Colorbar
    glBindVertexArray(lineRenderer.vao);
    glUseProgram(lineRenderer.program);
    glUniformMatrix4fv(lineRenderer.mvpUI, 1, GL_FALSE, meshRenderer.modelViewProjectionOffTwo.m);
    glUniform4f(lineRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.6f);
    glDrawArrays(GL_TRIANGLE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle], 4);
    glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle] + 4, 5);
    
    glBindVertexArray(meshRenderer.vao);
    glUseProgram(meshRenderer.program);
    if (colorbarNeedsUpdate) {
        float texCoord[] = {
            0.0f, pointRenderer.colormapIndexNormalized,
            0.0f, pointRenderer.colormapIndexNormalized,
            1.0f, pointRenderer.colormapIndexNormalized,
            1.0f, pointRenderer.colormapIndexNormalized,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f
        };
        glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[1]);  // textureCoord
        glBufferData(GL_ARRAY_BUFFER, sizeof(texCoord), texCoord, GL_STATIC_DRAW);
    }
    glUniformMatrix4fv(meshRenderer.mvpUI, 1, GL_FALSE, meshRenderer.modelViewProjection.m);
    glUniform4f(meshRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    glBindTexture(GL_TEXTURE_2D, meshRenderer.textureID);
    glDrawArrays(GL_TRIANGLE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle], 4);
    
    origin.x = 0.76f * width;
    origin.y = 45.0f;
    [textRenderer drawText:colorbarTitle origin:origin scale:0.25f];
    
    origin.y = 20.0f;
    for (k = 0; k < colorbarTickCount; k++) {
        origin.x = (0.25f + 0.5f * colorbarTickPositions[k]) * width;
        [textRenderer drawText:colorbarTickLabels[k] origin:origin scale:0.25f align:GLTextAlignmentCenter];
    }
    
    glBindVertexArray(0);
    glUseProgram(0);
    iframe++;
}

@end
