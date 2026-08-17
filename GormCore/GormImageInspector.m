/* All rights reserved */

#include <AppKit/AppKit.h>

#include "GormImageInspector.h"
#include "GormPrivate.h"
#include "GormImage.h"

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
      NSBundle *bundle = [NSBundle bundleForClass: [self class]];

      // load the gui...
      if (![bundle loadNibNamed: @"GormImageInspector"
			  owner: self
		topLevelObjects: NULL])
	{
	  NSLog(@"Could not open gorm GormImageInspector");
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
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)aNotification
{
}

- (void) setObject: (id)anObject
{
  NSImage *normalImage = [anObject normalImage];
  NSImage *displayImage = [anObject image];
  NSString *imageName = [anObject name];
  NSSize size = [normalImage size];

  [super setObject: anObject];
  [imageView setImageAlignment: NSImageAlignCenter];
  [imageView setImageFrameStyle: NSImageFrameGrayBezel];
  [imageView setImageScaling: NSScaleNone];
  
  // Prefer the thumbnail, but fall back to the full-size image.  Set the
  // image unconditionally so that a failed image does not leave stale
  // content from the previously inspected resource.
  [imageView setImage: (displayImage != nil) ? displayImage : normalImage];
  
  // Use the resource name.  NSImage names are globally registered, so
  // -setName: may fail when two resources have the same name.
  if (imageName != nil)
    {
      [name setStringValue: imageName];
    }
  else
    {
      [name setStringValue: @""];
    }
  
  // Set dimensions from the normal (full-size) image
  [width setDoubleValue: size.width];
  [height setDoubleValue: size.height];
}
@end
