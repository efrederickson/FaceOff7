#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import <notify.h>

@interface FaceOff7FlipswitchToggleSwitch : NSObject <FSSwitchDataSource>
@end

@implementation FaceOff7FlipswitchToggleSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSDictionary *prefs = [NSDictionary 
        dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist"];
    if ([prefs objectForKey:@"enabled"] != nil)
        return [[prefs objectForKey:@"enabled"] boolValue] ? FSSwitchStateOn : FSSwitchStateOff;
    else
        return FSSwitchStateOn;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
   if (newState == FSSwitchStateIndeterminate)
        return;
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist"];
    [prefs setObject:[NSNumber numberWithBool:newState] forKey:@"enabled"];
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist" atomically:YES];
    notify_post("com.lodc.ios.faceoff/reloadSettings");
}

@end