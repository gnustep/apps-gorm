/* IBInspector.m
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
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <InterfaceBuilder/IBApplicationAdditions.h>
#include <InterfaceBuilder/IBInspector.h>
#include <InterfaceBuilder/IBDocuments.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>
#include <AppKit/NSWindow.h>

static NSNotificationCenter *nc = nil;

@implementation	IBInspector

+ (void) initialize
{
  if(self == [IBInspector class])
    {
      nc = [NSNotificationCenter defaultCenter];
    }
}

- (id) init
{
  if((self = [super init]) != nil)
    {
      [nc addObserver: self
	  selector: @selector(_releaseObject:)
	  name: IBWillCloseDocumentNotification
	  object: nil];
    }

  return self;
}

- (void) dealloc
{
  [nc removeObserver: self];
  RELEASE(object);
  [super dealloc];
}

- (void) _releaseObject: (NSNotification *)notification
{
  id<IBDocuments> doc = [notification object];
  if([doc nameForObject: object] != nil)
    {
      [self setObject: nil];
    }
}

- (NSView*) initialFirstResponder
{
  return nil;
}

- (id) object
{
  return object;
}

- (void) ok: sender
{
  [self touch: sender];
}

- (NSButton*) okButton
{
  return okButton;
}

- (void) revert: (id)sender
{
  [window setDocumentEdited: NO];
}

- (NSButton*) revertButton
{
  return revertButton;
}

- (void) setObject: (id)anObject
{
  ASSIGN(object, anObject);
  [self revert: self];
}

- (void) textDidBeginEditing: (NSNotification*)aNotification
{
}

- (void) touch: (id)sender
{
  id<IBDocuments> doc = [(id<IB>)NSApp activeDocument];
  [doc touch];
}

- (BOOL) wantsButtons
{
  return NO;
}

- (NSWindow*) window
{
  return window;
}
@end
