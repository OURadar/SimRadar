//
//  Recorder.h
//
//  Created by Boon Leng Cheong on 11/2/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@interface Recorder : NSObject {
    
    NSSize videoSize;
    NSUInteger fps, bitrate;
    NSString *outputFilename;
    NSImage *overlayLogo;
    NSRect overlayRect;

    @private
    
    AVAssetWriter *videoWriter;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    
}

@property (nonatomic) NSSize videoSize;
@property (nonatomic) NSUInteger fps, bitrate;
@property (nonatomic, retain) NSString *outputFilename;
@property (nonatomic, retain) NSImage *overlayLogo;
@property (nonatomic) NSRect overlayRect;

- (id)initForView:(NSView *)view;

- (void)addFrame:(NSView *)view;
- (void)stopRecording;

@end
