//
//  Renderer.m
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
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
- (void)updateStatusMessage;
- (void)measureFPS;
- (void)validateLineRenderer:(GLuint)number;
- (void)addLinesToLineRenderer:(GLfloat *)lines number:(GLuint)number;

@end

// Gray code <--> decimal conversion
unsigned int binaryToGray(unsigned int num)
{
    return num ^ (num >> 1);
}

unsigned int grayToBinary(unsigned int num)
{
    unsigned int mask;
    for (mask = num >> 1; mask != 0; mask = mask >> 1)
    {
        num = num ^ mask;
    }
    return num;
}


@implementation Renderer

#pragma mark -
#pragma mark Properties

@synthesize titleString, subtitleString;
@synthesize delegate;
@synthesize resetRange;
@synthesize resetModelRotate;
@synthesize width, height;
@synthesize beamAzimuth, beamElevation;
@synthesize showDebrisAttributes, fadeSmallScatterers, viewParametersNeedUpdate;

- (void)setSize:(CGSize)size
{
	width = (GLsizei)size.width;
	height = (GLsizei)size.height;
	
	glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
	
	aspectRatio = size.width / size.height;
    
    viewParametersNeedUpdate = true;
    fboNeedsUpdate = true;
}


- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size
{
	NSLog(@"Renderer grid @ (%.1f, %.1f, %.1f)  (%.1f, %.1f, %.1f)", origin[0], origin[1], origin[2], size[0], size[1], size[2]);

    domainOrigin.x = origin[0];
    domainOrigin.y = origin[1];
    domainOrigin.z = origin[2];
    domainSize.x = size[0];
    domainSize.y = size[1];
    domainSize.z = size[2];

    GLfloat *pos = lineRenderer.positions + lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid] * 4;

	*pos++ = origin[0];
	*pos++ = origin[1];
	*pos++ = origin[2];
	*pos++ = 1.0f;
	*pos++ = origin[0] + size[0];
	*pos++ = origin[1];
	*pos++ = origin[2];
	*pos++ = 1.0f;

	*pos++ = origin[0];
	*pos++ = origin[1];
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


- (void)setBodyCount:(GLuint)number forDevice:(GLuint)deviceId
{
	bodyRenderer[deviceId].count = number;
    backgroundOpacity = MIN(1.0f, 1000.0f / ((float)number * 0.02f));
	vbosNeedUpdate = true;
}


- (void)setPopulationTo:(GLuint)count forDebris:(GLuint)debrisId forDevice:(GLuint)deviceId
{
    if (debrisId == 0) {
        NSLog(@"Invalid debrisId.");
        return;
    }
    debrisRenderer[debrisId].count = count;
    debrisRenderer[0].count = bodyRenderer[deviceId].count;
    for (int i = 1; i < RENDERER_MAX_DEBRIS_TYPES; i++) {
        debrisRenderer[0].count -= debrisRenderer[i].count;
    }
    statusMessageNeedsUpdate = true;
}


- (void)setAnchorPoints:(GLfloat *)points number:(GLuint)number
{
	anchorRenderer.positions = points;
	anchorRenderer.count = number;
	vbosNeedUpdate = true;
}


- (void)setAnchorLines:(GLfloat *)lines number:(GLuint)number
{
    lineRenderer.count = 2;
    [self addLinesToLineRenderer:lines number:number];
}


- (void)setCenterPoisitionX:(GLfloat)x y:(GLfloat)y z:(GLfloat)z
{
	modelCenter.x = x;
	modelCenter.y = y;
	modelCenter.z = z;
}


