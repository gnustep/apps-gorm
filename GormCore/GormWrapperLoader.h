/* GormWrapperLoader
 *
 * This class is a subclass of the NSDocumentController
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2006
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

#ifndef INCLUDED_GormWrapperLoader_h
#define INCLUDED_GormWrapperLoader_h

#include <Foundation/Foundation.h>

@class NSFileWrapper, GormDocument, NSString;

/**
 * GormWrapperLoader defines the interface for loading a document from an
 * NSFileWrapper-based bundle. Implementors parse wrappers for specific file
 * types and populate a Gorm document.
 */
@protocol GormWrapperLoader
/**
 * Load the document from the given file wrapper.
 */
- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *)document;
@end

/**
 * GormWrapperLoader is the default implementation of the loader protocol and
 * provides helpers shared by concrete loaders.
 */
@interface GormWrapperLoader : NSObject <GormWrapperLoader>
{
  GormDocument *document;
}
/**
 * Return the file type identifier (UTI or extension) handled by this loader.
 */
+ (NSString *) fileType;
/**
 * Save the SCM metadata directory contained in the given wrapper map.
 */
- (void) saveSCMDirectory: (NSDictionary *) fileWrappers;
@end

/**
 * GormWrapperLoaderFactory registers and returns wrapper loaders suitable for
 * specific file types.
 */
@interface GormWrapperLoaderFactory : NSObject
/**
 * Return the shared factory instance.
 */
+ (GormWrapperLoaderFactory *) sharedWrapperLoaderFactory;
/**
 * Register a loader implementation class for its supported file type.
 */
+ (void) registerWrapperLoaderClass: (Class) aClass;
/**
 * Return a loader capable of handling the given file type.
 */
- (id<GormWrapperLoader>) wrapperLoaderForType: (NSString *) type;
@end

#endif
