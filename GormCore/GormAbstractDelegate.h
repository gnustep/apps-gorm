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

@interface GormAbstractDelegate : NSObject <IB, GormAppDelegate, GormServer>
{
  IBOutlet id            gormMenu;
  IBOutlet id            guideLineMenuItem;

  GormPrefController    *preferencesController;
  GormClassManager	*classManager;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  GormPluginManager	*pluginManager;
  id<IBSelectionOwners>	 selectionOwner;
  BOOL			 isConnecting;
  BOOL			 isTesting;
  id             	 testContainer;
  NSMenu		*mainMenu; // saves the main menu...
  NSMenu                *servicesMenu; // saves the services menu...
  NSMenu                *classMenu; // so we can set it for the class view
  NSDictionary		*menuLocations;
  NSImage		*linkImage;
  NSImage		*sourceImage;
  NSImage		*targetImage;
  NSImage               *gormImage;
  NSImage               *testingImage;
  id			 connectSource;
  id			 connectDestination;
  NSMutableArray        *testingWindows;
  NSSet                 *topObjects;
  NSDockTile            *dockTile;
}

// testing the interface
- (IBAction) deferredEndTesting: (id) sender;
- (IBAction) testInterface: (id)sender;
- (IBAction) endTesting: (id)sender;

@end

#endif // import guard
