/* GormInspectorsManager.m
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

@implementation NSObject (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormObjectAttributesInspector";
}

- (NSString*) connectInspectorClassName
{
  return @"GormObjectConnectionsInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormObjectSizeInspector";
}

- (NSString*) helpInspectorClassName
{
  return @"GormObjectHelpInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormObjectClassInspector";
}

@end

@implementation GormInspectorsManager

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(selectionView);
  RELEASE(inspectorView);
  RELEASE(emptyView);
  RELEASE(multipleView);
  RELEASE(panel);
  [super dealloc];
}

- (id) init
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSBox		*box;
  NSCell	*cell;
  NSRect	contentRect = {{0, 0}, {272, 420}};
  NSRect	selectionRect = {{0, 378}, {272, 52}};
  NSRect	boxRect = {{0, 361}, {272, 2}};
  NSRect	inspectorRect = {{0, 0}, {272, 360}};
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask				| NSResizableWindowMask;

  panel = [[NSPanel alloc] initWithContentRect: contentRect
				     styleMask: style
				       backing: NSBackingStoreRetained
					 defer: NO];
  box = [[NSBox alloc] initWithFrame: boxRect];
  [box setBorderType: NSLineBorder];
  [box setTitlePosition: NSNoTitle];
  [box setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  [[panel contentView] addSubview: box]; 
  RELEASE(box);

  [panel setTitle: @"Inspector"];
  [panel setMinSize: [panel frame].size];

  selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
					     mode: NSRadioModeMatrix
					cellClass: [NSCell class]
				     numberOfRows: 1
				  numberOfColumns: 4];
  [selectionView setTarget: self];
  [selectionView setAction: @selector(setCurrentInspector:)];
  [selectionView setCellSize: NSMakeSize(52,52)];
  [selectionView setIntercellSpacing: NSMakeSize(0,0)];
  [selectionView setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  cell = [selectionView cellAtRow: 0 column: 0];
  [cell setStringValue: @"Attr"];
  cell = [selectionView cellAtRow: 0 column: 1];
  [cell setStringValue: @"Size"];
  cell = [selectionView cellAtRow: 0 column: 2];
  [cell setStringValue: @"Conn"];
  cell = [selectionView cellAtRow: 0 column: 3];
  [cell setStringValue: @"Help"];
  [[panel contentView] addSubview: selectionView]; 
  RELEASE(selectionView);

  inspectorView = [[NSView alloc] initWithFrame: inspectorRect];
  [inspectorView setAutoresizingMask:
    NSViewHeightSizable | NSViewWidthSizable];
  [[panel contentView] addSubview: inspectorView]; 
  RELEASE(inspectorView);

  [panel setFrameUsingName: @"Inspector"];
  [panel setFrameAutosaveName: @"Inspector"];

  current = -1;

  emptyView = [[NSButton alloc] initWithFrame: inspectorRect];
  [emptyView setAutoresizingMask:
    NSViewHeightSizable | NSViewWidthSizable];
  [emptyView setStringValue: @"Empty Selection"];
  [emptyView setBordered: NO];

  multipleView = [[NSButton alloc] initWithFrame: inspectorRect];
  [multipleView setAutoresizingMask:
    NSViewHeightSizable | NSViewWidthSizable];
  [multipleView setStringValue: @"Multiple Selection"];
  [multipleView setBordered: NO];

  [nc addObserver: self
	 selector: @selector(selectionChanged:)
	     name: IBSelectionChangedNotification
	   object: nil];
  [self setCurrentInspector: 0];
  return self;
}

- (NSPanel*) panel
{
  return panel;
}

- (void) selectionChanged: (NSNotification*)notification
{
  [self setCurrentInspector: self];
}

- (void) setCurrentInspector: (id)anObj
{
  id<IBSelectionOwners>	owner = [(id<IB>)NSApp selectionOwner];
  unsigned		count = [owner selectionCount];
  NSArray		*sub = [inspectorView subviews];
  IBInspector		*newInspector = nil;
  NSView		*newView = nil;

  if (anObj != self)
    {
      current = [anObj selectedColumn];
    }

  if (count == 0)
    {
      newView = emptyView;
    }
  else if (count > 1)
    {
      newView = multipleView;
    }
  else
    {
      id	obj = [[owner selection] lastObject];
      NSString	*name;
      Class	c;

      switch (current)
	{
	  case 0: name = [obj inspectorClassName]; break;
	  case 1: name = [obj connectInspectorClassName]; break;
	  case 2: name = [obj sizeInspectorClassName]; break;
	  case 3: name = [obj helpInspectorClassName]; break;
	  default: name = [obj classInspectorClassName]; break;
	}
      c = NSClassFromString(name);
      if (inspector == nil || [inspector class] != c)
	{
	  newInspector = [c new];
	  newView = [[newInspector window] contentView];
	}
      else
	{
	  newInspector = inspector;
	}
    }

  if (newInspector != inspector)
    {
      if (inspector != nil)
	{
	  [[inspector window] setContentView: [sub lastObject]];
	  RELEASE((id)inspector);
	  sub = [inspectorView subviews];
	}
      inspector = newInspector;
    }
  if (newView != nil)
    {
      if ([sub count] > 0)
	{
	  [inspectorView replaceSubview: [sub lastObject] with: newView];
	}
      else
	{
	  [inspectorView addSubview: newView];
	}
    }
}

@end
