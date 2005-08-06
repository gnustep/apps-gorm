/*
   GormComboBoxAttributesInspector.m

   Copyright (C) 2001-2005 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Date: Nov 2001
   
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

#include "GormNSComboBoxAttributesInspector.h"

#include <AppKit/NSButton.h>
#include <GormCore/NSColorWell+GormExtensions.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTextField.h>


/*
  IBObjectAdditions category 
*/
@implementation	NSComboBox (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormNSComboBoxAttributesInspector";
}
@end


@implementation GormNSComboBoxAttributesInspector

- (id) init
{
  if ([super init] == nil)
    return nil;
  
  if ([NSBundle loadNibNamed: @"GormNSComboBoxInspector" owner: self] == NO)
    {
       NSLog(@"Could not gorm GormNSComboBoxInspector");
       return nil;
     }
  
  return self;
}

/* Commit changes that the user makes in the Attributes Inspector */
- (void) ok:(id) sender
{
  if (sender == backgroundColorWell)
    {
      [object setBackgroundColor: [sender color]];
    }
  else if (sender == textColorWell)
    {
      [object setTextColor: [sender color]];
    }
  else if (sender == alignmentMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[sender selectedCell] tag]];
    }
  else if (sender == optionMatrix)
    {
      BOOL flag;

      flag = ([[sender cellAtRow: 0 column: 0] state] == NSOnState) ? YES :NO;
      [object setEditable: flag];
      flag = ([[sender cellAtRow: 1 column: 0] state] == NSOnState) ? YES :NO;
      [object setSelectable: flag];
      flag = ([[sender cellAtRow: 2 column: 0] state] == NSOnState) ? YES :NO;
      [[object cell] setUsesDataSource: flag];
    }
  else if (sender == visibleItemsForm)
    {
      [object setNumberOfVisibleItems: [[sender cellAtIndex: 0] intValue]];
    }
  else if (sender == itemField )
    {
#warning To be done
    }
  else if (sender == addButton) 
    {
      if ( ! [[itemTxt stringValue] isEqualToString:@""] )
	{
	  [object addItemWithObjectValue:[itemTxt stringValue]];
	  [itemTableView reloadData];
	}
    }
  else if (sender == removeButton) 
    {
      int selected = [itemTableView selectedRow];
      if ( selected != -1 ) 
	{
	  [itemTxt setStringValue:@""];
	  [object removeItemAtIndex:selected];
	  [itemTableView reloadData];
	}
    }

  [super ok:sender];
}

/* Sync from object ( NSComboBox ) changes to the inspector   */
-(void) revert:(id) sender
{
  
  if ( object == nil )
    return;

  [backgroundColorWell setColorWithoutAction: [object backgroundColor]];
  [textColorWell setColorWithoutAction: [object textColor]];

  [alignmentMatrix selectCellWithTag: [object alignment]];

#warning Fabien TODO remove the matrix ? 
  [optionMatrix deselectAllCells];

  if ([object isEditable])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([object isSelectable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([object usesDataSource])
    [optionMatrix selectCellAtRow: 2 column: 0];

  [itemTableView reloadData];
  [itemTxt setStringValue:@""];

  //     [[visibleItemsForm cellAtIndex: 0]
  //       setIntValue: [object numberOfVisibleItems]];
  
  [super revert:sender];
}

/* TableView dataSource methods */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  if (aTableView == itemTableView )
    return [[object objectValues]  count];
  
  return 0;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn
	    row:(int)rowIndex
{
  if (aTableView == itemTableView )
    return  [object itemObjectValueAtIndex:rowIndex];
  
  return nil;
}

/* TableView delegate methods */
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
  if ( aTableView == itemTableView ) 
    {
      [itemTxt setStringValue:[object itemObjectValueAtIndex:rowIndex]];
      return YES;
    }
   return NO;
}

#warning TODO : clean up 
// - (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
// {
// //   if (fieldEditor != itemTxt )
// //     return YES;
// //   if ( [[itemTxt setStringValue] isEqualToString:@""] )
// //     return YES;
// //   else if ( [aTableView selectedRow] != -1 )
// //     {
// //       [object 
    
//   return YES;
// }

@end
