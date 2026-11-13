/* GormDocumentIO.h
 *
 * Shared document file operations.
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
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

#ifndef INCLUDED_GormDocumentIO_h
#define INCLUDED_GormDocumentIO_h

#import <Foundation/Foundation.h>
#import <GormCore/GormDocumentPolicy.h>

@class GormDocument;

/**
 * Shared file operations, independent of document-controller registration and
 * window presentation. The host initializes AppKit, loads format plugins, and
 * configures editor-to-runtime class substitution as for other Gorm operations.
 * A noninteractive policy is required if the host must avoid decision dialogs.
 */
GS_EXPORT_CLASS
@interface GormDocumentIO : NSObject
/**
 * Return an autoreleased document, or nil and an error. The host owns document
 * registration and lifetime. The policy is not retained by the document.
 */
+ (GormDocument *) readDocumentFromFile: (NSString *)path
                               ofType: (NSString *)type
                               policy: (id<GormDocumentPolicy>)policy
                                error: (NSError **)error;

/** Write an existing document, returning failure details without presenting UI. */
+ (BOOL) writeDocument: (GormDocument *)document
               toFile: (NSString *)path
               ofType: (NSString *)type
                error: (NSError **)error;
@end

#endif
