//
//  DKGAppDelegate.m
//  BTCPrice
//
//  Created by Dylan Garrett on 1/19/13.
//  Copyright (c) 2013 Dylan Garrett. All rights reserved.
//

#import "DKGAppDelegate.h"

#define kDonationAddress            @"1Price4EGW8R59auccATvEwCFAhXYBML6V"
#define kDefaultsDisplay            @"display"
#define kDefaultsCurrency           @"currency"
#define kDefaultsUpdateTime         @"updateTime"
#define kDefaultsDisplayDecimals    @"displayDecimals"
#define kDefaultsDisplayLabel       @"displayLabel"

// Each subarray is of the format { JSON key, Print name, value }
#define kKeyNamesCount (8)
NSString* kKeyNames[kKeyNamesCount][2] = {
    { @"high",  @"High" },
    { @"low",   @"Low"  },
    { @"avg",   @"Avg"  },
    { @"vwap",  @"VWAP" },
    { @"vol",   @"Vol"  },
    { @"last",  @"Last" },
    { @"buy",   @"Buy"  },
    { @"sell",  @"Sell" }
};

typedef NS_ENUM(NSInteger, DKGLabelType) {
    kDataType = 0,
    kBitcoinSymbol,
    kNoLabel
};


@interface DKGAppDelegate ()
@end

@implementation DKGAppDelegate {
    IBOutlet NSMenu* _statusMenu;
    NSStatusItem* _statusItem;
    NSTimer* _updateTimer;
    double _updateInterval;
    
    NSInteger _displayItem;
    NSInteger _displayDecimals;
    DKGLabelType _displayLabelType;
    
    IBOutlet NSMenu* _updateSubmenu;
    IBOutlet NSMenu* _decimalsSubmenu;
    IBOutlet NSMenu* _labelSubmenu;
    IBOutlet NSMenu* _currencySubmenu;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

-(void)awakeFromNib{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setTitle:@"..."];
    [_statusItem setHighlightMode:YES];
    
    _statusMenu.delegate = self;
    
    for (int i = 0; i < 8; i++) {
        [_statusMenu itemAtIndex:i].action = @selector(changeDisplay:);
    }

    for (int i = 0; i < _currencySubmenu.itemArray.count; i++) {
        [_currencySubmenu itemAtIndex:i].action = @selector(changeCurrency:);
    }
    
    for (int i = 0; i < _updateSubmenu.itemArray.count; i++) {
        [_updateSubmenu itemAtIndex:i].action = @selector(changeUpdateTime:);
    }
    
    for (int i = 0; i < _decimalsSubmenu.itemArray.count; i++) {
        [_decimalsSubmenu itemAtIndex:i].action = @selector(changeDisplayDecimals:);
    }
    
    for (int i = 0; i < _labelSubmenu.itemArray.count; i++) {
        [_labelSubmenu itemAtIndex:i].action = @selector(changeDisplayLabel:);
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplay]) {
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:kDefaultsDisplay];
    }

    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsCurrency]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsCurrency];
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
    
    [self changeCurrency:[_currencySubmenu itemAtIndex:MAX(0, MIN([[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrency], _currencySubmenu.itemArray.count - 1))]];
    
    [self changeDisplay:[_statusMenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplay]]];
    
    [self changeUpdateTime:[_updateSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsUpdateTime]]];
    
    [self changeDisplayDecimals:[_decimalsSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayDecimals]]];
    
    [self changeDisplayLabel:[_labelSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayLabel]]];
    
    [self update];
}

-(void)update
{
    NSLog(@"Updating...");
    NSString* currency = @"USD";
    NSInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrency];
    i = MAX(0, MIN(i, _currencySubmenu.itemArray.count - 1));
    currency = [[_currencySubmenu itemAtIndex:i] title];
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://mtgox.com/api/1/BTC%@/ticker", currency]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:URL];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateWithData:data];
        });
    });
}

