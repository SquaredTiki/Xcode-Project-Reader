
//  XcodeProjReaderAppDelegate.h * XcodeProjReader
//  Created by Joshua Garnham on 08/05/2011. Edited by Alex Gray on 10/7/13

#import <Cocoa/Cocoa.h>

@class XcodeObject;
@interface ColorTableRowView : NSTableRowView
@property (readonly) XcodeObject *x;
@end

@class XCDProjectCoordinator;
@interface XcodeProjReaderAppDelegate : NSObject <NSApplicationDelegate> {
    BOOL _initialized;
}

@property (assign) IBOutlet NSWindow 			*window;
@property (weak) 	 IBOutlet NSOutlineView 	*outlineView;
@property (weak)   IBOutlet NSButton 			*parseButton;
@property (weak)   IBOutlet NSSegmentedControl 	*actions;
@property (weak)   IBOutlet NSPathControl 	*projLocField;
@property (weak)   IBOutlet NSTextField 		*titleField;

@property NSMutableArray *expandedItems;
@property XCDProjectCoordinator *projectCoordinator;

- (IBAction) parseCurrentlyLocatedXcodeProject:	(id)sender;
- (IBAction) browseForXcodeProject:					(id)sender;
- (IBAction) segmentAction:							(id)sender;

@end
