#ifndef GORMCLASSMANAGER_H
#define GORMCLASSMANAGER_H

@interface GormClassManager : NSObject
{
  NSMutableDictionary	*classInformation;
}
- (NSArray*) allActionsForClass: (Class)aClass;
- (NSArray*) allActionsForClassNamed: (NSString*)className;
- (NSArray*) allOutletsForClass: (Class)aClass;
- (NSArray*) allOutletsForClassNamed: (NSString*)className;
@end

#endif
