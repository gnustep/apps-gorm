#
# GNUmakefile 
# Written by Gregory John Casamento <greg_casamento@yahoo.com>
#
# NOTE: Do NOT change this file -- ProjectCenter maintains it!
#
# Put all of your customisations in GNUmakefile.preamble and
# GNUmakefile.postamble
#

include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)


#
# Subprojects
#



#
# Library
#

PACKAGE_NAME=GormObjCHeaderParser
LIBRARY_VAR=GMOBJCHEADERPARSER
LIBRARY_NAME=libGormObjCHeaderParser
libGormObjCHeaderParser_HEADER_FILES_DIR=.
libGormObjCHeaderParser_HEADER_FILES_INSTALL_DIR=/GormObjCHeaderParser
ADDITIONAL_INCLUDE_DIRS = -I..
srcdir = .

#
# Additional libraries
#

libGormObjCHeaderParser_LIBRARIES_DEPEND_UPON += -lgnustep-gui -l$(FOUNDATION_LIBRARY_NAME)

#
# Header files
#

libGormObjCHeaderParser_HEADER_FILES= \
OCHeaderParser.h \
OCClass.h \
OCIVar.h \
OCIVarDecl.h \
OCMethod.h \
NSScanner+OCHeaderParser.h

#
# Class files
#

libGormObjCHeaderParser_OBJC_FILES= \
OCHeaderParser.m \
OCClass.m \
OCIVar.m \
OCIVarDecl.m \
OCMethod.m \
NSScanner+OCHeaderParser.m

#
# C files
#

libGormObjCHeaderParser_C_FILES= 

HEADERS_INSTALL = $(libGormObjCHeaderParser_HEADER_FILES)

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
