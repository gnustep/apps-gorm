/* GormProtocol.h
 *
 * Copyright (C) 1999, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2005
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

#ifndef INCLUDED_GormProtocol_h
#define INCLUDED_GormProtocol_h

#include <Foundation/Foundation.h>

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
@protocol GormAppDelegate

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

/**
 * Asks whether an older archive format should be upgraded to the current format.
 * Returns YES to proceed with upgrade, NO to cancel.
 */
- (BOOL) shouldUpgradeOlderArchive;

/**
 * Asks whether a newer archive format should be loaded. Returns YES to proceed,
 * NO to cancel.
 */
- (BOOL) shouldLoadNewerArchive;

/**
 * Asks whether connections should be broken when a class is removed. Returns YES
 * to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsForClassNamed: (NSString *)className;

/**
 * Asks whether connections should be renamed when a class is renamed. Returns YES
 * to rename connections, NO to keep original names.
 */
- (BOOL) shouldRenameConnectionsForClassNamed: (NSString *)className toClassName: (NSString *)newName;

/**
 * Asks whether connections should be broken when modifying an action or outlet
 * label. Returns YES to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsModifyingLabel: (NSString *)name isAction: (BOOL)action prompted: (BOOL)prompted;

/**
 * Notifies that a class could not be parsed at the specified path.
 */
- (void) couldNotParseClassAtPath: (NSString *)path;

/**
 * Notifies that an exception occurred while parsing a class.
 */
- (void) exceptionWhileParsingClass: (NSException *)localException;

/**
 * Asks whether connections should be broken when reparsing a class. Returns YES
 * to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsReparsingClass: (NSString *)className;

/**
 * Notifies that an exception occurred while loading a model file.
 */
- (void) exceptionWhileLoadingModel: (NSString *)errorMessage;

@end

#endif
