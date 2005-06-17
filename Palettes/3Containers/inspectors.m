/* inspectors - Various inspectors for control elements

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

#include <Foundation/Foundation.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSBrowser.h>
#include <InterfaceBuilder/IBInspector.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/NSColorWell+GormExtensions.h>
#include "GormNSTableView.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

/*----------------------------------------------------------------------------
 * NSBrowser
 */
@implementation	NSBrowser (IBObjectAdditions)

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
  else if(control == tagField)
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

@end

@interface GormViewSizeInspector : IBInspector
{
  NSButton	*top;
  NSButton	*bottom;
  NSButton	*left;
  NSButton	*right;
  NSButton	*width;
  NSButton	*height;
  NSForm        *sizeForm;
}
@end

@interface GormTableViewSizeInspector : GormViewSizeInspector
@end
@implementation GormTableViewSizeInspector
- (void) setObject: (id)anObject
{
  id scrollView;
  scrollView = [anObject enclosingScrollView];

  [super setObject: scrollView];
}
@end

/*----------------------------------------------------------------------------
 * NSTableColumn
 */
@implementation NSTableColumn (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormTableColumnAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormTableColumnSizeInspector";
}

@end

@interface GormTableColumnAttributesInspector : IBInspector
{
  id titleAlignmentMatrix;
  id contentsAlignmentMatrix;
  id identifierTextField;
  id resizableSwitch;
  id editableSwitch;
  id setButton;
  id defaultButton;
  id cellTable;
}
- (void) _getValuesFromObject: (id)anObject;
- (void) _setValuesFromControl: (id)anObject;
@end

@implementation GormTableColumnAttributesInspector
- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormNSTableColumnInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableColumnInspector");
      return nil;
    }

  return self;
}

- (void) awakeFromNib
{
  [cellTable setDoubleAction: @selector(ok:)];
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

- (NSString *)_getCellClassName
{
  id cell = [[self object] dataCell];
  NSString *customClassName = [[(id<Gorm>)NSApp classManager] customClassForObject: cell];
  NSString *result = nil;

  if(customClassName == nil)
    {
      result = NSStringFromClass([cell class]);
    }
  else
    {
      result = customClassName;
    }
  
  return result;
}

- (void) _getValuesFromObject: anObject
{
  NSArray *list = [[(id<Gorm>)NSApp classManager] allSubclassesOf: @"NSCell"];
  NSString *cellClassName = [self _getCellClassName];
  int index = [list indexOfObject: cellClassName];

  if(index != NSNotFound && index != -1)
    {
      [cellTable selectRow: index byExtendingSelection: NO];
      [cellTable scrollRowToVisible: index];
    }
  
  switch ([[anObject headerCell] alignment])
    {
    case NSLeftTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 0];
      break;
    case NSCenterTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 1];
      break;
    case NSRightTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 2];
      break;
    default:
      NSLog(@"Unhandled alignment value...");
      break;
    }

  switch ([[anObject dataCell] alignment])
    {
    case NSLeftTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 0];
      break;
    case NSCenterTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 1];
      break;
    case NSRightTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 2];
      break;
    default:
      NSLog(@"Unhandled alignment value...");
      break;
    }

  [identifierTextField setStringValue: [(NSTableColumn *)anObject identifier]];

  if ([anObject isResizable])
    [resizableSwitch setState: NSOnState];
  else
    [resizableSwitch setState: NSOffState];

  if ([anObject isEditable])
    [editableSwitch setState: NSOnState];
  else
    [editableSwitch setState: NSOffState];

}