- (void)setBeamElevation:(GLfloat)elevation azimuth:(GLfloat)azimuth
{
    beamElevation = elevation * M_PI / 180.0f;
    beamAzimuth = azimuth * M_PI / 180.0f;
    viewParametersNeedUpdate = true;
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

    [self setAnchorLines:rect number:1];

    [self setAnchorPoints:rect number:1];
    
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
        pos[i] *= 4.5f;
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
        resource->colormapIndexNormalized = ((GLfloat)resource->colormapIndex + 0.5f) / resource->colormapCount;
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
    
    // This is specific to instanced geometry shader
    resource->lowZUI = glGetUniformLocation(resource->program, "lowZ");
    if (resource->lowZUI >= 0) {
        glUniform1f(resource->lowZUI, 1.0f);
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


- (void)updateStatusMessage
{
    sprintf(statusMessage[0],
            "Meteorological Scatterers: %s",
            [GLText commaint:bodyRenderer[0].count]);
    sprintf(statusMessage[1],
            "Debris 1-4: %s  %s  %s  %s",
            [GLText commaint:debrisRenderer[1].count],
            [GLText commaint:debrisRenderer[2].count],
            [GLText commaint:debrisRenderer[3].count],
            [GLText commaint:debrisRenderer[4].count]);
    sprintf(statusMessage[2],
            "Debris 5-8: %s  %s  %s  %s",
            [GLText commaint:debrisRenderer[5].count],
            [GLText commaint:debrisRenderer[6].count],
            [GLText commaint:debrisRenderer[7].count],
            [GLText commaint:debrisRenderer[8].count]);
    sprintf(statusMessage[3],
            "Colormap %d   Opacity %.3f",
            bodyRenderer[0].colormapIndex,
            backgroundOpacity);
    sprintf(statusMessage[4],
            "HUD %d%d%d%d / %d",
            (hudConfigGray & 0x08) >> 3, (hudConfigGray & 0x04) >> 2, (hudConfigGray & 0x02) >> 1, hudConfigGray & 0x01, hudConfigDecimal);
    sprintf(statusMessage[5],
            "FBO %u   VFX %u", ifbo, applyVFX);
}


- (void)measureFPS
{
    int otic = itic;
    tics[itic] = [NSDate timeIntervalSinceReferenceDate];
    itic = itic == RENDERER_TIC_COUNT - 1 ? 0 : itic + 1;
    fps = (float)(RENDERER_TIC_COUNT - 1) / (tics[otic] - tics[itic]);
    sprintf(fpsString, "%c%.0f FPS", (iframe / 40) % 2 == 0 ? '_' : ' ', fps);
}


- (void)validateLineRenderer:(GLuint)number
{
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


- (void)addLinesToLineRenderer:(GLfloat *)lines number:(GLuint)count
{
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
#pragma mark Initializations & Deallocation

- (id)initWithDevicePixelRatio:(GLfloat)pixelRatio
{
    self = [super init];
    if (self) {
        // View size in pixel counts
        width = 1;
        height = 1;
        spinModel = 5;
        aspectRatio = 1.0f;
        beamElevation = 75.0f / 180.0f * M_PI;
        
        iframe = -1;
        
        resetRange = 5000.0f;
        resetModelRotate = GLKMatrix4Identity;
        //resetModelRotate = GLKMatrix4MakeRotation(1.0, 0.0f, 1.0f, 1.0f);
        
        hudConfigGray = hudConfigShowGrid | hudConfigShowOverlay | hudConfigShowRadarView;
        hudConfigDecimal = grayToBinary(hudConfigGray);
        
        beamNearZ = 2.0f;
        
        hudModelViewProjection = GLKMatrix4Identity;
        beamModelViewProjection = GLKMatrix4Identity;
        
        // Add device pixel ratio here
        devicePixelRatio = pixelRatio;
        NSLog(@"Renderer initialized with pixel ratio = %.1f", devicePixelRatio);
        
        self.titleString = @"Renderer";
        colorbarTitle = statusMessage[9];
        sprintf(statusMessage[9], "Nothing");
        
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
    
    [overlayRenderer release];
    
	if (lineRenderer.positions != NULL) {
		free(lineRenderer.positions);
        free(lineRenderer.segmentOrigins);
        free(lineRenderer.segmentLengths);
	}
	if (instancedGeometryRenderer.positions != NULL) {
		free(instancedGeometryRenderer.positions);
	}
    for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        free(debrisRenderer[k].colors);
    }
	[super dealloc];
}

#pragma mark -
#pragma mark Methods

// This method is called right after the OpenGL context is initialized

- (void)allocateVAO:(GLuint)gpuCount
{
    clDeviceCount = gpuCount;
    if (clDeviceCount != 1) {
        // I only managed to make 1 work for now...
        clDeviceCount = 1;
    }
    
    // Get the GL version
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &GLSLVersion);
	
	NSLog(@"%s / %s / %.2f / %u GPU(s)", glGetString(GL_RENDERER), glGetString(GL_VERSION), GLSLVersion, clDeviceCount);

	GLint v[4] = {0, 0, 0, 0};
	glGetIntegerv(GL_ALIASED_LINE_WIDTH_RANGE, v);
	glGetIntegerv(GL_SMOOTH_LINE_WIDTH_RANGE, &v[2]);
	NSLog(@"Aliased / smoothed line width: %d ... %d / %d ... %d", v[0], v[1], v[2], v[3]);
    
    anchorRenderer = [self createRenderResourceFromVertexShader:@"anchor.vsh" fragmentShader:@"anchor.fsh"];
    lineRenderer   = [self createRenderResourceFromVertexShader:@"line_sc.vsh" fragmentShader:@"line_sc.fsh"];
    meshRenderer   = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"mesh.fsh"];
    frameRenderer  = [self createRenderResourceFromProgram:meshRenderer.program];
    blurRenderer   = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"blur.fsh"];
    
    // Only one renderer program needs to be created and the others can share the same program, so just make copies
    bodyRenderer[0] = [self createRenderResourceFromVertexShader:@"spheroid.vsh" fragmentShader:@"spheroid.fsh"];
    for (int i = 1; i < clDeviceCount; i++) {
        bodyRenderer[i] = [self createRenderResourceFromProgram:bodyRenderer[0].program];
    }

    // This is the renderer that uses GL instancing
    //instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom.vsh" fragmentShader:@"inst-geom.fsh"];
    instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom-t.vsh" fragmentShader:@"inst-geom.fsh"];
    glUniform4f(instancedGeometryRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    
    // Local rotating color table
    const GLfloat colors[][4] = {
        {1.00f, 1.00f, 1.00f, 1.00f},
        {0.00f, 1.00f, 0.00f, 1.00f},
        {1.00f, 0.20f, 1.00f, 1.00f},
        {1.00f, 0.65f, 0.00f, 1.00f}
    };
    for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        debrisRenderer[k] = [self createRenderResourceFromProgram:instancedGeometryRenderer.program];
        debrisRenderer[k].colors = malloc(4 * sizeof(GLfloat));
        debrisRenderer[k].colors[0] = colors[(k % 4)][0];
        debrisRenderer[k].colors[1] = colors[(k % 4)][1];
        debrisRenderer[k].colors[2] = colors[(k % 4)][2];
        debrisRenderer[k].colors[3] = colors[(k % 4)][3];
    }
    
    //NSLog(@"Each renderer uses %zu bytes", sizeof(RenderResource));
    //NSLog(@"meshRenderer's drawColor @ %d / %d / %d", meshRenderer.colorUI, meshRenderer.positionAI, meshRenderer.textureCoordAI);

    //NSLog(@"========:");
    textRenderer = [GLText new];
    //NSLog(@"========:");
    //tTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"Gas" size:72.0f]];
    tTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"Weird Science NBP" size:144.0f]];
    //fwTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"Menlo" size:40.0f]];
    fwTextRenderer = [[GLText alloc] initWithFont:[NSFont fontWithName:@"White Rabbit" size:40.0f]];

    overlayRenderer = [GLOverlay new];
    
