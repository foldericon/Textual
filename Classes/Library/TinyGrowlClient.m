// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define GROWL_REGISTER			@"GrowlApplicationRegistrationNotification"
#define GROWL_NOTIFICATION		@"GrowlNotification"
#define GROWL_IS_READY			@"GrowlReady!"
#define GROWL_CLICKED			@"GrowlClicked!"
#define GROWL_TIMED_OUT			@"GrowlTimedOut!"
#define GROWL_CONTEXT_KEY		@"ClickedContext"

@implementation TinyGrowlClient

@synthesize delegate;
@synthesize appName;
@synthesize allNotifications;
@synthesize defaultNotifications;
@synthesize appIcon;
@synthesize clickedNotificationName;
@synthesize timedOutNotificationName;

- (void)dealloc
{
	NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
	
	[dnc removeObserver:self name:GROWL_IS_READY object:nil];
	[dnc removeObserver:self name:clickedNotificationName object:nil];
	[dnc removeObserver:self name:timedOutNotificationName object:nil];
	
	[appName release];
	[appIcon release];
	[allNotifications release];
	[defaultNotifications release];
	[clickedNotificationName release];
	[timedOutNotificationName release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (void)notifyWithType:(NSString *)type title:(NSString *)title description:(NSString *)desc
{
	[self notifyWithType:type title:title description:desc clickContext:nil sticky:NO priority:0 icon:nil];
}

- (void)notifyWithType:(NSString *)type title:(NSString *)title description:(NSString *)desc  clickContext:(id)context
{
	[self notifyWithType:type title:title description:desc clickContext:context sticky:NO priority:0 icon:nil];
}

- (void)notifyWithType:(NSString *)type
				 title:(NSString *)title
		   description:(NSString *)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky
{
	[self notifyWithType:type title:title description:desc clickContext:context sticky:sticky priority:0 icon:nil];
}

- (void)notifyWithType:(NSString *)type
				 title:(NSString *)title
		   description:(NSString *)desc
		  clickContext:(id)context
				sticky:(BOOL)sticky
			  priority:(NSInteger)priority
				  icon:(NSImage *)icon
{
	NSInteger pid = [[NSProcessInfo processInfo] processIdentifier];
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:appName forKey:@"ApplicationName"];
	
	[dic setObject:type forKey:@"NotificationName"];;
	[dic setObject:title forKey:@"NotificationTitle"];
	[dic setObject:desc forKey:@"NotificationDescription"];
	
	[dic setObject:[NSString stringWithInteger:pid] forKey:@"ApplicationPID"];
	[dic setObject:[NSString stringWithInteger:priority] forKey:@"NotificationPriority"];
	
	if (icon) {
		[dic setObject:[icon TIFFRepresentation] forKey:@"NotificationIcon"];
	}
	
	if (sticky) {
		[dic setObject:[NSNumber numberWithInteger:1] forKey:@"NotificationSticky"];
	}
	
	if (context) {
		[dic setObject:context forKey:@"NotificationClickContext"];
	}
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION object:nil userInfo:dic deliverImmediately:NO];
}

- (void)registerApplication
{
	if (NSStringIsEmpty(appName)) {
		self.appName = [[Preferences textualInfoPlist] objectForKey:@"CFBundleName"];
	}
	
	if (defaultNotifications == nil) {
		self.defaultNotifications = allNotifications;
	}
	
	NSInteger pid = [[NSProcessInfo processInfo] processIdentifier];
	
	[clickedNotificationName release];
	[timedOutNotificationName release];
	
	clickedNotificationName = [[NSString stringWithFormat:@"%@-%d-%@", appName, pid, GROWL_CLICKED] retain];
	timedOutNotificationName = [[NSString stringWithFormat:@"%@-%d-%@", appName, pid, GROWL_TIMED_OUT] retain];
	
	NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
	
	[dnc addObserver:self selector:@selector(onReady:) name:GROWL_IS_READY object:nil];
	[dnc addObserver:self selector:@selector(onClicked:) name:clickedNotificationName object:nil];
	[dnc addObserver:self selector:@selector(onTimeout:) name:timedOutNotificationName object:nil];
	
	NSImage *icon = ((appIcon) ?: [NSApp applicationIconImage]);
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:appName forKey:@"ApplicationName"];
	[dic setObject:allNotifications forKey:@"AllNotifications"];
	[dic setObject:defaultNotifications forKey:@"DefaultNotifications"];
	[dic setObject:[icon TIFFRepresentation] forKey:@"ApplicationIcon"];
	
	[dnc postNotificationName:GROWL_REGISTER object:nil userInfo:dic deliverImmediately:NO];
}

- (void)onReady:(NSNotification *)note
{
	[self registerApplication];
}

- (void)onClicked:(NSNotification *)note
{
	id context = [[note userInfo] objectForKey:GROWL_CONTEXT_KEY];
	
	if ([delegate respondsToSelector:@selector(tinyGrowlClient:didClick:)]) {
		[delegate tinyGrowlClient:self didClick:context];
	}
}

- (void)onTimeout:(NSNotification *)note
{
	id context = [[note userInfo] objectForKey:GROWL_CONTEXT_KEY];
	
	if ([delegate respondsToSelector:@selector(tinyGrowlClient:didTimeOut:)]) {
		[delegate tinyGrowlClient:self didTimeOut:context];
	}
}

@end