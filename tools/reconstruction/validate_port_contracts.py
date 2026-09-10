"""Validate reusable Cybertron port preflight contracts against built CYBRUN."""

from pathlib import Path
import hashlib
import json
import sys


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNTIME = ROOT / "build" / "reconstruction" / "CYBRUN"
ROOM_FIXTURE = ROOT / "analysis" / "reconstruction" / "room_render_fixture.json"
LOAD_ADDRESS = 0x0D80


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> None:
    runtime_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_RUNTIME
    payload = runtime_path.read_bytes()
    if len(payload) != 0x2280:
        fail(f"{runtime_path} has {len(payload)} bytes; expected 8832")

    def block(address: int, count: int) -> bytes:
        offset = address - LOAD_ADDRESS
        result = payload[offset : offset + count]
        if len(result) != count:
            fail(f"${address:04X}: requested {count} bytes outside CYBRUN")
        return result

    # $2F40/$2F80 must map every graphic ID to its exact 24-byte record.
    pointer_high = block(0x2F40, 64)
    pointer_low = block(0x2F80, 64)
    for graphic_id in range(64):
        actual = pointer_low[graphic_id] | pointer_high[graphic_id] << 8
        expected = 0x2900 + graphic_id * 24
        if actual != expected:
            fail(f"graphic ${graphic_id:02X}: pointer ${actual:04X}, expected ${expected:04X}")

    # $16E1: direction*4 selects the upper cell. Phase groups 0,1,2,3
    # select lower offsets +1,+2,+3,+2 respectively.
    player_selector_rows = 0
    for direction in range(8):
        upper = direction * 4
        for phase_group, lower_offset in enumerate((1, 2, 3, 2)):
            lower = upper + lower_offset
            if not (0 <= upper < 32 and 0 <= lower < 32):
                fail(
                    f"direction {direction}, phase group {phase_group}: "
                    f"graphic pair ${upper:02X}/${lower:02X} outside player bank"
                )
            player_selector_rows += 1

    # $1735 player start tuples must agree with the renderer's byte-address
    # formula at $1D85 for both vertically adjacent cells.
    start_y = block(0x27B8, 4)
    start_x = block(0x27BC, 4)
    second_high = block(0x27C0, 4)
    second_low = block(0x27C4, 4)
    first_high = block(0x27C8, 4)
    first_low = block(0x27CC, 4)

    def object_pointer(x: int, y: int) -> int:
        return 0x3000 + 0x0140 * (y & 0xFE) + 8 * x

    for start in range(4):
        first_actual = first_low[start] | first_high[start] << 8
        second_actual = second_low[start] | second_high[start] << 8
        first_expected = object_pointer(start_x[start], start_y[start])
        second_expected = object_pointer(start_x[start], start_y[start] + 2)
        if first_actual != first_expected or second_actual != second_expected:
            fail(
                f"player start {start}: pointers ${first_actual:04X}/${second_actual:04X}, "
                f"expected ${first_expected:04X}/${second_expected:04X}"
            )

    # $1C4D/$1BFC: project all eight shot directions from every player start.
    shot_y_offsets = tuple(value if value < 0x80 else value - 0x100 for value in block(0x2788, 8))
    shot_x_offsets = tuple(value if value < 0x80 else value - 0x100 for value in block(0x2790, 8))

    def projectile_pointer(x: int, y: int) -> int:
        return object_pointer(x, y) + (4 if y & 1 else 0)

    projectile_rows = 0
    for start in range(4):
        for direction in range(8):
            x = (start_x[start] + shot_x_offsets[direction]) & 0xFF
            y = (start_y[start] + shot_y_offsets[direction]) & 0xFF
            pointer = projectile_pointer(x, y)
            if not (0x3000 <= pointer < 0x8000):
                fail(
                    f"player start {start}, shot direction {direction}: "
                    f"screen pointer ${pointer:04X} outside bitmap"
                )
            projectile_rows += 1

    # $1B87 movement deltas must reproduce $1BFC for both even and odd Y.
    delta_y = tuple(value if value < 0x80 else value - 0x100 for value in block(0x2798, 8))
    delta_x = tuple(value if value < 0x80 else value - 0x100 for value in block(0x27A0, 8))
    pointer_high_delta = block(0x27A8, 8)
    pointer_low_delta = block(0x27B0, 8)
    movement_rows = 0
    for x, y in ((0x20, 0x20), (0x20, 0x21), (0x07, 0x22), (0x45, 0x23)):
        before = projectile_pointer(x, y)
        for direction in range(8):
            new_x = (x + delta_x[direction]) & 0xFF
            new_y = (y + delta_y[direction]) & 0xFF
            raw_delta = pointer_low_delta[direction] | pointer_high_delta[direction] << 8
            if raw_delta & 0x8000:
                raw_delta -= 0x10000
            after = (before + raw_delta) & 0xFFFF
            if delta_y[direction] > 0 and not (new_y & 1):
                after = (after + 0x0278) & 0xFFFF
            elif delta_y[direction] < 0 and (new_y & 1):
                after = (after - 0x0278) & 0xFFFF
            expected = projectile_pointer(new_x, new_y)
            if after != expected:
                fail(
                    f"movement vector {direction} from ({x:02X},{y:02X}): "
                    f"pointer ${after:04X}, expected ${expected:04X}"
                )
            movement_rows += 1

    # G1: independently reproduce $1516/$0EFE and the two room-fill scans,
    # then compare every clean-screen result with the preserved original-output
    # digest. Room bank 0 is read from CYBRUN; banks 1-3 and the fill workspace
    # are the bounded semantic slices captured in room_render_fixture.json.
    fixture = json.loads(ROOM_FIXTURE.read_text(encoding="ascii"))
    if fixture.get("schema") != "cybertron.room_render_fixture.v1":
        fail(f"unsupported room fixture schema in {ROOM_FIXTURE}")

    room_data = bytearray(block(0x27E0, 0x120))
    for bank in fixture["external_room_banks"]:
        packed = bytes.fromhex(bank["packed_bytes"])
        if len(packed) != 0x120:
            fail(f"{bank['room_ids']}: external room bank has {len(packed)} bytes")
        room_data.extend(packed)
    if len(room_data) != 64 * 0x12:
        fail(f"room data has {len(room_data)} bytes; expected 1152")

    feature_mask = bytes.fromhex(fixture["feature_mask_0760"])
    fill_patterns = bytes.fromhex(fixture["fill_patterns_07a0"])
    if len(feature_mask) != 64 or len(fill_patterns) != 4 * 24:
        fail("room fixture feature-mask or fill-pattern extent is invalid")

    def runtime_byte(address: int) -> int:
        return block(address, 1)[0]

    def generated_tile_pattern(tile_class: int) -> bytes:
        if tile_class == 0:
            return bytes(24)
        result = bytearray()
        outer_index = ((tile_class >> 2) << 1) | (tile_class & 1)
        middle_index = tile_class >> 2
        right_index = tile_class >> 1
        for band in range(3):
            source = 0x2F00 + runtime_byte(0x2FC8 + band)
            result.append(runtime_byte(source + runtime_byte(0x2FD7 + outer_index)))
            result.append(runtime_byte(source + runtime_byte(0x2FCF + outer_index)))
            while len(result) & 7 < 6:
                result.append(runtime_byte(source + runtime_byte(0x2FCB + middle_index)))
            result.append(runtime_byte(source + runtime_byte(0x2FCF + right_index)))
            result.append(runtime_byte(source + runtime_byte(0x2FD7 + right_index)))
        if len(result) != 24:
            fail(f"tile class ${tile_class:X}: generated {len(result)} bytes")
        return bytes(result)

    tile_patterns = tuple(generated_tile_pattern(tile_class) for tile_class in range(16))

    def tile_destination(x_cell: int, y_cell: int) -> int:
        return 0x3000 + 0x0280 * y_cell + 0x18 * x_cell + 0x08

    def screen_offset(address: int) -> int:
        offset = address - 0x3000
        if not (0 <= offset and offset + 24 <= 0x5000):
            fail(f"screen cell ${address:04X} is outside $3000-$7FFF")
        return offset

    expected_variants = {
        (entry["room"], entry["variant"]): entry for entry in fixture["variants"]
    }
    if len(expected_variants) != 256:
        fail(f"room fixture has {len(expected_variants)} unique variants; expected 256")

    room_rows = 0
    for room_id in range(64):
        packed_room = room_data[room_id * 0x12 : (room_id + 1) * 0x12]

        def tile_class_at(row: int, column: int) -> int:
            value = packed_room[row * 3 + column // 2]
            return value & 0x0F if not (column & 1) else value >> 4

        for variant in range(4):
            screen = bytearray(0x5000)
            draw_calls = 0
            fill_1f19 = 0
            fill_1ec8 = 0

            def draw_tile(x_cell: int, y_cell: int, tile_class: int) -> None:
                nonlocal draw_calls
                offset = screen_offset(tile_destination(x_cell, y_cell))
                screen[offset : offset + 24] = tile_patterns[tile_class]
                draw_calls += 1

            def read_screen(address: int) -> int:
                offset = address - 0x3000
                if not 0 <= offset < len(screen):
                    fail(f"screen read ${address:04X} is outside $3000-$7FFF")
                return screen[offset]

            def copy_fill(address: int) -> None:
                offset = screen_offset(address)
                start = variant * 24
                screen[offset : offset + 24] = fill_patterns[start : start + 24]

            def fill_major_column(x_cell: int) -> None:
                nonlocal fill_1f19
                if not feature_mask[room_id] or x_cell == 0:
                    return
                object_x = x_cell * 3 - 2
                for object_y in range(0x06, 0x3A, 2):
                    left = object_pointer(object_x, object_y)
                    if read_screen(left) and not read_screen(left + 0x18):
                        copy_fill(left + 0x18)
                        fill_1f19 += 1

            def fill_gap_column(x_cell: int) -> None:
                nonlocal fill_1ec8
                if not feature_mask[room_id]:
                    return
                object_x = x_cell * 3 + 1
                between_edges = False
                for object_y in range(0x06, 0x3A, 2):
                    address = object_pointer(object_x, object_y)
                    if read_screen(address):
                        between_edges = not between_edges
                    elif between_edges:
                        copy_fill(address)
                        fill_1ec8 += 1

            x_cell = 0
            for column in range(6):
                horizontal_bridge_bits = []
                y_cell = 3
                for row in range(6):
                    tile_class = tile_class_at(row, column)
                    horizontal_bridge_bits.append(tile_class & 0x08)
                    draw_tile(x_cell, y_cell, tile_class)
                    if row != 5:
                        bridge_class = 0x03 if tile_class & 0x02 else 0x00
                        for _ in range(4):
                            y_cell += 1
                            draw_tile(x_cell, y_cell, bridge_class)
                        y_cell += 1

                fill_major_column(x_cell)
                if column == 5:
                    break

                for _ in range(4):
                    x_cell += 1
                    y_cell = 3
                    for row in range(6):
                        draw_tile(x_cell, y_cell, 0x0C if horizontal_bridge_bits[row] else 0x00)
                        if row != 5:
                            for _ in range(4):
                                y_cell += 1
                                draw_tile(x_cell, y_cell, 0x00)
                            y_cell += 1
                    fill_gap_column(x_cell)
                x_cell += 1

            expected = expected_variants[(room_id, variant)]
            actual_digest = hashlib.sha256(screen).hexdigest()
            actual_nonzero = sum(value != 0 for value in screen)
            actual_fields = (draw_calls, fill_1f19, fill_1ec8, actual_nonzero, actual_digest)
            expected_fields = (
                expected["draw_calls"],
                expected["fill_1f19"],
                expected["fill_1ec8"],
                expected["nonzero_bytes"],
                expected["sha256"],
            )
            if actual_fields != expected_fields:
                fail(
                    f"room ${room_id:02X} variant {variant}: "
                    f"actual {actual_fields}, expected {expected_fields}"
                )
            room_rows += 1

    print(
        "Validated port preflight: "
        "64 graphic pointers, "
        f"{player_selector_rows} player selector rows, "
        "4 player starts, "
        f"{projectile_rows} shot projections, "
        f"{movement_rows} movement projections, "
        f"{room_rows} room-render digests"
    )


if __name__ == "__main__":
    main()