- (void) _setValuesFromControl: (id) control
{
  if (control == titleAlignmentMatrix)
    {
      if ([[control cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSLeftTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 1] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSCenterTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 2] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSRightTextAlignment];
	}

      if ([[object tableView] headerView] != nil)
	{
	  [[[object tableView] headerView] setNeedsDisplay: YES];
	}
    }
  else if (control == contentsAlignmentMatrix)
    {
      if ([[control cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSLeftTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 1] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSCenterTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 2] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSRightTextAlignment];
	}
      [[object tableView] setNeedsDisplay: YES];
    }
  else if (control == identifierTextField)
    {
      [object setIdentifier:
		[identifierTextField stringValue]];
    }
  else if (control == editableSwitch)
    {
      [object setEditable:
		([editableSwitch state] == NSOnState)];
    }
  else if (control == resizableSwitch)
    {
      [object setResizable:
		([resizableSwitch state] == NSOnState)];
    }
  else if (control == setButton || control == cellTable)
    {
      id classManager = [(id<Gorm>)NSApp classManager];
      id<IBDocuments> doc = [(id<IB>)NSApp activeDocument];
      id cell = nil;
      int i = [cellTable selectedRow];
      NSArray *list = [classManager allSubclassesOf: @"NSCell"];
      NSString *className = [list objectAtIndex: i];
      BOOL isCustom = [classManager isCustomClass: className];
      Class cls = nil;

      if(isCustom)
	{
	  NSString *superClass = [classManager nonCustomSuperClassOf: className];
	  cls = NSClassFromString(superClass);
	  NSLog(@"Setting custom cell..");
	}
      else
	{
	  cls = NSClassFromString(className);
	}

      // initialize
      cell = [[cls alloc] init];
      [object setDataCell: cell];
      [[object tableView] setNeedsDisplay: YES];

      // add it to the document, since it needs a custom class...
      if(isCustom)
	{
	  NSString *name = nil;

	  // An object needs to be a "named object" to have a custom class
	  // assigned to it.   Add it to the document and get the name.
	  [doc attachObject: cell toParent: object];
	  if((name = [doc nameForObject: cell]) != nil)
	    {
	      [classManager setCustomClass: className forName: name];
	    } 
	}

      RELEASE(cell);
    }
  else if (control == defaultButton)
    {
      [object setDataCell: [[NSTextFieldCell alloc] init]];
      [[object tableView] setNeedsDisplay: YES];
      [self setObject: [self object]]; // reset...
    }
}

// data source
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSArray *list = [[(id<Gorm>)NSApp classManager] allSubclassesOf: @"NSCell"];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSArray *list = [[(id<Gorm>)NSApp classManager] allSubclassesOf: @"NSCell"];
  id value = nil;
  if([list count] > 0)
    {
      value = [list objectAtIndex: rowIndex];
    }
  return value;
}

// delegate
- (BOOL)    tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)aTableColumn
		  row: (int)rowIndex
{
  return NO;
}

- (BOOL) tableView: (NSTableView *)tv
   shouldSelectRow: (int)rowIndex
{
  return YES;
}
@end

@interface GormTableColumnSizeInspector : IBInspector
{
  id widthForm;
}
- (void) _getValuesFromObject: (id)anObject;
- (void) _setValuesFromControl: (id)anObject;
@end

@implementation GormTableColumnSizeInspector
- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormNSTableColumnSizeInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableColumnSizeInspector");
      return nil;
    }

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
- (void) _getValuesFromObject: anObject
{
  [[widthForm cellAtRow: 0 column: 0] setFloatValue:
					[anObject minWidth]];
  [[widthForm cellAtRow: 1 column: 0] setFloatValue:
					[anObject width]];
  [[widthForm cellAtRow: 2 column: 0] setFloatValue:
					[anObject maxWidth]];
}

- (void) _setValuesFromControl: (id) control
{
  [object setMinWidth:
	    [[widthForm cellAtRow: 0 column: 0] floatValue]];
  [object setWidth:
	    [[widthForm cellAtRow: 1 column: 0] floatValue]];
  [object setMaxWidth:
	    [[widthForm cellAtRow: 2 column: 0] floatValue]];

  [self _getValuesFromObject: object];
}
@end

/*----------------------------------------------------------------------------
 * NSTableView (possibly embedded in a Scroll view)
 */
@implementation	NSTableView (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormTableViewAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormTableViewSizeInspector";
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
  id backgroundColor;
}

- (void) _getValuesFromObject: (id)anObject;
- (void) _setValuesFromControl: (id)anObject;
@end


@implementation GormTableViewAttributesInspector


