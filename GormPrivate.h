#ifndef GORMPRIVATE_H
#define GORMPRIVATE_H

@class	GormDocument;
@class	GormInspectorsManager;
@class	GormPalettesManager;

#include "Gorm.h"
#include "GormFilesOwner.h"
#include "GormDocument.h"
#include "GormInspectorsManager.h"
#include "GormClassManager.h"
#include "GormPalettesManager.h"

extern NSString *GormLinkPboardType;

// templates
@interface GSNibItem (GormAdditions)
- initWithClassName: (NSString*)className frame: (NSRect)frame;
- (NSString*) className;
@end

@interface GormObjectProxy : GSNibItem 
/*
 * Use a GormObjectProxy in Gorm, but encode a GSNibItem in the archive.
 * This is done so that we can provide our own decoding method
 * (GSNibItem tries to morph into the actual class)
 */
- (void) setClassName: (NSString *)className;
@end

// Additions to template classes within gorm.
@protocol GormTemplate
- (id) initWithObject: (id)object className: (NSString *)name;
@end

@interface NSWindowTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSViewTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSTextTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSControlTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSButtonTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSTextViewTemplate (GormCustomClassAdditions) <GormTemplate>
@end

@interface NSMenuTemplate (GormCustomClassAdditions) <GormTemplate>
@end

// gorm template subclasses
@interface GormNSWindowTemplate : NSWindowTemplate
@end

@interface GormNSViewTemplate : NSViewTemplate
@end

@interface GormNSTextTemplate : NSTextTemplate
@end

@interface GormNSControlTemplate : NSControlTemplate
@end

@interface GormNSButtonTemplate : NSButtonTemplate
@end

@interface GormNSTextViewTemplate : NSTextViewTemplate
@end

@interface GormNSMenuTemplate : NSMenuTemplate
@end

// custom class support
@interface NSObject (GormCustomClassAdditions)
+ (BOOL) canSubstituteForClass: (Class)aClass;
@end

@interface GormClassProxy : NSObject
{
  NSString *name;
  int t;
}

- initWithClassName: (NSString*)n;
- (NSString*) className;
- (NSString*) inspectorClassName;
- (NSString*) connectInspectorClassName;
- (NSString*) sizeInspectorClassName;
@end

@interface NSApplication (Gorm)
- (GormClassManager*) classManager;
- (NSImage*) linkImage;
- (void) startConnecting;
@end

@interface Gorm : NSApplication <IB>
{
  id			infoPanel;
  id                    preferencesPanel;
  GormClassManager	*classManager;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  id			selectionOwner;
  NSMutableArray	*documents;
  BOOL			isConnecting;
  BOOL			isTesting;
  id			testContainer;
  NSMenu		*mainMenu;
  NSMenu                *classMenu; // so we can set it for the class view
  NSDictionary		*menuLocations;
  NSImage		*linkImage;
  NSImage		*sourceImage;
  NSImage		*targetImage;
  id			connectSource;
  NSWindow		*connectSWindow;
  NSRect		connectSRect;
  id			connectDestination;
  NSWindow		*connectDWindow;
  NSRect		connectDRect;
}
- (id<IBDocuments>) activeDocument;
- (id) connectSource;
- (id) connectDestination;
- (void) displayConnectionBetween: (id)source and: (id)destination;
- (void) handleNotification: (NSNotification*)aNotification;
- (GormInspectorsManager*) inspectorsManager;
- (BOOL) isConnecting;
- (GormPalettesManager*) palettesManager;
- (void) stopConnecting;

- (id) copy: (id)sender;
- (id) cut: (id)sender;
- (id) delete: (id)sender;
- (id) endTesting: (id)sender;
- (id) infoPanel: (id) sender;
- (id) preferencesPanel: (id) sender;
- (id) inspector: (id) sender;
- (id) newApplication: (id) sender;
- (id) loadPalette: (id) sender;
- (void) loadSound: (id) sender;
- (id) open: (id)sender;
- (id) palettes: (id) sender;
- (id) paste: (id)sender;
- (id) revertToSaved: (id)sender;
- (id) save: (id)sender;
- (id) saveAll: (id)sender;
- (id) saveAs: (id)sender;
- (id) selectAllItems: (id)sender;
- (id) setName: (id)sender;
- (id) testInterface: (id)sender;

// added for classes support
- (id) createSubclass: (id)sender;
- (id) instantiateClass: (id)sender;
- (id) editClass: (id)sender;
- (NSMenu*) classMenu;
@end

@interface GormClassEditor : NSObject <IBSelectionOwners>
{
  GormDocument          *document;
  NSString              *selectedClassName;
}
- (GormClassEditor*) initWithDocument: (GormDocument*)doc;
+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc;
- (void) setSelectedClassName: (NSString*)cn;
@end

@interface	GormGenericEditor : NSMatrix <IBEditors, IBSelectionOwners>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
@end

