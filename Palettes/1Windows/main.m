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
#include <InterfaceBuilder/IBPalette.h>
#include <InterfaceBuilder/IBInspector.h>
#include <InterfaceBuilder/IBApplicationAdditions.h>
#include "GormDocument.h"
#include "GormNSWindow.h"
#include "GormNSPanel.h"
#include "NSColorWell+GormExtensions.h"

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
  NSRect        screenRect = [[NSScreen mainScreen] frame];
  float
    x = (screenRect.size.width - 500)/2, 
    y = (screenRect.size.height - 300)/2;
  NSRect        windowRect = NSMakeRect(x,y,500,300);

  w = [[GormNSWindow alloc] initWithContentRect: windowRect 
			    styleMask: style 
			    backing: NSBackingStoreRetained
			    defer: NO];
  [w setFrame: windowRect display: YES];
  [w setTitle: @"Window"];
  [w orderFront: self];
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
  unsigned	style = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask;
  NSRect        screenRect = [[NSScreen mainScreen] frame];
  float         
    x = (screenRect.size.width - 500)/2, 
    y = (screenRect.size.height - 300)/2;
  NSRect        windowRect = NSMakeRect(x,y,500,300);
  
  w = [[GormNSPanel alloc] initWithContentRect: windowRect 
			   styleMask: style 
			   backing: NSBackingStoreRetained
			   defer: NO];
  [w setFrame: windowRect display: YES];
  [w setTitle: @"Panel"];
  [w orderFront: self];
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

  RELEASE(originalWindow);
  originalWindow= [[NSWindow alloc] initWithContentRect: 
				      NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [originalWindow contentView];

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

// the normal classes...
@implementation	NSWindow (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormWindowAttributesInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormWindowSizeInspector";
}
@end

@implementation	NSPanel (IBInspectorClassNames)
- (NSString*) inspectorClassName
{
  return @"GormWindowAttributesInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormWindowSizeInspector";
}
@end

// special subclasses...
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

@implementation	GormNSPanel (IBInspectorClassNames)
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
  id iconNameForm;
  id clearButton;
  id colorWell;
}
@end

@implementation GormWindowAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == titleForm)
    {
      [object setTitle: [[control cellAtIndex: 0] stringValue] ]; 
    }
  else if (control == iconNameForm)
    {
      NSString *string = [[control cellAtIndex: 0] stringValue];
      NSImage *image;

      if ([string length] > 0)
	{
	  image = [NSImage imageNamed: string];
	  [object setMiniwindowImage: image];
	}
      else
	{
	  // use the default, if the string is empty.
	  [object setMiniwindowImage: nil];
	}
    }
  else if (control == clearButton)
    {
      [[iconNameForm cellAtIndex: 0] setStringValue: nil];
      [object setMiniwindowImage: nil];
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

      newStyleMask = [object _styleMask];
      for (i=0;i<rows;i++) {
        if ([[control cellAtRow: i column: 0] state] == NSOnState)
          newStyleMask |= [[control cellAtRow: i column: 0] tag];
        else
          newStyleMask &= ~[[control cellAtRow: i column: 0] tag];
      }
 
      [object _setStyleMask: newStyleMask];
      // FIXME: This doesn't refresh the window decoration. How to do that?
      // (currently needs manual hide/unhide to update decorations)
      [object display];
   }
  else if (control == colorWell)
    {
      [object setBackgroundColor: [colorWell color]];
    }
  else if (control == optionMatrix)
    {
      BOOL flag;
      GormDocument *doc = (GormDocument*)[(id<IB>)NSApp activeDocument];
	
      // Release When Closed
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object _setReleasedWhenClosed: flag];

      // Hide on deactivate
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setHidesOnDeactivate: flag];

      // Visible at launch time. (not an object property. Stored in a Gorm dictionary)
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [doc setObject: object isVisibleAtLaunch: flag];

      // Deferred
      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;
      [doc setObject: object isDeferred: flag];

      // One shot
      flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
      [object setOneShot: flag];

      // Dynamic depth limit
      flag = ([[control cellAtRow: 5 column: 0] state] == NSOnState) ? YES : NO;
      [object setDynamicDepthLimit: flag];

      // wants to be color
      // FIXME:  probably means window depth > 2 bits per pixel but don't know
      // exactly what NSWindow method to use to enforce that.
      flag = ([[control cellAtRow: 6 column: 0] state] == NSOnState) ? YES : NO;
    }
}


- (void) _getValuesFromObject: anObject
{
  GormDocument *doc = (GormDocument*)[(id<IB>)NSApp activeDocument];
  if (anObject != object)
    return;

  [[titleForm cellAtIndex: 0] setStringValue: [anObject title] ];

  [backingMatrix selectCellWithTag: [anObject backingType] ];

 
  [controlMatrix deselectAllCells];
  if ([anObject _styleMask] & NSMiniaturizableWindowMask)
    [controlMatrix selectCellAtRow: 0 column: 0];
  if ([anObject _styleMask] & NSClosableWindowMask)
    [controlMatrix selectCellAtRow: 1 column: 0];
  if ([anObject _styleMask] & NSResizableWindowMask)
    [controlMatrix selectCellAtRow: 2 column: 0];

  [optionMatrix deselectAllCells];
  if ([anObject _isReleasedWhenClosed])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject hidesOnDeactivate])
    [optionMatrix selectCellAtRow: 1 column: 0];
  
  // visible at launch time.
  if ([doc objectIsVisibleAtLaunch: anObject])
    {
      [optionMatrix selectCellAtRow: 2 column: 0];
    }
  
  // defer comes here.
  if ([doc objectIsDeferred: anObject])
    {
      [optionMatrix selectCellAtRow: 3 column: 0];
    }

  if ([anObject isOneShot])
    [optionMatrix selectCellAtRow: 4 column: 0];

  if ([anObject hasDynamicDepthLimit])
    [optionMatrix selectCellAtRow: 5 column: 0];
  
  // FIXME: wants to be color comes here

  // icon name
  [[iconNameForm cellAtIndex: 0] setStringValue: [[object miniwindowImage] name]];

  // background color
  [colorWell setColorWithoutAction: [object backgroundColor]];
}

- (void) _validate: (id)anObject
{
  id cell = [controlMatrix cellAtRow: 0 column: 0];
  // Assumed to be the "miniaturize" cell.
  // panels should not be allowed to miniaturize the app.

  if([anObject isKindOfClass: [NSPanel class]])
    {
      [cell setEnabled: NO];
    }
  else
    {
      [cell setEnabled: YES];
    }
}

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormNSWindowInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormNSWindowInspector");
      return nil;
    }
  return self;
}

- (void) ok: (id)sender
{
  [super ok: sender];
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  // Need to do something here to disable certain portions of
  // the inspector if the object being edited is an NSPanel.
  [super setObject: anObject];
  //  [self _validate: anObject];
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

  if ([NSBundle loadNibNamed: @"GormNSWindowSizeInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormNSWindowSizeInspector");
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
  [super ok: sender];
  [self _setValuesFromControl: sizeForm];
  [self _setValuesFromControl: minForm];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end
