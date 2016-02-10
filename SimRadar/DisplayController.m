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

@synthesize glView;

- (void)setSim:(SimPoint *)newSim
{
	[sim release];
	sim = [newSim retain];
	
	RSVolume domain = [sim simulationDomain];
    
    //NSLog(@"sim.anchorCount = %d", sim.anchorCount);
    
    NSString *name = [[NSRunningApplication currentApplication] localizedName];
    [glView.renderer setTitleString:name];

	[glView.renderer setBodyCount:(GLuint)sim.pointCount forDevice:0];
	[glView.renderer setGridAtOrigin:(GLfloat *)&domain.origin size:(GLfloat *)&domain.size];
	[glView.renderer setAnchorPoints:(GLfloat *)sim.anchors number:(GLuint)sim.anchorCount];
	[glView.renderer setAnchorLines:(GLfloat *)sim.anchorLines number:(GLuint)sim.anchorLineCount];
	
	[glView.renderer setCenterPoisitionX:domain.origin.x + 0.5f * domain.size.x
									   y:domain.origin.y + 0.5f * domain.size.y
									   z:domain.origin.z + 0.5f * domain.size.z];
    
    [glView.renderer setResetRange:sim.recommendedViewRange];
    
//    GLKMatrix4 modelRotate = GLKMatrix4MakeRotation(-0.15f, 1.0f, 0.0f, 0.0f);
//    modelRotate = GLKMatrix4RotateY(modelRotate, 1.5f);
    
    GLKMatrix4 modelRotate = GLKMatrix4MakeRotation(0.25f, 1.0f, 0.0f, 0.0f);
    modelRotate = GLKMatrix4RotateY(modelRotate, -0.3f);
    
    [glView.renderer setResetModelRotate:modelRotate];
    
    [glView.renderer stopSpinModel];
    
    [glView.renderer resetViewParameters];
    
#ifdef DEBUG
    NSLog(@"Recommend viewing at %.2f m", sim.recommendedViewRange);
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
	[glView.renderer setDelegate:rootSender];
    
    mkey = 0;
    
    [self becomeFirstResponder];
}


- (id)initWithWindowNibName:(NSString *)windowNibName viewDelegate:(id)sender
{
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		rootSender = sender;
        debrisId = 1;
        NSLog(@"Allocating recorder ...");
	}
	return self;
}

- (void)dealloc
{
    NSLog(@"%@ deallocating ...", self);
	[glView release];
	[sim release];
    
    if (sampleAnchorLines != NULL) {
        free(sampleAnchorLines);
    }
    
    if (sampleAnchors != NULL) {
        free(sampleAnchors);
    }
	
	[super dealloc];
}

#pragma mark -
#pragma NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
	#ifdef DEBUG
	NSLog(@"Stopping animation ...");
	#endif
    
    if (recorder) {
        [recorder stopRecording];
        recorder = nil;
    }
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

- (IBAction)setSizeTo1080p:(id)sender
{
    [self setSizeAndCentralized:NSMakeSize(1920.0f, 1080.0f + 17.0f)];
}

- (IBAction)setSizeTo4K:(id)sender
{
//    [self.window setFrame:NSMakeRect(0.0f, -3000.0f, 3180.0f, 2160.0f + 17.0f) display:NO];
    NSSize size = NSMakeSize(3180.0f, 2160.0f);
    
    //[glView setFrameSize:size];
    [glView setBoundsSize:size];
    [glView.renderer setSize:size];
}

#pragma mark -
#pragma NSResponder

//- (void)mouseDown:(NSEvent *)theEvent
//{
//}

- (void)mouseDragged:(NSEvent *)event
{
    [glView.renderer panX:event.locationInWindow.x Y:event.locationInWindow.y dx:event.deltaX dy:event.deltaY];
}

- (void)mouseUp:(NSEvent *)event
{
    if (event.clickCount == 2) {
        [glView.renderer resetViewParameters];
    }
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    // NSLog(@"mag = %.3f", event.magnification);
    [glView.renderer magnify:1.5f * event.magnification];
}

