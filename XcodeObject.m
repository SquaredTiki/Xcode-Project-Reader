//
//  XcodeObject.m
//  XcodeProjReader
//
//  Created by Alex Gray on 10/8/13.
//
//

#import "XcodeObject.h"

@implementation XcodeObject @synthesize icon = _icon, humanUTI = _humanUTI;
static NSArray *iconMap = nil;

+ (instancetype) objectWithName:(NSString*)n uuid:(NSString*)uuid {
	XcodeObject *x = self.new;
    x.name = n;
    x.uuid = uuid;
    x.children = @[].mutableCopy;
    return x;   //	x.parent = NSNull.null;
}

-(id) mutableCopyWithZone: (NSZone *)z	{
    XcodeObject *cp = [XcodeObject allocWithZone:z];
    cp.name = _name;
    cp.uuid = _uuid;
    //cp.parent = _parent;
    // if (_catchall.count) cp.catchall = _catchall;
    cp.children = _children ?: @[].mutableCopy;
    return cp;
}

+ (NSSet*) keyPathsForValuesAffectingIcon {
    return [NSSet setWithArray:@[@"name"]];
}

- (void) setValue:(id)v forUndefinedKey:(NSString*)k {
    NSLog(@"need to set V for udk:%@", k);
}

- (id) valueForUndefinedKey:(NSString*)k  {
    return  nil;
}

- (void) setObject:(id)x forKeyedSubscript:(id <NSCopying>)k 	{
	if ([self respondsToSelector:NSSelectorFromString((NSString*)k)]) {
        [self setValue:x forKey:(NSString*)k];
    }
}

- (id)objectForKeyedSubscript:(id)k {
    return [self valueForKey:(NSString*)k];
}

- (NSImage*) icon {
    if (!_name) return [NSImage imageNamed:NSImageNameRefreshTemplate];
    
    NSString *ext = _name.pathExtension;

	return _icon = _icon ?
	 : [@[@"app"] containsObject:ext] ? [NSImage imageNamed:@"app"]
	 : [@[@"xcodeproj"] containsObject:ext] ? [NSImage imageNamed:@"project"]
	 : [@[@"framework"] containsObject:ext] ? [NSImage imageNamed:@"framework"]
	 : [@[@"h"] containsObject:ext] ? [NSImage imageNamed:@"header"]
	 : [@[@"m"] containsObject:ext] ? [NSImage imageNamed:@"source"]
	 : [self.name rangeOfString:@"."].location != NSNotFound ? [NSWorkspace.sharedWorkspace iconForFileType:ext]
	 :	[NSImage imageNamed:@"group"];	//	 : [NSImage imageNamed:NSImageNameCaution]; //	 : [ext 		 isEqualToString:@""]
}
- (NSString*) humanUTI {
    return  _humanUTI = _humanUTI ?: humanReadableFileTypeForFileExtension(self.name.pathExtension) ?: @"Folder";
}

@end



//	[self willChangeValueForKey:k];	if (!_catchall) _catchall = NSMutableDictionary.new;	_catchall[k] = v; 	[self didChangeValueForKey:k];
//return !_catchall || ![_catchall objectForKey:k] ? _catchall[k] : nil;  }
//	else { if(!_catchall)  _catchall = NSMutableDictionary.new; _catchall[k] = x; }
//	return [self respondsToSelector:NSSelectorFromString((NSString*)k)] ? [self valueForKey:(NSString*)k] :
//																			   !_catchall ? nil : _catchall[k];
//}
