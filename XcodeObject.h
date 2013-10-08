
//  XcodeObject.h  XcodeProjReader
//  Created by Alex Gray on 10/8/13.

#import <Cocoa/Cocoa.h>

@interface XcodeObject : NSObject <NSMutableCopying>

+ (instancetype) objectWithName:(NSString*)n
									uuid:(NSString*)uuid;

- (void)  	 		   setObject:(id)x
				 forKeyedSubscript:(id<NSCopying>)k;
- (id) objectForKeyedSubscript:(id)k;

@property (copy) 		NSString * uuid, * name;
@property (readonly)  NSImage * icon;
@property (readonly) NSString * humanUTI;
@property      NSMutableArray * children;
@property 						id   parent;

@end

NS_INLINE NSString* humanReadableFileTypeForFileExtension (NSString *extension) {
	CFStringRef fileUTI 			= UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
	NSString *utiDescription	= (__bridge NSString*)UTTypeCopyDescription(fileUTI);
	return 	CFRelease(fileUTI), utiDescription;
}
