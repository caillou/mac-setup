#!/usr/bin/env python3
"""Make Finder open Downloads in list view, sorted by Date Added, newest first.

Finder keeps a folder's view settings in the *parent* folder's `.DS_Store`,
in a record named after the folder: for `~/Downloads` that is `~/.DS_Store`,
record `Downloads`. Three entries decide the view:

    vstl  type  b"Nlsv"   always open this folder in list view
    vSrn  long  1         the folder uses its own view settings
    lsvC  blob            binary plist: the columns and the sort column

Finder 26 reads `lsvC`; the legacy `lsvp` record is a dict-keyed mirror with no
Date Added column and is never written here. Nothing else in the store is
touched, and nothing is written at all when the record already says this.

There is no supported way to do it: Finder's AppleScript dictionary has never
had a Date Added column, and the `defaults` view templates only reach folders
without a record of their own. See the PRD's research notes.

Run it the way the apply script does, so `ds_store` needs no virtualenv:

    uv run --with ds_store python3 ensure_downloads_view.py [store-path]
"""

import base64
import copy
import os
import plistlib
import sys

from ds_store import DSStore

FOLDER = "Downloads"

# `vstl`'s value: Finder's four-character code for list view.
LIST_VIEW = b"Nlsv"
SETTINGS_VERSION = 1
SORT_COLUMN = "dateAdded"

# The `lsvC` blob captured from a Mac where the view was set by hand in Finder,
# base64 of the binary plist. It is the fallback for a folder with no record
# yet: writing a blob Finder itself produced means every column Finder seeds is
# there, with its widths, rather than a minimal one of our own invention.
CAPTURED_LSVC_B64 = """
YnBsaXN0MDDaAQIDBAUGBwgJCgsMDRVWV1hZWgxfEBJ2aWV3T3B0aW9uc1ZlcnNpb25fEA9zaG93
SWNvblByZXZpZXdXY29sdW1uc18QEWNhbGN1bGF0ZUFsbFNpemVzXxAPc2Nyb2xsUG9zaXRpb25Z
WHRleHRTaXplXxAPc2Nyb2xsUG9zaXRpb25YWnNvcnRDb2x1bW5YaWNvblNpemVfEBB1c2VSZWxh
dGl2ZURhdGVzFAAAAAAAAAAAAAAAAAAAAAEJrg4XHCElKi8zOD1CR0xQ1A8QERIMFBUWV3Zpc2li
bGVVd2lkdGhZYXNjZW5kaW5nWmlkZW50aWZpZXIJEQIbCFRuYW1l1BIQEQ8YGRUVWHViaXF1aXR5
ECMICNQSEBEPHR4VFVxkYXRlTW9kaWZpZWQQtQgI1A8QERIMHgwkCQlbZGF0ZUNyZWF0ZWTUDxAR
EgwnFSkJEGEIVHNpemXUDxAREgwsDC4JEHMJVGtpbmTUEhARDzAeFQxZZGF0ZUFkZGVkCAnUDxAR
EhU1DDcIEGQJVWxhYmVs1A8QERIVOgw8CBBLCVd2ZXJzaW9u1A8QERIVPwxBCBEBLAlYY29tbWVu
dHPUDxAREhVEFUYIEMAIXmRhdGVMYXN0T3BlbmVk1A8QERIVSRVLCBDICFpzaGFyZU93bmVy1A8Q
ERIVSRVPCAhfEA9zaGFyZUxhc3RFZGl0b3LUDxAREhVSFVQIENIIXxAQaW52aXRhdGlvblN0YXR1
cwgjAAAAAAAAAAAjQCoAAAAAAAAjwGOAAAAAAABZZGF0ZUFkZGVkI0AwAAAAAAAACQAIAB0AMgBE
AEwAYAByAHsAjQCYAKEAtADFAMYA1QDeAOYA7AD2AQEBAgEFAQYBCwEUAR0BHwEgASEBKgE3ATkB
OgE7AUQBRQFGAVIBWwFcAV4BXwFkAW0BbgFwAXEBdgF/AYkBigGLAZQBlQGXAZgBngGnAagBqgGr
AbMBvAG9AcABwQHKAdMB1AHWAdcB5gHvAfAB8gHzAf4CBwIIAgkCGwIkAiUCJwIoAjsCPAJFAk4C
VwJhAmoAAAAAAAACAQAAAAAAAABcAAAAAAAAAAAAAAAAAAACaw==
"""


def captured_settings():
    """The captured `lsvC` settings, decoded."""
    return plistlib.loads(base64.b64decode(CAPTURED_LSVC_B64))


def wanted_settings(settings=None):
    """`settings` with the Date Added sort merged in.

    Column widths, icon size, scroll position and everything else Finder put in
    the blob are kept, so this is a merge and not an overwrite. Without usable
    settings to merge into, the captured blob is the base.
    """
    wanted = copy.deepcopy(settings) if isinstance(settings, dict) else captured_settings()

    columns = wanted.get("columns")
    if not isinstance(columns, list):
        # Not an lsvC-shaped column list (the legacy lsvp record keys its
        # columns by name): the captured list is the only sane base.
        columns = captured_settings()["columns"]
        wanted["columns"] = columns

    column = _column(columns, SORT_COLUMN)
    if column is None:
        column = _column(captured_settings()["columns"], SORT_COLUMN)
        columns.append(column)

    wanted["sortColumn"] = SORT_COLUMN
    column["visible"] = True
    column["ascending"] = False  # newest first
    return wanted


def read_view(store_path, folder=FOLDER):
    """The folder's view record, or None when the store has no record for it.

    Keys are the record's four-character codes, `lsvC` decoded from its binary
    plist. A code the record does not carry is left out.
    """
    if not os.path.exists(store_path):
        return None

    view = {}
    with DSStore.open(store_path, "r") as store:
        for code in ("vstl", "vSrn", "lsvC"):
            try:
                _entry_type, value = store[folder][code]
            except KeyError:
                continue
            view[code] = plistlib.loads(bytes(value)) if code == "lsvC" else value
    return view or None


def read_sort_column(store_path, folder=FOLDER):
    """The column Finder sorts the folder by, or None when there is no record."""
    settings = (read_view(store_path, folder) or {}).get("lsvC")
    return settings.get("sortColumn") if isinstance(settings, dict) else None


def ensure_view(store_path, folder=FOLDER):
    """Give the folder a Date Added list view. True when the store was written.

    The store is only opened for writing when the record is not already right,
    so a correct store keeps the bytes Finder wrote.
    """
    view = read_view(store_path, folder) or {}
    wanted = wanted_settings(view.get("lsvC"))
    if (
        view.get("vstl") == LIST_VIEW
        and view.get("vSrn") == SETTINGS_VERSION
        and view.get("lsvC") == wanted
    ):
        return False

    mode = "r+" if os.path.exists(store_path) else "w+"
    with DSStore.open(store_path, mode) as store:
        store[folder]["vstl"] = ("type", LIST_VIEW)
        store[folder]["vSrn"] = ("long", SETTINGS_VERSION)
        store[folder]["lsvC"] = ("blob", plistlib.dumps(wanted, fmt=plistlib.FMT_BINARY))
    return True


def _column(columns, identifier):
    for column in columns:
        if isinstance(column, dict) and column.get("identifier") == identifier:
            return column
    return None


def main(argv):
    store_path = argv[1] if len(argv) > 1 else os.path.expanduser("~/.DS_Store")
    if ensure_view(store_path):
        print(f"downloads view: {FOLDER} in {store_path} now opens sorted by Date Added")
    else:
        print(f"downloads view: {FOLDER} in {store_path} is already right, nothing written")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
