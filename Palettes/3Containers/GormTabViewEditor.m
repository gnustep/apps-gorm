/* GormTabViewEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Date:	2002
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <InterfaceBuilder/IBObjectAdditions.h>
#include <AppKit/AppKit.h>

#include <GormCore/GormPrivate.h>
#include <GormCore/GormViewKnobs.h>

#include "GormTabViewEditor.h"

#define _EO ((NSTabView *)_editedObject)

@implementation GormTabViewEditor

- (void) setOpened: (BOOL) flag
{
  [super setOpened: flag];
  if (flag == YES && currentView)
    {  
      [document setSelectionFromEditor: currentView];
    }
}

- (NSArray *) selection
{
  return [NSArray arrayWithObject: _EO];
}

- (BOOL) activate
{
  if ([super activate])
    {
      currentView = nil;
      [_EO setDelegate: self];
      [self 
	tabView: _EO
	didSelectTabViewItem: [_EO selectedTabViewItem]];
      return YES;
    }

  return NO;
}

- (void) deactivate
{
  if (activated == YES)
    {
      [self deactivateSubeditors];
      [_EO setDelegate: nil];
      [super deactivate];
    }
}



- (void) mouseDown: (NSEvent *) theEvent
{
  BOOL onKnob = NO;

  {
    if ([parent respondsToSelector: @selector(selection)] &&
	[[parent selection] containsObject: _EO])
      {
	IBKnobPosition	knob = IBNoneKnobPosition;
	NSPoint mouseDownPoint = 
	  [self convertPoint: [theEvent locationInWindow]
		fromView: nil];
	knob = GormKnobHitInRect([self bounds], 
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  onKnob = YES;
      }
    if (onKnob == YES)
      {
	if (parent)
	  return [parent mouseDown: theEvent];
	else
	  return [self noResponderFor: @selector(mouseDown:)];
      }
  }

  if (opened == NO)
    {
      [super mouseDown: theEvent];
      return;
    }

  if ([[_EO hitTest: [theEvent locationInWindow]]
	isDescendantOf: currentView])
    {
      NSDebugLog(@"md %@ descendant of", self);
      if ([currentView isOpened] == NO)
	[currentView setOpened: YES];
      [currentView mouseDown: theEvent];
    }
  else
    {      
      NSDebugLog(@"md %@ not descendant of", self);
      if ([currentView isOpened] == YES)
	[currentView setOpened: NO];
      [_EO mouseDown: theEvent];
    }
}


@end


@implementation GormTabViewEditor (TabViewDelegate)

- (void)       tabView: (NSTabView *)tabView 
  didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
  if ([tabViewItem view])
    {
      if ([[tabViewItem view] isKindOfClass: [GormViewEditor class]] == NO)
	{
	  currentView = (GormInternalViewEditor *)[document editorForObject: [tabViewItem view]
							    inEditor: self 
							    create: YES];
	  NSDebugLog(@"dSTVI %@ %@ %@", self, currentView, [tabViewItem view]);
	  NSDebugLog(@"dsTVI %@ %@", self, [document parentEditorForEditor: currentView]);
	}
      else
	{
	  NSDebugLog(@"dsTVI %@ already there", self);
	}
    }
}



- (BOOL)          tabView: (NSTabView *)tabView 
  shouldSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
  NSDebugLog(@"shouldSelectTabViewItem called");

  if ([[[tabView selectedTabViewItem] view] 
	isKindOfClass: 
	  [GormInternalViewEditor class]])
    {
      
      NSDebugLog(@"closing tabviewitem");
      [(GormInternalViewEditor *)[[tabView selectedTabViewItem] view] 
				 deactivate];
      currentView = nil;
      openedSubeditor = nil;
    }

  return YES;
}
@end
