/*
  GormBoxAttributesInspector.m

   Copyright (C) 2001-2005 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
           Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2003, 2004, 2005  

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

#include "GormBoxAttributesInspector.h"

#warning NSColorWell bug ? 
#include <GormCore/NSColorWell+GormExtensions.h>

#include <Foundation/NSNotification.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSTextFieldCell.h>

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})


/*
  IBObjectAdditions category
*/
@implementation	NSBox (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormBoxAttributesInspector";
}
@end


@implementation GormBoxAttributesInspector

- (id) init
{
  if ([super init] == nil)
      return nil;

  if ([NSBundle loadNibNamed: @"GormNSBoxInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormBoxInspector");
      return nil;
    }

  return self;
}

/* Commit changes that the user makes in the Attributes Inspector */
- (void) ok: (id) sender
{
  /* Position */
  if (sender == positionMatrix)
    {
      [object setTitlePosition: [[sender selectedCell] tag]];
    }
  /* border type */
  else if (sender == borderMatrix)
    {
      [object setBorderType: [[sender selectedCell] tag]];
    }
  /* title */
  else if (sender == titleForm)
    {
      [object setTitle: [[sender cellAtIndex: 0] stringValue]];
    }
  /* content view margins */
  else if (sender == horizontalSlider)
    {
      [object setContentViewMargins:
	NSMakeSize([sender floatValue], [verticalSlider floatValue])];
    }
  else if (sender == verticalSlider)
    {
      [object setContentViewMargins:
	NSMakeSize([horizontalSlider floatValue], [sender floatValue])];
    }
  /* title cell : background color */ 
#warning seems to not work
  else if(sender == colorWell)
    {
      NSTextFieldCell *titleCell = (NSTextFieldCell *)[object titleCell];
      if([titleCell isKindOfClass: [NSTextFieldCell class]])
	{
	  [titleCell setBackgroundColor: [colorWell color]];
	  [object display];
	}
    }
#warning NSBox is borken ? 
  else if(sender == backgroundSwitch)
    {
      NSTextFieldCell *titleCell = (NSTextFieldCell *)[object titleCell];
      if([titleCell isKindOfClass: [NSTextFieldCell class]])
	{
	  BOOL state = ([backgroundSwitch state] == NSOnState)?YES:NO;
	  [titleCell setDrawsBackground: state];
	}
    }

  [super ok:sender];
}

/* Sync from object ( NSBox ) changes to the inspector   */
- (void) revert: (id) sender
{
  NSTextFieldCell *titleCell;
    
  if ( object == nil ) 
    return;

  /* Position */
  [positionMatrix selectCellWithTag: [object titlePosition]];
  /* Border Type */
  [borderMatrix selectCellWithTag: [object borderType]];
  /* title */
  [[titleForm cellAtIndex: 0] setStringValue: VSTR([object title])];
  /* content view margins */
  [horizontalSlider setFloatValue: [object contentViewMargins].width];
  [verticalSlider setFloatValue: [object contentViewMargins].height];

  /* title cell: background color */
  titleCell = (NSTextFieldCell *)[object titleCell];

  if([titleCell isKindOfClass: [NSTextFieldCell class]])
    {
      [colorWell setColorWithoutAction: [titleCell backgroundColor]];
      [backgroundSwitch setState: ([titleCell drawsBackground]?
				   NSOnState:NSOffState)];
    }

  [super revert:sender];
}


/* delegate method for titleForm */
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self ok:[aNotification object]];
}

@end
