/* main.m

   Copyright (C) 1999,2000 Free Software Foundation, Inc.

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
#include "../../GormPrivate.h"
#include "GormNSMenu.h"

@interface MenusPalette: IBPalette
{
}
@end

@implementation MenusPalette

- (void) finishInstantiate
{
  NSView	*contents;
  NSMenuItem	*i;
  NSMenu	*m;
  NSMenu	*s;
  NSButton	*b;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];


  /*
   * The Info menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Info Panel..." 
	       action: @selector(infoPanel:) 
	keyEquivalent: @""];
  [m addItemWithTitle: @"Preferences..." 
	       action: NULL
	keyEquivalent: @""];
  [m addItemWithTitle: @"Help..." 
	       action: NULL 
	keyEquivalent: @"?"];
  [m setTitle: @"Info"];
  i = [[NSMenuItem alloc] initWithTitle: @"Info" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 140, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Info"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Font menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Font Panel..." 
	       action: @selector(orderFrontFontPanel:) 
	keyEquivalent: @"t"];
  [m addItemWithTitle: @"Bold" 
	       action: @selector(addFontTrait:)
	keyEquivalent: @"b"];
  [m addItemWithTitle: @"Italic" 
	       action: @selector(addFontTrait:)
	keyEquivalent: @"i"];
  [m addItemWithTitle: @"Underline" 
	       action: @selector(underline:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Superscript" 
	       action: @selector(superscript:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Subscript" 
	       action: @selector(subscript:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Unscript" 
	       action: @selector(unscript:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Copy Font" 
	       action: @selector(copyFont:)
	keyEquivalent: @"3"];
  [m addItemWithTitle: @"Paste Font" 
	       action: @selector(pasteFont:) 
	keyEquivalent: @"4"];
  [m setTitle: @"Font"];
  i = [[NSMenuItem alloc] initWithTitle: @"Font" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 140, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Font"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Document menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Open..." 
	       action: @selector(open:)
	keyEquivalent: @"o"];
  [m addItemWithTitle: @"New" 
	       action: @selector(new:)
	keyEquivalent: @"n"];
  [m addItemWithTitle: @"Save..." 
	       action: @selector(save:)
	keyEquivalent: @"s"];
  [m addItemWithTitle: @"Save As..." 
	       action: @selector(saveAs:)
	keyEquivalent: @"S"];
  [m addItemWithTitle: @"Save To..." 
	       action: @selector(saveTo:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Save All" 
	       action: @selector(saveAll:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"revert To Saved" 
	       action: @selector(revertToSaved:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Close" 
	       action: @selector(close:) 
	keyEquivalent: @""];
  [m setTitle: @"Document"];
  i = [[NSMenuItem alloc] initWithTitle: @"Document" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 120, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Document"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Text menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Align Left" 
	       action: @selector(alignLeft:) 
	keyEquivalent: @""];
  [m addItemWithTitle: @"Center" 
	       action: @selector(alignCenter:) 
	keyEquivalent: @""];
  [m addItemWithTitle: @"Align Right" 
	       action: @selector(alignRight:) 
	keyEquivalent: @""];
  [m addItemWithTitle: @"Show Ruler" 
	       action: @selector(toggleRuler:) 
	keyEquivalent: @""];
  [m addItemWithTitle: @"Copy Ruler" 
	       action: @selector(copyRuler:) 
	keyEquivalent: @"1"];
  [m addItemWithTitle: @"Paste Ruler" 
	       action: @selector(pasteRuler:) 
	keyEquivalent: @"2"];
  [m setTitle: @"Text"];
  i = [[NSMenuItem alloc] initWithTitle: @"Text" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 120, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Text"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Edit menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Cut" 
	       action: @selector(cut:) 
	keyEquivalent: @"x"];
  [m addItemWithTitle: @"Copy" 
	       action: @selector(copy:)
	keyEquivalent: @"c"];
  [m addItemWithTitle: @"Paste" 
	       action: @selector(paste:)
	keyEquivalent: @"v"];
  [m addItemWithTitle: @"Select All" 
	       action: @selector(selectAll:)
	keyEquivalent: @"a"];
  [m setTitle: @"Edit"];
  i = [[NSMenuItem alloc] initWithTitle: @"Edit" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 100, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Edit"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Find menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Find Panel..." 
	       action: NULL
	keyEquivalent: @"f"];
  [m addItemWithTitle: @"Find Next" 
	       action: NULL
	keyEquivalent: @"g"];
  [m addItemWithTitle: @"Find Previous" 
	       action: NULL
	keyEquivalent: @"d"];
  [m addItemWithTitle: @"Enter Selection" 
	       action: NULL
	keyEquivalent: @"e"];
  [m addItemWithTitle: @"Jump To Selection" 
	       action: NULL
	keyEquivalent: @"j"];
  [m setTitle: @"Find"];
  i = [[NSMenuItem alloc] initWithTitle: @"Find" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 100, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Find"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Format menu
   */
  m = [GormNSMenu new];
  /*
   * Font submenu
   */
  i = [m addItemWithTitle: @"Font" 
		   action: NULL
	    keyEquivalent: @""];
  s = [GormNSMenu new];
  [s addItemWithTitle: @"Font Panel..." 
	       action: @selector(orderFrontFontPanel:) 
	keyEquivalent: @"t"];
  [s addItemWithTitle: @"Bold" 
	       action: @selector(addFontTrait:)
	keyEquivalent: @"b"];
  [s addItemWithTitle: @"Italic" 
	       action: @selector(addFontTrait:)
	keyEquivalent: @"i"];
  [s addItemWithTitle: @"Underline" 
	       action: @selector(underline:)
	keyEquivalent: @""];
  [s addItemWithTitle: @"Superscript" 
	       action: @selector(superscript:)
	keyEquivalent: @""];
  [s addItemWithTitle: @"Subscript" 
	       action: @selector(subscript:)
	keyEquivalent: @""];
  [s addItemWithTitle: @"Unscript" 
	       action: @selector(unscript:)
	keyEquivalent: @""];
  [s addItemWithTitle: @"Copy Font" 
	       action: @selector(copyFont:)
	keyEquivalent: @"3"];
  [s addItemWithTitle: @"Paste Font" 
	       action: @selector(pasteFont:) 
	keyEquivalent: @"4"];
  [s setTitle: @"Font"];
  [m setSubmenu: s forItem: i];

  /*
   * Text submenu
   */
  i = [m addItemWithTitle: @"Text" 
		   action: NULL
	    keyEquivalent: @""];
  s = [GormNSMenu new];
  [s addItemWithTitle: @"Align Left" 
	       action: @selector(alignLeft:) 
	keyEquivalent: @""];
  [s addItemWithTitle: @"Center" 
	       action: @selector(alignCenter:) 
	keyEquivalent: @""];
  [s addItemWithTitle: @"Align Right" 
	       action: @selector(alignRight:) 
	keyEquivalent: @""];
  [s addItemWithTitle: @"Show Ruler" 
	       action: @selector(toggleRuler:) 
	keyEquivalent: @""];
  [s addItemWithTitle: @"Copy Ruler" 
	       action: @selector(copyRuler:) 
	keyEquivalent: @"1"];
  [s addItemWithTitle: @"Paste Ruler" 
	       action: @selector(pasteRuler:) 
	keyEquivalent: @"2"];
  [s setTitle: @"Text"];
  [m setSubmenu: s forItem: i];

  [m addItemWithTitle: @"Page Layout..." 
	       action: @selector(runPageLayout:)
	keyEquivalent: @"P"];
  [m setTitle: @"Format"];
  i = [[NSMenuItem alloc] initWithTitle: @"Format" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 80, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Format"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The Colors item
   */
  i = [[NSMenuItem alloc] initWithTitle: @"Colors..." 
				 action: @selector(orderFrontColorPanel:)
			  keyEquivalent: @""];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 80, 100, 20)];
  [b setAlignment: NSLeftTextAlignment];
  [b setTitle: @" Colors..."];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);


  /*
   * The Windows menu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Arrange In Front" 
	       action: @selector(arrangeInFront:)
	keyEquivalent: @""];
  [m addItemWithTitle: @"Miniaturize Window" 
	       action: @selector(performMiniaturize:)
	keyEquivalent: @"m"];
  [m addItemWithTitle: @"Close Window" 
	       action: @selector(performClose:)
	keyEquivalent: @"w"];
  [m setTitle: @"Windows"];
  i = [[NSMenuItem alloc] initWithTitle: @"Windows" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 60, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Windows"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The general item
   */
  i = [[NSMenuItem alloc] initWithTitle: @"Item" 
				 action: NULL
			  keyEquivalent: @""];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 60, 100, 20)];
  [b setAlignment: NSLeftTextAlignment];
  [b setTitle: @" Item"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);


  /*
   * The Services menu
   */
  m = [GormNSMenu new];
  [m setTitle: @"Services"];
  i = [[NSMenuItem alloc] initWithTitle: @"Services" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(30, 40, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Services"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);


  /*
   * The general submenu
   */
  m = [GormNSMenu new];
  [m addItemWithTitle: @"Item" 
	       action: NULL
	keyEquivalent: @""];
  [m setTitle: @"Submenu"];
  i = [[NSMenuItem alloc] initWithTitle: @"Submenu" 
				 action: @selector(submenuAction:)
			  keyEquivalent: @""];
  [i setSubmenu: m];

  b = [[NSButton alloc] initWithFrame: NSMakeRect(145, 40, 100, 20)];
  [b setImage: [NSImage imageNamed: @"common_3DArrowRight"]];
  [b setAlignment: NSLeftTextAlignment];
  [b setImagePosition: NSImageRight];
  [b setTitle: @" Submenu"];
  [contents addSubview: b];
  [self associateObject: i
		   type: IBMenuPboardType
		   with: b];
  RELEASE(b);
  RELEASE(i);
  RELEASE(m);

}
@end

