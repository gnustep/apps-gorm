/* All rights reserved */

#import "GormPersonNameComponentsFormatterInspector.h"

@implementation GormPersonNameComponentsFormatterInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormPersonNameComponentsFormatterInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormPersonNameComponentsFormatterInspector");
      return nil;
    }

  return self;
}

- (void) revert: (id)sender
{
  NSPersonNameComponentsFormatter *formatter = (NSPersonNameComponentsFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Get current values from formatter and update UI
  
  // Set style popup
  NSPersonNameComponentsFormatterStyle formatterStyle = [formatter style];
  [style selectItemWithTag: (NSInteger)formatterStyle];
  
  // Set phonetic checkbox
  BOOL isPhonetic = [formatter isPhonetic];
  [phonetic setState: isPhonetic ? NSOnState : NSOffState];
  
  [super revert: sender];
}

- (void) ok: (id)sender
{
  NSPersonNameComponentsFormatter *formatter = (NSPersonNameComponentsFormatter *)[object formatter];
  
  if (formatter == nil)
    return;
  
  // Set style from popup
  if (sender == style || sender == self)
    {
      NSPersonNameComponentsFormatterStyle formatterStyle = (NSPersonNameComponentsFormatterStyle)[[style selectedItem] tag];
      [formatter setStyle: formatterStyle];
    }
  
  // Set phonetic from checkbox
  if (sender == phonetic || sender == self)
    {
      BOOL isPhonetic = ([phonetic state] == NSOnState);
      [formatter setPhonetic: isPhonetic];
    }
  
  [super ok: sender];
}

@end
