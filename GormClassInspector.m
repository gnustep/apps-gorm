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

// interfaces
@interface GormDocument (GormClassInspectorAdditions)
- (void) collapseClass: (NSString *)className;
- (void) reloadClasses;
@end

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

@interface GormClassesDataSource : NSObject
{
  id inspector;
}
- (void) setInspector: (id)ins;
@end

// implementation
@implementation GormDocument (GormClassInspectorAdditions)
- (void) collapseClass: (NSString *)className
{
  NSDebugLog(@"%@",className);
  [classesView reset];
  [classesView expandItem: className];
  [classesView collapseItem: className collapseChildren: YES];
}

- (void) reloadClasses
{
  [classesView reloadData];
}
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
  id classManager = [(Gorm *)NSApp classManager];
  NSString *currentClass = [inspector _currentClass];
  NSArray *list = [classManager allOutletsForClassNamed: currentClass];
  NSString *name = [list objectAtIndex: rowIndex];
  NSString *formattedOutlet = [GormDocument formatOutlet: anObject];
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];
  
  if(![name isEqual: anObject])
    {
      BOOL removed = [document 
		       removeConnectionsWithLabel: name 
		       forClassNamed: currentClass
		       isAction: NO];
      if(removed)
	{
	  [classManager replaceOutlet: name
			withOutlet: formattedOutlet
			forClassNamed: currentClass];
	  
	  // collapse the class in question if it's being edited and make
	  // certain that names in the list are kept in sync.
	  [document collapseClass: currentClass];
	  [document reloadClasses];
	  [document selectClass: currentClass];
	}
    }
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
  id classManager = [(Gorm *)NSApp classManager];
  NSString *currentClass = [inspector _currentClass];
  NSArray *list = [classManager allActionsForClassNamed: currentClass];
  NSString *name = [list objectAtIndex: rowIndex];
  NSString *formattedAction = [GormDocument formatAction: anObject];
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];

  if(![name isEqual: anObject])
    {
      BOOL removed = [document 
		       removeConnectionsWithLabel: name 
		       forClassNamed: currentClass
		       isAction: YES];
      if(removed)
	{
	  [classManager replaceAction: name
			withAction: formattedAction
			forClassNamed: currentClass];
	  
	  // collapse the class in question if it's being edited and make
	  // certain that names in the list are kept in sync.
	  [document collapseClass: currentClass];
	  [document reloadClasses];
	  [document selectClass: currentClass];
	}
    }
}

// set method
- (void) setInspector: (id)ins
{
  ASSIGN(inspector, ins);
}
@end

@implementation GormClassesDataSource 
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSArray *list = [[(Gorm *)NSApp classManager] allClassNames];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSArray *list = [[(Gorm *)NSApp classManager] allClassNames];
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
  // cannot replace any values for this data source...
}

// set methods
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
      parentClassData = nil;

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
  parentClassData = [[GormClassesDataSource alloc] init];

  // initialize..
  [actionData setInspector: self];
  [outletData setInspector: self];
  [parentClassData setInspector: self];

  // use..
  [actionTable setDataSource: actionData];
  [outletTable setDataSource: outletData];
  [parentClass setDataSource: parentClassData];
  [parentClass setDoubleAction: @selector(selectClass:)];
  [parentClass setTarget: self];

  // delegate...
  [actionTable setDelegate: self];
  [outletTable setDelegate: self];
  [parentClass setDelegate: self];
}

- (void) _refreshView
{
  id addActionCell = [addAction cell];
  id removeActionCell = [removeAction cell];
  id addOutletCell = [addOutlet cell];
  id removeOutletCell = [removeOutlet cell];
  id selectClassCell = [selectClass cell];
  id searchCell = [search cell];
  BOOL isEditable = [classManager isCustomClass: [self _currentClass]]; 
  BOOL isFirstResponder = [[self _currentClass] isEqualToString: @"FirstResponder"];
  NSArray *list = [classManager allClassNames];
  NSString *superClass = [classManager parentOfClass: [self _currentClass]];
  int index = [list indexOfObject: superClass];

  [classField setStringValue: [self _currentClass]];
  [outletTable reloadData];
  [actionTable reloadData];
  [parentClass reloadData];

  // activate for actions...
  [addActionCell setEnabled: YES]; //isEditable];
  [removeActionCell setEnabled: YES]; //isEditable];

  // activate for outlet...
  [addOutletCell setEnabled: (isEditable && !isFirstResponder)];
  [removeOutletCell setEnabled: (isEditable && !isFirstResponder)];

  // activate select class...
  [selectClassCell setEnabled: (isEditable && !isFirstResponder)];
  [parentClass setEnabled: (isEditable && !isFirstResponder)];
  [searchCell setEnabled: (isEditable && !isFirstResponder)];
  [classField setEditable: (isEditable && !isFirstResponder)];
  [classField setBackgroundColor: ((isEditable && !isFirstResponder)?[NSColor whiteColor]:[NSColor lightGrayColor])];

  // select the parent class
  if(index != NSNotFound && list != nil)
    {
      [parentClass selectRow: index byExtendingSelection: NO];
      [parentClass scrollRowToVisible: index];
    }
}

