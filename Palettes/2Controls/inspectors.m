/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
              Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

/*----------------------------------------------------------------------------
 * NSBox
 */
@implementation	NSBox (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormBoxAttributesInspector";
}

@end

@interface GormBoxAttributesInspector : IBInspector
{
  id positionMatrix;
  id borderMatrix;
  id titleField;
  id horizontalSlider;
  id verticalSlider;
}
@end

@implementation GormBoxAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == positionMatrix)
    {
      [object setTitlePosition: [[control selectedCell] tag]];
    }
  else if (control == borderMatrix)
    {
      [object setBorderType: [[control selectedCell] tag]];
    }
  else if (control == titleField)
    {
      [object setTitle: [[control cellAtIndex: 0] stringValue]];
    }
  else if (control == horizontalSlider)
    {
      [object setContentViewMargins:
	NSMakeSize([control floatValue], [verticalSlider floatValue])];
    }
  else if (control == verticalSlider)
    {
      [object setContentViewMargins:
	NSMakeSize([horizontalSlider floatValue], [control floatValue])];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }
  [positionMatrix selectCellWithTag: [anObject titlePosition]];
  [borderMatrix selectCellWithTag: [anObject borderType]];
  [[titleField cellAtIndex: 0] setStringValue: VSTR([anObject title])];
  [horizontalSlider setFloatValue: [anObject contentViewMargins].width];
  [verticalSlider setFloatValue: [anObject contentViewMargins].height];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSBoxInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormBoxInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  NSDebugLog(@"ok: sender : %@", sender);
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSButton
 */
@implementation	NSButton (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormButtonAttributesInspector";
}

@end

@interface GormButtonAttributesInspector : IBInspector
{
  id alignMatrix;
  id iconMatrix;
  id keyField;
  id optionMatrix;
  id tagField;
  id titleForm;
  id typeButton;
  id keyEquiv;
}

- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormButtonAttributesInspector

/* The button type isn't stored in the button, so reverse-engineer it */
- (NSButtonType) buttonTypeForObject: button
{
  NSButtonCell *cell;
  NSButtonType type;
  int highlight, stateby;

  /* We could be passed the button or the cell */
  cell = ([button isKindOfClass: [NSButton class]]) ? [button cell] : button;

  highlight = [cell highlightsBy];
  stateby = [cell showsStateBy];
  NSDebugLog(@"highlight = %d, stateby = %d",
    [cell highlightsBy],[cell showsStateBy]);
  
  type = NSMomentaryPushButton;
  if (highlight == NSChangeBackgroundCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryLight;
      else 
	type = NSOnOffButton;
    }
  else if (highlight == (NSPushInCellMask | NSChangeGrayCellMask))
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryPushButton;
      else
	type = NSPushOnPushOffButton;
    }
  else if (highlight == (NSPushInCellMask | NSContentsCellMask))
    {
      type = NSToggleButton;
    }
  else if (highlight == NSContentsCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryChangeButton;
      else
	type = NSToggleButton; /* Really switch or radio. What should it be? */
    }
  else
    {
      NSDebugLog(@"Ack! no button type");
    }
  return type;
}

/* We may need to reset some parameters based on the previous type */
- (void) setButtonType: (NSButtonType)type forObject: (id)button
{
  [object setButtonType: type];
}

