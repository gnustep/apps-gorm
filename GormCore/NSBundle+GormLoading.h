/* NSBundle+GormLoading.h
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
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

#ifndef INCLUDED_NSBundle_GormLoading_h
#define INCLUDED_NSBundle_GormLoading_h

#include <Foundation/Foundation.h>

@interface NSBundle (GormLoading)

/**
 * Loads objects generated from a Gorm document compiled into the process.
 *
 * This mirrors +loadNibNamed:owner: for generated Gorm source.  The generated
 * source for "MainMenu" exposes a GormCreateMainMenuObjects() entry point;
 * this method locates it, passes owner as File's Owner, establishes generated
 * connections, and orders visible launch windows front.
 */
+ (BOOL) loadGormNamed: (NSString *)name owner: (id)owner;

@end

#endif
