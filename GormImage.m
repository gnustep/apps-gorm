/* GormImageEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2002
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

#include <AppKit/NSImage.h>
#include "GormImage.h"

// image proxy object...
@implementation GormImage
+ (GormImage*)imageForPath: (NSString *)aPath
{  
  return AUTORELEASE([[GormImage alloc] initWithPath: aPath]);
}

- (id) initWithPath: (NSString *)aPath
{
  NSString *aName = [[aPath lastPathComponent] stringByDeletingPathExtension];
  if((self = [self initWithName: aName path: aPath]) == nil)
    {
      RELEASE(self);
    }
  return self;
}

- (id) initWithName: (NSString *)aName
	       path: (NSString *)aPath
{
  if((self = [super init]) != nil)
    {
      NSSize originalSize;
      float ratioH;
      float ratioW;

      ASSIGN(name, aName);
      ASSIGN(path, aPath);
      image = RETAIN([[NSImage alloc] initByReferencingFile: aPath]);
      smallImage = RETAIN([[NSImage alloc] initWithContentsOfFile: aPath]);
      [image setName: aName];
      
      if (smallImage == nil)
	{
	  RELEASE(name);
	  RELEASE(path);
	  return nil;
	}
      
      originalSize = [smallImage size];
      ratioW = originalSize.width / 70;
      ratioH = originalSize.height / 55;
      
      if (ratioH > 1 || ratioW > 1)
	{
	  [smallImage setScalesWhenResized: YES];
	  if (ratioH > ratioW)
	    {
	      [smallImage setSize: NSMakeSize(originalSize.width / ratioH, 55)];
	    }
	  else 
	    {
	      [smallImage setSize: NSMakeSize(70, originalSize.height / ratioW)];
	    }
	}

      isSystemImage = NO;
      isInWrapper = NO;
    }
  else
    {
      RELEASE(self);
    }

  return self;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(path);
  RELEASE(image);
  RELEASE(smallImage);
  [super dealloc];
}

- (void) setImageName: (NSString *)aName
{
  ASSIGN(name, aName);
}

- (NSString *) imageName
{
  return name;
}

- (void) setImagePath: (NSString *)aPath
{
  ASSIGN(path, aPath);
}

- (NSString *) imagePath
{
  return path;
}

- (NSImage *) normalImage
{
  return image;
}

- (NSImage *) image
{
  return smallImage;
}

- (void) setSystemImage: (BOOL)flag
{
  isSystemImage = flag;
}

- (BOOL) isSystemImage
{
  return isSystemImage;
}

- (void) setInWrapper: (BOOL)flag
{
  isInWrapper = flag;
}

- (BOOL) isInWrapper
{
  return isInWrapper;
}

- (NSString *)inspectorClassName
{
  return @"GormImageInspector"; 
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) connectInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
}
@end
