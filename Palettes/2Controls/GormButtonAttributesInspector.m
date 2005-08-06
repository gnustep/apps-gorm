#include "GormButtonAttributesInspector.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})



@implementation GormButtonAttributesInspector

- (id) init
{
  if ([super init] == nil)
      return nil;

  if ([NSBundle loadNibNamed: @"GormNSButtonInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormButtonInspector");
      return nil;
    }

#warning Why ? 
  /* Need to set up popup button */
  [typeButton removeAllItems];
  [typeButton addItemWithTitle: @"Momentary Push"];
  [[typeButton lastItem] setTag: 0];
  [typeButton addItemWithTitle: @"Push On/Off"];
  [[typeButton lastItem] setTag: 1];
  [typeButton addItemWithTitle: @"Toggle"];
  [[typeButton lastItem] setTag: 2];
  [typeButton addItemWithTitle: @"Momentary Change"];
  [[typeButton lastItem] setTag: 5];
  [typeButton addItemWithTitle: @"On/Off"];
  [[typeButton lastItem] setTag: 6];
  [typeButton addItemWithTitle: @"Momentary Light"];
  [[typeButton lastItem] setTag: 7];
  /* Doesn't work yet? */
  //  [typeButton setAction: @selector(setButtonTypeFrom:)];
  //  [typeButton setTarget: self];
 
  return self;
}


- (void) ok: (id) sender
{
  if (sender == alignMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[sender selectedCell] tag]];
    }
  else if (sender == iconMatrix)
    {
      [object setImagePosition: 
	(NSCellImagePosition)[[sender selectedCell] tag]];
    }
  else if (sender == keyField)
    {
      [keyEquiv selectItem: nil]; // if the user does his own thing, select the default...
      [object setKeyEquivalent: [[sender cellAtIndex: 0] stringValue]];
    }
  else if (sender == optionMatrix)
    {
      BOOL flag;

      flag = ([[sender cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setBordered: flag];      flag = ([[sender cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setContinuous: flag];
      flag = ([[sender cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setEnabled: flag];

      [object setState: [[sender cellAtRow: 3 column: 0] state]];
      flag = ([[sender cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
      [object setTransparent: flag];
    }
  else if (sender == tagField)
    {
      [object setTag: [[sender cellAtIndex: 0] intValue]];
    }
  else if (sender == titleForm)
    {
      NSString *string;
      NSImage *image;
      
      [object setTitle: [[sender cellAtIndex: 0] stringValue]];
      [object setAlternateTitle: [[sender cellAtIndex: 1] stringValue]];

      string = [[sender cellAtIndex: 2] stringValue];
      if ([string length] > 0)
	{   
	  image = [NSImage imageNamed: string];
	  [object setImage: image];
	}
      string = [[sender cellAtIndex: 3] stringValue];
      if ([string length] > 0)
	{
	  image = [NSImage imageNamed: string];
	  [object setAlternateImage: image];
	}
    }
  else if (sender == typeButton) 
    {
      [self setButtonType: [[sender selectedItem] tag] forObject: object];
    }
  else if ([sender isKindOfClass: [NSMenuItem class]] )
    {
      /*
            * In old NSPopUpButton implementation we do receive
            * the selected menu item here. Not the PopUpbutton 'typeButton'
            * FIXME: Ideally we should also test if the menu item belongs
            * to the 'type button' control. How to do that?
            */
      [self setButtonType: [sender tag] forObject: object];
    }
}

-(void) revert:(id) anObject
{
  NSImage *image;
  NSString *key = VSTR([anObject keyEquivalent]);
 
  if (anObject != object)
    {
      return;
    } 
  [alignMatrix selectCellWithTag: [anObject alignment]];
  [iconMatrix selectCellWithTag: [anObject imagePosition]];
  [[keyField cellAtIndex: 0] setStringValue: VSTR([anObject keyEquivalent])];

  if([key isEqualToString: @"\n"])
    {
      [keyEquiv selectItemAtIndex: 1];
    }
  else if([key isEqualToString: @"\b"])
    {
      [keyEquiv selectItemAtIndex: 2];
    }
  else if([key isEqualToString: @"\E"])
    {
      [keyEquiv selectItemAtIndex: 3];
    }
  else if([key isEqualToString: @"\t"])
    {
      [keyEquiv selectItemAtIndex: 4];
    }
  else
    {
      [keyEquiv selectItem: nil];
    }

  [optionMatrix deselectAllCells];
  if ([anObject isBordered])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isContinuous])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject isEnabled])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([anObject state] == NSOnState)
    [optionMatrix selectCellAtRow: 3 column: 0];
  if ([anObject isTransparent])
    [optionMatrix selectCellAtRow: 4 column: 0];

  [[tagField cellAtIndex: 0] setIntValue: [anObject tag]];

  [[titleForm cellAtIndex: 0] setStringValue: VSTR([anObject title])];
  [[titleForm cellAtIndex: 1] setStringValue: VSTR([anObject alternateTitle])];

  image = [anObject image];
  if (image != nil)
    {
      [[titleForm cellAtIndex: 2] setStringValue: VSTR([image name])];
    }
  else
    {
      [[titleForm cellAtIndex: 2] setStringValue: @""];
    }

  image = [anObject alternateImage];
  if (image != nil)
    {
      [[titleForm cellAtIndex: 3] setStringValue: VSTR([image name])];
    }
  else
    {
      [[titleForm cellAtIndex: 3] setStringValue: @""];
    }

  [typeButton selectItemAtIndex: 
    [typeButton indexOfItemWithTag: [self buttonTypeForObject: anObject]]];
}
