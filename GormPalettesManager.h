#ifndef INCLUDED_GormPalettesManager_h
#define INCLUDED_GormPalettesManager_h

@interface GormPalettesManager : NSObject
{
  NSPanel		*panel;
  NSMatrix		*selectionView;
  NSView		*dragView;
  NSMutableArray	*bundles;
  NSMutableArray	*palettes;
  int			current;
  BOOL			hiddenDuringTest;
}
- (void) loadPalette: (NSString*)path;
- (id) openPalette: (id) sender;
- (NSPanel*) panel;
- (void) setCurrentPalette: (id)anObject;
@end

#endif
