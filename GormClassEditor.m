/* GormClassEditor.m
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormFunctions.h"
#include <AppKit/NSPasteboard.h>

NSString *GormClassPboardType = @"GormClassPboardType";

@implementation	GormClassEditor

- (GormClassEditor*) initWithDocument: (GormDocument*)doc
{
  self = [super init];
  if (self != nil)
    {
      NSColor *salmonColor = 
	[NSColor colorWithCalibratedRed: 0.850980 
		 green: 0.737255
		 blue: 0.576471
		 alpha: 1.0 ];
      NSTableColumn  *tableColumn;

      document = doc; // loose connection
      classManager = [doc classManager];
      [self setDataSource: self];
      [self setDelegate: self];  
      [self setAutoresizesAllColumnsToFit: YES];
      [self setAllowsColumnResizing: NO];
      [self setDrawsGrid: NO];
      [self setIndentationMarkerFollowsCell: YES];
      [self setAutoresizesOutlineColumn: YES];
      [self setIndentationPerLevel: 10];
      [self setAttributeOffset: 30];
      [self setRowHeight: 18];
      [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
      [self setMenu: [(Gorm*)NSApp classMenu]]; 
      [self setBackgroundColor: salmonColor ];

      // add the table columns...
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"classes"];
      [[tableColumn headerCell] setStringValue: _(@"Classes")];
      [tableColumn setMinWidth: 190];
      [tableColumn setResizable: YES];
      [tableColumn setEditable: YES];
      [self addTableColumn: tableColumn];     
      [self setOutlineTableColumn: tableColumn];
      RELEASE(tableColumn);
      
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"outlets"];
      [[tableColumn headerCell] setStringValue: _(@"Outlet")];
      [tableColumn setWidth: 50]; 
      [tableColumn setResizable: NO];
      [tableColumn setEditable: NO];
      [self addTableColumn: tableColumn];
      [self setOutletColumn: tableColumn];
      RELEASE(tableColumn);
      
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"actions"];
      [[tableColumn headerCell] setStringValue: _(@"Action")];
      [tableColumn setWidth: 50]; 
      [tableColumn setResizable: NO];
      [tableColumn setEditable: NO];
      [self addTableColumn: tableColumn];
      [self setActionColumn: tableColumn];
      RELEASE(tableColumn); 

      // expand all of the items in the classesView...
      [self expandItem: @"NSObject"];
    }
  return self;
}

+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc
{
  return AUTORELEASE([(GormClassEditor *)[self alloc] initWithDocument: doc]);
}

- (void) dealloc
{
  RELEASE(selectedClass);
  [super dealloc];
}

- (void) setSelectedClassName: (NSString*)cn
{
  [self selectClass: cn];
}

- (NSString *)selectedClassName
{
  int row = [self selectedRow];
  id  className = [self itemAtRow: row];

  if ([className isKindOfClass: [GormOutletActionHolder class]])
    {
      className = [self itemBeingEdited];
    }

  return className;
}

- (void) selectClass: (NSString *)className
{
  [self selectClass: className editClass: YES];
}

// class selection...
- (void) selectClass: (NSString *)className editClass: (BOOL)flag
{
  NSString	*currentClass = nil;
  NSArray	*classes;
  NSEnumerator	*en;
  int		row = 0;

  // abort, if we're editing a class.
  if([self isEditing])
    {
      return;
    }
  
  if(className != nil)
    {
      if([className isEqual: @"CustomView"] || 
	 [className isEqual: @"GormSound"] || 
	 [className isEqual: @"GormImage"])
	{
	  return; // return only if it is a special class name...
	}
    }
  else
    {
      return; // return if it is nil
    }
  
  classes = [classManager allSuperClassesOf: className]; 
  en = [classes objectEnumerator];

  // open the items...
  while ((currentClass = [en nextObject]) != nil)
    {
      [self expandItem: currentClass];
    }
  
  // select the item...
  row = [self rowForItem: className];
  if (row != NSNotFound)
    {
      [self selectRow: row byExtendingSelection: NO];
      [self scrollRowToVisible: row];
    }

  if(flag)
    {
      // set the editor...
      ASSIGN(selectedClass, className);
      [document setSelectionFromEditor: (id)self];
    }
}

- (void) selectClassWithObject: (id)obj 
{
  [self selectClassWithObject: obj editClass: YES];
}

- (void) selectClassWithObject: (id)object editClass: (BOOL)flag
{
  id obj = object;
  NSString *customClass = nil;

  // if it's a scrollview focus on it's contents.
  if([obj isKindOfClass: [NSScrollView class]])
    {
      id newobj = nil;
      newobj = [obj documentView];
      if(newobj != nil)
	{
	  obj = newobj;
	}
    }
  
  // check for a custom class.
  customClass = [classManager customClassForObject: obj];
  if(customClass != nil)
    {
      [self selectClass: customClass editClass: flag];
    }
  else if ([obj respondsToSelector: @selector(className)])
    { 
      [self selectClass: [obj className] editClass: flag];
    }
}

- (BOOL) currentSelectionIsClass
{  
  int i = [self selectedRow];
  BOOL result = NO;
  
  if (i >= 0 && i <= ([self numberOfRows] - 1))
    {
      id object = [self itemAtRow: i];
      if([object isKindOfClass: [NSString class]])
	{
	  result = YES;
	}
    }
  return result;
}

- (void) editClass
{
  int	row = [self selectedRow];

  if (row >= 0)
    {
      ASSIGN(selectedClass, [self selectedClassName]);
      [document setSelectionFromEditor: (id)self];
    }
}

- (void) createSubclass
{
  if (![self isEditing])
    {
      NSString *newClassName;
      NSString *itemSelected = [self selectedClassName];
      
      if(itemSelected != nil)
	{
	  if(![itemSelected isEqualToString: @"FirstResponder"])
	    {
	      int i = 0;
	      
	      newClassName = [classManager addClassWithSuperClassName:
					     itemSelected];
	      [self reloadData];
	      [self expandItem: itemSelected];
	      i = [self rowForItem: newClassName]; 
	      [self selectRow: i byExtendingSelection: NO];
	      [self scrollRowToVisible: i];
	    }
	  else
	    {
	      // inform the user of this error.
	      NSRunAlertPanel(_(@"Cannot instantiate"), 
			      _(@"FirstResponder cannot be instantiated."),
			      nil, nil, nil);
	    }
	}
    }
}

//--- IBSelectionOwners protocol ---
- (unsigned) selectionCount
{
  return ([self selectedRow] == -1)?0:1;
}

- (NSArray*) selection
{
  // when asked for a selection, it returns a class proxy
  if (selectedClass != nil) 
    {
      NSArray		*array;
      GormClassProxy	*classProxy;

      classProxy = [[GormClassProxy alloc] initWithClassName:
	selectedClass];
      array = [NSArray arrayWithObject: classProxy];
      RELEASE(classProxy);
      return array;
    } 
  else
    {
      return [NSArray array];
    }
}

- (void) drawSelection
{
}

- (void) makeSelectionVisible: (BOOL)flag
{
}

- (void) selectObjects: (NSArray*)objects
{
  id obj = [objects objectAtIndex: 0];
  [self selectClassWithObject: obj];
}

- (void) deleteSelection
{
  id anitem;
  int i = [self selectedRow];
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  
  // if no selection, then return.
  if (i == -1)
    {
      return;
    }

  anitem = [self itemAtRow: i];
  if ([anitem isKindOfClass: [GormOutletActionHolder class]])
    {
      id itemBeingEdited = [self itemBeingEdited];
      NSString *name = [anitem getName];

      // if the class being edited is a custom class or a category, 
      // then allow the deletion...
      if ([classManager isCustomClass: itemBeingEdited] ||
	  [classManager isAction: name onCategoryForClassNamed: itemBeingEdited])
	{
	  if ([self editType] == Actions)
	    {
	      // if this action is an action on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isAction: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [document removeConnectionsWithLabel: name 
					   forClassNamed: itemBeingEdited
					   isAction: YES];
		  if (removed)
		    {
		      [classManager removeAction: name
				    fromClassNamed: itemBeingEdited];
		      [self removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	  else if ([self editType] == Outlets)
	    {
	      // if this outlet is an outlet on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isOutlet: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [document removeConnectionsWithLabel: name 
					   forClassNamed: itemBeingEdited
					   isAction: NO];
		  if (removed)
		    {
		      [classManager removeOutlet: name
				    fromClassNamed: itemBeingEdited];
		      [self removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	}
    }
  else
    {
      NSArray *subclasses = [classManager subClassesOf: anitem];
      // if the class has no subclasses, then delete.
      if ([subclasses count] == 0)
	{
	  // if the class being edited is a custom class, then allow the deletion...
	  if ([classManager isCustomClass: anitem])
	    {
	      BOOL removed = [document removeConnectionsForClassNamed: anitem];
	      if (removed)
		{
		  [self copySelection];
		  [document removeAllInstancesOfClass: anitem];
		  [classManager removeClassNamed: anitem];
		  [self reloadData];
		  [nc postNotificationName: GormDidModifyClassNotification
		      object: classManager];
		  ASSIGN(selectedClass, nil); // don't keep the class we're pointing to.
		}
	    }
	}
      else
	{
	  NSString *message = [NSString stringWithFormat: 
	    _(@"The class %@ has subclasses which must be removed"), anitem];
	  NSRunAlertPanel(_(@"Problem removing class"), 
			  message,
			  nil, nil, nil);
	}
    }    
}

- (void) copySelection
{
  if(selectedClass != nil)
    {
      if([selectedClass isEqual: @"FirstResponder"] == NO)
	{
	  NSPasteboard *pb = [NSPasteboard generalPasteboard];
	  NSMutableDictionary *dict = 
	    [NSMutableDictionary dictionaryWithObjectsAndKeys: [classManager dictionaryForClassNamed: selectedClass], 
				 selectedClass, nil];
	  id classPlist = [[dict description] propertyList];
	  
	  if(classPlist != nil)
	    {
	      [pb declareTypes: [NSArray arrayWithObject: GormClassPboardType] owner: self];
	      [pb setPropertyList: classPlist forType: GormClassPboardType];
	    }
	}
    }
}

- (void) pasteInSelection
{
  if(selectedClass != nil)
    {
      if([selectedClass isEqual: @"FirstResponder"] == NO)
	{
	  NSPasteboard *pb = [NSPasteboard generalPasteboard];
	  NSArray *types = [pb types];
	  
	  if([types containsObject: GormClassPboardType])
	    {
	      id classPlist = [pb propertyListForType: GormClassPboardType];
	      NSDictionary *classesDict = [NSDictionary dictionaryWithDictionary: classPlist];
	      id name = nil;
	      NSEnumerator *en = [classesDict keyEnumerator];
	      
	      while((name = [en nextObject]) != nil)
		{
		  NSDictionary *classDict = [classesDict objectForKey: name];
		  NSString *className = [classManager uniqueClassNameFrom: name];
		  BOOL added = [classManager addClassNamed: className
					     withSuperClassNamed: selectedClass
					     withActions: [classDict objectForKey: @"Actions"]
					     withOutlets: [classDict objectForKey: @"Outlets"]];
		  if(!added)
		    {
		      NSString *message = [NSString stringWithFormat: @"Addition of %@ with superclass %@ failed.", className,
						    selectedClass];
		      NSRunAlertPanel(_(@"Problem pasting class"),
				      message, nil, nil, nil);
		    }
		}
	    }
	}
      else
	{
	  NSRunAlertPanel(_(@"Problem pasting class"),
			  _(@"FirstResponder cannot have subclasses."), nil, nil, nil);
	}
    }
}

/*
- (void) handleNotification: (NSNotification *)notification
{
  NSArray *selection =  [[(id<IB>)NSApp selectionOwner] selection];
  [selectionBox setContentView: classesScrollView];
  
  // if something is selected, in the object view.
  // show the equivalent class in the classes view.
  if ([selection count] > 0)
    {
      id obj = [selection objectAtIndex: 0];
      [classesView selectClassWithObject: obj];
    }  
}
*/
@end

