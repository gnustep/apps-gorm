/* GormWindowEditor.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

/*
 * Methods to return the images that should be used to display objects within
 * the matrix containing the objects in a document.
 */
@implementation NSMenu (GormObjectAdditions)
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormMenu"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

@implementation NSWindow (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormWindowEditor";
}
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormWindow"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

/*
 *	Default implementations of methods used for updating a view by
 *	direct action through an editor.
 */
@implementation NSView (ViewAdditions)

- (BOOL) acceptsColor: (NSColor*)color atPoint: (NSPoint)point
{
  return NO;	/* Can the view accept a color drag-and-drop?	*/
}

- (BOOL) allowsAltDragging
{
  return NO;	/* Can the view be dragged into a matrix?	*/
}

- (void) depositColor: (NSColor*)color atPoint: (NSPoint)point
{
  					/* Handle color drop in view.	*/
}

- (NSSize) maximumSizeFromKnobPosition: (IBKnobPosition)knobPosition
{
  NSView	*s = [self superview];
  NSRect	r = (s != nil) ? [s bounds] : [self bounds];

  return r.size;			/* maximum resize permitted	*/
}

- (NSSize) minimumSizeFromKnobPosition: (IBKnobPosition)position
{
  return NSZeroSize;			/* Minimum resize permitted	*/
}

- (void) placeView: (NSRect)newFrame
{
  [self setFrame: newFrame];		/* View changed by editor.	*/
}

@end



@interface	GormWindowEditor : NSView <IBEditors>
{
  id<IBDocuments>	document;
  NSWindow		*edited;
  NSView		*original;
  NSMutableArray	*selection;
  NSMutableArray	*subeditors;
  NSPoint		mouseDownPoint;
  BOOL			shouldBeginDrag;
  NSPasteboard		*dragPb;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (id) editedObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (void) resetObject: (id)anObject;
- (void) selectObjects: (NSArray*)objects;
- (void) validateEditing;
- (BOOL) wantsSelection;
- (NSWindow*) window;
@end

@implementation	GormWindowEditor

/*
 *	Intercepting events in the view and handling them
 */
- (NSView*) hitTest: (NSPoint)loc
{
  /*
   * Stop the subviews receiving events - we grab them all.
   */
  if ([super hitTest: loc] != nil)
    return self;
  return nil;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSView	*view;

  mouseDownPoint = [theEvent locationInWindow];
  view = [super hitTest: mouseDownPoint];
  if (view == self)
    {
      shouldBeginDrag = NO;
    }
  else
    {
      shouldBeginDrag = YES;
    }
  [super mouseDown: theEvent];
}

- (void) mouseDragged: (NSEvent*)theEvent
{
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  /*
   * A window editor can accept views dropped in to the window.
   */
  return [types containsObject: IBViewPboardType];
}

- (BOOL) activate
{
  if (original == nil)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Swap ourselves in as a replacement for the original window
       * content view.
       */
      original = RETAIN([edited contentView]);
      [self setFrame: [original frame]];
      enumerator = [[original subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [self addSubview: sub];
	}
      [edited setContentView: self];
    }
  if ([edited isKeyWindow] == NO)
    {
      [window makeKeyAndOrderFront: self];
    }
  if ([selection count] == 0)
    {
      [selection addObject: edited];
    }
  if ([(id<IB>)NSApp selectionOwner] != self)
    {
      [document setSelectionFromEditor: self];
    }
  return YES;
}

- (void) close
{
  [self closeSubeditors];

  if (original != nil)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Swap ourselves out and the original window content view in.
       */
      [original setFrame: [self frame]];
      enumerator = [[self subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [original addSubview: sub];
	}
      [edited setContentView: original];
      DESTROY(original);
    }
  if ([(id<IB>)NSApp selectionOwner] == self)
    {
      [document resignSelectionForEditor: self];
    }
}

- (void) closeSubeditors
{
  while ([subeditors count] > 0)
    {
      id<IBEditors>	sub = [subeditors lastObject];

      [sub close];
      [subeditors removeObjectIdenticalTo: sub];
    }
}

- (void) copySelection
{
  switch ([selection count])
    {
      case 0:
	break;

      case 1:
	{
	  id	obj = [selection lastObject];

	  if (obj == edited)
	    {
	      [document copyObject: selection
			      type: IBWindowPboardType
		      toPasteboard: [NSPasteboard generalPasteboard]];
	    }
	  else
	    {
	      [document copyObject: selection
			      type: IBViewPboardType
		      toPasteboard: [NSPasteboard generalPasteboard]];
	    }
	}
	break;

      default:
        [document copyObjects: selection
			 type: IBViewPboardType
		 toPasteboard: [NSPasteboard generalPasteboard]];
	break;
    }
}

- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  [self close];
  RELEASE(edited);
  RELEASE(selection);
  RELEASE(subeditors);
  RELEASE(document);
  [super dealloc];
}

