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

#include <AppKit/NSNibConnector.h>
#include <Foundation/NSException.h>
#include "GormPrivate.h"

#define HASFORMATTER(obj) \
      [obj respondsToSelector: @selector(cell)] && \
      [[obj cell] respondsToSelector: @selector(formatter)] && \
      [[obj cell] formatter] != nil

/*
 *	The GormEmptyInspector is a placeholder for an empty selection.
 */
@interface GormEmptyInspector : IBInspector
@end

@implementation GormEmptyInspector
- (void) dealloc
{
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: _(@"Empty Selection")];
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
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: _(@"Multiple Selection")];
      [button setBordered: NO];
      [button setEnabled: NO];
      [contents addSubview: button];
      RELEASE(button);
    }
  return self;
}
@end

/*
 *	The GormNotApplicableInspector is a uitility for odd objects.
 */
@interface GormNotApplicableInspector : IBInspector
@end

@implementation GormNotApplicableInspector
- (void) dealloc
{
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView	*contents;
      NSButton	*button;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      button = [[NSButton alloc] initWithFrame: [contents bounds]];
      [button setAutoresizingMask:
	NSViewHeightSizable | NSViewWidthSizable];
      [button setStringValue: _(@"Not Applicable")];
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
  RELEASE(oldInspector);
  RELEASE(cache);
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
  else if ([name isEqual: NSWindowDidResignKeyNotification] == YES)
    {
      if (current == 1)
	{
	  /* FIXME - need to fix window focus handling for this to work */
	  // [NSApp stopConnecting];
	}
    }
  else if ([name isEqual: IBWillCloseDocumentNotification] == YES)
    {
      // FIXME
      // show an empty selection of the document closes
      // [self setEmptyInspector];
      // [panel orderOut: self];
    }
}

- (id) init
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSBox		*bar;
  NSMenuItem	*item;
  NSRect	contentRect = {{0, 0}, {IVW, 420}};
  NSRect	popupRect = {{60, 5}, {152, 20}};
  NSRect	selectionRect = {{0, 390}, {IVW, 30}};
  NSRect	inspectorRect = {{0, 0}, {IVW, IVH}};
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask;

  cache = [NSMutableDictionary new];
  panel = [[NSPanel alloc] initWithContentRect: contentRect
				     styleMask: style
				       backing: NSBackingStoreRetained
					 defer: NO];
  [panel setTitle: _(@"Inspector")];
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

  [popup addItemWithTitle: _(@"Attributes")];
  item = (NSMenuItem *)[popup itemAtIndex: 0];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"1"];
  [item setTag: 0];

  [popup addItemWithTitle: _(@"Connections")];
  item = (NSMenuItem *)[popup itemAtIndex: 1];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"2"];
  [item setTag: 1];

  [popup addItemWithTitle: _(@"Size")];
  item = (NSMenuItem *)[popup itemAtIndex: 2];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"3"];
  [item setTag: 2];

  [popup addItemWithTitle: _(@"Help")];
  item = (NSMenuItem *)[popup itemAtIndex: 3];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"4"];
  [item setTag: 3];

  [popup addItemWithTitle: _(@"Custom Class")];
  item = (NSMenuItem *)[popup itemAtIndex: 4];
  [item setTarget: self];
  [item setAction: @selector(setCurrentInspector:)];
  [item setKeyEquivalent: @"5"];
  [item setTag: 4];
  [item setEnabled: NO];

  bar = [[NSBox alloc] initWithFrame: NSMakeRect (0, 0, IVW, 2)];
  [bar setBorderType: NSGrooveBorder];
  [bar setTitlePosition: NSNoTitle];
  [bar setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  [selectionView addSubview: bar];
  RELEASE(bar);

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

  inspector = [GormEmptyInspector new];
  [cache setObject: inspector forKey: @"GormEmptyInspector"];
  RELEASE(inspector);
  inspector = [GormMultipleInspector new];
  [cache setObject: inspector forKey: @"GormMultipleInspector"];
  DESTROY(inspector);

  [self setCurrentInspector: 0];

  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillBeginTestingInterfaceNotification
      object: nil];
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillEndTestingInterfaceNotification
      object: nil];
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: NSWindowDidResignKeyNotification
      object: panel];
  [nc addObserver: self
      selector: @selector(updateInspectorPopUp:)
      name: NSPopUpButtonWillPopUpNotification
      object: popup];
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: NSPopUpButtonWillPopUpNotification
      object: popup];
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillCloseDocumentNotification
      object: [(id<IB>)NSApp activeDocument]];
  [popup setTarget: self];
  [popup setAction: @selector(updateInspectorPopUp:)];
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
      current = 1;
    }
  else if (current >= [popup numberOfItems])
    {
      current = 1;
    }
  [self setCurrentInspector: self];
}