@implementation GormClassEditor (NSOutlineViewDataSource)

// --- NSOutlineView dataSource ---
- (id)        outlineView: (NSOutlineView *)anOutlineView 
objectValueForTableColumn: (NSTableColumn *)aTableColumn 
	           byItem: item
{
  id identifier = [aTableColumn identifier];
  id className = item;
  
  if([item isKindOfClass: [GormOutletActionHolder class]])
    return item;

  if ([identifier isEqualToString: @"classes"])
    {
      return className;
    } 
  else if ([identifier isEqualToString: @"outlets"])
    {
      return [NSString stringWithFormat: @"%d",
		       [[classManager allOutletsForClassNamed: className] count]];
    }
  else if ([identifier isEqualToString: @"actions"])
    {
      return [NSString stringWithFormat: @"%d",
		       [[classManager allActionsForClassNamed: className] count]];
    }

  return @"";
}

- (void) outlineView: (NSOutlineView *)anOutlineView 
      setObjectValue: (id)anObject 
      forTableColumn: (NSTableColumn *)aTableColumn
	      byItem: (id)item
{
  GormOutlineView *gov = (GormOutlineView *)anOutlineView;

  // ignore object values which come in as nil...
  if(anObject == nil)
    return;

  if ([item isKindOfClass: [GormOutletActionHolder class]])
    {
      if (![anObject isEqualToString: @""])
	{
	  NSString *name = [item getName];

	  // retain the name and add the action/outlet...
	  if ([gov editType] == Actions)
	    {
	      NSString *formattedAction = formatAction( (NSString *)anObject );
	      if (![classManager isAction: formattedAction 
				ofClass: [gov itemBeingEdited]])
		{
		  BOOL removed;

		  removed = [document removeConnectionsWithLabel: name
		    forClassNamed: [gov itemBeingEdited] isAction: YES];
		  if (removed)
		    {
		      [classManager replaceAction: name 
				    withAction: formattedAction 
				    forClassNamed: [gov itemBeingEdited]];
		      [(GormOutletActionHolder *)item setName: formattedAction];
		    }
		}
	      else
		{
		  NSString *message;

		  message = [NSString stringWithFormat: 
		    _(@"The class %@ already has an action named %@"),
		    [gov itemBeingEdited], formattedAction];

		  NSRunAlertPanel(_(@"Problem Adding Action"),
				  message, nil, nil, nil);
				  
		}
	    }
	  else if ([gov editType] == Outlets)
	    {
	      NSString *formattedOutlet = formatOutlet( (NSString *)anObject );
	      
	      if (![classManager isOutlet: formattedOutlet 
				  ofClass: [gov itemBeingEdited]])
		{
		  BOOL removed;

		  removed = [document removeConnectionsWithLabel: name
				      forClassNamed: [gov itemBeingEdited] 
				      isAction: NO];
		  if (removed)
		    {
		      [classManager replaceOutlet: name 
				    withOutlet: formattedOutlet 
				    forClassNamed: [gov itemBeingEdited]];
		      [(GormOutletActionHolder *)item setName: formattedOutlet];
		    }
		}
	      else
		{
		  NSString *message;

		  message = [NSString stringWithFormat: 
		    _(@"The class %@ already has an outlet named %@"),
		    [gov itemBeingEdited], formattedOutlet];
		  NSRunAlertPanel(_(@"Problem Adding Outlet"),
				  message, nil, nil, nil);
				  
		}
	    }
	}
    }
  else
    {
      if  ( ( ![anObject isEqualToString: @""] ) && ( ! [anObject isEqualToString:item]  ) )
	{
	  BOOL rename;

	  rename = [document renameConnectionsForClassNamed: item toName: anObject];
	  if (rename)
	    {
	      int row = 0;

	      [classManager renameClassNamed: item newName: anObject];
	      [gov reloadData];
	      row = [gov rowForItem: anObject];

	      // make sure that item is collapsed...
	      [gov expandItem: anObject];
	      [gov collapseItem: anObject];
	      
	      // scroll to the item..
	      [gov scrollRowToVisible: row];
	    }
	}
    }

  [gov setNeedsDisplay: YES];
}

