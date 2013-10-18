
//  XCDProjectCoordinator.m -  XcodeProjReader

#import "XCDProjectCoordinator.h"
#import "XcodeObject.h"


#define $(...) [NSString stringWithFormat:__VA_ARGS__]
static NSString *lettersAndNumbers, *numbers = nil;

#pragma mark - Additions

NSString* getRandomStringWithLengthAlpha(int len, BOOL alphaNumeric) {
    NSMutableString *randomString = NSMutableString.new;

	numbers = numbers	?: @"123456789"; lettersAndNumbers = lettersAndNumbers ?: @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	for (int x=0; x<len; x++) {
        [randomString appendFormat:@"%c", alphaNumeric
		? 	[lettersAndNumbers characterAtIndex:arc4random() % lettersAndNumbers.length]
		: 	[numbers characterAtIndex:arc4random() % numbers.length]];
    }
	return randomString;
}


@implementation XCDProjectCoordinator	//@synthesize files, filePath, rootObjectUUID, mainGroupUUID, exportDelegate, originalDropboxPath;

#pragma mark - Initiazlization

- (id)initWithProjectAtPath:(NSString *)path {
    if (self != super.init) return nil;
    
    _filePath = path;
    return self;
}

#pragma mark - Supporting Methods

- (void) enumerateChildrenWithObjects:(NSArray*)objects andMainData:(NSDictionary*)mainData 								{
    [objects enumerateObjectsUsingBlock:^(NSString *element, NSUInteger idx, BOOL *stop) {
    //		NSDictionary *elementDictionary = mainData[element];
        id elementDictionary = mainData[element];
        //NSLog(@"elementDictionary.class = %@", NSStringFromClass([elementDictionary class]));
    //		XcodeObject *elementDictionary = mainData[element];
        NSString *name = elementDictionary[@"name"]; // IF HAS NAME IT IS GROUP! OTHERWISE IS FILE AND USE PATH
        NSString *path = [elementDictionary[@"path"]lastPathComponent];

        NSLog(@"--- Name: %@ Path: %@",name,path);
        
        NSMutableString *gapping = @"".mutableCopy;
        for (int x=0; x < _i; x++) {
            [gapping appendString:@"\t"];
        }
        
        if (name && [name.pathExtension isEqualToString:@""]) {
            [_dataString appendString:$(@"%@%@|[GAP]|%@\n", gapping, name, element)];
            NSArray *children = [elementDictionary valueForKey:@"children"];
            if (children) {
                self.i++;
                [self enumerateChildrenWithObjects:children andMainData:mainData];
            }
        }
        else if (name) {
            [self.dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, name, element]];
        }
        else if (path && [[path pathExtension] isEqualToString:@""]) {
            [self.dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, path, element]];
            NSArray *children = [elementDictionary valueForKey:@"children"];
            if (children) { self.i++;
                [self enumerateChildrenWithObjects:children andMainData:mainData];
            }
        } else if (path) {
            [self.dataString appendString:[NSString stringWithFormat:@"%@%@|[GAP]|%@\n", gapping, path, element]];
        }
    }];
    self.i--;
}

//- (NSDictionary*)addChildrenTo:(NSDictionary*)dict withString:(NSString*)sString andCurrentRange:(NSRange)cRange 	{
- (XcodeObject*)addChildrenTo:(XcodeObject*)dict withString:(NSString*)sString andCurrentRange:(NSRange)cRange {

	NSInteger numToSkip = 100;
	NSArray *eachLine = [sString componentsSeparatedByString:@"\n"];
	XcodeObject *newDictionary = [dict mutableCopy];
//NSMutableDictionary *newDictionary = [dict mutableCopy];
	NSRange currentLineRange = NSMakeRange(cRange.location, 0);
	for (NSString *line in eachLine) {
		NSInteger newLoc = currentLineRange.location + line.length + 1;
		currentLineRange = NSMakeRange(newLoc, 0);
        
		if ([eachLine indexOfObject:line] == eachLine.count-1) break;
        
		NSInteger numOfTabs = numberOfOccurrencesOfStringInString(@"\t", line);
		NSString *nextLine = eachLine[[eachLine indexOfObject:line]+1];
		NSInteger numOfTabsOnNextLine = numberOfOccurrencesOfStringInString(@"\t", nextLine);
		NSMutableArray *children;

		if  (numOfTabs > numToSkip) {
            continue;
        }
		else if (numOfTabs < numToSkip) {
            numToSkip = 100;
        }
        
		if (self.waitTime > 0) {
            self.waitTime--;
            return newDictionary;
        }
        
		if (numOfTabsOnNextLine > numOfTabs) {
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location
													 + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location]
													stringByReplacingOccurrencesOfString:@"\t" withString:@""];
//		NSDictionary *dictionary 	= @{ @"name":name, @"children":@[].mutableCopy,@"uuid":uuid, @"parent":newDictionary, @"icon":
			NSString *hereOn = [self.dataString substringFromIndex:currentLineRange.location];
			XcodeObject *dictionary = [XcodeObject objectWithName:name uuid:uuid];
//			dictionary = [self addChildrenTo:dictionary withString:hereOn andCurrentRange:currentLineRange];
			dictionary = [self addChildrenTo:dictionary withString:hereOn andCurrentRange:currentLineRange];
			numToSkip = numOfTabs; // Skip anything > the current # of tabs until it comes down
			children = newDictionary[@"children"];
			//NSLog(@"Chlldren:%@", children);
			[children addObject:dictionary];
			newDictionary[@"children"] = children;
		} else if (numOfTabsOnNextLine < numOfTabs) {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location]
                              stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location
                                + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
//			NSDictionary *child 			= @{@"name": name, @"children" : @[].mutableCopy, @"uuid":uuid, @"parent":newDictionary,@"icon"
			XcodeObject *child = [XcodeObject objectWithName:name uuid:uuid];
			child.parent = newDictionary;
			[(children = newDictionary[@"children"]) addObject:child];
			newDictionary[@"children"] = children;
			self.waitTime = numOfTabs - numOfTabsOnNextLine - 1;
			return newDictionary;
		} else {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location]
                              stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location
                            + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];

