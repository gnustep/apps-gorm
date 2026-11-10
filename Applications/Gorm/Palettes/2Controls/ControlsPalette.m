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
    return _(@"Reserve an area for a custom NSView subclass; assign its class to use your own drawing and interaction code.");
  if ([object isKindOfClass: [NSPopUpButton class]])
    return [object pullsDown]
      ? _(@"Open a pull-down menu of commands from a button whose title stays visible after a choice.")
      : _(@"Choose one option from a pop-up menu; the button displays the currently selected item.");
  if ([object isKindOfClass: [NSButton class]])
    {
      NSString *imageName = [[object image] name];

      /* Switch and radio prototypes use the standard GNUstep images. */
      if ([imageName isEqual: @"GSSwitch"])
        return _(@"Turn an independent option on or off with a checkbox; its check mark shows the current state.");
      if ([imageName isEqual: @"GSRadio"])
        return _(@"Select an option with a radio button; use a radio matrix to make a group mutually exclusive.");
      if ([[object cell] showsStateBy] != NSNoCellMask)
        return _(@"Toggle a persistent on or off state with a button that shows whether it is selected.");
      return _(@"Perform a command when clicked; connect the button's action to the object that handles the command.");
    }
  if ([object isKindOfClass: [NSSecureTextField class]])
    return _(@"Enter a password or other sensitive text in a field that conceals the typed characters.");
  if ([object isKindOfClass: [NSTextField class]])
    return [object isEditable] ? _(@"Enter and edit a single text value; connect an action to respond when the user commits a change.")
      : _(@"Display a read-only label, instruction, or value alongside other controls.");
  if ([object isKindOfClass: [NSSlider class]])
    return _(@"Choose a numeric value within a minimum and maximum by dragging the slider knob.");
  if ([object isKindOfClass: [NSStepper class]])
    return _(@"Adjust a numeric value in fixed increments with up and down arrows, within a configurable range.");
  if ([object isKindOfClass: [NSColorWell class]])
    return _(@"Show the current color and let the user change it through the color panel.");
  if ([object isKindOfClass: [NSProgressIndicator class]])
    return _(@"Show how much of an operation is complete, or animate to indicate activity when its duration is unknown.");
  if ([object isKindOfClass: [NSBox class]]
      && [object boxType] == NSBoxSeparator)
    return _(@"Separate neighboring controls or sections with a horizontal or vertical divider line.");
  if ([object isKindOfClass: [NSBox class]])
    return _(@"Group related controls inside a titled box with a configurable border and content area.");
  if ([object isKindOfClass: [NSSplitView class]])
    return _(@"Divide an area into adjacent panes whose sizes the user can adjust by dragging the divider.");
  if ([object isKindOfClass: [NSForm class]])
    return _(@"Collect related values in a column of text fields, each with its own aligned label.");
  if ([object isKindOfClass: [NSMatrix class]]
      && [object mode] == NSRadioModeMatrix)
    return _(@"Present a group of mutually exclusive choices in rows or columns; selecting one cell deselects the others.");
  if ([object isKindOfClass: [NSMatrix class]])
    return _(@"Arrange cells in rows and columns to display values or offer a coordinated set of selectable controls.");
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
