/* GormViewWithContentViewEditor.m
 *
 * Copyright (C) 2002, 2026 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2002, 2026
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

// Forward declaration...
@class GormBoxEditor;
@class GormSplitViewEditor;
@class GormScrollViewEditor;

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

- (void) addViewToDocument: (NSView *)view
{
  NSView *par = [view superview];

  if([par isKindOfClass: [GormViewEditor class]])
    {
      par = [(GormViewEditor *)par editedObject];
    }

  [document attachObject: view toParent: par];
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

  return [types containsObject: IBViewPboardType];
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
  GormDocument *doc = (GormDocument *)document;

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
  // Order views and set orientation BEFORE setting the frame.
  // Setting the frame on NSSplitView triggers adjustSubviews internally;
  // isVertical must already be set at that point so the layout is correct.
  NSArray *sortedViews = [view orderSelectionForViews: viewSelection];

  [view setFrame: rect];

  [view addViews: sortedViews];

  // Add view to the edited object directly. We must NOT use
  // [parentObject contentView] here because after editor activation
  // [window contentView] returns the GormInternalViewEditor itself,
  // not the original NSView. Adding view there would put it outside
  // the subtree searched by mouseDown:'s [_editedObject hitTest:],
  // making the grouped view unselectable.
  [_editedObject addSubview: view];
  [doc attachObject: view toParent: _editedObject];

  // Get the editor for the object...
  id editor = [doc editorForObject: view inEditor: self create: YES];

  // Select objects...
  [self selectObjects: [NSArray arrayWithObject: editor]];
}

- (void) groupSelectionInSplitView
{
  [self groupSelectionInView: [[NSSplitView alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInBox
{
  [self groupSelectionInView: [[NSBox alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInView
{
  [self groupSelectionInView: [[NSView alloc] initWithFrame: NSZeroRect]];
}

- (void) groupSelectionInScrollView
{
  [self groupSelectionInView: [[NSScrollView alloc] initWithFrame: NSZeroRect]];
}

- (void) ungroup
{
  if ([selection count] != 1)
    return;

  id containerEditor = [selection objectAtIndex: 0];
  if (![containerEditor respondsToSelector: @selector(destroyAndListSubviews)])
    return;

  id eo = [containerEditor editedObject];

  // destroyAndListSubviews deactivates all sub-editors, converts each
  // subview's frame to self's coordinate space, and closes the container
  // editor itself.  The returned array contains the raw views only.
  NSArray *views = [containerEditor destroyAndListSubviews];

  if (!views || [views count] == 0)
    {
      // Container was empty; just remove it from document and redisplay.
      [eo removeFromSuperview];
      [document detachObject: eo closeEditor: NO];
      [self setNeedsDisplay: YES];
      return;
    }

  NSInteger i;
  NSInteger count = [views count];

  // ── Pass 1 ──────────────────────────────────────────────────────────
  // Move every extracted view into _editedObject (the outer editing
  // view) and update its NSNibConnector so the document parent pointer
  // changes from the container's internal content-view to _editedObject.
  // This must happen BEFORE detachObject: so that the recursive detach
  // of the container's internal views finds an empty child list for each
  // of those views and never calls removeFromSuperview on them.
  for (i = 0; i < count; i++)
    {
      id v = [views objectAtIndex: i];
      [_editedObject addSubview: v];
      [self addViewToDocument: v];
    }

  // Remove the container from the view hierarchy explicitly before
  // detaching it from the document.  The extracted views are already
  // siblings in _editedObject at this point, so removing eo is safe.
  [eo removeFromSuperview];

  // Detach the container (and its now-empty internal structure, e.g. the
  // NSBox content-view placeholder) from the document.  Because Pass 1
  // already re-pointed every extracted view's NSNibConnector to
  // _editedObject, the recursive detachment finds no "our" views and
  // will only clean up the container's own bookkeeping entries.
  [document detachObject: eo closeEditor: NO];

  // ── Pass 2 ──────────────────────────────────────────────────────────
  // Now that all container state has been cleaned up, create editors for
  // the extracted views.  Doing this after detachObject: avoids any
  // chance that the connections-removal sweep in detachObject: touches
  // connectors belonging to the freshly created editors.
  NSMutableArray *newSelection = [NSMutableArray arrayWithCapacity: count];
  for (i = 0; i < count; i++)
    {
      id v = [views objectAtIndex: i];
      id e = [document editorForObject: v
			      inEditor: self
				create: YES];

      [parent addSubview: v];
      [newSelection addObject: e];
    }

  // ── Finalize ──────────────────────────────────────────────────────────
  // Select objects that have been ungrouped and update the display.
  [self selectObjects: newSelection];
  [self setNeedsDisplay: YES];
}

- (void) pasteInView: (NSView *)view
{
  NSPasteboard	 *pb = [NSPasteboard generalPasteboard];
  NSMutableArray *array = [NSMutableArray array];
  NSArray	 *views = nil;
  NSEnumerator	 *enumerator = nil;
  NSView         *sub = nil;

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
	  [self addViewToDocument: sub];
	  [array addObject:
		   [document editorForObject: sub 
			     inEditor: self 
			     create: YES]];
	}
    }

  [self selectObjects: array];
}

@end
