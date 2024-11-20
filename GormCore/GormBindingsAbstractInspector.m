/* All rights reserved */

#import <Foundation/NSSet.h>

#import "GormAbstractDelegate.h"
#import "GormBindingsAbstractInspector.h"
#import "GormDocument.h"

@implementation GormBindingsAbstractInspector

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
    }
  return self;
}

- (void) awakeFromNib
{
  GormDocument *doc = (GormDocument *)[(id<IB>)[NSApp delegate] activeDocument];
  NSSet *tlo = [doc topLevelObjects];
  NSEnumerator *en = [tlo objectEnumerator];
  id o = nil;

  NSDebugLog(@"+++++ controllerPopUp = %@", _controllerPopUp);
  // Update the pop up...
  [_controllerPopUp removeAllItems];
  while ((o = [en nextObject]) != nil)
    {
      NSString *name = [doc nameForObject: o];
      if ([name isEqualToString: @"NSMenu"] == NO && name != nil)
	{
	  [_controllerPopUp addItemWithTitle: name];
	}
    }


  // Add ones we know will be present...
  [_controllerPopUp addItemWithTitle: @"NSOwner"];

  // Add ones we know will be present...
  [_controllerPopUp addItemWithTitle: @"NSApp"];

  // Make sure all fields show...
  [_multipleValuesPlaceholder setHidden: NO];
  [_noSelectionPlaceholder setHidden: NO];
  [_notApplicablePlaceholder setHidden: NO];
  [_nullPlaceholder setHidden: NO];

  [_multipleValuesTitle setHidden: NO];
  [_noSelectionTitle setHidden: NO];
  [_notApplicableTitle setHidden: NO];
  [_nullTitle setHidden: NO];
}

- (IBAction) ok: (id)sender
{
  [super ok: sender];
}

- (IBAction) revert: (id)sender
{
  [super revert: sender];
}

@end
