/* main.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard frith-Macdonald (richard@brainstorm.co.uk>
   Date: 1999
   
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
#include "GormNSBrowser.h"
#include "GormNSTableView.h"
#include "GormNSOutlineView.h"
#include <math.h>


/* --------------------------------------------------------------- 
 * Containers Palette Display
*/

@interface ContainersPalette: IBPalette
{
}
@end

@implementation ContainersPalette

- (void) finishInstantiate
{ 

  NSView	   *contents;
  NSTableView      *tv;
  NSOutlineView    *ov;
  NSTableColumn    *tc;
  NSSize           contentSize;
  id		   v;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

/*******************/
/* First Column... */
/*******************/


  // NSBrowser
  // 124 is the minimum width. Below that the browser doesn't display !!
  v = [[GormNSBrowser alloc] initWithFrame: NSMakeRect(10, 98, 124, 78)];

  //  [v setDelegate:nil];
  [v setHasHorizontalScroller: YES];
  [v setTitled: YES];
  [v loadColumnZero];

  //[v setTitle: @"Browser" ofColumn:0];
  //[v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  [contents addSubview: v];
  RELEASE(v);

  //  browserDelegate = [[NSBrowserDelegate alloc] init];
  //[v setDelegate:browserDelegate];
  //  [v setMaxVisibleColumns: 3];
  //[v setAllowsMultipleSelection:NO];
//  [v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  
  // NSTabView
  v = [[NSTabView alloc] initWithFrame: NSMakeRect(10, 10, 124, 78)];
  [contents addSubview: v];
  {
    NSView *vv;
    NSTabViewItem *tvi;
    tvi = [[NSTabViewItem alloc] initWithIdentifier: @"item 1"];
    [tvi setLabel: @"Item 1"];
    vv = [[NSView alloc] init];
    [vv setAutoresizingMask: 
	 NSViewWidthSizable | NSViewHeightSizable];
    [tvi setView: vv];
    [v addTabViewItem: tvi];
    RELEASE(tvi);
    tvi = [[NSTabViewItem alloc] initWithIdentifier: @"item 2"];
    [tvi setLabel: @"Item 2"];
    vv = [[NSView alloc] init];
    [vv setAutoresizingMask: 
	 NSViewWidthSizable | NSViewHeightSizable];
    [tvi setView: vv];
    [v addTabViewItem: tvi];
    RELEASE(tvi);
  }
  RELEASE(v);
  

/********************/
/* Second Column... */
/********************/


  // NSTableView
  v = [[NSScrollView alloc] initWithFrame: 
			      NSMakeRect(136, 10, 124, 78)];
  
  [v setHasVerticalScroller: YES];
  [v setHasHorizontalScroller: NO];
  //[v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  contentSize = [v contentSize];

  tv = [[GormNSTableView alloc] initWithFrame:
				  NSZeroRect];
  //  [tv setDataSource: [[NSTableViewDataSource alloc] init]];
  //  [tv setAutoresizesAllColumnsToFit: YES];
  [v setDocumentView: tv];
  RELEASE(tv);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"column1"];
  [[tc headerCell] setStringValue: @" "];
  [tc setWidth: floor(contentSize.width/2)];
  [tc setMinWidth: 20];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [tv addTableColumn: tc];
  RELEASE(tc);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"column2"];
  [[tc headerCell] setStringValue: @" "];
  [tc setWidth: ceil(contentSize.width/2)];
  [tc setMinWidth: 20];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [tv addTableColumn: tc];
  RELEASE(tc);
  
  //  [v setDocumentView: tv];
  [contents addSubview: v];
  RELEASE(tv);
  RELEASE(v);
  
  // NSOutlineView
  v = [[NSScrollView alloc] initWithFrame: 
			      NSMakeRect(136, 98, 124, 78)];
  
  [v setHasVerticalScroller: YES];
  [v setHasHorizontalScroller: NO];
  //[v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  contentSize = [v contentSize];

  ov = [[GormNSOutlineView alloc] initWithFrame:
				    NSZeroRect];
  //  [tv setAutoresizesAllColumnsToFit: YES];
  [v setDocumentView: ov];
  RELEASE(tv);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"classes"];
  [[tc headerCell] setStringValue: @" "];
  [tc setWidth: floor(contentSize.width/2)];
  [tc setMinWidth: 20];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [ov addTableColumn: tc];
  [ov setOutlineTableColumn: tc];
  RELEASE(tc);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"outlets"];
  [[tc headerCell] setStringValue: @" "];
  [tc setWidth: ceil(contentSize.width/2)];
  [tc setMinWidth: 20];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [ov addTableColumn: tc];
  RELEASE(tc);
  [ov setDrawsGrid: NO];
  [ov setIndentationPerLevel: 10.];
  [ov setIndentationMarkerFollowsCell: YES];
  
  [contents addSubview: v];
  RELEASE(ov);
  RELEASE(v);
  
  
}

@end
