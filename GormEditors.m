/* GormEditors.m
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


@implementation NSObject (IBEditorSpecification)
- (NSString*) editorClassName
{
  return @"GormObjectEditor";
}
@end


@interface GormObjectEditor : NSObject <IBEditors>
{
  id			object;
  id<IBDocuments>	document;
  NSMutableArray	*subeditors;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (id) editedObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (void) resetObject: (id)anObject;
- (void) selectObjects: (NSArray*)objects;
- (void) validateEditing;
- (BOOL) wantsSelection;
- (NSWindow*) window;
@end


@implementation GormObjectEditor

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  return NO;
}

- (BOOL) activate
{
  return NO;
}

- (void) dealloc
{
  RELEASE(subeditors);
  RELEASE(object);
  RELEASE(document);
  [super dealloc];
}

- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  self = [super init];
  if (self)
    {
      object = RETAIN(anObject);
      document = RETAIN(aDocument);
      subeditors = [NSMutableArray new];
    }
  return self;
}

- (void) close
{
  [self closeSubeditors];
}

- (void) closeSubeditors
{
  unsigned	i = [subeditors count];

  while (i-- > 0)
    {
      [[subeditors objectAtIndex: i] close];
      [subeditors removeObjectAtIndex: i];
    }
}

- (void) copySelection
{
}

- (void) deleteSelection
{
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) editedObject
{
  return object;
}

- (void) makeSelectionVisible: (BOOL)flag
{
}

@end
