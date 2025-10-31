/* All Rights reserved */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

/**
 * GormHelpInspector provides a simple inspector to edit help-related
 * properties (such as tool tips) for the selected object.
 */
@interface GormHelpInspector : IBInspector
{
  id toolTip;
}
@end
