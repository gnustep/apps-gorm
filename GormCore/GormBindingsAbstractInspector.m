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

#import "NSString+methods.h"

@interface GormBindingsAbstractInspector (Extras)
- (void) _initDefaults;
- (GormDocument *) _activeDocument;
- (void) _removeBindingConnectorAndRefresh: (BOOL)refresh;
- (void) _locateAndSetBinding;
//- (void) _locateAndSetBindingPreservingFields: (BOOL)preserveFields;
- (id) _objectForPopUpTitle: (NSString *)title inDocument: (GormDocument *)doc;
@end

@implementation GormBindingsAbstractInspector

- (instancetype) init
{
  self = [super init];

  if (self != nil)
    {
      // load the gui...
      if (![NSBundle loadNibNamed: @"GormBindingsAbstractInspector"
			    owner: self])
	{
	  NSLog(@"Could not open gorm file");
	  return nil;
	}

      // Initialize
      [self _initDefaults];
    }

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

// Private methods...

- (void) _populate: (NSArray *)array
{
  [_bindingsPopUp removeAllItems];

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
	  [_bindingsPopUp addItemWithTitle: string];
	}
    }
}

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
  GormDocument *doc = [self _activeDocument];

  if (doc == nil)
    {
      return;
    }

  [self _locateAndSetBinding];
}

- (NSString *) _currentBindingName
{
  NSString *title = [_bindingsPopUp titleOfSelectedItem];
  if (title != nil && ![title isEqualToString: @"No Bindings"])
    {
      return title;
    }
  return nil;
}

- (void) _setBindingFromPopUp
{
  [self _locateAndSetBinding];
}

- (id) _objectForPopUpTitle: (NSString *)title inDocument: (GormDocument *)doc
{
  id o = nil;

  if (doc == nil || title == nil)
    {
      return nil;
    }

  o = [doc objectForName: title];
  if (o != nil)
    {
      return o;
    }
  else
    {
      NSString *lowercaseTitle = [title lowercaseFirstCharacterString];
      o = [doc objectForName: lowercaseTitle];
      if (o != nil)
	{
	  return o;
	}
    }

  return nil;
}

