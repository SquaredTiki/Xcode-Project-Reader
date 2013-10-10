
//  XCDProjectCoordinator.h - XcodeProjReader
//  Created by Joshua Garnham on 20/06/2011. Edited by Alec Gray 10/7/13

#import <Cocoa/Cocoa.h>

@class XcodeObject;
@interface XCDProjectCoordinator : NSObject

// The root object which has references to the main group, configuration list's and targets
@property 					 NSDictionary * rootObject;
 // The main group is the highest group, it has the name of you proj. itself and contains all the subfold, e.g Classes, Other Sources, Resrcs etc.
@property (weak)			 NSDictionary * mainGroup;
@property			NSMutableDictionary * sourceData; 	// The original dictionary of the data from the xcode project
@property				 NSMutableString * dataString; 	// The orgiginal data string of the data from the xcode project
@property 								 int   waitTime, i; 	// Internal
@property 								BOOL   isDropbox; 	// Tells the project that it is accessing dropbox

// An array of nested dictionaries with value of parent, children, name and uuid.
//	Used generally only in conjunction with NSOutlineView which requires nested dictionaries with a weak reference to the parent object
@property 				  				NSMutableArray * files;
@property 				 						NSString * filePath,						// The location of the xcode project
																* originalDropboxPath;
@property (weak) 	 							NSString * rootObjectUUID,				// The UUID of the root object
																* mainGroupUUID;				// The UUID of the main group
@property (nonatomic,unsafe_unretained) 	   id	  exportDelegate;				// Delegate keeps track when exp. the proj.

- (void) parseXcodeProject;
-   (id) initWithProjectAtPath:	(NSString *)path;
- (void) removeItemWithUUID:	   (NSString*)uuid;
- (BOOL) addGroupWithTitle:		(NSString*)title 			  toItemWithUUID:(NSString*)parentUUID;
- (BOOL) addFileWithRelativePath:(NSString*)relPath asChildToItemWithUUID:(NSString*)parentItemUUID;
- (BOOL) newProjectAtPath:			(NSString*)path 			  withFrameworks:(NSArray*)frameworks 	     sourceFiles:(NSArray*)sourceFiles
																          supportingFiles:(NSArray*)supportingFiles oniOSVersion:(NSString*)iOSVersion; // iOS only

-      (NSArray*) uuidsOfChildrenOfItemWithUUID: (NSString*)uuid;
-    (NSUInteger) numberOfChildrenOfItemWithUUID:(NSString*)uuid;
- (XcodeObject*) itemWithUUID:						 (NSString*)uuid;
-     (NSString*) nameOfItemWithUUID:				 (NSString*)uuid;
- (XcodeObject*) parentOfItemWithUUID:			 (NSString*)uuid;

- (BOOL) exportFilesFromProjectIntoFolderAtPath:(NSString*)destinationPath;

@end

typedef NS_ENUM (NSInteger, XCDBuildPhase) 	{ 	XCDSourceBuildPhase, 		XCDFrameworksBuildPhase };
typedef NS_ENUM (NSInteger, XCDExportStatus) { 	XCDExportStatusBegun, 		XCDExportStatusPreProcessing,
																XCDExportStatusProcessing, XCDExportStatusComplete,
																XCDExportStatusFailure };

NS_INLINE NSUInteger numberOfOccurrencesOfStringInString (NSString *needle, NSString *haystack) {
	const char * rawNeedle 	= needle.UTF8String, * rawHaystack = haystack.UTF8String;
	NSUInteger needleLen = strlen(rawNeedle), haystackLen = strlen(rawHaystack), needleCt = 0, needleIdx = 0, idx;
	for (idx = 0; idx < haystackLen;  ++idx) 	{	const char thisChar = rawHaystack[idx];
		if (thisChar != rawNeedle[needleIdx])   	needleIdx = 0;  		// they don't match; reset the needle index
		if (thisChar == rawNeedle[needleIdx]) 	{  needleIdx++;    		// resetting the needle might be the beginning of another match // char match
			if (needleIdx >= needleLen) { needleCt++; needleIdx = 0;	}	// we completed finding the needle
}	} return needleCt; }

@interface NSObject (XCDProjectCoordinatorExportStatusDelegate)
- (void) statusChangedTo:(XCDExportStatus)status withFile:(NSString*)filePath;
@end


//<XCDProjectCoordinatorExportStatusDelegate> 		  exportDelegate;

//@protocol XCDProjectCoordinatorExportStatusDelegate <NSObject>
//- (void) statusChangedTo:(XCDExportStatus)status withFile:(NSString*)filePath;
//@end

//@property 	NSString *originalDropboxPath; // The dropbox location of the xcode project
//	NSString *filePath;
//@property (weak)	NSString * rootObjectUUID;
//@property (weak)		NSString * mainGroupUUID;
//	NSMutableArray *files;
