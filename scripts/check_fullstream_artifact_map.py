#!/usr/bin/env python3
"""Verify the generated full-stream XSA and DTBO address-map contract."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from collections.abc import Iterator
from pathlib import Path
from typing import Any


MUX_BASE = 0xA0020000
MUX_HIGH = 0xA002FFFF
MUX_SIZE = 0x00010000
SELF_TRIGGER_BASE = 0xA0010000
SELF_TRIGGER_HIGH = 0xA001FFFF


def walk_json(value: Any) -> Iterator[dict[str, Any]]:
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_json(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_json(child)


def overlaps_reserved(base: int, high: int) -> bool:
    return base <= SELF_TRIGGER_HIGH and high >= SELF_TRIGGER_BASE


def validate_xsa(path: Path) -> list[str]:
    errors: list[str] = []
    with zipfile.ZipFile(path) as archive:
        bda_names = [name for name in archive.namelist() if name.endswith(".bda")]
        if len(bda_names) != 1:
            return [f"XSA contains {len(bda_names)} BDA files; expected exactly one"]

        bda = json.loads(archive.read(bda_names[0]))
        access_records = [
            item
            for item in walk_json(bda)
            if item.get("VT") == "AC" and item.get("SX") == "/DAPHNE3"
        ]
        mux_records = [
            item
            for item in access_records
            if item.get("SI") == "MUX_S_AXI" and item.get("SS") == "reg0"
        ]
        if len(mux_records) != 1:
            errors.append(
                f"BDA contains {len(mux_records)} DAPHNE3/MUX_S_AXI/reg0 records; expected one"
            )
        else:
            base = int(mux_records[0]["BA"], 0)
            high = int(mux_records[0]["HA"], 0)
            if (base, high) != (MUX_BASE, MUX_HIGH):
                errors.append(
                    f"BDA MUX_S_AXI range is 0x{base:08X}-0x{high:08X}; "
                    f"expected 0x{MUX_BASE:08X}-0x{MUX_HIGH:08X}"
                )

        for item in access_records:
            base = int(item["BA"], 0)
            high = int(item["HA"], 0)
            if overlaps_reserved(base, high):
                errors.append(
                    f"BDA DAPHNE3/{item.get('SI', '?')} overlaps reserved self-trigger "
                    f"range at 0x{base:08X}-0x{high:08X}"
                )

        hwh_ranges: list[dict[str, str]] = []
        for name in (entry for entry in archive.namelist() if entry.endswith(".hwh")):
            root = ET.fromstring(archive.read(name))
            for element in root.iter("MEMRANGE"):
                if element.get("INSTANCE") == "DAPHNE3":
                    hwh_ranges.append(dict(element.attrib))

        hwh_mux_ranges = [
            item
            for item in hwh_ranges
            if item.get("SLAVEBUSINTERFACE") == "MUX_S_AXI"
            and item.get("ADDRESSBLOCK") == "reg0"
        ]
        if len(hwh_mux_ranges) != 1:
            errors.append(
                f"HWH contains {len(hwh_mux_ranges)} DAPHNE3/MUX_S_AXI/reg0 ranges; expected one"
            )
        else:
            base = int(hwh_mux_ranges[0]["BASEVALUE"], 0)
            high = int(hwh_mux_ranges[0]["HIGHVALUE"], 0)
            if (base, high) != (MUX_BASE, MUX_HIGH):
                errors.append(
                    f"HWH MUX_S_AXI range is 0x{base:08X}-0x{high:08X}; "
                    f"expected 0x{MUX_BASE:08X}-0x{MUX_HIGH:08X}"
                )

        for item in hwh_ranges:
            base = int(item["BASEVALUE"], 0)
            high = int(item["HIGHVALUE"], 0)
            if overlaps_reserved(base, high):
                errors.append(
                    "HWH DAPHNE3/"
                    f"{item.get('SLAVEBUSINTERFACE', '?')} overlaps reserved self-trigger "
                    f"range at 0x{base:08X}-0x{high:08X}"
                )

    return errors


def validate_dtbo(path: Path) -> list[str]:
    errors: list[str] = []
    dtc = shutil.which("dtc")
    if dtc is None:
        return ["dtc is required to inspect the full-stream DTBO address map"]

    result = subprocess.run(
        [dtc, "-I", "dtb", "-O", "dts", "-o", "-", str(path)],
        check=False,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        return [f"dtc could not decode {path}: {result.stderr.strip()}"]

    nodes = re.findall(
        r"\bDAPHNE3@[^\s{]+\s*\{(?P<body>.*?)^\s*\};",
        result.stdout,
        flags=re.IGNORECASE | re.MULTILINE | re.DOTALL,
    )
    register_nodes = [
        body for body in nodes if re.search(r"\breg\s*=\s*<[^;]+>;", body, re.DOTALL)
    ]
    if len(register_nodes) != 1:
        return [
            f"DTBO contains {len(register_nodes)} DAPHNE3 nodes with a reg property; "
            "expected exactly one"
        ]

    properties = re.findall(r"\breg\s*=\s*<([^;]+)>;", register_nodes[0], re.DOTALL)
    if len(properties) != 1:
        return [f"DTBO DAPHNE3 node contains {len(properties)} reg properties; expected one"]

    cells = [int(token, 16) for token in re.findall(r"0x[0-9A-Fa-f]+", properties[0])]
    if len(cells) % 4 != 0:
        return [f"DTBO DAPHNE3 reg property has {len(cells)} cells; expected 4-cell tuples"]

    ranges = [
        ((cells[index] << 32) | cells[index + 1], (cells[index + 2] << 32) | cells[index + 3])
        for index in range(0, len(cells), 4)
    ]
    if ranges.count((MUX_BASE, MUX_SIZE)) != 1:
        formatted = ", ".join(f"0x{base:X}/0x{size:X}" for base, size in ranges)
        errors.append(
            f"DTBO requires one 0x{MUX_BASE:08X}/0x{MUX_SIZE:X} tuple; found: {formatted}"
        )
    for base, size in ranges:
        if size > 0 and overlaps_reserved(base, base + size - 1):
            errors.append(
                f"DTBO DAPHNE3 tuple 0x{base:08X}/0x{size:X} overlaps the reserved "
                "self-trigger range"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xsa", type=Path, required=True)
    parser.add_argument("--dtbo", type=Path, required=True)
    args = parser.parse_args()

    errors: list[str] = []
    try:
        errors.extend(validate_xsa(args.xsa))
    except (OSError, KeyError, ValueError, json.JSONDecodeError, ET.ParseError, zipfile.BadZipFile) as error:
        errors.append(f"could not validate XSA address map: {error}")
    try:
        errors.extend(validate_dtbo(args.dtbo))
    except (OSError, ValueError) as error:
        errors.append(f"could not validate DTBO address map: {error}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(
        "Full-stream artifact map: PASS "
        "(MUX_S_AXI=0xA0020000/64K; 0xA0010000/64K unmapped)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
