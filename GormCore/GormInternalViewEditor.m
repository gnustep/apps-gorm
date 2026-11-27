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
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include "GormPrivate.h"
#include "GormInternalViewEditor.h"
#include "GormFontViewController.h"
#include "GormViewKnobs.h"
#include "GormDefines.h"

@class GormEditorToParent;


@implementation NSView (IBObjectAdditions)
- (NSString*) editorClassName
{
  // Any unattached view is treated as a standalone top-level view,
  // regardless of subclass.
  if ([self superview] == nil && [self window] == nil)
    {
      return @"GormStandaloneViewEditor";
    }
  
  // using NSBox gets rid of compiler warning, should be safe for all classes. 
  if ([self superview] && (([[self superview] respondsToSelector: @selector(contentView)] &&
			    [(NSBox *)[self superview] contentView] == self) ||
			   [[self superview] isKindOfClass: [NSTabView class]] || 
			   [[[self superview] window] contentView] == self ||
			   [[self superview] isKindOfClass: [NSClipView class]]))
    {
      return @"GormInternalViewEditor";
    }
  else if ([self class] == [NSView class])
    {
      return @"GormStandaloneViewEditor";
    } 
  else
    {
      return @"GormViewWithSubviewsEditor";
    }
}

- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      /* View subclasses may live in AppKit or in the user's bundle.
       * The document icon is always a GormCore resource. */
      NSBundle *bundle = [NSBundle bundleForClass: [GormInternalViewEditor class]];
      NSString *path = [bundle pathForImageResource: @"GormView"]; 
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }

  return image;
}

- (NSString*) sizeInspectorClassName
{
  return @"GormViewSizeInspector";
}

- (NSString*) customClassInspector
{
  return @"GormCustomClassInspector";
}

- (NSString *) inspectorClassName
{
  return @"GormViewAttributesInspector";
}

@end


@implementation GormInternalViewEditor



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
      else if ([[superview window] contentView] == _editedObject) 
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

      parent = (GormViewWithSubviewsEditor *)[document parentEditorForEditor: self];
      
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
  NSDebugLog(@"%@ called deactivate", [self class]);
  if (activated == YES)
    {
      id superview = [self superview];
      
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
      else if ([[superview window] contentView] == self)
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
  NSMutableArray *types = 
    [NSMutableArray arrayWithObjects: IBViewPboardType, 
		    GormLinkPboardType, nil];

  opened = NO;
  openedSubeditor = nil;

  if ((self = [super initWithObject: anObject
		     inDocument: aDocument]) == nil)
    return nil;

  selection = [[NSMutableArray alloc] initWithCapacity: 5];
  [self registerForDraggedTypes: types];


  return self;
}

- (void) makeSelectionVisible: (BOOL) value
{  
}

- (NSArray*) selection
{
  NSInteger i;
  NSInteger count = [selection count];
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
  NSInteger i;
  NSArray *sel = [selection copy];
  NSInteger count = [sel count];
  
  for (i = count - 1; i >= 0; i--)
    {
      id ed = [sel objectAtIndex: i];
      id temp = [ed editedObject];

      // detachObject: already handles child objects recursively
      [document detachObject: temp];
    }
}

- (void) pasteInSelection
{
  [self pasteInView: _editedObject];
}

@class GormBoxEditor;
@class GormSplitViewEditor;

- (NSArray *)destroyAndListSubviews
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
      // Convert frame from contentView coordinates to outer view coordinates
      // by offsetting by the container's position.
      frame.origin.x += [parent frame].origin.x;
      frame.origin.y += [parent frame].origin.y;
      [subview deactivate];
      
      [v setFrame: frame];
      [newSelection addObject: v];
    }
  
  [parent close];
   
  return newSelection;
}

- (void) deleteSelection: (id) sender
{
  [self deleteSelection];
}

- (void) changeFont: (id)sender
{
  NSEnumerator *enumerator = [[self selection] objectEnumerator];
  id anObject;
  NSFont *newFont;
  NSUInteger count = 0;

  NSDebugLog(@"In %@ changing font for %@",[self className],[self selection]);
  while ((anObject = [enumerator nextObject]))
    {
      if([anObject respondsToSelector: @selector(setTitleFont:)] &&
	 [anObject respondsToSelector: @selector(setTextFont:)])
	{
	  count++;
	  newFont = [sender convertFont: [anObject font]];
	  newFont = [[GormFontViewController sharedGormFontViewController] 
		      convertFont: newFont];
	  [anObject setTitleFont: newFont];
	  [anObject setTextFont: newFont];
	}
      else if ([anObject respondsToSelector: @selector(font)] &&
	       [anObject respondsToSelector: @selector(setFont:)])
	{
	  count++;
	  newFont = [sender convertFont: [anObject font]];
	  newFont = [[GormFontViewController sharedGormFontViewController] 
		      convertFont: newFont];
	  [anObject setFont: newFont];
	}
    }

  // if the font was changed, mark us as altered...
  if(count > 0)
    {
      [[self document] touch];
    }

  return;
}
@end
