#ifndef GORM_H
#define GORM_H

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>

/*
 * Positions of handles for resizing items.
 */
enum IBKnowPosition {
  IBBottomLeftKnobPosition,
  IBMiddleLeftKnobPosition,
  IBTopLeftKnobPosition,
  IBTopMiddleKnobPosition,
  IBTopRightKnobPosition,
  IBMiddleRightKnobPosition,
  IBBottomRightKnobPosition,
  IBBottomMiddleKnobPosition
};

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
extern NSString *IBWillBeginTestingInterfaceNotification;
extern NSString *IBDidBeginTestingInterfaceNotification;
extern NSString *IBWillEndTestingInterfaceNotification;
extern NSString *IBDidEndTestingInterfaceNotification;





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
- (BOOL) documentShouldClose;
- (void) documentWillClose;
- (NSString*) nameForObject: (id)anObject;
- (NSArray*) objects;
- (id) parentOfObject: (id)anObject;
- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent;
- (void) removeConnector: (id<IBConnectors>)aConnector;
- (void) setName: (NSString*)aName forObject: (id)object;
- (void) touch;		/* Mark document as having been changed.	*/
@end

@protocol IBSelectionOwners <NSObject>
- (unsigned) selectionCount;
- (NSArray*) selection;
- (void) drawSelection;
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
@interface NSObject (IBInspectorClassNames)
- (NSString*) inspectorClassName;
- (NSString*) connectInspectorClassName;
- (NSString*) sizeInspectorClassName;
- (NSString*) helpInspectorClassName;
- (NSString*) classInspectorClassName;
@end

@interface IBInspector : NSObject
{
  id		object;
  NSWindow	*window;
  NSButton	*okButton;
  NSButton	*revertButton;
}
- (id) object;
- (void) ok: (id)sender;
- (NSButton*) okButton;
- (void) revert: (id)sender;
- (NSButton*) revertButton;
- (void) touch: (id)sender;
- (BOOL) wantsButtons;
- (NSWindow*) window;
@end

@interface NSObject (IBEditorSpecification)
- (NSString*) editorClassName;
@end

@protocol IBEditors <IBSelectionOwners>
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

#endif
