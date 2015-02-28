//
//  DisplayController.m
//  _radarsim
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "DisplayController.h"
#import "FullscreenWindow.h"
#import "RootController.h"

// Fullscreen window
FullscreenWindow *fullscreenWindow;

// The initial window
NSWindow *standardWindow;


@interface DisplayController ()
- (void)setSizeAndCentralized:(NSSize)newSize;
- (void)checkInputIdling;
@end

@implementation DisplayController

#pragma mark -
#pragma mark Private Methods

- (void)setSizeAndCentralized:(NSSize)newSize
{
	if (fullscreenWindow) {
		return;
	}
	
	NSRect rect = self.window.frame;
	rect.origin.x += roundf(0.5f * (rect.size.width - newSize.width));
	rect.origin.y += roundf(0.5f * (rect.size.height - newSize.height));
	rect.size = newSize;
	
	[self.window setFrame:rect display:YES];
}

- (void)checkInputIdling
{
    CFTimeInterval
    t = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
    
    if (t > 2.0) {
        [NSCursor setHiddenUntilMouseMoves:YES];
    } else {
        [NSCursor unhide];
    }
}

#pragma mark -
#pragma mark Properties

// @synthesize sim;
@synthesize glView;

- (void)setSim:(SimPoint *)newSim
{
	[sim release];
	sim = [newSim retain];
	
	RSVolume domain = [sim simulationDomain];

	[glView.renderer setBodyCount:(GLuint)sim.pointCount];
	[glView.renderer setGridAtOrigin:(GLfloat *)&domain.origin size:(GLfloat *)&domain.size];
	[glView.renderer setAnchorPoints:(GLfloat *)sim.anchors number:(GLuint)sim.anchorCount];
	[glView.renderer setAnchorLines:(GLfloat *)sim.anchorLines number:(GLuint)sim.anchorLineCount];
	
	[glView.renderer setCenterPoisitionX:domain.origin.x + 0.5f * domain.size.x
									   y:domain.origin.y + 0.5f * domain.size.y
									   z:domain.origin.z + 0.5f * domain.size.z];
	
#ifdef DEBUG
	NSLog(@"Particles wired to view renderer (%d)", (int)sim.pointCount);
	NSLog(@"Domain center @ [ X %.2f  Y %.2f  Z %.2f ]", domain.origin.x + 0.5f * domain.size.x,
		  domain.origin.y + 0.5f * domain.size.y, domain.origin.z + 0.5f * domain.size.z);
#endif
}

- (SimPoint *)sim
{
	return sim;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromNib
{
	// Initialization code here.
	NSLog(@"Assigning %@ as %@'s delegate", rootSender, glView.renderer);
	[glView.renderer setDelegate:rootSender];
}


- (id)initWithWindowNibName:(NSString *)windowNibName viewDelegate:(id)sender
{
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		rootSender = sender;
	}
	return self;
}

- (void)dealloc
{
	[glView release];
	[sim release];
	
	[super dealloc];
}

#pragma mark -
#pragma NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
	#ifdef DEBUG
	NSLog(@"Stopping animation ...");
	#endif
	[glView stopAnimation];
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
		
	#ifdef DEBUG
	NSLog(@"Starting animation ...");
	#endif
	
	[glView startAnimation];
}


#pragma mark -
#pragma mark IBAction

- (IBAction)spinModel:(id)sender
{
	[glView.renderer toggleSpinModel];
}

- (IBAction)normalSizeWindow:(id)sender
{
	[self setSizeAndCentralized:NSMakeSize(640.0f, 480.0f)];
}

- (IBAction)doubleSizeWindow:(id)sender
{
	[self setSizeAndCentralized:NSMakeSize(1280.0f, 960.0f)];
}

- (IBAction)setSizeTo720p:(id)sender
{
	[self setSizeAndCentralized:NSMakeSize(1280.0f, 720.0f + 17.0f)];
}

