/* GormClassManager.h
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2002
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

#ifndef INCLUDED_GormClassManager_h
#define INCLUDED_GormClassManager_h

#import <InterfaceBuilder/InterfaceBuilder.h>

/**
 * GormClassManager manages class information for a Gorm document, including
 * custom classes, categories, actions, and outlets. The custom classes and
 * category arrays hold only those elements which will be persisted to the
 * .classes file. Since the overall list of classes will not change, only the
 * "delta" (custom classes) is saved. Once loaded, they can be merged with
 * the list of base classes to form the full list of classes.
 */
@interface GormClassManager : NSObject
{
  NSMutableDictionary	*_classInformation;
  NSMutableArray        *_customClasses;
  NSMutableDictionary   *_customClassMap;
  NSMutableArray        *_categoryClasses;
  id                     _document;
}

/**
 * Initializes the class manager with the specified document.
 */
- (id) initWithDocument: (id)aDocument;

/**
 * Adds an action to the specified object's class.
 */
- (void) addAction: (NSString *)anAction forObject: (id)anObject;

/**
 * Adds an outlet to the specified object's class.
 */
- (void) addOutlet: (NSString *)anOutlet forObject: (id)anObject;

/**
 * Returns an array of all actions defined for the named class.
 */
- (NSArray *) allActionsForClassNamed: (NSString *)className;

/**
 * Returns an array of all actions defined for the specified object's class.
 */
- (NSArray *) allActionsForObject: (id)anObject;

/**
 * Returns an array of extra actions (beyond inherited) for the specified object.
 */
- (NSArray *) extraActionsForObject: (id)anObject;

/**
 * Returns an array of all outlets defined for the named class.
 */
- (NSArray *) allOutletsForClassNamed: (NSString *)className;

/**
 * Returns an array of all outlets defined for the specified object's class.
 */
- (NSArray *) allOutletsForObject: (id)anObject;

/**
 * Returns an array of extra outlets (beyond inherited) for the specified object.
 */
- (NSArray *) extraOutletsForObject: (id)anObject;

/**
 * Returns an array of all known class names.
 */
- (NSArray *) allClassNames;

/**
 * Removes an action from the specified object's class.
 */
- (void) removeAction: (NSString *)anAction forObject: (id)anObject;

/**
 * Removes an outlet from the specified object's class.
 */
- (void) removeOutlet: (NSString *)anOutlet forObject: (id)anObject;

/**
 * Removes an action from the named class.
 */
- (void) removeAction: (NSString *)anAction fromClassNamed: (NSString *)anObject;

/**
 * Removes an outlet from the named class.
 */
- (void) removeOutlet: (NSString *)anOutlet fromClassNamed: (NSString *)anObject;

/**
 * Adds an outlet to the named class.
 */
- (void) addOutlet: (NSString *)anOutlet forClassNamed: (NSString *)className;

/**
 * Adds an action to the named class.
 */
- (void) addAction: (NSString *)anAction forClassNamed: (NSString *)className;

/**
 * Adds multiple actions to the named class.
 */
- (void) addActions: (NSArray *)actions forClassNamed: (NSString *)className;

/**
 * Adds multiple outlets to the named class.
 */
- (void) addOutlets: (NSArray *)outlets forClassNamed: (NSString *)className;

/**
 * Adds a new action with a generated name to the named class and returns the name.
 */
- (NSString *) addNewActionToClassNamed: (NSString *)name;

/**
 * Adds a new outlet with a generated name to the named class and returns the name.
 */
- (NSString *) addNewOutletToClassNamed: (NSString *)name;

/**
 * Replaces an action name with a new name for the named class.
 */
- (void) replaceAction: (NSString *)oldAction withAction: (NSString *)newAction forClassNamed: (NSString *)className;

/**
 * Replaces an outlet name with a new name for the named class.
 */
- (void) replaceOutlet: (NSString *)oldOutlet withOutlet: (NSString *)newOutlet forClassNamed: (NSString *)className;

