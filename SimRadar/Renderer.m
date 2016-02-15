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

@synthesize titleString, subtitleString;
@synthesize delegate;
@synthesize resetRange;
@synthesize resetModelRotate;
@synthesize width, height;
@synthesize beamAzimuth, beamElevation;
@synthesize showDebrisAttributes;

#pragma mark -
#pragma mark Properties

- (void)setRange:(float)newRange
{
	projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, RENDERER_NEAR_RANGE, RENDERER_FAR_RANGE);
}


- (void)setSize:(CGSize)size
{
	width = (GLsizei)size.width;
	height = (GLsizei)size.height;
	
	glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
	
	aspectRatio = size.width / size.height;
	
	[self setRange:10.0f];
    
    viewParametersNeedUpdate = true;
    fboNeedsUpdate = true;
}


- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size
{
	//NSLog(@"grid @ (%.1f, %.1f, %.1f)  (%.1f, %.1f, %.1f)", origin[0], origin[1], origin[2], size[0], size[1], size[2]);
    
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


- (void)setBodyCount:(GLuint)number forDevice:(GLuint)deviceId
{
	bodyRenderer[deviceId].count = number;
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
        pos[i] *= 5.5f;
    }
    prim->instanceSize = 7;
    GLuint ind0[] = {5, 1, 2, 0, 5, 3, 4};
    memcpy(prim->indices, ind0, 7 * sizeof(GLuint));
    prim->drawMode = GL_LINE_STRIP;


    // Box
    
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
        pos[4 * i + 1] *= 5.0f;
        pos[4 * i + 2] *= 9.0f;
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


    // Stick
    
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
    pos[32] =  0.0f;   pos[33] = -1.3f;   pos[34] =  0.0f;   pos[35] = 0.0f;
    pos[36] =  0.0f;   pos[37] =  1.1f;   pos[38] =  0.0f;   pos[39] = 0.0f;
    for (int i = 0; i < 10; i++) {
        pos[4 * i    ] *= 0.4f;
        pos[4 * i + 1] *= 8.0f;
        pos[4 * i + 2] *= 1.0f;
    }
    prim->vertexSize = 40 * sizeof(GLfloat);
    GLuint ind2[] = {
        0, 1, 1, 3, 3, 2, 2, 0,
        4, 5, 5, 7, 7, 6, 6, 4,
        0, 4, 1, 5, 3, 7, 2, 6,
        0, 8, 4, 8, 5, 8, 1, 8,
        2, 9, 3, 9, 7, 9, 6, 9
    };
    prim->instanceSize = sizeof(ind2) / sizeof(GLuint);
    memcpy(prim->indices, ind2, prim->instanceSize * sizeof(GLuint));
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


- (void)updateStatusMessage
{
    snprintf(statusMessage[0],
             sizeof(statusMessage[0]),
             "@ %s Particles",
             [GLText commaint:(double)bodyRenderer[0].count decimals:0]);
    snprintf(statusMessage[1],
             sizeof(statusMessage[1]),
             "Debris Pop. %d, %d, %d    Color %d / %.3f",
             debrisRenderer[1].count,
             debrisRenderer[2].count,
             debrisRenderer[3].count,
             bodyRenderer[0].colormapIndex,
             backgroundOpacity);
    snprintf(statusMessage[2],
             sizeof(statusMessage[2]),
             "HUD %d%d%d / %d", (hudConfigGray & 0x04) >> 2, (hudConfigGray & 0x02) >> 1, hudConfigGray & 0x01, hudConfigDecimal);
}


- (void)measureFPS
{
    int otic = itic;
    tics[itic] = [NSDate timeIntervalSinceReferenceDate];
    itic = itic == RENDERER_TIC_COUNT - 1 ? 0 : itic + 1;
    fps = (float)(RENDERER_TIC_COUNT - 1) / (tics[otic] - tics[itic]);
    snprintf(fpsString, sizeof(fpsString), "%.0f FPS", fps);
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
        size_t next_vertex_count = (lineRenderer.segmentMax + number + 1023) / 1024;
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
        
        iframe = -1;
        
        resetRange = 5000.0f;
        resetModelRotate = GLKMatrix4Identity;
        //resetModelRotate = GLKMatrix4MakeRotation(1.0, 0.0f, 1.0f, 1.0f);
        
        hudConfigGray = hudConfigShowAnchors | hudConfigShowGrid;
        
        hudModelViewProjection = GLKMatrix4Identity;
        beamModelViewProjection = GLKMatrix4Identity;
        backgroundOpacity = RENDERER_DEFAULT_BODY_OPACITY;
        
        // Add device pixel ratio here
        devicePixelRatio = pixelRatio;
        NSLog(@"Renderer initialized with pixel ratio = %.1f", devicePixelRatio);
        
        self.titleString = @"Renderer";
        
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
	if (lineRenderer.positions != NULL) {
		free(lineRenderer.positions);
        free(lineRenderer.segmentOrigins);
        free(lineRenderer.segmentLengths);
	}
	if (instancedGeometryRenderer.positions != NULL) {
		free(instancedGeometryRenderer.positions);
	}
    for (int k=0; k<RENDERER_MAX_DEBRIS_TYPES; k++) {
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
    
    // Local rotating color table
    const GLfloat colors[][4] = {
        {1.00f, 1.00f, 1.00f, 1.00f},
        {0.00f, 1.00f, 0.00f, 1.00f},
        {1.00f, 0.20f, 1.00f, 1.00f},
        {1.00f, 0.65f, 0.00f, 1.00f}
    };
    

    // Get the GL version
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &GLSLVersion);
	
	NSLog(@"%s / %s / %.2f / %u GPU(s)", glGetString(GL_RENDERER), glGetString(GL_VERSION), GLSLVersion, clDeviceCount);

	GLint v[4] = {0, 0, 0, 0};
	glGetIntegerv(GL_ALIASED_LINE_WIDTH_RANGE, v);
	glGetIntegerv(GL_SMOOTH_LINE_WIDTH_RANGE, &v[2]);
	NSLog(@"Aliased / smoothed line width: %d ... %d / %d ... %d", v[0], v[1], v[2], v[3]);
    
	// Set up VAO and shaders
    int i = 0;

    // Only one renderer program needs to be created and the others can share the same program
    bodyRenderer[i] = [self createRenderResourceFromVertexShader:@"spheroid.vsh" fragmentShader:@"spheroid.fsh"];

    // Make body renderer's color a bit translucent
    glUniform4f(bodyRenderer[i].colorUI, 1.0f, 1.0f, 1.0f, 0.75f);
    
    // Set default colormap index
    bodyRenderer[i].colormapIndex = RENDERER_DEFAULT_BODY_COLOR_INDEX;
    bodyRenderer[i].colormapIndexNormalized = ((GLfloat)bodyRenderer[i].colormapIndex + 0.5f) / bodyRenderer[i].colormapCount;

    // Make copies of render resource but use the same program
    for (i = 1; i < clDeviceCount; i++) {
        bodyRenderer[i] = [self createRenderResourceFromProgram:bodyRenderer[0].program];
    }

    // This is the renderer that uses GL instancing
    //instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom.vsh" fragmentShader:@"inst-geom.fsh"];
    instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom-t.vsh" fragmentShader:@"inst-geom.fsh"];
    glUniform4f(instancedGeometryRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);

    for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        debrisRenderer[k] = [self createRenderResourceFromProgram:instancedGeometryRenderer.program];
        debrisRenderer[k].colors = malloc(4 * sizeof(GLfloat));
        debrisRenderer[k].colors[0] = colors[(k % 4)][0];
        debrisRenderer[k].colors[1] = colors[(k % 4)][1];
        debrisRenderer[k].colors[2] = colors[(k % 4)][2];
        debrisRenderer[k].colors[3] = colors[(k % 4)][3];
    }
    
    lineRenderer   = [self createRenderResourceFromVertexShader:@"line_sc.vsh" fragmentShader:@"line_sc.fsh"];
    anchorRenderer = [self createRenderResourceFromVertexShader:@"anchor.vsh" fragmentShader:@"anchor.fsh"];
    meshRenderer   = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"mesh.fsh"];
    frameRenderer  = [self createRenderResourceFromProgram:meshRenderer.program];
    blurRenderer   = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"blur.fsh"];
    
    //NSLog(@"Each renderer uses %zu bytes", sizeof(RenderResource));
    //NSLog(@"meshRenderer's drawColor @ %d / %d / %d", meshRenderer.colorUI, meshRenderer.positionAI, meshRenderer.textureCoordAI);

    textRenderer = [GLText new];
    
