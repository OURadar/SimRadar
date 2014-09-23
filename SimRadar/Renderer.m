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

@end

@implementation Renderer

@synthesize delegate;

#pragma mark Properties

- (void)setRange:(float)newRange
{
	projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1.0f, 1.0f, RENDERER_NEAR_RANGE, 1000.0f);
}


- (void)setSize:(CGSize)size
{
	width = (GLsizei)size.width;
	height = (GLsizei)size.height;
	
	glViewport(0, 0, width, height);
	
	aspectRatio = size.width / size.height;
	
	[self setRange:10.0f];
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
	modelRotate = GLKMatrix4Translate(modelRotate, -x, -y, -z);
}

- (void)makeOneLeaf
{
	if (leafRenderer.positions == NULL) {
		leafRenderer.positions = (GLfloat *)malloc(6 * sizeof(cl_float4));
		NSLog(@"leafRenderer.positions allocated @ %p", leafRenderer.positions);
	}
	
	leafRenderer.positions[0]  =  1.0f;   leafRenderer.positions[1]  =  0.0f;   leafRenderer.positions[2]  = 0.0f;   leafRenderer.positions[3]  = 1.0f;
	leafRenderer.positions[4]  = -1.0f;   leafRenderer.positions[5]  =  0.0f;   leafRenderer.positions[6]  = 0.0f;   leafRenderer.positions[7]  = 1.0f;
	leafRenderer.positions[8]  =  0.0f;   leafRenderer.positions[9]  =  2.0f;   leafRenderer.positions[10] = 0.0f;   leafRenderer.positions[11] = 1.0f;
	leafRenderer.positions[12] =  0.0f;   leafRenderer.positions[13] = -1.0f;   leafRenderer.positions[14] = 0.0f;   leafRenderer.positions[15] = 1.0f;
	leafRenderer.positions[16] =  0.0f;   leafRenderer.positions[17] = -1.0f;   leafRenderer.positions[18] = 0.5f;   leafRenderer.positions[19] = 1.0f;

	leafRenderer.count = 10;
	
	for (int i=0; i<20; i++) {
		leafRenderer.positions[i] *= 50.0f;
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
        NSLog(@"%@", resource.texture);
        glUniform1i(resource.textureUI, resource.texture.name);
        glBindTexture(GL_TEXTURE_2D, resource.texture.name);
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

#pragma mark -
#pragma mark Initializations & Deallocation

- (id)init
{
	self = [super init];
	if (self) {
		// View size in pixel counts
		width = 1;
		height = 1;
		aspectRatio = 1.0f;
		spinModel = 1;
		
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

// Call this method as soon as the OpenGL context is initialized

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
	anchorRenderer = [self createRenderResourceFromVertexShader:@"shape_sc" fragmentShader:@"shape_sc"];
	anchorLineRenderer = [self createRenderResourceFromProgram:gridRenderer.program];
	leafRenderer = [self createRenderResourceFromVertexShader:@"leaf" fragmentShader:@"leaf"];
	
	NSLog(@"bodyRenderer.vao = %d   gridRenderer.vao = %d  anchorRenderer.vao = %d  anchorLineRendrer.vao = %d  leafRendrer.vao = %d",
		  bodyRenderer.vao, gridRenderer.vao, anchorRenderer.vao, anchorLineRenderer.vao, leafRenderer.vao);
	// Depth test will always be enabled
	//glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);

	// We will always cull back faces for better performance
	glEnable(GL_CULL_FACE);
	
	// Always use this clear color
	//glClearColor(0.0f, 0.2f, 0.25f, 1.0f);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	[self makeOneLeaf];
	
	// Tell whatever controller that the OpenGL context is ready for sharing and set up renderer's body count
	[delegate glContextVAOPrepared];
}


- (void)allocateVBO
{
	#ifdef DEBUG
	NSLog(@"Allocating %d particles on GPU ...", bodyRenderer.count);
	#endif

	// Grid lines
	glBindVertexArray(gridRenderer.vao);
	
	glGenBuffers(1, gridRenderer.vbo);
	
	NSLog(@"gridRenderer.count = %d", gridRenderer.count);
	glBindBuffer(GL_ARRAY_BUFFER, gridRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, gridRenderer.count * sizeof(cl_float4), gridRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(gridRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(gridRenderer.positionAI);
	
	
	// Scatter body
	glBindVertexArray(bodyRenderer.vao);
	
	glGenBuffers(2, bodyRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(bodyRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(bodyRenderer.positionAI);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[1]);
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(bodyRenderer.colorAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(bodyRenderer.colorAI);
	
	
	// Anchor
	glBindVertexArray(anchorRenderer.vao);
	
	glGenBuffers(1, anchorRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorRenderer.count * sizeof(cl_float4), anchorRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(anchorRenderer.positionAI);

	
	// Anchor Line
	glBindVertexArray(anchorLineRenderer.vao);

	glGenBuffers(1, anchorLineRenderer.vbo);
	
	glBindBuffer(GL_ARRAY_BUFFER, anchorLineRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, anchorLineRenderer.count * sizeof(cl_float4), anchorLineRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(anchorLineRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(anchorLineRenderer.positionAI);
	
	// Leaves
	glBindVertexArray(leafRenderer.vao);
	
	glGenBuffers(3, leafRenderer.vbo);
	
	NSLog(@"leafRenderer.positionAI = %d", leafRenderer.positionAI);
	NSLog(@"leafRenderer.rotationAI = %d", leafRenderer.rotationAI);
	NSLog(@"leafRenderer.translationAI = %d", leafRenderer.translationAI);

	glBindBuffer(GL_ARRAY_BUFFER, leafRenderer.vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, 5 * sizeof(cl_float4), leafRenderer.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(leafRenderer.positionAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(leafRenderer.positionAI);
	
	glBindBuffer(GL_ARRAY_BUFFER, bodyRenderer.vbo[0]);
	glVertexAttribPointer(leafRenderer.translationAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glVertexAttribDivisor(leafRenderer.translationAI, 1);
	glEnableVertexAttribArray(leafRenderer.translationAI);

	cl_float4 zeros[10];
	memset(zeros, 0, 10 * sizeof(cl_float4));
	glBindBuffer(GL_ARRAY_BUFFER, leafRenderer.vbo[1]);
	glBufferData(GL_ARRAY_BUFFER, bodyRenderer.count * sizeof(cl_float4), NULL, GL_STATIC_DRAW);
	glVertexAttribPointer(leafRenderer.rotationAI, 4, GL_FLOAT, GL_FALSE, 0, 0);
	glVertexAttribDivisor(leafRenderer.rotationAI, 1);
	glEnableVertexAttribArray(leafRenderer.rotationAI);

//	glBindBuffer(GL_ARRAY_BUFFER, leafRenderer.vbo[3]);
//	GLKMatrix4 mvp[10];
////    mvp[0] = GLKMatrix4Scale(GLKMatrix4MakeTranslation(-2000.0f, 10000.0f, 500.0f), 200.0f, 200.0f, 200.0f);
////    mvp[1] = GLKMatrix4Scale(GLKMatrix4MakeTranslation(1000.0f, 10000.0f, 1200.0f), 200.0f, 200.0f, 200.0f);
//	for (int i=0; i<10; i++) {
//		mvp[i] = GLKMatrix4Identity;
//	}
//	glBufferData(GL_ARRAY_BUFFER, 10 * sizeof(GLKMatrix4), mvp, GL_STATIC_DRAW);
//	glVertexAttribPointer(leafRenderer.transformMatrixAI    , 4, GL_FLOAT, GL_FALSE, sizeof(GLKMatrix4), NULL);
//	glVertexAttribPointer(leafRenderer.transformMatrixAI + 1, 4, GL_FLOAT, GL_FALSE, sizeof(GLKMatrix4), (const void *)(1 * sizeof(GLKVector4)));
//	glVertexAttribPointer(leafRenderer.transformMatrixAI + 2, 4, GL_FLOAT, GL_FALSE, sizeof(GLKMatrix4), (const void *)(2 * sizeof(GLKVector4)));
//	glVertexAttribPointer(leafRenderer.transformMatrixAI + 3, 4, GL_FLOAT, GL_FALSE, sizeof(GLKMatrix4), (const void *)(3 * sizeof(GLKVector4)));
//	glVertexAttribDivisor(leafRenderer.transformMatrixAI    , 1);
//	glVertexAttribDivisor(leafRenderer.transformMatrixAI + 1, 1);
//	glVertexAttribDivisor(leafRenderer.transformMatrixAI + 2, 1);
//	glVertexAttribDivisor(leafRenderer.transformMatrixAI + 3, 1);
//	glEnableVertexAttribArray(leafRenderer.transformMatrixAI);
//	glEnableVertexAttribArray(leafRenderer.transformMatrixAI + 1);
//	glEnableVertexAttribArray(leafRenderer.transformMatrixAI + 2);
//	glEnableVertexAttribArray(leafRenderer.transformMatrixAI + 3);

	GLuint indices[] = {2, 0, 1, 2, 3, 4};
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, leafRenderer.vbo[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(GLuint), indices, GL_STATIC_DRAW);

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
        //modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(0.003f * cos(theta)), modelRotate);
        theta = theta + 0.005f;
		viewParametersNeedUpdate = TRUE;
	}
	
	if (viewParametersNeedUpdate) {
		[self updateViewParameters];
	}
	
	// Tell the delgate I'm about to draw
	[delegate willDrawScatterBody];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
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
	//glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA_SATURATE);
	//glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
    //glBlendFunc(GL_ONE, GL_ONE);
    //glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_SRC_ALPHA);
	glBindVertexArray(bodyRenderer.vao);

	//NSLog(@"pixelsPerUnit = %.2f", pixelsPerUnit);
	//glPointSize(4.0f);
	glPointSize(MAX(1.0f, 10.0f * pixelsPerUnit));
	glUseProgram(bodyRenderer.program);
	glUniform4f(anchorRenderer.colorUI, 1.0f, 1.0f, 1.0f, 1.0f);
	glUniformMatrix4fv(bodyRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
    glUniform1i(bodyRenderer.textureUI, 0);
	glDrawArrays(GL_POINTS, 0, bodyRenderer.count);
	
	// Leaves
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glBindVertexArray(leafRenderer.vao);
	glPointSize(8.0f);
	glUseProgram(leafRenderer.program);
	glUniform4f(leafRenderer.colorUI, 0.3f, 1.0f, 0.0f, 1.0f);
    glUniformMatrix4fv(leafRenderer.mvpUI, 1, GL_FALSE, modelViewProjection.m);
	glDrawElementsInstanced(GL_LINE_STRIP, 6, GL_UNSIGNED_INT, leafRenderer.indices, 200);
}

#pragma mark -
#pragma mark Interaction

- (void)updateViewParameters {
	unitsPerPixel = 2.0f * range / height;
	pixelsPerUnit = 1.0f / unitsPerPixel;
	
	GLfloat scale = 2.0f / range;

	modelView = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f * RENDERER_NEAR_RANGE);
	modelView = GLKMatrix4Scale(modelView, scale, scale, scale);
	modelView = GLKMatrix4Multiply(modelView, modelRotate);
	
	modelViewProjection = GLKMatrix4Multiply(projection, modelView);
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

	rotateX = -0.65f * M_PI;
//	rotateX = -0.9f * M_PI;
	rotateY = 2.1f;
    //rotateY = M_PI;
	range = 1800.0f;
	modelRotate = GLKMatrix4MakeTranslation(-modelCenter.x, -modelCenter.y, -modelCenter.z);
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeXRotation(rotateX), modelRotate);
	modelRotate = GLKMatrix4Multiply(GLKMatrix4MakeYRotation(rotateY), modelRotate);

	
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

@end
