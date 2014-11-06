#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchState.h"
#import <SpringBoardServices/SBSAccelerometer.h>
#import <objc/runtime.h> 
#import <substrate.h>
//#import <UIKit/UIDevice.h>
#import <UIKit/UIApplication.h>
#import <IOKit/IOReturn.h>
#import <dlfcn.h>
#import <notify.h>
#include <unistd.h>
#include "NSData+AES.m"
#import <AudioToolbox/AudioToolbox.h>

#define ACCEL_UPDATE_INTERVAL (0.5)
#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist"

typedef uint32_t IOPMAssertionID;
enum {
   kIOPMAssertionLevelOff = 0,
   kIOPMAssertionLevelOn = 255
};
typedef uint32_t IOPMAssertionLevel;
IOReturn (*IOPMAssertionCreate)(CFStringRef, IOPMAssertionLevel, IOPMAssertionID*);
IOReturn (*IOPMAssertionRelease)(IOPMAssertionID);

// Required for the CoreTelephony notifications
extern "C" id kCTCallStatusChangeNotification;
extern "C" id kCTCallStatus;
extern "C" id CTTelephonyCenterGetDefault(void);
extern "C" void CTTelephonyCenterAddObserver(id, id, CFNotificationCallback, NSString *, void *, int);


// INTERFACES / HEADER CRAP
@interface SBUIController
+ (id)sharedInstance;
- (_Bool)isOnAC;
@end

@interface SBLockScreenNotificationListController
-(id) init;
@end

@interface SBTelephonyManager
+(id)sharedTelephonyManager;
-(BOOL)inCall;
@end

@interface MPIncomingFaceTimeCallController
- (void)ringOrVibrate;
- (void)stopRingingOrVibrating;
@end

@interface MPIncomingPhoneCallController
- (void)ignore;
- (void)ringOrVibrate;
- (void)stopRingingOrVibrating;
@end

@interface SpringBoard
//- (void)setExpectsFaceContact:(_Bool)arg1;
//- (void)setExpectsFaceContact:(_Bool)arg1 inLandscape:(_Bool)arg2;
//- (_Bool)expectsFaceContactInLandscape;
//- (_Bool)expectsFaceContact;
- (void)setProximityEventsEnabled:(_Bool)arg1;
//- (_Bool)proximityEventsEnabled;
//- (void)_proximityChanged:(id)arg1;

-(void)_lockButtonDownFromSource:(int)source;
-(void)_lockButtonUpFromSource:(int)source;

- (int)_frontMostAppOrientation;

// oh ho, what do we have here? Potential Smart Cover support? Heck yeah
- (void)_smartCoverDidClose:(struct __IOHIDEvent *)arg1;
- (void)_smartCoverDidOpen:(struct __IOHIDEvent *)arg1;
@end

@interface SBBacklightController
+ (id)sharedInstance;
- (void)setBacklightFactor:(float)arg1 source:(int)arg2;
@end

@interface SBLockStateAggregator
+ (id)sharedInstance;
- (void)_updateLockState;
- (_Bool)hasAnyLockState;
- (unsigned long long)lockState;
@end

@interface SBUserAgent
+ (id)sharedUserAgent;
- (id)foregroundDisplayID;
- (void)lockAndDimDevice;
- (void)undimScreen;
-(BOOL) deviceIsLocked;
@end

@interface SBLockScreenViewControllerBase
- (void)prepareForMesaUnlockWithCompletion:(id)arg1;
@end

