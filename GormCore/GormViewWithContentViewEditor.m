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

#include <AppKit/AppKit.h>

#include "GormPrivate.h"
#include "GormViewWithContentViewEditor.h"
#include "GormPlacementInfo.h"
#include "GormSplitViewEditor.h"
#include "GormViewKnobs.h"
#include "GormInternalViewEditor.h"

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





#undef MAX
#undef MIN

#define MAX(A,B) ((A)>(B)?(A):(B))
#define MIN(A,B) ((A)<(B)?(A):(B))

NSComparisonResult _sortViews(id view1, id view2, void *context)
{
  BOOL isVertical = *((BOOL *)context);
  NSInteger order = NSOrderedSame;
  NSRect rect1 = [[view1 editedObject] frame];
  NSRect rect2 = [[view2 editedObject] frame];

  if(!isVertical)
    {
      float y1 = rect1.origin.y;
      float y2 = rect2.origin.y;

      if(y1 == y2) 
	order = NSOrderedSame;
      else
	order = (y1 > y2)?NSOrderedAscending:NSOrderedDescending;
    }
  else
    {
      float x1 = rect1.origin.x;
      float x2 = rect2.origin.x;

      if(x1 == x2) 
	order = NSOrderedSame;
      else
	order = (x1 < x2)?NSOrderedAscending:NSOrderedDescending;
    }

  return order;
}

- (NSArray *) _sortByPosition: (NSArray *)subviews
		   isVertical: (BOOL)isVertical
{
  NSMutableArray *array = [subviews mutableCopy];
  NSArray *result = [array sortedArrayUsingFunction: _sortViews
                                            context: &isVertical];
  return result;
}

- (BOOL) _shouldBeVertical: (NSArray *)subviews
{
  BOOL vertical = NO;
  NSEnumerator *enumerator = [subviews objectEnumerator];
  GormViewEditor *editor = nil;
  NSRect prevRect = NSZeroRect;
  NSRect currRect = NSZeroRect;
  NSInteger count = 0;

  // iterate over the list of views...
  while((editor = [enumerator nextObject]) != nil)
    {
      NSView *subview = [editor editedObject];
      currRect = [subview frame];

      if(!NSEqualRects(prevRect,NSZeroRect))
	{
	  float 
	    x1 = prevRect.origin.x, // pull these for convenience.
	    x2 = currRect.origin.x,
	    y1 = prevRect.origin.y,
	    y2 = currRect.origin.y,
	    h1 = prevRect.size.height,
	    w1 = prevRect.size.width;

	  if((x1 < x2 || x1 > x2) && ((y2 >= y1 && y2 <= (y1 + h1)) || 
				      (y2 <= y1 && y2 >= (y1 - h1))))
	    { 
	      count++;
	    }

	  if((y1 < y2 || y1 > y2) && ((x2 >= x1 && x2 <= (x1 + w1)) ||
				      (x2 <= x1 && x2 >= (x1 - w1))))
	    {
	      count--;
	    }
	}
      
      prevRect = currRect;
    }

  NSDebugLog(@"The vote is %ld",(long int)count);

  if(count >= 0)
    vertical = YES;
  else
    vertical = NO;

  // return the result...
  return vertical;
}

