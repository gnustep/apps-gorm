#ifndef INCLUDED_GormGeneralPref_h
#define INCLUDED_GormGeneralPref_h

#include <Foundation/NSObject.h>
#include <AppKit/NSView.h>

@interface GormGeneralPref : NSObject
{
  id window;
  id backupButton;
  id inspectorButton;
  id palettesButton;

  id _view;
}

- (NSView *) view;
- (void) palettesAction: (id)sender;
- (void) inspectorAction: (id)sender;
- (void) backupAction: (id)sender;
@end


#endif
