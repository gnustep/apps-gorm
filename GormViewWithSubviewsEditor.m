/* GormViewWithSubviewsEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Date:	2002
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

#include <AppKit/AppKit.h>

#include "GormPrivate.h"

#include "GormViewWithSubviewsEditor.h"

@class GormEditorToParent;

@implementation GormViewWithSubviewsEditor

- (void) close
{
  if (closed == NO)
    {
//        NSLog(@"%@ close", self);
      [self deactivate];
      
      [self closeSubeditors];
      [document editor: self didCloseForObject: _editedObject];
      closed = YES;
    }
  else
    {
      NSLog(@"%@ close but already closed", self);
    }
}

- (void) deactivateSubeditors
{
  NSArray *subeditorConnections = 
    [NSArray arrayWithArray: [document connectorsForDestination: self
				       ofClass: [GormEditorToParent class]]];
  
  int count = [subeditorConnections count];
  int i;
  
//    NSLog(@"start deactivating subeditors");
  for ( i = 0; i < count; i ++ )
    {
//        NSLog(@"%@", [[subeditorConnections objectAtIndex: i] source]); 
      [[[subeditorConnections objectAtIndex: i] source] deactivate];
    }
//    NSLog(@"end deactivating subeditors");
}

- (void) closeSubeditors
{
  NSArray *subeditorConnections = 
    [NSArray arrayWithArray: [document connectorsForDestination: self
				       ofClass: [GormEditorToParent class]]];

  int count = [subeditorConnections count];
  int i;

//    NSLog(@"start subeditor's list");
  for ( i = 0; i < count; i ++ )
    {
//        NSLog(@"%@", [[subeditorConnections objectAtIndex: i] source]); 
      [[[subeditorConnections objectAtIndex: i] source] close];
    }
//    NSLog(@"end subeditor's list");
}


- (BOOL) canBeOpened
{
  return YES;
}

- (BOOL) isOpened
{
  return opened;
}


- (void) setOpened: (BOOL) value
{
  opened = value;

  if (value == YES)
    {
//        NSLog(@"sO %@ we are opened", self);
      [self silentlyResetSelection];
      [document setSelectionFromEditor: self];      
    }
  else
    {
      if (openedSubeditor != nil)
	{
//  	  NSLog(@"let's closed our subeditor");
	  [self makeSubeditorResign];
	  [self silentlyResetSelection];
	}
      else
	{
	  [self silentlyResetSelection];
	}
      [self setNeedsDisplay: YES];
    }
}

/*
 *  
 */
- (void) openParentEditor
{
  if ([parent respondsToSelector: @selector(setOpenedSubeditor:)])
    {
      [parent setOpenedSubeditor: self];
    }
}

- (void) setOpenedSubeditor: (GormViewWithSubviewsEditor *) newEditor
{
  [self silentlyResetSelection];

  if (opened == NO)
    {
      [self openParentEditor];
    }

  opened = YES;

  if (newEditor != openedSubeditor)
    {
      [self makeSubeditorResign];
    }
  
  openedSubeditor = newEditor;

  [self setNeedsDisplay: YES];
}

/*
 *  take the selection from the subeditors
 */
- (void) makeSubeditorResign
{
  if (openedSubeditor != nil)
    {
//        NSLog(@"%@ makeSubeditorResign", self);
      [openedSubeditor makeSubeditorResign];
      [openedSubeditor setOpened: NO];
      openedSubeditor = nil;
    }
}


- (void) makeSelectionVisible: (BOOL) value
{
}

- (void) changeFont: (id)sender
{
  NSEnumerator *enumerator = [[self selection] objectEnumerator];
  id anObject;
  NSFont *newFont;

  while ((anObject = [enumerator nextObject]))
    {
      if ([anObject respondsToSelector: @selector(font)]
	  && [anObject respondsToSelector: @selector(setFont:)])
	{
	  newFont = [sender convertFont: [anObject font]];
	  [anObject setFont: newFont];
	}
    }

  return;
}

- (NSArray*) selection
{
  int i;
  int count = [selection count];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity: count];
  
  if (count != 0)
    {
      for (i = 0; i < count; i++)
	{
	  if ([[selection objectAtIndex: i] 
		respondsToSelector: @selector(editedObject)])
	    [result addObject: [[selection objectAtIndex: i] editedObject]];
	  else
	    [result addObject: [selection objectAtIndex: i]];
	}
    }
  else
    {
      if ([self respondsToSelector: @selector(editedObject)])
	[result addObject: [self editedObject]];
      else
	[result addObject: self];
    }

  return result;
}

- (void) selectObjects: (NSArray *) objects
{
  int i;
  int count = [objects count];
  TEST_RELEASE(selection);
  
  selection = [[NSMutableArray alloc] initWithCapacity: [objects count]];

  for (i = 0; i < count; i++)
    {
//        NSLog(@"adding %@", [objects objectAtIndex: i]);
      [selection addObject: [objects objectAtIndex: i]];
    }

  [self makeSubeditorResign];

  opened = YES;

  [self openParentEditor];

  [document setSelectionFromEditor: self];

  [self setNeedsDisplay: YES];
}

- (void) silentlyResetSelection
{
  TEST_RELEASE(selection);
  
  selection = [[NSMutableArray alloc] initWithCapacity: 5];
  
}

- (void) copySelection
{
  if ([selection count] > 0)
    {
      [document copyObjects: [self selection]
		       type: IBViewPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (void) deleteSelection
{
  NSLog(@"deleteSelection should be subclassed");
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

@end
