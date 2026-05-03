# apps-gorm

[![CI](https://github.com/gnustep/apps-gorm/actions/workflows/main.yml/badge.svg)](https://github.com/gnustep/apps-gorm/actions/workflows/main.yml?query=branch%3Amaster)

## What Is Gorm?

Gorm is the GNUstep graphical interface builder.

- The name stands for Graphic Object Relationship Modeler (also commonly expanded as GNUstep Object Relationship Modeler).
- It is the GNUstep counterpart to the classic NeXTSTEP/OpenStep/Cocoa Interface Builder.
- It lets you design interface objects visually, wire outlets/actions, and save interface archives that GNUstep applications can load at runtime.

## Key Capabilities

- Visual editing of windows, panels, menus, controls, and custom views
- Property editing through inspectors
- Action/outlet connection modeling between objects
- Class management for custom classes, outlets, and actions
- Resource editing and management (for example images and sounds)
- Plugin/palette architecture for extensibility
- Import/export support through the headless gormtool utility (strings, XLIFF, class metadata, archive conversion workflows)

## Repository Layout

Top-level modules are split so core functionality can be reused by other tools and apps:

- GormCore/: core framework and editor/inspector implementation
- InterfaceBuilder/: protocol and compatibility layer abstractions
- GormObjCHeaderParser/: Objective-C header parsing support used by class tooling
- Applications/: application targets, including the Gorm app
- Plugins/: plugin bundles for archive/loading support
- Tools/: command-line tooling, including gormtool
- Documentation/: texinfo manual sources, man page source, and documentation status notes

The aggregate build in GNUmakefile builds these as subprojects in this order:

1. InterfaceBuilder
2. GormObjCHeaderParser
3. GormCore
4. Plugins
5. Applications
6. Tools

## Requirements

To build and run Gorm, you need GNUstep core components installed:

- gnustep-make
- gnustep-base
- gnustep-gui
- gnustep-back

The build expects GNUSTEP_MAKEFILES to be available (normally provided by gnustep-config).

## Build And Install

From the repository root:

```sh
make
make install
```

Notes:

- GormCore (the framework/library) must be installed for Gorm.app to run correctly.
- The root post-build step copies plugins into GormCore framework resources.

## Running Gorm

Typical launch methods:

```sh
openapp Gorm
```

```sh
gopen -a Gorm
```

```sh
Gorm
```

Open an existing document directly:

```sh
Gorm path/to/MyInterface.gorm
```

## Interface Archive Formats

Gorm primarily works with interface archive documents and associated resources.

- .gorm: native Gorm document format
- .nib: legacy Interface Builder archive format support
- .xib: XML-based Interface Builder archive support

## gormtool (Headless CLI)

gormtool is a command-line front end for selected Gorm document operations.
It loads a document, performs operations, optionally writes output, then exits.

Basic forms:

```sh
gormtool [options] inputfile
gormtool --read inputfile [options]
```

Important behavior:

- If --read is omitted, the last argument is treated as input.
- Operations that modify the in-memory document do not auto-save unless --write is also provided.

Common options:

- --read FILE: open input document
- --write FILE: write resulting document
- --import-strings-file FILE: import .strings translations
- --export-strings-file FILE: export localizable strings
- --export-xliff FILE: export XLIFF 1.2
- --import-xliff FILE: import XLIFF 1.2
- --source-language LANG: source language for XLIFF export
- --target-language LANG: optional target language for XLIFF export
- --import-class HEADER: import Objective-C class metadata from header
- --export-class CLASSNAME: export class interface/implementation files
- --output-path DIR: output directory for exported class files
- --objects, --connections, --classes: print document internals
- --test: keep process running in interactive test mode

Examples:

```sh
gormtool --export-strings-file Localizable.strings MyDocument.gorm
```

```sh
gormtool --read MyDocument.gorm --import-xliff MyDocument-fr.xliff --write MyDocument-fr.gorm
```

```sh
gormtool --read MyDocument.gorm --write MyDocument.xib
```

## Typical Workflow In Gorm

1. Create or open a .gorm document.
2. Add windows/views/controllers from palettes.
3. Configure properties using inspectors.
4. Define custom classes/actions/outlets as needed.
5. Wire outlets and actions between objects.
6. Add resources (images/sounds) and set references.
7. Save and load the archive from your GNUstep app at runtime.

## Documentation Map

Primary sources in this repository:

- Documentation/Gorm.texi: main manual source
- Documentation/gorm.1.in: man page source
- Documentation/install.texi: install requirements and build notes
- Documentation/news.texi: release/user-visible change notes
- Documentation/readme.texi: short overview summary
- Documentation/DOCUMENTATION_PROGRESS.md: API/header documentation tracking
- Documentation/DOCUMENTATION_SUMMARY.md: API documentation status summary

Additional manual/wiki entry point:

- <https://wiki.gnustep.org/index.php/Gorm_Manual>

## Project Status

Gorm is usable and stable.

Known long-term improvement areas include:

- Broader compatibility with newer Interface Builder behaviors
- Continued palette/editor expansion
- Ongoing API/header documentation completion

## Contributing

Contributions are welcome in all areas, especially:

- Bug fixes and regressions
- Documentation improvements
- New palettes/editors/inspectors
- Compatibility and archive import/export improvements

Please open issues and pull requests on GitHub:

- <https://github.com/gnustep/apps-gorm/issues>

You can also send feedback and patches to:

- <bug-gnustep@gnu.org>

## License

Gorm is part of GNUstep and distributed under the GNU General Public License.
See COPYING for details.

## Acknowledgements

- Icons: mostly by Andrew Lindsay; Gorm application icon by Jesse Ross.
- Code: GormViewKnobs.m adapted from code by Gerrit van Dyk.
