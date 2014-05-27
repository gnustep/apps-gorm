/*
  GormMatrixdAttributesInspector.m

   Copyright (C) 2001-2005 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
              Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   
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
  July 2005 : Split inspector classes into separate files.
  Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/


#include "GormMatrixAttributesInspector.h"

#include <GormCore/NSColorWell+GormExtensions.h>

#include <Foundation/NSNotification.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSNibLoading.h>


@implementation	NSMatrix (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormMatrixAttributesInspector";
}
@end

@implementation GormMatrixAttributesInspector

NSUInteger rowsStepperValue;
NSUInteger colsStepperValue;

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
  /* It shouldn't break functionality of rows/columns number 
     changing if someone will decide in the future to change 
     the values of the corresponding steppers in the gorm file. 
     So we stores those values from the gorm file in the auxillary 
     variables to use its later in -[ok:]. 
     (It allows us to avoid the values being hardcoded).
   */
  rowsStepperValue = [rowsStepper intValue];
  colsStepperValue = [colsStepper intValue];

  return self;
}

/* Commit changes that the user makes in the Attributes Inspector */
- (void) ok: (id) sender
{
  if (sender == autosizeSwitch)
    {
      [object setAutosizesCells: ([sender state] == NSOnState)];
    }
  else if (sender == autotagSwitch)
    {
      NSInteger	rows;
      NSInteger	cols;
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
  else if (sender == backgroundColorWell)
    {
      [object setBackgroundColor: [sender color]];
    }
  else if (sender == drawsBackgroundSwitch)
    {
      [object setDrawsBackground: ([sender state] == NSOnState)];
    }
  else if (sender == modeMatrix)
    {
      [(NSMatrix *)object setMode: [[sender selectedCell] tag]];
    }
  else if (sender == propagateSwitch)
    {
      //Nothing for the moment - must implement Prototype
      // item in the pull down menu
    }
  else if (sender == selRectSwitch)
    {
      [object setSelectionByRect: ([sender state] == NSOnState)];
    }
  else if (sender == tagForm)
    {
      [object setTag: [[sender cellAtIndex: 0] intValue]];
    }
  else if (sender == dimensionsForm)
    {
      int rows = [[sender cellAtIndex: 0] intValue];
      int cols = [[sender cellAtIndex: 1] intValue];
      int num;

      while((num = [object numberOfRows]) != rows)
	{
	  if(num > rows)
	    {
	      [object removeRow: num - 1]; // remove last row
	    }
	  else
	    {
	      [object addRow];
	    }
	}
      
      while((num = [object numberOfColumns]) != cols)
	{
	  if(num > cols)
	    {
	      [object removeColumn: num - 1]; // remove last column
	    }
	  else
	    {
	      [object addColumn];
	    }
	}
      //      [object sizeToCells];
      [object setNeedsDisplay: YES];
      [[object superview] setNeedsDisplay: YES];
    }
  else if(sender == rowsStepper)
    {
      int delta = [sender intValue] - rowsStepperValue;
      int num = [object numberOfRows];
      NSRect rect = [object frame];
      NSSize cell = [object cellSize];
      NSSize inter = [object intercellSpacing];

      while(delta > 0)
	{
	  [object addRow];
	  delta--;
	  num++;
	}
      while((delta < 0) && (num > 1))
	{
	  [object removeRow: num - 1];
	  num--;
	  delta++;
	}
      cell.height = (rect.size.height + inter.height) / num - inter.height;
      [object setCellSize: cell];
      [[dimensionsForm cellAtIndex: 0] setIntValue: num];
      [sender setIntValue: rowsStepperValue];
      [dimensionsForm setNeedsDisplay: YES];
      [object setNeedsDisplay: YES];
    }
  else if(sender == colsStepper)
    {
      int delta = [sender intValue] - colsStepperValue;
      int num = [object numberOfColumns];
      NSRect rect = [object frame];
      NSSize cell = [object cellSize];
      NSSize inter = [object intercellSpacing];

      while(delta > 0)
	{
	  [object addColumn];
	  delta--;
	  num++;
	}
      while((delta < 0) && (num > 1))
	{
	  [object removeColumn: num - 1];
	  num--;
	  delta++;
	}
      cell.width = (rect.size.width + inter.width) / num - inter.width;
      [object setCellSize: cell];
      [[dimensionsForm cellAtIndex: 1] setIntValue: num];
      [sender setIntValue: colsStepperValue];
      [dimensionsForm setNeedsDisplay: YES];
      [object setNeedsDisplay: YES];
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
  
  [super ok:sender];
}


/* Sync from object ( NSMatrix ) changes to the inspector   */
- (void) revert:(id)sender
{
  if (object == nil)
      return;


  [autosizeSwitch setState: 
    ([object autosizesCells]) ? NSOnState : NSOffState];

  {
    NSInteger	rows;
    NSInteger cols;

    [object getNumberOfRows: &rows columns: &cols];
 
    if ((rows == 1 && cols > 1) || (cols == 1 && rows > 1))
      [autotagSwitch setEnabled: YES];
    else
      [autotagSwitch setEnabled: NO];
  }

  [backgroundColorWell setColorWithoutAction: [object backgroundColor]];
  [drawsBackgroundSwitch setState: 
    ([object drawsBackground]) ? NSOnState : NSOffState];

  [modeMatrix selectCellWithTag: [(NSMatrix *)object mode]];
  
  [selRectSwitch setState: 
    ([object isSelectionByRect]) ? NSOnState : NSOffState];
  [[tagForm cellAtIndex: 0] setIntValue: [object tag]];
  [[dimensionsForm cellAtIndex: 0] setIntValue: [object numberOfRows]];
  [[dimensionsForm cellAtIndex: 1] setIntValue: [object numberOfColumns]];

  [super revert:sender];
}


/* delegate method for tag Form */
-(void) controlTextDidChange:(NSNotification*) aNotification
{
  [self ok:[aNotification object]];
}

@end
