/* GormInternalViewEditor.m
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
#include "GormInternalViewEditor.h"

@class GormEditorToParent;
@class GSWindowView;

static NSImage *verticalImage;
static NSImage *horizontalImage;

#ifndef max
#define max(a,b) ((a) >= (b) ? (a):(b))
#endif

#ifndef min
#define min(a,b) ((a) <= (b) ? (a):(b))
#endif


@implementation NSView (GormObjectAdditions)
- (NSString*) editorClassName
{
  if ([self superview] && 
      (([[self superview] respondsToSelector: @selector(contentView)] &&
	[(id)[self superview] contentView] == self) 
       ||
       [[self superview] isKindOfClass: [NSTabView class]]
       || 
       [[self superview] isKindOfClass: [GSWindowView class]]
       ||
       [[self superview] isKindOfClass: [NSClipView class]]
       ))
    {
      return @"GormInternalViewEditor";
    }
  else
    {
      return @"GormViewEditor";
    }
}
@end


@implementation GormInternalViewEditor


+ (void)initialize
{
  horizontalImage = nil;
  verticalImage = nil;
}

- (void) dealloc
{
  RELEASE(selection);
  [super dealloc];
}


- (BOOL) activate
{
  if (activated == NO)
    {
      NSEnumerator	*enumerator;
      NSView		*sub;
      id  superview = [_editedObject superview];
      
      [self setFrame: [_editedObject frame]];
      [self setBounds: [self frame]];

      if ([superview isKindOfClass: [NSBox class]])
	{
	  NSBox *boxSuperview = (NSBox *) superview;
	  [boxSuperview setContentView: self];
	}
      else if ([superview isKindOfClass: [NSTabView class]])
	{
	  NSTabView *tabSuperview = (NSTabView *) superview;
	  [tabSuperview removeSubview: 
			  [[tabSuperview selectedTabViewItem] view]];
	  [[tabSuperview selectedTabViewItem] setView: self];
	  [tabSuperview addSubview: self];
	  [self setFrame: [tabSuperview contentRect]];
	  [self setAutoresizingMask: 
		  NSViewWidthSizable | NSViewHeightSizable];
	}
      else if ([superview isKindOfClass: [GSWindowView class]])
	{
	  [[superview window] setContentView: self];
	}
      else if ([superview isKindOfClass: [NSClipView class]])
	{
	  [superview setDocumentView: self];
	}

      [self addSubview: _editedObject];
      
      [_editedObject setPostsFrameChangedNotifications: YES];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(editedObjectFrameDidChange:)
	name: NSViewFrameDidChangeNotification
	object: _editedObject];
      
      [self setPostsFrameChangedNotifications: YES];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(frameDidChange:)
	name: NSViewFrameDidChangeNotification
	object: self];

      parent = [document parentEditorForEditor: self];
      
      if ([parent isKindOfClass: [GormViewEditor class]])
	[parent setNeedsDisplay: YES];
      else
	[self setNeedsDisplay: YES];
      activated = YES;



      enumerator = [[NSArray arrayWithArray: [_editedObject subviews]]
		     objectEnumerator];

      while ((sub = [enumerator nextObject]) != nil)
	{
	  if ([sub isKindOfClass: [GormViewEditor class]] == NO)
	    {
	      [document editorForObject: sub
			inEditor: self
			create: YES];
	    }
	}
      return YES;
    }

  return NO;
}

- (void) deactivate
{
  if (activated == YES)
    {
      id superview = [self superview];
      // NSView *superview = [self superview];
      
      [self deactivateSubeditors];
      
      if ([superview isKindOfClass: [NSBox class]])
	{
	  NSBox *boxSuperview = (NSBox *) superview;
	  [self removeSubview: _editedObject];
	  [boxSuperview setContentView: _editedObject];
	}
      else if ([superview isKindOfClass: [NSTabView class]])
	{
	  NSTabView *tabSuperview = (NSTabView *) superview;
	  [tabSuperview removeSubview: self];
	  [[tabSuperview selectedTabViewItem] 
	    setView: _editedObject];
	  [tabSuperview addSubview: 
			  [[tabSuperview selectedTabViewItem] view]];
	  [[[tabSuperview selectedTabViewItem] view] 
	    setFrame: [tabSuperview contentRect]];
	}
      else if ([superview isKindOfClass: [GSWindowView class]])
	{
	  [self removeSubview: _editedObject];
	  [[superview window] setContentView: _editedObject];
	}
      else if ([superview isKindOfClass: [NSClipView class]])
	{
	  [superview setDocumentView: _editedObject];
	}
      [[NSNotificationCenter defaultCenter] removeObserver: self];

    }
  
  activated = NO;
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  opened = NO;
  openedSubeditor = nil;

  if ((self = [super initWithObject: anObject
		     inDocument: aDocument]) == nil)
    return nil;

  selection = [[NSMutableArray alloc] initWithCapacity: 5];
  
  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBViewPboardType, GormLinkPboardType, IBFormatterPboardType, nil]];
  

  if (horizontalImage == nil)
    {
      NSCachedImageRep *rep;
      horizontalImage = [[NSImage allocWithZone:(NSZone *)[(NSObject *)self zone]] 
                          initWithSize: NSMakeSize(3000, 2)];
      rep = [[NSCachedImageRep allocWithZone:
                                  (NSZone *)[(NSObject *)self zone]]
              initWithSize:NSMakeSize(3000, 2)
               depth:[NSWindow defaultDepthLimit] 
               separate:YES 
               alpha:YES];
      
      [horizontalImage addRepresentation: rep];
      RELEASE(rep);
      verticalImage = [[NSImage allocWithZone:(NSZone *)[(NSObject *)self zone]] 
                          initWithSize: NSMakeSize(2, 3000)];
      rep = [[NSCachedImageRep allocWithZone:
                                  (NSZone *)[(NSObject *)self zone]]
              initWithSize:NSMakeSize(2, 3000)
               depth:[NSWindow defaultDepthLimit] 
               separate:YES 
               alpha:YES];
      
      [verticalImage addRepresentation: rep];
      RELEASE(rep);
    }

  return self;
}

- (void) makeSelectionVisible: (BOOL) value
{  
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
	  [result addObject: [[selection objectAtIndex: i] editedObject]];
	}
    }
  else
    {
      return [parent selection];
    }

  return result;
}

- (void) deleteSelection
{
  int i;
  int count = [selection count];
  id temp;
  
  for (i = count - 1; i >= 0; i--)
    {
      temp = [[selection objectAtIndex: i] editedObject];

      [[selection objectAtIndex: i] detachSubviews];
      [document detachObject: temp];
      [[selection objectAtIndex: i] close];

      [temp removeFromSuperview];
      [selection removeObjectAtIndex: i];
    }
  
  [self selectObjects: [NSArray array]];  
}

- (void) mouseDown: (NSEvent *) theEvent
{
  BOOL onKnob = NO;

  {
    if ([parent respondsToSelector: @selector(selection)] &&
	[[parent selection] containsObject: _editedObject])
      {
	IBKnobPosition	knob = IBNoneKnobPosition;
	NSPoint mouseDownPoint = 
	  [self convertPoint: [theEvent locationInWindow]
		fromView: nil];
	knob = GormKnobHitInRect([self bounds], 
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  onKnob = YES;
      }
    if (onKnob == YES)
      {
	if (parent)
	  return [parent mouseDown: theEvent];
	else
	  return [self noResponderFor: @selector(mouseDown:)];
      }
  }
  
  {
    if ([parent isOpened] == NO)
      {
	NSDebugLog(@"md %@ calling my parent %@", self, parent);
	[parent mouseDown: theEvent];
	return;
      }
  }

  // are we on the knob of a selected view ?
  {
    int count = [selection count];
    int i;
    GormViewEditor *knobView = nil;
    IBKnobPosition	knob = IBNoneKnobPosition;
    NSPoint mouseDownPoint;

    for ( i = 0; i < count; i++ )
      {
	mouseDownPoint = [[[selection objectAtIndex: i] superview] 
			   convertPoint: [theEvent locationInWindow]
			   fromView: nil];

	knob = GormKnobHitInRect([[selection objectAtIndex: i] frame], 
				 mouseDownPoint);
	  
	if (knob != IBNoneKnobPosition)
	  {
	    knobView = [selection objectAtIndex: i];
	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
	    // we should set knobView as the only view selected
	    break;
	  }
      }
    
    if ( openedSubeditor != nil )
      {
	mouseDownPoint = [[openedSubeditor superview] 
			   convertPoint: [theEvent locationInWindow]
			   fromView: nil];

	knob = GormKnobHitInRect([openedSubeditor frame], 
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  {
	    knobView = openedSubeditor;
	    // we should take back the selection
	    // we should select openedSubeditor only
	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
	    [[self window] disableFlushWindow];
	    [self display];
	    [[self window] enableFlushWindow];
	    [[self window] flushWindow];
	  }
      }


    if (knobView != nil)
      {
	[self handleMouseOnKnob: knob
	      ofView: knobView
	      withEvent: theEvent];
	[self setNeedsDisplay: YES];
	return;
      }
  }

  {
    GormViewEditor *editorView;

    // get the view we are on
    {
      NSPoint mouseDownPoint;
      NSView *result = nil;
      GormViewEditor *theParent = nil;
      
      mouseDownPoint = [self
			 convertPoint: [theEvent locationInWindow]
			 fromView: nil];
      
      result = [_editedObject hitTest: mouseDownPoint];
      
      // we should get a result which is a direct subeditor
      {
	id temp = result;

	if ([temp isKindOfClass: [GormViewEditor class]])
	  theParent = [(GormViewEditor *)temp parent];
	while ((temp != nil) && (theParent != self) && (temp != self))
	  {
	    temp = [temp superview];
	    while (![temp isKindOfClass: [GormViewEditor class]])
	      {
		temp = [temp superview];
	      }
	    theParent = [(GormViewEditor *)temp parent];
	  }
	if (temp != nil)
	  {
	    result = temp;
	  }
	else
	  {
	    NSLog(@"WARNING -- strange case");
	    result = self;
	  }
      }


      if ([result isKindOfClass: [GormViewEditor class]])
	{
	}
      else
	{
	  result = nil;
	}

      // this is the direct subeditor the mouse was clicked on
      // (or self)
      editorView = (GormViewEditor *)result;
    }

    if (([theEvent clickCount] == 2) 
	&& [editorView isKindOfClass: [GormViewWithSubviewsEditor class]]
	&& ([(id)editorView canBeOpened] == YES)
	&& (editorView != self))
      // Let's open a subeditor       
      {
	[(GormViewWithSubviewsEditor *) editorView setOpened: YES];
	[self silentlyResetSelection];
	openedSubeditor = (GormViewWithSubviewsEditor *) editorView;
	[self setNeedsDisplay: YES];
	return;
      }

    if (editorView != self)
      {
	[self handleMouseOnView: editorView
	      withEvent: theEvent];
      }
    else // editorView == self
      {
	NSEvent *e;
	unsigned eventMask;
	NSDate *future = [NSDate distantFuture];
	NSRect oldRect = NSZeroRect;
	NSPoint p, oldp;
	NSRect r = NSZeroRect;
	float x, y, w, h;
	
	oldp = [self convertPoint: [theEvent locationInWindow] fromView: nil];

	eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask;

	
	if (!([theEvent modifierFlags] & NSShiftKeyMask))
	  [self selectObjects: [NSMutableArray array]];
	[[self window] disableFlushWindow];
	[self setNeedsDisplay: YES];
	[self displayIfNeeded];
	[[self window] enableFlushWindow];
	[[self window] flushWindowIfNeeded];

	e = [NSApp nextEventMatchingMask: eventMask
		   untilDate: future
		   inMode: NSEventTrackingRunLoopMode
		   dequeue: YES];
	[self lockFocus];
	while ([e type] != NSLeftMouseUp)
	  {
	    p = [self convertPoint: [e locationInWindow] fromView: nil];
	    
	    x = (p.x >= oldp.x) ? oldp.x : p.x;
	    y = (p.y >= oldp.y) ? oldp.y : p.y;
	    w = max(p.x, oldp.x) - min(p.x, oldp.x);
	    w = (w == 0) ? 1 : w;
	    h = max(p.y, oldp.y) - min(p.y, oldp.y);
	    h = (h == 0) ? 1 : h;
	    
	    r = NSMakeRect(x, y, w, h);

	    if (NSEqualRects(oldRect, NSZeroRect) == NO)
	      {
		[verticalImage 
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMinY(oldRect))
		  fromRect: NSMakeRect(0.0, 0.0, 1.0, oldRect.size.height)
		  operation: NSCompositeCopy];
		[verticalImage
		  compositeToPoint: NSMakePoint(NSMaxX(oldRect)-1, NSMinY(oldRect))
		  fromRect: NSMakeRect(1.0, 0.0, 1.0, oldRect.size.height)
		  operation: NSCompositeCopy];
		
		[horizontalImage 
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMinY(oldRect))
		  fromRect: NSMakeRect(0.0, 0.0, oldRect.size.width, 1.0)
		  operation: NSCompositeCopy];
		[horizontalImage
		  compositeToPoint: NSMakePoint(NSMinX(oldRect), NSMaxY(oldRect)-1)
		  fromRect: NSMakeRect(0.0, 1.0, oldRect.size.width, 1.0)
		  operation: NSCompositeCopy];
	      }

	    {
	      NSRect wr;
	      wr = [self convertRect: r
			 toView: nil];
	      
	      [verticalImage lockFocus];
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMinY(wr),
				    1.0, r.size.height),
			 NSMakePoint(0.0, 0.0));
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMaxX(wr)-1, NSMinY(wr),
				    1.0, r.size.height),
			 NSMakePoint(1.0, 0.0));
	      [verticalImage unlockFocus];

	      [horizontalImage lockFocus];
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMinY(wr),
				    r.size.width, 1.0),
			 NSMakePoint(0.0, 0.0));
	      NSCopyBits([[self window] gState],
			 NSMakeRect(NSMinX(wr), NSMaxY(wr)-1,
				    r.size.width, 1.0),
			 NSMakePoint(0.0, 1.0));
	      [horizontalImage unlockFocus];
	    }
	    
	    [[NSColor darkGrayColor] set];
	    NSFrameRect(r);
	    oldRect = r;
	    
	    [[self window] enableFlushWindow];
	    
	    [[self window] flushWindow];
	    [[self window] disableFlushWindow];


	    e = [NSApp nextEventMatchingMask: eventMask
		       untilDate: future
		       inMode: NSEventTrackingRunLoopMode
		       dequeue: YES];
	  }

	if (NSEqualRects(r, NSZeroRect) == NO)
	  {
	    [verticalImage 
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMinY(r))
	      fromRect: NSMakeRect(0.0, 0.0, 1.0, r.size.height)
	      operation: NSCompositeCopy];
	    [verticalImage
	      compositeToPoint: NSMakePoint(NSMaxX(r)-1, NSMinY(r))
	      fromRect: NSMakeRect(1.0, 0.0, 1.0, r.size.height)
	      operation: NSCompositeCopy];
	    
	    [horizontalImage 
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMinY(r))
	      fromRect: NSMakeRect(0.0, 0.0, r.size.width, 1.0)
	      operation: NSCompositeCopy];
	    [horizontalImage
	      compositeToPoint: NSMakePoint(NSMinX(r), NSMaxY(r)-1)
	      fromRect: NSMakeRect(0.0, 1.0, r.size.width, 1.0)
	      operation: NSCompositeCopy];
	  }


	{
	  NSMutableArray *array;
	  NSEnumerator *enumerator;
	  NSView *subview;


	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    array = [NSMutableArray arrayWithArray: selection];
	  else
	    array = [NSMutableArray arrayWithCapacity: 8];
	  enumerator = [[_editedObject subviews] objectEnumerator];
	  while ((subview = [enumerator nextObject]) != nil)
	    {
	      if ((NSIntersectsRect(r, [subview frame]) == YES)
		  && [subview isKindOfClass: [GormViewEditor class]])
		{
		  [array addObject: subview];
		}
	    }

	  if ([array count] > 0)
	    {
	      [self selectObjects: array];
	    }
	  [self displayIfNeeded];
	  
	  [self unlockFocus];
	  [[self window] enableFlushWindow];
	  
	  [[self window] flushWindow];
	}

      }
    
  }
}



- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSRect rect = [_editedObject bounds];
  NSPoint loc = [sender draggingLocation];
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  loc = [_editedObject convertPoint: loc fromView: nil];

  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return [parent draggingEntered: sender];
    }

  if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
    {
      return NSDragOperationNone;
    }
  else
    {
      rect.origin.x += 3;
      rect.origin.y += 2;
      rect.size.width -= 5;
      rect.size.height -= 5;
      
      [_editedObject lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [_editedObject unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}

- (void) draggingExited: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  NSRect         rect;

  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      [parent draggingExited: sender];
      return;
    }


  rect = [_editedObject bounds];
  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;
 
  rect.origin.x --;
  rect.size.width ++;
  rect.size.height ++;

  [[self window] disableFlushWindow];
  [self displayRect: 
	  [_editedObject convertRect: rect
			 toView: self]];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
}

- (unsigned int) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPoint loc = [sender draggingLocation];
  NSRect rect = [_editedObject bounds];
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  loc = [_editedObject 
	  convertPoint: loc fromView: nil];

  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return [parent draggingUpdated: sender];
    }

  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;

  if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
    {
      [[self window] disableFlushWindow];
      rect.origin.x --;
      rect.size.width ++;
      rect.size.height ++;
      [self displayRect: 
	      [_editedObject convertRect: rect
			     toView: self]];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      return NSDragOperationNone;
    }
  else
    {
      [_editedObject lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [_editedObject unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}


- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  NSString		*dragType;
  NSArray *types;
  NSPasteboard		*dragPb;

  dragPb = [sender draggingPasteboard];

  types = [dragPb types];
  
  if ([types containsObject: IBViewPboardType] == YES)
    {
      dragType = IBViewPboardType;
    }
  else if ([types containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
      return [parent prepareForDragOperation: sender];
    }
  else if ([types containsObject: IBFormatterPboardType] == YES)
    {
      dragType = IBFormatterPboardType;
    }
  else
    {
      dragType = nil;
    }

  if (dragType == IBViewPboardType)
    {
      /*
       * We can accept views dropped anywhere.
       */
      NSPoint		loc = [sender draggingLocation];
      loc = [_editedObject  
	      convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
	{
	  return NO;
	}
      
      return YES;
    }
  
  return NO;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSString		*dragType;
  NSPasteboard		*dragPb;
  NSArray *types;

  dragPb = [sender draggingPasteboard];

  types = [dragPb types];
  
  if ([types containsObject: IBViewPboardType] == YES)
    {
      dragType = IBViewPboardType;
    }
  else if ([types containsObject: GormLinkPboardType] == YES)
    {
      dragType = GormLinkPboardType;
    }
  else if ([types containsObject: IBFormatterPboardType] == YES)
    {
      dragType = IBFormatterPboardType;
    }
  else
    {
      dragType = nil;
    }

  if (dragType == IBViewPboardType)
    {
      NSPoint		loc = [sender draggingLocation];
      NSArray		*views;
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
       * Ask the document to get the dragged views from the pasteboard and add
       * them to it's collection of known objects.
       */
      views = [document pasteType: IBViewPboardType
		   fromPasteboard: dragPb
			   parent: _editedObject];
      /*
       * Now make all the views subviews of ourself, setting their origin to
       * be the point at which they were dropped (converted from window
       * coordinates to our own coordinates).
       */
      loc = [_editedObject convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_editedObject bounds], NO) == NO)
	{
	  // Dropped outside our view frame
	  NSLog(@"Dropped outside current edit view");
	  dragType = nil;
	  return NO;
	}
      enumerator = [views objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  NSRect	rect = [sub frame];
	  
	  rect.origin = [_editedObject
			  convertPoint: [sender draggedImageLocation]
			  fromView: nil];
	  rect.origin.x = (int) rect.origin.x;
	  rect.origin.y = (int) rect.origin.y;
	  rect.size.width = (int) rect.size.width;
	  rect.size.height = (int) rect.size.height;
	  [sub setFrame: rect];

	  [_editedObject addSubview: sub];
	  
	  {
	    id editor;
	    editor = [document editorForObject: sub 
			       inEditor: self 
			       create: YES];
	    [self selectObjects: 
		    [NSArray arrayWithObject: editor]];
	  }
	}
      // FIXME  we should maybe open ourself
    }

  return YES;
}

