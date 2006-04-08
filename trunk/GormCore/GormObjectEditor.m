/* GormObjectEditor.m
 *
 * Copyright (C) 1999,2002,2003,2004,2005 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2002,2003,2004,2005
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <InterfaceBuilder/IBObjectAdditions.h>
#include "GormPrivate.h"
#include "GormObjectEditor.h"
#include "GormFunctions.h"
#include "GormDocument.h"
#include "GormClassManager.h"
/*
 * Method to return the image that should be used to display objects within
 * the matrix containing the objects in a document.
 */
@interface NSObject (GormObjectAdditions)
@end

@implementation NSObject (GormObjectAdditions)
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString *path = [bundle pathForImageResource: @"GormUnknown"]; 
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }

  return image;
}

- (NSString*) inspectorClassName
{
  return @"GormObjectInspector";
}

- (NSString*) connectInspectorClassName
{
  return @"GormConnectionInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) helpInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormCustomClassInspector";
}

- (NSString*) editorClassName
{
  return @"GormObjectEditor";
}
@end

@implementation	GormObjectEditor

static NSMapTable	*docMap = 0;

+ (void) initialize
{
  if (self == [GormObjectEditor class])
    {
      docMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
				NSObjectMapValueCallBacks, 
				2);
    }
}

+ (id) editorForDocument: (id<IBDocuments>)aDocument
{
  id	editor = NSMapGet(docMap, (void*)aDocument);

  if (editor == nil)
    {
      editor = [[self alloc] initWithObject: nil inDocument: aDocument];
      AUTORELEASE(editor);
    }
  return editor;
}

+ (void) setEditor: (id)editor
       forDocument: (id<IBDocuments>)aDocument
{
  NSMapInsert(docMap, (void*)aDocument, (void*)editor);
}


- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  return ([[(GormDocument *)document allManagedPboardTypes] firstObjectCommonWithArray: types] != nil);
}

- (void) pasteInSelection
{
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  NSString *type = [[(GormDocument *)document allManagedPboardTypes] firstObjectCommonWithArray: [pb types]];

  if(type != nil)
    {
      // paste the object in.
      [document pasteType: type
		fromPasteboard: pb
		parent: nil];
    }
}

- (void) copySelection
{
  NSArray *sel = [self selection];
  if([sel count] > 0)
    {
      NSString *type = nil;
      id obj = [sel objectAtIndex: 0];

      if([obj isKindOfClass: [NSWindow class]])
	{
	  type = IBWindowPboardType;
 	}
      else if([obj isKindOfClass: [NSView class]])
	{
	  type = IBViewPboardType;
	}
      else
	{
	  type = IBObjectPboardType;
	}

      [document copyObjects: sel
		type: type
		toPasteboard: [NSPasteboard generalPasteboard]];
    }
}

- (void) deleteSelection
{
  if (selected != nil
      && [[document nameForObject: selected] isEqualToString: @"NSOwner"] == NO
      && [[document nameForObject: selected] isEqualToString: @"NSFirst"] == NO)
    {
      NSNotificationCenter	*nc;

      nc = [NSNotificationCenter defaultCenter];

      if ([selected isKindOfClass: [NSMenu class]] &&
	  [[document nameForObject: selected] isEqual: @"NSMenu"] == YES)
	{
	  NSString *title = _(@"Removing Main Menu");
	  NSString *msg = _(@"Are you sure you want to do this?");
	  int retval = NSRunAlertPanel(title, msg,_(@"OK"),_(@"Cancel"), nil, nil);
	  
	  // if the user *really* wants to delete the menu, do it.
	  if(retval != NSAlertDefaultReturn)
	    return;
	}

      [document detachObject: selected];
      if ([selected isKindOfClass: [NSWindow class]] == YES)
	{
	  NSArray *subviews = allSubviews([(NSWindow *)selected contentView]);
	  [document detachObjects: subviews];
	  [selected close];
	}
      
      if ([selected isKindOfClass: [NSMenu class]] == YES)
	{
	  NSArray *items = findAll( selected );
	  NSEnumerator *en = [items objectEnumerator];
	  id obj = nil;
	  
	  while((obj = [en nextObject]) != nil)
	    {
	      [document detachObject: obj];
	    }
	}
      
      [objects removeObjectIdenticalTo: selected];
      [self selectObjects: [NSArray array]];
      [self refreshCells];
    }
}

