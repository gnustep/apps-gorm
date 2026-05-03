# GormCore Framework

## Overview

GormCore is the central framework behind Gorm. It contains the document model,
editor and inspector infrastructure, class metadata management, plugin/palette
support, and archive/resource handling used to create and maintain .gorm
documents.

Both the Gorm application and the headless gormtool utility rely on this
framework. If you are extending or embedding Gorm functionality, this is the
primary library you integrate with.

## Design Goals

The framework is structured around a few practical goals:

- Keep document editing behavior in reusable framework code rather than in the
 app target.
- Expose extension points through protocols and managers.
- Support both interactive UI workflows and command-line automation flows.
- Preserve compatibility with long-lived GNUstep archive and plugin concepts.

## What GormCore Provides

At a high level, GormCore provides:

- A document-centric model for interface archives via GormDocument
- Editing surfaces and inspector infrastructure for interface objects
- Class/outlet/action metadata management
- Plugin and palette loading/management
- Resource management for image/sound and other document resources
- Wrapper-based import/export infrastructure for archive formats
- String and XLIFF localization import/export support

## Primary Public Entry Points

Use the umbrella header in most integrations:

```objc
#import <GormCore/GormCore.h>
```

The following headers are the most common integration touchpoints:

- GormDocument.h for document graph, connections, resources, and persistence
- GormDocumentController.h for document creation/opening workflows
- GormClassManager.h for class/action/outlet metadata
- GormPlugin.h, GormPluginManager.h, and GormPalettesManager.h for extension
 discovery and loading
- GormWrapperBuilder.h and GormWrapperLoader.h for file-wrapper serialization
 and loading
- GormXLIFFDocument.h for XLIFF localization I/O

## Architecture Summary

### Document Layer

Core classes:

- GormDocument
- GormDocumentController
- GormDocumentWindow

GormDocument is the central runtime object for an open archive. It implements
the InterfaceBuilder IBDocuments contract and handles:

- Object graph attachment/detachment and naming
- Connector management for actions/outlets
- Editor lifecycle and selection coordination
- Resource manager orchestration
- Visibility/deferred launch metadata for top-level objects
- Persistence and wrapper integration

Important document capabilities include:

- View switching among objects/images/sounds/classes/file preferences
- Validation support before save/export
- Translation I/O through string and XLIFF helpers
- Connection refresh/rename/remove flows when class metadata changes

GormDocumentController provides Gorm-specific document creation/open behavior,
including template-style new document construction.

### Editors And Inspectors

Representative editor classes:

- GormObjectEditor
- GormViewEditor and specialized subclasses
- GormWindowEditor
- GormClassEditor
- GormImageEditor
- GormSoundEditor
- GormResourceEditor

Representative inspector classes:

- GormObjectInspector
- GormClassInspector
- GormConnectionInspector
- GormHelpInspector
- GormImageInspector
- GormSoundInspector
- GormViewSizeInspector
- GormScrollViewAttributesInspector

Inspector orchestration is performed by GormInspectorsManager.

### Class Metadata And Connections

Key classes:

- GormClassManager
- GormClassPanelController

These components manage class definitions, actions, outlets, and class editing.
GormDocument maintains and updates connector data when class metadata changes,
including rename/removal flows.

Related API themes:

- Class creation and instantiation
- Class import and code generation
- Action/outlet compatibility checks against live connections

### Plugins And Palettes

Key classes:

- GormPlugin (subclass of IBPlugin)
- GormPluginManager
- GormPalettesManager

This layer is responsible for loading extension bundles, exposing palette
content, and importing palette-provided classes/resources.

GormPlugin adds document-type registration behavior on top of IBPlugin so
extensions can contribute additional file handling support.

### Resources

Key classes:

- GormResource
- GormResourceManager
- GormImage / GormSound and their editors/inspectors

GormResourceManager extends IBResourceManager behavior for Gorm-specific
resource workflows and pasteboard/file integration.

Resource flows include:

- Drag-and-drop and pasteboard insertion
- Project and document file integration
- Image and sound resource editing/inspection

### Archive Wrappers And File Types

Key protocols/classes:

- GormWrapperBuilder
- GormWrapperBuilderFactory
- GormWrapperLoader
- GormWrapperLoaderFactory

These abstractions map document types to loader/builder implementations so
GormCore can read and write wrapper-based archive structures.

Factory classes provide type-based lookup and registration for custom
loader/builder implementations.

### Localization Support

Localization features include:

- strings import/export through GormDocument
- XLIFF import/export via GormXLIFFDocument

