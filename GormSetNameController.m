// Author: Andrew E. Ruder
// Copyright (C) 2003 by Free Software Foundation, Inc

#include "GormSetNameController.h"

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPanel.h>

@implementation GormSetNameController : NSObject
- (int)runAsModal
{
  int result;
  
  if (!window)
    {
      if (![NSBundle loadNibNamed: @"GormSetName" owner: self])
        {
          return NSAlertAlternateReturn;
        }
    }
  
  [window makeKeyAndOrderFront: nil];
  [window makeFirstResponder: textField];
  
  result = [NSApp runModalForWindow: window];

  return result;
}
- (NSTextField *) textField
{
  return textField;
}
- (void) cancelHit: (id)sender
{
  [window close];
  [NSApp stopModalWithCode: NSAlertAlternateReturn];
}
- (void) okHit: (id)sender
{
  [window close];
  [NSApp stopModalWithCode: NSAlertDefaultReturn];
}
@end
