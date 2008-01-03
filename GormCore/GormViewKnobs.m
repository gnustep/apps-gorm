/* 
   GormViewKnobs.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decimax.com>
   Date: 1999
   Modified and extended by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
   This file is part of the GNUstep Interface Modeller Application.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "GormViewKnobs.h"
#include <math.h>

static int KNOB_WIDTH = 0.0;
static int KNOB_HEIGHT = 0.0;

#define MINSIZE 5.0

static NSRect	*blackRectList	= NULL;
static int	blackRectSize	= 0;
static int	blackRectCount	= 0;
static NSRect	*dkgrayRectList	= NULL;
static int	dkgrayRectSize	= 0;
static int	dkgrayRectCount	= 0;

static void _fastKnobFill(NSRect aRect,BOOL isBlack);
static void _drawKnobsForRect(NSRect aRect,BOOL isBlack);

static void
calcKnobSize(void)
{
  NSString	*value;
  float		w = 2.0;
  float		h = 2.0;

  value = [[NSUserDefaults standardUserDefaults] objectForKey: @"KnobWidth"];
  if (value != nil)
    {
      w = floor([value floatValue] / 2.0);
    }
  value = [[NSUserDefaults standardUserDefaults] objectForKey: @"KnobHeight"];
  if (value != nil)
    {
      h = floor([value floatValue] / 2.0);
    }
  w = MAX(w, 1.0);
  h = MAX(h, 1.0);
  KNOB_WIDTH = w * 2.0 + 1.0; // Size must be odd */
  KNOB_HEIGHT = h * 2.0 + 1.0;
}

void
GormShowFastKnobFills(void)
{
  if (blackRectCount)
    {
      PSsetgray(NSBlack);
      NSRectFillList(blackRectList, blackRectCount);
    }
  if (dkgrayRectCount)
    {
      PSsetrgbcolor(1,0,0);
      NSRectFillList(dkgrayRectList, dkgrayRectCount);
    }
  blackRectCount = 0;
  dkgrayRectCount = 0;
}

static void
_showLitKnobForRect(NSGraphicsContext *ctxt, NSRect frame, IBKnobPosition aKnob)
{
  float		dx, dy;
  BOOL		oddx, oddy;
  NSRect	r;

  if (!KNOB_WIDTH)
    {
      calcKnobSize();
    }
  dx = NSWidth(frame) / 2.0;
  dy = NSHeight(frame) / 2.0;
  oddx = (floor(dx) != dx);
  oddy = (floor(dy) != dy);
  frame.size.width = KNOB_WIDTH;
  frame.size.height = KNOB_HEIGHT;
  frame.origin.x -= ((KNOB_WIDTH - 1.0) / 2.0);
  frame.origin.y -= ((KNOB_HEIGHT - 1.0) / 2.0);

  if (aKnob == IBBottomLeftKnobPosition)
    r = frame;
  frame.origin.y += dy;
  if (oddy)
    frame.origin.y -= 0.5;
  if (aKnob == IBMiddleLeftKnobPosition)
    r = frame;
  frame.origin.y += dy;
  if (oddy)
    frame.origin.y += 0.5;
  if (aKnob == IBTopLeftKnobPosition)
    r = frame;
  frame.origin.x += dx;
  if (oddx)
   frame.origin.x -= 0.5;
  if (aKnob == IBTopMiddleKnobPosition)
    r = frame;
  frame.origin.x += dx;
  if (oddx)
    frame.origin.x += 0.5;
  if (aKnob == IBTopRightKnobPosition)
    r = frame;
  frame.origin.y -= dy;
  if (oddy)
    frame.origin.y -= 0.5;
  if (aKnob == IBMiddleRightKnobPosition)
    r = frame;
  frame.origin.y -= dy;
  if (oddy)
    frame.origin.y += 0.5;
  if (aKnob == IBBottomRightKnobPosition)
    r = frame;
  frame.origin.x -= dx;
  if (oddx)
    frame.origin.x += 0.5;
  if (aKnob == IBBottomMiddleKnobPosition)
    r = frame;

  r.origin.x += 1.0;
  r.origin.y -= 1.0;
  DPSsetgray(ctxt, NSBlack);
  DPSrectfill(ctxt, NSMinX(r), NSMinY(r), NSWidth(r), NSHeight(r));
  r.origin.x -= 1.0;
  r.origin.y += 1.0;
  DPSsetgray(ctxt, NSWhite);
  DPSrectfill(ctxt, NSMinX(r), NSMinY(r), NSWidth(r), NSHeight(r));
}

