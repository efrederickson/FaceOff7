/*
 This file contains #define's and other static objects used throughout the project
 
 */


// A bunch of shared headers used throughout FaceOff7
#import "headers.h"
#import <IOKit/IOReturn.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchState.h"

#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.lodc.ios.faceoff.settings.plist"

// Refresh rate of the accelerometer
#define ACCEL_UPDATE_INTERVAL (0.5)


// IOKit lib stuff to disable system sleep

typedef uint32_t IOPMAssertionID;
enum {
    kIOPMAssertionLevelOff = 0,
    kIOPMAssertionLevelOn = 255
};
typedef uint32_t IOPMAssertionLevel;

extern IOReturn IOPMAssertionCreate(
    CFStringRef AssertionType,
    IOPMAssertionLevel AssertionLevel,
    IOPMAssertionID *AssertionID);

extern IOReturn IOPMAssertionRelease(
    IOPMAssertionID AssertionID);
// THE sleep assertion
IOPMAssertionID noSleepAssertion;

// MobileGestalt stuff for UDID
/* extern "C" */
    CFPropertyListRef MGCopyAnswer(CFStringRef property);


// common.m functions
void vibrate();
NSString *getUDID();
NSString* getCurrentApp();
void ApplyToggles(BOOL);
void changeBacklight(float newValue);

BOOL disableLLSleep();
BOOL restoreLLSleep();