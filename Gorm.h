/* Gorm.h
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

#ifndef GORM_H
#define GORM_H

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>

/*
 * Positions of handles for resizing items.
 */
typedef enum {
  IBBottomLeftKnobPosition = 0,
  IBMiddleLeftKnobPosition = 1,
  IBTopLeftKnobPosition = 2,
  IBTopMiddleKnobPosition = 3,
  IBTopRightKnobPosition = 4,
  IBMiddleRightKnobPosition = 5,
  IBBottomRightKnobPosition = 6,
  IBBottomMiddleKnobPosition = 7,
  IBNoneKnobPosition = -1
} IBKnobPosition;

/*
 * Pasteboard types used for DnD when views are dragged out of a palette
 * window into another window in Gorm (or, in the case of IBWindowPboardType
 * onto the desktop).
 */
extern NSString	*IBCellPboardType;
extern NSString	*IBMenuPboardType;
extern NSString	*IBMenuCellPboardType;
extern NSString	*IBObjectPboardType;
extern NSString	*IBViewPboardType;
extern NSString	*IBWindowPboardType;

/*
 * Notification for editing and inspecting the objects etc.
 */
extern NSString *IBAttributesChangedNotification;
extern NSString *IBInspectorDidModifyObjectNotification;
extern NSString *IBSelectionChangedNotification;
extern NSString *IBDidOpenDocumentNotification;
extern NSString *IBWillSaveDocumentNotification;
extern NSString *IBDidSaveDocumentNotification;
extern NSString *IBWillCloseDocumentNotification;
extern NSString *IBWillBeginTestingInterfaceNotification;
extern NSString *IBDidBeginTestingInterfaceNotification;
extern NSString *IBWillEndTestingInterfaceNotification;
extern NSString *IBDidEndTestingInterfaceNotification;
extern NSString *IBClassNameChangedNotification;



/*
 * Connector objects are used to record connections between nib objects.
 */
@protocol IBConnectors <NSObject>
- (id) destination;
- (void) establishConnection;
- (NSString*) label;
- (void) replaceObject: (id)anObject withObject: (id)anotherObject;
- (id) source;
- (void) setDestination: (id)anObject;
- (void) setLabel: (NSString*)label;
- (void) setSource: (id)anObject;
@end

@interface NSApplication (IBConnections)
/*
 * [NSApp -connectSource] returns the source object as set by the most recent
 * [NSApp -displayConnectionBetween:and:]
 */
- (id) connectSource;

/*
 * [NSApp -connectDestination] returns the target object as set by the most
 * recent [NSApp -displayConnectionBetween:and:]
 */
- (id) connectDestination;

/*
 * [NSApp -isConnecting] simply lets you know if a connection is in progress.
 */
- (BOOL) isConnecting;

/*
 * [NSApp -stopConnecting] terminates the current connection process and
 * removes the connection marks from the display.
 */
- (void) stopConnecting;

/*
 * [NSApp -displayConnectionBetween:and:] is used to set the source and target
 * objects and mark the display appropriately.  Setting either source or
 * target to 'nil' will remove markup from any previous source or target.
 * NB. This method expects to be able to call the active document to ask it
 * for the window and rectangle in which to perform markup.
 */
- (void) displayConnectionBetween: (id)source and: (id)destination;
@end

/*
 * The [-editorClassName] method is used to return the name of the editor
 * class for the object.  Documents use this method to create editors for
 * objects, it shouldn't be used elsewhere.
 * If you are writing a custom editor for a particular class of object, you
 * need to override this method for objects of that class.
 */
@interface NSObject (IBEditorSpecification)
- (NSString*) editorClassName;
@end

/*
 * The IBSelectionOwners protocol defines the methods that a selection owner
 * must implement.
 */
@protocol IBSelectionOwners <NSObject>
- (unsigned) selectionCount;
- (NSArray*) selection;
- (void) drawSelection;
@end

/*
 * The IBEditors protocol defines API for object editors.  This is probably the
 * area in which Gorm differs most from InterfaceBuilder, as I have no clear
 * idea of how InterfaceBuilder editors are meant to operate.
 */
@protocol IBEditors <IBSelectionOwners>
/*
 * Decide whether an editor can accept data from the pasteboard.
 */
- (BOOL) acceptsTypeFromArray: (NSArray*)types;

/*
 * Activate an editor - inserts it into the view hierarchy or whatever is
 * needed for the editor to be able to provide its functionality.
 * This method should be called by the document when an editor is created
 * or opened.  It should be safe to call repeatedly.
 */
- (BOOL) activate;

- (id) initWithObject: (id)anObject inDocument: (id/*<IBDocuments>*/)aDocument;

/*
 * Close an editor - this destroys the editor.  In this method the editor
 * should tell its document that it has been closed, so that the document
 * can remove all its references to the editor.
 */
- (void) close;

/*
 * Close subeditors of this editor.
 */
- (void) closeSubeditors;

/*
 * This method places the current selection from the editor on the pasteboard.
 */
- (void) copySelection;

/*
 * Deactivate an editor - removes it from the view hierarchy so that objects
 * can be archived without including the editor.
 * This method should be called automatically by the 'close' method.
 * It should be safe to call repeatedly.
 */
- (void) deactivate;

/*
 * This method deletes all the objects in the current selection in the editor.
 */
- (void) deleteSelection;

/*
 * This method returns the document that owns the object that the editor edits.
 */
- (id /*<IBDocuments>*/) document;

/*
 * This method returns the object that the editor is editing.
 */
- (id) editedObject;

