PACKAGE_NAME = gorm
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Gux
BUNDLE_EXTENSION = .plugin
Gux_PRINCIPAL_CLASS = GormGuxPlugin

Gux_OBJC_FILES = GormGuxPlugin.m \
	GormGuxWrapperLoader.m \
	GormGuxWrapperBuilder.m \
	GSGuxLoader.m \
	GSGuxSerialization.m \
	GSGuxMatrixCompatibility.m \
	GormGuxClassMappings.m

Gux_HEADER_FILES = GSGuxLoader.h \
	GSGuxSerialization.h \
	GormGuxClassMappings.h \
	GormGuxWrapperLoader.h

Gux_STANDARD_INSTALL = no

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
