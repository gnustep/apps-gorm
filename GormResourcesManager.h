#ifndef GORMRESOURCESMANAGER_H
#define GORMRESOURCESMANAGER_H

@interface GormResourcesManager : NSObject
{
  NSWindow		*window;
  NSMatrix		*selectionView;
  NSScrollView		*scrollView;
  id			objectsView;
  id<IBDocuments>	document;
}
+ (GormResourcesManager*) newManagerForDocument: (id<IBDocuments>)doc;
- (void) addObject: (id)anObject;
- (id<IBDocuments>) document;
- (void) removeObject: (id)anObject;
- (NSWindow*) window;
- (BOOL) windowShouldClose: (NSWindow*)aWindow;
- (void) windowWillClose: (NSNotification*)aNotification;
@end

#endif
