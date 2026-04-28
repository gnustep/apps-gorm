# GormObjCHeaderParser Library

## Overview

GormObjCHeaderParser is a lightweight Objective-C header parser used by the
apps-gorm project to extract class metadata from Objective-C source headers.

Its primary purpose is to support Gorm class tooling workflows, especially
importing and reflecting class/interface information such as:

- Class names and superclasses
- Methods and selectors
- Action-like methods
- Instance variables and outlet-like ivars
- Property declarations

The parser is intentionally simple and scanner-based. It is designed for fast
metadata extraction, not full Objective-C language conformance.

## Where It Fits In apps-gorm

This library is built as its own module and consumed by higher-level Gorm
components that need Objective-C class information when importing headers.

Build order context in the repository places this module before GormCore so
the framework can be linked by downstream targets.

## Public API Surface

Primary umbrella header:

```objc
#import <GormObjCHeaderParser/GormObjCHeaderParser.h>
```

Main public types:

- `OCHeaderParser`: top-level parser for a header file
- `OCClass`: parsed class/category representation
- `OCMethod`: parsed method representation
- `OCIVar`: parsed ivar representation
- `OCIVarDecl`: parser for ivar declaration lines with multiple ivars
- `OCProperty`: property representation (subclass of `OCIVar`)
- `NSScanner (OCHeaderParser)`: scanner helpers for inclusive scanning
- `ParserFunctions`: small look-ahead helpers

## Data Model

### OCHeaderParser

`OCHeaderParser` is created from a file path and stores parse results in an
internal classes array.

Key methods:

- `-initWithContentsOfFile:`
- `-parse`
- `-classes`

`-parse` returns `YES` when at least one class/interface block is parsed.

### OCClass

`OCClass` stores the parsed declaration and members:

- Class name
- Superclass name (if present)
- Category flag
- Methods
- Ivars
- Properties
- Protocol list storage (present in the model)

### OCMethod

`OCMethod` extracts:

- Selector name
- Class method vs instance method
- Action-like flag (`isAction`)

The action flag is inferred from common signatures (for example `IBAction`,
`void`, `id`, and selector forms ending in `:` with compatible argument
patterns).

### OCIVar and OCIVarDecl

`OCIVar` stores ivar name and whether it is treated as an outlet-like ivar.
`OCIVarDecl` parses declaration lines and supports comma-separated ivars while
propagating outlet state.

### OCProperty

`OCProperty` currently inherits parsing behavior from `OCIVar` and acts as a
property model type.

## Parsing Pipeline

The parser performs a preprocessing stage before extracting interfaces:

1. Strip line comments (`// ...`)
2. Strip block comments (`/* ... */`)
3. Strip preprocessor lines beginning with `#`
4. Collapse redundant semicolon runs

Then it scans for `@interface ... @end` blocks and parses each block into an
`OCClass` instance.

Within a class parse, it identifies:

- Interface line and class/superclass/category details
- Ivar block (if present)
- Methods (semicolon-terminated declarations)
- Properties (semicolon-terminated lines scanned over class text)

## Usage Example

```objc
#import <Foundation/Foundation.h>
#import <GormObjCHeaderParser/GormObjCHeaderParser.h>

NSString *path = @"MyWidgetController.h";
OCHeaderParser *parser = [[OCHeaderParser alloc] initWithContentsOfFile:path];

if ([parser parse]) {
  for (OCClass *cls in [parser classes]) {
    NSLog(@"Class: %@", [cls className]);
    NSLog(@"Superclass: %@", [cls superClassName]);

    for (OCMethod *m in [cls methods]) {
      NSLog(@"  Method: %@ action=%d classMethod=%d",
            [m name], [m isAction], [m isClassMethod]);
    }

    for (OCIVar *v in [cls ivars]) {
      NSLog(@"  Ivar: %@ outlet=%d", [v name], [v isOutlet]);
    }
  }
}
```

## Build

From this directory:

```sh
make
make install
```

The module is built as `GormObjCHeaderParser` and installs public headers for
use by other apps-gorm modules or external consumers.

## Testing

The `Tests/` directory currently contains test harness make logic but no parser
test source files are present in this module directory at this time.

You can still run the make target entry point:

```sh
cd Tests
make check
```

If parser tests are added, this is the intended execution path.

## Limitations and Behavior Notes

This is not a full compiler-grade Objective-C parser. Important notes:

- Preprocessor lines are removed early, so macro-heavy declarations may not be
  interpreted as expected.
- Parsing is mostly token/substring based and assumes semicolon-terminated
  declaration forms.
- Complex modern Objective-C syntax may require future parser enhancements.
- Property parsing currently reuses ivar parsing behavior via `OCProperty`
  inheritance.

For Gorm's metadata import workflows, this tradeoff is typically acceptable and
keeps parsing fast and dependency-light.

## License

License headers in this module are mixed by file (historical GNUstep code plus
newer additions). Refer to individual source file headers for authoritative
terms, and to repository-level license files for project-wide context.