- (void) setClassInspector
{
  current = 4;
  [self setCurrentInspector: self];
}

- (void) setEmptyInspector
{
  NSString *newInspector = @"GormEmptyInspector";
  NSView	*newView = nil;

  // current = 1;
  [panel setTitle: @"Inspector"];
  inspector = [cache objectForKey: newInspector];
  if(inspector == nil)
    {
	  Class	c = NSClassFromString(newInspector);
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

      /*
       * Make the inspector view the correct size for the viewable panel,
       * and set the frame size for the new contents before adding them.
       */
      [inspectorView setFrame: rect];
      rect.origin = NSZeroPoint;
      [newView setFrame: rect];
      [inspectorView addSubview: newView];
    }
}

- (void) setCurrentInspector: (id)anObj
{
  NSArray	*selection = [[(id<IB>)NSApp selectionOwner] selection];
  unsigned	count = [selection count];
  id		obj = [selection lastObject];
  NSView	*newView = nil;
  NSString	*newInspector = nil;

  if (anObj != self)
    {
      current = [anObj tag];
    }

  // Operate on the document view if the selected object is a NSScrollView
  if ([obj isKindOfClass: [NSScrollView class]]
    && ([(NSScrollView *)obj documentView] != nil)
    && ([[(NSScrollView *)obj documentView] isKindOfClass: [NSTableView class]]
    || [[(NSScrollView *)obj documentView] isKindOfClass: [NSTextView class]]))
    {
      obj = [(NSScrollView *)obj documentView];
    }

  /*
   * Set panel title for the type of object being inspected.
   */
  if (obj == nil)
    {
      [panel setTitle: _(@"Inspector")];
    }
  else if ([obj isKindOfClass: [GormClassProxy class]])
    {
      [panel setTitle: [NSString stringWithFormat: @"Class Edit Inspector:%@",
				 [obj className]]];
    }
  else
    {
      NSString *newTitle = [obj className]; 
      [panel setTitle: [NSString stringWithFormat:_(@"%@ Inspector"), newTitle]];
    }

  if (count == 0)
    {
      newInspector = @"GormEmptyInspector";
    }
  else if (count > 1)
    {
      newInspector = @"GormMultipleInspector";
    }
  else
    {
      switch (current)
	{
	  case 0: newInspector = [obj inspectorClassName]; break;
	  case 1: newInspector = [obj connectInspectorClassName]; break;
	  case 2: newInspector = [obj sizeInspectorClassName]; break;
	  case 3: newInspector = [obj helpInspectorClassName]; break;
          case 5: 
            {
              // If the object doesn't understand formatter then default to attributes
              if (HASFORMATTER(obj))
                {
                  newInspector = [ [[obj cell] formatter] inspectorClassName];
                }
              else
                {
                  current = 0;
                  [popup selectItemAtIndex: 0];
                  newInspector = [obj inspectorClassName];
                }
              break;
            }  
	  default: newInspector = [obj classInspectorClassName]; break;
	}
    }

  if (newInspector == nil)
    newInspector = @"GormNotApplicableInspector";

  if ([oldInspector isEqual: newInspector] == NO)
    {
      /*
       * Return the inspector view to its original window and release the old
       * inspector.
       */
      [[inspector okButton] removeFromSuperview];
      [[inspector revertButton] removeFromSuperview];
      [[inspector window] setContentView:
	[[inspectorView subviews] lastObject]];
      [popup selectItemAtIndex: current];

      ASSIGN(oldInspector, newInspector);
      inspector = [cache objectForKey: newInspector];
      if (inspector == nil)
	{
	  Class	c = NSClassFromString(newInspector);

	  inspector = [c new];
	  /* Try to gracefully handle an inspector creation error */
	  while (inspector == nil && (obj = [obj superclass]) 
		 && current == 0)
	    {
	      NSDebugLog(@"Error loading %@ inspector", newInspector);
	      newInspector = [obj inspectorClassName];
	      inspector = [NSClassFromString(newInspector) new];
	    }
	  [cache setObject: inspector forKey: newInspector];
	  RELEASE(inspector);
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
	      buttonsRect.size.height = IVB;
	      rect.origin.y += IVB;
	      rect.size.height -= IVB;

	      buttonView = [[NSView alloc] initWithFrame: buttonsRect];
	      [buttonView setAutoresizingMask:
		NSViewHeightSizable | NSViewWidthSizable];
	      [outer addSubview: buttonView];
	      RELEASE(buttonView);

	      ok = [inspector okButton];
	      if (ok != nil)
		{
		  bRect = [ok frame];
		  bRect.origin.y = 10;
		  bRect.origin.x = buttonsRect.size.width-10-bRect.size.width;
		  [ok setFrame: bRect];
		  [buttonView addSubview: ok];
		}

	      revert = [inspector revertButton];
	      if (revert != nil)
		{
		  bRect = [revert frame];
	 	  bRect.origin.y = 10;
		  bRect.origin.x = 10;
		  [revert setFrame: bRect];
		  [buttonView addSubview: revert];
		}
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
    }

  [inspector setObject: obj];
}

/* This is to include the formatter item in the pop up button
 * if the selected object in Gorm has a formatter set
 */
- (void) updateInspectorPopUp: (NSNotification*)aNotification
{
  NSArray	*selection = [[(id<IB>)NSApp selectionOwner] selection];
  id		obj = [selection lastObject];
 
  // See if the selected object has a formatter
  if (HASFORMATTER(obj))
    {
      // Ifso add the Formatter menu item if not already there
      if ([popup numberOfItems] < 6)
        {
          NSMenuItem *item;
          [popup addItemWithTitle: _(@"Formatter")];
          item = (NSMenuItem *)[popup itemAtIndex: 5];
          [item setTarget: self];
          [item setAction: @selector(setCurrentInspector:)];
          [item setKeyEquivalent: @"6"];
          [item setTag: 5];
        }
    }
  else
    {
      // Remove the Formatter menu item
      if ([popup numberOfItems] == 6)
        {
          [popup removeItemAtIndex: 5];
        }
    }
}

@end



@interface GormConnectionInspector : IBInspector
{
  id			currentConnector;
  NSMutableArray	*connectors;
  NSArray		*actions;
  NSArray		*outlets;
  NSBrowser		*newBrowser;
  NSBrowser		*oldBrowser;
}
- (void) updateButtons;
@end

@implementation GormConnectionInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  int		rows = 0;

  if (sender == newBrowser)
    {
      if (column == 0)
	{
	  rows = [outlets count];
	}
      else
	{
	  NSString	*name = [[sender selectedCellInColumn: 0] stringValue];

	  if ([name isEqual: @"target"])
	    {
	      rows = [actions count];
	    }
	}
    }
  else
    {
      rows = [connectors count];
    }
  return rows;
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  if (sender == newBrowser)
    {
      if (column == 0)
	{
	  return @"Outlets";
	}
      else
	{
	  NSString	*name = [[sender selectedCellInColumn: 0] stringValue];

	  if ([name isEqual: @"target"])
	    {
	      return @"Actions";
	    }
	  else
	    {
	      return @"";
	    }
	}
    }
  else
    {
      return @"Connections";
    }
}

