#ifndef GORMDOCUMENT_H
#define GORMDOCUMENT_H

@class GormClassManager, GormClassEditor;

/*
 * Each document has a GormFirstResponder object that is used as a placeholder
 * for the first responder at any instant.
 */
@interface	GormFirstResponder : NSObject
{
}
@end

/*
 * Each document may have a GormFontManager object that is used as a
 * placeholder for the current font manager.
 */
@interface	GormFontManager : NSObject
{
}
@end

@interface GormDocument : GSNibContainer <IBDocuments>
{
  GormClassManager      *classManager;
  GormFilesOwner	*filesOwner;
  GormFirstResponder	*firstResponder;
  GormFontManager	*fontManager;
  GormClassEditor       *classEditor; // perhaps should not be here...
  NSString		*documentPath;
  NSMapTable		*objToName;
  NSMutableDictionary   *tempNameTable;
  NSWindow		*window;
  NSMatrix		*selectionView;
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
  NSMenu		*savedMenu;
  NSMenuItem		*quitItem;		/* Replaced during test */
  NSMutableArray	*savedEditors;
  NSMutableArray	*hidden;
  NSMutableSet          *sounds;
  NSMutableSet          *images;
  // NSFileWrapper         *wrapper;
}
- (void) addConnector: (id<IBConnectors>)aConnector;
- (NSArray*) allConnectors;
- (void) attachObject: (id)anObject toParent: (id)aParent;
- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent;
- (void) beginArchiving;
- (GormClassManager*) classManager;
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
- (void) endArchiving;
- (void) handleNotification: (NSNotification*)aNotification;
- (BOOL) isActive;
- (NSString*) nameForObject: (id)anObject;
- (id) objectForName: (NSString*)aString;
- (BOOL) objectIsVisibleAtLaunch: (id)anObject;
- (BOOL) objectIsDeferred: (id)anObject;
- (NSArray*) objects;
- (id) loadDocument: (NSString*)path;
- (id) openDocument: (id)sender;
- (id) parentOfObject: (id)anObject;
- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent;
- (void) removeConnector: (id<IBConnectors>)aConnector;
- (id) revertDocument: (id)sender;
- (id) saveAsDocument: (id)sender;
- (id) saveDocument: (id)sender;
- (void) setupDefaults: (NSString*)type;
- (void) setDocumentActive: (BOOL)flag;
- (void) setName: (NSString*)aName forObject: (id)object;
- (void) setObject: (id)anObject isVisibleAtLaunch: (BOOL)flag;
- (void) setObject: (id)anObject isDeferred: (BOOL)flag;
- (void) touch;		/* Mark document as having been changed.	*/
- (NSWindow*) window;
- (BOOL) windowShouldClose: (id)sender;

// classes support..
- (id) createSubclass: (id)sender;
- (id) instantiateClass: (id)sender;
- (id) editClass: (id)sender;
- (id) createClassFiles: (id)sender;
- (void) changeCurrentClass: (id)sender;

// sound & image support
- (id) openSound: (id)sender;
- (id) openImage: (id)sender;

// Internals support
- (void) rebuildObjToNameMapping;
- (id) parseHeader: (NSString *)headerPath;
- (BOOL) removeConnectionsWithLabel: (NSString *)name
                      forClassNamed: (NSString *)className
                           isAction: (BOOL)action;
- (BOOL) removeConnectionsForClassNamed: (NSString *)name;
- (BOOL) renameConnectionsForClassNamed: (NSString *)name 
                                 toName: (NSString *)newName;
@end

@interface GormDocument (MenuValidation)
- (BOOL) isEditingObjects;
- (BOOL) isEditingImages;
- (BOOL) isEditingSounds;
- (BOOL) isEditingClasses;
@end

#endif
