# CIB archive regression tests

Build from the repository root, then run with a working GNUstep GUI backend:

```sh
make
xvfb-run -a make -C Plugins/Cib/Tests check
```

The test is also included in `make -C Tests check`. The runner uses the configured
GNUstep compiler, rebuilds the exporter source with the native fixture, and loads
this checkout's GormCore, InterfaceBuilder and header parser libraries. Build
products and archives live in a temporary directory.

`archive.m` uses real AppKit windows and controls with controlled document
metadata. Its Testing.h checks cover repeated exports, unsupported-class failure,
and reuse of the graph after a failed export. `check.py` independently follows
UIDs and checks the keyed archive envelope, class records, object identity,
ownership, custom classes, names, action/outlet connections, first responder,
window visibility metadata, numeric tags, enabled/selected state, geometry,
autoresizing, named image resources and scroll/clip/document-view ownership. Two objects deliberately have names
`NSButton(1)` and `NSButton(2)` to catch the former identifier collision. Editor
connections are included in the source fixture and must not reach the archive.

The gormtool conversion matrix separately verifies the built plugin for all four
supported input formats; its CIB assertions inspect the keyed archive rather than
the former custom property-list schema:

```sh
xvfb-run -a python3 Tools/gormtool/Tests/conversions.py
```

## Independent Cappuccino runtime validation

With Cappuccino's Objective-J runner and built Foundation/AppKit frameworks:

```sh
CIB_OBJJ=/path/to/objj \
CIB_OBJJ_FLAGS='-I/path/to/Frameworks' \
xvfb-run -a make -C Plugins/Cib/Tests check
```

`load.j` runs in a fresh process. It uses Cappuccino's actual CPKeyedUnarchiver,
instantiates the window and custom button, establishes the connections, and
checks their identity, geometry and state, including a nested scroll view and
text field. It also exercises CPCib's complete
instantiation entry point. Image-resource awakening is disabled for this test;
it checks resource names and sizes, not loading assets from an application's
bundle. This is not a browser rendering test. Without `CIB_OBJJ`, the runner
explicitly reports the runtime check as skipped.

These checks prevent a syntactically valid plist from being mistaken for a
loadable CIB, and detect dropped/merged objects or incorrectly restored
connections. They do not establish complete Cocoa-to-Cappuccino property parity
for every control or compatibility with every Cappuccino release.

## Format contract

CIB uses a CPKeyedArchiver archive, including `$top`, `$objects`, `$archiver`,
`$version`, `CP$UID` references and class descriptors. The top key is
`CPCibObjectDataKey`, referencing `_CPCibObjectData`; its object/parent arrays,
connections and window templates drive runtime instantiation. XML plist is a
supported container; changing the container to `280NPLIST` would not fix an
incorrect object graph.

The implementation follows the Cappuccino sources, rather than treating the
old Gorm exporter or its tests as a specification:

- https://github.com/cappuccino/cappuccino/blob/master/Foundation/CPKeyedArchiver.j
- https://github.com/cappuccino/cappuccino/blob/master/Foundation/CPKeyedUnarchiver.j
- https://github.com/cappuccino/cappuccino/blob/master/AppKit/Cib/CPCib.j
- https://github.com/cappuccino/cappuccino/blob/master/AppKit/Cib/_CPCibObjectData.j
- https://github.com/cappuccino/cappuccino/blob/master/AppKit/Cib/_CPCibWindowTemplate.j

CIB import remains unsupported. Custom Objective-J classes and named resources
must be supplied by the consuming Cappuccino application. Unsupported runtime
classes, unnamed images and unsupported connector types (including bindings)
fail export instead of inventing a class name or silently omitting a connection.

Class mappings currently cover windows/panels, views/custom views, buttons/popups,
text fields (including secure fields), boxes, image views, scroll/clip views and
scrollers, tab views/items, menus/items and custom-object proxies. Text views,
tables/outlines, browsers and split views are rejected: their old class-name-only
mappings did not encode the required text system, cell prototypes or internal
layout. Supporting those requires dedicated coders and runtime regressions;
export must not silently turn them into incomplete controls.
