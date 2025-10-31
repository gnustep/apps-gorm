/* GormPluginManager.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999, 2003
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

#ifndef INCLUDED_GormPluginManager_h
#define INCLUDED_GormPluginManager_h

#include <Foundation/Foundation.h>

@class NSMutableArray, NSMutableDictionary, NSDictionary, NSArray, NSBundle;
@class NSPanel, NSMatrix, NSView;

/**
 * GormPluginManager handles loading and managing Gorm plugin bundles. Plugins extend Gorm's functionality by providing additional palettes, inspectors, or custom object types.
 */
@interface GormPluginManager : NSObject
{
  NSMutableArray	*bundles;
  NSMutableDictionary	*pluginsDict;
  NSMutableArray        *plugins;
  NSMutableArray        *pluginNames;
}

// methods for loading and managing plugins
/**
 * Loads a plugin bundle from the specified file system path and registers it
 * with Gorm so that any provided palettes, inspectors, or extensions become
 * available.
 */
- (BOOL) loadPlugin: (NSString*)path;
/**
 * Opens the plugin management UI or triggers the default action for plugins,
 * depending on the sender.
 */
- (id) openPlugin: (id) sender;
@end

#endif
