/* GormNSWindowView.h

   Copyright (C) 2021 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2021
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/
#ifndef	INCLUDED_GormNSWindowView_h
#define	INCLUDED_GormNSWindowView_h

#include <AppKit/AppKit.h>

@interface GormNSWindowView : NSView
{
  NSRect        _frame;
  NSSize        _minimumSize;
  NSSize        _maximumSize;
  NSSize        _increments;
  NSString	*_autosaveName;
  GSWindowDecorationView *_wv;
  id            _contentView;
  id            _firstResponder;
  id            _futureFirstResponder;
  NSView        *_initialFirstResponder;
  GSAutoLayoutEngine *_layoutEngine;
PACKAGE_SCOPE
  id            _delegate;
@protected
  id            _fieldEditor;
  id            _lastLeftMouseDownView;
  id            _lastRightMouseDownView;
  id            _lastOtherMouseDownView;
  id            _lastDragView;
  NSInteger     _lastDragOperationMask;
  NSInteger     _windowNum;
  NSInteger     _gstate;
  id            _defaultButtonCell;
  NSGraphicsContext *_context;

  NSScreen      *_screen;
  NSColor       *_backgroundColor;
  NSString      *_representedFilename;
  NSString      *_miniaturizedTitle;
  NSImage       *_miniaturizedImage;
  NSString      *_windowTitle;
PACKAGE_SCOPE
  NSPoint       _lastPoint;
@protected
  NSBackingStoreType _backingType;
  NSUInteger    _styleMask;
  NSInteger     _windowLevel;
PACKAGE_SCOPE
  NSRect        _rectNeedingFlush;
  NSMutableArray *_rectsBeingDrawn;
@protected
  unsigned	_disableFlushWindow;
  
  NSWindowDepth _depthLimit;
  NSWindowController *_windowController;
  NSInteger     _counterpart;
  CGFloat       _alphaValue;
  
  NSMutableArray *_children;
  NSWindow       *_parent;
  NSCachedImageRep *_cachedImage;
  NSPoint        _cachedImageOrigin;
  NSWindow       *_attachedSheet;

PACKAGE_SCOPE
  struct GSWindowFlagsType {
    unsigned	accepts_drag:1;
    unsigned	is_one_shot:1;
    unsigned	needs_flush:1;
    unsigned	is_autodisplay:1;
    unsigned	optimize_drawing:1;
    unsigned	dynamic_depth_limit:1;
    unsigned	cursor_rects_enabled:1;
    unsigned	cursor_rects_valid:1;
    unsigned	visible:1;
    unsigned	is_key:1;
    unsigned	is_main:1;
    unsigned	is_edited:1;
    unsigned	is_released_when_closed:1;
    unsigned	is_miniaturized:1;
    unsigned	menu_exclude:1;
    unsigned	hides_on_deactivate:1;
    unsigned	accepts_mouse_moved:1;
    unsigned	has_opened:1;
    unsigned	has_closed:1;
    unsigned	default_button_cell_key_disabled:1;
    unsigned	can_hide:1;
    unsigned	has_shadow:1;
    unsigned	is_opaque:1;
    unsigned	views_need_display:1;
    // 3 bits reserved for subclass use
    unsigned subclass_bool_one: 1;
    unsigned subclass_bool_two: 1;
    unsigned subclass_bool_three: 1;

    unsigned selectionDirection: 2;
    unsigned displays_when_screen_profile_changes: 1;
    unsigned is_movable_by_window_background: 1;
    unsigned allows_tooltips_when_inactive: 1;

    // 4 used 28 available
    unsigned shows_toolbar_button: 1;
    unsigned autorecalculates_keyview_loop: 1;
    unsigned ignores_mouse_events: 1;
    unsigned preserves_content_during_live_resize: 1;
  } _f;
@protected 
  NSToolbar     *_toolbar;
  void          *_reserved_1;
}

- (void) setStyleMask: (unsigned int)newStyleMask;
- (unsigned int) styleMask;
- (void) setReleasedWhenClosed: (BOOL) flag;
- (BOOL) isReleasedWhenClosed;
- (unsigned int) autoPositionMask;
- (void) setAutoPositionMask: (unsigned int)mask;

@end

#endif
