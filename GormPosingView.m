#include "GormPosingView.h"


@implementation GormPosingView

struct _rFlagsType2 {
  /*
   * 'flipped_view' is set in NSViews designated initialiser (and other
   * methods that create views) to be the value returned by [-isFlipped]
   * This caching assumes that the value returned by [-isFlipped] will
   * not change during the views lifetime - if it does, the view must
   * be sure to change the flag accordingly.
   */
  unsigned    flipped_view:1;
  unsigned    has_subviews:1;         /* The view has subviews.       */
  unsigned    has_currects:1;         /* The view has cursor rects.   */
  unsigned    has_trkrects:1;         /* The view has tracking rects. */
  unsigned    has_draginfo:1;         /* View/window has drag types.  */
  unsigned    opaque_view:1;          /* For views whose opacity may  */
  /* change to keep track of it.  */
  unsigned    valid_rects:1;          /* Some cursor rects may be ok. */
  unsigned    needs_display:1;        /* Window/view needs display.   */
  unsigned    isCustom:1;
} ;


- (id) initWithFrame: (NSRect)frameRect
{
  struct _rFlagsType2 *rft2;
  
  rft2 = (struct _rFlagsType2 *) &_rFlags;
  
  rft2->isCustom = 0;

  [super initWithFrame: frameRect];
}

- (void) viewWillMoveToWindow: (NSWindow*)newWindow
{
  if ([newWindow isKindOfClass: NSClassFromString(@"GormNSWindow")])
    {
      [self setCustom: YES];
    }
  [super viewWillMoveToWindow: newWindow];

}

- (BOOL) isCustom
{
  struct _rFlagsType2 *rft2;
  
  rft2 = (struct _rFlagsType2 *) &_rFlags;
  
  if (rft2->isCustom == 0)
    return NO;
  else
    return YES;
}

- (void) display
{
  if ([self isCustom])
    {
      NSLog(@"%@ display", self);
    }
  [super display];
}

- (void) displayIfNeeded
{
  if ([self isCustom])
    {
      NSLog(@"%@ displayIfNeeded", self);
    }
  [super displayIfNeeded];
}

- (void) setCustom: (BOOL) value
{
  struct _rFlagsType2 *rft2;
  
  rft2 = (struct _rFlagsType2 *) &_rFlags;
  if (value)
    rft2->isCustom = 1;
  else
    rft2->isCustom = 0;
}

@end
