/* GormMenuInspectors.m
 *
 * Copyright (C) 2000 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	2000
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

#include "../../GormPrivate.h"

@implementation	NSMenu (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormMenuAttributesInspector";
}
@end

@interface GormMenuAttributesInspector : IBInspector
{
  NSTextField	*titleText;
}
@end

@implementation GormMenuAttributesInspector

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  [object setTitle: [titleText stringValue]];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSTextField	*title;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      title
	= [[NSTextField alloc] initWithFrame: NSMakeRect(10,IVH-30,70,20)];
      [title setEditable: NO];
      [title setSelectable: NO];
      [title setBezeled: NO];
      [title setAlignment: NSLeftTextAlignment];
      [title setFont: [NSFont systemFontOfSize: 14.0]];
      [title setDrawsBackground: NO];
      [title setStringValue: @"Title:"];
      [contents addSubview: title];
      RELEASE(title);

      titleText
	= [[NSTextField alloc] initWithFrame: NSMakeRect(60,IVH-30,IVW-80,20)];
      [titleText setDelegate: self];
      [contents addSubview: titleText];
      RELEASE(titleText);
    }
  return self;
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [titleText setStringValue: [object title]];
}

@end



@implementation	NSMenuItem (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormMenuItemAttributesInspector";
}
@end

@interface GormMenuItemAttributesInspector : IBInspector
{
  NSTextField	*titleText;
  NSTextField	*shortCut;
}
@end

@implementation GormMenuItemAttributesInspector

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id	o = [aNotification object];

  if (o == titleText)
    {
      [object setTitle: [titleText stringValue]];
    }
  if (o == shortCut)
    {
      NSString	*s = [[shortCut stringValue] stringByTrimmingSpaces];

      [object setKeyEquivalent: s];
    }
  [[object menu] display];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSTextField	*title;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      title
	= [[NSTextField alloc] initWithFrame: NSMakeRect(10,IVH-30,50,20)];
      [title setEditable: NO];
      [title setSelectable: NO];
      [title setBezeled: NO];
      [title setAlignment: NSLeftTextAlignment];
      [title setFont: [NSFont systemFontOfSize: 14.0]];
      [title setDrawsBackground: NO];
      [title setStringValue: @"Title:"];
      [contents addSubview: title];
      RELEASE(title);

      titleText
	= [[NSTextField alloc] initWithFrame: NSMakeRect(60,IVH-30,IVW-80,20)];
      [titleText setDelegate: self];
      [contents addSubview: titleText];
      RELEASE(titleText);

      title
	= [[NSTextField alloc] initWithFrame: NSMakeRect(10,IVH-60,70,20)];
      [title setEditable: NO];
      [title setSelectable: NO];
      [title setBezeled: NO];
      [title setAlignment: NSLeftTextAlignment];
      [title setFont: [NSFont systemFontOfSize: 14.0]];
      [title setDrawsBackground: NO];
      [title setStringValue: @"Shortcut:"];
      [contents addSubview: title];
      RELEASE(title);

      shortCut
	= [[NSTextField alloc] initWithFrame: NSMakeRect(80,IVH-60,20,20)];
      [shortCut setDelegate: self];
      [contents addSubview: shortCut];
      RELEASE(shortCut);
    }
  return self;
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [titleText setStringValue: [object title]];
  [shortCut setStringValue: [object keyEquivalent]];
}

@end

