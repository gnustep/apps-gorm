#ifndef GORMINSPECTORSMANAGER_H
#define GORMINSPECTORSMANAGER_H

@interface GormInspectorsManager : NSObject
{
  NSPanel		*panel;
  NSMutableDictionary	*cache;
  NSPopUpButton		*popup;
  NSView		*selectionView;
  NSView		*inspectorView;
  NSView		*buttonView;
  NSString		*oldInspector;
  IBInspector		*inspector;
  int			current;
  BOOL			hiddenDuringTest;
}
- (NSPanel*) panel;
- (void) setCurrentInspector: (id)anObject;
- (void) updateSelection;
@end

#endif
