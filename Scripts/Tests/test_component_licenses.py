"""Check component notices without requiring GNUstep or a GUI backend."""

from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
COMPONENTS = ("GormCore", "GormObjCHeaderParser", "Plugins")


def notice_errors(text):
    # Join wrapped comment lines so both C and makefile notices are checked.
    text = re.sub(r"(?m)^\s*(?:\*|#|//)\s?", "", text)
    text = " ".join(text.split())
    errors = []
    if re.search(r"GNU (?:Library )?General Public License", text):
        errors.append("non-LGPL notice")
    for identifier in re.findall(r"\b(?:L?GPL)[-v][\w.+-]+", text):
        identifier = identifier.rstrip(".")
        if identifier != "LGPL-2.1-or-later":
            errors.append("unexpected identifier: " + identifier)
    for version in re.findall(r"version ([\d.]+) (?:of the License|or later)", text):
        if version != "2.1":
            errors.append("unexpected license version: " + version)
    if "GNU Lesser General Public License" in text:
        if not re.search(r"version 2\.1\b", text):
            errors.append("missing LGPL version")
        if not re.search(r"any later version|or later", text):
            errors.append("missing later-version permission")
    return errors


class ComponentLicenses(unittest.TestCase):
    def test_notices(self):
        paths = subprocess.check_output(
            ["git", "ls-files", "-z", "--", *COMPONENTS], cwd=ROOT
        ).decode().split("\0")
        for name in filter(None, paths):
            path = ROOT / name
            # License texts contain explanatory references to the ordinary GPL.
            if path.name.startswith("COPYING"):
                continue
            try:
                text = path.read_text()
            except UnicodeError:
                continue
            with self.subTest(path=name):
                self.assertEqual(notice_errors(text), [])

    def test_license_texts_and_readmes(self):
        reference = (ROOT / "InterfaceBuilder/COPYING.LIB").read_bytes()
        for component in COMPONENTS:
            with self.subTest(component=component):
                self.assertEqual(
                    (ROOT / component / "COPYING.LIB").read_bytes(), reference
                )
                self.assertIn(
                    "LGPL-2.1-or-later",
                    (ROOT / component / "README.md").read_text(),
                )
        self.assertEqual(
            (ROOT / "Plugins/Nib/COPYING.LIB").read_bytes(), reference
        )

    def test_rejects_historical_conflicts(self):
        for notice in (
            "GNU General Public\n# License; version 3 of the License",
            "GNU Library General Public License; version 3 of the License",
            "SPDX-License-Identifier: GPL-3.0-or-later",
            "LGPL-2.0-or-later",
            "GNU Lesser General Public License, version 2 or later",
            "GNU Lesser General Public License, version 2.1 only",
        ):
            with self.subTest(notice=notice):
                self.assertTrue(notice_errors(notice))

    def test_accepts_lgpl_notices(self):
        for notice in (
            "SPDX-License-Identifier: LGPL-2.1-or-later",
            "/* LGPL-2.1-or-later. */",
            "GNU Lesser General Public\n * License; either version 2.1 of the "
            "License, or (at your option) any later version.",
            "GNU Lesser General\n * Public License, version 2.1 or later.",
        ):
            with self.subTest(notice=notice):
                self.assertEqual(notice_errors(notice), [])


if __name__ == "__main__":
    unittest.main()
