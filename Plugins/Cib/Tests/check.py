#!/usr/bin/env python3
"""Build a native graph, validate CIB coding, and optionally run Cappuccino."""
import os
from pathlib import Path
import plistlib
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent

def config(option):
    return shlex.split(subprocess.check_output(["gnustep-config", option], text=True))


def main():
    libraries = [ROOT / "GormCore/GormCore.framework/Versions/Current",
                 ROOT / "InterfaceBuilder/obj", ROOT / "GormObjCHeaderParser/obj"]
    environment = os.environ.copy()
    environment["LD_LIBRARY_PATH"] = os.pathsep.join(
        [str(path) for path in libraries] + [environment.get("LD_LIBRARY_PATH", "")])
    with tempfile.TemporaryDirectory(prefix="gorm-cib-") as directory:
        executable = Path(directory) / "archive"
        archive = Path(directory) / "graph.cib"
        makefiles = subprocess.check_output(
            ["gnustep-config", "--variable=GNUSTEP_MAKEFILES"], text=True).strip()
        command = config("--variable=CC") + config("--objc-flags")
        command += ["-I" + str(ROOT), "-I" + str(Path(makefiles) / "TestFramework"),
                    str(HERE / "archive.m"), str(HERE.parent / "GormCIBModelGenerator.m"),
                    "-o", str(executable)]
        command += ["-L" + str(path) for path in libraries]
        command += ["-lGormCore", "-lInterfaceBuilder", "-lGormObjCHeaderParser"]
        command += config("--gui-libs")
        subprocess.run(command, cwd=directory, check=True)
        result = subprocess.run([str(executable), str(archive)], cwd=ROOT,
                                env=environment, capture_output=True, text=True, timeout=30)
        print(result.stdout + result.stderr, end="")
        result.check_returncode()
        assert "Failed test" not in result.stderr
        document = plistlib.loads(archive.read_bytes())
        objects = document["$objects"]
        assert document["$archiver"] == "CPKeyedArchiver"
        assert document["$version"] == "100000"
        assert objects[0] == "$null"

        def deref(ref):
            assert set(ref) == {"CP$UID"}
            index = ref["CP$UID"]
            assert isinstance(index, int) and 0 <= index < len(objects)
            return objects[index]

        def array(ref):
            return [deref(item) for item in deref(ref)["CP.objects"]]

        def classname(obj):
            return deref(obj["$class"])["$classname"]

        # Inspect every reference, including references outside the root graph.
        def references(value):
            if isinstance(value, dict):
                if "CP$UID" in value:
                    deref(value)
                else:
                    for item in value.values(): references(item)
            elif isinstance(value, list):
                for item in value: references(item)
        references(document)
        root = deref(document["$top"]["CPCibObjectDataKey"])
        assert classname(root) == "_CPCibObjectData"
        graph = array(root["_CPCibObjectDataObjectsKeysKey"])
        parents = array(root["_CPCibObjectDataObjectsValuesKey"])
        owner = deref(root["_CPCibObjectDataFileOwnerKey"])
        assert classname(owner) == "_CPCibCustomObject"
        assert owner["_CPCibCustomObjectClassName"] == "CibTestOwner"
        window, = [obj for obj in graph if classname(obj) == "_CPCibWindowTemplate"]
        content = deref(window["_CPCibWindowTemplateWindowViewKey"])
        first, second, scroll = array(content["CPViewSubviewsKey"])
        clip = deref(scroll["CPScrollViewContentView"])
        scroll_document = deref(clip["CPScrollViewDocumentView"])
        assert clip in array(scroll["CPViewSubviewsKey"])
        assert scroll_document in array(clip["CPViewSubviewsKey"])
        assert classname(deref(scroll["CPScrollViewVScroller"])) == "CPScroller"
        assert first is not second
        assert classname(first) == "_CPCibClassSwapper"
        assert first["_CPCibClassSwapperClassNameKey"] == "CibTestButton"
        assert first["_CPCibClassSwapperOriginalClassNameKey"] == "CPButton"
        assert classname(second) == "CPButton"
        assert first["CPViewTagKey"] == 7 and second["CPViewTagKey"] == 8
        image = deref(first["$aimage"])
        assert classname(image) == "_CPCibCustomResource"
        assert image["_CPCibCustomResourceResourceNameKey"] == "cib-test.png"
        assert first["CPViewAutoresizingMask"] == 32
        assert first["CPControlValueKey"] == 1
        assert second["CPViewThemeStateKey"] == "disabled"
        assert first["CPViewFrameKey"] == "{{20, 148}, {120, 32}}"
        assert first["CPViewBoundsKey"] == "{{0, 0}, {120, 32}}"
        assert parents[graph.index(window)] is owner
        assert parents[graph.index(content)] is window
        assert parents[graph.index(first)] is content
        assert deref(first["CPViewSuperviewKey"]) is content
        assert array(deref(root["_CPCibObjectDataVisibleWindowsKey"])["CPSetObjectsKey"]) == [window]
        names = dict(zip(array(root["_CPCibObjectDataNamesValuesKey"]),
                         array(root["_CPCibObjectDataNamesKeysKey"])))
        assert names["NSButton(1)"] is first and names["NSButton(2)"] is second
        links = array(root["_CPCibObjectDataConnectionsKey"])
        assert len(links) == 4
        links = {link["_CPCibConnectorLabelKey"]: link for link in links}
        assert deref(links["firstButton"]["_CPCibConnectorSourceKey"]) is owner
        assert deref(links["firstButton"]["_CPCibConnectorDestinationKey"]) is first
        assert deref(links["secondButton"]["_CPCibConnectorDestinationKey"]) is second
        assert deref(links["clicked:"]["_CPCibConnectorSourceKey"]) is first
        assert deref(links["clicked:"]["_CPCibConnectorDestinationKey"]) is owner
        assert links["performClose:"]["_CPCibConnectorDestinationKey"] == {"CP$UID": 0}
        print("PASS: CIB structure, identity, ownership, connections, custom classes and geometry")
        objj = os.environ.get("CIB_OBJJ")
        if objj:
            command = [objj] + shlex.split(os.environ.get("CIB_OBJJ_FLAGS", ""))
            subprocess.run(command + [str(HERE / "load.j"), str(archive)],
                           check=True, timeout=60)
        else:
            print("SKIP: Cappuccino runtime check (set CIB_OBJJ and optionally CIB_OBJJ_FLAGS)")

if __name__ == "__main__":
    main()
