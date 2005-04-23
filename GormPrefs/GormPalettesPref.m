#/* GormPalettesPref.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
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

#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>

#include <GormCore/GormPrivate.h>
#include "GormPalettesPref.h"

@class NSTableView;

// data source...
@interface PaletteDataSource : NSObject
@end

@implementation PaletteDataSource
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *list = [defaults objectForKey: @"UserPalettes"];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *list = [defaults objectForKey: @"UserPalettes"];
  id value = nil;
  if([list count] > 0)
    {
      value = [[list objectAtIndex: rowIndex] lastPathComponent];
    }
  return value;
}
@end


@implementation GormPalettesPref
- (id) init
{
  _view = nil;

  self = [super init];
  
  if ( ! [NSBundle loadNibNamed:@"GormPrefPalettes" owner:self] )
    {
      NSLog(@"Can not load bundle GormPrefPalettes");
      return nil;
    }
  
  _view =  [[(NSWindow *)window contentView] retain];
  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_view);
  [super dealloc];
}


-(NSView *) view
{
  return _view;
}

- (void) addAction: (id)sender
{
  [[(id<Gorm>)NSApp palettesManager] openPalette: self];
  [table reloadData];
}


- (void) removeAction: (id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *list = [defaults objectForKey: @"UserPalettes"];
  int row = [table selectedRow];

  if(row >= 0)
    {
      NSString *stringValue = [list objectAtIndex: row];
      
      if(stringValue != nil)
	{
	  [list removeObject: stringValue];
	  [defaults setObject: list forKey: @"UserPalettes"];
	  [table reloadData];
	}
    }
}

- (BOOL)    tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)aTableColumn
		  row: (int)rowIndex
{
  BOOL result = NO;
  return result;
}

- (BOOL) tableView: (NSTableView *)tv
   shouldSelectRow: (int)rowIndex
{
  BOOL result = YES;
  return result;
}

@end