void
GormShowFrameWithKnob(NSRect aRect, IBKnobPosition aKnob)
{
  NSGraphicsContext	*ctxt = [NSGraphicsContext currentContext];
  NSRect		 r = aRect;

  /*
   * We draw a wire-frame around the rectangle.
   */
  r.origin.x -= 0.5;
  r.origin.y -= 0.5;
  r.size.width += 1.0;
  r.size.height += 1.0;
  DPSsetgray(ctxt, NSBlack);
  DPSmoveto(ctxt, NSMinX(r), NSMinY(r));
  DPSlineto(ctxt, NSMinX(r), NSMaxY(r));
  DPSlineto(ctxt, NSMaxX(r), NSMaxY(r));
  DPSlineto(ctxt, NSMaxX(r), NSMinY(r));
  DPSlineto(ctxt, NSMinX(r), NSMinY(r));
  DPSstroke(ctxt);

  if (aKnob != IBNoneKnobPosition)
    {
      /*
       * NB. we use the internal rectangle for calculating the knob position.
       */
      _showLitKnobForRect(ctxt, aRect, aKnob);
    }
}

void
GormDrawKnobsForRect(NSRect aRect)
{
  NSRect	r;

  r.origin.x = floor(NSMinX(aRect));
  r.origin.y = floor(NSMinY(aRect));
  r.size.width = floor(NSMaxX(aRect) + 0.99) - NSMinX(r);
  r.size.height = floor(NSMaxY(aRect) + 0.99) - NSMinY(r);
  r.origin.x += 1.0;
  r.origin.y -= 1.0;
  _drawKnobsForRect(r, YES);
  r.origin.x = floor(NSMinX(aRect));
  r.origin.y = floor(NSMinY(aRect));
  r.size.width = floor(NSMaxX(aRect) + 0.99) - NSMinX(r);
  r.size.height = floor(NSMaxY(aRect) + 0.99) - NSMinY(r);
  _drawKnobsForRect(r, NO);
}

/* Draw these around an NSBox whose contents are being edited.
*/
void
GormDrawOpenKnobsForRect(NSRect aRect)
{
  NSRect	r;

  r.origin.x = floor(NSMinX(aRect));
  r.origin.y = floor(NSMinY(aRect));
  r.size.width = floor(NSMaxX(aRect) + 0.99) - NSMinX(r);
  r.size.height = floor(NSMaxY(aRect) + 0.99) - NSMinY(r);
  _drawKnobsForRect(r, YES);
}

IBKnobPosition
GormKnobHitInRect(NSRect aFrame, NSPoint p)
{
  NSRect	eb;
  NSRect	knob;
  float		dx, dy;
  BOOL		oddx, oddy;

  eb = GormExtBoundsForRect(aFrame);

  if (!NSMouseInRect(p, eb, NO))
    {
      return IBNoneKnobPosition;
    }
  knob = aFrame;
  dx = NSWidth(knob) / 2.0;
  dy = NSHeight(knob) / 2.0;
  oddx = (floor(dx) != dx);
  oddy = (floor(dy) != dy);
  knob.size.width = KNOB_WIDTH;
  knob.size.height = KNOB_HEIGHT;
  knob.origin.x -= ((KNOB_WIDTH - 1.0) / 2.0);
  knob.origin.y -= ((KNOB_HEIGHT - 1.0) / 2.0);

  if (NSMouseInRect(p, knob, NO))
    {
      return(IBBottomLeftKnobPosition);
    }
  knob.origin.y += dy;
  if (oddy)
    {
      knob.origin.y -= 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBMiddleLeftKnobPosition);
    }
  knob.origin.y += dy;
  if (oddy)
    {
      knob.origin.y += 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBTopLeftKnobPosition);
    }
  knob.origin.x += dx;
  if (oddx)
    {
      knob.origin.x -= 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBTopMiddleKnobPosition);
    }
  knob.origin.x += dx;
  if (oddx)
    {
      knob.origin.x += 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBTopRightKnobPosition);
    }
  knob.origin.y -= dy;
  if (oddy)
    {
      knob.origin.y -= 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBMiddleRightKnobPosition);
    }
  knob.origin.y -= dy;
  if (oddy)
    {
      knob.origin.y += 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBBottomRightKnobPosition);
    }
  knob.origin.x -= dx;
  if (oddx)
    {
      knob.origin.x += 0.5;
    }
  if (NSMouseInRect(p, knob, NO))
    {
      return(IBBottomMiddleKnobPosition);
    }

  return IBNoneKnobPosition;
}

