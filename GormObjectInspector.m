/* GormObjectInspector.m
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

#include "GormPrivate.h"

@interface GormObjectInspector : IBInspector
{
  NSBrowser	*browser;
  NSArray	*names;
  NSArray	*types;
  NSButton	*label;
  NSText	*value;
}
- (void) updateButtons;
@end

@implementation GormObjectInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  return [names count];
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)col
{
  [self updateButtons];
  return YES;
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)col
{
  return @"Attribute setters";
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  if (row >= 0 && row < [names count])
    {
      [aCell setStringValue: [names objectAtIndex: row]];
      [aCell setEnabled: YES];
    }
  else
    {
      [aCell setStringValue: @""];
      [aCell setEnabled: NO];
    }
  [aCell setLeaf: YES];
}

- (void) dealloc
{
  RELEASE(label);
  RELEASE(value);
  RELEASE(names);
  RELEASE(types);
  RELEASE(okButton);
  RELEASE(revertButton);
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSRect		windowRect = NSMakeRect(0, 0, IVW, IVH-IVB);
      NSRect		rect;

      window = [[NSWindow alloc] initWithContentRect: windowRect
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      rect = windowRect;
      rect.size.height -= 70;
      rect.origin.y += 70;

      browser = [[NSBrowser alloc] initWithFrame: rect];
      [browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [browser setMaxVisibleColumns: 1];
      [browser setAllowsMultipleSelection: NO];
      [browser setHasHorizontalScroller: NO];
      [browser setTitled: YES];
      [browser setDelegate: self];
      [browser setTarget: self];
      [browser setAction: @selector(updateButtons)];

      [contents addSubview: browser];
      RELEASE(browser);

      rect = windowRect;
      rect.size.width -= 120;
      rect.size.height = 22;
      rect.origin.y = 30;
      rect.origin.x = 60;
      label = [[NSButton alloc] initWithFrame: rect];
      [label setBordered: NO];
      [label setTitle: @"No Type"];
      [contents addSubview: label];
      RELEASE(label);

      rect = windowRect;
      rect.size.height = 22;
      rect.origin.y = 0;
      value = [[NSTextField alloc] initWithFrame: rect];
      [contents addSubview: value];
      RELEASE(value);

      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: @"Add"];
      [okButton setEnabled: NO];

      revertButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [revertButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [revertButton setAction: @selector(revert:)];
      [revertButton setTarget: self];
      [revertButton setTitle: @"Revert"];
      [revertButton setEnabled: NO];
    }
  return self;
}

- (void) ok: (id)sender
{
}

- (void) setObject: (id)anObject
{
  if (anObject != nil && anObject != object)
    {
      ASSIGN(object, anObject);

      [browser loadColumnZero];
      [self updateButtons];
    }
}

- (void) updateButtons
{
}

- (BOOL) wantsButtons
{
  return YES;
}
@end

