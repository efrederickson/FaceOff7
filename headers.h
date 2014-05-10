// Please, add more interfaces and whatever as needed.

#import <IOKit/IOReturn.h>

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
- (void)setExpectsFaceContact:(_Bool)arg1;
- (void)setExpectsFaceContact:(_Bool)arg1 inLandscape:(_Bool)arg2;
- (_Bool)expectsFaceContactInLandscape;
- (_Bool)expectsFaceContact;
- (void)setProximityEventsEnabled:(_Bool)arg1;
- (_Bool)proximityEventsEnabled;
- (void)_proximityChanged:(id)arg1;

-(void)_lockButtonDownFromSource:(int)source;
-(void)_lockButtonUpFromSource:(int)source;

- (int)_frontMostAppOrientation;

//- (void)_smartCoverDidClose:(struct __IOHIDEvent *)arg1;
//- (void)_smartCoverDidOpen:(struct __IOHIDEvent *)arg1;
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