#ifdef DEBUG_GL
	NSLog(@"VAOs = bodyRenderer:%d  instancedGeometryRenderer = %d  lineRenderer %d  anchorRenderer %d",
		  bodyRenderer[0].vao, instancedGeometryRenderer.vao, lineRenderer.vao, anchorRenderer.vao);
#endif

    [self allocateFBO];
    
    // Some OpenGL features
	glEnable(GL_BLEND);
//    glEnable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);

	// Always use this clear color: I use 16-bit internal FBO texture format, so minimum can only be sqrt ( 1 / 65536 ) = 1 / 256
	//glClearColor(0.0f, 0.2f, 0.25f, 1.0f);
	//glClearColor(0.0f, 0.0f, 0.0f, 0.01f);
    glClearColor(0.0f, 0.0f, 0.0f, 4.0f / 256.0f);

    [self makePrimitives];
    
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
    
    // Grid lines
	glBindVertexArray(lineRenderer.vao);

    glDeleteBuffers(1, lineRenderer.vbo);
	glGenBuffers(1, lineRenderer.vbo);

	glBindBuffer(GL_ARRAY_BUFFER, lineRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, lineRenderer.segmentNextOrigin * 4 * sizeof(GLfloat), lineRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(lineRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(lineRenderer.positionAI);
	
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
    
    // Use .w element for anchor size, scale by pixel ratio for Retina displays
    if (anchorRenderer.positions[3] == 1.0f && devicePixelRatio > 1.0f) {
        for (i = 0; i < anchorRenderer.count; i++) {
            anchorRenderer.positions[4 * i + 3] *= devicePixelRatio;
        }
    }

    // Anchors
	glBindVertexArray(anchorRenderer.vao);
	
    glDeleteBuffers(1, anchorRenderer.vbo);
	glGenBuffers(1, anchorRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorRenderer.count * sizeof(cl_float4), anchorRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(anchorRenderer.positionAI);
	
    // Mesh 1 : colorbar
    glBindVertexArray(meshRenderer.vao);
    
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
    
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[0]);  // position
    //glBufferData(GL_ARRAY_BUFFER, sizeof(pos), pos, GL_STATIC_DRAW);
    //NSLog(@"basic rect is length %u", lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle]);
    glBufferData(GL_ARRAY_BUFFER, lineRenderer.segmentLengths[RendererLineSegmentBasicRectangle] * 4 * sizeof(GLfloat), &lineRenderer.positions[lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle]], GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.positionAI);

    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[1]);  // textureCoord
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoord), texCoord, GL_STATIC_DRAW);
    glVertexAttribPointer(meshRenderer.textureCoordAI, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(meshRenderer.textureCoordAI);

	#ifdef DEBUG
	NSLog(@"VBOs   %d %d %d   %d %d %d   %d ...",
          bodyRenderer[0].vbo[0], bodyRenderer[0].vbo[1], bodyRenderer[0].vbo[2],
          bodyRenderer[1].vbo[0], bodyRenderer[1].vbo[1], bodyRenderer[1].vbo[2],
          anchorRenderer.vbo[0]);
	#endif
	
    GLuint vbos[RENDERER_MAX_VBO_GROUPS][8];
    for (int i=0; i<clDeviceCount; i++) {
        vbos[i][0] = bodyRenderer[i].vbo[0];
        vbos[i][1] = bodyRenderer[i].vbo[1];
        vbos[i][2] = bodyRenderer[i].vbo[2];
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
    for (int k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        if (debrisRenderer[k].count == 0) {
            continue;
        }
        glBindVertexArray(debrisRenderer[k].vao);
        
        if (debrisRenderer[k].vbo[0]) {
            glDeleteBuffers(5, debrisRenderer[k].vbo);
        }
        glGenBuffers(5, debrisRenderer[k].vbo);
        
        RenderPrimitive *prim = &primitives[(k + 2) % 3];

        debrisRenderer[k].instanceSize = prim->instanceSize;
        debrisRenderer[k].drawMode = prim->drawMode;
        
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[0]);           // 1-st VBO for geometry (primitive, we are instancing)
        glBufferData(GL_ARRAY_BUFFER, prim->vertexSize, prim->vertices, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glEnableVertexAttribArray(debrisRenderer[k].positionAI);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, debrisRenderer[k].vbo[1]);   // 2-nd VBO for position index
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, prim->instanceSize * sizeof(GLuint), prim->indices, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[2]);           // 3-rd VBO for translation
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].translationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].translationAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].translationAI);
        
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[3]);           // 4-th VBO for quaternion (rotation)
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].quaternionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].quaternionAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].quaternionAI);

        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[4]);           // 5-th VBO for color index
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
    for (i = 0; i < clDeviceCount; i++) {
        glBindVertexArray(bodyRenderer[i].vao);
        glUseProgram(bodyRenderer[i].program);
        glUniform4f(bodyRenderer[i].sizeUI, pixelsPerUnit * devicePixelRatio, 1.0f, 1.0f, 1.0f);
        glUniform4f(bodyRenderer[i].colorUI, bodyRenderer[i].colormapIndexNormalized, 1.0f, 1.0f, backgroundOpacity);
        glUniformMatrix4fv(bodyRenderer[i].mvpUI, 1, GL_FALSE, modelViewProjection.m);
//        if (debrisRenderer[0].count > 100000) {
//            glUniform1i(bodyRenderer[i].pingPongUI, 1);
//        } else {
//            glUniform1i(bodyRenderer[i].pingPongUI, 0);
//        }
        glUniform1i(bodyRenderer[i].pingPongUI, blurSmallScatterers);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].textureID);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].colormapID);
        glDrawArrays(GL_POINTS, 0, debrisRenderer[0].count); // Yes, debrisRenderer[0].count is used for the background.
    }
    //glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);

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
    for (i = 0; i < clDeviceCount; i++) {
        for (k = 1; k < RENDERER_MAX_DEBRIS_TYPES > 0; k++) {
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
            glUniform4f(lineRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.8f);
            glDrawArrays(GL_TRIANGLE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle], 4);
            glUniform4f(lineRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
            glDrawArrays(GL_LINE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle] + 4, 5);
        }
        
        // Objects on HUD (beam's view)
        glViewport(hudOrigin.x * devicePixelRatio, hudOrigin.y * devicePixelRatio, hudSize.width * devicePixelRatio, hudSize.height * devicePixelRatio);

        // Draw the debris again
        glUseProgram(instancedGeometryRenderer.program);
        glUniformMatrix4fv(instancedGeometryRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
        for (int k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
            if (debrisRenderer[k].count == 0) {
                continue;
            }
            glBindVertexArray(debrisRenderer[k].vao);
            //glUniform4f(instancedGeometryRenderer.colorUI, debrisRenderer[k].colors[0], debrisRenderer[k].colors[1], debrisRenderer[k].colors[2], debrisRenderer[k].colors[3]);
            glDrawElementsInstanced(GL_LINE_STRIP, debrisRenderer[k].instanceSize, GL_UNSIGNED_INT, NULL, debrisRenderer[k].count);
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
        // Just the framebuffer for final presentation
        glUseProgram(frameRenderer.program);
        glUniformMatrix4fv(frameRenderer.mvpUI, 1, GL_FALSE, frameRenderer.modelViewProjection.m);
        glUniform4f(frameRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }

    // Show the framebuffer on the window
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(frameRenderer.program);
    glBindTexture(GL_TEXTURE_2D, frameBufferTextures[ifbo]);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glClear(GL_DEPTH_BUFFER_BIT);

    //glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);

    if (hudConfigGray & hudConfigShowAnchors) {
        // Anchors
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glBindVertexArray(anchorRenderer.vao);
        glUseProgram(anchorRenderer.program);
        glUniform4f(anchorRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
        //glUniformMatrix4fv(anchorRenderer.mvUI, 1, GL_FALSE, modelView.m);
        glUniformMatrix4fv(anchorRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, anchorRenderer.textureID);
        glDrawArrays(GL_POINTS, 0, anchorRenderer.count);
    }
    
#ifdef DEBUG_GL
    [textRenderer showTextureMap];
#endif

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Text
    snprintf(statusMessage[3], 256, "FBO %u   VFX %u  Frame %d", ifbo, applyVFX, iframe);
    
    NSPoint origin = NSMakePoint(25.0f, height - 60.0f);
    
    if (titleString) {
        [textRenderer drawText:[titleString UTF8String] origin:origin scale:0.5f red:0.2f green:1.0f blue:0.9f alpha:1.0f];
        origin.y -= 30.0f;
    }
    if (subtitleString) {
        [textRenderer drawText:[subtitleString UTF8String] origin:origin scale:0.3f];
        origin.y -= 30.0f;
    }
    [textRenderer drawText:statusMessage[0] origin:origin scale:0.3f];   origin.y -= 30.0f;
    [textRenderer drawText:statusMessage[1] origin:origin scale:0.3f];   origin.y -= 30.0f;
    [textRenderer drawText:statusMessage[2] origin:origin scale:0.3f];   origin.y -= 30.0f;
    [textRenderer drawText:statusMessage[3] origin:origin scale:0.3f];   origin.y -= 30.0f;

#ifndef GEN_IMG
    [textRenderer drawText:fpsString origin:NSMakePoint(width - 30.0f, 20.0f) scale:0.333f red:1.0f green:0.9f blue:0.2f alpha:1.0f align:GLTextAlignmentRight];
#endif
    
    if (hudConfigGray & hudConfigShowRadarView) {
        snprintf(statusMessage[4], 128, "EL %.2f   AZ %.2f", beamElevation / M_PI * 180.0f, beamAzimuth / M_PI * 180.0f);
        [textRenderer drawText:statusMessage[4] origin:NSMakePoint(hudOrigin.x + 15.0f, hudOrigin.y + 15.0f) scale:0.25f];
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
    glUniform4f(meshRenderer.colorUI, 1.0f, 1.0f, 1.0f, 0.9f);
    glBindTexture(GL_TEXTURE_2D, meshRenderer.textureID);
    glDrawArrays(GL_TRIANGLE_STRIP, lineRenderer.segmentOrigins[RendererLineSegmentBasicRectangle], 4);

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

    hudSize = CGSizeMake(roundf(aspectRatio * 250.0f), 250.0f);
    hudOrigin = CGPointMake(width - hudSize.width - 30.0f, height - hudSize.height - 30.0f);
    hudProjection = GLKMatrix4MakeOrtho(0.0f, width, 0.0f, height, 0.0f, 1.0f);
    mat = GLKMatrix4MakeTranslation(hudOrigin.x, hudOrigin.y, 0.0f);
    mat = GLKMatrix4Scale(mat, hudSize.width, hudSize.height, 1.0f);
    hudModelViewProjection = GLKMatrix4Multiply(hudProjection, mat);

    beamProjection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, MIN(RENDERER_NEAR_RANGE, 4.0f * near), RENDERER_FAR_RANGE);
    mat = GLKMatrix4Identity;
    mat = GLKMatrix4RotateY(mat, beamAzimuth);
    mat = GLKMatrix4RotateX(mat, -beamElevation);
    mat = GLKMatrix4RotateX(mat, -M_PI_2);
    beamModelViewProjection = GLKMatrix4Multiply(beamProjection, mat);
    
    float cx = roundf(0.25f * width);
    float cy = 25.0f;
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
}


- (void)resetViewParameters
{
    range = resetRange;
    modelRotate = resetModelRotate;
    
    viewParametersNeedUpdate = true;
}


- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy
{
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(2.0f * dx / width), modelRotate);
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(2.0f * dy / height), modelRotate);
    viewParametersNeedUpdate = true;
}


- (void)magnify:(GLfloat)scale
{
	range = MIN(RENDERER_FAR_RANGE, MAX(RENDERER_NEAR_RANGE, range * (1.0f - scale)));
	viewParametersNeedUpdate = true;
}


- (void)rotate:(GLfloat)angle
{
	if (angle > 2.0 * M_PI) {
		angle -= 2.0 * M_PI;
	} else if (angle < -2.0 * M_PI) {
		angle += 2.0 * M_PI;
	}
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeZRotation(angle), modelRotate);
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


- (void)toggleVFX
{
    applyVFX = !applyVFX;
}


- (void)toggleBlurSmallScatterer {
    blurSmallScatterers = !blurSmallScatterers;
}



- (void)cycleVFX
{
    applyVFX = applyVFX >= 4 ? 0 : applyVFX + 1;
    // The following needs a better way to get organized
    switch (applyVFX) {
        case 1:
        case 2:
            backgroundOpacity = 0.12f;
            for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
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
            for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
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

- (void)cycleFBO {
    ifbo = ifbo >= 4 ? 0 : ifbo + 1;
}

- (void)cycleFBOReverse {
    ifbo = ifbo == 0 ? 4 : ifbo - 1;
}

@end
