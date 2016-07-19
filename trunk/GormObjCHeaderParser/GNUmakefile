#
# GNUmakefile 
# Written by Gregory John Casamento <greg_casamento@yahoo.com>
#
PACKAGE_NAME = gorm
include $(GNUSTEP_MAKEFILES)/common.make


#
# Subprojects
#



#
# Library
#

LIBRARY_VAR=GMOBJCHEADERPARSER
LIBRARY_NAME=libGormObjCHeaderParser
libGormObjCHeaderParser_HEADER_FILES_DIR=.
libGormObjCHeaderParser_HEADER_FILES_INSTALL_DIR=/GormObjCHeaderParser
ADDITIONAL_INCLUDE_DIRS = -I..
srcdir = .

include ./Version

#
# Additional libraries
#

libGormObjCHeaderParser_LIBRARIES_DEPEND_UPON += -lgnustep-gui -l$(FOUNDATION_LIBRARY_NAME)

#
# Header files
#

libGormObjCHeaderParser_HEADER_FILES= \
NSScanner+OCHeaderParser.h \
OCClass.h \
OCHeaderParser.h \
OCIVar.h \
OCIVarDecl.h \
OCMethod.h \
ParserFunctions.h


#
# Class files
#

libGormObjCHeaderParser_OBJC_FILES= \
NSScanner+OCHeaderParser.m \
OCClass.m \
OCHeaderParser.m \
OCIVar.m \
OCIVarDecl.m \
OCMethod.m \
ParserFunctions.m

#
# C files
#

libGormObjCHeaderParser_C_FILES= 

HEADERS_INSTALL = $(libGormObjCHeaderParser_HEADER_FILES)

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
