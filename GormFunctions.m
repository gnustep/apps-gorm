/* GormFunctions.m
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
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

#include "GormFunctions.h"
#include "GormViewEditor.h"
#include <AppKit/AppKit.h>
#include <Foundation/NSDictionary.h>

// find all subitems for the given items...
void findAllWithArray(id item, NSMutableArray *array)
{
  [array addObject: item];
  if([item isKindOfClass: [NSMenuItem class]])
    {
      if([item hasSubmenu])
	{
	  NSMenu *submenu = [item submenu];
	  NSArray *items = [submenu itemArray];
	  NSEnumerator *e = [items objectEnumerator];
	  id i = nil;

	  [array addObject: submenu];
	  while((i = [e nextObject]) != nil)
	    {
	      findAllWithArray(i, array);
	    }
	}
    } 
}

// find all sub items for the selections...
NSArray* findAllSubmenus(NSArray *array)
{
  NSEnumerator *e = [array objectEnumerator];
  id i = nil;
  NSMutableArray *results = [[NSMutableArray alloc] init];

  while((i = [e nextObject]) != nil)
    {
      findAllWithArray(i, results);
    }

  return results;
}

NSArray* findAll(NSMenu *menu)
{
  NSArray *items = [menu itemArray];
  return findAllSubmenus(items);
}

void subviewsForView(NSView *view, NSMutableArray *array)
{
  if(view != nil)
    {
      NSArray *subviews = [view subviews];
      NSEnumerator *en = [subviews objectEnumerator];
      NSView *aView = nil;

      // if it's not me and it's not and editor, include it in the list of
      // things to be deleted from the document.
      if(![view isKindOfClass: [GormViewEditor class]]) 
	{
	  [array addObject: view];
	}

      while((aView = [en nextObject]) != nil)
	{
	  subviewsForView( aView, array );
	}
    }
}

NSArray *allSubviews(NSView *view)
{
  NSMutableArray *views = [NSMutableArray array];
  subviewsForView( view, views );
  return views;
}

// cut the text...  code taken from GWorkspace, by Enrico Sersale
static inline NSString *cutText(NSString *filename, id label, int lenght)
{
  NSString *cutname = nil;
  NSString *reststr = nil;
  NSString *dots;
  NSFont *labfont;
  NSDictionary *attr;
  float w, cw, dotslenght;
  int i;
  
  cw = 0;
  labfont = [label font];
  
  attr = [NSDictionary dictionaryWithObjectsAndKeys: 
			 labfont, NSFontAttributeName, nil];  
  
  dots = @"...";  
  dotslenght = [dots sizeWithAttributes: attr].width;  
  w = [filename sizeWithAttributes: attr].width;
  
  if (w > lenght) 
    {
      i = 0;
      while (cw <= (lenght - dotslenght)) 
	{
	  if (i == [filename cStringLength]) 
	    {
	      break;
	    }
	  cutname = [filename substringToIndex: i];
	  reststr = [filename substringFromIndex: i];
	  cw = [cutname sizeWithAttributes: attr].width;
	  i++;
	}	
      if ([cutname isEqual: filename] == NO) 
	{      
	  if ([reststr cStringLength] <= 3) 
	    { 
	      return filename;
	    } 
	  else 
	    {
	      cutname = [cutname stringByAppendingString: dots];
	    }
	} 
      else 
	{
	  return filename;
	}	
    } 
  else 
    {
      return filename;
    }
  
  return cutname;
}

NSString *cutFileLabelText(NSString *filename, id label, int length)
{
  if (length > 0) 
    {
      return cutText(filename, label, length);
    }
  return filename;
}

NSSize defaultCellSize()
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 
  int width = [defaults integerForKey: @"CellSizeWidth"];
  NSSize size = NSMakeSize(width, 72);
  return size;
}

NSColor *colorFromDict(NSDictionary *dict)
{
  if(dict != nil)
    {
      return [NSColor colorWithCalibratedRed: [[dict objectForKey: @"red"] floatValue]
		      green: [[dict objectForKey: @"green"] floatValue]
		      blue: [[dict objectForKey: @"blue"] floatValue]
		      alpha: [[dict objectForKey: @"alpha"] floatValue]];
    }
  return nil;
}

NSDictionary *colorToDict(NSColor *color)
{
  if(color != nil)
    {
      NSMutableDictionary *dict = [NSMutableDictionary dictionary];
      float red, green, blue, alpha;
      NSNumber *fred = nil;
      NSNumber *fgreen = nil;
      NSNumber *fblue = nil;
      NSNumber *falpha = nil;
      
      [color getRed: &red
	     green: &green
	     blue: &blue
	     alpha: &alpha];
      
      fred   = [NSNumber numberWithFloat: red];
      fgreen = [NSNumber numberWithFloat: green];
      fblue  = [NSNumber numberWithFloat: blue];
      falpha = [NSNumber numberWithFloat: alpha];
      
      [dict setObject: fred   forKey: @"red"];
      [dict setObject: fgreen forKey: @"green"];
      [dict setObject: fblue  forKey: @"blue"];
      [dict setObject: falpha forKey: @"alpha"];
      
      return dict;
    }
  return nil;
}