- (void) _internalCall: (NSBrowser*)sender
{
  unsigned	numConnectors = [connectors count];
  unsigned	index;
  NSBrowserCell	*cell = [sender selectedCell];
  NSString	*title = [cell stringValue];
  int		col = [sender selectedColumn];

  if (sender == newBrowser)
    {
      if (col == 0)
	{
	  if ([title isEqual: @"target"])
	    {
	      id	con = nil;
	      NSString	*action;

	      for (index = 0; index < numConnectors; index++)
		{
		  con = [connectors objectAtIndex: index];
		  if ([con isKindOfClass: [NSNibControlConnector class]] == YES)
		    {
		      RELEASE(actions);
		      actions = RETAIN([[NSApp classManager]
			allActionsForObject: [con destination]]);
		      break;
		    }
		}
	      if (con == nil)
		{
		  RELEASE(actions);
		  actions = RETAIN([[NSApp classManager]
		    allActionsForObject: [NSApp connectDestination]]);
		  if ([actions count] > 0)
		    {
		      con = [NSNibControlConnector new];
		      [con setSource: object];
		      [con setDestination: [NSApp connectDestination]];
		      [con setLabel: [actions objectAtIndex: 0]];
		      AUTORELEASE(con);
		    }
		}
  	      if (currentConnector != con)
  		{
  		  ASSIGN(currentConnector, con);
  		}
	      /*
	       * Ensure that the actions are displayed in column one,
	       * and select the action for the current connection (if any).
	       */
	      [newBrowser reloadColumn: 1];
  	      action = [con label];
  	      if (action != nil)
  		{
  		  [newBrowser selectRow: [actions indexOfObject: action]
  			       inColumn: 1];
  		}
	    }
	  else
	    {
	      BOOL	found = NO;

	      /*
	       * See if there already exists a connector for this outlet.
	       */
	      for (index = 0; index < numConnectors; index++)
		{
		  id	con = [connectors objectAtIndex: index];

		  if ([con label] == nil || [[con label] isEqual: title] == YES)
		    {
		      ASSIGN(currentConnector, con);
		      found = YES;
		      break;
		    }
		}
	      /*
	       * if there was no connector, make one.
	       */
	      if (found == NO)
		{
		  RELEASE(currentConnector);
		  currentConnector = [NSNibOutletConnector new];
		  [currentConnector setSource: object];
		  [currentConnector setDestination: [NSApp connectDestination]];
		  [currentConnector setLabel: title];
		}
	    }
	  /*
	   * Update the bottom browser.
	   */
	  [oldBrowser loadColumnZero];
	  [oldBrowser selectRow: index inColumn: 0];
	  [NSApp displayConnectionBetween: object
				      and: [currentConnector destination]];
	}
      else
	{
	  BOOL	found = NO;

	  for (index = 0; index < numConnectors; index++)
	    {
	      id	con = [connectors objectAtIndex: index];

	      if ([con isKindOfClass: [NSNibControlConnector class]] == YES)
		{
		  NSString	*action = [con label];

		  if ([action isEqual: title] == YES)
		    {
		      ASSIGN(currentConnector, con);
		      found = YES;
		      break;
		    }
		}
	    }
	  if (found == NO)
	    {
	      RELEASE(currentConnector);
	      currentConnector = [NSNibControlConnector new];
	      [currentConnector setSource: object];
	      [currentConnector setDestination: [NSApp connectDestination]];
	      [currentConnector setLabel: title];
	      [oldBrowser loadColumnZero];
	    }
	  [oldBrowser selectRow: index inColumn: 0];
	}
    }
  else
    {
      for (index = 0; index < numConnectors; index++)
	{
	  id		con = [connectors objectAtIndex: index];
	  NSString	*label = [con label];

	  if ([title hasPrefix: label] == YES)
	    {
	      NSString	*name;
	      id	dest = [NSApp connectDestination];

	      dest = [con destination];
	      name = [[(id<IB>)NSApp activeDocument] nameForObject: dest];
	      name = [label stringByAppendingFormat: @" (%@)", name];
	      if ([title isEqual: name] == YES)
		{
		  NSString	*path = label;

		  ASSIGN(currentConnector, con);
		  /*
		   * Update the main browser to reflect selected connection
		   */
		  path = [@"/" stringByAppendingString: label];
		  if ([con isKindOfClass: [NSNibControlConnector class]] == YES)
		    {
		      path = [@"/target" stringByAppendingString: path];
		    }
		  [newBrowser setPath: path];
		  [NSApp displayConnectionBetween: object
					      and: [con destination]];
		  break;
		}
	    }
	}
    }
  [self updateButtons];
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)col
{
  NSMatrix	*matrix = [sender matrixInColumn: col];
  int		rows = [matrix numberOfRows];
  int		i;

  for (i = 0; i < rows; i++)
    {
      NSBrowserCell	*cell = [matrix cellAtRow: i column: 0];

      if ([[cell stringValue] isEqual: title] == YES)
        {
	  [matrix selectCellAtRow: i column: 0];
	  return YES;
	}
    }
  return NO;
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  if (sender == newBrowser)
    {
      NSString	*name;

      if (col == 0)
	{
	  if (row >= 0 && row < [outlets count])
	    {
	      name = [outlets objectAtIndex: row];
	      [aCell setStringValue: name];
	      if ([name isEqual: @"target"])
		{
		  [aCell setLeaf: NO];
		}
	      else
		{
		  [aCell setLeaf: YES];
		}
	      [aCell setEnabled: YES];
	    }
	  else
	    {
	      [aCell setStringValue: @""];
	      [aCell setLeaf: YES];
	      [aCell setEnabled: NO];
	    }
	}
      else
	{
	  name = [[sender selectedCellInColumn: 0] stringValue];
	  if ([name isEqual: @"target"] == NO)
	    {
	      NSDebugLog(@"cell selected in actions column without target");
	    }
	  if (row >= 0 && row < [actions count])
	    {
	      [aCell setStringValue: [actions objectAtIndex: row]];
	      [aCell setEnabled: YES];
	    }
	  else
	    {
	      [aCell setStringValue: @""];
	      [aCell setEnabled: NO];
	    }
	  [aCell setLeaf: YES];
	}
    }
  else
    {
      if (row >= 0 && row < [connectors count])
	{
	  NSString	*label;
	  NSString	*name;
	  id		dest = [NSApp connectDestination];

	  label = [[connectors objectAtIndex: row] label];
	  dest = [[connectors objectAtIndex: row] destination];
	  name = [[(id<IB>)NSApp activeDocument] nameForObject: dest];
	  name = [label stringByAppendingFormat: @" (%@)", name];

	  [aCell setStringValue: name];
	  [aCell setEnabled: YES];
	}
      else
	{
	  [aCell setStringValue: @""];
	  [aCell setEnabled: NO];
	}
      [aCell setLeaf: YES];
    }
}

