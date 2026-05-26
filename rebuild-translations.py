#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path


I18N_PREFIX = "ui/i18n/"


def load_json(path: Path) -> OrderedDict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle, object_pairs_hook=OrderedDict)


def write_json(path: Path, data: OrderedDict) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def run_git(checkout_dir: Path, *args: str, capture_output: bool = False):
    return subprocess.run(
        ["git", "-C", str(checkout_dir), *args],
        check=True,
        text=True,
        capture_output=capture_output,
    )


def parse_json_property(line: str):
    text = line.strip()
    if not text or text in {"{", "}", "},", "{"}:
        return None
    if ":" not in text:
        return None
    key_part, value_part = text.split(":", 1)
    key_part = key_part.strip()
    value_part = value_part.strip().rstrip(",")
    if not (key_part.startswith('"') and key_part.endswith('"')):
        return None
    try:
        key = json.loads(key_part)
        value = json.loads(value_part)
    except json.JSONDecodeError:
        return None
    return key, value


def apply_patch_file(checkout_dir: Path, patch_path: Path) -> list[Path]:
    current_file = None
    in_hunk = False
    files = {}

    for raw_line in patch_path.read_text(encoding="utf-8").splitlines():
        if raw_line.startswith("diff --git "):
            match = re.match(r"diff --git a/(.+) b/(.+)$", raw_line)
            current_file = match.group(2) if match else None
            in_hunk = False
            continue
        if current_file is None:
            continue
        if not current_file.startswith(I18N_PREFIX) or not current_file.endswith(".json"):
            continue
        if raw_line.startswith("@@"):
            in_hunk = True
            continue
        if not in_hunk:
            continue
        if raw_line.startswith("+") and not raw_line.startswith("+++"):
            parsed = parse_json_property(raw_line[1:])
            if parsed is None:
                continue
            key, value = parsed
            files.setdefault(current_file, OrderedDict())
            files[current_file][key] = value

    changed_paths = []
    for relative_path, updates in files.items():
        target = checkout_dir / relative_path
        if not target.exists():
            print(f"warning: skipping missing translation file: {relative_path}", file=sys.stderr)
            continue
        data = load_json(target)
        original = OrderedDict(data)
        for key, value in updates.items():
            data[key] = value
        if data != original:
            write_json(target, data)
            changed_paths.append(target)

    return changed_paths


def commit_changes(checkout_dir: Path, changed_paths: list[Path], patch_files: list[Path]) -> None:
    if not changed_paths:
        print("info: translations already up to date; no commit created")
        return

    relative_paths = [str(path.relative_to(checkout_dir)) for path in changed_paths]
    run_git(checkout_dir, "add", "--", *relative_paths)

    subject = "feat(i18n): rebuild translation files from patch set"
    body_lines = ["Applied patch inputs:"]
    body_lines.extend(f"- {patch_path.name}" for patch_path in patch_files)
    run_git(
        checkout_dir,
        "commit",
        "--quiet",
        "-m",
        subject,
        "-m",
        "\n".join(body_lines),
    )

    result = run_git(checkout_dir, "rev-parse", "--short", "HEAD", capture_output=True)
    print(f"info: created translation commit {result.stdout.strip()}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rebuild locale JSON files by merging the i18n patch files onto a checkout."
    )
    parser.add_argument("checkout_dir", help="Path to the patched Seatsurfing checkout")
    parser.add_argument(
        "patches_dir",
        nargs="?",
        default=str(Path(__file__).resolve().parent),
        help="Path to the patch repository root (default: script directory)",
    )
    args = parser.parse_args()

    checkout_dir = Path(args.checkout_dir).resolve()
    patches_dir = Path(args.patches_dir).resolve()
    i18n_dir = patches_dir / "i18n"

    if not checkout_dir.is_dir():
        print(f"error: checkout directory does not exist: {checkout_dir}", file=sys.stderr)
        return 1
    if not i18n_dir.is_dir():
        print(f"error: i18n patch directory does not exist: {i18n_dir}", file=sys.stderr)
        return 1

    patch_files = sorted(i18n_dir.glob("*.patch"))
    if not patch_files:
        print(f"warning: no i18n patches found in {i18n_dir}", file=sys.stderr)
        return 0

    changed_paths = []
    for patch_path in patch_files:
        changed_paths.extend(apply_patch_file(checkout_dir, patch_path))

    commit_changes(checkout_dir, changed_paths, patch_files)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
