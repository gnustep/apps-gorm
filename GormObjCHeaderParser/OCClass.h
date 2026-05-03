/* OCHeaderParser.h
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
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
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <Foundation/Foundation.h>

#ifndef INCLUDED_OCClass_h
#define INCLUDED_OCClass_h

@class NSMutableArray, NSString;

/**
 * OCClass provides OCClass class or protocol.
 */
@interface OCClass : NSObject
{
  NSMutableArray        *_ivars;
  NSMutableArray        *_methods;
  NSMutableArray        *_protocols;
  NSMutableArray        *_properties;
  NSString              *_className;
  NSString              *_superClassName;
  NSString              *_classString;
  BOOL                   _isCategory;
}

/**
 * Initializes and returns a new instance.
 */
- (id) initWithString: (NSString *)string;
/**
 * Returns the methods.
 */
- (NSArray *) methods;
/**
 * Adds an object to the collection.
 */
- (void) addMethod: (NSString *)name isAction: (BOOL)flag;
/**
 * Returns the ivars.
 */
- (NSArray *) ivars;
/**
 * Adds an object to the collection.
 */
- (void) addIVar: (NSString *)name isOutlet: (BOOL)flag;
/**
 * Returns the className.
 */
- (NSString *) className;
/**
 * Sets the property value.
 */
- (void) setClassName: (NSString *)name;
/**
 * Returns the superClassName.
 */
- (NSString *) superClassName;
/**
 * Sets the property value.
 */
- (void) setSuperClassName: (NSString *)name;
/**
 * Returns YES if the condition is true, NO otherwise.
 */
- (BOOL) isCategory;
/**
 * Sets the property value.
 */
- (void) setIsCategory: (BOOL)flag;
/**
 * Returns the properties.
 */
- (NSArray *) properties;

/**
 * Returns the parse.
 */
- (void) parse;

@end

#endif