This enables translation workflows in both GUI and tool-driven scenarios.

## Protocols And Interop Surface

GormCore works closely with the InterfaceBuilder framework protocols:

- IBDocuments, IBEditors, IBSelectionOwners for editing and selection control
- IBConnectors for outlet/action graph maintenance
- IBResourceManager for pluggable resource handling

GormProtocol.h also defines GormAppDelegate, which documents what the app-level
delegate provides to the framework during editing and connection workflows.

Additional framework-defined protocol/category surfaces include:

- GormServer for simple class add/remove service interactions
- NSView category methods in GormGroupProtocol.h for grouping/layout operations

## Relationship To InterfaceBuilder Framework

GormCore builds on the InterfaceBuilder compatibility layer in this repository.
In practice:

- InterfaceBuilder defines the base protocols/classes used for editing and
 plugin integration.
- GormCore provides the concrete Gorm implementations on top of those APIs.

If you are developing extensions, you typically use both frameworks.

## Build And Runtime Dependencies

This framework depends on GNUstep base and GUI libraries and on other modules in
this repository.

At repository build time, GormCore is built after:

- InterfaceBuilder
- GormObjCHeaderParser

and before application/tool targets that consume it.

## Build And Install

From this directory:

```sh
make
make install
```

From the repository root, the aggregate build includes GormCore after
InterfaceBuilder and GormObjCHeaderParser.

Typical prerequisites:

- gnustep-make
- gnustep-base
- gnustep-gui
- gnustep-back

On some platforms, makefile preamble settings also ensure linkage against local
InterfaceBuilder and GormObjCHeaderParser build outputs.

## Versioning Notes

GormCore includes generated version macros through GormVersion.h. This header is
generated from GormVersion.h.in and the repository Version data during build.

The generated macros are:

- GORM_MAJOR_VERSION
- GORM_MINOR_VERSION
- GORM_SUBMINOR_VERSION

## Resource And UI Assets In This Module

The framework bundles:

- Shared images used by editors/inspectors and connection visualization
- Localized .gorm UI resources (currently English.lproj)
- Class/profile metadata resources

These are compiled into the framework resources and loaded at runtime.

## Quick Integration Guide

Minimal host-app integration typically looks like this:

1. Link against GormCore and InterfaceBuilder.
2. Include GormCore.h in extension or host integration code.
3. Open or create documents through GormDocumentController workflows.
4. Use GormDocument APIs for object graph, class, and connection operations.
5. Register plugin, resource manager, and wrapper types when extending behavior.

## Typical Integration Patterns

### Using GormCore In Another App

Common pattern:

1. Link against GormCore (and InterfaceBuilder where required).
2. Open/create GormDocument instances through document controller workflows.
3. Use wrapper factories and resource managers for import/export customization.
4. Optionally load plugin bundles for additional palettes/editors.

### Extending Gorm With Plugins

Common pattern:

1. Subclass GormPlugin (or IBPlugin where appropriate).
2. Register additional document types or extension behaviors.
3. Package and load through GormPluginManager / palette manager flows.

### Adding A New Wrapper Format

Common pattern:

1. Implement a GormWrapperBuilder subclass and declare its file type.
2. Implement a matching GormWrapperLoader subclass.
3. Register both classes with their respective factories.
4. Route open/save behavior through document controller and document workflows.

### Adding A Resource Type

Common pattern:

1. Implement or extend a resource manager based on GormResourceManager.
2. Advertise supported pasteboard and file types.
3. Integrate with document resource manager creation and editor switching.

## Notes On API Stability

GormCore is a mature codebase with long-standing API concepts. However,
internal editor/inspector behavior evolves over time. For extension code,
prefer protocol- and manager-based integration points rather than relying on
private implementation details.

When possible:

- Depend on published headers in GormCore.h and InterfaceBuilder.h
- Avoid assumptions about internal view hierarchy details
- Validate connections and class metadata updates after structural changes

## Source Navigation Pointers

Useful files when exploring or extending behavior:

- GormDocument.h and GormDocument.m for document orchestration
- GormClassManager.h and GormClassManager.m for class metadata logic
- GormPluginManager.h and GormPalettesManager.h for extension loading
- GormWrapperBuilder.h and GormWrapperLoader.h for archive format support
- GormXLIFFDocument.h and GormXLIFFDocument.m for localization workflows

## License

GormCore is part of apps-gorm. Source files in this module carry their own
license headers, and the project provides license texts at repository scope.

See:

- COPYING at repository root
- file-level headers in this directory for specific terms
