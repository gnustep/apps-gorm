/* IBApplicationAdditions.h
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
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

#ifndef INCLUDED_IBAPPLICATIONADDITIONS_H
#define INCLUDED_IBAPPLICATIONADDITIONS_H

#include <InterfaceBuilder/IBDocuments.h>
#include <InterfaceBuilder/IBEditors.h>

extern NSString *IBWillBeginTestingInterfaceNotification;
extern NSString *IBDidBeginTestingInterfaceNotification;
extern NSString *IBWillEndTestingInterfaceNotification;
extern NSString *IBDidEndTestingInterfaceNotification;

@protocol IB <NSObject>
- (id<IBDocuments>) activeDocument;
- (BOOL) isTestingInterface;
- (id<IBSelectionOwners>) selectionOwner;
- (id) selectedObject;
@end

@interface NSApplication (GormSpecific)
- (NSImage *) linkImage;
- (void) startConnecting;
@end

#endif
