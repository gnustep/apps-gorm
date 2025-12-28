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

      NSView *content = [[NSView alloc] initWithFrame: NSMakeRect(0,0,width,height)];
      [self setContentView: content];

      NSUInteger i = 0;
      NSEnumerator *en = [allObjects objectEnumerator];
      id obj = nil;

      while ((obj = [en nextObject]) != nil)
        {
          NSUInteger col = i % (NSUInteger)cols;
          NSUInteger row = i / (NSUInteger)cols;
          NSRect r = NSMakeRect(spacing + col * (tileW + spacing),
                                height - spacing - (row+1) * (tileH + spacing) + spacing,
                                tileW, tileH);
          NSString *className = NSStringFromClass([obj class]);
          NSString *name = nil;

	  name = [doc nameForObject: obj];
          if (name == nil)
	    {
	      name = @"";
	    }

          if ([obj isKindOfClass: [NSWindow class]])
            {
              NSWindow *w = (NSWindow *)obj;
	      NSRect wf = [w frame];
              GormWindowReplica *rep = [[GormWindowReplica alloc] initWithWindow: w frame: wf];

              [content addSubview: rep];

	      // Small label with a short description inside the replica
              NSTextField *label = [[NSTextField alloc] initWithFrame: NSInsetRect(rep.bounds, 8, 28)];
              [label setEditable: NO];
              [label setBordered: NO];
              [label setBackgroundColor: [NSColor clearColor]];
              [label setSelectable: NO];

	      // Description
	      NSString *desc = [NSString stringWithFormat:
					   @"Window frame: (%.0f,%.0f) %.0fx%.0f",
					 wf.origin.x, wf.origin.y, wf.size.width, wf.size.height];
              [label setStringValue: desc];
              [rep addSubview: label];
              RELEASE(label);
              RELEASE(rep);
            }
          i++;
        }

      RELEASE(content);
    }

  return self;
}

- (void)orderFront:(id)sender
{
  [super orderFront: sender];
}

@end
