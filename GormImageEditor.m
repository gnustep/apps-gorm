/* GormSoundEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
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

#include "GormPrivate.h"

/*
 * Method to return the image that should be used to display objects within
 * the matrix containing the objects in a document.
 */
@implementation NSObject (GormImageAdditions)
- (NSString*) imageInspectorClassName
{
  return @"GormImageInspector";
}

@end



@implementation	GormImageEditor

static NSMapTable	*docMap = 0;
static int handled_mask= NSDragOperationCopy|NSDragOperationGeneric|NSDragOperationPrivate;

+ (void) initialize
{
  if (self == [GormImageEditor class])
    {
      docMap = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,
	NSObjectMapValueCallBacks, 2);
    }
}

+ (GormImageEditor*) editorForDocument: (id<IBDocuments>)aDocument
{
  id	editor = NSMapGet(docMap, (void*)aDocument);

  if (editor == nil)
    {
      editor = [[self alloc] initWithObject: nil inDocument: aDocument];
      AUTORELEASE(editor);
    }
  return editor;
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  return NO;
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
}

- (unsigned int) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSArray *types=[[sender draggingPasteboard] types];
  unsigned int mask=[sender draggingSourceOperationMask];

  NSDebugLLog(@"GormImageEditor draggingEntered mask=%i types=%@",mask,types);
  
   if (  mask&handled_mask &&
       ([types containsObject: NSFilenamesPboardType] ||
        [types containsObject: NSTIFFPboardType]))

    return NSDragOperationCopy;

  return NSDragOperationNone;
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSArray *types=[[sender draggingPasteboard] types];
  unsigned int mask=[sender draggingSourceOperationMask];

  NSDebugLLog(@"dragndrop",@"GormImageEditor draggingEntered mask=%x types=%@",mask,types);
  
  if (mask&handled_mask &&
       ([types containsObject: NSFilenamesPboardType] ||
        [types containsObject: NSTIFFPboardType]))
    return NSDragOperationCopy;


  return NSDragOperationNone;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb=[sender draggingPasteboard];
  NSArray *types=[pb types];
  unsigned int mask=[sender draggingSourceOperationMask];

  NSDebugLLog(@"dragndrop",@"performDrag %x %@",mask,types);

   if (!(mask&handled_mask))
     return NO;

  if ([types containsObject: NSFilenamesPboardType])
    {
      NSArray *data;
      int i,c;

      data=[pb propertyListForType: NSFilenamesPboardType];
      if (!data)
	data=[NSUnarchiver unarchiveObjectWithData: [pb dataForType: NSFilenamesPboardType]];

      c=[data count];
      printf("count %i\n",c);
      for (i=0;i<c;i++)
	{
 	  id placeHolder =  nil;

	  NSLog(@"====> %@",[data objectAtIndex:i]);
	  placeHolder = [(GormDocument *)document _createImagePlaceHolder: [data objectAtIndex: i]];
 	  NSLog(@"here1 %@", [data objectAtIndex: i]);

	  if (placeHolder)
 	    {
 	      NSLog(@"here %@", [data objectAtIndex: i]);
   	      [self addObject: placeHolder];
   	      [(GormDocument *)document addImage: [data objectAtIndex: i]];

	    }

	}
      return YES;
    }
  return NO;


}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}

- (void) drawSelection
{
}

- (id<IBDocuments>) document
{
  return document;
}

