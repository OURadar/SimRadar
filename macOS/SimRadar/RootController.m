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
- (void)closeSplashWindow:(id)sender;
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
    [sc.progress setNeedsDisplay:true];
}

#pragma mark -
#pragma mark Methods

- (IBAction)newLiveDisplay:(id)sender
{
	if (dc == nil) {
		dc = [[DisplayController alloc] initWithWindowNibName:@"LiveDisplay" viewDelegate:self];
        //[dc.window setLevel:-1];
        [dc showWindow:self];
    } else {
        [self showLiveDisplay:self];
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

- (IBAction)topView:(id)sender
{
    [dc.glView.renderer topView];
}

//- (IBAction)startRecord:(id)sender
//{
//    if ([dc.glView recorder]) {
//        NSLog(@"Recorder exists.");
//        return;
//    }
//    Recorder *recorder = [[Recorder alloc] initForView:dc.glView];
//    [dc.glView setRecorder:recorder];
//}

//- (IBAction)stopRecord:(id)sender
//{
//    [dc.glView detachRecorder];
//}

#pragma mark -

- (void)awakeFromNib
{
    // Default simulation state: 0 - advance beam and time; 1 - advance nothing; 2 - advance beam
    state = 0;

    // Check folders
    NSFileManager *fm = [NSFileManager defaultManager];
    const char *homeFolder = getenv("HOME");
    NSString *tableFolder = nil;
    for (NSString *folder in @[@"Downloads", @"Documents", @"Desktop"]) {
        NSString *path = [NSString stringWithFormat:@"%s/%@/tables", homeFolder, folder];
        NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
        #ifdef DEBUG
        NSLog(@"%@ -> %@", path, attr);
        #endif
        if (attr) {
            if (tableFolder == nil) {
                tableFolder = folder;
            }
        }
    }
    bool allExists = true;
    bool allAccessible = true;
    if (tableFolder) {
        // Check LES, ADM and RCS
        for (NSString *folder in @[@"les", @"adm", @"rcs"]) {
            NSString *path = [NSString stringWithFormat:@"%s/%@/tables/%@", homeFolder, tableFolder, folder];
            NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
            #ifdef DEBUG
            NSLog(@"%@ -> %@", path, attr);
            #endif
            allExists &= (attr != nil);
        }
        NSLog(@"allExists = %s", allExists ? "true" : "false");
        for (NSString *file in @[@"les/suctvort/fort.10_2", @"adm/plate.adm", @"rcs/brick.rcs"]) {
            NSString *path = [NSString stringWithFormat:@"%s/%@/tables/%@", homeFolder, tableFolder, file];
            NSLog(@"%@ -> %@", path, [fm attributesOfItemAtPath:path error:nil]);
            FILE *fid = fopen([path UTF8String], "r");
            if (fid == NULL) {
                allAccessible = false;
                break;
            }
            fclose(fid);
        }
        NSLog(@"allAccessible = %s", allAccessible ? "true" : "false");
    }
    if (allExists && allAccessible) {
        sc = [[SplashController alloc] initWithWindowNibName:@"Splash"];
        [sc setDelegate:self];
        [sc.window makeKeyAndOrderFront:nil];
        [sc showWindow:self];
    } else {
        [self alertMissingResources];
    }

	iconFolder = [[[NSBundle mainBundle] pathForResource:@"Minion-Icons" ofType:nil] retain];
	icons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:iconFolder error:nil] retain];

//    NSLog(@"%@ %@", startRecordMenuItem, stopRecordMenuItem);
    
//    [startRecordMenuItem setEnabled:true];
//    [stopRecordMenuItem setEnabled:false];
    
}

- (void)dealloc
{
	[iconFolder release];
	[icons release];
	
	[dc release];
	[sim release];
    
    [startRecordMenuItem release];
    [stopRecordMenuItem release];
	
	[super dealloc];
}

#pragma mark -

