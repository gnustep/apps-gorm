# InterfaceBuilder Framework

## Overview

The InterfaceBuilder framework in this directory provides the compatibility and
extension API layer used by Gorm.

Historically, this framework mirrors the classic Interface Builder style API,
adapted for GNUstep and Gorm. Its main goals are:

- Expose protocols and base classes for editors, inspectors, palettes, plugins,
 connectors, and resources.
- Provide a stable, reusable header surface for code that extends Gorm.
- Decouple extension code from direct dependencies on Gorm internals.

You must build and install this library before building the full Gorm project.

## What This Library Contains

This module is primarily an Objective-C library plus public headers under the
InterfaceBuilder include namespace.

Primary deliverables:

- Public umbrella header: InterfaceBuilder.h
- Public protocol and base-class headers in this directory
- Runtime implementations for core extension points (plugin, inspector manager,
 editor/document helpers, connectors, resource manager)

The library links against GNUstep GUI and Foundation.

## Core API Areas

The public API is organized around a small set of extension concepts.

### 1. Documents And Object Graph Management

Key header: IBDocuments.h

The IBDocuments protocol models editable interface documents. It includes
operations for:

- Attaching and detaching objects in the document hierarchy
- Naming and looking up objects
- Creating/opening/closing editors for objects
- Managing connectors (actions/outlets)
- Copy/paste with pasteboard support
- Querying class actions and outlets

It also publishes lifecycle notifications such as:

- IBDidOpenDocumentNotification
- IBWillSaveDocumentNotification
- IBDidSaveDocumentNotification
- IBWillCloseDocumentNotification

### 2. Editors And Selection

Key header: IBEditors.h

The IBEditors and IBSelectionOwners protocols define editor behavior and
selection ownership:

- Editor activation/deactivation, ordering, paste/delete
- Subeditor support
- Selection queries and mutation
- Editing validation and redraw hooks

Important notifications include:

- IBAttributesChangedNotification
- IBInspectorDidModifyObjectNotification
- IBSelectionChangedNotification
- IBClassNameChangedNotification

### 3. Inspectors

Key headers: IBInspector.h, IBInspectorManager.h, IBInspectorMode.h

- IBInspector is the base class for inspector panels.
- IBInspectorManager coordinates inspector modes and selected-object
 inspection flow.
- Inspector mode support allows different inspector views/aspects per object.

Inspector notifications include:

- IBWillInspectObjectNotification
- IBWillInspectWithModeNotification

### 4. Connectors (Outlets And Actions)

Key header: IBConnectors.h

The IBConnectors protocol abstracts source-label-destination connections and
connection establishment behavior. A category makes NSNibConnector conform to
this protocol, so nib connectors can be handled uniformly.

Connection lifecycle notifications include:

- IBWillAddConnectorNotification
- IBDidAddConnectorNotification
- IBWillRemoveConnectorNotification
- IBDidRemoveConnectorNotification

### 5. Palettes And Plugins

Key headers: IBPalette.h, IBPlugin.h

- IBPalette models drag-enabled palette windows and palette document context.
- IBPlugin is the base class for plugin modules that contribute library nibs,
 preference views, and drag/drop insertion behavior.

IBPalette also defines pasteboard type constants used by drag-and-drop for
views, cells, menu cells, objects, windows, formatters, and Gorm-specific
resource types.

### 6. Resources And Project Integration

Key headers: IBResourceManager.h, IBProjects.h, IBProjectFiles.h

- IBResourceManager handles resource import and persistence for documents.
- Resource manager classes can be registered globally and by framework.
- IBProjects and IBProjectFiles define how interface tools query project
 structure, file metadata, localization, and hierarchy.

Resource manager registry changes are announced through:

- IBResourceManagerRegistryDidChangeNotification

### 7. Object/View/Cell Extension Protocols

Key headers: IBObjectProtocol.h, IBViewProtocol.h, IBCellProtocol.h

These protocols define hooks for edit-time behavior:

- Inspector/editor class naming for objects
- Alternate class substitution support
- Viewer labels and images
- Geometry and resizing constraints
- Color-drop behavior

Supporting categories provide default conformance on NSObject and NSCell via
IBObjectAdditions.h and IBCellAdditions.h.

### 8. Application-Level Integration

Key header: IBApplicationAdditions.h

The IB protocol exposes application-level context used by tools and extensions:

- Active document access
- Selection owner and selected object
- Testing mode state
- Document lookup for objects

Testing lifecycle notifications:

- IBWillBeginTestingInterfaceNotification
- IBDidBeginTestingInterfaceNotification
- IBWillEndTestingInterfaceNotification
- IBDidEndTestingInterfaceNotification

## Public Headers Map

Include the umbrella header for most users:

```objc
#import <InterfaceBuilder/InterfaceBuilder.h>
```

This aggregates the public headers:

- IBApplicationAdditions.h
- IBCellAdditions.h
- IBCellProtocol.h
- IBConnectors.h
- IBDefines.h
- IBDocuments.h
- IBEditors.h
- IBInspector.h
- IBInspectorManager.h
- IBInspectorMode.h
- IBObjectAdditions.h
- IBObjectProtocol.h
- IBPalette.h
- IBPlugin.h
- IBProjectFiles.h
- IBProjects.h
- IBResourceManager.h
- IBSystem.h
- IBViewAdditions.h
- IBViewProtocol.h
- IBViewResourceDragging.h

## Build And Install

From this directory:

```sh
make
make install
```

Or from the repository root, the top-level build invokes this module first.

Typical dependency stack for building this library:

- gnustep-make
- gnustep-base
- gnustep-gui

The installed headers are exposed under the InterfaceBuilder include path.

## Using The Library In Extensions

Common extension patterns:

- Subclass IBPlugin to contribute palette/library content and preferences UI.
- Subclass IBInspector to provide property editing panels.
- Implement IBEditors for custom editing surfaces.
- Implement IBResourceManager subclasses for additional resource types.
- Adopt IBObjectProtocol on custom model objects when richer edit-time
 integration is needed.

If you need only API definitions and compatibility behavior for Gorm
integration, include the umbrella header and adopt the relevant protocols.

## Compatibility Notes

- This framework is intended for GNUstep/Gorm extension workflows.
- It mirrors historical Interface Builder API concepts, but should not be
 treated as a guaranteed drop-in replacement for every platform-specific
 Interface Builder implementation.

## Relationship To Gorm

In this repository, InterfaceBuilder is a foundational module used by:

- GormCore
- Applications/Gorm
- Plugin and tool code that targets Gorm extension APIs

Because of that dependency chain, it is built first in the aggregate build.

## License

This library is distributed under the GNU Lesser General Public License.
See COPYING.LIB in this directory for details.
