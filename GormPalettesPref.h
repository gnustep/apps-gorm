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
- (NSView *) view;
- (void) addAction: (id)sender;
- (void) removeAction: (id)sender;
@end

#endif
