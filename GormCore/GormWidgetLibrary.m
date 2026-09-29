/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "GormWidgetLibrary.h"
#import "GormPrivate.h"
#import "GormCustomView.h"
#import <math.h>

/* Keep the original prototype and its pasteboard type. In particular, a
 * palette's picture of a window or formatter is not the object to insert. */
@interface GormLibraryEntry : NSObject
{
@public
  id object;
  NSString *type;
  NSString *title;
  NSString *detail;
  NSString *category;
  NSData *previewData;
}
@end
@implementation GormLibraryEntry
- (void) dealloc
{
  RELEASE(object);
  RELEASE(type);
  RELEASE(title);
  RELEASE(detail);
  RELEASE(category);
  RELEASE(previewData);
  [super dealloc];
}
@end

static NSString *LibraryDescription(id object)
{
  if ([object isKindOfClass: [GormCustomView class]])
    return _(@"Add a placeholder for a custom view class.");
  if ([object isKindOfClass: [NSPopUpButton class]])
    return _(@"Choose an item from a pop-up list of options.");
  if ([object isKindOfClass: [NSButton class]])
    {
      return _(@"Trigger an action or select an option with a button.");
    }
  if ([object isKindOfClass: [NSComboBox class]])
    return _(@"Enter text or choose a value from a drop-down list.");
  if ([object isKindOfClass: [NSSecureTextField class]])
    return _(@"Enter a password with its characters concealed.");
  if ([object isKindOfClass: [NSTextField class]])
    return [object isEditable] ? _(@"Enter or edit a single line of text.")
      : _(@"Display a label or other read-only text.");
  if ([object isKindOfClass: [NSSlider class]]) return _(@"Choose a value by dragging a slider.");
  if ([object isKindOfClass: [NSStepper class]]) return _(@"Increase or decrease a numeric value.");
  if ([object isKindOfClass: [NSColorWell class]]) return _(@"Display and choose a color.");
  if ([object isKindOfClass: [NSProgressIndicator class]]) return _(@"Show the progress of an operation.");
  if ([object isKindOfClass: [NSImageView class]]) return _(@"Display an image in the interface.");
  if ([object isKindOfClass: [NSBox class]]) return _(@"Group related controls in a bordered container.");
  if ([object isKindOfClass: [NSTabView class]]) return _(@"Organize views into selectable tabs.");
  if ([object isKindOfClass: [NSSplitView class]]) return _(@"Arrange panes separated by a draggable divider.");
  if ([object isKindOfClass: [NSScrollView class]]) return _(@"Present scrollable content inside a view.");
  if ([object isKindOfClass: [NSOutlineView class]]) return _(@"Display expandable rows of hierarchical data.");
  if ([object isKindOfClass: [NSTableView class]]) return _(@"Display data in rows and columns.");
  if ([object isKindOfClass: [NSTextView class]]) return _(@"Display and edit multiple lines of text.");
  if ([object isKindOfClass: [NSForm class]]) return _(@"Present labeled text fields for entering values.");
  if ([object isKindOfClass: [NSMatrix class]]) return _(@"Arrange a group of cells in rows and columns.");
  if ([object isKindOfClass: [NSBrowser class]]) return _(@"Browse a hierarchy using columns.");
  if ([object isKindOfClass: [NSWindow class]]) return _(@"Add a top-level window to the document.");
  if ([object isKindOfClass: [NSMenu class]]) return _(@"Add a menu of commands to the document.");
  if ([object isKindOfClass: [NSMenuItem class]]) return _(@"Add a command or submenu to an existing menu.");
  if ([object isKindOfClass: [NSFormatter class]]) return _(@"Format and validate a control's displayed value.");
  return _(@"Drag this palette object into your document.");
}

@interface GormLibraryRow : NSView
{
  GormLibraryEntry *entry;
  NSPasteboard *dragPasteboard;
  NSView *preview;
}
- (id) initWithEntry: (GormLibraryEntry *)anEntry frame: (NSRect)frame;
@end

