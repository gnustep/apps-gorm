#ifndef INCLUDED_GormPrefController_h
#define INCLUDED_GormPrefController_h

#include <Foundation/NSObject.h>

#include <AppKit/NSWindowController.h>

@interface GormPrefController : NSWindowController
{
  id window;
  id popup;
  id prefBox;

  id _generalView;
  id _headersView;
  id _shelfView;
  id _colorsView;
  id _palettesView;
  id _guidelineView;
}

- (void) popupAction: (id)sender;

@end

#endif