#ifdef DEBUG_GL
	NSLog(@"VAOs = bodyRenderer:%d  instancedGeometryRenderer = %d  lineRenderer %d  anchorRenderer %d",
		  bodyRenderer[0].vao, instancedGeometryRenderer.vao, lineRenderer.vao, anchorRenderer.vao);
#endif

    [self allocateFBO];
    
    // Some OpenGL features
	glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);

	// Always use this clear color: I use 16-bit internal FBO texture format, so minimum can only be sqrt ( 1 / 65536 ) = 1 / 256
    glClearColor(0.0f, 0.0f, 0.0f, 4.0f / 256.0f);

    [self makePrimitives];
    
    NSLog(@"delegate @ %@", delegate);
    
    // Tell the delegate that the OpenGL context is ready for sharing and set up renderer's body count
    [delegate glContextVAOPrepared];

    [self updateStatusMessage];
}


- (void)allocateVBO
{
    int i;
    
	#ifdef DEBUG
	NSLog(@"Allocating (%d, %d) particles on GPU ...", bodyRenderer[0].count, bodyRenderer[1].count);
	#endif
    
    // Anchors
    glBindVertexArray(anchorRenderer.vao);
    
    glDeleteBuffers(1, anchorRenderer.vbo);
    glGenBuffers(1, anchorRenderer.vbo);
    
    // Use .w element for anchor size, scale by pixel ratio for Retina displays
    if (anchorRenderer.positions[3] == 1.0f && devicePixelRatio > 1.0f) {
        for (i = 0; i < anchorRenderer.count; i++) {
            anchorRenderer.positions[4 * i + 3] *= devicePixelRatio;
        }
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, anchorRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, anchorRenderer.count * sizeof(cl_float4), anchorRenderer.positions, GL_STATIC_DRAW);
    glVertexAttribPointer(anchorRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(anchorRenderer.positionAI);
    
    // Lines
	glBindVertexArray(lineRenderer.vao);

    glDeleteBuffers(1, lineRenderer.vbo);
	glGenBuffers(1, lineRenderer.vbo);

	glBindBuffer(GL_ARRAY_BUFFER, lineRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, lineRenderer.segmentNextOrigin * 4 * sizeof(GLfloat), lineRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(lineRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(lineRenderer.positionAI);
	
    // Mesh 1 : colorbar
    glBindVertexArray(meshRenderer.vao);
    
    // Two VBOs for position and texture coordinates
    glDeleteBuffers(2, meshRenderer.vbo);
    glGenBuffers(2, meshRenderer.vbo);
    
    float texCoord[] = {
        0.0f, bodyRenderer[0].colormapIndexNormalized,
        0.0f, bodyRenderer[0].colormapIndexNormalized,
        1.0f, bodyRenderer[0].colormapIndexNormalized,
        1.0f, bodyRenderer[0].colormapIndexNormalized,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 0.0f
    };
    
    // position
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[0]);
    //glBufferData(GL_ARRAY_BUFFER, sizeof(pos), pos, GL_STATIC_DRAW);
    //NSLog(@"basic rect is length %u", lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle]);
    glBufferData(GL_ARRAY_BUFFER, lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle] * 4 * sizeof(GLfloat), &lineRenderer.positions[lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle]], GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.positionAI);
    
    // textureCoord
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoord), texCoord, GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.textureCoordAI, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.textureCoordAI);
    
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
    
    // Blur renderer
    glBindVertexArray(blurRenderer.vao);
    
    glDeleteBuffers(2, blurRenderer.vbo);
    glGenBuffers(2, blurRenderer.vbo);
    
    glBindBuffer(GL_ARRAY_BUFFER, blurRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(GLfloat), &lineRenderer.positions[lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle]], GL_STATIC_DRAW);
    glVertexAttribPointer(blurRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(blurRenderer.positionAI);
    
    glBindBuffer(GL_ARRAY_BUFFER, blurRenderer.vbo[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(coord), coord, GL_STATIC_DRAW);
    glVertexAttribPointer(blurRenderer.textureCoordAI, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(blurRenderer.textureCoordAI);

    // Scatter body (spheroid)
    for (i = 0; i < clDeviceCount; i++) {
        if (bodyRenderer[i].count == 0) {
            continue;
        }
        glBindVertexArray(bodyRenderer[i].vao);
        
        glDeleteBuffers(3, bodyRenderer[i].vbo);
        glGenBuffers(3, bodyRenderer[i].vbo);
        
        glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer[i].vbo[0]);  // position
        glBufferData(GL_ARRAY_BUFFER, bodyRenderer[i].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(bodyRenderer[i].positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glEnableVertexAttribArray(bodyRenderer[i].positionAI);
        
        glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer[i].vbo[1]);  // color
        glBufferData(GL_ARRAY_BUFFER, bodyRenderer[i].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(bodyRenderer[i].colorAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glEnableVertexAttribArray(bodyRenderer[i].colorAI);

        glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer[i].vbo[2]);  // orientation
        glBufferData(GL_ARRAY_BUFFER, bodyRenderer[i].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(bodyRenderer[i].quaternionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glEnableVertexAttribArray(bodyRenderer[i].quaternionAI);
    }
    
    GLuint vbos[RENDERER_MAX_VBO_GROUPS][8];
    for (i = 0; i < clDeviceCount; i++) {
        vbos[i][0] = bodyRenderer[i].vbo[0];
        vbos[i][1] = bodyRenderer[i].vbo[1];
        vbos[i][2] = bodyRenderer[i].vbo[2];
    }

#ifdef DEBUG
    NSLog(@"anchorRenderer.vbo = %d   lineRenderer.vbo = %d",
          anchorRenderer.vbo[0], lineRenderer.vbo[0]);
    NSLog(@"meshRenderer.vbo = %d %d   frameRenderer.vbo = %d %d   blurRenderer.vbo = %d %d",
          meshRenderer.vbo[0], meshRenderer.vbo[1],
          frameRenderer.vbo[0], frameRenderer.vbo[1],
          blurRenderer.vbo[0], blurRenderer.vbo[1]);
    NSLog(@"bodyRenderer.vbos = %d %d %d / %d %d %d",
          bodyRenderer[0].vbo[0], bodyRenderer[0].vbo[1], bodyRenderer[0].vbo[2],
          bodyRenderer[1].vbo[0], bodyRenderer[1].vbo[1], bodyRenderer[1].vbo[2]);
#endif
    
    [delegate vbosAllocated:vbos];
    
	viewParametersNeedUpdate = true;
}

- (void)allocateFBO {
    GLenum status;

    #ifdef DEBUG
    NSLog(@"Allocating FBO ...");
    #endif

    GLint w = width * devicePixelRatio;
    GLint h = height * devicePixelRatio;
    
    if (w == 0 || h == 0) {
        NSLog(@"Error. Unexpected combination of w = %d, h = %d", w, h);
        return;
    }
    
    glDeleteFramebuffersEXT(RENDERER_FBO_COUNT, frameBuffers);
    glGenFramebuffersEXT(RENDERER_FBO_COUNT, frameBuffers);
    glDeleteTextures(RENDERER_FBO_COUNT, frameBufferTextures);
    glGenTextures(RENDERER_FBO_COUNT, frameBufferTextures);
    GLvoid *zeros = (GLvoid *)malloc(w * h * 4 * sizeof(unsigned short));
    if (zeros == NULL) {
        NSLog(@"Error allocating zeros.");
        return;
    }
    memset(zeros, 0, w * h * 4 * sizeof(unsigned short));
    for (int i = 0; i < RENDERER_FBO_COUNT; i++) {
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[i]);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16, w, h, 0, GL_RGBA, GL_UNSIGNED_SHORT, zeros);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, frameBufferTextures[i], 0);
        status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
        if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
            NSLog(@"Error setting up framebuffer");
        }
    }
    free(zeros);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}


- (void)updateBodyToDebrisMappings
{
    int k;
    // Debris
    GLuint offset = bodyRenderer[0].count;
    k = RENDERER_MAX_DEBRIS_TYPES;
    while (k > 1) {
        k--;
        if (debrisRenderer[k].count > 0) {
            offset -= debrisRenderer[k].count;
            debrisRenderer[k].sourceOffset = offset;
        }
    }

    // Various Debris
    for (k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        #if defined(DEBUG_DEBRIS_MAPPING)
        NSLog(@"Mapping debris %d  count = %d", k, debrisRenderer[k].count);
        #endif
        if (debrisRenderer[k].count == 0) {
            continue;
        }
        glBindVertexArray(debrisRenderer[k].vao);
        
        if (debrisRenderer[k].vbo[0]) {
            glDeleteBuffers(5, debrisRenderer[k].vbo);
        }
        glGenBuffers(5, debrisRenderer[k].vbo);
        
        RenderPrimitive *prim = &primitives[(k + 3) % 4];

        debrisRenderer[k].instanceSize = prim->instanceSize;
        debrisRenderer[k].drawMode = prim->drawMode;
        
        // 1-st VBO for geometry (primitive, we are instancing)
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, prim->vertexSize, prim->vertices, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glEnableVertexAttribArray(debrisRenderer[k].positionAI);
        
        // 2-nd VBO for position index
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, debrisRenderer[k].vbo[1]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, prim->instanceSize * sizeof(GLuint), prim->indices, GL_STATIC_DRAW);
        
        // 3-rd VBO for translation (position)
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[2]);
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].translationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].translationAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].translationAI);
        
        // 4-th VBO for quaternion (rotation)
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[3]);
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].quaternionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].quaternionAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].quaternionAI);

        // 5-th VBO for color index
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[4]);
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].colorAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].colorAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].colorAI);
    }
}

