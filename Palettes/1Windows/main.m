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
#include "../../GormPrivate.h"
#include "GormNSWindow.h"

@interface GormWindowMaker : NSObject <NSCoding>
{
}
@end

@implementation	GormWindowMaker
- (void) encodeWithCoder: (NSCoder*)aCoder
{
}
- (id) initWithCoder: (NSCoder*)aCoder
{
  id		w;
  unsigned	style = NSTitledWindowMask | NSClosableWindowMask
			| NSResizableWindowMask | NSMiniaturizableWindowMask;

  w = [[GormNSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 500, 300)
			    styleMask: style 
			    backing: NSBackingStoreRetained
			    defer: NO];
  [w setTitle: @"Window"];
  RELEASE(self);
  return w;
}
@end

@interface GormPanelMaker : NSObject <NSCoding>
{
}
@end

@implementation	GormPanelMaker
- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  id		w;
  unsigned	style = NSTitledWindowMask | NSClosableWindowMask
			| NSResizableWindowMask | NSMiniaturizableWindowMask;

  w = [[NSPanel alloc] initWithContentRect: NSMakeRect(0, 0, 500, 300)
				 styleMask: style 
				   backing: NSBackingStoreRetained
				     defer: NO];
  [w setTitle: @"Panel"];
  RELEASE(self);
  return w;
}
@end

@interface WindowsPalette: IBPalette
{
}
@end

@implementation WindowsPalette
- (void) finishInstantiate
{
  NSView	*contents;
  id		w;
  id		v;
  NSBundle	*bundle = [NSBundle bundleForClass: [self class]];
  NSString	*path = [bundle pathForImageResource: @"WindowDrag"];
  NSImage	*dragImage = [[NSImage alloc] initWithContentsOfFile: path];

  RELEASE(window);
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

  w = [GormWindowMaker new];
  v = [[NSButton alloc] initWithFrame: NSMakeRect(35, 60, 80, 64)];
  [v setBordered: NO];
  [v setImage: dragImage];
  [v setImagePosition: NSImageOverlaps];
  [v setTitle: @"Window"];
  [contents addSubview: v];
  [self associateObject: w
		   type: IBWindowPboardType
		   with: v];
  RELEASE(v);
  RELEASE(w);

  w = [GormPanelMaker new];
  v = [[NSButton alloc] initWithFrame: NSMakeRect(155, 60, 80, 64)];
  [v setBordered: NO];
  [v setImage: dragImage];
  [v setImagePosition: NSImageOverlaps];
  [v setTitle: @"Panel"];
  [contents addSubview: v];
  [self associateObject: w
		   type: IBWindowPboardType
		   with: v];
  RELEASE(v);
  RELEASE(w);

  RELEASE(dragImage);
}
@end

/* ---------------------------------------------------------
NSwindow inspector
---------------------------------------------------------*/
@implementation NSWindow (GormPrivate)
+ (id) allocSubstitute
{
  return [GormNSWindow alloc];
}
@end
/*
@interface NSWindow (GormPrivate)
- (void) _setStyleMask: (unsigned int)mask;
@end
*/
/*
@implementation GormWindow (GormPrivate)
// private method to change the Window style mask on the fly
- (void) _setStyleMask: (unsigned int)mask
{
   _styleMask = mask;
   DPSstylewindow(GSCurrentContext(), mask, [self windowNumber]);
}
@end
*/
@implementation	GormNSWindow (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormWindowAttributesInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormWindowSizeInspector";
}
@end



@interface GormWindowAttributesInspector : IBInspector
{
  id titleForm;
  id backingMatrix;
  id optionMatrix;
  id controlMatrix;
}
@end

@implementation GormWindowAttributesInspector

