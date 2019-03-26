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
#define kDefaultsExchange           @"exchange"
#define kDefaultsUpdateTime         @"updateTime"
#define kDefaultsDisplayDecimals    @"displayDecimals"
#define kDefaultsTrailingZeros      @"trailingZeros"
#define kDefaultsDisplayLabel       @"displayLabel"
#define kDefaultsFontSize           @"fontSize"

/* To add support for an exchange, update:
 - the Exchange enum
 - the EXCHANGECOUNT constant
 - the kKeyNames array
 - the currencies array
 - getURLByCurrency method
 - parseData method
 - the .xib menu
*/

const typedef enum {
    MTGox,
    BitStamp,
    BTCentral,
    Bitcoin24,
    BTCe,
    BTCeLTC
} Exchange;

#define EXCHANGECOUNT               6
#define KEYCOUNT                    8

// Each subarray is of the format { JSON key, Print name }
// use a NULL key to gracefully indicate a value is missing
NSString* kKeyNames[EXCHANGECOUNT][KEYCOUNT][2] = {
    { //MTGOX
        { @"high",  @"High" },
        { @"low",   @"Low"  },
        { @"avg",   @"Avg"  },
        { @"vwap",  @"VWAP" },
        { @"vol",   @"Vol"  },
        { @"last",  @"Last" },
        { @"buy",   @"Buy"  },
        { @"sell",  @"Sell" }
    },
    { //Bitstamp
        { @"high",      @"High" },
        { @"low",       @"Low"  },
        { @"NULL",      @"Avg"  },
        { @"NULL",      @"VWAP" },
        { @"volume",    @"Vol"  },
        { @"last",      @"Last" },
        { @"bid",       @"Bid"  },
        { @"ask",       @"Ask"  }
    },
    { //BTCentral
        { @"high",      @"High" },
        { @"low",       @"Low"  },
        { @"midpoint",  @"Mid"  },
        { @"variation", @"Var"  },
        { @"volume",    @"Vol"  },
        { @"price",     @"Price" },
        { @"bid",       @"Bid"  },
        { @"ask",       @"Ask"  }
    },
    { //Bitcoin24
        { @"high",      @"High" },
        { @"low",       @"Low"  },
        { @"avg",       @"Avg"  },
        { @"NULL",      @"Var"  },
        { @"trades_today", @"# Today" },
        { @"last",      @"Last" },
        { @"bid",       @"Bid"  },
        { @"ask",       @"Ask"  }
    },
    { //BTC-e
        { @"high",      @"High" },
        { @"low",       @"Low"  },
        { @"avg",       @"Avg"  },
        { @"NULL",      @"Var"  },
        { @"vol_cur",   @"Vol"  },
        { @"last",      @"Last" },
        { @"buy",       @"Buy"  },
        { @"sell",      @"Sell" }
    },
    { //BTCeLTC
        { @"high",      @"High" },
        { @"low",       @"Low"  },
        { @"avg",       @"Avg"  },
        { @"NULL",      @"Var"  },
        { @"vol_cur",   @"Vol"  },
        { @"last",      @"Last" },
        { @"buy",       @"Buy"  },
        { @"sell",      @"Sell" }
    }
    
};

const typedef enum {
    USD, EUR, JPY, CAD, GBP, CHF, RUB, AUD
} Currency;

#define CURRENCIES                    8

