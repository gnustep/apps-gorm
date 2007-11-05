/*
   GormMenuItemAttributesInspector.m

   Copyright (C) 1999-2005 Free Software Foundation, Inc.

   Author:  Richard frith-Macdonald (richard@brainstorm.co.uk>
   Date: 1999
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
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
  July 2005 : Spilt inspector in separate classes.
  Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/


#include "GormMenuItemAttributesInspector.h"

#include <Foundation/NSNotification.h>

#include <AppKit/NSMenuItem.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTextField.h>

@implementation GormMenuItemAttributesInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMenuItemAttributesInspector" owner: self]
      == NO)
    {
      NSLog(@"Could not gorm GormMenuItemAttributesInspector");
      return nil;
    }
  return self;
}


- (void) revert : (id)sender
{
  if ( object == nil )
    return;

  [titleText setStringValue: [object title]];
  [shortCut setStringValue: [object keyEquivalent]];
  [tagText setIntValue: [object tag]];
}

-(void) ok: (id) sender
{
  if (sender == titleText)
    {
      [object setTitle: [titleText stringValue]];
    }
  if (sender == shortCut)
    {
      [object setKeyEquivalent:[[shortCut stringValue]stringByTrimmingSpaces]];
    }
  if (sender == tagText)
    {
      [object setTag: [tagText intValue]];
    }

  [super ok:sender];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self ok: [aNotification object]];
}

@end
