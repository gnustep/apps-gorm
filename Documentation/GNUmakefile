
GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The application to be compiled
DOCUMENT_NAME = Gorm

DOCUMENT_TEXT_NAME = README NEWS INSTALL

# The texinfo source files to be used
Gorm_TEXI_FILES = install.tmpl.texi news.tmpl.texi Gorm

README_TEXI_FILES = version.texi
README_TEXT_MAIN = readme.tmpl.texi

INSTALL_TEXT_MAIN = install.tmpl.texi

NEWS_TEXT_MAIN = news.tmpl.texi

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/documentation.make

-include Makefile.postamble
