/* GormBindingsAbstractInspector.m

   Copyright (C) 2026 Free Software Foundation, Inc.
   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2026
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 31 Milk St #960789, Fifth Floor, Boston,
   MA 02196 USA.
*/

#import <Foundation/NSSet.h>
#import <GNUstepGUI/GSNibLoading.h>

#import "GormAbstractDelegate.h"
#import "GormBindingsAbstractInspector.h"
#import "GormDocument.h"

@interface GormBindingsAbstractInspector (Extras)
- (void) _initDefaults;
- (GormDocument *) _activeDocument;
@end

@implementation GormBindingsAbstractInspector

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      [self _initDefaults];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_bindingName);
  [super dealloc];
}

// Private methods...

- (GormDocument *) _activeDocument
{
  id<IBDocuments> doc = [(id<IB>)[NSApp delegate] activeDocument];

  if ([doc isKindOfClass: [GormDocument class]])
    {
      return (GormDocument *)doc;
    }

  return nil;
}

- (void) _setSourceFromPopUp
{
  NSString *title = [_controllerPopUp titleOfSelectedItem];
  GormDocument *doc = [self _activeDocument];
  id o = [doc objectForName: title];

  _source = o;
  NSLog(@"Source set to %@", _source);
}

- (void) _initDefaults
{
  // Make sure all fields show...
  [_multipleValuesPlaceholder setHidden: YES];
  [_noSelectionPlaceholder setHidden: YES];
  [_notApplicablePlaceholder setHidden: YES];
  [_nullPlaceholder setHidden: YES];

  [_multipleValuesTitle setHidden: YES];
  [_noSelectionTitle setHidden: YES];
  [_notApplicableTitle setHidden: YES];
  [_nullTitle setHidden: YES];

  [_alwaysPresentsAppModalAlerts setHidden: YES];
  [_raisesForNotApplicableKeys setHidden: YES];
  [_validatesImmediately setHidden: YES];
  
  [_controllerKey setStringValue: @""];
  [_modelKeyPath setStringValue: @""];

  [self _setSourceFromPopUp];
}

- (void) _addTopLevelObjectsToPopUp
{
  GormDocument *doc = [self _activeDocument];
  if (doc == nil)
    {
      return;
    }

  NSSet *tlo = [doc topLevelObjects];
  NSEnumerator *en = [tlo objectEnumerator];
  NSUInteger index = 0;
  id o = nil;

  // Update the pop up...
  [_controllerPopUp removeAllItems];

  // Add TLO...
  while ((o = [en nextObject]) != nil)
    {
      NSString *name = [doc nameForObject: o];
      if ([name isEqualToString: @"NSMenu"] == NO && name != nil)
	{
	  id<NSMenuItem> item = nil;

	  [_controllerPopUp addItemWithTitle: name];
	  item = [_controllerPopUp itemWithTitle: name];
	  [item setTag: index];
	  index++;
	}
    }

  // Add placeholder...
  [_controllerPopUp addItemWithTitle: @"NSFirst"];
}

- (NSMutableArray *) _bindingConnections
{
  GormDocument *doc = [self _activeDocument];
  if (doc == nil)
    {
      return [NSMutableArray array];
    }

  NSMutableArray *conn = [doc connections];
  NSMutableArray *result = [NSMutableArray array];
  NSEnumerator *en = [conn objectEnumerator];
  id o = nil;

  while (o = [en nextObject])
    {
      if ([o isKindOfClass: [NSNibBindingConnector class]])
	{
	  [result addObject: o];
	}
    }

  return result;
}

- (void) _createBindingConnector
{
  NSNibBindingConnector *conn = [[NSNibBindingConnector alloc] init];
  NSString *keyPath = [_controllerKey stringValue];
  GormDocument *doc = [self _activeDocument];
  if (doc == nil)
    {
      RELEASE(conn);
      return;
    }

  NSString *srcName = [[_controllerPopUp selectedItem] title];
  id src = [doc objectForName: srcName];

  // Build connection...
  [keyPath stringByAppendingFormat: @".%@", [_modelKeyPath stringValue]];
  [conn setDestination: object];
  [conn setSource: src];
  [conn setBinding: _bindingName];
  [conn setKeyPath: keyPath];

  [doc addConnector: conn];

  NSLog(@"connectors = %@", [self _bindingConnections]);
  
  RELEASE(conn);
}

- (void) _removeBindingConnector
{
  NSLog(@"Remove...");
}

- (void) _locateAndSetBinding
{
  NSArray *c = [self _bindingConnections];
  NSEnumerator *en = [c objectEnumerator];
  id o = nil;

  NSLog(@"in locateAndSetBinding c=%@", c);
  while (o = [en nextObject])
    {
      NSString *n = [o binding];
      
      NSLog(@"o = %@, n=%@, _bindingName = %@, source = %@, _source = %@", o, n, _bindingName, [o source], _source);
      if ([n isEqualToString: _bindingName]
	  && [o source] == _source)
	{
	  NSString *keyPath = [o keyPath];
	  NSArray *array = [keyPath componentsSeparatedByString: @"."];

	  NSLog(@"located = %@, keyPath = %@", o, keyPath);
	  if ([array count] > 1)
	    {
	      NSLog(@"Array > 1");
	      NSString *controllerKey = [array objectAtIndex: 0];
	      [_controllerKey setStringValue: controllerKey];

	      // remove controller key...
	      NSString *modelKeyPath = [keyPath stringByReplacingOccurrencesOfString:
					      [controllerKey stringByAppendingString: @"."]
									  withString: @""];
	      [_modelKeyPath setStringValue: modelKeyPath];
	    }
	}
    }
}

// Methods to set and revert information...

- (IBAction) ok: (id)sender
{
  if (sender == _controllerPopUp)
    {
      GormDocument *doc = [self _activeDocument];
      if (doc == nil)
        {
          [super ok: sender];
          return;
        }

      id item = [_controllerPopUp selectedItem];
      NSString *title = [item title];

      _source = [doc objectForName: title];
      NSLog(@"_source set to = %@", _source);
    }
  else if (sender == _bindTo)
    {
      if ([_bindTo state] == NSOnState)
	{
	  [self _createBindingConnector];
	}
      else
	{
	  [self _removeBindingConnector];
	}
    }

  [super ok: sender];
}

- (IBAction) revert: (id)sender
{
  NSMutableArray *conn = [self _bindingConnections];
  NSLog(@"connections = %@", conn);
  [self _addTopLevelObjectsToPopUp];
  [self _locateAndSetBinding];

  [super revert: sender];
}

- (void) awakeFromNib
{
  [self _addTopLevelObjectsToPopUp];
  [self _initDefaults];
}

// Setters and getters...

- (void) setBindingName: (NSString *)name
{
  ASSIGN(_bindingName, name);
  [self _locateAndSetBinding];
}

@end