BOOL* kCurrencies[EXCHANGECOUNT][CURRENCIES] = {
    { //MTGOX
        true, //USD
        true, //EUR
        true, //JPY
        true, //CAD
        true, //GBP
        true, //CHF
        true, //RUB
        true  //AUD
    },
    { //BitStamp
        true, //USD
        false, //EUR
        false, //JPY
        false, //CAD
        false, //GBP
        false, //CHF
        false, //RUB
        false  //AUD
    },
    { //BTCentral
        false, //USD
        true, //EUR
        false, //JPY
        false, //CAD
        false, //GBP
        false, //CHF
        false, //RUB
        false  //AUD
    },
    { //Bitcoin24
        true, //USD
        true, //EUR
        false, //JPY
        false, //CAD
        false, //GBP
        false, //CHF
        false, //RUB
        false  //AUD
    },
    { //BTC-e
        true, //USD
        true, //EUR
        false, //JPY
        false, //CAD
        false, //GBP
        false, //CHF
        false, //RUB
        false  //AUD
    },
    { //BTCeLTC
        true, //USD
        true, //EUR
        false, //JPY
        false, //CAD
        false, //GBP
        false, //CHF
        false, //RUB
        false  //AUD
    }
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
    BOOL _trailingZeros;
    NSInteger _displayExchange;
    DKGLabelType _displayLabelType;
    double _displayFontSize;
    
    IBOutlet NSMenu* _updateSubmenu;
    IBOutlet NSMenu* _decimalsSubmenu;
    IBOutlet NSMenu* _exchangeSubmenu;
    IBOutlet NSMenu* _labelSubmenu;
    IBOutlet NSMenu* _currencySubmenu;
    IBOutlet NSMenu* _fontSizeSubmenu;
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
    [_currencySubmenu setAutoenablesItems:NO]; //required to be able to enable/disable currencies
    _statusMenu.delegate = self;
    
    for (int i = 0; i < 8; i++) {
        [_statusMenu itemAtIndex:i].action = @selector(changeDisplay:);
    }

    for (int i = 0; i < _exchangeSubmenu.itemArray.count; i++) {
        [_exchangeSubmenu itemAtIndex:i].action = @selector(changeExchange:);
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
    
    for (int i = 0; i < _fontSizeSubmenu.itemArray.count; i++) {
        [_fontSizeSubmenu itemAtIndex:i].action = @selector(changeFontSize:);
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplay]) {
        [[NSUserDefaults standardUserDefaults] setInteger:5 forKey:kDefaultsDisplay];
    }

    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsCurrency]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsCurrency];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsExchange]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsExchange];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsUpdateTime]) {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kDefaultsUpdateTime];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplayDecimals]) {
        [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:kDefaultsDisplayDecimals];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsTrailingZeros]) {
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:kDefaultsTrailingZeros];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsDisplayLabel]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kDefaultsDisplayLabel];
    }
    
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsFontSize]
        || nil == [_fontSizeSubmenu itemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:kDefaultsFontSize]]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"13pt (Default)" forKey:kDefaultsFontSize];
    }
    
    [self changeCurrency:[_currencySubmenu itemAtIndex:MAX(0, MIN([[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrency], _currencySubmenu.itemArray.count - 1))]];
    
    NSLog(@"Initing at exchange: %ld", [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsExchange]);
    
    [self changeExchange:[_exchangeSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsExchange]]];
    
    [self changeDisplay:[_statusMenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplay]]];
    
    [self changeUpdateTime:[_updateSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsUpdateTime]]];
    
    [self changeDisplayDecimals:[_decimalsSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayDecimals]]];
    
    //UI defaults to disabled, so if kDefaultsTrailingZeros is set, we need to toggle once to the onState
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsTrailingZeros]) {
        [self changeDisplayDecimals:[_decimalsSubmenu itemAtIndex:_decimalsSubmenu.itemArray.count-1]];
    }
    
    [self changeDisplayLabel:[_labelSubmenu itemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsDisplayLabel]]];
    
    [self changeFontSize:[_fontSizeSubmenu itemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:kDefaultsFontSize]]];
    
    [self update];
}

-(void)update
{
    NSLog(@"Updating...");
    NSString* currency = @"USD";
    NSInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrency];
    i = MAX(0, MIN(i, _currencySubmenu.itemArray.count - 1));
    currency = [[[_currencySubmenu itemAtIndex:i] title] uppercaseString];
	NSURL* URL = [NSURL URLWithString:[self getURLByCurrency:currency]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:URL];
        dispatch_async(dispatch_get_main_queue(), ^{
				[self updateData:data];
        });
    });
}

- (NSString*) getURLByCurrency:(NSString *)currency
{
    switch (_displayExchange) {
        case BTCentral :
            return [NSString stringWithFormat:@"https://bitcoin-central.net/api/v1/ticker/%@", currency];
        case BitStamp:
            return [NSString stringWithFormat:@"https://www.bitstamp.net/api/ticker/"];
        case Bitcoin24:
            return [NSString stringWithFormat:@"https://bitcoin-24.com/api/%@/ticker.json", currency];
        case BTCe:
            return [NSString stringWithFormat:@"https://btc-e.com/api/2/btc_%@/ticker",[currency lowercaseString]];
        case BTCeLTC:
            return [NSString stringWithFormat:@"https://btc-e.com/api/2/ltc_%@/ticker",[currency lowercaseString]];
        //Room for more exchanges here
        case MTGox :
        default :
            return [NSString stringWithFormat:@"https://mtgox.com/api/1/BTC%@/ticker", currency];
    }
}

- (NSString *) parseData:(NSDictionary*)json byKey:(NSString*)key
{
    switch (_displayExchange) {
        case BTCentral :
            return [json[key] stringValue];
        case BitStamp:
        case Bitcoin24:
            return json[key];
        case BTCe:
        case BTCeLTC:
            return [json[@"ticker"][key] stringValue];
        //Room for more exchanges here
        case MTGox :
        default:
            return json[@"return"][key][@"value"];
    }
}