@implementation GormLibraryRow
- (id) initWithEntry: (GormLibraryEntry *)anEntry frame: (NSRect)frame
{
  if ((self = [super initWithFrame: frame]))
    {
      entry = RETAIN(anEntry);
      NSUnarchiver *unarchiver = [[NSUnarchiver alloc]
        initForReadingWithData: entry->previewData];
      [unarchiver decodeClassName: @"GSCustomView" asClassName: @"GormCustomView"];
      preview = [unarchiver decodeObject];
      NSSize size = [preview frame].size;
      CGFloat scale = MIN(1.0, MIN(126.0 / MAX(size.width, 1), 76.0 / MAX(size.height, 1)));
      [preview setFrame: NSMakeRect(10 + (126 - size.width * scale) / 2,
        (frame.size.height - size.height * scale) / 2,
        size.width * scale, size.height * scale)];
      [preview setBoundsSize: size];
      [preview setAutoresizingMask: NSViewNotSizable];
      [self addSubview: preview];
      RELEASE(unarchiver);
      [self setAutoresizingMask: NSViewWidthSizable];
      [self setToolTip: [NSString stringWithFormat: @"%@ — %@\n%@",
        entry->title, entry->category, entry->detail]];
    }
  return self;
}
- (void) dealloc
{
  RELEASE(entry);
  RELEASE(dragPasteboard);
  [super dealloc];
}
/* The examples are illustrative, so the entire row starts a copy drag. */
- (NSView *) hitTest: (NSPoint)point
{
  return [super hitTest: point] != nil ? self : nil;
}
- (BOOL) acceptsFirstMouse: (NSEvent *)event { return YES; }
- (void) drawRect: (NSRect)dirty
{
  NSRect bounds = [self bounds];
  [[NSColor controlBackgroundColor] set];
  NSRectFill(bounds);
  [entry->title drawInRect: NSMakeRect(148, 76, bounds.size.width - 160, 20)
    withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
      [NSFont boldSystemFontOfSize: 13], NSFontAttributeName,
      [NSColor controlTextColor], NSForegroundColorAttributeName, nil]];
  [entry->detail drawInRect: NSMakeRect(148, 30, bounds.size.width - 160, 44)
    withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
      [NSFont systemFontOfSize: 12], NSFontAttributeName,
      [NSColor controlTextColor], NSForegroundColorAttributeName, nil]];
  [entry->category drawInRect: NSMakeRect(148, 7, bounds.size.width - 160, 18)
    withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
      [NSFont systemFontOfSize: 10], NSFontAttributeName,
      [NSColor controlTextColor], NSForegroundColorAttributeName, nil]];
  [[NSColor gridColor] set];
  NSRectFill(NSMakeRect(0, 0, bounds.size.width, 1));
}
- (void) mouseDown: (NSEvent *)event
{
  GormDocument *document = (id)[(id<IB>)[NSApp delegate] activeDocument];
  NSEvent *next;
  NSPoint start = [event locationInWindow];
  if (document == nil)
    {
      NSRunAlertPanel(nil, _(@"No document is currently active"), _(@"OK"), nil, nil);
      return;
    }
  /* A click should not create a window or menu; wait for an actual drag. */
  do
    {
      next = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
      if ([next type] == NSLeftMouseUp) return;
    }
  while (fabs([next locationInWindow].x - start.x) < 3
         && fabs([next locationInWindow].y - start.y) < 3);
  ASSIGN(dragPasteboard, [NSPasteboard pasteboardWithName: NSDragPboard]);
  if ([document copyObject: entry->object type: entry->type toPasteboard: dragPasteboard])
    {
      NSPoint point = [self convertPoint: [next locationInWindow] fromView: nil];
      NSSize size = [preview frame].size;
      NSImage *image = [[NSImage alloc] initWithSize: size];
      NSRect rect = [self convertRect: [preview frame] toView: nil];
      [image lockFocus];
      NSCopyBits([[self window] gState], rect, NSZeroPoint);
      [image unlockFocus];
      point.x -= size.width / 2;
      point.y -= size.height / 2;
      [self dragImage: image at: point offset: NSZeroSize event: next
          pasteboard: dragPasteboard source: self
           slideBack: !([entry->type isEqual: IBWindowPboardType]
                        || [entry->type isEqual: IBMenuPboardType])];
      RELEASE(image);
    }
}
- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL)local
{
  return local ? NSDragOperationCopy : NSDragOperationNone;
}
- (void) draggedImage: (NSImage *)image endedAt: (NSPoint)point deposited: (BOOL)deposited
{
  if (!deposited && ([entry->type isEqual: IBWindowPboardType]
                    || [entry->type isEqual: IBMenuPboardType]))
    {
      /* Match palettes: top-level objects can be dropped onto the desktop,
       * but dropping back anywhere in the library cancels insertion. */
      if (NSPointInRect(point, [[self window] frame])) return;
      id<IBDocuments> document = [(id<IB>)[NSApp delegate] activeDocument];
      [document pasteType: entry->type fromPasteboard: dragPasteboard parent: nil];
    }
}
@end

