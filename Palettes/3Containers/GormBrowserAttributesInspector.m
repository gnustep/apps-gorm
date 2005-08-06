/*
  GormBrowserAttributesInspector.m

   Copyright (C) 2001-2005 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
            Laurent Julliard <laurent@julliard-online.org>
            Gregory John Casamento <greg_casamento@yahoo.com>
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

/*
  July 2005 : Split inspector classes into separate files. 
 Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/

#include "GormBrowserAttributesInspector.h"

#include <Foundation/NSNotification.h>

#include <AppKit/NSBrowser.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTextField.h>

@implementation GormBrowserAttributesInspector

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormNSBrowserInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormBrowserInspector");
      return nil;
    }

  return self;
}

/* Commit changes that the user makes in the Attributes Inspector */
- (void) ok: (id)sender
{
  /* options */
  if ( sender == multipleSelectionSwitch ) 
    {
      [object setAllowsMultipleSelection: [multipleSelectionSwitch state]];
    }
  else if ( sender == emptySelectionSwitch ) 
    {
      [object setAllowsEmptySelection: [emptySelectionSwitch state]];
    }
  else if ( sender == branchSelectionSwitch ) 
    {
      [object setAllowsBranchSelection: [branchSelectionSwitch state]];
    }
  else if ( sender == separateColumnsSwitch ) 
    {
      [object setSeparatesColumns: [separateColumnsSwitch state]];
    }
  else if ( sender == horizontalScrollerSwitch ) 
    {
      [object setHasHorizontalScroller: [horizontalScrollerSwitch state]];
    }
  else if ( sender == displayTitlesSwitch )
    {
      [object setTitled: [displayTitlesSwitch state]];
    }
  /* minimum column width */
  else if ( sender == minColumnWidthField ) 
    {
#warning TODO use stepper
      [object setMinColumnWidth:[minColumnWidthField intValue]];
    }
  /* tag */
  else if(sender == tagForm)
    {
      [object setTag:[[tagForm cellAtIndex:0] intValue]];
    }

  [super ok:sender];
}

/* Sync from object ( NSBrowser ) changes to the inspector */
- (void) revert: (id) sender
{
  if (object == nil)
    return;
  
  [multipleSelectionSwitch setState: [object allowsMultipleSelection]];
  [emptySelectionSwitch setState: [object allowsEmptySelection]];
  [branchSelectionSwitch setState:[object allowsBranchSelection]];
  [separateColumnsSwitch setState:[object separatesColumns]];
  [displayTitlesSwitch setState:[object isTitled]];
  [horizontalScrollerSwitch setState:[object hasHorizontalScroller]];

#warning chek where is the bug ? !!! 
  [[tagForm cellAtIndex:0] setIntValue:[object tag]];

  [minColumnWidthField setStringValue:[NSString stringWithFormat:@"%i",[object minColumnWidth]]];

  [super revert:sender];
}

/* delegate method for tagForm and minColumnWidthField */
-(void) controlTextDidChange:(NSNotification *)aNotification
{
  [self ok:[aNotification object]];
}


@end