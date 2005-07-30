#ifndef INCLUDED_GormPalettesPref_h
#define INCLUDED_GormPalettesPref_h

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSView.h>

@interface GormPalettesPref : NSObject
{
  id table;
  id addButton;
  id removeButton;
  id window;
  id _view;

  NSMutableArray *palettes;
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
