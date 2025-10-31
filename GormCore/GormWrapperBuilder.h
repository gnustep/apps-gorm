/* GormWrapperBuilder
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

#ifndef INCLUDED_GormWrapperBuilder_h
#define INCLUDED_GormWrapperBuilder_h

#include <Foundation/Foundation.h>

@class NSFileWrapper, GormDocument, NSString, NSMutableDictionary;

/**
 * GormWrapperBuilder defines the interface for building NSFileWrapper-based
 * representations of a Gorm document. Implementors produce wrapper content
 * for specific file types.
 */
@protocol GormWrapperBuilder
/**
 * Build the dictionary of file wrappers for the document contents.
 */
- (NSMutableDictionary *) buildFileWrapperDictionaryWithDocument: (GormDocument *)document;
/**
 * Build a top-level NSFileWrapper for the document.
 */
- (NSFileWrapper *) buildFileWrapperWithDocument: (GormDocument *)document;
@end

/**
 * GormWrapperBuilder is the default implementation of the builder protocol
 * and provides utilities common to concrete builders.
 */
@interface GormWrapperBuilder : NSObject <GormWrapperBuilder>
{
  GormDocument *document;
}
/**
 * Return the file type identifier (UTI or extension) handled by this builder.
 */
+ (NSString *) fileType;
@end

/**
 * GormWrapperBuilderFactory registers and creates wrapper builders for file
 * types, returning the appropriate builder instance on demand.
 */
@interface GormWrapperBuilderFactory : NSObject
/**
 * Return the shared factory instance.
 */
+ (GormWrapperBuilderFactory *) sharedWrapperBuilderFactory;
/**
 * Register a builder implementation class for its supported file type.
 */
+ (void) registerWrapperBuilderClass: (Class) aClass;
/**
 * Return a builder capable of producing a wrapper for the given type.
 */
- (id<GormWrapperBuilder>) wrapperBuilderForType: (NSString *) type;
@end

#endif
