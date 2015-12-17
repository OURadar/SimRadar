//
//  SplashController.h
//
//  Created by Boon Leng Cheong on 12/16/15.
//  Copyright © 2015 Boon Leng Cheong. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SplashController : NSWindowController {

    NSImageCell *imageCell;

}

@property (nonatomic, retain) IBOutlet NSImageCell *imageCell;

@end
