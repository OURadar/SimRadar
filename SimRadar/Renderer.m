//
//  Renderer.m
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "Renderer.h"

@interface Renderer ()

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
@synthesize width, height;
@synthesize beamAzimuth, beamElevation;

#pragma mark Properties

- (void)setRange:(float)newRange
{
	projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, RENDERER_NEAR_RANGE, RENDERER_FAR_RANGE);
}


- (void)setSize:(CGSize)size
{
	width = (GLsizei)size.width;
	height = (GLsizei)size.height;
	
	glViewport(0, 0, width, height);
	
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
	NSLog(@"grid @ (%.1f, %.1f, %.1f)  (%.1f, %.1f, %.1f)", origin[0], origin[1], origin[2], size[0], size[1], size[2]);
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


- (void)setBodyCount:(GLuint)number
{
	bodyRenderer.count = number;
	vbosNeedUpdate = TRUE;
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


- (void)makeOneLeaf
{
	if (leafRenderer.positions == NULL) {
		leafRenderer.positions = (GLfloat *)malloc(6 * sizeof(cl_float4));
	}
	
	leafRenderer.positions[0]  =  1.0f;   leafRenderer.positions[1]  =  0.0f;   leafRenderer.positions[2]  = 0.0f;   leafRenderer.positions[3]  = 0.0f;
	leafRenderer.positions[4]  = -1.0f;   leafRenderer.positions[5]  =  0.0f;   leafRenderer.positions[6]  = 0.0f;   leafRenderer.positions[7]  = 0.0f;
	leafRenderer.positions[8]  =  0.0f;   leafRenderer.positions[9]  =  2.0f;   leafRenderer.positions[10] = 0.0f;   leafRenderer.positions[11] = 0.0f;
	leafRenderer.positions[12] =  0.0f;   leafRenderer.positions[13] = -1.0f;   leafRenderer.positions[14] = 0.0f;   leafRenderer.positions[15] = 0.0f;
	leafRenderer.positions[16] =  0.0f;   leafRenderer.positions[17] = -1.0f;   leafRenderer.positions[18] = 0.5f;   leafRenderer.positions[19] = 0.0f;
	leafRenderer.positions[20] =  0.0f;   leafRenderer.positions[21] =  0.0f;   leafRenderer.positions[22] = 0.0f;   leafRenderer.positions[23] = 0.0f;

	leafRenderer.count = 1;
	
	for (int i=0; i<24; i++) {
		leafRenderer.positions[i] *= 40.0f;
	}
	
	vbosNeedUpdate = TRUE;
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

	resource.positions = NULL;
	resource.colors = NULL;
	resource.indices = NULL;
	
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
	}
	glUniform4f(resource.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
	
	// Get attributes
	resource.colorAI = glGetAttribLocation(resource.program, "inColor");
	resource.positionAI = glGetAttribLocation(resource.program, "inPosition");
	resource.rotationAI = glGetAttribLocation(resource.program, "inRotation");
	resource.translationAI = glGetAttribLocation(resource.program, "inTranslation");

	return resource;
}


- (RenderResource)createRenderResourceFromVertexShader:(NSString *)vShader fragmentShader:(NSString *)fShader
{
	GLint param;

	RenderResource resource;
	
	resource.positions = NULL;
	resource.colors = NULL;
	resource.indices = NULL;
	
	glGenVertexArrays(1, &resource.vao);
	glBindVertexArray(resource.vao);
	
	resource.program = glCreateProgram();
	if (vShader) {
		[self attachShader:[[NSBundle mainBundle] pathForResource:vShader ofType:@"vsh"] toProgram:resource.program];
	}
	if (fShader) {
		[self attachShader:[[NSBundle mainBundle] pathForResource:fShader ofType:@"fsh"] toProgram:resource.program];
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
	
	// Get matrix location
	resource.mvpUI = glGetUniformLocation(resource.program, "modelViewProjectionMatrix");
	if (resource.mvpUI < 0) {
		NSLog(@"No modelViewProjection Matrix %d", resource.mvpUI);
	} else {
		GLKMatrix4 idMat = GLKMatrix4Identity;
		glUniformMatrix4fv(resource.mvpUI, 1, GL_FALSE, idMat.m);
	}
	
	// Get color location
	resource.colorUI = glGetUniformLocation(resource.program, "drawColor");
	if (resource.colorUI < 0) {
		NSLog(@"No drawColor %d", resource.colorUI);
	} else {
        glUniform4f(resource.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
    }
	
	// Get texture location
	resource.textureUI = glGetUniformLocation(resource.program, "drawTexture");
	if (resource.textureUI < 0) {
		// NSLog(@"No drawTexture %d", resource.textureUI);
	} else {
        //resource.texture = [self loadTexture:@"texture_32.png"];
        //resource.texture = [self loadTexture:@"sphere1.png"];
        //resource.texture = [self loadTexture:@"depth.png"];
        //resource.texture = [self loadTexture:@"sphere64.png"];
		resource.texture = [self loadTexture:@"disc64.png"];
        resource.textureID = [resource.texture name];
        glUniform1i(resource.textureUI, resource.textureID);
    }
	
	// Get attributes
	resource.colorAI = glGetAttribLocation(resource.program, "inColor");
    resource.positionAI = glGetAttribLocation(resource.program, "inPosition");
	resource.rotationAI = glGetAttribLocation(resource.program, "inRotation");
	resource.translationAI = glGetAttribLocation(resource.program, "inTranslation");

//	NSLog(@"positionAI = %d", leafRenderer.positionAI);
//	NSLog(@"rotationAI = %d", leafRenderer.rotationAI);
//	NSLog(@"translationAI = %d", leafRenderer.translationAI);

	return resource;
}


- (GLKTextureInfo *)loadTexture:(NSString *)filename
{
    NSDictionary* options = @{[NSNumber numberWithBool:YES] : GLKTextureLoaderOriginBottomLeft};
    
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (texture == nil)
    {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    
    return texture;
}

- (void)updateStatusMessage
{
    snprintf(statusMessage[0],
             sizeof(statusMessage[0]),
             "@ %d Particles / %d Leaves",
             bodyRenderer.count,
             leafRenderer.count);
}

- (void)measureFPS
{
    int otic = itic;
    tics[itic] = [NSDate timeIntervalSinceReferenceDate];
    itic = itic == RENDERER_TIC_COUNT - 1 ? 0 : itic + 1;
    fps = (float)RENDERER_TIC_COUNT / (tics[otic] - tics[itic]);
    snprintf(fpsString, sizeof(fpsString), "%.0f FPS", fps);
}

#pragma mark -
#pragma mark Initializations & Deallocation

- (id)init
{
	self = [super init];
	if (self) {
		// View size in pixel counts
		width = 1;
		height = 1;
        spinModel = 1;
		aspectRatio = 1.0f;
        
        hudModelViewProjection = GLKMatrix4Identity;
        beamModelViewProjection = GLKMatrix4Identity;
        
		// View parameters
		[self resetViewParameters];
	}
	return self;
}


- (void)dealloc
{
	if (gridRenderer.positions != NULL) {
		free(gridRenderer.positions);
	}
	if (leafRenderer.positions != NULL) {
		free(leafRenderer.positions);
	}
	[super dealloc];
}

#pragma mark -
#pragma mark Methods

// This method is called right after the OpenGL context is initialized

- (void)allocateVAO
{
	// Get the GL version
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &GLSLVersion);
	
	NSLog(@"%s / %s / %.2f", glGetString(GL_RENDERER), glGetString(GL_VERSION), GLSLVersion);
	
	GLint v[4] = {0, 0, 0, 0};
	glGetIntegerv(GL_ALIASED_LINE_WIDTH_RANGE, v);
	glGetIntegerv(GL_SMOOTH_LINE_WIDTH_RANGE, &v[2]);
	NSLog(@"Aliased / smoothed line width: %d ... %d / %d ... %d", v[0], v[1], v[2], v[3]);
	
	// Set up VAO and shaders
	//bodyRenderer = [self createRenderResourceFromVertexShader:@"shape" fragmentShader:@"shape"];
    bodyRenderer = [self createRenderResourceFromVertexShader:@"square" fragmentShader:@"square"];
	gridRenderer = [self createRenderResourceFromVertexShader:@"shape_sc" fragmentShader:@"shape_sc"];
	anchorRenderer = [self createRenderResourceFromProgram:gridRenderer.program];
	anchorLineRenderer = [self createRenderResourceFromProgram:gridRenderer.program];
	leafRenderer = [self createRenderResourceFromVertexShader:@"leaf" fragmentShader:@"leaf"];
	hudRenderer = [self createRenderResourceFromProgram:gridRenderer.program];
	
	textRenderer = [GLText new];
	
	NSLog(@"VAOs = bodyRenderer %d  gridRenderer %d  anchorRenderer %d  anchorLineRendrer %d  leafRendrer = %d",
		  bodyRenderer.vao, gridRenderer.vao, anchorRenderer.vao, anchorLineRenderer.vao, leafRenderer.vao);
	// Depth test will always be enabled
	//glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);

	// We will always cull back faces for better performance
	//glEnable(GL_CULL_FACE);
    glEnable(GL_TEXTURE_2D);
    
	// Always use this clear color
	//glClearColor(0.0f, 0.2f, 0.25f, 1.0f);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	[self makeOneLeaf];
    
    // Tell whatever controller that the OpenGL context is ready for sharing and set up renderer's body count
	[delegate glContextVAOPrepared];

    [self updateStatusMessage];
}


- (void)allocateVBO
{
	#ifdef DEBUG
	NSLog(@"Allocating %d particles on GPU ...", bodyRenderer.count);
	#endif

	// Grid lines
	glBindVertexArray(gridRenderer.vao);
	
	glGenBuffers(1, gridRenderer.vbo);

	glBindBuffer(GL_ARRAY_BUFFER, gridRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, gridRenderer.count * sizeof(cl_float4), gridRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(gridRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(gridRenderer.positionAI);
	
	
	// Scatter body
	glBindVertexArray(bodyRenderer.vao);
	
	glGenBuffers(3, bodyRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[0]);  // position
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(bodyRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(bodyRenderer.positionAI);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[1]);  // color
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(bodyRenderer.colorAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(bodyRenderer.colorAI);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[2]);  // angles: alpha, beta, gamma
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(bodyRenderer.rotationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(bodyRenderer.rotationAI);

	
	// Anchor
	glBindVertexArray(anchorRenderer.vao);
	
	glGenBuffers(1, anchorRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorRenderer.count * sizeof(cl_float4), anchorRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(anchorRenderer.positionAI);

	
	// Anchor Line
	glBindVertexArray(anchorLineRenderer.vao);

	glGenBuffers(1, anchorLineRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorLineRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorLineRenderer.count * sizeof(cl_float4), anchorLineRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorLineRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(anchorLineRenderer.positionAI);
	
	
	// Debris
	glBindVertexArray(leafRenderer.vao);
	
	glGenBuffers(3, leafRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, leafRenderer.vbo[0]);  // Debris primitive
	glBufferData(GL_ARRAY_BUFFER, 5 * sizeof(cl_float4), leafRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(leafRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(leafRenderer.positionAI);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[0]);  // Debris position as translation
	glVertexAttribPointer(leafRenderer.translationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glVertexAttribDivisor(leafRenderer.translationAI, 1);
	glEnableVertexAttribArray(leafRenderer.translationAI);

	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[2]);  // Debris angles as rotation
	glVertexAttribPointer(leafRenderer.rotationAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glVertexAttribDivisor(leafRenderer.rotationAI, 1);
	glEnableVertexAttribArray(leafRenderer.rotationAI);

	GLuint indices[] = {5, 1, 2, 0, 5, 3, 4};
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, leafRenderer.vbo[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
	
	// HUD
	glBindVertexArray(hudRenderer.vao);
	
	glGenBuffers(1, hudRenderer.vbo);
    
	glBindBuffer(GL_ARRAY_BUFFER, hudRenderer.vbo[0]);
	float pos[] = {0.0f, 0.0f, 0.0f, 0.0f,
		           0.0f, 1.0f, 0.0f, 0.0f,
                   1.0f, 0.0f, 0.0f, 0.0f,
                   1.0f, 1.0f, 0.0f, 0.0f,
                   0.0f, 0.0f, 0.0f, 0.0f,
				   1.0f, 0.0f, 0.0f, 0.0f,
		           1.0f, 1.0f, 0.0f, 0.0f,
		           0.0f, 1.0f, 0.0f, 0.0f,
				   0.0f, 0.0f, 0.0f, 0.0f};
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(pos), pos, GL_STATIC_DRAW);
    glVertexAttribPointer(hudRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(hudRenderer.positionAI);
	
	
	#ifdef DEBUG
	NSLog(@"VBOs %d %d %d ...", bodyRenderer.vbo[0], bodyRenderer.vbo[1], anchorRenderer.vbo[0]);
	#endif
	
	[delegate vbosAllocated:bodyRenderer.vbo];
	
	viewParametersNeedUpdate = TRUE;
}

- (void)render
{
    static float theta = 0.0f;
    
	if (vbosNeedUpdate) {
		vbosNeedUpdate = FALSE;
		[self allocateVBO];
	}
	
	if (spinModel) {
		modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(0.001f * spinModel), modelRotate);
//        modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(0.003f * cos(theta)), modelRotate);
//        modelRotate = GLKMatrix4RotateY(modelRotate, 0.001f * spinModel);
        theta = theta + 0.005f;
		viewParametersNeedUpdate = TRUE;
	}
	
	if (viewParametersNeedUpdate) {
		[self updateViewParameters];
	}
	

    iframe++;
    [self measureFPS];
    
	// Tell the delgate I'm about to draw
	[delegate willDrawScatterBody];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glViewport(0, 0, width, height);
	
//	NSLog(@"%d %d", anchorRenderer.colorUI, gridRenderer.colorUI);
    
    // Grid
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindVertexArray(gridRenderer.vao);
	glLineWidth(2.0f);
	glUseProgram(gridRenderer.program);
	glUniform4f(gridRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
	glUniformMatrix4fv(gridRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawArrays(GL_LINES, 0, gridRenderer.count);

	// Anchor Lines
	glBindVertexArray(anchorLineRenderer.vao);
	glUseProgram(anchorLineRenderer.program);
	glUniform4f(anchorLineRenderer.colorUI, 1.0f, 1.0f, 0.0f, 1.0f);
	glUniformMatrix4fv(anchorLineRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawArrays(GL_LINES, 0, anchorLineRenderer.count);

	// Anchors
	glBindVertexArray(anchorRenderer.vao);
	glPointSize(5.0f);
	glUseProgram(anchorRenderer.program);
	glUniform4f(anchorRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
	glUniformMatrix4fv(anchorRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawArrays(GL_POINTS, 0, anchorRenderer.count);
	
	// The scatter bodies
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	glBindVertexArray(bodyRenderer.vao);
	glPointSize(MIN(MAX(15.0f * pixelsPerUnit, 1.0f), 32.0f));
	glUseProgram(bodyRenderer.program);
	glUniform4f(bodyRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
	glUniformMatrix4fv(bodyRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform1i(bodyRenderer.textureUI, 0);
    glBindTexture(GL_TEXTURE_2D, bodyRenderer.textureID);
	glDrawArrays(GL_POINTS, 0, bodyRenderer.count);
	
	// Leaves
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindVertexArray(leafRenderer.vao);
	glUseProgram(leafRenderer.program);
	glUniform4f(leafRenderer.colorUI, 0.3f, 1.0f, 0.0f, 1.0f);
    glUniformMatrix4fv(leafRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawElementsInstanced(GL_LINE_STRIP, 7, GL_UNSIGNED_INT, NULL, leafRenderer.count);
	

    // HUD
    glBindVertexArray(hudRenderer.vao);
    glUseProgram(hudRenderer.program);
    glLineWidth(1.0f);
    glUniform4f(hudRenderer.colorUI, 0.0f, 0.0f, 0.0f, 0.8f);
    glUniformMatrix4fv(hudRenderer.mvpUI, 1, GL_FALSE, hudModelViewProjection.m);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glUniform4f(hudRenderer.colorUI, 0.0f, 1.0f, 1.0f, 1.0f);
    glDrawArrays(GL_LINE_STRIP, 4, 5);

#ifdef DEBUG_GL
    [textRenderer showTextureMap];
#endif

    // Text
    snprintf(statusMessage[1], 256, "Frame %d", iframe);
    
    [textRenderer drawText:"SimRadar" origin:NSMakePoint(25.0f, height - 60.0f) scale:0.5f red:0.2f green:1.0f blue:0.9f alpha:1.0f];
    //[textRenderer drawText:"SimRadar" origin:NSMakePoint(25.0f, height - 150.0f) scale:1.0f red:0.2f green:1.0f blue:0.9f alpha:1.0f];
    [textRenderer drawText:statusMessage[0] origin:NSMakePoint(25.0f, height - 90.0f) scale:0.333f];
    [textRenderer drawText:statusMessage[1] origin:NSMakePoint(25.0f, height - 120.0f) scale:0.333f];
//    [textRenderer drawText:fpsString origin:NSMakePoint(width - 25.0f, height - 49.0f) scale:0.333f red:1.0f green:0.9f blue:0.2f alpha:1.0f align:GLTextAlignmentRight];

    snprintf(statusMessage[2], 128, "AZ %.2f", beamAzimuth / M_PI * 180.0f);
    [textRenderer drawText:statusMessage[2] origin:NSMakePoint(width - hudRect.size.width - 15.0f, height - hudRect.size.height - 15.0f) scale:0.25f];
    
    glViewport(hudRect.origin.x, hudRect.origin.y, hudRect.size.width, hudRect.size.height);
    
    // Leaves on HUD
    glBindVertexArray(leafRenderer.vao);
    glUseProgram(leafRenderer.program);
    glUniformMatrix4fv(leafRenderer.mvpUI, 1, GL_FALSE, beamModelViewProjection.m);
    glDrawElementsInstanced(GL_LINE_STRIP, 7, GL_UNSIGNED_INT, NULL, leafRenderer.count);
    

    glBindVertexArray(0);
    glUseProgram(0);
}

#pragma mark -
#pragma mark Interaction

- (void)updateViewParameters {

    GLfloat near = 2.0f / range * modelCenter.y;
    
    unitsPerPixel = range / height;
    pixelsPerUnit = 1.0f / unitsPerPixel;

    GLKMatrix4 mat;

    // Finally, world's z-axis (up) should be antenna's y-axis (up)
    modelView = GLKMatrix4MakeTranslation(0.0f, 0.0f, -modelCenter.y);
    modelView = GLKMatrix4Multiply(modelView, modelRotate);
    modelView = GLKMatrix4Translate(modelView, -modelCenter.x, -modelCenter.z, modelCenter.y);
    modelView = GLKMatrix4RotateX(modelView, -M_PI_2);
    
    projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, MIN(RENDERER_NEAR_RANGE, near), RENDERER_FAR_RANGE);
    modelViewProjection = GLKMatrix4Multiply(projection, modelView);

    hudRect = CGRectMake(width - 280.0f, height - 280.0f, 250.0f, 250.0f);
    hudProjection = GLKMatrix4MakeOrtho(0.0f, width, 0.0f, height, 0.0f, 1.0f);
    mat = GLKMatrix4MakeTranslation(hudRect.origin.x + 0.5f, hudRect.origin.y + 0.5f, 0.0f);
    mat = GLKMatrix4Scale(mat, hudRect.size.width, hudRect.size.height, 1.0f);
    hudModelViewProjection = GLKMatrix4Multiply(hudProjection, mat);

//    beamProjection = GLKMatrix4MakeFrustum(-1.0f, 1.0f, -1.0f, 1.0f, 16.0f, RENDERER_FAR_RANGE);
    beamProjection = GLKMatrix4MakeFrustum(-1.0f, 1.0f, -1.0f, 1.0f, MIN(RENDERER_NEAR_RANGE, near), RENDERER_FAR_RANGE);
    mat = GLKMatrix4Identity;
    mat = GLKMatrix4RotateY(mat, beamAzimuth);
    mat = GLKMatrix4RotateX(mat, -beamElevation);
    mat = GLKMatrix4RotateX(mat, -M_PI_2);
    beamModelViewProjection = GLKMatrix4Multiply(beamProjection, mat);
    
    [textRenderer setModelViewProjection:hudProjection];
}


- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy
{
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(2.0f * dx / width), modelRotate);
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(2.0f * dy / height), modelRotate);
}

- (void)magnify:(GLfloat)scale
{
	range = MIN(50000.0f, MAX(0.001f, range * (1.0f - scale)));
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
//	rotateX = 0.0f;
//	rotateZ = 0.0f;
//	range = 20000.0f;
//	modelRotate = GLKMatrix4MakeTranslation(-modelCenter.x, -modelCenter.y, -modelCenter.z);

	rotateX = 0.35f * M_PI;
	rotateY = -0.1f;
	range = 5000.0f;

    modelRotate = GLKMatrix4MakeRotation(rotateY, 0.0f, 1.0f, 0.0f);
    modelRotate = GLKMatrix4RotateX(modelRotate, rotateX);
    
    iframe = 0;
    
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

- (void)increaseLeafCount
{
    if (leafRenderer.count >= 1000 && leafRenderer.count < bodyRenderer.count - 1000) {
        leafRenderer.count += 1000;
    } else if (leafRenderer.count < bodyRenderer.count - 100) {
		leafRenderer.count += 100;
	}
    [self updateStatusMessage];
}

- (void)decreaseLeafCount
{
    if (leafRenderer.count > 1000) {
        leafRenderer.count -= 1000;
    } else if (leafRenderer.count > 100) {
		leafRenderer.count -= 100;
	}
    [self updateStatusMessage];
}

@end