//			NSDictionary *child = @{@"name": name, @"children" : @[].mutableCopy, @"uuid":uuid, @"parent":newDictionary, @"icon":
			XcodeObject *child = [XcodeObject objectWithName:name uuid:uuid];
			child.parent = newDictionary;
			[(children = newDictionary[@"children"]) addObject:child];
			newDictionary[@"children"] = children;
		}
	}
	NSLog(@"FAILURE");
	return newDictionary;
}

#pragma mark - Parsing

- (void)parseIt {

	NSArray *eachLine = [self.dataString componentsSeparatedByString:@"\n"];
	NSRange currentLineRange = NSMakeRange(0, 0);

	for (NSString *line in eachLine) {

		NSInteger newLoc = currentLineRange.location + line.length + 1;
		currentLineRange = NSMakeRange(newLoc, 0);

		if ([eachLine indexOfObject:line] == eachLine.count-1) break;

		NSInteger numOfTabs = numberOfOccurrencesOfStringInString(@"\t", line);
		NSString *nextLine = eachLine[[eachLine indexOfObject:line]+1];
		NSInteger numOfTabsOnNextLine = numberOfOccurrencesOfStringInString(@"\t", nextLine);

		if (numOfTabs == 0 && numOfTabsOnNextLine > numOfTabs) {			// Folder, I am

			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location]
                                stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location
                            + [line rangeOfString:@"|[GAP]|"].length]
                                stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			XcodeObject *obj = [XcodeObject objectWithName:name uuid:uuid];
//			obj.name = name;
//			obj.uuid = uuid;
//			[obj setValue:@[].mutableCopy forKey:@"children"];
//			NSDictionary *dictionary = @{@"name": name, @"children": @[].mutableCopy, @"uuid": uuid, @"parent": NSNull.null, @"icon":[NSImage imageNamed:@"group"] }; [NSWorkspace.sharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)]};
			
            NSString *hereOn = [self.dataString substringFromIndex:currentLineRange.location];
			//dictionary = [self addChildrenTo:dictionary withString:hereOn andCurrentRange:currentLineRange];
			obj = [self addChildrenTo:obj withString:hereOn andCurrentRange:currentLineRange];
			[self.files addObject:obj];
            //dictionary];
		} else if (numOfTabs == 0) {
			NSString *name = [[line substringToIndex:[line rangeOfString:@"|[GAP]|"].location]
                            stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			NSString *uuid = [[line substringFromIndex:[line rangeOfString:@"|[GAP]|"].location
							   + [line rangeOfString:@"|[GAP]|"].length] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			XcodeObject *dictionary = [XcodeObject objectWithName:name uuid:uuid];
			NSLog(@"adding dict: %@", dictionary);
//			NSDictionary *dictionary = @{@"name": name, @"children": [NSMutableArray array], @"uuid": uuid, (id)@"parent": (id)nil};
			[self.files addObject:dictionary];
		}
	}
}
- (void)parseXcodeProject {
    NSLog(@"Parsing project at path: %@", self.filePath);

	// Clean up
	self.i = 0;
	self.files = NSMutableArray.new;
	self.dataString = @"".mutableCopy;
	NSString *path = self.filePath;
	NSString *projectFilePath = self.isDropbox ? path : [path stringByAppendingFormat:@"/project.pbxproj"];
	self.sourceData = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:projectFilePath]]mutableCopy];
	//NSLog(@"sourceData: %@", _sourceData);
	NSDictionary *objects = _sourceData[@"objects"];
	self.rootObjectUUID = _sourceData[@"rootObject"];
	self.rootObject = objects[self.rootObjectUUID];
	self.mainGroupUUID = _rootObject[@"mainGroup"];
	self.mainGroup = objects[self.mainGroupUUID];
	NSArray *children = _mainGroup[@"children"];
	if (children) {
        [self enumerateChildrenWithObjects:children andMainData:objects];
    }
    
	[self parseIt];
}

#pragma mark - Addding and Removing items

- (void)removeItemWithUUID:(NSString*)uuid {

	NSMutableDictionary *newData = self.sourceData;

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
	NSString *projectFilePath = [self.filePath stringByAppendingFormat:@"/project.pbxproj"];
	[stringToWrite writeToFile:projectFilePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];
}

- (BOOL)addGroupWithTitle:(NSString*)title toItemWithUUID:(NSString*)parentUUID 		{
	/* If parentUUID == nil, item will be added to root group. */
	// PRE-LIMINARY CHECK -- Make sure parent item is a PBXGroup and NOT a file
	NSDictionary *objects = self.sourceData[@"objects"];
	if (![[objects[parentUUID] valueForKey:@"isa"] isEqualToString:@"PBXGroup"] && parentUUID != nil)		return NO;
	// PRE-LIMINARY CHECK -- Make sure title is not empty or nil
	if ([title isEqualToString:@""] || title == nil) return NO;
	// Get to work!
	NSString *uuid 		= getRandomStringWithLengthAlpha(24,YES); // Used for actually key to look for in objects
	NSArray *children 	= @[]; // Use empty array
	NSString *_isa 		= @"PBXGroup"; // Always PBXGroup for a group
	NSString *name 		= title;; // Copy of title
	NSString *sourceTree = @"<group>"; // Same for all items and groups

	NSDictionary *newGroup = @{@"isa": _isa, @"name": name, @"sourceTree": sourceTree, @"children": children};
    
	_sourceData[@"objects"][uuid] = newGroup;
	// Add new group to parent group
	parentUUID = parentUUID ?: self.mainGroupUUID;
	NSMutableDictionary *parentDictionary = [[self.sourceData[@"objects"] valueForKey:parentUUID] mutableCopy];
	NSMutableArray *parentChildren = [parentDictionary[@"children"] mutableCopy];
	[parentChildren addObject:uuid];
	parentDictionary[@"children"] = parentChildren;
	// Relay info back to main dictionary
	self.sourceData[@"objects"][parentUUID] = parentDictionary;
	// Write to file
	NSString *stringToWrite = self.sourceData.description;
	NSString *projectFilePath = [self.filePath stringByAppendingFormat:@"/project.pbxproj"];
	[stringToWrite writeToFile:projectFilePath atomically:YES encoding:NSASCIIStringEncoding error:NULL];
	return YES;
}