@interface GormLibraryList : NSView
@end
@implementation GormLibraryList
- (BOOL) isFlipped { return YES; }
@end

@implementation GormWidgetLibrary
- (id) init
{
  if ((self = [super init]))
    {
      entries = [[NSMutableArray alloc] init];
      [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(savePanelFrame:)
        name: NSApplicationWillTerminateNotification object: NSApp];
      [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(testing:)
        name: IBWillBeginTestingInterfaceNotification object: nil];
      [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(testing:)
        name: IBWillEndTestingInterfaceNotification object: nil];
    }
  return self;
}
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [searchField setTarget: nil];
  RELEASE(panel);
  RELEASE(entries);
  [super dealloc];
}
- (void) savePanelFrame: (NSNotification *)notification
{
  if (panel != nil)
    [panel saveFrameUsingName: @"WidgetLibrary"];
}
- (void) testing: (NSNotification *)notification
{
  if ([[notification name] isEqual: IBWillBeginTestingInterfaceNotification])
    {
      hiddenDuringTest = [panel isVisible];
      [panel orderOut: self];
    }
  else if (hiddenDuringTest)
    {
      hiddenDuringTest = NO;
      [panel orderFront: self];
    }
}
- (void) reload: (id)sender
{
  if (panel == nil) return;
  NSString *query = [searchField stringValue];
  CGFloat width = [[scrollView contentView] bounds].size.width;
  GormLibraryList *list = [[GormLibraryList alloc] initWithFrame: NSMakeRect(0, 0, width, 0)];
  CGFloat y = 0;
  NSEnumerator *enumerator = [entries objectEnumerator];
  GormLibraryEntry *entry;
  [list setAutoresizingMask: NSViewWidthSizable];
  while ((entry = [enumerator nextObject]))
    {
      NSString *text = [NSString stringWithFormat: @"%@ %@ %@", entry->title, entry->detail, entry->category];
      if ([query length] && [text rangeOfString: query options: NSCaseInsensitiveSearch].location == NSNotFound)
        continue;
      GormLibraryRow *row = [[GormLibraryRow alloc] initWithEntry: entry frame: NSMakeRect(0, y, width, 108)];
      [list addSubview: row];
      RELEASE(row);
      y += 108;
    }
  if (y == 0)
    {
      NSTextField *label = [[NSTextField alloc] initWithFrame: NSMakeRect(16, 20, width - 32, 24)];
      [label setStringValue: _(@"No widgets match your search.")];
      [label setEditable: NO];
      [label setBezeled: NO];
      [label setDrawsBackground: NO];
      [list addSubview: label];
      RELEASE(label);
      y = 64;
    }
  [list setFrameSize: NSMakeSize(width, MAX(y, [[scrollView contentView] bounds].size.height))];
  [scrollView setDocumentView: list];
  RELEASE(list);
  [[scrollView documentView] scrollPoint: NSZeroPoint];
}
- (BOOL) isVisible
{
  return [panel isVisible];
}
- (NSPanel *) panel
{
  if (panel == nil)
    {
      panel = [[NSPanel alloc] initWithContentRect: NSMakeRect(160, 180, 480, 570)
        styleMask: NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask
        backing: NSBackingStoreBuffered defer: NO];
      [panel setTitle: _(@"Widget Library")];
      [panel setReleasedWhenClosed: NO];
      [panel setMinSize: NSMakeSize(480, 300)];
      searchField = [[NSSearchField alloc] initWithFrame: NSMakeRect(12, 532, 456, 26)];
      [[searchField cell] setPlaceholderString: _(@"Search widgets")];
      [searchField setTarget: self];
      [searchField setAction: @selector(reload:)];
      [[searchField cell] setSendsWholeSearchString: NO];
      [searchField setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [[panel contentView] addSubview: searchField];
      RELEASE(searchField);
      NSTextField *hint = [[NSTextField alloc] initWithFrame: NSMakeRect(12, 505, 456, 22)];
      [hint setStringValue: _(@"Drag an example or its description into your document.")];
      [hint setEditable: NO];
      [hint setBezeled: NO];
      [hint setDrawsBackground: NO];
      [hint setFont: [NSFont systemFontOfSize: 12]];
      [hint setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [[panel contentView] addSubview: hint];
      RELEASE(hint);
      scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 480, 500)];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [[panel contentView] addSubview: scrollView];
      RELEASE(scrollView);
      [panel setFrameUsingName: @"WidgetLibrary"];
      [panel setFrameAutosaveName: @"WidgetLibrary"];
      /* Also save programmatic moves and the final frame on close/quit. */
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc addObserver: self selector: @selector(savePanelFrame:)
                 name: NSWindowDidMoveNotification object: panel];
      [nc addObserver: self selector: @selector(savePanelFrame:)
                 name: NSWindowDidResizeNotification object: panel];
      [nc addObserver: self selector: @selector(savePanelFrame:)
                 name: NSWindowWillCloseNotification object: panel];
      [self reload: self];
    }
  return panel;
}
- (void) addPalette: (IBPalette *)palette
{
  NSEnumerator *enumerator = [[[[palette originalWindow] contentView] subviews] objectEnumerator];
  NSView *view;
  while ((view = [enumerator nextObject]))
    {
      GormLibraryEntry *entry = [[GormLibraryEntry alloc] init];
      entry->object = RETAIN([IBPalette objectForView: view]);
      entry->type = RETAIN([IBPalette typeForView: view]);
      NSString *name = NSStringFromClass([entry->object class]);
      if ([name hasPrefix: @"Gorm"])
        name = [name substringFromIndex: 4];
      if ([entry->object respondsToSelector: @selector(title)] && [[entry->object title] length])
        name = [NSString stringWithFormat: @"%@ (%@)", [entry->object title], name];
      entry->title = [name copy];
      entry->detail = [LibraryDescription(entry->object) copy];
      entry->category = [[[palette originalWindow] title] copy];
      /* Independent examples keep controls visible without moving the palette
       * prototypes, and preserve custom palette views and their appearance. */
      NSMutableData *data = [NSMutableData data];
      NSArchiver *archiver = [[NSArchiver alloc] initForWritingWithMutableData: data];
      /* GormCustomView writes the native GSCustomView payload. Match the
       * document copy/paste mapping so its versioned decoder can read it,
       * including placeholders nested inside container previews. */
      [archiver encodeClassName: @"GormCustomView" intoClassName: @"GSCustomView"];
      [archiver encodeRootObject: view];
      entry->previewData = [data copy];
      RELEASE(archiver);
      [entries addObject: entry];
      RELEASE(entry);
    }
  [self reload: self];
}
@end
