/* GormBoxEditor.h
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
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef	INCLUDED_GormBoxEditor_h
#define	INCLUDED_GormBoxEditor_h

#include <GormCore/GormViewWithContentViewEditor.h>
#include <GormCore/GormInternalViewEditor.h>

/**
 * GormBoxEditor provides editing capabilities for NSBox views within the
 * Gorm interface builder. It manages the content view of the box and handles
 * subview manipulation.
 */
@interface GormBoxEditor : GormViewWithSubviewsEditor
{
  GormInternalViewEditor *contentViewEditor;
}

/**
 * Destroys the editor and returns an array of the subviews that were being
 * edited.
 */
- (NSArray *)destroyAndListSubviews;
@end

#endif
