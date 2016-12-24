//
//  Renderer.h
//  _simradar
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/OpenCL.h>
#import "GLText.h"

#define RENDERER_NEAR_RANGE                 100.0f      // View range in m
#define RENDERER_FAR_RANGE                  100000.0f   // View range in m
#define RENDERER_TIC_COUNT                  10          //
#define RENDERER_MAX_DEBRIS_TYPES           8           // Actual plus one
#define RENDERER_MAX_CL_DEVICE              1
#define RENDERER_MAX_VBO_GROUPS             8
#define RENDERER_DEFAULT_BODY_COLOR_INDEX   27          // Default colormap index
#define RENDERER_FBO_COUNT                  5

typedef struct _draw_resource {
    GLchar         vShaderName[64];
    GLchar         fShaderName[64];
    GLuint         program;
    GLuint         vao;
    GLuint         vbo[5];            // positions, colors, tex_coord, wvp_mat, etc.
    
    GLint          mvUI;
    GLint          mvpUI;
    GLint          sizeUI;
    GLint          colorUI;
    GLint          textureUI;
    GLint          colormapUI;
    GLint          pingPongUI;
    
    GLuint         count;
    
    GLfloat        *colors;           // CPU side color
    GLfloat        *positions;        // CPU side position
    GLfloat        *textureCoord;     // CPU side texture coordinate
    GLuint         *indices;          // CPU side indexing for instancing
    
    GLuint         *segmentOrigins;
    GLuint         *segmentLengths;
    GLuint         segmentNextOrigin;
    GLuint         segmentMax;
    
    GLint          colorAI;
    GLint          positionAI;
    GLint          rotationAI;
    GLint          quaternionAI;
    GLint          translationAI;
    GLint          textureCoordAI;
    
    GLKTextureInfo *texture;
    GLuint         textureID;
    
    GLKTextureInfo *colormap;
    GLuint         colormapCount;
    GLuint         colormapIndex;
    GLfloat        colormapIndexNormalized;
    GLuint         colormapID;
    
    GLuint         sourceOffset;
    GLuint         instanceSize;
    GLenum         drawMode;
    
    GLKMatrix4     modelView;
    GLKMatrix4     modelViewProjection;
    GLKMatrix4     modelViewProjectionOffOne;
    GLKMatrix4     modelViewProjectionOffTwo;
} RenderResource;

typedef struct _draw_primitive {
    GLfloat vertices[64];
    GLuint indices[64];
    GLuint vertexSize;
    GLuint instanceSize;
    GLenum drawMode;
} RenderPrimitive;

enum RendererLineSegment {
    RendererLineSegmentBasicRectangle  = 0,
    RendererLineSegmentSimulationGrid  = 1,
    RendererLineSegmentAnchorLines     = 2
};

#pragma mark -

@protocol RendererDelegate <NSObject>

- (void)glContextVAOPrepared;
- (void)vbosAllocated:(GLuint [][8])vbos;
- (void)willDrawScatterBody;

@end

#pragma mark -

@interface Renderer : NSObject {
    
    NSString *titleString, *subtitleString, *overlayString;
    
    float GLSLVersion;
    
    GLfloat resetRange;
    GLKMatrix4 resetModelRotate;
    
    GLsizei width, height;
    GLfloat aspectRatio;
    GLfloat rotateX, rotateY, rotateZ, range;
    
    GLKMatrix4 modelView, projection, modelViewProjection;
    GLKMatrix4 modelRotate;
    GLKMatrix4 hudProjection, hudModelViewProjection;
    
    CGPoint hudOrigin;
    CGSize hudSize;
    
    GLint MVPUniformIndex, singleColorMVPUniformIndex;
    GLint ColorUniformIndex;
    
    GLfloat pixelsPerUnit;
    GLfloat unitsPerPixel;
    GLfloat devicePixelRatio;
    
    GLfloat beamAzimuth, beamElevation;
    
    id<RendererDelegate> delegate;
    
    unsigned int hudConfigDecimal, hudConfigGray;
    
    BOOL applyVFX;
    BOOL colorbarNeedsUpdate;
    BOOL fadeSmallScatterers;
    BOOL showDebrisAttributes;
    
@private

    cl_float4 modelCenter;
    
    BOOL fboNeedsUpdate;
    BOOL vbosNeedUpdate;
    BOOL viewParametersNeedUpdate;
    BOOL statusMessageNeedsUpdate;
    BOOL overlayNeedsUpdate;
    GLchar spinModel;
    
    RenderResource pointRenderer;
    RenderResource lineRenderer;
    RenderResource instancedGeometryRenderer;
    RenderResource meshRenderer;
    RenderResource frameRenderer;

    RenderPrimitive primitives[8];
    
    GLfloat backgroundOpacity;
    GLfloat theta, phase;
    
    GLText *textRenderer;
    GLText *tTextRenderer;
    GLText *fwTextRenderer;

    char statusMessage[16][256];
    
    char *colorbarTitle;
    char colorbarTickLabels[10][16];
    float *colorbarTickPositions;
    int colorbarTickCount;
    
    int itic, iframe;
    NSTimeInterval tics[RENDERER_TIC_COUNT];
    float fps;
    char fpsString[16];
    
    GLuint frameBuffers[5], frameBufferTextures[5];
    GLuint ifbo;
}

@property (nonatomic) GLfloat resetRange;
@property (nonatomic) GLKMatrix4 resetModelRotate;
@property (nonatomic, retain) id<RendererDelegate> delegate;
@property (nonatomic, readonly) GLsizei width, height;

- (id)initWithDevicePixelRatio:(GLfloat)pixelRatio;
- (id)init;

- (void)allocateVAO;

- (void)setSize:(CGSize)size;
- (void)setCenterPoisitionX:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;
- (void)setGridAtOrigin:(GLfloat *)origin size:(GLfloat *)size;
- (void)setColormapTitle:(char *)title tickLabels:(NSArray *)labels positions:(GLfloat *)positions;

- (void)render;

- (void)panX:(GLfloat)x Y:(GLfloat)y dx:(GLfloat)dx dy:(GLfloat)dy;
- (void)magnify:(GLfloat)scale;
- (void)rotate:(GLfloat)angle;
- (void)resetViewParameters;
- (void)topView;

- (void)startSpinModel;
- (void)stopSpinModel;
- (void)toggleSpinModel;
- (void)toggleSpinModelReverse;

- (void)cycleForwardColormap;
- (void)cycleReverseColormap;

@end
