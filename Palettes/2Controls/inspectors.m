/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
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
#include "../../GormPrivate.h"

/*----------------------------------------------------------------------------
  NSBox
*/
@implementation	NSBox (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormBoxAttributesInspector";
}

@end

@interface GormBoxAttributesInspector : IBInspector
{
  id positionMatrix;
  id borderMatrix;
  id tagField;
  id titleField;
}
@end

@implementation GormBoxAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == positionMatrix)
    {
      [object setTitlePosition: [[control selectedCell] tag] ];
    }
  else if (control == borderMatrix)
    {
      [object setBorderType: [[control selectedCell] tag] ];
    }
  else if (control == titleField)
    {
      [object setTitle: [[control cellAtIndex: 0] stringValue] ];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;

  [positionMatrix selectCellWithTag: [anObject titlePosition] ];
  [borderMatrix selectCellWithTag: [anObject borderType] ];
  [[titleField cellAtIndex: 0] setStringValue: [anObject title] ];
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormBoxInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormBoxInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

  return self;
}

- (BOOL) wantsButtons
{
  return YES;
}

- (NSButton*) okButton
{
  if (okButton == nil)
    {
      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"OK"];
      [okButton setEnabled: YES];
    }
  return okButton;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: titleField];
  [self _setValuesFromControl: positionMatrix];
  [self _setValuesFromControl: borderMatrix];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
  NSButton
*/
@implementation	NSButton (IBInspectorClassNames)
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
}

- (void) _getValuesFromObject: anObject;
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
  type = NSMomentaryPushButton;
  if (highlight == NSChangeBackgroundCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryLight;
      else if (stateby == NSChangeBackgroundCellMask)
	type = NSOnOffButton;
      else 
	type = NSToggleButton;
    }
  else if (highlight == (NSPushInCellMask | NSChangeGrayCellMask) )
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryPushButton;
      else
	type = NSPushOnPushOffButton;
    }
  else if (highlight == NSContentsCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryChangeButton;
      else
	type = NSToggleButton;
    }
  else
    NSDebugLog(@"Ack! no button type");

  return type;
}

/* We may need to reset some parameters based on the previous type */
- (void) setButtonType: (NSButtonType)type forObject: button
{
  NSButtonType oldType = [self buttonTypeForObject: object];

  if (type == oldType)
    return;

  [object setButtonType: type ];
  [self _getValuesFromObject: object];
}

- (void) setButtonTypeFrom: sender
{
  [self setButtonType: [[sender selectedItem] tag] forObject: object];
}

- (void) _setValuesFromControl: control
{
  if (control == alignMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[control selectedCell] tag] ];
    }
  else if (control == iconMatrix)
    {
      [object setImagePosition: 
		(NSCellImagePosition)[[control selectedCell] tag] ];
    }
  else if (control == keyField)
    {
      [object setKeyEquivalent: [[control cellAtIndex: 0] stringValue] ];
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
      [object setTag: [[control cellAtIndex: 0] intValue] ];
    }
  else if (control == titleForm)
    {
      NSString *string;
      NSImage *image;
      [object setTitle: [[control cellAtIndex: 0] stringValue] ];
      [object setAlternateTitle: [[control cellAtIndex: 1] stringValue] ];
      string = [[control cellAtIndex: 2] stringValue];
      if ([string length] > 0)
	{
	  image = [NSImage imageNamed: string ];
	  [object setImage: image ];
	}
      string = [[control cellAtIndex: 3] stringValue];
      if ([string length] > 0)
	{
	  image = [NSImage imageNamed: string ];
	  [object setAlternateImage: image ];
	}
    }
  else if (control == typeButton)
    {
      [self setButtonType: [[control selectedItem] tag] forObject: object];
    }
}

- (void) _getValuesFromObject: anObject
{
  NSImage *image;
  if (anObject != object)
    return;
  
  [alignMatrix selectCellWithTag: [anObject alignment] ];
  [iconMatrix selectCellWithTag: [anObject imagePosition] ];
  [[keyField cellAtIndex: 0] setStringValue: [anObject keyEquivalent] ];
  
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

  [[tagField cellAtIndex: 0] setIntValue: [anObject tag] ];

  [[titleForm cellAtIndex: 0] setStringValue: [anObject title] ];
  [[titleForm cellAtIndex: 1] setStringValue: [anObject alternateTitle] ];
  image = [anObject image];
  if (image)
    [[titleForm cellAtIndex: 2] setStringValue: [image name] ];
  else
    [[titleForm cellAtIndex: 2] setStringValue: @""];
  image = [anObject alternateImage];
  if (image)
    [[titleForm cellAtIndex: 3] setStringValue: [image name] ];
  else
    [[titleForm cellAtIndex: 3] setStringValue: @"" ];

  [typeButton selectItemAtIndex: 
		[typeButton indexOfItemWithTag: 
			      [self buttonTypeForObject: anObject ] ] ];

}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormButtonInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormButtonInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

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
  [typeButton setAction: @selector(setButtonTypeFrom:)];
  [typeButton setTarget: self];

  return self;
}

- (BOOL) wantsButtons
{
  return YES;
}

- (NSButton*) okButton
{
  if (okButton == nil)
    {
      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"OK"];
      [okButton setEnabled: YES];
    }
  return okButton;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: alignMatrix];
  [self _setValuesFromControl: iconMatrix];
  [self _setValuesFromControl: keyField];
  [self _setValuesFromControl: tagField];
  [self _setValuesFromControl: titleForm];
  [self _setValuesFromControl: optionMatrix];
  [self _setValuesFromControl: typeButton];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
  NSButtonCell
