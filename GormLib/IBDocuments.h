/* IBDocuments.h
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

#ifndef INCLUDED_IBDOCUMENTS_H
#define INCLUDED_IBDOCUMENTS_H

#include <Foundation/NSGeometry.h>
#include <InterfaceBuilder/IBEditors.h>
#include <InterfaceBuilder/IBConnectors.h>
#include <InterfaceBuilder/IBSystem.h>

IB_EXPORT NSString *IBDidOpenDocumentNotification;
IB_EXPORT NSString *IBWillSaveDocumentNotification;
IB_EXPORT NSString *IBDidSaveDocumentNotification;
IB_EXPORT NSString *IBWillCloseDocumentNotification;

@protocol IBDocuments <NSObject>
- (void) addConnector: (id<IBConnectors>)aConnector;
- (NSArray*) allConnectors;
- (void) attachObject: (id)anObject toParent: (id)aParent;
- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent;
- (NSArray*) connectorsForDestination: (id)destination;
- (NSArray*) connectorsForDestination: (id)destination
			      ofClass: (Class)aConnectorClass;
- (NSArray*) connectorsForSource: (id)source;
- (NSArray*) connectorsForSource: (id)source
			 ofClass: (Class)aConnectorClass;
- (BOOL) containsObject: (id)anObject;
- (BOOL) containsObjectWithName: (NSString*)aName forParent: (id)parent;
- (BOOL) copyObject: (id)anObject
	       type: (NSString*)aType
       toPasteboard: (NSPasteboard*)aPasteboard;
- (BOOL) copyObjects: (NSArray*)anArray
		type: (NSString*)aType
	toPasteboard: (NSPasteboard*)aPasteboard;
- (void) detachObject: (id)anObject;
- (void) detachObjects: (NSArray*)anArray;
- (NSString*) documentPath;
- (void) editor: (id<IBEditors>)anEditor didCloseForObject: (id)anObject;
- (id<IBEditors>) editorForObject: (id)anObject
			   create: (BOOL)flag;
- (id<IBEditors>) editorForObject: (id)anObject
			 inEditor: (id<IBEditors>)anEditor
			   create: (BOOL)flag;
- (NSString*) nameForObject: (id)anObject;
- (id) objectForName: (NSString*)aName;
- (NSArray*) objects;
- (id<IBEditors>) openEditorForObject: (id)anObject;
- (id<IBEditors, IBSelectionOwners>) parentEditorForEditor: (id<IBEditors>)anEditor;
- (id) parentOfObject: (id)anObject;
- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent;
- (void) removeConnector: (id<IBConnectors>)aConnector;
- (void) resignSelectionForEditor: (id<IBEditors>)editor;
- (void) setName: (NSString*)aName forObject: (id)object;
- (void) setSelectionFromEditor: (id<IBEditors>)anEditor;
- (void) touch;		/* Mark document as having been changed.	*/
@end

#endif
