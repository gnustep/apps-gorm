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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <GormCore/GormCustomView.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/GormOpenGLView.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSNibLoading.h>

#include <GNUstepGUI/GSNibTemplates.h>

@class GSCustomView;

@implementation GormCustomView 

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];

  [self setBackgroundColor: [NSColor darkGrayColor]];
  [self setTextColor: [NSColor whiteColor]];
  [self setDrawsBackground: YES];
  [self setAlignment: NSCenterTextAlignment];
  [self setFont: [NSFont boldSystemFontOfSize: 0]];
  [self setEditable: NO];
  [self setSelectable: NO];
  [self setClassName: @"CustomView"];
  
  return self;
}

- (NSString*) inspectorClassName
{
  return @"GormFilesOwnerInspector";
}

- (NSString*) classInspectorClassName
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

@interface GormTestCustomView : GSNibItem <NSCoding>
{
}
@end

@implementation	GormTestCustomView

- (Class) _bestPossibleSuperClass
{
  Class cls = [NSView class];
  GormClassManager *classManager = [(id<Gorm>)NSApp classManager];

  if([classManager isSuperclass: @"NSOpenGLView" linkedToClass: theClass] ||
     [theClass isEqual: @"NSOpenGLView"])
    {
      cls = [GormOpenGLView class];
    }
  else  if([classManager isSuperclass: @"NSView" linkedToClass: theClass])
    {
      NSString *superClass = [classManager nonCustomSuperClassOf: theClass];

      // get the superclass if one exists...
      if(superClass != nil)
	{
	  cls = NSClassFromString(superClass);
	  if(cls == nil)
	    {
	      cls = [NSView class];
	    }
	}
    }

  return cls;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  id		obj;
  Class		cls;
  unsigned int      mask;
  GormClassManager *classManager = [(id<Gorm>)NSApp classManager];
  
  [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
  theFrame = [aCoder decodeRect];
  [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	  at: &mask];
  
  cls = NSClassFromString(theClass);
  if([classManager isSuperclass: @"NSOpenGLView" linkedToClass: theClass] ||
     [theClass isEqual: @"NSOpenGLView"] || cls == nil)
    {
      cls = [self _bestPossibleSuperClass];
    }
  
  obj = [cls allocWithZone: [self zone]];
  if (theFrame.size.height > 0 && theFrame.size.width > 0)
    obj = [obj initWithFrame: theFrame];
  else
    obj = [obj init];
  
  if ([obj respondsToSelector: @selector(setAutoresizingMask:)])
    {
      [obj setAutoresizingMask: mask];
    }
  
  /*
  if (![self isKindOfClass: [GSCustomView class]])
    {
      RETAIN(obj);
    }
  */

  RELEASE(self);
  return obj;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  // nothing to do.  This is a class for testing custom views only. GJC
}
@end

