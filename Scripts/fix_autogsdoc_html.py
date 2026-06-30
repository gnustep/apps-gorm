#!/usr/bin/env python3
"""Clean up HTML emitted by autogsdoc for this source tree.

autogsdoc writes well-formed gsdoc for Objective-C protocol-qualified id types,
but its HTML backend can emit raw angle brackets in method signatures.  It also
wraps generated summary lists in paragraph tags.  Both forms confuse stricter
HTML consumers even though browsers often recover.
"""

from pathlib import Path
import re
import sys


PROTOCOL_ID_RE = re.compile(r"id<([A-Za-z_][A-Za-z0-9_, ]*)>")


def fix_html(text):
    text = text.replace("id<<a ", "id&lt;<a ")
    text = text.replace("</a>>", "</a>&gt;")
    text = PROTOCOL_ID_RE.sub(r"id&lt;\1&gt;", text)

    text = re.sub(r"(?m)^(\s*)<p>\s*\n(\s*<[uo]l>)", r"\1\2", text)
    text = re.sub(r"(?m)^(\s*</[uo]l>)\s*\n\s*</p>\s*$", r"\1", text)
    return text


def main(argv):
    if not argv:
        print("usage: fix_autogsdoc_html.py DOC_DIR [...]", file=sys.stderr)
        return 2

    for arg in argv:
        doc_dir = Path(arg)
        for html_file in doc_dir.rglob("*.html"):
            text = html_file.read_text(encoding="utf-8")
            fixed = fix_html(text)
            if fixed != text:
                html_file.write_text(fixed, encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
