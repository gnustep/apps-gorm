/** <title>GormOutlineView</title>

   <abstract>The NSOutlineView subclass in gorm which handles outlet/action editing</abstract>
   
   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: July 2002
   
   This file is part of the GNUstep GUI Library.

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

#include "GormOutlineView.h"
#include <Foundation/NSNotification.h>
#include <Foundation/NSNull.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSTextFieldCell.h>

static NSNotificationCenter *nc = nil;
static const int current_version = 1;

// Cache the arrow images...
static NSImage *collapsed = nil;
static NSImage *expanded  = nil;
static NSImage *unexpandable  = nil;
static NSImage *action = nil;
static NSImage *outlet = nil;

// some common colors which will be used to indicate state in the outline
// view.
static NSColor *salmonColor = nil;
static NSColor *darkSalmonColor = nil;
static NSColor *lightGreyBlueColor = nil;
static NSColor *darkGreyBlueColor = nil;

// a class to hold the outlet/actions so that the
// draw row method will know how to render them on
// the display...
@interface GormOutletActionHolder : NSObject
{
  NSString *_name;
}
- initWithName: (NSString *)name;
- (NSString *)getName;
@end

@implementation GormOutletActionHolder
- init
{
  [super init];
  _name = nil;
  return self;
}

- initWithName: (NSString *)name
{
  [self init];
  ASSIGN(_name,name);
  return self;
}

- (NSString *)getName
{
  return _name;
}
@end

@implementation GormOutlineView
// Initialize the class when it is loaded
+ (void) initialize
{
  if (self == [GormOutlineView class])
    {
      // initialize images
      [self setVersion: current_version];
      nc = [NSNotificationCenter defaultCenter];
      collapsed    = [NSImage imageNamed: @"common_outlineCollapsed.tiff"];
      expanded     = [NSImage imageNamed: @"common_outlineExpanded.tiff"];
      unexpandable = [NSImage imageNamed: @"common_outlineUnexpandable.tiff"];
      action       = [NSImage imageNamed: @"GormAction.tiff"];
      outlet       = [NSImage imageNamed: @"GormOutlet.tiff"];

      // initialize colors
      salmonColor = 
	RETAIN([NSColor colorWithCalibratedRed: 0.850980 
			green: 0.737255
			blue: 0.576471
			alpha: 1.0 ]);
      darkSalmonColor = 
	RETAIN([NSColor colorWithCalibratedRed: 0.568627 
			green: 0.494118
			blue: 0.384314
			alpha: 1.0 ]);
      lightGreyBlueColor = 
	RETAIN([NSColor colorWithCalibratedRed: 0.450980 
			green: 0.450980
			blue: 0.521569
			alpha: 1.0 ]);
      darkGreyBlueColor = 
	RETAIN([NSColor colorWithCalibratedRed: 0.333333 
			green: 0.333333
			blue: 0.384314
			alpha: 1.0 ]);
    }
}

- init
{
  [super init];
  _actionColumn = nil;
  _outletColumn = nil;
  _isEditing = NO;
  _attributeOffset = 0.0;
  return self;
}

- (void) dealloc
{
}

- (void)collapseItem: (id)item collapseChildren: (BOOL)collapseChildren;
{
  if(!_isEditing)
    {
      [super collapseItem: item
	     collapseChildren: collapseChildren];
    } else
      NSLog(@"Cannot collapse while editing");
}

- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
  if(!_isEditing)
    {
      [super expandItem: item
	     expandChildren: expandChildren];
    } else
      NSLog(@"Cannot expand while editing");
}

- (BOOL)_isOutletOrActionOfItemBeingEdited: (NSString *)name
{
  NSArray *array = nil;
  array = [_dataSource outlineView: self
		       actionsForItem: _itemBeingEdited];
  if([array containsObject: name])
    return YES;
  array = [_dataSource outlineView: self
		       outletsForItem: _itemBeingEdited];
  if([array containsObject: name])
    return YES;
  return NO;
}

- (void)_openActions: (id)item
{
  int numchildren = 0;
  int i = 0;
  int insertionPoint = 0;
  id object = nil;
  id sitem = (item == nil)?[NSNull null]:item;

  object = [_dataSource outlineView: self
			actionsForItem: sitem];
  numchildren = [object count];
  
  _numberOfRows += numchildren;
  // open the item...
  if(item != nil)
    {
      [self setItemBeingEdited: item];
      [self setIsEditing: YES];
    }

  insertionPoint = [_items indexOfObject: item];
  if(insertionPoint == NSNotFound)
    {
      insertionPoint = 0;
    }
  else
    {
      insertionPoint++;
    }
  
  [self setNeedsDisplay: YES];  
  for(i=numchildren-1; i >= 0; i--)
    {
      id child = [object objectAtIndex: i];       // Add all of the children...
      GormOutletActionHolder *holder = [[GormOutletActionHolder alloc] initWithName: child];
      [_items insertObject: holder atIndex: insertionPoint];
    }
  [self noteNumberOfRowsChanged];
}

- (void)_openOutlets: (id)item
{
  int numchildren = 0;
  int i = 0;
  int insertionPoint = 0;
  id object = nil;
  id sitem = (item == nil)?[NSNull null]:item;

  object = [_dataSource outlineView: self
			outletsForItem: sitem];
  numchildren = [object count];
  
  _numberOfRows += numchildren;
  // open the item...
  if(item != nil)
    {
      [self setItemBeingEdited: item];
      [self setIsEditing: YES];
    }

  insertionPoint = [_items indexOfObject: item];
  if(insertionPoint == NSNotFound)
    {
      insertionPoint = 0;
    }
  else
    {
      insertionPoint++;
    }
  
  [self setNeedsDisplay: YES];  
  for(i=numchildren-1; i >= 0; i--)
    {
      id child = [object objectAtIndex: i];       // Add all of the children...
      GormOutletActionHolder *holder = [[GormOutletActionHolder alloc] initWithName: child];
      [_items insertObject: holder atIndex: insertionPoint];
    }
  [self noteNumberOfRowsChanged];
}

- (void)drawRow: (int)rowIndex clipRect: (NSRect)aRect
{
  int startingColumn; 
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  NSCell *imageCell = nil;
  NSRect imageRect;
  int i;
  float x_pos;
  static BOOL drawingEditedObject = NO;

  if (_dataSource == nil)
    {
      return;
    }

  /* Using columnAtPoint: here would make it called twice per row per drawn 
     rect - so we avoid it and do it natively */
  
  if(rowIndex >= _numberOfRows)
    {
      return;
    }

  /* Determine starting column as fast as possible */
  x_pos = NSMinX (aRect);
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  /* Determine ending column as fast as possible */
  x_pos = NSMaxX (aRect);
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      if (i != _editedColumn || rowIndex != _editedRow)
	{
	  id item = [self itemAtRow: rowIndex];
	  id value = nil, valueforcell = nil;
	  BOOL isOutletAction = NO;

	  tb = [_tableColumns objectAtIndex: i];
	  cell = [tb dataCellForRow: rowIndex];
	  value = [_dataSource outlineView: self
			       objectValueForTableColumn: tb
			       byItem: item];

	  if([value isKindOfClass: [GormOutletActionHolder class]])
	    {
	      valueforcell = [value getName];
	      isOutletAction = YES;
	      drawingEditedObject = YES;
 	    }
	  else
	    {
	      valueforcell = value;
	      isOutletAction = NO;
	    }

	  if ([_delegate respondsToSelector: @selector(outlineView:willDisplayCell:forTableColumn:item:)])
	    {
	      [_delegate outlineView: self   
			 willDisplayCell: cell 
			 forTableColumn: tb   
			 item: item];
	    }
	  
	  [cell setObjectValue: valueforcell]; 
	  drawingRect = [self frameOfCellAtColumn: i
			      row: rowIndex];	      
	  

	  if(isOutletAction)
	    {
	      drawingRect.origin.x += _attributeOffset;
	      drawingRect.size.width -= _attributeOffset;
	    }	  


	  /* For later...
	  if(drawingEditedObject)
	    {
	      [self setBackgroundColor: salmonColor];
	    }
	  else
	    if(_isEditing)
	      {
		[self setBackgroundColor: darkSalmonColor]; 
	      }
	  */

	  if(tb == _outlineTableColumn && !isOutletAction)
	    {
	      NSImage *image = nil;
	      int level = 0;
	      float indentationFactor = 0.0;
	      // float originalWidth = drawingRect.size.width;

	      drawingEditedObject = NO;
	      // display the correct arrow...
	      if([self isItemExpanded: item])
		{
		  image = expanded;
		}
	      else
		{
		  image = collapsed;
		}
	      
	      if(![self isExpandable: item])
		{
		  image = unexpandable;
		}
	      
	      level = [self levelForItem: item];
	      indentationFactor = _indentationPerLevel * level;
	      imageCell = [[NSCell alloc] initImageCell: image];
	      
	      if(_indentationMarkerFollowsCell)
		{
		  imageRect.origin.x = drawingRect.origin.x + indentationFactor;
		  imageRect.origin.y = drawingRect.origin.y;
		}
	      else
		{
		  imageRect.origin.x = drawingRect.origin.x;
		  imageRect.origin.y = drawingRect.origin.y;
		}
	      
	      imageRect.size.width = [image size].width;
	      imageRect.size.height = [image size].height;
	      
	      [imageCell drawWithFrame: imageRect inView: self];
	      
	      drawingRect.origin.x += indentationFactor + [image size].width + 5;
	      drawingRect.size.width -= indentationFactor + [image size].width + 5;
	      
	    }
	  
	  
	  if((tb == _actionColumn || tb == _outletColumn) && !drawingEditedObject)
	    {
	      NSImage *image = (tb == _actionColumn)?action:outlet;
	      
	      // Prepare image cell...
	      imageCell = [[NSCell alloc] initImageCell: image];
	      imageRect.origin.x = drawingRect.origin.x;
	      imageRect.origin.y = drawingRect.origin.y;
	      imageRect.size.width = [image size].width;
	      imageRect.size.height = [image size].height;
	      [imageCell drawWithFrame: imageRect inView: self];
	      
	      // Adjust drawing rect of cell being displayed...
	      drawingRect.origin.x += [image size].width + 5;
	      drawingRect.size.width -= [image size].width + 5;
	    }
	  
	  if(((tb != _outletColumn || tb != _actionColumn) && !drawingEditedObject) ||
	     (tb == _outlineTableColumn))
	    {
	      [cell drawWithFrame: drawingRect inView: self];
	    }
	}
    }
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTableColumn *tb;
  NSImage *image = nil;
  id _clickedItem = nil;
  BOOL isActionOrOutlet = NO;

  location = [self convertPoint: location  fromView: nil];
  _clickedRow = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];
  _clickedItem = [self itemAtRow: _clickedRow];
  isActionOrOutlet = [_clickedItem isKindOfClass: [GormOutletActionHolder class]];

  NSLog(@"clickedItem = %@",_clickedItem);
  tb = [_tableColumns objectAtIndex: _clickedColumn];
  if(tb == _actionColumn)
    {
      NSLog(@"setting action image");
      image = action;
    }
  else if (tb == _outletColumn)
    {
      NSLog(@"setting outlet image");
      image = outlet;
    }

  if((tb == _actionColumn || tb == _outletColumn) && !_isEditing)
    {
      int position = 0;      
      position += _columnOrigins[_clickedColumn] + 5;

      if(location.x >= position && location.x <= position + [image size].width + 5)
	{
	  [self setItemBeingEdited: _clickedItem];
	  [self setIsEditing: YES];
	  // [self setBackgroundColor: darkSalmonColor]; // for later
	  if(tb == _actionColumn)
	    {
	      [self _openActions: _clickedItem];
	    }
	  else if(tb == _outletColumn)
	    {
	      [self _openOutlets: _clickedItem];
	    }
	}
    }
  else if(_isEditing && !isActionOrOutlet)
    {
      //id clickedItem = [self itemAtRow: _clickedRow];
      if(_clickedItem != [self itemBeingEdited] &&
	 !isActionOrOutlet)
	{
	  NSLog(@"RESETTING......");
	  [self setItemBeingEdited: nil];
	  [self setIsEditing: NO];
	  [self setBackgroundColor: salmonColor];
	  [self reloadData];
	}
    }
  else if(isActionOrOutlet)
    {
      NSString *name = [_clickedItem getName];
      NSLog(@"clicked on action/outlet: %@",name);
    }

  [super mouseDown: theEvent];
}  

// additional methods for subclass
- (void) setAttributeOffset: (float)offset
{
  _attributeOffset = offset;
}

- (float) attributeOffset
{
  return _attributeOffset;
}

- (void) setItemBeingEdited: (id)item
{
  _itemBeingEdited = item;
}

- (id) itemBeingEdited
{
  return _itemBeingEdited;
}

- (void) setIsEditing: (BOOL)flag
{
  _isEditing = flag;
}

- (BOOL) isEditing
{
  return _isEditing;
}

- (void)setActionColumn: (NSTableColumn *)ac
{
  ASSIGN(_actionColumn,ac);
}

- (NSTableColumn *)actionColumn
{
  return _actionColumn;
}

- (void)setOutletColumn: (NSTableColumn *)oc
{
  ASSIGN(_outletColumn,oc);
}

- (NSTableColumn *)outletColumn
{
  return _outletColumn;
}
@end /* implementation of GormOutlineView */

