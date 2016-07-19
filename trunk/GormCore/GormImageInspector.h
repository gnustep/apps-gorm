/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <InterfaceBuilder/IBInspector.h>

@interface GormImageInspector : IBInspector
{
  id name;
  id imageView;
  id width;
  id height;
  id _currentImage;
}
@end
