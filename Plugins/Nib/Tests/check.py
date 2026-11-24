#!/usr/bin/env python3
"""Exercise Gorm's own OPENSTEP importer and fresh-process CLI conversions."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import importlib.util
import sys
sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def config(option):
    return shlex.split(subprocess.check_output(['gnustep-config', option], text=True))


def main():
    libraries = [ROOT / 'GormCore/GormCore.framework/Versions/Current',
                 ROOT / 'InterfaceBuilder/obj', ROOT / 'GormObjCHeaderParser/obj']
    env = os.environ.copy()
    env['LD_LIBRARY_PATH'] = os.pathsep.join(map(str, libraries)) + ':' + env.get('LD_LIBRARY_PATH', '')
    with tempfile.TemporaryDirectory(prefix='gorm-openstep-') as tmp:
        tmp = Path(tmp)
        spec = importlib.util.spec_from_file_location('fixtures', HERE / 'make-openstep-fixtures.py')
        fixtures = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(fixtures)
        exe = tmp / 'import'
        makefiles = config('--variable=GNUSTEP_MAKEFILES')[0]
        command = config('--variable=CC') + config('--objc-flags')
        command += ['-I' + str(ROOT), '-I' + str(Path(makefiles) / 'TestFramework')]
        command += [str(HERE / 'import.m')]
        command += ['-o', str(exe)] + ['-L' + str(p) for p in libraries]
        command += ['-lGormCore', '-lInterfaceBuilder', '-lGormObjCHeaderParser'] + config('--gui-libs')
        subprocess.run(command, cwd=tmp, check=True)

        proxy = tmp / 'proxy'
        proxy_command = command[:command.index(str(HERE / 'import.m'))]
        proxy_command += [str(HERE / 'proxy.m'),
                          str(HERE.parents[1] / 'Gorm/GormGormWrapperBuilder.m')]
        proxy_command += ['-o', str(proxy)] + ['-L' + str(p) for p in libraries]
        proxy_command += ['-lGormCore', '-lInterfaceBuilder', '-lGormObjCHeaderParser'] + config('--gui-libs')
        subprocess.run(proxy_command, cwd=tmp, check=True)

        translator = tmp / 'translate'
        decoder = tmp / 'typedstream'
        common = config('--variable=CC') + config('--objc-flags')
        common += ['-I' + str(HERE.parent), '-I' + str(Path(makefiles) / 'TestFramework')]
        subprocess.run(common + [str(HERE / 'translate.m'),
            str(HERE.parent / 'GormOpenStepNibReader.m'),
            str(HERE.parent / 'GormOpenStepTypedStream.m'), '-o', str(translator)]
            + config('--gui-libs'), cwd=tmp, check=True)
        subprocess.run(common + ['-x', 'objective-c', str(HERE / 'typedstream.c'),
            str(HERE.parent / 'GormOpenStepTypedStream.m'), '-o', str(decoder)]
            + config('--base-libs'), cwd=tmp, check=True)
        if '--build-only' in sys.argv:
            print('All four regression executables compiled (not run)')
            return

        def run(args):
            result = subprocess.run(list(map(str, args)), cwd=ROOT, env=env,
                                    capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            errors = ('Failed test',) if 'reject' in args else (
                'Failed test', 'Load failed', 'Failed to load', 'Failed to save',
                'export failed', 'was not saved')
            if result.returncode or any(text in output for text in errors):
                raise AssertionError(f'{args}: exit {result.returncode}\n{output}')
            return output

        for mode in ('write', 'editor', 'runtime'):
            print(run([proxy, mode, tmp / 'proxy.gorm']), end='')

        for version in (3, 4):
            for order in ('<', '>'):
                writer = fixtures.Writer(order, version)
                writer.group('@', [fixtures.document(views=True)])
                source = tmp / f'window-{version}-{ord(order)}.nib'
                source.write_bytes(writer.data)
                run([translator, source])
                if '--reader-only' in sys.argv:
                    continue
                print(run([exe, source]), end='')
                for extension in ('gorm', 'nib', 'xib', 'gux', 'cib', 'gormcode'):
                    destination = tmp / f'{source.stem}.{extension}'
                    # Do not overwrite the original standalone nib.
                    destination = tmp / ('converted-' + destination.name)
                    output = run([ROOT / 'Tools/gormtool/obj/gormtool', '--read', source, '--write', destination])
                    payload = destination
                    if extension in ('gorm', 'nib'):
                        payload = destination / ('objects.gorm' if extension == 'gorm' else 'keyedobjects.nib')
                    elif extension == 'gormcode':
                        payload = destination / 'GeneratedGorm.m'
                        assert (destination / 'GeneratedGorm.h').stat().st_size > 0, output
                    assert payload.is_file() and payload.stat().st_size > 0, output
                    if extension in ('gorm', 'nib', 'xib', 'gux'):
                        reopened = tmp / f'reopened-{source.stem}-{extension}.nib'
                        output = run([ROOT / 'Tools/gormtool/obj/gormtool', '--read', destination, '--write', reopened])
                        assert (reopened / 'keyedobjects.nib').stat().st_size > 0, output
                        # Periodic timing has integer precision in ordinary keyed nibs.
                        # Inspect the other graph invariants after a fresh-process reopen.
                        print(run([exe, reopened, 'roundtrip']), end='')
        # The reader's string-encoding decision:  Rhapsody and Mac OS X
        # (system version 1000 or above) wrote strings as UTF-8, so prefer
        # UTF-8 per string and fall back to NEXTSTEP for one that is not
        # valid UTF-8;  NeXTSTEP/OpenStep (930 or below) wrote single-byte
        # NEXTSTEP text, and a NEXTSTEP byte can spell a valid UTF-8
        # sequence, so never guess UTF-8 there.  The big-endian version 4
        # header matches every real file of the 1998 corpus.
        # Expected values follow GNUstep's NEXTSTEP character set, in which
        # for example 0xE2 is U+00ED (i-acute) and 0xE9 is U+00D8 (O-stroke).
        # (Loop-local names:  the legacy bundle section below reuses the
        # matrix's writer and source, so do not clobber them here.)
        for system_version, title, want_title in (
            (1000, b"0.0\xe2\x80\x941.0", "0.0\u20141.0"),   # UTF-8 em dash
            (1000, b"\xdd", "\u00e9"),                       # invalid UTF-8
            ( 930, b"0.0\xe2\x80\x941.0", "0.0\u00ed\u00a0\u00d41.0"),
        ):
            uwriter = fixtures.Writer(">", 4, system_version)
            uwriter.group("@", [fixtures.document(views=True, title=title)])
            usource = tmp / f"unicode-v4-{system_version}-{title.hex()[:4]}.nib"
            usource.write_bytes(uwriter.data)
            print(run([translator, usource]), end='')
            print(run([exe, usource, "unicode", want_title]), end='')
            udestination = tmp / f"unicode-{system_version}-{title.hex()[:4]}.gorm"
            output = run([ROOT / 'Tools/gormtool/obj/gormtool', '--read', usource, '--write', udestination])
            assert (udestination / 'objects.gorm').stat().st_size > 0, output
            ureopened = tmp / f"unicode-reopened-{system_version}-{title.hex()[:4]}.nib"
            output = run([ROOT / 'Tools/gormtool/obj/gormtool', '--read', udestination, '--write', ureopened])
            assert (ureopened / 'keyedobjects.nib').stat().st_size > 0, output
            print(run([exe, ureopened, "unicode", want_title]), end='')
        for name, graph in [('objects', fixtures.document()),
                            ('scroll', fixtures.scroll_document()),
                            ('min-size', fixtures.document(views=True, window_min_size=True)),
                            ('unsupported', fixtures.document(bad_version=True))]:
            extra = fixtures.Writer('<', 4)
            extra.group('@', [graph])
            path = tmp / (name + '.nib')
            path.write_bytes(extra.data)
            run([translator, path] + (['reject'] if name == 'unsupported' else []))
            if name == 'objects':
                print(run([decoder, path]), end='')
        if '--reader-only' in sys.argv:
            print('Reader translation, truncation, version and decoder mutation checks passed')
            return
        bundle = tmp / 'legacy.nib'
        bundle.mkdir()
        (bundle / 'data.nib').write_bytes(writer.data)
        print(run([exe, bundle]), end='')
        (bundle / 'objects.nib').write_bytes(writer.data)
        (bundle / 'data.nib').write_bytes(b'bad')
        print(run([exe, bundle]), end='')
        (bundle / 'keyedobjects.nib').write_bytes(b'bad')
        print(run([exe, bundle, 'reject', source]), end='')
        (bundle / 'keyedobjects.nib').write_bytes(b'')
        print(run([exe, bundle, 'reject', source]), end='')
        (bundle / 'keyedobjects.nib').unlink()
        (bundle / 'keyedobjects.nib').mkdir()
        print(run([exe, bundle, 'reject', source]), end='')
        print('OPENSTEP import and conversion checks passed')


if __name__ == '__main__':
    main()
