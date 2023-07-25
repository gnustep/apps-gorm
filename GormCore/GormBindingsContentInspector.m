/* All Rights Reserved */

#import "GormBindingsContentInspector.h"

@implementation GormBindingsContentInspector : GormBindingsAbstractInspector

- (void) awakeFromNib
{
  [super awakeFromNib];

  [_multipleValuesPlaceholder setHidden: YES];
  [_noSelectionPlaceholder setHidden: YES];
  [_notApplicablePlaceholder setHidden: YES];
  [_nullPlaceholder setHidden: YES];

  [_multipleValuesTitle setHidden: YES];
  [_noSelectionTitle setHidden: YES];
  [_notApplicableTitle setHidden: YES];
  [_nullTitle setHidden: YES];
}
@end
