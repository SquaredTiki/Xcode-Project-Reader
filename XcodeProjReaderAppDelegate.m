//
//  XcodeProjReaderAppDelegate.m
//  XcodeProjReader
//
//  Created by Joshua Garnham on 08/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "XcodeProjReaderAppDelegate.h"

@implementation XcodeProjReaderAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Application Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

- (IBAction)browseForXcodeProject:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
	[oPanel setAllowedFileTypes:[NSArray arrayWithObject:@"xcodeproj"]];
	
	[oPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
	    if (result == NSOKButton) {
			NSArray *selectedFiles = [oPanel URLs];
			NSURL *selectedFile = [selectedFiles objectAtIndex:0];
			filePath = [[selectedFile path] retain];
			[projLocField setStringValue:filePath];
			[parseButton setEnabled:YES];
		} else {
			[parseButton setEnabled:NO];
		}
	}];	
}

- (IBAction)parseCurrentlyLocatedXcodeProject:(id)sender {
    projectCoordinator = [[[XCDProjectCoordinator alloc] initWithProjectAtPath:filePath] retain];
	[projectCoordinator parseXcodeProject];
    [outlineView reloadData];
}

#pragma mark -
#pragma mark Adding and Removing Items

- (IBAction)remove:(id)sender {
	id item = [outlineView itemAtRow:[outlineView selectedRow]];
	NSString *uuid = [item objectForKey:@"uuid"];
	[projectCoordinator removeItemWithUUID:uuid];
    [self parseCurrentlyLocatedXcodeProject:self];
/*    NSLog(@"TEMPORARY OVERIDE");
    NSString *path = @"/Users/joshuagarnham/Desktop/MyApp/MyApp.xcodeproj";
    NSArray *frameworks = [NSArray arrayWithObjects:@"UIKit.framework", @"Foundation.framework", @"CoreGraphics.framework", nil];
    NSArray *sourceFiles = [NSArray arrayWithObjects:@"MainViewController.h", @"MainViewController.m", @"MainViewController.xib", nil];
    NSArray *supportingFiles = [NSArray arrayWithObjects:@"MyApp-Info.plist", @"InfoPlist.strings", @"main.m", @"MyApp-Prefix.pch", nil];
    NSString *iOSVersion = @"4.2.1";
    BOOL success = [self newProjectAtPath:path withFrameworks:frameworks sourceFiles:sourceFiles supportingFiles:supportingFiles oniOSVersion:iOSVersion];
    if (!success) {
        NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Error creating project"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
    } */
}

- (IBAction)addGroup:(id)sender {
	NSString *title = [newGroupTitleField stringValue];
	int selectedItemRow = [outlineView selectedRow];
	
	NSString *uuid;
	if (selectedItemRow >= 0) {
		id selectedItem = [outlineView itemAtRow:selectedItemRow];
		uuid = [selectedItem objectForKey:@"uuid"];
	} else {
		uuid = nil;
	}
	
	BOOL success = [projectCoordinator addGroupWithTitle:title toItemWithUUID:uuid];
    [self parseCurrentlyLocatedXcodeProject:self];
	if (!success) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Error adding item"];
		[alert setInformativeText:@"A new group could not be added likely because no title was entered or the item was trying to be added to a file."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
	}
}

- (IBAction)add:(id)sender {
	NSString *title = [newItemTitleField stringValue];
	int selectedItemRow = [outlineView selectedRow];
	
	NSString *uuid;
	if (selectedItemRow >= 0) {
		id selectedItem = [outlineView itemAtRow:selectedItemRow];
		uuid = [selectedItem objectForKey:@"uuid"];
	} else {
		uuid = nil;
	}
	
	BOOL success = [projectCoordinator addFileWithRelativePath:title asChildToItemWithUUID:uuid];
    [self parseCurrentlyLocatedXcodeProject:self];
	if (!success) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Error adding item"];
		[alert setInformativeText:@"A new item could not be added likely because no title was entered or the item was trying to be added to a file."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
	}
}

#pragma mark -
#pragma mark Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	if ([item objectForKey:@"parent"] == nil)
		return YES;
	return NO;
}

#pragma mark -
#pragma mark Outline View Datasource

-(BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    id children;
    if (!item) {
        children=projectCoordinator.files;
    } else {
        children=[item objectForKey:@"children"];
    }
    if ((!children) || ([children count]<1)) return NO;
    return YES;
}

-(int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    id children;
    if (!item) {
        children=projectCoordinator.files;
    } else {
        children=[item objectForKey:@"children"];
    }
    return [children count];
}

-(id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item {
    id children;
    if (!item) {
        children=projectCoordinator.files;
    } else {
        children=[item objectForKey:@"children"];
    }
    if ((!children) || ([children count]<=index)) return nil;
    return [children objectAtIndex:index];
}

-(id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return [item valueForKey:tableColumn.identifier];
}

@end
