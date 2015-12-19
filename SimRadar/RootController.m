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
- (void)showLiveDisplay:(id)sender;
@end

@implementation RootController

@synthesize startRecordMenuItem, stopRecordMenuItem;

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

- (void)showLiveDisplay:(id)sender
{
    [dc.window setLevel:NSNormalWindowLevel];
    [dc.window makeKeyAndOrderFront:nil];
}

- (void)updateProgressIndicator:(id)sender
{
    [sc.progress setDoubleValue:initProgress];
    [sc.progress setNeedsDisplay:TRUE];
}

#pragma mark -
#pragma mark Methods

- (IBAction)newLiveDisplay:(id)sender
{
	if (dc == nil) {
		dc = [[DisplayController alloc] initWithWindowNibName:@"LiveDisplay" viewDelegate:self];
        NSLog(@"Setting window level to %d", -1);
        [dc.window setLevel:-1];
        [dc showWindow:self];
    } else {
        [self showLiveDisplay:self];
        [dc.glView startAnimation];
    }
}

- (IBAction)playPause:(id)sender
{
	state = state == STATE_MAX ? 0 : state + 1;
	//NSLog(@"state = %d", state);
	
	switch (state) {
		case 1:
			[self setIcon:2];
			break;

		case 2:
			[self setIcon:19];
			break;

		case 3:
			[self setIcon:11];
			break;

		default:
			[self setIcon:1];
			break;
	}
}

- (IBAction)resetSimulator:(id)sender
{
	[sim upload];
}

- (IBAction)startRecord:(id)sender
{
    if ([dc.glView recorder]) {
        NSLog(@"Recorder exists.");
        return;
    }
    Recorder *recorder = [[Recorder alloc] initForView:dc.glView];
    [dc.glView setRecorder:recorder];
}

- (IBAction)stopRecord:(id)sender
{
    [dc.glView detachRecorder];
}

#pragma mark -

- (void)awakeFromNib
{
    sc = [[SplashController alloc] initWithWindowNibName:@"Splash"];
    [sc setDelegate:self];
    //[sc.window makeKeyAndOrderFront:self];
    [sc showWindow:self];
    
    
	iconFolder = [[[NSBundle mainBundle] pathForResource:@"Minion-Icons" ofType:nil] retain];
	icons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:iconFolder error:nil] retain];

    state = 2;

    NSLog(@"%@ %@", startRecordMenuItem, stopRecordMenuItem);
    
//    [startRecordMenuItem setEnabled:TRUE];
//    [stopRecordMenuItem setEnabled:FALSE];
    
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

- (void)alertMissingResources {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Error"];
    [alert setInformativeText:@"Required resource(s) cannot be found in any of the search paths. Check Console log for more details."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        return;
    }
    [alert release];
}

#pragma mark -
#pragma mark RendererDelegate

#if defined(DEBUG)
#define DNSLog(_expr) { NSLog(_expr); }
#else
#define DNSLog(_expr) {}
#endif

- (void)createSimulation {
    @autoreleasepool {
        sim = [[SimPoint alloc] initWithDelegate:self];
        if (sim) {
            NSLog(@"New simulation domain initiated.");
            // Wire the simulator to the controller.
            // The displayController will tell the renderer how many scatter body
            // the simulator is using and pass the anchor points from RS API to
            // the renderer
            [dc setSim:sim];
            [dc.glView startAnimation];
        } else {
            NSLog(@"Error initializing simulation domain.");
            //[self performSelectorOnMainThread:@selector(alertMissingResources) withObject:nil waitUntilDone:TRUE];
            //[[NSApplication sharedApplication] terminate:self];
            [dc emptyDomain];
        }
    }
}

- (void)glContextVAOPrepared
{
	DNSLog(@"glContextVAOPrepared");

	if (sim) {
		NSLog(@"There is a simulation session running. It will be re-activated. The muti-session version has not been implemented.");
	} else {
        [self performSelectorInBackground:@selector(createSimulation) withObject:nil];
	}
}


- (void)vbosAllocated:(GLuint [][8])vbos
{
	DNSLog(@"vbosAllocated:");

    if (sim) {
        [sim shareVBOsWithGL:vbos];
        
        [sim populate];
        
        for (int k=1; k<RENDERER_MAX_DEBRIS_TYPES; k++) {
            GLuint pop = [sim populationForSpecies:k];
            [dc.glView.renderer setPopulationTo:pop forSpecies:k forDevice:0];
        }
    } else {
        NSLog(@"No simulation");
    }
    [dc.glView.renderer setDebrisCountsHaveChanged:TRUE];
}


- (void)willDrawScatterBody
{
    if (sim == nil) {
        return;
    }
	switch (state) {
		default:
			[sim advanceTimeAndBeamPosition];
            [dc.glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
			break;

		case 1:
			// Nothing moves
			break;
			
		case 2:
			[sim advanceTime];
			break;

		case 3:
			[sim advanceBeamPosition];
            [dc.glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
			break;
	}
}

#pragma mark -
#pragma mark SplashControllerDelegate

- (void)splashWindowDidLoad:(id)sender
{
    [self newLiveDisplay:self];
}

#pragma mark -
#pragma mark SimPointDelegate

- (void)timeAdvanced:(id)sender
{
    [sc release];
    sc = nil;
}

- (void)progressUpdated:(double)completionPercentage message:(NSString *)message
{
    initProgress = completionPercentage;
    [self performSelectorOnMainThread:@selector(updateProgressIndicator:) withObject:nil waitUntilDone:NO];

    [sc.label setStringValue:message];
    
    if (completionPercentage >= 99.0) {
        [sc close];
        [sc release];
        sc = nil;
        [self performSelectorOnMainThread:@selector(showLiveDisplay:) withObject:nil waitUntilDone:NO];
    }
}

@end
