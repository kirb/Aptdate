/**
 * Aptdate - Cydia package update notifications
 *
 * WARNING: Code is /very/ ugly; expect a rewrite soon
 *
 * By Ad@m <http://adam.hbang.ws>
 * Licensed under the GNU GPL <http://gnu.org/copyleft/gpl.html>
 */

#include <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
static NSString *outputForShellCommand(NSString *cmd);
static BOOL inItem=NO;
static NSString *inTag=@"";
static NSMutableArray *data;
static NSMutableDictionary *current;
static NSAutoreleasePool *p;

@interface NSTextCheckingResult:NSArray
-(NSRange)rangeAtIndex:(int)index;
@end
@interface NSRegularExpression:NSObject
+(NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern options:(int)opt error:(id)err;
-(NSTextCheckingResult *)matchesInString:(NSString *)str options:(int)opt range:(NSRange)range;
-(NSRange)rangeOfFirstMatchInString:(NSString *)str options:(int)opt range:(NSRange)range;
@end
@protocol NSXMLParserDelegate <NSObject>
@optional
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
@end
@interface ADAPParserDelegate:NSObject<NSXMLParserDelegate>
//So... it's come to this.
@end
@implementation ADAPParserDelegate
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elname namespaceURI:(NSString *)space qualifiedName:(NSString *)qualified attributes:(NSDictionary *)attribs{
	if(!inItem&&[elname isEqualToString:@"item"]){
		inItem=YES;
		current=[[NSMutableDictionary alloc]init];
	}else if(inItem){
		if([elname isEqualToString:@"title"]||[elname isEqualToString:@"feedburner:origLink"]){
			inTag=[elname copy];
		}
	}
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elname namespaceURI:(NSString *)space qualifiedName:(NSString *)qualified{
	inTag=@"";
	if([elname isEqualToString:@"item"]){
		inItem=NO;
		[data addObject:current];
	}else if([elname isEqualToString:@"channel"]){
		inItem=NO;
		printf("Getting list of installed packages...\n");
		NSString* installed=outputForShellCommand(@"/usr/bin/aptitude search -F '%p %v' --disable-columns ~i");
		printf("Comparing list...\n");
		NSEnumerator *enu=[[installed componentsSeparatedByString:@"\n"]objectEnumerator];
		NSArray *pkg;
		NSMutableDictionary *list=[[NSMutableDictionary alloc]init];
		NSString *i;
		while((i=[enu nextObject])){
			pkg=[i componentsSeparatedByString:@" "];
			if([pkg count]==2&&![[pkg objectAtIndex:1]isEqualToString:@"<none>"]) [list setObject:[pkg objectAtIndex:1] forKey:[pkg objectAtIndex:0]];
		}
		enu=[data objectEnumerator];
		NSMutableArray *updates=[[NSMutableArray alloc]init];
		NSString *title=@"";
		NSString *ver=@"";
		NSString *bundleid=@"";
		NSError *err=NULL;
		NSRegularExpression *titleRegex=[objc_getClass("NSRegularExpression") regularExpressionWithPattern:@"^(.*) (([0-9]+)(((\\.|-)[0-9]+)*)?) \\((.*)\\)$" options:0 error:err];
		NSRegularExpression *verRegex=[objc_getClass("NSRegularExpression") regularExpressionWithPattern:@"^http:\\/\\/cydiaupdates.net\\/pkg\\/(.*)$" options:0 error:err];
		NSTextCheckingResult *results;
		NSDictionary *j;
		while((j=[enu nextObject])){
			if(err==NULL){
				if(![j objectForKey:@"title"]||![j objectForKey:@"feedburner:origLink"]){
					continue;
				}
				results=[titleRegex matchesInString:[j objectForKey:@"title"] options:0 range:NSMakeRange(0,[[j objectForKey:@"title"]length])];
				for(NSTextCheckingResult *result in results){
					title=[[j objectForKey:@"title"]substringWithRange:[result rangeAtIndex:1]];
					ver=[[j objectForKey:@"title"]substringWithRange:[result rangeAtIndex:2]];
				}
				err=NULL;
				results=[verRegex matchesInString:[j objectForKey:@"feedburner:origLink"] options:0 range:NSMakeRange(0,[[j objectForKey:@"feedburner:origLink"]length])];
				if(err==NULL) for(NSTextCheckingResult *result in results) bundleid=[[j objectForKey:@"feedburner:origLink"]substringWithRange:[result rangeAtIndex:1]];
				if([list objectForKey:bundleid]&&![[list objectForKey:bundleid]isEqualToString:ver]) [updates addObject:[[NSArray alloc]initWithObjects:bundleid,ver,title,nil]];
			}
		}
		printf("%u update(s) were found.\n",[updates count]);
		#if DEBUG
		NSLog(@"updates = %@",updates);
		#endif
		if([updates count]>0){
			printf("Posting to SpringBoard...\n");
			[[CPDistributedMessagingCenter centerNamed:@"ws.hbang.aptdate.server"]sendMessageAndReceiveReplyName:@"aptdatenotify" userInfo:[NSDictionary dictionaryWithObject:updates forKey:@"data"]];
		}
		printf("\n");
		[p drain];
	}
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)data{
	if(([inTag isEqualToString:@"title"]||[inTag isEqualToString:@"feedburner:origLink"])&&!([data isEqualToString:@""]||[data isEqualToString:@"\n"]||[data isEqualToString:@"<"]||[data isEqualToString:@">"]))[current setObject:data forKey:inTag];
}
@end

int main(int argc,char **argv,char **envp){
	p=[[NSAutoreleasePool alloc]init];
	data=[[NSMutableArray alloc]init];
	NSDateFormatter *format=[[NSDateFormatter alloc]init];
	[format setDateFormat:@"dd/MM/yy HH:mm:ss zzz"];
	printf("Update check initiated at %s\n",[[format stringFromDate:[NSDate date]]UTF8String]);
	[format release];
	//if(system("/usr/bin/whoami 2>&1|/bin/grep -E ^root$ 2>&1>/dev/null")!=0){
	/*if(getuid()!=0){
		fprintf(stderr,"Must be run as root\n");
		return 1;
	}*/
	if(argc>1&&strcmp(argv[1],"--dry-run")==0){
		printf("Dry run mode activated\n\n");
		[[CPDistributedMessagingCenter centerNamed:@"ws.hbang.aptdate.server"]sendMessageAndReceiveReplyName:@"aptdatenotify" userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSArray arrayWithObjects:@"ws.hbang.aptdate",@"1.2",@"Aptdate"]] forKey:@"data"]];
	}else{
		printf("Downloading list from CydiaUpdates...\n");
		NSXMLParser *rss=[[NSXMLParser alloc]initWithContentsOfURL:[NSURL URLWithString:@"http://feeds.feedburner.com/CydiaupdatesAllSections?format=xml"]];
		[rss setDelegate:[[ADAPParserDelegate alloc]init]];
		[rss parse];
		[[NSRunLoop currentRunLoop]runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:120]];
	}
	return 0;
}

//adapted from CyDelete (pardon the pun)
static NSString *outputForShellCommand(NSString *cmd){
	FILE *fp;
	char dat[1024];
	NSString *finalRet=@"";
	fp=popen([cmd UTF8String],"r");
	if(fp==NULL) return nil;
	while(fgets(dat,1024,fp)!=NULL) finalRet=[finalRet stringByAppendingString:[NSString stringWithUTF8String:dat]];
	if(pclose(fp)!=0) return nil;
	return finalRet;
}
