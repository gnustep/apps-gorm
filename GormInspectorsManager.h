#ifndef GORMINSPECTORSMANAGER_H
#define GORMINSPECTORSMANAGER_H

@interface GormInspectorsManager : NSObject
{
  NSPanel		*panel;
  NSView		*selectionView;
  NSView		*inspectorView;
  NSView		*buttonView;
  IBInspector		*emptyInspector;
  IBInspector		*multipleInspector;
  IBInspector		*inspector;
  int			current;
  BOOL			hiddenDuringTest;
}
- (NSPanel*) panel;
- (void) setCurrentInspector: (id)anObject;
- (void) updateSelection;
@end

#endif