- (BOOL)addFileWithRelativePath: (NSString*)relPath asChildToItemWithUUID:(NSString*)parentItemUUID 	{

	// If parentUUID == nil, item will be added to root group. Returns successful or not.
	// PRE-LIMINARY CHECK -- Make sure parent item is a PBXGroup and NOT a file
	NSDictionary *objects = self.sourceData[@"objects"];
	if (![objects[parentItemUUID][@"isa"] isEqualToString:@"PBXGroup"] && parentItemUUID != nil) return NO;
	if ([relPath isEqualToString:@""] || relPath == nil) return NO; // PRE-LIMINARY CHECK -- Make sure relPath is not empty or nil

	// Get to work!
	NSString         * uuid = getRandomStringWithLengthAlpha(24,YES), // Used for actually key to look for in objects. Norm length is 24.
				* fileEncoding = @"4", 																						// As far as i can tell, is always 4
						  * _isa = @"PBXFileReference", 																	// Always PBXFileReference for a file
						  * path	= relPath, 																					// Copy of relPath
				  * sourceTree = @"<group>"; 																				// Same for all items and groups
	self.sourceData[@"objects"][uuid] = @{	@"fileEncoding" : fileEncoding, 	 @"isa" : _isa,
																  @"path" : path, 	@"sourceTree" : sourceTree}; 	// newFile;
	// Add newFile to parent group found by using parentUUID
	NSString			 * parentUUID 				= parentItemUUID ?: self.mainGroupUUID;
//	NSMutableDictionary * parentDictionary	= [objects[parentUUID] mutableCopy];
	XcodeObject * parentDictionary			= [objects[parentUUID] mutableCopy];
	NSMutableArray        * parentChildren	= [parentDictionary[@"children"] mutableCopy];
	[parentChildren addObject:uuid];
	parentDictionary[@"children"] 			= parentChildren;
	// Relay info back to main dictionary
	self.sourceData[@"objects"][parentUUID] = parentDictionary;

	if ([relPath.pathExtension isEqualToString:@"m"]) {  // Add newFile to Sources build phase
		// Choose which target to use from array, beware that an important project can have more than one target in this case you should have allowed the user to choose the target
		NSString *targetUUID 				= self.rootObject[@"targets"][0];
//		NSDictionary *targetDictionary = [objects valueForKey:targetUUID];
//		NSDictionary *buildPhases 		= targetDictionary[@"buildPhases"];
		XcodeObject *targetDictionary = [objects valueForKey:targetUUID];
		NSDictionary *buildPhases 		= targetDictionary[@"buildPhases"];
		NSString *sourcesBuildPhaseUUID;
//		NSMutableDictionary *sourcesBuildPhase;
		XcodeObject *sourcesBuildPhase;
		for (NSString *element in buildPhases) {
			XcodeObject *elementDictionary 	= objects[element];
//			NSDictionary *elementDictionary 	= objects[element];
			if ([elementDictionary[@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]) {
				sourcesBuildPhaseUUID 			= element;
				sourcesBuildPhase 				= [elementDictionary mutableCopy];
				break;
			}
		}
		if (!sourcesBuildPhase)   return NO;
//		*buildFileIsa 			= @"PBXBuildFile",	*fileReference 			= uuid; 		NSDictionary *buildFile 			= ;
// 	Change build phases files  //NSMutableArray *sourcesFiles =		[sourcesFiles addObject:buildFileUUID];

		// Add buildFile object to data
		NSString *buildFileUUID 							= getRandomStringWithLengthAlpha(24,YES);
		self.sourceData[@"objects"][buildFileUUID] 	= @{@"isa": @"PBXBuildFile", @"fileRef": uuid};//buildFileIsa...fileReference}; // BuildFile
		// Change build phases files
		sourcesBuildPhase[@"files"] 						= [sourcesBuildPhase[@"files"] arrayByAddingObject:buildFileUUID].mutableCopy;
		self.sourceData[@"objects"][sourcesBuildPhaseUUID] = sourcesBuildPhase;		// Relay info back to main dictionary
	}

	// Write to file
	return [self.sourceData.description writeToFile:[self.filePath stringByAppendingFormat:@"/project.pbxproj"]
													 atomically:YES encoding:NSASCIIStringEncoding error:NULL];
}

#pragma mark - New Project

- (BOOL)newProjectAtPath:(NSString*)path withFrameworks:(NSArray*)frameworks       sourceFiles:(NSArray *)sourceFiles
			supportingFiles:(NSArray*)supportingFiles oniOSVersion:(NSString *)iOSVersion {

	NSLog(@"Alpha"); if (!path || !frameworks || !sourceFiles || !supportingFiles || !iOSVersion)  return NO;

	// This is used multiple times in this method so is declared right at the start
	NSString *projectName = [[path.lastPathComponent stringByReplacingOccurrencesOfString:path.pathExtension withString:@""]
									 stringByReplacingOccurrencesOfString:@"." withString:@""];

	NSString *archiveVersion 		= @"1",
				*objectVersion 		= @"46";
	NSArray *classes 					= @[];
	NSMutableDictionary *objects 	= NSMutableDictionary.new;   // Coming Up…
	NSString *projectRootObject; // UUID of root object. Will be set later after the object has been created

	// First up the frameworks build phase
	NSString *frameworksBuildPhaseUUID 				= getRandomStringWithLengthAlpha(24,YES),
	*frameworksBuildPhaseISA 							= @"PBXFrameworksBuildPhase",
	*frameworksBuildPhaseBuildActionMask 			= @"2147483647";
	NSMutableArray *frameworksBuildPhaseFiles 	= NSMutableArray.new,
	*frameworksFileRefs 									= NSMutableArray.new;  // Used when creating groups
	NSString *frameworksBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";

	// Create frameworks build files and file references
	for (NSString *frameworkName in frameworks) {
		NSString 	*fileRefUUID 	= getRandomStringWithLengthAlpha(24,YES),
		*fileRefISA 					= @"PBXFileReference",
		*fileRefLastKnownFileType 	= @"wrapper.framework",
		*fileRefName 					= frameworkName,
		*fileRefPath 					= [NSString stringWithFormat:@"System/Library/Frameworks/%@", frameworkName],
		*fileRefSourceTree			= @"SDKROOT";
		NSDictionary 				  *fileRef = @{					 @"isa"	:	fileRefISA,
																				 @"lastKnowFileType"	:	fileRefLastKnownFileType,
																				 @"name"	: 	fileRefName,
																				 @"path"	: 	fileRefPath,
																				 @"sourceTree"	: 	fileRefSourceTree};
		objects[fileRefUUID] = fileRef;
		[frameworksFileRefs addObject:fileRefUUID];

		NSString *buildFileUUID = getRandomStringWithLengthAlpha(24,YES),
		*buildFileISA = @"PBXBuildFile";
		NSDictionary *buildFile = @{@"isa": buildFileISA, @"fileRef": fileRefUUID};
		objects[buildFileUUID]  = buildFile;
		[frameworksBuildPhaseFiles addObject:buildFileUUID];
	}
	[objects setValue: @{				 @"isa": frameworksBuildPhaseISA,
												 @"buildActionMask": frameworksBuildPhaseBuildActionMask,
												 @"files": frameworksBuildPhaseFiles,
												 @"runOnlyForDeploymentPostprocessing": frameworksBuildPhaseRunOnlyForDeploymentPostprocessing}
				  forKey:frameworksBuildPhaseUUID];

	// Start Creating Groups : Frameworks, Main Group and Products
	// First frameworks group, this is easier as we have already prepared for this above ^^^
	NSString *frameworksGroupUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *frameworksGroupISA = @"PBXGroup";
	NSArray *frameworksGroupChildren = frameworksFileRefs;
	NSString *frameworksGroupName = @"Frameworks";
	NSString *frameworksGroupSourceTree = @"<group>";
	NSDictionary *frameworksGroup = @{@"isa": frameworksGroupISA, @"children": frameworksGroupChildren, @"name": frameworksGroupName, @"sourceTree": frameworksGroupSourceTree};
	[objects setValue:frameworksGroup forKey:frameworksGroupUUID];

	// Before we continue create two mutable arrays to store uuid's for source build phase and resources build phase which will be created later
	NSMutableArray *sourcesBuildPhaseFiles = NSMutableArray.new, *resourcesBuildPhaseFiles = NSMutableArray.new;

	// One other thing we need to do is to create two strings in which to store the location of the prefix header file (.pch) and the info property list file (.plist). We use these later when creating the build configurations
	NSString *prefixHeaderFilePath = @"", *infoPlistPath = @"";

	// Now, supporting files.
	NSString *supportingGroupUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *supportingGroupISA = @"PBXGroup";
	NSMutableArray *supportingGroupChildren = NSMutableArray.new;
	NSString *supportingGroupName = @"Supporting Group";
	NSString *supportingGroupSourceTree = @"<group>";

	// Create supporting file refs and if neccesary create build files
	for (NSString *supportingFilePath in supportingFiles) {
		NSString *fileRefUUID = getRandomStringWithLengthAlpha(24,YES);
		NSString *fileRefISA = @"PBXFileReference";
		NSString *fileRefPath = supportingFilePath;
		NSString *fileRefSourceTree = @"<group>";
		NSDictionary *fileRef = @{@"isa": fileRefISA, @"path": fileRefPath, @"sourceTree": fileRefSourceTree};
		[objects setValue:fileRef forKey:fileRefUUID];
		[supportingGroupChildren addObject:fileRefUUID];

		if ([[supportingFilePath pathExtension] isEqualToString:@"m"]) {
			// This is an implementation file, add to sources build phase
			NSString *buildFileUUID = getRandomStringWithLengthAlpha(24,YES);
			NSString *buildFileISA = @"PBXBuildFile";
			NSDictionary *buildFile = @{@"isa": buildFileISA, @"fileRef": fileRefUUID};
			[objects setValue:buildFile forKey:buildFileUUID];
			[sourcesBuildPhaseFiles addObject:buildFileUUID];
		} else if ([[supportingFilePath pathExtension] isEqualToString:@"m"] || [[supportingFilePath pathExtension] isEqualToString:@"m"]) {
			// This is a '.strings' file most likely Info-Plist.strings OR a '.xib' file
			NSString *buildFileUUID = getRandomStringWithLengthAlpha(24,YES);
			NSString *buildFileISA = @"PBXBuildFile";
			NSDictionary *buildFile = @{@"isa": buildFileISA, @"fileRef": fileRefUUID};
			[objects setValue:buildFile forKey:buildFileUUID];
			[resourcesBuildPhaseFiles addObject:buildFileUUID];
		}

		// Quick theck for .pch or .plist file, if found store path into previously created variables
		if ([[supportingFilePath pathExtension] isEqualToString:@"pch"])
			prefixHeaderFilePath = supportingFilePath;
		else if ([[supportingFilePath pathExtension] isEqualToString:@"plist"])
			infoPlistPath = supportingFilePath;
	}

	NSDictionary *supportingGroup = @{@"isa": supportingGroupISA, @"children": supportingGroupChildren, @"name": supportingGroupName, @"sourceTree": supportingGroupSourceTree};
	[objects setValue:supportingGroup forKey:supportingGroupUUID];

	// Now, primary class files.
	NSString *primaryClassesGroupUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *primaryClassesGroupISA = @"PBXGroup";
	NSMutableArray *primaryClassesGroupChildren = NSMutableArray.new;
	NSString *primaryClassesGroupName = projectName; // This is simply the project name. This maintains backwards compatability with Xcode 3 as it uses 'name' rather than 'path'
	NSString *primaryClassesGroupSourceTree = @"<group>";

	// Create primary classes file refs and if neccesary create build files
	for (NSString *sourceFilePath in sourceFiles) {
		NSString   * fileRefUUID = getRandomStringWithLengthAlpha(24,YES),
		* fileRefISA = @"PBXFileReference",
		* fileRefPath = sourceFilePath,
		* fileRefSourceTree = @"<group>";
		NSDictionary 	* fileRef = @{@"isa": fileRefISA, @"path": fileRefPath, @"sourceTree": fileRefSourceTree};
		[objects setValue:fileRef forKey:fileRefUUID];
		[primaryClassesGroupChildren addObject:fileRefUUID];

		if ([[sourceFilePath pathExtension] isEqualToString:@"m"]) {
			// This is an implementation file, add to sources build phase
			NSString *buildFileUUID = getRandomStringWithLengthAlpha(24,YES);
			NSString *buildFileISA = @"PBXBuildFile";
			NSDictionary *buildFile = @{@"isa": buildFileISA, @"fileRef": fileRefUUID};
			[objects setValue:buildFile forKey:buildFileUUID];
			[sourcesBuildPhaseFiles addObject:buildFileUUID];
		} else if ([[sourceFilePath pathExtension] isEqualToString:@"m"] || [[sourceFilePath pathExtension] isEqualToString:@"m"]) {
			// This is a '.strings' file most likely Info-Plist.strings OR a '.xib' file
			NSString *buildFileUUID = getRandomStringWithLengthAlpha(24,YES);
			NSString *buildFileISA = @"PBXBuildFile";
			NSDictionary *buildFile = @{@"isa": buildFileISA, @"fileRef": fileRefUUID};
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

	NSDictionary *primaryClassesGroup = @{@"isa": primaryClassesGroupISA, @"children": primaryClassesGroupChildren, @"name": primaryClassesGroupName, @"sourceTree": primaryClassesGroupSourceTree};
	[objects setValue:primaryClassesGroup forKey:primaryClassesGroupUUID];

	// Now, the products group with just a single file; the '.app' file
	NSString *productsGroupUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *productsGroupISA = @"PBXGroup";
	NSMutableArray *productsGroupChildren = NSMutableArray.new;
	NSString *productsGroupName = @"Products";
	NSString *productsGroupSourceTree = @"<group>";

	// Create the '.app' file as a child
	NSString *productAppUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *productAppISA = @"PBXFileReference";
	NSString *productAppExplicitFileType = @"wrapper.application";
	NSString *productAppIncludeInIndex = @"0";
	NSString *productAppPath = [projectName stringByAppendingFormat:@".app"];
	NSString *productAppSourceTree = @"BUILT_PRODUCTS_DIR";
	NSDictionary *productApp = @{@"isa": productAppISA, @"explicitFileType": productAppExplicitFileType, @"includeInIndex": productAppIncludeInIndex, @"path": productAppPath, @"sourceTree": productAppSourceTree};
	[objects setValue:productApp forKey:productAppUUID];
	[productsGroupChildren addObject:productAppUUID];

	NSDictionary *productsGroup = @{@"isa": productsGroupISA, @"children": productsGroupChildren, @"name": productsGroupName, @"sourceTree": productsGroupSourceTree};
	[objects setValue:productsGroup forKey:productsGroupUUID];

	// Final stage of dealing with files now, creating the root project group
	NSString *rootProjectGroupUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *rootProjectISA = @"PBXGroup";
	NSArray *rootProjectGroupChildren = @[primaryClassesGroupUUID, frameworksGroupUUID, productsGroupUUID];
	NSString *rootProjectGroupSourceTree = @"<group>";
	NSDictionary *rootProject = @{@"isa": rootProjectISA, @"children": rootProjectGroupChildren, @"sourceTree": rootProjectGroupSourceTree};
	[objects setValue:rootProject forKey:rootProjectGroupUUID];

	// Now we create and add the remining two build phases, the source build phase and resources build phase using the arrays we built earlier
	NSString *resourcesBuildPhaseUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *resourcesBuildPhaseISA = @"PBXSourcesBuildPhase";
	NSString *resourcesBuildPhaseBuildActionMask = @"2147483647";
	NSString *resourcesBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";
	NSDictionary *resourcesBuildPhase = @{@"isa": resourcesBuildPhaseISA, @"buildActionMask": resourcesBuildPhaseBuildActionMask, @"files": resourcesBuildPhaseFiles, @"runOnlyForDeploymentPostprocessing": resourcesBuildPhaseRunOnlyForDeploymentPostprocessing};
	[objects setValue:resourcesBuildPhase forKey:resourcesBuildPhaseUUID];

	NSString *sourcesBuildPhaseUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *sourcesBuildPhaseISA = @"PBXSourcesBuildPhase";
	NSString *sourcesBuildPhaseBuildActionMask = @"2147483647";
	NSString *sourcesBuildPhaseRunOnlyForDeploymentPostprocessing = @"0";
	NSDictionary *sourcesBuildPhase = @{@"isa": sourcesBuildPhaseISA, @"buildActionMask": sourcesBuildPhaseBuildActionMask, @"files": sourcesBuildPhaseFiles, @"runOnlyForDeploymentPostprocessing": sourcesBuildPhaseRunOnlyForDeploymentPostprocessing};
	[objects setValue:sourcesBuildPhase forKey:sourcesBuildPhaseUUID];

	/*
	 So that's most if not all the hassle with files and build files and build phases and what not sorted. Phew! That's gotta be it, right? No. We've still got to sort out the even more compicated build configurations. Yay!
	 We start right at the bottom with the 4 build configurations, 2 for debug, 2 for release. For some reason xcode has one for the project itself and one for the target, hence why there are 2 of each.
	 */

	if (prefixHeaderFilePath == NULL || infoPlistPath == NULL) // Make sure we have a prefix header file and info.plist file in the files we've added as they are required for creating the build configuration files
		return NO;

	// First build configurations for the target. Some have the same value, so they are bit mixed up but the names of the variable should be enough to identify which is which.
	NSString *targetDebugBuildConfigurationUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *targetReleaseBuildConfigurationUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *targetDebugBuildConfigurationName = @"Debug";
	NSString *targetReleaseBuildConfigurationName = @"Release";
	NSString *targetBuildConfigurationISA = @"XCBuildConfiguration";
	NSMutableDictionary *targetBuildConfigurationBuildSettings = NSMutableDictionary.new;

	[targetBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_PRECOMPILE_PREFIX_HEADER"];
	[targetBuildConfigurationBuildSettings setValue:prefixHeaderFilePath forKey:@"GCC_PREFIX_HEADER"];
	[targetBuildConfigurationBuildSettings setValue:infoPlistPath forKey:@"INFOPLIST_FILE"];
	[targetBuildConfigurationBuildSettings setValue:@"$(TARGET_NAME)" forKey:@"PRODUCT_NAME"];
	[targetBuildConfigurationBuildSettings setValue:@"app" forKey:@"WRAPPER_EXTENSION"];

	NSDictionary *targetDebugBuildConfiguation = @{@"isa": targetBuildConfigurationISA, @"buildSettings": targetBuildConfigurationBuildSettings, @"name": targetDebugBuildConfigurationName};
	NSDictionary *targetReleaseBuildConfiguation = @{@"isa": targetBuildConfigurationISA, @"buildSettings": targetBuildConfigurationBuildSettings, @"name": targetReleaseBuildConfigurationName};
	[objects setValue:targetDebugBuildConfiguation forKey:targetDebugBuildConfigurationUUID];
	[objects setValue:targetReleaseBuildConfiguation forKey:targetReleaseBuildConfigurationUUID];

	// Now onto the build configurations for the project, many more settings this time. Only some of the variables are the same this time so i'll split them up between debug and release. NOTE: There are two settings I don't add, one is the code sign identity because there is now way of choosing one. And second is the option to enable ARC (automatic reference counting) because at the current time (18/06/11) it is still only available in Xcode 4.2 which is in beta
	NSString *projectDebugBuildConfigurationUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *projectDebugBuildConfigurationISA = @"XCBuildConfiguration";
	NSString *projectDebugBuildConfigurationName = @"Debug";
	NSDictionary *projectDebugBuildConfigurationBuildSettings = NSMutableDictionary.new;

	[projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"ALWAYS_SEARCH_USER_PATHS"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"$(ARCHS_STANDARD_32_BIT)" forKey:@"ARCHS"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"gnu99" forKey:@"GCC_C_LANGUAGE_STANDARD"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"COPY_PHASE_STRIP"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"GCC_DYNAMIC_NO_PIC"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"0" forKey:@"GCC_OPTIMIZATION_LEVEL"];
	[projectDebugBuildConfigurationBuildSettings setValue:@[@"DEBUG=1", @"$(inherited)"] forKey:@"GCC_PREPROCESSOR_DEFINITIONS"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"NO" forKey:@"GCC_SYMBOLS_PRIVATE_EXTERN"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"com.apple.compilers.llvm.clang.1_0" forKey:@"GCC_VERSION"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_MISSING_PROTOTYPES"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_ABOUT_RETURN_TYPE"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"YES" forKey:@"GCC_WARN_UNUSED_VARIABLE"];
	[projectDebugBuildConfigurationBuildSettings setValue:iOSVersion forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
	[projectDebugBuildConfigurationBuildSettings setValue:@"iphoneos" forKey:@"SDKROOT"];

	NSDictionary *projectDebugBuildConfiguration = @{@"isa": projectDebugBuildConfigurationISA, @"buildSettings": projectDebugBuildConfigurationBuildSettings, @"name": projectDebugBuildConfigurationName};
	[objects setValue:projectDebugBuildConfiguration forKey:projectDebugBuildConfigurationUUID];

	// Now create the release config
	NSString *projectReleaseBuildConfigurationUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *projectReleaseBuildConfigurationISA = @"XCBuildConfiguration";
	NSString *projectReleaseBuildConfigurationName  = @"Release";
	NSDictionary *projectReleaseBuildConfigurationBuildSettings = NSMutableDictionary.new;

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

	NSDictionary *projectReleaseBuildConfiguration = @{@"isa": projectReleaseBuildConfigurationISA, @"buildSettings": projectReleaseBuildConfigurationBuildSettings, @"name": projectReleaseBuildConfigurationName};
	[objects setValue:projectReleaseBuildConfiguration forKey:projectReleaseBuildConfigurationUUID];

	// Now we move on to the configuration lists, one for the project, one for the target. Again variables are the same for both dictionarys except for the buildConfigs themselves so I'll do it all in one go.
	NSString *projectConfigurationListUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *targetConfigurationListUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *configurationListISA = @"XCConfigurationList";
	NSString *configurationListDefaultConfigurationIsVisible = @"0";
	NSString *configurationListDefaultConfigurationName = @"Release";
	NSArray *projectConfigurationListBuildConfigurations = @[projectDebugBuildConfigurationUUID, projectReleaseBuildConfigurationUUID];
	NSArray *targetConfigurationListBuildConfigurations = @[targetDebugBuildConfigurationUUID, targetReleaseBuildConfigurationUUID];

	NSDictionary *projectConfigurationList = @{@"isa": configurationListISA, @"defaultConfigurationIsVisible": configurationListDefaultConfigurationIsVisible, @"defaultConfigurationName": configurationListDefaultConfigurationName, @"buildConfigurations": projectConfigurationListBuildConfigurations};
	NSDictionary *targetConfigurationList = @{@"isa": configurationListISA, @"defaultConfigurationIsVisible": configurationListDefaultConfigurationIsVisible, @"defaultConfigurationName": configurationListDefaultConfigurationName, @"buildConfigurations": targetConfigurationListBuildConfigurations};
	[objects setValue:projectConfigurationList forKey:projectConfigurationListUUID];
	[objects setValue:targetConfigurationList forKey:targetConfigurationListUUID];

	// We are nearing the end. Only two things left to do; create the target and then finally the root project object. Firstly though the target…
	NSString *nativeTargetUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *nativeTargetISA = @"PBXNativeTarget";
	NSString *nativeTargetBuildConfigurationList = targetConfigurationListUUID;
	NSArray *nativeTargetBuildPhases = @[sourcesBuildPhaseUUID, frameworksBuildPhaseUUID, resourcesBuildPhaseUUID];
	NSArray *nativeTargetBuildRules = @[];
	NSArray *nativeTargetDependencies = @[];
	NSString *nativeTargetName = projectName;
	NSString *nativeTargetProductName = projectName;
	NSString *nativeTargetProductReference = productAppUUID;
	NSString *nativeTargetProductType = @"com.apple.product-type.application";
	NSDictionary *nativeTarget = @{@"isa": nativeTargetISA, @"buildConfigurationList": nativeTargetBuildConfigurationList, @"buildPhases": nativeTargetBuildPhases, @"buildRules": nativeTargetBuildRules, @"dependencies": nativeTargetDependencies, @"name": nativeTargetName, @"productName": nativeTargetProductName, @"productReference": nativeTargetProductReference, @"productType": nativeTargetProductType};
	[objects setValue:nativeTarget forKey:nativeTargetUUID];

	// Now the last piece of puzzle, the root project object…
	NSString *projectObjectUUID = getRandomStringWithLengthAlpha(24,YES);
	NSString *projectObjectISA = @"PBXProject";
	NSString *projectObjectBuildConfigurationList = projectConfigurationListUUID;
	NSString *projectObjectCompatibilityVersion = @"Xcode 3.2";
	NSString *projectObjectDevelopmentRegion = @"English";
	NSString *projectObjectHasScannedForEncodings = @"0";
	NSArray *projectObjectKnowRegions = @[@"en"];
	NSString *projectObjectMainGroup = rootProjectGroupUUID;
	NSString *projectObjectProductRefGroup = productsGroupUUID;
	NSString *projectObjectProjectDirPath = @"";
	NSString *projectObjectProjectRoot = @"";
	NSArray *projectObjectTargets = @[nativeTargetUUID];
	NSDictionary *projectObject = @{@"isa": projectObjectISA, @"buildConfigurationList": projectObjectBuildConfigurationList, @"compatibilityVersion": projectObjectCompatibilityVersion, @"developmentRegion": projectObjectDevelopmentRegion, @"hasScannedForEncodings": projectObjectHasScannedForEncodings, @"knownRegions": projectObjectKnowRegions, @"mainGroup": projectObjectMainGroup, @"productRefGroup": projectObjectProductRefGroup, @"dirPath": projectObjectProjectDirPath, @"projectRoot": projectObjectProjectRoot, @"targets": projectObjectTargets};
	[objects setValue:projectObject forKey:projectObjectUUID];

	// Wow, that's it pretty much all done. Know we just need to create the pbxproj and xcodeproj file
	// Set this to the correct UUID
	projectRootObject = projectObjectUUID;

	// Now create the dictionary which glues everything together
	NSDictionary *pbxProjDictionary = @{@"archiveVersion": archiveVersion, @"classes": classes, @"objectVersion": objectVersion, @"objects": objects, @"rootObject": projectRootObject};

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

- (NSArray*) uuidsOfChildrenOfItemWithUUID: (NSString*)uuid {

	if (!_sourceData) // Data not parsed, make sure you call parseXcodeProject before using this or any other method
		return nil;
	NSDictionary *objects = self.sourceData[@"objects"];
	NSDictionary *item = [objects valueForKey:uuid];

	if (!item) // Item doesn't exist. Incorrect uuid.
		return nil;
	if (![[item valueForKey:@"isa"] isEqualToString:@"PBXGroup"]) // Make sure we're trying to get the children of a group otherwise we know there won't be any children in a file or whatevery else
		return nil;

	NSArray *children = [item valueForKey:@"children"];

	return children;
}

-  (NSUInteger) numberOfChildrenOfItemWithUUID:(NSString*)uuid {
	NSArray *children = [self uuidsOfChildrenOfItemWithUUID:uuid];
	return children.count;
}
- (XcodeObject*) itemWithUUID:(NSString*)uuid {
	if (!_sourceData) // Data not parsed, make sure you call parseXcodeProject before using this or any other method
		return nil;

	XcodeObject *objects = _sourceData[@"objects"];
	return objects[uuid] ?: nil; // Item doesn't exist. Incorrect uuid.
}

- (NSDictionary*) itemWithUUIDAsNSDictionary:(NSString *)uuid
{
    if (!_sourceData) // Data not parsed, make sure you call parseXcodeProject before using this or any other method
		return nil;
    
	NSDictionary *objects = _sourceData[@"objects"];
	return objects[uuid] ?: nil; // Item doesn't exist. Incorrect uuid.
}


- (NSString*) nameOfItemWithUUID:(NSString*)uuid {

	return [self itemWithUUID:uuid][@"name"] ?: [self itemWithUUID:uuid][@"path"] != nil
			? [[self itemWithUUID:uuid][@"path"] lastPathComponent] : nil;
}

//- (NSDictionary*) parentOfItemWithUUID:(NSString*)uuid {
- (XcodeObject*) parentOfItemWithUUID:(NSString*)uuid {
	NSDictionary *objects = self.sourceData[@"objects"];

	for (NSString *element in objects) {
//		NSDictionary *item = [objects valueForKey:element];
		XcodeObject *item = [objects valueForKey:element];
		NSArray *children = [item valueForKey:@"children"];
		if (!children)
			continue;
        
		if ([children containsObject:uuid]) {
//			NSMutableDictionary *customItem = [item mutableCopy];
			XcodeObject *customItem = [item mutableCopy];
			[customItem setValue:element forKey:@"uuid"]; // Do this to help users of this method get the uuid
			return customItem;
		}
	}

	return nil; // No parent, unlikely but can happen
}

#pragma mark - Internal Methods (Deals with build phases)

- (BOOL)_removeFileWithUUID:(NSString *)uuid fromBuildPhase:(XCDBuildPhase)buildPhase {
	if (buildPhase == XCDSourceBuildPhase) {
		NSArray *objects = [self.sourceData valueForKey:@"objects"];
		NSString *targetUUID = [self.rootObject valueForKey:@"targets"][0]; // Choose which target to use from array, beware that an large project can have more than one target in this case you should have allowed the user to choose the target
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
		NSMutableArray *sourcesFilesToRemove = NSMutableArray.new;

		for (NSString *buildRefUUID in sourcesFiles) {
			NSDictionary *buildRef = [objects valueForKey:buildRefUUID];
			NSString *fileRefUUID = [buildRef valueForKey:@"fileRef"];
			if ([fileRefUUID isEqualToString:uuid])
				[sourcesFilesToRemove addObject:buildRefUUID];
		}

		[sourcesFiles removeObjectsInArray:sourcesFilesToRemove];

		sourcesBuildPhase[@"files"] = sourcesFiles;

		// Relay info back to main dictionary
		self.sourceData[@"objects"][sourcesBuildPhaseUUID] = sourcesBuildPhase;
	}
	return YES;
}

#pragma mark - Exporting

static int timeout = 5,  currentNum = 0;

- (BOOL) exportFilesFromProjectIntoFolderAtPath:(NSString*)destinationPath		 	{
	// Set up some variables
	NSDictionary *objects = [self.sourceData valueForKey:@"objects"];
	BOOL delegateRespondsToStatusChanged = [self.exportDelegate respondsToSelector:@selector(statusChangedTo:withFile:)];

	// First let's Check whether files are in same folder as project (Xcode 3) or in seperate folder which is entitled the proj title (Xcode 4)
	NSString *enclosingFolderPath = [self.filePath stringByDeletingLastPathComponent];
	NSString *possibleFolderLocation = [self.filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:_filePath.lastPathComponent.stringByDeletingPathExtension];
	BOOL isDirectory = NO;
	BOOL folderExists = [NSFileManager.defaultManager fileExistsAtPath:possibleFolderLocation isDirectory:&isDirectory];
	NSError *error = NULL;
	NSString *originalDestinationPath = [destinationPath copy];

	if (delegateRespondsToStatusChanged)
		[_exportDelegate statusChangedTo:XCDExportStatusBegun withFile:nil];

	if (delegateRespondsToStatusChanged)
		[_exportDelegate statusChangedTo:XCDExportStatusPreProcessing withFile:nil];

	if (folderExists && isDirectory) {
		// Adjust the encolsing folder path to match
		enclosingFolderPath = possibleFolderLocation;
		// Adjust destination path then create that directory
		destinationPath = [destinationPath stringByAppendingPathComponent:self.filePath.lastPathComponent.stringByDeletingPathExtension];
		[[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO attributes:NULL error:&error];
		if (error != NULL) {
			if (!delegateRespondsToStatusChanged) {
				// Raise exception
				NSString *title = @"Directory creation error";
				NSString *format = [NSString stringWithFormat:@"An error occured while attempting to create the primary enclosing directory during the process of copying the Xcode projects files. The cause of the problem was the folder located at '%@' relative to the ROOT when trying to be created at '%@'. The provided user info is as follows: %@", enclosingFolderPath, destinationPath, error.userInfo];
				[NSException raise:title format:format, nil];
			}
			// Inform delegate
			if (delegateRespondsToStatusChanged) [_exportDelegate statusChangedTo:XCDExportStatusFailure withFile:enclosingFolderPath];
			return NO;
		}
	}

	error = NULL;

	// Let's loop through the dictionary's keys and check for file references and add the paths to the array
	NSMutableArray *filePaths = NSMutableArray.new;

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
			[self.exportDelegate statusChangedTo:XCDExportStatusProcessing withFile:originalFilePath];

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
						[NSException raise:title format:format, nil];
						NSLog(@"%@", format);
					}
					// Inform delegate
					if (delegateRespondsToStatusChanged) 	[self.exportDelegate statusChangedTo:XCDExportStatusFailure withFile:upperPath];
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
				[NSException raise:title format:format, nil];
			}
			// Inform delegate
			if (delegateRespondsToStatusChanged) [self.exportDelegate statusChangedTo:XCDExportStatusFailure withFile:path];
		}
	}

	error = NULL;

	// Now copy the xcode project
	NSString *xcodeProjectDestinationPath = [originalDestinationPath stringByAppendingPathComponent:self.filePath.lastPathComponent];

	// Inform delegate of current stage
	if (delegateRespondsToStatusChanged) [self.exportDelegate statusChangedTo:XCDExportStatusProcessing withFile:self.filePath];

	[NSFileManager.defaultManager copyItemAtPath:self.filePath toPath:xcodeProjectDestinationPath error:&error]; // !!! : <-- Here

	if (error != NULL) {
		// Raise exception
		if (!delegateRespondsToStatusChanged) {
			[NSException raise: @"Copy error" format:@"An error occured while attempting to copy the Xcode project itself. The cause of the problem was the xcode project located at '%@' when trying to be copied to '%@'. The provided user info is as follows: %@", self.filePath, xcodeProjectDestinationPath, error.userInfo, nil];
		}
		if (delegateRespondsToStatusChanged)	// Inform delegate
			[self.exportDelegate statusChangedTo:XCDExportStatusFailure withFile:self.filePath];
	}
	// Inform delegate of completion
	if (delegateRespondsToStatusChanged) [self.exportDelegate statusChangedTo:XCDExportStatusComplete withFile:nil];
	return YES;
}
- (NSString*)_correctedFilePathForPathContainingElipsis:	(NSString*)path 						{	return path; }
- (NSString*)_correctedFilePathForItemAtPath:				(NSString*)path
												withUUID:				(NSString*)uuid
									inEnclosingFolder:				(NSString*)enclosingFolderPath 	{
	NSString *originalPath = [path copy];
	if (currentNum > timeout)
		return originalPath;
	currentNum++;
//	NSDictionary *parent = [self parentOfItemWithUUID:uuid];
	XcodeObject *parent = [self parentOfItemWithUUID:uuid];
	NSString *parentName = [parent valueForKey:@"name"];
	if (parentName == nil)
		parentName = [parent valueForKey:@"path"];
	NSString *possibleNewLocation = [[enclosingFolderPath stringByAppendingPathComponent:parentName] stringByAppendingPathComponent:path];
	// Check if that exists, if so then adjust the path. If not try again
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:possibleNewLocation];
	//    if (isDropbox)
	//        fileExists = [self _dropboxFileExistsAtPath:path metadata:nil];
	if (fileExists) {
		path = [parentName stringByAppendingPathComponent:path];
	} else if (!fileExists) { // Check parent of parent
		path = [self _correctedFilePathForItemAtPath:path withUUID:[parent valueForKey:@"uuid"] inEnclosingFolder:enclosingFolderPath];
	}
	currentNum = 0;
	return path;
}

@end


//@interface WeakReference : NSObject { id parent; }
//+   (id) weakReferenceWithParent:(id)parent;
//- (void) setParent:(id)_parent;
//- 	 (id) parent;
//@end
//@implementation WeakReference
//+   (id) weakReferenceWithParent:(id)parent { id weakRef = WeakReference.new; [weakRef setParent:parent]; return weakRef; }
//- (void) setParent:(id)p {  parent= p; }
//-(id) parent {  return parent;
//}
//@end
