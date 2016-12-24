//
//  DrawGLView.h
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
//#import <OpenGL/gl3.h>
#import <OpenCL/OpenCL.h>
#import <GLKit/GLKit.h>
#import <Quartz/Quartz.h>
#import "Renderer.h"

@interface DrawGLView : NSOpenGLView {
    BOOL animating;
    Renderer *renderer;
@private
    CVDisplayLinkRef displayLink;
    void *scratchBuffer;
}

@property (readonly, nonatomic, getter = isAnimating) BOOL animating;
@property (readonly) Renderer *renderer;

- (void)startAnimation;
- (void)stopAnimation;
- (void)viewToFile:(NSString *)filename;

@end
