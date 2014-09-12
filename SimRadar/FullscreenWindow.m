//
//  FullscreenWindow.m
//  Radar
//
//  Created by Boon Leng Cheong on 7/19/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "FullscreenWindow.h"

@implementation FullscreenWindow

-(id) init
{
	// Create a screen-sized window on the display
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	// Initialize the window making it size of the screen and borderless
	self = [super initWithContentRect:screenRect
							styleMask:NSBorderlessWindowMask
							  backing:NSBackingStoreBuffered
								defer:YES];

	// Set the window level to be above the menu bar to cover everything else
	[self setLevel:NSMainMenuWindowLevel+1];
	
	// Set opaque
	[self setOpaque:YES];
	
	// Hide this when user switches to another window (or app)
	[self setHidesOnDeactivate:YES];
	
	return self;
}

-(BOOL) canBecomeKeyWindow
{
	// Return yes so that this borderless window can receive input
	return YES;
}

- (void) keyDown:(NSEvent *)event
{
	// Implement keyDown since controller will not get [ESC] key event which
	// the controller uses to kill fullscreen
	[[self windowController] keyDown:event];
}

@end
