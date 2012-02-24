//
//  XCDProjectCoordinator.m
//  XcodeProjReader
//
//  Created by Joshua Garnham on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface WeakReference : NSObject {
    id parent;
}
+(id)weakReferenceWithParent:(id)parent;
-(void)setParent:(id)_parent;
-(id)parent;
@end
@implementation WeakReference
+(id)weakReferenceWithParent:(id)parent {
    id weakRef=[[WeakReference alloc] init];
    [weakRef setParent:parent];
    return weakRef;
}
-(void)setParent:(id)_parent {
    parent=_parent;
}
-(id)parent {
    return parent;
}

@end

#import "XCDProjectCoordinator.h"

@interface XCDProjectCoordinator (Private)
- (BOOL)_removeFileWithUUID:(NSString *)uuid fromBuildPhase:(XCDBuildPhase)buildPhase;
NSUInteger numberOfOccurrencesOfStringInString(NSString * needle, NSString * haystack);
@end

@implementation XCDProjectCoordinator
@synthesize files, filePath, rootObjectUUID, mainGroupUUID, exportDelegate, originalDropboxPath;

#pragma mark - Initiazlization

- (id)initWithProjectAtPath:(NSString *)path {
    self = [super init];
    if (self) {
        // Initialization code here.
        filePath = path;
    }
    return self;
}

#pragma mark - Additions

NSUInteger numberOfOccurrencesOfStringInString(NSString * needle, NSString * haystack) {
    const char * rawNeedle = [needle UTF8String];
    NSUInteger needleLength = strlen(rawNeedle);
	
    const char * rawHaystack = [haystack UTF8String];
    NSUInteger haystackLength = strlen(rawHaystack);
	
    NSUInteger needleCount = 0;
    NSUInteger needleIndex = 0;
    for (NSUInteger index = 0; index < haystackLength; ++index) {
        const char thisCharacter = rawHaystack[index];
        if (thisCharacter != rawNeedle[needleIndex]) {
            needleIndex = 0; //they don't match; reset the needle index
        }
		
        //resetting the needle might be the beginning of another match
        if (thisCharacter == rawNeedle[needleIndex]) {
            needleIndex++; //char match
            if (needleIndex >= needleLength) {
                needleCount++; //we completed finding the needle
                needleIndex = 0;
            }
        }
    }
	
    return needleCount;
}

NSString *lettersAndNumbers = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
NSString *numbers = @"123456789";

- (NSString *)getRandomStringWithLength:(int)len alphaNumeric:(BOOL)alphaNumeric {
	
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
	
    for (int x=0; x<len; x++) {
        if (alphaNumeric)
            [randomString appendFormat:@"%c", [lettersAndNumbers characterAtIndex:arc4random()%[lettersAndNumbers length]]];
        else
            [randomString appendFormat:@"%c", [numbers characterAtIndex:arc4random()%[numbers length]]];       
	}
    
	return randomString;
}

#pragma mark - Supporting Methods

- (void)enumerateChildrenWithObjects:(NSArray *)objects andMainData:(NSDictionary *)mainData {
	for (NSString *element in objects) {
		NSDictionary *elementDictionary = [mainData valueForKey:element];
		NSString *name = [elementDictionary valueForKey:@"name"]; // IF HAS NAME IT IS GROUP! OTHERWISE IS FILE AND USE PATH
		NSString *path = [[elementDictionary valueForKey:@"path"] lastPathComponent];
		
		NSMutableString *gapping = [NSMutableString stringWithString:@""];
		for(int x=0;x<i;x++) { [gapping appendString:@"\t"]; }
		
		if (name && [[name pathExtension] isEqualToString:@""]) {
			[dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, name, element]];
			NSArray *children = [elementDictionary valueForKey:@"children"];
			if (children) {
				i++;
				[self enumerateChildrenWithObjects:children andMainData:mainData];
			}
		} else if (name) {
			[dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, name, element]];
		} else if (path && [[path pathExtension] isEqualToString:@""]) {
			[dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, path, element]];
			NSArray *children = [elementDictionary valueForKey:@"children"];
			if (children) {
				i++;
				[self enumerateChildrenWithObjects:children andMainData:mainData];
			}
		} else if (path) {
			[dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, path, element]];
		}
	}
	i--;
}

- (NSDictionary *)addChildrenTo:(NSDictionary *)dictionary withString:(NSString *)searchString andCurrentRange:(NSRange)currentRange {
	NSInteger numToSkip = 100;
	NSArray *eachLine = [searchString componentsSeparatedByString:@"\n"];
	NSMutableDictionary *newDictionary = [dictionary mutableCopy];
	NSRange currentLineRange = NSMakeRange(currentRange.location, 0);
	for (NSString *line in eachLine) {
		NSInteger newLoc = currentLineRange.location + line.length + 1; 
		currentLineRange = NSMakeRange(newLoc, 0);
		if ([eachLine indexOfObject:line] == eachLine.count-1)
			break;
		NSInteger numOfTabs = numberOfOccurrencesOfStringInString(@"\t", line);
		NSString *nextLine = [eachLine objectAtIndex:[eachLine indexOfObject:line]+1];
		NSInteger numOfTabsOnNextLine = numberOfOccurrencesOfStringInString(@"\t", nextLine);
        
		if (numOfTabs > numToSkip) {
			continue;
		} else if (numOfTabs < numToSkip) {
			numToSkip = 100;
		}
		if (waitTime > 0) {
			waitTime--;
			return newDictionary;
		}
		if (numOfTabsOnNextLine > numOfTabs) {
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [NSMutableArray array], @"children", uuid, @"uuid", [WeakReference weakReferenceWithParent:newDictionary], @"parent", nil];
			NSString *hereOn = [dataString substringFromIndex:currentLineRange.location];
            
			dictionary = [self addChildrenTo:dictionary withString:hereOn andCurrentRange:currentLineRange];
			
			numToSkip = numOfTabs; // Skip anything greater than the current num of tabs until it comes down
			
			NSMutableArray *children = [newDictionary valueForKey:@"children"];
			[children addObject:dictionary];
			[newDictionary setObject:children forKey:@"children"];
            
		} else if (numOfTabsOnNextLine < numOfTabs) {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSDictionary *child = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [NSMutableArray array], @"children", uuid, @"uuid", [WeakReference weakReferenceWithParent:newDictionary], @"parent", nil];
			
			NSMutableArray *children = [newDictionary valueForKey:@"children"];
			[children addObject:child];
			[newDictionary setObject:children forKey:@"children"];
			
			waitTime = numOfTabs - numOfTabsOnNextLine - 1;
			
			return newDictionary;
		} else {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSDictionary *child = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [NSMutableArray array], @"children", uuid, @"uuid", [WeakReference weakReferenceWithParent:newDictionary], @"parent", nil];
			
			NSMutableArray *children = [newDictionary valueForKey:@"children"];
			[children addObject:child];
			[newDictionary setObject:children forKey:@"children"];
		}
	}
	NSLog(@"FAILURE");
	return newDictionary; 
}

