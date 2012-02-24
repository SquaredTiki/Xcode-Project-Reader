//
//  XcodeProjReaderAppDelegate.h
//  XcodeProjReader
//
//  Created by Joshua Garnham on 08/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XCDProjectCoordinator.h"

@interface XcodeProjReaderAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    
    NSString *filePath;

	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSButton *browseButton;
	IBOutlet NSButton *parseButton;
	IBOutlet NSTextField *projLocField;
	
	IBOutlet NSTextField *newItemTitleField;
    IBOutlet NSTextField *newGroupTitleField;
    
    XCDProjectCoordinator *projectCoordinator;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)parseCurrentlyLocatedXcodeProject:(id)sender;
- (IBAction)browseForXcodeProject:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)addGroup:(id)sender;

@end
