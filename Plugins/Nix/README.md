# Gorm NIX plugin

This plugin owns the Native Interface XML (NIX) version 1 reader and writer.
NIX is a Gorm document format and is not registered as an `NSNib` model
loader by libs-gui.

The on-disk representation is an XML property list containing keyed-coding
properties, nested object definitions, stable object identifiers, references,
and Gorm connection metadata. Gorm replacement-class mappings are applied in
both directions: editor classes are instantiated while loading when their
palettes are available, and AppKit runtime class names are written when saving.

Compatibility repairs for NIX files produced by earlier implementations are
kept here so they do not alter normal keyed or unkeyed nib archiving.
