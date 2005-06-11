/* GormDocument.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef INCLUDED_GormDocument_h
#define INCLUDED_GormDocument_h

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <GNUstepGUI/GSNibTemplates.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@class GormClassManager, GormClassEditor, GormObjectProxy, GormFilesOwner;

/*
 * Each document has a GormFirstResponder object that is used as a placeholder
 * for the first responder at any instant.
 */
@interface GormFirstResponder : NSObject
{
}
@end

@interface GormDocument : GSNibContainer <IBDocuments>
{
  GormClassManager      *classManager;
  GormFilesOwner	*filesOwner;
  GormFirstResponder	*firstResponder;
  GormObjectProxy       *fontManager;
  NSString		*documentPath;
  NSMapTable		*objToName;
  NSWindow		*window;
  NSBox                 *selectionBox;
  NSScrollView		*scrollView;
  NSScrollView          *classesScrollView;
  NSScrollView          *soundsScrollView;
  NSScrollView          *imagesScrollView;
  id                    classesView;
  id			objectsView;
  id			soundsView;
  id			imagesView;
  BOOL			hasSetDefaults;
  BOOL			isActive;
  BOOL                  isDocumentOpen;
  NSMenu		*savedMenu;
  NSMenuItem		*quitItem;		/* Replaced during test-mode */
  NSMutableArray	*savedEditors;
  NSMutableArray	*hidden;
  NSMutableArray        *openEditors;
  NSToolbar             *toolbar;
  id                    lastEditor;
  BOOL                  isOlderArchive;
  id                    filePrefsView;
  id                    filePrefsManager;
  NSWindow              *filePrefsWindow;
  NSMutableArray        *resourceManagers;
}

/* Archiving objects */
- (void) beginArchiving;
- (void) endArchiving;

/* Handle notifications */
- (void) handleNotification: (NSNotification*)aNotification;

/* Document management */
- (BOOL) isActive;
- (BOOL) objectIsVisibleAtLaunch: (id)anObject;
- (BOOL) objectIsDeferred: (id)anObject;
- (id) loadDocument: (NSString*)path;
- (id) openDocument: (id)sender;
- (id) revertDocument: (id)sender;
- (BOOL) saveAsDocument: (id)sender;
- (BOOL) saveGormDocument: (id)sender;
- (void) setupDefaults: (NSString*)type;
- (void) setDocumentActive: (BOOL)flag;
- (void) setObject: (id)anObject isVisibleAtLaunch: (BOOL)flag;
- (void) setObject: (id)anObject isDeferred: (BOOL)flag;
- (NSWindow*) window;
- (BOOL) couldCloseDocument;
- (BOOL) windowShouldClose: (id)sender;
- (BOOL) isTopLevelObject: (id)obj;
- (void) closeAllEditors;
- (void) createResourceManagers;
- (NSArray *) resourceManagers;
- (IBResourceManager *) resourceManagerForPasteboard: (NSPasteboard *)pboard;
- (void) changeToTopLevelEditorAcceptingTypes: (NSArray *)types 
                                  andFileType: (NSString *)fileType;
- (void) changeToViewWithTag: (int)tag;
- (NSArray *) allManagedPboardTypes;

/* Language translation */
- (void) translate;
- (void) exportStrings;

/* Managing classes */
- (GormClassManager*) classManager;
- (id) createSubclass: (id)sender;
- (id) instantiateClass: (id)sender;
- (id) createClassFiles: (id)sender;
- (id) addAttributeToClass: (id)sender;
- (id) remove: (id)sender;
- (id) createClassFiles: (id)sender;
- (id) instantiateClass: (id)sender;
- (void) selectClass: (NSString *)className;
- (void) selectClass: (NSString *)className editClass: (BOOL)flag;
- (BOOL) classIsSelected;
- (void) removeAllInstancesOfClass: (NSString *)classNamed;

/* Sound & Image support */
- (id) openSound: (id)sender;
- (id) openImage: (id)sender;

/* Connections */
- (void) rebuildObjToNameMapping;
- (BOOL) removeConnectionsWithLabel: (NSString *)name
                      forClassNamed: (NSString *)className
                           isAction: (BOOL)action;
- (BOOL) removeConnectionsForClassNamed: (NSString *)name;
- (BOOL) renameConnectionsForClassNamed: (NSString *)name 
                                 toName: (NSString *)newName;

/* class loading */
- (id) loadClass: (id)sender;

/* services/windows menus... */
- (void) setServicesMenu: (NSMenu *)menu;
- (NSMenu *) servicesMenu;
- (void) setWindowsMenu: (NSMenu *)menu;
- (NSMenu *) windowsMenu;

/* first responder/font manager */
- (id) fontManager;
- (id) firstResponder;

/* 
 * windowAndRect:forObject: is called by Gorm to determine where it should
 * draw selection markup
 */
- (NSWindow*) windowAndRect: (NSRect*)r forObject: (id)object;
@end

@interface GormDocument (MenuValidation)
- (BOOL) isEditingObjects;
- (BOOL) isEditingImages;
- (BOOL) isEditingSounds;
- (BOOL) isEditingClasses;
@end

#endif
