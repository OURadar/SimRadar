//
//  SplashController.m
//
//  Created by Boon Leng Cheong on 12/16/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "SplashController.h"

@implementation SplashController

@synthesize imageCell;
@synthesize label, version, copyright;
@synthesize progress;
@synthesize delegate;

- (void)awakeFromNib {
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *file = [bundle pathForResource:@"images/simradar.jpg" ofType:nil];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    [imageCell setImage:image];
    
    [version setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                             [bundle.infoDictionary objectForKey:@"CFBundleShortVersionString"],
                             [bundle.infoDictionary objectForKey:@"CFBundleVersion"]]];
    
    [copyright setStringValue:[bundle.infoDictionary objectForKey:@"NSHumanReadableCopyright"]];
}

- (void)dealloc {
    [imageCell release];
    
    [super dealloc];
}

- (void)windowDidLoad {
    [self.window setLevel:kCGScreenSaverWindowLevel];
    [progress setMinValue:0.0];
    [progress setMaxValue:100.0];
    [progress setDoubleValue:10.0];
    [progress setUsesThreadedAnimation:true];
    //[progress setControlTint:NSBlueControlTint];
    if (delegate) {
        [delegate splashWindowDidLoad:self];
    }
}

- (void)windowWillLoad {
}

@end
