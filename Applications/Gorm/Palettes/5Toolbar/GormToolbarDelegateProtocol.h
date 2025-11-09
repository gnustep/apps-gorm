/* GormToolbarDelegateProtocol.m
 *
 * Implementation of the protocol for NSToolbar delegate objects in Gorm palettes.
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg.casamento@gmail.com>
 *
 * This file is part of GNUstep.
 *
 * GNUstep is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * GNUstep is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNUstep; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

@protocol GormToolbarDelegateProtocol

// Allowed items...
- (void) addAllowedItemIdentifier: (NSString *)identifier;
- (void) removeAllowedItemIdentifier: (NSString *)identifier;

// Default items...
- (void) addDefaultItemIdentifier: (NSString *)identifier;
- (void) removeDefaultItemIdentifier: (NSString *)identifier;

@end
