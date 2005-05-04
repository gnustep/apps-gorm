/* GormClassEditor.h
 *
 * Copyright (C) 1999, 2003, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2005
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

#ifndef INCLUDED_GormClassEditor_h
#define INCLUDED_GormClassEditor_h

#include <InterfaceBuilder/InterfaceBuilder.h>
#include <AppKit/NSBox.h>
#include <GormCore/GormOutlineView.h>

@class NSString, NSArray, GormDocument, GormClassManager;

extern NSString *GormClassPboardType;

@interface GormClassEditor : NSBox <IBEditors, IBSelectionOwners>
{
  GormDocument          *document;
  GormClassManager      *classManager;
  NSString              *selectedClass;
  NSScrollView          *scrollView;
  GormOutlineView       *outlineView;
  NSBrowser             *browserView;
}
- (GormClassEditor*) initWithDocument: (GormDocument*)doc;
+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc;
- (void) setSelectedClassName: (NSString*)cn;
- (NSString *) selectedClassName;
- (void) selectClassWithObject: (id)obj editClass: (BOOL)flag;
- (void) selectClassWithObject: (id)obj;
- (void) selectClass: (NSString *)className editClass: (BOOL)flag;
- (void) selectClass: (NSString *)className;
- (BOOL) currentSelectionIsClass;
- (void) editClass;
- (void) createSubclass;
- (void) addAttributeToClass;
- (void) deleteSelection;
- (NSArray *) fileTypes;

- (void) reloadData;
- (BOOL) isEditing;
@end

#endif
