#import <SpringBoardServices/SBSAccelerometer.h>
#import "common.h"

@interface FOAccelerometerHandler : NSObject <SBSAccelerometerDelegate>
+(BOOL) shouldActivate:(float)x y:(float)y z:(float)z;

-(void) start;
-(void) stop;

@property (nonatomic, retain) SBSAccelerometer *accelerometer;
@end