/* NSCell+GormAdditions.h
 *
 * Copyright (C) 1999, 2003, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2005
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

#ifndef INCLUDED_NSCellGormAdditions_h
#define INCLUDED_NSCellGormAdditions_h

#include <AppKit/AppKit.h>

@class NSText;

/**
 * Adds a convenience method used by Gorm to configure the field editor for
 * a cell without letting the Font Panel take over font changes.
 */
@interface NSCell (GormAdditions)
/**
 *  This methods is comes directly from NSCell.m
 *  The only additions is [textObject setUsesFontPanel: NO]
 *  We do this because we want to have control over the font 
 *  panel changes.
 */
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject;
@end

#endif
