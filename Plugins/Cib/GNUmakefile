#   GNUmakefile

PACKAGE_NAME = gorm
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Cib
BUNDLE_EXTENSION = .plugin
Cib_PRINCIPAL_CLASS = GormCibPlugin

Cib_OBJC_FILES = GormCibPlugin.m \
	GormCibWrapperLoader.m \
	GormCibWrapperBuilder.m \
	GormCIBModelGenerator.m \

Cib_RESOURCE_FILES =

Cib_STANDARD_INSTALL = no

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