#pragma mark - Parsing

- (void)parseIt {		
	NSArray *eachLine = [dataString componentsSeparatedByString:@"\n"];
	NSRange currentLineRange = NSMakeRange(0, 0);
	for (NSString *line in eachLine) {
		NSInteger newLoc = currentLineRange.location + line.length + 1; 
		currentLineRange = NSMakeRange(newLoc, 0);
		if ([eachLine indexOfObject:line] == eachLine.count-1)
			break;
		NSInteger numOfTabs = numberOfOccurrencesOfStringInString(@"\t", line);
		NSString *nextLine = [eachLine objectAtIndex:[eachLine indexOfObject:line]+1];
		NSInteger numOfTabsOnNextLine = numberOfOccurrencesOfStringInString(@"\t", nextLine);
		if (numOfTabs == 0 && numOfTabsOnNextLine > numOfTabs) {
			// Folder, I am
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [NSMutableArray array], @"children", uuid, @"uuid", nil, @"parent", nil];
			NSString *hereOn = [dataString substringFromIndex:currentLineRange.location];
			dictionary = [self addChildrenTo:dictionary withString:hereOn andCurrentRange:currentLineRange];
			[files addObject:dictionary];
		} else if (numOfTabs == 0) {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [NSMutableArray array], @"children", uuid, @"uuid", nil, @"parent", nil];	
			[files addObject:dictionary];
		}
	}
}

- (void)parseXcodeProject {
    // Clean up
    i = 0;
	files = [[[NSMutableArray alloc] init] retain];
	dataString = [[NSMutableString stringWithString:@""] retain];
    
    NSString *path = filePath;
    
	NSString *projectFilePath;
    
    if (!isDropbox)
        projectFilePath = [path stringByAppendingFormat:@"/project.pbxproj"];
    else
        projectFilePath = path;
	
	NSDictionary *data = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:projectFilePath]];
    
	sourceData = [[NSMutableDictionary dictionaryWithDictionary:data] retain];
    
	NSDictionary *objects = [data valueForKey:@"objects"];
    
    rootObjectUUID = [data valueForKey:@"rootObject"];
    rootObject = [objects valueForKey:rootObjectUUID];
    mainGroupUUID = [rootObject valueForKey:@"mainGroup"];
    mainGroup = [objects valueForKey:mainGroupUUID];
    
	NSArray *children = [mainGroup valueForKey:@"children"];
	if (children)
		[self enumerateChildrenWithObjects:children andMainData:objects];
    
	[self parseIt];	
}

#pragma mark - Addding and Removing items

