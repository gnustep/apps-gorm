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

@implementation GormToolbarEditor

- (NSToolbar *)toolbar
{
  return toolbar;
}

- (void)setToolbar:(NSToolbar *)aToolbar
{
  toolbar = aToolbar;
}

- (void)addAllowedToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  [items addObject: item];
  [toolbar setAllowedItemIdentifiers: items];
}

- (void)removeAllowedToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  [items removeObject: item];
  [toolbar setAllowedItemIdentifiers: items];
}

- (void)addDefaultToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  [items addObject: item];
  [toolbar setDefaultItemIdentifiers: items];
}

- (void)removeDefaultToolbarItem:(NSToolbarItem *)item
{
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  [items removeObject: item];
  [toolbar setDefaultItemIdentifiers: items];
}

- (void)configureToolbarItem:(NSToolbarItem *)item
{
  // Present inspector UI for item properties (label, image, action, etc.)
  // Implementation would depend on Gorm's inspector infrastructure
}


- (void) mouseDown: (NSEvent *)theEvent
{
  /*
  // Check if we're clicking on a knob for resizing
  BOOL onKnob = NO;
  
  if ([parent respondsToSelector: @selector(selection)] &&
      [[parent selection] containsObject: _editedObject])
    {
      IBKnobPosition knob = IBNoneKnobPosition;
      NSPoint mouseDownPoint = [self convertPoint: [theEvent locationInWindow]
                                         fromView: nil];
      knob = GormKnobHitInRect([self bounds], mouseDownPoint);
      if (knob != IBNoneKnobPosition)
        {
          onKnob = YES;
        }
    }
  
  if (onKnob == YES)
    {
      if (parent)
        return [parent mouseDown: theEvent];
      else
        return [self noResponderFor: @selector(mouseDown:)];
    }
  */
  // Otherwise handle as a regular selection/connection event
  [super mouseDown: theEvent];
}

/*
- (void) postDraw: (NSRect)rect
{
  // Draw selection knobs if this toolbar is selected
  if ([parent respondsToSelector: @selector(selection)] &&
      [[parent selection] containsObject: _editedObject])
    {
      NSRect bounds = [self bounds];
      GormDrawKnobsForRect(bounds);
    }
  
  [super postDraw: rect];
}
*/

- (BOOL) acceptsTypeFromArray: (NSArray *)types
{
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
  
  // Check if this is a connection drag
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      return NSDragOperationLink;
    }
  
  return NSDragOperationNone;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  
  // Handle connection drags
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      // The connection will be handled by the document's drag handling mechanism
      // which is inherited from GormViewEditor
      return YES;
    }
  
  return NO;
}

@end
