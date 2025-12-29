/* GormCanvasView.h
 *
 * Document view for the canvas that draws a graph-paper background.
 */
#import <AppKit/AppKit.h>

@interface GormCanvasView : NSView
{
  CGFloat _gridSize;
  NSUInteger _majorInterval;
  NSColor *_minorLineColor;
  NSColor *_majorLineColor;
  NSColor *_backgroundColor;
}

- (id)initWithFrame: (NSRect)frameRect;

@end
