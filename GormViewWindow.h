#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>

@interface GormViewWindow : NSWindow
{
  NSView *_view;
}
- (id) initWithView: (NSView *)view;
- (void) setView: (NSView *) view;
- (NSView *)view;
@end