- (void)alertMissingResources {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Resources Not Found"];
    [alert setInformativeText:@"Required resources, e.g., LES, ADM and or RCS tables cannot be found in any of the search paths. Check Console log for more details."];
    [alert setAlertStyle:NSAlertStyleCritical];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[NSApplication sharedApplication] terminate:self];
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

- (void)createSimulation:(NSNumber *)number {
    @autoreleasepool {
        CGLShareGroupObj sharegroup = (CGLShareGroupObj)[number longValue];
        NSLog(@"Creating a simulation with sharedGroup %p ...", sharegroup);
        sim = [[SimPoint alloc] initWithDelegate:self cglShareGroup:sharegroup];
        if (sim) {
            // Wire the simulator to the controller.
            // The displayController will tell the renderer how many scatter body
            // the simulator is using and pass the anchor points from RS framework to
            // the Renderer object.
            [dc setSim:sim];
            [dc.glView startAnimation];
        } else {
            NSLog(@"Error initializing simulation domain.");
            [dc emptyDomain];
            [dc.glView startAnimation];
            [dc performSelectorOnMainThread:@selector(setSizeTo720p:) withObject:nil waitUntilDone:NO];

            sleep(2);
            
            [self performSelectorOnMainThread:@selector(closeSplashWindow:) withObject:nil waitUntilDone:NO];
        }
    }
}

#pragma mark -
#pragma mark RendererDelegate

- (void)glContextVAOPrepared
{
	DNSLog(@"glContextVAOPrepared");

	if (sim) {
		NSLog(@"There is a simulation session running. It will be re-activated. The muti-session version has not been implemented.");
	} else {
        CGLContextObj context = CGLGetCurrentContext();
        CGLShareGroupObj sharegroup = CGLGetShareGroup(context);
        NSNumber *number = [NSNumber numberWithLong:(long)sharegroup];
        [self performSelectorInBackground:@selector(createSimulation:) withObject:number];
	}
}


- (void)vbosAllocated:(GLuint [][8])vbos
{
	DNSLog(@"vbosAllocated:");

    if (sim) {
        [sim shareVBOsWithGL:vbos];
        
        [sim populate];

        for (int k = 1; k < RENDERER_MAX_DEBRIS_TYPES; k++) {
            GLuint pop = [sim populationForDebris:k];
            [dc.glView.renderer setPopulationTo:pop forDebris:k forDevice:0];
        }
        // Initial draw mode
        [dc setDrawMode:0];
        // Get some information from the simulator
        [dc.glView.renderer setOverlayText:sim.simulationDescription withTitle:@"Basic Parameters"];
    } else {
        NSLog(@"No simulation yet.");
    }
}


- (void)willDrawScatterBody
{
    if (sim == nil) {
        if (noSimWarning++ < 3) {
            NSLog(@"willDrawScatterBody: No simulation");
        }
        return;
    }
    if (!sim.isPopulated) {
        NSLog(@"Simulation not ready.");
        return;
    }
	switch (state) {
		default:
			[sim advanceTimeAndBeamPosition];
            [dc.glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
			break;

		case 1:
            [sim advanceNone];
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
#pragma mark Dismiss SplashController

- (void)closeSplashWindow:(id)sender {
    [sc close];
    [sc release];
    sc = nil;
}

#pragma mark -
#pragma mark SimPointDelegate

- (void)timeAdvanced:(id)sender
{
    [sc release];
    sc = nil;
}

- (void)progressUpdatedMain:(NSArray *)input
{
    NSNumber *number = [input objectAtIndex:0];
    NSString *message = [input objectAtIndex:1];
    initProgress = [number doubleValue];
    [self updateProgressIndicator:nil];
    [sc.label setStringValue:message];
    if (initProgress >= 99.0) {
        [sc close];
        [sc release];
        sc = nil;
        [self showLiveDisplay:self];
    }
}

- (void)progressUpdated:(double)completionPercentage message:(NSString *)message
{
    NSArray *input = @[[NSNumber numberWithDouble:completionPercentage], message];
    [self performSelectorOnMainThread:@selector(progressUpdatedMain:) withObject:input waitUntilDone:YES];
}

@end
