# InterfaceBuilder compatibility with OPENSTEP

Gorm's InterfaceBuilder library closely follows the classic OPENSTEP extension
model, but it is not an exact replacement. It provides familiar APIs for
palettes, inspectors, editors, and document connections, with GNUstep additions
and implementation responsibilities shared with GormCore.

## Scope and evidence

This comparison covers the current repository's public headers and selected
implementations. Historical sources are Sun's 1996 *OpenStep Development Tools*
manual and NeXT's OPENSTEP 4.1 release notes. Sun's manual is useful evidence for
the contemporary API, but does not establish exact compatibility with NeXT's
SDK. This is not an exhaustive selector audit or a runtime compatibility test.

## Shared architecture

| Area | Historical OPENSTEP Interface Builder | Gorm implementation |
| --- | --- | --- |
| Palettes | `IBPalette` supplies prototypes dragged into documents. | Preserves `finishInstantiate`, object-to-view associations, pasteboard types, and palette document access. |
| Inspectors | `IBInspector` supplies property panels, OK/Revert, and editing hooks. | Preserves that structure and adds explicit `setObject:` handling. |
| Editors and selection | Protocols expose editing and selection behavior. | `IBEditors` and `IBSelectionOwners` cover activation, selection, subeditors, paste/delete, and validation. |
| Documents | `IBDocuments` exposes the editable object graph and connections. | Similar abstraction for ownership, naming, connectors, copying, and editor management. |
| Connections | Application and connector APIs support connecting objects. | `IBConnectors` integrates with GNUstep's `NSNibConnector`; connection UI remains host-provided. |

See appendices C–D of the [historical API reference][sun-manual] and the local
[umbrella header](InterfaceBuilder/InterfaceBuilder.h).

## Differences and gaps

### The library is only part of the implementation

`IBDocuments` is a protocol; the concrete document implementation is
[GormDocument](GormCore/GormDocument.h). Some category methods declared by
InterfaceBuilder, including view resource-dragging registration, are implemented
in [GormCore](GormCore/NSView+GormExtensions.m).

Linking `libInterfaceBuilder` alone does not provide a functioning interface
editor. Ported extensions must account for the behavior supplied by the host.

### GNUstep extensions

The headers explicitly identify additions to the historical contract:

- [IBDocuments](InterfaceBuilder/IBDocuments.h) supports attaching an object
  with a specified name and detaching objects with control over editor closure.
- [IBInspector](InterfaceBuilder/IBInspector.h) provides `setObject:`, documented
  there as an extension absent from NeXTstep.
- [IBPaletteDescriptions](InterfaceBuilder/IBPalette.h) supplies optional
  Widget Library descriptions.
- [IBPalette](InterfaceBuilder/IBPalette.h) exports Gorm-specific resource
  pasteboard types.

Extensions using these facilities need adaptation when targeting historical IB.

### Additional API surface is not proof of historical parity

The library also exposes `IBPlugin`, resource-manager registration, inspector
modes, project/file protocols, and bindings-inspector hooks. Their presence does
not establish that each facility existed in OPENSTEP or behaves identically
there. Dating and comparing these APIs requires a separate SDK-level audit.

Relevant declarations are in [IBPlugin.h](InterfaceBuilder/IBPlugin.h),
[IBResourceManager.h](InterfaceBuilder/IBResourceManager.h),
[IBInspectorManager.h](InterfaceBuilder/IBInspectorManager.h),
[IBProjects.h](InterfaceBuilder/IBProjects.h),
[IBProjectFiles.h](InterfaceBuilder/IBProjectFiles.h), and
[IBObjectProtocol.h](InterfaceBuilder/IBObjectProtocol.h).

### Palette API discrepancies

Sun's reference documents `IBPalette -imageNamed:`. Gorm's
[IBPalette header](InterfaceBuilder/IBPalette.h) and
[implementation](InterfaceBuilder/IBPalette.m) do not provide that method.
Code relying on palette-specific image lookup needs adaptation or a compatible
implementation.

The same reference documents `associateObject:ofType:withView:`, while Gorm
exposes `associateObject:type:with:`. However, the historical manual itself uses
both spellings. Treat this as an unresolved documentation/SDK discrepancy, not
as a confirmed missing NeXT selector. Check the original NeXT SDK headers before
adding a compatibility alias. See [pages C-8–C-9][palette-reference].

### Archive compatibility is a separate concern

The [OPENSTEP 4.1 release notes][next-release-notes] describe support for OpenStep
nib files. Gorm's persistence behavior depends on GormCore, format plugins, and
GNUstep's archiving implementations.

Matching extension methods does not establish that a saved object graph loads
correctly on OPENSTEP. Archive interoperability must be tested separately,
including object identity, custom classes, connections, resources, geometry,
and control state. Successful loading into an editor alone is insufficient.

## Porting assessment

Gorm offers a strong starting point for porting classic palettes and inspectors:
the architecture and many selectors are familiar. Expect to rebuild and adapt
bundle resources, host integration, and mismatched methods.

Binary compatibility, unchanged-source compatibility, and archive
interchangeability are separate questions. None is established by this review.
An exact compatibility assessment would require NeXT's SDK headers, representative
extensions, and tests on an actual OPENSTEP installation.

## Validation and review status

This document was drafted with AI assistance. Independent human verification
is required before acceptance under [POLICY_AI.md](POLICY_AI.md).

Documentation validation checks local link targets, verifies that representative
API names occur in the cited source files, and checks patch whitespace. These
checks address broken repository references and accidental API-name errors;
they are sufficient for those mechanical properties of this documentation-only
change, not for historical or behavioral compatibility claims.

No builds, GUI tests, conversion tests, or OPENSTEP runtime tests were performed
for this comparison. No implementation or archive resources were changed.

[sun-manual]: https://docs.oracle.com/cd/E19957-01/802-2110/802-2110.pdf
[palette-reference]: https://docs.oracle.com/cd/E19957-01/802-2110/802-2110.pdf#page=462
[next-release-notes]: https://www.nextop.de/NeXTAnswers/2473.html
