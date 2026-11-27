/* GormViewWindow.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2004
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include "GormViewWindow.h"
#include "GormFunctions.h"

@interface GormViewWindowDelegate : NSObject
{
  NSView *_view;
}

- (id) initWithView: (NSView *)view;
- (void) initialResize;
@end

@implementation GormViewWindowDelegate

- (id) initWithView: (NSView *)view;
{
  if((self = [super init]) != nil)
    {
      _view = view;
      [self initialResize];
    }
  return self;
}

- (void) initialResize
{
  NSWindow *window = [_view window];
  NSRect frame = [_view frame];

  if (NSIsEmptyRect(frame))
    {
      frame.size = NSMakeSize(360, 230);
      if ([[_view subviews] count] > 0)
        frame.size = minimalContainerFrame([_view subviews]).size;
      [_view setFrame: frame];
    }

  /* The window is only an editing surface. Opening it must not change
   * the document view's origin, size, or autoresizing mask. */
  [[window contentView] setAutoresizesSubviews: NO];
  [window setContentSize: NSMakeSize(frame.size.width + 20,
                                    frame.size.height + 40)];
  [[window contentView] setBoundsOrigin:
    NSMakePoint(frame.origin.x - 10, frame.origin.y - 20)];
  [window center];
}

- (void) windowDidResize: (NSNotification *)notification
{
  NSWindow *window = [notification object];
  NSSize size = [[window contentView] bounds].size;
  [_view setFrameSize: NSMakeSize(MAX(1, size.width - 20),
                                 MAX(1, size.height - 40))];
}

@end


@implementation GormViewWindow

- (id) initWithView: (NSView *)view
{
  if((self = [super init]) != nil)
    { 
      NSString *className = NSStringFromClass([view class]);
      NSString *objectName = [[(id<IB>)[NSApp delegate] activeDocument] nameForObject: view];
      NSString *title = [NSString stringWithFormat: @"Standalone View Window: (%@, %@)",
				  className, objectName];

      [self setTitle: title];
      [self setFrame: NSMakeRect(0,0,400,300) display: YES];
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
  id oldDelegate = [self delegate];
  [self setDelegate: nil];
  RELEASE(oldDelegate);
  [self setDelegate: [[GormViewWindowDelegate alloc] initWithView: _view]];
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
  RELEASE([self delegate]);
  [self setDelegate: nil];
  [super dealloc];
}

@end