/**
 * Renames a class from oldName to name. Returns YES on success, NO on failure.
 */
- (BOOL) renameClassNamed: (NSString *)oldName newName: (NSString *)name;

/**
 * Removes the named class from the class manager.
 */
- (void) removeClassNamed: (NSString *)className;

/**
 * Adds a new class with the specified superclass name and returns the new
 * class name.
 */
- (NSString *) addClassWithSuperClassName: (NSString *)name;

/**
 * Returns an array of direct subclasses of the specified superclass.
 */
- (NSArray *) subClassesOf: (NSString *)superclass;

/**
 * Returns an array of all subclasses (direct and indirect) of the specified
 * superclass.
 */
- (NSArray *) allSubclassesOf: (NSString *)superClass;

/**
 * Returns an array of direct custom subclasses of the specified superclass.
 */
- (NSArray *) customSubClassesOf: (NSString *)superclass;

/**
 * Returns an array of all custom subclasses (direct and indirect) of the
 * specified superclass.
 */
- (NSArray *) allCustomSubclassesOf: (NSString *)superclass;

/**
 * Returns an array of all custom class names.
 */
- (NSArray *) allCustomClassNames;

/**
 * Adds a class with the specified name, superclass, actions, and outlets.
 * Returns YES on success, NO on failure.
 */
- (BOOL) addClassNamed: (NSString *)className
   withSuperClassNamed: (NSString *)superClassName
	   withActions: (NSArray *)actions
           withOutlets: (NSArray *)outlets;

/**
 * Adds a class with the specified name, superclass, actions, outlets, and
 * custom flag. Returns YES on success, NO on failure.
 */
- (BOOL) addClassNamed: (NSString *)class_name
   withSuperClassNamed: (NSString *)super_class_name
	   withActions: (NSArray *)_actions
	   withOutlets: (NSArray *)_outlets
              isCustom: (BOOL) isCustom;

/**
 * Sets the superclass for the specified subclass. Returns YES on success,
 * NO on failure.
 */
- (BOOL) setSuperClassNamed: (NSString *)superclass
	      forClassNamed: (NSString *)subclass;

/**
 * Returns the name of the parent class for the specified class.
 */
- (NSString *)parentOfClass: (NSString *)aClass;

/**
 * Returns the name of the superclass for the named class.
 */
- (NSString *) superClassNameForClassNamed: (NSString *)className;

/**
 * Returns YES if superclass is linked to subclass in the class hierarchy,
 * NO otherwise.
 */
- (BOOL) isSuperclass: (NSString *)superclass
	linkedToClass: (NSString *)subclass;

/**
 * Returns a dictionary containing all information for the named class.
 */
- (NSDictionary *) dictionaryForClassNamed: (NSString *)className;

/**
 * Generates and returns a unique class name based on the provided name.
 */
- (NSString *) uniqueClassNameFrom: (NSString *)name;

/**
 * Returns YES if the named class is a root class, NO otherwise.
 */
- (BOOL) isRootClass: (NSString *)className;

/**
 * Returns YES if the outlet exists on the named class, NO otherwise.
 */
- (BOOL) outletExists: (NSString *)outlet
         onClassNamed: (NSString *)className;

/**
 * Returns YES if the action exists on the named class, NO otherwise.
 */
- (BOOL) actionExists: (NSString *)action
         onClassNamed: (NSString *)className;

/**
 * Returns YES if the named class is a custom class, NO otherwise.
 */
- (BOOL) isCustomClass: (NSString *)className;

/**
 * Returns YES if the named class is not a custom class, NO otherwise.
 */
- (BOOL) isNonCustomClass: (NSString *)className;

/**
 * Returns YES if the named class is a category, NO otherwise.
 */
- (BOOL) isCategoryForClass: (NSString *)className;

/**
 * Returns YES if the named class is known to the class manager, NO otherwise.
 */
- (BOOL) isKnownClass: (NSString *)className;

/**
 * Returns YES if the action exists on the named class, NO otherwise.
 */
