/* InfoPanel.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface InfoPanel : NSPanel
{
  NSTextField	*versionfield;
  NSTextField	*authorfield;
  NSTextField	*addressfield;	
}
@end

@implementation InfoPanel

- (id) init
{
  NSRect	contentRect = {{0, 0}, {380, 120}};
  NSRect	versionRect = {{30, 75}, {320, 20}};
  NSRect	authorRect = {{30, 50}, {320, 20}};
  NSRect	addressRect = {{30, 25}, {320, 20}};
  NSFont	*font;
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask;
	
  self = [super initWithContentRect: contentRect
			  styleMask: style
			    backing: NSBackingStoreRetained
			      defer: NO];
  if (self != nil)
    {
      [self setTitle: @"Info"];
      font = [NSFont systemFontOfSize: 10];

      versionfield = [[NSTextField alloc] init];
      [versionfield setFrame: versionRect];
      [versionfield setFont: font];
      [versionfield setBezeled: NO];
      [versionfield setEditable: NO];
      [versionfield setSelectable: NO];
      [versionfield setAlignment: NSCenterTextAlignment];
      [versionfield setBackgroundColor: [NSColor lightGrayColor]];
      [versionfield setStringValue:
	@"GNUstep Graphicsl Object Relationship Modeller v0.0 1999"];
      [[self contentView] addSubview: versionfield]; 

      authorfield = [[NSTextField alloc] init];
      [authorfield setFrame: authorRect];
      [authorfield setFont: font];
      [authorfield setBezeled: NO];
      [authorfield setEditable: NO];
      [authorfield setSelectable: NO];
      [authorfield setAlignment: NSCenterTextAlignment];
      [authorfield setBackgroundColor: [NSColor lightGrayColor]];
      [authorfield setStringValue: @"by Richard Frith-Macdonald"];
      [[self contentView] addSubview: authorfield]; 

      addressfield = [[NSTextField alloc] init];
      [addressfield setFrame: addressRect];
      [addressfield setFont: font];
      [addressfield setBezeled: NO];
      [addressfield setEditable: NO];
      [addressfield setSelectable: NO];
      [addressfield setAlignment: NSCenterTextAlignment];
      [addressfield setBackgroundColor: [NSColor lightGrayColor]];
      [addressfield setStringValue: @"http://www.gnustep.org"];
      [[self contentView] addSubview: addressfield]; 
      [self center];
      [self setFrameUsingName: @"Info"];
      [self setFrameAutosaveName: @"Info"];
    }
  return self;
}

- (void) dealloc
{
  [versionfield release];
  [authorfield release];
  [addressfield release];
  [super dealloc];
}

@end
