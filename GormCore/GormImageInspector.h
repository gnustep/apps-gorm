/* All Rights reserved */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

/**
 * GormImageInspector provides an inspector panel for editing image resource
 * attributes such as name and size, and for previewing the selected image.
 */
@interface GormImageInspector : IBInspector
{
  id name;
  id imageView;
  id width;
  id height;
  id _currentImage;
}
@end