- (void)removeItemWithUUID:(NSString *)uuid {	
	NSMutableDictionary *newData = sourceData;
    
    // Delete object its self
	NSString *uuidComplete = [uuid stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	[[newData valueForKey:@"objects"] removeObjectForKey:uuidComplete];
    
    // Delete any references
    NSMutableDictionary *parent = [[self parentOfItemWithUUID:uuid] mutableCopy];
    NSMutableArray *children = [[parent valueForKey:@"children"] mutableCopy];
	[children removeObject:uuid];
    [parent setValue:children forKey:@"children"];
    [[newData valueForKey:@"objects"] setValue:parent forKey:[parent valueForKey:@"uuid"]];
    
    // Delete build phase reference
    BOOL success = [self _removeFileWithUUID:uuid fromBuildPhase:XCDSourceBuildPhase];
    if (!success)
        NSLog(@"ERROR");
    
    NSString *stringToWrite = [newData description];
	NSString *projectFilePath = [filePath stringByAppendingFormat:@"/project.pbxproj"];
	[stringToWrite writeToFile:projectFilePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];		
}

- (BOOL)addGroupWithTitle:(NSString *)title toItemWithUUID:(NSString *)parentUUID { 
	/* If parentUUID == nil, item will be added to root group. */
    
    // PRE-LIMINARY CHECK -- Make sure parent item is a PBXGroup and NOT a file
	NSDictionary *objects = [sourceData valueForKey:@"objects"];
	if (![[[objects valueForKey:parentUUID] valueForKey:@"isa"] isEqualToString:@"PBXGroup"] && parentUUID != nil)
		return NO;
	
	// PRE-LIMINARY CHECK -- Make sure title is not empty or nil
	if ([title isEqualToString:@""] || title == nil)
		return NO;
    
    // Get to work!
	NSString *uuid = [self getRandomStringWithLength:24 alphaNumeric:YES]; // Used for actually key to look for in objects
	
	NSArray *children = [NSArray array]; // Use empty array
	NSString *_isa = @"PBXGroup"; // Always PBXGroup for a group
	NSString *name = title;; // Copy of title
	NSString *sourceTree = @"<group>"; // Same for all items and groups
    
    NSDictionary *newGroup = [NSDictionary dictionaryWithObjectsAndKeys:_isa, @"isa", name, @"name", sourceTree, @"sourceTree", children, @"children", nil];
	[[sourceData valueForKey:@"objects"] setObject:newGroup forKey:uuid];
    
    // Add new group to parent group	    
	if (parentUUID == nil)
		parentUUID = mainGroupUUID;
    
	NSMutableDictionary *parentDictionary = [[[sourceData valueForKey:@"objects"] valueForKey:parentUUID] mutableCopy];
	NSMutableArray *parentChildren = [[parentDictionary valueForKey:@"children"] mutableCopy];
	[parentChildren addObject:uuid];
	[parentDictionary setObject:parentChildren forKey:@"children"];
	
	// Relay info back to main dictionary
	[[sourceData valueForKey:@"objects"] setObject:parentDictionary forKey:parentUUID];
    
    // Write to file
	NSString *stringToWrite = [sourceData description];
	
	NSString *projectFilePath = [filePath stringByAppendingFormat:@"/project.pbxproj"];
	[stringToWrite writeToFile:projectFilePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];	
    
    return YES;
}

- (BOOL)addFileWithRelativePath:(NSString *)relPath asChildToItemWithUUID:(NSString *)parentItemUUID { 
	/* If parentUUID == nil, item will be added to root group. Returns successful or not. */
    
	// PRE-LIMINARY CHECK -- Make sure parent item is a PBXGroup and NOT a file
	
	NSDictionary *objects = [sourceData valueForKey:@"objects"];
	if (![[[objects valueForKey:parentItemUUID] valueForKey:@"isa"] isEqualToString:@"PBXGroup"] && parentItemUUID != nil)
		return NO;
	
	// PRE-LIMINARY CHECK -- Make sure relPath is not empty or nil
	
	if ([relPath isEqualToString:@""] || relPath == nil)
		return NO;
	
	// Get to work!
	
	NSString *uuid = [self getRandomStringWithLength:24 alphaNumeric:YES]; // Used for actually key to look for in objects. Norm length is 24.
	NSLog(@"%@", uuid);
    
	NSString *fileEncoding = @"4"; // As far as i can tell, is always 4
	NSString *_isa = @"PBXFileReference"; // Always PBXFileReference for a file
	NSString *path = relPath; // Copy of relPath
	NSString *sourceTree = @"<group>"; // Same for all items and groups
	
	NSDictionary *newFile = [NSDictionary dictionaryWithObjectsAndKeys:fileEncoding, @"fileEncoding", _isa, @"isa", path, @"path", sourceTree, @"sourceTree", nil];
	[[sourceData valueForKey:@"objects"] setObject:newFile forKey:uuid];
	
	// Add newFile to parent group found by using parentUUID
	
	NSString *parentUUID = parentItemUUID;
    
	if (parentUUID == nil)
		parentUUID = mainGroupUUID;
    
	NSMutableDictionary *parentDictionary = [[objects valueForKey:parentUUID] mutableCopy];
	NSMutableArray *parentChildren = [[parentDictionary valueForKey:@"children"] mutableCopy];
	[parentChildren addObject:uuid];
	[parentDictionary setObject:parentChildren forKey:@"children"];
	
	// Relay info back to main dictionary
	[[sourceData valueForKey:@"objects"] setObject:parentDictionary forKey:parentUUID];
    
    if ([[relPath pathExtension] isEqualToString:@"m"]) {
        // Add newFile to Sources build phase
        NSString *targetUUID = [[rootObject valueForKey:@"targets"] objectAtIndex:0]; // Choose which target to use from array, beware that an important project can have more than one target in this case you should have allowed the user to choose the target
        NSDictionary *targetDictionary = [objects valueForKey:targetUUID];
        NSDictionary *buildPhases = [targetDictionary valueForKey:@"buildPhases"];
        NSString *sourcesBuildPhaseUUID;
        NSMutableDictionary *sourcesBuildPhase;
        
        for (NSString *element in buildPhases) {
            NSDictionary *elementDictionary = [objects valueForKey:element];
            if ([[elementDictionary valueForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]) {
                sourcesBuildPhaseUUID = element;
                sourcesBuildPhase = [elementDictionary mutableCopy];
                break;
            }
        }
        
        if (!sourcesBuildPhase)
            return NO;
        
        // Add buildFile object to data
        NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
        NSString *buildFileIsa = @"PBXBuildFile";
        NSString *fileReference = uuid; 
        NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileIsa, @"isa", fileReference, @"fileRef", nil];
        [[sourceData valueForKey:@"objects"] setObject:buildFile forKey:buildFileUUID];
        
        // Change build phases files
        NSMutableArray *sourcesFiles = [[sourcesBuildPhase valueForKey:@"files"] mutableCopy];
        [sourcesFiles addObject:buildFileUUID];
        [sourcesBuildPhase setObject:sourcesFiles forKey:@"files"];
        
        // Relay info back to main dictionary
        [[sourceData valueForKey:@"objects"] setObject:sourcesBuildPhase forKey:sourcesBuildPhaseUUID];
    }
	
	// Write to file
	
	NSString *stringToWrite = [sourceData description];
	
	NSString *projectFilePath = [filePath stringByAppendingFormat:@"/project.pbxproj"];
	[stringToWrite writeToFile:projectFilePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];	
    
	return YES;	
}

#pragma mark - New Project

- (BOOL)newProjectAtPath:(NSString *)path withFrameworks:(NSArray *)frameworks sourceFiles:(NSArray *)sourceFiles supportingFiles: (NSArray *)supportingFiles oniOSVersion:(NSString *)iOSVersion {
    NSLog(@"Alpha");
    if (!path || !frameworks || !sourceFiles || !supportingFiles || !iOSVersion)
        return NO;
    
    NSString *projectName = [[[path lastPathComponent] stringByReplacingOccurrencesOfString:[path pathExtension] withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@""]; // This is used multiple times in this method so is declared right at the start
    
    NSString *archiveVersion = @"1";
    NSArray *classes = [NSArray array];
    NSString *objectVersion = @"46";
    NSMutableDictionary *objects = [[NSMutableDictionary alloc] init]; // Coming Up…
    NSString *projectRootObject; // UUID of root object. Will be set later after the object has been created
    
    // First up the frameworks build phase
    NSString *frameworksBuildPhaseUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *frameworksBuildPhaseISA = @"PBXFrameworksBuildPhase";
    NSString *frameworksBuildPhaseBuildActionMask = @"2147483647";
    NSMutableArray *frameworksBuildPhaseFiles = [[NSMutableArray alloc] init];;
    NSString *frameworksBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";
    
    NSMutableArray *frameworksFileRefs = [[NSMutableArray alloc] init]; // Used when creating groups
    
    // Create frameworks build files and file references
    for (NSString *frameworkName in frameworks) {
        NSString *fileRefUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
        NSString *fileRefISA = @"PBXFileReference";
        NSString *fileRefLastKnownFileType = @"wrapper.framework";
        NSString *fileRefName = frameworkName;
        NSString *fileRefPath = [NSString stringWithFormat:@"System/Library/Frameworks/%@", frameworkName];
        NSString *fileRefSourceTree = @"SDKROOT";
        NSDictionary *fileRef = [NSDictionary dictionaryWithObjectsAndKeys:fileRefISA, @"isa", fileRefLastKnownFileType, @"lastKnowFileType", fileRefName, @"name", fileRefPath, @"path", fileRefSourceTree, @"sourceTree", nil];
        [objects setValue:fileRef forKey:fileRefUUID];
        [frameworksFileRefs addObject:fileRefUUID];
        
        NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
        NSString *buildFileISA = @"PBXBuildFile";
        NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileISA, @"isa", fileRefUUID, @"fileRef", nil];
        [objects setValue:buildFile forKey:buildFileUUID];
        [frameworksBuildPhaseFiles addObject:buildFileUUID];
    }
    
    NSDictionary *frameworksBuildPhase = [NSDictionary dictionaryWithObjectsAndKeys:frameworksBuildPhaseISA, @"isa", frameworksBuildPhaseBuildActionMask, @"buildActionMask", frameworksBuildPhaseFiles, @"files", frameworksBuildPhaseRunOnlyForDeploymentPostprocessing, @"runOnlyForDeploymentPostprocessing", nil];
    
    [objects setValue:frameworksBuildPhase forKey:frameworksBuildPhaseUUID];
    
    // Start Creating Groups : Frameworks, Main Group and Products
    // First frameworks group, this is easier as we have already prepared for this above ^^^
    NSString *frameworksGroupUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *frameworksGroupISA = @"PBXGroup";
    NSArray *frameworksGroupChildren = frameworksFileRefs;
    NSString *frameworksGroupName = @"Frameworks";
    NSString *frameworksGroupSourceTree = @"<group>";
    NSDictionary *frameworksGroup = [NSDictionary dictionaryWithObjectsAndKeys:frameworksGroupISA, @"isa", frameworksGroupChildren, @"children", frameworksGroupName, @"name", frameworksGroupSourceTree, @"sourceTree", nil];
    [objects setValue:frameworksGroup forKey:frameworksGroupUUID];
    
    // Before we continue create two mutable arrays to store uuid's for source build phase and resources build phase which will be created later
    NSMutableArray *sourcesBuildPhaseFiles = [[NSMutableArray alloc] init];
    NSMutableArray *resourcesBuildPhaseFiles = [[NSMutableArray alloc] init];
    
    // One other thing we need to do is to create two strings in which to store the location of the prefix header file (.pch) and the info property list file (.plist). We use these later when creating the build configurations
    NSString *prefixHeaderFilePath = NULL;
    NSString *infoPlistPath = NULL;
    
    // Now, supporting files.
    NSString *supportingGroupUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *supportingGroupISA = @"PBXGroup";
    NSMutableArray *supportingGroupChildren = [[NSMutableArray alloc] init];
    NSString *supportingGroupName = @"Supporting Group";
    NSString *supportingGroupSourceTree = @"<group>";
    
    // Create supporting file refs and if neccesary create build files
    for (NSString *supportingFilePath in supportingFiles) {
        NSString *fileRefUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
        NSString *fileRefISA = @"PBXFileReference";
        NSString *fileRefPath = supportingFilePath;
        NSString *fileRefSourceTree = @"<group>";
        NSDictionary *fileRef = [NSDictionary dictionaryWithObjectsAndKeys:fileRefISA, @"isa", fileRefPath, @"path", fileRefSourceTree, @"sourceTree", nil];
        [objects setValue:fileRef forKey:fileRefUUID];
        [supportingGroupChildren addObject:fileRefUUID];
        
        if ([[supportingFilePath pathExtension] isEqualToString:@"m"]) {
            // This is an implementation file, add to sources build phase
            NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
            NSString *buildFileISA = @"PBXBuildFile";
            NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileISA, @"isa", fileRefUUID, @"fileRef", nil];
            [objects setValue:buildFile forKey:buildFileUUID];
            [sourcesBuildPhaseFiles addObject:buildFileUUID];
        } else if ([[supportingFilePath pathExtension] isEqualToString:@"m"] || [[supportingFilePath pathExtension] isEqualToString:@"m"]) {
            // This is a '.strings' file most likely Info-Plist.strings OR a '.xib' file
            NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
            NSString *buildFileISA = @"PBXBuildFile";
            NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileISA, @"isa", fileRefUUID, @"fileRef", nil];
            [objects setValue:buildFile forKey:buildFileUUID];
            [resourcesBuildPhaseFiles addObject:buildFileUUID];
        }
        
        // Quick theck for .pch or .plist file, if found store path into previously created variables
        if ([[supportingFilePath pathExtension] isEqualToString:@"pch"])
            prefixHeaderFilePath = supportingFilePath;
        else if ([[supportingFilePath pathExtension] isEqualToString:@"plist"])
            infoPlistPath = supportingFilePath;
    }
    
    NSDictionary *supportingGroup = [NSDictionary dictionaryWithObjectsAndKeys:supportingGroupISA, @"isa", supportingGroupChildren, @"children", supportingGroupName, @"name", supportingGroupSourceTree, @"sourceTree", nil];
    [objects setValue:supportingGroup forKey:supportingGroupUUID];
    
    // Now, primary class files.
    NSString *primaryClassesGroupUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *primaryClassesGroupISA = @"PBXGroup";
    NSMutableArray *primaryClassesGroupChildren = [[NSMutableArray alloc] init];
    NSString *primaryClassesGroupName = projectName; // This is simply the project name. This maintains backwards compatability with Xcode 3 as it uses 'name' rather than 'path'
    NSString *primaryClassesGroupSourceTree = @"<group>";
    
    // Create primary classes file refs and if neccesary create build files
    for (NSString *sourceFilePath in sourceFiles) {
        NSString *fileRefUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
        NSString *fileRefISA = @"PBXFileReference";
        NSString *fileRefPath = sourceFilePath;
        NSString *fileRefSourceTree = @"<group>";
        NSDictionary *fileRef = [NSDictionary dictionaryWithObjectsAndKeys:fileRefISA, @"isa", fileRefPath, @"path", fileRefSourceTree, @"sourceTree", nil];
        [objects setValue:fileRef forKey:fileRefUUID];
        [primaryClassesGroupChildren addObject:fileRefUUID];
        
        if ([[sourceFilePath pathExtension] isEqualToString:@"m"]) {
            // This is an implementation file, add to sources build phase
            NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
            NSString *buildFileISA = @"PBXBuildFile";
            NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileISA, @"isa", fileRefUUID, @"fileRef", nil];
            [objects setValue:buildFile forKey:buildFileUUID];
            [sourcesBuildPhaseFiles addObject:buildFileUUID];
        } else if ([[sourceFilePath pathExtension] isEqualToString:@"m"] || [[sourceFilePath pathExtension] isEqualToString:@"m"]) {
            // This is a '.strings' file most likely Info-Plist.strings OR a '.xib' file
            NSString *buildFileUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
            NSString *buildFileISA = @"PBXBuildFile";
            NSDictionary *buildFile = [NSDictionary dictionaryWithObjectsAndKeys:buildFileISA, @"isa", fileRefUUID, @"fileRef", nil];
            [objects setValue:buildFile forKey:buildFileUUID];
            [resourcesBuildPhaseFiles addObject:buildFileUUID];
        }
        
        // Quick theck for .pch or .plist file, if found store path into previously created variables
        if ([[sourceFilePath pathExtension] isEqualToString:@"pch"])
            prefixHeaderFilePath = sourceFilePath;
        else if ([[sourceFilePath pathExtension] isEqualToString:@"plist"])
            infoPlistPath = sourceFilePath;
    }
    [primaryClassesGroupChildren addObject:supportingGroupUUID]; // Add supporting group to the primary class group
    
    NSDictionary *primaryClassesGroup = [NSDictionary dictionaryWithObjectsAndKeys:primaryClassesGroupISA, @"isa", primaryClassesGroupChildren, @"children", primaryClassesGroupName, @"name", primaryClassesGroupSourceTree, @"sourceTree", nil];
    [objects setValue:primaryClassesGroup forKey:primaryClassesGroupUUID];
    
    // Now, the products group with just a single file; the '.app' file
    NSString *productsGroupUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *productsGroupISA = @"PBXGroup";
    NSMutableArray *productsGroupChildren = [[NSMutableArray alloc] init];
    NSString *productsGroupName = @"Products";
    NSString *productsGroupSourceTree = @"<group>";
    
    // Create the '.app' file as a child
    NSString *productAppUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *productAppISA = @"PBXFileReference";
    NSString *productAppExplicitFileType = @"wrapper.application";
    NSString *productAppIncludeInIndex = @"0";
    NSString *productAppPath = [projectName stringByAppendingFormat:@".app"];
    NSString *productAppSourceTree = @"BUILT_PRODUCTS_DIR";
    NSDictionary *productApp = [NSDictionary dictionaryWithObjectsAndKeys:productAppISA, @"isa", productAppExplicitFileType, @"explicitFileType", productAppIncludeInIndex, @"includeInIndex", productAppPath, @"path", productAppSourceTree, @"sourceTree", nil];
    [objects setValue:productApp forKey:productAppUUID];
    [productsGroupChildren addObject:productAppUUID];
    
    NSDictionary *productsGroup = [NSDictionary dictionaryWithObjectsAndKeys:productsGroupISA, @"isa", productsGroupChildren, @"children", productsGroupName, @"name", productsGroupSourceTree, @"sourceTree", nil];
    [objects setValue:productsGroup forKey:productsGroupUUID];
    
    // Final stage of dealing with files now, creating the root project group
    NSString *rootProjectGroupUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *rootProjectISA = @"PBXGroup";
    NSArray *rootProjectGroupChildren = [NSArray arrayWithObjects:primaryClassesGroupUUID, frameworksGroupUUID, productsGroupUUID, nil];
    NSString *rootProjectGroupSourceTree = @"<group>";
    NSDictionary *rootProject = [NSDictionary dictionaryWithObjectsAndKeys:rootProjectISA, @"isa", rootProjectGroupChildren, @"children", rootProjectGroupSourceTree, @"sourceTree", nil];
    [objects setValue:rootProject forKey:rootProjectGroupUUID];
    
    // Now we create and add the remining two build phases, the source build phase and resources build phase using the arrays we built earlier
    NSString *resourcesBuildPhaseUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *resourcesBuildPhaseISA = @"PBXSourcesBuildPhase";
    NSString *resourcesBuildPhaseBuildActionMask = @"2147483647";
    NSString *resourcesBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";
    NSDictionary *resourcesBuildPhase = [NSDictionary dictionaryWithObjectsAndKeys:resourcesBuildPhaseISA, @"isa", resourcesBuildPhaseBuildActionMask, @"buildActionMask", resourcesBuildPhaseFiles, @"files", resourcesBuildPhaseRunOnlyForDeploymentPostprocessing, @"runOnlyForDeploymentPostprocessing", nil];
    [objects setValue:resourcesBuildPhase forKey:resourcesBuildPhaseUUID];
    
    NSString *sourcesBuildPhaseUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *sourcesBuildPhaseISA = @"PBXSourcesBuildPhase";
    NSString *sourcesBuildPhaseBuildActionMask = @"2147483647";
    NSString *sourcesBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";
    NSDictionary *sourcesBuildPhase = [NSDictionary dictionaryWithObjectsAndKeys:sourcesBuildPhaseISA, @"isa", sourcesBuildPhaseBuildActionMask, @"buildActionMask", sourcesBuildPhaseFiles, @"files", sourcesBuildPhaseRunOnlyForDeploymentPostprocessing, @"runOnlyForDeploymentPostprocessing", nil];
    [objects setValue:sourcesBuildPhase forKey:sourcesBuildPhaseUUID];    
    
    /* 
     So that's most if not all the hassle with files and build files and build phases and what not sorted. Phew! That's gotta be it, right? No. We've still got to sort out the even more compicated build configurations. Yay!
     We start right at the bottom with the 4 build configurations, 2 for debug, 2 for release. For some reason xcode has one for the project itself and one for the target, hence why there are 2 of each.
     */
    
    if (prefixHeaderFilePath == NULL || infoPlistPath == NULL) // Make sure we have a prefix header file and info.plist file in the files we've added as they are required for creating the build configuration files
        return NO;
    
    // First build configurations for the target. Some have the same value, so they are bit mixed up but the names of the variable should be enough to identify which is which.
    NSString *targetDebugBuildConfigurationUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *targetReleaseBuildConfigurationUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *targetDebugBuildConfigurationName = @"Debug";
    NSString *targetReleaseBuildConfigurationName = @"Release";
    NSString *targetBuildConfigurationISA = @"XCBuildConfiguration";
    NSMutableDictionary *targetBuildConfigurationBuildSettings = [[NSMutableDictionary alloc] init];
    
    [targetBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_PRECOMPILE_PREFIX_HEADER"];
    [targetBuildConfigurationBuildSettings setValue:prefixHeaderFilePath forKey:@"GCC_PREFIX_HEADER"];
    [targetBuildConfigurationBuildSettings setValue:infoPlistPath forKey:@"INFOPLIST_FILE"];
    [targetBuildConfigurationBuildSettings setValue:@"$(TARGET_NAME)" forKey:@"PRODUCT_NAME"];
    [targetBuildConfigurationBuildSettings setValue:@"app" forKey:@"WRAPPER_EXTENSION"];
    
    NSDictionary *targetDebugBuildConfiguation = [NSDictionary dictionaryWithObjectsAndKeys:targetBuildConfigurationISA, @"isa", targetBuildConfigurationBuildSettings, @"buildSettings", targetDebugBuildConfigurationName, @"name", nil];
    NSDictionary *targetReleaseBuildConfiguation = [NSDictionary dictionaryWithObjectsAndKeys:targetBuildConfigurationISA, @"isa", targetBuildConfigurationBuildSettings, @"buildSettings", targetReleaseBuildConfigurationName, @"name", nil];
    [objects setValue:targetDebugBuildConfiguation forKey:targetDebugBuildConfigurationUUID];
    [objects setValue:targetReleaseBuildConfiguation forKey:targetReleaseBuildConfigurationUUID];
    
    // Now onto the build configurations for the project, many more settings this time. Only some of the variables are the same this time so i'll split them up between debug and release. NOTE: There are two settings I don't add, one is the code sign identity because there is now way of choosing one. And second is the option to enable ARC (automatic reference counting) because at the current time (18/06/11) it is still only available in Xcode 4.2 which is in beta
    NSString *projectDebugBuildConfigurationUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *projectDebugBuildConfigurationISA = @"XCBuildConfiguration";
    NSString *projectDebugBuildConfigurationName = @"Debug";
    NSDictionary *projectDebugBuildConfigurationBuildSettings = [[NSMutableDictionary alloc] init];
    
    [projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"ALWAYS_SEARCH_USER_PATHS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"$(ARCHS_STANDARD_32_BIT)" forKey:@"ARCHS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"gnu99" forKey:@"GCC_C_LANGUAGE_STANDARD"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"COPY_PHASE_STRIP"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"GCC_DYNAMIC_NO_PIC"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"0" forKey:@"GCC_OPTIMIZATION_LEVEL"];
    [projectDebugBuildConfigurationBuildSettings setValue:[NSArray arrayWithObjects:@"DEBUG=1", @"$(inherited)", nil] forKey:@"GCC_PREPROCESSOR_DEFINITIONS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"GCC_SYMBOLS_PRIVATE_EXTERN"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"com.apple.compilers.llvm.clang.1_0" forKey:@"GCC_VERSION"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_MISSING_PROTOTYPES"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_RETURN_TYPE"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_UNUSED_VARIABLE"];
    [projectDebugBuildConfigurationBuildSettings setValue:iOSVersion forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"iphoneos" forKey:@"SDKROOT"];
    
    NSDictionary *projectDebugBuildConfiguration = [NSDictionary dictionaryWithObjectsAndKeys:projectDebugBuildConfigurationISA, @"isa", projectDebugBuildConfigurationBuildSettings, @"buildSettings", projectDebugBuildConfigurationName, @"name", nil];
    [objects setValue:projectDebugBuildConfiguration forKey:projectDebugBuildConfigurationUUID];
    
    // Now create the release config
    NSString *projectReleaseBuildConfigurationUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *projectReleaseBuildConfigurationISA = @"XCBuildConfiguration";
    NSString *projectReleaseBuildConfigurationName  = @"Release";
    NSDictionary *projectReleaseBuildConfigurationBuildSettings = [[NSMutableDictionary alloc] init];
    
    [projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"ALWAYS_SEARCH_USER_PATHS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"$(ARCHS_STANDARD_32_BIT)" forKey:@"ARCHS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"COPY_PHASE_STRIP"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"gnu99" forKey:@"GCC_C_LANGUAGE_STANDARD"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"com.apple.compilers.llvm.clang.1_0" forKey:@"GCC_VERSION"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_MISSING_PROTOTYPES"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_RETURN_TYPE"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_UNUSED_VARIABLE"];
    [projectDebugBuildConfigurationBuildSettings setValue:iOSVersion forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"-DNS_BLOCK_ASSERTIONS=1" forKey:@"OTHER_CFLAGS"];
    [projectDebugBuildConfigurationBuildSettings setValue:@"iphoneos" forKey:@"SDKROOT"];
    
    NSDictionary *projectReleaseBuildConfiguration = [NSDictionary dictionaryWithObjectsAndKeys:projectReleaseBuildConfigurationISA, @"isa", projectReleaseBuildConfigurationBuildSettings, @"buildSettings", projectReleaseBuildConfigurationName, @"name", nil];
    [objects setValue:projectReleaseBuildConfiguration forKey:projectReleaseBuildConfigurationUUID];
    
    // Now we move on to the configuration lists, one for the project, one for the target. Again variables are the same for both dictionarys except for the buildConfigs themselves so I'll do it all in one go.
    NSString *projectConfigurationListUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *targetConfigurationListUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *configurationListISA = @"XCConfigurationList";
    NSString *configurationListDefaultConfigurationIsVisible = @"0";
    NSString *configurationListDefaultConfigurationName = @"Release";
    NSArray *projectConfigurationListBuildConfigurations = [NSArray arrayWithObjects:projectDebugBuildConfigurationUUID, projectReleaseBuildConfigurationUUID, nil];
    NSArray *targetConfigurationListBuildConfigurations = [NSArray arrayWithObjects:targetDebugBuildConfigurationUUID, targetReleaseBuildConfigurationUUID, nil];
    
    NSDictionary *projectConfigurationList = [NSDictionary dictionaryWithObjectsAndKeys:configurationListISA, @"isa", configurationListDefaultConfigurationIsVisible, @"defaultConfigurationIsVisible", configurationListDefaultConfigurationName, @"defaultConfigurationName", projectConfigurationListBuildConfigurations, @"buildConfigurations", nil];
    NSDictionary *targetConfigurationList = [NSDictionary dictionaryWithObjectsAndKeys:configurationListISA, @"isa", configurationListDefaultConfigurationIsVisible, @"defaultConfigurationIsVisible", configurationListDefaultConfigurationName, @"defaultConfigurationName", targetConfigurationListBuildConfigurations, @"buildConfigurations", nil];
    [objects setValue:projectConfigurationList forKey:projectConfigurationListUUID];
    [objects setValue:targetConfigurationList forKey:targetConfigurationListUUID];
    
    // We are nearing the end. Only two things left to do; create the target and then finally the root project object. Firstly though the target…
    NSString *nativeTargetUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *nativeTargetISA = @"PBXNativeTarget";
    NSString *nativeTargetBuildConfigurationList = targetConfigurationListUUID;
    NSArray *nativeTargetBuildPhases = [NSArray arrayWithObjects:sourcesBuildPhaseUUID, frameworksBuildPhaseUUID, resourcesBuildPhaseUUID, nil];
    NSArray *nativeTargetBuildRules = [NSArray array];
    NSArray *nativeTargetDependencies = [NSArray array];
    NSString *nativeTargetName = projectName;
    NSString *nativeTargetProductName = projectName;
    NSString *nativeTargetProductReference = productAppUUID;
    NSString *nativeTargetProductType = @"com.apple.product-type.application";
    NSDictionary *nativeTarget = [NSDictionary dictionaryWithObjectsAndKeys:nativeTargetISA, @"isa", nativeTargetBuildConfigurationList, @"buildConfigurationList", nativeTargetBuildPhases, @"buildPhases", nativeTargetBuildRules, @"buildRules", nativeTargetDependencies, @"dependencies", nativeTargetName, @"name", nativeTargetProductName, @"productName", nativeTargetProductReference, @"productReference", nativeTargetProductType, @"productType", nil];
    [objects setValue:nativeTarget forKey:nativeTargetUUID];
    
    // Now the last piece of puzzle, the root project object…
    NSString *projectObjectUUID = [self getRandomStringWithLength:24 alphaNumeric:YES];
    NSString *projectObjectISA = @"PBXProject";
    NSString *projectObjectBuildConfigurationList = projectConfigurationListUUID;
    NSString *projectObjectCompatibilityVersion = @"Xcode 3.2";
    NSString *projectObjectDevelopmentRegion = @"English";
    NSString *projectObjectHasScannedForEncodings = @"0";
    NSArray *projectObjectKnowRegions = [NSArray arrayWithObject:@"en"];
    NSString *projectObjectMainGroup = rootProjectGroupUUID;
    NSString *projectObjectProductRefGroup = productsGroupUUID;
    NSString *projectObjectProjectDirPath = @"";
    NSString *projectObjectProjectRoot = @"";
    NSArray *projectObjectTargets = [NSArray arrayWithObject:nativeTargetUUID];
    NSDictionary *projectObject = [NSDictionary dictionaryWithObjectsAndKeys:projectObjectISA, @"isa", projectObjectBuildConfigurationList, @"buildConfigurationList", projectObjectCompatibilityVersion, @"compatibilityVersion", projectObjectDevelopmentRegion, @"developmentRegion", projectObjectHasScannedForEncodings, @"hasScannedForEncodings", projectObjectKnowRegions, @"knownRegions", projectObjectMainGroup, @"mainGroup", projectObjectProductRefGroup, @"productRefGroup", projectObjectProjectDirPath, @"dirPath", projectObjectProjectRoot, @"projectRoot", projectObjectTargets, @"targets", nil];
    [objects setValue:projectObject forKey:projectObjectUUID];
    
    // Wow, that's it pretty much all done. Know we just need to create the pbxproj and xcodeproj file
    // Set this to the correct UUID
    projectRootObject = projectObjectUUID;
    
    // Now create the dictionary which glues everything together
    NSDictionary *pbxProjDictionary = [NSDictionary dictionaryWithObjectsAndKeys:archiveVersion, @"archiveVersion", classes, @"classes", objectVersion, @"objectVersion", objects, @"objects", projectRootObject, @"rootObject", nil];
    
    // Before we write the dictionary as a .pbxProj we need somewhere to actually put it specifically the xcodeproj itself. Create that directory now
    NSError *error = NULL;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    if (error != NULL)
        return NO;
    
    // Now we can write the pbxProj into this newly created directory
    NSString *pbxProjContents = [pbxProjDictionary description]; // Not neccesaruly the purpose of the method but it does what we need it  too
    NSString *pbxProjFilePath = [path stringByAppendingFormat:@"/project.pbxproj"];
	[pbxProjContents writeToFile:pbxProjFilePath atomically:YES encoding:NSASCIIStringEncoding error:&error];
    if (error != NULL)
        return NO;
    NSLog(@"Omega");
    return YES; // Wow, that's it! All down! We have completely created our own Xcode project!
}

#pragma mark - Retrieving Data

- (NSArray *)uuidsOfChildrenOfItemWithUUID:(NSString *)uuid {
    if (!sourceData) // Data not parsed, make sure you call parseXcodeProject before using this or any other method
        return nil;
    
    NSDictionary *objects = [sourceData valueForKey:@"objects"];
    NSDictionary *item = [objects valueForKey:uuid];
    
    if (!item) // Item doesn't exist. Incorrect uuid.
        return nil;
    if (![[item valueForKey:@"isa"] isEqualToString:@"PBXGroup"]) // Make sure we're trying to get the children of a group otherwise we know there won't be any children in a file or whatevery else
        return nil;
    
    NSArray *children = [item valueForKey:@"children"];
    
    return children;
}

- (NSUInteger)numberOfChildrenOfItemWithUUID:(NSString *)uuid {
    NSArray *children = [self uuidsOfChildrenOfItemWithUUID:uuid];
    return children.count;
}

- (NSDictionary *)itemWithUUID:(NSString *)uuid {
    if (!sourceData) // Data not parsed, make sure you call parseXcodeProject before using this or any other method
        return nil;
    
    NSDictionary *objects = [sourceData valueForKey:@"objects"];
    NSDictionary *item = [objects valueForKey:uuid];
    
    if (!item) // Item doesn't exist. Incorrect uuid.
        return nil;
    
    return item;
}

- (NSString *)nameOfItemWithUUID:(NSString *)uuid {
    NSDictionary *item = [self itemWithUUID:uuid];
    if ([item valueForKey:@"name"] != nil)
        return [item valueForKey:@"name"];
    else if ([item valueForKey:@"path"] != nil)
        return [[item valueForKey:@"path"] lastPathComponent];
    else
        return nil;
}

- (NSDictionary *)parentOfItemWithUUID:(NSString *)uuid {
    NSDictionary *objects = [sourceData valueForKey:@"objects"];
    
    for (NSString *element in objects) {
        NSDictionary *item = [objects valueForKey:element];
        NSArray *children = [item valueForKey:@"children"];
        if (!children)
            continue;
        if ([children containsObject:uuid]) {
            NSMutableDictionary *customItem = [item mutableCopy];
            [customItem setValue:element forKey:@"uuid"]; // Do this to help users of this method get the uuid
            return customItem;
        }
    }
    
    return nil; // No parent, unlikely but can happen
}

#pragma mark - Internal Methods (Deals with build phases)

- (BOOL)_removeFileWithUUID:(NSString *)uuid fromBuildPhase:(XCDBuildPhase)buildPhase {
    if (buildPhase == XCDSourceBuildPhase) {
        NSArray *objects = [sourceData valueForKey:@"objects"];
        NSString *targetUUID = [[rootObject valueForKey:@"targets"] objectAtIndex:0]; // Choose which target to use from array, beware that an large project can have more than one target in this case you should have allowed the user to choose the target
        NSDictionary *targetDictionary = [objects valueForKey:targetUUID];
        NSDictionary *buildPhases = [targetDictionary valueForKey:@"buildPhases"];
        NSString *sourcesBuildPhaseUUID;
        NSMutableDictionary *sourcesBuildPhase;
        
        for (NSString *element in buildPhases) {
            NSDictionary *elementDictionary = [objects valueForKey:element];
            if ([[elementDictionary valueForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]) {
                sourcesBuildPhaseUUID = element;
                sourcesBuildPhase = [elementDictionary mutableCopy];
                break;
            }
        }
        
        if (!sourcesBuildPhase)
            return NO;
        
        // Change build phases files
        NSMutableArray *sourcesFiles = [[sourcesBuildPhase valueForKey:@"files"] mutableCopy];
        NSMutableArray *sourcesFilesToRemove = [[NSMutableArray alloc] init];
        
        for (NSString *buildRefUUID in sourcesFiles) {
            NSDictionary *buildRef = [objects valueForKey:buildRefUUID];
            NSString *fileRefUUID = [buildRef valueForKey:@"fileRef"];
            if ([fileRefUUID isEqualToString:uuid])
                [sourcesFilesToRemove addObject:buildRefUUID];
        }
        
        [sourcesFiles removeObjectsInArray:sourcesFilesToRemove];
        
        [sourcesBuildPhase setObject:sourcesFiles forKey:@"files"];
        
        // Relay info back to main dictionary
        [[sourceData valueForKey:@"objects"] setObject:sourcesBuildPhase forKey:sourcesBuildPhaseUUID];
    }
    return YES;
}

#pragma mark - Exporting

static int timeout = 5;
static int currentNum = 0;

- (NSString *)_correctedFilePathForItemAtPath:(NSString *)path withUUID:(NSString *)uuid inEnclosingFolder:(NSString *)enclosingFolderPath {
    NSString *originalPath = [path copy];
    if (currentNum > timeout)
        return originalPath;
    currentNum++;
    NSDictionary *parent = [self parentOfItemWithUUID:uuid];
    NSString *parentName = [parent valueForKey:@"name"];
    if (parentName == nil)
        parentName = [parent valueForKey:@"path"];
    NSString *possibleNewLocation = [[enclosingFolderPath stringByAppendingPathComponent:parentName] stringByAppendingPathComponent:path];
    // Check if that exists, if so then adjust the path. If not try again
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:possibleNewLocation];
    if (isDropbox)
        fileExists = [self _dropboxFileExistsAtPath:path metadata:nil];
    if (fileExists) {
        path = [parentName stringByAppendingPathComponent:path];
    } else if (!fileExists) { // Check parent of parent 
        path = [self _correctedFilePathForItemAtPath:path withUUID:[parent valueForKey:@"uuid"] inEnclosingFolder:enclosingFolderPath];
    }
    currentNum = 0;
    return path;
}

- (NSString *)_correctedFilePathForPathContainingElipsis:(NSString *)path {
    return path;
}

- (BOOL)exportFilesFromProjectIntoFolderAtPath:(NSString *)destinationPath {
    // Set up some variables
    NSDictionary *objects = [sourceData valueForKey:@"objects"];
    BOOL delegateRespondsToStatusChanged = [exportDelegate respondsToSelector:@selector(statusChangedTo:withFile:)];
    
    // First let's Check whether files are in same folder as project (Xcode 3) or in seperate folder which is entitled the proj title (Xcode 4)
    NSString *enclosingFolderPath = [filePath stringByDeletingLastPathComponent];
    NSString *possibleFolderLocation = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[filePath lastPathComponent] stringByDeletingPathExtension]];
    BOOL isDirectory = NO;
    BOOL folderExists = [[NSFileManager defaultManager] fileExistsAtPath:possibleFolderLocation isDirectory:&isDirectory];
    NSError *error = NULL;
    NSString *originalDestinationPath = [destinationPath copy];
    
    if (delegateRespondsToStatusChanged)
        [exportDelegate statusChangedTo:XCDExportStatusBegun withFile:nil];

    if (delegateRespondsToStatusChanged)
        [exportDelegate statusChangedTo:XCDExportStatusPreProcessing withFile:nil];
    
    if (folderExists && isDirectory) {
        // Adjust the encolsing folder path to match
        enclosingFolderPath = possibleFolderLocation;
        // Adjust destination path then create that directory
        destinationPath = [destinationPath stringByAppendingPathComponent:[[filePath lastPathComponent] stringByDeletingPathExtension]];
        [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO attributes:NULL error:&error];
        if (error != NULL) {
            if (!delegateRespondsToStatusChanged) {
                // Raise exception
                NSString *title = @"Directory creation error";
                NSString *format = [NSString stringWithFormat:@"An error occured while attempting to create the primary enclosing directory during the process of copying the Xcode projects files. The cause of the problem was the folder located at '%@' relative to the ROOT when trying to be created at '%@'. The provided user info is as follows: %@", enclosingFolderPath, destinationPath, error.userInfo];
                [NSException raise:title format:format]; 
            }
            // Inform delegate
            if (delegateRespondsToStatusChanged)
                [exportDelegate statusChangedTo:XCDExportStatusFailure withFile:enclosingFolderPath];
            return NO;
        }
    }
    
    error = NULL;
    
    // Let's loop through the dictionary's keys and check for file references and add the paths to the array
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    
    for (NSString *key in objects) {
        NSDictionary *item = [objects valueForKey:key];
        NSString *_isa = [item valueForKey:@"isa"];
        NSString *sourceTree = [item valueForKey:@"sourceTree"];
        if ([_isa isEqualToString:@"PBXFileReference"] && ([sourceTree isEqualToString:@"<group>"] || [sourceTree isEqualToString:@"SOURCE_ROOT"])) {
            NSString *path = [item valueForKey:@"path"];
            // Let's see if it exists
            NSString *originalFilePath = [enclosingFolderPath stringByAppendingPathComponent:path];
            BOOL fileExits = [[NSFileManager defaultManager] fileExistsAtPath:originalFilePath];
            // If not then check if it exists in a folder with the groups name
            if (!fileExits) {
                path =  [self _correctedFilePathForItemAtPath:path withUUID:key inEnclosingFolder:enclosingFolderPath];
            }
            // Add it to the array
            [filePaths addObject:path];
        }
    }
    
    error = NULL;
    
    // Now go through the file paths and copy them to our into our destination folder
    for (NSString *path in filePaths) {
        NSString *originalFilePath = [enclosingFolderPath stringByAppendingPathComponent:path];
        NSString *destinationFilePath = [destinationPath stringByAppendingPathComponent:path];
        
        // Inform delegate of current stage
        if (delegateRespondsToStatusChanged)
            [exportDelegate statusChangedTo:XCDExportStatusProcessing withFile:originalFilePath];
            
        // Check for a folder in the path first, see if it exists, if not create it and intermediaries
        NSString *upperPath = [path stringByDeletingLastPathComponent];
        if (![upperPath isEqualToString:@""]) { // Folder in path
            NSString *upperDirectoryDestiniationPath = [destinationPath stringByAppendingPathComponent:upperPath];
            BOOL upperDirectoryExists = [[NSFileManager defaultManager] fileExistsAtPath:upperDirectoryDestiniationPath];
            if (!upperDirectoryExists) { // Folder doesn't exist
                [[NSFileManager defaultManager] createDirectoryAtPath:upperDirectoryDestiniationPath withIntermediateDirectories:YES attributes:NULL error:&error];
                if (error != NULL) {
                    if (!delegateRespondsToStatusChanged) {
                        // Raise exception
                        NSString *title = @"Directory creation error";
                        NSString *format = [NSString stringWithFormat:@"An error occured while attempting to create a directory during the process of copying the Xcode projects files. The cause of the problem was the folder located at '%@' relative to the project when trying to be created at '%@'. The provided user info is as follows: %@", upperPath, upperDirectoryDestiniationPath, error.userInfo];
                        [NSException raise:title format:format]; 
                        NSLog(@"%@", format);
                    }
                    // Inform delegate
                    if (delegateRespondsToStatusChanged)
                        [exportDelegate statusChangedTo:XCDExportStatusFailure withFile:upperPath];
                }
            }
        }
        
        error = NULL;
        
        // Now copy that file
        [[NSFileManager defaultManager] copyItemAtPath:originalFilePath toPath:destinationFilePath error:&error]; // !!! : <-- Here
        if (error != NULL) {
            if (!delegateRespondsToStatusChanged) {
                // Raise exception
                NSString *title = @"Copy error";
                NSString *format = [NSString stringWithFormat:@"An error occured while attempting to copy the Xcode projects files. The cause of the problem was the file located at '%@' relative to the project when trying to be copied to '%@'. The provided user info is as follows: %@", path, destinationFilePath, error.userInfo];
                [NSException raise:title format:format]; 
            }
            // Inform delegate
            if (delegateRespondsToStatusChanged)
                [exportDelegate statusChangedTo:XCDExportStatusFailure withFile:path];
        }
    }
    
    error = NULL;
    
    // Now copy the xcode project
    NSString *xcodeProjectDestinationPath = [originalDestinationPath stringByAppendingPathComponent:[filePath lastPathComponent]]; 
    
    // Inform delegate of current stage
    if (delegateRespondsToStatusChanged)
        [exportDelegate statusChangedTo:XCDExportStatusProcessing withFile:filePath];
    
    [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:xcodeProjectDestinationPath error:&error]; // !!! : <-- Here
    
    if (error != NULL) {
        // Raise exception
        if (!delegateRespondsToStatusChanged) {
            NSString *title = @"Copy error";
            NSString *format = [NSString stringWithFormat:@"An error occured while attempting to copy the Xcode project itself. The cause of the problem was the xcode project located at '%@' when trying to be copied to '%@'. The provided user info is as follows: %@", filePath, xcodeProjectDestinationPath, error.userInfo];
            [NSException raise:title format:format]; 
        }
        // Inform delegate
        if (delegateRespondsToStatusChanged)
            [exportDelegate statusChangedTo:XCDExportStatusFailure withFile:filePath];
    }
    
    // Inform delegate of completion
    if (delegateRespondsToStatusChanged)
        [exportDelegate statusChangedTo:XCDExportStatusComplete withFile:nil]; 
    
    return YES;
}

@end
