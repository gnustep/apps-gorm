#ifndef GORMPALETTESMANAGER_H
#define GORMPALETTESMANAGER_H

@interface GormPalettesManager : NSObject
{
  NSPanel		*panel;
  NSMatrix		*selectionView;
  NSView		*dragView;
  NSMutableArray	*bundles;
  NSMutableArray	*palettes;
  int			current;
}

- (void) loadPalette: (NSString*)path;
- (id) openPalette: (id) sender;
- (NSPanel*) panel;
- (void) setCurrentPalette: (id)anObject;
@end

#endif
