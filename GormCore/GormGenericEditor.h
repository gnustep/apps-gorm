/* GormGenericEditor.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2004
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

#ifndef INCLUDED_GormGenericEditor_h
#define INCLUDED_GormGenericEditor_h

#include <InterfaceBuilder/InterfaceBuilder.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface	GormGenericEditor : NSMatrix <IBEditors, IBSelectionOwners>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPasteboard		*dragPb;
  NSString		*dragType;
  BOOL                  closed;
  BOOL                  activated;
  IBResourceManager     *resourceManager;
}

// class methods...
+ (id) editorForDocument: (id<IBDocuments>)aDocument;
+ (void) setEditor: (id)editor
       forDocument: (id<IBDocuments>)aDocument; 

// selection methods...
- (void) selectObjects: (NSArray*)objects;
- (BOOL) wantsSelection;
- (void) copySelection;
- (void) deleteSelection;
- (void) pasteInSelection;
- (void) refreshCells;
- (void) closeSubeditors;

- (NSWindow*) window;
- (void) addObject: (id)anObject;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id)aDocument;
- (void) close;
- (void) closeSubeditors;
- (BOOL) containsObject: (id)anObject;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (id) editedObject;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (NSRect) rectForObject: (id)anObject;

- (NSArray *) objects;
- (BOOL) isOpened;
- (NSArray *) fileTypes;
@end

// private methods...
@interface GormGenericEditor (PrivateMethods)
- (void) groupSelectionInScrollView;
- (void) groupSelectionInSplitView;
- (void) groupSelectionInBox;
- (void) ungroup;
- (void) setEditor: (id)anEditor forDocument: (id<IBDocuments>)doc;
- (id) changeSelection: (id)sender;
@end

#endif
