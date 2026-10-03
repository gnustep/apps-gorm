# Working on Gorm

Gorm is GNUstep’s graphical interface builder. Changes must preserve
editable document graphs, runtime-loadable archives, and compatibility
with supported GNUstep compilers and runtimes.

Read POLICY_AI.md before preparing contributions. It requires tests for
AI-assisted contributions, independent human review before acceptance,
and disclosure when AI materially shapes a submission. Explain what the
tests cover, why they are sufficient, and which failures they prevent.

## Repository map

- InterfaceBuilder/: extension protocols and compatibility APIs.
- GormObjCHeaderParser/: Objective-C class/header parsing.
- GormCore/: shared document model, editors, inspectors, and persistence.
- Plugins/: archive-format loaders and builders.
- Applications/Gorm/: application UI, palettes, and app integration.
- Tools/gormtool/: command-line document operations.
- Tests/: aggregate test runner; component tests live with their modules.
- Documentation/: manuals and command-line documentation.

Keep shared document behavior in GormCore so the app and gormtool benefit.
Keep format-specific behavior in the relevant plugin. NIX compatibility
repairs belong in Plugins/Nix, not in general nib archiving.

## Coding conventions

- Match the surrounding GNUstep Objective-C style.
- Preserve GCC and Clang compatibility. Do not introduce syntax or APIs
  that require an Apple-only environment or modern Objective-C runtime.
- Follow existing manual memory-management conventions; do not introduce
  ARC as part of an unrelated change.
- Preserve public InterfaceBuilder and GormCore contracts.
- Prefer focused fixes over unrelated refactoring or formatting.
- Use NSDebugLog for development diagnostics rather than adding noisy
  unconditional logging.
- Preserve existing license and copyright notices.

## Archive and document invariants

A successful save must produce an archive that reopens correctly.

For persistence changes, verify the affected object graph: ownership,
custom classes, names, actions/outlets, geometry, control state, resources,
and relevant metadata. Check object identity where connections depend on it.

- Preserve editor-to-runtime class substitution.
- Keep editor-only objects and incidental AppKit implementation subviews
  out of exported archives.
- Treat unkeyed class versions and encoding order as compatibility
  contracts. Test changes in a fresh process so initialization state
  cannot hide a broken archive.
- For XIB, distinguish symbolic enum values from ordinary numeric values
  such as tags. Cover missing optional fields and prototype cells where
  relevant.
- For NIB imports, preserve deterministic payload precedence and optional
  OPENSTEP support. A corrupt preferred payload must not silently select
  a different payload.
- Restore temporary document or archiver state on failure as well as
  success. Save/export errors must not leave the editor unusable.
- Preserve existing import compatibility. Do not accidentally restore
  removed archive-version downgrade controls.

## Build and runtime

Build from the repository root with GNUstep configured:

```sh
make
```

The aggregate build orders dependencies and copies plugins into the built
GormCore framework. Rebuild from the root after plugin changes before
testing conversions.

Confirm that tests and manual runs load the intended rebuilt libraries
and plugins. An installed older GormCore can mask changes. Some standalone
tests require installed frameworks; follow their README instructions.

Do not assume that a command-line tool is display-independent:
gormtool uses AppKit and conversion tests require a working GUI backend.

## Verification

Run tests appropriate to the change. Common commands from the root are:

```sh
# Full suite, with a working display/backend:
make -C Tests check

# Headless X11:
xvfb-run -a make -C Tests check

# Focused core or CLI coverage:
xvfb-run -a make -C GormCore/Tests check
xvfb-run -a make -C Tools/gormtool/Tests check
```

Use existing Testing.h conventions for Objective-C regression tests.
See Plugins/Xib/Tests/README.md for additional serialization tests.

For conversion changes, run the gormtool conversion matrix. It covers
gorm, nib, xib, and nix as inputs and outputs, plus export to cib and
gormcode. CIB import and gormcode loading are currently unsupported.

Do not rely on gormtool's exit status alone: it can report a load/save
failure while returning zero. Check diagnostics, nonempty output, and
reopen supported outputs in a separate process.

For UI changes, exercise the affected workflow in Gorm. For archived UI
resource changes, verify custom classes and outlet connections as well
as appearance. Local XML checks do not establish Xcode compatibility.

Report the commands run, results, skipped tests, and unverified behavior.
Never describe unavailable compiler/runtime coverage as tested.

## Scope and deliverables

- Inspect the working tree before editing; preserve unrelated changes.
- Keep generated build products and test logs out of commits.
- Edit generation inputs rather than generated version headers or plists.
- Change Version only when the task includes a version/release change.
- Avoid unrelated binary .gorm resource rewrites. When a resource change
  is necessary, explain it and verify that the resource still loads.
- Update relevant manuals or CLI documentation for user-visible changes.
- Summarize the behavior changed, the regression prevented, and validation.