- (void)rotateWithEvent:(NSEvent *)event
{
    //NSLog(@"rotate %.2f", event.rotation);
    [glView.renderer rotate:event.rotation / 180.0f * M_PI];
    //	CGPoint location = [event locationInWindow];
    //	[renderer rotate:event.rotation X:location.x Y:location.y];
}


- (void)keyDown:(NSEvent *)event
{
	unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
	
    GLint ret;
    GLint counts[RS_MAX_GPU_DEVICE];

	switch (c)
	{
		case 27:
			// Handle [ESC] key
			if (fullscreenWindow != nil) {
                [self windowMode:nil];
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
			
        case 'h':
            // Toggle HUD
            //[glView.renderer toggleHUDVisibility];
            [glView.renderer cycleForwardHUDConfig];
            break;
            
        case 'H':
            [glView.renderer cycleReverseHUDConfig];
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
                [self windowMode:nil];
			}
			break;
			
        case 'g':
            [glView.renderer cycleFBO];
            break;
        
        case 'G':
            [glView.renderer cycleFBOReverse];
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
            ret = [sim increasePopulationForDebris:debrisId returnCounts:counts];
            if (ret >= 0) {
//                [glView.renderer setPopulationTo:ret forDebris:debrisId];
                for (int i = 0; i< sim.deviceCount; i++) {
                    [glView.renderer setPopulationTo:counts[i] forDebris:debrisId forDevice:i];
                }
                [glView.renderer setDebrisCountsHaveChanged:true];
            }
			break;
            
		case '[':
            ret = [sim decreasePopulationForDebris:debrisId returnCounts:counts];
            if (ret >= 0) {
//                [glView.renderer setPopulationTo:ret forDebris:debrisId];
                for (int i = 0; i< sim.deviceCount; i++) {
                    [glView.renderer setPopulationTo:counts[i] forDebris:debrisId forDevice:i];
                }
                [glView.renderer setDebrisCountsHaveChanged:true];
            }
			break;
			
        case 'b':
            [sim homeBeamPosition];
            [glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
            break;
            
        case 'B':
            [sim randomBeamPosition];
            [glView.renderer setBeamElevation:sim.elevationInDegrees azimuth:sim.azimuthInDegrees];
            break;
            
        case 'o':
            [glView.renderer decreaseBackgroundOpacity];
            break;
            
        case 'O':
            [glView.renderer increaseBackgroundOpacity];
            break;
            
        case '1':
        case '2':
        case '3':
        case '4':
            debrisId = c - '0';
            NSLog(@"debrisId = %d", debrisId);
            break;
            
        case 'c':
            [glView.renderer cycleForwardColormap];
            break;
            
        case 'C':
            [glView.renderer cycleReverseColormap];
            break;
        
        case 'v':
            [glView.renderer cycleVFX];
            break;
            
        case 'm':
            mkey = mkey >= 5 ? 0 : mkey + 1;
            if (mkey % 2 == 0) {
                [sim cycleScattererColorMode];
            }
            [glView.renderer toggleBlurSmallScatterer];
            break;
            
		default:
			// Allow other character to be handled by how the superclass defined it
			[super keyDown:event];
			break;
	}
}

- (void)scrollWheel:(NSEvent *)event
{
    if ([event modifierFlags] & NSShiftKeyMask) {
//        GLfloat deltaX = [event scrollingDeltaX];
        GLfloat deltaY = [event scrollingDeltaY];

        if (deltaY > 0.0f) {
            [sim decreaseDemoRange];
        } else {
            [sim increaseDemoRange];
        }
        return;
    }

    // No shift key is held
    GLfloat deltaX = [event scrollingDeltaX];
	GLfloat deltaY = [event scrollingDeltaY];

	if (ABS(deltaY) < ABS(deltaX)) {
		return;
	}

	if ([event isDirectionInvertedFromDevice]) {
		deltaY *= -1.0f;
	}

	if (deltaY > 0.0f) {
		if (deltaY >= 6.0f) {
			[glView.renderer magnify:0.10f];
		} else if (deltaY >= 3.0f) {
			[glView.renderer magnify:0.05f];
		} else {
			[glView.renderer magnify:0.02f];
		}
	} else {
		if (deltaY <= -6.0f) {
			[glView.renderer magnify:-0.10f];
		} else if (deltaY <= -3.0f) {
			[glView.renderer magnify:-0.05f];
		} else {
			[glView.renderer magnify:-0.02f];
		}
	}
}

- (IBAction)windowMode:(id)sender
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

- (void)emptyDomain {
    int i;
    
    GLfloat orig[] = {-1000.0f, 5000.0f, 0.0f};
    GLfloat size[] = {2000.0f, 2000.0f, 2000.0f};
    
    GLfloat anchors[] =
    {
        orig[0] + 0.5f * size[0], orig[1]          , orig[2] + 0.5f * size[2], 10.0f,
        orig[0] + 0.5f * size[0], orig[1] + size[1], orig[2] + 0.5f * size[2], 10.0f,
        0.0f                    ,              0.0f,           0.5f * size[2], 20.0f
    };
    
    GLfloat anchorLines[] =
    {
        -1.0f, -1.0f, -1.0f, 1.0f,  //
        +1.0f, -1.0f, -1.0f, 1.0f,
        -1.0f, +1.0f, -1.0f, 1.0f,
        +1.0f, +1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, +1.0f, 1.0f,
        +1.0f, -1.0f, +1.0f, 1.0f,
        -1.0f, +1.0f, +1.0f, 1.0f,
        +1.0f, +1.0f, +1.0f, 1.0f,
        -1.0f, -1.0f, -1.0f, 1.0f,  //
        -1.0f, +1.0f, -1.0f, 1.0f,
        +1.0f, -1.0f, -1.0f, 1.0f,
        +1.0f, +1.0f, -1.0f, 1.0f,
        -1.0f, -1.0f, +1.0f, 1.0f,
        -1.0f, +1.0f, +1.0f, 1.0f,
        +1.0f, -1.0f, +1.0f, 1.0f,
        +1.0f, +1.0f, +1.0f, 1.0f,
        -1.0f, -1.0f, -1.0f, 1.0f,  //
        -1.0f, -1.0f, +1.0f, 1.0f,
        +1.0f, -1.0f, -1.0f, 1.0f,
        +1.0f, -1.0f, +1.0f, 1.0f,
        -1.0f, +1.0f, -1.0f, 1.0f,
        -1.0f, +1.0f, +1.0f, 1.0f,
        +1.0f, +1.0f, -1.0f, 1.0f,
        +1.0f, +1.0f, +1.0f, 1.0f
    };
    for (i = 0; i < sizeof(anchorLines) / sizeof(cl_float4); i++) {
        anchorLines[4 * i    ] = size[0] * (0.25f * anchorLines[4 * i    ] + 0.5f) + orig[0];
        anchorLines[4 * i + 1] = size[1] * (0.25f * anchorLines[4 * i + 1] + 0.5f) + orig[1];
        anchorLines[4 * i + 2] = size[2] * (0.25f * anchorLines[4 * i + 2] + 0.5f) + orig[2];
    }

    // Allocate and copy over the sample data based on the local arrays
    sampleAnchors = (GLfloat *)malloc(sizeof(anchors));
    sampleAnchorLines = (GLfloat *)malloc(sizeof(anchorLines));
    memcpy(sampleAnchors, anchors, sizeof(anchors));
    memcpy(sampleAnchorLines, anchorLines, sizeof(anchorLines));
    
    [glView.renderer setGridAtOrigin:orig size:size];
    [glView.renderer setAnchorPoints:sampleAnchors number:sizeof(anchors) / sizeof(cl_float4)];
    [glView.renderer setCenterPoisitionX:orig[0] + 0.5f * size[0]
                                       y:orig[1] + 0.5f * size[1]
                                       z:orig[2] + 0.5f * size[2]];
    [glView.renderer setAnchorLines:sampleAnchorLines number:sizeof(anchorLines) / sizeof(cl_float4)];

    NSSize newSize = NSMakeSize(1280.0f, 720.0f);
    CGFloat xPos = (self.window.screen.frame.size.width - newSize.width) * 0.5f;
    CGFloat yPos = (self.window.screen.frame.size.height - newSize.height) * 0.5f;
    [self.window setFrame:NSMakeRect(xPos, yPos, newSize.width, newSize.height) display:YES];
}

@end
