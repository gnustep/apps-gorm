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

@interface Gorm : NSApplication <IB>
{
  id			infoPanel;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  id			selectionOwner;
  id			activeDocument;
  NSMutableArray	*documents;
  BOOL			isTesting;
  NSImage		*sourceImage;
  NSImage		*targetImage;
  id			connectSource;
  id			connectDestination;
}
- (id<IBDocuments>) activeDocument;
- (id) connectSource;
- (id) connectDestination;
- (void) displayConnectionBetween: (id)source and: (id)destination;
- (void) handleNotification: (NSNotification*)aNotification;
- (GormInspectorsManager*) inspectorsManager;
- (BOOL) isConnecting;
- (GormPalettesManager*) palettesManager;
- (void) setConnectDestination: (id)anObject;
- (void) setConnectSource: (id)anObject;
- (NSImage*) sourceImage;
- (void) stopConnecting;
- (NSImage*) targetImage;

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

/*
 * Functions for drawing knobs etc.
 */
void GormDrawKnobsForRect(NSRect aFrame);
NSRect GormExtBoundsForRect(NSRect aFrame);
IBKnobPosition GormKnobHitInRect(NSRect aFrame, NSPoint p);
void GormShowFastKnobFills(void);
void GormShowFrameWithKnob(NSRect aRect, IBKnobPosition aKnob);

#endif