- (void) dealloc
{
  RELEASE(currentConnector);
  RELEASE(connectors);
  RELEASE(actions);
  RELEASE(outlets);
  RELEASE(okButton);
  RELEASE(revertButton);
  [super dealloc];
}

- (void) handleNotification: (NSNotification *)notification
{
  // got the notification...  since we only subscribe to one, just do what
  // needs to be done.
  [self setObject: object];
  [self _internalCall: newBrowser]; // reload the connections browser..  
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSView		*contents;
      NSSplitView	*split;
      NSRect		rect;

      rect = NSMakeRect(0, 0, IVW, IVH);
      window = [[NSWindow alloc] initWithContentRect: rect
					   styleMask: NSBorderlessWindowMask
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];
      split = [[NSSplitView alloc] initWithFrame: [contents bounds]];
      [split setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

      newBrowser = [[NSBrowser alloc] initWithFrame: rect];
      [newBrowser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [newBrowser setMaxVisibleColumns: 2];
      [newBrowser setAllowsMultipleSelection: NO];
      [newBrowser setHasHorizontalScroller: NO];
      [newBrowser setDelegate: self];
      [newBrowser setTarget: self];
      [newBrowser setAction: @selector(_internalCall:)];

      [split addSubview: newBrowser];
      RELEASE(newBrowser);

      rect.size.height /= 2;
      oldBrowser = [[NSBrowser alloc] initWithFrame: rect];
      [oldBrowser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [oldBrowser setMaxVisibleColumns: 1];
      [oldBrowser setAllowsMultipleSelection: NO];
      [oldBrowser setHasHorizontalScroller: NO];
      [oldBrowser setDelegate: self];
      [oldBrowser setTarget: self];
      [oldBrowser setAction: @selector(_internalCall:)];

      [split addSubview: oldBrowser];
      RELEASE(oldBrowser);

      [contents addSubview: split];
      RELEASE(split);

      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,70,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: _(@"Connect")];
      [okButton setEnabled: NO];

      revertButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,60,20)];
      [revertButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [revertButton setAction: @selector(revert:)];
      [revertButton setTarget: self];
      [revertButton setTitle: _(@"Revert")];
      [revertButton setEnabled: NO];

      // catch notifications concerning connection deletions...
      [nc addObserver: self 
	  selector: @selector(handleNotification:)
	  name: IBDidRemoveConnectorNotification
	  object: nil];
    }
  return self;
}

