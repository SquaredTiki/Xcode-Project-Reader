//
//  XCDProjectCoordinator.h
//  XcodeProjReader
//
//  Created by Joshua Garnham on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    XCDExportStatusBegun,
    XCDExportStatusPreProcessing,
    XCDExportStatusProcessing,
    XCDExportStatusComplete,
    XCDExportStatusFailure
} XCDExportStatus;

@protocol XCDProjectCoordinatorExportStatusDelegate <NSObject>
- (void)statusChangedTo:(XCDExportStatus)status withFile:(NSString *)filePath;
@end

typedef enum {
    XCDSourceBuildPhase,
    XCDFrameworksBuildPhase
} XCDBuildPhase;

@interface XCDProjectCoordinator : NSObject {
    NSString *filePath; // The location of the xcode project
    
    NSString *rootObjectUUID; // The UUID of the root object
    NSDictionary *rootObject; // The root object which has references to the main group, configuration list's and targets
    
	NSString *mainGroupUUID; // The UUID of the main group
    NSDictionary *mainGroup; // The main group is the highest group, it has the name of you project it self and contains all the subfolders, e.g Classes, Other Sources, Resources etc.
    
	NSMutableDictionary *sourceData; // The original dictionary of the data from the xcode project
	
	NSMutableArray *files; // An array of nested dictionaries with value of parent, children, name and uuid. Used generally only in conjunction with NSOutlineView which requires nested dictionaries with a weak reference to the parent object 
	NSMutableString *dataString; // The orgiginal data string of the data from the xcode project
    
    int waitTime; // Internal
	int i; // Internal
    
    id <XCDProjectCoordinatorExportStatusDelegate> exportDelegate; // Delegate for keeping track when exporting the project 
    
    BOOL isDropbox; // Tells the project that it is accessing dropbox
    NSString *originalDropboxPath; // The dropbox location of the xcode project
}

@property (nonatomic, readonly) NSMutableArray *files;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *originalDropboxPath;
@property (nonatomic, readonly) NSString *rootObjectUUID;
@property (nonatomic, readonly) NSString *mainGroupUUID;
@property (nonatomic, assign) id <XCDProjectCoordinatorExportStatusDelegate> exportDelegate;

- (id)initWithProjectAtPath:(NSString *)path;

- (void)parseXcodeProject;

- (void)removeItemWithUUID:(NSString *)uuid;
- (BOOL)addGroupWithTitle:(NSString *)title toItemWithUUID:(NSString *)parentUUID;
- (BOOL)addFileWithRelativePath:(NSString *)relPath asChildToItemWithUUID:(NSString *)parentItemUUID;

- (BOOL)newProjectAtPath:(NSString *)path withFrameworks:(NSArray *)frameworks sourceFiles:(NSArray *)sourceFiles supportingFiles: (NSArray *)supportingFiles oniOSVersion:(NSString *)iOSVersion; // iOS only

- (NSArray *)uuidsOfChildrenOfItemWithUUID:(NSString *)uuid;
- (NSUInteger)numberOfChildrenOfItemWithUUID:(NSString *)uuid;

- (NSDictionary *)itemWithUUID:(NSString *)uuid;
- (NSString *)nameOfItemWithUUID:(NSString *)uuid;
- (NSDictionary *)parentOfItemWithUUID:(NSString *)uuid;

- (BOOL)exportFilesFromProjectIntoFolderAtPath:(NSString *)destinationPath;

@end