#pragma mark -
#pragma mark Render

- (void)render
{
    int i;
    int k;
    
    if (fboNeedsUpdate) {
        fboNeedsUpdate = false;
        [self allocateFBO];
    }
    
	if (vbosNeedUpdate) {
		vbosNeedUpdate = false;
		[self allocateVBO];
	}
	
    if (statusMessageNeedsUpdate) {
        statusMessageNeedsUpdate = false;
        [self updateBodyToDebrisMappings];
        [self updateStatusMessage];
    }
    
	if (spinModel) {
        cameraYaw -= 0.001f * spinModel;
        if (cameraYaw > 2.0 * M_PI) {
            cameraYaw -= 2.0 * M_PI;
        } else if (cameraYaw < -2.0 * M_PI) {
            cameraYaw += 2.0 * M_PI;
        }
		viewParametersNeedUpdate = true;
	}
	
	if (viewParametersNeedUpdate) {
        viewParametersNeedUpdate = false;
		[self updateViewParameters];
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
        NSLog(@"First frame %.1f x %.1f", width * devicePixelRatio, height * devicePixelRatio);
    }
#endif
    
    [self measureFPS];
    
	// Tell the delgate I'm about to draw
	[delegate willDrawScatterBody];

#ifdef GEN_IMG
    // Advance twice for things to go twice as fast
    [delegate willDrawScatterBody];
#endif

//    NSLog(@"render %d", iframe);

    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[0]);

    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    // The background scatter bodies
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    for (i = 0; i < clDeviceCount; i++) {
        glBindVertexArray(bodyRenderer[i].vao);
        glUseProgram(bodyRenderer[i].program);
        glUniform4f(bodyRenderer[i].sizeUI, pixelsPerUnit * devicePixelRatio, 1.0f, 1.0f, 1.0f);
        glUniform4f(bodyRenderer[i].colorUI, bodyRenderer[i].colormapIndexNormalized, 1.0f, 1.0f, backgroundOpacity);
        
        glUniformMatrix4fv(bodyRenderer[i].mvpUI, 1, GL_FALSE, modelViewProjection.m);
        glUniform1i(bodyRenderer[i].pingPongUI, fadeSmallScatterers);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].textureID);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].colormapID);
        glDrawArrays(GL_POINTS, 0, debrisRenderer[0].count); // Yes, debrisRenderer[0].count is used for the background.
    }