*/
@implementation	NSButtonCell (IBInspectorClassNames)
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
  NSForm
*/
@implementation	NSForm (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  // Not Implemented Yet
  return @"GormObjectInspector";
}
@end

/*----------------------------------------------------------------------------
  NSMatrix
*/
@implementation	NSMatrix (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormMatrixAttributesInspector";
}
@end

@interface GormMatrixAttributesInspector : IBInspector
{
  id backgroundColor;
  id drawsBackground;
  id modeMatrix;
  id tagField;
}

@end

@implementation GormMatrixAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == backgroundColor)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == drawsBackground)
    {
      [object setDrawsBackground: ([control state] == NSOnState)];
    }
  if (control == modeMatrix)
    {
      [(NSMatrix *)object setMode: [[control selectedCell] tag] ];
    }
  else if (control == tagField)
    {
      [object setTag: [[control cellAtIndex: 0] intValue] ];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;
  
  [backgroundColor setColor: [anObject backgroundColor] ];
  [drawsBackground setState: 
		     ([anObject drawsBackground]) ? NSOnState : NSOffState];

  [modeMatrix selectCellWithTag: [(NSMatrix *)anObject mode] ];
  [[tagField cellAtIndex: 0] setIntValue: [anObject tag] ];
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMatrixInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormMatrixInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

  return self;
}

- (BOOL) wantsButtons
{
  return YES;
}

- (NSButton*) okButton
{
  if (okButton == nil)
    {
      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,80,30)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"OK"];
      [okButton setEnabled: YES];
    }
  return okButton;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: modeMatrix];
  [self _setValuesFromControl: backgroundColor];
  [self _setValuesFromControl: drawsBackground];
  [self _setValuesFromControl: tagField];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
  NSPopUpButton
*/
@implementation	NSPopUpButton (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  // Not Implemented Yet
  return @"GormObjectInspector";
}
@end

/*----------------------------------------------------------------------------
  NSSlider
*/
@implementation	NSSlider (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormSliderAttributesInspector";
}

@end

@interface GormSliderAttributesInspector : IBInspector
{
  id unitForm;
  id altForm;
  id numberOfTicks;
  id tickPosition;
  id snapToTicks;
}
@end

@implementation GormSliderAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == unitForm)
    {
      [object setMinValue: [[control cellAtIndex: 0] doubleValue]];
      [object setDoubleValue: [[control cellAtIndex: 1] doubleValue]];
      [object setMaxValue: [[control cellAtIndex: 2] doubleValue]];
    }
  else if (control == altForm)
    {
      [[object cell] setAltIncrementValue: 
		       [[control cellAtIndex: 0] doubleValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;

  [[unitForm cellAtIndex: 0] setDoubleValue: [anObject minValue]];
  [[unitForm cellAtIndex: 1] setDoubleValue: [anObject doubleValue]];
  [[unitForm cellAtIndex: 2] setDoubleValue: [anObject maxValue]];

  [[altForm cellAtIndex: 2] setDoubleValue: 
			       [[anObject cell] altIncrementValue]];
  
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormSliderInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormSliderInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];
  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: unitForm];
  [self _setValuesFromControl: altForm];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
  NSStepper
*/
@implementation	NSStepper (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormStepperAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return nil;
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
    return;

  [valueField setDoubleValue: [anObject doubleValue]];
  [minimumValueField setDoubleValue: [anObject minValue]];
  [maximumValueField setDoubleValue: [anObject maxValue]];
  if ([object autorepeat])
    [autorepeatButton setState: 1];
  else
    [autorepeatButton setState: 0];
  if ([object valueWraps])
    [valueWrapsButton setState: 1];
  else
    [valueWrapsButton setState: 0];
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormStepperInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormStepperAttributesInspector");
      return nil;
    }

  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];
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
  NSTextField
*/
@implementation	NSTextField (IBInspectorClassNames)
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
  id tagField;
}

@end

@implementation GormTextFieldAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == alignMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[control selectedCell] tag] ];
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
      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES :NO;
      [object setBezeled: flag];
      flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES :NO;
      [object setBordered: flag];
    }
  else if (control == tagField)
    {
      [object setTag: [[control cellAtIndex: 0] intValue] ];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;
  
  [alignMatrix selectCellWithTag: [anObject alignment] ];
  [backgroundColor setColor: [anObject backgroundColor] ];
  [textColor setColor: [anObject textColor] ];
  [drawsBackground setState: 
		     ([anObject drawsBackground]) ? NSOnState : NSOffState];
  
  [optionMatrix deselectAllCells];
  if ([anObject isEditable])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isSelectable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([[anObject cell] isScrollable])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([anObject isBezeled])
    [optionMatrix selectCellAtRow: 3 column: 0];
  if ([anObject isBordered])
    [optionMatrix selectCellAtRow: 4 column: 0];

  [[tagField cellAtIndex: 0] setIntValue: [anObject tag] ];
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormTextFieldInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTextFieldInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

  return self;
}

- (BOOL) wantsButtons
{
  return YES;
}

- (NSButton*) okButton
{
  if (okButton == nil)
    {
      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,80,30)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"OK"];
      [okButton setEnabled: YES];
    }
  return okButton;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: alignMatrix];
  [self _setValuesFromControl: backgroundColor];
  [self _setValuesFromControl: textColor];
  [self _setValuesFromControl: drawsBackground];
  [self _setValuesFromControl: optionMatrix];
  [self _setValuesFromControl: tagField];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end