- (void) _initDefaults
{
  // Hide these fields for now, future use
  [_multipleValuesPlaceholder setHidden: YES];
  [_noSelectionPlaceholder setHidden: YES];
  [_notApplicablePlaceholder setHidden: YES];
  [_nullPlaceholder setHidden: YES];

  [_multipleValuesTitle setHidden: YES];
  [_noSelectionTitle setHidden: YES];
  [_notApplicableTitle setHidden: YES];
  [_valueTransformerTitle setHidden: YES];
  [_nullTitle setHidden: YES];

  [_alwaysPresentAppModalAlerts setHidden: YES];
  [_raisesForNotApplicableKeys setHidden: YES];
  [_validatesImmediately setHidden: YES];
  [_valueTransformer setHidden: YES];

  // Initialize these to be empty...
  [_controllerKey setStringValue: @""];
  [_modelKeyPath setStringValue: @""];

  // Set the source from the popup...
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
  [_sourcePopUp removeAllItems];

  // Add TLO...
  while ((o = [en nextObject]) != nil)
    {
      NSString *name = [doc nameForObject: o];
      if ([name isEqualToString: @"NSMenu"] == NO && name != nil)
	{
	  id<NSMenuItem> item = nil;

	  [_sourcePopUp addItemWithTitle: name];
	  item = [_sourcePopUp itemWithTitle: name];
	  [item setTag: index];
	  index++;
	}
    }

  // Add placeholder...
  [_sourcePopUp addItemWithTitle: @"NSOwner"];
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
  NSDictionary *opts = [NSDictionary dictionary];

  if (doc == nil)
    {
      NSLog(@"Document is nil");
      RELEASE(conn);
      return;
    }

  NSString *srcName = [[_sourcePopUp selectedItem] title];
  id src = [self _objectForPopUpTitle: srcName inDocument: doc];

  [conn setOptions: opts];
  if (src == nil || [controllerKey length] == 0)
    {
      NSLog(@"src or controllerKey is not set");
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
  [conn setBinding: [self _currentBindingName]];
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
      NSString *currentBinding = [self _currentBindingName];

      if ([o destination] != object)
        {
          continue;
        }

      if (currentBinding == nil || [binding isEqualToString: currentBinding] == NO)
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
  GormDocument *doc = [self _activeDocument];
  NSArray *c = nil; // [self _bindingConnections];
  NSEnumerator *en = nil; // [c objectEnumerator];
  id preferred = nil;
  id fallback = nil;
  id o = nil;

  if (doc == nil)
    {
      return;
    }

  // Get the connections...
  c = [self _bindingConnections];
  en = [c objectEnumerator];
  
  // Clear / Reset fields...
  [_bindTo setState: NSOffState];
  [_controllerKey setStringValue: @""];
  [_modelKeyPath setStringValue: @""];

  while ((o = [en nextObject]) != nil)
    {
      NSString *n = [o binding];
      NSString *currentBinding = [self _currentBindingName];

      NSLog(@"n = %@", n);
      if ([o destination] != object)
        {
	  NSLog(@"Destination is not %@", object);
          continue;
        }

      if (currentBinding == nil || [n isEqualToString: currentBinding] == NO)
        {
          continue;
        }

      if (fallback == nil)
        {
          fallback = o;
        }
    }

  o = (preferred != nil) ? preferred : fallback;
  NSLog(@"o = %@", o);
  if (o != nil)
    {
      NSString *keyPath = [o keyPath];
      NSRange dot = [keyPath rangeOfString: @"."];
      id src = [o source];
      NSString *sourceName = [doc nameForObject: src];

      [_bindTo setState: NSOnState];

      if (doc != nil)
        {
          if (sourceName != nil)
            {
              [_sourcePopUp selectItemWithTitle: sourceName];
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

- (void) _updateSourceForBinding
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

  while ((o = [en nextObject]) != nil)
    {
      NSString *n = [o binding];
      NSString *currentBinding = [self _currentBindingName];

      NSLog(@"n = %@", n);
      if ([o destination] != object)
        {
	  NSLog(@"Destination is not %@", object);
          continue;
        }

      if (currentBinding == nil || [n isEqualToString: currentBinding] == NO)
        {
          continue;
        }

      if (fallback == nil)
        {
          fallback = o;
        }
    }

  o = (preferred != nil) ? preferred : fallback;
  NSLog(@"o = %@", o);
  if (o != nil)
    {
      NSString *sourceName = [_sourcePopUp titleOfSelectedItem];
      id src = [self _objectForPopUpTitle: sourceName inDocument: doc];
      [o setSource: src];
    }
}

// Methods to set and revert information...

- (IBAction) ok: (id)sender
{  
  if (sender == _sourcePopUp)
    {
      GormDocument *doc = [self _activeDocument];
      if (doc == nil)
        {
          [super ok: sender];
          return;
        }

      [self _updateSourceForBinding];
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
  else if (sender == _bindingsPopUp)
    {
      [self _setBindingFromPopUp];
    }
  else if (sender == _controllerKey
           || sender == _modelKeyPath)
    {
      // Update connection when editing is finished
      if ([_bindTo state] == NSOnState)
        {
          if ([[_controllerKey stringValue] length] > 0)
            {
              [self _createBindingConnector];
              [self _locateAndSetBinding];
            }
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

- (void) setObject: (id)obj
{
  NSArray *array = nil;
  
  [super setObject: obj];
  array = [[self object] exposedBindings];
  [self _populate: array];
  [self _locateAndSetBinding];
}


- (void) awakeFromNib
{
  [self _addTopLevelObjectsToPopUp];
  [self _initDefaults];
}

- (void) selectBindingNamed: (NSString *)name
{
  if (name != nil)
    {
      [_bindingsPopUp selectItemWithTitle: name];
      [self _setBindingFromPopUp];
    }
}

// Setters and getters...



@end
