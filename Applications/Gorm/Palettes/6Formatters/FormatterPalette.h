/* ToolbarPalette

   Copyright (C) 2025 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Nov 2025
   
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

/* All rights reserved */

#ifndef FormatterPalette_H_INCLUDE
#define FormatterPalette_H_INCLUDE

#import <InterfaceBuilder/IBPalette.h>

@interface FormatterPalette : IBPalette
{
  IBOutlet id _byteCount;
  IBOutlet id _dateComponents;
  IBOutlet id _dateInterval;
  IBOutlet id _energy;
  IBOutlet id _iso1806date;
  IBOutlet id _length;
  IBOutlet id _mass;
  IBOutlet id _measurement;
  IBOutlet id _personNameComponents;
}  
@end

#endif // FormatterPalette_H_INCLUDE