@interface SBLockScreenManager
+ (id)sharedInstance;
- (_Bool)attemptUnlockWithPasscode:(id)arg1;
- (void)_bioAuthenticated:(id)arg1;
- (void)startUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
- (_Bool)_shouldAutoUnlockFromUnlockSource:(int)arg1;
- (void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
- (void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_setUILocked:(_Bool)arg1;
@property(readonly, nonatomic) SBLockScreenViewControllerBase *lockScreenViewController;
@end

@interface SBUIBiometricEventMonitor
+ (id)sharedInstance;
- (void)_setDeviceLocked:(BOOL)arg1;
@end

@interface FOAccelerometerHandler : NSObject <SBSAccelerometerDelegate>
    -(void) start;
@end

// SOME VARIABLES
static FOAccelerometerHandler *accelHandler;
static SBSAccelerometer *theAcc;
static BOOL wasUndimmed = YES;
static SBLockScreenNotificationListController *LSNotifications;

// OPTIONS
static BOOL enabled = YES; // DONE
static BOOL disableOnAC = NO; // DONE
static BOOL enableWhileLocked = NO; // DONE
static BOOL enabledOnFaceUp = YES; // DONE
static BOOL useProximitySensor = YES; // DONE
static int proxMode = 1; // 1=standard, 2=WaveOff mode  DONE
static BOOL disableProxUntilMovement = YES; // DONE
static BOOL enableSmartCover = YES; // DONE
static float sensitivity = 2; // 1=high,2=normal,3=low(more likely to turn off) DONE
static float delay = 0; // seconds              DONE
static float delayOnFaceUp = 0; // seconds      DONE
static BOOL disableInCall = YES; // DONE NEEDS TESTING
static float proxTimeout = 3; // DONE
static BOOL overrideSmartCover = YES;
static BOOL enableProxOnlyOnAC = NO; // DONE
static BOOL disableLSNotifications = YES; // NEEDS TESTING
static BOOL disableSystemSleep = NO; // NEEDS TESTING
static BOOL disableSystemSleepWithProx = YES; // NEEDS TESTING
static BOOL detectPocket = YES; // DONE
static BOOL lockInPocket = YES;
static BOOL unlockWhenOutOfPocket = YES; 
static BOOL disableProxLandscape = NO;
static BOOL pocketUsesProx = YES;
static double autoDimDelay = 10;
static double autoDimLSDelay = 20;
static BOOL enableDimDelay = YES;
static BOOL disableDimDelayOnAC = YES;
static BOOL onlyLSDimDelayOnAC = NO;
static BOOL playLockSound = NO;
static BOOL disableInAllApps = NO;
static BOOL disableOnHS = NO;
static float proxDelay = 0; // seconds
static BOOL enabledOnFaceDown = YES;
static BOOL revertSwitches = YES;
static BOOL stayOnLSIfNotifications = YES;
static BOOL onlyTurnOnIfNotifications = NO;
static BOOL vibrateOnActivation = NO;

static BOOL silenceCalls = YES; // TODO, TODO integrate with callBar; all other toggles DONE
static BOOL enableDND = YES;
FSSwitchState lastStateOfDND;
static BOOL enableVibration = YES;
FSSwitchState lastStateOfVibration;
static BOOL disableVibration = NO;
static BOOL enableAirplaneMode = NO;
FSSwitchState lastStateOfAirplane;
static BOOL enableAutolock = NO;
FSSwitchState lastStateOfAutolock;
static BOOL enableMute = YES;
FSSwitchState lastStateOfMute;

static BOOL lockInstead = NO; // DONE
static BOOL autoUnlock = YES; // DONE
static BOOL turnOnWhenPickedUp = YES; // DONE
static BOOL overridePassword = YES; // DONE, NOT TOUCHID

static BOOL inPocket = NO;
static BOOL actualProxState = NO;
static BOOL wasInPocket = NO;

static NSString *password = @"";
static BOOL wantsPassword = YES;
static NSDate *delayBase, *unDelayBase, *proxDelayBase;

static NSDate *lastEnabledProx = [NSDate date];
static int lastX = 0, lastY = 0, lastZ = 0;
static BOOL proxDimmed = NO;
static BOOL didILockIt = NO;

static IOPMAssertionID noSleepAssertion;

static void vibrate()
{
    //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

static NSString* getUDID()
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    //CFStringRef uniqueIdentifier = MGCopyAnswer(CFSTR("UniqueDeviceID"));
    //return (NSString*)uniqueIdentifier;
    
    /*NSString *retVal = nil;
    CFTypeRef tmp = MGCopyAnswer(CFSTR("UniqueDeviceID"));
    if (tmp) {
        //retVal = [NSString stringWithString:tmp];
        NSData *resultData = CFBridgingRelease(tmp);
        retVal = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        CFRelease(tmp);
    }
    return retVal;*/
}

static void changeBacklight(float newValue)
{
    /*if (animateBacklight)
    {
        if (newValue == 1)
            for (int i = 0; i < 5; i++)
                [[%c(SBBacklightController) sharedInstance] setBacklightFactor:(newValue / i) source:0];
        else // newValue = 0
            for (int i = 0; i < 5; i++)
                [[%c(SBBacklightController) sharedInstance] setBacklightFactor:(0+(newValue/i) source:0];

        [[%c(SBBacklightController) sharedInstance] setBacklightFactor:newValue source:0];
    }
    else
    {*/
        [[%c(SBBacklightController) sharedInstance] setBacklightFactor:newValue source:0];
    //}
}

static void restoreLLSleep()
{
    if (!noSleepAssertion || disableSystemSleep)
        return;
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW|RTLD_GLOBAL);
    IOPMAssertionRelease = (IOReturn (*)(IOPMAssertionID)) dlsym(IOKit, "IOPMAssertionRelease");
    IOReturn status = IOPMAssertionRelease(noSleepAssertion);
    if (status != kIOReturnSuccess)
        NSLog(@"FaceOff7: Unable to restore system sleep :(");
    else
        NSLog(@"FaceOff7: restored system sleep");

    dlclose(IOKit);
}

static void disableLLSleep()
{
    if (noSleepAssertion)
        return;
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW|RTLD_GLOBAL);
    IOPMAssertionCreate = (IOReturn (*)(CFStringRef, IOPMAssertionLevel, IOPMAssertionID *)) dlsym(IOKit, "IOPMAssertionCreate");
    IOReturn status = IOPMAssertionCreate(CFSTR("NoIdleSleepAssertion"), 
                                    kIOPMAssertionLevelOn, &noSleepAssertion);

    if (status != kIOReturnSuccess || !noSleepAssertion)
        NSLog(@"FaceOff7: Unable to prevent system sleep :(");
    else
        NSLog(@"FaceOff7: Created system sleep prevention");

    dlclose(IOKit);
}

