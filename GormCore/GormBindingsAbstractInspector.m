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

- (void) _initDefaults
{
  // Add ones we know will be present...  these are singletons.
  [_controllerPopUp addItemWithTitle: @"NSApp"];
  [_controllerPopUp addItemWithTitle: @"NSUserDefaults"];

  // Make sure all fields show...
  [_multipleValuesPlaceholder setHidden: NO];
  [_noSelectionPlaceholder setHidden: NO];
  [_notApplicablePlaceholder setHidden: NO];
  [_nullPlaceholder setHidden: NO];

  [_multipleValuesTitle setHidden: NO];
  [_noSelectionTitle setHidden: NO];
  [_notApplicableTitle setHidden: NO];
  [_nullTitle setHidden: NO];

  [_controllerKey setStringValue: @""];
  [_modelKeyPath setStringValue: @""];
}

- (void) awakeFromNib
{
  GormDocument *doc = (GormDocument *)[(id<IB>)[NSApp delegate] activeDocument];
  NSSet *tlo = [doc topLevelObjects];
  NSEnumerator *en = [tlo objectEnumerator];
  id o = nil;

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
  
  [self _initDefaults];
  [self ok: _controllerPopUp]; // load the path/key properly
}

- (IBAction) ok: (id)sender
{
  if (sender == _controllerPopUp)
    {
      NSString *key = @"self";
      id item = [_controllerPopUp selectedItem];
      NSString *title = [item title];

      [self _initDefaults];
      if ([title isEqualToString: @"NSUserDefaults"])
	{
	  key = @"values";
	  [_controllerKey setStringValue: key];
	}
      else
	{
	  [_modelKeyPath setStringValue: @"self"];
	}
    }

  [super ok: sender];
}

- (IBAction) revert: (id)sender
{
  [super revert: sender];
}

@end
