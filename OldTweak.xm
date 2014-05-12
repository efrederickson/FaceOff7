// Required for the CoreTelephony notifications
extern "C" id kCTCallStatusChangeNotification;
extern "C" id kCTCallStatus;
extern "C" id CTTelephonyCenterGetDefault(void);
extern "C" void CTTelephonyCenterAddObserver(id, id, CFNotificationCallback, NSString *, void *, int);

// SOME VARIABLES
static FOAccelerometerHandler *accelHandler;
static SBSAccelerometer *theAcc;
static BOOL wasUndimmed = YES;
static SBLockScreenNotificationListController *LSNotifications;

static BOOL lockInstead = NO; // DONE
static BOOL autoUnlock = YES; // DONE
static BOOL turnOnWhenPickedUp = YES; // DONE
static BOOL overridePassword = YES; // DONE

static BOOL inPocket = NO;
static BOOL actualProxState = NO;
static BOOL wasInPocket = NO;

static NSString *password = @"";
static BOOL wantsPassword = YES;
static

static NSDate *lastEnabledProx = [NSDate date];
static int lastX = 0, lastY = 0, lastZ = 0;
static BOOL proxDimmed = NO;
static BOOL didILockIt = NO;

static IOPMAssertionID noSleepAssertion;

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


@end

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
