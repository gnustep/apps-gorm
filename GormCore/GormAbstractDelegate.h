/* GormAppDelegate.m
 *
 * Copyright (C) 2023 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2023
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111
 * USA.
 */

#ifndef GNUSTEP_GormAbstractDelegate_H
#define GNUSTEP_GormAbstractDelegate_H

#import <InterfaceBuilder/InterfaceBuilder.h>
#import <GNUstepBase/GSObjCRuntime.h>

#import <GormCore/GormProtocol.h>
#import <GormCore/GormServer.h>

@class NSDictionary;
@class NSImage;
@class NSMenu;
@class NSMutableArray;
@class NSSet;
@class GormPrefController;
@class GormClassManager;
@class GormPalettesManager;
@class GormPluginManager;
@class NSDockTile;

/**
 * GormAbstractDelegate serves as the abstract base class for Gorm's application
 * delegate. It provides core functionality for managing the interface builder
 * environment including inspectors, palettes, plugins, and the testing mode.
 */
@interface GormAbstractDelegate : NSObject <IB, GormAppDelegate, GormServer>
{
  IBOutlet id            _gormMenu;
  IBOutlet id            _guideLineMenuItem;

  GormPrefController    *_preferencesController;
  GormClassManager	*_classManager;
  GormInspectorsManager	*_inspectorsManager;
  GormPalettesManager	*_palettesManager;
  GormPluginManager	*_pluginManager;
  id<IBSelectionOwners>	 _selectionOwner;
  BOOL			 _isConnecting;
  BOOL			 _isTesting;
  id             	 _testContainer;
  NSMenu		*_mainMenu; // saves the main menu...
  NSMenu                *_servicesMenu; // saves the services menu...
  NSMenu                *_classMenu; // so we can set it for the class view
  NSDictionary		*_menuLocations;
  NSImage		*_linkImage;
  NSImage		*_sourceImage;
  NSImage		*_targetImage;
  NSImage               *_gormImage;
  NSImage               *_testingImage;
  id			 _connectSource;
  id			 _connectDestination;
  NSMutableArray        *_testingWindows;
  NSSet                 *_topObjects;
  NSDockTile            *_dockTile;
}

/**
 * Defers the end of interface testing to allow proper cleanup.
 */
- (IBAction) deferredEndTesting: (id) sender;

/**
 * Begins testing the interface by simulating the application's runtime
 * environment.
 */
- (IBAction) testInterface: (id)sender;

/**
 * Ends the interface testing mode and returns to editing mode.
 */
- (IBAction) endTesting: (id)sender;

/**
 * Sets whether the interface is currently in testing mode.
 */
- (void) setTestingInterface: (BOOL)testing;

/**
 * Returns YES if the interface is currently in testing mode, NO otherwise.
 */
- (BOOL) isTestingInterface;

@end

#endif // import guard
