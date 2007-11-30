/* IBPlugin.h
 *
 * Copyright (C) 2007 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2007
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

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <AppKit/NSView.h>
#include <InterfaceBuilder/IBPlugin.h>

@implementation IBPlugin

// Getting the shared plugin...
/**
 * Returns the shared instance of the plugin.
 */
+ (id)sharedInstance
{
  return nil;
}

// Loading and unloading plugin resources.
/**
 * Notifies the receiver that the plugin will be loaded.
 */
- (void) didLoad
{
  // do nothing... will be overridden.
}

/**
 * Notifies the receiver that the plugin will be unloaded.
 */
- (void) willUnload
{
  // do nothing... will be overridden.
}

// Getting the plugins nib files.
/**
 * Return the array of custom nib filenames.  You are required to override
 * this method when creating a plugin.
 */
- (NSArray *) libraryNibNames
{
  return nil;
}

// Configuring the plugin
/**
 * Returns the name of the plugin to be displayed.
 */
- (NSString *) label
{
  return nil;
}

/**
 * The preferences panel/view that should be added to the preferences drop
 * down and preferences window.
 */
- (NSView *) preferencesView
{
  return nil;
}

/**
 * Returns the list of frameworks needed to support the plugin.
 */
- (NSArray *) requiredFrameworks
{
  return nil;
}

// Pasteboard notifications...
/**
 * Notifies the receiver that one of it's components will be added to the
 * document.
 */
- (NSArray *) pasteboardObjectsForDraggedLibraryView: (NSView *)view
{
  return nil;
}

/**
 * Notifies the receiver that objects were added to the document.
 */
- (void)      document: (id<IBDocuments>)document  
  didAddDraggedObjects: (NSArray *)roots 
fromDraggedLibraryView: (NSView *)view
{
  // do nothing;
}

@end

