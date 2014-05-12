#import "common.h"

// Ok, the name is kindof a lie - it also maintains static variables too
@interface FOSettings : NSObject
+(FOSettings*) sharedInstance;
-(void) reloadSettings;

// Settings
@property (nonatomic) BOOL enabled;
@property (nonatomic) int sensitivity;
@property (nonatomic) BOOL enabledOnFaceDown;
@property (nonatomic) BOOL enabledOnFaceUp;
@property (nonatomic) BOOL detectPocket;
@property (nonatomic) BOOL pocketUsesProx;
@property (nonatomic) BOOL enableSmartCover;
@property (nonatomic) BOOL playLockSound;
@property (nonatomic) BOOL disableLSNotifications;
@property (nonatomic) BOOL disableOnAC;
@property (nonatomic) BOOL enableWhileLocked;
@property (nonatomic) BOOL useProximitySensor;
@property (nonatomic) int proxMode; // 1=standard (on/off with covered/uncovered), 2=WaveOff mode
@property (nonatomic) BOOL disableProxUntilMovement;
@property (nonatomic) float delay;
@property (nonatomic) float delayOnFaceUp;
@property (nonatomic) BOOL disableInCall;
@property (nonatomic) float proxTimeout;
@property (nonatomic) BOOL overrideSmartCover;
@property (nonatomic) BOOL enableProxOnlyOnAC;
@property (nonatomic) BOOL disableSystemSleep;
@property (nonatomic) BOOL disableSystemSleepWithProx;
@property (nonatomic) BOOL lockInPocket;
@property (nonatomic) BOOL unlockWhenOutOfPocket;
@property (nonatomic) BOOL disableProxLandscape;
@property (nonatomic) double autoDimDelay;
@property (nonatomic) double autoDimLSDelay;
@property (nonatomic) BOOL enableDimDelay;
@property (nonatomic) BOOL disableDimDelayOnAC;
@property (nonatomic) BOOL onlyLSDimDelayOnAC;
@property (nonatomic) BOOL disableInAllApps;
@property (nonatomic) BOOL disableOnHS;
@property (nonatomic) float proxDelay;
@property (nonatomic) BOOL stayOnLSIfNotifications;
@property (nonatomic) BOOL onlyTurnOnIfNotifications;
@property (nonatomic) BOOL vibrateOnActivation;

@property (nonatomic) BOOL silenceCalls;
@property (nonatomic) BOOL revertSwitches;
@property (nonatomic) BOOL enableDND;
@property (nonatomic) BOOL enableVibration;
@property (nonatomic) BOOL disableVibration;
@property (nonatomic) BOOL enableAirplaneMode;
@property (nonatomic) BOOL enableAutolock;
@property (nonatomic) BOOL enableMute;

// FlipSwitch states
@property (nonatomic) FSSwitchState lastStateOfDND;
@property (nonatomic) FSSwitchState lastStateOfVibration;
@property (nonatomic) FSSwitchState lastStateOfAirplane;
@property (nonatomic) FSSwitchState lastStateOfAutolock;
@property (nonatomic) FSSwitchState lastStateOfMute;

// Other
@property (nonatomic) BOOL isDimmed;
@property (nonatomic) BOOL actualProximityState;
@property (nonatomic) BOOL inPocket;
@property (nonatomic) BOOL wasInPocket;

@property (nonatomic) NSDate *delayBase, *unDelayBase, *proxDelayBase;
@end