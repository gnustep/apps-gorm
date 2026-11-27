/* First-attempt connection dragging from standalone views and their children. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import <GormCore/GormDefines.h>

static NSUInteger dragCount;
static NSPoint dragPoint;
static NSString *dragName;
static BOOL connectingAtDrag;

@interface ConnectionHost : NSObject
{
@public
  GormDocument *document;
  id source;
  BOOL connecting;
}
@end
@implementation ConnectionHost
- (BOOL) isInTool { return YES; }
- (id) palettesManager { return nil; }
- (id) selectionOwner { return nil; }
- (id) activeDocument { return document; }
- (void) stopConnecting { connecting = NO; source = nil; }
- (void) startConnecting { connecting = source != nil; }
- (void) displayConnectionBetween: (id)from and: (id)to { source = from; }
- (NSImage *) linkImage { return nil; }
@end

/* Stop at AppKit's drag boundary: exercise the real selection, source and
 * pasteboard setup without requiring a human to complete a native drag. */
#define RECORD_DRAG \
- (void) dragImage: (NSImage *)image at: (NSPoint)point \
           offset: (NSSize)offset event: (NSEvent *)event \
       pasteboard: (NSPasteboard *)pasteboard source: (id)source \
        slideBack: (BOOL)slideBack \
{ \
  dragCount++; \
  dragPoint = point; \
  ASSIGN(dragName, [pasteboard stringForType: GormLinkPboardType]); \
  connectingAtDrag = ((ConnectionHost *)[NSApp delegate])->connecting; \
}

@interface ConnectionViewEditor : GormStandaloneViewEditor
@end
@implementation ConnectionViewEditor
RECORD_DRAG
@end
@interface ConnectionControlEditor : GormControlEditor
@end
@implementation ConnectionControlEditor
RECORD_DRAG
@end
@interface ConnectionView : NSView
@end
@implementation ConnectionView
- (NSString *) editorClassName { return @"ConnectionViewEditor"; }
@end
@interface ConnectionButton : NSButton
@end
@implementation ConnectionButton
- (NSString *) editorClassName { return @"ConnectionControlEditor"; }
@end

static void checkDrag(GormDocument *doc, NSView *object, ConnectionHost *host)
{
  GormViewEditor *editor = (id)[doc editorForObject: object create: NO];
  NSPoint local = NSMakePoint(NSMaxX([editor bounds]) - 15,
                              NSMaxY([editor bounds]) - 15);
  NSPoint windowPoint = [editor convertPoint: local toView: nil];
  NSEvent *down = [NSEvent mouseEventWithType: NSLeftMouseDown
    location: windowPoint modifierFlags: NSControlKeyMask timestamp: 0
    windowNumber: [[editor window] windowNumber] context: nil
    eventNumber: 1 clickCount: 1 pressure: 1];
  NSEvent *up = [NSEvent mouseEventWithType: NSLeftMouseUp
    location: windowPoint modifierFlags: NSControlKeyMask timestamp: 0
    windowNumber: [[editor window] windowNumber] context: nil
    eventNumber: 2 clickCount: 1 pressure: 0];
  NSUInteger previous = dragCount;

  /* Bound the old marquee-selection path so the regression fails, not hangs. */
  [NSApp postEvent: up atStart: YES];
  NSView *content = [[editor window] contentView];
  NSView *hit = [content hitTest: [[content superview]
    convertPoint: windowPoint fromView: nil]];
  PASS(hit == editor, "the window hit test routes the gesture to the intended editor")
  [hit mouseDown: down];
  [NSApp nextEventMatchingMask: NSLeftMouseUpMask untilDate: [NSDate distantPast]
    inMode: NSEventTrackingRunLoopMode dequeue: YES];
  PASS(dragCount == previous + 1 && connectingAtDrag && host->source == object,
       "the first Control-drag starts a connection from the clicked object")
  PASS(dragName != nil && [dragName isEqual: [doc nameForObject: object]],
       "the connection pasteboard identifies the named document object")
  PASS(NSEqualPoints(dragPoint, local),
       "the link image starts in editor coordinates at the clicked point")
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  START_SET("Standalone connection dragging")
  [NSApplication sharedApplication];
  ConnectionHost *host = [ConnectionHost new];
  GormDocument *doc = [GormDocument new];
  host->document = doc;
  [NSApp setDelegate: host];
  NSView *root = [[ConnectionView alloc] initWithFrame: NSMakeRect(37, 53, 320, 240)];
  NSView *nested = [[ConnectionView alloc] initWithFrame: NSMakeRect(40, 50, 180, 120)];
  NSButton *button = [[ConnectionButton alloc] initWithFrame: NSMakeRect(20, 30, 80, 24)];
  [nested addSubview: button];
  [root addSubview: nested];
  [doc attachObject: root toParent: nil];
  PASS([doc nameForObject: nested] != nil && [doc nameForObject: button] != nil,
       "attaching a standalone root registers nested views and controls")
  PASS([doc parentOfObject: nested] == root && [doc parentOfObject: button] == nested,
       "standalone descendants retain their document parents")
  GormStandaloneViewEditor *rootEditor = (id)[doc editorForObject: root create: YES];
  [rootEditor orderFront];
  checkDrag(doc, root, host);
  checkDrag(doc, nested, host);
  checkDrag(doc, button, host);
  checkDrag(doc, button, host);
  [doc deactivateEditors];
  [doc reactivateEditors];
  checkDrag(doc, root, host);
  checkDrag(doc, button, host);
  [doc closeAllEditors];
  [NSApp setDelegate: nil];
  RELEASE(button);
  RELEASE(nested);
  RELEASE(root);
  RELEASE(doc);
  RELEASE(host);
  DESTROY(dragName);
  END_SET("Standalone connection dragging")
  RELEASE(pool);
  return 0;
}
