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
  [view addViews: sortedViews];

  // Add view to parent...
  id parentObject = [parent editedObject];
  if ([parentObject respondsToSelector: @selector(contentView)])
    {
      id contentView = [parentObject contentView];
      [contentView addSubview: view];
      NSLog(@"**** added subview %@ to parent %@", view, contentView);
    }

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
  NSView *toUngroup = nil;

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
	  [self addViewToDocument: v];

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
