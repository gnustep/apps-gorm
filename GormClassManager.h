#ifndef GORMCLASSMANAGER_H
#define GORMCLASSMANAGER_H

// the custom classes array will hold only those things which will be persisted
// to the .classes file.   Since the overall list of classes will not change
// it seems that the only thing that we should save is the "delta" that being
// the custom classes.   Once loaded they can be "merged" in with the list of
// base classes, in gui, to form the full list of classes.
@interface GormClassManager : NSObject
{
  NSMutableDictionary	*classInformation;
  NSMutableArray        *customClasses;
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
- (NSArray*) subClassesOf: (NSString *)superclass;
- (void) removeAction: (NSString*)anAction forObject: (NSObject*)anObject;
- (void) removeOutlet: (NSString*)anOutlet forObject: (NSObject*)anObject;
- (void) removeAction: (NSString*)anAction fromClassNamed: (NSString*)anObject;
- (void) removeOutlet: (NSString*)anOutlet fromClassNamed: (NSString*)anObject;
- (void) addOutlet: (NSString *)anOutlet forClassNamed: (NSString *)className;
- (void) addAction: (NSString *)anAction forClassNamed: (NSString *)className;
- (NSString *) addNewActionToClassNamed: (NSString *)name;
- (NSString *) addNewOutletToClassNamed: (NSString *)name;
- (void) replaceAction: (NSString *)oldAction withAction: (NSString *)newAction forClassNamed: className;
- (void) replaceOutlet: (NSString *)oldOutlet withOutlet: (NSString *)newOutlet forClassNamed: className;
- (BOOL) renameClassNamed: (NSString *)oldName newName: (NSString*)name;
- (void) removeClassNamed: (NSString *)className;
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
- (BOOL) loadCustomClasses: (NSString*)path;
- (BOOL) isCustomClass: (NSString *)className;
- (BOOL) isAction: (NSString *)actionName ofClass: (NSString *)className;
- (BOOL) isOutlet: (NSString *)outletName ofClass: (NSString *)className;
@end

#endif
