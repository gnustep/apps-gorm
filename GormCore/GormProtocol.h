/* GormProtocol.h
 *
 * Copyright (C) 1999, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2005
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef INCLUDED_GormProtocol_h
#define INCLUDED_GormProtocol_h

#include <Foundation/Foundation.h>
#include <GormCore/GormDocumentPolicy.h>

@class GormClassManager;
@class GormInspectorsManager;
@class GormPalettesManager;
@class GormPluginManager;

@class NSMenu;
@class NSString;

/**
 * GormAppDelegate defines the protocol that the Gorm application delegate
 * must implement. It provides methods for managing connections, accessing
 * managers, and handling various document operations and error conditions.
 */
@protocol GormAppDelegate <GormDocumentPolicy>

/**
 * Returns the source object for the current connection being created.
 */
- (id) connectSource;

/**
 * Returns the destination object for the current connection being created.
 */
- (id) connectDestination;

/**
 * Displays the connection line between the source and destination objects.
 */
- (void) displayConnectionBetween: (id)source and: (id)destination;

/**
 * Returns YES if the application is currently in connection mode, NO otherwise.
 */
- (BOOL) isConnecting;

/**
 * Stops the current connection operation and exits connection mode.
 */
- (void) stopConnecting;

/**
 * Returns the palettes manager instance.
 */
- (GormPalettesManager*) palettesManager;

/**
 * Returns the inspectors manager instance.
 */
- (GormInspectorsManager*) inspectorsManager;

/**
 * Returns the plugin manager instance.
 */
- (GormPluginManager*) pluginManager;

/**
 * Returns the class manager instance for managing custom classes.
 */
- (GormClassManager*) classManager;

/**
 * Returns the class menu for the class editor view.
 */
- (NSMenu*) classMenu;

/**
 * Returns YES if running as the command-line gormtool, NO if running as the
 * Gorm application.
 */
- (BOOL) isInTool;


@end

#endif
