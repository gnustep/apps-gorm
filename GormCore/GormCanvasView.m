/* GormCanvasView.m
 *
 * Implementation of a document view that paints a graph-paper background.
 */
#import "GormCanvasView.h"

@implementation GormCanvasView

- (id)initWithFrame: (NSRect)frameRect
{
  if ((self = [super initWithFrame: frameRect]) == nil)
    return nil;

  _gridSize = 20.0;
  _majorInterval = 2;
  // use light-gray grid lines so the pattern is subtle and not dark
  _minorLineColor = [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] retain];
  _majorLineColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] retain];
  _backgroundColor = [[NSColor windowBackgroundColor] retain];

  [self setAutoresizingMask: NSViewNotSizable];
  return self;
}

- (void)dealloc
{
  RELEASE(_minorLineColor);
  RELEASE(_majorLineColor);
  RELEASE(_backgroundColor);
  [super dealloc];
}

- (void)drawRect: (NSRect)dirtyRect
{
  NSRect bounds = [self bounds];

  // fill background
  [_backgroundColor setFill];
  NSRectFill(bounds);

  // draw grid lines
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineWidth: 1.0];

  CGFloat gx = floor(bounds.origin.x / _gridSize) * _gridSize;
  for (; gx <= NSMaxX(bounds); gx += _gridSize)
    {
      NSInteger idx = (NSInteger)floor((gx - bounds.origin.x) / _gridSize);
      NSColor *lineColor = nil;
      if (idx % _majorInterval == 0)
        lineColor = _majorLineColor;
      else
        lineColor = _minorLineColor;

      // make every third line semi-transparent
      if ((idx % 3) == 0)
        lineColor = [lineColor colorWithAlphaComponent:0.5];

      [lineColor setStroke];
      [path removeAllPoints];
      [path moveToPoint: NSMakePoint(gx, bounds.origin.y)];
      [path lineToPoint: NSMakePoint(gx, NSMaxY(bounds))];
      [path stroke];
    }

  CGFloat gy = floor(bounds.origin.y / _gridSize) * _gridSize;
  for (; gy <= NSMaxY(bounds); gy += _gridSize)
    {
      NSInteger idx = (NSInteger)floor((gy - bounds.origin.y) / _gridSize);
      NSColor *lineColor = nil;
      if (idx % _majorInterval == 0)
        lineColor = _majorLineColor;
      else
        lineColor = _minorLineColor;

      // make every third line semi-transparent
      if ((idx % 3) == 0)
        lineColor = [lineColor colorWithAlphaComponent:0.5];

      [lineColor setStroke];
      [path removeAllPoints];
      [path moveToPoint: NSMakePoint(bounds.origin.x, gy)];
      [path lineToPoint: NSMakePoint(NSMaxX(bounds), gy)];
      [path stroke];
    }
}

@end
