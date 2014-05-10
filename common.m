#import "common.h"
#import <AudioToolbox/AudioToolbox.h>
#import "FOSettings.h"
#import <objc/runtime.h> 
#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchState.h"

// Vibrates the device
void vibrate()
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

// returns the device's UDID. Because we are in SpringBoard this works
NSString *getUDID()
{
    NSString *udid = (__bridge NSString*)MGCopyAnswer(CFSTR("UniqueDeviceID"));
    return udid;
}

// Returns the current foreground (running) app's identifier
NSString* getCurrentApp()
{
    NSString *app = [[objc_getClass("SBUserAgent") sharedUserAgent] foregroundDisplayID];
    return app; /* nil = no app | non-nil = app id (e.g. com.apple.Mail) */
}

void changeBacklight(float newValue)
{
    // Changes the backlight to the specified value. Currently does not "animate" or "fade"
    [[objc_getClass("SBBacklightController") sharedInstance] setBacklightFactor:newValue source:0];
}


BOOL restoreLLSleep()
{
    IOReturn status = IOPMAssertionRelease(noSleepAssertion);
    if (status != kIOReturnSuccess)
        NSLog(@"FaceOff7: Unable to restore system sleep :(");
    else
        NSLog(@"FaceOff7: restored system sleep");
    
    return status == kIOReturnSuccess;
}

BOOL disableLLSleep()
{
    if (noSleepAssertion)
        return YES;
    
    IOReturn status = IOPMAssertionCreate(CFSTR("NoIdleSleepAssertion"),
        kIOPMAssertionLevelOn, &noSleepAssertion);
    
    if (status != kIOReturnSuccess || !noSleepAssertion)
        NSLog(@"FaceOff7: Unable to prevent system sleep :(");
    else
        NSLog(@"FaceOff7: Created system sleep prevention");
    
    return status == kIOReturnSuccess;
}

// This will (using Flipswitch) activate/deactivate switches
void ApplyToggles(BOOL apply)
{
    if (apply)
    {
        if ([FOSettings sharedInstance].enableDND)
        {
            [FOSettings sharedInstance].lastStateOfDND = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
        }
        if ([FOSettings sharedInstance].enableVibration && ![FOSettings sharedInstance].disableVibration)
        {
            [FOSettings sharedInstance].lastStateOfVibration = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        }
        if ([FOSettings sharedInstance].disableVibration)
        {
            [FOSettings sharedInstance].lastStateOfVibration = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        }
        if ([FOSettings sharedInstance].enableAirplaneMode)
        {
            [FOSettings sharedInstance].lastStateOfAirplane = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
        }
        if ([FOSettings sharedInstance].enableAutolock)
        {
            [FOSettings sharedInstance].lastStateOfAutolock = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
        }
        if ([FOSettings sharedInstance].enableMute)
        {
            [FOSettings sharedInstance].lastStateOfMute = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
        }
    }
    else
    {
        if ([FOSettings sharedInstance].enableDND)
            [[FSSwitchPanel sharedPanel] setState:([FOSettings sharedInstance].revertSwitches ? [FOSettings sharedInstance].lastStateOfDND : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
        if ([FOSettings sharedInstance].enableVibration)
            [[FSSwitchPanel sharedPanel] setState:([FOSettings sharedInstance].revertSwitches ? [FOSettings sharedInstance].lastStateOfVibration : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        if ([FOSettings sharedInstance].disableVibration)
            [[FSSwitchPanel sharedPanel] setState:[FOSettings sharedInstance].lastStateOfVibration forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        if ([FOSettings sharedInstance].enableAirplaneMode)
            [[FSSwitchPanel sharedPanel] setState:([FOSettings sharedInstance].revertSwitches ? [FOSettings sharedInstance].lastStateOfAirplane : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
        if ([FOSettings sharedInstance].enableAutolock)
            [[FSSwitchPanel sharedPanel] setState:([FOSettings sharedInstance].revertSwitches ? [FOSettings sharedInstance].lastStateOfAutolock : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
        if ([FOSettings sharedInstance].enableMute)
            [[FSSwitchPanel sharedPanel] setState:([FOSettings sharedInstance].revertSwitches ? [FOSettings sharedInstance].lastStateOfMute : FSSwitchStateOn) forSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
    }
}