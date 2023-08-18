/* main.m
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

// main.m

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

#import "AppDelegate.h"

int main(int argc, char **argv)
{
  NSApplication *app = [NSApplication sharedApplication];
  AppDelegate *delegate = [[AppDelegate alloc] init];
  extern char **environ;

  // Don't show icon...
  [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"GSSuppressAppIcon"];

  // Initialize process...
  [NSProcessInfo initializeWithArguments: (char **)argv
				   count: argc
			     environment: environ];

  // Run...
  [app setDelegate: delegate];
  [app run];

  return 0;
}