- (void) _setValuesFromControl: (id)control
{
  BOOL flag;
  BOOL isScrollView;
  id scrollView;

  scrollView = [[object superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (control == selectionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsMultipleSelection: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsEmptySelection: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnSelection: flag];
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
      int numCols = [object numberOfColumns];
      int newNumCols = [[control cellAtIndex: 1] intValue];

      // add/delete columns based on number in #columns field...
      [object setRowHeight: [[control cellAtIndex: 0] intValue] ];
      if(newNumCols > 0)
	{
	  if(numCols < newNumCols)
	    {
	      int colsToAdd = newNumCols - numCols;
	      int i = 0;
	      // Add columns from the last to the target number...
	      for(i = 0; i < colsToAdd; i++)
		{
		  NSString *identifier = [NSString stringWithFormat: @"column%d",(numCols + i + 1)];
		  NSTableColumn *tc = AUTORELEASE([(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: (id)identifier]);
		  [tc setWidth: 50];
		  [tc setMinWidth: 20];
		  [tc setResizable: YES];
		  [tc setEditable: YES];
		  [object addTableColumn: tc];
		}
	    }
	  else if(numCols > newNumCols)
	    {
	      int colsToDelete = numCols - newNumCols;
	      int i = 0;
	      NSArray *columns = [object tableColumns];
	      // remove columns...
	      for(i = 0; i < colsToDelete; i++)
		{
		  NSTableColumn *tc = [columns objectAtIndex: (i + newNumCols)];
		  [object removeTableColumn: tc];
		}
	    }
	}

      // recompute column sizes..
      [object sizeToFit];
      [object tile];
    } 
  else if (control == optionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setDrawsGrid: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnResizing: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnReordering: flag];
    }
  else if( control == tagField )
    {
      [object setTag:[[tagField cellAtIndex:0] intValue]];
    }
  else if( control == backgroundColor )
    {
      [object setBackgroundColor: [backgroundColor color]];
    }

  [scrollView setNeedsDisplay: YES];
}

- (void) _getValuesFromObject: anObject
{
  BOOL isScrollView;
  id scrollView;

  scrollView = [object enclosingScrollView];

  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (anObject != object)
    {
      return;
    }

  [selectionMatrix deselectAllCells];
  if ([anObject gormAllowsMultipleSelection])
    [selectionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject gormAllowsEmptySelection])
    [selectionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject gormAllowsColumnSelection])
    [selectionMatrix selectCellAtRow: 2 column: 0];

  if (isScrollView)
    {
      [verticalScrollerSwitch setEnabled: YES];
      [verticalScrollerSwitch setState: 
				([scrollView hasVerticalScroller]) ? NSOnState : NSOffState];

      [horizontalScrollerSwitch setEnabled: YES];   
      [horizontalScrollerSwitch setState: 
				  ([scrollView hasHorizontalScroller]) ? NSOnState : NSOffState];
      
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
  [[rowsHeightForm cellAtIndex: 1] setIntValue: [anObject numberOfColumns]];

  [optionMatrix deselectAllCells];
  if ([anObject drawsGrid])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject gormAllowsColumnResizing])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject gormAllowsColumnReordering])
    [optionMatrix selectCellAtRow: 2 column: 0];
  [[tagField cellAtIndex:0] setIntValue:[anObject tag]];

  // set the background color into the inspector...
  [backgroundColor setColorWithoutAction: [anObject backgroundColor]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormNSTableViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableViewInspector");
      return nil;
    }

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

@end

/*----------------------------------------------------------------------------
 * NSTabView (possibly embedded in a Scroll view)
 */

static NSString *ITEM=@"item";

@implementation	NSTabView (IBObjectAdditions)

- (NSString*) inspectorClassName
{
  return @"GormTabViewInspector";
}

- (NSString*) editorClassName
{
  return @"GormTabViewEditor";
}

@end

@interface GormTabViewInspector : IBInspector
{
  id typeMatrix;
  int numberOfDisplayItem;
  id allowtruncate;
  id  numberOfItemsField;
  id  itemStepper;
  id  itemLabel;
  id  itemIdentifier;
}

- (void) _getValuesFromObject: (id)anObject;
- (void) _setValuesFromControl: (id)anObject;
@end


@implementation GormTabViewInspector


- (void) _setValuesFromControl: (id)control
{
  if (control == typeMatrix)
      [object setTabViewType:[[control selectedCell] tag]];
  else if (control == allowtruncate)
    {
      BOOL flag;
      flag = ([allowtruncate state] == NSOnState) ? YES : NO;
      [object setAllowsTruncatedLabels:flag];
    }
  else if (control == itemStepper )
    {
      int number = [itemStepper intValue];
      [itemLabel setStringValue:[[object tabViewItemAtIndex:number] label]];
      [itemIdentifier setStringValue:[[object tabViewItemAtIndex:number] identifier]];
      [object selectTabViewItemAtIndex:number];
    }
  

  else if (control == numberOfItemsField)
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
  else if ( control == itemLabel )
    {
      if ( ! [[itemLabel stringValue] isEqualToString:@""] )
	[[object selectedTabViewItem] setLabel:[itemLabel stringValue]];
    }
  else if ( control == itemIdentifier )
    {
      if ( ! [[itemIdentifier stringValue] isEqualToString:@""] )
	[[object selectedTabViewItem] setIdentifier:[itemIdentifier stringValue]];
    }


  [object display];
}

- (void) _getValuesFromObject: anObject
{
  unsigned int numberOfTabViewItems;
  numberOfTabViewItems=[anObject numberOfTabViewItems];
  
  [numberOfItemsField setStringValue:[NSString stringWithFormat:@"%i",numberOfTabViewItems]];

  [itemStepper setMaxValue:(numberOfTabViewItems -1)];

  [itemLabel setStringValue:[[anObject selectedTabViewItem] label]];
  [itemIdentifier setStringValue:[[anObject selectedTabViewItem] identifier]];
}

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
  [super ok: sender];
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

