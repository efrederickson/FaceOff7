#import "common.h"
#import "FOSettings.h"
#import "FOAccelerometerHandler.h"

%group CallController
%hook MPIncomingPhoneCallController
-(void)ringOrVibrate
{
    if ([FOSettings sharedInstance].isDimmed && [FOSettings sharedInstance].enabled && [FOSettings sharedInstance].silenceCalls)
        return;
        //[self ignore];
        //[self stopRingingOrVibrating];
    %orig;
}
%end
%hook MPIncomingFaceTimeCallController
-(void)ringOrVibrate
{
    if ([FOSettings sharedInstance].isDimmed && [FOSettings sharedInstance].enabled && [FOSettings sharedInstance].silenceCalls)
        return;
    %orig;
}
%end
%end // GROUP CallController

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

%hook SBSoundPreferences
+ (_Bool)playLockSound
{
    return ([FOSettings sharedInstance].enabled && [FOSettings sharedInstance].playLockSound ? YES : %orig);
}
%end

%hook SBPluginManager
-(Class)loadPluginBundle:(NSBundle*)bundle
{
    id ret = %orig;

    if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilephone.incomingcall"] && [bundle isLoaded])
    {
         NSLog(@"FaceOff7: initializing phone call overriding");
         %init(CallController);
    }

    return ret;
}
%end

%hook SBLockScreenNotificationListController
- (void)turnOnScreenIfNecessaryForItem:(id)arg1
{
    if ([FOSettings sharedInstance].enabled && [FOSettings sharedInstance].disableLSNotifications && [FOSettings sharedInstance].isDimmed)
        return;
    %orig;
}
%end


%hook SBBacklightController
-(double) _nextIdleTimeDuration
{
    if (enableDimDelay)
    {
        if (disableDimDelayOnAC && [[%c(SBUIController) sharedInstance] isOnAC])
            return %orig;
        else
            return autoDimDelay;
    }

    return %orig;
}

- (double)defaultLockScreenDimIntervalWhenNotificationsPresent
{
    if (enableDimDelay)
        if (onlyLSDimDelayOnAC == NO || (onlyLSDimDelayOnAC && [[%c(SBUIController) sharedInstance] isOnAC]))
            return autoDimLSDelay;

    return %orig;
}
- (double)defaultLockScreenDimInterval
{
    if (enableDimDelay)
        if (onlyLSDimDelayOnAC == NO || (onlyLSDimDelayOnAC && [[%c(SBUIController) sharedInstance] isOnAC]))
            return autoDimLSDelay;

    return %orig;
}
- (double)_currentLockScreenIdleTimerInterval
{
    if (enableDimDelay)
        if (onlyLSDimDelayOnAC == NO || (onlyLSDimDelayOnAC && [[%c(SBUIController) sharedInstance] isOnAC]))
            return autoDimLSDelay;

    return %orig;
}
- (void)_didIdle
{
    if (enableDimDelay)
    {
        NSDictionary *blacklist = [NSDictionary 
            dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff7.blacklist.plist"];
        NSString *prefix = @"Blacklist-";
        if ([blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] != nil)
            if ([[blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] boolValue])
                return;
    }
    %orig;
}
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