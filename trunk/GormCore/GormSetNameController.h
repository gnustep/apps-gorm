// Author: Andrew E. Ruder
// Copyright (C) 2003 by Free Software Foundation, Inc

@class GormSetNameController;

#ifndef GORM_SET_NAME_CONTROLLER_H
#define GORM_SET_NAME_CONTROLLER_H

#include <Foundation/NSObject.h>

@class NSButton, NSPanel, NSTextField;

@interface GormSetNameController : NSObject
{
  NSPanel *window;
  NSTextField *textField;
  NSButton *okButton;
  NSButton *cancelButton;
}
- (int)runAsModal;

- (NSTextField *) textField;
- (void) cancelHit: (id)sender;
- (void) okHit: (id)sender;
@end

#endif
