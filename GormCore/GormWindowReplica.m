/* GormWindowReplica.m
 *
 * Implementation of a simple window-like view used in the canvas.
 */
#import "GormWindowReplica.h"

@implementation GormWindowReplica

{
  NSWindow *_originalWindow;
  NSString *_title;
  NSPoint _mouseDownPoint;
  NSRect _startFrame;
}

- (id)initWithWindow: (NSWindow *)window frame: (NSRect)frameRect
{
  if ((self = [super initWithFrame: frameRect]) == nil)
    return nil;

  _originalWindow = [window retain];
  _title = [[window title] copy];

  // hide the original window so the canvas owns the visual
  @try {
    [_originalWindow orderOut: nil];
  } @catch (id e) {
    // ignore
  }

  [self setAutoresizingMask: NSViewNotSizable];
  return self;
}

- (void)dealloc
{
  RELEASE(_originalWindow);
  RELEASE(_title);
  [super dealloc];
}

- (void)drawRect: (NSRect)dirtyRect
{
  NSRect bounds = [self bounds];

  // draw a window border
  [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] setFill];
  NSRectFill(bounds);

  [[NSColor blackColor] setStroke];
  NSFrameRect(bounds);

  // title bar area
  NSRect titleBar = NSMakeRect(0, bounds.size.height - 20, bounds.size.width, 20);
  [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] setFill];
  NSRectFill(titleBar);

  // title text
  if (_title != nil)
    {
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSFont systemFontOfSize:11], NSFontAttributeName,
                             [NSColor blackColor], NSForegroundColorAttributeName,
                             nil];
      NSSize tsize = [_title sizeWithAttributes: attrs];
      NSPoint pt = NSMakePoint(6, bounds.size.height - 4 - tsize.height);
      [_title drawAtPoint: pt withAttributes: attrs];
    }

  // content area placeholder
  NSRect content = NSMakeRect(6, 6, bounds.size.width - 12, bounds.size.height - 30);
  [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
  NSRectFill(content);
  [[NSColor grayColor] setStroke];
  NSFrameRect(content);
}

- (void)mouseDown: (NSEvent *)event
{
  _mouseDownPoint = [self convertPoint: [event locationInWindow] fromView: nil];
  _startFrame = [self frame];

  if ([event clickCount] == 2)
    {
      [self restoreOriginalWindow: self];
    }
}

- (void)mouseDragged: (NSEvent *)event
{
  NSPoint p = [self convertPoint: [event locationInWindow] fromView: nil];
  NSPoint delta = NSMakePoint(p.x - _mouseDownPoint.x, p.y - _mouseDownPoint.y);
  NSRect f = _startFrame;
  f.origin.x += delta.x;
  f.origin.y += delta.y;
  [self setFrame: f];
}

- (void)restoreOriginalWindow: (id)sender
{
  if (_originalWindow == nil)
    return;

  // bring the original window back on screen
  @try {
    [_originalWindow makeKeyAndOrderFront: nil];
  } @catch (id e) {
    // ignore
  }
}

@end
