//
//  RootController.h
//  SimRadar
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DisplayController.h"
#import "SplashController.h"
#import "SimPoint.h"

@interface RootController : NSController <SplashControllerDelegate, SimPointDelegate> {
	
	char state;
	
	DisplayController *dc;
    SplashController *sc;
	
    SimPoint *sim;
    
    IBOutlet NSMenuItem *startRecordMenuItem;
    IBOutlet NSMenuItem *stopRecordMenuItem;

@private
	
	NSString *iconFolder;
	NSArray *icons;

    double initProgress;
}

@property (nonatomic, retain) NSMenuItem *startRecordMenuItem, *stopRecordMenuItem;

- (IBAction)newLiveDisplay:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)resetSimulator:(id)sender;
- (IBAction)startRecord:(id)sender;
- (IBAction)stopRecord:(id)sender;

- (void)alertMissingResources;

@end
