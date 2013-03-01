//
//  DKGAppDelegate.m
//  BTCPrice
//
//  Created by Dylan Garrett on 1/19/13.
//  Copyright (c) 2013 Dylan Garrett. All rights reserved.
//

#import "DKGAppDelegate.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define kGoxURL [NSURL URLWithString:@"https://mtgox.com/code/data/ticker.php"]
#define kDonationAddr @"1Price4EGW8R59auccATvEwCFAhXYBML6V"
#define kDefaultsDisplay            @"display"
#define kDefaultsUpdateTime         @"updateTime"
#define kDefaultsDisplayDecimals    @"displayDecimals"
#define kDefaultsDisplayLabel       @"displayLabel"

enum labelTypes {
    kDataType = 0,
    kBitcoinSymbol,
    kNoLabel
};


@implementation DKGAppDelegate {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    NSTimer* updateTimer;
    double updateInterval;
    
    int displayItem;
    int displayDecimals;
    enum labelTypes displayLabel;
    
    IBOutlet NSMenu* updateSubmenu;
    IBOutlet NSMenu* decimalsSubmenu;
    IBOutlet NSMenu* labelSubmenu;
}


// Each subarray is of the format { JSON key, Print name, value }
NSString* data[8][3] = {
    { @"high",  @"High",    @"" },
    { @"low",   @"Low",     @"" },
    { @"avg",   @"Avg",     @"" },
    { @"vwap",  @"VWAP",    @"" },
    { @"vol",   @"Vol",     @"" },
    { @"last",  @"Last",    @"" },
    { @"buy",   @"Buy",     @"" },
    { @"sell",  @"Sell",    @"" }
};

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

-(void)awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"Loading..."];
    [statusItem setHighlightMode:YES];
    
    statusMenu.delegate = self;
    
    for (int i = 0; i < 8; i++) {
        [statusMenu itemAtIndex:i].action = @selector(changeDisplay:);
    }
    
    for (int i = 0; i < updateSubmenu.itemArray.count; i++) {
        [updateSubmenu itemAtIndex:i].action = @selector(changeUpdateTime:);
    }
    
    for (int i = 0; i < decimalsSubmenu.itemArray.count; i++) {
        [decimalsSubmenu itemAtIndex:i].action = @selector(changeDisplayDecimals:);
    }
    
    for (int i = 0; i < labelSubmenu.itemArray.count; i++) {
        [labelSubmenu itemAtIndex:i].action = @selector(changeDisplayLabel:);
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplay]) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:kDefaultsDisplay];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsUpdateTime]) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kDefaultsUpdateTime];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplayDecimals]) {
        [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:kDefaultsDisplayDecimals];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplayLabel]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsDisplayLabel];
    }
    
    [self changeDisplay:[statusMenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplay]]];
    
    [self changeUpdateTime:[updateSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsUpdateTime]]];
    
    [self changeDisplayDecimals:[decimalsSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayDecimals]]];
    
    [self changeDisplayLabel:[labelSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayLabel]]];
    
}

-(void)update {
    NSLog(@"Updating...");
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:
                        kGoxURL];
        [self performSelectorOnMainThread:@selector(fetchedData:)
                               withObject:data waitUntilDone:YES];
    });
}

- (void)fetchedData:(NSData *)responseData {
    NSError* error;
    if (responseData == nil) return;
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          options:kNilOptions
                          error:&error];
    id ticker = [json objectForKey:@"ticker"];
    
    for (int i = 0; i < 8; i++) {
        NSString* label;
        switch (displayLabel) {
            case kDataType:
                label = [NSString stringWithFormat:@"%@: ", data[i][1]];
                break;
            case kBitcoinSymbol:
                label = @"฿ ";
                break;
            case kNoLabel:
                label = @"";
                break;
            default:
                label = [NSString stringWithFormat:@"%@: ", data[i][1]];
                break;
        }
        data[i][2] = [NSString stringWithFormat:@"%@", [ticker objectForKey:data[i][0]]];
        NSString* menuString = data[i][2];
        
        // Decimals
        NSRange decimalLocation = [data[i][2] rangeOfString:@"."];
        if (decimalLocation.location != NSNotFound && displayDecimals < data[i][2].length - decimalLocation.location) {
            menuString = [menuString substringToIndex:(decimalLocation.location + (displayDecimals > 0 ? displayDecimals + 1 : 0))];
        }
        
        [[statusMenu itemAtIndex:i] setTitle:[NSString stringWithFormat:@"%@:  \t%@", data[i][1], data[i][2]]];
        
        if (displayItem == i) {
            [statusItem setTitle:[NSString stringWithFormat:@"%@%@", label, menuString]];
        }
    }
    
    
}

- (void)changeDisplay:(id)sender {
    int item = (int)[[statusMenu itemArray] indexOfObject:sender];
    NSLog(@"index: %lu", (unsigned long)[[statusMenu itemArray] indexOfObject:sender]);
    
    for (int i = 0; i < statusMenu.itemArray.count; i++) {
        [statusMenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    displayItem = item;
    [[NSUserDefaults standardUserDefaults] setInteger:[statusMenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplay];
    [self update];
}

- (IBAction)bootup:(id)sender {
    [sender setState:NSOnState];
}

- (IBAction)quit:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)changeUpdateTime:(id)sender {
    NSLog(@"%@", [sender title]);
    for (int i = 0; i < updateSubmenu.itemArray.count; i++) {
        [updateSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[updateSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsUpdateTime];
    
    if ([@"10s" isEqual:[sender title]]) {
        updateInterval = 10.0;
    }
    if ([@"30s" isEqual:[sender title]]) {
        updateInterval = 30.0;
    }
    if ([@"1min" isEqual:[sender title]]) {
        updateInterval = 60.0;
    }
    if ([@"10min" isEqual:[sender title]]) {
        updateInterval = 10*60.0;
    }
    if ([@"30min" isEqual:[sender title]]) {
        updateInterval = 30*60.0;
    }
    if ([@"1hr" isEqual:[sender title]]) {
        updateInterval = 60*60.0;
    }
    NSLog(@"interval: %lf", updateInterval);
    [updateTimer invalidate];
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                   target:self
                                                 selector:@selector(update)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self update];
}

- (IBAction)donations:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"I'd greatly appreciate any donations."
                                     defaultButton:@"Copy Address"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:kDonationAddr];
    
    long button = [alert runModal];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    switch (button) {
        case NSAlertDefaultReturn:
            NSLog(@"copy");
            [pasteboard clearContents];
            [pasteboard writeObjects:[NSArray arrayWithObject:kDonationAddr]];
            break;
        case NSAlertAlternateReturn:
            NSLog(@"Don't copy");
            break;
            
        default:
            break;
    }
}

- (void)changeDisplayDecimals:(id)sender {
    for (int i = 0; i < decimalsSubmenu.itemArray.count; i++) {
        [decimalsSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[decimalsSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplayDecimals];
    
    displayDecimals = [decimalsSubmenu.itemArray indexOfObject:sender];
    
    [self update];
}

- (void)changeDisplayLabel:(id)sender {
    for (int i = 0; i < labelSubmenu.itemArray.count; i++) {
        [labelSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[labelSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplayLabel];
    
    displayLabel = [labelSubmenu.itemArray indexOfObject:sender];
    
    [self update];
}

@end
