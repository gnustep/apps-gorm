# Gorm

Gorm (GNUstep Object Relationship Modeler) is the visual interface builder for GNUstep. It lets you design graphical user interfaces for Objective‑C applications by assembling windows, menus, controls, and custom views; wiring actions and outlets; and organizing resources—all without writing boilerplate UI code.

Gorm is the GNUstep counterpart to the classic NeXTSTEP/OpenStep/Cocoa Interface Builder, tailored for the GNUstep environment.

## Highlights

- Visual editor for windows, panels, menus, and controls
- Drag‑and‑drop creation and arrangement of views with alignment and sizing tools
- Inspectors for properties, sizes, connections, and help
- Class browser with support for actions and outlets
- Resource management for images and sounds
- Palettes system for extending Gorm with new widgets and editors
- Generates and maintains connection graphs between objects
- Produces archives that can be loaded at runtime via GNUstep nib loading

## Getting started

- See `NEWS` for recent changes.
- See `INSTALL` for build and installation instructions.
- Full documentation lives in the `Documentation/` directory of the repository. A tutorial/reference is also available on the wiki:
  - <https://wiki.gnustep.org/index.php/Gorm_Manual>

## Status

Gorm is usable and stable. Please report bugs to:

- <bug-gnustep@gnu.org>

Known areas for improvement include:

- Increased compatibility with newer Interface Builder behaviors
- Additional palettes and editor integrations

## Contributing

Contributions are welcome. Typical areas include:

- Palette development (new controls or inspectors)
- Documentation improvements (class/method docs, guides)
- Bug fixes and UI/UX refinements

## License

Gorm is part of the GNUstep project and is released under the GNU General Public License (GPL). See `COPYING` for details.

## Acknowledgements

- Icons: Mostly by Andrew Lindsay; application icon by Jesse Ross
- Code: `GormViewKnobs.m` adapted from code by Gerrit van Dyk