//    glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    if (hudConfigGray & hudConfigShowGrid) {
        // Simulation Grid
        glBindVertexArray(lineRenderer.vao);
        glUseProgram(lineRenderer.program);
        glUniformMatrix4fv(lineRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
        glUniform4f(lineRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
        glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid], lineRenderer.segmentLengths[RendererLineSegmentSimulationGrid]);
        glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 0.0f, 1.0f);
        glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentAnchorLines], lineRenderer.segmentLengths[RendererLineSegmentAnchorLines]);
    }
    
    if (applyVFX == 4) {
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[2]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    
    // Various debris types
    glUseProgram(instancedGeometryRenderer.program);
    glUniformMatrix4fv(instancedGeometryRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform1f(instancedGeometryRenderer.lowZUI, domainOrigin.z + 0.1f * domainSize.z);
    for (i = 0; i < clDeviceCount; i++) {
        for (k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
            //NSLog(@"k = %d  debris count = %d", k, debrisRenderer[k].count);
            if (debrisRenderer[k].count == 0) {
                continue;
            }
            // Update the VBOs by copy
            glBindVertexArray(debrisRenderer[k].vao);
            
            if (showDebrisAttributes) {
                glUniform1i(instancedGeometryRenderer.pingPongUI, 1);
                glUniform4f(instancedGeometryRenderer.colorUI, bodyRenderer[0].colormapIndexNormalized, 1.0f, 1.0f, 1.0f);

                glBindBuffer(GL_COPY_READ_BUFFER, bodyRenderer[i].vbo[1]);             // color index
                glBindBuffer(GL_COPY_WRITE_BUFFER, debrisRenderer[k].vbo[4]);          // color index of debris[k]
                glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, debrisRenderer[k].sourceOffset * sizeof(cl_float4), 0, debrisRenderer[k].count * sizeof(cl_float4));
            } else {
                glUniform1i(instancedGeometryRenderer.pingPongUI, 0);
                glUniform4f(instancedGeometryRenderer.colorUI, debrisRenderer[k].colors[0], debrisRenderer[k].colors[1], debrisRenderer[k].colors[2], debrisRenderer[k].colors[3]);
            }
            
            glBindBuffer(GL_COPY_READ_BUFFER, bodyRenderer[i].vbo[0]);             // positions of simulation particles
            glBindBuffer(GL_COPY_WRITE_BUFFER, debrisRenderer[k].vbo[2]);          // translations of debris[k]
            glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, debrisRenderer[k].sourceOffset * sizeof(cl_float4), 0, debrisRenderer[k].count * sizeof(cl_float4));
            
            glBindBuffer(GL_COPY_READ_BUFFER, bodyRenderer[i].vbo[2]);             // quaternions of simulation particles
            glBindBuffer(GL_COPY_WRITE_BUFFER, debrisRenderer[k].vbo[3]);          // quaternions of debris[k]
            glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, debrisRenderer[k].sourceOffset * sizeof(cl_float4), 0, debrisRenderer[k].count * sizeof(cl_float4));
            
            glDrawElementsInstanced(debrisRenderer[k].drawMode, debrisRenderer[k].instanceSize, GL_UNSIGNED_INT, NULL, debrisRenderer[k].count);
        }
    }
    
    if (hudConfigGray & hudConfigShowRadarView) {
        // HUD Background & Outline
        if (lineRenderer.segmentNextOrigin) {
            glBindVertexArray(lineRenderer.vao);
            glUseProgram(lineRenderer.program);
            glUniformMatrix4fv(lineRenderer.mvpUI, 1, GL_FALSE, hudModelViewProjection.m);
            glUniform4f(lineRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.75f);
            glDrawArrays(GL_TRIANGLE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle], 4);
            glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
            glDrawArrays(GL_LINE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle] + 4, 5);
        }
        
        // Objects on HUD (beam's view)
        glViewport((hudOrigin.x + 1.5f) * devicePixelRatio, (hudOrigin.y + 1.5f) * devicePixelRatio,
                   (hudSize.width - 3.0f) * devicePixelRatio, (hudSize.height - 3.0f) * devicePixelRatio);

        // Draw the debris again
        glUseProgram(instancedGeometryRenderer.program);
        glUniformMatrix4fv(instancedGeometryRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
        for (k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
            if (debrisRenderer[k].count == 0) {
                continue;
            }
            glBindVertexArray(debrisRenderer[k].vao);

            if (showDebrisAttributes) {
                glUniform1i(instancedGeometryRenderer.pingPongUI, 1);
                glUniform4f(instancedGeometryRenderer.colorUI, bodyRenderer[0].colormapIndexNormalized, 1.0f, 1.0f, 1.0f);
            } else {
                glUniform1i(instancedGeometryRenderer.pingPongUI, 0);
                glUniform4f(instancedGeometryRenderer.colorUI, debrisRenderer[k].colors[0], debrisRenderer[k].colors[1], debrisRenderer[k].colors[2], debrisRenderer[k].colors[3]);
            }

            glDrawElementsInstanced(debrisRenderer[k].drawMode, debrisRenderer[k].instanceSize, GL_UNSIGNED_INT, NULL, debrisRenderer[k].count);
        }

        // Draw the grid
        glBindVertexArray(lineRenderer.vao);
        glUseProgram(lineRenderer.program);
        glUniformMatrix4fv(lineRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
        glUniform4f(lineRenderer.colorUI, 0.4f, 1.0f, 1.0f, 0.8f);
        glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentSimulationGrid], lineRenderer.segmentLengths[RendererLineSegmentSimulationGrid]);
        glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 0.0f, 0.8f);
        glDrawArrays(GL_LINES, lineRenderer.segmentOrigins[RendererLineSegmentAnchorLines], lineRenderer.segmentLengths[RendererLineSegmentAnchorLines]);
    }

    // Restore to full view port
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);

    // Restore to texture 0
    glActiveTexture(GL_TEXTURE0);

    glDisable(GL_DEPTH_TEST);
    
    glBlendFunc(GL_ONE, GL_ZERO);

    glBindVertexArray(frameRenderer.vao);

    if (applyVFX == 4) {
        // -- Bloom the background --
        glUseProgram(blurRenderer.program);
        glUniformMatrix4fv(blurRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        
        // Copy and blur frame buffer (ping) to frame buffer (pong)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[4]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glUniform1i(blurRenderer.pingPongUI, 0);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // Copy and blur frame buffer (pong) to frame buffer (ping)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[4]);
        glUniform1i(blurRenderer.pingPongUI, 1);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // Second pass
//        // Copy and blur frame buffer (ping) to frame buffer (pong)
//        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[4]);
//        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[1]);
//        glUniform1i(blurRenderer.pingPongUI, 0);
//        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//
//        // Copy and blur frame buffer (pong) to frame buffer (ping)
//        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
//        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[4]);
//        glUniform1i(blurRenderer.pingPongUI, 1);
//        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
        // -- Bloom the debris --
        glUseProgram(blurRenderer.program);
    
        glBlendFunc(GL_ONE, GL_ZERO);
        
        // Copy and blur frame buffer (ping) to frame buffer (pong)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[4]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[2]);
        glUniform1i(blurRenderer.pingPongUI, 0);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // Copy and blur frame buffer (pong) to frame buffer (ping)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[3]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[4]);
        glUniform1i(blurRenderer.pingPongUI, 1);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
        glUseProgram(frameRenderer.program);

        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[3]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[2]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    } else if (applyVFX == 3) {

        glUseProgram(blurRenderer.program);
        glUniformMatrix4fv(blurRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);

        // Copy and blur frame buffer (ping) to frame buffer (pong)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[4]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glUniform1i(blurRenderer.pingPongUI, 0);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        // Copy and blur frame buffer (pong) to frame buffer (ping)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[4]);
        glUniform1i(blurRenderer.pingPongUI, 1);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);

        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    } else if (applyVFX == 2) {
        
        glUseProgram(blurRenderer.program);
        glUniformMatrix4fv(blurRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        
        // Copy and blur frame buffer (ping) to frame buffer (pong)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[4]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glUniform1i(blurRenderer.pingPongUI, 0);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // Copy and blur frame buffer (pong) to frame buffer (ping)
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[2]);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[4]);
        glUniform1i(blurRenderer.pingPongUI, 1);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
        
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[2]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    } else if (applyVFX == 1) {

        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
        
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffers[1]);
        glBindTexture(GL_TEXTURE_2D, frameBufferTextures[0]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    } else {

        // The framebuffer for final presentation
        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);

    }

    // Show the framebuffer on the window
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
    glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    glBindTexture(GL_TEXTURE_2D, frameBufferTextures[ifbo]);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glClear(GL_DEPTH_BUFFER_BIT);

    if (hudConfigGray & hudConfigShowAnchors) {
        // Anchors
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glBindVertexArray(anchorRenderer.vao);
        glUseProgram(anchorRenderer.program);
        glUniform4f(anchorRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
        glUniformMatrix4fv(anchorRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, anchorRenderer.textureID);
        glDrawArrays(GL_POINTS, 0, anchorRenderer.count);
    }
    
#ifdef DEBUG_GL
    [tTextRenderer showTextureMap];
#endif

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Text
    //sprintf(statusMessage[5], "Frame %s", [GLText commaint:iframe]);
    
    NSPoint origin = NSMakePoint(25.0f, height - tTextRenderer.pointSize * 0.5f - 35.0f);
    
    if (titleString) {
        [tTextRenderer drawText:[titleString UTF8String] origin:origin scale:0.5f red:0.2f green:1.0f blue:0.9f alpha:1.0f];
        origin.y -= 32.0f;
    }
    GLfloat scale = 0.5f * (GLfloat)height / 1080.0f;
    if (subtitleString) {
        [fwTextRenderer drawText:[subtitleString UTF8String] origin:origin scale:scale];
        origin.y -= scale * 50.0f;
    }
    for (k = 0; k < 6; k++) {
        [fwTextRenderer drawText:statusMessage[k] origin:origin scale:scale];
        origin.y -= scale * 50.0f;
    }

#ifndef GEN_IMG
    [fwTextRenderer drawText:fpsString origin:NSMakePoint(width - 30.0f, 20.0f) scale:0.5f red:1.0f green:0.9f blue:0.2f alpha:1.0f align:GLTextAlignmentRight];
#endif
    
    if (hudConfigGray & hudConfigShowOverlay) {
        [overlayRenderer draw];
    }

    if (hudConfigGray & hudConfigShowRadarView) {
        sprintf(statusMessage[7], "EL %.2f   AZ %.2f", beamElevation / M_PI * 180.0f, beamAzimuth / M_PI * 180.0f);
        [textRenderer drawText:statusMessage[7] origin:NSMakePoint(hudOrigin.x + 15.0f, hudOrigin.y - 30.0f) scale:0.25f];
    }

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
            0.0f, bodyRenderer[0].colormapIndexNormalized,
            0.0f, bodyRenderer[0].colormapIndexNormalized,
            1.0f, bodyRenderer[0].colormapIndexNormalized,
            1.0f, bodyRenderer[0].colormapIndexNormalized,
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

#pragma mark -
#pragma mark Interaction

- (void)updateViewParameters {

    #ifdef DEBUG_INTERACTION
    NSLog(@"updateViewParameters:");
    #endif
    
    GLfloat s;
    
    unitsPerPixel = range / height / devicePixelRatio;
    pixelsPerUnit = 1.0f / unitsPerPixel;

    GLKMatrix4 mat;

    // Manipulate the model if we wanted to
    modelView = GLKMatrix4Identity;
    
    // Camera (inverse of the desired view parameters)
    camera = GLKMatrix4MakeXRotation(-M_PI_2);
    camera = GLKMatrix4Translate(camera, -modelCenter.x, 2.0f * range - modelCenter.y, 0.0);
    camera = GLKMatrix4RotateY(camera, cameraRoll);
    camera = GLKMatrix4Translate(camera, 0.0, modelCenter.y, 0.0);
    camera = GLKMatrix4RotateX(camera, cameraPitch);
    camera = GLKMatrix4RotateZ(camera, cameraYaw);
    camera = GLKMatrix4Translate(camera, 0.0, -modelCenter.y, -modelCenter.z);

    modelView = GLKMatrix4Multiply(camera, modelView);

    projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, 3.0f, RENDERER_FAR_RANGE);
    modelViewProjection = GLKMatrix4Multiply(projection, modelView);

    s = roundf(MAX(height * 0.25f, width * 0.2f));
    hudSize = CGSizeMake(s, s);
    hudOrigin = CGPointMake(width - hudSize.width - 30.5f, height - hudSize.height - 35.0f);
    hudProjection = GLKMatrix4MakeOrtho(0.0f, width, 0.0f, height, 0.0f, 1.0f);
    mat = GLKMatrix4MakeTranslation(hudOrigin.x, hudOrigin.y, 0.0f);
    mat = GLKMatrix4Scale(mat, hudSize.width, hudSize.height, 1.0f);
    hudModelViewProjection = GLKMatrix4Multiply(hudProjection, mat);

    GLfloat w = hudSize.width / hudSize.height;
    beamProjection = GLKMatrix4MakeFrustum(-w, w, -1.0f, 1.0f, beamNearZ, RENDERER_FAR_RANGE);
//    mat = GLKMatrix4MakeZRotation(beamAzimuth);
//    mat = GLKMatrix4RotateX(mat, -M_PI_2 - beamElevation);
    mat = GLKMatrix4MakeXRotation(-M_PI_2 - beamElevation);
    mat = GLKMatrix4RotateZ(mat, beamAzimuth);
    beamModelViewProjection = GLKMatrix4Multiply(beamProjection, mat);
    
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
    
    [overlayRenderer setModelViewProjection:hudProjection];
}


