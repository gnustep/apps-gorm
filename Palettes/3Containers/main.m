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


@class NSBrowserDelegate;

NSBrowserDelegate * browserDelegate;

/* --------------------------------------------------------------- 
 * NSBrowser Delegate
*/
@interface NSBrowserDelegate: NSObject
{
}

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column;
- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column;
- (void) browser: (NSBrowser *)sender willDisplayCell: (id)cell
           atRow: (int)row column: (int)column;

@end


@implementation NSBrowserDelegate

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
  return 0;
}

- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column
{
  return (column==0) ? @"Browser" : @"";
}

- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
           atRow: (int)row
          column: (int)column
{
  NSDebugLog(@"<%@ %x>: browser %x will display %@ %x at %d,%d",[self class],self,sender,[cell class],cell,row,column);
  // This code should never be called because there is no row
  // in our browser. But just in case...
  [cell setLeaf:YES];
  [cell setStringValue: @""];
}

@end

/* --------------------------------------------------------------- 
 * NSTableView data source
*/

@interface NSTableViewDataSource: NSObject
{
}
@end

@implementation NSTableViewDataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return 3;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  return [NSString stringWithFormat:@"%d",rowIndex];
}

@end

/* --------------------------------------------------------------- 
 * Containers Palette Display
*/

@interface ContainersPalette: IBPalette
{
}
@end

@implementation ContainersPalette

- (void) dealloc
{
  RELEASE(browserDelegate);
  [super dealloc];
}

- (void) finishInstantiate
{ 

  NSView	   *contents;
  NSTableView    *tv;
  NSTableColumn  *tc;
  NSSize          contentSize;
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
  v = [[NSBrowser alloc] initWithFrame: NSMakeRect(10, 38, 124, 116)];

  browserDelegate = [[NSBrowserDelegate alloc] init];
  [v setDelegate:browserDelegate];

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

/********************/
/* Second Column... */
/********************/


  // NSTableView
  v = [[NSScrollView alloc] initWithFrame: NSMakeRect(136, 38, 124, 116)];
  
  [v setHasVerticalScroller: YES];
  [v setHasHorizontalScroller: NO];
  //[v setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
  contentSize = [v contentSize];

  tv = [[NSTableView alloc] initWithFrame:
             NSMakeRect(0,0,contentSize.width, contentSize.height)];
  //  [tv setDataSource: [[NSTableViewDataSource alloc] init]];
  [tv setAutoresizesAllColumnsToFit: YES];
  [v setDocumentView: tv];
  RELEASE(tv);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"table"];
  [[tc headerCell] setStringValue: @" "];
  [tc setWidth: contentSize.width/2];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [tv addTableColumn: tc];
  RELEASE(tc);

  tc = [[NSTableColumn alloc] initWithIdentifier: @"view"];
  [[tc headerCell] setStringValue: @" "];
  [tc setMinWidth: contentSize.width/2];
  [tc setResizable: YES];
  [tc setEditable: YES];
  [tv addTableColumn: tc];
  RELEASE(tc);
  [tv setFrame: NSMakeRect(0,0,contentSize.width, contentSize.height)];
  
  [v setDocumentView: tv];
  [contents addSubview: v];
  RELEASE(tv);
  RELEASE(v);
  
}

@end
