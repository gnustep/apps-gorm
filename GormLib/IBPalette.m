/* IBPalette.m
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
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

#include <InterfaceBuilder/IBPalette.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

NSString	*IBCellPboardType = @"IBCellPboardType";
NSString	*IBMenuPboardType = @"IBMenuPboardType";
NSString	*IBMenuCellPboardType = @"IBMenuCellPboardType";
NSString	*IBObjectPboardType = @"IBObjectPboardType";
NSString	*IBViewPboardType = @"IBViewPboardType";
NSString	*IBWindowPboardType = @"IBWindowPboardType";
NSString	*IBFormatterPboardType = @"IBFormatterPboardType";

@implementation	IBPalette

static NSMapTable	*viewToObject = 0;
static NSMapTable	*viewToType = 0;

+ (void) initialize
{
  if (self == [IBPalette class])
    {
      viewToObject = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
	NSObjectMapValueCallBacks, 20);
      viewToType = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
	NSObjectMapValueCallBacks, 20);
    }
}

+ (id) objectForView: (NSView*)aView
{
  id	obj = (id)NSMapGet(viewToObject, (void*)aView);

  if (obj == nil)
    {
      obj = aView;
    }
  return obj;
}

+ (NSString*) typeForView: (NSView*)aView
{
  NSString	*type = (NSString*)NSMapGet(viewToType, (void*)aView);

  if (type == nil)
    {
      type = IBViewPboardType;
    }
  return type;
}

- (void) associateObject: (id)anObject
		    type: (NSString*)aType
		    with: (NSView*)aView
{
  NSMapInsert(viewToType, (void*)aView, (id)aType);
  NSMapInsert(viewToObject, (void*)aView, (id)anObject);
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(icon);
  [super dealloc];
}

- (void) finishInstantiate
{
}

- (id) init
{
  NSBundle	*bundle;
  NSDictionary	*paletteInfo;
  NSString	*fileName;
  
  bundle = [NSBundle bundleForClass: [self class]]; 

  fileName = [bundle pathForResource: @"palette" ofType: @"table"];
  paletteInfo = [[NSString stringWithContentsOfFile: fileName]
    propertyListFromStringsFileFormat];

  fileName = [paletteInfo objectForKey: @"Icon"];
  fileName = [bundle  pathForImageResource: fileName];
  if (fileName == nil)
    {
      NSRunAlertPanel(NULL, @"Icon for palette is missing",
		       @"OK", NULL, NULL);
      AUTORELEASE(self);
      return nil;
    }
  icon = [[NSImage alloc] initWithContentsOfFile: fileName];

  fileName = [paletteInfo objectForKey: @"NibFile"];
  if (fileName != nil && [fileName isEqual: @""] == NO)
    {
      if ([NSBundle loadNibNamed: fileName owner: self] == NO)
	{
	  NSRunAlertPanel(NULL, @"Nib for palette would not load",
			   @"OK", NULL, NULL);
	  AUTORELEASE(self);
	  return nil;
	}
    }

  return self;
}

- (NSImage*) paletteIcon
{
  return icon;
}

- (NSWindow*) originalWindow
{
  return window;
}
@end