- (void) _setValuesFromControl: (id)control
{
  if (control == alignMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[control selectedCell] tag]];
    }
  else if (control == iconMatrix)
    {
      [object setImagePosition: 
	(NSCellImagePosition)[[control selectedCell] tag]];
    }
  else if (control == keyField)
    {
      [keyEquiv selectItem: nil]; // if the user does his own thing, select the default...
      [object setKeyEquivalent: [[control cellAtIndex: 0] stringValue]];
    }
  else if (control == optionMatrix)
    {
      BOOL flag;

      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setBordered: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setContinuous: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setEnabled: flag];

      [object setState: [[control cellAtRow: 3 column: 0] state]];
      flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
      [object setTransparent: flag];
    }
  else if (control == tagField)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }
  else if (control == titleForm)
    {
      NSString *string;
      NSImage *image;

      [object setTitle: [[control cellAtIndex: 0] stringValue]];
      [object setAlternateTitle: [[control cellAtIndex: 1] stringValue]];
      string = [[control cellAtIndex: 2] stringValue];
      if ([string length] > 0)
	{   
          image = [NSImage imageNamed: string];
	  [object setImage: image];
	}
      string = [[control cellAtIndex: 3] stringValue];
      if ([string length] > 0)
	{
	  image = [NSImage imageNamed: string];
	  [object setAlternateImage: image];
	}
    }
  else if (control == typeButton) 
    {
      [self setButtonType: [[control selectedItem] tag] forObject: object];
    }
  else if ([control isKindOfClass: [NSMenuItem class]] )
    {
      /*
            * In old NSPopUpButton implementation we do receive
            * the selected menu item here. Not the PopUpbutton 'typeButton'
            * FIXME: Ideally we should also test if the menu item belongs
            * to the 'type button' control. How to do that?
            */
      [self setButtonType: [control tag] forObject: object];
    }
}

- (void) _getValuesFromObject: anObject
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

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSButtonInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormButtonInspector");
      return nil;
    }

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

