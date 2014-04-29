#import <GraphicsServices/GraphicsServices.h>
#import <substrate.h>
#import <IOKit/hid/IOHIDEvent.h>
#import <IOKit/hid/IOHIDService.h>
#import <IOKit/hid/IOHIDEventSystem.h>
#import <notify.h>

@interface BKProximitySensorInterface : NSObject
+(id)sharedInstance;
-(BOOL)clientRequestedProximityMode:(int)arg1 processID:(int)arg2 clientPort:(unsigned)arg3 ;
-(BOOL)isDetectionActive;
-(int)requestedMode;
-(void)_updateProximityDetectionMode;
-(BOOL)_updateClientPID:(int)arg1 clientPort:(unsigned)arg2 withDetectionMode:(int)arg3 ;
-(void)requestProximityMode:(int)arg1 ;
-(void)disableProximityDetection;
-(void)enableProximityDetectionWithMode:(int)arg1;
-(int)currentMode;
@end

@interface BKProximityDetectionClient
@property (assign,nonatomic) id delegate;                   //@synthesize delegate=_delegate - In the implementation block
@property (setter=setPID:,getter=PID) int pid;              //@synthesize pid=_pid - In the implementation block
@property (assign) int requestedMode;                       //@synthesize requestedMode=_requestedMode - In the implementation block
@property (assign,nonatomic) unsigned port;                 //@synthesize port=_port - In the implementation block
-(int)PID;
-(void)setPID:(int)arg1 ;
-(void)setRequestedMode:(int)arg1 ;
-(int)requestedMode;
-(id)initWithPID:(int)arg1 port:(unsigned)arg2 delegate:(id)arg3 ;
-(void)setPort:(unsigned)arg1 ;
-(void)dealloc;
-(void)setDelegate:(id)arg1 ;
-(id)init;
-(id)description;
-(id)delegate;
-(BOOL)isValid;
-(unsigned)port;
@end


static BOOL enabled = YES; 
static BOOL disableOnAC = NO; 
static BOOL enableWhileLocked = NO;
static BOOL useProximitySensor = YES; 
static int proxMode = 1; 
static BOOL disableProxUntilMovement = YES;
static BOOL enableProxOnlyOnAC = NO;
static float proxTimeout = 3; 
static BOOL didILockIt = NO;
static BOOL prox_override = YES;
static BOOL isLocked = NO;
static BOOL pocketUsesProx = YES;
static BOOL unlockWhenOutOfPocket = YES; 
static BOOL detectPocket = YES; // DONE
static BOOL lockInPocket = YES;
static BOOL inPocket = NO;

static void didILockIt_off(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    didILockIt = NO;
}

static void didILockIt_on(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    didILockIt = YES;
}

static void proximity_override_off(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    prox_override = NO;
}

static void proximity_override_on(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    prox_override = YES;
}

static void islocked_on(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    isLocked = YES;
}

static void islocked_off(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    isLocked = NO;
}

static void inpocket_on(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    inPocket = YES;
}

static void inpocket_off(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    inPocket = NO;
}

