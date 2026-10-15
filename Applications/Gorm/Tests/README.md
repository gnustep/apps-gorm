# Application tests

Build from the repository root with `make`, then run:

```sh
xvfb-run -a make -C Applications/Gorm/Tests check
```

The runner selects the rebuilt GormCore and supporting libraries. The panel
visibility test compiles the application delegate sources directly and uses
real NSApplication hide/deactivate notifications and real NSPanels. Lightweight
managers avoid loading palettes or opening documents.

The regression checks that quitting while inactive or hidden preserves panel
choices, that deliberate closures (including an independent library closure)
are saved, and that interface testing cannot overwrite those choices. This
exercises the notification ordering responsible for temporary invisibility,
which previously caused startup preferences to be saved as NO.

For a full application check, open the library, palettes and inspectors from
Tools, switch to another app or hide Gorm, then quit Gorm and relaunch. The
panels should return. Repeat after closing one panel deliberately; that panel
should remain closed. Existing saved NO values are respected: reopen the
panels once to establish the desired state.

The automated checks do not verify window-manager stacking, screen placement,
or the complete application menu workflow.
