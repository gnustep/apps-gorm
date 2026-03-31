/* GormViewWithContentViewEditor.m
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
 * the Free Software Foundation; either version 3 of the License, or
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

#import <AppKit/AppKit.h>

#import "GormPrivate.h"
#import "GormViewWithContentViewEditor.h"
#import "GormPlacementInfo.h"
#import "GormSplitViewEditor.h"
#import "GormViewKnobs.h"
#import "GormInternalViewEditor.h"
#import "GormDocument.h"
#import "GormGroupProtocol.h"
#import "GormGroupViews.h"

@interface GormViewEditor (Private)
- (NSRect) _displayMovingFrameWithHint: (NSRect) frame
                     andPlacementInfo: (GormPlacementInfo *)gpi;
@end

@implementation GormViewWithContentViewEditor

- (id) initWithObject: (id) anObject
  	   inDocument: (id<IBDocuments>)aDocument
{
  _displaySelection = YES;
  //GuideLine
  [[NSNotificationCenter defaultCenter] addObserver:self 
					selector:@selector(guideline:)
					name: GormToggleGuidelineNotification
					object:nil];
  _followGuideLine = YES;
  self = [super initWithObject: anObject
		inDocument: aDocument];
  return self;
}

-(void) guideline:(NSNotification *)notification
{
  if ( _followGuideLine )
    _followGuideLine = NO;
  else 
    _followGuideLine = YES;
}



- (void) moveSelectionByX: (float)x 
		     andY: (float)y
{
  NSInteger i;
  NSInteger count = [selection count];

  for (i = 0; i < count; i++)
    {
      id v = [selection objectAtIndex: i];
      NSRect f = [v frame];
      
      f.origin.x += x;
      f.origin.y += y;

      [v setFrameOrigin: f.origin];
    }
}

- (void) resizeSelectionByX: (float)x 
		       andY: (float)y
{
  NSInteger i;
  NSInteger count = [selection count];

  for (i = 0; i < count; i++)
    {
      id v = [selection objectAtIndex: i];
      NSRect f = [v frame];
      
      f.size.width += x;
      f.size.height += y;

      [v setFrameSize: f.size];
    }
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = 0;
  float moveBy = 1.0;

  if ([characters length] > 0)
    {
      character = [characters characterAtIndex: 0];
    }

  if (([theEvent modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask)
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  moveBy = 10.0;
	}
      
      if ([selection count] == 1)
	{
	  switch (character)
	    {
	    case NSUpArrowFunctionKey:
	      [self resizeSelectionByX: 0 andY: 1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSDownArrowFunctionKey:
	      [self resizeSelectionByX: 0 andY: -1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSLeftArrowFunctionKey:
	      [self resizeSelectionByX: -1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSRightArrowFunctionKey:
	      [self resizeSelectionByX: 1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
    }
  else
    {
      if (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
	  moveBy = 10.0;
	}
      
      if ([selection count] > 0)
	{
	  switch (character)
	    {
	    case NSUpArrowFunctionKey:
	      [self moveSelectionByX: 0 andY: 1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSDownArrowFunctionKey:
	      [self moveSelectionByX: 0 andY: -1*moveBy];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSLeftArrowFunctionKey:
	      [self moveSelectionByX: -1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    case NSRightArrowFunctionKey:
	      [self moveSelectionByX: 1*moveBy andY: 0];
	      [self setNeedsDisplay: YES];
	      return;
	    }
	}
    }
  [super keyDown: theEvent];

}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  if ([super acceptsTypeFromArray: types])
    {
      return YES;
    }
  else
    {
      return [types containsObject: IBViewPboardType];
    }
}

- (void) postDrawForView: (GormViewEditor *) viewEditor
{
  if (_displaySelection == NO)
    {
      return;
    }
  if (((id)openedSubeditor == (id)viewEditor) 
      && (openedSubeditor != nil)
      && ![openedSubeditor isKindOfClass: [GormInternalViewEditor class]])
    {
      GormDrawOpenKnobsForRect([viewEditor bounds]);
      GormShowFastKnobFills();
    }
  else if ([selection containsObject: viewEditor])
    {
      GormDrawKnobsForRect([viewEditor bounds]);
      GormShowFastKnobFills();
    }
}

- (void) postDraw: (NSRect) rect
{
  [super postDraw: rect];

  if (openedSubeditor 
      && ![openedSubeditor isKindOfClass: [GormInternalViewEditor class]])
    {
      GormDrawOpenKnobsForRect(
			       [self convertRect: [openedSubeditor bounds]
				     fromView: openedSubeditor]);
      GormShowFastKnobFills();
    }
  else if (_displaySelection)
    {
      NSInteger i;
      NSInteger count = [selection count];

      for ( i = 0; i < count ; i++ )
	{
	  GormDrawKnobsForRect([self convertRect:
				       [[selection objectAtIndex: i] bounds]
				     fromView: [selection objectAtIndex: i]]);
	  GormShowFastKnobFills();
	}
    }

}

- (NSArray *) editedViewsFromSelection
{
  NSMutableArray *sel = [NSMutableArray arrayWithCapacity: [selection count]];
  NSEnumerator *en = [selection objectEnumerator];
  id e = nil;

  while ((e = [en nextObject]) != nil)
    {
      id v = [e editedObject];
      [e deactivate];
      [sel addObject: v];
    }

  return sel;
}

- (NSRect) computeBoundingRectForViews: (NSArray *)views
{
  NSRect boundingRect = NSZeroRect;
  NSEnumerator *en = [views objectEnumerator];
  id view = nil;
  
  while ((view = [en nextObject]) != nil)
    {
      if ([view isKindOfClass: [NSView class]])
        {
          NSRect viewFrame = [view frame];
          if (NSIsEmptyRect(boundingRect))
            {
              boundingRect = viewFrame;
            }
          else
            {
              boundingRect = NSUnionRect(boundingRect, viewFrame);
            }
        }
    }
    
  return boundingRect;
}

- (void) groupSelectionInView: (id)view
{
  // Validate count...
  if ([view respondsToSelector: @selector(validateCount:)])
    {
      if (![view validateCount: [selection count]])
        {
          return;
        }
    }

  NSArray *viewSelection = [self editedViewsFromSelection];

  // Compute rect...
  NSRect rect = NSZeroRect;
  if ([view respondsToSelector: @selector(computeRectForViews:)])
    {
      rect = [view computeRectForViews: viewSelection];
    }
  else
    {
      // Fallback: compute bounding rect manually
      rect = [self computeBoundingRectForViews: viewSelection];
    }
  [view setFrame: rect];

  // Order views...
  NSArray *sortedViews = [view orderSelectionForViews: viewSelection];
  
  // Add back into the main view...
  NSEnumerator *en = [sortedViews objectEnumerator];
cts...
  [document attachObject: view 
		toParent: _editedObject];

  // Select objects...
  [self selectObjects: [NSArray arrayWithObject: view]];
}

- (void) groupSelectionInSplitView
{
  [self groupSelectionInView: [[NSSplitView alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInBox
{
  NSEnumerator *enumerator = nil;
  NSMutableArray *viewsToGroup = [NSMutableArray array];
  NSMutableArray *editorsToClose = [NSMutableArray array];
  NSBox *box = nil;
  NSRect unionRect = NSZeroRect;
  GormViewEditor *editor = nil;
  NSView *parentView = nil;
  NSView *contentView = nil;

  if ([selection count] < 1)
    {
      return;
    }

  // First pass: collect actual NSView instances and compute the union rect
  enumerator = [selection objectEnumerator];
  GormViewEditor *subviewEditor = nil;
  while ((subviewEditor = [enumerator nextObject]) != nil)
    {
      NSView *childView = [subviewEditor editedObject];

      if (parentView == nil)
        {
          parentView = [childView superview];
        }
      else if (parentView != [childView superview])
        {
          return;
        }

      unionRect = NSUnionRect(unionRect, [childView frame]);
      [viewsToGroup addObject: childView];
      [editorsToClose addObject: subviewEditor];
      [subviewEditor deactivate];
    }

  box = [[NSBox alloc] initWithFrame: unionRect];
  [document attachObject: box toParent: _editedObject];
  [parentView addSubview: box];
  contentView = [box contentView];

  editor = (GormViewEditor *)[document editorForObject: box
                                             inEditor: self
                                               create: YES];

  NSRect contentFrame = [contentView frame];

  // Move each child into the box's content view, adjusting its origin
  for (NSView *childView in viewsToGroup)
    {
      NSRect frame = [childView frame];

      // Update the parent connector to point to the new box
      NSArray *old = [document connectorsForSource: childView
                                           ofClass: [NSNibConnector class]];
      if ([old count] > 0)
        {
          [[old objectAtIndex: 0] setDestination: box];
        }

      [childView removeFromSuperview];
      [contentView addSubview: childView];

      // Adjust position relative to contentView origin
      frame.origin.x -= unionRect.origin.x;
      frame.origin.y -= unionRect.origin.y;
      frame.origin.x -= contentFrame.origin.x;
      frame.origin.y -= contentFrame.origin.y;
      [childView setFrame: frame];

      [document editorForObject: childView
                       inEditor: editor
                         create: YES];
    }

  // Close the old editors for the grouped views
  for (id editorToClose in editorsToClose)
    {
      [editorToClose close];
    }

  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInView
{
  NSEnumerator *enumerator = nil;
  NSMutableArray *viewsToGroup = [NSMutableArray array];
  NSMutableArray *editorsToClose = [NSMutableArray array];
  NSView *containerView = nil;
  NSView *parentView = nil;
  NSRect unionRect = NSZeroRect;
  GormViewEditor *editor = nil;

  if ([selection count] < 1)
    {
      return;
    }
  
  // First pass: collect the actual NSView instances and compute the union rect
  enumerator = [selection objectEnumerator];
  GormViewEditor *subviewEditor = nil;
  while ((subviewEditor = [enumerator nextObject]) != nil)
    {
      NSView *childView = [subviewEditor editedObject];

      // Keep a consistent parent; if selection spans multiple parents, bail out
      if (parentView == nil)
        {
          parentView = [childView superview];
        }
      else if (parentView != [childView superview])
        {
          return;
        }

      unionRect = NSUnionRect(unionRect, [childView frame]);
      [viewsToGroup addObject: childView];
      [editorsToClose addObject: subviewEditor];
      [subviewEditor deactivate];
    }

  // Create the container view covering the union rect in parent coordinates
  containerView = [[NSView alloc] initWithFrame: unionRect];

  [document attachObject: containerView
                toParent: _editedObject];
  [parentView addSubview: containerView];

  // Move each child into the new container and update positions/connectors
  for (NSView *childView in viewsToGroup)
    {
      NSPoint origin = [childView frame].origin;

      // Update the parent connector to point to the new container
      NSArray *old = [document connectorsForSource: childView ofClass: [NSNibConnector class]];
      if ([old count] > 0)
        {
          [[old objectAtIndex: 0] setDestination: containerView];
        }

      [childView removeFromSuperview];
      [containerView addSubview: childView];

      // Adjust position relative to the new container
      origin.x -= unionRect.origin.x;
      origin.y -= unionRect.origin.y;
      [childView setFrameOrigin: origin];
    }

  // Close the old editors for the grouped views
  for (id editorToClose in editorsToClose)
    {
      [editorToClose close];
    }

  editor = (GormViewEditor *)[document editorForObject: containerView
                                             inEditor: self
                                               create: YES];
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInMatrix
{
  GormViewEditor *editor = nil;
  NSMatrix *matrix = nil;
  
  if ([selection count] < 1)
    {
      return;
    }

  // For an NSMatrix there can only be one prototype cell.
  if ([selection count] == 1)
    {
      GormViewEditor *s = [selection objectAtIndex: 0];
      id editedObject = [s editedObject];
      NSCell *cell = [editedObject cell];
      NSRect rect = [editedObject frame];
      NSView *superview = [s superview];

      // Create the matrix
      matrix = [[NSMatrix alloc] initWithFrame: rect
                                          mode: NSRadioModeMatrix
                                     prototype: cell
                                  numberOfRows: 1
                               numberOfColumns: 1];
      
      rect = NSUnionRect(rect, [s frame]);
      [s deactivate];
      
      NSDebugLog(@"editedObject = %@,\n\nsuperview = %@,\n\nmatrix = %@",editedObject, superview, matrix);
      NSDebugLog(@"cell = %@", cell);

      [matrix setPrototype: cell];
      [editedObject removeFromSuperview];
      
      [document attachObject: matrix
                    toParent: _editedObject];

      [superview addSubview: matrix];
    }

  editor = (GormViewEditor *)[document editorForObject: matrix
                                              inEditor: self
                                                create: YES];
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInScrollView
{
  NSEnumerator *enumerator = nil;
  NSMutableArray *viewsToGroup = [NSMutableArray array];
  NSMutableArray *editorsToClose = [NSMutableArray array];
  NSView *contentView = nil;
  NSScrollView *scrollView = nil;
  NSRect unionRect = NSZeroRect;
  GormViewEditor *editor = nil;
  NSView *parentView = nil;

  if ([selection count] < 1)
    {
      return;
    }
  
  // Collect views and compute union rect in parent coordinates
  enumerator = [selection objectEnumerator];
  GormViewEditor *subviewEditor = nil;
  while ((subviewEditor = [enumerator nextObject]) != nil)
    {
      NSView *childView = [subviewEditor editedObject];

      if (parentView == nil)
        {
          parentView = [childView superview];
        }
      else if (parentView != [childView superview])
        {
          return;
        }

      unionRect = NSUnionRect(unionRect, [childView frame]);
      [viewsToGroup addObject: childView];
      [editorsToClose addObject: subviewEditor];
      [subviewEditor deactivate];
    }

  // Create the scroll view and a content view sized to the union rect
  scrollView = [[NSScrollView alloc] initWithFrame: unionRect];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];

  contentView = [[NSView alloc] initWithFrame:
                 NSMakeRect(0, 0, unionRect.size.width, unionRect.size.height)];
  [scrollView setDocumentView: contentView];

  [document attachObject: scrollView
                toParent: _editedObject];
  [parentView addSubview: scrollView];

  // Move grouped views into the scroll view's document view
  for (NSView *childView in viewsToGroup)
    {
      NSPoint origin = [childView frame].origin;

      [childView removeFromSuperview];
      [contentView addSubview: childView];

      origin.x -= unionRect.origin.x;
      origin.y -= unionRect.origin.y;
      [childView setFrameOrigin: origin];

      [document attachObject: childView
                    toParent: scrollView];
    }

  // Close the editors for the moved views
  for (id editorToClose in editorsToClose)
    {
      [editorToClose close];
    }
  
  editor = (GormViewEditor *)[document editorForObject: scrollView
                                             inEditor: self
                                               create: YES];
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

@class GormBoxEditor;
@class GormSplitViewEditor;
@class GormScrollViewEditor;

- (void) _addViewToDocument: (NSView *)view
{
  NSView *par = [view superview];

  if([par isKindOfClass: [GormViewEditor class]])
    {
      par = [(GormViewEditor *)par editedObject];
    }

  [document attachObject: view toParent: par];
}

- (void) ungroup
{
  NSView *toUngroup;

  if ([selection count] != 1)
    return;
  
  NSDebugLog(@"ungroup called");

  toUngroup = [selection objectAtIndex: 0];

  NSDebugLog(@"toUngroup = %@",[toUngroup description]);

  if ([toUngroup respondsToSelector: @selector(destroyAndListSubviews)])
    {
      id contentView = toUngroup;
      id eo = [contentView editedObject];

      NSMutableArray *newSelection = [NSMutableArray array];
      NSArray *views;
      NSInteger i;
      views = [contentView destroyAndListSubviews];
      for (i = 0; i < [views count]; i++)
	{
	  id v = [views objectAtIndex: i];
	  [_editedObject addSubview: v];
	  [self _addViewToDocument: v];

	  [newSelection addObject:
			  [document editorForObject: v
				    inEditor: self
				    create: YES]];
	}

      [contentView close];
      [self selectObjects: newSelection];
      [document detachObject: eo];
      [eo removeFromSuperview];
    }
}

- (void) pasteInView: (NSView *)view
{
  NSPasteboard	 *pb = [NSPasteboard generalPasteboard];
  NSMutableArray *array = [NSMutableArray array];
  NSArray	 *views;
  NSEnumerator	 *enumerator;
  NSView         *sub;

  /*
   * Ask the document to get the copied views from the pasteboard and add
   * them to it's collection of known objects.
   */
  views = [document pasteType: IBViewPboardType
	       fromPasteboard: pb
		       parent: _editedObject];
  /*
   * Now make all the views subviews of ourself.
   */
  enumerator = [views objectEnumerator];
  while ((sub = [enumerator nextObject]) != nil)
    {
      if ([sub isKindOfClass: [NSView class]] == YES)
	{
	  //
	  // Correct the frame if it is outside of the containing view.
	  // this prevents issues where the subview is placed outside the
	  // viewable region of the superview.
	  //
	  if(NSContainsRect([view frame], [sub frame]) == NO)
	    {
	      NSRect newFrame = [sub frame];
	      newFrame.origin.x = 0;
	      newFrame.origin.y = 0;
	      [sub setFrame: newFrame];
	    }

	  [view addSubview: sub];
	  [self _addViewToDocument: sub];
	  [array addObject:
		   [document editorForObject: sub 
			     inEditor: self 
			     create: YES]];
	}
    }

  [self selectObjects: array];
}

@end
