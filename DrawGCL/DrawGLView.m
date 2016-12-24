//
//  DrawGLView.m
//
//  Created by Boon Leng Cheong on 12/24/16.
//  Copyright © 2016 Boon Leng Cheong. All rights reserved.
//

#import "DrawGLView.h"

@implementation DrawGLView

@synthesize animating;
@synthesize renderer;

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext) {
    [(DrawGLView *)displayLinkContext drawView];
    return kCVReturnSuccess;
}

#pragma mark -

// We setup the display window using Interface Builder so setup should be
// done here after the interface has been properly loaded and wired up.
- (void)awakeFromNib {
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

    CGLContextObj cglContext = context.CGLContextObj;
    CGLEnable(cglContext, kCGLCECrashOnRemovedFunctions);

    CGLShareGroupObj cglSharegroup = CGLGetShareGroup(cglContext);
    gcl_gl_set_sharegroup(cglSharegroup);

    NSLog(@"awakeFromNib.  cglContext %p   cglShareGroup %p", cglContext, cglSharegroup);

    [self setPixelFormat:pixelFormat];
    [self setOpenGLContext:context];

    CGLSetCurrentContext(cglContext);

    [pixelFormat release];
    [context release];
    
    NSLog(@"Emptying domain ...");

    [self emptyDomain];
    
    posix_memalign(&scratchBuffer, 64, 5120 * 2880 * 4);
}

- (void)dealloc {
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
    CVDisplayLinkStop(displayLink);
    
    CVDisplayLinkRelease(displayLink);

    [renderer release];

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
    
    // Init our renderer.  Use 0 for the defaultFBO which is appropriate for
    // OSX (but not iOS since iOS apps must create their own FBO)
   
    // Set the render size to bound size
    if (self.wantsBestResolutionOpenGLSurface) {
        renderer = [[Renderer alloc] initWithDevicePixelRatio:self.window.backingScaleFactor];
    } else {
        renderer = [Renderer new];
    }
    [renderer setSize:self.bounds.size];
    [renderer allocateVAO];
    
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
    
    // Set the display link for the current renderer
    CGLContextObj cglContext = self.openGLContext.CGLContextObj;
    CGLPixelFormatObj cglPixelFormat = self.pixelFormat.CGLPixelFormatObj;
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // Register to be notified when the window closes so we can stop the displaylink
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:[self window]];
}

#pragma mark -

- (void)setFrame:(NSRect)frameRect {
    CGLLockContext(self.openGLContext.CGLContextObj);
    [renderer setSize:frameRect.size];
    CGLUnlockContext(self.openGLContext.CGLContextObj);
    
    [super setFrame:frameRect];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    // Don't have to draw anything since this is the very first view.
    [self.openGLContext makeCurrentContext];
    CGLLockContext([self.openGLContext CGLContextObj]);
    glViewport(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    CGLFlushDrawable([self.openGLContext CGLContextObj]);
    CGLUnlockContext([self.openGLContext CGLContextObj]);
}

- (void)drawView {
    // Drawing code here.
    [self.openGLContext makeCurrentContext];
    
    // We draw on a secondary thread through the display link
    // When resizing the view, -reshape is called automatically on the main
    // thread. Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing
    CGLLockContext([self.openGLContext CGLContextObj]);
    
    [renderer render];
    
    CGLFlushDrawable([self.openGLContext CGLContextObj]);
    CGLUnlockContext([self.openGLContext CGLContextObj]);
}

#pragma mark -
#pragma mark Image Export

- (NSBitmapImageRep *)bitmapImageRepFromViewWithClearBackground:(BOOL)clearBackground {
    
    int bytesPerRow;
    unsigned char *bitmapData;
    
    int width = (int)self.bounds.size.width * self.window.backingScaleFactor;
    int height = (int)self.bounds.size.height * self.window.backingScaleFactor;
    
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

#pragma mark -

- (void)startAnimation {
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

- (void)windowWillClose:(NSNotification *)notification {
    [self stopAnimation];
}

- (void)emptyDomain {
    GLfloat orig[] = {-1000.0f, 5000.0f, 0.0f};
    GLfloat size[] = {2000.0f, 2000.0f, 2000.0f};
    
    [renderer setGridAtOrigin:orig size:size];
    [renderer setCenterPoisitionX:orig[0] + 0.5f * size[0]
                                       y:orig[1] + 0.5f * size[1]
                                       z:orig[2] + 0.5f * size[2]];
}

@end
