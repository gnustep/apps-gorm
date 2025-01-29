/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSTable.h>
#include "BoxesPalette.h"

@interface GSTable (GormDrawingExtension)
- (void) drawRect: (NSRect)rect;
@end

@implementation GSTable (GormDrawingExtension)
- (void) drawRect: (NSRect)aRect
{
  // draw whatever the parent view contains.
  [super drawRect: aRect];

  if([(id<IB>)NSApp isTestingInterface] == NO)
    {
      CGFloat dot_dash[] = {1.0, 1.0};
      NSGraphicsContext *ctxt = GSCurrentContext();

      // Draw a green box;
      [[NSColor blueColor] set];
      DPSsetlinewidth(ctxt, 1.0);
      DPSsetdash(ctxt, dot_dash, 4, 0.0);
      DPSrectstroke(ctxt,  NSMinX(aRect) + 0.5, NSMinY(aRect) + 0.5,
		    NSWidth(aRect) - 1.0, NSHeight(aRect) - 1.0);
    }
}
@end

@implementation BoxesPalette

- (void)finishInstantiate
{
  // make the associations...
  [self associateObject: tview
	type: IBViewPboardType
	with: timage];

  [self associateObject: hview
	type: IBViewPboardType
	with: himage];

  [self associateObject: vview
	type: IBViewPboardType
	with: vimage];
}

@end
