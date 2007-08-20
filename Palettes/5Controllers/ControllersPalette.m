/* main.m

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: Aug 2007
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include <Foundation/Foundation.h>
#include <Foundation/NSFormatter.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSNumberFormatter.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSClipView.h>
#include <InterfaceBuilder/IBPalette.h>
#include <InterfaceBuilder/IBViewResourceDragging.h>
#include <GormCore/GormPrivate.h>

@interface ControllersPalette : IBPalette <IBViewResourceDraggingDelegates>
@end

@implementation ControllersPalette

- (id) init
{
  if((self = [super init]) != nil)
    {
      // Make ourselves a delegate, so that when the formatter is dragged in, 
      // this code is called...
      [NSView registerViewResourceDraggingDelegate: self];

      // subscribe to the notification...      
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(willInspectObject:)
	name: IBWillInspectObjectNotification
	object: nil];
      
    }
  
  return self;
}

- (void) dealloc
{
  [NSView unregisterViewResourceDraggingDelegate: self];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (void) finishInstantiate
{ 

  NSView	*contents;
  /*
  NSTextView	*tv;
  id		v;
  NSNumberFormatter *nf;
  NSDateFormatter *df;
  NSRect rect;  
  */

  originalWindow = [[NSWindow alloc] initWithContentRect: 
				       NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [originalWindow contentView];
}

- (void) willInspectObject: (NSNotification *)notification
{
}

// view resource dragging delegate...

/**
 * Ask if the view accepts the object.
 */
- (BOOL) acceptsViewResourceFromPasteboard: (NSPasteboard *)pb
                                 forObject: (id)obj
                                   atPoint: (NSPoint)p
{
  return NO;
}

/**
 * Perform the action of depositing the object.
 */
- (void) depositViewResourceFromPasteboard: (NSPasteboard *)pb
                                  onObject: (id)obj
                                   atPoint: (NSPoint)p
{
}

/**
 * Should we draw the connection frame when the resource is
 * dragged in?
 */
- (BOOL) shouldDrawConnectionFrame
{
  return NO;
}

/**
 * Types of resources accepted by this view.
 */
- (NSArray *)viewResourcePasteboardTypes
{
  return [NSArray arrayWithObject: IBObjectPboardType];
}

@end
