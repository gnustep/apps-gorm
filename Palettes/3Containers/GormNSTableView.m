/* GormNSTableView.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "GormNSTableView.h"

/* --------------------------------------------------------------- 
 * NSTableView dataSource
*/
@interface NSTableViewDataSource: NSObject
{
}
- (int) numberOfRowsInTableView: (NSTableView *)tv;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end

static NSString* value1[] =
{@"zero",
 @"un",
 @"deux", 
 @"trois",
 @"quatre",
 @"cinq",
 @"six",
 @"sept",
 @"huit", 
 @"neuf"};

static NSString* value2[] =
{@"zero",
 @"one",
 @"two", 
 @"three",
 @"four",
 @"five",
 @"six",
 @"seven",
 @"eight", 
 @"nine"};

@implementation NSTableViewDataSource

- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  return 10;
}
- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	    row:(int)rowIndex
{
  if ([[aTableColumn identifier] isEqualToString: @"column1"])
    {
      return value1[rowIndex];
    }
  return value2[rowIndex];
}

@end

static id _sharedDataSource = nil;

@implementation GormNSTableView
+ (id) sharedDataSource
{
  if (_sharedDataSource == nil)
    {
      _sharedDataSource = [[NSTableViewDataSource alloc] init];
    }
  return _sharedDataSource;
}

- (id) initWithFrame: (NSRect) aRect
{
  self = [super initWithFrame: aRect];
  [super setDataSource: [GormNSTableView sharedDataSource]];
  _gormDataSource = nil;
  return self;
}

- (void)setDataSource: (id)anObject
{
  _gormDataSource = anObject;
}

- (id)dataSource
{
  return _gormDataSource;
}

- (void)setDelegate: (id)anObject
{
  _gormDelegate = anObject;
}

- (id)delegate
{
  return _gormDelegate;
}

- (id)setGormDelegate: (id)anObject
{
  [super setDelegate: anObject];
}

- (void)encodeWithCoder: (NSCoder*) aCoder
{
  id oldDelegate;
  _allowsColumnReordering = _gormAllowsColumnReordering;
  _allowsColumnResizing = _gormAllowsColumnResizing;
  _allowsColumnSelection = _gormAllowsColumnSelection;
  _allowsMultipleSelection = _gormAllowsMultipleSelection;
  _allowsEmptySelection = _gormAllowsEmptySelection;

  _dataSource = _gormDataSource;
  oldDelegate = _delegate;
  _delegate = _gormDelegate;
  _numberOfRows = 0;
  [super encodeWithCoder: aCoder];
  _numberOfRows = 10;
  _allowsColumnReordering = YES;
  _allowsColumnResizing = YES;
  _allowsColumnSelection = YES;
  _allowsMultipleSelection = NO;
  _allowsEmptySelection = YES;

  _delegate = oldDelegate;
  _dataSource = _sharedDataSource;
}

- (id) initWithCoder: (NSCoder*) aCoder
{
  self = [super initWithCoder: aCoder];
  [super setDataSource: [GormNSTableView sharedDataSource]];

  _gormAllowsColumnReordering = _allowsColumnReordering;
  _gormAllowsColumnResizing = _allowsColumnResizing;
  _gormAllowsColumnSelection = _allowsColumnSelection;
  _gormAllowsMultipleSelection = _allowsMultipleSelection;
  _gormAllowsEmptySelection = _allowsEmptySelection;
  _gormDelegate = _delegate;
  _delegate = nil;

  return self;
}


- (void) setGormAllowsColumnReordering: (BOOL)flag
{
  _gormAllowsColumnReordering = flag;
}

- (BOOL) gormAllowsColumnReordering
{
  return _gormAllowsColumnReordering;
}

- (void) setGormAllowsColumnResizing: (BOOL)flag
{
  _gormAllowsColumnResizing = flag;
}

- (BOOL) gormAllowsColumnResizing
{
  return _gormAllowsColumnResizing;
}

- (void) setGormAllowsMultipleSelection: (BOOL)flag
{
  _gormAllowsMultipleSelection = flag;
}

- (BOOL) gormAllowsMultipleSelection
{
  return _gormAllowsMultipleSelection;
}

- (void) setGormAllowsEmptySelection: (BOOL)flag
{
  _gormAllowsEmptySelection = flag;
}

- (BOOL) gormAllowsEmptySelection
{
  return _gormAllowsEmptySelection;
}

- (void) setGormAllowsColumnSelection: (BOOL)flag
{
  _gormAllowsColumnSelection = flag;
}

- (BOOL) gormAllowsColumnSelection
{
  return _gormAllowsColumnSelection;
}



@end
