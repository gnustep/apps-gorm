/* GormObjectEditor.m
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

@interface	GormObjectEditor : NSMatrix <IBEditors>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPoint		mouseDownPoint;
  BOOL			shouldBeginDrag;
  NSPasteboard		*dragPb;
}
- (void) addObject: (id)anObject;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
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

@implementation	GormObjectEditor

static NSImage	*objectImage = nil;
static NSImage	*windowImage = nil;
static NSImage	*menuImage = nil;
static NSImage	*firstImage = nil;
static NSImage	*ownerImage = nil;
static NSImage	*fontImage = nil;
static NSImage	*dragImage = nil;

+ (void) initialize
{
  if (self == [GormObjectEditor class])
    {
      NSBundle	*bundle;
      NSString	*path;

      bundle = [NSBundle mainBundle];
      path = [bundle pathForImageResource: @"GormLinkImage"];
      if (path != nil)
	{
	  dragImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormObject"];
      if (path != nil)
	{
	  objectImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormFilesOwner"];
      if (path != nil)
	{
	  ownerImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormFirstResponder"];
      if (path != nil)
	{
	  firstImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormFontManager"];
      if (path != nil)
	{
	  fontImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormMenu"];
      if (path != nil)
	{
	  menuImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormWindow"];
      if (path != nil)
	{
	  windowImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
    }
}

- (void) addObject: (id)anObject
{
  if ([objects indexOfObjectIdenticalTo: anObject] == NSNotFound)
    {
      [objects addObject: anObject];
      [self refreshCells];
    }
}

- (void) dealloc
{
  RELEASE(objects);
  [super dealloc];
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  self = [super init];
  if (self)
    {
      NSButtonCell	*proto;

      selected = anObject;
      document = aDocument;

      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	IBCellPboardType, IBMenuPboardType, IBMenuCellPboardType,
	IBObjectPboardType, IBViewPboardType, IBWindowPboardType, nil]];

      [self setAutosizesCells: NO];
      [self setCellSize: NSMakeSize(72,72)];
      [self setIntercellSpacing: NSMakeSize(8,8)];
      [self setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];
      [self setMode: NSRadioModeMatrix];
      /*
       * Send mouse click actions to self, so we can handle selection.
       */
      [self setAction: @selector(changeSelection:)];
      [self setDoubleAction: @selector(raiseSelection:)];
      [self setTarget: self];

      objects = [NSMutableArray new];
      [objects addObject: ownerImage];
      [objects addObject: firstImage];
      proto = [NSButtonCell new];
      [proto setBordered: NO];
      [proto setAlignment: NSCenterTextAlignment];
      [proto setImagePosition: NSImageAbove];
      [proto setShowsStateBy: NSChangeGrayCellMask];
      [proto setHighlightsBy: NSChangeGrayCellMask];
      [proto setSelectable: NO];
      [proto setEditable: NO];
      [self setPrototype: proto];
      RELEASE(proto);
      [self refreshCells];
    }
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

#if 0
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

- (id) changeSelection: (id)sender
{
  int	row = [self selectedRow];
  int	col = [self selectedColumn];
  int	index = row * [self numberOfColumns] + col;
  id	obj = nil;

  if (index >= 0 && index < [objects count])
    {
      obj = [objects objectAtIndex: index];
      if (obj == ownerImage || obj == firstImage || obj == fontImage)
	{
	  obj = nil;	/* Can't select these. */
	}
      if (obj != selected)
	{
	  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

	  selected = obj;
	  [nc postNotificationName: IBSelectionChangedNotification
			    object: self];
	}
    }
  return obj;
}

- (id) raiseSelection: (id)sender
{
  id	obj = [self changeSelection: sender];

  if ([obj isKindOfClass: [NSWindow class]])
    {
      [obj makeKeyAndOrderFront: self];
    }
  else if ([obj isKindOfClass: [NSMenu class]])
    {
      NSLog(@"Menu needs raising"); /* FIXME */
    }
  return self;
}

- (void) refreshCells
{
  unsigned	count = [objects count];
  unsigned	index;
  int		cols = 0;
  int		rows;
  int		width;

  width = [[self superview] bounds].size.width;
  while (width >= 72)
    {
      width -= (72 + 8);
      cols++;
    }
  if (cols == 0)
    {
      cols = 1;
    }
  rows = count / cols;
  if (rows == 0 || rows * cols != count)
    {
      rows++;
    }
  [self renewRows: rows columns: cols];

  for (index = 0; index < count; index++)
    {
      id		obj = [objects objectAtIndex: index];
      NSButtonCell	*but = [self cellAtRow: index/cols column: index%cols];

      if (obj == ownerImage)
	{
	  [but setImage: obj];
	  [but setTitle: @"File's Owner"];
	}
      else if (obj == firstImage)
	{
	  [but setImage: obj];
	  [but setTitle: @"1st Responder"];
	}
      else if (obj == fontImage)
	{
	  [but setImage: obj];
	  [but setTitle: @"Font Manager"];
	}
      else if ([obj isKindOfClass: [NSWindow class]])
	{
	  [but setImage: windowImage];
	  [but setTitle: [document nameForObject: obj]];
	}
      else if ([obj isKindOfClass: [NSMenu class]])
	{
	  [but setImage: menuImage];
	  [but setTitle: [document nameForObject: obj]];
	}
      else
	{
	  [but setImage: objectImage];
	  [but setTitle: [document nameForObject: obj]];
	}
    }
  while (index < rows * cols)
    {
      NSButtonCell	*but = [self cellAtRow: index/cols column: index%cols];

      [but setImage: nil];
      [but setTitle: nil];
      [but setEnabled: NO];
      index++;
    }
  [self setIntercellSpacing: NSMakeSize(8,8)];
  [self sizeToCells];
  [self setNeedsDisplay: YES];
}

- (void) removeObject: (id)anObject
{
  unsigned	pos;

  pos = [objects indexOfObjectIdenticalTo: anObject];
  if (pos == NSNotFound)
    {
      return;
    }
  if (anObject == ownerImage || anObject == firstImage)
    {
      return;
    }
  [objects removeObjectAtIndex: pos];
  [self refreshCells];
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [self refreshCells];
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
  return selected;
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
  if (selected == nil)
    return [NSArray array];
  else
    return [NSArray arrayWithObject: selected];
}

- (unsigned) selectionCount
{
  return (selected == nil) ? 0 : 1;
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
