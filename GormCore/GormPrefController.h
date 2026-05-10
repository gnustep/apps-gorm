/* GormShelfPref.m
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg.casamento@gmail.com>
 * Date: February 2004
 *
 * This class is heavily based on work done by Enrico Sersale
 * on ShelfPref.m for GWorkspace.
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
 * Foundation, Inc., 31 Milk St # 960789 Boston, MA 02196 USA
 */

#ifndef INCLUDED_GormPrefController_h
#define INCLUDED_GormPrefController_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
GS_EXPORT_CLASS
@interface GormPrefController : NSObject
{
  id panel;
  id popup;
  id prefBox;

  id _generalView;
  id _headersView;
  id _shelfView;
  id _colorsView;
  id _palettesView;
  id _pluginsView;
  id _guidelineView;
}

/**
 * Called when the popup is used to select a pref panel.
 */
- (void) popupAction: (id)sender;

/**
 * Returns the panel window that displays the current palette contents.
 */
- (id) panel;
@end

#endif
