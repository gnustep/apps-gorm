/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
   Date: Aug 2001
   
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
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "../../GormPrivate.h"

@implementation	NSSlider (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormSliderAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return nil;
}
@end

@interface GormSliderAttributesInspector : IBInspector
{
  id unitForm;
  id altForm;
  id numberOfTicks;
  id tickPosition;
  id snapToTicks;
}
@end

@implementation GormSliderAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == unitForm)
    {
      [object setMinValue: [[control cellAtIndex: 0] doubleValue]];
      [object setDoubleValue: [[control cellAtIndex: 1] doubleValue]];
      [object setMaxValue: [[control cellAtIndex: 2] doubleValue]];
    }
  else if (control == altForm)
    {
      [[object cell] setAltIncrementValue: 
		       [[control cellAtIndex: 0] doubleValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;

  [[unitForm cellAtIndex: 0] setDoubleValue: [anObject minValue]];
  [[unitForm cellAtIndex: 1] setDoubleValue: [anObject doubleValue]];
  [[unitForm cellAtIndex: 2] setDoubleValue: [anObject maxValue]];

  [[altForm cellAtIndex: 2] setDoubleValue: 
			       [[anObject cell] altIncrementValue]];
  
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormSliderInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormSliderInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];
  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: unitForm];
  [self _setValuesFromControl: altForm];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

@implementation	NSStepper (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormStepperAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return nil;
}
@end

@interface GormStepperAttributesInspector : IBInspector
{
  NSTextField *valueField;
  NSTextField *minimumValueField;
  NSTextField *maximumValueField;
  NSTextField *incrementValueField;
  NSButton *autorepeatButton;
  NSButton *valueWrapsButton;
}
@end

@implementation GormStepperAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == valueField)
    {
      [object setDoubleValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == minimumValueField)
    {
      [object setMinValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == maximumValueField)
    {
      [object setMaxValue:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == incrementValueField)
    {
      [object setIncrement:[control doubleValue]];
      [object setNeedsDisplay: YES];
    }
  else if (control == autorepeatButton)
    {
      switch ([control state])
	{
	case 0:
	  [object setAutorepeat: NO];
	  break;
	case 1:
	  [object setAutorepeat: YES];
	  break;
	}
    }
  else if (control == valueWrapsButton)
    {
      switch ([control state])
	{
	case 0:
	  [object setValueWraps: NO];
	  break;
	case 1:
	  [object setValueWraps: YES];
	  break;
	}
    }
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;

  [valueField setDoubleValue: [anObject doubleValue]];
  [minimumValueField setDoubleValue: [anObject minValue]];
  [maximumValueField setDoubleValue: [anObject maxValue]];
  if ([object autorepeat])
    [autorepeatButton setState: 1];
  else
    [autorepeatButton setState: 0];
  if ([object valueWraps])
    [valueWrapsButton setState: 1];
  else
    [valueWrapsButton setState: 0];
}

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormStepperInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormStepperAttributesInspector");
      return nil;
    }

  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];
  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: valueField];
  [self _setValuesFromControl: minimumValueField];
  [self _setValuesFromControl: maximumValueField];
  [self _setValuesFromControl: incrementValueField];
  [self _setValuesFromControl: autorepeatButton];
  [self _setValuesFromControl: valueWrapsButton];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end
