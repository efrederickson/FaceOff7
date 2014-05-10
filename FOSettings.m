#include "FOSettings.h"
#import "common.h"

@implementation FOSettings
+(id)sharedInstance
{
    static FOSettings *instance;
    if (!instance)
    {
        instance = [[FOSettings alloc] init];
        [instance reloadSettings];
    }
    return instance;
}

-(id) init
{
    self = [super init];
    
    self.isDimmed = NO;
    
    return self;
}

-(void) reloadSettings
{
    // Load the settings file
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE];
    
    // This loads settings, defaulting to YES if the key doesn't exist in the file
    self.enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
}
@end