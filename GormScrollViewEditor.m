/* GormScrollViewEditor.m
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

#define _EO ((NSScrollView *)_editedObject)

@implementation NSScrollView (GormObjectAdditions)
- (NSString*) editorClassName
{
  if ([self documentView]
      && [[self documentView] isKindOfClass: [NSTableView class]])
    return @"GormTableViewEditor";
  else if ([self documentView]
      && [[self documentView] isKindOfClass: [NSTextView class]])
    return @"GormTextViewEditor";
  else 
    return @"GormScrollViewEditor";
}
@end


@interface GormScrollViewEditor : GormViewWithSubviewsEditor
{
  GormInternalViewEditor *documentViewEditor;
}
@end

@implementation GormScrollViewEditor

- (void) setOpened: (BOOL) flag
{
  [super setOpened: flag];
  if (flag == YES)
    {  
      [document setSelectionFromEditor: documentViewEditor];
    }
}

- (BOOL) activate
{
  if ([super activate])
    {
      NSView *documentView = [_EO documentView];
      
      NSLog(@"documentView %@", documentView);

      documentViewEditor = [document editorForObject: documentView
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
	isDescendantOf: documentViewEditor])
    {
//        NSLog(@"md %@ descendant of", self);
      if (([self isOpened] == YES) && ([documentViewEditor isOpened] == NO))
	[documentViewEditor setOpened: YES];
      if ([documentViewEditor isOpened])
	[documentViewEditor mouseDown: theEvent];
    }
  else
    {
      NSView *v = [_EO hitTest: [theEvent locationInWindow]];
      if (v && [v isKindOfClass: [NSScroller class]])
	[v mouseDown: theEvent];
    }
}

- (void) dealloc
{
  RELEASE(selection);
  [super dealloc];
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

@end
