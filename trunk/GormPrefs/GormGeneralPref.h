#ifndef INCLUDED_GormGeneralPref_h
#define INCLUDED_GormGeneralPref_h

#include <Foundation/NSObject.h>
#include <AppKit/NSView.h>

@interface GormGeneralPref : NSObject
{
  id window;
  id backupButton;
  id interfaceMatrix;

  id _view;
}

/**
 * View to be shown.
 */
- (NSView *) view;

/**
 * Should create a backup file.
 */
- (void) backupAction: (id)sender;

/**
 * Show the classes view as a browser or an outline.
 */
- (void) classesAction: (id)sender;
@end


#endif
