/** <title>GormNSMenuView</title>

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: 2007
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GormNSMenuView.h"

@interface NSMenuView (GormNSMenuViewPrivate)
- (id) itemsLink;
@end

@implementation NSMenuView (GormNSMenuViewPrivate)
- (id) itemsLink
{
  return _items_link;
}
@end

@implementation GormNSMenuView

- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  NSRect frame = [_window frame];
  NSRect submenuFrame;

  if (_needsSizing)
    [self sizeToFit];

  if (aSubmenu)
    submenuFrame = [[[aSubmenu menuRepresentation] window] frame];
  else
    submenuFrame = NSZeroRect;

  return NSMakePoint(NSMaxX(frame),
		     NSMaxY(frame) - NSHeight(submenuFrame));

}

#define MOVE_THRESHOLD_DELTA 2.0
#define DELAY_MULTIPLIER     10

- (BOOL) trackWithEvent: (NSEvent*)event
{
  unsigned	eventMask = NSPeriodicMask;
  NSDate        *theDistantFuture = [NSDate distantFuture];
  NSPoint	lastLocation = {0,0};
  BOOL		justAttachedNewSubmenu = NO;
  BOOL          subMenusNeedRemoving = YES;
  BOOL		shouldFinish = YES;
  int		delayCount = 0;
  int           indexOfActionToExecute = -1;
  int		firstIndex = -1;
  NSEvent	*original;
  NSEventType	type;
  NSEventType	end;

  /*
   * The original event is unused except to determine whether the method
   * was invoked in response to a right or left mouse down.
   * We pass the same event on when we want tracking to move into a
   * submenu.
   */
  original = AUTORELEASE(RETAIN(event));

  type = [event type];

  if (type == NSRightMouseDown || type == NSRightMouseDragged)
    {
      end = NSRightMouseUp;
      eventMask |= NSRightMouseUpMask | NSRightMouseDraggedMask;
      eventMask |= NSRightMouseDownMask;
    }
  else if (type == NSOtherMouseDown || type == NSOtherMouseDragged)
    {
      end = NSOtherMouseUp;
      eventMask |= NSOtherMouseUpMask | NSOtherMouseDraggedMask;
      eventMask |= NSOtherMouseDownMask;
    }
  else if (type == NSLeftMouseDown || type == NSLeftMouseDragged)
    {
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
      eventMask |= NSLeftMouseDownMask;
    }
  else
    {
      NSLog (@"Unexpected event: %d during event tracking in NSMenuView", type);
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
      eventMask |= NSLeftMouseDownMask;
    }

  if ([self isHorizontal] == YES)
    {
      /*
       * Ignore the first mouse up if nothing interesting has happened.
       */
      shouldFinish = NO;
    }
  do
    {
      if (type == end)
        {
	  shouldFinish = YES;
        }
      if (type == NSPeriodic || event == original)
        {
          NSPoint	location;
          int           index;

          location     = [_window mouseLocationOutsideOfEventStream];
          index        = [self indexOfItemAtPoint: location];

	  if (event == original)
	    {
	      firstIndex = index;
	    }
	  if (index != firstIndex)
	    {
	      shouldFinish = YES;
	    }

          /*
           * 1 - if menus is only partly visible and the mouse is at the
           *     edge of the screen we move the menu so it will be visible.
           */ 
          if ([[self attachedMenu] isPartlyOffScreen])
            {
              NSPoint pointerLoc = [_window convertBaseToScreen: location];
              /*
               * The +/-1 in the y - direction is because the flipping
               * between X-coordinates and GNUstep coordinates let the
               * GNUstep screen coordinates start with 1.
               */
              if (pointerLoc.x == 0 || pointerLoc.y == 1
		|| pointerLoc.x == [[_window screen] frame].size.width - 1
		|| pointerLoc.y == [[_window screen] frame].size.height)
                [[self attachedMenu] shiftOnScreen];
            }


          /*
           * 2 - Check if we have to reset the justAttachedNewSubmenu
           * flag to NO.
           */
          if (justAttachedNewSubmenu && index != -1
	    && index != _highlightedItemIndex)
            { 
              if (location.x - lastLocation.x > MOVE_THRESHOLD_DELTA)
                {
                  delayCount ++;
                  if (delayCount >= DELAY_MULTIPLIER)
                    {
                      justAttachedNewSubmenu = NO;
                    }
                }
              else
                {
                  justAttachedNewSubmenu = NO;
                }
            }


          // 3 - If we have moved outside this menu, take appropriate action
          if (index == -1)
            {
              NSPoint   locationInScreenCoordinates;
              NSWindow *windowUnderMouse;
              NSMenu   *candidateMenu;

              subMenusNeedRemoving = NO;

              locationInScreenCoordinates
                = [_window convertBaseToScreen: location];

              /*
               * 3a - Check if moved into one of the ancester menus.
               *      This is tricky, there are a few possibilities:
               *          We are a transient attached menu of a
               *          non-transient menu
               *          We are a non-transient attached menu
               *          We are a root: isTornOff of AppMenu
               */
              candidateMenu = [[self attachedMenu] supermenu];
              while (candidateMenu  
		&& !NSMouseInRect (locationInScreenCoordinates, 
		  [[candidateMenu window] frame], NO) // not found yet
		&& (! ([candidateMenu isTornOff] 
		  && ![candidateMenu isTransient]))  // no root of display tree
		&& [candidateMenu isAttached]) // has displayed parent
                {
                  candidateMenu = [candidateMenu supermenu];
                }

              if (candidateMenu != nil
		&& NSMouseInRect (locationInScreenCoordinates,
		  [[candidateMenu window] frame], NO))
                {
		  BOOL	candidateMenuResult;

                  // The call to fetch attachedMenu is not needed. But putting
                  // it here avoids flicker when we go back to an ancestor 
		  // menu and the attached menu is already correct.
                  [[[candidateMenu attachedMenu] menuRepresentation]
                    detachSubmenu];
                  
                  // Reset highlighted index for this menu.
                  // This way if we return to this submenu later there 
                  // won't be a highlighted item.
                  [[[candidateMenu attachedMenu] menuRepresentation]
                    setHighlightedItemIndex: -1];
                  
                  candidateMenuResult = [[candidateMenu menuRepresentation]
                           trackWithEvent: original];
		  return candidateMenuResult;
                }

              // 3b - Check if we enter the attached submenu
              windowUnderMouse = [[[self attachedMenu] attachedMenu] window];
              if (windowUnderMouse != nil
		&& NSMouseInRect (locationInScreenCoordinates,
		  [windowUnderMouse frame], NO))
                {
                  BOOL wasTransient = [[self attachedMenu] isTransient];
                  BOOL subMenuResult;

                  subMenuResult
                    = [[self attachedMenuView] trackWithEvent: original];
                  if (subMenuResult
		    && wasTransient == [[self attachedMenu] isTransient])
                    {
                      [self detachSubmenu];
                    }
                  return subMenuResult;
                }
            }

          // 4 - We changed the selected item and should update.
          if (!justAttachedNewSubmenu && index != _highlightedItemIndex)
            {
              subMenusNeedRemoving = NO;
              [self detachSubmenu];
              [self setHighlightedItemIndex: index];

              // WO: Question?  Why the ivar _items_link
              if (index >= 0 && [[[self itemsLink] objectAtIndex: index] submenu])
                {
                  [self attachSubmenuForItemAtIndex: index];
                  justAttachedNewSubmenu = YES;
                  delayCount = 0;
                }
            }

          // Update last seen location for the justAttachedNewSubmenu logic.
          lastLocation = location;
        }

      event = [NSApp nextEventMatchingMask: eventMask
        untilDate: theDistantFuture
        inMode: NSEventTrackingRunLoopMode
        dequeue: YES];
      type = [event type];
    }
  while (type != end || shouldFinish == NO);

  /*
   * Ok, we released the mouse
   * There are now a few possibilities:
   * A - We released the mouse outside the menu.
   *     Then we want the situation as it was before
   *     we entered everything.
   * B - We released the mouse on a submenu item
   *     (i) - this was highlighted before we started clicking:
   *           Remove attached menus
   *     (ii) - this was not highlighted before pressed the mouse button;
   *            Keep attached menus.
   * C - We released the mouse above an ordinary action:
   *     Execute the action.
   *
   *  In case A, B and C we want the transient menus to be removed
   *  In case A and C we want to remove the menus that were created
   *  during the dragging.
   *
   *  So we should do the following things:
   * 
   * 1 - Stop periodic events,
   * 2 - Determine the action.
   * 3 - Remove the Transient menus from the screen.
   * 4 - Perform the action if there is one.
   */

  [NSEvent stopPeriodicEvents];

  /*
   * We need to store this, because _highlightedItemIndex
   * will not be valid after we removed this menu from the screen.
   */
  indexOfActionToExecute = _highlightedItemIndex;

  // remove transient menus. --------------------------------------------
    {
      NSMenu *currentMenu = [self attachedMenu];

      while (currentMenu && ![currentMenu isTransient])
        {
          currentMenu = [currentMenu attachedMenu];
        }

      while ([currentMenu isTransient] && [currentMenu supermenu])
        {
          currentMenu = [currentMenu supermenu];
        }

      [[currentMenu menuRepresentation] detachSubmenu];

      if ([currentMenu isTransient])
        {
          [currentMenu closeTransient];
        }
    }

  // ---------------------------------------------------------------------
  if (indexOfActionToExecute == -1)
    {
      return YES;
    }

  if (indexOfActionToExecute >= 0
    && [[self attachedMenu] attachedMenu] != nil && [[self attachedMenu] attachedMenu] ==
    [[[self itemsLink] objectAtIndex: indexOfActionToExecute] submenu])
    {
      if (subMenusNeedRemoving)
        {
          [self detachSubmenu];
        }
      // Clicked on a submenu.
      return NO;
    }

  [[self attachedMenu] performActionForItemAtIndex: indexOfActionToExecute];

  /*
   * Remove highlighting.
   * We first check if it still highlighted because it could be the
   * case that we choose an action in a transient window which
   * has already dissappeared.  
   */
  if (_highlightedItemIndex >= 0)
    {
      [self setHighlightedItemIndex: -1];
    }
  return YES;
}
@end

