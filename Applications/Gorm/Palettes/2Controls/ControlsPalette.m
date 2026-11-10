/** 
   ControlsPalette.m

   Copyright (C) 2024 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2024, 2004
   
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
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

#include <AppKit/AppKit.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

#include "GormNSPopUpButton.h"
#include <GormCore/GormCustomView.h>

@interface ControlsPalette: IBPalette <IBViewResourceDraggingDelegates, IBPaletteDescriptions>
{
  IBOutlet NSPopUpButton *_prototypePopUp;
}
@end


@implementation ControlsPalette 

- (NSString *) descriptionForObject: (id)object
{
  if ([object isKindOfClass: [GormCustomView class]])
    return _(@"Add a placeholder for a custom view class.");
  if ([object isKindOfClass: [NSPopUpButton class]])
    return _(@"Choose an item from a pop-up list of options.");
  if ([object isKindOfClass: [NSButton class]])
    return _(@"Trigger an action or select an option with a button.");
  if ([object isKindOfClass: [NSSecureTextField class]])
    return _(@"Enter a password with its characters concealed.");
  if ([object isKindOfClass: [NSTextField class]])
    return [object isEditable] ? _(@"Enter or edit a single line of text.")
      : _(@"Display a label or other read-only text.");
  if ([object isKindOfClass: [NSSlider class]])
    return _(@"Choose a value by dragging a slider.");
  if ([object isKindOfClass: [NSStepper class]])
    return _(@"Increase or decrease a numeric value.");
  if ([object isKindOfClass: [NSColorWell class]])
    return _(@"Display and choose a color.");
  if ([object isKindOfClass: [NSProgressIndicator class]])
    return _(@"Show the progress of an operation.");
  if ([object isKindOfClass: [NSBox class]])
    return _(@"Group related controls in a bordered container.");
  if ([object isKindOfClass: [NSSplitView class]])
    return _(@"Arrange panes separated by a draggable divider.");
  if ([object isKindOfClass: [NSForm class]])
    return _(@"Present labeled text fields for entering values.");
  if ([object isKindOfClass: [NSMatrix class]])
    return _(@"Arrange a group of cells in rows and columns.");
  return nil;
}

- (id) init
{
  if((self = [super init]) != nil)
    {
      // Make ourselves a delegate, so that when the sound/image is dragged in, 
      // this code is called...
      [NSView registerViewResourceDraggingDelegate: self];
      
      // subscribe to the notification...      
      [[NSNotificationCenter defaultCenter]
	addObserver: self
           selector: @selector(willInspectObject:)
               name: IBWillInspectObjectNotification
             object: nil];
    }

  return self;
}

- (void) dealloc
{
  [NSView unregisterViewResourceDraggingDelegate: self];
  [super dealloc];
}

- (void) finishInstantiate
{
  NSView *contentView = [originalWindow contentView];
  NSArray *allItems = nil;
  NSEnumerator *en = nil;
  id item = nil;
  
  _prototypePopUp = [[GormNSPopUpButton alloc] initWithFrame: NSMakeRect(71.0, 157.0, 102.0, 24.0)];
  [_prototypePopUp addItemWithTitle: @"Item #0"];
  [_prototypePopUp addItemWithTitle: @"Item #1"];
  [_prototypePopUp addItemWithTitle: @"Item #2"];
  [_prototypePopUp setAutoenablesItems: YES];
  
  allItems = [[_prototypePopUp menu] itemArray];
  en = [allItems objectEnumerator];
  while ((item = [en nextObject]) != nil)
    {
      [item setTarget: nil];
      [item setAction: NULL]; // @selector(_popUpItemAction:)];
      [item setEnabled: YES];
    }

  [contentView addSubview: _prototypePopUp];
  AUTORELEASE(_prototypePopUp);
}

- (void) willInspectObject: (NSNotification *)notification
{
  id o = [notification object];

  // [o respondsToSelector: @selector(prototype)] && [o prototype])
  if ([o isKindOfClass: [NSMatrix class]])
    {
      id prototype = [o prototype];
      NSString *ident = NSStringFromClass([prototype class]);
      [[IBInspectorManager sharedInspectorManager]
		addInspectorModeWithIdentifier: ident
                                     forObject: o
                                localizedLabel: _(@"Prototype")
                            inspectorClassName: [prototype inspectorClassName]
                                      ordering: -1.0];
    }
}

/**
 * Ask if the view accepts the object.
 */
- (BOOL) acceptsViewResourceFromPasteboard: (NSPasteboard *)pb
                                 forObject: (id)obj
                                   atPoint: (NSPoint)p
{
  NSArray *types = [pb types];
  return (([obj respondsToSelector: @selector(setSound:)] || 
	   [obj respondsToSelector: @selector(setImage:)]) &&
	  ([types containsObject: GormImagePboardType] ||
	   [types containsObject: GormSoundPboardType]));
}

/**
 * Perform the action of depositing the object.
 */
- (void) depositViewResourceFromPasteboard: (NSPasteboard *)pb
                                  onObject: (id)obj
                                   atPoint: (NSPoint)p
{
  NSArray *types = [pb types];
  if ([types containsObject: GormImagePboardType] == YES)
    {
      NSString *name = [pb stringForType: GormImagePboardType];
      if([(id)obj respondsToSelector: @selector(setImage:)])
	{
	  NSImage *image = [NSImage imageNamed: name];
	  [(id)obj setImage: AUTORELEASE([image copy])];
	}
    }
  else   if ([types containsObject: GormSoundPboardType] == YES)
    {
      NSString *name;
      name = [pb stringForType: GormSoundPboardType];
      if([(id)obj respondsToSelector: @selector(setSound:)])
	{
	  NSSound *sound = [NSSound soundNamed: name];
	  [(id)obj setSound: AUTORELEASE([sound copy])];
	}
    }
}

/**
 * Should we draw the connection frame when the resource is
 * dragged in?
 */
- (BOOL) shouldDrawConnectionFrame
{
  return NO;
}

/**
 * Types of resources accepted by this view.
 */
- (NSArray *)viewResourcePasteboardTypes
{
  return [NSArray arrayWithObjects: GormImagePboardType, GormSoundPboardType, nil];
}
@end
