//
//  SplashController.m
//
//  Created by Boon Leng Cheong on 12/16/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import "SplashController.h"

@implementation SplashController

@synthesize imageCell;

- (void)awakeFromNib {
    NSString *file = [[NSBundle mainBundle] pathForResource:@"images/tornado.jpg" ofType:nil];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    [imageCell setImage:image];
}

@end
