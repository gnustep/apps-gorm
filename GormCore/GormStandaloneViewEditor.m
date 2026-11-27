/* GormStandaloneViewEditor.m
 *
 * Copyright (C) 2009 Free Software Foundation, Inc.
 *
 * Author:	Gregory Casamento <greg.casamento@gmail.com>
 * Date:	2009
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <AppKit/AppKit.h>

#include <GormCore/GormPrivate.h>
#include <GormCore/GormStandaloneViewEditor.h>
#include <GormCore/GormDefines.h>
#include <GormCore/GormViewKnobs.h>
#include <GormCore/GormAbstractDelegate.h>


@class GormEditorToParent;

@implementation GormStandaloneViewEditor

- (NSImage*) imageForViewer
{
  static NSImage       *image = nil;
  GormAbstractDelegate *delegate = (GormAbstractDelegate *)[NSApp delegate];

  if (image == nil && [delegate isInTool] == NO)
    {
      NSBundle	*bundle = [NSBundle bundleForClass: [GormStandaloneViewEditor class]];
      NSString *path = [bundle pathForImageResource: @"GormView"]; 
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }

  return image;
}

- (BOOL) activate
{
  if ([super activate] == NO)
    return NO;

  /* Match a window content editor: wrap children before accepting input. */
  NSEnumerator *enumerator = [[NSArray arrayWithArray: [_editedObject subviews]]
                              objectEnumerator];
  NSView *view;
  while ((view = [enumerator nextObject]) != nil)
    {
      if (![view isKindOfClass: [GormViewEditor class]])
        [document editorForObject: view inEditor: self create: YES];
    }
  if (viewWindow != nil)
    [self setOpened: YES];
  return YES;
}

- (void) deactivate
{
  [self deactivateSubeditors];
  [super deactivate];
}

- (void) pasteInSelection
{
  [self pasteInView: _editedObject];
}

- (void) deleteSelection
{
  NSArray *selected = [NSArray arrayWithArray: selection];
  NSEnumerator *enumerator = [selected objectEnumerator];
  id editor;
  while ((editor = [enumerator nextObject]) != nil)
    [document detachObject: [editor editedObject]];
  [self selectObjects: [NSArray array]];
}

@end
