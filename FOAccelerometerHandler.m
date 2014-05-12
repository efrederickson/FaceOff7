#import "FOAccelerometerHandler.h"
#import "common.h"
#import "FOSettings.h"
#import <objc/runtime.h>

@implementation FOAccelerometerHandler

+(BOOL) shouldActivate:(float)x y:(float)y z:(float)z
{
    // Cache it here so it is (minutely) and easier to read
    int sensitivity = [FOSettings sharedInstance].sensitivity;
    
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
    
    if ([FOSettings sharedInstance].isDimmed)
    {
        rX += 0.05;
        rY += 0.05;
        rZ += 0.05;
    }
    
    if ((x < rX && x > -rX) &&
        (y < rY && y > -rY) &&
        (z > rZ) && [FOSettings sharedInstance].enabledOnFaceDown) // face down
        return YES;
    
    if ((x < rX && x > -rX) &&
        (y < rY && y > -rY) &&
        (z < -rZ) && [FOSettings sharedInstance].enabledOnFaceUp) // face up
        return YES;
    
    /*
     
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
     */
    
    return NO;
}

-(void) start
{
    if (!self.accelerometer)
    {
        self.accelerometer = [[SBSAccelerometer alloc] init];
        self.accelerometer.updateInterval = ACCEL_UPDATE_INTERVAL; // seconds
        self.accelerometer.xThreshold = 0.01; //0.2
        self.accelerometer.yThreshold = 0.01;
        self.accelerometer.zThreshold = 0.01;
        self.accelerometer.orientationEventsEnabled = NO;
        self.accelerometer.delegate = self;
    }
    self.accelerometer.accelerometerEventsEnabled = YES;
    
    //[d release];
    //[theAcc _checkIn];
}

-(void) stop
{
    self.accelerometer.accelerometerEventsEnabled = NO;
    
}

-(void) accelerometer:(SBSAccelerometer *)accelerometer
didAccelerateWithTimeStamp:(NSTimeInterval)timeStamp x:(float)x
                    y:(float)y
                    z:(float)z eventType:(unsigned)type
{
    if ([FOSettings sharedInstance].enabled == NO ||
        ([FOSettings sharedInstance].disableOnAC == YES && [[objc_getClass("SBUIController") sharedInstance] isOnAC]) ||
        ([FOSettings sharedInstance].disableInCall && [[objc_getClass("SBTelephonyManager") sharedTelephonyManager] inCall]) ||
        ([FOSettings sharedInstance].disableInAllApps && ![getCurrentApp() isEqual:@""]) ||
        ([FOSettings sharedInstance].disableOnHS && ([getCurrentApp() isEqual:@""] && ![[objc_getClass("SBLockStateAggregator") sharedInstance] hasAnyLockState]))
        )
    {
        [FOSettings sharedInstance].delayBase = nil;
        [FOSettings sharedInstance].unDelayBase = nil;
        [FOSettings sharedInstance].proxDelayBase = nil;
        return;
    }
    
    NSDictionary *blacklist = [NSDictionary
                               dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff7.blacklist.plist"];
    NSString *prefix = @"Blacklist-";
    if ([blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] != nil)
        if ([[blacklist objectForKey: [prefix stringByAppendingString:getCurrentApp()]] boolValue])
        {
            [FOSettings sharedInstance].delayBase = nil;
            [FOSettings sharedInstance].unDelayBase = nil;
            [FOSettings sharedInstance].proxDelayBase = nil;
            return;
        }
    
    BOOL should = [FOAccelerometerHandler shouldActivate:x y:y z:z];
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

}
@end