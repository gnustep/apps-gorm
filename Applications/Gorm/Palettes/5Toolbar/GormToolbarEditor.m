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

#import <GormCore/GormViewKnobs.h>
#import <GormCore/GormClassManager.h>
#import <GormCore/GormDocument.h>

#import <InterfaceBuilder/InterfaceBuilder.h>

#import "GormToolbarEditor.h"

static void
GormDrawStippleForRect(NSRect aRect)
{
  static NSImage *stipplePattern = nil;
  
  if (stipplePattern == nil)
    {
      // Create a stipple pattern (8x8 pixels) with larger dots
      stipplePattern = [[NSImage alloc] initWithSize: NSMakeSize(8, 8)];
      [stipplePattern lockFocus];
      
      // Draw larger dots (3x3 pixels) at specific positions
      [[NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.4] set];
      NSRectFill(NSMakeRect(0, 0, 3, 3));  // Top-left dot
      NSRectFill(NSMakeRect(4, 4, 3, 3));  // Bottom-right dot
      
      [stipplePattern unlockFocus];
    }
  
  // Draw the stipple pattern over the rectangle
  NSGraphicsContext *context = [NSGraphicsContext currentContext];
  [context saveGraphicsState];
  
  // Set the compositing mode to highlight the selection
  [[NSColor colorWithPatternImage: stipplePattern] set];
  NSRectFillUsingOperation(aRect, NSCompositeSourceOver);
  
  // Draw a border around the selection
  [[NSColor colorWithCalibratedRed: 0.0 green: 0.5 blue: 1.0 alpha: 0.8] set];
  NSFrameRectWithWidth(aRect, 2.0);
  
  [context restoreGraphicsState];
}

@implementation GormToolbarEditor

- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  if ((self = [super initWithObject: anObject inDocument: aDocument]) != nil)
    {
      NSMutableArray *draggedTypes;
      
      toolbar = (NSToolbar *)anObject;
      toolbarView = [toolbar toolbarView];
      activated = NO;

      // Add to selected objects...
      [objects addObject: anObject];
      
      // Register for dragged types to enable connections
      draggedTypes = [NSMutableArray arrayWithObject: GormLinkPboardType];
      [self registerForDraggedTypes: draggedTypes];
    }

  return self;
}

- (BOOL) activate
{
  if (activated == NO)
    {
      NSView *superview = [toolbarView superview];
      NSString *name = [document nameForObject: toolbar];
      GormClassManager *cm = [(GormDocument *)document classManager];

      [self setFrame: [toolbarView frame]];
      [self setBounds: [self frame]];

      [superview replaceSubview: toolbarView
		 with: self];
      
      [self setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];
      [self setAutoresizesSubviews: YES];      
      [self addSubview: toolbarView];
      [self setToolTip: [NSString stringWithFormat: @"%@,%@",
				  name, 
				  [cm classNameForObject: toolbar]]];

      [self setNeedsDisplay: YES];
      activated = YES;
    }

  return activated;
}

- (void) deactivate
{
    if (activated == YES)
    {
      NSView *superview = [self superview];

      [self removeSubview: toolbarView];
      [superview replaceSubview: self
			   with: toolbarView];

      [[NSNotificationCenter defaultCenter] removeObserver: self];
      activated = NO;
    }
}

- (NSToolbar *)toolbar
{
  return toolbar;
}

- (void)setToolbar: (NSToolbar *)aToolbar
{
  toolbar = aToolbar;
  toolbarView = [toolbar toolbarView];
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];

  // Check for Control-click to initiate connections
  if ([theEvent modifierFlags] & NSControlKeyMask)
    {
      NSString *name = [document nameForObject: toolbar];
      
      if (name != nil && [name isEqualToString: @"NSFirst"] == NO)
        {
          NSPasteboard *pb;
          id delegate = [NSApp delegate];
          
          // Select the toolbar first
          [document setSelectionFromEditor: self];
          
          // Set up drag pasteboard for connection
          pb = [NSPasteboard pasteboardWithName: NSDragPboard];
          [pb declareTypes: [NSArray arrayWithObject: GormLinkPboardType]
                     owner: self];
          [pb setString: name forType: GormLinkPboardType];
          
          // Start the connection process
          [delegate displayConnectionBetween: toolbar and: nil];
          [delegate startConnecting];
          
          // Drag the link image
          [self dragImage: [delegate linkImage]
                       at: location
                   offset: NSZeroSize
                    event: theEvent
               pasteboard: pb
                   source: self
                slideBack: YES];
          
          [self makeSelectionVisible: YES];
          return;
        }
    }
  
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
  
  // Draw stipple pattern over the toolbar view if this editor owns selection
  if (toolbarView && [(id<IB>)[NSApp delegate] selectionOwner] == self)
    {
      NSRect toolbarFrame = [toolbarView frame];
      [self lockFocus];
      GormDrawStippleForRect(toolbarFrame);
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
  id delegate = [NSApp delegate];
  
  // Check if this is a connection drag
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      // Display the connection feedback
      [delegate displayConnectionBetween: [delegate connectSource] and: toolbar];
      return NSDragOperationLink;
    }
  
  return NSDragOperationNone;
}

- (void) draggingExited: (id<NSDraggingInfo>)sender
{
  NSArray *types;
  id delegate = [NSApp delegate];

  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      // Clear the connection display
      [delegate displayConnectionBetween: [delegate connectSource] and: nil];
      return;
    }

  // Handle other drag types if needed
  NSRect rect = [toolbarView bounds];
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

/*
- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPoint loc = [sender draggingLocation];
  NSRect rect = [toolbarView bounds];
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
*/

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSLog(@"Updating...");
  return [self draggingEntered: sender];
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  id delegate = [NSApp delegate];

  // Handle connection drags
  if ([pb availableTypeFromArray: [NSArray arrayWithObject: GormLinkPboardType]])
    {
      // Display the connection to the toolbar and let the document handle it
      [delegate displayConnectionBetween: [delegate connectSource] and: toolbar];
      [delegate startConnecting];
      return YES;
    }
  
  return NO;
}

@end
