/* Regression coverage for editing top-level views without changing their graph. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>

@interface GormViewWithContentViewEditor (TestMovement)
- (void) moveSelectionByX: (float)x andY: (float)y;
- (void) resizeSelectionByX: (float)x andY: (float)y;
@end

@interface ClickEditor : GormStandaloneViewEditor
{
@public
  id clicked;
}
@end
@implementation ClickEditor
- (void) handleMouseOnView: (GormViewEditor *)view withEvent: (NSEvent *)event
{
  clicked = [view editedObject];
  [self selectObjects: [NSArray arrayWithObject: view]];
}
@end
@interface StandaloneFixture : NSView
@end
@implementation StandaloneFixture
- (NSString *) editorClassName { return @"ClickEditor"; }
@end

int main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  START_SET("Standalone view editing")
  [NSApplication sharedApplication];
  if (argc == 2)
    {
      NSArray *graph = [NSUnarchiver unarchiveObjectWithFile:
        [NSString stringWithUTF8String: argv[1]]];
      NSView *loaded = [graph objectAtIndex: 0];
      NSNibControlConnector *connection = [graph objectAtIndex: 1];
      [connection establishConnection];
      NSButton *control = [[loaded subviews] objectAtIndex: 0];
      BOOL valid = [loaded isKindOfClass: [StandaloneFixture class]] &&
        [loaded superview] == nil && [loaded window] == nil &&
        NSEqualRects([loaded frame], NSMakeRect(37, 53, 320, 240)) &&
        NSEqualRects([control frame], NSMakeRect(45, 57, 90, 34)) &&
        [[control title] isEqual: @"Child"] && [control target] == loaded &&
        [NSStringFromSelector([control action]) isEqual: @"description"];
      RELEASE(pool);
      return valid ? 0 : 1;
    }
  NSLog(@"Editor framework: %@", [NSBundle bundleForClass:
    [GormStandaloneViewEditor class]]);
  GormDocument *doc = [GormDocument new];
  NSWindow *documentWindow = [[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 100, 100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  [documentWindow setReleasedWhenClosed: NO];
  NSWindowController *controller = [[NSWindowController alloc]
    initWithWindow: documentWindow];
  RELEASE(documentWindow);
  [doc addWindowController: controller];
  RELEASE(controller);
  NSRect original = NSMakeRect(37, 53, 320, 240);
  NSView *root = [[StandaloneFixture alloc] initWithFrame: original];
  NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(40, 50, 80, 30)];
  [button setTitle: @"Child"];
  [button setTarget: root];
  [button setAction: @selector(description)];
  [root setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [root addSubview: button];
  [doc attachObject: root toParent: nil];
  [doc attachObject: button toParent: root];
  ClickEditor *editor = (id)[doc editorForObject: root create: YES];
  NSBundle *framework = [NSBundle bundleForClass: [GormStandaloneViewEditor class]];
  NSImage *viewIcon = [[NSImage alloc] initWithContentsOfFile:
    [framework pathForImageResource: @"GormView"]];
  NSView *plainView = [[NSView alloc] initWithFrame: NSZeroRect];
  PASS([viewIcon isValid] && [[root imageForViewer] isValid] &&
       [[[root imageForViewer] TIFFRepresentation] isEqual: [viewIcon TIFFRepresentation]],
       "custom standalone views find the view icon in the GormCore bundle")
  PASS([[plainView imageForViewer] isValid] &&
       [[[plainView imageForViewer] TIFFRepresentation] isEqual: [viewIcon TIFFRepresentation]],
       "ordinary views have a document icon rather than an empty representation")
  PASS([[[editor imageForViewer] TIFFRepresentation] isEqual: [viewIcon TIFFRepresentation]],
       "the standalone editor uses the view icon rather than the unknown-object icon")
  PASS([[[editor window] backgroundColor] isEqual: [documentWindow backgroundColor]],
       "standalone views use the normal window background without a color override")
  RELEASE(plainView);
  RELEASE(viewIcon);
  PASS(NSEqualRects([root frame], original), "opening preserves the standalone frame")
  PASS([editor isOpened], "standalone content is immediately open for editing")
  id childEditor = [doc editorForObject: button create: NO];
  PASS(childEditor != nil && [button superview] == childEditor,
       "existing controls have active editors")
  PASS([doc isTopLevelObject: root] && ![doc isTopLevelObject: [editor window]],
       "the host window is not a document object")

  NSPoint point = [button convertPoint: NSMakePoint(40, 15) toView: nil];
  NSEvent *event = [NSEvent mouseEventWithType: NSLeftMouseDown
    location: point modifierFlags: 0 timestamp: 0
    windowNumber: [[editor window] windowNumber] context: nil
    eventNumber: 1 clickCount: 1 pressure: 1];
  [editor mouseDown: event];
  PASS(editor->clicked == button && [[editor selection] containsObject: button],
       "clicks at a nonzero root origin select the child control")
  [editor moveSelectionByX: 5 andY: 7];
  PASS(NSEqualPoints([button frame].origin, NSMakePoint(45, 57)),
       "selected controls use the ordinary movement path")
  [editor resizeSelectionByX: 10 andY: 4];
  PASS(NSEqualSizes([button frame].size, NSMakeSize(90, 34)),
       "selected controls use the ordinary resizing path")

  [doc deactivateEditors];
  PASS([root superview] == nil && [root window] == nil &&
       [button superview] == root, "deactivation restores the raw top-level graph")
  PASS(NSEqualRects([root frame], original), "deactivation preserves root geometry")
  [doc reactivateEditors];
  PASS([[editor window] isVisible] && [button superview] == childEditor,
       "reactivation reattaches the root and child editors")
  PASS(NSEqualRects([root frame], original), "reactivation does not inflate the view")
  PASS([[[editor window] backgroundColor] isEqual: [documentWindow backgroundColor]],
       "reactivation preserves the normal standalone background")
  [doc deactivateEditors];
  PASS([root superview] == nil && [button superview] == root &&
       [root autoresizingMask] == (NSViewWidthSizable | NSViewHeightSizable),
       "repeated activation preserves ownership and autoresizing")
  NSString *archivePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
    [[NSProcessInfo processInfo] globallyUniqueString]];
  NSNibControlConnector *connection = [NSNibControlConnector new];
  [connection setSource: button];
  [connection setDestination: root];
  [connection setLabel: @"description"];
  NSArray *graph = [NSArray arrayWithObjects: root, connection, nil];
  PASS([NSArchiver archiveRootObject: graph toFile: archivePath],
       "the deactivated graph archives without editor objects")
  NSTask *reader = [NSTask new];
  NSString *executable = [[[NSProcessInfo processInfo] arguments] objectAtIndex: 0];
  if (![executable isAbsolutePath])
    executable = [[[NSFileManager defaultManager] currentDirectoryPath]
      stringByAppendingPathComponent: executable];
  [reader setLaunchPath: executable];
  [reader setArguments: [NSArray arrayWithObject: archivePath]];
  [reader launch];
  [reader waitUntilExit];
  PASS([reader terminationStatus] == 0,
       "a fresh process restores geometry, class, title, and target identity")
  RELEASE(reader);
  RELEASE(connection);
  [[NSFileManager defaultManager] removeItemAtPath: archivePath error: NULL];
  [doc reactivateEditors];
  [editor selectObjects: [NSArray arrayWithObject: childEditor]];
  [editor copySelection];
  [editor pasteInSelection];
  PASS([[root subviews] count] == 2 &&
       [[editor selection] objectAtIndex: 0] != button,
       "pasting creates and selects a new child in the standalone view")
  [editor deleteSelection];
  PASS([[root subviews] count] == 1 && [button superview] == childEditor,
       "deleting the pasted child preserves the original control")
  [editor selectObjects: [NSArray arrayWithObject: childEditor]];
  [editor deleteSelection];
  PASS([[root subviews] count] == 0 && [doc isTopLevelObject: root],
       "deleting selected controls leaves the standalone root intact")
  [doc closeAllEditors];
  RELEASE(button);
  RELEASE(root);
  RELEASE(doc);
  END_SET("Standalone view editing")
  RELEASE(pool);
  /* A decoding exception caught by Testing.h must fail the child process. */
  return argc == 2 ? 1 : 0;
}