/*
 * This method is used to draw or remove markup that identifies selected
 * objects within the object being edited.
 */
- (void) makeSelectionVisible: (BOOL)flag;

/*
 * This method is used to open an editor for an object within the object
 * currently being edited.
 */
- (id<IBEditors>) openSubeditorForObject: (id)anObject;

/*
 * This method is used to ensure that the editor is visible on screen.
 */
- (void) orderFront;

/*
 * This method is used to add the contents of the pasteboard to the current
 * selection of objects within the editor.
 */
- (void) pasteInSelection;

/*
 * FIXME - I don't think we use this.
 */
- (void) resetObject: (id)anObject;

/*
 * This method changes the current selection to those objects in the array.
 */
- (void) selectObjects: (NSArray*)objects;

/*
 * FIXME - I don't think we use this.
 */
- (void) validateEditing;

/*
 * When an editor resigns the selection ownership, all editors are asked if
 * they want selection ownership, and the first one to return YES gets made
 * into the current selection owner.
 */
- (BOOL) wantsSelection;

/*
 * This returns the window in which the editor is drawn.
 */
- (NSWindow*) window;
@end

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
- (id<IBEditors>) parentEditorForEditor: (id<IBEditors>)anEditor;
- (id) parentOfObject: (id)anObject;
- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent;
- (void) removeConnector: (id<IBConnectors>)aConnector;
- (void) resignSelectionForEditor: (id<IBEditors>)editor;
- (void) setName: (NSString*)aName forObject: (id)object;
- (void) setSelectionFromEditor: (id<IBEditors>)anEditor;
- (void) touch;		/* Mark document as having been changed.	*/

/*
 * windowAndRect:forObject: is called by Gorm to determine where it should
 * draw selection markup
 */
- (NSWindow*) windowAndRect: (NSRect*)r forObject: (id)object;
@end

@protocol IB <NSObject>
- (id<IBDocuments>) activeDocument;
- (BOOL) isTestingInterface;
- (id<IBSelectionOwners>) selectionOwner;
- (id) selectedObject;
@end

@interface IBPalette : NSObject
{
  NSWindow	*window;
  NSImage	*icon;
}
/*
 * For internal use only - these class methods return the information
 * associated with a particular view.
 */
+ (id) objectForView: (NSView*)aView;
+ (NSString*) typeForView: (NSView*)aView;

/*
 * Associate a particular object and DnD type with a view - so that
 * Gorm knows to initiate a DnD session with the specified object
 * and type rather than an archived copy of the view itsself and
 * the default type (IBViewPboardType).
 */
- (void) associateObject: (id)anObject
		    type: (NSString*)aType
		    with: (NSView*)aView;

/*
 * Method called by Gorm when a new palette has been created and its nib
 * (if any) has been loaded.  Any palette initialisation should be done here.
 */
- (void) finishInstantiate;

/*
 * Return the icon representing the palette.
 */
- (NSImage*) paletteIcon;

/*
 * Return the window containing the views that may be dragged from the
 * palette.
 */
- (NSWindow*) originalWindow;
@end

/*
 * How to get the inspector for a particular object.
 */
@interface NSObject (GormObjectAdditions)
- (NSString*) inspectorClassName;
- (NSString*) connectInspectorClassName;
- (NSString*) sizeInspectorClassName;
- (NSString*) helpInspectorClassName;
- (NSString*) classInspectorClassName;
- (NSString*) editorClassName;
@end


#define	IVH	388	/* Standard height of inspector view.	*/
#define	IVW	272	/* Standard width of inspector view.	*/
#define	IVB	40	/* Standard height of buttons area.	*/

@interface IBInspector : NSObject
{
  id		object;
  NSWindow	*window;
  NSButton	*okButton;
  NSButton	*revertButton;
}

- (NSView*) initialFirstResponder;

/*
 * The object being inspected.
 */
- (id) object;

/*
 * Action to take when user clicks the OK button
 */
- (void) ok: (id)sender;

/*
 * Inspector supplied button - the inspectors manager will position this
 * button for you.
 */
- (NSButton*) okButton;

/*
 * Action to take when user clicks the revert button
 */
- (void) revert: (id)sender;

/*
 * Inspector supplied button - the inspectors manager will position this
 * button for you.
 */
- (NSButton*) revertButton;

/*
 * Extension - not in NeXTstep - this message is sent to your inspector to
 * tell it to set its edited object and make any changes to its UI needed.
 */
- (void) setObject: (id)anObject;

/*
 * Used to take notice of textfields in inspector being updated.
 */
- (void) textDidBeginEditing: (NSNotification*)aNotification;

/*
 * Method to mark the inspector as needing saving (ok or revert).
 */
- (void) touch: (id)sender;

/*
 * If this method returns YES, the manager will partition off a section of
 * the inspector panel for display of 'ok' and 'revert' buttons, which
 * your inspector must supply.
 */
- (BOOL) wantsButtons;

/*
 * The window that the UI of the inspector exists in.
 */
- (NSWindow*) window;
@end

@interface NSView (ViewAdditions)
- (BOOL) acceptsColor: (NSColor*)color atPoint: (NSPoint)point;
- (BOOL) allowsAltDragging;
- (void) depositColor: (NSColor*)color atPoint: (NSPoint)point;
- (NSSize) maximumSizeFromKnobPosition: (IBKnobPosition)knobPosition;
- (NSSize) minimumSizeFromKnobPosition: (IBKnobPosition)position;
- (void) placeView: (NSRect)newFrame;
@end

#endif
