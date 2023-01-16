/** <title>GormClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: March 2003

   This file is part of GNUstep.
 
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/* All rights reserved */

#import "GormBindingsInspector.h"
#import "GormDocument.h"
#import "GormFunctions.h"
#import "GormPrivate.h"
#import "GormProtocol.h"

@implementation GormBindingsInspector
+ (void) initialize
{
  if (self == [GormBindingsInspector class])
    {
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // load the gui...
      if (![NSBundle loadNibNamed: @"GormBindingsInspector"
		     owner: self])
	{
	  NSLog(@"Could not open gorm file");
	  return nil;
	}
    }
  return self;
}

- (void) awakeFromNib
{
}

- (void) ok: (id)sender
{
  [super ok: sender];
}

- (void) revert: (id)sender
{
  [super revert: sender];
}

@end
