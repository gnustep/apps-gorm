/* GormMenuEditor.m
 *
 * Copyright (C) 2000 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	2000
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

#include "../../GormPrivate.h"

@implementation NSMenu (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormMenuEditor";
}
/*
 * Method to return the image that should be used to display menus within
 * the matrix containing the objects in a document.
 */
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



@interface	GormMenuEditor : NSMenuView <IBEditors>
{
  id<IBDocuments>	document;
  NSMenu		*edited;
  id			original;
  NSMenuView		*rep;
  NSMutableArray	*selection;
  id			subeditor;
  BOOL			isLinkSource;
  BOOL			isClosed;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (void) copySelection;
- (void) deactivate;
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

@implementation	GormMenuEditor

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Argh - encoding menu editor"];
}

/*
 *	Intercepting events in the view and handling them
 */
- (NSView*) hitTest: (NSPoint)loc
{
  /*
   * We grab all events in the window.
   */
  if ([super hitTest: loc] != nil)
    {
      return self;
    }
  return nil;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint	loc = [theEvent locationInWindow];
  NSView	*hit = [super hitTest: loc];

  if (hit == rep)
    {
      int	pos = [rep indexOfItemAtPoint: loc];

NSLog(@"Mouse down on item %d", pos);
      if (pos >= 0)
	{
	  NSMenuItem	*item = [edited itemAtIndex: pos];

	  [self makeSelectionVisible: NO];
	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    {
	      NSMutableArray	*array;

	      array = [NSMutableArray arrayWithArray: selection];
	      if ([array containsObject: item] == YES)
		{
		  [array removeObject: item];
		}
	      else
		{
		  [array addObject: item];
		}
	      [self selectObjects: array];
	    }
	  else
	    {
	      [self selectObjects: [NSArray arrayWithObject: item]];
	      if ([theEvent modifierFlags] & NSControlKeyMask)
		{
		  NSPoint	dragPoint = [theEvent locationInWindow];
		  NSPasteboard	*pb;
		  NSString	*name = [document nameForObject: item];

		  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
		  [pb declareTypes:
		    [NSArray arrayWithObject: GormLinkPboardType]
			     owner: self];
		  [pb setString: name forType: GormLinkPboardType];
		  [NSApp displayConnectionBetween: item and: nil];

		  isLinkSource = YES;
		  [self dragImage: [NSApp linkImage]
			       at: dragPoint
			   offset: NSZeroSize
			    event: theEvent
		       pasteboard: pb
			   source: self
			slideBack: YES];
		  isLinkSource = NO;
		}
	    }
	  [self makeSelectionVisible: YES];
	}
    }
  else
    {
      /*
       * The mouse down wasn't over the menu items, so we just let the menu
       * handle it.
       */
      [hit mouseDown: theEvent];
    }
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  /*
   * A menu editor can accept menu items pasted in to it.
   */
  return [types containsObject: IBMenuPboardType];
}

