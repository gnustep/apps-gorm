#ifndef GORMINSPECTORSMANAGER_H
#define GORMINSPECTORSMANAGER_H

@interface GormInspectorsManager : NSObject
{
  NSPanel		*panel;
  NSMatrix		*selectionView;
  NSBox			*divider;
  NSView		*inspectorView;
  NSView		*buttonView;
  IBInspector		*emptyInspector;
  IBInspector		*multipleInspector;
  IBInspector		*inspector;
  int			current;
}
- (NSPanel*) panel;
- (void) setCurrentInspector: (id)anObject;
- (void) updateSelection;
@end

#endif