- (void)resetViewParameters
{
    range = resetRange;
    modelRotate = resetModelRotate;
    viewParametersNeedUpdate = true;
}

- (void)topView
{
    modelRotate = GLKMatrix4MakeRotation(M_PI_2, 1.0f, 0.0f, 0.0f);
    viewParametersNeedUpdate = true;
}


- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy
{
    cameraPitch += 2.0f * dy / height;
    if (cameraPitch > 2.0 * M_PI) {
        cameraPitch -= 2.0 * M_PI;
    } else if (cameraPitch < -2.0 * M_PI) {
        cameraPitch += 2.0 * M_PI;
    }
    cameraYaw += 2.0f * dx / width;
    if (cameraYaw > 2.0 * M_PI) {
        cameraYaw -= 2.0 * M_PI;
    } else if (cameraYaw < -2.0 * M_PI) {
        cameraYaw += 2.0 * M_PI;
    }
    viewParametersNeedUpdate = true;
}


- (void)magnify:(GLfloat)scale
{
    range = CLAMP(range * (1.0f - scale), RENDERER_NEAR_RANGE, RENDERER_FAR_RANGE);
    beamNearZ = CLAMP(beamNearZ * (1.0f + scale), 0.1f, 1000.0f);
	viewParametersNeedUpdate = true;
}