- (void) handleNotification: (NSNotification*)aNotification
{
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  id	old = NSMapGet(docMap, (void*)aDocument);

  if (old != nil)
    {
      RELEASE(self);
      self = RETAIN(old);
      [self addObject: anObject];
      return self;
    }

  self = [super init];
  if (self != nil)
    {
      NSButtonCell	*proto;

      document = aDocument;

      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	NSFilenamesPboardType, nil]];

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
      proto = [NSButtonCell new];
      [proto setBordered: NO];
      [proto setAlignment: NSCenterTextAlignment];
      [proto setImagePosition: NSImageAbove];
      [proto setSelectable: NO];
      [proto setEditable: NO];
      [self setPrototype: proto];
      RELEASE(proto);
      NSMapInsert(docMap, (void*)aDocument, (void*)self);
      [self addObject: anObject];
    }
  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (flag == YES && selected != nil)
    {
      unsigned	pos = [objects indexOfObjectIdenticalTo: selected];
      int	r = pos / [self numberOfColumns];
      int	c = pos % [self numberOfColumns];

      [self selectCellAtRow: r column: c];
    }
  else
    {
      [self deselectAllCells];
    }
  [self displayIfNeeded];
  [[self window] flushWindow];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  int row, column;
  int newRow, newColumn;
  unsigned eventMask = NSLeftMouseUpMask | NSLeftMouseDownMask
			| NSMouseMovedMask | NSLeftMouseDraggedMask
			| NSPeriodicMask;
  NSPoint lastLocation = [theEvent locationInWindow];
  NSEvent* lastEvent = theEvent;
  NSPoint initialLocation;

  /*
   * Pathological case -- ignore mouse down
   */
  if ((_numRows == 0) || (_numCols == 0))
    {
      [super mouseDown: theEvent];
      return; 
    }

  lastLocation = [self convertPoint: lastLocation
		       fromView: nil];
  initialLocation = lastLocation;
  // If mouse down was on a selectable cell, start editing/selecting.
  if ([self getRow: &row
	    column: &column
	    forPoint: lastLocation])
    {
      if ([_cells[row][column] isEnabled])
	{
	  if ((_mode == NSRadioModeMatrix) && _selectedCell != nil)
	    {
	      [_selectedCell setState: NSOffState];
	      [self drawCellAtRow: _selectedRow column: _selectedColumn];
	      _selectedCells[_selectedRow][_selectedColumn] = NO;
	      _selectedCell = nil;
	      _selectedRow = _selectedColumn = -1;
	    }
	  [_cells[row][column] setState: NSOnState];
	  [self drawCellAtRow: row column: column];
	  [_window flushWindow];
	  _selectedCells[row][column] = YES;
	  _selectedCell = _cells[row][column];
	  _selectedRow = row;
	  _selectedColumn = column;
	}
    }
  else
    {
      return;
    }
  
  lastEvent = [NSApp nextEventMatchingMask: eventMask
		     untilDate: [NSDate distantFuture]
		     inMode: NSEventTrackingRunLoopMode
		     dequeue: YES];
  
  lastLocation = [self convertPoint: [lastEvent locationInWindow]
		       fromView: nil];


  while ([lastEvent type] != NSLeftMouseUp)
    {
      if((![self getRow: &newRow
		 column: &newColumn
		 forPoint: lastLocation])
	 ||
	 (row != newRow)
	 ||
	 (column != newColumn)
	 ||
	 ((lastLocation.x - initialLocation.x) * 
	  (lastLocation.x - initialLocation.x) +
	  (lastLocation.y - initialLocation.y) * 
	  (lastLocation.y - initialLocation.y)
	  >= 25))
	{
  	  NSPasteboard	*pb;
	  int pos;
	  pos = row * [self numberOfColumns] + column;

  	  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
  	  [pb declareTypes: [NSArray arrayWithObject: GormImagePboardType]
  		     owner: self];
  	  [pb setString: [[objects objectAtIndex: pos] imageName] 
	      forType: GormImagePboardType];
  	  [self dragImage: [[objects objectAtIndex: pos] image]
  		       at: lastLocation
  		   offset: NSZeroSize
  		    event: theEvent
  	       pasteboard: pb
  		   source: self
  		slideBack: YES];

	  return;
	}

      lastEvent = [NSApp nextEventMatchingMask: eventMask
			 untilDate: [NSDate distantFuture]
			 inMode: NSEventTrackingRunLoopMode
			 dequeue: YES];
      
      lastLocation = [self convertPoint: [lastEvent locationInWindow]
			   fromView: nil];

    }

  [self changeSelection: self];

}

- (void) pasteInSelection
{
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationCopy;
}

- (id) raiseSelection: (id)sender
{
  id	obj = [self changeSelection: sender];
  id	e;

  e = [document editorForObject: obj create: YES];
  [e orderFront];
  [e resetObject: obj];
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
      NSString          *name = [obj imageName];
      
      [but setImage: [obj image]];
      [but setTitle: name];
      [but setShowsStateBy: NSChangeGrayCellMask];
      [but setHighlightsBy: NSChangeGrayCellMask];
    }
  while (index < rows * cols)
    {
      NSButtonCell	*but = [self cellAtRow: index/cols column: index%cols];

      [but setImage: nil];
      [but setTitle: @""];
      [but setShowsStateBy: NSNoCellMask];
      [but setHighlightsBy: NSNoCellMask];
      index++;
    }
  [self setIntercellSpacing: NSMakeSize(8,8)];
  [self sizeToCells];
  [self setNeedsDisplay: YES];
}

@end

// sound proxy object...
@implementation GormImage
- (id) initWithName: (NSString *)aName
	       path: (NSString *)aPath
{
  NSSize originalSize;
  float ratioH;
  float ratioW;
  [super init];
  ASSIGN(name, aName);
  ASSIGN(path, aPath);
  image = [[NSImage alloc] initByReferencingFile: aPath];
  smallImage = [[NSImage alloc] initWithContentsOfFile: aPath];
  [image setName: aName];

  if (smallImage == nil)
    {
      RELEASE(name);
      RELEASE(path);
      return nil;
    }

  originalSize = [smallImage size];
  ratioW = originalSize.width / 70;
  ratioH = originalSize.height / 55;
  
  if (ratioH > 1 || ratioW > 1)
    {
      [smallImage setScalesWhenResized: YES];
      if (ratioH > ratioW)
	{
	  [smallImage setSize: NSMakeSize(originalSize.width / ratioH, 55)];
	}
      else 
	{
	  [smallImage setSize: NSMakeSize(70, originalSize.height / ratioW)];
	}
    }

  isSystemImage = NO;
  isInWrapper = NO;
  return self;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(path);
  RELEASE(image);
}

- (void) setImageName: (NSString *)aName
{
  ASSIGN(name, aName);
}

- (NSString *) imageName
{
  return name;
}

- (void) setImagePath: (NSString *)aPath
{
  ASSIGN(path, aPath);
}

- (NSString *) imagePath
{
  return path;
}

- (NSImage *) normalImage
{
  return image;
}

- (NSImage *) image
{
  return smallImage;
}

- (void) setSystemImage: (BOOL)flag
{
  isSystemImage = flag;
}

- (BOOL) isSystemImage
{
  return isSystemImage;
}

- (void) setInWrapper: (BOOL)flag
{
  isInWrapper = flag;
}

- (BOOL) isInWrapper
{
  return isInWrapper;
}

- (NSString *)inspectorClassName
{
  return @"GormImageInspector"; 
}
@end
