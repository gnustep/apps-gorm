/* GormButtonEditor.m
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
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <AppKit/AppKit.h>

#include "GormPrivate.h"

#import "GormButtonEditor.h"

#import "GormViewWithSubviewsEditor.h"

#define _EO ((NSButton *)_editedObject)

@implementation NSButton (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormButtonEditor";
}
@end

@interface NSButtonCell (GormObjectAdditions)
- (NSRect) gormTitleRectForFrame: (NSRect) cellFrame
			  inView: (NSView *)controlView;
@end
@implementation NSButtonCell (GormObjectAdditions)
- (NSRect) gormTitleRectForFrame: (NSRect) cellFrame
			  inView: (NSView *)controlView
{
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSRect	imageRect;
  NSString	*titleToDisplay;
  NSRect	titleRect;
  NSSize	imageSize = {0, 0};
  NSSize        titleSize = {0, 0};
  NSColor	*backgroundColor = nil;
  BOOL		flippedView = [controlView isFlipped];
  NSCellImagePosition ipos = _cell.image_position;

//    // transparent buttons never draw
//    if (_buttoncell_is_transparent)
//      return;

  cellFrame = [self drawingRectForBounds: cellFrame];

  if (_cell.is_highlighted)
    {
      mask = _highlightsByMask;

      if (_cell.state)
	mask &= ~_showAltStateMask;
    }
  else if (_cell.state)
    mask = _showAltStateMask;
  else
    mask = NSNoCellMask;

  /* Pushed in buttons contents are displaced to the bottom right 1px.  */
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., flippedView ? 1. : -1.);
    }

  /* Determine the background color. */
  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      backgroundColor = [NSColor selectedControlColor];
    }

  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  /* Draw the cell's background color.  
     We draw when there is a border or when highlightsByMask
     is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
     as required by our nextstep-like look and feel.  */
  if (_cell.is_bordered 
      || (_highlightsByMask & NSChangeBackgroundCellMask)
      || (_highlightsByMask & NSChangeGrayCellMask))
    {
//        [backgroundColor set];
//        NSRectFill (cellFrame);
    }

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   */
  if (mask & NSContentsCellMask)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
	imageToDisplay = _cell_image;
      titleToDisplay = _altContents;
      if (titleToDisplay == nil || [titleToDisplay isEqual: @""])
        titleToDisplay = _contents;
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = _contents;
    }

  if (imageToDisplay)
    {
      /* FIXME - the following is a hack!  Because we don't seem to be
	 getting alpha composing of images right, we use this hack of
	 hard-setting manually the background color of the image to
	 the wanted background color ... this should go away when
	 alpha composing of images works 100%.  */
//        [imageToDisplay setBackgroundColor: backgroundColor];
      imageSize = [imageToDisplay size];
    }

//    if (titleToDisplay && (ipos == NSImageAbove || ipos == NSImageBelow))
//      {
      titleSize = [self _sizeText: titleToDisplay];
//      }

  if (flippedView == YES)
    {
      if (ipos == NSImageAbove)
	{
	  ipos = NSImageBelow;
	}
      else if (ipos == NSImageBelow)
	{
	  ipos = NSImageAbove;
	}
    }
  
  switch (ipos)
    {
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	{
	  int heightDiff = titleRect.size.height - titleSize.height;
	  titleRect.origin.y += heightDiff - heightDiff / 2;
	  titleRect.size.height -= heightDiff;
	}
	break;

      case NSImageOnly: 
	titleToDisplay = nil;
	imageRect = cellFrame;
	break;

      case NSImageLeft: 
	imageRect.origin = cellFrame.origin;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x += 3;
	    imageRect.size.height -= 2;
	    imageRect.origin.y += 1;
	  }
	titleRect = imageRect;
	titleRect.origin.x += imageSize.width + xDist;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    titleRect.size.width -= 3;
	  }
	{
	  int heightDiff = titleRect.size.height - titleSize.height;
	  titleRect.origin.y += heightDiff - heightDiff / 2;
	  titleRect.size.height -= heightDiff;
	}
	break;

      case NSImageRight: 
	imageRect.origin.x = NSMaxX(cellFrame) - imageSize.width;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x -= 3;
	    imageRect.size.height -= 2;
	    imageRect.origin.y += 1;
	  }
	titleRect.origin = cellFrame.origin;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	titleRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 3;
	  }
	{
	  int heightDiff = titleRect.size.height - titleSize.height;
	  titleRect.origin.y += heightDiff - heightDiff / 2;
	  titleRect.size.height -= heightDiff;
	}
	break;

      case NSImageAbove: 
	/*
         * In this case, imageRect is all the space we can allocate
	 * above the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = cellFrame.origin.y;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.origin.y += titleRect.size.height + yDist;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = cellFrame.size.height;
	imageRect.size.height -= titleSize.height + yDist;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.size.width -= 6;
	    imageRect.origin.x   += 3;
	    titleRect.size.width -= 6;
	    titleRect.origin.x   += 3;
	    imageRect.size.height -= 1;
	    titleRect.size.height -= 1;
//  	    titleRect.origin.y    += 1;
	  }
	break;

      case NSImageBelow: 
	/*
	 * In this case, imageRect is all the space we can allocate
	 * below the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = cellFrame.origin.y + cellFrame.size.height;
	titleRect.origin.y -= titleSize.height;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = cellFrame.size.height;
	imageRect.size.height -= titleSize.height + yDist;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.size.width -= 6;
	    imageRect.origin.x   += 3;
	    titleRect.size.width -= 6;
	    titleRect.origin.x   += 3;
	    imageRect.size.height -= 1;
	    imageRect.origin.y    += 1;
//  	    titleRect.size.height -= 1;
	  }
	break;

      case NSImageOverlaps: 
	titleRect = cellFrame;
	imageRect = cellFrame;
	{
	  int heightDiff = titleRect.size.height - titleSize.height;
	  titleRect.origin.y += heightDiff - heightDiff / 2;
	  titleRect.size.height -= heightDiff;
	}
	// TODO: Add distance from border if needed
	break;
    }
  
  return titleRect;
}

@end


@implementation GormButtonEditor
- (void) mouseDown:  (NSEvent*)theEvent
{
  if (([theEvent clickCount] == 2) && [parent isOpened])
    // double-clicked -> let's edit
    {
      NSTextField *tf = 
	[[NSTextField alloc] initWithFrame: [self bounds]];
      NSRect frame = [[_EO cell] 
		       gormTitleRectForFrame: [_EO frame]
		       inView: _EO];
      frame.origin.y -= 2;
      frame.size.height += 4;
      [tf setFrame: frame];
      [tf setEditable: YES];
      [tf setBezeled: NO];
      [tf setBordered: YES];
      [tf setAlignment: [_EO alignment]];
      [tf setFont: [_EO font]];
      [self addSubview: tf];
      [tf setStringValue: [_EO stringValue]];
      [self editTextField: tf
	    withEvent: theEvent];
      [_EO setStringValue: [tf stringValue]];
      [tf removeFromSuperview];
      RELEASE(tf);
      [[NSNotificationCenter defaultCenter]
	postNotificationName: IBSelectionChangedNotification
	object: parent];
    }
  else
    {
      [super mouseDown: theEvent];
    }
}
@end