- (IBAction)setSizeTo4K:(id)sender
{
//    [self.window setFrame:NSMakeRect(0.0f, -3000.0f, 3180.0f, 2160.0f + 17.0f) display:NO];
    NSSize size = NSMakeSize(3180.0f, 2160.0f);
    
    //[glView setFrameSize:size];
    [glView setBoundsSize:size];
    [glView.renderer setSize:size];
}

- (void)keyDown:(NSEvent *)event
{
	unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
	switch (c)
	{
		case 27:
			// Handle [ESC] key
			if (fullscreenWindow != nil) {
				[self windowMode];
			}
			break;
			
		case NSLeftArrowFunctionKey:
			// Left
			[glView.renderer panX:0.0f Y:0.0f dx:-30.0f dy:0.0f];
			break;

		case NSRightArrowFunctionKey:
			// Right
			[glView.renderer panX:0.0f Y:0.0f dx:+30.0f dy:0.0f];
			break;

		case NSDownArrowFunctionKey:
			// Down
			[glView.renderer panX:0.0f Y:0.0f dx:0.0f dy:+30.0f];
			break;
			
		case NSUpArrowFunctionKey:
			// Up
			[glView.renderer panX:0.0f Y:0.0f dx:0.0f dy:-30.0f];
			break;
			
		case '+':
		case '=':
			// Zoom in
			[glView.renderer magnify:+0.05f];
			break;
			
		case '-':
			[glView.renderer magnify:-0.05f];
			break;
			
		case 'f':
			// Have [f] key toggle fullscreen
			if (fullscreenWindow == nil) {
				[self fullscreenMode:nil];
			} else {
				[self windowMode];
			}
			break;
			
		case 's':
			[glView.renderer toggleSpinModelReverse];
			break;
			
		case 'S':
			[glView.renderer toggleSpinModel];
			break;
			
		case 'p':
			if ([rootSender respondsToSelector:@selector(playPause:)]) {
				[rootSender playPause:self];
			}
			break;
			
		case 'r':
			[rootSender resetSimulator:self];
			break;

		case ']':
			[glView.renderer increaseLeafCount];
			break;
		case '[':
			[glView.renderer decreaseLeafCount];
			break;
			
        case 'b':
            [sim homeBeamPosition];
            [glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
            break;
            
        case 'o':
            [glView.renderer decreaseBackgroundOpacity];
            break;
        case 'O':
            [glView.renderer increaseBackgroundOpacity];
            break;
            
		default:
			// Allow other character to be handled by how the superclass defined it
			[super keyDown:event];
			break;
	}
}

- (void)windowMode
{
	if (fullscreenWindow == nil) {
		// Application is still in window mode
		return;
	}
	
	[glView setFrameSize:standardWindow.frame.size];
	
	[self setWindow:standardWindow];
	
	[standardWindow release];
	
	[self.window setContentView:glView];
	
	[self.window makeKeyAndOrderFront:self];
	
	// Release the fullscreen window
	[fullscreenWindow release];
	
	// Set to nil because we will use this to check the mode
	fullscreenWindow = nil;
	
	// Stop the input check
	[inputMonitorTimer invalidate];
	[NSCursor unhide];
}

- (IBAction)fullscreenMode:(id)sender
{
	if (fullscreenWindow) {
		[fullscreenWindow makeKeyAndOrderFront:self];
		return;
	}
	
	fullscreenWindow = [FullscreenWindow new];
	
	[glView setFrameSize:fullscreenWindow.frame.size];
	
	[fullscreenWindow setContentView:glView];
	
	standardWindow = [self.window retain];
	
	// Hide non-fullscreen window so it doesn't show up when switching out
	// of this app (i.e. with CMD-TAB)
	[standardWindow orderOut:self];
	
	// Set controller to the fullscreen window so that all input will go to
	// this controller (self)
	[self setWindow:fullscreenWindow];
	
	// Show the window and make it the key window for input
	[fullscreenWindow makeKeyAndOrderFront:self];
	
	[NSCursor setHiddenUntilMouseMoves:YES];

	inputMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
														 target:self
													   selector:@selector(checkInputIdling)
													   userInfo:nil
														repeats:YES];
	
}

@end
