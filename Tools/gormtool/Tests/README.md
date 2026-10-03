# gormtool tests

Build the checkout with `make`, then run:

```sh
make -C Tools/gormtool/Tests check
```

The conversion tests require Python 3 and a working GNUstep GUI backend/display.
For a headless X11 run, use:

```sh
xvfb-run -a make -C Tools/gormtool/Tests check
```

`conversions.py` runs the built gormtool using the checkout's libraries and
plugins. It creates inputs from a small XIB fixture in a temporary directory,
then tests all 16 ordered pairs of `gorm`, `nib`, `xib`, and `nix`
(including same-format saves). Every output must contain a nonempty archive
and reopen in a separate process with its window, nested button, titles, and
button tag preserved. The four input formats also export to `cib` and
`gormcode`, for 24 conversion cases total. CIB keyed archives are parsed and
checked for their envelope, UID references, root graph, ownership, window
template, button, titles, numeric tag and geometry encoding; generated Objective-C
headers/sources and titles are checked. CIB import is explicitly unimplemented
and `gormcode` has no loader, so these export-only formats are not input rows.
Each CLI invocation has a 30-second timeout.

To run only the conversion matrix:

```sh
python3 Tools/gormtool/Tests/conversions.py
```

For native CIB graph regressions and optional validation with Cappuccino's actual
decoder and loader, see `Plugins/Cib/Tests/README.md`.
