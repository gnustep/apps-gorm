/* GormBoxEditor.m
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


#import <AppKit/AppKit.h>

#import "GormPrivate.h"

#import "GormBoxEditor.h"

#import "GormInternalViewEditor.h"

#define _EO ((NSBox *)_editedObject)

@class GormWindowEditor;

@implementation NSBox (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormBoxEditor";
}
@end



@implementation GormBoxEditor

- (void) setOpened: (BOOL) flag
{
  [super setOpened: flag];
  if (flag == YES)
    {  
      [document setSelectionFromEditor: contentViewEditor];
    }
}

- (void) dealloc
{
  RELEASE(selection);
  [super dealloc];
}


- (BOOL) activate
{
  if ([super activate])
    {
      NSView *contentView = [_EO contentView];

      contentViewEditor = [document editorForObject: contentView
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

  
  return self;
}



- (void) makeSelectionVisible: (BOOL) value
{
  
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


  // if we are on one of our own knob, then this event should be processed
  // by our parent (cause this is a resizing event)
  {
    if ([parent respondsToSelector: @selector(selection)] &&
	[[parent selection] containsObject: _EO])
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

  if (opened == NO)
    {
//        NSLog(@"GormBoxEditor not opened");
      [super mouseDown: theEvent];
      return;
    }


  if ([[_EO hitTest: [theEvent locationInWindow]]
	isDescendantOf: contentViewEditor])
    {
//        NSLog(@"md %@ descendant of", self);
      if ([contentViewEditor isOpened] == NO)
	[contentViewEditor setOpened: YES];
      [contentViewEditor mouseDown: theEvent];
    }
  else
    {      
//        NSLog(@"md %@ not descendant of sending to %@", self, _EO);
      if ([contentViewEditor isOpened] == YES)
	[contentViewEditor setOpened: NO];
      
      if ((NSMouseInRect([_EO convertPoint: [theEvent locationInWindow]
			     fromView: nil], 
			[_EO titleRect], NO) == YES)
	  && ([theEvent clickCount] == 2))
	{
	  NSTextField *tf = 
	    [[NSTextField alloc] initWithFrame: 
				   [self convertRect: [_EO titleRect]
					 fromView: _EO]];
	  NSRect frame = [tf frame];
	  frame.origin.x = [self bounds].origin.x + 3;
	  frame.size.width = [self bounds].size.width - 6;
	  frame.origin.y -= 3;
	  frame.size.height += 4;
	  [tf setBordered: YES];
	  [tf setEditable: YES];
	  [tf setBezeled: NO];
	  [tf setAlignment: NSCenterTextAlignment];
	  [tf setFrame: frame];
	  [self addSubview: tf];
	  [tf setStringValue: [_EO title]];
	  [self editTextField: tf
		withEvent: theEvent];
	  [_EO setTitle: [tf stringValue]];
	  [tf removeFromSuperview];
	  RELEASE(tf);
	  [[NSNotificationCenter defaultCenter] 
	    postNotificationName: IBSelectionChangedNotification
	    object: self];

	}
    }

  

  // the following code did job that is now done by GormInternalViewEditor

//    // are we on the knob of a selected view ?
//    {
//      int count = [selection count];
//      int i;
//      GormViewEditor *knobView = nil;
//      IBKnobPosition	knob = IBNoneKnobPosition;
//      NSPoint mouseDownPoint;

//      for ( i = 0; i < count; i++ )
//        {
//  	mouseDownPoint = [[[selection objectAtIndex: i] superview] 
//  			   convertPoint: [theEvent locationInWindow]
//  			   fromView: nil];

//  	knob = GormKnobHitInRect([[selection objectAtIndex: i] frame], 
//  				 mouseDownPoint);
	  
//  	if (knob != IBNoneKnobPosition)
//  	  {
//  	    knobView = [selection objectAtIndex: i];
//  	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
//  	    // we should set knobView as the only view selected
//  	    break;
//  	  }
//        }
    
//      NSLog(@"md %@ openedSubeditor %@", self, openedSubeditor);
//      if ( openedSubeditor != nil )
//        {
//  	mouseDownPoint = [[openedSubeditor superview] 
//  			   convertPoint: [theEvent locationInWindow]
//  			   fromView: nil];

//  	NSLog(@"md %@ %@ %@", self, NSStringFromPoint(mouseDownPoint),
//  	      NSStringFromRect([openedSubeditor frame]));

//  	knob = GormKnobHitInRect([openedSubeditor frame], 
//  				 mouseDownPoint);
//  	if (knob != IBNoneKnobPosition)
//  	  {
//  	    NSLog(@"md %@ on knob !", self);
//  	    knobView = openedSubeditor;
//  	    // we should take back the selection
//  	    // we should select openedSubeditor only
//  	    [self selectObjects: [NSMutableArray arrayWithObject: knobView]];
//  	    [[self window] disableFlushWindow];
//  	    [self display];
//  	    [[self window] enableFlushWindow];
//  	    [[self window] flushWindow];
//  	  }
//        }


//      if (knobView != nil)
//        {
//  	[self handleMouseOnKnob: knob
//  	      ofView: knobView
//  	      withEvent: theEvent];
//  	//	NSLog(@"resize %@", knobView);
//  	[self setNeedsDisplay: YES];
//  	return;
//        }
//    }



//    {
//      GormViewEditor *editorView;

//      // get the view we are on
//      {
//        NSPoint mouseDownPoint;
//        NSView *result;

      
//        mouseDownPoint = [self convertPoint: [theEvent locationInWindow]
//  			     fromView: nil];
      
//        result = [_editedObject hitTest: mouseDownPoint];

      
//        NSLog(@"md %@ result %@", self, result);
//        // we should get a result which is a direct subeditor
//        {
//  	id temp = result;
//  	GormViewEditor *parent = [document parentEditorForEditor: temp];

//  	NSLog(@"md %@ parent %@", self, parent);
//  	while ((temp != nil) && (parent != self) && (temp != self))
//  	  {
//  	    NSLog(@"md %@ temp = %@", self, temp);
//  	    temp = [temp superview];
//  	    while (![temp isKindOfClass: [GormViewEditor class]])
//  	      {
//  		NSLog(@"md %@ temp = %@", self, temp);
//  		temp = [temp superview];
//  	      }
//  	    NSLog(@"md %@ temp = %@", self, temp);
//  	    parent = [document parentEditorForEditor: temp];
//  	  }
//  	NSLog(@"md %@ temp = %@", self, temp);
//  	if (temp != nil)
//  	  {
//  	    result = temp;
//  	  }
//  	else
//  	  {
//  	    NSLog(@"WARNING -- strange case");
//  	    result = self;
//  	  }
//        }


//        if ([result isKindOfClass: [GormViewEditor class]])
//  	{
//  	  /*
//  	  if (result != self)
//  	    {
//  	      [self selectObjects: [NSMutableArray arrayWithObject: result]];
//  	    }
//  	  else
//  	    {
//  	      [self selectObjects: [NSMutableArray array]];
//  	    }
//  	  [[self window] disableFlushWindow];
//  	  [self display];
//  	  [[self window] enableFlushWindow];
//  	  [[self window] flushWindow];
//  	  NSLog(@"clicked on %@", result);
//  	  */
//  	}
//        else
//  	{
//  	  NSLog(@"md %@ result = nil", self);
//  	  result = nil;
//  	}

