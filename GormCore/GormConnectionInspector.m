/* GormInspectorsManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003,2005
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include "GormPrivate.h"
#include "GormConnectionInspector.h"

@interface GormConnectionCell : NSBrowserCell
{
  BOOL isOutletConnected;
}
@end
@implementation GormConnectionCell : NSBrowserCell

- (void) setIsOutletConnected:(BOOL)yn
{
  isOutletConnected = yn;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  if (isOutletConnected != NO)
    {
      NSImage *dimple_image = [NSImage imageNamed: @"common_Dimple"];
      NSRect  title_rect = cellFrame;
      NSRect  imgRect;

      if ([self isHighlighted] != NO)
        {
          [[self highlightColorInView: controlView] setFill];
          NSRectFill(cellFrame);
        }
      
      imgRect.size = [dimple_image size];
      imgRect.origin.x = MAX(NSMaxX(title_rect) - imgRect.size.width - 4.0, 0.);
      imgRect.origin.y = MAX(NSMidY(title_rect) - (imgRect.size.height/2.), 0.);

      title_rect.size.width -= imgRect.size.width + 8;
      [super drawInteriorWithFrame: title_rect inView: controlView];
      
      if (controlView != nil)
        {
          imgRect = [controlView centerScanRect: imgRect];
        }

      [dimple_image drawInRect: imgRect
                      fromRect: NSZeroRect
                     operation: NSCompositeSourceOver
                      fraction: 1.0
                respectFlipped: YES
                         hints: nil];
    }
  else
    {
      [super drawInteriorWithFrame: cellFrame inView: controlView];
    }
}

@end

@implementation GormConnectionInspector

- (id) init
{
  if ((self = [super init]) != nil)
    {      
      NSBundle *bundle = [NSBundle bundleForClass: [self class]];

      if([bundle loadNibNamed: @"GormConnectionInspector" owner: self topLevelObjects: NULL] == NO)
	{
	  NSLog(@"Couldn't load GormConnectionInsector");
	  return nil;
	}

      // Create the okay and revert buttons, programmatically, since we shouldn't 
      // add them to the view.  The wantsButtons handling code will do that.
      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,80,20)];
      [okButton setAutoresizingMask: NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: _(@"Connect")];
      [okButton setEnabled: NO];

      revertButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,80,20)];
      [revertButton setAutoresizingMask: NSViewMaxXMargin];
      [revertButton setAction: @selector(revert:)];
      [revertButton setTarget: self];
      [revertButton setTitle: _(@"Revert")];
      [revertButton setEnabled: NO];      
    }
  return self;
}

- (void) awakeFromNib
{
  [newBrowser setCellClass: [GormConnectionCell class]];
  [newBrowser setDoubleAction: @selector(ok:)];
}

- (NSInteger) browser: (NSBrowser*)sender numberOfRowsInColumn: (NSInteger)column
{
  NSInteger		rows = 0;

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

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (NSInteger)column
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

- (void) _selectAction: (NSString *)action
{
  /*
   * Ensure that the actions are displayed in column one,
   * and select the action for the current connection (if any).
   */
  [newBrowser reloadColumn: 1];
  if (action != nil)
    {
      [newBrowser selectRow: [actions indexOfObject: action]
		  inColumn: 1];
    }
}