static void disable_proximity()
{
    notify_post("com.lodc.ios.faceoff/proximity_override_on");
    //[(SpringBoard*)[UIApplication sharedApplication] setProximityEventsEnabled:NO];
notify_post("com.lodc.ios.faceoff/updateProximity_off");
        //[UIDevice currentDevice].proximityMonitoringEnabled = YES;
        //[UIDevice currentDevice].proximityMonitoringEnabled = NO;
        notify_post("com.lodc.ios.faceoff/proximity_override_off");
        //notify_post("com.lodc.ios.faceoff/updateProximity_off");
}

static void updateProximity(BOOL override)
{
    //NSLog(@"FaceOff7: proximity override: %@", override ? @"yes" : @"no");
    if (enabled && useProximitySensor)
    {
        if (disableProxUntilMovement && override == false) //TODO
 disable_proximity();
        else
        {
            if (enableProxOnlyOnAC == NO)
            {
                notify_post("com.lodc.ios.faceoff/updateProximity_on");
                lastEnabledProx = [[NSDate date] retain];
            }
            else if (enableProxOnlyOnAC && [[%c(SBUIController) sharedInstance] isOnAC])
            {
                notify_post("com.lodc.ios.faceoff/updateProximity_on");
                lastEnabledProx = [[NSDate date] retain];
            }
            else
            {
 disable_proximity();
            }
        }
    }
    else
    {
        disable_proximity();
    }
}

