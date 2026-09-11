#!/usr/bin/env python3
"""The Downloads view writer, against a temporary `.DS_Store`.

Run them the way the apply script runs the module:

    uv run --with ds_store python3 -m unittest discover -s tests

Every test works on a store in a temporary directory. The real `~/.DS_Store`
is never opened, in either mode.
"""

import contextlib
import io
import os
import plistlib
import sys
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, ".downloads-view"))

from ds_store import DSStore  # noqa: E402

import ensure_downloads_view as writer  # noqa: E402


class DownloadsViewTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.store = os.path.join(tmp.name, ".DS_Store")

    # --- helpers -----------------------------------------------------------

    def seed(self, entries, folder=writer.FOLDER):
        """Write raw record entries, the way Finder would have left them."""
        mode = "r+" if os.path.exists(self.store) else "w+"
        with DSStore.open(self.store, mode) as store:
            for code, value in entries.items():
                store[folder][code] = value

    def seed_settings(self, settings, folder=writer.FOLDER):
        """Seed a folder with a full list view record carrying `settings`."""
        self.seed(
            {
                "vstl": ("type", b"Nlsv"),
                "vSrn": ("long", 1),
                "lsvC": ("blob", plistlib.dumps(settings, fmt=plistlib.FMT_BINARY)),
            },
            folder,
        )

    def codes(self, folder=writer.FOLDER):
        """The record's codes and entry types, as they are in the store."""
        with DSStore.open(self.store, "r") as store:
            return {
                entry.code.decode(): entry.type.decode()
                for entry in store
                if entry.filename == folder
            }

    def bytes_on_disk(self):
        with open(self.store, "rb") as store:
            return store.read()

    def column(self, identifier):
        settings = writer.read_view(self.store)["lsvC"]
        for column in settings["columns"]:
            if column["identifier"] == identifier:
                return column
        return None

    def settings_sorted_by_name(self):
        """A plausible Finder blob for a folder nobody has touched."""
        settings = writer.captured_settings()
        settings["sortColumn"] = "name"
        for column in settings["columns"]:
            if column["identifier"] == "dateAdded":
                column["visible"] = False
                column["ascending"] = True
        return settings

    # --- a folder with no record yet ---------------------------------------

    def test_creates_the_store_when_it_is_missing(self):
        self.assertFalse(os.path.exists(self.store))

        self.assertTrue(writer.ensure_view(self.store))

        self.assertTrue(os.path.exists(self.store))
        self.assertEqual(self.codes(), {"vstl": "type", "vSrn": "long", "lsvC": "blob"})

    def test_writes_list_view_sorted_by_date_added(self):
        writer.ensure_view(self.store)

        view = writer.read_view(self.store)
        self.assertEqual(view["vstl"], b"Nlsv")
        self.assertEqual(view["vSrn"], 1)
        self.assertEqual(view["lsvC"]["sortColumn"], "dateAdded")
        self.assertEqual(writer.read_sort_column(self.store), "dateAdded")

    def test_date_added_is_visible_and_newest_first(self):
        writer.ensure_view(self.store)

        self.assertEqual(self.column("dateAdded")["visible"], True)
        self.assertEqual(self.column("dateAdded")["ascending"], False)

    def test_never_writes_the_legacy_list_view_records(self):
        writer.ensure_view(self.store)

        self.assertNotIn("lsvp", self.codes())
        self.assertNotIn("lsvP", self.codes())

    # --- a folder that already has a record --------------------------------

    def test_merges_into_an_existing_record(self):
        settings = self.settings_sorted_by_name()
        settings["textSize"] = 15.0
        settings["scrollPositionY"] = 42.0
        name_width = 321
        for column in settings["columns"]:
            if column["identifier"] == "name":
                column["width"] = name_width
        self.seed_settings(settings)

        self.assertTrue(writer.ensure_view(self.store))

        merged = writer.read_view(self.store)["lsvC"]
        self.assertEqual(merged["sortColumn"], "dateAdded")
        self.assertEqual(self.column("dateAdded")["visible"], True)
        self.assertEqual(self.column("dateAdded")["ascending"], False)
        # Everything the user had set is still there.
        self.assertEqual(merged["textSize"], 15.0)
        self.assertEqual(merged["scrollPositionY"], 42.0)
        self.assertEqual(self.column("name")["width"], name_width)
        self.assertEqual(len(merged["columns"]), len(settings["columns"]))

    def test_adds_the_date_added_column_when_the_record_has_none(self):
        settings = self.settings_sorted_by_name()
        settings["columns"] = [
            column for column in settings["columns"] if column["identifier"] != "dateAdded"
        ]
        self.seed_settings(settings)

        self.assertTrue(writer.ensure_view(self.store))

        self.assertEqual(self.column("dateAdded")["visible"], True)
        self.assertEqual(self.column("dateAdded")["ascending"], False)
        self.assertEqual(writer.read_sort_column(self.store), "dateAdded")

    def test_takes_the_captured_columns_when_the_record_has_no_column_list(self):
        self.seed_settings({"viewOptionsVersion": 1, "sortColumn": "name", "textSize": 15.0})

        self.assertTrue(writer.ensure_view(self.store))

        merged = writer.read_view(self.store)["lsvC"]
        self.assertEqual(merged["sortColumn"], "dateAdded")
        self.assertEqual(self.column("dateAdded")["visible"], True)
        self.assertEqual(merged["textSize"], 15.0)
        self.assertEqual(
            [column["identifier"] for column in merged["columns"]],
            [column["identifier"] for column in writer.captured_settings()["columns"]],
        )

    def test_falls_back_to_the_captured_blob_when_the_record_has_no_settings(self):
        self.seed({"Iloc": (100, 200)})

        self.assertTrue(writer.ensure_view(self.store))

        written = writer.read_view(self.store)["lsvC"]
        captured = writer.captured_settings()
        self.assertEqual(
            [column["identifier"] for column in written["columns"]],
            [column["identifier"] for column in captured["columns"]],
        )
        self.assertEqual(written, captured)

    def test_writes_nothing_when_the_record_is_already_right(self):
        writer.ensure_view(self.store)
        before = self.bytes_on_disk()

        self.assertFalse(writer.ensure_view(self.store))

        self.assertEqual(self.bytes_on_disk(), before)

    def test_leaves_a_finder_written_correct_record_untouched(self):
        self.seed_settings(writer.captured_settings())
        before = self.bytes_on_disk()

        self.assertFalse(writer.ensure_view(self.store))

        self.assertEqual(self.bytes_on_disk(), before)

    def test_rewrites_a_record_whose_view_style_is_wrong(self):
        self.seed_settings(writer.captured_settings())
        self.seed({"vstl": ("type", b"icnv")})

        self.assertTrue(writer.ensure_view(self.store))

        self.assertEqual(writer.read_view(self.store)["vstl"], b"Nlsv")

    # --- the rest of the store ---------------------------------------------

    def test_touches_no_other_record(self):
        self.seed({"Iloc": (10, 20), "vstl": ("type", b"icnv")}, folder="Pictures")

        writer.ensure_view(self.store)

        with DSStore.open(self.store, "r") as store:
            pictures = {entry.code.decode(): entry.value for entry in store.find("Pictures")}
        self.assertEqual(pictures["Iloc"], (10, 20))
        self.assertEqual(pictures["vstl"], b"icnv")

    # --- reading back -------------------------------------------------------

    def test_read_back_reports_nothing_for_a_store_without_the_record(self):
        self.seed({"Iloc": (10, 20)}, folder="Pictures")

        self.assertIsNone(writer.read_view(self.store))
        self.assertIsNone(writer.read_sort_column(self.store))

    def test_read_back_reports_nothing_for_a_missing_store(self):
        self.assertIsNone(writer.read_view(self.store))
        self.assertIsNone(writer.read_sort_column(self.store))

    # --- the command line ---------------------------------------------------

    def test_the_command_line_writes_the_store_it_is_given(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(writer.main(["ensure_downloads_view.py", self.store]), 0)

        self.assertEqual(writer.read_sort_column(self.store), "dateAdded")
        self.assertIn(self.store, out.getvalue())


if __name__ == "__main__":
    unittest.main()
