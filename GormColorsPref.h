#ifndef INCLUDED_GormColorsPref_h
#define INCLUDED_GormColorsPref_h

#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSView.h>

@interface GormColorsPref : NSObject
{
  id color;
  id window;
  id _view;
}
- (NSView *) view;
- (void)ok: (id)sender;
@end

#endif
