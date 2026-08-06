/* GormScrollViewEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Author:      Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2002
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include "GormPrivate.h"
#include "GormBoxEditor.h"
#include "GormViewKnobs.h"

@implementation NSScrollView (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormScrollViewAttributesInspector";
}

- (NSString*) editorClassName
{
  return @"GormScrollViewEditor";
}
@end

@interface GormDocument (GormScrollViewEditorPrivate)
- (id<IBEditors>) editorForObject: (id)anObject
                         inEditor: (id<IBEditors>)anEditor
                           create: (BOOL)flag;
@end

#define _EO ((NSScrollView *)_editedObject)

@interface GormScrollViewEditor : GormViewWithSubviewsEditor
{
  GormInternalViewEditor *documentViewEditor;
}
- (id<IBEditors>) _editorForTableView: (NSTableView *)tableView;
- (NSTableView *) _tableViewDocumentView;
- (void) _openTableViewEditor: (id<IBEditors>)editor
                    withEvent: (NSEvent *)event;
@end

@implementation GormScrollViewEditor

- (id<IBEditors>) _editorForTableView: (NSTableView *)tableView
{
  return [(GormDocument *)document editorForObject: tableView
                                         inEditor: self
                                           create: YES];
}

- (NSTableView *) _tableViewDocumentView
{
  id documentView = [_EO documentView];

  if ([documentView isKindOfClass: [NSTableView class]])
    {
      return (NSTableView *)documentView;
    }
  if ([documentView respondsToSelector: @selector(editedObject)]
      && [[documentView editedObject] isKindOfClass: [NSTableView class]])
    {
      return (NSTableView *)[documentView editedObject];
    }

  return nil;
}

- (void) _openTableViewEditor: (id<IBEditors>)editor
                    withEvent: (NSEvent *)event
{
  if ([(id)editor respondsToSelector: @selector(setOpened:)])
    {
      [(id)editor setOpened: YES];
    }
  if ([(id)editor respondsToSelector: @selector(mouseDown:)])
    {
      [(id)editor mouseDown: event];
    }
}

- (void) setOpened: (BOOL) flag
{
  [super setOpened: flag];
  if (flag == YES)
    {  
      [document setSelectionFromEditor: documentViewEditor];
    }
}

- (BOOL) activate
{
  if ([super activate])
    {
      NSView *documentView = [_EO documentView];
      
      NSDebugLog(@"documentView %@", documentView);
      documentViewEditor = (GormInternalViewEditor *)[document 
						       editorForObject: documentView
						       inEditor: self 
						       create: YES];
      return YES;
    }

  return NO;
}

- (void) deactivate
{
  if (activated == YES)
    {
      [self deactivateSubeditors];
      
      [super deactivate];
    }
}

- (void) close
{
  [self setOpened: NO];
  [super close];
}

- (void) mouseDown: (NSEvent *) theEvent
{
  BOOL onKnob = NO;

  if ([parent respondsToSelector: @selector(selection)] &&
      [[parent selection] containsObject: _EO])
    {
      IBKnobPosition knob = IBNoneKnobPosition;
      NSPoint mouseDownPoint = 
	[self convertPoint: [theEvent locationInWindow]
	      fromView: nil];
      knob = GormKnobHitInRect([self bounds], 
			       mouseDownPoint);
      if (knob != IBNoneKnobPosition)
	{
	  onKnob = YES;
	}
    }

  if (onKnob == YES)
    {
      if (parent)
	{
	  return [parent mouseDown: theEvent];
	}
      else
	{
	  return [self noResponderFor: @selector(mouseDown:)];
	}
    }

  // Open the scrollview, if it's not opened...
  if (opened == NO)
    {
      [super mouseDown: theEvent];
      // return;
    }

  NSTableView *tableView = [self _tableViewDocumentView];
  NSTableHeaderView *headerView = [tableView headerView];

  if (headerView != nil)
    {
      NSPoint pointInHeader = [headerView convertPoint: [theEvent locationInWindow]
                                              fromView: nil];

      if (NSMouseInRect(pointInHeader,
                        [headerView bounds],
                        [headerView isFlipped]))
        {
          [self _openTableViewEditor: [self _editorForTableView: tableView]
                           withEvent: theEvent];
          return;
        }
    }

  NSPoint pointInScrollView = [_EO convertPoint: [theEvent locationInWindow]
				       fromView: nil];
  NSView *clickedView = [_EO hitTest: pointInScrollView];

  // If click landed directly on a table view, select it and forward the event
  if ([clickedView isKindOfClass: [NSTableView class]])
    {
      [self _openTableViewEditor: [self _editorForTableView: (NSTableView *)clickedView]
                       withEvent: theEvent];
      return;
    }

  // If hit testing reaches a table header, route through the table editor so
  // column selection stays owned by the editor rather than AppKit's header.
  if ([clickedView isKindOfClass: [NSTableHeaderView class]])
    {
      NSTableHeaderView *hv = (NSTableHeaderView *)clickedView;
      NSTableView *tv = [hv tableView];
      [self _openTableViewEditor: [self _editorForTableView: tv]
                       withEvent: theEvent];
      return;
    }

  if ([clickedView isDescendantOf: documentViewEditor])
    {
      if (([self isOpened] == YES) && ([documentViewEditor isOpened] == NO))
        {
          [documentViewEditor setOpened: YES];
        }
      if ([documentViewEditor isOpened])
        {
          [documentViewEditor mouseDown: theEvent];
        }
    }
  else
    {
      NSView *v = clickedView;
      id r = [v nextResponder];

      if([v respondsToSelector: @selector(setNextResponder:)])
        {
          // prevent responder loop
          [v setNextResponder: nil];
          [v mouseDown: theEvent];
          [v setNextResponder: r];
        }
      else
        {
          [v mouseDown: theEvent];
        }
    }

  opened = NO;
}

- (void) dealloc
{
  RELEASE(selection);
  [super dealloc];
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  opened = NO;
  openedSubeditor = nil;

  if ((self = [super initWithObject: anObject
		     inDocument: aDocument]) == nil)
    {
      return nil;
    }

  selection = [[NSMutableArray alloc] initWithCapacity: 5];  
  [self registerForDraggedTypes: [NSArray arrayWithObjects: IBViewPboardType, 
					  GormLinkPboardType, 
					  IBFormatterPboardType, 
					  nil]];

  return self;
}

- (NSArray *)destroyAndListSubviews
{
  id documentView = [_EO documentView];
  NSArray *subviews = [documentView subviews];
  NSMutableArray *newSelection = [NSMutableArray array];

  if([documentView conformsToProtocol: @protocol(IBEditors)] == YES)
    {
      id internalView = [subviews objectAtIndex: 0];
      NSEnumerator *enumerator = [[internalView subviews] objectEnumerator];
      GormViewEditor *subview;

      if([[documentView editedObject] isKindOfClass: [NSTextView class]])
        return newSelection;

      [parent makeSubeditorResign];
      while ((subview = [enumerator nextObject]) != nil)
	{
	  id v;
	  NSRect frame;

	  v = [subview editedObject];
	  frame = [v frame];
	  // Convert frame from scrollView coordinates to outer view coordinates
	  frame.origin.x += [_EO frame].origin.x;
	  frame.origin.y += [_EO frame].origin.y;
	  [subview deactivate];      
	  [v setFrame: frame];
	  [newSelection addObject: v];
	}
    }
  else
    {
      NSRect frame = [documentView frame];

      if([documentView isKindOfClass: [NSTextView class]])
        return newSelection;

      // In this case the view editor is the documentView and
      // we need to add the internal view back into the superview
      frame.origin.x += [_EO frame].origin.x;
      frame.origin.y += [_EO frame].origin.y;
      [documentView setFrame: frame];
      [newSelection addObject: documentView];
      [_EO setDocumentView: nil];
    }

  [self close];
  return newSelection;
}
@end
