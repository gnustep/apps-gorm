/* GormImageEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2002
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
#include "GormFunctions.h"
#include "GormPalettesManager.h"
#include <AppKit/NSImage.h>
#include "GormImage.h"

@implementation	GormImageEditor

static NSMapTable *docMap = 0;

+ (void) initialize
{
  if (self == [GormImageEditor class])
    {
      docMap = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,
				NSObjectMapValueCallBacks, 2);
    }
}

+ (GormImageEditor*) editorForDocument: (id<IBDocuments>)aDocument
{
  id	editor = NSMapGet(docMap, (void*)aDocument);

  if (editor == nil)
    {
      editor = [[self alloc] initWithObject: nil inDocument: aDocument];
      AUTORELEASE(editor);
    }
  return editor;
}

- (NSArray *) fileTypes
{
  return [NSImage imageFileTypes];
}

- (NSArray *)pbTypes
{
  return [NSArray arrayWithObject: GormImagePboardType]; 
}

- (NSString *) resourceType
{
  return @"image";
}

- (id) placeHolderWithPath: (NSString *)string
{
  return [GormImage imageForPath: string];
}

- (void) addSystemResources
{
  NSMutableArray    *list = [NSMutableArray array];
  NSEnumerator      *en;
  id                obj;
  GormPalettesManager *palettesManager = [(Gorm *)NSApp palettesManager];
     
  // add all of the system objects...
  [list addObjectsFromArray: systemImagesList()];
  [list addObjectsFromArray: [palettesManager importedImages]];
  en = [list objectEnumerator];
  while((obj = [en nextObject]) != nil)
    {
      GormImage *image = [GormImage imageForPath: obj];
      [image setSystemResource: YES];
      [self addObject: image];
    }  
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument
{
  id	old = NSMapGet(docMap, (void*)aDocument);

  if (old != nil)
    {
      RELEASE(self);
      self = RETAIN(old);
      [self addObject: anObject];
      return self;
    }

  if ((self = [super initWithObject: anObject inDocument: aDocument]) != nil)
    {
      NSMapInsert(docMap, (void*)aDocument, (void*)self);
    }

  return self;
}

- (void) dealloc
{
  if(closed == NO)
    [self close];

  // TODO: This is a band-aid fix until I find the actual problem. 
  // This *WILL* leak, but I don't want it crashing on people.
  
  RELEASE(objects);
  NSDebugLog(@"Released...");
}

- (void) close
{
  [super close];
  NSMapRemove(docMap,document);
}
@end
