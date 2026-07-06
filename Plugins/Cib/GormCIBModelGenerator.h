/* GormCIBModelGenerator.h
 *
 * Builds a Cappuccino-oriented CIB property-list model from a Gorm document.
 */

#ifndef GORM_CIBMODELGENERATOR_H
#define GORM_CIBMODELGENERATOR_H

#import <Foundation/NSObject.h>

@class NSData;
@class GormDocument;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSMutableSet;
@class NSString;

GS_EXPORT_CLASS
@interface GormCIBModelGenerator : NSObject
{
  GormDocument *_gormDocument;
  NSMutableDictionary *_objectIDs;
  NSMutableSet *_visitedObjects;
  NSMutableArray *_objects;
}

+ (instancetype) cibWithGormDocument: (GormDocument *)doc;
- (instancetype) initWithGormDocument: (GormDocument *)doc;
- (NSData *) data;
- (BOOL) exportCIBDocumentWithName: (NSString *)name;

@end

#endif
