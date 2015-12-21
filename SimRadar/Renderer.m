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
- (void)allocateVBO;
- (GLKTextureInfo *)loadTexture:(NSString *)filename;
- (void)updateStatusMessage;
- (void)measureFPS;

@end

@implementation Renderer

@synthesize delegate;
@synthesize resetRange;
@synthesize resetModelRotate;
@synthesize width, height;
@synthesize beamAzimuth, beamElevation;
@synthesize showHUD;

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
    
    viewParametersNeedUpdate = TRUE;
}


- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size
{
	if (gridRenderer.positions == NULL) {
		//NSLog(@"Allocating grid lines");
		gridRenderer.positions = (GLfloat *)malloc(128 * sizeof(GLfloat));  // More than enough
	}
	//NSLog(@"grid @ (%.1f, %.1f, %.1f)  (%.1f, %.1f, %.1f)", origin[0], origin[1], origin[2], size[0], size[1], size[2]);
	gridRenderer.positions[0]  = origin[0];
	gridRenderer.positions[1]  = origin[1];
	gridRenderer.positions[2]  = origin[2];
	gridRenderer.positions[3]  = 1.0f;
	gridRenderer.positions[4]  = origin[0] + size[0];
	gridRenderer.positions[5]  = origin[1];
	gridRenderer.positions[6]  = origin[2];
	gridRenderer.positions[7]  = 1.0f;

	gridRenderer.positions[8]  = origin[0];
	gridRenderer.positions[9]  = origin[1];
	gridRenderer.positions[10] = origin[2];
	gridRenderer.positions[11] = 1.0f;
	gridRenderer.positions[12] = origin[0];
	gridRenderer.positions[13] = origin[1] + size[1];
	gridRenderer.positions[14] = origin[2];
	gridRenderer.positions[15] = 1.0f;

	gridRenderer.positions[16] = origin[0] + size[0];
	gridRenderer.positions[17] = origin[1];
	gridRenderer.positions[18] = origin[2];
	gridRenderer.positions[19] = 1.0f;
	gridRenderer.positions[20] = origin[0] + size[0];
	gridRenderer.positions[21] = origin[1] + size[1];
	gridRenderer.positions[22] = origin[2];
	gridRenderer.positions[23] = 1.0f;

	gridRenderer.positions[24] = origin[0];
	gridRenderer.positions[25] = origin[1] + size[1];
	gridRenderer.positions[26] = origin[2];
	gridRenderer.positions[27] = 1.0f;
	gridRenderer.positions[28] = origin[0] + size[0];
	gridRenderer.positions[29] = origin[1] + size[1];
	gridRenderer.positions[30] = origin[2];
	gridRenderer.positions[31] = 1.0f;

	gridRenderer.positions[32] = origin[0];
	gridRenderer.positions[33] = origin[1];
	gridRenderer.positions[34] = origin[2] + size[2];
	gridRenderer.positions[35] = 1.0f;
	gridRenderer.positions[36] = origin[0] + size[0];
	gridRenderer.positions[37] = origin[1];
	gridRenderer.positions[38] = origin[2] + size[2];
	gridRenderer.positions[39] = 1.0f;
	
	gridRenderer.positions[40] = origin[0];
	gridRenderer.positions[41] = origin[1];
	gridRenderer.positions[42] = origin[2] + size[2];
	gridRenderer.positions[43] = 1.0f;
	gridRenderer.positions[44] = origin[0];
	gridRenderer.positions[45] = origin[1] + size[1];
	gridRenderer.positions[46] = origin[2] + size[2];
	gridRenderer.positions[47] = 1.0f;
	
	gridRenderer.positions[48] = origin[0] + size[0];
	gridRenderer.positions[49] = origin[1];
	gridRenderer.positions[50] = origin[2] + size[2];
	gridRenderer.positions[51] = 1.0f;
	gridRenderer.positions[52] = origin[0] + size[0];
	gridRenderer.positions[53] = origin[1] + size[1];
	gridRenderer.positions[54] = origin[2] + size[2];
	gridRenderer.positions[55] = 1.0f;
	
	gridRenderer.positions[56] = origin[0];
	gridRenderer.positions[57] = origin[1] + size[1];
	gridRenderer.positions[58] = origin[2] + size[2];
	gridRenderer.positions[59] = 1.0f;
	gridRenderer.positions[60] = origin[0] + size[0];
	gridRenderer.positions[61] = origin[1] + size[1];
	gridRenderer.positions[62] = origin[2] + size[2];
	gridRenderer.positions[63] = 1.0f;

	gridRenderer.positions[64] = origin[0];
	gridRenderer.positions[65] = origin[1];
	gridRenderer.positions[66] = origin[2];
	gridRenderer.positions[67] = 1.0f;
	gridRenderer.positions[68] = origin[0];
	gridRenderer.positions[69] = origin[1];
	gridRenderer.positions[70] = origin[2] + size[2];
	gridRenderer.positions[71] = 1.0f;
	
	gridRenderer.positions[72] = origin[0] + size[0];
	gridRenderer.positions[73] = origin[1];
	gridRenderer.positions[74] = origin[2];
	gridRenderer.positions[75] = 1.0f;
	gridRenderer.positions[76] = origin[0] + size[0];
	gridRenderer.positions[77] = origin[1];
	gridRenderer.positions[78] = origin[2] + size[2];
	gridRenderer.positions[79] = 1.0f;

	gridRenderer.positions[80] = origin[0];
	gridRenderer.positions[81] = origin[1] + size[1];
	gridRenderer.positions[82] = origin[2];
	gridRenderer.positions[83] = 1.0f;
	gridRenderer.positions[84] = origin[0];
	gridRenderer.positions[85] = origin[1] + size[1];
	gridRenderer.positions[86] = origin[2] + size[2];
	gridRenderer.positions[87] = 1.0f;

	gridRenderer.positions[88] = origin[0] + size[0];
	gridRenderer.positions[89] = origin[1] + size[1];
	gridRenderer.positions[90] = origin[2];
	gridRenderer.positions[91] = 1.0f;
	gridRenderer.positions[92] = origin[0] + size[0];
	gridRenderer.positions[93] = origin[1] + size[1];
	gridRenderer.positions[94] = origin[2] + size[2];
	gridRenderer.positions[95] = 1.0f;

	gridRenderer.count = 24;
	vbosNeedUpdate = TRUE;
}


