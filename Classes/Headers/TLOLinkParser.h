// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

@interface TLOLinkParser : NSObject
+ (NSArray *)locatedLinksForString:(NSString *)body;
+ (NSArray *)bannedURLRegexLineTypes;
@end