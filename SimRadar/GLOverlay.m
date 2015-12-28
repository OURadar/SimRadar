//
//  GLOverlay.m
//
//  Theory of Operations
//
//  - Instantiate the class object at anytime since it is Core Graphic based
//  - Draw / update to the CG context after initialization (separate thread)
//  - During OpenGL rendering, call the method updateGLTexture
//  - Then, call the method drawAtRect:, which draws the rectangular overlay
//
//  Created by Boon Leng Cheong on 12/26/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "GLOverlay.h"

@implementation GLOverlay

- (id)initWithSize:(NSSize)size {
    self = [super init];
    if (self) {
        // Initialize a Core-graphic context of given size
    }
    return self;
}

- (int)updateGLTexture {
    // Include vertex & fragment shader GLSL here
    return 0;
}

- (void)drawAtRect:(NSRect)rect {
    
}


@end