- (void) ok: (id)sender
{
  if([currentConnector destination] == nil ||
     [currentConnector source] == nil)
    {
      NSRunAlertPanel(_(@"Problem making connection"),
		      _(@"Please select a valid destination."), 
		      _(@"OK"), nil, nil, nil);
    }
  else if ([connectors containsObject: currentConnector] == YES)
    {
      [[(id<IB>)NSApp activeDocument] removeConnector: currentConnector];
      if ([currentConnector isKindOfClass: [NSNibOutletConnector class]])
	{
	  [currentConnector setDestination: nil];

	  if ([[currentConnector source] isKindOfClass: [GormObjectProxy class]] == YES)
	  {
	    [NSException raise: NSInternalInconsistencyException
			 format: @"Source is a GormProxyObject: invalid connection."];
	  }
	}
      if ([currentConnector isKindOfClass: [NSNibControlConnector class]])
	{
	  [currentConnector setDestination: nil];
	  [currentConnector setLabel: nil];
	}
      [connectors removeObject: currentConnector];
      [oldBrowser loadColumnZero];
    }
  else
    {
      NSString	*path;
      id	dest;

      /*
       * Establishing a target/action type connection will automatically
       * remove any previous target/action connection.
       */
      if ([currentConnector isKindOfClass: [NSNibControlConnector class]])
	{
	  NSEnumerator	*enumerator = [connectors objectEnumerator];
	  id		con;

	  while ((con = [enumerator nextObject]) != nil)
	    {
	      if ([con isKindOfClass: [NSNibControlConnector class]])
		{
		  [[(id<IB>)NSApp activeDocument] removeConnector: con];
		  [con setDestination: nil];
		  [con setLabel: nil];
		  [connectors removeObjectIdenticalTo: con];
		  break;
		}
	    }
	}
      [connectors addObject: currentConnector];
      [[(id<IB>)NSApp activeDocument] addConnector: currentConnector];

      /*
       * We don't want to establish connections on proxy object as their
       * class are unknown to IB
       */
      if ([[currentConnector source] isKindOfClass: [GormObjectProxy class]] == YES ||
	  [[currentConnector destination] isKindOfClass: [GormObjectProxy class]] == YES)
	{
	    [NSException raise: NSInternalInconsistencyException
			 format: @"Source/Destination is a GormProxyObject: invalid connection."];
	}

      /*
       * When we establish a connection, we want to highlight it in
       * the browser so the user can see it has been done.
       */
      dest = [currentConnector destination];
      path = [[(id<IB>)NSApp activeDocument] nameForObject: dest];
      path = [[currentConnector label] stringByAppendingFormat: @" (%@)", path];
      path = [@"/" stringByAppendingString: path];
      [oldBrowser loadColumnZero];
      [oldBrowser setPath: path];
    }
  [[(id<IB>)NSApp activeDocument] touch];	/* mark as edited.	*/
  [self updateButtons];
}

