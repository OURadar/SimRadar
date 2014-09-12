//
//  RootController.m
//  _radarsim
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "RootController.h"
#define STATE_MAX  3

@interface RootController()
- (void)setIcon:(NSInteger)index;
@end

@implementation RootController

#pragma mark -
#pragma mark Private Methods

- (void)setIcon:(NSInteger)index
{
	if (index > [icons count]) {
		return;
	}
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[iconFolder stringByAppendingPathComponent:[icons objectAtIndex:index]]];
	[[NSApplication sharedApplication] setApplicationIconImage:image];
	[image release];
}

#pragma mark -
#pragma mark Methods

- (IBAction)newLiveDisplay:(id)sender
{
	if (dc == nil) {
		dc = [[DisplayController alloc] initWithWindowNibName:@"LiveDisplay" viewDelegate:self];
		state = STATE_MAX;
	}

	[dc showWindow:self];
	
	//state = 3;
	
	//[sim explode];
    state = 3;
	
}

- (IBAction)playPause:(id)sender
{
	state = state == STATE_MAX ? 0 : state + 1;
	switch (state) {
		case 1:
			[self setIcon:19];
			break;

		case 2:
			[self setIcon:11];
			break;

		case 3:
			[self setIcon:1];
			break;

		default:
			[self setIcon:2];
			break;
	}
}

- (IBAction)resetSimulator:(id)sender
{
	[sim upload];
}

#pragma mark -

- (void)awakeFromNib
{
	iconFolder = [[[NSBundle mainBundle] pathForResource:@"Minion-Icons" ofType:nil] retain];
	icons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:iconFolder error:nil] retain];

	[self newLiveDisplay:self];
}

- (void)dealloc
{
	[iconFolder release];
	[icons release];
	
	[dc release];
	[sim release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark RendererDelegate

#if defined(DEBUG)
#define DNSLog(_expr) { NSLog(_expr); }
#else
#define DNSLog(_expr) {}
#endif

- (void)glContextVAOPrepared
{
	DNSLog(@"glContextVAOPrepared");

	if (sim) {
		NSLog(@"There is simulation session running.");
	} else {
		sim = [SimPoint new];
		NSLog(@"New simulation domain initiated.");
	}
	
	// Wire the simulator to the controller.
	// The displayController will tell the renderer how many scatter body
	// the simulator is using and pass the anchor points from RS API to
	// the renderer
	
	[dc setSim:sim];
}


- (void)vbosAllocated:(GLuint *)vbos
{
	DNSLog(@"vbosAllocated:");
	
	[sim shareVBOsWithGL:vbos];

	[sim populate];
}


- (void)willDrawScatterBody
{
	switch (state) {
		case 1:
        [sim advanceBeamPosition];
		break;
		
		case 2:
        [sim advanceTime];
		break;
		
		case 3:
        [sim advanceTimeAndBeamPosition];
		break;
		
		default:
		break;
	}
}
@end
