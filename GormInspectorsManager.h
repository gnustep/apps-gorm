#ifndef INCLUDED_GormInspectorsManager_h
#define INCLUDED_GormInspectorsManager_h

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
- (void) setClassInspector;
- (void) setCurrentInspector: (id)anObject;
- (void) updateSelection;
@end

#endif