- (void) _setValuesFromControl: control
{

  if (control == titleForm)
    {
      [object setTitle: [[control cellAtIndex: 0] stringValue] ]; 
    }
  else if (control == backingMatrix)
    {
      [object setBackingType: [[control selectedCell] tag] ];
    }
  else if (control == controlMatrix)
    {
      unsigned int newStyleMask;
      int rows,cols,i;

      [control getNumberOfRows:&rows columns:&cols];

      newStyleMask = [object styleMask];
      for (i=0;i<rows;i++) {
        if ([[control cellAtRow: i column: 0] state] == NSOnState)
          newStyleMask |= [[control cellAtRow: i column: 0] tag];
        else
          newStyleMask &= ~[[control cellAtRow: i column: 0] tag];
      }
 
      [object setStyleMask: newStyleMask];
      // FIXME: This doesn't refresh the window decoration. How to do that?
      // (currently needs manual hide/unhide to update decorations)
      [object display];
   }
  else if (control == optionMatrix)
    {
      BOOL flag;

      // Release When Closed
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setReleasedWhenClosed: flag];

      // Hide on deactivate
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setHidesOnDeactivate: flag];

      // Visible at launch time. (not an object property. Stored in a Gorm dictionnary)
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      {
        GormDocument	*doc = (GormDocument*)[(id<IB>)NSApp activeDocument];
        [doc setObject: object isVisibleAtLaunch: flag];
      }

      // Deferred
      // FIXME: This flag is not a WIndow property. Like Visible at launch time
      // it should be stored in the Nib File and used at the Window creation time
      // but I do not know how to do that
      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;


      // One shot
     flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
     [object setOneShot: flag];

      // Dynamic depth limit
     flag = ([[control cellAtRow: 5 column: 0] state] == NSOnState) ? YES : NO;
     [object setDynamicDepthLimit: flag];

     // wants to be color
     // FIXME:  probably means window depth > 2 bits per pixel but don't know
     // exactly what NSWindow method to use to enforce  that.
     flag = ([[control cellAtRow: 6 column: 0] state] == NSOnState) ? YES : NO;
     
    }
}


- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    return;

  [[titleForm cellAtIndex: 0] setStringValue: [anObject title] ];

  [backingMatrix selectCellWithTag: [anObject backingType] ];

 
  [controlMatrix deselectAllCells];
  if ([anObject styleMask] & NSMiniaturizableWindowMask)
    [controlMatrix selectCellAtRow: 0 column: 0];
  if ([anObject styleMask] & NSClosableWindowMask)
    [controlMatrix selectCellAtRow: 1 column: 0];
  if ([anObject styleMask] & NSResizableWindowMask)
    [controlMatrix selectCellAtRow: 2 column: 0];

  [optionMatrix deselectAllCells];
  if ([anObject isReleasedWhenClosed])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject hidesOnDeactivate])
    [optionMatrix selectCellAtRow: 1 column: 0];
  {
    GormDocument	*doc = (GormDocument*)[(id<IB>)NSApp activeDocument];
    if ([doc objectIsVisibleAtLaunch: anObject])
      [optionMatrix selectCellAtRow: 2 column: 0];
  }
  
  // FIXME: defer comes here.

  if ([anObject isOneShot])
    [optionMatrix selectCellAtRow: 4 column: 0];

  if ([anObject hasDynamicDepthLimit])
    [optionMatrix selectCellAtRow: 5 column: 0];
  
  // FIXME: wants to be color comes here
  
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormWindowInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormWindowInspector");
      return nil;
    }
  return self;
}

- (void) ok: (id)sender
{
    [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end



@interface GormWindowSizeInspector : IBInspector
{
  NSForm *sizeForm;
  NSForm *minForm;
}
@end

@implementation GormWindowSizeInspector

- (void) _setValuesFromControl: control
{
  if (control == sizeForm)
    {
      NSRect rect;
      rect = NSMakeRect([[control cellAtIndex: 0] floatValue],
			[[control cellAtIndex: 1] floatValue],
			[[control cellAtIndex: 2] floatValue],
			[[control cellAtIndex: 3] floatValue]);
      [object setFrame: rect display: YES];
    }
  else if (control == minForm)
    {
      NSSize size;
      size = NSMakeSize([[minForm cellAtIndex: 0] floatValue],
			[[minForm cellAtIndex: 1] floatValue]);
      [object setMinSize: size];
    }
}

- (void) _getValuesFromObject: anObject
{
  NSRect frame;
  NSSize size;

  if (anObject != object)
    return;

  frame = [anObject frame];
  [[sizeForm cellAtIndex: 0] setFloatValue: NSMinX(frame)];
  [[sizeForm cellAtIndex: 1] setFloatValue: NSMinY(frame)];
  [[sizeForm cellAtIndex: 2] setFloatValue: NSWidth(frame)];
  [[sizeForm cellAtIndex: 3] setFloatValue: NSHeight(frame)];

  size = [anObject minSize];
  [[minForm cellAtIndex: 0] setFloatValue: size.width];
  [[minForm cellAtIndex: 1] setFloatValue: size.height];
}

- (void) windowChangeNotification: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  
  [self _getValuesFromObject: notifier];
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormWindowSizeInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormWindowSizeInspector");
      return nil;
    }
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(windowChangeNotification:)
             name: NSWindowDidMoveNotification
           object: object];
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(windowChangeNotification:)
             name: NSWindowDidResizeNotification
           object: object];
  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sizeForm];
  [self _setValuesFromControl: minForm];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end
