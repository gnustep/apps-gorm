#ifndef GORMINSPECTORSMANAGER_H
#define GORMINSPECTORSMANAGER_H

@interface GormInspectorsManager : NSObject
{
  NSPanel		*panel;
  NSMatrix		*selectionView;
  NSView		*inspectorView;
  NSArray		*selection;
  NSButton		*emptyView;
  NSButton		*multipleView;
  IBInspector		*inspector;
  int			current;
}
- (NSPanel*) panel;
- (void) setCurrentInspector: (id)anObject;
@end

#endif
