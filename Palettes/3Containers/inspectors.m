/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
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

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

/*----------------------------------------------------------------------------
 * NSBrowser
 */
@implementation	NSBrowser (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormBrowserAttributesInspector";
}

@end

@interface GormBrowserAttributesInspector : IBInspector
{
  id optionMatrix;
  id tagField;
}

- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormBrowserAttributesInspector


- (void) _setValuesFromControl: (id)control
{
  if (control == optionMatrix)
    {
      BOOL flag;

      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsMultipleSelection: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsEmptySelection: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsBranchSelection: flag];

      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;
      [object setSeparatesColumns: flag];
      
      flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
      [object setTitled: flag];

      flag = ([[control cellAtRow: 5 column: 0] state] == NSOnState) ? YES : NO;
      [object setHasHorizontalScroller: flag];
    }
  else if( control == tagField )
    {
      [object setTag:[[tagField cellAtIndex:0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{

  if (anObject != object)
    {
      return;
    }
  
  [optionMatrix deselectAllCells];
  if ([anObject allowsMultipleSelection])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject allowsEmptySelection])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject allowsBranchSelection])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([anObject separatesColumns])
    [optionMatrix selectCellAtRow: 3 column: 0];
  if ([anObject isTitled])
    [optionMatrix selectCellAtRow: 4 column: 0];
  if ([anObject hasHorizontalScroller])
    [optionMatrix selectCellAtRow: 5 column: 0];
  
  [[tagField cellAtIndex:0] setIntValue:[anObject tag]];
}

- (void) dealloc
{
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormBrowserInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormBrowserInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSTableView (possibly embedded in a Scroll view)
 */
@implementation	NSTableView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormTableViewAttributesInspector";
}

@end

@interface GormTableViewAttributesInspector : IBInspector
{
  id selectionMatrix;
  id verticalScrollerSwitch;
  id horizontalScrollerSwitch;
  id borderMatrix;
  id rowsHeightForm;
  id optionMatrix;
  id tagField;
}

- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormTableViewAttributesInspector


- (void) _setValuesFromControl: (id)control
{
  BOOL flag;
  BOOL isScrollView;
  id scrollView;

  scrollView = [[object superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (control == optionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsMultipleSelection: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsEmptySelection: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsColumnSelection: flag];
    }

  else if ( (control == verticalScrollerSwitch) && isScrollView)
    {
      flag = ([control state] == NSOnState) ? YES : NO;
      [scrollView setHasVerticalScroller: flag];
    }
 
  else if ( (control == horizontalScrollerSwitch) && isScrollView)
    {
      flag = ([control state] == NSOnState) ? YES : NO;
      [scrollView setHasHorizontalScroller: flag];
    } 

  else if ( (control == borderMatrix) && isScrollView)
    {
      [scrollView setBorderType: [[control selectedCell] tag]];
    }
  
  else if (control == rowsHeightForm)
    {
      [object setRowHeight: [[control cellAtIndex: 0] intValue] ];
    } 

  else if (control == optionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setDrawsGrid: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsColumnResizing: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsColumnReordering: flag];
    }
  else if( control == tagField )
    {
      [object setTag:[[tagField cellAtIndex:0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  BOOL isScrollView;
  id scrollView;

  scrollView = [[object superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (anObject != object)
    {
      return;
    }
  
  [selectionMatrix deselectAllCells];
  if ([anObject allowsMultipleSelection])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject allowsEmptySelection])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject allowsColumnSelection])
    [optionMatrix selectCellAtRow: 2 column: 0];

  if (isScrollView)
    {
      [verticalScrollerSwitch setEnabled: YES];
      [verticalScrollerSwitch setState: 
         ([scrollView hasVerticalScroller]) ? NSOnState : NSOffState];

      [horizontalScrollerSwitch setEnabled: YES];   
      [horizontalScrollerSwitch setState: 
         ([scrollView hasVerticalScroller]) ? NSOnState : NSOffState];

      [borderMatrix setEnabled: YES];
      [borderMatrix selectCellWithTag: [scrollView borderType]];
    }
  else
    {
      [verticalScrollerSwitch setEnabled: NO];
      [horizontalScrollerSwitch setEnabled: NO];   
      [borderMatrix setEnabled: NO];   
    }

  [[rowsHeightForm cellAtIndex: 0] setIntValue: [anObject rowHeight] ];

  [optionMatrix deselectAllCells];
  if ([anObject drawsGrid])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject allowsColumnResizing])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject allowsColumnReordering])
    [optionMatrix selectCellAtRow: 2 column: 0];
  [[tagField cellAtIndex:0] setIntValue:[anObject tag]];
}

- (void) dealloc
{
  RELEASE(window);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormTableViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableViewInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end


/*----------------------------------------------------------------------------
 * NSScrollView
 */

/*
 * For now NSScrollView has no inspector in itself. It is only used as a 
 * convenience in the NSTableView and NSTextView controls and there
 * are minimal NSScrollView settings in the inspector of these 2 controls
 * (like horizontal and vertical scrollbar)
*/

@implementation	NSScrollView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormEmptyInspector";
}

@end

@interface GormScrollViewAttributesInspector : IBInspector
{
}
@end

@implementation GormScrollViewAttributesInspector
@end