- (void) removeAllInstancesOfClass: (NSString *)className
{
  GormClassManager *classManager = [(GormDocument *)document classManager];
  NSMutableArray *removedObjects = [NSMutableArray array];
  NSEnumerator *en = [objects objectEnumerator];
  id object = nil;

  // locate objects for removal
  while((object = [en nextObject]) != nil)
    {
      NSString *clsForObj = [classManager classNameForObject: object];
      if([className isEqual: clsForObj])
	{
	  [removedObjects addObject: object];
	}
    }

  // remove the objects
  [document detachObjects: removedObjects];
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSArray   *pbTypes = nil;
  NSString  *type = nil;
  NSArray   *mgrTypes = nil; 
  
  // Get the resource manager first, if nil don't bother calling the rest...
  dragPb = [sender draggingPasteboard];
  pbTypes = [dragPb types];
  resourceManager = [(GormDocument *)document resourceManagerForPasteboard: dragPb];

  if(resourceManager != nil)
    {
      mgrTypes = [resourceManager resourcePasteboardTypes];
      type = [mgrTypes firstObjectCommonWithArray: pbTypes];
    }

  if (type != nil)
    {
      dragType = type;
    }
  else if ([pbTypes containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
    }
  else if ([pbTypes containsObject: NSFilenamesPboardType] == YES)
    {
      NSArray *data = [dragPb propertyListForType: NSFilenamesPboardType];
      NSString *fileName = [data objectAtIndex: 0];
      NSString *ext = [fileName pathExtension];

      [(GormDocument *)document changeToTopLevelEditorAcceptingTypes: pbTypes
		       andFileType: ext]; 
      dragType = nil;
    }
  else
    {
      dragType = nil;
    }
  
  return [self draggingUpdated: sender];
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  if ([[resourceManager resourcePasteboardTypes] containsObject: dragType]) 
    {
      return NSDragOperationCopy;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      int	r, c;
      int	pos;
      id	obj = nil;

      loc = [self convertPoint: loc fromView: nil];
      [self getRow: &r column: &c forPoint: loc];
      pos = r * [self numberOfColumns] + c;
      if (pos >= 0 && pos < [objects count])
	{
	  obj = [objects objectAtIndex: pos];
	}
      if (obj == [NSApp connectSource])
	{
	  return NSDragOperationNone;	/* Can't drag an object onto itsself */
	}

      [NSApp displayConnectionBetween: [NSApp connectSource] and: obj];
      if (obj != nil)
	{
	  return NSDragOperationLink;
	}

      return NSDragOperationNone;
    }

  return NSDragOperationNone;
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationLink;
}

- (void) drawSelection
{
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString *name = [aNotification name];

  if([name isEqual: GormResizeCellNotification])
    {
      NSDebugLog(@"Recieved notification");
      [self setCellSize: defaultCellSize()];
    }
  else if([name isEqual: IBResourceManagerRegistryDidChangeNotification])
    {
      [IBResourceManager registerForAllPboardTypes: self
			 inDocument: document];
    }
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

  self = [super initWithObject: anObject inDocument: aDocument];
  if (self != nil)
    {
      NSButtonCell	*proto;

      document = aDocument;

      [IBResourceManager registerForAllPboardTypes: self
			 inDocument: document];

      [self setAutosizesCells: NO];
      [self setCellSize: defaultCellSize()];
      [self setIntercellSpacing: NSMakeSize(8,8)];
      [self setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];
      [self setMode: NSRadioModeMatrix];
      /*
       * Send mouse click actions to self, so we can handle selection.
       */
      [self setAction: @selector(changeSelection:)];
      [self setDoubleAction: @selector(raiseSelection:)];
      [self setTarget: self];

      objects = [[NSMutableArray alloc] init];
      proto = [[NSButtonCell alloc] init];
      [proto setBordered: NO];
      [proto setAlignment: NSCenterTextAlignment];
      [proto setImagePosition: NSImageAbove];
      [proto setSelectable: NO];
      [proto setEditable: NO];
      [self setPrototype: proto];
      RELEASE(proto);
      [self setEditor: self
	    forDocument: aDocument];
      [self addObject: anObject];

      // set up the notification...
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(handleNotification:)
	name: GormResizeCellNotification
	object: nil];

      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(handleNotification:)
	name: IBResourceManagerRegistryDidChangeNotification
	object: nil];
    }
  return self;
}

