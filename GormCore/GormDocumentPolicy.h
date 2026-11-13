/* GormDocumentPolicy.h
 *
 * Copyright (C) 1999, 2005 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
 * Date:	2005
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef INCLUDED_GormDocumentPolicy_h
#define INCLUDED_GormDocumentPolicy_h

#import <Foundation/Foundation.h>

/**
 * Host decisions and diagnostics for document operations. Implementations may
 * prompt interactively or apply a noninteractive policy. No editor UI services
 * are required by this protocol.
 */
@protocol GormDocumentPolicy <NSObject>

/**
 * Asks whether an older archive format should be upgraded to the current format.
 * Returns YES to proceed with upgrade, NO to cancel.
 */
- (BOOL) shouldUpgradeOlderArchive;

/**
 * Asks whether a newer archive format should be loaded. Returns YES to proceed,
 * NO to cancel.
 */
- (BOOL) shouldLoadNewerArchive;

/**
 * Asks whether connections should be broken when a class is removed. Returns YES
 * to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsForClassNamed: (NSString *)className;

/**
 * Asks whether connections should be renamed when a class is renamed. Returns YES
 * to rename connections, NO to keep original names.
 */
- (BOOL) shouldRenameConnectionsForClassNamed: (NSString *)className toClassName: (NSString *)newName;

/**
 * Asks whether connections should be broken when modifying an action or outlet
 * label. Returns YES to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsModifyingLabel: (NSString *)name isAction: (BOOL)action prompted: (BOOL)prompted;

/**
 * Notifies that a class could not be parsed at the specified path.
 */
- (void) couldNotParseClassAtPath: (NSString *)path;

/**
 * Notifies that an exception occurred while parsing a class.
 */
- (void) exceptionWhileParsingClass: (NSException *)localException;

/**
 * Asks whether connections should be broken when reparsing a class. Returns YES
 * to break connections, NO to keep them.
 */
- (BOOL) shouldBreakConnectionsReparsingClass: (NSString *)className;

/**
 * Notifies that an exception occurred while loading a model file.
 */
- (void) exceptionWhileLoadingModel: (NSString *)errorMessage;


@end

#endif
