/* GormTest.m
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface Controller: NSObject
{
}
- (id)open: (id) sender;
@end

@implementation Controller

- (id) open: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObject: @"nib"];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      [NSBundle loadNibFile: [oPanel filename]
	  externalNameTable:
	[NSDictionary dictionaryWithObject: NSApp forKey: @"NSOwner"]
		   withZone: NSDefaultMallocZone()];
      [[NSApp delegate] makeKeyAndOrderFront: self];
      return self;
    }
  return nil;		/* Failed	*/
}
@end

int 
main (void)
{ 
   NSAutoreleasePool	*pool;
   NSApplication	*app;
   NSMenu		*mainMenu;
   NSMenu		*windowsMenu;
   NSMenuItem		*menuItem;
   Controller		*appController;

   pool = [NSAutoreleasePool new];
   initialize_gnustep_backend ();
   app = [NSApplication sharedApplication];

   mainMenu = [[NSMenu alloc] initWithTitle: @"Gorm Test"];

   [mainMenu addItemWithTitle: @"Open" 
		       action: @selector(open:)
		keyEquivalent: @"o"];	

   menuItem = [mainMenu addItemWithTitle: @"Windows" 
				  action: NULL 
			   keyEquivalent: @""];
   windowsMenu = [NSMenu new];
   [mainMenu setSubmenu: windowsMenu forItem: menuItem];

   [mainMenu addItemWithTitle: @"Quit" 
		       action: @selector(terminate:)
		keyEquivalent: @"q"];	

   [app setMainMenu: mainMenu];
   [app setWindowsMenu: windowsMenu];
   [mainMenu display];
   appController = [Controller new];
   [app setDelegate: appController];
   [app run];
   [pool release];
   return 0;
}