- (void) _internalCall: (NSBrowser *)sender
{
  unsigned	 numConnectors = [connectors count];
  unsigned	 index = 0;
  NSBrowserCell	*cell = [sender selectedCell];
  NSString	*title = [cell stringValue];
  NSInteger	 col = [sender selectedColumn];

  if (sender == newBrowser)
    {
      if (col == 0)
	{
	  if ([title isEqual: @"target"])
	    {
	      id	con = nil;

	      for (index = 0; index < numConnectors; index++)
		{
		  con = [connectors objectAtIndex: index];
		  if ([con isKindOfClass: [NSNibControlConnector class]] == YES)
		    {
		      RELEASE(actions);
		      actions = [[(id<GormAppDelegate>)[NSApp delegate] classManager]
				  allActionsForObject: [con destination]];
		      actions = [actions sortedArrayUsingSelector: @selector(compare:)];
		      RETAIN(actions);
		      break;
		    }
		  else
		    {
		      con = nil;
		    }
		}

	      if (con == nil) // && [actions containsObject: [currentConnector label]] == NO) 
		{
		  RELEASE(actions);
		  actions = [[(id<GormAppDelegate>)[NSApp delegate] classManager]
			      allActionsForObject: [[NSApp delegate] connectDestination]];
		  actions = [actions sortedArrayUsingSelector: @selector(compare:)];
		  RETAIN(actions);		  
		  if ([actions count] > 0)
		    {
		      con = [[NSNibControlConnector alloc] init];
		      [con setSource: object];
		      [con setDestination: [[NSApp delegate] connectDestination]];
		      [con setLabel: [actions objectAtIndex: 0]];
		      AUTORELEASE(con);
		    }
		}

	      // if we changed the current connector, update to the new one...
  	      if (currentConnector != con)
  		{
  		  ASSIGN(currentConnector, con);
  		}

	      /*
	       * Ensure that the actions are displayed in column one,
	       * and select the action for the current connection (if any).
	       */
	      [self _selectAction: [con label]];
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
		  currentConnector = [[NSNibOutletConnector alloc] init];
		  [currentConnector setSource: object];
		  [currentConnector setDestination: [[NSApp delegate] connectDestination]];
		  [currentConnector setLabel: title];
		}
	    }
	  /*
	   * Update the bottom browser.
	   */
	  [oldBrowser loadColumnZero];
	  [oldBrowser selectRow: index inColumn: 0];
	  [[NSApp delegate] displayConnectionBetween: object
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
	      currentConnector = [[NSNibControlConnector alloc] init];
	      [currentConnector setSource: object];
	      [currentConnector setDestination: [[NSApp delegate] connectDestination]];
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
	      id	dest = [[NSApp delegate] connectDestination];

	      dest = [con destination];
	      name = [[(id<IB>)[NSApp delegate] activeDocument] nameForObject: dest];
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
		  [[NSApp delegate] displayConnectionBetween: object
					      and: [con destination]];
		  break;
		}
	    }
	}
    }

  // if it's a control connection select target, if not, don't
  // if([currentConnector isKindOfClass: [NSNib

  [self updateButtons];
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (NSInteger)col
{
  NSMatrix	*matrix = [sender matrixInColumn: col];
  NSInteger		rows = [matrix numberOfRows];
  NSInteger		i;

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
	   atRow: (NSInteger)row
	  column: (NSInteger)col
{
  [aCell setRefusesFirstResponder: YES];
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

              // Draws dimple for connected outlets
              NSEnumerator *en = [connectors objectEnumerator];
              id conn = nil;
              while ((conn = [en nextObject]) != nil)
                {
                  if ([name isEqualToString: [conn label]])
                    {
                      [aCell setIsOutletConnected: YES];
                      break;
                    }
                }
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
	  id		dest = [[NSApp delegate] connectDestination];

	  label = [[connectors objectAtIndex: row] label];
	  dest = [[connectors objectAtIndex: row] destination];
	  name = [[(id<IB>)[NSApp delegate] activeDocument] nameForObject: dest];
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
  [self setObject: object]; // resets the browser...
}

- (void) ok: (id)sender
{
  if([currentConnector destination] == nil ||
     [currentConnector source] == nil)
    {
      NSRunAlertPanel(_(@"Problem making connection"),
		      _(@"Please select a valid destination."), 
		      _(@"OK"), nil, nil, nil);
      return;
    }
  else if ([connectors containsObject: currentConnector] == YES)
    {
      id con = currentConnector;

      [[(id<IB>)[NSApp delegate] activeDocument] removeConnector: con];
      [connectors removeObject: con];
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
		  [[(id<IB>)[NSApp delegate] activeDocument] removeConnector: con];
		  [connectors removeObjectIdenticalTo: con];
		  break;
		}
	    }

	  // select the new action from the list...
	  [self _selectAction: [currentConnector label]];
	}
      [connectors addObject: currentConnector];
      [[(id<IB>)[NSApp delegate] activeDocument] addConnector: currentConnector];
      
      /*
       * When we establish a connection, we want to highlight it in
       * the browser so the user can see it has been done.
       */
      dest = [currentConnector destination];
      path = [[(id<IB>)[NSApp delegate] activeDocument] nameForObject: dest];
      path = [[currentConnector label] stringByAppendingFormat: @" (%@)", path];
      path = [@"/" stringByAppendingString: path];
      [oldBrowser loadColumnZero];
      [oldBrowser setPath: path];
    }

  // Update image marker in "Outlets" browser
  NSString *newPath = [newBrowser path];
  [newBrowser loadColumnZero];
  [newBrowser setPath:newPath];
  
  // mark as edited.   
  [super ok: sender];
  [self updateButtons];
}

