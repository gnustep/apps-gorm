#!/usr/bin/env python3
"""Exercise every supported gormtool input/output format through the CLI."""

import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
TOOL = ROOT / "Tools/gormtool/obj/gormtool"
FIXTURE = Path(__file__).resolve().parent / "fixtures/conversion.xib"
FORMATS = ("gorm", "nib", "xib", "nix")
# CIB's loader is an explicit stub; generated Objective-C has no loader.
OUTPUT_FORMATS = FORMATS + ("cib", "gormcode")
BUNDLE_CONTENTS = {"gorm": "objects.gorm", "nib": "keyedobjects.nib"}
WINDOW_TITLE = "Gormtool conversion window"
BUTTON_TITLE = "Convert this button"


class Conversions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not TOOL.is_file():
            raise RuntimeError("Build Gorm and gormtool with make before running tests")
        cls.scratch = tempfile.TemporaryDirectory(prefix="gormtool-conversions-")
        cls.addClassCleanup(cls.scratch.cleanup)
        cls.directory = Path(cls.scratch.name)
        cls.environment = os.environ.copy()
        # Load this checkout's framework (and its bundled plugins), not an
        # older installed GormCore. Preserve the caller's AppKit library path.
        libraries = [ROOT / "GormCore/GormCore.framework/Versions/Current",
                     ROOT / "InterfaceBuilder/obj",
                     ROOT / "GormObjCHeaderParser/obj"]
        cls.environment["LD_LIBRARY_PATH"] = os.pathsep.join(
            [str(path) for path in libraries]
            + [cls.environment.get("LD_LIBRARY_PATH", "")])
        cls.inputs = {}
        cls.input_errors = {}
        for extension in FORMATS:
            source = cls.directory / ("source." + extension)
            try:
                cls.convert(FIXTURE, source)
                cls.inputs[extension] = source
            except (AssertionError, OSError, subprocess.SubprocessError) as error:
                # Still run the other rows and report each affected pair.
                cls.input_errors[extension] = str(error)

    @classmethod
    def convert(cls, source, destination):
        result = subprocess.run(
            [str(TOOL), "--read", str(source), "--write", str(destination)],
            cwd=ROOT, env=cls.environment, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, errors="replace", timeout=30)
        diagnostic = "{} -> {}\n{}".format(source, destination, result.stdout)
        if result.returncode:
            raise AssertionError(diagnostic)
        # gormtool can return zero after a failed load/save, so an exit status
        # alone is not evidence that conversion succeeded.
        extension = destination.suffix[1:]
        if extension == "gormcode":
            payloads = [destination / "GeneratedGorm.h",
                        destination / "GeneratedGorm.m"]
        elif extension in BUNDLE_CONTENTS:
            payloads = [destination / BUNDLE_CONTENTS[extension]]
        else:
            payloads = [destination]
        for payload in payloads:
            if not payload.is_file() or payload.stat().st_size == 0:
                raise AssertionError("Missing or empty {}\n{}".format(
                    payload, diagnostic))

    def check_conversion(self, source_format, target_format):
        self.assertNotIn(source_format, self.input_errors,
                         self.input_errors.get(source_format))
        destination = self.directory / (
            "{}-to-{}.{}".format(source_format, target_format, target_format))
        self.convert(self.inputs[source_format], destination)
        if target_format == "cib":
            with destination.open("rb") as archive:
                document = plistlib.load(archive)
            self.assertEqual(document["$archiver"], "CPKeyedArchiver")
            self.assertEqual(document["$version"], "100000")
            objects = document["$objects"]
            self.assertEqual(objects[0], "$null")

            def deref(reference):
                return objects[reference["CP$UID"]]

            def classname(obj):
                return deref(obj["$class"])["$classname"]

            def array(reference):
                return [deref(ref) for ref in deref(reference)["CP.objects"]]

            root = deref(document["$top"]["CPCibObjectDataKey"])
            self.assertEqual(classname(root), "_CPCibObjectData")
            graph = array(root["_CPCibObjectDataObjectsKeysKey"])
            parents = array(root["_CPCibObjectDataObjectsValuesKey"])
            windows = [obj for obj in graph if classname(obj) == "_CPCibWindowTemplate"]
            buttons = [obj for obj in graph if classname(obj) == "CPButton"]
            self.assertEqual(len(windows), 1)
            self.assertEqual(len(buttons), 1)
            self.assertIs(parents[graph.index(windows[0])],
                          deref(root["_CPCibObjectDataFileOwnerKey"]))
            self.assertEqual(windows[0]["_CPCibWindowTemplateWindowTitleKey"],
                             WINDOW_TITLE)
            self.assertEqual(buttons[0]["CPButtonTitleKey"], BUTTON_TITLE)
            self.assertEqual(buttons[0]["CPViewTagKey"], 42)
            self.assertIsInstance(buttons[0]["CPViewFrameKey"], str)
            content = deref(windows[0]["_CPCibWindowTemplateWindowViewKey"])
            self.assertIn(buttons[0], array(content["CPViewSubviewsKey"]))
            return
        if target_format == "gormcode":
            code = (destination / "GeneratedGorm.m").read_text()
            self.assertIn(WINDOW_TITLE, code)
            self.assertIn(BUTTON_TITLE, code)
            return

        # Reopen every result in a fresh gormtool process, including XIB
        # outputs. Normalize to XML to inspect content without depending on
        # binary archive details, generated object IDs, or window decoration.
        reopened = self.directory / (
            "{}-to-{}-reopened.xib".format(source_format, target_format))
        self.convert(destination, reopened)
        document = ET.parse(reopened).getroot()
        windows = document.findall("./objects/window")
        self.assertEqual(len(windows), 1)
        self.assertEqual(windows[0].get("title"), WINDOW_TITLE)
        buttons = windows[0].findall("./view/subviews/button")
        self.assertEqual(len(buttons), 1)
        self.assertEqual(buttons[0].get("tag"), "42")
        cell = buttons[0].find("buttonCell")
        self.assertIsNotNone(cell)
        self.assertEqual(cell.get("title"), BUTTON_TITLE)


def conversion_test(source, target):
    def test(self):
        self.check_conversion(source, target)
    return test


# Individual names make omissions and failing directions visible in test logs.
# Include same-format saves as well as every ordered cross-format pair.
for source_format in FORMATS:
    for target_format in OUTPUT_FORMATS:
        setattr(Conversions, "test_{}_to_{}".format(source_format, target_format),
                conversion_test(source_format, target_format))


if __name__ == "__main__":
    unittest.main(verbosity=2)
