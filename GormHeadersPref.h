#ifndef INCLUDED_GormHeadersPref_h
#define INCLUDED_GormHeadersPref_h

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSView.h>

@interface GormHeadersPref : NSObject
{
  id preloadButton;
  id browser;
  id addButton;
  id removeButton;
  id window;
  id _view;

  NSMutableArray *headers;
}
- (NSView *) view;
- (void) addAction: (id)sender;
- (void) removeAction: (id)sender;
- (void) preloadAction: (id)sender;
@end

#endif