- (void) groupSelectionInSplitView
{
  NSEnumerator *enumerator = nil;
  GormViewEditor *subview = nil;
  NSSplitView *splitView = nil;
  NSRect rect = NSZeroRect;
  GormViewEditor *editor = nil;
  NSView *superview = nil;
  NSArray *sortedviews = nil;
  BOOL vertical = NO;

  if ([selection count] < 2)
    {
      return;
    }
  
  enumerator = [selection objectEnumerator];
  
  while ((subview = [enumerator nextObject]) != nil)
    {
      superview = [subview superview];
      rect = NSUnionRect(rect, [subview frame]);
      [subview deactivate];
    }

  splitView = [[NSSplitView alloc] initWithFrame: rect];

  
  [document attachObject: splitView 
	    toParent: _editedObject];

  [superview addSubview: splitView];

  // positionally determine orientation
  vertical = [self _shouldBeVertical: selection];
  sortedviews = [self _sortByPosition: selection isVertical: vertical];
  [splitView setVertical: vertical];

  enumerator = [sortedviews objectEnumerator];
  
  editor = (GormViewEditor *)[document editorForObject: splitView
				       inEditor: self
				       create: YES];

  while ((subview = [enumerator nextObject]) != nil)
    {
      id eO = [subview editedObject];
      
      // Update the parent connector to point to the new split view
      NSArray *old = [document connectorsForSource: eO ofClass: [NSNibConnector class]];
      if ([old count] > 0)
        {
          [[old objectAtIndex: 0] setDestination: splitView];
        }
      
      // Remove from old superview before adding to split view
      [eO removeFromSuperview];
      [splitView addSubview: eO];
      [subview close];
      [document editorForObject: eO
	  inEditor: editor
	  create: YES];
    }
  
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInBox
{
  NSEnumerator *enumerator = nil;
  GormViewEditor *subviewEditor = nil;
  NSBox *box = nil;
  NSRect unionRect = NSZeroRect;
  GormViewEditor *boxEditor = nil;
  NSView *parentView = nil;
  NSMutableArray *viewsToGroup = [NSMutableArray array];
  NSMutableArray *editorsToClose = [NSMutableArray array];

  // Need at least one view to group
  if ([selection count] < 1)
    {
      return;
    }
  
  // First pass: calculate bounding rect and collect the actual views
  enumerator = [selection objectEnumerator];
  while ((subviewEditor = [enumerator nextObject]) != nil)
    {
      NSView *view = [subviewEditor editedObject];
      if (parentView == nil)
        {
          parentView = [view superview];
        }
      else if (parentView != [view superview])
        {
          return;
        }

      unionRect = NSUnionRect(unionRect, [view frame]);
      [viewsToGroup addObject: view];
      [editorsToClose addObject: subviewEditor];
      [subviewEditor deactivate];
    }

  // Create the box with frame matching the content area we need
  box = [[NSBox alloc] initWithFrame: unionRect];
  [box setTitlePosition: NSNoTitle];
  
  // Add box to the parent view
  [parentView addSubview: box];
  
  // Attach box to the document structure
  [document attachObject: box
                toParent: _editedObject];

  // Second pass: move each view into the box's content view
  for (NSView *view in viewsToGroup)
    {
      NSRect viewFrame = [view frame];
      NSPoint contentOrigin = [[box contentView] frame].origin;
      
      // Remove from current superview
      [view removeFromSuperview];
      
      // Add to box's content view (not the box itself)
      [[box contentView] addSubview: view];
      
      // Adjust frame to be relative to box's content view coordinate system
      viewFrame.origin.x -= unionRect.origin.x;
      viewFrame.origin.y -= unionRect.origin.y;
      viewFrame.origin.x -= contentOrigin.x;
      viewFrame.origin.y -= contentOrigin.y;
      [view setFrame: viewFrame];
      
      // Update document structure: view is now child of box
      [document attachObject: view
                    toParent: box];
    }
  
  // Close all the old editors for the grouped views
  for (id editorToClose in editorsToClose)
    {
      [editorToClose close];
    }

  // Create editor for the new box
  boxEditor = (GormViewEditor *)[document editorForObject: box
                                                 inEditor: self
                                                   create: YES];
  
  // Select the new box editor
  [self selectObjects: [NSArray arrayWithObject: boxEditor]];
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
      
      NSLog(@"editedObject = %@,\n\nsuperview = %@,\n\nmatrix = %@",editedObject, superview, matrix);
      [matrix setPrototype: cell];
      NSLog(@"cell = %@", cell);
      NSLog(@"prototype = %@", [matrix prototype]);
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
