//
//  SimGLView.h
//  _radarsim
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Renderer.h"

@interface SimGLView : NSOpenGLView {
	BOOL animating;
	Renderer *renderer;
@private
	CVDisplayLinkRef displayLink;
    unsigned int tic;
}

@property (readonly, nonatomic, getter = isAnimating) BOOL animating;
@property (readonly) Renderer *renderer;

- (void)startAnimation;
- (void)stopAnimation;
- (void)viewToFile:(NSString *)filename;

@end
