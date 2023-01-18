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
#import "NSString+methods.h"

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

      // Initialize the array that holds the inspector names...
      _bindingsArray = [[NSMutableArray alloc] initWithCapacity: 10];
      _selectedInspectorIndex = 0;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_bindingsArray);
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (NSString *) _mapStringToInspectorName: (NSString *)string
{
  NSString *capString = [string capitalizedFirstCharacterString];
  NSString *name = [NSString stringWithFormat: @"GormBindings%@Inspector", capString];

  return name;
}

- (NSString *) _mapStringToTitle: (NSString *)string
{
  NSString *title = [string splitCamelCaseString];
  title = [title capitalizedFirstCharacterString];
  return title;
}

- (void) _loadInspector
{
  NSString *inspectorName = [_bindingsArray objectAtIndex: _selectedInspectorIndex];
  Class cls = NSClassFromString(inspectorName);
  
  _inspectorObject = [[cls alloc] init];
  if (_inspectorObject != nil)
    {
      if (![NSBundle loadNibNamed: inspectorName owner: _inspectorObject])
	{
	  NSLog(@"Could not load inspector for binding %@", inspectorName);
	}
    }
  else
    {
      _inspectorObject = nil; // make certain this is nil, if load failed...
      NSLog(@"Could not instantiate class for %@", inspectorName);
    }
}

- (void) _populate: (NSArray *)array
{
  [_bindingsPopUp removeAllItems];
  [_bindingsArray removeAllObjects];

  _selectedInspectorIndex = 0;
  
  if ([array count] == 0 || array == nil)
    {      
      [_bindingsPopUp addItemWithTitle: @"No Bindings"];
    }
  else
    {
      NSEnumerator *en = [array objectEnumerator];
      NSString *string = nil;

      while ((string = [en nextObject]) != nil)
	{
	  NSString *title = [self _mapStringToTitle: string];
	  NSString *inspector = [self _mapStringToInspectorName: string];

	  [_bindingsPopUp addItemWithTitle: title];
	  [_bindingsArray addObject: inspector];
	}
    }

  [self _loadInspector];
}

- (void) setObject: (id)obj
{
  NSArray *array = nil;
  
  [super setObject: obj];
  array = [[self object] exposedBindings];
  [self _populate: array];
  [_inspectorObject setObject: obj];
  
  NSLog(@"Bindings = %@, inspectors = %@", array, _bindingsArray);
}

- (void) ok: (id)sender
{
  [super ok: sender];
  [_inspectorObject ok: sender];
}

- (void) revert: (id)sender
{
  [super revert: sender];
  [_inspectorObject revert: sender];
}

- (IBAction) selectInspector: (id)sender
{
  _selectedInspectorIndex = [sender indexOfSelectedItem];
  [self _loadInspector];
}

@end
