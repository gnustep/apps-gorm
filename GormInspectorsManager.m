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
  return @"GormObjectInspector";
}
- (NSString*) connectInspectorClassName
{
  return @"GormObjectInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormObjectInspector";
}
- (NSString*) helpInspectorClassName
{
  return @"GormObjectInspector";
}
- (NSString*) classInspectorClassName
{
  return @"GormObjectInspector";
}
@end



/*
 *	The GormEmptyInspector is a placeholder for an empty selection.
 */
@interface GormEmptyInspector : IBInspector
@end

@implementation GormEmptyInspector
- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 360)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: @"Empty Selection"];
      [button setBordered: NO];
      [button setEnabled: NO];
      [contents addSubview: button];
      RELEASE(button);
    }
  return self;
}
@end



/*
 *	The GormObjectInspector is a placeholder for any object without a
 *	suitable inspector.
 */
@interface GormObjectInspector : IBInspector
@end

@implementation GormObjectInspector
- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 360)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: @"Unknown object"];
      [button setBordered: NO];
      [button setEnabled: NO];
      [contents addSubview: button];
      RELEASE(button);
    }
  return self;
}
@end



/*
 *	The GormMultipleInspector is a placeholder for a multiple selection.
 */
@interface GormMultipleInspector : IBInspector
@end

@implementation GormMultipleInspector
- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 360)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: @"Multiple Selection"];
      [button setBordered: NO];
      [button setEnabled: NO];
      [contents addSubview: button];
      RELEASE(button);
    }
  return self;
}
@end

@interface GormISelectionView : NSView
{
}
@end

@implementation GormISelectionView : NSView
@end



@implementation GormInspectorsManager

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(emptyInspector);
  RELEASE(multipleInspector);
  RELEASE(panel);
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([panel isVisible] == YES)
	{
	  hiddenDuringTest = YES;
	  [panel orderOut: self];
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if (hiddenDuringTest == YES)
	{
	  hiddenDuringTest = NO;
	  [panel orderFront: self];
	}
    }
}

- (id) init
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSMenuItem	*item;
  NSRect	contentRect = {{0, 0}, {272, 420}};
  NSRect	popupRect = {{60, 15}, {152, 20}};
  NSRect	selectionRect = {{0, 380}, {272, 40}};
  NSRect	inspectorRect = {{0, 0}, {272, 378}};
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask				| NSResizableWindowMask;

  panel = [[NSPanel alloc] initWithContentRect: contentRect
				     styleMask: style
				       backing: NSBackingStoreRetained
					 defer: NO];
  [panel setTitle: @"Inspector"];
  [panel setMinSize: [panel frame].size];

  /*
   * The selection view sits at the top of the panel and is always the
   * same height.
   */
  selectionView = [[GormISelectionView alloc] initWithFrame: selectionRect];
  [selectionView setAutoresizingMask:
    NSViewMinYMargin | NSViewWidthSizable];
  [[panel contentView] addSubview: selectionView]; 
  RELEASE(selectionView);

  /*
   * The selection view contains a popup menu identifying the type of
   * inspector being used.
   */
  popup = [[NSPopUpButton alloc] initWithFrame: popupRect pullsDown: NO];
  [popup setAutoresizingMask: NSViewMinXMargin | NSViewMaxXMargin];
  [selectionView addSubview: popup];
  RELEASE(popup);

  [popup addItemWithTitle: @"Attributes"];
  item = [popup itemAtIndex: 0];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"1"];
  [item setTag: 0];

  [popup addItemWithTitle: @"Connections"];
  item = [popup itemAtIndex: 1];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"2"];
  [item setTag: 1];

  [popup addItemWithTitle: @"Size"];
  item = [popup itemAtIndex: 2];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"3"];
  [item setTag: 2];

  [popup addItemWithTitle: @"Help"];
  item = [popup itemAtIndex: 3];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"4"];
  [item setTag: 3];

  /*
   * The inspector view fills the area below the selection view.
   */
  inspectorView = [[NSView alloc] initWithFrame: inspectorRect];
  [inspectorView setAutoresizingMask:
    NSViewHeightSizable | NSViewWidthSizable];
  [[panel contentView] addSubview: inspectorView]; 
  RELEASE(inspectorView);

  [panel setFrameUsingName: @"Inspector"];
  [panel setFrameAutosaveName: @"Inspector"];

  current = -1;

  emptyInspector = [GormEmptyInspector new];
  multipleInspector = [GormMultipleInspector new];

  [self setCurrentInspector: 0];

  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillBeginTestingInterfaceNotification
	   object: nil];
  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillEndTestingInterfaceNotification
	   object: nil];

  return self;
}