- (void)rotate:(GLfloat)angle
{
	//modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(-angle), modelRotate);
    cameraRoll -= angle;
    if (cameraRoll > 2.0 * M_PI) {
        cameraRoll -= 2.0 * M_PI;
    } else if (cameraRoll < -2.0 * M_PI) {
        cameraRoll += 2.0 * M_PI;
    }
	viewParametersNeedUpdate = true;
}


- (void)startSpinModel
{
	spinModel = 1;
}

- (void)stopSpinModel
{
	spinModel = 0;
}


- (void)toggleSpinModel
{
	spinModel = spinModel == 5 ? 0 : spinModel + 1;
}


- (void)toggleSpinModelReverse
{
	spinModel = spinModel == 0 ? 5 : spinModel - 1;
}


- (void)toggleHUDVisibility
{
    hudConfigGray = !hudConfigGray;
}


- (void)cycleForwardHUDConfig
{
    hudConfigDecimal = hudConfigDecimal == hudConfigLast ? 0 : hudConfigDecimal + 1;
    hudConfigGray = binaryToGray(hudConfigDecimal);
    statusMessageNeedsUpdate = true;
}


- (void)cycleReverseHUDConfig
{
    hudConfigDecimal = hudConfigDecimal == 0 ? hudConfigLast : hudConfigDecimal - 1;
    hudConfigGray = binaryToGray(hudConfigDecimal);
    statusMessageNeedsUpdate = true;
}


- (void)showAllHUD
{
    hudConfigGray = hudConfigShowAll;
    hudConfigDecimal = grayToBinary(hudConfigGray);
}


- (void)toggleVFX
{
    applyVFX = !applyVFX;
}


- (void)toggleBlurSmallScatterer {
    fadeSmallScatterers = !fadeSmallScatterers;
}



