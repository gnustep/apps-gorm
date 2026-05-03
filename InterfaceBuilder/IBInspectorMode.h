/* IBInspectorMode
 *
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2004
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef IBINSPECTORMODE_H
#define IBINSPECTORMODE_H

#include <Foundation/Foundation.h>

@class NSString;

/**
 * IBInspectorMode describes a single inspector mode tab for a given object,
 * including an identifier, localized label, the inspector class to use, and
 * an ordering value to control presentation.
 */
@interface IBInspectorMode : NSObject
{
  NSString *identifier;
  NSString *localizedLabel;
  NSString *inspectorClassName;
  id object;
  float ordering;
}
/**
 * Designated initializer: configure with id, inspected object, localized
 * label, inspector class name, and ordering.
 */
- (id) initWithIdentifier: (NSString *)ident
                forObject: (id)obj
           localizedLabel: (NSString *)lab
       inspectorClassName: (NSString *)cn
		 ordering: (float)ord;
/**
 * Set the unique identifier for the inspector mode.
 */
- (void) setIdentifier: (NSString *)ident;
/**
 * The unique identifier for this inspector mode.
 */
- (NSString *) identifier;
/**
 * Set the object this inspector mode applies to.
 */
- (void) setObject: (id)obj;
/**
 * The object this mode inspects.
 */
- (id) object;
/**
 * Set the localized label used to display the mode.
 */
- (void) setLocalizedLabel: (NSString *)label;
/**
 * The localized title displayed for the mode.
 */
- (NSString *) localizedLabel;
/**
 * Set the name of the inspector class used to implement this mode.
 */
- (void) setInspectorClassName: (NSString *)className;
/**
 * The class name of the inspector used for this mode.
 */
- (NSString *) inspectorClassName;
/**
 * Set the ordering weight controlling the position of this mode.
 */
- (void) setOrdering: (float)ord;
/**
 * The ordering weight used to sort modes.
 */
- (float) ordering;
@end

#endif