- (BOOL) activate
{
  NSAssert(isClosed == NO, NSInternalInconsistencyException);
  if (original == nil)
    {
      NSWindow		*w;
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Swap ourselves in as a replacement for the original window
       * content view.
       */
      w = [rep window];
      original = RETAIN([w contentView]);
      [self setFrame: [original frame]];
      enumerator = [[original subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [self addSubview: sub];
	}
      [w setContentView: self];
      [edited display];
      return NO;
    }
  return YES;
}

- (void) close
{
  NSAssert(isClosed == NO, NSInternalInconsistencyException);
  isClosed = YES;
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [self makeSelectionVisible: NO];
  if ([(id<IB>)NSApp selectionOwner] == self)
    {
      [document resignSelectionForEditor: self];
    }

  [self closeSubeditors];

  [self deactivate];

  [edited close];

  [document editor: self didCloseForObject: edited];
}

- (void) closeSubeditors
{
  if (subeditor != nil)
    {
      [subeditor close];
      DESTROY(subeditor);
    }
}

- (void) copySelection
{
  if ([selection count] > 0)
    {
      [document copyObjects: selection
		       type: IBMenuPboardType
	       toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (void) deactivate
{
  if (original != nil)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      RETAIN(self);
      /*
       * Swap ourselves out and the original window content view in.
       */
      [original setFrame: [self frame]];
      [[rep window] setContentView: original];
      enumerator = [[self subviews] objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [original addSubview: sub];
	}
      DESTROY(original);
      RELEASE(self);
    }
}

- (void) dealloc
{
  if (isClosed == NO)
    {
      [self close];
    }
  RELEASE(edited);
  RELEASE(selection);
  RELEASE(subeditor);
  RELEASE(document);
  [super dealloc];
}

- (void) deleteSelection
{
  if ([selection count] > 0)
    {
      NSArray		*s = [NSArray arrayWithArray: selection];
      NSEnumerator	*e = [s objectEnumerator];
      NSMenuItem	*i;

      [self makeSelectionVisible: NO];
      [self selectObjects: [NSArray array]];
      while ((i = [e nextObject]) != nil)
	{
	  [edited removeItem: i];
	}
      [document detachObjects: s];
    }
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  /*
   * FIXME - handle this.
   * Notification that a drag failed/succeeded.
   */
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  if (isLinkSource == YES)
    return NSDragOperationLink;
  else
    return NSDragOperationCopy;
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSArray	*types;

  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: IBMenuPboardType] == YES)
    {
      dragType = IBMenuPboardType;
    }
  else if ([types containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
    }
  else
    {
      dragType = nil;
    }
  return [self draggingUpdated: sender];
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  if (dragType == IBMenuPboardType)
    {
      return NSDragOperationCopy;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      int	pos = [rep indexOfItemAtPoint: loc];
      id	item = nil;

      if (pos >= 0)
	{
	  item = [edited itemAtIndex: pos];
	}
      if (item == [NSApp connectSource])
	{
	  item = nil;
	}
      [NSApp displayConnectionBetween: [NSApp connectSource] and: item];
      return NSDragOperationLink;
    }
  else
    {
      return 0;
    }
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
  self = [super init];
  ASSIGN(document, aDocument);
  ASSIGN(edited, anObject);
  selection = [NSMutableArray new];
  rep = [edited menuRepresentation];
  /*
   * Permit views and connections to be dragged in to the window.
   */
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBMenuPboardType, GormLinkPboardType, nil]];

  /*
   * Make sure that all our menu items are attached in the document.
   */
  [document attachObjects: [edited itemArray] toParent: edited];

  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (flag == NO)
    {
      if ([selection count] > 0)
	{
	  NSEnumerator	*enumerator = [selection objectEnumerator];
	  NSMenuItem	*item;

	  [[self window] disableFlushWindow];
	  [rep lockFocus];
	  while ((item = [enumerator nextObject]) != nil)
	    {
	      int	pos = [edited indexOfItem: item];
	      id	cell = [rep menuItemCellForItemAtIndex: pos];
	      NSRect	rect = [rep rectOfItemAtIndex: pos];
	      
	      [cell highlight: NO withFrame: rect inView: rep];
	    }
	  [rep unlockFocus];
	  [[self window] enableFlushWindow];
	  [[self window] flushWindowIfNeeded];
	}
    }
  else
    {
      if ([selection count] > 0)
	{
	  NSEnumerator	*enumerator = [selection objectEnumerator];
	  NSMenuItem	*item;

	  [[self window] disableFlushWindow];
	  [rep lockFocus];
	  while ((item = [enumerator nextObject]) != nil)
	    {
	      int	pos = [edited indexOfItem: item];
	      id	cell = [rep menuItemCellForItemAtIndex: pos];
	      NSRect	rect = [rep rectOfItemAtIndex: pos];
	      
	      [cell highlight: YES withFrame: rect inView: rep];
	    }
	  [rep unlockFocus];
	  [[self window] enableFlushWindow];
	  [[self window] flushWindowIfNeeded];
	}
    }
}

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  return nil;
}

- (void) orderFront
{
  [[edited window] orderFront: self];
}

