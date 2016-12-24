//
//  AppDelegate.h
//  DrawGCL
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DrawGLView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    DrawGLView *glView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet DrawGLView *glView;

@end

