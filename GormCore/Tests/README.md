# GormCore tests

Build from the repository root, then run with GNUstep and a working GUI backend:

```sh
make
xvfb-run -a make -C GormCore/Tests check
```

The runner selects the checkout's framework and supporting libraries through
its include, link, and runtime library paths.

`documentServices.m` covers the boundary between document operations and host
policy. Two documents use opposing policies while a global delegate is present;
connection removal must honor each document's policy and preserve connector
identity when refused. Clearing the explicit policy tests the compatibility
path used by existing application delegates.

The metadata drag callback is checked for a `BOOL` return signature and an
explicit refusal of unsupported exports. This prevents a protocol mismatch
and an undefined return value from being interpreted as a successful drag.

Controlled wrapper builders and loaders exercise exceptions, rejected payloads,
missing input, invalid arguments, and successful retries. The tests verify
error results, editor reactivation, preservation of the pending archive upgrade
decision after construction failure, and caller-owned document registration.
These checks prevent global policy leakage, modal controller error handling,
and unusable editor state after a builder fails.

These controlled wrappers test service behavior, not archive fidelity. Run
[the gormtool conversion matrix](../../Tools/gormtool/Tests/README.md) for real
formats and fresh-process reopening, and the aggregate suite for plugin graph,
custom-class, geometry, and connection-identity regressions. Together these
checks cover the service migration and its compatibility with existing loaders
and builders; they do not establish support for unavailable runtimes or replace
manual verification of interactive workflows.

`objectInspector.m` loads the actual fallback inspector resource and exercises
its property table, value field, and apply/revert actions with an inherited fixture.
It covers every supported scalar encoding, full-width integer limits, double
precision, is-prefixed getters, mismatched signatures, write-only setters,
string whitespace, nil values, getter/setter exceptions, and selection clearing.
Invalid edits must call neither the setter nor the document touch hook; valid
edits must touch once and remain possible after an error. These checks guard
against ABI mismatches, truncation, silent invalid-input conversion, stale
selection state, and exceptions escaping into the event loop. The test prints
the loaded framework resource path so an installed copy cannot silently mask
the intended build. This is control-level coverage, not a substitute for an
interactive inspection workflow in the Gorm application.

Table coverage checks all three columns, values in unselected rows, isolated
getter errors, explicit unknown values, dependent-row refresh after edits,
and clearing rows and selection when switching objects. Together with the
existing scalar edit tests, this verifies that the new presentation preserves
the edit path and does not mutate the document just by displaying values.
