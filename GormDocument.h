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
 * placeholder for the current fornt manager.
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
  NSWindow		*window;
  NSMatrix		*selectionView;
  NSBox                 *selectionBox;
  NSScrollView		*scrollView;
  NSScrollView          *classesScrollView;
  id                    classesView;
  id			objectsView;
  BOOL			hasSetDefaults;
  BOOL			isActive;
  NSMenu		*savedMenu;
  NSMenuItem		*quitItem;		/* Replaced during test */
  NSMutableArray	*savedEditors;
  NSMutableArray	*hidden;
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
- (void) touch;		/* Mark document as having been changed.	*/
- (NSWindow*) window;
- (BOOL) windowShouldClose: (id)sender;

// classes support 
- (id) createSubclass: (id)sender;
- (id) instantiateClass: (id)sender;
- (id) editClass: (id)sender;
- (id) createClassFiles: (id)sender;
- (void) changeCurrentClass: (id)sender;
@end

#endif
