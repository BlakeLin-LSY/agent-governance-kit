#!/usr/bin/env python3
"""memory-archive.py — non-destructive L0 archival via [ARCHIVED] markers.

Adds an [ARCHIVED YYYY-MM-DD → <archive-file>] line under each matching
## [date] entry in core/.agents/memory.md. Original entry content stays
intact so the L8 append-only pre-commit hook never blocks.

Optionally copies the entry body to an archive file. If the entry header
already exists in the archive (idempotency), the copy is skipped.

Usage:
    python3 core/scripts/memory-archive.py \
        --before 2026-05-15 \
        --archive-file core/.agents/memory/archive-2026-Q2.md \
        [--marker-date 2026-05-19] [--copy-to-archive] [--dry-run]
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path

ENTRY_HEADER_RE = re.compile(r"^## \[.*(\d{4}-\d{2}-\d{2}).*\]", re.MULTILINE)
ARCHIVED_MARKER_RE = re.compile(r"^\*\*\[ARCHIVED ", re.MULTILINE)


def split_entries(text: str) -> tuple[str, list[str]]:
    parts = re.split(r"(?=^## \[.*?\d{4}-\d{2}-\d{2}.*?\])", text, flags=re.MULTILINE)
    if not parts:
        return text, []
    header = parts[0] if not parts[0].startswith("## [") else ""
    entries = parts[1:] if header else parts
    return header, entries


def entry_date(entry: str) -> str | None:
    m = re.match(r"## \[.*?(\d{4}-\d{2}-\d{2}).*?\]", entry)
    return m.group(1) if m else None


def entry_first_line(entry: str) -> str:
    return entry.splitlines()[0] if entry else ""


def add_marker(entry: str, marker_date: str, archive_file: str) -> tuple[str, bool]:
    """Insert [ARCHIVED ...] line directly after the header. Skip if present."""
    lines = entry.splitlines(keepends=True)
    if len(lines) < 1:
        return entry, False
    body_start = 1
    # Check if marker already present in first few lines.
    for ln in lines[1:6]:
        if ARCHIVED_MARKER_RE.match(ln):
            return entry, False
    marker = f"**[ARCHIVED {marker_date} → {archive_file}]**\n"
    new_lines = [lines[0], marker] + lines[body_start:]
    return "".join(new_lines), True


def header_in_archive(header: str, archive_text: str) -> bool:
    return header.strip() in archive_text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--before",
                      help="Archive entries with date < YYYY-MM-DD")
    mode.add_argument("--keep", type=int,
                      help="Mark all but the N newest entries (append-order assumed)")
    mode.add_argument("--purge-marked", action="store_true",
                      help="DESTRUCTIVE: physically REMOVE entries that already carry an "
                           "[ARCHIVED → <file>] marker AND whose header is confirmed present "
                           "in that referenced archive file. An entry marked but NOT found in "
                           "its archive is KEPT (safety-skip) — a body is never purged unless "
                           "its content is provably preserved. Pair with --dry-run first. "
                           "(T-MEM-4: relieves marker-bloat after a --keep rotation.)")
    ap.add_argument("--archive-file", required=True,
                    help="Path to the archive file (referenced in marker)")
    ap.add_argument("--memory-file", default="core/.agents/memory.md")
    ap.add_argument("--marker-date", default=date.today().isoformat())
    ap.add_argument("--copy-to-archive", action="store_true",
                    help="Also append entry bodies to the archive file "
                         "(skip if header already present).")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    memory_path = Path(args.memory_file)
    archive_path = Path(args.archive_file)
    if not memory_path.exists():
        print(f"❌ memory file missing: {memory_path}", file=sys.stderr)
        return 2

    memory_text = memory_path.read_text()
    archive_text = archive_path.read_text() if archive_path.exists() else ""

    file_header, entries = split_entries(memory_text)
    if not entries:
        print("⚠️  no entries parsed; nothing to do")
        return 0

    # ── --purge-marked: physically remove already-archived (marker'd) entries ──
    # Safety: an entry is dropped ONLY if it carries an [ARCHIVED → <file>] marker
    # AND its header line is found in that referenced archive file. Any marked
    # entry not confirmed in its archive is KEPT (never purge an unpreserved body).
    if args.purge_marked:
        marker_path_re = re.compile(r"\[ARCHIVED\b.*?→\s*(.+?)\]\*\*")
        archive_cache: dict[str, str] = {}

        def archive_has(path: str, hdr: str) -> bool:
            if path not in archive_cache:
                p = Path(path)
                archive_cache[path] = p.read_text() if p.exists() else ""
            return hdr.strip() in archive_cache[path]

        kept_entries: list[str] = []
        purged = kept_live = safety_skipped = 0
        for entry in entries:
            lines = entry.splitlines()
            marker_line = next(
                (ln for ln in lines[1:6] if ARCHIVED_MARKER_RE.match(ln)), None)
            if marker_line is None:
                kept_entries.append(entry)
                kept_live += 1
                continue
            m = marker_path_re.search(marker_line)
            arch_path = m.group(1).strip() if m else args.archive_file
            entry_hdr = entry_first_line(entry)
            if archive_has(arch_path, entry_hdr):
                purged += 1                       # drop (body preserved in archive)
            else:
                kept_entries.append(entry)        # safety: keep unpreserved body
                safety_skipped += 1
                print(f"  ⚠ safety-skip (marked but NOT in {arch_path}): {entry_hdr[:72]}")

        new_memory = file_header + "".join(kept_entries)
        print(f"  purged (marked + in archive): {purged}")
        print(f"  kept live (no marker)       : {kept_live}")
        print(f"  safety-skipped (unverified) : {safety_skipped}")
        if args.dry_run:
            print("\n(dry-run — no files written)")
            return 0
        memory_path.write_text(new_memory)
        print(f"\n✅ wrote {memory_path} — {purged} archived bodies removed")
        return 0

    modified = 0
    skipped_existing_marker = 0
    skipped_out_of_range = 0
    copy_appended = 0
    copy_already_present = 0
    new_entries: list[str] = []
    archive_appends: list[str] = []

    # --keep N → mark every entry except the N newest (entries are append-ordered).
    # Build an index set of entries to archive.
    keep_archive_idx: set[int] | None = None
    if args.keep is not None:
        dated = [i for i, e in enumerate(entries) if entry_date(e) is not None]
        if len(dated) > args.keep:
            keep_archive_idx = set(dated[:-args.keep])
        else:
            keep_archive_idx = set()

    for idx, entry in enumerate(entries):
        d = entry_date(entry)
        in_range = (
            (args.before is not None and d is not None and d < args.before)
            or (keep_archive_idx is not None and idx in keep_archive_idx)
        )
        if d is None or not in_range:
            new_entries.append(entry)
            if d is not None:
                skipped_out_of_range += 1
            continue
        new_entry, did = add_marker(entry, args.marker_date, args.archive_file)
        if not did:
            skipped_existing_marker += 1
            new_entries.append(entry)
            continue
        modified += 1
        new_entries.append(new_entry)
        if args.copy_to_archive:
            first = entry_first_line(entry)
            if header_in_archive(first, archive_text):
                copy_already_present += 1
            else:
                archive_appends.append(entry)
                archive_text += "\n" + entry
                copy_appended += 1

    new_memory = file_header + "".join(new_entries)

    print(f"  in-range entries marked     : {modified}")
    print(f"  skipped (already marked)    : {skipped_existing_marker}")
    print(f"  out-of-range entries kept   : {skipped_out_of_range}")
    if args.copy_to_archive:
        print(f"  archive append (new)        : {copy_appended}")
        print(f"  archive append (had header) : {copy_already_present}")

    if args.dry_run:
        print("\n(dry-run — no files written)")
        return 0

    memory_path.write_text(new_memory)
    print(f"\n✅ wrote {memory_path}")
    if args.copy_to_archive and archive_appends:
        with archive_path.open("a") as f:
            for e in archive_appends:
                f.write("\n" + e)
        print(f"✅ appended {len(archive_appends)} entries to {archive_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
