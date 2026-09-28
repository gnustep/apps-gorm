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
