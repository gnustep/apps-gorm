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

@interface GormWindowMaker : NSObject <NSCoding>
{
}
@end

@implementation	GormWindowMaker
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}
- (id) initWithCoder: (NSCoder*)aCoder
{
  id		w;
  unsigned	style = NSTitledWindowMask | NSClosableWindowMask
			| NSResizableWindowMask | NSMiniaturizableWindowMask;

  w = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 500, 300)
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



@interface GormWindowAttributesInspector : IBInspector
{
  NSTextField	*titleText;
  NSButton	*visibleAtLaunchTime;
}
@end

@implementation GormWindowAttributesInspector

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  [object setTitle: [titleText stringValue]];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSTextField	*title;
      NSBox		*box;

      window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, IVW, IVH)
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      title
	= [[NSTextField alloc] initWithFrame: NSMakeRect(10,IVH-30,70,20)];
      [title setEditable: NO];
      [title setSelectable: NO];
      [title setBezeled: NO];
      [title setAlignment: NSLeftTextAlignment];
      [title setFont: [NSFont systemFontOfSize: 14.0]];
      [title setDrawsBackground: NO];
      [title setStringValue: @"Title:"];
      [contents addSubview: title];
      RELEASE(title);

      titleText
	= [[NSTextField alloc] initWithFrame: NSMakeRect(60,IVH-30,IVW-80,20)];
      [titleText setDelegate: self];
      [contents addSubview: titleText];
      RELEASE(titleText);

      box = [[NSBox alloc] initWithFrame: NSMakeRect(10, 10, IVW-20, IVW)];
      [box setTitle: @"Options"];
      [box setBorderType: NSGrooveBorder];
      [contents addSubview: box];
      RELEASE(box);

      visibleAtLaunchTime
	= [[NSButton alloc] initWithFrame: NSMakeRect(10, 10, 180, 20)];
      [visibleAtLaunchTime setButtonType: NSSwitchButton];
      [visibleAtLaunchTime setBordered: NO];
      [visibleAtLaunchTime setImagePosition: NSImageRight];
      [visibleAtLaunchTime setTitle: @"Visible at launch time:"];
      [visibleAtLaunchTime setTarget: self];
      [visibleAtLaunchTime setAction: @selector(ok:)];
      [box addSubview: visibleAtLaunchTime];
      RELEASE(visibleAtLaunchTime);
    }
  return self;
}

- (void) ok: (id)sender
{
  GormDocument	*doc = (GormDocument*)[(id<IB>)NSApp activeDocument];

  if (sender == visibleAtLaunchTime)
    {
      if ([sender state] == NSOnState)
	{
	  [doc setObject: object isVisibleAtLaunch: YES];
	}
      else
	{
	  [doc setObject: object isVisibleAtLaunch: NO];
	}
    } 
}

- (void) setObject: (id)anObject
{
  GormDocument	*doc = (GormDocument*)[(id<IB>)NSApp activeDocument];

  [super setObject: anObject];

  if ([doc objectIsVisibleAtLaunch: object] == YES)
    {
      [visibleAtLaunchTime setState: NSOnState];
    }
  else
    {
      [visibleAtLaunchTime setState: NSOffState];
    }
  [titleText setStringValue: [object title]];
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

- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  [self _setValuesFromControl: notifier];
}

- (void) windowChangeNotification: (NSNotification*)aNotification
{
  id notifier = [aNotification object];
  
  [self _getValuesFromObject: notifier];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(window);
  [super dealloc];
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
  [[NSNotificationCenter defaultCenter] 
      addObserver: self
         selector: @selector(controlTextDidEndEditing:)
             name: NSControlTextDidEndEditingNotification
           object: nil];
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
