/* GormFilesOwner.m
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

#include <AppKit/NSNibConnector.h>
#include "GormPrivate.h"

@implementation	GormFilesOwner
- (NSString*) className
{
  return className;
}

- (void) dealloc
{
  RELEASE(className);
}

- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFilesOwner"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}

- (id) init
{
  self = [super init];
  [self setClassName: @"NSApplication"];
  return self;
}

- (NSString*) inspectorClassName
{
  return @"GormFilesOwnerInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (void) setClassName: (NSString*)aName
{
  ASSIGN(className, aName);
}

@end

@implementation GormFilesOwnerInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  return [classes count];
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  return @"Class";
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  if (row >= 0 && row < [classes count])
    {
      [aCell setStringValue: [classes objectAtIndex: row]];
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
  RELEASE(classes);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSRect		rect;

      rect = NSMakeRect(0, 0, IVW, IVH);
      window = [[NSWindow alloc] initWithContentRect: rect
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      browser = [[NSBrowser alloc] initWithFrame: rect];
      [browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [browser setMaxVisibleColumns: 1];
      [browser setAllowsMultipleSelection: NO];
      [browser setHasHorizontalScroller: NO];
      [browser setDelegate: self];
      [browser setTarget: self];
      [browser setAction: @selector(takeClassFrom:)];

      [contents addSubview: browser];
      RELEASE(browser);
    }
  return self;
}

- (void) setObject: (id)anObject
{
  ASSIGN(classes, [[NSApp classManager] allClassNames]);
  if (anObject != nil && anObject != object)
    {
      NSArray	*array;
      unsigned	pos;

      ASSIGN(object, anObject);
      hasConnections = NO;

      /*
       * Create list of existing connections for selected object.
       */
      array = [[(id<IB>)NSApp activeDocument] connectorsForSource: object
	ofClass: [NSNibControlConnector class]];
      if ([array count] > 0)
	hasConnections = YES;
      array = [[(id<IB>)NSApp activeDocument] connectorsForSource: object
	ofClass: [NSNibOutletConnector class]];
      if ([array count] > 0)
	hasConnections = YES;

      [browser loadColumnZero];
      pos = [classes indexOfObject: [object className]];
      if (pos != NSNotFound)
	{
	  [browser selectRow: pos inColumn: 0];
	}
    }
}

- (void) takeClassFrom: (id)sender
{
  NSString	*title = [[browser selectedCell] stringValue];

NSLog(@"Selected %d, %@", [browser selectedRowInColumn: 0], title);
  if (hasConnections > 0 && [title isEqual: [object className]] == NO)
    {
      if (NSRunAlertPanel(0, @"This operation will break existing connection",
	@"OK", @"Cancel", NULL) != NSAlertDefaultReturn)
	{
	  unsigned	pos = [classes indexOfObject: [object className]];

	  [browser selectRow: pos inColumn: 0];
	  return;
	}
      else
	{
	  NSArray	*array;
	  id		doc = [(id<IB>)NSApp activeDocument];
	  unsigned	i;

	  array = [doc connectorsForSource: object
				   ofClass: [NSNibControlConnector class]];
	  for (i = 0; i < [array count]; i++)
	    {
	      id<IBConnectors>	con = [array objectAtIndex: i];

	      [doc removeConnector: con];
	    }
	  array = [doc connectorsForSource: object
				   ofClass: [NSNibOutletConnector class]];
	  for (i = 0; i < [array count]; i++)
	    {
	      id<IBConnectors>	con = [array objectAtIndex: i];

	      [doc removeConnector: con];
	    }
	  hasConnections = NO;
	}
    }
  [object setClassName: title];
}

@end