- (void) ok: (id)sender
{
  NSDebugLog(@"ok: sender = %@",sender);
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  if ([self object] != anObject)
    {
      /*
       * Ensure textfields in title form are written to old object.
       */
      [self _setValuesFromControl: titleForm];
    }
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

- (void) selectKeyEquivalent: (id)sender
{
  int code = [[keyEquiv selectedItem] tag];
  id cell = [keyField cellAtIndex: 0];
  switch(code)
    {
    case 0:
      [cell setStringValue: @""];
      [object setKeyEquivalent: @""];
      break;
    case 1:
      [cell setStringValue: @"\n"];
      [object setKeyEquivalent: @"\n"];
      break;
    case 2:
      [cell setStringValue: @"\b"];
      [object setKeyEquivalent: @"\b"];
      break;
    case 3:
      [cell setStringValue: @"\E"];
      [object setKeyEquivalent: @"\E"];
      break;
    case 4:
      [cell setStringValue: @"\t"];
      [object setKeyEquivalent: @"\t"];
      break;
    default:
      break;
    }
}
@end

/*----------------------------------------------------------------------------
 * NSButtonCell
 */
@implementation	NSButtonCell (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormButtonCellAttributesInspector";
}

@end

@interface GormButtonCellAttributesInspector : GormButtonAttributesInspector
{
}
@end

@implementation GormButtonCellAttributesInspector
@end

/*----------------------------------------------------------------------------
 * NSCell
 */
@implementation	NSCell (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormCellAttributesInspector";
}
@end

@interface GormCellAttributesInspector: IBInspector
{
  id disabledSwitch;
  id tagForm;
}
@end

@implementation GormCellAttributesInspector
- (void) _setValuesFromControl: control
{
  if (control == disabledSwitch)
    {
      [object setEnabled: ([control state] == NSOffState)];
    }
  else if (control == tagForm)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }
  [disabledSwitch setState: ([anObject isEnabled]) ? NSOffState : NSOnState];  
  [[tagForm cellAtRow: 0 column: 0] setIntValue: [anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSCellInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormCellInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSForm
 */
@implementation	NSForm (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormFormAttributesInspector";
}

@end

@interface GormFormAttributesInspector: IBInspector
{
  id backgroundColorWell;
  id drawsBackgroundSwitch;
  id optionMatrix;
  id tagForm;
  id textMatrix;
  id titleMatrix;
}
@end

@implementation GormFormAttributesInspector

- (void) _setValuesFromControl: control
{
  int	rows;
  int	cols;
  int	i;
      
  [object getNumberOfRows: &rows columns: &cols];
  
  if (control == backgroundColorWell)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == drawsBackgroundSwitch)
    {
      [object setDrawsBackground: ([control state] == NSOnState)];
    }
  else if (control == optionMatrix)
    {
      BOOL flag;

      // Cells tags = Positions?
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      if (flag == YES)
	{
	  for (i = 0; i < rows; i++)
	    {
	      [[object cellAtIndex: i] setTag: i];
	    }
	}

      // Editable?
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      for (i = 0; i < rows; i++)
	{
	  [[object cellAtIndex: i] setEditable: flag];
	}

      // Selectable?
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      for (i = 0; i < rows; i++)
	{
	  [[object cellAtIndex: i] setSelectable: flag];
	}

      // Scrollable?
      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;
      for (i = 0; i < rows; i++)
	{
	  [[object cellAtIndex: i] setScrollable: flag];
	}
    }
  else if (control == textMatrix)
    {
      [object setTextAlignment: (NSTextAlignment)[[control selectedCell] tag]];
    }
  else if (control == titleMatrix)
    {
      [object setTitleAlignment: (NSTextAlignment)[[control selectedCell] tag]];
    }
  else if (control == tagForm)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }
}

- (void) _getValuesFromObject: (id)anObject
{
  if (anObject != object)
    {
      return;
    }
  [backgroundColorWell setColor: [anObject backgroundColor]];
  [drawsBackgroundSwitch setState: 
    ([anObject drawsBackground]) ? NSOnState : NSOffState];
  [textMatrix selectCellWithTag: [[anObject  cellAtIndex: 0] alignment]];
  [titleMatrix selectCellWithTag: [[anObject cellAtIndex: 0] titleAlignment]];
  
  [optionMatrix deselectAllCells];
  if ([[anObject cellAtIndex: 0] isEditable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([[anObject cellAtIndex: 0] isSelectable])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([[anObject cellAtIndex: 0] isScrollable])
    [optionMatrix selectCellAtRow: 3 column: 0];

  // Cells tags = position is not directly stored in the Form so guess it.
  {
    int		rows;
    int		cols;
    int		i;
    BOOL	flag;
    
    [anObject getNumberOfRows: &rows columns: &cols];

    i = 0;    
    do
      {
	flag = ([[anObject cellAtIndex: i] tag] == i);
      }
    while (flag && (++i < rows)); 

    if (flag)
      {
        [optionMatrix selectCellAtRow: 0 column: 0];
      }
  }
  
  [[tagForm cellAtRow: 0 column: 0] setIntValue: [anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSFormInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormFormInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  NSDebugLog(@"ok: sender is %@", sender);
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSMatrix
 */
@implementation	NSMatrix (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormMatrixAttributesInspector";
}

@end

@interface GormMatrixAttributesInspector : IBInspector
{
  id autosizeSwitch;
  id autotagSwitch;
  id backgroundColorWell;
  id drawsBackgroundSwitch;
  id modeMatrix;
  id propagateSwitch;
  id prototypeMatrix;
  id selRectSwitch;
  id tagForm;
}

@end

@implementation GormMatrixAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == autosizeSwitch)
    {
      [object setAutosizesCells: ([control state] == NSOnState)];
    }
  else if (control == autotagSwitch)
    {
      int	rows;
      int	cols;
      int	i;

      [object getNumberOfRows: &rows columns: &cols];

      if ((rows == 1) && (cols > 1))
        {
          for (i = 0; i < cols; i++)
	    {
	      [[object cellAtRow:0 column:i] setTag: i];
	    }
        }
      else if ((rows > 1) && (cols ==1))
        {
          for (i = 0; i < rows; i++)
	    {
	      [[object cellAtRow:i column:0] setTag: i];
	    }
        }
    }
  else if (control == backgroundColorWell)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == drawsBackgroundSwitch)
    {
      [object setDrawsBackground: ([control state] == NSOnState)];
    }
  else if (control == modeMatrix)
    {
      [(NSMatrix *)object setMode: [[control selectedCell] tag]];
    }
  else if (control == propagateSwitch)
    {
      //Nothing for the moment - must implement Prototype
      // item in the pull down menu
    }
  else if (control == selRectSwitch)
    {
      [object setSelectionByRect: ([control state] == NSOnState)];
    }
  else if (control == tagForm)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }

  /*
   * prototypeMatrix
   * If prototype cell is set show it else show a matrix cell
   */
  if ([object prototype] == nil)
    {
      [prototypeMatrix putCell: [object cellAtRow:0 column:0] atRow:0 column:0];
    }
   else
    {
       [prototypeMatrix putCell: [object prototype] atRow:0 column:0];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    } 
  [autosizeSwitch setState: 
    ([anObject autosizesCells]) ? NSOnState : NSOffState];

  {
    int	rows;
    int cols;

    [anObject getNumberOfRows: &rows columns: &cols];
 
    if ((rows == 1 && cols > 1) || (cols == 1 && rows > 1))
      [autotagSwitch setEnabled: YES];
    else
      [autotagSwitch setEnabled: NO];
  }

  [backgroundColorWell setColor: [anObject backgroundColor]];
  [drawsBackgroundSwitch setState: 
    ([anObject drawsBackground]) ? NSOnState : NSOffState];

  [modeMatrix selectCellWithTag: [(NSMatrix *)anObject mode]];
  
  [selRectSwitch setState: 
    ([anObject isSelectionByRect]) ? NSOnState : NSOffState];
  [[tagForm cellAtIndex: 0] setIntValue: [anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSMatrixInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormMatrixInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSPopUpButton
 */
@implementation	NSPopUpButton (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormPopUpButtonAttributesInspector";
}

@end

@interface GormPopUpButtonAttributesInspector : IBInspector
{
  id typeMatrix;
  id disabledSwitch;
  id tagForm;
}
@end

@implementation GormPopUpButtonAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == typeMatrix)
    {
      id selectedItem;
      [object setPullsDown: [[control selectedCell] tag]];
      selectedItem = [object selectedItem];
      [object selectItem: nil];
      [object selectItem: selectedItem];
    }
  else if (control == disabledSwitch)
    {
      [object setAutoenablesItems: ([control state] == NSOffState)];
    }
  else if (control == tagForm)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }
}

- (void) _getValuesFromObject: (id)anObject
{
  if (anObject != object)
    {
      return;
    }
  [typeMatrix selectCellWithTag: [anObject pullsDown]];
  [disabledSwitch setState: ![anObject autoenablesItems]];
  [[tagForm cellAtRow: 0 column: 0] setIntValue: [anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSPopUpButtonInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormPopUpButtonInspector");
      return nil;
    }

  return self;
}


- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end


/*----------------------------------------------------------------------------
 * NSSlider
 */
@implementation	NSSlider (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormSliderAttributesInspector";
}

@end

@interface GormSliderAttributesInspector : IBInspector
{
  id altForm;
  id knobField;
  id numberOfTicks;
  id snapToTicks;
  id tickPosition;
  id unitForm;
  id valueForm;
  id altIncrementForm;
  id optionMatrix;
  id knobThicknessForm;
  id tagForm;
}
@end

@implementation GormSliderAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == valueForm)
    {
      [object setMinValue: [[control cellAtIndex: 0] doubleValue]];
      [object setDoubleValue: [[control cellAtIndex: 1] doubleValue]];
      [object setMaxValue: [[control cellAtIndex: 2] doubleValue]];
    }
  else if (control == optionMatrix)
    {
       BOOL flag;
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setContinuous: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setEnabled: flag];
    }
  else if (control == altIncrementForm)
    {
      [[object cell] setAltIncrementValue: 
		       [[control cellAtIndex: 0] doubleValue]];
    }
  else if (control == knobThicknessForm)
    {
      [[object cell] setKnobThickness: 
		       [[control cellAtIndex: 0] floatValue]];
    }
  else if (control == tagForm)
    {
      [[object cell] setTag: [[control cellAtIndex: 0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }
  [[valueForm cellAtIndex: 0] setDoubleValue: [anObject minValue]];
  [[valueForm cellAtIndex: 1] setDoubleValue: [anObject doubleValue]];
  [[valueForm cellAtIndex: 2] setDoubleValue: [anObject maxValue]];

  [optionMatrix deselectAllCells];
  if ([anObject isContinuous])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isEnabled])
    [optionMatrix selectCellAtRow: 1 column: 0];


  [[altIncrementForm cellAtIndex: 0] setDoubleValue: 
			       [[anObject cell] altIncrementValue]];
  [[knobThicknessForm cellAtIndex: 0] setFloatValue: 
			       [[anObject cell] knobThickness]];
  [[tagForm cellAtIndex: 0] setIntValue: [[anObject cell] tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSSliderInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormSliderInspector");
      return nil;
    }
  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSStepper
 */
@implementation	NSStepper (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormStepperAttributesInspector";
}

@end

@interface GormStepperAttributesInspector : IBInspector
{
  NSTextField *valueField;
  NSTextField *minimumValueField;
  NSTextField *maximumValueField;
  NSTextField *incrementValueField;
  NSButton *autorepeatButton;
  NSButton *valueWrapsButton;
}
@end

@implementation GormStepperAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == valueField)
    {
      [object setDoubleValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == minimumValueField)
    {
      [object setMinValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == maximumValueField)
    {
      [object setMaxValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == incrementValueField)
    {
      [object setIncrement:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == autorepeatButton)
    {
      switch ([control state])
	{
	case 0:
	  [object setAutorepeat: NO];
	  break;
	case 1:
	  [object setAutorepeat: YES];
	  break;
	}
    }
  else if (control == valueWrapsButton)
    {
      switch ([control state])
	{
	case 0:
	  [object setValueWraps: NO];
	  break;
	case 1:
	  [object setValueWraps: YES];
	  break;
	}
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }
  [valueField setDoubleValue: [anObject doubleValue]];
  [minimumValueField setDoubleValue: [anObject minValue]];
  [maximumValueField setDoubleValue: [anObject maxValue]];
  [incrementValueField setDoubleValue: [anObject increment]];
  if ([object autorepeat])
    [autorepeatButton setState: 1];
  else
    [autorepeatButton setState: 0];
  if ([object valueWraps])
    [valueWrapsButton setState: 1];
  else
    [valueWrapsButton setState: 0];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormNSStepperInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormStepperAttributesInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: valueField];
  [self _setValuesFromControl: minimumValueField];
  [self _setValuesFromControl: maximumValueField];
  [self _setValuesFromControl: incrementValueField];
  [self _setValuesFromControl: autorepeatButton];
  [self _setValuesFromControl: valueWrapsButton];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSStepperCell
 */
@implementation	NSStepperCell (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormStepperCellAttributesInspector";
}

@end

@interface GormStepperCellAttributesInspector : GormStepperAttributesInspector
{
}
@end

@implementation GormStepperCellAttributesInspector
@end

/*----------------------------------------------------------------------------
 * NSTextField
 */
@implementation	NSTextField (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormTextFieldAttributesInspector";
}

@end

@interface GormTextFieldAttributesInspector : IBInspector
{
  id alignMatrix;
  id backgroundColor;
  id drawsBackground;
  id textColor;
  id optionMatrix;
  id borderMatrix;
  id tagForm;
}

@end

@implementation GormTextFieldAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == alignMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[control selectedCell] tag]];
    }
  else if (control == backgroundColor)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == drawsBackground)
    {
      [object setDrawsBackground: ([control state] == NSOnState)];
    }
  else if (control == textColor)
    {
      [object setTextColor: [control color]];
    }
  else if (control == optionMatrix)
    {
      BOOL flag;

      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES :NO;
      [object setEditable: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES :NO;
      [object setSelectable: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES :NO;
      [[object cell] setScrollable: flag];
    }

  else if (control == borderMatrix)
    {
      BOOL bordered, bezeled;

      if ([[control cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  bordered = bezeled = NO;
	}
      else if ([[control cellAtRow: 0 column: 1] state] == NSOnState)
        {
          bordered = YES;
          bezeled = NO;
        } 
      else if ([[control cellAtRow: 0 column: 2] state] == NSOnState)
	{
	  bordered = NO; bezeled = YES;
	}
      [object setBordered: bordered];
      [object setBezeled: bezeled];
    }
  else if (control == tagForm)
    {
      [object setTag: [[control cellAtIndex: 0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    } 
  [alignMatrix selectCellWithTag: [anObject alignment]];
  [backgroundColor setColor: [anObject backgroundColor]];
  [textColor setColor: [anObject textColor]];
  [drawsBackground setState: 
    ([anObject drawsBackground]) ? NSOnState : NSOffState];
  
  [optionMatrix deselectAllCells];
  if ([anObject isEditable])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isSelectable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([[anObject cell] isScrollable])
    [optionMatrix selectCellAtRow: 2 column: 0];

  NSDebugLog(@"isBordered: %d",[anObject isBordered]);
  NSDebugLog(@"isBezeled: %d",[anObject isBezeled]);
  
  if ([anObject isBordered] == YES)
    {
      [borderMatrix selectCellAtRow: 0 column: 1];
    }
  else
    {
      if ([anObject isBezeled] == YES)
        [borderMatrix selectCellAtRow: 0 column: 2];
      else
        [borderMatrix selectCellAtRow: 0 column: 0];
    }

  [[tagForm cellAtIndex: 0] setIntValue: [anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormNSTextFieldInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTextFieldInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

@interface GormProgressIndicatorInspector : IBInspector
{
  id doubleValue;
  id borderMatrix;
  id indeterminate;
  id minValue;
  id maxValue;
  id vertical;
}
- (void) indeterminateSelected: (id)sender;
- (void) verticalSelected: (id)sender;
- (void) borderSelected: (id)sender;
@end

@implementation NSProgressIndicator (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormProgressIndicatorInspector";
}
@end

@implementation GormProgressIndicatorInspector
- init
{
  NSDebugLog(@"Starting to instantiate...");
  self = [super init];
  if (self != nil)
    {
      if ([NSBundle loadNibNamed: @"GormNSProgressIndicatorInspector" 
		    owner: self] == NO)
	{
	  
	  NSDictionary	*table;
	  NSBundle	*bundle;
	  table = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
	  bundle = [NSBundle mainBundle];
	  if ([bundle loadNibFile: @"GormNSProgressIndicatorInspector"
		      externalNameTable: table
		      withZone: [self zone]] == NO)
	    {
	      NSLog(@"Could not open gorm GormNSProgressIndicatorInspector");
	      NSLog(@"self %@", self);
	      return nil;
	    }
	}
    }
  NSDebugLog(@"Made it...");
  return self;
}

- (void) _getValuesFromObject
{
  [indeterminate setState: [object isIndeterminate]?NSOnState:NSOffState];
  [vertical setState: [(NSProgressIndicator *)object isVertical]?NSOnState:NSOffState];
  [minValue setIntValue: [object minValue]];
  [maxValue setIntValue: [object maxValue]];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject];
}

- (void) indeterminateSelected: (id)sender
{
  /* insert your code here */
  [object setIndeterminate: ([indeterminate state] == NSOnState)];
}


- (void) verticalSelected: (id)sender
{
  /* insert your code here */
  [object setVertical: ([vertical state] == NSOnState)];
}

- (void) borderSelected: (id)sender
{
  /* insert your code here */
  [object setBorderType: [[borderMatrix selectedCell] tag]];
}

- (void) minValueSelected: (id)sender
{
  [object setMinValue: [minValue doubleValue]];
}

- (void) maxValueSelected: (id)sender
{
  [object setMaxValue: [maxValue doubleValue]];
}
@end
