#!/usr/bin/env python3
"""Check that the documented full-stream register map matches RTL and Vivado."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "Memory_Map.md"
STUFF_PATH = ROOT / "ip_repo/daphne3_ip/rtl/config/stuff.vhd"
MUX_PATH = ROOT / "ip_repo/daphne3_ip/rtl/stream/stream_input_mux.vhd"
MUX_SELECT_PATH = ROOT / "ip_repo/daphne3_ip/rtl/stream/stream_mux_select.vhd"
STREAM4_PATH = ROOT / "ip_repo/daphne3_ip/rtl/stream/stream4.vhd"
TOP_PATH = ROOT / "ip_repo/daphne3_ip/rtl/daphne3.vhd"
BD_PATH = ROOT / "xilinx/daphne_fullstream_bd_gen.tcl"
FLOW_PATH = ROOT / "xilinx/daphne_fullstream_vivado_flow.tcl"
MUX_BASE = 0xA0020000
MUX_RANGE = 0x00010000


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


def hex_constants(text: str) -> dict[str, int]:
    pattern = re.compile(
        r'constant\s+(\w+)\s*:\s*std_logic_vector\([^)]*\)\s*:=\s*X"([0-9A-Fa-f]+)"',
        re.IGNORECASE,
    )
    return {name: int(value, 16) for name, value in pattern.findall(text)}


def mux_reset_values(text: str) -> tuple[dict[tuple[int, int], int], list[str]]:
    """Return reset selector values keyed by (output, lane)."""
    pattern = re.compile(
        r'muxctrl_reg\((\d+)\)\((\d+)\)\s*<=\s*X"([0-9A-Fa-f]{2})"',
        re.IGNORECASE,
    )
    values: dict[tuple[int, int], int] = {}
    errors: list[str] = []
    for output_text, lane_text, value_text in pattern.findall(text):
        key = (int(output_text), int(lane_text))
        if key in values:
            errors.append(
                f"RTL defines muxctrl_reg({key[0]})({key[1]}) reset more than once"
            )
            continue
        values[key] = int(value_text, 16)
    return values, errors


def main() -> int:
    doc = DOC_PATH.read_text(encoding="utf-8")
    stuff = STUFF_PATH.read_text(encoding="utf-8")
    mux = MUX_PATH.read_text(encoding="utf-8")
    mux_select = MUX_SELECT_PATH.read_text(encoding="utf-8")
    stream4 = STREAM4_PATH.read_text(encoding="utf-8")
    top = TOP_PATH.read_text(encoding="utf-8")
    block_design = BD_PATH.read_text(encoding="utf-8")
    flow = FLOW_PATH.read_text(encoding="utf-8")
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

    constants = binary_constants(stuff) | hex_constants(stuff)
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

    identity_registers = {
        "FW_ID_MAGIC_OFFSET": (
            "fw_identity_magic",
            "FW_ID_MAGIC_C",
            0x44415048,
        ),
        "FW_ABI_VERSION_OFFSET": (
            "fw_abi_version",
            "FW_ABI_VERSION_C",
            0x00020000,
        ),
        "FW_VARIANT_ID_OFFSET": (
            "fw_variant_id",
            "FW_VARIANT_ID_C",
            0x00000002,
        ),
    }
    for offset_name, (register, value_name, expected_value) in identity_registers.items():
        if constants.get(offset_name) is None:
            errors.append(f"RTL is missing identity offset constant {offset_name}")
            continue
        if constants.get(value_name) != expected_value:
            actual = constants.get(value_name)
            errors.append(
                f"RTL identity constant {value_name} is {actual!r}, "
                f"expected 0x{expected_value:08X}"
            )
        require_row(
            0x94000000 + constants[offset_name],
            register,
            "R/O",
            size="32b",
            default=f"0x{expected_value:08X}",
        )
    if constants.get("FW_BUILD_ID_OFFSET") is None:
        errors.append("RTL is missing identity offset constant FW_BUILD_ID_OFFSET")
    else:
        require_row(
            0x94000000 + constants["FW_BUILD_ID_OFFSET"],
            "fw_build_id",
            "R/O",
            size="32b",
        )

    version_port = re.search(
        r"version\s*:\s*in\s+std_logic_vector\((\d+)\s+downto\s+0\)",
        stuff,
        re.IGNORECASE,
    )
    if version_port is None or int(version_port.group(1)) + 1 != 4:
        errors.append("full-stream board-control RTL version port is not 4 bits")
    top_version_generic = re.search(
        r"version\s*:\s*std_logic_vector\(3\s+downto\s+0\)",
        top,
        re.IGNORECASE,
    )
    if top_version_generic is None:
        errors.append("full-stream top-level legacy version generic is not 4 bits")
    if re.search(
        r"core_inst\s*:\s*entity\s+work\.stream_core.*?version\s*=>\s*version",
        top,
        re.IGNORECASE | re.DOTALL,
    ) is None:
        errors.append("full-stream header no longer receives the legacy version nibble")
    build_id_port = re.search(
        r"build_id\s*:\s*in\s+std_logic_vector\(31\s+downto\s+0\)",
        stuff,
        re.IGNORECASE,
    )
    if build_id_port is None:
        errors.append("full-stream board-control RTL build_id port is not 32 bits")
    if re.search(
        r'X"0"\s*&\s*build_id\(27\s+downto\s+0\)', stuff, re.IGNORECASE
    ) is None:
        errors.append("full-stream build ID readback is not zero-extended from 28 bits")
    build_id_generic = re.search(
        r"build_id\s*:\s*std_logic_vector\(31\s+downto\s+0\)",
        top,
        re.IGNORECASE,
    )
    if build_id_generic is None:
        errors.append("full-stream top-level build_id generic is not 32 bits")
    if "set_property CONFIG.build_id $bd_build_id $DAPHNE3_0" not in block_design:
        errors.append("Vivado block design does not stamp the full-stream build_id")
    if re.search(
        r'set\s+cfg\(bd_build_id\)\s+"32\'h0\$version_git_sha"', flow
    ) is None:
        errors.append("Vivado flow does not zero-extend the seven-hex build ID")

    mux_defaults, mux_default_errors = mux_reset_values(mux)
    errors.extend(mux_default_errors)

    # The full-stream mux has eight outputs with four lanes each. The selector
    # value is nibble-encoded as AFE/channel rather than a linear input index.
    for output in range(8):
        for lane in range(4):
            index = output * 4 + lane
            key = (output, lane)
            if key not in mux_defaults:
                errors.append(
                    f"RTL is missing muxctrl_reg({output})({lane}) reset value"
                )
                continue
            require_row(
                MUX_BASE + index * 4,
                f"muxctrl_reg({output})({lane})",
                "R/W",
                size="32b",
                default=f"0x{mux_defaults[key]:08X}",
            )

    require_row(
        MUX_BASE + 0x80,
        "mux_activation",
        "R/W",
        size="32b",
        default="0x00000000",
    )

    unexpected_mux_defaults = sorted(
        key
        for key in mux_defaults
        if key[0] not in range(8) or key[1] not in range(4)
    )
    if unexpected_mux_defaults:
        errors.append(
            "RTL defines reset values outside the 8x4 mux register bank: "
            + ", ".join(
                f"muxctrl_reg({output})({lane})"
                for output, lane in unexpected_mux_defaults
            )
        )

    # The selector bank crosses as stable bundled data, guarded by a
    # synchronized level request. Enforce the key structural parts of that
    # contract so later register-map edits cannot silently restore live AXI
    # writes or remove the acknowledgement handshake.
    cdc_patterns = {
        "stream-domain active selector bank": (
            r"signal\s+muxctrl_active_reg\s*:\s*array_8x4x8_type"
        ),
        "AXI-domain enable request": (
            r"signal\s+mux_enable_request_axi\s*:\s*std_logic"
        ),
        "request control write at offset 0x80": (
            r'when\s+X"80"\s*=>\s*'
            r"mux_enable_request_axi\s*<=\s*AXI_IN\.WDATA\(0\)"
        ),
        "atomic shadow-bank capture": (
            r"muxctrl_active_reg\s*<=\s*muxctrl_reg"
        ),
        "fail-closed active selector assignment": (
            r'muxctrl_active_reg\s*<=\s*\(others\s*=>\s*'
            r'\(others\s*=>\s*X"FF"\)\)'
        ),
        "active selector datapath": (
            r"muxctrl\s*=>\s*muxctrl_active_reg\(s\)\(c\)"
        ),
        "active selector export": (
            r"muxctrl\s*<=\s*muxctrl_active_reg"
        ),
        "stream-domain committed enable export": (
            r"stream_enable\s*<=\s*mux_active_stream"
        ),
        "request/acknowledgement status readback": (
            r'X"0000000"\s*&\s*"00"\s*&\s*mux_active_ack_sync\s*&\s*'
            r"mux_enable_request_axi"
        ),
    }
    for description, pattern in cdc_patterns.items():
        if re.search(pattern, mux, re.IGNORECASE | re.DOTALL) is None:
            errors.append(f"mux RTL is missing {description}")

    for synchronizer in (
        "mux_enable_request_meta",
        "mux_enable_request_sync",
        "stream_resetn_meta",
        "stream_resetn_sync",
        "mux_active_ack_meta",
        "mux_active_ack_sync",
    ):
        if re.search(
            rf'attribute\s+ASYNC_REG\s+of\s+{synchronizer}\s*:\s*signal\s+is\s+"TRUE"',
            mux,
            re.IGNORECASE,
        ) is None:
            errors.append(f"mux CDC synchronizer {synchronizer} lacks ASYNC_REG")

    if "bundled-data CDC" not in mux:
        errors.append("mux RTL does not document bundled-data CDC stability")
    if re.search(
        r"stream_reset_sync_proc\s*:\s*process\(clock,\s*AXI_IN\.ARESETN\).*?"
        r"stream_resetn_sync\s*<=\s*stream_resetn_meta",
        mux,
        re.IGNORECASE | re.DOTALL,
    ) is None:
        errors.append("mux RTL lacks asynchronous-assert/synchronous-release reset CDC")
    if "requested-enable level" not in doc or "active acknowledgement" not in doc:
        errors.append("mux activation request/acknowledgement protocol is not documented")

    # Board/logical selector bytes are an ABI and are copied unchanged into
    # packet headers. Only the payload source lookup is permuted to match the
    # frontend PL ordering [0,4,3,2,1].
    source_lookups = {
        int(selector, 16): (int(din_index), int(channel))
        for din_index, channel, selector in re.findall(
            r'din\((\d+)\)\((\d+)\)\(15\s+downto\s+2\)\s+when\s+'
            r'\(muxctrl\s*=\s*X"([0-9A-Fa-f]{2})"\)',
            mux_select,
            re.IGNORECASE,
        )
    }
    board_to_pl = (0, 4, 3, 2, 1)
    for board_afe, pl_index in enumerate(board_to_pl):
        for channel in range(9):
            selector = (board_afe << 4) | channel
            actual = source_lookups.get(selector)
            expected = (pl_index, channel)
            if actual != expected:
                errors.append(
                    f"selector 0x{selector:02X} maps to {actual}, expected "
                    f"PL din{expected} for board AFE {board_afe}"
                )
    if "packet header remains `0x10`" not in doc or "PL `din(4)(0)`" not in doc:
        errors.append("board/logical selector and PL AFE permutation are not documented")

    sender_reset_patterns = {
        "unchanged mux selector IDs connected to top-level channel IDs": (
            r"muxctrl\s*=>\s*channel_id"
        ),
        "unchanged top-level channel IDs connected to stream core": (
            r"channel_id\s*=>\s*channel_id"
        ),
        "mux active signal connected to top-level stream enable": (
            r"stream_enable\s*=>\s*stream_mux_enable"
        ),
        "mux disable connected to stream-core reset": (
            r"reset\s*=>\s*not\s+stream_mux_enable"
        ),
    }
    for description, pattern in sender_reset_patterns.items():
        if re.search(pattern, top, re.IGNORECASE) is None:
            errors.append(f"top-level RTL is missing {description}")

    stream4_reset_patterns = {
        "FIFO reset while disabled": r"rst\s*=>\s*reset_clean",
        "FSM reset to record-boundary search": (
            r"if\s*\(reset_clean\s*=\s*'1'\)\s*then\s*state\s*<=\s*rst"
        ),
        "immediate VALID suppression": (
            r"regout_proc\s*:\s*process\(clock,\s*reset\).*?"
            r"if\s+reset\s*=\s*'1'\s+then.*?valid_reg\s*<=\s*'0'"
        ),
    }
    for description, pattern in stream4_reset_patterns.items():
        if re.search(pattern, stream4, re.IGNORECASE | re.DOTALL) is None:
            errors.append(f"stream4 RTL is missing {description}")
    for lane in range(4):
        if re.search(
            rf"channel_id\({lane}\)\s*&\s*version",
            stream4,
            re.IGNORECASE,
        ) is None:
            errors.append(
                f"stream4 header lane {lane} does not contain the unchanged channel ID"
            )
    if "rst -> purge -> hold -> header" not in stream4:
        errors.append("stream4 RTL does not document record-boundary reset/rearm")
    if "first visible record begins with its timestamp" not in doc:
        errors.append("stream sender record-boundary reset/rearm is not documented")

    if "## Hermes/10G sender control" not in doc or "0x98000000" not in doc:
        errors.append("0x98000000 must be documented as Hermes/10G sender control")
    if "## Stream input mux" not in doc or "0xA002_0000" not in doc:
        errors.append("0xA0020000 must be documented as the full-stream input mux")
    mux_assignment = re.search(
        r"assign_bd_address\s+-offset\s+(0x[0-9A-Fa-f]+)\s+"
        r"-range\s+(0x[0-9A-Fa-f]+)[^\n]*DAPHNE3/MUX_S_AXI/reg0",
        block_design,
    )
    if mux_assignment is None:
        errors.append("Vivado block design is missing the MUX_S_AXI address assignment")
    elif (int(mux_assignment.group(1), 16), int(mux_assignment.group(2), 16)) != (
        MUX_BASE,
        MUX_RANGE,
    ):
        errors.append(
            "Vivado MUX_S_AXI window is "
            f"{mux_assignment.group(1)}/{mux_assignment.group(2)}, expected "
            f"0x{MUX_BASE:08X}/0x{MUX_RANGE:08X}"
        )
    reserved_rows = [address for address in rows if 0xA0010000 <= address < 0xA0020000]
    if reserved_rows:
        errors.append(
            "full-stream map uses addresses in the reserved self-trigger window: "
            + ", ".join(f"0x{address:08X}" for address in reserved_rows)
        )
    if "reserved for self-trigger threshold registers" not in doc:
        errors.append("the reserved self-trigger 0xA0010000 window is not documented")
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
