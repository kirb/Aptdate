#import <Preferences/Preferences.h>
@interface AptdateListController:PSListController{}
@end
@implementation AptdateListController
-(id)specifiers{
	if(_specifiers==nil) _specifiers=[[self loadSpecifiersFromPlistName:@"Aptdate" target:self]retain];
	return _specifiers;
}
-(void)adtwitter:(id)params{
	if([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"tweetbot:"]]){
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"tweetbot:///user_profile/thekirbylover"]];
	}else if([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"tweetings:"]]){
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=thekirbylover"]];
	}else if([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"twitter:"]]){
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"twitter://user?screen_name=thekirbylover"]];
	}else{
		[[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://twitter.com/intent/follow?screen_name=thekirbylover"]];
	}
}
@end