- (void)setBodyCount:(GLuint)number forDevice:(GLuint)deviceId
{
	bodyRenderer[deviceId].count = number;
	vbosNeedUpdate = TRUE;
}


- (void)setPopulationTo:(GLuint)count forSpecies:(GLuint)speciesId forDevice:(GLuint)deviceId
{
    if (speciesId == 0) {
        NSLog(@"Invalid speciesId.");
        return;
    }
    debrisRenderer[speciesId].count = count;
    debrisRenderer[0].count = bodyRenderer[deviceId].count;
    for (int i = 1; i < RENDERER_MAX_DEBRIS_TYPES; i++) {
        debrisRenderer[0].count -= debrisRenderer[i].count;
    }
    statusMessageNeedsUpdate = TRUE;
}


- (void)setAnchorPoints:(GLfloat *)points number:(GLuint)number
{
	anchorRenderer.positions = points;
	anchorRenderer.count = number;
	vbosNeedUpdate = TRUE;
}


- (void)setAnchorLines:(GLfloat *)lines number:(GLuint)number
{
	anchorLineRenderer.positions = lines;
	anchorLineRenderer.count = number;
	vbosNeedUpdate = TRUE;
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
}


- (void)makePrimitives
{
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
        pos[i] *= 2.5f;
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


- (RenderResource)createRenderResourceFromProgram:(GLuint)program
{
	RenderResource resource;

    memset(&resource, 0, sizeof(RenderResource));

	glGenVertexArrays(1, &resource.vao);
	glBindVertexArray(resource.vao);

	resource.program = program;

	glUseProgram(resource.program);
	
	// Get matrix location
	resource.mvpUI = glGetUniformLocation(resource.program, "modelViewProjectionMatrix");
	if (resource.mvpUI < 0) {
		NSLog(@"No modelViewProjection Matrix %d", resource.mvpUI);
	}
	
	// Get color location
	resource.colorUI = glGetUniformLocation(resource.program, "drawColor");
	if (resource.colorUI < 0) {
		NSLog(@"No drawColor %d", resource.colorUI);
    } else {
        glUniform4f(resource.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }
	
	// Get attributes
    resource.colorAI = glGetAttribLocation(resource.program, "inColor");
    resource.positionAI = glGetAttribLocation(resource.program, "inPosition");
    resource.rotationAI = glGetAttribLocation(resource.program, "inRotation");
    resource.quaternionAI = glGetAttribLocation(resource.program, "inQuaternion");
    resource.translationAI = glGetAttribLocation(resource.program, "inTranslation");
    resource.textureCoordAI = glGetAttribLocation(resource.program, "inTextureCoord");

	return resource;
}


- (RenderResource)createRenderResourceFromVertexShader:(NSString *)vShader fragmentShader:(NSString *)fShader
{
	GLint param;

	RenderResource resource;
	
    const GLKMatrix4 idMat = GLKMatrix4Identity;

    memset(&resource, 0, sizeof(RenderResource));

    glGenVertexArrays(1, &resource.vao);
	glBindVertexArray(resource.vao);
	
	resource.program = glCreateProgram();
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"Shaders" ofType:nil];
	if (vShader) {
		[self attachShader:[shaderPath stringByAppendingString:[NSString stringWithFormat:@"/%@", vShader]] toProgram:resource.program];
	}
	if (fShader) {
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
	
	glUseProgram(resource.program);
	
    // Get MV matrix location
    resource.mvUI = glGetUniformLocation(resource.program, "modelViewMatrix");
    if (resource.mvUI < 0) {
        // NSLog(@"%@ shader has no modelView Matrix %d", vShader, resource.mvUI);
    } else {
        glUniformMatrix4fv(resource.mvUI, 1, GL_FALSE, idMat.m);
    }

    // Get MVP matrix location
	resource.mvpUI = glGetUniformLocation(resource.program, "modelViewProjectionMatrix");
	if (resource.mvpUI < 0) {
		NSLog(@"%@ shader has no modelViewProjection Matrix %d", vShader, resource.mvpUI);
	} else {
		glUniformMatrix4fv(resource.mvpUI, 1, GL_FALSE, idMat.m);
	}
	
	// Get color location
	resource.colorUI = glGetUniformLocation(resource.program, "drawColor");
	if (resource.colorUI < 0) {
		NSLog(@"%@ shader has no drawColor %d", vShader, resource.colorUI);
	} else {
        glUniform4f(resource.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }
	
    // Get size location
    resource.sizeUI = glGetUniformLocation(resource.program, "drawSize");
    if (resource.sizeUI >= 0) {
        //NSLog(@"%@ has drawSize", vShader);
        glUniform4f(resource.sizeUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }
    
    // Use drawTemplate1, drawTemplate2, etc. for various drawing shapes; All to TEXTURE0
	if ((resource.textureUI = glGetUniformLocation(resource.program, "drawTemplate1")) >= 0) {
        //resource.texture = [self loadTexture:@"texture_32.png"];
        //resource.texture = [self loadTexture:@"sphere1.png"];
        resource.texture = [self loadTexture:@"disc64.png"];
        resource.textureID = [resource.texture name];
        glUniform1i(resource.textureUI, 0);
//        glActiveTexture(GL_TEXTURE0);
//        glBindTexture(GL_TEXTURE_2D, resource.textureID);
    } else if ((resource.textureUI = glGetUniformLocation(resource.program, "drawTemplate2")) >= 0) {
        //resource.texture = [self loadTexture:@"sphere64.png"];
        resource.texture = [self loadTexture:@"spot64.png"];
        //resource.texture = [self loadTexture:@"disc64.png"];
        resource.textureID = [resource.texture name];
        glUniform1i(resource.textureUI, 0);
    } else if ((resource.textureUI = glGetUniformLocation(resource.program, "diffuseTexture")) >= 0) {
        resource.texture = [self loadTexture:@"colormap.png"];
        resource.textureID = [resource.texture name];
        glUniform1i(resource.textureUI, 0);
    }
    
    // Get colormap location
    resource.colormapUI = glGetUniformLocation(resource.program, "colormapTexture");
    if (resource.colormapUI >= 0) {
        resource.colormap = [self loadTexture:@"colormap.png"];
        resource.colormapID = [resource.colormap name];
        resource.colormapCount = resource.colormap.height;
        resource.colormapIndex = 3;
        glUniform1i(resource.colormapUI, 1);  // TEXTURE1 for colormap
        #ifdef DEBUG_GL
        NSLog(@"Colormap has %d maps, each with %d colors", resource.colormap.height, resource.colormap.width);
        #endif
    }
    
	// Get attributes
	resource.colorAI = glGetAttribLocation(resource.program, "inColor");
    resource.positionAI = glGetAttribLocation(resource.program, "inPosition");
	resource.rotationAI = glGetAttribLocation(resource.program, "inRotation");
    resource.quaternionAI = glGetAttribLocation(resource.program, "inQuaternion");
	resource.translationAI = glGetAttribLocation(resource.program, "inTranslation");
    resource.textureCoordAI = glGetAttribLocation(resource.program, "inTextureCoord");

    // Others
    resource.modelViewProjection = GLKMatrix4Identity;
    
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
}


- (void)measureFPS
{
    int otic = itic;
    tics[itic] = [NSDate timeIntervalSinceReferenceDate];
    itic = itic == RENDERER_TIC_COUNT - 1 ? 0 : itic + 1;
    fps = (float)(RENDERER_TIC_COUNT - 1) / (tics[otic] - tics[itic]);
    snprintf(fpsString, sizeof(fpsString), "%.0f FPS", fps);
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
        
        //showHUD = TRUE;
        
        hudModelViewProjection = GLKMatrix4Identity;
        beamModelViewProjection = GLKMatrix4Identity;
        backgroundOpacity = RENDERER_DEFAULT_BODY_OPACITY;
        
        // Add device pixel ratio here
        devicePixelRatio = pixelRatio;
        NSLog(@"Renderer initialized with pixel ratio = %.1f", devicePixelRatio);
        
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
	if (gridRenderer.positions != NULL) {
		free(gridRenderer.positions);
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

- (void)allocateVAO:(GLuint)count
{
    clDeviceCount = count;
    
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

    instancedGeometryRenderer = [self createRenderResourceFromVertexShader:@"inst-geom.vsh" fragmentShader:@"inst-geom.fsh"];

    gridRenderer       = [self createRenderResourceFromVertexShader:@"line_sc.vsh" fragmentShader:@"line_sc.fsh"];
    anchorRenderer     = [self createRenderResourceFromVertexShader:@"anchor.vsh" fragmentShader:@"anchor.fsh"];
	anchorLineRenderer = [self createRenderResourceFromProgram:gridRenderer.program];
	hudRenderer        = [self createRenderResourceFromProgram:gridRenderer.program];
    meshRenderer       = [self createRenderResourceFromVertexShader:@"mesh.vsh" fragmentShader:@"mesh.fsh"];
    
    //NSLog(@"meshRenderer's drawColor @ %d / %d / %d", meshRenderer.colorUI, meshRenderer.positionAI, meshRenderer.textureCoordAI);

    const GLfloat colors[] = {
        1.00f, 1.00f, 1.00f,
        0.00f, 1.00f, 0.00f,
        1.00f, 0.40f, 1.00f,
        1.00f, 0.65f, 0.00f
    };
    
    for (int k = 0; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        debrisRenderer[k] = [self createRenderResourceFromProgram:instancedGeometryRenderer.program];
        debrisRenderer[k].colors = malloc(4 * sizeof(GLfloat));
        debrisRenderer[k].colors[0] = colors[(k % 4) * 3];
        debrisRenderer[k].colors[1] = colors[(k % 4) * 3 + 1];
        debrisRenderer[k].colors[2] = colors[(k % 4) * 3 + 2];
        debrisRenderer[k].colors[3] = 1.0f;
    }
	
    textRenderer = [GLText new];
    
#ifdef DEBUG_GL
	NSLog(@"VAOs = bodyRenderer:%d  instancedGeometryRenderer = %d  gridRenderer %d  anchorRenderer %d  anchorLineRendrer %d",
		  bodyRenderer[0].vao, instancedGeometryRenderer.vao, gridRenderer.vao, anchorRenderer.vao, anchorLineRenderer.vao);
#endif
    
	// Depth test will always be enabled
	//glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);

	// We will always cull back faces for better performance
	//glEnable(GL_CULL_FACE);
    glEnable(GL_TEXTURE_2D);
//    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);

	// Always use this clear color
	//glClearColor(0.0f, 0.2f, 0.25f, 1.0f);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    [self makePrimitives];
    
    // Tell whatever controller that the OpenGL context is ready for sharing and set up renderer's body count
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
	glBindVertexArray(gridRenderer.vao);

    glDeleteBuffers(1, gridRenderer.vbo);
	glGenBuffers(1, gridRenderer.vbo);

	glBindBuffer(GL_ARRAY_BUFFER, gridRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, gridRenderer.count * sizeof(cl_float4), gridRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(gridRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(gridRenderer.positionAI);
	
	
	// Scatter body
    for (i = 0; i < clDeviceCount; i++) {
        if (bodyRenderer[i].count == 0) {
            continue;
        }
        glBindVertexArray(bodyRenderer[i].vao);
        
        glDeleteBuffers(4, bodyRenderer[i].vbo);
        glGenBuffers(4, bodyRenderer[i].vbo);
        
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

    // Anchor
	glBindVertexArray(anchorRenderer.vao);
	
    glDeleteBuffers(1, anchorRenderer.vbo);
	glGenBuffers(1, anchorRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorRenderer.count * sizeof(cl_float4), anchorRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(anchorRenderer.positionAI);

	
	// Anchor Line
	glBindVertexArray(anchorLineRenderer.vao);

    glDeleteBuffers(1, anchorLineRenderer.vbo);
	glGenBuffers(1, anchorLineRenderer.vbo);

	glBindBuffer(GL_ARRAY_BUFFER, anchorLineRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorLineRenderer.count * sizeof(cl_float4), anchorLineRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorLineRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(anchorLineRenderer.positionAI);
	
	
    // HUD
	glBindVertexArray(hudRenderer.vao);
	
    glDeleteBuffers(1, hudRenderer.vbo);
	glGenBuffers(1, hudRenderer.vbo);
    
    float pos[] = {0.0f, 0.0f, 0.0f, 1.0f,   // First part is for the dark area
                   0.0f, 1.0f, 0.0f, 1.0f,
                   1.0f, 0.0f, 0.0f, 1.0f,
                   1.0f, 1.0f, 0.0f, 1.0f,
                   0.0f, 0.0f, 0.0f, 1.0f,   // Second part is for the outline
                   1.0f, 0.0f, 0.0f, 1.0f,
                   1.0f, 1.0f, 0.0f, 1.0f,
                   0.0f, 1.0f, 0.0f, 1.0f,
                   0.0f, 0.0f, 0.0f, 1.0f};
    
    glBindBuffer(GL_ARRAY_BUFFER, hudRenderer.vbo[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(pos), pos, GL_STATIC_DRAW);
    glVertexAttribPointer(hudRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(hudRenderer.positionAI);
	
	
    // Mesh 1 : colorbar
    glBindVertexArray(meshRenderer.vao);
    
    glDeleteBuffers(2, meshRenderer.vbo);
    glGenBuffers(2, meshRenderer.vbo);
    
    float texCoord[] = {0.0f, bodyRenderer[0].colormapIndexNormalized,
                        0.0f, bodyRenderer[0].colormapIndexNormalized,
                        1.0f, bodyRenderer[0].colormapIndexNormalized,
                        1.0f, bodyRenderer[0].colormapIndexNormalized,
                        0.0f, 0.0f,
                        0.0f, 0.0f,
                        0.0f, 0.0f,
                        0.0f, 0.0f,
                        0.0f, 0.0f};
    
    glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[0]);  // position
    glBufferData(GL_ARRAY_BUFFER, sizeof(pos), pos, GL_STATIC_DRAW);
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
	
	viewParametersNeedUpdate = TRUE;
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
    
    // Various Species
    for (int k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
        if (debrisRenderer[k].count == 0) {
            continue;
        }
        glBindVertexArray(debrisRenderer[k].vao);
        
        if (debrisRenderer[k].vbo[0]) {
            glDeleteBuffers(4, debrisRenderer[k].vbo);
        }
        glGenBuffers(4, debrisRenderer[k].vbo);
        
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
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_DYNAMIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].translationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].translationAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].translationAI);
        
        glBindBuffer(GL_ARRAY_BUFFER, debrisRenderer[k].vbo[3]);           // 4-th VBO for quaternion (rotation)
        glBufferData(GL_ARRAY_BUFFER, debrisRenderer[k].count * sizeof(cl_float4), NULL, GL_DYNAMIC_DRAW);
        glVertexAttribPointer(debrisRenderer[k].quaternionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
        glVertexAttribDivisor(debrisRenderer[k].quaternionAI, 1);
        glEnableVertexAttribArray(debrisRenderer[k].quaternionAI);
    }
}


- (void)render
{
    int i;
    static float theta = 0.0f;
    static float phase = 0.0f;
    
	if (vbosNeedUpdate) {
		vbosNeedUpdate = FALSE;
		[self allocateVBO];
	}
	
    if (statusMessageNeedsUpdate) {
        statusMessageNeedsUpdate = FALSE;
        [self updateBodyToDebrisMappings];
        [self updateStatusMessage];
    }
    
	if (spinModel) {
		//modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(0.001f * spinModel), modelRotate);
        modelRotate = GLKMatrix4Multiply(modelRotate, GLKMatrix4MakeYRotation(0.001f * spinModel));
        theta = theta + 0.005f;
		viewParametersNeedUpdate = TRUE;
	}
	
	if (viewParametersNeedUpdate) {
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
        NSLog(@"First frame <==============================");
    }
#endif
    
    [self measureFPS];
    
	// Tell the delgate I'm about to draw
	[delegate willDrawScatterBody];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
	
    // Grid
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindVertexArray(gridRenderer.vao);
	glUseProgram(gridRenderer.program);
    glUniform4f(gridRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
	glUniformMatrix4fv(gridRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawArrays(GL_LINES, 0, gridRenderer.count);

	// Anchor Lines
//	glBindVertexArray(anchorLineRenderer.vao);
//	glUseProgram(anchorLineRenderer.program);
//    glUniform4f(anchorLineRenderer.colorUI, 1.0f, 1.0f, 0.0f, phase);
//	glUniformMatrix4fv(anchorLineRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
//	glDrawArrays(GL_LINES, 0, anchorLineRenderer.count);

	// Anchors
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindVertexArray(anchorRenderer.vao);
    glUseProgram(anchorRenderer.program);
    glUniform4f(anchorRenderer.colorUI, 0.4f, 1.0f, 1.0f, phase);
    //glUniform4f(anchorRenderer.sizeUI, pixelsPerUnit, pixelsPerUnit, pixelsPerUnit, pixelsPerUnit);
    //glUniformMatrix4fv(anchorRenderer.mvUI, 1, GL_FALSE, modelView.m);
	glUniformMatrix4fv(anchorRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, anchorRenderer.textureID);
	glDrawArrays(GL_POINTS, 0, anchorRenderer.count);
    
	// The scatter bodies
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
    for (i = 0; i < clDeviceCount; i++) {
        glBindVertexArray(bodyRenderer[i].vao);
        //glPointSize(4.0f * pixelsPerUnit * devicePixelRatio);
        glUseProgram(bodyRenderer[i].program);
        glUniform4f(bodyRenderer[i].sizeUI, pixelsPerUnit * devicePixelRatio, 1.0f, 1.0f, 1.0f);
        glUniform4f(bodyRenderer[i].colorUI, bodyRenderer[i].colormapIndexNormalized, 1.0f, 1.0f, backgroundOpacity);
        glUniformMatrix4fv(bodyRenderer[i].mvpUI, 1, GL_FALSE, modelViewProjection.m);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].textureID);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, bodyRenderer[i].colormapID);
        glDrawArrays(GL_POINTS, 0, debrisRenderer[0].count); // Yes, debrisRenderer[0].count is used for the background.
    }
    glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);

    // Various debris types
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(instancedGeometryRenderer.program);
    glUniformMatrix4fv(instancedGeometryRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);

    for (i = 0; i < clDeviceCount; i++) {
        for (int k = 1; k < RENDERER_MAX_DEBRIS_TYPES > 0; k++) {
            if (debrisRenderer[k].count == 0) {
                continue;
            }
            // Update the VBOs by copy
            glBindVertexArray(debrisRenderer[k].vao);
            
            glUniform4f(instancedGeometryRenderer.colorUI, debrisRenderer[k].colors[0], debrisRenderer[k].colors[1], debrisRenderer[k].colors[2], debrisRenderer[k].colors[3]);
            
            glBindBuffer(GL_COPY_READ_BUFFER, bodyRenderer[i].vbo[0]);             // positions of simulation particles
            glBindBuffer(GL_COPY_WRITE_BUFFER, debrisRenderer[k].vbo[2]);          // translations of species[k]
            glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, debrisRenderer[k].sourceOffset * sizeof(cl_float4), 0, debrisRenderer[k].count * sizeof(cl_float4));
            
            glBindBuffer(GL_COPY_READ_BUFFER, bodyRenderer[i].vbo[2]);             // quaternions of simulation particles
            glBindBuffer(GL_COPY_WRITE_BUFFER, debrisRenderer[k].vbo[3]);          // quaternions of species[k]
            glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, debrisRenderer[k].sourceOffset * sizeof(cl_float4), 0, debrisRenderer[k].count * sizeof(cl_float4));
            
            glDrawElementsInstanced(debrisRenderer[k].drawMode, debrisRenderer[k].instanceSize, GL_UNSIGNED_INT, NULL, debrisRenderer[k].count);
        }
    }
    
    if (showHUD) {
        // HUD Background & Outline
        glBindVertexArray(hudRenderer.vao);
        glUseProgram(hudRenderer.program);
        glUniform4f(hudRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.8f);
        glUniformMatrix4fv(hudRenderer.mvpUI, 1, GL_FALSE, hudModelViewProjection.m);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glUniform4f(hudRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
        glDrawArrays(GL_LINE_STRIP, 4, 5);
        
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
            glUniform4f(instancedGeometryRenderer.colorUI, debrisRenderer[k].colors[0], debrisRenderer[k].colors[1], debrisRenderer[k].colors[2], debrisRenderer[k].colors[3]);
            glDrawElementsInstanced(GL_LINE_STRIP, debrisRenderer[k].instanceSize, GL_UNSIGNED_INT, NULL, debrisRenderer[k].count);
        }

        glBindVertexArray(anchorLineRenderer.vao);
        glUseProgram(anchorLineRenderer.program);
        glUniform4f(anchorLineRenderer.colorUI, 1.0f, 1.0f, 0.0f, 0.8f);
        glUniformMatrix4fv(anchorLineRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
        glDrawArrays(GL_LINES, 0, anchorLineRenderer.count);
        
        glBindVertexArray(gridRenderer.vao);
        glUseProgram(gridRenderer.program);
        glUniform4f(gridRenderer.colorUI, 0.4f, 1.0f, 1.0f, 0.8f);
        glUniformMatrix4fv(gridRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
        glDrawArrays(GL_LINES, 0, gridRenderer.count);
    }
    
    glViewport(0, 0, width * devicePixelRatio, height * devicePixelRatio);
    
#ifdef DEBUG_GL
    [textRenderer showTextureMap];
#endif
    
    // Text
    glActiveTexture(GL_TEXTURE0);

    snprintf(statusMessage[2], 256, "Frame %d", iframe);
    
    [textRenderer drawText:"SimRadar" origin:NSMakePoint(25.0f, height - 60.0f) scale:0.5f red:0.2f green:1.0f blue:0.9f alpha:1.0f];
    [textRenderer drawText:statusMessage[0] origin:NSMakePoint(25.0f, height - 90.0f) scale:0.3f];
    [textRenderer drawText:statusMessage[1] origin:NSMakePoint(25.0f, height - 120.0f) scale:0.3f];
    [textRenderer drawText:statusMessage[2] origin:NSMakePoint(25.0f, height - 150.0f) scale:0.3f];

#ifndef GEN_IMG
    [textRenderer drawText:fpsString origin:NSMakePoint(width - 30.0f, 20.0f) scale:0.333f red:1.0f green:0.9f blue:0.2f alpha:1.0f align:GLTextAlignmentRight];
#endif
    
    if (showHUD) {
        snprintf(statusMessage[3], 128, "EL %.2f   AZ %.2f", beamElevation / M_PI * 180.0f, beamAzimuth / M_PI * 180.0f);
        [textRenderer drawText:statusMessage[3] origin:NSMakePoint(hudOrigin.x + 15.0f, hudOrigin.y + 15.0f) scale:0.25f];
    }

    // Colorbar
    glBindVertexArray(hudRenderer.vao);
    glUseProgram(hudRenderer.program);
    glUniformMatrix4fv(hudRenderer.mvpUI, 1, GL_FALSE, meshRenderer.modelViewProjectionOffTwo.m);
    glUniform4f(hudRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.6f);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glUniform4f(hudRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINE_STRIP, 4, 5);

    glBindVertexArray(meshRenderer.vao);
    glUseProgram(meshRenderer.program);
    if (colorbarNeedsUpdate) {
        float texCoord[] = {0.0f, bodyRenderer[0].colormapIndexNormalized,
            0.0f, bodyRenderer[0].colormapIndexNormalized,
            1.0f, bodyRenderer[0].colormapIndexNormalized,
            1.0f, bodyRenderer[0].colormapIndexNormalized,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f,
            0.0f, 0.0f};
        glBindBuffer(GL_ARRAY_BUFFER, meshRenderer.vbo[1]);  // textureCoord
        glBufferData(GL_ARRAY_BUFFER, sizeof(texCoord), texCoord, GL_STATIC_DRAW);
    }
    glUniformMatrix4fv(meshRenderer.mvpUI, 1, GL_FALSE, meshRenderer.modelViewProjection.m);
    glUniform4f(meshRenderer.colorUI, 1.0f, 1.0f, 1.0f, 0.9f);
    glBindTexture(GL_TEXTURE_2D, meshRenderer.textureID);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindVertexArray(0);
    glUseProgram(0);
    iframe++;
}

#pragma mark -
#pragma mark Interaction

- (void)updateViewParameters {

    GLfloat near = 2.0f / range * modelCenter.y;
    
//    glLineWidth(2.0f * devicePixelRatio);
    
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
    //float ch = MIN(MAX(roundf(0.0125f * width), 16.0f), 30.0f);
    
    mat = GLKMatrix4MakeTranslation(cx, cy, 0.0f);
    mat = GLKMatrix4Scale(mat, cw, ch, 1.0f);
    meshRenderer.modelViewProjection = GLKMatrix4Multiply(hudProjection, mat);

    mat = GLKMatrix4MakeTranslation(cx - 0.5f, cy - 0.5f, 0.0f);
    mat = GLKMatrix4Scale(mat, cw + 1.0f, ch + 1.0f, 1.0f);
    meshRenderer.modelViewProjectionOffOne = GLKMatrix4Multiply(hudProjection, mat);

    mat = GLKMatrix4MakeTranslation(cx - 1.5f, cy - 1.5f, 0.0f);
    mat = GLKMatrix4Scale(mat, cw + 3.0f, ch + 3.0f, 1.0f);
    meshRenderer.modelViewProjectionOffTwo = GLKMatrix4Multiply(hudProjection, mat);
    
    [textRenderer setModelViewProjection:hudProjection];
}


- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy
{
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(2.0f * dx / width), modelRotate);
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(2.0f * dy / height), modelRotate);
}


- (void)magnify:(GLfloat)scale
{
	range = MIN(RENDERER_FAR_RANGE, MAX(RENDERER_NEAR_RANGE, range * (1.0f - scale)));
	viewParametersNeedUpdate = TRUE;
}


- (void)rotate:(GLfloat)angle
{
	if (angle > 2.0 * M_PI) {
		angle -= 2.0 * M_PI;
	} else if (angle < -2.0 * M_PI) {
		angle += 2.0 * M_PI;
	}
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeZRotation(angle), modelRotate);
	viewParametersNeedUpdate = TRUE;
}


- (void)resetViewParameters
{
    range = resetRange;
    modelRotate = resetModelRotate;
    
//    iframe = 0;
    
	viewParametersNeedUpdate = TRUE;
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
    showHUD = !showHUD;
}


- (void)increaseBackgroundOpacity
{
    backgroundOpacity = MIN(1.0f, backgroundOpacity + 0.01f);
    statusMessageNeedsUpdate = TRUE;
}


- (void)decreaseBackgroundOpacity
{
    backgroundOpacity = MAX(0.01f, backgroundOpacity - 0.01f);
    statusMessageNeedsUpdate = TRUE;
}


- (void)cycleForwardColormap
{
    bodyRenderer[0].colormapIndex = bodyRenderer[0].colormapIndex >= bodyRenderer[0].colormapCount - 1 ? 0 : bodyRenderer[0].colormapIndex + 1;
    bodyRenderer[0].colormapIndexNormalized = ((GLfloat)bodyRenderer[0].colormapIndex + 0.5f) / bodyRenderer[0].colormapCount;
    statusMessageNeedsUpdate = TRUE;
    colorbarNeedsUpdate = TRUE;
}


- (void)cycleReverseColormap
{
    bodyRenderer[0].colormapIndex = bodyRenderer[0].colormapIndex <= 0 ? bodyRenderer[0].colormapCount - 1 : bodyRenderer[0].colormapIndex - 1;
    bodyRenderer[0].colormapIndexNormalized = ((GLfloat)bodyRenderer[0].colormapIndex + 0.5f) / bodyRenderer[0].colormapCount;
    statusMessageNeedsUpdate = TRUE;
    colorbarNeedsUpdate = TRUE;
}

@end
