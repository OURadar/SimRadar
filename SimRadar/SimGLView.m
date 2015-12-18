//
//  SimGLView.m
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "SimGLView.h"
#import "rs.h"

@interface SimGLView()
- (NSBitmapImageRep *)bitmapImageRepFromView;
- (NSBitmapImageRep *)bitmapImageRepFromViewWithClearBackground:(BOOL)clearBackground;
- (NSImage *)imageFromView;
@end

@implementation SimGLView

@synthesize animating;
@synthesize renderer;
@synthesize recorder;

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp* now,
									  const CVTimeStamp* outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags* flagsOut,
									  void* displayLinkContext)
{
	[(SimGLView *)displayLinkContext drawView];
    return kCVReturnSuccess;
}

#pragma mark -

// We setup the display window using Interface Builder so setup should be
// done here after the interface has been properly loaded and wired up.
- (void)awakeFromNib
{
	// NSLog(@"%@ awakeFromNib", self);
	NSOpenGLPixelFormatAttribute attr[] = {
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		0
	};
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	
	if (pf == NULL) {
		NSLog(@"Unable to create OpenGL pixel format object");
	}
	
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
	CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
	
	CGLContextObj cglContext = [context CGLContextObj];
	gcl_gl_set_sharegroup(CGLGetShareGroup(cglContext));

	[self setOpenGLContext:context];
	
	[context release];
	[pf release];

    if (self.wantsBestResolutionOpenGLSurface) {
        renderer = [[Renderer alloc] initWithDevicePixelRatio:[self.window backingScaleFactor]];
    } else {
        renderer = [Renderer new];
    }

    posix_memalign(&scratchBuffer, 64, 3840 * 2160 * 4);
}


- (void)dealloc
{
	// Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
	CVDisplayLinkStop(displayLink);
	
	CVDisplayLinkRelease(displayLink);
	
	[renderer release];
    
    free(scratchBuffer);
	
	[super dealloc];
}

#pragma mark -

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	// The reshape function may have changed the thread to which our OpenGL
	// context is attached before prepareOpenGL and initGL are called.  So call
	// makeCurrentContext to ensure that our OpenGL context current to this
	// thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
	// to [self openGLContext])
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint ival = 1;
	[[self openGLContext] setValues:&ival forParameter:NSOpenGLCPSwapInterval];
	
	// Init our renderer.  Use 0 for the defaultFBO which is appropriate for
	// OSX (but not iOS since iOS apps must create their own FBO)
	CGSize size = CGSizeMake(self.bounds.size.width, self.bounds.size.height);

    // Set the render size to bound size
    [renderer setSize:size];

    // Allocate VAO based on the number of CL devices
    //[renderer allocateVAO:RS_gpu_count()];
    [renderer allocateVAO:1];
    
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
    // Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
}

#pragma mark -

- (void)setFrame:(NSRect)frameRect {
	CGLLockContext([[self openGLContext] CGLContextObj]);
	CGSize size = CGSizeMake(frameRect.size.width, frameRect.size.height);
	[renderer setSize:size];
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
	
	[super setFrame:frameRect];
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
	[self drawView];
}

- (void)drawView
{
	// Drawing code here.
	[[self openGLContext] makeCurrentContext];
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main
	// thread. Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[renderer render];
	
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    
    if (recorder) {
//        [recorder addFrame:<#(NSView *)#>];
    }
    
#ifdef GEN_IMG
    if (tic > 3000 && tic <= 6000) {
		NSString *filename = [NSString stringWithFormat:@"~/Desktop/figs/img%04d.png", tic];
		NSLog(@"tic=%d  filename=%@\n", tic, filename.stringByExpandingTildeInPath);
        [self viewToFile:filename.stringByExpandingTildeInPath];
    } else if (tic > 3000) {
        [[NSApplication sharedApplication] terminate:self];
    }
#endif

    CGLUnlockContext([[self openGLContext] CGLContextObj]);

    tic++;
    
}


- (void)startAnimation {
	if (!animating) {
        animating = TRUE;
        CVDisplayLinkStart(displayLink);
	}
}


