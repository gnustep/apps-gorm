#ifndef GORMPRIVATE_H
#define GORMPRIVATE_H

@class	GormDocument;
@class	GormInspectorsManager;
@class	GormPalettesManager;

#include "Gorm.h"

#include "GormDocument.h"
#include "GormInspectorsManager.h"
#include "GormPalettesManager.h"

@interface Gorm : NSApplication <IB>
{
  id			infoPanel;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  id<IBSelectionOwners>	selectionOwner;
  id<IBDocuments>	activeDocument;
  NSMutableArray	*documents;
}
- (id<IBDocuments>) activeDocument;
- (void) handleNotification: (NSNotification*)aNotification;
- (GormInspectorsManager*) inspectorsManager;
- (id) makeNewDocument: (id) sender;
- (id) openPalette: (id) sender;
- (GormPalettesManager*) palettesManager;
- (id) runInfoPanel: (id) sender;
- (id) runGormInspectors: (id) sender;
- (id) runGormPalettes: (id) sender;
@end

/*
 * Functions for drawing knobs etc.
 */
void GormDrawKnobsForRect(NSRect aFrame);
NSRect GormExtBoundsForRect(NSRect aFrame);
IBKnobPosition GormKnobHitInRect(NSRect aFrame, NSPoint p);
void GormShowFastKnobFills(void);

#endif
