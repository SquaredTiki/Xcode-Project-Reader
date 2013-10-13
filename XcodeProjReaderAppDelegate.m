
//  XcodeProjReaderAppDelegate.m - XcodeProjReader
//  Created by Joshua Garnham on 08/05/2011. Edited by Alex Gray on 10/7/13

#import <QuartzCore/QuartzCore.h>
#import "XcodeProjReaderAppDelegate.h"
#import "XCDProjectCoordinator.h"
#import "XcodeObject.h"

#pragma mark - main.m

int main(int argc, char *argv[])	{   return NSApplicationMain(argc, (const char**) argv); }

#pragma mark - TableRowView ... see Id in IB of "NSTableViewRowViewKey"

@implementation ColorTableRowView @synthesize  x = _objectValue;

- (XcodeObject*) x {  id ov = self.superview; int i = 6; 		 // Sneaky object finder
	while (i > 0 && ![ov isKindOfClass:NSOutlineView.class]) { ov = [ov superview]; i--; }
	return [[ov itemAtRow:[ov selectedRow]] representedObject];
}
- (void) awakeFromNib {	self.layer = CALayer.new; self.layer.delegate = self; self.wantsLayer = YES;
	[self.layer bind:@"colored" toObject:self withKeyPath:@"selected" options:nil];
}
- (id<CAAction>) actionForLayer:(CALayer*)l forKey:(NSString *)e { 		CABasicAnimation *ca;

	if ([e isEqualToString:@"colored"]) {   // Layer backed actio delegate
 		ca = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
		NSLog(@"self.x.parent::%@", self.x.parent);
		NSColor  *c1 	=	(self.x.parent == nil) ?
								[NSColor colorWithDeviceHue:0.168 saturation:0.942 brightness:0.612 alpha:1.000]:
								[NSColor colorWithCalibratedRed:.78  green:0.772 blue:0.020 alpha:1.000],
					*c2 	= 	[NSColor colorWithCalibratedRed:0.779 green:0.247 blue:0.020 alpha:1.000];
		ca.fromValue 	= self.selected ?(id) c1.CGColor : (id)c2.CGColor;
		ca.toValue 		= self.selected ?  (id)c2.CGColor :(id) c1.CGColor;
		ca.duration 	= 2;
		ca.fillMode 	= kCAFillModeForwards;
		ca.removedOnCompletion  = NO;
		return ca;
	}
	return ca;
}
@end

@implementation XcodeProjReaderAppDelegate

- (void) awakeFromNib
{
	[_projLocField addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:0];
	self.projLocField.URL = [NSURL URLWithString:[NSString stringWithFormat:
			@"%s/TestProject/TestProject.xcodeproj", getenv("PROJECT_FOLDER")]];
}
- (void) observeValueForKeyPath:(NSString *)kP ofObject:(id)o change:(NSDictionary *)chg context:(void *)ctx
{
	if ([kP isEqualToString:@"URL"])	_parseButton.enabled = [o valueForKey:kP] != nil;
}
- (IBAction) browseForXcodeProject:(id)sender	{ NSOpenPanel *p = NSOpenPanel.openPanel;

	 p.allowsMultipleSelection 	= NO;
 	 p.allowedFileTypes				= @[@"xcodeproj"];
	[p beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {

		if (result == NSOKButton && NSOpenPanel.openPanel.URLs.count)
			_projLocField.URL = NSOpenPanel.openPanel.URLs[0];
	}];
}
- (IBAction)parseCurrentlyLocatedXcodeProject:(id)sender
{
	self.projectCoordinator = [XCDProjectCoordinator.alloc initWithProjectAtPath:self.projLocField.URL.path];
	NSLog(@"project: %@", _projectCoordinator);
	[_projectCoordinator willChangeValueForKey:@"files"];
	[_projectCoordinator parseXcodeProject];
	[_projectCoordinator didChangeValueForKey:@"files"];
}

#pragma mark - Adding and Removing Items

- (void) runAlertWithMessage:(NSString*)message {	NSAlert *alert = NSAlert.new;

	 alert.messageText	 	= @"Error adding item";	 alert.informativeText	= message;
	 alert.alertStyle 		= NSWarningAlertStyle;	[alert addButtonWithTitle:@"OK"];	 	[alert runModal];
}
- (NSString*) selectedUUID
{
	return _outlineView.selectedRow > 0 ? [[_outlineView itemAtRow:_outlineView.selectedRow]representedObject][@"uuid"]  : nil;
}
- (IBAction) segmentAction:(id)x {  NSInteger idx = ((NSSegmentedControl*)x).selectedSegment;

	 idx == 0 ? ^{	[_projectCoordinator	removeItemWithUUID:self.selectedUUID];
						[self parseCurrentlyLocatedXcodeProject:self];																			}()
	:idx == 1 ? ^{	[_projectCoordinator addFileWithRelativePath:self.titleField.stringValue
													  asChildToItemWithUUID:self.selectedUUID]
				 ?		[self parseCurrentlyLocatedXcodeProject:self]
				 :	   [self runAlertWithMessage:	@"A new item could not be added likely because no title was "
															 "entered or the item was trying to be added to a file."];									}()
				 : ^{	[_projectCoordinator addGroupWithTitle:self.titleField.stringValue
				 										toItemWithUUID:self.selectedUUID]
				 ? 	[self parseCurrentlyLocatedXcodeProject:self]
				 :	   [self runAlertWithMessage:@"A new group could not be added likely because no title was "
															"entered or the item was trying to be added to a file."];									}();
}
- (id) selection { return  [[_outlineView itemAtRow:_outlineView.selectedRow] representedObject]; }

#pragma mark - Outline View Delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)note {

	id x, z; if ((x = self.selection)) [_actions setEnabled:YES forSegment:0]; else return;
	BOOL canAdd = ((z = x[@"parent"])); 	NSLog(@"Parent: %@", z);
	[_actions setEnabled:canAdd forSegment:1];
	[_actions setEnabled:canAdd forSegment:2];
}
- (void)outlineViewItemWillExpand:(NSNotification *)note { [_expandedItems = _expandedItems ?: NSMutableArray.new addObject:note.object]; }

/* Disabled in favor of NSTreeController bindings for View-based table...

- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item { return  [_expandedItems containsObject:item]; }
- (BOOL) outlineView:(NSOutlineView*)ov isGroupItem:(id)item {
 	if ((item != nil) && ([item isKindOfClass:NSDictionary.class]))	NSLog(@"item: %@", [item valueForKey:@"name"]);
	id x = [item representedObject][@"parent"]; NSLog(@"x %@", x); return x == NSNull.null || x == nil;
}

#pragma mark - Outline View Datasource

-(BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
	return ![self childrenOfItem:item] || [self childrenOfItem:item].count<1 ? NO : YES;
}
-(int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
	return [self childrenOfItem:item].count;
}
-(id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item
{
	return ![self childrenOfItem:item] || [self childrenOfItem:item].count <= index ? nil
			: [self childrenOfItem:item][index];
}
-(id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tc byItem:(id)item {
	return [item valueForKey:tc.identifier];
}*/

@end



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