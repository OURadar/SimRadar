//
//  Recorder.h
//
//  Created by Boon Leng Cheong on 11/2/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Recorder : NSObject {
    
    NSSize videoSize;
    NSUInteger fps, bitrate;
    NSString *outputFilename;
    NSImage *overlayLogo;
    NSRect overlayRect;

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
