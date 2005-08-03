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
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <InterfaceBuilder/InterfaceBuilder.h>
#include <GormCore/NSColorWell+GormExtensions.h>

#include "GormStepperAttributesInspector.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

/* This is so that the NSSecureTextField will show in the custom class inspector */
/*
@implementation NSSecureTextField (IBObjectAdditions)
+ (BOOL) canSubstituteForClass: (Class)origClass
{
  if(origClass == [NSTextField class])
    {
      return YES;
    }

  return NO;
}
@end
*/

/*----------------------------------------------------------------------------
 * NSButton
 */
@implementation	NSButton (IBObjectAdditions)

- (NSString*) editorClassName
{
  return @"GormButtonEditor";
}

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
- (void) setButtonType: (NSButtonType)type forObject: (id)button;
- (void) _setValuesFromControl: (id)control;
- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormButtonAttributesInspector

/* delegate method for changing the NSButton title */
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self ok:[aNotification object]];
}


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
      [object setBordered: flag];      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
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
  [super ok: sender];
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
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



