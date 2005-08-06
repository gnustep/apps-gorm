/*
  GormTabViewAttributesInspector.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: Aug 2001. 2003, 2004
   
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
/*
  July 2005 : Split inspector classes into separate files.
  Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/

#include "GormTabViewAttributesInspector.h"

#include <Foundation/NSNotification.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSStepper.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/NSTextField.h>

static NSString *ITEM=@"item";

@implementation GormTabViewAttributesInspector


- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
 
  if ([NSBundle loadNibNamed: @"GormTabViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTabViewInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  if (sender == typeMatrix)
      [object setTabViewType:[[sender selectedCell] tag]];
  else if (sender == allowtruncate)
    {
      BOOL flag;
      flag = ([allowtruncate state] == NSOnState) ? YES : NO;
      [object setAllowsTruncatedLabels:flag];
    }
  else if (sender == itemStepper )
    {
      int number = [itemStepper intValue];
      [itemLabel setStringValue:[[object tabViewItemAtIndex:number] label]];
      [itemIdentifier setStringValue:[[object tabViewItemAtIndex:number] identifier]];
      [object selectTabViewItemAtIndex:number];
    }
  

  else if (sender == numberOfItemsField)
    {
      int newNumber = [[numberOfItemsField stringValue] intValue];

      //Can we allow stupid numbers like 66666666 ????????
      if (newNumber <= 0) 
	{
	  [numberOfItemsField setStringValue:[NSString stringWithFormat:@"%i",[object numberOfTabViewItems]]];
	  return; 
	}
      if ( newNumber > [object numberOfTabViewItems] ) 
	{
	  int i;
	  NSTabViewItem *newTabItem;
	  for (i=([object numberOfTabViewItems]+1);i<=newNumber;i++)
	    {
	      NSString *identif = [NSString stringWithFormat:@"%i",i]; 
	      newTabItem = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: (id)identif];
	      [newTabItem setLabel:[ITEM  stringByAppendingString:identif]]; 
	      [newTabItem setView:[[NSView alloc] init]];
	      [object addTabViewItem:newTabItem];
	    }
	}
      else 
	{
	  int i;
	  for (i=([object numberOfTabViewItems]-1);i>=newNumber;i--)
	    {
	      [object removeTabViewItem:[object tabViewItemAtIndex:i]];
	    }
	}
      [itemStepper setMaxValue:(newNumber - 1)];
    }
  else if ( sender == itemLabel )
    {
      if ( ! [[itemLabel stringValue] isEqualToString:@""] )
	[[object selectedTabViewItem] setLabel:[itemLabel stringValue]];
    }
  else if ( sender == itemIdentifier )
    {
      if ( ! [[itemIdentifier stringValue] isEqualToString:@""] )
	[[object selectedTabViewItem] setIdentifier:[itemIdentifier stringValue]];
    }

#warning needed ? 
  [object display];
  
  [super ok: sender];
}


- (void) revert :(id) sender
{
  unsigned int numberOfTabViewItems;
  
  if ( object == nil ) 
    return;

  numberOfTabViewItems=[object numberOfTabViewItems];
  
  [numberOfItemsField setStringValue:[NSString stringWithFormat:@"%i",numberOfTabViewItems]];

  [itemStepper setMaxValue:(numberOfTabViewItems -1)];

  [itemLabel setStringValue:[[object selectedTabViewItem] label]];
  [itemIdentifier setStringValue:[[object selectedTabViewItem] identifier]];
}


-(void) controlTextDidChange:(NSNotification *)aNotification
{
  [self ok:[aNotification object]];
}



@end