- (void) setObject: (id)anObject
{
  if (anObject != nil) 
    {
      NSArray		*array;

      ASSIGN(object, anObject);
      DESTROY(currentConnector);
      RELEASE(connectors);

      /*
       * Create list of existing connections for selected object.
       */
      connectors = [NSMutableArray new];
      array = [[(id<IB>)NSApp activeDocument] connectorsForSource: object
	ofClass: [NSNibControlConnector class]];
      [connectors addObjectsFromArray: array];
      array = [[(id<IB>)NSApp activeDocument] connectorsForSource: object
	ofClass: [NSNibOutletConnector class]];
      [connectors addObjectsFromArray: array];

      RELEASE(outlets);
      outlets = RETAIN([[NSApp classManager] allOutletsForObject: object]); 
      DESTROY(actions);

      [oldBrowser loadColumnZero];

      /*
       * See if we can do initial selection based on pre-existing connections.
       */
      if ([NSApp isConnecting] == YES)
	{
	  id dest = [currentConnector destination];
	  unsigned row;

	  for (row = 0; row < [connectors count]; row++)
	    {
	      id<IBConnectors>	con = [connectors objectAtIndex: row];

	      if ([con destination] == dest)
		{
		  ASSIGN(currentConnector, con);
		  [oldBrowser selectRow: row inColumn: 0];
		  break;
		}
	    }
	}

      [newBrowser loadColumnZero];
      if (currentConnector == nil)
	{
	  if ([connectors count] > 0)
	    {
	      currentConnector = RETAIN([connectors objectAtIndex: 0]);
	    }
	  else if ([outlets count] == 1)
	    {
	      [newBrowser selectRow: 0 inColumn: 0];
	      [newBrowser sendAction];
	    }
	}
      if ([currentConnector isKindOfClass:
	[NSNibControlConnector class]] == YES)
	{
	  [newBrowser setPath: @"/target"];
	  [newBrowser sendAction];
	}

      [self updateButtons];
    }
}

- (void) updateButtons
{
  if (currentConnector == nil)
    {
      [okButton setEnabled: NO];
    }
  else
    {
      id active = [(id<IB>)NSApp activeDocument];
      id src = [currentConnector source];
      id dest = [currentConnector destination];

      // highlight or unhiglight the connection depending on
      // the object being connected to.
      if((src == nil || src == [active firstResponder]) ||
	 ((dest == nil || dest == [active firstResponder]) &&
	  [currentConnector isKindOfClass: [NSNibOutletConnector class]] == YES))
	
	{
	  [okButton setEnabled: NO];
	}
      else
	{
	  [okButton setEnabled: YES];
	  if ([connectors containsObject: currentConnector] == YES)
	    {
	      [okButton setTitle: _(@"Disconnect")];
	    }
	  else
	    {
	      [okButton setTitle: _(@"Connect")];
	    }
	}
    }
}

- (BOOL) wantsButtons
{
  return YES;
}
@end
