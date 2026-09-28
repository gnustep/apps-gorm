/** <title>GormXIBArchiver</title>

   <abstract>Interface of GormXIBKeyedArchiver</abstract>

   Copyright (C) 2023 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2023
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef GormXIBArchiver_H_INCLUDE
#define GormXIBArchiver_H_INCLUDE

#import <Foundation/NSObject.h>

@class GormDocument;
@class NSMutableDictionary;
@class NSString;
@class NSData;
@class NSMutableArray;
@class NSMutableSet;
@class NSMapTable;

/**
 * Archives a Gorm document in Interface Builder's XIB representation.
 */
GS_EXPORT_CLASS
@interface GormXIBArchiver : NSObject
{
  GormDocument *_gormDocument;
  NSMutableDictionary *_mappingDictionary;
  NSMutableArray *_allIdentifiers;
  NSMutableSet *_emittedIdentifiers;
  NSMapTable *_objectToIdentifier;
  NSDictionary *_classNameMappings;
  NSUInteger _nextIdentifier;
}

/**
 * Archives a document and returns its XIB data.  On failure nil is returned.
 * If errorDescription is non-NULL, the caller owns the returned string.
 */
+ (NSData *) dataWithGormDocument: (GormDocument *)doc
                classNameMappings: (NSDictionary *)classNameMappings
                 errorDescription: (NSString **)errorDescription;

/**
 * Initialize an archiver for the supplied Gorm document.
 */
- (instancetype) initForWritingWithGormDocument: (GormDocument *)doc
                               classNameMappings: (NSDictionary *)classNameMappings;

/**
 * Finish the archive and return its XIB representation.
 */
- (NSData *) archivedData;

@end

#endif // GormXIBArchiver_H_INCLUDE
