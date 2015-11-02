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
    [super dealloc];
}

- (void)addFrame:(NSView *)view {
    // Setup movie file, etc.
    NSLog(@"add frame");
}

- (void)stopRecording {
    // Close movie file, etc.
}

@end