- (BOOL) isAction: (NSString *)actionName ofClass: (NSString *)className;

/**
 * Returns YES if the outlet exists on the named class, NO otherwise.
 */
- (BOOL) isOutlet: (NSString *)outletName ofClass: (NSString *)className;

/**
 * Returns an array of all superclasses of the named class.
 */
- (NSArray *) allSuperClassesOf: (NSString *)className;

/**
 * Returns YES if the named class can be instantiated, NO otherwise.
 */
- (BOOL) canInstantiateClassNamed: (NSString *)className;

/**
 * Returns the custom class name for the specified object.
 */
- (NSString *) customClassForObject: (id)object;

/**
 * Returns the custom class associated with the given name.
 */
- (NSString *) customClassForName: (NSString *)name;

/**
 * Sets a custom class mapping for the specified name.
 */
- (void) setCustomClass: (NSString *)className
                forName: (NSString *)name;

/**
 * Removes the custom class mapping for the specified name.
 */
- (void) removeCustomClassForName: (NSString *)name;

/**
 * Returns the custom class map dictionary.
 */
- (NSMutableDictionary *) customClassMap;

/**
 * Sets the custom class map dictionary.
 */
- (void) setCustomClassMap: (NSMutableDictionary *)dict;

/**
 * Returns YES if the custom class map is empty, NO otherwise.
 */
- (BOOL) isCustomClassMapEmpty;

/**
 * Returns the first non-custom superclass of the named class.
 */
- (NSString *) nonCustomSuperClassOf: (NSString *)className;

/**
 * Returns YES if the action is defined on a category for the named class,
 * NO otherwise.
 */
- (BOOL) isAction: (NSString *)actionName  onCategoryForClassNamed: (NSString *)className;

/**
 * Returns the class name for the specified object.
 */
- (NSString *) classNameForObject: (id)object;

/**
 * Finds and returns the class name matching the specified name.
 */
- (NSString *) findClassByName: (NSString *)name;

/**
 * Returns the complete class information dictionary.
 */
- (NSDictionary *) classInformation;

/**
 * Returns a dictionary containing only custom class information.
 */
- (NSDictionary *) customClassInformation;

/**
 * Creates source and header files for the specified class at the given paths.
 * Returns YES on success, NO on failure.
 */
- (BOOL) makeSourceAndHeaderFilesForClass: (NSString *)className
				 withName: (NSString *)sourcePath
				      and: (NSString *)headerPath;

/**
 * Parses a header file and loads class information from it. Returns YES on
 * success, NO on failure.
 */
- (BOOL) parseHeader: (NSString *)headerPath;

/**
 * Saves class information to the specified file path. Returns YES on success,
 * NO on failure.
 */
- (BOOL) saveToFile: (NSString *)path;

/**
 * Returns the class information as serialized NSData.
 */
- (NSData *) data;

/**
 * Returns the class information as serialized NSData in nib format.
 */
- (NSData *) nibData;

/**
 * Loads class information from the specified file path. Returns YES on success,
 * NO on failure.
 */
- (BOOL) loadFromFile: (NSString *)path;

/**
 * Loads custom class information from the specified file path. Returns YES on
 * success, NO on failure.
 */
- (BOOL) loadCustomClasses: (NSString *)path;

/**
 * Loads custom class information from the specified NSData. Returns YES on
 * success, NO on failure.
 */
- (BOOL) loadCustomClassesWithData: (NSData *)data;

/**
 * Loads custom class information from the specified dictionary. Returns YES on
 * success, NO on failure.
 */
- (BOOL) loadCustomClassesWithDict: (NSDictionary *)dict;

/**
 * Loads custom class information from nib format NSData. Returns YES on success,
 * NO on failure.
 */
- (BOOL) loadNibFormatCustomClassesWithData: (NSData *)data;

/**
 * Loads custom class information from a nib format dictionary. Returns YES on
 * success, NO on failure.
 */
- (BOOL) loadNibFormatCustomClassesWithDict: (NSDictionary *)dict;

@end

#endif
