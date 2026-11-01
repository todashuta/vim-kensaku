#!/usr/bin/env python3
"""Generates the Vim9 script lookup tables from jsmigemo sources.

The romaji to hiragana converter uses the exact double array trie tables of
jsmigemo's RomajiProcessor2, and the width / kana conversions use the tables
of jsmigemo's CharacterConverter.  Both are large, purely mechanical data, so
they are generated here instead of being written by hand.

Usage:
    python3 tools/generate-tables.py /path/to/jsmigemo
"""

from __future__ import annotations

import argparse
import pathlib
import re


def parse_number_array(source: str, pattern: str) -> list[int]:
    match = re.search(pattern, source, re.S)
    if match is None:
        raise SystemExit(f"not found: {pattern}")
    return [int(value) for value in re.findall(r"-?\d+", match.group(1))]


def vim_number_list(name: str, values: list[int], per_line: int = 40) -> str:
    lines = [
        "  " + ", ".join(str(value) for value in values[i : i + per_line]) + ","
        for i in range(0, len(values), per_line)
    ]
    return f"export const {name}: list<number> = [\n" + "\n".join(lines) + "\n]"


def vim_string_list(name: str, values: list[str], per_line: int = 20) -> str:
    lines = []
    for i in range(0, len(values), per_line):
        chunk = [
            '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
            for value in values[i : i + per_line]
        ]
        lines.append("  " + ", ".join(chunk) + ",")
    return f"export const {name}: list<string> = [\n" + "\n".join(lines) + "\n]"


def vim_dict(name: str, values: dict[str, str]) -> str:
    lines = [
        "  '" + key.replace("'", "''") + "': '" + value.replace("'", "''") + "',"
        for key, value in values.items()
    ]
    return f"export const {name}: dict<string> = {{\n" + "\n".join(lines) + "\n}"


def generate_romaji_table(jsmigemo: pathlib.Path, outdir: pathlib.Path) -> None:
    source = (jsmigemo / "src" / "RomajiProcessor2.ts").read_text()
    base = parse_number_array(source, r"const base\s*=\s*new Int16Array\((\[.*?\])\)")
    check = parse_number_array(source, r"const check\s*=\s*new Int16Array\((\[.*?\])\)")
    remain = parse_number_array(source, r"const remainList\s*=\s*new Int8Array\((\[.*?\])\)")
    match = re.search(r"const hiraganaList[^=]*=\s*(\[.*?\]);?", source, re.S)
    if match is None:
        raise SystemExit("not found: hiraganaList")
    hiragana = re.findall(r'"((?:[^"\\]|\\.)*)"', match.group(1))
    if not (len(base) == len(check) == len(remain) == len(hiragana)):
        raise SystemExit("table lengths differ")

    text = "vim9script\n# Generated from jsmigemo RomajiProcessor2 tables. Do not edit by hand.\n\n"
    text += vim_number_list("BASE", base) + "\n\n"
    text += vim_number_list("CHECK", check) + "\n\n"
    text += vim_number_list("REMAIN", remain) + "\n\n"
    text += vim_string_list("HIRAGANA", hiragana) + "\n"
    (outdir / "romaji_table.vim").write_text(text)
    print(f"wrote {outdir / 'romaji_table.vim'} ({len(base)} entries)")


def generate_charset_table(jsmigemo: pathlib.Path, outdir: pathlib.Path) -> None:
    source = (jsmigemo / "src" / "CharacterConverter.ts").read_text()
    match = re.search(r"const han2zenEntries[^=]*=\s*\[(.*?)\];", source, re.S)
    if match is None:
        raise SystemExit("not found: han2zenEntries")
    pairs = [
        (unescape(han), unescape(zen))
        for han, zen in re.findall(r"\['((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'\]", match.group(1))
    ]

    zen2han = {zen: han for han, zen in pairs}
    match = re.search(r"const zen2hanEntries[^=]*=\s*\[(.*?)\];", source, re.S)
    if match is None:
        raise SystemExit("not found: zen2hanEntries")
    for zen, han in re.findall(r"\['([^']*)',\s*\"([^\"]*)\"\]", match.group(1)):
        zen2han[zen] = han

    text = "vim9script\n# Generated from jsmigemo CharacterConverter tables. Do not edit by hand.\n\n"
    text += vim_dict("HAN2ZEN", dict(pairs)) + "\n\n"
    text += vim_dict("ZEN2HAN", zen2han) + "\n"
    (outdir / "charset_table.vim").write_text(text)
    print(f"wrote {outdir / 'charset_table.vim'} ({len(pairs)} + {len(zen2han)} entries)")


def unescape(value: str) -> str:
    return value.replace("\\'", "'").replace("\\\\", "\\")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("jsmigemo", type=pathlib.Path, help="path to a jsmigemo checkout")
    parser.add_argument(
        "--outdir",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parent.parent / "autoload" / "kensaku",
        help="output directory (default: autoload/kensaku)",
    )
    args = parser.parse_args()
    generate_romaji_table(args.jsmigemo, args.outdir)
    generate_charset_table(args.jsmigemo, args.outdir)


if __name__ == "__main__":
    main()