static void reloadSettings(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    NSDictionary *prefs = [NSDictionary 
        dictionaryWithContentsOfFile:SETTINGS_FILE];

    
    if ([prefs objectForKey:@"enabled"] != nil)
        enabled = [[prefs objectForKey:@"enabled"] boolValue];
    else
        enabled = YES;

    if ([prefs objectForKey:@"disableOnAC"] != nil)
        disableOnAC = [[prefs objectForKey:@"disableOnAC"] boolValue];
    else
        disableOnAC = NO;

    if ([prefs objectForKey:@"enableWhileLocked"] != nil)
        enableWhileLocked = [[prefs objectForKey:@"enableWhileLocked"] boolValue];
    else
        enableWhileLocked = NO;

    if ([prefs objectForKey:@"enabledOnFaceUp"] != nil)
        enabledOnFaceUp = [[prefs objectForKey:@"enabledOnFaceUp"] boolValue];
    else
        enabledOnFaceUp = YES;

    if ([prefs objectForKey:@"useProximitySensor"] != nil)
        useProximitySensor = [[prefs objectForKey:@"useProximitySensor"] boolValue];
    else
        useProximitySensor = NO;

    if ([prefs objectForKey:@"disableProxUntilMovement"] != nil)
        disableProxUntilMovement = [[prefs objectForKey:@"disableProxUntilMovement"] boolValue];
    else
        disableProxUntilMovement = YES;

    if ([prefs objectForKey:@"silenceCalls"] != nil)
        silenceCalls = [[prefs objectForKey:@"silenceCalls"] boolValue];
    else
        silenceCalls = YES;

    if ([prefs objectForKey:@"enableDND"] != nil)
        enableDND = [[prefs objectForKey:@"enableDND"] boolValue];
    else
        enableDND = YES;

    if ([prefs objectForKey:@"enableVibration"] != nil)
        enableVibration = [[prefs objectForKey:@"enableVibration"] boolValue];
    else
        enableVibration = YES;

    if ([prefs objectForKey:@"disableVibration"] != nil)
        disableVibration = [[prefs objectForKey:@"disableVibration"] boolValue];
    else
        disableVibration = NO;

    if ([prefs objectForKey:@"enableAirplaneMode"] != nil)
        enableAirplaneMode = [[prefs objectForKey:@"enableAirplaneMode"] boolValue];
    else
        enableAirplaneMode = NO;

    if ([prefs objectForKey:@"enableAutolock"] != nil)
        enableAutolock = [[prefs objectForKey:@"enableAutolock"] boolValue];
    else
        enableAutolock = NO;

    if ([prefs objectForKey:@"enableMute"] != nil)
        enableMute = [[prefs objectForKey:@"enableMute"] boolValue];
    else
        enableMute = YES;

    if ([prefs objectForKey:@"lockInstead"] != nil)
        lockInstead = [[prefs objectForKey:@"lockInstead"] boolValue];
    else
        lockInstead = NO;

    if ([prefs objectForKey:@"autoUnlock"] != nil)
        autoUnlock = [[prefs objectForKey:@"autoUnlock"] boolValue];
    else
        autoUnlock = YES;

    if ([prefs objectForKey:@"turnOnWhenPickedUp"] != nil)
        turnOnWhenPickedUp = [[prefs objectForKey:@"turnOnWhenPickedUp"] boolValue];
    else
        turnOnWhenPickedUp = YES;

    if ([prefs objectForKey:@"proxMode"] != nil)
        proxMode = [[prefs objectForKey:@"proxMode"] intValue];
    else
        proxMode = 1;

    if ([prefs objectForKey:@"sensitivity"] != nil)
        sensitivity = [[prefs objectForKey:@"sensitivity"] floatValue];
    else
        sensitivity = 2;

    if ([prefs objectForKey:@"delay"] != nil)
        delay = [[prefs objectForKey:@"delay"] floatValue];
    else
        delay = 0;

    if ([prefs objectForKey:@"delayOnFaceUp"] != nil)
        delayOnFaceUp = [[prefs objectForKey:@"delayOnFaceUp"] floatValue];
    else
        delayOnFaceUp = 0;

    if ([prefs objectForKey:@"enableSmartCover"] != nil)
        enableSmartCover = [[prefs objectForKey:@"enableSmartCover"] boolValue];
    else
        enableSmartCover = YES;

    if ([prefs objectForKey:@"overridePassword"] != nil)
        overridePassword = [[prefs objectForKey:@"overridePassword"] boolValue];
    else
        overridePassword = YES;

    if ([prefs objectForKey:@"disableInCall"] != nil)
        disableInCall = [[prefs objectForKey:@"disableInCall"] boolValue];
    else
        disableInCall = YES;

    if ([prefs objectForKey:@"overrideSmartCover"] != nil)
        overrideSmartCover = [[prefs objectForKey:@"overrideSmartCover"] boolValue];
    else
        overrideSmartCover = YES;

    if ([prefs objectForKey:@"enableProxOnlyOnAC"] != nil)
        enableProxOnlyOnAC = [[prefs objectForKey:@"enableProxOnlyOnAC"] boolValue];
    else
        enableProxOnlyOnAC = NO;

    if ([prefs objectForKey:@"disableLSNotifications"] != nil)
        disableLSNotifications = [[prefs objectForKey:@"disableLSNotifications"] boolValue];
    else
        disableLSNotifications = YES;

    if ([prefs objectForKey:@"disableSystemSleep"] != nil)
        disableSystemSleep = [[prefs objectForKey:@"disableSystemSleep"] boolValue];
    else
        disableSystemSleep = NO;

    if ([prefs objectForKey:@"disableSystemSleepWithProx"] != nil)
        disableSystemSleepWithProx = [[prefs objectForKey:@"disableSystemSleepWithProx"] boolValue];
    else
        disableSystemSleepWithProx = NO;

    if ([prefs objectForKey:@"proxTimeout"] != nil)
        proxTimeout = [[prefs objectForKey:@"proxTimeout"] floatValue];
    else
        proxTimeout = 3;

    if ([prefs objectForKey:@"detectPocket"] != nil)
        detectPocket = [[prefs objectForKey:@"detectPocket"] boolValue];
    else
        detectPocket = YES;

    if ([prefs objectForKey:@"lockInPocket"] != nil)
        lockInPocket = [[prefs objectForKey:@"lockInPocket"] boolValue];
    else
        lockInPocket = YES;

    if ([prefs objectForKey:@"unlockWhenOutOfPocket"] != nil)
        unlockWhenOutOfPocket = [[prefs objectForKey:@"unlockWhenOutOfPocket"] boolValue];
    else
        unlockWhenOutOfPocket = YES;

    if ([prefs objectForKey:@"disableProxLandscape"] != nil)
        disableProxLandscape = [[prefs objectForKey:@"disableProxLandscape"] boolValue];
    else
        disableProxLandscape = NO;

    if ([prefs objectForKey:@"pocketUsesProx"] != nil)
        pocketUsesProx = [[prefs objectForKey:@"pocketUsesProx"] boolValue];
    else
        pocketUsesProx = NO;

    if ([prefs objectForKey:@"enableDimDelay"] != nil)
        enableDimDelay = [[prefs objectForKey:@"enableDimDelay"] boolValue];
    else
        enableDimDelay = YES;

    if ([prefs objectForKey:@"disableDimDelayOnAC"] != nil)
        disableDimDelayOnAC = [[prefs objectForKey:@"disableDimDelayOnAC"] boolValue];
    else
        disableDimDelayOnAC = YES;

    if ([prefs objectForKey:@"onlyLSDimDelayOnAC"] != nil)
        onlyLSDimDelayOnAC = [[prefs objectForKey:@"onlyLSDimDelayOnAC"] boolValue];
    else
        onlyLSDimDelayOnAC = NO;

    if ([prefs objectForKey:@"autoDimDelay"] != nil)
        autoDimDelay = [[prefs objectForKey:@"autoDimDelay"] doubleValue];
    else
        autoDimDelay = 10;
    if (autoDimDelay == 0 || !autoDimDelay)
        autoDimDelay = -1;

    if ([prefs objectForKey:@"autoDimLSDelay"] != nil)
        autoDimLSDelay = [[prefs objectForKey:@"autoDimLSDelay"] doubleValue];
    else
        autoDimLSDelay = 20;
    if (autoDimLSDelay == 0 || !autoDimLSDelay)
        autoDimLSDelay = 8;

    if ([prefs objectForKey:@"playLockSound"] != nil)
        playLockSound = [[prefs objectForKey:@"playLockSound"] boolValue];
    else
        playLockSound = NO;

    if ([prefs objectForKey:@"disableInAllApps"] != nil)
        disableInAllApps = [[prefs objectForKey:@"disableInAllApps"] boolValue];
    else
        disableInAllApps = NO;

    if ([prefs objectForKey:@"disableOnHS"] != nil)
        disableOnHS = [[prefs objectForKey:@"disableOnHS"] boolValue];
    else
        disableOnHS = NO;

    if ([prefs objectForKey:@"proxDelay"] != nil)
        proxDelay = [[prefs objectForKey:@"proxDelay"] floatValue];
    else
        proxDelay = 0;

    if ([prefs objectForKey:@"enabledOnFaceDown"] != nil)
        enabledOnFaceDown = [[prefs objectForKey:@"enabledOnFaceDown"] boolValue];
    else
        enabledOnFaceDown = YES;

    if ([prefs objectForKey:@"revertSwitches"] != nil)
        revertSwitches = [[prefs objectForKey:@"revertSwitches"] boolValue];
    else
        revertSwitches = YES;

    if ([prefs objectForKey:@"stayOnLSIfNotifications"] != nil)
        stayOnLSIfNotifications = [[prefs objectForKey:@"stayOnLSIfNotifications"] boolValue];
    else
        stayOnLSIfNotifications = YES;
    
    if ([prefs objectForKey:@"onlyTurnOnIfNotifications"] != nil)
        onlyTurnOnIfNotifications = [[prefs objectForKey:@"onlyTurnOnIfNotifications"] boolValue];
    else
        onlyTurnOnIfNotifications = NO;

    if ([prefs objectForKey:@"vibrateOnActivation"] != nil)
        vibrateOnActivation = [[prefs objectForKey:@"vibrateOnActivation"] boolValue];
    else
        vibrateOnActivation = NO;

    if (disableSystemSleep)
    {
        disableLLSleep();
    }
    else if (noSleepAssertion)
    {
        restoreLLSleep();
    }

    updateProximity(NO);
}