- (void) addAction: (id)sender
{
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];
  NSString *className = [self _currentClass];
  NSString *newAction = [classManager addNewActionToClassNamed: className];  
  NSArray *list = [classManager allActionsForClassNamed: className];
  int row = [list indexOfObject: newAction];

  [document collapseClass: className];
  [document reloadClasses];
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [actionTable reloadData];
  [actionTable scrollRowToVisible: row];
  [actionTable selectRow: row byExtendingSelection: NO];
  [document selectClass: className];
}

- (void) addOutlet: (id)sender
{
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];
  NSString *className = [self _currentClass];
  NSString *newOutlet = [classManager addNewOutletToClassNamed: className];  
  NSArray *list = [classManager allOutletsForClassNamed: className];
  int row = [list indexOfObject: newOutlet];
  
  [document collapseClass: className];
  [document reloadClasses];
  [nc postNotificationName: IBInspectorDidModifyObjectNotification
		    object: classManager];
  [outletTable reloadData];
  [outletTable scrollRowToVisible: row];
  [outletTable selectRow: row byExtendingSelection: NO];
  [document selectClass: className];
}

- (void) removeAction: (id)sender
{
  int i = [actionTable selectedRow];
  NSString *className = [self _currentClass];
  NSArray *list = [classManager allActionsForClassNamed: className];
  BOOL removed = NO;
  BOOL isCustom = [classManager isCustomClass: className]; 
  NSString *name = nil;
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];

  // check the count...
  if(isCustom || [classManager isCategoryForClass: className])
    {
      if([list count] > 0 && i >= 0 && i < [list count])
	{
	  [actionTable deselectAll: self];
	  name = [list objectAtIndex: i];
	  if(isCustom || [classManager isAction: name onCategoryForClassNamed: className])
	    {
	      removed = [document 
			  removeConnectionsWithLabel: name 
			  forClassNamed: currentClass
			  isAction: YES];
	    }
	}
      
      if(removed)
	{
	  [document collapseClass: className];
	  [document reloadClasses];
	  [classManager removeAction: name fromClassNamed: className];
	  [nc postNotificationName: IBInspectorDidModifyObjectNotification
	      object: classManager];
	  [actionTable reloadData];
	  [document selectClass: className];
	}
    }
}

- (void) removeOutlet: (id)sender
{
  int i = [outletTable selectedRow];
  NSString *className = [self _currentClass];
  NSArray *list = [classManager allOutletsForClassNamed: className];
  BOOL removed = NO;
  NSString *name = nil;
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];

  // check the count...
  if([list count] > 0 && i >= 0 && i < [list count])
    {
      [outletTable deselectAll: self];
      name = [list objectAtIndex: i];
      removed = [document 
		  removeConnectionsWithLabel: name 
		  forClassNamed: currentClass
		  isAction: NO];
    }

  if(removed)
    {
      [document collapseClass: className];
      [document reloadClasses];
      [classManager removeOutlet: name fromClassNamed: className];
      [nc postNotificationName: IBInspectorDidModifyObjectNotification
	  object: classManager];
      [outletTable reloadData];
      [document selectClass: className];
    }
}

- (void) select: (id)sender
{
  NSLog(@"select...");
}

- (void) searchForClass: (id)sender
{
  NSArray *list = [classManager allClassNames];
  NSString *stringValue = [searchText stringValue];
  int index = [list indexOfObject: stringValue];

  NSLog(@"Search... %@",[searchText stringValue]);
  if(index != NSNotFound && list != nil && 
     [stringValue isEqualToString: @"FirstResponder"] == NO)
    {
      // select the parent class
      [parentClass selectRow: index byExtendingSelection: NO];
      [parentClass scrollRowToVisible: index];
    }
}

- (void) selectClass: (id)sender
{
  NSArray *list = [classManager allClassNames];
  int row = [parentClass selectedRow];

  if(row >= 0)
    {
      NSString *newParent = [list objectAtIndex: row];
      NSString *name = [self _currentClass];
      BOOL removed = NO;
      GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];
      
      // if it's a custom class, let it go, if not do nothing.
      if([classManager isCustomClass: name])
	{     
	  // check to see if the user wants to do this and remove the connections.
	  removed = [document removeConnectionsForClassNamed: name]; 
	  
	  // if removed, move the class and notify... 
	  if(removed)
	    {
	      NSString *oldSuper = [classManager superClassNameForClassNamed: name];
	      
	      [classManager setSuperClassNamed: newParent forClassNamed: name];
	      [nc postNotificationName: IBInspectorDidModifyObjectNotification
		  object: classManager];
	      [document collapseClass: oldSuper];
	      [document collapseClass: name];
	      [document reloadClasses];
	      [document selectClass: name];
	    }
	}
    }
}