@interface	GormObjectEditor : GormGenericEditor <IBEditors, IBSelectionOwners>
{
//    NSMutableArray	*objects;
//    id<IBDocuments>	document;
//    id			selected;
//    NSPasteboard		*dragPb;
//    NSString		*dragType;
}
// + (GormObjectEditor*) editorForDocument: (id<IBDocuments>)aDocument;
- (void) addObject: (id)anObject;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) close;
- (void) closeSubeditors;
- (BOOL) containsObject: (id)anObject;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (id) editedObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (NSRect) rectForObject: (id)anObject;
- (void) resetObject: (id)anObject;
- (void) selectObjects: (NSArray*)objects;
- (BOOL) wantsSelection;
- (NSWindow*) window;
@end

@interface	GormSoundEditor : GormGenericEditor <IBEditors, IBSelectionOwners>
{
//    NSMutableArray        *objects;
//    id<IBDocuments>       document;
//    id			selected;
//    NSPasteboard		*dragPb;
//    NSString		*dragType;
}
// don't redeclare methods already declared in protocols.
+ (GormSoundEditor*) editorForDocument: (id<IBDocuments>)aDocument;
- (void) addObject: (id)anObject;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
- (void) closeSubeditors;
- (BOOL) containsObject: (id)anObject;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) pasteInSelection;
- (NSRect) rectForObject: (id)anObject;
@end

@interface	GormImageEditor : GormGenericEditor <IBEditors, IBSelectionOwners>
{
}
// don't redeclare methods already declared in protocols.
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (void) copySelection;
- (void) deleteSelection;
- (void) pasteInSelection;
@end


@interface GormFilesOwnerInspector : IBInspector
{
  NSBrowser	*browser;
  NSArray	*classes;
  BOOL		hasConnections;
}
- (void) takeClassFrom: (id)sender;
@end

/*
 * NSDateFormatter and NSNumberFormatter extensions
 * for Gorm Formatters used in the Data Palette
 */

@interface NSDateFormatter (GormAdditions)

+ (void) initialize;
+ (int) formatCount;
+ (NSString *) formatAtIndex: (int)index;
+ (int) indexOfFormat: (NSString *) format;
+ (NSString *) defaultFormat;
+ (id) defaultFormatValue;

@end

@interface NSNumberFormatter (GormAdditions)

+ (void) initialize;
+ (int) formatCount;
+ (NSString *) formatAtIndex: (int)index;
+ (NSString *) positiveFormatAtIndex: (int)index;
+ (NSString *) zeroFormatAtIndex: (int)index;
+ (NSString *) negativeFormatAtIndex: (int)index;
+ (NSDecimalNumber *) positiveValueAtIndex: (int)index;
+ (NSDecimalNumber *) negativeValueAtIndex: (int)index;
+ (int) indexOfFormat: format;
+ (NSString *) defaultFormat;
+ (id) defaultFormatValue;
- (NSString *) zeroFormat;

@end

@interface NSObject (GormAdditions)
- (id) allocSubstitute;
@end

// we don't use the actual sound since we don't want to read the entire sound into
// memory.
@interface GormSound : NSObject
{
  NSString *name;
  NSString *path;
  BOOL     isSystemSound;
  BOOL     isInWrapper; 
}
- (id) initWithName: (NSString *)aName
               path: (NSString *)aPath;
- (void) setSoundName: (NSString *)aName;
- (NSString *) soundName;
- (void) setSoundPath: (NSString *)aPath;
- (NSString *) soundPath;
- (void) setSystemSound: (BOOL)flag;
- (BOOL) isSystemSound;
- (void) setInWrapper: (BOOL)flag;
- (BOOL) isInWrapper;
- (NSString *)inspectorClassName;
@end

@interface GormImage : NSObject
{
  NSString *name;
  NSString *path;
  NSImage  *image;
  NSImage  *smallImage;
  BOOL     isSystemImage;
  BOOL     isInWrapper; 
}
- (id) initWithName: (NSString *)aName
               path: (NSString *)aPath;
- (void) setImageName: (NSString *)aName;
- (NSString *) imageName;
- (void) setImagePath: (NSString *)aPath;
- (NSString *) imagePath;
- (void) setSystemImage: (BOOL)flag;
- (BOOL) isSystemImage;
- (void) setInWrapper: (BOOL)flag;
- (BOOL) isInWrapper;
- (NSString *)inspectorClassName;
@end

/*
 * Functions for drawing knobs etc.
 */
void GormDrawKnobsForRect(NSRect aFrame);
void GormDrawOpenKnobsForRect(NSRect aFrame);
NSRect GormExtBoundsForRect(NSRect aFrame);
IBKnobPosition GormKnobHitInRect(NSRect aFrame, NSPoint p);
void GormShowFastKnobFills(void);
void GormShowFrameWithKnob(NSRect aRect, IBKnobPosition aKnob);

#endif
