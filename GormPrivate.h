#ifndef GORMPRIVATE_H
#define GORMPRIVATE_H

@class	GormDocument;
@class	GormInspectorsManager;
@class	GormPalettesManager;

#include "Gorm.h"

#include "GormDocument.h"
#include "GormInspectorsManager.h"
#include "GormPalettesManager.h"

extern NSString *GormLinkPboardType;

@interface NSApplication (Gorm)
- (NSImage*) linkImage;
- (void) startConnecting;
@end

@interface Gorm : NSApplication <IB>
{
  id			infoPanel;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  id			selectionOwner;
  id			activeDocument;
  NSMutableArray	*documents;
  BOOL			isConnecting;
  BOOL			isTesting;
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
- (id) inspector: (id) sender;
- (id) newApplication: (id) sender;
- (id) loadPalette: (id) sender;
- (id) open: (id)sender;
- (id) palettes: (id) sender;
- (id) paste: (id)sender;
- (id) revertToSaved: (id)sender;
- (id) save: (id)sender;
- (id) saveAll: (id)sender;
- (id) saveAs: (id)sender;
- (id) selectAll: (id)sender;
- (id) setName: (id)sender;
- (id) testInterface: (id)sender;
@end

@interface	GormObjectEditor : NSMatrix <IBEditors>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPoint		mouseDownPoint;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
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
- (void) validateEditing;
- (BOOL) wantsSelection;
- (NSWindow*) window;
@end

/*
 * Functions for drawing knobs etc.
 */
void GormDrawKnobsForRect(NSRect aFrame);
NSRect GormExtBoundsForRect(NSRect aFrame);
IBKnobPosition GormKnobHitInRect(NSRect aFrame, NSPoint p);
void GormShowFastKnobFills(void);
void GormShowFrameWithKnob(NSRect aRect, IBKnobPosition aKnob);

#endif
