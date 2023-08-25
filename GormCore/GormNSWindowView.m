/* GormWindow.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include <GNUstepGUI/GSGormLoading.h>

#include "GormNSWindowView.h"

// the default style mask we start with.
// static NSUInteger defaultStyleMask = NSTitledWindowMask | NSClosableWindowMask
//		  | NSResizableWindowMask | NSMiniaturizableWindowMask;

@implementation GormNSWindowView

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // save the old values...
  // oldStyleMask = _styleMask;

  // set the values we wish to save.. after save restore.
  // _styleMask = _gormStyleMask;
  // [self setReleasedWhenClosed: _gormReleasedWhenClosed];
  [super encodeWithCoder: aCoder];
  // _styleMask = oldStyleMask;
  [self setReleasedWhenClosed: NO];
}


- (id) initResponderWithCoder: (NSCoder *)aDecoder
{
  if ((self = [super init]) != nil)
    {
      id obj = nil;
      int interface_style = 0;
      
      [aDecoder decodeValueOfObjCType: @encode(int) at: &interface_style];
      obj = [aDecoder decodeObject];
      [self setMenu: obj];
    }
  return self;
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  if ((self = [self initResponderWithCoder: aDecoder]) != nil)
    {
      NSSize aSize;
      NSRect aRect;
      NSPoint p;
      NSUInteger aStyle;
      NSBackingStoreType aBacking;
      NSInteger level;
      id obj;
      int version = [aDecoder versionForClassName: @"NSWindow"];
      BOOL flag;
      
      aRect = [aDecoder decodeRect];
      [aDecoder decodeValueOfObjCType: @encode(NSUInteger)
                                   at: &aStyle];
      // This used to be int, we need to stay compatible
      [aDecoder decodeValueOfObjCType: @encode(NSInteger)
                                   at: &aBacking];

      // call the designated initializer....
      self = [self initWithContentRect: aRect
                             styleMask: aStyle
                               backing: aBacking
                                 defer: NO];

      p = [aDecoder decodePoint];
      obj = [aDecoder decodeObject];
      [self setContentView: obj];
      obj = [aDecoder decodeObject];
      [self setBackgroundColor: obj];
      obj = [aDecoder decodeObject];
      [self setRepresentedFilename: obj];
      obj = [aDecoder decodeObject];
      [self setMiniwindowTitle: obj];
      obj = [aDecoder decodeObject];
      [self setTitle: obj];

      if (version < 3)
        {
          aSize = [aDecoder decodeSize];
          [self setMinSize: aSize];
          aSize = [aDecoder decodeSize];
          [self setMaxSize: aSize];
        }
      else
        {
          aSize = [aDecoder decodeSize];
          [self setContentMinSize: aSize];
          aSize = [aDecoder decodeSize];
          [self setContentMaxSize: aSize];
        }

      [aDecoder decodeValueOfObjCType: @encode(NSInteger)
                                   at: &level];
      [self setLevel: level];

      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setExcludedFromWindowsMenu: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setOneShot: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setAutodisplay: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self useOptimizedDrawing: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setDynamicDepthLimit: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      if (flag)
        [self enableCursorRects];
      else
        [self disableCursorRects];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setReleasedWhenClosed: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setHidesOnDeactivate: flag];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
      [self setAcceptsMouseMovedEvents: flag];

      /* If the image has been specified, use it, if not use the default. */
      obj = [aDecoder decodeObject];
      if (obj != nil)
        {
          ASSIGN(_miniaturizedImage, obj);
        }

      [aDecoder decodeValueOfObjCType: @encode(id)
                                   at: &_initialFirstResponder];

      [self setFrameTopLeftPoint: p];
    }

  return self;
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (NSUInteger)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  _styleMask = aStyle;
  self = [super init];
    // initWithContentRect: contentRect
    // styleMask: defaultStyleMask
    // backing: bufferingType
    // defer: NO]; // always no, because this isn't recorded here...
  if(self != nil)
    {
      // Don't release when the window is closed, a window being edited may
      // be periodically opened and closed.
      // [self setReleasedWhenClosed: NO];
      
      // remove the default icon...
      // [self setMiniwindowImage: nil];

      // set the default position mask;
      // autoPositionMask = GSWindowMaxXMargin | GSWindowMinYMargin;
    }

  return self;
}

- (void) setTitle: (NSString *)t
{
  ASSIGN(_windowTitle, t);
}

- (NSString *) title
{
  return _windowTitle;
}

- (void) setMiniwindowTitle: (NSString *)t
{
  ASSIGN(_miniaturizedTitle, t);
}

- (NSString *) miniwindowTitle
{
  return _miniaturizedTitle;
}

- (void) setRepresentedFilename: (NSString *)rf
{
  ASSIGN(_representedFilename, rf);
}

- (NSString *) representedFilename
{
  return _representedFilename;
}

- (void) setBackgroundColor: (NSColor *)bg
{
  ASSIGN(_backgroundColor, bg);
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setContentView: (NSView *)v
{
  NSArray *sv = [NSArray arrayWithObject: v];

  [v removeFromSuperview];
  [self setSubviews: sv];

  ASSIGN(_contentView, v);
}

- (NSView *) contentView
{
  return _contentView;
}

- (void) setStyleMask: (unsigned int)newStyleMask
{
  _styleMask = newStyleMask;
}

- (unsigned int) styleMask
{
  return _styleMask;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (NSString *) className
{
  return @"NSWindow";
}

- (void) setReleasedWhenClosed: (BOOL) flag
{
  // _releasedWhenClosed = flag;
}

- (BOOL) isReleasedWhenClosed
{
  return NO; // _gormReleasedWhenClosed;
}

- (unsigned int) autoPositionMask
{
  return 0L; // autoPositionMask;
}

- (void) setAutoPositionMask: (unsigned int)mask
{
  // autoPositionMask = mask;
}

- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (NSInteger)otherWin
{
  /*
  id<IBDocuments> document = [(id<IB>)NSApp documentForObject: self];
  [super orderWindow: place relativeTo: otherWin];
  if([NSApp isConnecting] == NO)
    { 
      id editor = [document editorForObject: self create: NO];

      // select myself.
      if([editor respondsToSelector: @selector(selectObjects:)])
	{
	  [editor selectObjects: [NSArray arrayWithObject: self]];
	}

      [document setSelectionFromEditor: editor];
      [editor makeSelectionVisible: YES];
    }
  */
}

- (void) saveFrameUsingName: (NSString*)name
{
  // do nothing... 
}
@end
