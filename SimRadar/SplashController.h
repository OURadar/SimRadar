//
//  SplashController.h
//
//  Created by Boon Leng Cheong on 12/16/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SplashControllerDelegate <NSObject>

- (void)splashWindowDidLoad:(id)sender;

@end

@interface SplashController : NSWindowController {

    NSImageCell *imageCell;
    
    NSTextField *label;
    
    NSProgressIndicator *progress;
    
    id<SplashControllerDelegate> delegate;

}

@property (nonatomic, retain) IBOutlet NSImageCell *imageCell;
@property (nonatomic, retain) IBOutlet NSTextField *label;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progress;
@property (nonatomic, retain) id<SplashControllerDelegate> delegate;

@end
