#import "FOAccelerometerHandler.h"
#import "common.h"
#import "FOSettings.h"

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
    
}
@end