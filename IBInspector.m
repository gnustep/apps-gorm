/* IBInspector.m
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


NSString *IBInspectorDidModifyObjectNotification
  = @"IBInspectorDidModifyObjectNotification";
NSString *IBSelectionChangedNotification
  = @"IBSelectionChangedNotification";

@implementation	IBInspector

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(object);
  RELEASE(okButton);
  RELEASE(revertButton);
  RELEASE(window);
  [super dealloc];
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
}

- (NSButton*) okButton
{
  return okButton;
}

- (void) revert: (id)sender
{
}

- (NSButton*) revertButton
{
  return revertButton;
}

- (void) setObject: (id)anObject
{
  ASSIGN(object, anObject);
}

- (void) textDidBeginEditing: (NSNotification*)aNotification
{
}

- (void) touch: (id)sender
{
  [window setDocumentEdited: YES];
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

