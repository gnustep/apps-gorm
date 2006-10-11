/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
            Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2003, 2005
   
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

#include "GormButtonAttributesInspector.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

// trivial cell subclass.
@interface GormButtonCellAttributesInspector : GormButtonAttributesInspector
@end

@implementation GormButtonCellAttributesInspector
@end

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
 
  return self;
}

/* The button type isn't stored in the button, so reverse-engineer it */
- (NSButtonType) buttonTypeForObject: (id)button
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
  else if (sender == keyForm)
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
  else if (sender == tagForm)
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
      [object setButtonType: [[sender selectedItem] tag]];
    }
  else if ([sender isKindOfClass: [NSMenuItem class]] )
    {
      /*
            * In old NSPopUpButton implementation we do receive
            * the selected menu item here. Not the PopUpbutton 'typeButton'
            * FIXME: Ideally we should also test if the menu item belongs
            * to the 'type button' control. How to do that?
            */
      [object setButtonType: [sender tag]];
    }

  [super ok: sender];
}

-(void) revert: (id)sender
{
  NSImage *image;

  if(sender != nil)
    {
      NSString *key = VSTR([object keyEquivalent]);
      
      [alignMatrix selectCellWithTag: [object alignment]];
      [iconMatrix selectCellWithTag: [object imagePosition]];
      [[keyForm cellAtIndex: 0] setStringValue: VSTR([object keyEquivalent])];
      
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
      if ([object isBordered])
	[optionMatrix selectCellAtRow: 0 column: 0];
      if ([object isContinuous])
	[optionMatrix selectCellAtRow: 1 column: 0];
      if ([object isEnabled])
	[optionMatrix selectCellAtRow: 2 column: 0];
      if ([object state] == NSOnState)
	[optionMatrix selectCellAtRow: 3 column: 0];
      if ([object isTransparent])
	[optionMatrix selectCellAtRow: 4 column: 0];
      
      [[tagForm cellAtIndex: 0] setIntValue: [object tag]];
      
      [[titleForm cellAtIndex: 0] setStringValue: VSTR([object title])];
      [[titleForm cellAtIndex: 1] setStringValue: VSTR([object alternateTitle])];
      
      image = [object image];
      if (image != nil)
	{
	  [[titleForm cellAtIndex: 2] setStringValue: VSTR([image name])];
	}
      else
	{
	  [[titleForm cellAtIndex: 2] setStringValue: @""];
	}
      
      image = [object alternateImage];
      if (image != nil)
	{
	  [[titleForm cellAtIndex: 3] setStringValue: VSTR([image name])];
	}
      else
	{
	  [[titleForm cellAtIndex: 3] setStringValue: @""];
	}
      
      [typeButton selectItemAtIndex: 
		    [typeButton indexOfItemWithTag: 
				  [self buttonTypeForObject: object]]];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self ok: [aNotification object]];
}


@end
