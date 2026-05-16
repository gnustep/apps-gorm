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
- (void) _removeBindingConnectorAndRefresh: (BOOL)refresh;
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
  if (doc == nil)
    {
      _source = nil;
      return;
    }

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
  [_valueTransformer setHidden: YES];

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
  NSString *controllerKey = [_controllerKey stringValue];
  NSString *modelKeyPath = [_modelKeyPath stringValue];
  NSString *keyPath = nil;
  GormDocument *doc = [self _activeDocument];
  if (doc == nil)
    {
      RELEASE(conn);
      return;
    }

  NSString *srcName = [[_controllerPopUp selectedItem] title];
  id src = [doc objectForName: srcName];

  if (src == nil || [controllerKey length] == 0)
    {
      RELEASE(conn);
      return;
    }

  // Build connection...
  if ([modelKeyPath length] > 0)
    {
      keyPath = [NSString stringWithFormat: @"%@.%@", controllerKey, modelKeyPath];
    }
  else
    {
      keyPath = controllerKey;
    }

  [self _removeBindingConnectorAndRefresh: NO];
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
  [self _removeBindingConnectorAndRefresh: YES];
}

- (void) _removeBindingConnectorAndRefresh: (BOOL)refresh
{
  GormDocument *doc = [self _activeDocument];
  NSArray *connections = [self _bindingConnections];
  NSEnumerator *en = [connections objectEnumerator];
  NSMutableArray *toRemove = [NSMutableArray array];
  id o = nil;

  if (doc == nil)
    {
      return;
    }

  while ((o = [en nextObject]) != nil)
    {
      NSString *binding = [o binding];

      if ([o destination] != object)
        {
          continue;
        }

      if ([binding isEqualToString: _bindingName] == NO)
        {
          continue;
        }

      if (_source != nil && [o source] != _source)
        {
          continue;
        }

      [toRemove addObject: o];
    }

  en = [toRemove objectEnumerator];
  while ((o = [en nextObject]) != nil)
    {
      [doc removeConnector: o];
    }

  if (refresh)
    {
      [self _locateAndSetBinding];
    }
}

- (void) _locateAndSetBinding
{
  NSArray *c = [self _bindingConnections];
  NSEnumerator *en = [c objectEnumerator];
  GormDocument *doc = [self _activeDocument];
  id preferred = nil;
  id fallback = nil;
  id o = nil;

  if (doc == nil)
    {
      return;
    }

  [_bindTo setState: NSOffState];

  while ((o = [en nextObject]) != nil)
    {
      NSString *n = [o binding];

      if ([o destination] != object)
        {
          continue;
        }

      if ([n isEqualToString: _bindingName] == NO)
        {
          continue;
        }

      if (fallback == nil)
        {
          fallback = o;
        }

      if (_source != nil && [o source] == _source)
        {
          preferred = o;
          break;
        }
    }

  o = (preferred != nil) ? preferred : fallback;
  if (o != nil)
    {
      NSString *keyPath = [o keyPath];
      NSRange dot = [keyPath rangeOfString: @"."];
      NSString *sourceName = nil;

      _source = [o source];
      [_bindTo setState: NSOnState];

      if (doc != nil && _source != nil)
        {
          sourceName = [doc nameForObject: _source];
          if (sourceName != nil)
            {
              [_controllerPopUp selectItemWithTitle: sourceName];
            }
        }

      if (dot.location == NSNotFound)
        {
          [_controllerKey setStringValue: keyPath ?: @""];
          [_modelKeyPath setStringValue: @""];
        }
      else
        {
          NSString *controllerKey = [keyPath substringToIndex: dot.location];
          NSString *modelKeyPath = [keyPath substringFromIndex: dot.location + 1];

          [_controllerKey setStringValue: controllerKey];
          [_modelKeyPath setStringValue: modelKeyPath];
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

      if ([_bindTo state] == NSOnState)
        {
          [self _createBindingConnector];
        }
      [self _locateAndSetBinding];
    }
  else if (sender == _bindTo)
    {
      if ([_bindTo state] == NSOnState)
	{
	  [self _createBindingConnector];
	  [self _locateAndSetBinding];
	}
      else
	{
	  [self _removeBindingConnector];
	}
    }
  else if (sender == _controllerKey
           || sender == _modelKeyPath
           || sender == _valueTransformer)
    {
      if ([_bindTo state] == NSOnState)
        {
          [self _createBindingConnector];
          [self _locateAndSetBinding];
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
