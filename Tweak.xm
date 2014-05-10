#import "common.h"
#import "FOSettings.h"
#import "FOAccelerometerHandler.h"

%group SpringBoard

static FOAccelerometerHandler *accelerometerHandler;

%hook SpringBoard

-(void) applicationDidFinishLaunching:(id)application
{
    accelerometerHandler = [[FOAccelerometerHandler alloc] init];
    [accelerometerHandler start];
}

/*
    TODO: currently gives errors about ApplyToggles
- (void)_smartCoverDidClose:(struct __IOHIDEvent *)arg1
{
    %orig;

    if ([FOSettings sharedInstance].enabled && [FOSettings sharedInstance].enableSmartCover)
        ApplyToggles(YES);
}

- (void)_smartCoverDidOpen:(struct __IOHIDEvent *)arg1
{
    %orig;

    if ([FOSettings sharedInstance].enabled && [FOSettings sharedInstance].enableSmartCover)
        ApplyToggles(NO);
}
*/

%end

%end // GROUP SpringBoard

%ctor
{
    // Start up
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        %init(SpringBoard);
    }
    else if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"])
    {
    
    }
    // TODO: Hook up preference change and telephony notifications
}