//        editorView = result;
//      }

//      if (([theEvent clickCount] == 2) 
//  	&& [editorView respondsToSelector: @selector(canBeOpened)]
//  	&& ([editorView canBeOpened] == YES)
//  	&& (editorView != self))
       
//        {
//  	[editorView setOpened: YES];
//  	[self silentlyResetSelection];
//  	openedSubeditor = editorView;
//  	[self setNeedsDisplay: YES];
//  	NSLog(@"md %@ editor should open", self);
//  	return;
//        }

//      if (editorView != self)
//        [self handleMouseOnView: editorView
//  	    withEvent: theEvent];
//      else // editorView == self
//        {
//  	[self selectObjects: [NSMutableArray array]];
//  	[self setNeedsDisplay: YES];
//        }
	  
//    }


  /*
  // are we on a selected view ?
  {
    int count = [selection count];
    int i;
    BOOL inView = NO;
    NSPoint mouseDownPoint;
    

    for ( i = 0; i < count; i++ )
      {
	mouseDownPoint = [[[selection objectAtIndex: i] superview] 
			   convertPoint: [theEvent locationInWindow]
			   fromView: nil];

	if ([[[selection objectAtIndex: i] superview] 
	      mouse: mouseDownPoint
	      inRect: [[selection objectAtIndex: i] frame]])
	  {
	    inView = YES;
	    break;
	  }
      }

    if (inView)
      {
	NSLog(@"inside %@", [selection objectAtIndex: i]);
	return;
      }
  }
  */
  // are we on a view ?
  
}



- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSRect rect = [[_EO contentView] bounds];
  NSPoint loc = [sender draggingLocation];
  loc = [[_EO contentView] 
	  convertPoint: loc fromView: nil];

  if (NSMouseInRect(loc, [[_EO contentView] bounds], NO) == NO)
    {
      return NSDragOperationNone;
    }
  else
    {
      rect.origin.x += 2;
      rect.origin.y += 2;
      rect.size.width -= 4;
      rect.size.height -= 4;
      
      [[_EO contentView] lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [[_EO contentView] unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}

- (void) draggingExited: (id<NSDraggingInfo>)sender
{
  NSRect rect = [[_EO contentView] bounds];
  rect.origin.x += 2;
  rect.origin.y += 2;
  rect.size.width -= 4;
  rect.size.height -= 4;
 
  rect.origin.x --;
  rect.size.width ++;
  rect.size.height ++;

  [[self window] disableFlushWindow];
  [self displayRect: 
	  [[_EO contentView] convertRect: rect
				       toView: self]];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
}

- (unsigned int) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPoint loc = [sender draggingLocation];
  NSRect rect = [[_EO contentView] bounds];
  loc = [[_EO contentView] 
	  convertPoint: loc fromView: nil];

  rect.origin.x += 2;
  rect.origin.y += 2;
  rect.size.width -= 4;
  rect.size.height -= 4;

  if (NSMouseInRect(loc, [[_EO contentView] bounds], NO) == NO)
    {
      [[self window] disableFlushWindow];
      rect.origin.x --;
      rect.size.width ++;
      rect.size.height ++;
      [self displayRect: 
	      [[_EO contentView] convertRect: rect
					   toView: self]];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      return NSDragOperationNone;
    }
  else
    {
      [[_EO contentView] lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [[_EO contentView] unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}


- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  NSString		*dragType;
  NSArray *types;
  NSPasteboard		*dragPb;

  NSLog(@"prepareForDragOperation called");

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
      /*
       * We can accept views dropped anywhere.
       */
      NSPoint		loc = [sender draggingLocation];
      loc = [[_EO contentView] 
	      convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_EO bounds], NO) == NO)
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
      //      NSArray           *array = [NSMutableArray array];
      NSEnumerator	*enumerator;
      NSView		*sub;

      /*
      if (opened != YES)
	{
	  NSLog(@"make ourself the editor");
	}
      else if (openedSubeditor != nil)
	{
	  NSLog(@"close our subeditors");
	}
      */

      /*
       * Ask the document to get the dragged views from the pasteboard and add
       * them to it's collection of known objects.
       */
      views = [document pasteType: IBViewPboardType
		   fromPasteboard: dragPb
			   parent: _EO];
      /*
       * Now make all the views subviews of ourself, setting their origin to
       * be the point at which they were dropped (converted from window
       * coordinates to our own coordinates).
       */
      loc = [[_EO contentView] 
	      convertPoint: loc fromView: nil];
      if (NSMouseInRect(loc, [_EO bounds], NO) == NO)
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
	  
	  rect.origin = [[_EO contentView] 
			  convertPoint: [sender draggedImageLocation]
			  fromView: nil];
	  rect.origin.x = (int) rect.origin.x;
	  rect.origin.y = (int) rect.origin.y;
	  rect.size.width = (int) rect.size.width;
	  rect.size.height = (int) rect.size.height;
	  [sub setFrame: rect];

	  [[_EO contentView] addSubview: sub];
	  
	  [self selectObjects: 
		  [NSArray arrayWithObject: 
			     [document editorForObject: sub 
				       inEditor: self 
				       create: YES]]];
	}
      // FIXME  we should maybe open ourself
    }

  return YES;
}


//  - (void) pasteInSelection
//  {
//    [self pasteInView: [_EO contentView]];
//  }

- (NSArray *)destroyAndListSubviews
{
  if (contentViewEditor)
    {
      return [contentViewEditor destroyAndListSubviews];
    }
  else
    {
      return nil;
    }
}

@end
