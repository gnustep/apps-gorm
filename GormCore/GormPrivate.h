/* GormPrivate.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
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

#ifndef INCLUDED_GormPrivate_h
#define INCLUDED_GormPrivate_h

#include <InterfaceBuilder/InterfaceBuilder.h>

#include <GNUstepGUI/GSGormLoading.h>
#include <GNUstepGUI/GSNibLoading.h>

#include <GormCore/GormFilesOwner.h>
#include <GormCore/GormDocument.h>
#include <GormCore/GormInspectorsManager.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormPalettesManager.h>
#include <GormCore/GormProtocol.h>
#include <GormCore/GormClassEditor.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattributes"
extern NSString *GormLinkPboardType;
extern NSString *GormToggleGuidelineNotification;
extern NSString *GormDidModifyClassNotification;
extern NSString *GormDidAddClassNotification;
extern NSString *GormDidDeleteClassNotification;
extern NSString *GormWillDetachObjectFromDocumentNotification;
extern NSString *GormDidDetachObjectFromDocumentNotification;
extern NSString *GormResizeCellNotification;
#pragma GCC diagnostic pop

@class	GormDocument;
@class	GormInspectorsManager;
@class	GormPalettesManager;

// templates
/**
 * Adds convenience initializers used by Gorm to create template nib items
 * with a particular class name (and optional frame) for archiving.
 */
@interface GSNibItem (GormAdditions)
/**
 * Initialize a template item with the specified class name.
 */
- (id) initWithClassName: (NSString*)className;
/**
 * Initialize a template item with the specified class name and frame.
 */
- (id) initWithClassName: (NSString*)className frame: (NSRect)frame;
/**
 * The name of the class to instantiate when unarchiving.
 */
- (NSString*) className;
@end

/**
 * Extend GSClassSwapper with a flag indicating Interface Builder context so
 * components can adapt behavior while edited in Gorm.
 */
@interface GSClassSwapper (GormCustomClassAdditions)
/**
 * Set whether code is currently running under Interface Builder.
 */
+ (void) setIsInInterfaceBuilder: (BOOL)flag;
/**
 * Return whether this instance is considered to be in Interface Builder.
 */
- (BOOL) isInInterfaceBuilder;
@end

/**
 * Extend NSClassSwapper with a flag indicating Interface Builder context so
 * components can adapt behavior while edited in Gorm.
 */
@interface NSClassSwapper (GormCustomClassAdditions)
/**
 * Set whether code is currently running under Interface Builder.
 */
+ (void) setIsInInterfaceBuilder: (BOOL)flag;
/**
 * Return whether this instance is considered to be in Interface Builder.
 */
- (BOOL) isInInterfaceBuilder;
@end

/**
 * GormObjectProxy is used in Gorm documents but encodes as a GSNibItem when
 * archived. This allows Gorm to control instantiation at load time.
 */
@interface GormObjectProxy : GSNibItem 
/*
 * Use a GormObjectProxy in Gorm, but encode a GSNibItem in the archive.
 * This is done so that we can provide our own decoding method
 * (GSNibItem tries to morph into the actual class)
 */
@end

/**
 * GormClassProxy is a lightweight holder for class-related names used by
 * inspectors for a given class.
 */
@interface GormClassProxy : NSObject
{
  NSString *name;
  NSInteger t;
}

 initWithClassName: (NSString*)n;
/**
 * The base class name represented by this proxy.
 */
- (NSString*) className;
/**
 * The class name of the main inspector for this class.
 */
- (NSString*) inspectorClassName;
/**
 * The class name of the connections inspector for this class.
 */
- (NSString*) connectInspectorClassName;
/**
 * The class name of the size inspector for this class.
 */
- (NSString*) sizeInspectorClassName;
@end

/*
 * NSDateFormatter and NSNumberFormatter extensions
 * for Gorm Formatters used in the Data Palette
 */

@interface NSDateFormatter (GormAdditions)

/**
 * Return the number of predefined date format strings available in Gorm.
 */
+ (int) formatCount;
/**
 * Return the date format string at the specified index.
 */
+ (NSString *) formatAtIndex: (int)index;
/**
 * Return the index for the given date format string, or NSNotFound if absent.
 */
+ (NSInteger) indexOfFormat: (NSString *) format;
/**
 * Return the default date format string used by the Data palette.
 */
+ (NSString *) defaultFormat;
/**
 * Return a default value suitable for previewing the default date format.
 */
+ (id) defaultFormatValue;

@end

/**
 * Extend NSNumberFormatter with predefined formats and sample values used by
 * the Data palette (positive, zero, and negative representations).
 */
@interface NSNumberFormatter (GormAdditions)

/**
 * Return the number of predefined number formats available in Gorm.
 */
+ (int) formatCount;
/**
 * Return a generic number format string at the specified index.
 */
+ (NSString *) formatAtIndex: (int)index;
/**
 * Return the positive number format string at the specified index.
 */
+ (NSString *) positiveFormatAtIndex: (int)index;
/**
 * Return the zero number format string at the specified index.
 */
+ (NSString *) zeroFormatAtIndex: (int)index;
/**
 * Return the negative number format string at the specified index.
 */
+ (NSString *) negativeFormatAtIndex: (int)index;
/**
 * Return a sample positive value for the format at the specified index.
 */
+ (NSDecimalNumber *) positiveValueAtIndex: (int)index;
/**
 * Return a sample negative value for the format at the specified index.
 */
+ (NSDecimalNumber *) negativeValueAtIndex: (int)index;
/**
 * Return the index of the given number format string, or NSNotFound if absent.
 */
+ (NSInteger) indexOfFormat: (NSString *)format;
/**
 * Return the default number format string used by the Data palette.
 */
+ (NSString *) defaultFormat;
/**
 * Return a default value suitable for previewing the default number format.
 */
+ (id) defaultFormatValue;
/**
 * Return the format string used by this formatter when formatting zero.
 */
- (NSString *) zeroFormat;

@end

/**
 * Add helpers used by Gorm at design time for object substitution and
 * representation in browsers.
 */
@interface NSObject (GormAdditions)
/**
 * Return a substitute instance used during design time instead of allocating
 * a real runtime object.
 */
- (id) allocSubstitute;
/**
 * Return an image representation for display in object viewers.
 */
- (NSImage *) imageForViewer;
@end

/**
 * Add a convenience for registering all pasteboard types used by an editor in
 * the context of a document, to support drag and drop.
 */
@interface IBResourceManager (GormAdditions)
/**
 * Register all known pasteboard types for the given editor within the
 * specified document.
 */
+ (void) registerForAllPboardTypes: (id)editor
                        inDocument: (id)document;
@end

#endif