static void proximity_disabled(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    actualProxState = NO;
    if (proxMode == 1)
    {
        proxDimmed = NO;
        [accelHandler accelerometer:theAcc didAccelerateWithTimeStamp:0 x:lastX y:lastY z:lastZ eventType:0]; // force refresh
    }
}

static void proximity_enabled(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    actualProxState = YES;
    if (!useProximitySensor)
    {
        //proxDimmed = NO;
        return;
    }

    if (disableProxLandscape && UIDeviceOrientationIsLandscape([(SpringBoard*)[UIApplication sharedApplication] _frontMostAppOrientation]))
        return;

    if (proxMode == 1)
        proxDimmed = YES;
    if (proxMode == 2)
        proxDimmed = !proxDimmed;

    if (proxDimmed && disableSystemSleepWithProx)
    {
        disableLLSleep();
    }
    else if (disableSystemSleepWithProx == NO)
    {
        restoreLLSleep();
    }

    [accelHandler accelerometer:theAcc didAccelerateWithTimeStamp:0 x:lastX y:lastY z:lastZ eventType:0]; // force refresh
}


static BOOL shouldActivate(float x, float y, float z)
{
    float rX, rY, rZ; // r is for “required” 

    if (sensitivity == 1) // high
    {
        rX = 0.085; rY = 0.085; rZ = 0.88;
    }
    else if (sensitivity == 2) // normal
    {
        rX = 0.15; rY = 0.15; rZ = 0.8;
    }
    else // if (sensitivity == 3) // low
    {
        rX = 0.2; rY = 0.2; rZ = 0.7;
    }

    if (wasUndimmed == NO)
    {
        rX += 0.05;
        rY += 0.05;
        rZ += 0.05;
    }

    if ((x < rX && x > -rX) &&
      (y < rY && y > -rY) &&
      (z > rZ) && enabledOnFaceDown) // face down
        return YES;

    if ((x < rX && x > -rX) &&
    (y < rY && y > -rY) &&
    (z < -rZ) && enabledOnFaceUp) // face up
        return YES;

//NSLog(@“FaceOff7: proxMode: %@", proxMode == 1 ? @"proxMode1" : @"proxMode2");
//NSLog(@"FaceOff7: proxDimmed: %@", proxDimmed ? @"yes" : @"no");

    if (detectPocket)
    {
        if ((x < 0.4 && x > -0.4) && (y > 0.8 && y < 1.02) && (z < 0.4 && z > -0.4))
        {
            if (pocketUsesProx == NO || (pocketUsesProx && actualProxState))
            {
                notify_post("com.lodc.ios.faceoff/inpocket_on");
                inPocket = YES;
                wasInPocket = YES;
                //NSLog(@"FaceOff7: pocket detected! %f %f %f", x, y, z);
                return YES;
            }
        }
        else if ((wasInPocket || inPocket) && pocketUsesProx && actualProxState) // checkForProxIfMovement())
            return YES;
        
        // check if it’s still pointing down enough
        //if (inPocket && (x < 0.6 && x > -0.4) && (y > 0.5 && y < 1.15) && (z < 0.6 && z > -0.4))
        if ((x < 0.5 && x > -0.5) && (y > 0.75 && y < 1.04) && (z < 0.5 && z > -0.5))
            return YES;
    }
    notify_post("com.lodc.ios.faceoff/inpocket_off");
    inPocket = NO;

    if (useProximitySensor)
    {
        if (enableProxOnlyOnAC == NO || (enableProxOnlyOnAC && [[%c(SBUIController) sharedInstance] isOnAC]))
        {
            //return proxDimmed;

            if (proxDelayBase == nil)
                proxDelayBase = [[NSDate date] retain];

            if ([[NSDate date] timeIntervalSinceDate:proxDelayBase] >= proxDelay)
            {
                proxDelayBase = nil;
                return proxDimmed;
            } else {
                return NO;
            }
        }
    }


//NSLog(@"FaceOff7: pocket not detected! %f %f %f", x, y, z);
    return NO;
}


