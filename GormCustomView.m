/* GormCustomView - Visual representation of a custom view placeholder
 *
 * Copyright (C) 2001 Free Software Foundation, Inc.
 *
 * Author:	Adam Fedor <fedor@gnu.org>
 * Date:	2001
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

#include "GormCustomView.h"
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSFont.h>

@class GSCustomView;

@implementation GormCustomView 

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];

  [self setBackgroundColor: [NSColor darkGrayColor]];
  [self setTextColor: [NSColor whiteColor]];
  [self setDrawsBackground: YES];
  [self setAlignment: NSCenterTextAlignment];
  [self setFont: [NSFont boldSystemFontOfSize: 12]];
  [self setEditable: NO];
  [self setClassName: @"CustomView"];
  return self;
}

- (NSString*) inspectorClassName
{
  return @"GormFilesOwnerInspector";
}

- (void) setClassName: (NSString *)aName
{
  [self setStringValue: aName];
}

- (NSString *) className
{
  return [self stringValue];
}


- (Class) classForCoder
{
  return [GSCustomView class];
}

/*
 * This needs to be coded like a GSNibItem. How do we make sure this
 * tracks changes in GSNibItem coding?
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: [self stringValue]];
  [aCoder encodeRect: _frame];
  [aCoder encodeValueOfObjCType: @encode(unsigned int) 
	  at: &_autoresizingMask];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: 
			  NSStringFromClass([GSCustomView class])];

  if (version == 1)
    {
      NSString *string;
      // do not decode super. We need to maintain mapping to NibItems
      string = [aCoder decodeObject];
      _frame = [aCoder decodeRect];
      [self initWithFrame: _frame];
      [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	      at: &_autoresizingMask];
      [self setClassName: string];
      return self;
    }
  else if (version == 0)
    {
      NSString *string;
      // do not decode super. We need to maintain mapping to NibItems
      string = [aCoder decodeObject];
      _frame = [aCoder decodeRect];
      
      [self initWithFrame: _frame];
      [self setClassName: string];
      return self;
    }
  else
    {
      NSLog(@"no initWithCoder for version");
      RELEASE(self);
      return nil;
    }
}


@end

