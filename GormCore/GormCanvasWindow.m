/* GormCanvasWindow.m
 *
 * Simple canvas window that lays out basic representations of
 * all document objects (windows, views, menus) as boxes.
 */

#import "GormCanvasWindow.h"
#import "GormDocument.h"
#import "GormFunctions.h"
#import "GormWindowReplica.h"

@interface GormDocument (CanvasAdditions)
- (NSArray *) _collectAllObjects;
@end

@implementation GormCanvasWindow

- (id)initWithDocument:(GormDocument *)doc
{
  NSArray *allObjects = [doc _collectAllObjects];
  NSUInteger count = [allObjects count];
  CGFloat cols = 4;
  CGFloat spacing = 12.0;
  CGFloat tileW = 220.0;
  CGFloat tileH = 120.0;
  CGFloat width = cols * (tileW + spacing) + spacing;
  CGFloat rows = (count + cols - 1) / cols;
  CGFloat height = rows * (tileH + spacing) + spacing;

  unsigned style = NSTitledWindowMask | NSClosableWindowMask
    | NSResizableWindowMask | NSMiniaturizableWindowMask;

  if ((self = [super initWithContentRect: NSMakeRect(0,0,width,height)
                               styleMask: style
                                 backing: NSBackingStoreBuffered
                                   defer: NO]) != nil)
    {
      NSLog(@"GormCanvasWindow: created (size %.0fx%.0f) with %u objects", width, height, (unsigned)count);

      [self setTitle: @"Gorm Canvas"];
      [self center];
      [self setReleasedWhenClosed: NO];

      // create a scrollable document view so the canvas can be larger than the window
      NSView *documentView = [[NSView alloc] initWithFrame: NSMakeRect(0,0,width,height)];
      NSScrollView *scroll = [[NSScrollView alloc] initWithFrame: [[self contentView] bounds]];
      [scroll setHasVerticalScroller: YES];
      [scroll setHasHorizontalScroller: YES];
      [scroll setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [scroll setDocumentView: documentView];
      [self setContentView: scroll];

      NSUInteger i = 0;
      CGFloat contentWidth = width;
      CGFloat contentHeight = height;
      for (id obj in allObjects)
        {
          NSUInteger col = i % (NSUInteger)cols;
          NSUInteger row = i / (NSUInteger)cols;
          NSRect r = NSMakeRect(spacing + col * (tileW + spacing),
                                height - spacing - (row+1) * (tileH + spacing) + spacing,
                                tileW, tileH);
          NSString *className = NSStringFromClass([obj class]);
          NSString *name = nil;
          @try {
            name = [doc nameForObject: obj];
          } @catch (id e) {
            name = nil;
          }

          if (name == nil) name = @"";

          if ([obj isKindOfClass: [NSWindow class]])
            {
              NSWindow *w = (NSWindow *)obj;
              NSRect wf = [w frame];
              // make the replica the same size as the original window
              r.size.width = wf.size.width;
              r.size.height = wf.size.height;

              // create replica and add to documentView
              GormWindowReplica *rep = [[GormWindowReplica alloc] initWithWindow: w frame: r];
              [documentView addSubview: rep];

              // small label with a short description inside the replica (only if replica has no real content)
              if ([[rep subviews] count] == 0)
                {
                  NSTextField *label = [[NSTextField alloc] initWithFrame: NSInsetRect([rep bounds], 8, 28)];
                  [label setEditable: NO];
                  [label setBordered: NO];
                  [label setBackgroundColor: [NSColor clearColor]];
                  [label setSelectable: NO];
                  NSString *desc = [NSString stringWithFormat: @"Window frame: (%.0f,%.0f) %.0fx%.0f", wf.origin.x, wf.origin.y, wf.size.width, wf.size.height];
                  [label setStringValue: desc];
                  [rep addSubview: label];
                  RELEASE(label);
                }

              // expand documentView frame if replica extends beyond current bounds
              if (NSMaxX(r) > contentWidth) contentWidth = NSMaxX(r);
              if (NSMaxY(r) > contentHeight) contentHeight = NSMaxY(r);

              RELEASE(rep);
            }
          /* No box/placeholder for non-window objects in canvas; skip */
          i++;
        }

      // if content size changed due to varying window sizes, adjust documentView
      if (contentWidth != width || contentHeight != height)
        {
          [documentView setFrame: NSMakeRect(0,0, contentWidth, contentHeight)];
        }

      RELEASE(documentView);
      RELEASE(scroll);
    }

  return self;
}

- (void)orderFront:(id)sender
{
  [super orderFront: sender];
}

@end
