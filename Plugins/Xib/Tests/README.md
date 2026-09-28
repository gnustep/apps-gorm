# XIB serialization regression test

From the repository root, with GNUstep configured and GormCore installed:

```sh
make -C Plugins/Xib
clang $(gnustep-config --objc-flags) -I. Plugins/Xib/Tests/enums.m \
  -o /tmp/gorm-xib-enums -lGormCore -lInterfaceBuilder \
  -lGormObjCHeaderParser $(gnustep-config --gui-libs)
xvfb-run -a /tmp/gorm-xib-enums
```

The test loads the workspace XIB plugin, exercises real AppKit enum accessors,
and serializes a view containing a button, popup, and box. It checks symbolic
enum values, preservation of numeric tags, button-type collisions, and exclusion
of editor objects reachable through the key-view chain.

This checks XML output locally; it does not substitute for opening it in Xcode.

Coverage also includes progress indicators, sliders, browser runtime-subview
exclusion, and an outline view inside a scroll view with both scrollers. The
outline regression checks column/selection enum mappings, scroll elasticity,
scroller styles, document-view nesting, and exclusion of unused rulers and
inherited control cells.

The loader crash fixture omits both the matrix prototype and cellClass, as
Xcode can do when saving explicit cells. With the current plugin installed:

```sh
xvfb-run -a Tools/gormtool/obj/gormtool \
  --read Plugins/Xib/Tests/matrix-without-prototype.xib \
  --write /tmp/matrix-loaded.xib
```

The load must not crash, and the output must retain the two button cells,
their titles, and the first cell's selected state.

Native-save regressions (with the rebuilt GormCore and XIB plugin installed):

```sh
clang $(gnustep-config --objc-flags) -I. Plugins/Xib/Tests/custom-view-native.m \
  -o /tmp/gorm-custom-view-native -lGormCore -lInterfaceBuilder \
  -lGormObjCHeaderParser $(gnustep-config --gui-libs)
xvfb-run -a /tmp/gorm-custom-view-native
xvfb-run -a Tools/gormtool/obj/gormtool \
  --read Plugins/Xib/Tests/empty-form-custom-view.xib \
  --write /tmp/empty-form-custom-view.gorm
xvfb-run -a Tools/gormtool/obj/gormtool \
  --read /tmp/empty-form-custom-view.gorm --objects
```

The fresh-process native test checks the custom-view class version, frame,
autoresizing mask, and the object following it in the archive. The fixture
must save and reopen without an exception and list its window. Check the
output as well as the exit status: gormtool can report a load failure while
returning zero. `form-without-prototype.xib` additionally exercises populated
form cells through the same save/reopen path.
