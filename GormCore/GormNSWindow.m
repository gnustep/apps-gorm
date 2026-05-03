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

#include "GormNSWindow.h"

// the default style mask we start with.
static NSUInteger defaultStyleMask = NSTitledWindowMask | NSClosableWindowMask
		  | NSResizableWindowMask | NSMiniaturizableWindowMask;

@implementation GormNSWindow
/*
 * Intercept mouse events at the window level so we can detect clicks in the
 * title/toolbar chrome (which views/editors don't receive). When the user
 * clicks in the area above the contentView and the window has a toolbar,
 * select the NSToolbar so the toolbar inspector opens.
 */
- (void) sendEvent: (NSEvent *)event
{
  if ([event type] == NSLeftMouseDown)
    {
      NSToolbar *tb = [self toolbar];
      if (tb != nil)
        {
          NSPoint p = [event locationInWindow];
          // Prefer precise hit-testing against the actual toolbar view rect.
          id tv = nil;
          if ([tb respondsToSelector: @selector(toolbarView)])
            {
              tv = [tb performSelector: @selector(toolbarView)];
            }

          if ([tv isKindOfClass: [NSView class]])
            {
              NSRect toolbarInWindow = [(NSView *)tv convertRect:[(NSView *)tv bounds] toView:nil];
#ifdef GORM_DEBUG_TOOLBAR_HITTEST
              NSDebugLog(@"Toolbar hit-test: click=(%.1f, %.1f) toolbarRect=(%.1f, %.1f, %.1f, %.1f)",
                         p.x, p.y,
                         toolbarInWindow.origin.x, toolbarInWindow.origin.y,
                         toolbarInWindow.size.width, toolbarInWindow.size.height);
#endif
              if (NSPointInRect(p, toolbarInWindow))
                {
                  id<IBDocuments> document = [(id<IB>)[NSApp delegate] documentForObject: self];
                  id editor = [document editorForObject: tb create: YES];
                  if ([editor respondsToSelector: @selector(selectObjects:)])
                    {
#ifdef GORM_DEBUG_TOOLBAR_HITTEST
                      NSDebugLog(@"Toolbar selection routed to GormToolbarEditor");
#endif
                      [editor selectObjects: [NSArray arrayWithObject: tb]];
                    }
                }
            }
          else
            {
              // Fallback: if toolbar view is unavailable, avoid broad chrome selection.
              // Do nothing to prevent titlebar clicks from selecting the toolbar.
#ifdef GORM_DEBUG_TOOLBAR_HITTEST
              NSDebugLog(@"Toolbar hit-test fallback: toolbar view unavailable");
#endif
            }
        }
    }

  [super sendEvent: event];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  unsigned oldStyleMask;

  // save the old values...
  oldStyleMask = _styleMask;

  // set the values we wish to save.. after save restore.
  _styleMask = _gormStyleMask;
  [self setReleasedWhenClosed: _gormReleasedWhenClosed];
  [super encodeWithCoder: aCoder];
  _styleMask = oldStyleMask;
  [self setReleasedWhenClosed: NO];
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self == nil)
    {
      return nil;
    }
  
  // preserve the setting and set the actual window to NO.
  _gormReleasedWhenClosed = [self isReleasedWhenClosed];
  [self setReleasedWhenClosed: NO];
  
  return self;
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (NSUInteger)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  _gormStyleMask = aStyle;
  self = [super initWithContentRect: contentRect
		styleMask: defaultStyleMask
		backing: bufferingType
		defer: NO]; // always no, because this isn't recorded here...
  if(self != nil)
    {
      // Don't release when the window is closed, a window being edited may
      // be periodically opened and closed.
      [self setReleasedWhenClosed: NO];
      
      // remove the default icon...
      [self setMiniwindowImage: nil];

      // set the default position mask;
      autoPositionMask = GSWindowMaxXMargin | GSWindowMinYMargin;
    }

  return self;
}

- (void) _setStyleMask: (unsigned int)newStyleMask
{
  _gormStyleMask = newStyleMask;
}

- (unsigned int) _styleMask
{
  return _gormStyleMask;
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

- (void) _setReleasedWhenClosed: (BOOL) flag
{
  _gormReleasedWhenClosed = flag;
}

- (BOOL) _isReleasedWhenClosed
{
  return _gormReleasedWhenClosed;
}

- (unsigned int) autoPositionMask
{
  return autoPositionMask;
}

- (void) setAutoPositionMask: (unsigned int)mask
{
  autoPositionMask = mask;
}

- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (NSInteger)otherWin
{
  id<IBDocuments> document = [(id<IB>)[NSApp delegate] documentForObject: self];
  [super orderWindow: place relativeTo: otherWin];
  if([[NSApp delegate] isConnecting] == NO)
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
}

- (void) saveFrameUsingName: (NSString*)name
{
  // do nothing... 
}
@end
