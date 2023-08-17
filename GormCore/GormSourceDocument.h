/* GormSourceDocument.h
 *
 * Copyright (C) 2023 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2023
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

#ifndef GormSourceDocument_H_INCLUDE
#define GormSourceDocument_H_INCLUDE

#import <Foundation/NSObject.h>

@class NSString;
@class NSMutableString;
@class GormDocument;

@interface GormSourceDocument : NSObject
{
  GormDocument *_gormDocument;

  NSMutableString *_sourceString;
  NSMutableString *_headerString;
}

/**
 * Returns an autoreleased GormSourceDocument object;
 */
+ (instancetype) sourceWithGormDocument: (GormDocument *)doc;

/**
 * Initialize with GormDocument object to parse the XML from or into.
 */
- (instancetype) initWithGormDocument: (GormDocument *)doc;

/**
 * Exports source files.  This method starts the process and calls
 * another method that recurses through the objects in the model and pulls
 * any elements needed to generate the .m and .h files.
 */
- (BOOL) exportSourceDocumentWithName: (NSString *)name;

@end

#endif // GormSourceDocument_H_INCLUDE
