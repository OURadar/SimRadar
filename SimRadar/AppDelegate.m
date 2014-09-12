//
//  AppDelegate.m
//  RadarSimView
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate()
- (void)rotateIcon;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	//[NSThread detachNewThreadSelector:@selector(rotateIcon) toTarget:self withObject:nil];
}


- (void)rotateIcon
{
	@autoreleasepool {
		NSString *minionFolder = [[NSBundle mainBundle] pathForResource:@"Minion-Icons" ofType:nil];
		
		while (TRUE) {
			NSArray *icons = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:minionFolder error:nil];
			if (icons.count > 0) {
				NSInteger i = rand() * icons.count / RAND_MAX;
				NSString *iconName = [minionFolder stringByAppendingPathComponent:[icons objectAtIndex:i]];
				NSImage *img = [[NSImage alloc] initWithContentsOfFile:iconName];
				// NSLog(@"icon %@ %@", iconName, img);
				[[NSApplication sharedApplication] setApplicationIconImage:img];
				[img release];
			}
			sleep(2);
		}
	}
}
@end
