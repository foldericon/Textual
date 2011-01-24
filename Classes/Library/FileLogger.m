// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface FileLogger (Private)
- (NSString *)buildFileName;
@end

@implementation FileLogger

@synthesize client;
@synthesize channel;
@synthesize fileName;
@synthesize file;

- (void)dealloc
{
	[self close];
	[fileName release];
	[super dealloc];
}

- (void)close
{
	if (file) {
		[file closeFile];
		[file release];
		
		file = nil;
	}
}

- (void)writeLine:(NSString *)s
{
	[self open];
	
	if (file) {
		s = [s stringByAppendingString:@"\n"];
		
		NSData *data = [s dataUsingEncoding:client.encoding];
		
		if (data == nil) {
			data = [s dataUsingEncoding:client.config.fallbackEncoding];
			
			if (data == nil) {
				data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			}
		}
		
		if (data) {
			[file writeData:data];
		}
	}
}

- (void)reopenIfNeeded
{
	if (NSStringIsEmpty(fileName) || [fileName isEqualToString:[self buildFileName]] == NO) {
		[self open];
	}
}

- (void)open
{
	[self close];
	
	[fileName release];
	fileName = [[self buildFileName] retain];
	
	NSString *dir = [fileName stringByDeletingLastPathComponent];
	
	BOOL isDir = NO;
	
	if ([TXNSFileManager() fileExistsAtPath:dir isDirectory:&isDir] == NO) {
		[TXNSFileManager() createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	if ([TXNSFileManager() fileExistsAtPath:fileName] == NO) {
		[TXNSFileManager() createFileAtPath:fileName contents:[NSData data] attributes:nil];
	}
	
	[file release];
	file = [[NSFileHandle fileHandleForUpdatingAtPath:fileName] retain];
	
	if (file) {
		[file seekToEndOfFile];
	}
}

- (NSString *)buildFileName
{
	NSString *base = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	
	static NSDateFormatter *format = nil;
	
	if (format == nil) {
		format = [NSDateFormatter new];
		[format setDateFormat:@"yyyy-MM-dd"];
	}
	
	NSString *date = [format stringFromDate:[NSDate date]];
	NSString *name = [[client name] safeFileName];
	
	if (!channel) {
		return [base stringByAppendingFormat:@"/%@/Console/%@.txt", name, date];
	} else if ([channel isTalk]) {
		return [base stringByAppendingFormat:@"/%@/Queries/%@/%@.txt", name, [[channel name] safeFileName], date];
	} else {
		return [base stringByAppendingFormat:@"/%@/Channels/%@/%@.txt", name, [[channel name] safeFileName], date];
	}
	
	return nil;
}

@end