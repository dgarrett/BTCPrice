//
//  DKGAppDelegate.h
//  BTCPrice
//
//  Created by Dylan Garrett on 1/19/13.
//  Copyright (c) 2013 Dylan Garrett. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DKGAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (assign) IBOutlet NSWindow *window;

- (void)update;
- (void)fetchedData:(NSData *)responseData;
- (void)changeDisplay:(id)sender;
- (IBAction)bootup:(id)sender;
- (IBAction)quit:(id)sender;
- (void)changeUpdateTime:(id)sender;
- (IBAction)donations:(id)sender;
- (void)changeDisplayDecimals:(id)sender;
- (void)changeDisplayLabel:(id)sender;

@end
