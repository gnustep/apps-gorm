#ifndef INCLUDED_GormClassManager_h
#define INCLUDED_GormClassManager_h

// the custom classes array will hold only those things which will be persisted
// to the .classes file.   Since the overall list of classes will not change
// it seems that the only thing that we should save is the "delta" that being
// the custom classes.   Once loaded they can be "merged" in with the list of
// base classes, in gui, to form the full list of classes.
@interface GormClassManager : NSObject
{
  NSMutableDictionary	*classInformation;
  NSMutableArray        *customClasses;
  NSMutableDictionary   *customClassMap;
}
- (void) addAction: (NSString*)anAction forObject: (id)anObject;
- (void) addOutlet: (NSString*)anOutlet forObject: (id)anObject;
- (NSArray*) allActionsForClassNamed: (NSString*)className;
- (NSArray*) allActionsForObject: (id)anObject;
- (NSArray*) allClassNames;
- (NSArray*) allOutletsForClassNamed: (NSString*)className;
- (NSArray*) allOutletsForObject: (id)anObject;
- (NSArray*) extraActionsForObject: (id)anObject;
- (NSArray*) extraOutletsForObject: (id)anObject;
- (NSArray*) subClassesOf: (NSString *)superclass;
- (NSArray*) allSubclassesOf: (NSString *)superClass;
- (NSArray*) customSubClassesOf: (NSString *)superclass;
- (NSArray*) allCustomSubclassesOf: (NSString *)superclass;
- (void) removeAction: (NSString*)anAction forObject: (id)anObject;
- (void) removeOutlet: (NSString*)anOutlet forObject: (id)anObject;
- (void) removeAction: (NSString*)anAction fromClassNamed: (NSString*)anObject;
- (void) removeOutlet: (NSString*)anOutlet fromClassNamed: (NSString*)anObject;
- (void) addOutlet: (NSString *)anOutlet forClassNamed: (NSString *)className;
- (void) addAction: (NSString *)anAction forClassNamed: (NSString *)className;
- (void) addActions: (NSArray *)actions forClassNamed: (NSString *)className;
- (void) addOutlets: (NSArray *)outlets forClassNamed: (NSString *)className;
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
- (BOOL) isKnownClass: (NSString *)className;
- (BOOL) isAction: (NSString *)actionName ofClass: (NSString *)className;
- (BOOL) isOutlet: (NSString *)outletName ofClass: (NSString *)className;
- (NSArray *) allSuperClassesOf: (NSString *)className;

// custom class support...
- (NSString *) customClassForObject: (id)object;
- (NSString *) customClassForName: (NSString *)name;
- (void) setCustomClass: (NSString *)className
              forObject: (id)object;
- (void) removeCustomClassForObject: (id) object;
- (NSMutableDictionary *) customClassMap;
- (void) setCustomClassMap: (NSMutableDictionary *)dict;
- (BOOL) isCustomClassMapEmpty;
- (NSString *) nonCustomSuperClassOf: (NSString *)className;
- (NSString *)parentOfClass: (NSString *)aClass;

// class methods
// Maps internally used names to actual names.
+ (NSString *) correctClassName: (NSString *)className;
@end

#endif
