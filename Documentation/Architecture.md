# Application and framework architecture

Gorm has a useful build and reuse boundary between its application and
framework, but GormCore remains coupled to editor UI and application state.
It is a reusable interface editor framework, not an independent,
display-free document processing library. This distinction matters when
adding shared behavior, extending gormtool, or embedding Gorm in another host.

## Current responsibilities

| Component | Responsibility |
| --- | --- |
| InterfaceBuilder | Extension protocols and compatibility APIs for documents, editors, inspectors, connectors, resources, and plugins. |
| GormObjCHeaderParser | Objective-C header parsing used by class tooling. |
| GormCore | Document graphs, class metadata, persistence coordination, editors, inspectors, preferences, and plugin/palette managers. |
| Plugins | Format-specific archive loaders and builders. |
| Applications/Gorm | Application entry point, concrete application delegate, language controller, application resources, and bundled palettes. |
| Tools/gormtool | Command-line orchestration of shared document operations. |

The [root build](../GNUmakefile) orders InterfaceBuilder and the header parser
before GormCore, then plugins, applications, tools, and tests. The
[post-build step](../GNUmakefile.postamble) copies format plugins into the built
GormCore framework resources. Plugin discovery therefore depends on deployment
as well as linkage.

The [application target](../Applications/Gorm/GNUmakefile) compiles only its
delegate, language controller, and entry point as its main source files;
palettes are separate subprojects. Both the
[GUI delegate](../Applications/Gorm/GormAppDelegate.h) and the
[tool delegate](../Tools/gormtool/AppDelegate.h) inherit from
`GormAbstractDelegate`. This is a real reuse boundary: shared operations do
not need to be implemented independently in each front end.

## Coupling across the boundary

### Editor UI lives in the framework

The [GormCore target](../GormCore/GNUmakefile) contains document windows,
inspectors, palette management, preference panes, and their archived UI
resources. [GormAbstractDelegate](../GormCore/GormAbstractDelegate.m) also
coordinates interface testing, including application menus and windows.
These are substantial interactive responsibilities, not just data services.
Their presence is appropriate for an editor framework, but limits reuse by
hosts that only want archive operations.

### Framework objects use global application state

[GormConnectionInspector](../GormCore/GormConnectionInspector.m) accesses
the active document, class manager, and connection state through `NSApp`'s
delegate. [GormObjectEditor](../GormCore/GormObjectEditor.m) similarly obtains
connection and inspector services from the delegate.
[GormDocument](../GormCore/GormDocument.m) combines object graph and persistence
operations with editor lifecycle, window management, and selection handling.

The [GormAppDelegate protocol](../GormCore/GormProtocol.h) formalizes some of
this host contract. It combines manager access, connection UI, class menus,
and an `isInTool` distinction. A protocol provides an extension point, but
global delegate lookup still makes the host dependency implicit at call sites.
Embedding code must account for the services used by its chosen workflows;
linking the framework alone does not supply a complete editing environment.

### Command-line operation still needs AppKit

[gormtool's entry point](../Tools/gormtool/main.m) creates an `NSApplication`,
installs its delegate, and processes commands without entering the GUI event
loop. AppKit initialization is required to decode interface objects. Here,
"headless" means operating without the interactive Gorm UI; it does not mean
display-independent. Conversion tests need a working GNUstep GUI backend and,
with X11, a display such as Xvfb.

Separating editor coordination from document services would reduce host
coupling, but would not remove the need for AppKit when constructing archived
windows, views, or controls.

## Guidance for new development

- Put shared document behavior in GormCore so both the GUI and gormtool use it.
  Keep command parsing and application launch integration in their front ends.
- Keep format-specific compatibility fixes in the relevant plugin. In
  particular, GUX repairs belong in Plugins/Gux, not general nib archiving.
- Prefer passing the document or required service explicitly for new shared
  operations rather than discovering it through the active application.
  Avoid introducing new tool-versus-GUI branches where an explicit capability
  or policy supplied by the host would suffice.
- Keep interactive presentation separate from reusable operations where
  practical. Let the host decide how to present an operation's failure, while
  preserving existing API and error behavior for current callers.
- Preserve public InterfaceBuilder and GormCore contracts, manual memory
  management, and compatibility with supported GNUstep compilers and runtimes.
  Do not move existing UI classes merely to make directory names look cleaner.

## Possible incremental improvements

These are future directions, not services or layering guarantees that exist
today. Start with a concrete shared workflow and its regression coverage.

1. Isolate its document and persistence operations from selection, windows,
   alerts, and connection presentation.
2. Introduce narrow service contracts or explicit parameters at that boundary,
   retaining adapters for existing delegate-based callers.
3. Have Gorm and gormtool supply the required services and presentation policy.
4. Consider a separate editor UI layer only after the dependencies are clear.
   Preserve class names, resource lookup, plugin loading, and archive behavior
   when moving implementation between targets.

The goal is independently usable document operations within their actual
AppKit requirements. A large framework split is not a prerequisite for
improving individual boundaries.

## Verification for boundary changes

Read [POLICY_AI.md](../POLICY_AI.md) before preparing AI-assisted contributions;
it requires tests, independent human review before acceptance, and disclosure
when AI materially shapes a submission.

Build from the repository root with GNUstep configured, especially after
plugin changes. Confirm that tests load the rebuilt framework and plugins;
an older installed copy can hide a regression. Follow component test READMEs
where installation is required.

```sh
make
xvfb-run -a make -C GormCore/Tests check
xvfb-run -a make -C Tools/gormtool/Tests check
# Full suite with an X11 backend:
xvfb-run -a make -C Tests check
```

For persistence or conversion changes, use the conversion coverage described
in [gormtool's test README](../Tools/gormtool/Tests/README.md) and the additional
[XIB serialization tests](../Plugins/Xib/Tests/README.md). Cover gorm, nib, xib,
and gux inputs and outputs, plus cib and gormcode export. CIB import and
gormcode loading are unsupported. Check diagnostics and nonempty output,
then reopen supported outputs in a separate process; gormtool's exit status
alone does not establish success.

Assert ownership, custom classes, names, actions/outlets, geometry, control
state, resources, metadata, and object identity where connections depend on
it. Preserve editor-to-runtime class substitution and keep editor-only objects
and incidental AppKit subviews out of exported archives. Fresh-process tests
must cover unkeyed class versions and encoding order. Exercise failure paths
to verify restoration of temporary document and archiver state.

For UI or archived resource changes, exercise the affected workflow in Gorm
and verify custom classes and outlets as well as appearance. Explain what each
test covers, why that coverage is sufficient for the change, and which failures
it prevents. Report commands, results, skipped coverage, and unverified
compiler/runtime behavior explicitly.
