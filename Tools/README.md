# gormtool

`gormtool` is a command-line front end for selected Gorm document operations.
It runs as a headless AppKit application, loads a `.gorm` document, performs one
or more actions, optionally writes the modified document back out, and then exits.

The implementation lives in `Tools/gormtool/` and the option list below matches
the currently parsed and executed arguments in that code.

## Synopsis

```sh
gormtool [options] inputfile
gormtool --read inputfile [options]
```

## Input File Rules

- `--read FILE` explicitly selects the input document.
- If `--read` is omitted, `gormtool` treats the last argument as the input file.
- The last-argument fallback is only used when its extension matches a registered
 Gorm document type.
- If no readable document is resolved, the tool prints `No document specified`
 and exits.

## Execution Model

- The tool opens the input document first.
- Most options are then processed in the order implemented by `AppDelegate.m`,
 not strictly in the order they appear on the command line.
- `--write` is intentionally processed near the end, after import/export and
 inspection actions.
- `--test` is processed last and keeps the application running until you stop it.

## Options

### Document I/O

- `--read FILE`
 Load the specified Gorm document.

- `--write FILE`
 Save the possibly modified document to `FILE`.

 Notes:
 	- The document type is inferred from `FILE`'s extension.
 	- If the save fails, the tool logs an error.
 	- This does not happen automatically after an import. Use `--write` when you
  want modifications persisted.

- `--output-path DIR`
 Directory used by `--export-class` when writing generated `.h` and `.m` files.
 If omitted, the default is `./`.

### Strings Export and Import

- `--export-strings-file FILE`
 Export the document's localizable strings to `FILE`.

- `--import-strings-file FILE`
 Import translations or replacements from a `.strings` file into the loaded
 document.

 Notes:
 	- This updates the in-memory document.
 	- Use `--write` as well if you want the modified `.gorm` saved.

### XLIFF Export and Import

- `--export-xliff FILE`
 Export the document to an XLIFF 1.2 file at `FILE`.

- `--import-xliff FILE`
 Import translations from the XLIFF file at `FILE` into the loaded document.

- `--source-language LANG`
 Source language passed to XLIFF export.

- `--target-language LANG`
 Optional target language passed to XLIFF export.

 Notes:
 	- `--source-language` is effectively required for `--export-xliff`.
 	- If no source language is supplied, the tool logs `Please specify a source language`.
 	- `--import-xliff` does not require language flags.
 	- As with strings import, `--import-xliff` only changes the in-memory document
  unless `--write` is also supplied.

### Class Import and Export

- `--import-class HEADER`
 Parse the Objective-C header at `HEADER` and import the class information into
 the document's class manager.

 Notes:
 	- The delegate is implemented to allow breaking existing connections when a
  reparsed class changes incompatibly.
 	- Parse failures are logged.

- `--export-class CLASSNAME`
 Generate source files for `CLASSNAME` using the document's class information.

 Output:
 	- `CLASSNAME.h`
 	- `CLASSNAME.m`

 Notes:
 	- Files are written into `--output-path` if supplied, otherwise the current
  directory.
 	- If the class cannot be exported, the tool logs `Class named ... not saved`.

### Inspection and Reporting

These flags print internal document data structures to standard output.

- `--connections`
 Print the document's connection objects.

- `--classes`
 Print the custom class information dictionary.

- `--objects`
 Print the document's top-level objects.

- `--errors`
 Print the current file preferences profile.

- `--warnings`
 Print the current file preferences profile.

- `--notices`
 Print the current file preferences profile.

 Important:
 	- In the current implementation, `--errors`, `--warnings`, and `--notices`
  all print the same profile dictionary from `GormFilePrefsManager`.
 	- They are not currently filtered into separate categories by `gormtool`.

### Interactive Test Mode

- `--test`
 Enter test mode after processing all other options.

 Behavior:
 	- The tool logs `Control-C to end`.
 	- The application remains running instead of terminating immediately.

## Examples

### Export a strings file

```sh
gormtool MyDocument.gorm --export-strings-file Localizable.strings
```

### Import a strings file and save to a new document

```sh
gormtool --read MyDocument.gorm \
 --import-strings-file fr.strings \
 --write MyDocument-fr.gorm
```

### Export XLIFF with an explicit source language

```sh
gormtool MyDocument.gorm \
 --source-language en \
 --target-language fr \
 --export-xliff MyDocument.xliff
```

### Import XLIFF and persist the modified document

```sh
gormtool --read MyDocument.gorm \
 --import-xliff MyDocument-fr.xliff \
 --write MyDocument-fr.gorm
```

### Export a custom class into a chosen directory

```sh
gormtool MyDocument.gorm \
 --output-path ./Generated \
 --export-class MyCustomView
```

### Print top-level objects and connections

```sh
gormtool MyDocument.gorm --objects --connections
```

## Practical Notes

- Multiple options can be combined in a single run.
- Actions that modify the document do not imply saving.
- Unknown options are not documented here because this file only covers options
 explicitly parsed by the current source.
- This tool is still best treated as experimental. Validate output when using it
 in automation.
