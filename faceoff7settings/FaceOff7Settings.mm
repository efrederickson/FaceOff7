#import <Preferences/Preferences.h>

@interface FaceOff7SettingsListController: PSListController {
}
@end

@implementation FaceOff7SettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"FaceOff7Settings" target:self] retain];
	}
	return _specifiers;
}

-(void) openTwitter
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=mlnlover11"]];
}

-(void) openGithub
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"github.com/mlnlover11"]];
}

-(void) sendEmail
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:elijah.frederickson@gmail.com?subject=FaceOff7"]];
}
-(void) sendEmail_FR
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:elijah.frederickson@gmail.com?subject=FaceOff7%20Feature%20Request"]];
}

-(void) donatePaypal
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=elijah%2efrederickson%40gmail%2ecom&lc=US&item_name=FaceOff%20Donations&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted"]];
    
}

-(void) donateBitcoin
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://coinbase.com/checkouts/c1efaa7447e82b9a8078dd69a7151f3a"]];
}

@end

@interface FOTogglesListController: PSListController {
}
@end

@implementation FOTogglesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Toggles" target:self] retain];
	}
	return _specifiers;
}
@end

@interface FOPocketSettingsListController: PSListController {
}
@end

@implementation FOPocketSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"pocketSettings" target:self] retain];
	}
	return _specifiers;
}
@end

@interface FOHelpListController: PSListController {
}
@end

@implementation FOHelpListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"FOHelp" target:self] retain];
	}
	return _specifiers;
}
@end

@interface FOLockUnlockSettingsListController: PSListController {
}
@end

@implementation FOLockUnlockSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"LockUnlockOptions" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
