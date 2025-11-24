/* GormToolbarEditor.m
 *
 * Implementation of the editor class for NSToolbar objects in Gorm palettes.
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg.casamento@gmail.com>
 *
 * This file is part of GNUstep.
 *
 * GNUstep is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNUstep is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNUstep; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import "GormToolbarEditor.h"
#import <GormCore/GormViewKnobs.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

@implementation GormToolbarEditor

- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  if ((self = [super initWithObject: anObject inDocument: aDocument]) != nil)
    {
      toolbar = (NSToolbar *)anObject;
      toolbarView = [toolbar toolbarView];
    }
  return self;
}

- (NSToolbar *)toolbar
{
  return toolbar;
}

- (void)setToolbar:(NSToolbar *)aToolbar
{
  toolbar = aToolbar;
  toolbarView = [toolbar toolbarView];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  
  // Check if click is on the toolbar view area
  if (toolbarView && NSPointInRect(location, [toolbarView frame]))
    {
      // Handle selection - select the toolbar
      [document setSelectionFromEditor: self];
      [[NSNotificationCenter defaultCenter]
        postNotificationName: IBSelectionChangedNotification
        object: self];
      return;
    }
  
  // Otherwise delegate to super
  [super mouseDown: theEvent];
}

- (void) drawRect: (NSRect)rect
{
  [super drawRect: rect];
  
  // Draw selection knobs around the toolbar view if this editor owns selection
  if (toolbarView && [(id<IB>)[NSApp delegate] selectionOwner] == self)
    {
      NSRect toolbarFrame = [toolbarView frame];
      [self lockFocus];
      GormDrawKnobsForRect(toolbarFrame);
      [self unlockFocus];
    }
}

- (NSArray *) selection
{
  // Return the toolbar as the selected object
  return [NSArray arrayWithObject: toolbar];
}

- (void) makeSelectionVisible: (BOOL)flag
{
  [self setNeedsDisplay: YES];
  [super makeSelectionVisible: flag];
}

- (BOOL) acceptsTypeFromArray: (NSArray *)types
{
  NSLog(@"types = %@", types);
  // Accept link types for making connections (outlets, actions, etc.)
  if ([types containsObject: GormLinkPboardType])
    {
      return YES;
    }
  
  return [super acceptsTypeFromArray: types];
}

- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSLog(@"Entered");
  // Check if this is a connection drag
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      NSLog(@"Success");
      return NSDragOperationLink;
    }
  
  return NSDragOperationNone;
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
      [super draggingExited: sender];
      return;
    }

  rect = [toolbarView bounds];
  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;
 
  rect.origin.x --;
  rect.size.width ++;
  rect.size.height ++;

  [[self window] disableFlushWindow];
  [self displayRect: 
	  [toolbarView convertRect: rect
			    toView: self]];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPoint loc = [sender draggingLocation];
  NSRect rect = [toolbarView bounds];
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  loc = [toolbarView convertPoint: loc
			 fromView: nil];

  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return [super draggingUpdated: sender];
    }

  rect.origin.x += 3;
  rect.origin.y += 2;
  rect.size.width -= 5;
  rect.size.height -= 5;

  if (NSMouseInRect(loc, [toolbarView bounds], NO) == NO)
    {
      [[self window] disableFlushWindow];
      rect.origin.x --;
      rect.size.width ++;
      rect.size.height ++;
      [self displayRect: 
	      [toolbarView convertRect: rect
				toView: self]];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      return NSDragOperationNone;
    }
  else
    {
      [toolbarView lockFocus];
      
      [[NSColor darkGrayColor] set];
      NSFrameRectWithWidth(rect, 2);
      
      [toolbarView unlockFocus];
      [[self window] flushWindow];
      return NSDragOperationCopy;
    }
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSLog(@"Entered2");
  // Handle connection drags
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      NSLog(@"Success2");
      // The connection will be handled by the document
      return YES;
    }
  
  return NO;
}

@end
