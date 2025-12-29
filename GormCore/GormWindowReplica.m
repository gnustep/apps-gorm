/* GormWindowReplica.m
 *
 * Implementation of a simple window-like view used in the canvas.
 */
#import <InterfaceBuilder/InterfaceBuilder.h>
#import "GormWindowReplica.h"

@implementation GormWindowReplica

- (id)initWithWindow: (NSWindow *)window frame: (NSRect)frameRect
{
  if ((self = [super initWithFrame: frameRect]) == nil)
    return nil;

  _originalWindow = [window retain];
  _title = [[window title] copy];

  // move the original window's content view into this replica
  NSView *origContent = nil;
  @try {
    origContent = [_originalWindow contentView];
  } @catch (id e) {
    origContent = nil;
  }

  if (origContent != nil)
    {
      // detach from original window
      @try {
        [origContent retain];
        [origContent removeFromSuperview];
      } @catch (id e) {
        // ignore
      }

      // place origContent into replica's content area
      NSRect bounds = [self bounds];
      NSRect contentArea = NSMakeRect(6, 6, bounds.size.width - 12, bounds.size.height - 30);
      // convert to replica coords and set frame
      [origContent setFrame: contentArea];
      [origContent setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [self addSubview: origContent];
      // keep a reference but do not release here; dealloc will release window and content if needed
    }
  else
    {
      // hide the original window if no content available
      @try {
        [_originalWindow orderOut: nil];
      } @catch (id e) {
        // ignore
      }
    }

  [self setAutoresizingMask: NSViewNotSizable];
  return self;
}

- (void)dealloc
{
  // if we still hold the original window, ensure its content is restored
  NSView *maybeContent = nil;
  @try {
    maybeContent = [_originalWindow contentView];
  } @catch (id e) {
    maybeContent = nil;
  }

  // If original window has no content and we have a subview, move it back
  if (_originalWindow != nil && maybeContent == nil)
    {
      NSView *first = [[self subviews] count] ? [[self subviews] objectAtIndex:0] : nil;
      if (first != nil)
        {
          @try {
            [first retain];
            [first removeFromSuperview];
            [_originalWindow setContentView: first];
            [first release];
          } @catch (id e) {
            // ignore
          }
        }
    }

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

  // content area placeholder only if we have no real content
  if ([[self subviews] count] == 0)
    {
      NSRect content = NSMakeRect(6, 6, bounds.size.width - 12, bounds.size.height - 30);
      [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
      NSRectFill(content);
      [[NSColor grayColor] setStroke];
      NSFrameRect(content);
    }
}

- (void)mouseDown: (NSEvent *)event
{
  _mouseDownPoint = [self convertPoint: [event locationInWindow] fromView: nil];
  _startFrame = [self frame];

  if ([event clickCount] == 2)
    {
      [self restoreOriginalWindow: self];
    }
  else
    {
      // Route selection to the document/editor system so the object becomes editable
      id doc = nil;
      @try {
        doc = [(id<IB>)[NSApp delegate] documentForObject: _originalWindow];
      } @catch (id e) {
        doc = nil;
      }

      if (doc != nil)
        {
          id editor = nil;
          @try {
            editor = [doc editorForObject: _originalWindow create: YES];
          } @catch (id e) {
            editor = nil;
          }

          if (editor != nil)
            {
              if ([editor respondsToSelector: @selector(selectObjects:)])
                {
                  [editor selectObjects: [NSArray arrayWithObject: _originalWindow]];
                }

              if ([editor respondsToSelector: @selector(makeSelectionVisible:)])
                {
                  [editor makeSelectionVisible: YES];
                }

              if ([doc respondsToSelector: @selector(setSelectionFromEditor:)])
                {
                  [doc setSelectionFromEditor: editor];
                }

              // If the editor is a view, forward the mouse event so drag/connect operations work
              if ([editor isKindOfClass: [NSView class]] && [editor respondsToSelector: @selector(mouseDown:)])
                {
                  @try {
                    [(NSView *)editor mouseDown: event];
                  } @catch (id e) {
                    // ignore forwarding errors
                  }
                }
            }
        }
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

  // If we've moved a content view into the replica, move it back first
  NSView *first = [[self subviews] count] ? [[self subviews] objectAtIndex:0] : nil;
  if (first != nil)
    {
      @try {
        [first retain];
        [first removeFromSuperview];
        [_originalWindow setContentView: first];
        [first release];
      } @catch (id e) {
        // ignore
      }
    }

  // bring the original window back on screen
  @try {
    [_originalWindow makeKeyAndOrderFront: nil];
  } @catch (id e) {
    // ignore
  }
}

@end
