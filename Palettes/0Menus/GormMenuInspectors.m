/* GormMenuInspectors.m
 *
 * Copyright (C) 2000 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	2000
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <AppKit/AppKit.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@interface GormMenuAttributesInspector : IBInspector
{
  NSTextField	*titleText;
  NSMatrix      *menuType;
}
@end

@implementation GormMenuAttributesInspector

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  [object setTitle: [titleText stringValue]];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMenuAttributesInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormMenuAttributesInspector");
      return nil;
    }
  return self;
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [titleText setStringValue: [object title]];
}

@end



@implementation	NSMenuItem (IBObjectAdditions)
- (NSString*) inspectorClassName
{
  return @"GormMenuItemAttributesInspector";
}
@end

@interface GormMenuItemAttributesInspector : IBInspector
{
  NSTextField	*titleText;
  NSTextField	*shortCut;
  NSTextField	*tagText;
}
@end

@implementation GormMenuItemAttributesInspector

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id	o = [aNotification object];

  if (o == titleText)
    {
      [object setTitle: [titleText stringValue]];
    }
  if (o == shortCut)
    {
      NSString	*s = [[shortCut stringValue] stringByTrimmingSpaces];

      [object setKeyEquivalent: s];
    }
  if (o == tagText)
    {
      [object setTag: [tagText intValue]];
    }
  [[object menu] display];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormMenuItemAttributesInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormMenuItemAttributesInspector");
      return nil;
    }
  return self;
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [titleText setStringValue: [object title]];
  [shortCut setStringValue: [object keyEquivalent]];
  [tagText setIntValue: [object tag]];
}

@end

