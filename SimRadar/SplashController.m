//
//  SplashController.m
//
//  Created by Boon Leng Cheong on 12/16/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "SplashController.h"

@implementation SplashController

@synthesize imageCell;
@synthesize label;
@synthesize progress;
@synthesize delegate;

- (void)awakeFromNib {
    NSString *file = [[NSBundle mainBundle] pathForResource:@"images/tornado.jpg" ofType:nil];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    [imageCell setImage:image];
}

- (void)windowDidLoad {
    [self.window setLevel:kCGScreenSaverWindowLevel];
    [progress setMinValue:0.0];
    [progress setMaxValue:100.0];
    [progress setDoubleValue:10.0];
    [progress setUsesThreadedAnimation:TRUE];
    //[progress setControlTint:NSBlueControlTint];
    if (delegate) {
        [delegate splashWindowDidLoad:self];
    }
}

- (void)windowWillLoad {
}

@end
