/* Widget library, an additional browser for palette prototypes.
 * Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef INCLUDED_GormWidgetLibrary_h
#define INCLUDED_GormWidgetLibrary_h

#import <AppKit/AppKit.h>
@class IBPalette;

@interface GormWidgetLibrary : NSObject
{
  NSPanel *panel;
  NSSearchField *searchField;
  NSScrollView *scrollView;
  NSMutableArray *entries;
  BOOL hiddenDuringTest;
}
- (NSPanel *) panel;
- (BOOL) isVisible;
- (void) addPalette: (IBPalette *)palette;
@end
#endif
