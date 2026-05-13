/* GormViewAttributeInspector.m

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

#import "GormViewAttributesInspector.h"

// - (NSString *) inspectorClassName defined in GormInternalViewEditor.m

/**
 * View attributes inspector
 */
@implementation GormViewAttributesInspector

- init
{
  self = [super init];
  if (self != nil)
    {
      NSBundle *bundle = [NSBundle bundleForClass: [self class]];
      
      if ([bundle loadNibNamed: @"GormViewAttributesInspector" 
			 owner: self
	       topLevelObjects: NULL] == NO)
	{
	  NSLog(@"Could not open gorm GormViewAttributesInspector");
	  NSLog(@"self %@", self);
	  return nil;
	}
    }

  return self;
}

/**
 * Set attributes
 */
- (IBAction) ok: (id)sender
{
  if (object == nil)
    {
      return;
    }
  else
    {
      NSRect frame = [object frame];

      if (sender == xpos)
	{
	  frame.origin.x = [xpos floatValue];
	}
      else if (sender == ypos)
	{
	  frame.origin.y = [ypos floatValue];
	}
      else if (sender == width)
	{
	  frame.size.width = [xpos floatValue];
	}
      else if (sender == height)
	{
	  frame.size.height = [xpos floatValue];
	}
      else if (sender == theClass)
	{
	  // non-editable...
	}
      else if (sender == identifier)
	{
	  if ([object respondsToSelector: @selector(setIdentifier:)])
	    {
	      [object performSelector: @selector(setIdentifier:)
			   withObject: [identifier stringValue]];
	    }
	}
      else if (sender == tag)
	{
	  [object setTag: [tag integerValue]];
	}

      // reset the frame...
      [object setFrame: frame];
      [object setNeedsDisplay: YES];

      id sv = [object superview];
      [sv setNeedsDisplay: YES];
    }
}

/**
 * Reload the inspector from the object
 */
- (IBAction) revert: (id)sender
{
  if (object == nil)
    {
      return;
    }
  else
    {
      NSRect frame = [object frame];
      NSString *className = NSStringFromClass([object class]);

      [theClass setStringValue: className];

      if ([object respondsToSelector: @selector(identifier)])
	{
	  id ident = [object performSelector: @selector(identifier)];
	  [identifier setEditable: YES];
	  [identifier setStringValue: ident];
	}
      else
	{
	  [identifier setEditable: NO];
	  [identifier setStringValue: @"N/A"];
	}

      // Set properties
      [flipped setState: ([object isFlipped] == YES) ? NSOnState : NSOffState];
      [opaque setState: ([object isOpaque] == YES) ? NSOnState : NSOffState];

      // Set the frame information...
      [xpos setFloatValue: frame.origin.x];
      [ypos setFloatValue: frame.origin.y];
      [width setFloatValue: frame.size.width];
      [height setFloatValue: frame.size.height];

      [tag setIntegerValue: [object tag]];
    }
}

/**
 * delegate for tag and Forms
 */
- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  [self ok: [aNotification object]];
}

@end
