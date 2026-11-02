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
`python3 Plugins/Nib/Tests/check.py --build-only` compiles the three native
regression executables without running them; this is not a test pass.
Use `--reader-only` to run translation, truncation, unsupported-version, and
mutation checks without creating AppKit windows.

The original fixture generator and decoder mutation test moved from libs-gui.
Fixtures and executables are generated in a temporary directory; no historical
third-party nib files are needed. `make-openstep-fixtures.py` can also generate
standalone fixtures in `OpenStepFixtures` for manual inspection.

Coverage:

* Streamer versions 3 and 4, both byte orders, window/button graphs, unnamed
  objects, owner custom class, fractional geometry, shared outlet identity,
  window-template replacement, action endpoints, and periodic button timing.
* Direct calls to the rebuilt plugin, plus OPENSTEP input conversion to gorm,
  nib, xib, gux, cib, and gormcode. Supported archive outputs reopen in separate
  gormtool processes and are inspected again through the importer. CIB and
  generated code are checked for nonempty output; neither supports import.
* Bundle payload precedence (keyedobjects.nib, objects.nib, data.nib), including
  corrupt, empty, and directory-valued preferred payloads. Editor state must
  be restored on success and failure.
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

The root build and compilation of all three regression executables succeeded
with the configured Clang/GNUstep runtime. The `--reader-only` tests passed for
both versions and byte orders, all tested truncations, scroll and minimum-size
layouts, unsupported versions, and decoder mutations/random inputs.

The sandbox cannot write the usual user defaults directory. An independent
Foundation/AppKit probe exposed recursion in NSUserDefaults/NSLog (confirmed
with AddressSanitizer). Validation used a temporary GNUSTEP_CONFIG_FILE copied
from the system configuration, with GNUSTEP_USER_DEFAULTS_DIR pointing to a
writable directory under /tmp, and file permissions 0600. No installed files
or user settings were changed.

With that configuration, the GUI import suite and the existing 24-case CLI
matrix still cannot run: AppKit reports NSWindowServerCommunicationException,
and independent `xdpyinfo` also fails to connect to the Xvfb display. These are
failed/blocked checks, not passes. Manual UI and GCC coverage remain unverified.
Rerun the full commands above with a working display before acceptance.

This is an AI-assisted contribution. POLICY_AI.md requires independent human
review before acceptance; the coverage described above still needs to pass.
