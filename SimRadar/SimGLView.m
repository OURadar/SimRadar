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

@synthesize animating;
@synthesize renderer;
//@synthesize recorder;

- (void)setFrame:(NSRect)frameRect
{
    CGLLockContext([[self openGLContext] CGLContextObj]);
    CGSize size = CGSizeMake(frameRect.size.width, frameRect.size.height);
    [renderer setSize:size];
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    
    [super setFrame:frameRect];
}

#pragma mark - Overrides

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
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	if (pixelFormat == NULL) {
		NSLog(@"Unable to create OpenGL pixel format object");
	}
	
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    if (context == NULL) {
        NSLog(@"Unable to create OpenGL context");
    }
	
	CGLContextObj cglContext = [context CGLContextObj];
    CGLEnable(cglContext, kCGLCECrashOnRemovedFunctions);

    CGLShareGroupObj cglSharegroup = CGLGetShareGroup(cglContext);
    gcl_gl_set_sharegroup(cglSharegroup);
    NSLog(@"OpenGL context prepared.  cglContext %p   cglShareGroup %p", cglContext, cglSharegroup);

    [self setPixelFormat:pixelFormat];
    [self setOpenGLContext:context];

    CGLSetCurrentContext(cglContext);
   
	[pixelFormat release];
    [context release];

    posix_memalign(&scratchBuffer, 64, 5120 * 2880 * 4);
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self stopAnimation];
}

- (void)dealloc
{
	// Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
	CVDisplayLinkStop(displayLink);
	
	CVDisplayLinkRelease(displayLink);
	
	[renderer release];
//    [recorder release];
    
    free(scratchBuffer);
	
	[super dealloc];
}

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	// The reshape function may have changed the thread to which our OpenGL
	// context is attached before prepareOpenGL and initGL are called.  So call
	// makeCurrentContext to ensure that our OpenGL context current to this
	// thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
	// to [self openGLContext])
	[self.openGLContext makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint ival = 1;
	[self.openGLContext setValues:&ival forParameter:NSOpenGLCPSwapInterval];

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

- (void)drawRect:(NSRect)dirtyRect
{
    //NSLog(@"drawRect: %d", animating);
    // Don't have to draw anything since this is the very first view.
    [self.openGLContext makeCurrentContext];
    CGLLockContext([self.openGLContext CGLContextObj]);
    glViewport(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    CGLFlushDrawable([self.openGLContext CGLContextObj]);
    CGLUnlockContext([self.openGLContext CGLContextObj]);
}

- (void)drawView
{
	// Drawing code here.
    [self.openGLContext makeCurrentContext];
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main
	// thread. Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing
    CGLLockContext([self.openGLContext CGLContextObj]);
	
	[renderer render];
	
    CGLFlushDrawable([self.openGLContext CGLContextObj]);
    
//  if (recorder) {
//     Add frame ...
//    }
    
#ifdef GEN_IMG
    NSLog(@"tic = %d", tic);
    if (tic > 3000 && tic <= 4800) {
		NSString *filename = [NSString stringWithFormat:@"~/Desktop/figs/img%04d.png", tic];
		NSLog(@"tic=%d  filename=%@\n", tic, filename.stringByExpandingTildeInPath);
        [self viewToFile:filename.stringByExpandingTildeInPath];
    } else if (tic > 3000) {
        [[NSApplication sharedApplication] terminate:self];
    }
#endif

    CGLUnlockContext([self.openGLContext CGLContextObj]);

    tic++;
    
}

#pragma mark - Methods

- (void)prepareRendererWithDelegate:(id)sender
{
    // Allocate a separate renderer
    if (self.wantsBestResolutionOpenGLSurface) {
        renderer = [[Renderer alloc] initWithDevicePixelRatio:[self.window backingScaleFactor]];
    } else {
        renderer = [Renderer new];
    }
    [renderer setSize:self.bounds.size];
    [renderer setDelegate:sender];
    [renderer allocateVAO:1];
}

- (void)startAnimation
{
	if (!animating) {
        animating = true;
        CVDisplayLinkStart(displayLink);
	}
}


- (void)stopAnimation
{
	if (animating) {
        animating = false;
		CVDisplayLinkStop(displayLink);
	}
}

#pragma mark - Image Export

- (NSBitmapImageRep *)bitmapImageRepFromViewWithClearBackground:(BOOL)clearBackground {
    
    int bytesPerRow;
    unsigned char *bitmapData;
    
    int width = self.bounds.size.width * self.window.backingScaleFactor;
    int height = self.bounds.size.height * self.window.backingScaleFactor;
    
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

- (NSBitmapImageRep *)bitmapImageRepFromView
{
	return [self bitmapImageRepFromViewWithClearBackground:NO];
}

- (NSImage *)imageFromView
{
    
	NSBitmapImageRep *imageRep = [self bitmapImageRepFromView];
    
	// Create the NSImage
	NSImage *image = [[[NSImage alloc] initWithSize:self.bounds.size] autorelease];
	[image addRepresentation:imageRep];
    
	return image;
}


- (void)viewToFile:(NSString *)filename
{
	NSBitmapImageRep *imageRep = [self bitmapImageRepFromView];
    NSLog(@"%@", imageRep);
	NSData *data = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSImageFallbackBackgroundColor, nil]];
	[data writeToFile:filename atomically:NO];
}


//- (void)detachRecorder {
//    [recorder release];
//    [self setRecorder:nil];
//}

@end
