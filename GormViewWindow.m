#include "GormViewWindow.h"
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>
#include <Foundation/NSNotification.h>

@implementation GormViewWindow
- (id) initWithView: (NSView *)view
{
  // initializer yourself....
  if((self = [super init]) != nil)
    {
      ASSIGN(_view,view);
      [self setDelegate: self];
   }
  return self;
}

- (void) _resizeView
{
  NSRect newFrame = [[self contentView] frame];
  newFrame.origin.x += 10;
  newFrame.origin.y += 10;
  newFrame.size.height -= 10;
  newFrame.size.width -= 10;
  [_view setFrame: newFrame];
}

- (void) setView: (NSView *) view
{
  if(_view != nil)
    {
      [_view removeFromSuperview];
    }
  ASSIGN(_view,view);
  [self _resizeView];
  [[self contentView] addSubview: _view];
}

- (NSView *) view
{
  return _view;
}

- (void) windowDidResize: (NSNotification *)notification
{
  if(_view != nil)
    {
      [self _resizeView];
    }
}
@end
 