- (void) pasteInSelection
{
  [self pasteInView: _editedObject];
}

@class GormBoxEditor;
@class GormSplitViewEditor;

- (NSArray *)destroyAndListSubviews
{
  if ([parent isKindOfClass: [GormBoxEditor class]]
      && 
      ([[parent parent] isKindOfClass: 
			    [GormViewWithContentViewEditor class]]
       || [[parent parent] isKindOfClass: 
			     [GormSplitViewEditor class]]))
    {
      NSEnumerator *enumerator = [[_editedObject subviews] objectEnumerator];
      GormViewEditor *subview;
      NSMutableArray *newSelection = [NSMutableArray array];

      [[parent parent] makeSubeditorResign];

      while ((subview = [enumerator nextObject]) != nil)
	{
	  id v;
	  NSRect frame;
	  v = [subview editedObject];
	  frame = [v frame];
	  frame = [[parent parent] convertRect: frame
				   fromView: _editedObject];
	  [subview deactivate];
	  
	  [v setFrame: frame];
	  [newSelection addObject: v];
	}

      {
	id thisView = [parent editedObject];
	[parent close];
	[thisView removeFromSuperview];

      }
      
      return newSelection;
    }
  return nil;
}

- (void) deleteSelection: (id) sender
{
  [self deleteSelection];
}
@end