- (void) deleteSelection
{
  NSArray	*a = [NSArray arrayWithArray: selection];
  unsigned	c = [a count];

  [selection removeAllObjects];
  [document resignSelectionForEditor: self];
  while (c-- > 0)
    {
      id	obj = [a objectAtIndex: c];

      [document detachObject: obj];
    }
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  NSString	*type = [[dragPb types] lastObject];

  /*
   * Windows are an exception to the normal DnD mechanism - we create them
   * if they are dropped anywhere except back in the pallettes view -
   * ie. if they are dragged, but the drop fails.
   */
  if (f == NO && [type isEqual: IBWindowPboardType] == YES)
    {
      id<IBDocuments>	active = [(id<IB>)NSApp activeDocument];

      if (active != nil)
	{
	  [active pasteType: type fromPasteboard: dragPb parent: nil];
	}
    }
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationCopy;
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  /*
   * Let the dragging source know we will copy the dragged object.
   */
  return NSDragOperationCopy;;
}

- (void) drawSelection
{
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) editedObject
{
  return edited;
}

- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  NSWindow	*win = (NSWindow*)anObject;
  NSView	*cv = [win contentView];
  NSView	*sub;
  NSEnumerator	*enumerator;

  /*
   * Initialize with current window content frame, move window subviews to
   * self, and replace window content view with self.
   */
  if ((self = [super initWithFrame: [cv frame]]) == nil)
    return nil;
  original = RETAIN(cv);
  enumerator = [[original subviews] objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      [self addSubview: sub];
    }
  [win setContentView: self];

  ASSIGN(document, aDocument);
  ASSIGN(edited, anObject);
  selection = [NSMutableArray new];
  [selection addObject: edited];
  subeditors = [NSMutableArray new];

  /*
   * Permit views to be dragged in to the window.
   */
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBViewPboardType, nil]];

  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
}

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  id<IBEditors>	sub;

  sub = [document editorForObject: anObject inEditor: self create: YES];
  /*
   * If we don't already have this subeditor, make a note of it so we
   * can close it later.
   */
  if ([subeditors indexOfObjectIdenticalTo: sub] == NSNotFound)
    {
      [subeditors addObject: sub];
    }
  return sub;
}

- (void) orderFront
{
  [edited orderFront: self];
}

- (void) pasteInSelection
{
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPoint	loc = [sender draggedImageLocation];
  NSPasteboard	*pb = [sender draggingPasteboard];
  NSArray	*views;
  NSEnumerator	*enumerator;
  NSView	*sub;

  /*
   * Ask the document to get the dragged views from the pasteboard and add
   * them to it's collection of known objects.
   */
  views = [document pasteType: IBViewPboardType
	       fromPasteboard: pb
		       parent: edited];
  /*
   * Now make all the views subviews of ourself, setting their origin to be
   * the point at which they were dropped (converted from window coordinates
   * to our own coordinates).
   */
  loc = [self convertPoint: loc fromView: nil];
  enumerator = [views objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      NSRect	rect = [sub frame];

      rect.origin = loc;
      [sub setFrame: rect];
      [self addSubview: sub];
    }
  return YES;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  /*
   * Tell the source that we will accept the drop.
   */
  return YES;
}

- (void) resetObject: (id)anObject
{
}

- (void) selectObjects: (NSArray*)anArray
{
  if (anArray != selection)
    {
      [selection removeAllObjects];
      [selection addObjectsFromArray: anArray];
      if ([selection indexOfObjectIdenticalTo: edited] != NSNotFound)
	{
	  /*
	   * we have selected our edited window ... we can't have anything
	   * else selected at the same time.
	   */
	  if ([selection count] > 0)
	    {
	      [selection removeAllObjects];
	      [selection addObject: edited];
	    }
	}
      else
	{
	  unsigned	count = [selection count];

	  /*
	   * We can only select views that are direct subviews - discard others.
	   */
	  while (count-- > 0)
	    {
	      id	o = [selection objectAtIndex: count];

	      if ([[self subviews] indexOfObjectIdenticalTo: o] == NSNotFound)
		{
		  [selection removeObjectAtIndex: count];
		}
	    }
	}
    }
  /*
   * Now we must let the document (and hence the rest of the app) know about
   * our new selection.
   */
  [document setSelectionFromEditor: self];
}

- (NSArray*) selection
{
  return [NSArray arrayWithArray: selection];
}

- (unsigned) selectionCount
{
  return [selection count];
}

- (void) validateEditing
{
}

- (BOOL) wantsSelection
{
  /*
   * We only want to be the selection owner if we are active (have been
   * swapped for the windows original content view) and if we have some
   * object selected.
   */
  if (original == nil)
    return NO;
  if ([selection count] == 0)
    return NO;
  return YES;
}

- (NSWindow*) window
{
  return [super window];
}
@end
