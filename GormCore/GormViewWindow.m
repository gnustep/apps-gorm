/* GormViewWindow.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
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

#include "GormViewWindow.h"
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>
#include <AppKit/NSColor.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@interface GormViewWindowDelegate : NSObject
{
  NSView *_view;
}

- (id) initWithView: (NSView *)view;
- (void) resize;
@end

@implementation GormViewWindowDelegate

- (id) initWithView: (NSView *)view;
{
  if((self = [super init]) != nil)
    {
      _view = view;
      [self resize];
    }
  return self;
}

- (void) resize
{
  NSWindow *window = [_view window];
  NSRect newFrame = [window frame];
  
  newFrame.origin.x = 10;
  newFrame.origin.y = 20;
  newFrame.size.height -= 70;
  newFrame.size.width -= 20;
  [_view setFrame: newFrame];

  NSLog(@"Resized %@",NSStringFromRect(newFrame));
}

- (void) windowDidResize: (NSNotification *)notification
{
  [self resize];
}

@end


@implementation GormViewWindow

- (id) initWithView: (NSView *)view
{
  if((self = [super init]) != nil)
    { 
      NSString *className = NSStringFromClass([view class]);
      NSString *objectName = [[(id<IB>)NSApp activeDocument] nameForObject: view];
      NSString *title = [NSString stringWithFormat: @"View Window: (%@, %@)",
				  className, objectName];

      [self setTitle: title];
      [self setFrame: NSMakeRect(0,0,400,300) display: YES];
      // [self setBackgroundColor: [NSColor redColor]];
      [self setReleasedWhenClosed: NO];
      [self setView: view];
    }
  return self;
}

- (void) setView: (NSView *)view
{
  if(_view != nil)
    {
      [_view removeFromSuperviewWithoutNeedingDisplay];
    }

  _view = view;

  [[self contentView] addSubview: _view];
  DESTROY(_delegate);
  [self setDelegate: [[GormViewWindowDelegate alloc] initWithView: _view]];
  [self center];
}

- (NSView *) view
{
  return _view;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [NSException raise: NSInternalInconsistencyException
	       format: @"Cannot encode a GormViewWindow"];
}

- (void) dealloc
{
  DESTROY(_delegate);
  [super dealloc];
}

@end

