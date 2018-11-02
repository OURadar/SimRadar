//
//  Recorder.m
//
//  Created by Boon Leng Cheong on 11/2/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "Recorder.h"

@implementation Recorder

@synthesize videoSize;
@synthesize fps, bitrate;
@synthesize outputFilename;
@synthesize overlayLogo;
@synthesize overlayRect;

- (id)initForView:(NSView *)view {
    self = [super init];
    if (self) {
        fps = 60;
        videoSize = [view bounds].size;
        bitrate = videoSize.width * videoSize.height * fps;
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyymmhh-HHMMSS"];
        NSString *storePath = [@"~/Desktop" stringByExpandingTildeInPath];
        NSString *timeString = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
        outputFilename = [storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"simradar-%@.mp4", timeString]];
        NSLog(@"output Filename: %@  view @ %@ %.1f x %.1f", outputFilename, view, videoSize.width, videoSize.height);

        NSError *error;

        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInteger:videoSize.width], AVVideoWidthKey,
                                       [NSNumber numberWithInteger:videoSize.height], AVVideoHeightKey,
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInteger:bitrate], AVVideoAverageBitRateKey,
                                        nil], AVVideoCompressionPropertiesKey,
                                       nil];

        AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput
                                                assetWriterInputWithMediaType:AVMediaTypeVideo
                                                outputSettings:videoSettings];

        videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL URLWithString:outputFilename]
                                                fileType:AVFileTypeMPEG4
                                                   error:&error];

        adaptor = [AVAssetWriterInputPixelBufferAdaptor
                   assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                   sourcePixelBufferAttributes:nil];

        [videoWriterInput setExpectsMediaDataInRealTime:YES];
        if ([videoWriter canAddInput:videoWriterInput]) {
            NSLog(@"Info: Video writer can be added.\n");
        } else {
            NSLog(@"Error: Video writer cannot be added.\n");
        }
        [videoWriter addInput:videoWriterInput];

        BOOL started = [videoWriter startWriting];
        if (started) {
            NSLog(@"Info: Session started.\n");
        } else {
            NSLog(@"Error: Session NOT started.\n");
        }
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
    }
    return self;
}

- (id)init {
    NSArray *windows = [NSApplication.sharedApplication windows];
    return [self initForView:[windows.firstObject contentView]];
}

- (void)dealloc {
    NSLog(@"stop recording and release object");
    [self stopRecording];
    [outputFilename release];
    [overlayLogo release];
    [super dealloc];
}

- (void)addFrame:(NSView *)view {
    // Setup movie file, etc.
    NSLog(@"add frame");
   // [adaptor appendPixelBuffer:<#(nonnull CVPixelBufferRef)#> withPresentationTime:<#(CMTime)#>]
}

- (void)stopRecording {
    // Close movie file, etc.
}

@end
