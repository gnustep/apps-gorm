/* GormResourcesManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include "GormPrivate.h"

@class	GormObjectEditor;

@implementation GormResourcesManager

static NSImage	*objectsImage = nil;
static NSImage	*imagesImage = nil;
static NSImage	*soundsImage = nil;
static NSImage	*classesImage = nil;

+ (void) initialize
{
  if (self == [GormResourcesManager class])
    {
      NSBundle	*bundle;
      NSString	*path;

      bundle = [NSBundle mainBundle];
      path = [bundle pathForImageResource: @"GormObject"];
      if (path != nil)
	{
	  objectsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormImage"];
      if (path != nil)
	{
	  imagesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormSound"];
      if (path != nil)
	{
	  soundsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormClass"];
      if (path != nil)
	{
	  classesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
    }
}

+ (GormResourcesManager*) newManagerForDocument: (id<IBDocuments>)doc
{
  GormResourcesManager	*mgr;

  mgr = [self alloc];
  mgr->document = doc;
  mgr = [mgr init];
  return mgr;
}

- (void) addObject: (id)anObject
{
  [objectsView addObject: anObject];
}

- (void) dealloc
{
  [window performClose: self];
  RELEASE(window);
  RELEASE(objectsView);
  [super dealloc];
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSRect	winrect = NSMakeRect(100,100,340,252);
      NSRect	selectionRect = {{0, 188}, {240, 64}};
      NSRect	scrollRect = {{0, 0}, {340, 188}};
      NSRect	mainRect = {{20, 0}, {320, 188}};
      NSImage	*image;
      NSButtonCell	*cell;
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask
			| NSResizableWindowMask | NSMiniaturizableWindowMask;

      window = [[NSWindow alloc] initWithContentRect: winrect
					   styleMask: style 
					     backing: NSBackingStoreRetained
					       defer: NO];
      [window setDelegate: self];
      [window setMinSize: [window frame].size];
      [window setTitle: @"UNTITLED"];

      [nc addObserver: self
	     selector: @selector(windowWillClose:)
		 name: NSWindowWillCloseNotification
	       object: window];

      selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
						 mode: NSRadioModeMatrix
					    cellClass: [NSButtonCell class]
					 numberOfRows: 1
				      numberOfColumns: 4];
      [selectionView setTarget: self];
      [selectionView setAction: @selector(changeView:)];
      [selectionView setAutosizesCells: NO];
      [selectionView setCellSize: NSMakeSize(64,64)];
      [selectionView setIntercellSpacing: NSMakeSize(28,0)];
      [selectionView setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];

      if ((image = objectsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 0];
	  [cell setImage: image];
	  [cell setTitle: @"Objects"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = imagesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 1];
	  [cell setImage: image];
	  [cell setTitle: @"Images"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = soundsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 2];
	  [cell setImage: image];
	  [cell setTitle: @"Sounds"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = classesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 3];
	  [cell setImage: image];
	  [cell setTitle: @"Classes"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      [[window contentView] addSubview: selectionView];
      RELEASE(selectionView);

      scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setHasHorizontalScroller: NO];
      [scrollView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [[window contentView] addSubview: scrollView];
      RELEASE(scrollView);

      mainRect.origin = NSMakePoint(0,0);
      objectsView = [[GormObjectEditor alloc] initWithObject: nil
						  inDocument: document];
      [objectsView setFrame: mainRect];
      [objectsView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setDocumentView: objectsView];
    }
  return self;
}

- (void) removeObject: (id)anObject
{
  [objectsView removeObject: anObject];
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) windowShouldClose: (NSWindow*)aWindow
{
  return [document documentShouldClose];
}

- (void) windowWillClose: (NSNotification*)aNotification
{
  [document documentWillClose];
}
@end