- (void) close
{
  [super close];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  NSMapRemove(docMap,document);
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
  if ([theEvent modifierFlags] & NSControlKeyMask)
    {
      NSPoint	loc = [theEvent locationInWindow];
      NSString	*name;
      int	r = 0, c = 0;
      int	pos = 0;
      id	obj = nil;

      loc = [self convertPoint: loc fromView: nil];
      [self getRow: &r column: &c forPoint: loc];
      pos = r * [self numberOfColumns] + c;
      if (pos >= 0 && pos < [objects count])
	{
	  obj = [objects objectAtIndex: pos];
	}
      if (obj != nil && obj != selected)
	{
	  [self selectObjects: [NSArray arrayWithObject: obj]];
	  [self makeSelectionVisible: YES];
	}
      name = [document nameForObject: obj];
      if ([name isEqualToString: @"NSFirst"] == NO && name != nil)
	{
	  NSPasteboard	*pb;

	  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
	  [pb declareTypes: [NSArray arrayWithObject: GormLinkPboardType]
		     owner: self];
	  [pb setString: name forType: GormLinkPboardType];
	  [NSApp displayConnectionBetween: obj and: nil];

	  [self dragImage: [NSApp linkImage]
		       at: loc
		   offset: NSZeroSize
		    event: theEvent
	       pasteboard: pb
		   source: self
		slideBack: YES];
	  [self makeSelectionVisible: YES];
	  return;
	}
    }

  [super mouseDown: theEvent];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  if ([[resourceManager resourcePasteboardTypes] containsObject: dragType]) 
    {
      [resourceManager addResourcesFromPasteboard: dragPb];
      return YES;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      int	r, c;
      int	pos;
      id	obj = nil;

      loc = [self convertPoint: loc fromView: nil];
      [self getRow: &r column: &c forPoint: loc];
      pos = r * [self numberOfColumns] + c;
      if (pos >= 0 && pos < [objects count])
	{
	  obj = [objects objectAtIndex: pos];
	}
      if (obj == nil)
	{
	  return NO;
	}
      else
	{
	  [NSApp displayConnectionBetween: [NSApp connectSource] and: obj];
	  [NSApp startConnecting];
	  return YES;
	}
    }
  else
    {
      NSLog(@"Drop with unrecognized type!");
      return NO;
    }
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  /*
   * Tell the source that we will accept the drop if we can.
   */
  if ([[resourceManager resourcePasteboardTypes] containsObject: dragType]) 
    {
      /*
       * We can accept objects dropped anywhere.
       */
      return YES;
    }
  else if (dragType == GormLinkPboardType)
    {
      NSPoint	loc = [sender draggingLocation];
      int	r, c;
      int	pos;
      id	obj = nil;

      loc = [self convertPoint: loc fromView: nil];
      [self getRow: &r column: &c forPoint: loc];
      pos = r * [self numberOfColumns] + c;
      if (pos >= 0 && pos < [objects count])
	{
	  obj = [objects objectAtIndex: pos];
	}
      if (obj != nil)
	{
	  return YES;
	}
    }
  return NO;
}

- (id) raiseSelection: (id)sender
{
  id	obj = [self changeSelection: sender];
  id	e;

  if(obj != nil)
    {
      e = [document editorForObject: obj create: YES];
      [e orderFront];
      [e resetObject: obj];
    }

  return self;
}

- (void) resetObject: (id)anObject
{
  NSString		*name = [document nameForObject: anObject];
  GormInspectorsManager	*mgr = [(id<Gorm>)NSApp inspectorsManager];

  if ([name isEqual: @"NSOwner"] == YES)
    {
      [mgr setClassInspector];
    }
  if ([name isEqual: @"NSFirst"] == YES)
    {
      [mgr setClassInspector];
    }
}
@end