- (void) changeClassName: (id)sender
{
  NSString *name = [self _currentClass];
  NSString *newName = [sender stringValue];
  GormDocument *document = (GormDocument *)[(id <IB>)NSApp activeDocument];
  BOOL removed = NO;

  // check to see if the user wants to do this and remove the connections.
  removed = [document removeConnectionsForClassNamed: name]; 

  if(removed)
    {
      [document collapseClass: name];
      [classManager renameClassNamed: name
		    newName: newName];
      [nc postNotificationName: IBInspectorDidModifyObjectNotification
	  object: classManager];
      [document reloadClasses];
      [document selectClass: newName];
    }
}

- (void) clickOnClass: (id)sender
{
  NSLog(@"Click on class %@",sender);
}

- (void) setObject: (id)anObject
{
  int outletsCount = 0;
  int actionsCount = 0;
  NSTabViewItem *item = nil;

  [super setObject: anObject];
  ASSIGN(classManager, [(Gorm *)NSApp classManager]);
  ASSIGN(currentClass, [object className]);

  outletsCount = [[classManager allOutletsForClassNamed: currentClass] count];
  actionsCount = [[classManager allActionsForClassNamed: currentClass] count];

  item = [tabView tabViewItemAtIndex: 1]; // actions;
  [item setLabel: [NSString stringWithFormat: @"Actions (%d)",actionsCount]];
  item = [tabView tabViewItemAtIndex: 0]; // outlets;
  [item setLabel: [NSString stringWithFormat: @"Outlets (%d)",outletsCount]];
  [tabView setNeedsDisplay: YES];

  [self _refreshView];
}

- (NSString *) _currentClass
{
  return [object className];
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

  if(tableView != parentClass)
    {
      NSArray *list = nil;
      NSString *name = nil;
      NSString *className = [self _currentClass];
      
      if(tableView == actionTable)
	{
	  list = [classManager allActionsForClassNamed: className];
	  name = [list objectAtIndex: rowIndex];
	}
      else if(tableView == outletTable)
	{
	  list = [classManager allOutletsForClassNamed: className];
	  name = [list objectAtIndex: rowIndex];
	}
      
      if([classManager isCustomClass: className])
	{
	  if(tableView == actionTable)
	    {
	      result = [classManager isAction: name
				     ofClass: className];
	    }
	  else if(tableView == outletTable)
	    {
	      result = [classManager isOutlet: name
				     ofClass: className];
	    }	       
	}
      else 
	{
	  result = [classManager isAction: name onCategoryForClassNamed: className];
	}
    }

  return result;
}

/*
- (void) tableView: (NSTableView *)tableView
   willDisplayCell: (id)aCell
    forTableColumn: (NSTableColumn *)aTableColumn
	       row: (int)rowIndex
{
  NSString *name = [aCell stringValue];
  NSString *className = [self _currentClass];

  if(tableView == actionTable)
    {
      if(([classManager isCustomClass: className] &&
	  [classManager isAction: name ofClass: className]) ||
	 [classManager isAction: name onCategoryForClassNamed: className])
	{
	  [aCell setTextColor: [NSColor blackColor]];
	}
      else
	{
	  [aCell setTextColor: [NSColor darkGrayColor]];
	}
    }
  else if(tableView == outletTable)
    {
      if([classManager isCustomClass: className] &&
	 [classManager isOutlet: name ofClass: className])
	{
	  [aCell setTextColor: [NSColor blackColor]];
	}
      else
	{
	  [aCell setTextColor: [NSColor darkGrayColor]];
	}
    }
}
*/

- (BOOL) tableView: (NSTableView *)tv
   shouldSelectRow: (int)rowIndex
{
  BOOL result = YES;
  if(tv == parentClass)
    {
      NSArray *list = [classManager allClassNames];
      NSString *className = [list objectAtIndex: rowIndex];
      NSString *name = [self _currentClass];
      BOOL isFirstResponder = [className isEqualToString: @"FirstResponder"];
      BOOL isCurrentClass = [className isEqualToString: name];
      BOOL isSubClass = [classManager isSuperclass: name linkedToClass: className];
      if(isFirstResponder || isCurrentClass || isSubClass)
	{
	  NSBeep();
	  result = NO;
	}
    }
  return result;
}

@end
