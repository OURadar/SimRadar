//
//  AppDelegate.m
//  DrawGCL
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize glView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSSize newSize = NSMakeSize(1280.0f, 720.0f);
    CGFloat xPos = (self.window.screen.frame.size.width - newSize.width) * 0.5f;
    CGFloat yPos = (self.window.screen.frame.size.height - newSize.height) * 0.5f;
    [self.window setFrame:NSMakeRect(xPos, yPos, newSize.width, newSize.height) display:YES];

    [glView setBoundsSize:newSize];
    [glView.renderer setSize:newSize];
    
    [glView startAnimation];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [glView stopAnimation];
}


@end
