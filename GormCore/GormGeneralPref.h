#ifndef INCLUDED_GormGeneralPref_h
#define INCLUDED_GormGeneralPref_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

/**
 * GormGeneralPref implements the General preferences pane. It hosts common
 * options like creating backups, and whether classes are shown as a browser
 * or outline, and exposes the view for the preferences window.
 */
@interface GormGeneralPref : NSObject
{
  id window;
  id backupButton;
  id interfaceMatrix;
  id checkConsistency;
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

/**
 * Toggle consistency checking of loaded documents and update the preference.
 */
- (void) consistencyAction: (id)sender;
@end


#endif