- (NSPanel*) panel
{
  return panel;
}

- (void) updateSelection
{
  if ([NSApp isConnecting] == YES)
    {
      [popup selectItemAtIndex: 1];
      [popup setNeedsDisplay: YES];
      [panel makeKeyAndOrderFront: self];
    }
  else
    {
      [self setCurrentInspector: self];
    }
}

- (void) setCurrentInspector: (id)anObj
{
  NSArray	*selection = [[(id<IB>)NSApp selectionOwner] selection];
  unsigned	count = [selection count];
  id		obj = [selection lastObject];
  NSView	*newView = nil;

  if (anObj != self)
    {
      current = [anObj tag];
    }

  /*
   * Set panel title for the type of object being inspected.
   */
  if (obj == nil)
    {
      [panel setTitle: @"Inspector"];
    }
  else
    {
      [panel setTitle: [NSString stringWithFormat: @"%@ Inspector",
	NSStringFromClass([obj class])]];
    }

  /*
   * Return the inspector view to its original window and release the old
   * inspector.
   */
  [[inspector window] setContentView: [[inspectorView subviews] lastObject]];
  DESTROY(inspector);
  
  if (count == 0 || count > 1)
    {
      inspector = RETAIN(emptyInspector);
    }
  else if (count > 1)
    {
      inspector = RETAIN(multipleInspector);
    }
  else
    {
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
      inspector = [c new];
    }

  newView = [[inspector window] contentView];
  if (newView != nil)
    {
      NSView	*outer = [panel contentView];
      NSRect	rect = [outer bounds];

      if (buttonView != nil)
	{
	  [buttonView removeFromSuperview];
	  buttonView = nil;
	}

      rect.size.height = [selectionView frame].origin.y;
      if ([inspector wantsButtons] == YES)
	{
	  NSRect	buttonsRect;
	  NSRect	bRect = NSMakeRect(0, 0, 60, 20);
	  NSButton	*ok;
	  NSButton	*revert;

	  buttonsRect = rect;
	  buttonsRect.size.height = 40;
	  rect.origin.y += 40;
	  rect.size.height -= 40;

	  buttonView = [[NSView alloc] initWithFrame: buttonsRect];
	  [buttonView setAutoresizingMask:
	    NSViewHeightSizable | NSViewWidthSizable];
	  [outer addSubview: buttonView];
	  RELEASE(buttonView);

	  ok = [inspector okButton];
	  if (ok == nil)
	    {
	      ok = AUTORELEASE([[NSButton alloc] initWithFrame: bRect]);
	      [ok setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
	      [ok setTitle: @"Ok"];
	      [ok setAction: @selector(ok:)];
	      [ok setTarget: inspector];
	    }
	  revert = [inspector revertButton];
	  if (revert == nil)
	    {
	      revert = AUTORELEASE([[NSButton alloc] initWithFrame: bRect]);
	      [revert setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
	      [revert setTitle: @"Revert"];
	      [revert setAction: @selector(revert:)];
	      [revert setTarget: inspector];
	    }

	  bRect = [ok frame];
	  bRect.origin.y = 10;
	  bRect.origin.x = buttonsRect.size.width - 10 - bRect.size.width;
	  [ok setFrame: bRect];

	  bRect = [revert frame];
	  bRect.origin.y = 10;
	  bRect.origin.x = 10;
	  [revert setFrame: bRect];

	  [buttonView addSubview: ok];
	  [buttonView addSubview: revert];
	}
      else
	{
	  [buttonView removeFromSuperview];
	}

      /*
       * Make the inspector view the correct size for the viewable panel,
       * and set the frame size for the new contents before adding them.
       */
      [inspectorView setFrame: rect];
      rect.origin = NSZeroPoint;
      [newView setFrame: rect];
      [inspectorView addSubview: newView];
    }
  /*
   * Tell inspector to update from its object.
   */
  [inspector revert: self];
}

@end
