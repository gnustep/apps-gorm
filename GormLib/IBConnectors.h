/* Gorm.h
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
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

#ifndef INCLUDED_IBCONNECTORS_H
#define INCLUDED_IBCONNECTORS_H

#include <Foundation/NSObject.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSNibConnector.h>

// forward declarations
@class NSString;

extern NSString *IBWillAddConnectorNotification;
extern NSString *IBDidAddConnectorNotification;
extern NSString *IBWillRemoveConnectorNotification;
extern NSString *IBDidRemoveConnectorNotification;

/*
 * Connector objects are used to record connections between nib objects.
 */
@protocol IBConnectors <NSObject>
- (id) destination;
- (void) establishConnection;
- (NSString*) label;
- (void) replaceObject: (id)anObject withObject: (id)anotherObject;
- (id) source;
- (void) setDestination: (id)anObject;
- (void) setLabel: (NSString*)label;
- (void) setSource: (id)anObject;
- (id) nibInstantiate;
@end

@interface NSNibConnector (IBConnectorsProtocol) <IBConnectors>
@end

@interface NSObject (IBNibInstantiation)
- (id) nibInstantiate;
@end

@interface NSApplication (IBConnections)
/*
 * [NSApp -connectSource] returns the source object as set by the most recent
 * [NSApp -displayConnectionBetween:and:]
 */
- (id) connectSource;

/*
 * [NSApp -connectDestination] returns the target object as set by the most
 * recent [NSApp -displayConnectionBetween:and:]
 */
- (id) connectDestination;

/*
 * [NSApp -isConnecting] simply lets you know if a connection is in progress.
 */
- (BOOL) isConnecting;

/*
 * [NSApp -stopConnecting] terminates the current connection process and
 * removes the connection marks from the display.
 */
- (void) stopConnecting;

/*
 * [NSApp -displayConnectionBetween:and:] is used to set the source and target
 * objects and mark the display appropriately.  Setting either source or
 * target to 'nil' will remove markup from any previous source or target.
 * NB. This method expects to be able to call the active document to ask it
 * for the window and rectangle in which to perform markup.
 */
- (void) displayConnectionBetween: (id)source and: (id)destination;
@end

#endif
