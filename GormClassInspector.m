/** <title>GormClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: March 2003

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
#include "GormClassInspector.h"
#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormDocument.h"
#include <InterfaceBuilder/IBApplicationAdditions.h>

NSNotificationCenter *nc = nil;

// the data source classes for each of the tables...
@interface GormOutletDataSource : NSObject
{
  id inspector;
}
- (void) setInspector: (id)ins;
@end

@interface GormActionDataSource : NSObject
{
  id inspector;
}
- (void) setInspector: (id)ins;
@end

@implementation GormOutletDataSource 
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSArray *list = [[(Gorm *)NSApp classManager] allOutletsForClassNamed: [inspector _currentClass]];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSArray *list = [[(Gorm *)NSApp classManager] allOutletsForClassNamed: [inspector _currentClass]];
  id value = nil;
  if([list count] > 0)
    {
      value = [list objectAtIndex: rowIndex];
    }
  return value;
}

- (void) tableView: (NSTableView *)tv
    setObjectValue: (id)anObject
    forTableColumn: (NSTableColumn *)tc
	       row: (int)rowIndex
{
  NSArray *list = [[(Gorm *)NSApp classManager] allOutletsForClassNamed: [inspector _currentClass]];
  NSString *name = [list objectAtIndex: rowIndex];

  RETAIN(anObject);
  [[(Gorm *)NSApp classManager] replaceOutlet: name
				withOutlet: anObject
				forClassNamed: [inspector _currentClass]];
}

// set methods
- (void) setInspector: (id)ins
{
  ASSIGN(inspector, ins);
}
@end

@implementation GormActionDataSource
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSArray *list = [[(Gorm *)NSApp classManager] allActionsForClassNamed: [inspector _currentClass]];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSArray *list = [[(Gorm *)NSApp classManager] allActionsForClassNamed: [inspector _currentClass]];
  return [list objectAtIndex: rowIndex];
}

- (void) tableView: (NSTableView *)tv
    setObjectValue: (id)anObject
    forTableColumn: (NSTableColumn *)tc
	       row: (int)rowIndex
{
  NSArray *list = [[(Gorm *)NSApp classManager] allActionsForClassNamed: [inspector _currentClass]];
  NSString *name = [list objectAtIndex: rowIndex];

  RETAIN(anObject);
  [[(Gorm *)NSApp classManager] replaceAction: name
				withAction: anObject
				forClassNamed: [inspector _currentClass]];
}

// set method
- (void) setInspector: (id)ins
{
  ASSIGN(inspector, ins);
}
@end

@implementation GormClassInspector
+ (void) initialize
{
  if (self == [GormClassInspector class])
    {
      nc = [NSNotificationCenter defaultCenter];
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // initialize all member variables...
      actionTable = nil;
      addAction = nil;
      addOutlet = nil;
      classField = nil;
      outletTable = nil;
      removeAction = nil;
      removeOutlet = nil;
      tabView = nil;
      currentClass = nil;
      actionData = nil;
      outletData = nil;

      // load the gui...
      if (![NSBundle loadNibNamed: @"GormClassInspector"
		     owner: self])
	{
	  NSLog(@"Could not open gorm GormClassInspector");
	  return nil;
	}

      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: GormDidModifyClassNotification
	       object: nil];

    }
  return self;
}

- (void) awakeFromNib
{
  // instantiate..
  actionData = [[GormActionDataSource alloc] init];
  outletData = [[GormOutletDataSource alloc] init];

  // initialize..
  [actionData setInspector: self];
  [outletData setInspector: self];

  // use..
  [actionTable setDataSource: actionData];
  [outletTable setDataSource: outletData];

  // delegate...
  [actionTable setDelegate: self];
  [outletTable setDelegate: self];
}

- (void) _refreshView
{
  id addActionCell = [addAction cell];
  id removeActionCell = [removeAction cell];
  id addOutletCell = [addOutlet cell];
  id removeOutletCell = [removeOutlet cell];
  BOOL isCustom = [classManager isCustomClass: [self _currentClass]];
  BOOL isFirstResponder = [[self _currentClass] isEqualToString: @"FirstResponder"];

  [classField setStringValue: [self _currentClass]];
  [outletTable reloadData];
  [actionTable reloadData];

  // activate for actions...
  [addActionCell setEnabled: isCustom];
  [removeActionCell setEnabled: isCustom];

  // activate for outlet...
  [addOutletCell setEnabled: (isCustom && !isFirstResponder)];
  [removeOutletCell setEnabled: (isCustom && !isFirstResponder)];
}

- (void) addAction: (id)sender
{
  [[(Gorm *)NSApp classManager] addNewActionToClassNamed: [self _currentClass]];
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [actionTable reloadData];
}

- (void) addOutlet: (id)sender
{
  [[(Gorm *)NSApp classManager] addNewOutletToClassNamed: [self _currentClass]];  
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [outletTable reloadData];
}

- (void) removeAction: (id)sender
{
  int i = [actionTable selectedRow];
  NSArray *list = [[(Gorm *)NSApp classManager] allActionsForClassNamed: [self _currentClass]];
  NSString *name = [list objectAtIndex: i];
  [[(Gorm *)NSApp classManager] removeAction: name fromClassNamed: [self _currentClass]];
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [actionTable reloadData];
}

- (void) removeOutlet: (id)sender
{
  int i = [outletTable selectedRow];
  NSArray *list = [[(Gorm *)NSApp classManager] allOutletsForClassNamed: [self _currentClass]];
  NSString *name = [list objectAtIndex: i];
  [[(Gorm *)NSApp classManager] removeOutlet: name fromClassNamed: [self _currentClass]];
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [outletTable reloadData];
}

- (void) select: (id)sender
{
  NSLog(@"select...");
}

- (void) setObject: (id)anObject
{
  ASSIGN(theobject,anObject);
  ASSIGN(classManager, [(Gorm *)NSApp classManager]);
  RETAIN(theobject);
  [self _refreshView];
}

- (NSString *) _currentClass
{
  return [theobject className];
}

- (void) handleNotification: (NSNotification *)notification
{
  if([notification object] == classManager)
    {
      [self _refreshView];
    }
}

// table delegate/data source methods...
- (BOOL)    tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)aTableColumn
		  row: (int)rowIndex
{
  BOOL result = NO;
  NSArray *list = nil;
  NSString *name = nil;
  NSTabViewItem *tvi = [tabView selectedTabViewItem];
  BOOL isAction = [[tvi identifier] isEqualToString: @"Actions"];
  NSString *className = [self _currentClass];
  // id classManager = [(Gorm *)NSApp classManager];

  if(isAction)
    {
      list = [classManager allActionsForClassNamed: className];
      name = [list objectAtIndex: rowIndex];
    }
  else
    {
      list = [classManager allOutletsForClassNamed: className];
      name = [list objectAtIndex: rowIndex];
    }
  
  if([classManager isCustomClass: className])
    {
      if (isAction)
	{
	  result = [classManager isAction: name
				 ofClass: className];
	}
      else 
	{
	  result = [classManager isOutlet: name
				 ofClass: className];
	}	       
    }
  return result;
}
@end
