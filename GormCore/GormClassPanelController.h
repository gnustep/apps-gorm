/* GormClassPanelController.h
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

/* All Rights reserved */

#include <AppKit/AppKit.h>

@class NSMutableArray;

/**
 * GormClassPanelController manages the modal panel used to pick a class name.
 * It loads the panel UI, presents the available classes in a browser, and
 * returns the selected class name when the user confirms.
 */
@interface GormClassPanelController : NSObject
{
  id okButton;
  id classBrowser;
  id panel;
  id classNameForm;
  NSString *className;
  NSMutableArray *allClasses;
}
/**
 * Initialize the controller with a window title and the list of class names
 * to display in the browser.
 */
- (id) initWithTitle: (NSString *)title classList: (NSArray *)classes;
/**
 * Confirm the current selection and close the panel.
 */
- (void) okButton: (id)sender;
/**
 * Update the text field when the user changes the selection in the browser.
 */
- (void) browserAction: (id)sender;
/**
 * Run the panel modally and return the chosen class name, or nil if cancelled.
 */
- (NSString *)runModal;
@end
