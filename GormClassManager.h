#ifndef GORMCLASSMANAGER_H
#define GORMCLASSMANAGER_H

@interface GormClassManager : NSObject
{
  NSMutableDictionary	*classInformation;
}
- (NSArray*) allActionsForClassNamed: (NSString*)className;
- (NSArray*) allActionsForObject: (NSObject*)anObject;
- (NSArray*) allClassNames;
- (NSArray*) allOutletsForClassNamed: (NSString*)className;
- (NSArray*) allOutletsForObject: (NSObject*)anObject;
@end

#endif