- (void) updateWithData:(NSData *)data
{
    NSError* error = nil;
    
    if (data == nil) return;
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
    
    //NSLog(@"DEBUG: json = %@", json);
    
    if (![json[@"result"] isEqual:@"success"]) return;
    
    id ticker = json[@"return"];
    
    for (int i = 0; i < kKeyNamesCount; i++)
    {
        NSString* label = nil;
        NSString* key = kKeyNames[i][0];
        NSString* keyName = kKeyNames[i][1];
        
        switch (_displayLabelType)
        {
            case kBitcoinSymbol:
                label = @"฿ ";
                break;
            case kNoLabel:
                label = @"";
                break;
            default:
                label = [NSString stringWithFormat:@"%@: ", keyName];
                break;
        }
        
        NSString* valueString = ticker[key][@"value"];
        
        // Decimals
        NSRange decimalLocation = [valueString rangeOfString:@"."];
        if (decimalLocation.location != NSNotFound && _displayDecimals < valueString.length - decimalLocation.location) {
            valueString = [valueString substringToIndex:(decimalLocation.location + (_displayDecimals > 0 ? _displayDecimals + 1 : 0))];
        }
        
        [[_statusMenu itemAtIndex:i] setTitle:[NSString stringWithFormat:@"%@:  \t%@", keyName, valueString]];
        
        if (_displayItem == i) {
            [_statusItem setTitle:[NSString stringWithFormat:@"%@%@", label, valueString]];
        }
    }
}

- (void)changeDisplay:(id)sender
{
    int item = (int)[[_statusMenu itemArray] indexOfObject:sender];
    NSLog(@"Display mode: %lu", (unsigned long)[[_statusMenu itemArray] indexOfObject:sender]);
    
    for (int i = 0; i < _statusMenu.itemArray.count; i++) {
        [_statusMenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    _displayItem = item;
    [[NSUserDefaults standardUserDefaults] setInteger:[_statusMenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplay];
    [self update];
}

- (void) changeCurrency:(NSMenuItem*)sender
{
    NSLog(@"Currency: %@", [sender title]);
    for (int i = 0; i < _currencySubmenu.itemArray.count; i++) {
        [_currencySubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[_currencySubmenu.itemArray indexOfObject:sender] forKey:kDefaultsCurrency];
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
    NSLog(@"Update time: %@", [sender title]);
    for (int i = 0; i < _updateSubmenu.itemArray.count; i++) {
        [_updateSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[_updateSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsUpdateTime];
    
    if ([@"10s" isEqual:[sender title]]) {
        _updateInterval = 10.0;
    }
    if ([@"30s" isEqual:[sender title]]) {
        _updateInterval = 30.0;
    }
    if ([@"1min" isEqual:[sender title]]) {
        _updateInterval = 60.0;
    }
    if ([@"10min" isEqual:[sender title]]) {
        _updateInterval = 10*60.0;
    }
    if ([@"30min" isEqual:[sender title]]) {
        _updateInterval = 30*60.0;
    }
    if ([@"1hr" isEqual:[sender title]]) {
        _updateInterval = 60*60.0;
    }
    
    if (_updateInterval < 10.0) _updateInterval = 10.0;
    
    NSLog(@"interval: %lf", _updateInterval);
    [self restartTimer];
}

- (void) restartTimer
{
    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:_updateInterval
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
                         informativeTextWithFormat:kDonationAddress];
    
    long button = [alert runModal];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    switch (button) {
        case NSAlertDefaultReturn:
            NSLog(@"copy");
            [pasteboard clearContents];
            [pasteboard writeObjects:[NSArray arrayWithObject:kDonationAddress]];
            break;
        case NSAlertAlternateReturn:
            NSLog(@"Don't copy");
            break;
            
        default:
            break;
    }
}

- (void)changeDisplayDecimals:(id)sender {
    for (int i = 0; i < _decimalsSubmenu.itemArray.count; i++) {
        [_decimalsSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[_decimalsSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplayDecimals];
    
    _displayDecimals = [_decimalsSubmenu.itemArray indexOfObject:sender];
    
    [self update];
}

- (void)changeDisplayLabel:(id)sender {
    for (int i = 0; i < _labelSubmenu.itemArray.count; i++) {
        [_labelSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[_labelSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplayLabel];
    
    _displayLabelType = [_labelSubmenu.itemArray indexOfObject:sender];
    
    [self update];
}

@end