static NSString* getCurrentApp()
{
    NSString *app = [[%c(SBUserAgent) sharedUserAgent] foregroundDisplayID];
    return app == nil ? @"" : app;
}

static void ApplyToggles(BOOL apply)
{
    if (apply)
    {
        if (enableDND)
        {
            lastStateOfDND = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
        }
        if (enableVibration && !disableVibration)
        {
            lastStateOfVibration = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        }
        if (disableVibration)
        {
            lastStateOfVibration = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        }
        if (enableAirplaneMode)
        {
            lastStateOfAirplane = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
        }
        if (enableAutolock)
        {
            lastStateOfAutolock = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOn forSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
        }
        if (enableMute)
        {
            lastStateOfMute = [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
            [[FSSwitchPanel sharedPanel] setState:FSSwitchStateOff forSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
        }
    }
    else
    {
        if (enableDND)
            [[FSSwitchPanel sharedPanel] setState:(revertSwitches ? lastStateOfDND : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.do-not-disturb"];
        if (enableVibration)
            [[FSSwitchPanel sharedPanel] setState:(revertSwitches ? lastStateOfVibration : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        if (disableVibration)
            [[FSSwitchPanel sharedPanel] setState:lastStateOfVibration forSwitchIdentifier:@"com.a3tweaks.switch.vibration"];
        if (enableAirplaneMode)
            [[FSSwitchPanel sharedPanel] setState:(revertSwitches ? lastStateOfAirplane : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.airplane-mode"];
        if (enableAutolock)
            [[FSSwitchPanel sharedPanel] setState:(revertSwitches ? lastStateOfAutolock : FSSwitchStateOff) forSwitchIdentifier:@"com.a3tweaks.switch.autolock"];
        if (enableMute)
            [[FSSwitchPanel sharedPanel] setState:(revertSwitches ? lastStateOfMute : FSSwitchStateOn) forSwitchIdentifier:@"com.a3tweaks.switch.ringer"];
    }
}

static void telephonyEventCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    if (userInfo != NULL)
        updateProximity(NO);
}

@implementation FOAccelerometerHandler

// Because this updates every .5 seconds it is also used for other things than just the Accelerometer part
-(void) accelerometer:(SBSAccelerometer *)accelerometer
  didAccelerateWithTimeStamp:(NSTimeInterval)timeStamp x:(float)x 
y:(float)y 
  z:(float)z eventType:(unsigned)type
{

    //NSLog(@"FaceOff7: enabled: %@", enabled ? @"yes": @"no");
    if (enabled == NO ||
      (disableOnAC == YES && [[%c(SBUIController) sharedInstance] isOnAC]) ||
      (disableInCall && [[%c(SBTelephonyManager) sharedTelephonyManager] inCall]) ||
      (disableInAllApps && ![getCurrentApp() isEqual:@""]) ||
      (disableOnHS && ([getCurrentApp() isEqual:@""] && ![[%c(SBLockStateAggregator) sharedInstance] hasAnyLockState])) 
      )
    {
        delayBase = nil; unDelayBase = nil; proxDelayBase = nil;
        return;
    }

    NSDictionary *blacklist = [NSDictionary 
        dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff7.blacklist.plist"];
    NSString *prefix = @"Blacklist-";
    if ([blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] != nil)
        if ([[blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] boolValue])
        {
            delayBase = nil; unDelayBase = nil; proxDelayBase = nil;
            return;
        }

    BOOL should = shouldActivate(x, y, z);
    //NSLog(@"FaceOff7: shouldActivate: %@", should ? @"yes" : @"no");
    if (should)
    {
        proxDelayBase = nil;
        
        if (wasUndimmed)
        {
            unDelayBase = nil;
            if (delayBase == nil)
                delayBase = [[NSDate date] retain];

            if ([[NSDate date] timeIntervalSinceDate:delayBase] >= delay)
            {
                delayBase = nil;
            } else {
                return;
            }

            if (lockInstead || (inPocket && detectPocket && lockInPocket && unlockWhenOutOfPocket))
            {
NSLog(@"FaceOff7: locking device");
                didILockIt = YES;
                notify_post("com.lodc.ios.faceoff/didILockIt_on");
                //[[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
                if (![[%c(SBUserAgent) sharedUserAgent] deviceIsLocked])
                {
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonDownFromSource:1];
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonUpFromSource:1];
                }
                if (disableSystemSleep)
                    disableLLSleep();
            }
            else if (inPocket && detectPocket && lockInPocket && unlockWhenOutOfPocket == NO)
            {
                didILockIt = NO;
                notify_post("com.lodc.ios.faceoff/didILockIt_off");
                //[[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
                if (![[%c(SBUserAgent) sharedUserAgent] deviceIsLocked])
                {
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonDownFromSource:1];
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonUpFromSource:1];
                }
            }
            else
            {
                disableLLSleep();
                changeBacklight(0.0f);
            }

            wasUndimmed = NO;
            NSLog(@"FaceOff7: Dimmed screen");
            ApplyToggles(YES);
            if (vibrateOnActivation)
                vibrate();
            if (inPocket && lockInPocket && unlockWhenOutOfPocket)
                disableLLSleep();
        }
    }
    else
    {
        delayBase = nil;

        if (wasUndimmed == NO)
        {
            if (unDelayBase == nil)
                unDelayBase = [[NSDate date] retain];

            if ([[NSDate date] timeIntervalSinceDate:unDelayBase] >= delayOnFaceUp)
            {
                unDelayBase = nil;
            } else {
                return;
            }


            if (lockInstead)
            {
                if (turnOnWhenPickedUp) 
                {
                    if (onlyTurnOnIfNotifications && LSNotifications != NULL)
                    {
                        NSMutableArray *li = MSHookIvar<NSMutableArray *>(LSNotifications, "_listItems");
                        if ([li count] == 0)
                            return;
                    }
                    
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonDownFromSource:1];
                    [(SpringBoard*)[UIApplication sharedApplication] _lockButtonUpFromSource:1];
                }
                    //[[%c(SBUserAgent) sharedUserAgent] undimScreen];
                if (autoUnlock)
                {
                    if (stayOnLSIfNotifications && LSNotifications != NULL)
                    {
                        NSMutableArray *li = MSHookIvar<NSMutableArray *>(LSNotifications, "_listItems");
                        if ([li count] > 0)
                            return;
                    }

                    if (overridePassword)
                    {
                        //NSLog(@"FaceOff7: unlocking: %@", password);
                        [[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:password];
                    }
                    else
                        [[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:@""];
                }
            }
            else if (detectPocket && lockInPocket && unlockWhenOutOfPocket && wasInPocket)
            {
                wasInPocket = NO;
                [[%c(SBUserAgent) sharedUserAgent] undimScreen];
            }
            else //if (wasInPocket == NO || (wasInPocket && unlockWhenOutOfPocket))
            {
                if (!disableSystemSleep)
                    restoreLLSleep();
                changeBacklight(1.0f);
            }

            if (lockInPocket && unlockWhenOutOfPocket && wasInPocket)
                restoreLLSleep();
            wasUndimmed = YES;
            NSLog(@"FaceOff7: Undimmed screen");
            ApplyToggles(NO);
        }

    }

/*
    if (disableProxUntilMovement && useProximitySensor)
    {
        if (abs(lastX - x) > 0.1 || abs(lastY - y) > 0.1 || abs(lastZ - z) > 0.1)
        { //NSLog(@"FaceOff7: prox movement starting");
            updateProximity(YES);
        }
        else if (wasUndimmed && lastEnabledProx != nil && [[NSDate date] timeIntervalSinceDate:lastEnabledProx] >= proxTimeout) 
        { //NSLog(@"FaceOff7: prox time out");
            updateProximity(NO); 
        }
    }
*/

    lastX = x; lastY = y; lastZ = z;
}

-(void) start
{
    theAcc = [[SBSAccelerometer alloc] init];
    theAcc.accelerometerEventsEnabled = YES;
    theAcc.updateInterval = ACCEL_UPDATE_INTERVAL; // seconds
    theAcc.xThreshold = 0.01; //0.2
    theAcc.yThreshold = 0.01;
    theAcc.zThreshold = 0.01;
    theAcc.orientationEventsEnabled = NO;
    theAcc.delegate = self;

    reloadSettings(nil, nil, nil, nil, nil);
    
    wasUndimmed = YES;

    //[d release];
    //[theAcc _checkIn];
}

@end

%hook SpringBoard

-(void) applicationDidFinishLaunching:(id)application
{
    %orig;

    accelHandler = [[FOAccelerometerHandler alloc] init];
    [accelHandler start];
}

/*
-(void) dealloc
{
    %orig;
    
    //[accelHandler release];
    //[accelHandler dealloc];
}
*/

- (void)_smartCoverDidClose:(struct __IOHIDEvent *)arg1
{
    %orig;

    if (enabled && enableSmartCover)
        ApplyToggles(YES);
}

- (void)_smartCoverDidOpen:(struct __IOHIDEvent *)arg1
{
    %orig;

    if (enabled && enableSmartCover)
        ApplyToggles(NO);
}
%end

%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;

    //if ([self hasAnyLockState]) NSLog(@"FaceOff7: locked without didILockIt : %@", didILockIt ? @"iDidLockIt" : @"iDidntLockIt");
    if ([self hasAnyLockState])
        notify_post("com.lodc.ios.faceoff/islocked_on");
    else
        notify_post("com.lodc.ios.faceoff/islocked_off");

    if ([self hasAnyLockState] && !enableWhileLocked && didILockIt == NO)
    {
        theAcc.delegate = nil;
        //theAcc.updateInterval = 600000000; // … (/).-)
        //if (useProximitySensor)
        //    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        didILockIt = NO;
        notify_post("com.lodc.ios.faceoff/didILockIt_off");
    }
    else if ([self hasAnyLockState] && didILockIt)
    {
        //notify_post("com.lodc.ios.faceoff/didILockIt_off");
        //didILockIt = NO; 
    }
    else if ([self hasAnyLockState] == NO)
    {
        //if (password && wantsPassword)
        //    wantsPassword = NO;
        theAcc.delegate = accelHandler;
        //theAcc.updateInterval = ACCEL_UPDATE_INTERVAL;
        updateProximity(NO);
        didILockIt = NO;
    }
}
%end

%hook SBDeviceLockController
-(_Bool)attemptDeviceUnlockWithPassword:(id)arg1 appRequested:(_Bool)arg2
{
    BOOL result = %orig;

    if (wantsPassword)
    {
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_FILE];
        if (!prefs)
            prefs = [[NSMutableDictionary alloc] init];

        if ([arg1 isKindOfClass:[NSString class]] && ![prefs[@"devicePasscode"] isKindOfClass:[NSData class]] && result)
        {
            password = [arg1 retain];
            [prefs setObject:[[arg1 dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:getUDID()] forKey:@"devicePasscode"];
            [prefs writeToFile:SETTINGS_FILE atomically:YES];
            wantsPassword = NO;
            UIAlertView *alert = [[UIAlertView alloc]
					initWithTitle:@"FaceOff7"
					message:@"Sucessfully updated stored passcode!"
					delegate:nil
					cancelButtonTitle:@"OK"
					otherButtonTitles:nil];
            [alert show];
        }
        else if ([prefs[@"devicePasscode"] isKindOfClass:[NSData class]])
        {
            NSData *passcodeData = [prefs[@"devicePasscode"] AES256DecryptWithKey:getUDID()];
            password = [[NSString stringWithUTF8String:[[[NSString alloc] initWithData:passcodeData encoding:NSUTF8StringEncoding] UTF8String]] retain];
            
            if (result)
            {
                if (password != arg1 && [arg1 isKindOfClass:[NSString class]])
                {
                    password = [arg1 retain];
                    [prefs setObject:[[arg1 dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:getUDID()] forKey:@"devicePasscode"];
                    [prefs writeToFile:SETTINGS_FILE atomically:YES];
                    wantsPassword = NO;
                }
            }
        }
        
        if (![prefs[@"devicePasscode"] isKindOfClass:[NSData class]] && wantsPassword)// no passcode stored
        {
            UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:@"FaceOff7"
                message:@"No device passcode stored. Please unlock the device with your passcode."
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
            [alert show];
        }
        //[prefs release];
    }
    else
    {
        if (result && password != nil && password != arg1 && [arg1 isKindOfClass:[NSString class]])
        {
            NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_FILE];
            if (!prefs)
                prefs = [[NSMutableDictionary alloc] init];
            password = [arg1 retain];
            [prefs setObject:[[arg1 dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:getUDID()] forKey:@"devicePasscode"];
            [prefs writeToFile:SETTINGS_FILE atomically:YES];
        }
    }


    return result;
}
%end

%hook SBLockScreenNotificationListController
- (void)turnOnScreenIfNecessaryForItem:(id)arg1
{
    if (enabled && disableLSNotifications && wasUndimmed == NO && lockInstead)
        return;
    %orig;
}
%end


%group CallController
%hook MPIncomingPhoneCallController
-(void)ringOrVibrate
{
    if (wasUndimmed == NO && enabled && silenceCalls)
        return;
        //[self ignore];
        //[self stopRingingOrVibrating];
    %orig;
}
%end
%hook MPIncomingFaceTimeCallController
-(void)ringOrVibrate
{
    if (wasUndimmed == NO && enabled && silenceCalls)
        return;
    %orig;
}
%end
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

%hook SBSoundPreferences
+ (_Bool)playLockSound
{
    return (enabled && playLockSound ? YES : %orig);
}
%end

%hook SBLockScreenNotificationListController
-(id) init
{
    id a = %orig;
    LSNotifications = a;
    return a;
}
%end

%ctor
{
    %init;
     // Register for the preferences-did-change notification
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &reloadSettings, CFSTR("com.lodc.ios.faceoff/reloadSettings"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &proximity_enabled, CFSTR("com.lodc.ios.faceoff/proximity_enabled"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &proximity_disabled, CFSTR("com.lodc.ios.faceoff/proximity_disabled"), NULL, 0);
    CTTelephonyCenterAddObserver(CTTelephonyCenterGetDefault(), NULL, telephonyEventCallback, NULL, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
