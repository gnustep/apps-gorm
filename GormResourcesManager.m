/* GormResourcesManager.m
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


@interface	GormObjectsView : NSMatrix
{
  NSMutableArray	*objects;
  NSPoint		mouseDownPoint;
  BOOL			shouldBeginDrag;
  NSPasteboard		*dragPb;
}
- (void) addObject: (id)anObject;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
@end

@implementation	GormObjectsView

static NSImage	*objectImage = nil;
static NSImage	*windowImage = nil;
static NSImage	*menuImage = nil;
static NSImage	*firstImage = nil;
static NSImage	*ownerImage = nil;
static NSImage	*fontImage = nil;
static NSImage	*dragImage = nil;

+ (void) initialize
{
  if (self == [GormObjectsView class])
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
- (id) initWithFrame: (NSRect)aFrame
{
  self = [super initWithFrame: aFrame];
  if (self != nil)
    {
      NSButtonCell	*proto;

      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	IBCellPboardType, IBMenuPboardType, IBMenuCellPboardType,
	IBObjectPboardType, IBViewPboardType, IBWindowPboardType, nil]];

      [self setAutosizesCells: NO];
      [self setCellSize: NSMakeSize(72,72)];
      [self setIntercellSpacing: NSMakeSize(8,8)];
      [self setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];

      objects = [NSMutableArray new];
      [objects addObject: ownerImage];
      [objects addObject: firstImage];
      proto = [NSButtonCell new];
      [proto setBordered: NO];
      [proto setAlignment: NSCenterTextAlignment];
      [proto setImagePosition: NSImageAbove];
      [self setPrototype: proto];
      RELEASE(proto);
      [self renewRows: 2 columns: 3];
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
    }
}

- (void) refreshCells
{
  unsigned	count = [objects count];
  unsigned	index;
  int		cols = 0;
  int		rows;
  int		width;
  id<IBDocuments>	document;

  document = [(id<IB>)NSApp activeDocument];

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

@end




@implementation GormResourcesManager

+ (GormResourcesManager*) newManagerForDocument: (id<IBDocuments>)doc
{
  GormResourcesManager	*mgr;

  mgr = [[self alloc] init];
  mgr->document = doc;
  return mgr;
}

- (void) addObject: (id)anObject
{
  [objectsView addObject: anObject];
}

- (void) dealloc
{
  [window performClose: self];
  RELEASE(window);
  RELEASE(objectsView);
  [super dealloc];
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSRect	winrect = NSMakeRect(100,100,340,252);
      NSRect	selectionRect = {{0, 188}, {240, 64}};
      NSRect	scrollRect = {{0, 0}, {340, 188}};
      NSRect	mainRect = {{20, 0}, {320, 188}};
      NSBundle	*bundle;
      NSString	*path;
      NSImage	*image;
      NSButtonCell	*cell;
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask
			| NSResizableWindowMask | NSMiniaturizableWindowMask;

      window = [[NSWindow alloc] initWithContentRect: winrect
					   styleMask: style 
					     backing: NSBackingStoreRetained
					       defer: NO];
      [window setDelegate: self];
      [window setMinSize: [window frame].size];
      [window setTitle: @"UNTITLED"];
      [nc addObserver: self
	     selector: @selector(windowWillClose:)
		 name: NSWindowWillCloseNotification
	       object: window];

      selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
						 mode: NSRadioModeMatrix
					    cellClass: [NSButtonCell class]
					 numberOfRows: 1
				      numberOfColumns: 4];
      [selectionView setTarget: self];
      [selectionView setAction: @selector(changeView:)];
      [selectionView setAutosizesCells: NO];
      [selectionView setCellSize: NSMakeSize(64,64)];
      [selectionView setIntercellSpacing: NSMakeSize(28,0)];
      [selectionView setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];

      bundle = [NSBundle mainBundle];

      path = [bundle pathForImageResource: @"GormObject"];
      if (path != nil)
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	  cell = [selectionView cellAtRow: 0 column: 0];
	  [cell setImage: image];
	  RELEASE(image);
	  [cell setTitle: @"Objects"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      path = [bundle pathForImageResource: @"GormImage"];
      if (path != nil)
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	  cell = [selectionView cellAtRow: 0 column: 1];
	  [cell setImage: image];
	  RELEASE(image);
	  [cell setTitle: @"Images"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      path = [bundle pathForImageResource: @"GormSound"];
      if (path != nil)
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	  cell = [selectionView cellAtRow: 0 column: 2];
	  [cell setImage: image];
	  RELEASE(image);
	  [cell setTitle: @"Sounds"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      path = [bundle pathForImageResource: @"GormClass"];
      if (path != nil)
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	  cell = [selectionView cellAtRow: 0 column: 3];
	  [cell setImage: image];
	  RELEASE(image);
	  [cell setTitle: @"Classes"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      [[window contentView] addSubview: selectionView];
      RELEASE(selectionView);

      scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setHasHorizontalScroller: NO];
      [scrollView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [[window contentView] addSubview: scrollView];
      RELEASE(scrollView);

      mainRect.origin = NSMakePoint(0,0);
      mainRect.size = [scrollView contentSize];
      objectsView = [[GormObjectsView alloc] initWithFrame: mainRect];
      [objectsView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setDocumentView: objectsView];
    }
  return self;
}

- (void) removeObject: (id)anObject
{
  [objectsView removeObject: anObject];
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) windowShouldClose: (NSWindow*)aWindow
{
  return [document documentShouldClose];
}

- (void) windowWillClose: (NSNotification*)aNotification
{
  [document documentWillClose];
}
@end

