/* GormPreferences.m
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
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

#include <AppKit/AppKit.h>
#include <Foundation/NSUserDefaults.h>
#include "GormPreferences.h"

@implementation GormPreferences

- (id) init
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  int state = NSOffState;

  // load the interface...
  if(![NSBundle loadNibNamed: @"GormPreferences" owner: self])
    {
      NSLog(@"Failed to load interface");
      exit(-1);
    }

  // set the buttons to the proper states...
  state = [defaults boolForKey: @"PreloadHeaders"]?NSOnState:NSOffState;
  [preloadHeaders setState: state];
  state = [defaults boolForKey: @"ShowPalettes"]?NSOnState:NSOffState;
  [showPalettes setState: state];
  state = [defaults boolForKey: @"ShowInspectors"]?NSOnState:NSOffState;
  [showInspectors setState: state];

  // get the preloaded headers list...
  headers = [NSMutableArray arrayWithArray: [defaults arrayForKey: @"HeaderList"]];
  RETAIN(headers);

  // return
  return self;
}

- (void) awakeFromNib
{
  [browser setTarget: self];
  [browser setAction: @selector(selectHeader:)];
}

- (void) setGeneralPreferences: (id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  [defaults setBool: ([preloadHeaders state] == NSOnState)
	    forKey: @"PreloadHeaders"];
  [defaults setBool: ([showPalettes state] == NSOnState)
	    forKey: @"ShowPalettes"];
  [defaults setBool: ([showInspectors state] == NSOnState)
	    forKey: @"ShowInspectors"];

  // get the preloaded headers list...
  [defaults setObject: headers forKey: @"HeaderList"];
}

- (void) addHeader: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      [headers addObjectsFromArray: [oPanel filenames]];
      [browser reloadColumn: 0];
    }
}

- (void) removeHeader: (id)sender
{
  NSCell *cell = [browser selectedCellInColumn: 0];

  if(cell != nil)
    {
      NSString *stringValue = [NSString stringWithString: [cell stringValue]];
      [headers removeObject: stringValue];
      [browser reloadColumn: 0];
      NSLog(@"Header removed");
    }
}

- (void) selectHeader: (id)sender
{
  NSLog(@"Selected header");
}

- (id) window
{
  return window;
}
@end

// delegate
@interface GormPreferences(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column;

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix;

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column;

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column;

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column;
@end

@implementation GormPreferences(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column
{
  return YES;
}

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSEnumerator     *e = [headers objectEnumerator];
  NSString    *header = nil;
  NSBrowserCell *cell = nil;
  int i = 0;

  while((header = [e nextObject]) != nil)
    {
      [matrix insertRow: i withCells: nil];
      cell = [matrix cellAtRow: i column: 0];
      [cell setLeaf: YES];
      i++;
      [cell setStringValue: header];
    }
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  return @"Preloaded Headers";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column
{
  return NO;
}
@end