- (void)cycleVFX
{
    int k;
    applyVFX = applyVFX >= 4 ? 0 : applyVFX + 1;
    // The following needs a better way to get organized
    switch (applyVFX) {
        case 1:
        case 2:
            backgroundOpacity = 0.12f;
            for (k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
                debrisRenderer[k].colors[3] = 0.05f;
            }
            break;
        default:
            if (debrisRenderer[0].count > 100000) {
                backgroundOpacity = 0.3f;
            } else {
                backgroundOpacity = 1.0f;
            }
            backgroundOpacity = 1.0f;
            for (k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
                debrisRenderer[k].colors[3] = 1.0f;
            }
            break;
    }
    statusMessageNeedsUpdate = true;
}


- (void)increaseBackgroundOpacity
{
    if (backgroundOpacity >= 0.01) {
        backgroundOpacity = MIN(1.0f, backgroundOpacity + 0.01f);
    } else {
        backgroundOpacity = MIN(0.101f, backgroundOpacity + 0.001f);
    }
    statusMessageNeedsUpdate = true;
}


- (void)decreaseBackgroundOpacity
{
    if (backgroundOpacity <= 0.1) {
        backgroundOpacity = MAX(0.001f, backgroundOpacity - 0.001f);
    } else {
        backgroundOpacity = MAX(0.01f, backgroundOpacity - 0.01f);
    }
    statusMessageNeedsUpdate = true;
}


- (void)cycleForwardColormap
{
    bodyRenderer[0].colormapIndex = bodyRenderer[0].colormapIndex >= bodyRenderer[0].colormapCount - 1 ? 0 : bodyRenderer[0].colormapIndex + 1;
    bodyRenderer[0].colormapIndexNormalized = ((GLfloat)bodyRenderer[0].colormapIndex + 0.5f) / bodyRenderer[0].colormapCount;
    statusMessageNeedsUpdate = true;
    colorbarNeedsUpdate = true;
}


- (void)cycleReverseColormap
{
    bodyRenderer[0].colormapIndex = bodyRenderer[0].colormapIndex <= 0 ? bodyRenderer[0].colormapCount - 1 : bodyRenderer[0].colormapIndex - 1;
    bodyRenderer[0].colormapIndexNormalized = ((GLfloat)bodyRenderer[0].colormapIndex + 0.5f) / bodyRenderer[0].colormapCount;
    statusMessageNeedsUpdate = true;
    colorbarNeedsUpdate = true;
}


- (void)setColormapTitle:(char *)title tickLabels:(NSArray *)labels positions:(GLfloat *)positions;
{
    colorbarTitle = title;
    colorbarTickPositions = positions;
    colorbarTickCount = (int)[labels count];
    for (int k = 0; k < colorbarTickCount; k++) {
        NSString *label = [labels objectAtIndex:k];
        strncpy(colorbarTickLabels[k], label.UTF8String, 16);
    }
    overlayNeedsUpdate = true;
}


- (void)cycleFBO
{
    ifbo = ifbo >= 4 ? 0 : ifbo + 1;
    statusMessageNeedsUpdate = true;
}


- (void)cycleFBOReverse
{
    ifbo = ifbo == 0 ? 4 : ifbo - 1;
    statusMessageNeedsUpdate = true;
}


- (void)setOverlayText:(NSString *)bodyText withTitle:(NSString *)title
{
    NSColor *color1 = [NSColor colorWithWhite:0.0f alpha:0.65f];
    NSColor *color2 = [NSColor colorWithRed:1.0f green:0.8f blue:0.2f alpha:1.0f];
    NSColor *color3 = [NSColor colorWithRed:0.5f green:0.9f blue:1.0f alpha:1.0f];
    
    NSDictionary *bodyAtts = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont fontWithName:@"Menlo Bold" size:12.0f], NSFontAttributeName,
                               color3, NSForegroundColorAttributeName,
                               nil];
    
    NSSize bodySize = [bodyText sizeWithAttributes:bodyAtts];
    
    // The overall canvas size in points
    NSRect drawRect = NSMakeRect(20.0f, 80.0f, ceilf(bodySize.width + 30.0f), ceilf(bodySize.height + 50.0f));
    [overlayRenderer setDrawRect:drawRect];
    [overlayRenderer beginCanvas];
    
    // CoreGraphics API for drawing
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    // Black translucent background
    NSRect rect = CGRectMake(0.0f, 0.0f, drawRect.size.width, drawRect.size.height - 13.0f);
    
    CGContextSetFillColorWithColor(context, color1.CGColor);
    CGContextFillRect(context, rect);
    
    rect = CGRectInset(rect, 3.0f, 3.0f);
    //    CGContextSetStrokeColorWithColor(context, [NSColor whiteColor].CGColor);
    //    CGContextSetLineWidth(context, 1.0f);
    //    CGContextStrokeRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, color2.CGColor);
    CGContextSetLineWidth(context, 2.0f);
    CGContextStrokeRect(context, rect);
    
    NSDictionary *atts = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSFont boldSystemFontOfSize:20.0f], NSFontAttributeName,
                          color2, NSForegroundColorAttributeName,
                          nil];
    
    CGSize titleSize = [title sizeWithAttributes:atts];
    
    rect = CGRectMake(20.0f, drawRect.size.height - titleSize.height - 5.0f, ceilf(titleSize.width), ceilf(titleSize.height));
    rect = CGRectInset(rect, -8.0f, -4.0f);
    CGContextSetFillColorWithColor(context, color1.CGColor);
    CGContextClearRect(context, rect);
    CGContextFillRect(context, rect);
    
    [title drawAtPoint:CGPointMake(20.0f, drawRect.size.height - titleSize.height - 3.0f) withAttributes:atts];

    [bodyText drawAtPoint:CGPointMake(15.0, 15.0) withAttributes:bodyAtts];

    [overlayRenderer endCanvas];
    
    overlayNeedsUpdate = true;
}

@end
