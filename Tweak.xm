/**
 * Aptdate - Cydia package update notifications
 *
 * By Ad@m <http://adam.hbang.ws>
 * Licensed under the GNU GPL <http://gnu.org/copyleft/gpl.html>
 * Based on SBServer by innoying <http://github.com/innoying/iOS-sbutils>
 * and MusicBanners by rpetrich <http://github.com/rpetrich/MusicBanners>
 */

#import <AppSupport/CPDistributedMessagingCenter.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BulletinBoard/BulletinBoard.h"
#define prefpath @"/var/mobile/Library/Preferences/ws.hbang.aptdate.plist"
#define alerttxt @"Aptdate"
#define alertver @"Version %@"
#define alertmsg @"An update for %@ is available."
#define alertsnd @"/System/Library/Audio/UISounds/SIMToolkitPositiveACK.caf"
#define cydiaurl @"cydia://package/%@"
#define __(key) [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/Aptdate.bundle"]localizedStringForKey:key value:key table:@"Aptdate"]
static BOOL enabled=YES;
static BOOL limitSB=NO;
static NSMutableDictionary *known=[[[NSMutableDictionary alloc]init]retain];
static int pendingAlert=0;
static NSString *pendingName;
static NSString *pendingBundle;
static NSString *pendingVersion;
static BOOL firstRun=NO;
static void ADAPShowPending();

@interface SBBulletinBannerItem:NSObject
+(SBBulletinBannerItem *)itemWithBulletin:(BBBulletin *)bulletin;
@end
@interface SBBulletinBannerController:NSObject
+(SBBulletinBannerController *)sharedInstance;
-(id)_presentBannerForItem:(SBBulletinBannerItem *)item;
@end
@interface NSSortDescriptor (thekirbylover)
+(id)sortDescriptorWithKey:(NSString *)key ascending:(BOOL)ascend;
@end

