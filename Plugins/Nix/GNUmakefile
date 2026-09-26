PACKAGE_NAME = gorm
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Nix
BUNDLE_EXTENSION = .plugin
Nix_PRINCIPAL_CLASS = GormNixPlugin

Nix_OBJC_FILES = GormNixPlugin.m \
	GormNixWrapperLoader.m \
	GormNixWrapperBuilder.m \
	GSNixLoader.m \
	GSNixSerialization.m \
	GSNixMatrixCompatibility.m \
	GormNixClassMappings.m

Nix_HEADER_FILES = GSNixLoader.h \
	GSNixSerialization.h \
	GormNixClassMappings.h \
	GormNixWrapperLoader.h

Nix_STANDARD_INSTALL = no

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
