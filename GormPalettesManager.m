/* GormPalettesPanager.m
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

@interface	GormPaletteView : NSView
{
  NSPoint	mouseDownPoint;
  BOOL		shouldBeginDrag;
  NSPasteboard	*dragPb;
}
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
@end

@implementation	GormPaletteView

static NSImage	*dragImage = nil;
+ (void) initialize
{
  if (self == [GormPaletteView class])
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormLinkImage"];

      dragImage = [[NSImage alloc] initWithContentsOfFile: path];
    }
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithFrame: (NSRect)aFrame
{
  self = [super initWithFrame: aFrame];
  if (self != nil)
    {
      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	IBCellPboardType, IBMenuPboardType, IBMenuCellPboardType,
	IBObjectPboardType, IBViewPboardType, IBWindowPboardType, nil]];
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

      offset.width = rect.origin.x - dragPoint.x;
      offset.height = rect.origin.y - dragPoint.y;

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
@end


@implementation GormPalettesManager

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(panel);
  RELEASE(bundles);
  RELEASE(palettes);
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([panel isVisible] == YES)
	{
	  hiddenDuringTest = YES;
	  [panel orderOut: self];
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if (hiddenDuringTest == YES)
	{
	  hiddenDuringTest = NO;
	  [panel orderFront: self];
	}
    }
}

- (id) init
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSScrollView	*scrollView;
  NSArray	*array;
  NSRect	contentRect = {{0, 0}, {272, 266}};
  NSRect	selectionRect = {{0, 0}, {52, 52}};
  NSRect	scrollRect = {{0, 192}, {272, 74}};
  NSRect	dragRect = {{0, 0}, {272, 192}};
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask				| NSResizableWindowMask;

  panel = [[NSPanel alloc] initWithContentRect: contentRect
				     styleMask: style
				       backing: NSBackingStoreRetained
					 defer: NO];
  [panel setTitle: @"Palettes"];
  [panel setMinSize: [panel frame].size];

  bundles = [NSMutableArray new];
  palettes = [NSMutableArray new];

  scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: NO];
  [scrollView setAutoresizingMask: NSViewMinYMargin | NSViewWidthSizable];
  selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
					     mode: NSRadioModeMatrix
					cellClass: [NSImageCell class]
				     numberOfRows: 1
				  numberOfColumns: 0];
  [selectionView setTarget: self];
  [selectionView setAction: @selector(setCurrentPalette:)];
  [selectionView setCellSize: NSMakeSize(52,52)];
  [selectionView setIntercellSpacing: NSMakeSize(0,0)];
  [scrollView setDocumentView: selectionView];
  RELEASE(selectionView);
  [[panel contentView] addSubview: scrollView]; 
  RELEASE(scrollView);

  dragView = [[GormPaletteView alloc] initWithFrame: dragRect];
  [dragView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
  [[panel contentView] addSubview: dragView]; 
  RELEASE(dragView);

  [panel setFrameUsingName: @"Palettes"];
  [panel setFrameAutosaveName: @"Palettes"];
  current = -1;

  array = [[NSBundle mainBundle] pathsForResourcesOfType: @"palette"
					     inDirectory: nil];
  if ([array count] > 0)
    {
      unsigned	index;

      for (index = 0; index < [array count]; index++)
	{
	  [self loadPalette: [array objectAtIndex: index]];
	}
    }

  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillBeginTestingInterfaceNotification
	   object: nil];
  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillEndTestingInterfaceNotification
	   object: nil];

  return self;
}

- (void) loadPalette: (NSString*)path
{
  NSBundle	*bundle;
  NSWindow	*window;
  Class		paletteClass;
  NSDictionary	*paletteInfo;
  NSString	*className;
  IBPalette	*palette;
  NSImageCell	*cell;
  int		col;
  
  for (col = 0; col < [bundles count]; col++)
    {
      bundle = [bundles objectAtIndex: col];
      if ([path isEqualToString: [bundle bundlePath]] == YES)
	{
	  NSRunAlertPanel (NULL, @"Palette has already been loaded", 
			   @"OK", NULL, NULL);
	  return;
	}
    }
  bundle = [NSBundle bundleWithPath: path]; 
  if (bundle == nil)
    {
      NSRunAlertPanel(NULL, @"Could not load Palette", 
		       @"OK", NULL, NULL);
      return;
    }
  [bundles addObject: bundle];	

  path = [bundle pathForResource: @"palette" ofType: @"table"];
  if (path == nil)
    {
      NSRunAlertPanel(NULL, @"File 'palette.table' missing",
		       @"OK", NULL, NULL);
      return;
    }

  paletteInfo = [[NSString stringWithContentsOfFile: path]
    propertyListFromStringsFileFormat];
  if (paletteInfo == nil)
    {
      NSRunAlertPanel(NULL, @"Failed to load 'palette.table'",
		       @"OK", NULL, NULL);
      return;
    }

  className = [paletteInfo objectForKey: @"Class"];
  if (className == nil)
    {
      NSRunAlertPanel(NULL, @"No palette class in 'palette.table'",
		       @"OK", NULL, NULL);
      return;
    }

  paletteClass = [bundle classNamed: className];
  if (paletteClass == 0)
    {
      NSRunAlertPanel (NULL, @"Could not load palette class", 
		       @"OK", NULL, NULL);
      return;
    }

  palette = [paletteClass new];
  if ([palette isKindOfClass: [IBPalette class]] == NO)
    {
      NSRunAlertPanel (NULL, @"Palette contains wrong type of class", 
		       @"OK", NULL, NULL);
      RELEASE(palette);
      return;
    }

  [palette finishInstantiate];
  window = [palette originalWindow];
  [window setExcludedFromWindowsMenu: YES];

  [palettes addObject: palette];
  [selectionView addColumn];
  [[palette paletteIcon] setBackgroundColor: [selectionView backgroundColor]];
  col = [selectionView numberOfColumns] - 1;
  cell = [selectionView cellAtRow: 0 column: col];
  [cell setImageFrameStyle: NSImageFrameButton];
  [cell setImage: [palette paletteIcon]];
  [selectionView sizeToCells];
  [selectionView selectCellAtRow: 0 column: col];
  [selectionView setNeedsDisplay: YES];
  RELEASE(palette);
}

- (id) openPalette: (id) sender
{
  NSArray	*fileTypes = [NSArray arrayWithObject: @"palette"];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];

  if (result == NSOKButton)
    {
      NSArray	*filesToOpen = [oPanel filenames];
      unsigned	count = [filesToOpen count];
      unsigned	i;

      for (i = 0; i < count; i++)
	{
	  NSString	*aFile = [filesToOpen objectAtIndex: i];

	  [self loadPalette: aFile];
	}
      return self;
    }
  return nil;
}

- (NSPanel*) panel
{
  return panel;
}

- (void) setCurrentPalette: (id)anObj
{
  NSView	*wv;
  NSView	*sv;
  NSEnumerator	*enumerator;

  if (current >= 0)
    {
      /*
       * Move the views in the drag view back to the content view of the
       * window they originally came from.
       */
      wv = [[[palettes objectAtIndex: current] originalWindow] contentView];
      enumerator = [[dragView subviews] objectEnumerator];
      while ((sv = [enumerator nextObject]) != nil)
	{
	  RETAIN(sv);
	  [sv removeFromSuperview];
	  [wv addSubview: sv];
	  RELEASE(sv);
	}
    }

  current = [anObj selectedColumn];
  if (current >= 0 && current < [palettes count])
    {
      /*
       * Move the views from their original window into our drag view.
       * Resize our drag view to the right size fitrst.
       */
      wv = [[[palettes objectAtIndex: current] originalWindow] contentView];
      [dragView setFrameSize: [wv frame].size];
      enumerator = [[wv subviews] objectEnumerator];
      while ((sv = [enumerator nextObject]) != nil)
	{
	  RETAIN(sv);
	  [sv removeFromSuperview];
	  [dragView addSubview: sv];
	  RELEASE(sv);
	}
    }
  else
    {
      NSLog(@"Bad palette selection - %d", [anObj selectedColumn]);
      current = -1;
    }
  [dragView setNeedsDisplay: YES];
}

@end
