/** <title>GormCustomClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: September 2002

   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormCustomClassInspector.h"
#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormDocument.h"
#include "GormPrivate.h"

@implementation GormCustomClassInspector
+ (void) initialize
{
  if (self == [GormCustomClassInspector class])
    {
      // TBD
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // initialize all member variables...
      _classManager = nil;
      _currentSelectionClassName = nil;
      _rowToSelect = 0;
      
      // load the gui...
      if (![NSBundle loadNibNamed: @"GormCustomClassInspector"
			    owner: self])
	{
	  NSLog(@"Could not open gorm GormCustomClassInspector");
	  return nil;
	}
    }
  return self;
}

- (void) _setCurrentSelectionClassName: (id)anobject
{
  NSString	 *className;

  className = [_classManager customClassForObject: anobject];
  if ([className isEqualToString: @""]
    || className == nil)
    {
      className = [anobject className];
    }

  ASSIGN(_currentSelectionClassName, className);
  ASSIGN(_parentClassName, [anobject className]);
}

- (NSMutableArray *) _generateClassList
{
  NSMutableArray *classes = [NSMutableArray arrayWithObject: _parentClassName];
  NSArray *subclasses = [_classManager allSubclassesOf: _parentClassName];
  NSEnumerator *en = [subclasses objectEnumerator];
  NSString *className = nil;
  Class parentClass = NSClassFromString(_parentClassName);

  while((className = [en nextObject]) != nil)
    {
      if([_classManager isCustomClass: className] == YES)
	{
	  [classes addObject: className];
	}
      else if(parentClass != nil)
	{
	  Class cls = NSClassFromString(className);
	  if(cls != nil)
	    {
	      if([cls respondsToSelector: @selector(canSubstituteForClass:)])
		{
		  if([cls canSubstituteForClass: parentClass])
		    {
		      [classes addObject: className];
		    }
		}
	    }
	}
    }
  
  return classes;
}

- (void) setObject: (id)anObject
{
  if(anObject != nil)
    {
      NSMutableArray *classes = nil; 
      
      [super setObject: anObject];
      _document = [(id<IB>)NSApp activeDocument];
      _classManager = [(id<Gorm>)NSApp classManager];
      
      // get the information...
      NSDebugLog(@"Current selection %@", [self object]);
      [self _setCurrentSelectionClassName: [self object]];
      
      // load the array...
      [browser loadColumnZero];  
      
      // get a list of all of the classes allowed and the class to be shown
      // and select the appropriate row in the inspector...
      classes = [self _generateClassList];
      // [NSMutableArray arrayWithObject: _parentClassName];
      // [classes addObjectsFromArray: [_classManager allCustomSubclassesOf: _parentClassName]];
      
      _rowToSelect = [classes indexOfObject: _currentSelectionClassName];
      _rowToSelect = (_rowToSelect != NSNotFound)?_rowToSelect:0;
      
      if(_rowToSelect != NSNotFound)
	{
	  [browser selectRow: _rowToSelect inColumn: 0];
	}
    }
}

- (void) awakeFromNib
{
  [browser setTarget: self];
  [browser setAction: @selector(select:)];
  [browser setMaxVisibleColumns: 1];
}

- (void) _replaceCellClassForObject: (id)obj
			  className: (NSString *)name
{
  if([name isEqualToString: @"NSSecureTextField"] || 
     [name isEqualToString: @"NSTextField"])
    {
      NSCell *cell = [obj cell];
      NSCell *newCell = nil;
      BOOL   drawsBackground = [object drawsBackground];

      // instantiate the cell...
      if([name isEqualToString: @"NSSecureTextField"])
	{
	  newCell = [[NSSecureTextFieldCell alloc] init];
	}
      else if([name isEqualToString: @"NSTextField"])
	{
	  newCell = [[NSTextFieldCell alloc] init];
	}

      // copy everything from the old cell...
      [newCell setFont: [cell font]];
      [newCell setEnabled: [cell isEnabled]];
      [newCell setEditable: [cell isEditable]];
      [newCell setImportsGraphics: [cell importsGraphics]];
      [newCell setShowsFirstResponder: [cell showsFirstResponder]];
      [newCell setRefusesFirstResponder: [cell refusesFirstResponder]];
      [newCell setBordered: [cell isBordered]];
      [newCell setBezeled: [cell isBezeled]];
      [newCell setScrollable: [cell isScrollable]];
      [newCell setSelectable: [cell isSelectable]];
      [newCell setState: [cell state]];

      // set attributes of textfield.
      [object setCell: newCell];
      [object setDrawsBackground: drawsBackground];
    }
}

- (void) select: (id)sender
{
  NSCell *cell = [browser selectedCellInColumn: 0];
  NSString *stringValue = [NSString stringWithString: [cell stringValue]];
  NSString *nameForObject = [_document nameForObject: [self object]];
  NSString *classForObject = [[self object] className]; 

  NSDebugLog(@"selected = %@, class = %@",stringValue,nameForObject);

  /* add or remove the mapping as necessary. */
  if(nameForObject != nil)
    {
      [super ok: sender];
      if (![stringValue isEqualToString: classForObject])
	{
	  [_classManager setCustomClass: stringValue
			 forName: nameForObject];
	}
      else
	{
	  [_classManager removeCustomClassForName: nameForObject];
	}

      [self _replaceCellClassForObject: [self object]
	    className: stringValue];

    }
  else
    NSLog(@"name for object %@ returned as nil",[self object]);
}

// Browser delegate
- (void)    browser: (NSBrowser *)sender 
createRowsForColumn: (int)column
	   inMatrix: (NSMatrix *)matrix
{
  if (_parentClassName != nil)
    {
      NSMutableArray	*classes;
      NSEnumerator	*e = nil;
      NSString		*class = nil;
      NSBrowserCell	*cell = nil;
      int		i = 0;
      
      classes = [self _generateClassList]; 
      // [NSMutableArray arrayWithObject: _parentClassName];
      // get a list of all of the classes allowed and the class to be shown.
      //[classes addObjectsFromArray:
      // [_classManager allCustomSubclassesOf: _parentClassName]];
      
      // enumerate through the classes...
      e = [classes objectEnumerator];
      while ((class = [e nextObject]) != nil)
	{
	  if ([class isEqualToString: _currentSelectionClassName])
	    {
	      _rowToSelect = i;
	    }
	  [matrix insertRow: i withCells: nil];
	  cell = [matrix cellAtRow: i column: 0];
	  [cell setLeaf: YES];
	  i++;
	  [cell setStringValue: class];
	}
    }
}

- (NSString*) browser: (NSBrowser*)sender 
	titleOfColumn: (int)column
{
  NSDebugLog(@"Delegate called");
  return @"Class";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender 
   isColumnValid: (int)column
{
  return YES;
}
@end