- (void)stopAnimation
{
	if (animating) {
        animating = FALSE;
		CVDisplayLinkStop(displayLink);
	}
}


- (void)windowWillClose:(NSNotification *)notification {
	[self stopAnimation];
}

#pragma mark -
#pragma NSResponder

//- (void)mouseDown:(NSEvent *)theEvent
//{
//}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[renderer panX:theEvent.locationInWindow.x Y:theEvent.locationInWindow.y dx:theEvent.deltaX dy:theEvent.deltaY];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	//NSLog(@"%d", theEvent.clickCount);
	if (theEvent.clickCount == 2) {
		[renderer resetViewParameters];
	}
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	// NSLog(@"mag = %.3f", event.magnification);
	[renderer magnify:1.5f * event.magnification];
}

- (void)rotateWithEvent:(NSEvent *)event
{
	//NSLog(@"rotate %.2f", event.rotation);
	[renderer rotate:event.rotation / 180.0f * M_PI];
	//	CGPoint location = [event locationInWindow];
	//	[renderer rotate:event.rotation X:location.x Y:location.y];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	GLfloat deltaX = [theEvent scrollingDeltaX];
	GLfloat deltaY = [theEvent scrollingDeltaY];
	
	if (ABS(deltaY) < ABS(deltaX)) {
		return;
	}

	if ([theEvent isDirectionInvertedFromDevice]) {
		deltaY *= -1.0f;
	}

	if (deltaY > 0.0f) {
		if (deltaY >= 6.0f) {
			[renderer magnify:0.10f];
		} else if (deltaY >= 3.0f) {
			[renderer magnify:0.05f];
		} else {
			[renderer magnify:0.02f];
		}
	} else {
		if (deltaY <= -6.0f) {
			[renderer magnify:-0.10f];
		} else if (deltaY <= -3.0f) {
			[renderer magnify:-0.05f];
		} else {
			[renderer magnify:-0.02f];
		}
	}
}

#pragma mark -
#pragma mark Image Export

- (NSBitmapImageRep *)bitmapImageRepFromViewWithClearBackground:(BOOL)clearBackground {
    
    int bytesPerRow;
    unsigned char *bitmapData;
    
    int width = renderer.width * [self.window backingScaleFactor];
    int height = renderer.height * [self.window backingScaleFactor];
    
    NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                          pixelsWide:width
                                                                          pixelsHigh:height
                                                                       bitsPerSample:8
                                                                     samplesPerPixel:clearBackground ? 4 : 3
                                                                            hasAlpha:NO
                                                                            isPlanar:NO
                                                                      colorSpaceName:NSDeviceRGBColorSpace
                                                                         bytesPerRow:0
                                                                        bitsPerPixel:0] autorelease];
    
    bitmapData = [imageRep bitmapData];
    bytesPerRow = (int)[imageRep bytesPerRow];
    
    glPixelStorei(GL_PACK_ROW_LENGTH, 8 * bytesPerRow / [imageRep bitsPerPixel]);
    glReadPixels(0, 0, width, height, clearBackground ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, scratchBuffer);
    
    for (int j=0; j<height; j++)
        bcopy(scratchBuffer + j * bytesPerRow, bitmapData + (height - 1 - j) * bytesPerRow, bytesPerRow);
    
    return imageRep;
}

- (NSBitmapImageRep *)bitmapImageRepFromView {
	return [self bitmapImageRepFromViewWithClearBackground:NO];
}

- (NSImage *)imageFromView {
    
	NSBitmapImageRep *imageRep = [self bitmapImageRepFromView];
    
	// Create the NSImage
	NSImage *image = [[[NSImage alloc] initWithSize:self.bounds.size] autorelease];
	[image addRepresentation:imageRep];
    
	return image;
}


- (void)viewToFile:(NSString *)filename {
	NSBitmapImageRep *imageRep = [self bitmapImageRepFromView];
    NSLog(@"%@", imageRep);
	NSData *data = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSImageFallbackBackgroundColor, nil]];
	[data writeToFile:filename atomically:NO];
}


- (void)detachRecorder {
    [recorder release];
    [self setRecorder:nil];
}

@end
