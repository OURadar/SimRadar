//
//  Renderer.h
//  _radarsim
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/OpenCL.h>
#import "glUtil.h"
#import "GLText.h"

#define RENDERER_NEAR_RANGE         100.0f
#define RENDERER_FAR_RANGE          100000.0f
#define RENDERER_TIC_COUNT          10
#define RENDERER_MAX_DEBRIS_TYPES   4
#define RENDERER_MAX_VBO_GROUPS     8

typedef struct _draw_resource {
	GLuint program;
	GLuint vao;
	GLuint vbo[5];       // positions, colors, tex_coord, wvp_mat, etc.
    GLint mvUI;
	GLint mvpUI;
    GLint sizeUI;
	GLint colorUI;
    GLint textureUI;
    GLint colormapUI;
	GLuint count;
	GLfloat *positions;    // CPU side position
	GLfloat *colors;       // CPU side color
    GLfloat *textureCoord; // CPU side texture coordinate
	GLuint *indices;       // CPU side indexing for instancing
    GLint positionAI;
	GLint rotationAI;
    GLint quaternionAI;
	GLint translationAI;
    GLint textureCoordAI;
	GLint colorAI;
    GLKTextureInfo *texture;
    GLuint textureID;
    GLKTextureInfo *colormap;
    GLuint colormapCount;
    GLuint colormapIndex;
    GLfloat colormapIndexNormalized;
    GLuint colormapID;
    GLuint sourceOffset;
    GLuint instanceSize;
    GLenum drawMode;
    GLKMatrix4 modelView;
    GLKMatrix4 modelViewProjection;
    GLKMatrix4 modelViewProjectionOffOne;
    GLKMatrix4 modelViewProjectionOffTwo;
} RenderResource;


typedef struct _draw_primitive {
    GLfloat vertices[64];
    GLuint indices[64];
    GLuint vertexSize;
    GLuint instanceSize;
    GLenum drawMode;
} RenderPrimitive;

@protocol RendererDelegate <NSObject>

- (void)glContextVAOPrepared;
- (void)vbosAllocated:(GLuint [][8])vbos;
- (void)willDrawScatterBody;

@end

@interface Renderer : NSObject {
	
	float GLSLVersion;
	
	GLsizei width, height;
	GLfloat aspectRatio;
	GLfloat rotateX, rotateY, rotateZ, range;
	
	GLKMatrix4 modelView, projection, modelViewProjection;
	GLKMatrix4 modelRotate;
    GLKMatrix4 hudProjection, hudModelViewProjection;
    GLKMatrix4 beamProjection, beamModelViewProjection;
	
    CGPoint hudOrigin;
    CGSize hudSize;
    
	GLint MVPUniformIndex, singleColorMVPUniformIndex;
	GLint ColorUniformIndex;

	GLfloat pixelsPerUnit;
	GLfloat unitsPerPixel;
    GLfloat devicePixelRatio;

    GLfloat beamAzimuth, beamElevation;
    
	id<RendererDelegate> delegate;
    
    BOOL showHUD;
    BOOL colorbarNeedsUpdate;
	
	@private
	
    cl_uint clDeviceCount;
    
	cl_float4 modelCenter;

    BOOL vbosNeedUpdate;
    BOOL viewParametersNeedUpdate;
    BOOL statusMessageNeedsUpdate;
    GLchar spinModel;
    
    RenderResource bodyRenderer[8];
    RenderResource instancedGeometryRenderer;

    RenderResource gridRenderer;
    RenderResource anchorRenderer;
    RenderResource anchorLineRenderer;
    RenderResource debrisRenderer[RENDERER_MAX_DEBRIS_TYPES];
    RenderResource hudRenderer;
    RenderResource meshRenderer;

    RenderPrimitive primitives[4];
    
    GLfloat backgroundOpacity;
    
    GLText *textRenderer;
    
    char statusMessage[16][256];

    int itic, iframe;
    NSTimeInterval tics[RENDERER_TIC_COUNT];
    float fps;
    char fpsString[16];
}

@property (nonatomic, retain) id<RendererDelegate> delegate;
@property (nonatomic, readonly) GLsizei width, height;
@property (nonatomic) GLfloat beamAzimuth, beamElevation;
@property (nonatomic) BOOL showHUD;
@property (nonatomic) BOOL debrisCountsHaveChanged;

- (id)initWithDevicePixelRatio:(GLfloat)pixelRatio;

- (void)setSize:(CGSize)size;
- (void)setBodyCount:(GLuint)number forDevice:(GLuint)deviceId;
- (void)setPopulationTo:(GLuint)count forSpecies:(GLuint)speciesId forDevice:(GLuint)deviceId;
- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size;
- (void)setAnchorPoints:(GLfloat *)points number:(GLuint)number;
- (void)setAnchorLines:(GLfloat *)lines number:(GLuint)number;
- (void)setCenterPoisitionX:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
- (void)setBeamElevation:(GLfloat)elevation azimuth:(GLfloat)azimuth;

- (void)allocateVAO:(GLuint)count;
- (void)updateBodyToDebrisMappings;

- (void)render;

- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy;
- (void)magnify:(GLfloat)scale;
- (void)rotate:(GLfloat)angle;
- (void)resetViewParameters;

- (void)startSpinModel;
- (void)stopSpinModel;
- (void)toggleSpinModel;
- (void)toggleSpinModelReverse;
- (void)toggleHUDVisibility;

- (void)increaseBackgroundOpacity;
- (void)decreaseBackgroundOpacity;

- (void)cycleForwardColormap;
- (void)cycleReverseColormap;

@end
