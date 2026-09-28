/* Regression checks for XIB tokens emitted from real AppKit objects.
 * Run from the repository root after building Plugins/Xib. */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import "../GormXIBArchiver.h"

@interface GormXIBArchiver (EnumTests)
- (void) _addProperty: (NSString *)name withType: (NSString *)type
           toElement: (NSXMLElement *)element fromObject: (id)object;
@end

/* Supply only document metadata; all archived controls are real AppKit
 * objects and go through the full writer rather than a mock property path. */
@interface EnumDocument : NSObject
{
  NSSet *_objects;
}
- (id) initWithObjects: (NSSet *)objects;
@end
@implementation EnumDocument
- (id) initWithObjects: (NSSet *)objects
{
  self = [super init];
  if (self) _objects = [objects retain];
  return self;
}
- (void) dealloc { [_objects release]; [super dealloc]; }
- (NSSet *) topLevelObjects { return _objects; }
- (id) filesOwner { return nil; }
- (id) servicesMenu { return nil; }
- (NSString *) nameForObject: (id)object { return nil; }
- (NSArray *) connectorsForSource: (id)object ofClass: (Class)class { return nil; }
- (void) deactivateEditors {}
- (void) reactivateEditors {}
@end

static void check(id archiver, id object, NSString *key, NSString *expected)
{
  NSXMLElement *element = [NSXMLElement elementWithName: @"test"];
  [archiver _addProperty: key withType: @"unsigned long long"
              toElement: element fromObject: object];
  NSString *actual = [[element attributeForName: key] stringValue];
  if (!(actual == expected || [actual isEqual: expected]))
    [NSException raise: @"TestFailure" format: @"%@: expected %@, got %@",
                 key, expected, actual];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  /* Ensure GormCore is linked before loading the plugin. */
  [GormDocument class];
  NSBundle *bundle = [NSBundle bundleWithPath:
    [[[NSFileManager defaultManager] currentDirectoryPath]
      stringByAppendingPathComponent: @"Plugins/Xib/Xib.plugin"]];
  if (![bundle load]) return 1;
  id archiver = [[NSClassFromString(@"GormXIBArchiver") alloc]
    initForWritingWithGormDocument: nil classNameMappings: nil];
  NSButtonCell *cell = [[NSButtonCell alloc] initTextCell: @"Button"];
  [cell setControlSize: NSRegularControlSize];
  check(archiver, cell, @"controlSize", @"regular");
  [cell setControlSize: NSSmallControlSize];
  check(archiver, cell, @"controlSize", @"small");
  [cell setControlTint: NSGraphiteControlTint];
  check(archiver, cell, @"controlTint", @"graphite");
  [cell setAllowsMixedState: YES];
  [cell setState: NSMixedState];
  check(archiver, cell, @"state", @"mixed");
  [cell setState: NSOffState];
  check(archiver, cell, @"state", nil);
  [cell setFocusRingType: NSFocusRingTypeNone];
  check(archiver, cell, @"focusRingType", @"none");
  [cell setLineBreakMode: NSLineBreakByTruncatingTail];
  check(archiver, cell, @"lineBreakMode", @"truncatingTail");
  [cell setImageScaling: NSImageScaleNone];
  check(archiver, cell, @"imageScaling", nil);
  [cell setButtonType: NSMomentaryPushInButton];
  check(archiver, cell, @"type", @"push");
  NSPopUpButton *popup = [[NSPopUpButton alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 24) pullsDown: NO];
  [popup addItemsWithTitles: [NSArray arrayWithObjects: @"One", @"Two", nil]];
  [[popup cell] setArrowPosition: NSPopUpArrowAtCenter];
  check(archiver, [popup cell], @"arrowPosition", @"arrowAtCenter");
  [popup setPreferredEdge: NSMaxYEdge];
  check(archiver, popup, @"preferredEdge", @"maxY");
  check(archiver, popup, @"nextKeyView", nil);
  check(archiver, popup, @"previousKeyView", nil);
  check(archiver, [popup cell], @"controlView", nil);
  NSBox *box = [[NSBox alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  [box setBoxType: NSBoxPrimary];
  check(archiver, box, @"boxType", @"primary");
  [box setBorderType: NSGrooveBorder];
  check(archiver, box, @"borderType", @"groove");
  [cell setTag: 23];
  check(archiver, cell, @"tag", @"23");

  NSView *view = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 400, 300)];
  [view addSubview: popup];
  [view addSubview: box];
  NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(0, 100, 90, 24)];
  [button setButtonType: NSMomentaryPushInButton];
  [button setFont: [NSFont systemFontOfSize: 13]];
  [view addSubview: button];
  [button setAlphaValue: 0.0]; // Legacy unkeyed palette archive default.
  [popup setAlphaValue: 0.5]; // Preserve a meaningful opacity setting.
  NSMatrix *matrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(120, 100, 100, 48)
    mode: NSRadioModeMatrix cellClass: [NSButtonCell class]
    numberOfRows: 2 numberOfColumns: 1];
  for (NSButtonCell *radioCell in [matrix cells])
    {
      [radioCell setButtonType: NSRadioButton];
      [radioCell setFont: [NSFont systemFontOfSize: 12]];
    }
  [view addSubview: matrix];
  [view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSView *editor = [[NSView alloc] initWithFrame: NSZeroRect];
  [editor setToolTip: @"EDITOR_MUST_NOT_BE_ARCHIVED"];
  [popup setNextKeyView: editor];
  EnumDocument *document = [[EnumDocument alloc]
    initWithObjects: [NSSet setWithObject: view]];
  NSString *error = nil;
  NSData *data = [NSClassFromString(@"GormXIBArchiver")
    dataWithGormDocument: (id)document classNameMappings: nil errorDescription: &error];
  if (data == nil)
    [NSException raise: @"TestFailure" format: @"%@", error];
  NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData: data options: 0 error: NULL];
  if (xml == nil
      || [[xml nodesForXPath: @"//popUpButton" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//buttonCell[@type='push']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//button[@alphaValue='1.0']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//popUpButton[@alphaValue='0.5']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//matrix/cells/column/buttonCell[@type='radio']"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//matrix/*[@key='cell'] | //matrix/@cell"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//font[not(@name) and not(@metaFont)]"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//buttonCell/font[@metaFont='system' and @size='13']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//autoresizingMask[@key='autoresizingMask']"
                       error: NULL] count] == 0
      || [[xml nodesForXPath: @"//*[@key='autoresizeMask']"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//*[@toolTip='EDITOR_MUST_NOT_BE_ARCHIVED']" error: NULL] count] != 0
      || [[xml nodesForXPath: @"//*[@controlSize='0' or @state='0' or @focusRingType='0' or @type='1']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid full XIB output: %@", xml];
  if ([button alphaValue] != 0.0 || [popup alphaValue] != 0.5)
    [NSException raise: @"TestFailure" format: @"Export mutated view opacity"];
  [xml release];
  [document release];
  [editor release];
  [button release];
  [matrix release];
  [view release];
  NSLog(@"XIB enum regression checks passed");
  [box release];
  [popup release];
  [cell release];
  [archiver release];
  [pool drain];
  return 0;
}
