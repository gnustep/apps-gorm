#ifndef INCLUDED_GormPalettesPref_h
#define INCLUDED_GormPalettesPref_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

/**
 * GormPalettesPref implements the Palettes preferences pane. It shows the
 * available palettes and lets users add or remove entries, providing the
 * view used within the preferences window.
 */
@interface GormPalettesPref : NSObject
{
  id table;
  id addButton;
  id removeButton;
  id window;
  id _view;
}

/**
 * View to be shown in the preferences panel.
 */
- (NSView *) view;

/**
 * Add a palette to the list.
 */
- (void) addAction: (id)sender;

/**
 * Remove a palette from the list.
 */
- (void) removeAction: (id)sender;
@end

#endif
