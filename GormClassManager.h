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

- (BOOL) renameClassNamed: (NSString*)oldName newName: (NSString*)name;
- (NSString*) addClassWithSuperClassName: (NSString*)name;
- (BOOL) addClassNamed: (NSString*)className
   withSuperClassNamed: (NSString*)superClassName
	   withActions: (NSArray*)actions
           withOutlets: (NSArray*)outlets;
- (BOOL) setSuperClassNamed: (NSString*)superclass
	      forClassNamed: (NSString*)subclass;

- (NSString*) superClassNameForClassNamed: (NSString*)className;
- (BOOL) isSuperclass: (NSString*)superclass
	linkedToClass: (NSString*)subclass;
- (BOOL) makeSourceAndHeaderFilesForClass: (NSString*)className
				 withName:(NSString*)sourcePath
				      and:(NSString*)headerPath;

- (BOOL) saveToFile: (NSString*)path;
- (BOOL) loadFromFile: (NSString*)path;
@end

#endif