static void reloadSettings(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    NSDictionary *prefs = [NSDictionary 
        dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist"];

    
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

    if ([prefs objectForKey:@"useProximitySensor"] != nil)
        useProximitySensor = [[prefs objectForKey:@"useProximitySensor"] boolValue];
    else
        useProximitySensor = NO;

    if ([prefs objectForKey:@"disableProxUntilMovement"] != nil)
        disableProxUntilMovement = [[prefs objectForKey:@"disableProxUntilMovement"] boolValue];
    else
        disableProxUntilMovement = YES;

    if ([prefs objectForKey:@"proxMode"] != nil)
        proxMode = [[prefs objectForKey:@"proxMode"] intValue];
    else
        proxMode = 1;

    if ([prefs objectForKey:@"enableProxOnlyOnAC"] != nil)
        enableProxOnlyOnAC = [[prefs objectForKey:@"enableProxOnlyOnAC"] boolValue];
    else
        enableProxOnlyOnAC = NO;

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

    if ([prefs objectForKey:@"pocketUsesProx"] != nil)
        pocketUsesProx = [[prefs objectForKey:@"pocketUsesProx"] boolValue];
    else
        pocketUsesProx = NO;

    //NSLog(@"FaceOff7: bb prox mode: %d", MSHookIvar<int>([%c(BKProximitySensorInterface) sharedInstance], "_currentMode"));
}

static void updateProximity_off(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    prox_override = YES;
    //if ([[%c(BKProximitySensorInterface) sharedInstance] requestedMode] != 255)
        //if (currentClient)
        //    [currentClient setRequestedMode:255];
        //[[%c(BKProximitySensorInterface) sharedInstance] requestProximityMode:255];
    prox_override = NO;
}

static void updateProximity_off_2(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    prox_override = YES;
    //if ([[%c(BKProximitySensorInterface) sharedInstance] requestedMode] != 255)
        //if (currentClient)
        //    [currentClient setRequestedMode:255];
        //[[%c(BKProximitySensorInterface) sharedInstance] requestProximityMode:255];
    [[%c(BKProximitySensorInterface) sharedInstance] disableProximityDetection];
    prox_override = NO;
}

static void updateProximity_on(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    prox_override = YES;
    if ([[%c(BKProximitySensorInterface) sharedInstance] requestedMode] != 2)
        [[%c(BKProximitySensorInterface) sharedInstance] enableProximityDetectionWithMode:2];
    prox_override = NO;
}


typedef void(*IOHIDEventSystemCallback)(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);

static Boolean (*ori_IOHIDEventSystemOpen)(IOHIDEventSystemRef, IOHIDEventSystemCallback,void *,void *,void *);
static void (*ori_IOHIDEventCallback)(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e) = NULL;

static void __IOHIDEventCallback(void *a, void *b, __IOHIDService *c, __IOHIDEvent *e)
{
    ori_IOHIDEventCallback(a, b, c, e);
    //NSLog(@"FaceOff7: __IOHIDEventCallback");
    //NSLog(@"FaceOff7: IOHIDEventCallback %d ", IOHIDEventGetType(e));
    if (IOHIDEventGetType(e) == kIOHIDEventTypeProximity)
    {
        int proximityValue = IOHIDEventGetIntegerValue(e, (IOHIDEventField)kIOHIDEventFieldProximityDetectionMask);
        //NSLog(@"FaceOff7: IOHIDEventCallback %d (proximity) %d", IOHIDEventGetType(e), proximityValue);
        if (proximityValue != 0)
            notify_post("com.lodc.ios.faceoff/proximity_enabled");
        else
            notify_post("com.lodc.ios.faceoff/proximity_disabled");
    }
}

MSHook(Boolean, IOHIDEventSystemOpen, IOHIDEventSystemRef system, IOHIDEventSystemCallback callback, void *a, void *b, void *c)
{
    NSLog(@"FaceOff7: override IOHIDEventSystemOpen %p", system);
    
    ori_IOHIDEventCallback = callback;
    MSHookFunction(callback, __IOHIDEventCallback, &ori_IOHIDEventCallback);
    return ori_IOHIDEventSystemOpen(system, callback, a, b, c);

    //return ori_IOHIDEventSystemOpen(system, __IOHIDEventCallback, a, b, c);
}


// Mode = 0    :=255 [?]
// Mode = 1    : ???
// Mode = 2    : enable?
// Mode = 255  : disable (disable touch as well)


%hook BKProximitySensorInterface
- (void)disableProximityDetection {
    //NSLog(@"FaceOff7: disableProximityDetection islocked: %@", isLocked ? @"yah" : @"naww");
    BOOL a = (didILockIt == YES || enableWhileLocked || isLocked == NO);
    BOOL pocket = (detectPocket && pocketUsesProx && unlockWhenOutOfPocket && inPocket);
    if (enabled && prox_override == NO)
          if ((useProximitySensor && a) || pocket)
                return;
    %orig;
}
%end

%ctor
{
    MSHookFunction(IOHIDEventSystemOpen, $IOHIDEventSystemOpen, &ori_IOHIDEventSystemOpen);

    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &reloadSettings, CFSTR("com.lodc.ios.faceoff/reloadSettings"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &updateProximity_off, CFSTR("com.lodc.ios.faceoff/updateProximity_off"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &updateProximity_off_2, CFSTR("com.lodc.ios.faceoff/updateProximity_off_2"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &updateProximity_on, CFSTR("com.lodc.ios.faceoff/updateProximity_on"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &didILockIt_off, CFSTR("com.lodc.ios.faceoff/didILockIt_off"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &didILockIt_on, CFSTR("com.lodc.ios.faceoff/didILockIt_on"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &proximity_override_off, CFSTR("com.lodc.ios.faceoff/proximity_override_off"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &proximity_override_on, CFSTR("com.lodc.ios.faceoff/proximity_override_on"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &islocked_off, CFSTR("com.lodc.ios.faceoff/islocked_off"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &islocked_on, CFSTR("com.lodc.ios.faceoff/islocked_on"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &inpocket_on, CFSTR("com.lodc.ios.faceoff/inpocket_on"), NULL, 0);
    CFNotificationCenterAddObserver(r, NULL, &inpocket_off, CFSTR("com.lodc.ios.faceoff/inpocket_off"), NULL, 0);
    reloadSettings(nil, nil, nil, nil, nil);
}