#ifndef GORMCLASSMANAGER_H
#define GORMCLASSMANAGER_H

@interface GormClassManager : NSObject
{
  NSMutableDictionary	*classInformation;
}
- (void) addAction: (NSString*)anAction forObject: (NSObject*)anObject;
- (void) addOutlet: (NSString*)anOutlet forObject: (NSObject*)anObject;
- (NSArray*) allActionsForClassNamed: (NSString*)className;
- (NSArray*) allActionsForObject: (NSObject*)anObject;
- (NSArray*) allClassNames;
- (NSArray*) allOutletsForClassNamed: (NSString*)className;
- (NSArray*) allOutletsForObject: (NSObject*)anObject;
- (NSArray*) extraActionsForObject: (NSObject*)anObject;
- (NSArray*) extraOutletsForObject: (NSObject*)anObject;
- (void) removeAction: (NSString*)anAction forObject: (NSObject*)anObject;
- (void) removeOutlet: (NSString*)anOutlet forObject: (NSObject*)anObject;
@end

#endif
