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

#define RENDERER_NEAR_RANGE  2.0f

typedef struct _draw_resource {
	GLuint program;
	GLuint vao;
	GLuint vbo[5];       // positions, colors, tex_coord, wvp_mat
	GLint mvpUI;
	GLint colorUI;
    GLint textureUI;
	GLuint count;
	GLfloat *positions;  // CPU side position
	GLfloat *colors;     // CPU side color
	GLuint *indices;     // CPU side indexing for instancing
    GLint positionAI;
	GLint rotationAI;
	GLint translationAI;
	GLint colorAI;
    GLKTextureInfo *texture;
} RenderResource;


@protocol RendererDelegate <NSObject>

- (void)glContextVAOPrepared;
- (void)vbosAllocated:(GLuint *)vbos;
- (void)willDrawScatterBody;

@end

@interface Renderer : NSObject {
	
	float GLSLVersion;
	
	GLsizei width, height;
	GLfloat aspectRatio;
	GLfloat rotateX, rotateY, rotateZ, range;
	
	GLKMatrix4 modelView, projection, modelViewProjection;
	GLKMatrix4 modelRotate;
    GLKMatrix4 hudMatrix;
	
	GLint MVPUniformIndex, singleColorMVPUniformIndex;
	GLint ColorUniformIndex;

	RenderResource gridRenderer;
	RenderResource bodyRenderer;
	RenderResource anchorRenderer;
	RenderResource anchorLineRenderer;
	RenderResource leafRenderer;
	RenderResource hudRenderer;
	
	GLText *textRenderer;
	
	GLfloat pixelsPerUnit;
	GLfloat unitsPerPixel;

	BOOL vbosNeedUpdate;
	BOOL viewParametersNeedUpdate;
	GLchar spinModel;
	
	id<RendererDelegate> delegate;
	
	@private
	
	cl_float4 modelCenter;
}

@property (nonatomic, retain) id<RendererDelegate> delegate;

- (void)setSize:(CGSize)size;
- (void)setBodyCount:(GLuint)number;
- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size;
- (void)setAnchorPoints:(GLfloat *)points number:(GLuint)number;
- (void)setAnchorLines:(GLfloat *)lines number:(GLuint)number;
- (void)setCenterPoisitionX:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
- (void)makeOneLeaf;

- (void)allocateVAO;
- (void)render;

- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy;
- (void)magnify:(GLfloat)scale;
- (void)rotate:(GLfloat)angle;
- (void)resetViewParameters;

- (void)startSpinModel;
- (void)stopSpinModel;
- (void)toggleSpinModel;
- (void)toggleSpinModelReverse;

- (void)increaseLeaves;
- (void)decreaseLeaves;

@end