- (void) pasteInSelection
{
  NSPasteboard	*pb = [NSPasteboard generalPasteboard];
  NSArray	*items;
  NSEnumerator	*enumerator;
  NSMenuItem	*item;

  /*
   * Ask the document to get the copied items from the pasteboard and add
   * them to it's collection of known objects.
   */
  items = [document pasteType: IBMenuPboardType
	       fromPasteboard: pb
		       parent: edited];
  
  enumerator = [items objectEnumerator];
  while ((item = [enumerator nextObject]) != nil)
    {
      NSString	*title = [item title];

      if ([edited indexOfItemWithTitle: title] > 0)
	{
	  [document detachObject: item];	/* Already exists */
	}
      else
	{
	  [edited addItem: item];
	}
    }
  [edited sizeToFit];
  [edited display];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSRect	f = [rep frame];

  if (dragType == IBMenuPboardType)
    {
      NSPoint		loc = [sender draggedImageLocation];
      NSArray		*items;
      NSEnumerator	*enumerator;
      NSMenuItem	*item;
      int		pos;

      /*
       * Adjust location so that it lies within horizontal bounds, and so that
       * it appears about half an item higher than it is.  That way, we treat
       * a drop in the lower half of an item as an insertion below it, and a
       * drop in the upper half as an insertion above it.
       */
      if (loc.x < NSMinX(f))
	loc.x = NSMinX(f);
      if (loc.x > NSMaxX(f))
	loc.x = NSMaxX(f);
      loc.y += 10;
      pos = [rep indexOfItemAtPoint: loc] + 1;

      /*
       * Ask the document to get the dragged views from the pasteboard and add
       * them to it's collection of known objects.
       */
      items = [document pasteType: IBMenuPboardType
		   fromPasteboard: dragPb
			   parent: edited];
      enumerator = [items objectEnumerator];
      while ((item = [enumerator nextObject]) != nil)
	{
	  NSString	*title = [item title];

	  if ([edited indexOfItemWithTitle: title] > 0)
	    {
	      [document detachObject: item];	/* Already exists */
	    }
	  else
	    {
	      [edited insertItem: item atIndex: pos++];
	    }
	}
      [edited sizeToFit];
      [edited display];
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      int	pos = [rep indexOfItemAtPoint: loc];

NSLog(@"Link at index: %d (%@)", pos, NSStringFromPoint(loc));
      if (pos >= 0)
	{
	  id	item = [edited itemAtIndex: pos];

	  [NSApp displayConnectionBetween: [NSApp connectSource] and: item];
	  [NSApp startConnecting];
	}
    }
  else
    {
      NSLog(@"Drop with unrecognized type (%@)!", dragType);
      dragType = nil;
      return NO;
    }
  dragType = nil;
  return YES;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  /*
   * Tell the source that we will accept the drop if we can.
   */
  if (dragType == IBMenuPboardType)
    {
      /*
       * We can accept menus dropped anywhere.
       */
      return YES;
    }
  else if (dragType == GormLinkPboardType)
    {
      /*
       * We can accept a link dropped on any of our items.
       */
      return YES;
    }
  return NO;
}

/*
 * Return the rectangle in which an objects link status will be displayed.
 */
- (NSRect) rectForObject: (id)anObject
{
  int		pos = [edited indexOfItem: anObject];
  NSRect	rect;

  if (pos >= 0)
    {
      rect = [rep rectOfItemAtIndex: pos];
      rect = [rep convertRect: rect toView: nil];
    }
  else
    {
      rect = [self frame];
    }
  return rect;
}

- (void) resetObject: (id)anObject
{
  [[self window] makeKeyAndOrderFront: self];
}

- (id) selectAll: (id)sender
{
  [self selectObjects: [edited itemArray]];
  return self;
}

- (void) selectObjects: (NSArray*)anArray
{
  if ([anArray isEqual: selection] == NO)
    {
      unsigned	count;

      [selection removeAllObjects];
      [selection addObjectsFromArray: anArray];

      count = [selection count];

      /*
       * We can only select items in our menu - discard others.
       */
      while (count-- > 0)
	{
	  id	o = [selection objectAtIndex: count];

	  if ([edited indexOfItem: o] == NSNotFound)
	    {
	      [selection removeObjectAtIndex: count];
	    }
	}
    }
  /*
   * Now we must let the document (and hence the rest of the app) know
   * about our new selection.  If there is nothing in it, make sure
   * that our edited window is selected instead.
   */
  if ([selection count] > 0)
    {
      [document setSelectionFromEditor: self];
    }
  else
    {
      GormObjectEditor	*ed;

      ed = [GormObjectEditor editorForDocument: document];
      [ed selectObjects: [NSArray arrayWithObject: edited]];
    }
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
