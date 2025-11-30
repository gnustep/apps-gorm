#   GNUmakefile 
#
#   Copyright (C) 1999 Free Software Foundation, Inc.
#
#   Author: Gregory Casamento <greg.casamento@gmail.com>
#   Date: Nov 2025
#   
#   This file is part of GNUstep.
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

PACKAGE_NAME = gorm

include $(GNUSTEP_MAKEFILES)/common.make

PALETTE_NAME = 6Formatters

6Formatters_PALETTE_ICON = FormatterPalette
6Formatters_PRINCIPAL_CLASS = FormatterPalette

6Formatters_OBJC_FILES = \
	FormatterPalette.m \

6Formatters_RESOURCE_FILES = \
	Resources/FormatterPalette.tiff \
	Resources/byteCount.tiff \
	Resources/FormatterPalette.gorm \
	palette.table \

6Formatters_STANDARD_INSTALL = no

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/palette.make
