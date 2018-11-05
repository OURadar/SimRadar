//
//  main.m
//  RadarSimView
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
//	@autoreleasepool {
//		NSLog(@"%@", [[NSBundle mainBundle] infoDictionary]);
//	}
	if (argc == 2 && !strncmp("-v", argv[1], 2)) {
		@autoreleasepool {
			const char *version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] UTF8String];
			const char *build = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String];
			printf("%s (B%s)\n", version, build);
		}
		return 0;
	}
	return NSApplicationMain(argc, argv);
}
