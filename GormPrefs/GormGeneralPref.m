/* GormGeneralPref.m
 *
 * Copyright (C) 2003, 2004, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003, 2004, 2005
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include "GormGeneralPref.h"

#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMatrix.h>

#include <GormCore/GormClassEditor.h>

static NSString *SHOWPALETTES=@"ShowPalettes";
static NSString *SHOWINSPECTOR=@"ShowInspectors";
static NSString *BACKUPFILE=@"BackupFile";
static NSString *ARCTYPE=@"ArchiveType";
static NSString *INTTYPE=@"ClassViewType";

@implementation GormGeneralPref

- (id) init
{
  _view = nil;

  self = [super init];
  
  if ( ! [NSBundle loadNibNamed:@"GormPrefGeneral" owner:self] )
    {
      NSLog(@"Can not load bundle GormPrefGeneral");
      return nil;
    }

  _view =  [[window contentView] retain];

  //Defaults
  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *arcType = [defaults stringForKey: ARCTYPE];
    NSString *intType = [defaults stringForKey: INTTYPE];
 
    [inspectorButton setState: [defaults integerForKey: SHOWINSPECTOR]];
    [palettesButton setState: [defaults integerForKey: SHOWPALETTES]];
    [backupButton setState: [defaults integerForKey: BACKUPFILE]];
    
    // set the archive matrix...
    if([arcType isEqual: @"Typed"])
      {
	[archiveMatrix setState: NSOnState atRow: 0 column: 0];
	[archiveMatrix setState: NSOffState atRow: 1 column: 0];
	[archiveMatrix setState: NSOffState atRow: 2 column: 0];
      }
    else if([arcType isEqual: @"Keyed"])
      {
	[archiveMatrix setState: NSOffState atRow: 0 column: 0];
	[archiveMatrix setState: NSOnState atRow: 1 column: 0];
	[archiveMatrix setState: NSOffState atRow: 2 column: 0];
      }
    else if([arcType isEqual: @"Both"])
      {
	[archiveMatrix setState: NSOffState atRow: 0 column: 0];
	[archiveMatrix setState: NSOffState atRow: 1 column: 0];
	[archiveMatrix setState: NSOnState atRow: 2 column: 0];
      }

    // set the interface matrix...
    if([intType isEqual: @"Outline"])
      {
	[interfaceMatrix setState: NSOnState atRow: 0 column: 0];
	[interfaceMatrix setState: NSOffState atRow: 1 column: 0];
      }
    else if([intType isEqual: @"Browser"])
      {
	[interfaceMatrix setState: NSOffState atRow: 0 column: 0];
	[interfaceMatrix setState: NSOnState atRow: 1 column: 0];
      }
  }

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_view);
  [super dealloc];
}

- (NSView *) view 
{
  return _view;
}

/* IBActions */
- (void) palettesAction: (id)sender
{
  if (sender != palettesButton) 
    return;
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      [defaults setInteger:[palettesButton state] forKey:SHOWPALETTES];
      [defaults synchronize];
    }
}


- (void) inspectorAction: (id)sender
{
  if (sender != inspectorButton) 
    return;
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      [defaults setInteger:[inspectorButton state] forKey:SHOWINSPECTOR];
      [defaults synchronize];
    }
}


- (void) backupAction: (id)sender
{
  if (sender != backupButton) 
    return;
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      [defaults setInteger:[backupButton state] forKey:BACKUPFILE];
      [defaults synchronize];
    }
}

- (void) archiveAction: (id)sender
{
  if (sender != archiveMatrix) 
    return;
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      if([[archiveMatrix cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Typed" forKey: ARCTYPE];
	}
      else if([[archiveMatrix cellAtRow: 1 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Keyed" forKey: ARCTYPE];
	}
      else if([[archiveMatrix cellAtRow: 2 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Both" forKey: ARCTYPE];
	}
      [defaults synchronize];
    }
}

- (void) classesAction: (id)sender
{
  if (sender != interfaceMatrix) 
    return;
  else
    {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
 
      if([[interfaceMatrix cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Outline" forKey: INTTYPE];
	}
      else if([[interfaceMatrix cellAtRow: 1 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Browser" forKey: INTTYPE];
	}

      // let the world know it's changed.
      [nc postNotificationName: GormSwitchViewPreferencesNotification
	  object: nil];

      [defaults synchronize];
    }
}
@end

