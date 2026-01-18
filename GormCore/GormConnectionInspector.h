/* GormConnectionInspector.m
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

#ifndef INCLUDED_GormConnectionInspector_h
#define INCLUDED_GormConnectionInspector_h

#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

@class NSBrowser, NSArray, NSMutableArray;

/**
 * GormConnectionInspector is the inspector used to connect outlets and actions
 * between objects. It shows existing connections and lets users create or
 * remove them.
 */
@interface GormConnectionInspector : IBInspector
{
  id			currentConnector;
  NSMutableArray	*connectors;
  NSArray		*actions;
  NSArray		*outlets;
  NSBrowser		*newBrowser;
  NSBrowser		*oldBrowser;
}

/**
 * Update the enabled state and titles of buttons based on the current
 * selection and connector state.
 */
- (void) updateButtons;

/**
 * Perform intelligent connection selection based on type information and name heuristics.
 * This method is called when a connection drag is completed to automatically select
 * the most appropriate outlet or action.
 */
- (void) performIntelligentConnectionSelection;

/**
 * Check if the destination object is compatible with the given outlet type.
 * Returns YES if the destination can be connected to an outlet of the specified type.
 */
- (BOOL) isDestinationCompatibleWithOutletType: (NSString *)outletType;

/**
 * Get the expected class name for an outlet based on its name and type.
 * Returns the most likely class that should be connected to this outlet.
 */
- (NSString *) expectedClassForOutlet: (NSString *)outletName;

/**
 * Calculate a matching score between an outlet/action name and a destination object.
 * Higher scores indicate better matches. Uses name heuristics like substring matching.
 */
- (NSInteger) matchingScoreForName: (NSString *)name withDestination: (id)destination;

/**
 * Find the best outlet to connect based on type compatibility and name heuristics.
 * Returns the outlet name that should be automatically selected, or nil if none found.
 */
- (NSString *) findBestOutletForDestination: (id)destination;

/**
 * Find the best action to connect based on name heuristics.
 * Returns the action name that should be automatically selected, or nil if none found.
 */
- (NSString *) findBestActionForDestination: (id)destination;

/**
 * Find the best action to connect based on name heuristics with a provided action list.
 * Returns the action name that should be automatically selected, or nil if none found.
 */
- (NSString *) findBestActionForDestination: (id)destination withActions: (NSArray *)actionList;

/**
 * Determine whether actions should be preferred over outlets for the given destination.
 * Returns YES for interactive controls like buttons where actions are more common.
 */
- (BOOL) shouldPreferActionsForDestination: (id)destination;

@end

#endif
