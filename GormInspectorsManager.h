/* GormInspectorsManager.h
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

#ifndef INCLUDED_GormInspectorsManager_h
#define INCLUDED_GormInspectorsManager_h

#include <Foundation/NSObject.h>

@class NSPanel;
@class NSMutableDictionary;
@class NSPopUpButton;
@class NSView;
@class IBInspector;

@interface GormInspectorsManager : NSObject
{
  NSPanel		*panel;
  NSMutableDictionary	*cache;
  NSPopUpButton		*popup;
  NSView		*selectionView;
  NSView		*inspectorView;
  NSView		*buttonView;
  NSString		*oldInspector;
  IBInspector		*inspector;
  int			current;
  BOOL			hiddenDuringTest;
}
- (NSPanel*) panel;
- (void) setClassInspector;
- (void) setEmptyInspector;
- (void) setCurrentInspector: (id)anObject;
- (void) updateSelection;
@end

#endif