- (void) setObject: (id)anObject
{
  if (anObject != nil) 
    {
      NSArray		*array;

      [super setObject: anObject];
      RELEASE(connectors);

      /*
       * Create list of existing connections for selected object.
       */
      connectors = [[NSMutableArray alloc] init];
      array = [[(id<IB>)[NSApp delegate] activeDocument] connectorsForSource: object
	ofClass: [NSNibControlConnector class]];
      [connectors addObjectsFromArray: array];
      array = [[(id<IB>)[NSApp delegate] activeDocument] connectorsForSource: object
	ofClass: [NSNibOutletConnector class]];
      [connectors addObjectsFromArray: array];

      RELEASE(outlets);
      outlets = [[(id<GormAppDelegate>)[NSApp delegate] classManager] allOutletsForObject: object];
      outlets = [outlets sortedArrayUsingSelector: @selector(compare:)];
      RETAIN(outlets);
      DESTROY(actions);

      [oldBrowser loadColumnZero];

      /*
       * See if we can do initial selection based on pre-existing connections.
       */
      if ([[NSApp delegate] isConnecting] == YES)
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

      // Perform intelligent connection selection if we're actively connecting
      // and no specific connection was already selected
      if ([[NSApp delegate] isConnecting] == YES && currentConnector == nil)
	{
	  [self performIntelligentConnectionSelection];
	}

      if ([currentConnector isKindOfClass: [NSNibControlConnector class]] == YES && 
	  [[NSApp delegate] isConnecting] == NO)
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
      GormDocument *active = (GormDocument *)[(id<IB>)[NSApp delegate] activeDocument];
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

- (void) performIntelligentConnectionSelection
{
  // Only perform intelligent selection when actively connecting
  if (![[NSApp delegate] isConnecting])
    {
      return;
    }
  
  id destination = [[NSApp delegate] connectDestination];
  if (destination == nil)
    {
      return;
    }
  
  // Check if a connection already exists for this destination
  NSEnumerator *connectorEnum = [connectors objectEnumerator];
  id<IBConnectors> connector;
  while ((connector = [connectorEnum nextObject]) != nil)
    {
      if ([connector destination] == destination)
        {
          // Connection already exists, select it
          ASSIGN(currentConnector, connector);
          [oldBrowser selectRow: [connectors indexOfObject: connector] inColumn: 0];
          return;
        }
    }
  
  // No existing connection found, find the best new connection
  // Get available actions directly from the class manager
  NSArray *availableActions = [[(id<GormAppDelegate>)[NSApp delegate] classManager] 
                               allActionsForObject: destination];
  NSString *bestAction = [self findBestActionForDestination: destination withActions: availableActions];
  NSString *bestOutlet = [self findBestOutletForDestination: destination];
  
  // Determine if we should prefer actions over outlets
  BOOL preferActions = [self shouldPreferActionsForDestination: destination];
  
  if (preferActions && bestAction != nil && [outlets containsObject: @"target"])
    {
      // Select target and then the best action
      NSInteger targetIndex = [outlets indexOfObject: @"target"];
      if (targetIndex != NSNotFound)
        {
          [newBrowser selectRow: targetIndex inColumn: 0];
          [newBrowser sendAction]; // This will populate the actions
          
          // Now select the best action in column 1
          NSInteger actionIndex = [actions indexOfObject: bestAction];
          if (actionIndex != NSNotFound)
            {
              [newBrowser selectRow: actionIndex inColumn: 1];
              [newBrowser sendAction];
            }
        }
    }
  else if (bestOutlet != nil)
    {
      // Select the best outlet
      NSInteger outletIndex = [outlets indexOfObject: bestOutlet];
      if (outletIndex != NSNotFound)
        {
          [newBrowser selectRow: outletIndex inColumn: 0];
          [newBrowser sendAction]; // Trigger the selection handler
        }
    }
  else if (bestAction != nil && [outlets containsObject: @"target"])
    {
      // Fallback: select target and action even if we don't prefer actions
      NSInteger targetIndex = [outlets indexOfObject: @"target"];
      if (targetIndex != NSNotFound)
        {
          [newBrowser selectRow: targetIndex inColumn: 0];
          [newBrowser sendAction]; // This will populate the actions
          
          // Now select the best action in column 1
          NSInteger actionIndex = [actions indexOfObject: bestAction];
          if (actionIndex != NSNotFound)
            {
              [newBrowser selectRow: actionIndex inColumn: 1];
              [newBrowser sendAction];
            }
        }
    }
}

- (BOOL) isDestinationCompatibleWithOutletType: (NSString *)outletType
{
  id destination = [[NSApp delegate] connectDestination];
  if (destination == nil || outletType == nil)
    {
      return NO;
    }
  
  NSString *destinationClass = NSStringFromClass([destination class]);
  
  // Common outlet type to class mappings
  static NSDictionary *typeMapping = nil;
  if (typeMapping == nil)
    {
      typeMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
        // UI Controls
        [NSArray arrayWithObjects: @"NSButton", @"GormNSButton", nil], @"button",
        [NSArray arrayWithObjects: @"NSTextField", @"GormNSTextField", @"NSSecureTextField", nil], @"textField",
        [NSArray arrayWithObjects: @"NSTextView", @"GormNSTextView", nil], @"textView",
        [NSArray arrayWithObjects: @"NSImageView", @"GormNSImageView", nil], @"imageView",
        [NSArray arrayWithObjects: @"NSScrollView", @"GormNSScrollView", nil], @"scrollView",
        [NSArray arrayWithObjects: @"NSTableView", @"GormNSTableView", nil], @"tableView",
        [NSArray arrayWithObjects: @"NSOutlineView", @"GormNSOutlineView", nil], @"outlineView",
        [NSArray arrayWithObjects: @"NSPopUpButton", @"GormNSPopUpButton", nil], @"popUpButton",
        [NSArray arrayWithObjects: @"NSComboBox", @"GormNSComboBox", nil], @"comboBox",
        [NSArray arrayWithObjects: @"NSSlider", @"GormNSSlider", nil], @"slider",
        [NSArray arrayWithObjects: @"NSStepper", @"GormNSStepper", nil], @"stepper",
        [NSArray arrayWithObjects: @"NSProgressIndicator", @"GormNSProgressIndicator", nil], @"progressIndicator",
        [NSArray arrayWithObjects: @"NSColorWell", @"GormNSColorWell", nil], @"colorWell",
        [NSArray arrayWithObjects: @"NSDatePicker", @"GormNSDatePicker", nil], @"datePicker",
        [NSArray arrayWithObjects: @"NSTabView", @"GormNSTabView", nil], @"tabView",
        [NSArray arrayWithObjects: @"NSSplitView", @"GormNSSplitView", nil], @"splitView",
        [NSArray arrayWithObjects: @"NSBox", @"GormNSBox", nil], @"box",
        [NSArray arrayWithObjects: @"NSMatrix", @"GormNSMatrix", nil], @"matrix",
        [NSArray arrayWithObjects: @"NSBrowser", @"GormNSBrowser", nil], @"browser",
        
        // Views and containers
        [NSArray arrayWithObjects: @"NSView", @"GormNSView", @"NSControl", @"NSButton", @"NSTextField", @"NSImageView", nil], @"view",
        [NSArray arrayWithObjects: @"NSControl", @"NSButton", @"NSTextField", @"NSSlider", @"NSPopUpButton", nil], @"control",
        [NSArray arrayWithObjects: @"NSCell", @"NSButtonCell", @"NSTextFieldCell", @"NSImageCell", nil], @"cell",
        
        // Window and menu items
        [NSArray arrayWithObjects: @"NSWindow", @"GormNSWindow", @"NSPanel", @"GormNSPanel", nil], @"window",
        [NSArray arrayWithObjects: @"NSPanel", @"GormNSPanel", nil], @"panel",
        [NSArray arrayWithObjects: @"NSMenu", @"GormNSMenu", nil], @"menu",
        [NSArray arrayWithObjects: @"NSMenuItem", @"GormNSMenuItem", nil], @"menuItem",
        nil];
    }
  
  // Try exact outlet name match first
  NSArray *compatibleClasses = [typeMapping objectForKey: outletType];
  if (compatibleClasses != nil)
    {
      NSEnumerator *classEnum = [compatibleClasses objectEnumerator];
      NSString *className;
      while ((className = [classEnum nextObject]) != nil)
        {
          if ([destinationClass isEqualToString: className] || 
              [destination isKindOfClass: NSClassFromString(className)])
            {
              return YES;
            }
        }
    }
  
  // Try partial matches for compound outlet names
  NSEnumerator *keyEnum = [[typeMapping allKeys] objectEnumerator];
  NSString *type;
  while ((type = [keyEnum nextObject]) != nil)
    {
      if ([[outletType lowercaseString] rangeOfString: type].location != NSNotFound || 
          [type rangeOfString: [outletType lowercaseString]].location != NSNotFound)
        {
          NSArray *classes = [typeMapping objectForKey: type];
          NSEnumerator *classEnum = [classes objectEnumerator];
          NSString *className;
          while ((className = [classEnum nextObject]) != nil)
            {
              if ([destination isKindOfClass: NSClassFromString(className)])
                {
                  return YES;
                }
            }
        }
    }
  
  return NO;
}

- (NSString *) expectedClassForOutlet: (NSString *)outletName
{
  if (outletName == nil)
    {
      return nil;
    }
  
  NSString *lowerName = [outletName lowercaseString];
  
  // Common outlet naming patterns
  if ([lowerName rangeOfString: @"button"].location != NSNotFound)
    return @"NSButton";
  if ([lowerName rangeOfString: @"textfield"].location != NSNotFound || [lowerName rangeOfString: @"field"].location != NSNotFound)
    return @"NSTextField";
  if ([lowerName rangeOfString: @"textview"].location != NSNotFound)
    return @"NSTextView";
  if ([lowerName rangeOfString: @"imageview"].location != NSNotFound || [lowerName rangeOfString: @"image"].location != NSNotFound)
    return @"NSImageView";
  if ([lowerName rangeOfString: @"scrollview"].location != NSNotFound)
    return @"NSScrollView";
  if ([lowerName rangeOfString: @"tableview"].location != NSNotFound || [lowerName rangeOfString: @"table"].location != NSNotFound)
    return @"NSTableView";
  if ([lowerName rangeOfString: @"outlineview"].location != NSNotFound || [lowerName rangeOfString: @"outline"].location != NSNotFound)
    return @"NSOutlineView";
  if ([lowerName rangeOfString: @"popupbutton"].location != NSNotFound || [lowerName rangeOfString: @"popup"].location != NSNotFound)
    return @"NSPopUpButton";
  if ([lowerName rangeOfString: @"combobox"].location != NSNotFound || [lowerName rangeOfString: @"combo"].location != NSNotFound)
    return @"NSComboBox";
  if ([lowerName rangeOfString: @"slider"].location != NSNotFound)
    return @"NSSlider";
  if ([lowerName rangeOfString: @"stepper"].location != NSNotFound)
    return @"NSStepper";
  if ([lowerName rangeOfString: @"progress"].location != NSNotFound)
    return @"NSProgressIndicator";
  if ([lowerName rangeOfString: @"colorwell"].location != NSNotFound || [lowerName rangeOfString: @"color"].location != NSNotFound)
    return @"NSColorWell";
  if ([lowerName rangeOfString: @"datepicker"].location != NSNotFound || [lowerName rangeOfString: @"date"].location != NSNotFound)
    return @"NSDatePicker";
  if ([lowerName rangeOfString: @"tabview"].location != NSNotFound || [lowerName rangeOfString: @"tab"].location != NSNotFound)
    return @"NSTabView";
  if ([lowerName rangeOfString: @"splitview"].location != NSNotFound || [lowerName rangeOfString: @"split"].location != NSNotFound)
    return @"NSSplitView";
  if ([lowerName rangeOfString: @"box"].location != NSNotFound)
    return @"NSBox";
  if ([lowerName rangeOfString: @"matrix"].location != NSNotFound)
    return @"NSMatrix";
  if ([lowerName rangeOfString: @"browser"].location != NSNotFound)
    return @"NSBrowser";
  if ([lowerName rangeOfString: @"window"].location != NSNotFound)
    return @"NSWindow";
  if ([lowerName rangeOfString: @"panel"].location != NSNotFound)
    return @"NSPanel";
  if ([lowerName rangeOfString: @"menu"].location != NSNotFound)
    return @"NSMenu";
  if ([lowerName rangeOfString: @"view"].location != NSNotFound)
    return @"NSView";
  
  return @"NSView"; // Default fallback
}

- (NSInteger) matchingScoreForName: (NSString *)name withDestination: (id)destination
{
  if (name == nil || destination == nil)
    {
      return 0;
    }
  
  NSString *destinationClass = NSStringFromClass([destination class]);
  NSString *lowerName = [name lowercaseString];
  NSString *lowerClass = [destinationClass lowercaseString];
  
  NSInteger score = 0;
  
  // Remove common prefixes from class name for better matching
  if ([lowerClass hasPrefix: @"gorm"])
    {
      lowerClass = [lowerClass substringFromIndex: 4];
    }
  if ([lowerClass hasPrefix: @"ns"])
    {
      lowerClass = [lowerClass substringFromIndex: 2];
    }
  
  // Exact class name match in outlet name gets highest score
  if ([lowerName rangeOfString: lowerClass].location != NSNotFound)
    {
      score += 100;
    }
  
  // Common naming patterns
  if ([lowerName hasSuffix: @"button"] && [lowerClass isEqualToString: @"button"])
    score += 80;
  if ([lowerName hasSuffix: @"field"] && [lowerClass isEqualToString: @"textfield"])
    score += 80;
  if ([lowerName hasSuffix: @"view"] && [lowerClass hasSuffix: @"view"])
    score += 70;
  if ([lowerName hasSuffix: @"textview"] && [lowerClass isEqualToString: @"textview"])
    score += 80;
  if ([lowerName hasSuffix: @"imageview"] && [lowerClass isEqualToString: @"imageview"])
    score += 80;
  if ([lowerName hasSuffix: @"scrollview"] && [lowerClass isEqualToString: @"scrollview"])
    score += 80;
  if ([lowerName hasSuffix: @"tableview"] && [lowerClass isEqualToString: @"tableview"])
    score += 80;
  
  // Action name heuristics (for actions like "print", "save", etc.)
  if ([lowerName hasPrefix: @"print"] || [lowerName rangeOfString: @"print"].location != NSNotFound)
    {
      if ([lowerClass isEqualToString: @"button"])
        score += 60;
    }
  if ([lowerName hasPrefix: @"save"] || [lowerName rangeOfString: @"save"].location != NSNotFound)
    {
      if ([lowerClass isEqualToString: @"button"])
        score += 60;
    }
  if ([lowerName hasPrefix: @"cancel"] || [lowerName rangeOfString: @"cancel"].location != NSNotFound)
    {
      if ([lowerClass isEqualToString: @"button"])
        score += 60;
    }
  if ([lowerName hasPrefix: @"ok"] || [lowerName rangeOfString: @"ok"].location != NSNotFound)
    {
      if ([lowerClass isEqualToString: @"button"])
        score += 60;
    }
  
  // Partial matches get some points
  NSArray *nameComponents = [lowerName componentsSeparatedByCharactersInSet:
    [NSCharacterSet characterSetWithCharactersInString: @"_-"]];
  NSEnumerator *compEnum = [nameComponents objectEnumerator];
  NSString *component;
  while ((component = [compEnum nextObject]) != nil)
    {
      if ([lowerClass rangeOfString: component].location != NSNotFound && [component length] > 2)
        {
          score += 30;
        }
    }
  
  return score;
}

- (NSString *) findBestOutletForDestination: (id)destination
{
  if (destination == nil || outlets == nil || [outlets count] == 0)
    {
      return nil;
    }
  
  NSString *bestOutlet = nil;
  NSInteger bestScore = 0;
  NSString *bestTypeMatchOutlet = nil;
  
  NSEnumerator *outletEnum = [outlets objectEnumerator];
  NSString *outlet;
  while ((outlet = [outletEnum nextObject]) != nil)
    {
      // Skip target outlet as it's for actions, not outlets
      if ([outlet isEqualToString: @"target"])
        {
          continue;
        }
      
      // Check type compatibility first
      if ([self isDestinationCompatibleWithOutletType: outlet])
        {
          if (bestTypeMatchOutlet == nil)
            {
              bestTypeMatchOutlet = outlet;
            }
          
          // Calculate name matching score
          NSInteger score = [self matchingScoreForName: outlet withDestination: destination];
          if (score > bestScore)
            {
              bestScore = score;
              bestOutlet = outlet;
            }
        }
    }
  
  // Return the best scoring outlet, or the first type-compatible one if no good name match
  return bestOutlet != nil ? bestOutlet : bestTypeMatchOutlet;
}

- (NSString *) findBestActionForDestination: (id)destination
{
  if (destination == nil || actions == nil || [actions count] == 0)
    {
      return nil;
    }
  
  NSString *bestAction = nil;
  NSInteger bestScore = 0;
  
  // Get the destination's class name for heuristic matching
  NSString *destinationClass = NSStringFromClass([destination class]);
  NSString *lowerClass = [destinationClass lowercaseString];
  
  NSEnumerator *actionEnum = [actions objectEnumerator];
  NSString *action;
  while ((action = [actionEnum nextObject]) != nil)
    {
      NSInteger score = [self matchingScoreForName: action withDestination: destination];
      
      // Bonus for common action patterns on buttons
      if ([lowerClass rangeOfString: @"button"].location != NSNotFound)
        {
          NSString *lowerAction = [action lowercaseString];
          if ([lowerAction hasPrefix: @"print"] || [lowerAction hasPrefix: @"save"] ||
              [lowerAction hasPrefix: @"cancel"] || [lowerAction hasPrefix: @"ok"] ||
              [lowerAction hasPrefix: @"apply"] || [lowerAction hasPrefix: @"close"] ||
              [lowerAction hasPrefix: @"show"] || [lowerAction hasPrefix: @"hide"])
            {
              score += 40;
            }
        }
      
      if (score > bestScore)
        {
          bestScore = score;
          bestAction = action;
        }
    }
  
  return bestAction;
}

- (NSString *) findBestActionForDestination: (id)destination withActions: (NSArray *)actionList
{
  if (destination == nil || actionList == nil || [actionList count] == 0)
    {
      return nil;
    }
  
  NSString *bestAction = nil;
  NSInteger bestScore = 0;
  
  // Get the destination's class name for heuristic matching
  NSString *destinationClass = NSStringFromClass([destination class]);
  NSString *lowerClass = [destinationClass lowercaseString];
  
  NSEnumerator *actionEnum = [actionList objectEnumerator];
  NSString *action;
  while ((action = [actionEnum nextObject]) != nil)
    {
      NSInteger score = [self matchingScoreForName: action withDestination: destination];
      
      // Bonus for common action patterns on buttons
      if ([lowerClass rangeOfString: @"button"].location != NSNotFound)
        {
          NSString *lowerAction = [action lowercaseString];
          if ([lowerAction hasPrefix: @"print"] || [lowerAction hasPrefix: @"save"] ||
              [lowerAction hasPrefix: @"cancel"] || [lowerAction hasPrefix: @"ok"] ||
              [lowerAction hasPrefix: @"apply"] || [lowerAction hasPrefix: @"close"] ||
              [lowerAction hasPrefix: @"show"] || [lowerAction hasPrefix: @"hide"])
            {
              score += 40;
            }
        }
      
      if (score > bestScore)
        {
          bestScore = score;
          bestAction = action;
        }
    }
  
  return bestAction;
}

- (BOOL) shouldPreferActionsForDestination: (id)destination
{
  if (destination == nil)
    {
      return NO;
    }
  
  NSString *destinationClass = NSStringFromClass([destination class]);
  NSString *lowerClass = [destinationClass lowercaseString];
  
  // Remove common prefixes
  if ([lowerClass hasPrefix: @"gorm"])
    {
      lowerClass = [lowerClass substringFromIndex: 4];
    }
  if ([lowerClass hasPrefix: @"ns"])
    {
      lowerClass = [lowerClass substringFromIndex: 2];
    }
  
  // Prefer actions for interactive controls
  if ([lowerClass isEqualToString: @"button"] || 
      [lowerClass isEqualToString: @"menuitem"] ||
      [lowerClass hasPrefix: @"button"])
    {
      return YES;
    }
  
  return NO;
}

@end
