/* CIB regression: real AppKit objects with controlled document metadata. */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import "Testing.h"
#import "../GormCIBModelGenerator.h"

@interface CibDocument : NSObject
{
@public
  GormFilesOwner *owner;
  GormFirstResponder *responder;
  NSWindow *window;
  NSButton *first;
  NSButton *second;
  NSMutableArray *links;
  NSMutableSet *roots;
}
@end
@implementation CibDocument
- (id) init
{
  self = [super init];
  if (self)
    {
      owner = [GormFilesOwner new];
      [owner setClassName: @"CibTestOwner"];
      responder = [GormFirstResponder new];
      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100, 100, 300, 200)
        styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: YES];
      [window setReleasedWhenClosed: NO];
      [window setTitle: @"CIB graph"];
      first = [[NSButton alloc] initWithFrame: NSMakeRect(20, 20, 120, 32)];
      second = [[NSButton alloc] initWithFrame: NSMakeRect(20, 70, 120, 32)];
      [first setTitle: @"First"];
      [first setButtonType: NSToggleButton];
      [first setState: NSOnState];
      [first setTag: 7];
      [first setAutoresizesSubviews: NO];
      [first setAutoresizingMask: NSViewMinYMargin];
      NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(16, 12)];
      [image setName: @"cib-test.png"];
      [first setImage: image];
      [image release];
      [second setTitle: @"Second"];
      [second setEnabled: NO];
      [second setTag: 8];
      [[window contentView] addSubview: first];
      [[window contentView] addSubview: second];
      NSScrollView *scroll = [[NSScrollView alloc] initWithFrame: NSMakeRect(160, 20, 120, 140)];
      NSView *document = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 260)];
      NSTextField *label = [[NSTextField alloc] initWithFrame: NSMakeRect(10, 20, 100, 24)];
      [label setStringValue: @"Scrolled"];
      [label setEditable: NO];
      [document addSubview: label];
      [scroll setHasVerticalScroller: YES];
      [scroll setDocumentView: document];
      [[window contentView] addSubview: scroll];
      [label release]; [document release]; [scroll release];
      roots = [[NSMutableSet alloc] initWithObjects: window, nil];
      links = [NSMutableArray new];
    }
  return self;
}
- (id) filesOwner { return owner; }
- (id) firstResponder { return responder; }
- (id) topLevelObjects { return roots; }
- (id) connections { return links; }
- (id) classManager { return self; }
- (NSString *) customClassForName: (NSString *)name
{
  return [name isEqual: @"NSButton(1)"] ? @"CibTestButton" : nil;
}
- (NSString *) nameForObject: (id)obj
{
  if (obj == first) return @"NSButton(1)";
  if (obj == second) return @"NSButton(2)";
  if (obj == owner) return @"NSOwner";
  if (obj == window) return @"Window";
  return nil;
}
- (BOOL) objectIsVisibleAtLaunch: (id)obj { return obj == window; }
- (void) dealloc
{
  [roots release]; [links release]; [first release]; [second release];
  [window release]; [owner release]; [responder release];
  [super dealloc];
}
@end

static void addConnection(CibDocument *doc, Class cls, id source, id destination, NSString *label)
{
  NSNibConnector *connector = [[cls alloc] init];
  [connector setSource: source];
  [connector setDestination: destination];
  [connector setLabel: label];
  [doc->links addObject: connector];
  [connector release];
}

int main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  CibDocument *doc = [CibDocument new];
  addConnection(doc, [NSNibOutletConnector class], doc->owner, doc->first, @"firstButton");
  addConnection(doc, [NSNibOutletConnector class], doc->owner, doc->second, @"secondButton");
  addConnection(doc, [NSNibControlConnector class], doc->first, doc->owner, @"clicked:");
  addConnection(doc, [NSNibControlConnector class], doc->second, doc->responder, @"performClose:");
  addConnection(doc, [NSNibConnector class], doc->first, [doc->window contentView], @"parent");
  /* Editor connections must never enter the runtime object graph. */
  addConnection(doc, [GormObjectToEditor class], doc->first, doc, @"editor");
  id generator = [[GormCIBModelGenerator alloc] initWithGormDocument: (id)doc];
  NSData *data = [generator data];
  PASS([data length] > 0, "the CIB graph exports")
  if (!testPassed) return 1;
  PASS([data writeToFile: [NSString stringWithUTF8String: argv[1]] atomically: YES],
       "the archive is available for independent decoder tests")
  if (!testPassed) return 1;
  NSDictionary *archive = [NSPropertyListSerialization propertyListFromData: data
    mutabilityOption: NSPropertyListImmutable format: NULL errorDescription: NULL];
  NSData *again = [generator data];
  NSDictionary *secondArchive = [NSPropertyListSerialization propertyListFromData: again
    mutabilityOption: NSPropertyListImmutable format: NULL errorDescription: NULL];
  PASS([archive isEqual: secondArchive], "repeated exports reset the UID table")
  if (!testPassed) return 1;
  NSObject *unsupported = [NSObject new];
  [doc->roots addObject: unsupported];
  PASS([generator data] == nil, "unsupported runtime classes fail instead of fabricating a CIB class")
  if (!testPassed) return 1;
  [doc->roots removeObject: unsupported];
  [unsupported release];
  PASS([[generator data] length] > 0 && [[[doc->window contentView] subviews] count] == 3,
       "a failed export leaves the graph usable for another export")
  if (!testPassed) return 1;
  [generator release]; [doc release]; [pool drain];
  return 0;
}
