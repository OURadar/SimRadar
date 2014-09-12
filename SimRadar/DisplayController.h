//
//  DisplayController.h
//  _radarsim
//
//  Created by Boon Leng Cheong on 10/29/13.
//  Copyright (c) 2013 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimPoint.h"
#import "SimGLView.h"

@interface DisplayController : NSWindowController <NSWindowDelegate> {
	
	SimPoint *sim;
	SimGLView *glView;

@private

	id rootSender;
	NSTimer *inputMonitorTimer;
	
}

@property (nonatomic, retain) SimPoint *sim;
@property (nonatomic, retain) IBOutlet SimGLView *glView;

- (id)initWithWindowNibName:(NSString *)windowNibName viewDelegate:(id)sender;
- (IBAction)spinModel:(id)sender;
- (IBAction)normalSizeWindow:(id)sender;
- (IBAction)doubleSizeWindow:(id)sender;
- (IBAction)setSizeTo720p:(id)sender;
- (IBAction)fullscreenMode:(id)sender;

@end