__attribute__((visibility("hidden")))
@interface ADAPProvider:NSObject<BBDataProvider>
-(NSDictionary *)handleAptdate:(NSString *)name withInfo:(NSDictionary *)info;
@end
@implementation ADAPProvider
static ADAPProvider *sharedProvider;
+(ADAPProvider *)sharedProvider{
	return [[sharedProvider retain]autorelease];
}
-(id)init{
	if((self=[super init])) sharedProvider=self;
	CPDistributedMessagingCenter *server=[CPDistributedMessagingCenter centerNamed:@"ws.hbang.aptdate.server"];
	[server runServerOnCurrentThread];
	[server registerForMessageName:@"aptdatenotify" target:self selector:@selector(handleAptdate:withInfo:)];
	return self;
}
-(NSDictionary *)handleAptdate:(NSString *)name withInfo:(NSDictionary *)info{
	[NSThread detachNewThreadSelector:@selector(_handleAptdate:) toTarget:self withObject:info];
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"status"];	
}
-(void)_handleAptdate:(NSDictionary *)info{
	NSEnumerator *updates=[[info objectForKey:@"data"]objectEnumerator];
	NSString *key;
	NSString *title;
	NSString *val;
	NSMutableArray *i;
	while((i=[updates nextObject])){
		key=[[i objectAtIndex:0]retain];
		title=[[[i objectAtIndex:2]stringByReplacingOccurrencesOfString:@"\n" withString:@""]retain];
		val=[[i objectAtIndex:1]retain];
		known=[NSMutableDictionary dictionaryWithDictionary:known];
		if([known objectForKey:key]&&[[[known objectForKey:key]objectAtIndex:1]isEqualToString:val]){
			continue;
		}else{
			pendingAlert=1;
			[pendingName release];
			pendingName=[title retain];
			[pendingBundle release];
			pendingBundle=[key retain];
			[pendingVersion release];
			pendingVersion=[val retain];
			[self performSelectorOnMainThread:@selector(dataProviderDidLoad) withObject:nil waitUntilDone:NO];
			if(!known)known=[[[NSMutableDictionary alloc]init]retain];
			[known setObject:[NSArray arrayWithObjects:pendingName,pendingVersion,nil] forKey:pendingBundle];
			NSMutableDictionary *prefs=[NSMutableDictionary dictionaryWithContentsOfFile:prefpath];
			[prefs setObject:known forKey:@"Updates"];
			[prefs writeToFile:prefpath atomically:YES];
			[prefs release];
		}
		[key release];
		[title release];
		[val release];
	}
}
-(void)dealloc{
	sharedProvider=nil;
	[super dealloc];
}
-(NSString *)sectionIdentifier{
	return @"com.saurik.Cydia";
}
-(NSArray *)sortDescriptors{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}
-(NSArray *)bulletinsFilteredBy:(unsigned)by count:(unsigned)count lastCleared:(id)cleared{
	return nil;
}
-(NSString *)sectionDisplayName{
	return alerttxt;
}
-(BBSectionInfo *)defaultSectionInfo{
	BBSectionInfo *sectionInfo=[BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit=10;
	sectionInfo.sectionID=[self sectionIdentifier];
	return sectionInfo;
}
-(void)dataProviderDidLoad{
	if(!pendingAlert)return;
	BBBulletinRequest *bulletin=[[BBBulletinRequest alloc]init];
	bulletin.sectionID=@"com.saurik.Cydia";
	bulletin.publisherBulletinID=@"ws.hbang.aptdate";
	bulletin.recordID=bulletin.bulletinID=[NSString stringWithFormat:@"ws.hbang.aptdate.banner_for_%@_ver_%@_%i",pendingBundle,pendingVersion,[[NSDate date]timeIntervalSince1970]];
	bulletin.title=alerttxt;
	bulletin.message=[NSString stringWithFormat:alertmsg,pendingName];
	bulletin.subtitle=[NSString stringWithFormat:alertver,pendingVersion];
	bulletin.date=bulletin.lastInterruptDate=[NSDate date];
	bulletin.defaultAction=[BBAction actionWithLaunchURL:[NSURL URLWithString:[NSString stringWithFormat:cydiaurl,pendingBundle]] callblock:nil];
	SystemSoundID beep;
	AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:alertsnd isDirectory:NO],&beep);
	if(beep) bulletin.sound=[BBSound alertSoundWithSystemSoundID:beep];
	beep=NULL;
	BBDataProviderAddBulletin(self,bulletin);
}
@end

%hook BBServer
-(void)_loadAllDataProviderPluginBundles{
	%orig;
	ADAPProvider *prov=[[ADAPProvider alloc]init];
	[self _addDataProvider:prov sortSectionsNow:YES];
	[prov release];
}
%end
%hook SBUIController
-(void)finishedUnscattering{
	%orig;
	if(firstRun){
		[[[UIAlertView alloc]initWithTitle:@"Thanks for installing Aptdate!" message:@"You will now receive banner notifications when there is an update available in Cydia.\nUse the Settings app to control how Aptdate works." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]show];
		firstRun=NO;
	}
}
%end

static void ADAPPrefsLoad(){
	if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
		NSDictionary *prefs=[[NSDictionary alloc]initWithContentsOfFile:prefpath];
		if([prefs objectForKey:@"Enabled"]) enabled=[[prefs objectForKey:@"Enabled"]boolValue];
		if([prefs objectForKey:@"Updates"]) known=[[prefs objectForKey:@"Updates"]retain];
		[prefs release];
	}else{
		firstRun=YES;
		[[[NSDictionary alloc]initWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],@"Enabled",
			[[NSDictionary alloc]init],@"Updates",
			nil]writeToFile:prefpath atomically:YES];
	}
}
static void ADAPPrefsUpdate(CFNotificationCenterRef center,void *observer,CFStringRef name,const void *object,CFDictionaryRef userInfo){
	ADAPPrefsLoad();
}

%ctor{
	%init;
	ADAPPrefsLoad();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,&ADAPPrefsUpdate,CFSTR("ws.hbang.aptdate/ReloadPrefs"),NULL,0);
}
