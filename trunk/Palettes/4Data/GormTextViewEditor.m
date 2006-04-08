/* inspectors - Various inspectors for data elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Date: Nov 2001   
   Author:  Gregory Casamento <greg_casamento@yahoo.com>
   Date: Nov 2003,2004,2005
   
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
#include <AppKit/AppKit.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

#include <GormCore/GormPrivate.h>
#include <GormCore/GormViewEditor.h>
#include <GormCore/NSColorWell+GormExtensions.h>
#include <GormCore/GormViewSizeInspector.h>

#include "GormTextViewEditor.h"

@implementation GormTextViewEditor

- (BOOL) activate
{
  if ([super activate])
    {
      if ([_editedObject isKindOfClass: [NSScrollView class]])
	textView = [(NSScrollView *)_editedObject documentView];
      else
	textView = (NSTextView *)_editedObject;
      return YES;
    }
  return NO;
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender

{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      id destination = nil;
      NSView *hitView = 
	[[textView enclosingScrollView] 
	  hitTest: 
	    [[[textView enclosingScrollView] superview]
	      convertPoint: [sender draggingLocation]
	      fromView: nil]];

      if ((hitView == textView) || (hitView == [textView superview]))
	destination = textView;

      if (destination == nil)
	destination = _editedObject;

      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: destination];
      return NSDragOperationLink;
    }
  else
    {
      return NSDragOperationNone;
    }
}
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      id destination = nil;
      NSView *hitView = 
	[[textView enclosingScrollView] 
	  hitTest: 
	    [[[textView enclosingScrollView] superview]
	      convertPoint: [sender draggingLocation]
	      fromView: nil]];
      
      if ((hitView == textView) || (hitView == [textView superview]))
	destination = textView;

      if (destination == nil)
	destination = _editedObject;

      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: destination];
      [NSApp startConnecting];
      return YES;
    }
  return YES;
}

- (NSWindow *)windowAndRect: (NSRect *)prect
		  forObject: (id) object
{
  if (object == textView)
    {
      *prect = [[textView superview] convertRect: [[textView superview] visibleRect]
			  toView :nil];
      return _window;
    }
  else
    {
      return [super windowAndRect: prect forObject: object];
    }
}
@end
