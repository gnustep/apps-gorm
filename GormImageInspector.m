/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormImageInspector.h"
#include "GormPrivate.h"

@implementation GormImageInspector
+ (void) initialize
{
  if (self == [GormImageInspector class])
    {
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // initialize all member variables...
      // none...

      // load the gui...
      if (![NSBundle loadNibNamed: @"GormImageInspector"
		     owner: self])
	{
	  NSLog(@"Could not open gorm GormImageInspector");
	  return nil;
	}
      else
	{
	  [[NSNotificationCenter defaultCenter] 
	    addObserver: self
	    selector: @selector(handleNotification:)
	    name: IBSelectionChangedNotification
	    object: nil];
	}
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) handleNotification: (NSNotification*)aNotification
{
}

- (void) setObject: (id)aobject
{
  NSImage *image = [aobject normalImage];
  NSSize size = [image size];

  object = aobject;
  [imageView setImageAlignment: NSImageAlignCenter];
  [imageView setImageFrameStyle: NSImageFrameGrayBezel];
  [imageView setImageScaling: NSScaleNone];
  [imageView setImage: [aobject image]];
  [name setStringValue: [image name]];
  [width setDoubleValue: size.width];
  [height setDoubleValue: size.height];
}
@end
