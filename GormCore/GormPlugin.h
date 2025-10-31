/* GormNibModule.m
 *
 * Copyright (C) 2007 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2007
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
 */

#ifndef GORM_GORMPLUGIN
#define GORM_GORMPLUGIN

#include <InterfaceBuilder/InterfaceBuilder.h>

@class NSString, NSArray;

/**
 * GormPlugin is the base plugin interface used by Gorm to extend functionality.
 * Plugins can register document types, contribute palettes and inspectors, and
 * provide additional behaviors to the editor.
 */
@interface GormPlugin : IBPlugin
/**
 * Registers a document type with a human‑readable name and the associated file
 * extensions, allowing Gorm to present the type in open/save panels and to map
 * files to the correct document class.
 */
- (void) registerDocumentTypeName: (NSString *)name
                humanReadableName: (NSString *)hrName
                    forExtensions: (NSArray *)extensions;
@end

#endif
