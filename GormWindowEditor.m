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
@implementation NSMenu (IBObjectAdditions)
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

@implementation NSWindow (IBObjectAdditions)
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
  id			edited;
  NSMutableArray	*selection;
  NSPoint		mouseDownPoint;
  BOOL			shouldBeginDrag;
  NSPasteboard		*dragPb;
}
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
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

- (void) dealloc
{
  RELEASE(edited);
  RELEASE(selection);
  RELEASE(document);
  [super dealloc];
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  self = [super init];
  ASSIGN(document, aDocument);
  ASSIGN(edited, anObject);
  selection = [NSMutableArray new];
  return self;
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

/*
 *	Dragging destination protocol implementation
 *
 *	We actually don't handle anything being dropped on the palette,
 *	but we pretend to accept drops from ourself, so that the drag
 *	session quietly terminates - and it looks like the drop has
 *	been successful - this stops windows being created when they are
 *	dropped back on the palette (a window is normally created if the
 *	dnd drop is refused).
 */
- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  return NSDragOperationCopy;;
}
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}
- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}


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
  if (shouldBeginDrag == YES)
    {
      NSPoint		dragPoint = [theEvent locationInWindow];
      NSView		*view = [super hitTest: mouseDownPoint];
      GormDocument	*active = [(id<IB>)NSApp activeDocument];
      NSRect		rect = [view frame];
      NSString		*type;
      id		obj;
      NSPasteboard	*pb;
      NSImageRep	*rep;
      NSSize		offset;

      offset.width = mouseDownPoint.x - dragPoint.x;
      offset.height = mouseDownPoint.y - dragPoint.y;

#if 1
NSLog(@"Could do dragging");
#else
      RELEASE(dragImage);
      dragImage = [NSImage new];
      rep = [[NSCachedImageRep alloc] initWithWindow: [self window]
						rect: rect];
      [dragImage setSize: rect.size];
      [dragImage addRepresentation: rep];

      type = [IBPalette typeForView: view];
      obj = [IBPalette objectForView: view];
      pb = [NSPasteboard pasteboardWithName: NSDragPboard];
      ASSIGN(dragPb, pb);
      [active copyObject: obj type: type toPasteboard: pb];

      [self dragImage: dragImage
		   at: rect.origin
	       offset: offset
		event: theEvent
	   pasteboard: pb
	       source: self
	    slideBack: [type isEqual: IBWindowPboardType] ? NO : YES];
#endif
    }
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  return NO;
}

- (BOOL) activate
{
  [window makeKeyAndOrderFront: self];
  return YES;
}

- (void) close
{
  [self closeSubeditors];
}

- (void) closeSubeditors
{
}

- (void) copySelection
{
}

- (void) deleteSelection
{
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

- (void) makeSelectionVisible: (BOOL)flag
{
}

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  return nil;
}

- (void) orderFront
{
  [window orderFront: self];
}

- (void) pasteInSelection
{
}

- (void) resetObject: (id)anObject
{
}

- (void) selectObjects: (NSArray*)anArray
{
}

- (NSArray*) selection
{
  return AUTORELEASE([selection copy]);
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
  return NO;
}

- (NSWindow*) window
{
  return [self window];
}
@end
