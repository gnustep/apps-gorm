// Author: Andrew E. Ruder
// Copyright (C) 2003 by Free Software Foundation, Inc

@class GormSetNameController;

#ifndef GORM_SET_NAME_CONTROLLER_H
#define GORM_SET_NAME_CONTROLLER_H

#include <Foundation/Foundation.h>

@class NSButton, NSPanel, NSTextField;

/**
 * GormSetNameController presents a simple modal panel to collect a name from
 * the user (e.g., for renaming). It exposes the text field and returns the
 * modal response when run.
 */
@interface GormSetNameController : NSObject
{
  NSPanel *window;
  NSTextField *textField;
  NSButton *okButton;
  NSButton *cancelButton;
}
/**
 * Run the window as a modal session and return the modal response code.
 */
- (NSInteger)runAsModal;

/**
 * Access the editable text field used to input the name.
 */
- (NSTextField *) textField;
/**
 * Cancel the dialog without applying changes.
 */
- (void) cancelHit: (id)sender;
/**
 * Accept the current value and close the dialog.
 */
- (void) okHit: (id)sender;
@end

#endif
