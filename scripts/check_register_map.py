#!/usr/bin/env python3
"""Check that the documented full-stream register map matches the RTL."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "Memory_Map.md"
STUFF_PATH = ROOT / "ip_repo/daphne3_ip/rtl/config/stuff.vhd"


def table_rows(text: str) -> dict[int, list[list[str]]]:
    """Return Markdown register rows grouped by their absolute address."""
    rows: dict[int, list[list[str]]] = {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 8 or re.fullmatch(r"0x[0-9A-Fa-f]{8}", cells[1]) is None:
            continue
        rows.setdefault(int(cells[1], 16), []).append(cells)
    return rows


def binary_constants(text: str) -> dict[str, int]:
    pattern = re.compile(
        r"constant\s+(\w+)\s*:\s*std_logic_vector\([^)]*\)\s*:=\s*\"([01]+)\"",
        re.IGNORECASE,
    )
    return {name: int(bits, 2) for name, bits in pattern.findall(text)}


def main() -> int:
    doc = DOC_PATH.read_text(encoding="utf-8")
    stuff = STUFF_PATH.read_text(encoding="utf-8")
    rows = table_rows(doc)
    errors: list[str] = []

    def require_row(
        address: int,
        register: str,
        access: str,
        *,
        size: str | None = None,
        default: str | None = None,
    ) -> None:
        matches = [row for row in rows.get(address, []) if row[2] == register]
        if len(matches) != 1:
            errors.append(
                f"0x{address:08X}: expected one '{register}' row, found {len(matches)}"
            )
            return
        row = matches[0]
        if row[4] != access:
            errors.append(
                f"0x{address:08X} {register}: access is {row[4]}, expected {access}"
            )
        if size is not None and row[3] != size:
            errors.append(
                f"0x{address:08X} {register}: size is {row[3]}, expected {size}"
            )
        if default is not None and row[5] != default:
            errors.append(
                f"0x{address:08X} {register}: default is {row[5]}, expected {default}"
            )

    constants = binary_constants(stuff)
    board_registers = {
        "FANCTRL_OFFSET": ("fan_speed_reg", "R/W", "8b"),
        "FAN0SPD_OFFSET": ("fan0_rpm", "R/O", "12b"),
        "FAN1SPD_OFFSET": ("fan1_rpm", "R/O", "12b"),
        "HVBIAS_OFFSET": ("hvbias_en_reg", "R/W", "1b"),
        "MUXEN_OFFSET": ("mux_en_reg", "R/W", "2b"),
        "MUXA_OFFSET": ("mux_a_reg", "R/W", "2b"),
        "LED_OFFSET": ("stat_led_reg", "R/W", "6b"),
        "VER_OFFSET": ("version", "R/O", "4b"),
        "CORE_EN_LO_OFFSET": ("core_enable_reg", "R/W", "32b"),
        "CORE_EN_HI_OFFSET": ("core_enable_reg", "R/W", "8b"),
    }
    for constant, (register, access, size) in board_registers.items():
        if constant not in constants:
            errors.append(f"RTL is missing board-control constant {constant}")
            continue
        require_row(0x94000000 + constants[constant], register, access, size=size)

    version_port = re.search(
        r"version\s*:\s*in\s+std_logic_vector\((\d+)\s+downto\s+0\)",
        stuff,
        re.IGNORECASE,
    )
    if version_port is None or int(version_port.group(1)) + 1 != 4:
        errors.append("full-stream board-control RTL version port is not 4 bits")

    # The full-stream mux has eight outputs with four lanes each, in linear order.
    for output in range(8):
        for lane in range(4):
            index = output * 4 + lane
            require_row(
                0xA0010000 + index * 4,
                f"muxctrl_reg({output})({lane})",
                "R/W",
                size="32b",
                default=f"0x{index:08X}",
            )

    if "## Hermes/10G sender control" not in doc or "0x98000000" not in doc:
        errors.append("0x98000000 must be documented as Hermes/10G sender control")
    if "## Stream input mux" not in doc:
        errors.append("0xA0010000 must be documented as the full-stream input mux")
    if "threshold_xc(" in doc:
        errors.append("self-trigger threshold registers appear in the full-stream map")
    if "asssociated" in doc:
        errors.append("misspelling 'asssociated' remains in the mux table")
    if "Readable, but not consumed by the active full-stream datapath" not in doc:
        errors.append("legacy channel-enable behavior is not stated")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("Register-map consistency check: PASS (full-stream mode)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
