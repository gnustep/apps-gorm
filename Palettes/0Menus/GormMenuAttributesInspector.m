/*
   GormMenuAttributesInspector.m

   Copyright (C) 1999-2005 Free Software Foundation, Inc.

   Author:  Richard frith-Macdonald (richard@brainstorm.co.uk>
   Date: 1999
   
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
  July 2005 : Spilt inspector in separate classes.
  Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/

#include "GormMenuAttributesInspector.h"

#include <Foundation/NSNotification.h>

#include <GormCore/GormDocument.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTextField.h>


#define WINDOWSMENUTAG  0
#define SERVICESMENUTAG 1 
#define NORMALMENUTAG   2

@implementation	NSMenu (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormMenuAttributesInspector";
}
@end


@implementation GormMenuAttributesInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMenuAttributesInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormMenuAttributesInspector");
      return nil;
    }
  return self;

}

-(void) ok:(id) sender
{
  if ( sender == titleText ) 
    {
      [object setTitle:[titleText stringValue]];
    }
  if ( sender == autoenable ) 
    {
      BOOL flag;
      
      // look at the values passed back in the matrix.
      flag = ([autoenable state] == NSOnState) ? YES : NO;
      [object setAutoenablesItems: flag];
    }
  else if ( sender == menuType ) 
    {
      BOOL flag;
      GormDocument *doc = (GormDocument *)[(id<IB>)NSApp activeDocument];
      int tag = [[menuType selectedCell] tag];
      
      switch ( tag ) 
	{
	case WINDOWSMENUTAG: 
	  [doc setWindowsMenu:object];
	  if ( [doc servicesMenu] == object ) 
	    [doc setServicesMenu: nil];
	  break;
	  
	case SERVICESMENUTAG:
	  [doc setServicesMenu: object];	  
	  if ( [doc windowsMenu] == object )	  
	    [doc setWindowsMenu: nil];
	  break;
	  
	case NORMALMENUTAG:
	  if ( [doc windowsMenu] == object )
	    [doc setWindowsMenu: nil]; 
	  if ( [doc servicesMenu] == object )
	    [doc setServicesMenu: nil];
	  break;
	}
    }

  [super ok:sender];
}



- (void) revert: (id)sender
{
  GormDocument *doc;
  
  if ( object == nil ) 
    return;

  doc = (GormDocument *)[(id<IB>)NSApp activeDocument];

  [titleText setStringValue: [object title]];
  [autoenable setState: ([object autoenablesItems]?NSOnState:NSOffState)];

  // set up the menu type matrix...
  if([doc windowsMenu] == object)
    {
      [menuType selectCellAtRow:WINDOWSMENUTAG column: 0];
    }
  else if([doc servicesMenu] == object)
    {
      [menuType selectCellAtRow:SERVICESMENUTAG column: 0];
    }
  else 
    {
      [menuType selectCellAtRow:NORMALMENUTAG column: 0];
    }
}


/* delegate method used for menu title */
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [object setTitle: [titleText stringValue]];
}

@end

