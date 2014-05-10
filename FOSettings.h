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
@end