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

- (void)encodeWithCoder: (NSCoder*) aCoder
{
  _dataSource = _gormDataSource;
  [super encodeWithCoder: aCoder];
  _dataSource = _sharedDataSource;
}

- (id) initWithCoder: (NSCoder*) aCoder
{
  self = [super initWithCoder: aCoder];
  [super setDataSource: [GormNSTableView sharedDataSource]];
  return self;
}

@end