NSRect
GormExtBoundsForRect(NSRect aRect)
{
  NSRect returnRect;
    
  if (NSWidth(aRect) < 0.0)
    {
      returnRect.origin.x = NSMaxX(aRect);
      returnRect.size.width = - NSWidth(aRect);
    }
   else
    {
      returnRect.origin.x = NSMinX(aRect);
      returnRect.size.width = NSWidth(aRect);
    }
   if (aRect.size.height < 0.0)
    {
      returnRect.origin.y = NSMaxY(aRect);
      returnRect.size.height = - NSHeight(aRect);
    }
   else
    {
      returnRect.origin.y = NSMinY(aRect);
      returnRect.size.height = NSHeight(aRect);
    }

  returnRect.size.width = MAX(1.0, NSWidth(returnRect));
  returnRect.size.height = MAX(1.0, NSHeight(returnRect));

  returnRect = NSInsetRect(returnRect, 
    - ((KNOB_WIDTH - 1.0) + 1.0), - ((KNOB_HEIGHT - 1.0) + 1.0));

  return NSIntegralRect(returnRect);
}

static void
_fastKnobFill(NSRect aRect, BOOL isBlack)
{
  if (isBlack)
    {
      if (!blackRectList)
	{
	   blackRectSize = 16;
	   blackRectList = NSZoneMalloc(NSDefaultMallocZone(), 
	     blackRectSize * sizeof(NSRect));
	}
      else
	{
	  while (blackRectCount >= blackRectSize)
	    {
	      blackRectSize <<= 1;
	    }
	  blackRectList = NSZoneRealloc(NSDefaultMallocZone(), blackRectList, 
	    blackRectSize * sizeof(NSRect));
        }
      blackRectList[blackRectCount++] = aRect;
    }
  else
    {
      if (!dkgrayRectList)
	{
	  dkgrayRectSize = 16;
	  dkgrayRectList = NSZoneMalloc(NSDefaultMallocZone(), 
	    dkgrayRectSize * sizeof(NSRect));
	}
      else
	{
	  while (dkgrayRectCount >= dkgrayRectSize)
	    {
	      dkgrayRectSize <<= 1;
	    }
	  dkgrayRectList = NSZoneRealloc(NSDefaultMallocZone(), dkgrayRectList, 
	    dkgrayRectSize * sizeof(NSRect));
	}
      dkgrayRectList[dkgrayRectCount++] = aRect;
    }
}

static void
_drawKnobsForRect(NSRect knob, BOOL isBlack)
{
  float		dx, dy;
  BOOL		oddx, oddy;

  if (!KNOB_WIDTH)
    {
      calcKnobSize();
    }
  dx = NSWidth(knob) / 2.0;
  dy = NSHeight(knob) / 2.0;
  oddx = (floor(dx) != dx);
  oddy = (floor(dy) != dy);
  knob.size.width = KNOB_WIDTH;
  knob.size.height = KNOB_HEIGHT;
  knob.origin.x -= ((KNOB_WIDTH - 1.0) / 2.0);
  knob.origin.y -= ((KNOB_HEIGHT - 1.0) / 2.0);

  _fastKnobFill(knob, isBlack);
  knob.origin.y += dy;
  if (oddy)
    {
      knob.origin.y -= 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.y += dy;
  if (oddy)
    {
      knob.origin.y += 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.x += dx;
  if (oddx)
    {
     knob.origin.x -= 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.x += dx;
  if (oddx)
    {
      knob.origin.x += 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.y -= dy;
  if (oddy)
    {
      knob.origin.y -= 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.y -= dy;
  if (oddy)
    {
      knob.origin.y += 0.5;
    }
  _fastKnobFill(knob, isBlack);
  knob.origin.x -= dx;
  if (oddx)
    {
      knob.origin.x += 0.5;
    }
  _fastKnobFill(knob, isBlack);
}

