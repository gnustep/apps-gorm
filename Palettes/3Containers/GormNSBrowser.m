/* GormNSBrowser.m

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

#include "GormNSBrowser.h"

/* --------------------------------------------------------------- 
 * NSBrowser Delegate
*/
@interface NSBrowserDelegate: NSObject
{
}

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column;
- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column;
- (void) browser: (NSBrowser *)sender willDisplayCell: (id)cell
           atRow: (int)row column: (int)column;

@end


@implementation NSBrowserDelegate

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
  return 0;
}

- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column
{
  return (column==0) ? @"Browser" : @"";
}

- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
           atRow: (int)row
          column: (int)column
{
  NSDebugLog(@"<%@ %x>: browser %x will display %@ %x at %d,%d",[self class],self,sender,[cell class],cell,row,column);
  // This code should never be called because there is no row
  // in our browser. But just in case...
  [cell setLeaf:YES];
  [cell setStringValue: @""];
}

@end

static id _sharedDelegate = nil;

@implementation GormNSBrowser
+ (id) sharedDelegate
{
  if (_sharedDelegate == nil)
    {
      _sharedDelegate = [[NSBrowserDelegate alloc] init];
    }
  return _sharedDelegate;
}

- (id) initWithFrame: (NSRect) aRect
{
  self = [super initWithFrame: aRect];
  [super setDelegate: [GormNSBrowser sharedDelegate]];
  _gormDelegate = nil;
  return self;
}

- (void)setDelegate: (id)anObject
{
  _gormDelegate = anObject;
}

- (id)delegate
{
  return _gormDelegate;
}

- (void)encodeWithCoder: (NSCoder*) aCoder
{
  _browserDelegate = _gormDelegate;
  [super encodeWithCoder: aCoder];
  _browserDelegate = _sharedDelegate;
}

- (id) initWithCoder: (NSCoder*) aCoder
{
  [super setDelegate: [GormNSBrowser sharedDelegate]];
  self = [super initWithCoder: aCoder];
  return self;
}
@end
