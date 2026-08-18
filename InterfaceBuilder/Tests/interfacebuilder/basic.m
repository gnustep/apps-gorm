/*
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

#import "Testing.h"
#import <Foundation/Foundation.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  IBInspectorMode *mode;
  IBPlugin *plugin;
  NSObject *object;

  START_SET("InterfaceBuilder library")

  mode = AUTORELEASE([[IBInspectorMode alloc]
                       initWithIdentifier: @"attributes"
                                 forObject: @"edited-object"
                            localizedLabel: @"Attributes"
                        inspectorClassName: @"AttributesInspector"
                                 ordering: 4.0]);
  PASS([[mode identifier] isEqual: @"attributes"],
       "IBInspectorMode stores its identifier")
  PASS([[mode object] isEqual: @"edited-object"],
       "IBInspectorMode stores its edited object")
  PASS([[mode localizedLabel] isEqual: @"Attributes"],
       "IBInspectorMode stores its localized label")
  PASS([[mode inspectorClassName] isEqual: @"AttributesInspector"],
       "IBInspectorMode stores its inspector class name")
  PASS([mode ordering] == 4.0, "IBInspectorMode stores its ordering")

  [mode setIdentifier: @"size"];
  [mode setObject: @"other-object"];
  [mode setLocalizedLabel: @"Size"];
  [mode setInspectorClassName: @"SizeInspector"];
  [mode setOrdering: 1.0];
  PASS([[mode identifier] isEqual: @"size"] &&
       [[mode object] isEqual: @"other-object"] &&
       [[mode localizedLabel] isEqual: @"Size"] &&
       [[mode inspectorClassName] isEqual: @"SizeInspector"] &&
       [mode ordering] == 1.0,
       "IBInspectorMode mutators replace every stored value")

  plugin = [IBPlugin sharedInstance];
  PASS(plugin == [IBPlugin sharedInstance],
       "IBPlugin returns one shared instance per class")
  PASS([[plugin label] isEqual: NSStringFromClass([IBPlugin class])],
       "IBPlugin default label is its class name")
  PASS([plugin libraryNibNames] == nil &&
       [plugin preferencesView] == nil &&
       [plugin requiredFrameworks] == nil,
       "IBPlugin default optional extension points return nil")

  object = AUTORELEASE([[NSObject alloc] init]);
  PASS([object nibInstantiate] == object,
       "NSObject nibInstantiate default returns the receiver")

  PASS([IBWillAddConnectorNotification isEqual:
          @"IBWillAddConnectorNotification"] &&
       [IBDidAddConnectorNotification isEqual:
          @"IBDidAddConnectorNotification"] &&
       [IBWillRemoveConnectorNotification isEqual:
          @"IBWillRemoveConnectorNotification"] &&
       [IBDidRemoveConnectorNotification isEqual:
          @"IBDidRemoveConnectorNotification"],
       "connector notification constants are exported")

  END_SET("InterfaceBuilder library")

  RELEASE(pool);
  return 0;
}
