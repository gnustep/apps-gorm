OPENSTEP nib import regression tests
===================================

Build from the repository root with `make`, then run:

```
xvfb-run -a make -C Plugins/Nib/Tests check
xvfb-run -a python3 Tools/gormtool/Tests/conversions.py
```

The aggregate `make -C Tests check` includes this suite. Python 3, GNUstep's
Testing.h, and a working AppKit backend are required. The runner uses the
checkout's rebuilt GormCore, InterfaceBuilder, parser, and bundled plugins.
`python3 Plugins/Nib/Tests/check.py --build-only` compiles the four native
regression executables without running them; this is not a test pass.
Use `--reader-only` to run proxy archive, translation, truncation,
unsupported-version, and mutation checks without creating AppKit windows.

The original fixture generator and decoder mutation test moved from libs-gui.
Fixtures and executables are generated in a temporary directory; no historical
third-party nib files are needed. `make-openstep-fixtures.py` can also generate
standalone fixtures in `OpenStepFixtures` for manual inspection.

Coverage:

* Streamer versions 3 and 4, both byte orders, window/button graphs, unnamed
  objects, owner custom class, fractional geometry, shared outlet identity,
  window-template replacement, action endpoints, and periodic button timing.
  Fractional origins and dimensions and owner outlet sources are checked
  after each supported round trip. This catches XIB rounding and placeholder
  ordering errors, duplicate proxy coding in NIB, and lost GUX owner classes,
  custom-object proxies, window identifiers, or connection metadata.
* Direct calls to the rebuilt plugin, plus OPENSTEP input conversion to gorm,
  nib, xib, gux, cib, and gormcode. Supported archive outputs reopen in separate
  gormtool processes and are inspected again through the importer. CIB and
  generated code are checked for nonempty output; neither supports import.
* Bundle payload precedence (keyedobjects.nib, objects.nib, data.nib), including
  corrupt, empty, and directory-valued preferred payloads. Editor state must
  be restored on success and failure.
* Custom owners and objects without a classes.nib companion are registered
  with an NSObject superclass. The importer checks their class metadata and
  connected object identity; the fresh-process conversion checks guard against
  treating an unlinked custom class as the runtime superclass during export.
* A display-independent test exercises the Gorm builder's template selection
  for custom-object proxies. Separate processes write the archive, reopen it
  as editor proxies, and instantiate runtime objects. It checks custom class
  names, shared identity, and trailing archive fields. This prevents wrapping
  a GSNibItem payload in an incompatible superclass template: the previous
  builder reproduces `expected object and got struct` in this test.
* Translation of scroll-view and window minimum-size layouts; every truncation
  of the tested graphs; useful rejection of unsupported class versions; decoder
  mutation, random input, excessive type nesting, and oversized array lengths.

These checks target the migration boundaries: plugin ownership, complete graph
import rather than just named objects, deterministic bundle selection, and
archive reopening without relying on the previous process's initialization.
They do not establish compatibility with every historical class/layout or
replace manual testing of Gorm's Open and Save workflow. Periodic timing is
checked on direct OPENSTEP import; ordinary keyed nib coding has lower timing
precision and is outside the scope of this move.

Validation in this workspace
----------------------------

With the configured Clang/GNUstep runtime and a working Xvfb display:

```
make
xvfb-run -a make check
```

Both commands passed. The aggregate run includes all four OPENSTEP version /
byte-order combinations, fresh-process archive reopening, the proxy editor
and runtime checks, CIB structural checks, application and palette checks, and
all 24 CLI conversion cases. The standalone XIB enum/geometry regression also
passed with the checkout's plugin and libraries (see Plugins/Xib/Tests/README.md).

These checks reproduce the failing conversion paths and inspect custom classes,
connection endpoints and identity, and fractional geometry after reopening.
They prevent silent graph loss as well as the proxy encoding exceptions.
The CIB test includes a cell-based action and verifies that its exported source
is the owning control.

The optional Cappuccino runtime check was skipped because CIB_OBJJ is not
configured. Manual Gorm UI, Xcode, and GCC coverage remain unverified. Earlier
sandbox display/defaults restrictions no longer blocked this Xvfb run.

This is an AI-assisted contribution. POLICY_AI.md requires independent human
review before acceptance.