- (int) outlineView: (NSOutlineView *)anOutlineView 
numberOfChildrenOfItem: (id)item
{
  if (item == nil) 
    {
      return 1;
    }
  else
    {
      NSArray *subclasses = [classManager subClassesOf: item];
      return [subclasses count];
    }

  return 0;
}

- (BOOL) outlineView: (NSOutlineView *)anOutlineView 
    isItemExpandable: (id)item
{
  NSArray *subclasses = nil;
  if (item == nil)
    return YES;

  subclasses = [classManager subClassesOf: item];
  if ([subclasses count] > 0)
    return YES;

  return NO;
}

- (id) outlineView: (NSOutlineView *)anOutlineView 
	     child: (int)index
	    ofItem: (id)item
{
  if (item == nil && index == 0)
    {
      return @"NSObject";
    }
  else
    {
      NSArray *subclasses = [classManager subClassesOf: item];
      return [subclasses objectAtIndex: index];
    }

  return nil;
}

// GormOutlineView data source methods...
- (NSArray *)outlineView: (NSOutlineView *)anOutlineView
	  actionsForItem: (id)item
{
  NSArray *actions = [classManager allActionsForClassNamed: item];
  return actions;
}

- (NSArray *)outlineView: (NSOutlineView *)anOutlineView
	  outletsForItem: (id)item
{
  NSArray *outlets = [classManager allOutletsForClassNamed: item];
  return outlets;
}

- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewActionForClass: (id)item
{
  // removed the restriction, since it's now possible to add
  // actions for kit classes.
  return [classManager addNewActionToClassNamed: item];
}

- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewOutletForClass: (id)item		 
{
  GormOutlineView *gov = (GormOutlineView *)anOutlineView;
  if (![classManager isCustomClass: [gov itemBeingEdited]])
    {
      return nil;
    }

  if([item isEqualToString: @"FirstResponder"])
	    return nil;

  return [classManager addNewOutletToClassNamed: item];
}

// Delegate methods
- (BOOL)  outlineView: (NSOutlineView *)outlineView
shouldEditTableColumn: (NSTableColumn *)tableColumn
		 item: (id)item
{
  BOOL result = NO;
  GormOutlineView *gov = (GormOutlineView *)outlineView;

  NSDebugLog(@"in the delegate %@", [tableColumn identifier]);
  if (tableColumn == [gov outlineTableColumn])
    {
      NSDebugLog(@"outline table col");
      if (![item isKindOfClass: [GormOutletActionHolder class]] &&
	  ![item isEqualToString: @"FirstResponder"])
	{
	  result = [classManager isCustomClass: item];
	  [self editClass];
	}
      else
	{
	  id itemBeingEdited = [gov itemBeingEdited];
	  if ([classManager isCustomClass: itemBeingEdited])
	    {
	      if ([gov editType] == Actions)
		{
		  result = [classManager isAction: [item getName]
					 ofClass: itemBeingEdited];
		}
	      else if ([gov editType] == Outlets)
		{
		  result = [classManager isOutlet: [item getName]
					 ofClass: itemBeingEdited];
		}	       
	    }
	  else if ([classManager isCategoryForClass: itemBeingEdited])
	    {
	      if ([gov editType] == Actions)
		{
		  result = [classManager isAction: [item getName]
					 ofClass: itemBeingEdited];
		}
	    }	    
	}
    }

  return result;
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notification
{
  id object = [notification object];
  int row = [object selectedRow];

  if(row != -1)
    {
      id item = [object itemAtRow: [object selectedRow]];
      if (![item isKindOfClass: [GormOutletActionHolder class]])
	{
	  [self editClass];
	}
    }
}

@end // end of data source
