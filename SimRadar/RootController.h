//
//  RootController.h
//  SimRadar
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DisplayController.h"
#import "SimPoint.h"

@interface RootController : NSController {
	
	char state;
	
	SimPoint *sim;

	DisplayController *dc;
	
	@private
	
	NSString *iconFolder;
	NSArray *icons;
}

- (IBAction)newLiveDisplay:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)resetSimulator:(id)sender;

@end
