/* main.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Date: Nov 2001
   
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
#include "../../Gorm.h"

@interface DataPalette: IBPalette
{
}
@end

@implementation DataPalette

- (void) finishInstantiate
{ 

  NSView	*contents;
  NSTextView	*tv;
  NSSize        contentSize;
  id		v;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

/*******************/
/* First Column... */
/*******************/


  // NSScrollView
  v = [[NSScrollView alloc] initWithFrame: NSMakeRect(20, 22, 113,148)];
  [v setHasVerticalScroller: YES];
  [v setHasHorizontalScroller: NO];
  [v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  contentSize = [v contentSize];

  tv = [[NSTextView alloc] initWithFrame:
      NSMakeRect(0,0,contentSize.width, contentSize.height)];
  [tv setMinSize: NSMakeSize(0.0, 0.0)];
  [tv setMaxSize: NSMakeSize(1.0E7,1.0E7)];
  [tv setVerticallyResizable:YES];
  [tv setHorizontallyResizable:NO];
  [tv setAutoresizingMask: NSViewWidthSizable];
  [tv setSelectable: YES];
  [tv setEditable: YES];
  [tv setRichText: YES];
  [tv setImportsGraphics: YES];

  [[tv textContainer] setContainerSize:contentSize];
  [[tv textContainer] setWidthTracksTextView:YES];
  
  [v setDocumentView:tv];
  [contents addSubview: v];
  RELEASE(v);
  RELEASE(tv);

/********************/
/* Second Column... */
/********************/


  // NSImageView
  v = [[NSImageView alloc] initWithFrame: NSMakeRect(143, 98, 96, 72)];
  [v setImageFrameStyle: NSImageFramePhoto]; //FramePhoto not implemented
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"Sunday_seurat.tiff"]];
  [contents addSubview: v];
  RELEASE(v);

  // Number and Date formatter
  v = [[NSImageView alloc] initWithFrame: NSMakeRect(143, 48, 43, 43)];
  [v setImageFrameStyle: NSImageFramePhoto]; //FramePhoto not implemented
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"number_formatter.tiff"]];
  [contents addSubview: v];
  RELEASE(v);

  v = [[NSImageView alloc] initWithFrame: NSMakeRect(196, 48, 43, 43)];
  [v setImageFrameStyle: NSImageFramePhoto]; //FramePhoto not implemented
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"date_formatter.tiff"]];
  [contents addSubview: v];
  RELEASE(v);
  
  // NSComboBox
  v = [[NSComboBox alloc] initWithFrame: NSMakeRect(143, 22, 96, 21)];
  [contents addSubview: v];
  RELEASE(v);
  
}

@end