- (void) updateData:(NSData *)data
{
    NSError* error = nil;
    
    if (data == nil) return;
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
    
    for (int i = 0; i < KEYCOUNT; i++)
    {
        NSString* label = nil;
        NSString* valueString = nil;
        NSString* key = kKeyNames[_displayExchange][i][0];
        NSString* keyName = kKeyNames[_displayExchange][i][1];
        
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
        
        if ([key isEqualToString:@"NULL"]) {
            valueString = @"-";
        }
        else {
            valueString = [self parseData:json byKey: key];
            
            // Decimals
            double valueDouble = [valueString doubleValue];
            valueString = [NSString stringWithFormat:[NSString stringWithFormat:@"%%.%ldf", _displayDecimals], valueDouble];
            if (!_trailingZeros) {
                int index = (int)[valueString length] - 1;
                while ([valueString characterAtIndex:index] == '0' && index > 0) {
                    index--;
                }
                if ([valueString characterAtIndex:index] == '.')
                    index--;
                valueString = [valueString substringToIndex: index +1];
            }
        }
        
        [[_statusMenu itemAtIndex:i] setTitle:[NSString stringWithFormat:@"%@:  \t%@", keyName, valueString]];
        
        if (_displayItem == i) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSFont systemFontOfSize: _displayFontSize], NSFontAttributeName, nil];
            NSMutableAttributedString* s = [[NSMutableAttributedString alloc]
                                            initWithString:[NSString stringWithFormat:@"%@%@", label, valueString]
                                            attributes:attributes];
            [_statusItem setAttributedTitle:s];
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
    if (kCurrencies[_displayExchange][[_currencySubmenu.itemArray indexOfObject:sender]]) {
        NSLog(@"Currency: %@", [sender title]);
        for (int i = 0; i < _currencySubmenu.itemArray.count; i++) {
            [_currencySubmenu itemAtIndex:i].state = NSOffState;
        }
        [sender setState:NSOnState];
        
        [[NSUserDefaults standardUserDefaults] setInteger:[_currencySubmenu.itemArray indexOfObject:sender] forKey:kDefaultsCurrency];
        [self update];
    }
    else {
        NSLog(@"Invalid currency for this exchange! %@ %@", [[_exchangeSubmenu.itemArray objectAtIndex:_displayExchange] title], [sender title]);
    }
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
    if ([_decimalsSubmenu.itemArray indexOfObject:sender] == _decimalsSubmenu.itemArray.count - 1) {
        [sender setState: ([sender state] == NSOnState ? NSOffState : NSOnState)];
        [[NSUserDefaults standardUserDefaults] setBool:[sender state] == NSOnState forKey:kDefaultsTrailingZeros];
        _trailingZeros = [sender state] == NSOnState;
    }
    else {
        for (int i = 0; i < _decimalsSubmenu.itemArray.count - 1; i++) {//-1 to prevent affecting 'trailing zeros'
            [_decimalsSubmenu itemAtIndex:i].state = NSOffState;
        }
        [sender setState:NSOnState];
        
        [[NSUserDefaults standardUserDefaults] setInteger:[_decimalsSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsDisplayDecimals];
        
        _displayDecimals = [_decimalsSubmenu.itemArray indexOfObject:sender];
    }
    [self update];
}

- (void)changeExchange:(id)sender {
    for (int i = 0; i < _exchangeSubmenu.itemArray.count; i++) {
        [_exchangeSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[_exchangeSubmenu.itemArray indexOfObject:sender] forKey:kDefaultsExchange];
    
    _displayExchange = [_exchangeSubmenu.itemArray indexOfObject:sender];
    
    [self validateCurrencies];
    [self update];
}

//enables only the currencies that the exchange supports
//falls back to first supported currency when selected currency is not supported
- (void)validateCurrencies {
    for (int i = 0; i < _currencySubmenu.itemArray.count; i++) {
        [[_currencySubmenu itemAtIndex:i] setEnabled:kCurrencies[_displayExchange][i]];
    }
    NSInteger cIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsCurrency];
    cIndex = MAX(0, MIN(cIndex, _currencySubmenu.itemArray.count - 1));
    if (!kCurrencies[_displayExchange][cIndex]) {
        for (int i = 0; i < _currencySubmenu.itemArray.count; i++) {
            if (kCurrencies[_displayExchange][i]) {
                [self changeCurrency:[_currencySubmenu itemAtIndex:i]];
                
                NSString* alertTitle = [NSString stringWithFormat:@"%@ does not support %@",
                                       [[_exchangeSubmenu itemAtIndex:_displayExchange] title],
                                       [[_currencySubmenu itemAtIndex:cIndex] title]];

                
                NSString* alertText = [NSString stringWithFormat:@"The selected exchange (%@) does not support the selected currency (%@). Falling back to %@.",
                                       [[_exchangeSubmenu itemAtIndex:_displayExchange] title],
                                       [[_currencySubmenu itemAtIndex:cIndex] title],
                                       [[_currencySubmenu itemAtIndex:i] title]];
                
                NSAlert *alert = [NSAlert alertWithMessageText:alertTitle
                                                 defaultButton:@"OK" alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"%@", alertText];
                [alert runModal];
                
                break;
            }
        }
    }
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

- (void)changeFontSize:(id)sender {
    for (int i = 0; i < _fontSizeSubmenu.itemArray.count; i++) {
        [_fontSizeSubmenu itemAtIndex:i].state = NSOffState;
    }
    [sender setState:NSOnState];
    
    [[NSUserDefaults standardUserDefaults] setObject:[sender title] forKey:kDefaultsFontSize];
    
    _displayFontSize = [[sender title] doubleValue];
    
    [self update];
}
                                     
                                     

@end
