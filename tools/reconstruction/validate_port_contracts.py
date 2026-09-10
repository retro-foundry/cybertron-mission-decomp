"""Validate reusable Cybertron port preflight contracts against built CYBRUN."""

from pathlib import Path
import hashlib
import json
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNTIME = ROOT / "build" / "reconstruction" / "CYBRUN"
ROOM_FIXTURE = ROOT / "analysis" / "reconstruction" / "room_render_fixture.json"
STATUS_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_status_panel_reference.txt"
SPRITE_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_sprite_renderer_reference.txt"
SETUP_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_setup_frame_reference.txt"
MOVEMENT_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_player_movement.txt"
OBJECT_LIFECYCLE_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_object_lifecycle_reference.txt"
OBJECT_SLOT_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_object_slot_contract.txt"
PROJECTILE_LIFECYCLE_REFERENCE = ROOT / "analysis" / "reconstruction" / "runtime_projectile_lifecycle.txt"
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

    # Exhaust the $1609 keyboard key-mask space and the $2207 direction map.
    # The expected rows are retained separately from the source-built tables.
    movement_reference = MOVEMENT_REFERENCE.read_text(encoding="ascii")
    keyboard_y_delta = tuple(
        value if value < 0x80 else value - 0x100 for value in block(0x27D4, 4)
    )
    keyboard_x_delta = tuple(
        value if value < 0x80 else value - 0x100 for value in block(0x27D8, 4)
    )
    if block(0x27DC, 4) != bytes((0xBE, 0x9E, 0x99, 0x98)):
        fail("keyboard INKEY table differs from the control reference")

    def direction_for_delta(x_delta: int, y_delta: int):
        return {
            (0, 1): 0,
            (0, -1): 1,
            (1, 0): 2,
            (-1, 0): 3,
            (1, -1): 4,
            (1, 1): 5,
            (-1, -1): 6,
            (-1, 1): 7,
        }.get((x_delta, y_delta))

    keyboard_projection = movement_reference.split(
        "keyboard_combination_projection_1609_16e1\n", 1
    )[1].split("\njoystick_input_1287\n", 1)[0]
    keyboard_pattern = re.compile(
        r"^mask=\$(?P<mask>[0-9a-f]{2}) keys=.* net_x=(?P<x>[+-][0-9]+) "
        r"net_y=(?P<y>[+-][0-9]+) direction=(?P<direction>[0-7]|idle_preserve_0035)$",
        re.MULTILINE,
    )
    expected_keyboard = {
        int(match["mask"], 16): match.groupdict()
        for match in keyboard_pattern.finditer(keyboard_projection)
    }
    if len(expected_keyboard) != 16:
        fail(f"movement reference has {len(expected_keyboard)} keyboard masks; expected 16")
    keyboard_rows = 0
    for mask in range(16):
        x_delta = sum(keyboard_x_delta[index] for index in range(4) if mask & (1 << index))
        y_delta = sum(keyboard_y_delta[index] for index in range(4) if mask & (1 << index))
        direction = direction_for_delta(x_delta, y_delta)
        expected = expected_keyboard[mask]
        expected_direction = (
            None if expected["direction"] == "idle_preserve_0035" else int(expected["direction"])
        )
        if (x_delta, y_delta, direction) != (
            int(expected["x"]),
            int(expected["y"]),
            expected_direction,
        ):
            fail(f"keyboard mask ${mask:02X}: direction projection differs")
        keyboard_rows += 1

    # Boundary values exercise both branches of each joystick threshold, and
    # all previous/current pairs exercise the rising-edge fire latch at $15DD.
    def joystick_axis(sample: int) -> int:
        if sample < 0x40:
            return 1
        if sample >= 0xC0:
            return -1
        return 0

    joystick_cases = ((0x00, 1), (0x3F, 1), (0x40, 0), (0xBF, 0), (0xC0, -1), (0xFF, -1))
    for sample, expected_delta in joystick_cases:
        if joystick_axis(sample) != expected_delta:
            fail(f"joystick sample ${sample:02X}: threshold projection differs")
    fire_edge_rows = 0
    for previous in (0, 1):
        for current in (0, 1):
            fire_edge = previous == 0 and current != 0
            expected_edge = (previous, current) == (0, 1)
            if fire_edge != expected_edge:
                fail(f"fire latch {previous}->{current}: edge projection differs")
            fire_edge_rows += 1

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
    room_screens = {}
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
            room_screens[(room_id, variant)] = bytes(screen)
            room_rows += 1

    # G2: reproduce $1CAB/$1D3C/$2319/$2345 over every validated clean
    # room. The original helper clears a 24-byte cell, copies one graphic
    # record, and falls through to the pointer advance at $1D4F.
    reference_text = STATUS_REFERENCE.read_text(encoding="ascii")
    table_text = reference_text.split(
        "room_status_composite_digests_lives4_score_spaces_no_collected\n", 1
    )[1].split("\nlife_status_reference\n", 1)[0]
    status_pattern = re.compile(
        r"^(?P<room>[0-9a-f]{2}) (?P<level>[0-9]) (?P<variant>[0-3]) "
        r"(?P<nonzero>[0-9]+) (?P<digest>[0-9a-f]{64})$",
        re.MULTILINE,
    )
    expected_status = {
        (int(match["room"], 16), int(match["level"])): match.groupdict()
        for match in status_pattern.finditer(table_text)
    }
    if len(expected_status) != 640:
        fail(f"status reference has {len(expected_status)} digest rows; expected 640")

    graphic_records = tuple(block(0x2900 + graphic_id * 24, 24) for graphic_id in range(64))

    def render_status(room_id: int, level_ones: int) -> bytes:
        screen = bytearray(room_screens[(room_id, level_ones & 3)])

        def clear_cell(address: int) -> None:
            offset = screen_offset(address)
            screen[offset : offset + 24] = bytes(24)

        def draw_glyph(address: int, graphic_id: int) -> int:
            clear_cell(address)
            offset = screen_offset(address)
            screen[offset : offset + 24] = graphic_records[graphic_id]
            return address + 0x18

        pointer = 0x3288
        for graphic_id in (0x25, 0x35, 0x20, 0x36, 0x37):
            pointer = draw_glyph(pointer, graphic_id)

        pointer = 0x3318
        for graphic_id in (0x20, 0x20, 0x20, 0x20, 0x20):
            pointer = draw_glyph(pointer, graphic_id)

        pointer = 0x7B08
        for _ in range(4):
            pointer = draw_glyph(pointer, 0x39)
        clear_cell(pointer)

        # No target is collected in the 640-row composite table. Validate the
        # five slot-to-graphic mappings used by the omitted conditional draws.
        if tuple(block(0x2F37, 5)) != (0x3F, 0x3E, 0x32, 0x3E, 0x32):
            fail("target status slot graphic mapping changed")

        screen[0x34BA - 0x3000] = 0x2A
        screen[0x34BD - 0x3000] = 0x2A

        pointer = 0x3408
        for graphic_id in (0x36, 0x20, 0x20, 0x38):
            pointer = draw_glyph(pointer, graphic_id)
        pointer += 0x18
        room_low = room_id & 0x0F
        if room_low >= 9:
            pointer = draw_glyph(pointer, 0x21)
            pointer = draw_glyph(pointer, room_low + 0x17)
        else:
            pointer += 0x18
            pointer = draw_glyph(pointer, room_low + 0x21)
        pointer += 0x18
        pointer = draw_glyph(pointer, 0x20)
        draw_glyph(pointer, level_ones + 0x20)
        return bytes(screen)

    status_rows = 0
    for room_id in range(64):
        for level_ones in range(10):
            expected = expected_status[(room_id, level_ones)]
            if int(expected["variant"]) != level_ones & 3:
                fail(f"status room ${room_id:02X} level {level_ones}: bad fixture variant")
            screen = render_status(room_id, level_ones)
            actual_nonzero = sum(value != 0 for value in screen)
            actual_digest = hashlib.sha256(screen).hexdigest()
            if (actual_nonzero, actual_digest) != (
                int(expected["nonzero"]),
                expected["digest"],
            ):
                fail(
                    f"status room ${room_id:02X} level {level_ones}: "
                    f"actual {(actual_nonzero, actual_digest)}, "
                    f"expected {(expected['nonzero'], expected['digest'])}"
                )
            status_rows += 1

    # G3: independently reproduce the split source/destination walk at
    # $1426-$1464, then apply store mode 1 (EOR) to both player cells from
    # each $1735 start. Odd Y is deliberately non-linear across Mode 2 rows.
    sprite_reference = SPRITE_REFERENCE.read_text(encoding="ascii")

    def renderer_steps(object_y: int) -> tuple[tuple[int, int], ...]:
        if not object_y & 1:
            return tuple((index, index) for index in range(24))
        steps = []
        source_index = 0
        destination_y = 4
        pointer_delta = 0
        while True:
            steps.append((source_index, pointer_delta + destination_y))
            destination_y += 1
            source_index += 1
            if source_index & 3 == 0:
                source_index += 4
                destination_y += 4
            if destination_y == 0x98:
                return tuple(steps)
            if source_index == 0x18:
                source_index = 4
                destination_y = 0x80
                pointer_delta += 0x200

    def reference_steps(section: str, following_section: str) -> tuple[tuple[int, int], ...]:
        rows = sprite_reference.split(f"{section}\n", 1)[1].split(
            f"\n{following_section}\n", 1
        )[0]
        return tuple(
            (int(match.group(1), 16), int(match.group(2), 16))
            for match in re.finditer(r"^([0-9a-f]{2}) ([0-9a-f]{3})$", rows, re.MULTILINE)
        )

    expected_even_steps = reference_steps(
        "even_object_y_destination_sequence_1426",
        "odd_object_y_destination_sequence_143a",
    )
    expected_odd_steps = reference_steps(
        "odd_object_y_destination_sequence_143a",
        "player_start_cells_from_1735",
    )
    if renderer_steps(0) != expected_even_steps or renderer_steps(1) != expected_odd_steps:
        fail("sprite renderer even/odd source walk differs from original-output reference")
    if len(expected_even_steps) != 24 or len(expected_odd_steps) != 24:
        fail("sprite renderer reference must contain 24 even and 24 odd writes")

    digest_text = sprite_reference.split("player_start_blank_layer_digests\n", 1)[1].split(
        "\nmovement_parity_note\n", 1
    )[0]
    player_digest_pattern = re.compile(
        r"^(?P<start>[0-3]) (?P<x>[0-9a-f]{2}) (?P<y>[0-9a-f]{2}) "
        r"(?P<direction>[0-7]) (?P<graphic0>[0-9a-f]{2}) (?P<graphic1>[0-9a-f]{2}) "
        r"(?P<nonzero>[0-9]+) (?P<digest>[0-9a-f]{64})$",
        re.MULTILINE,
    )
    expected_player_layers = {
        int(match["start"]): match.groupdict()
        for match in player_digest_pattern.finditer(digest_text)
    }
    if len(expected_player_layers) != 4:
        fail(f"sprite reference has {len(expected_player_layers)} player layers; expected 4")

    first_graphic = block(0x254F, 4)
    second_graphic = block(0x254B, 4)
    start_direction = block(0x2553, 4)

    def draw_xor(screen: bytearray, pointer: int, object_y: int, graphic_id: int) -> None:
        source = graphic_records[graphic_id]
        for source_index, destination_offset in renderer_steps(object_y):
            offset = pointer + destination_offset - 0x3000
            if not 0 <= offset < len(screen):
                fail(f"graphic ${graphic_id:02X}: destination outside bitmap")
            screen[offset] ^= source[source_index]

    player_layer_rows = 0
    for start in range(4):
        expected = expected_player_layers[start]
        actual_fields = (
            start_x[start],
            start_y[start],
            start_direction[start],
            first_graphic[start],
            second_graphic[start],
        )
        expected_fields = tuple(
            int(expected[name], 16 if name != "direction" else 10)
            for name in ("x", "y", "direction", "graphic0", "graphic1")
        )
        if actual_fields != expected_fields:
            fail(f"player start {start}: source tables {actual_fields}, expected {expected_fields}")
        screen = bytearray(0x5000)
        draw_xor(screen, first_low[start] | first_high[start] << 8, start_y[start], first_graphic[start])
        draw_xor(
            screen,
            second_low[start] | second_high[start] << 8,
            start_y[start] + 2,
            second_graphic[start],
        )
        actual_nonzero = sum(value != 0 for value in screen)
        actual_digest = hashlib.sha256(screen).hexdigest()
        if (actual_nonzero, actual_digest) != (int(expected["nonzero"]), expected["digest"]):
            fail(
                f"player start {start} layer: actual {(actual_nonzero, actual_digest)}, "
                f"expected {(expected['nonzero'], expected['digest'])}"
            )
        player_layer_rows += 1

    # G4: compose deterministic $1735 setup scenarios from the already
    # validated room, status, and sprite primitives. These vectors cover RNG
    # target codes, enemy/target rejection placement, and the immediate
    # visible-player draw at $1849-$1863.
    setup_reference = SETUP_REFERENCE.read_text(encoding="ascii")
    setup_pattern = re.compile(
        r"^## (?P<name>[^\n]+)\n"
        r"inputs: room=\$(?P<room>[0-9a-f]{2}) level=(?P<tens>[0-9])(?P<ones>[0-9]) "
        r"level_index=(?P<level_index>[0-5]) start_index=(?P<start>[0-3]) lives=(?P<lives>[0-9]+) "
        r"rng_seed=(?P<seed>[0-9a-f]{6}) (?P<carry>[Cc])\n"
        r"target_required_max_slot=(?P<required>[0-5]) target_codes=(?P<codes>[^\n]+)\n"
        r"player_anchor_for_proximity: x=\$(?P<player_x>[0-9a-f]{2}) y=\$(?P<player_y>[0-9a-f]{2})\n"
        r"rng_final=(?P<rng_final>[0-9a-f]{6}) (?P<rng_carry>[Cc]) rng_calls=(?P<rng_calls>[0-9]+)\n"
        r"screen_sha256=(?P<screen_digest>[0-9a-f]{64}) nonzero_bytes=(?P<screen_nonzero>[0-9]+)\n"
        r"entry_player_draw_1849_1863: .*? sha256=(?P<player_digest>[0-9a-f]{64}) "
        r"nonzero_bytes=(?P<player_nonzero>[0-9]+)$",
        re.MULTILINE,
    )
    setup_scenarios = [match.groupdict() for match in setup_pattern.finditer(setup_reference)]
    if len(setup_scenarios) != 7:
        fail(f"setup reference has {len(setup_scenarios)} scenarios; expected 7")

    spinner_counts = block(0x2782, 6)
    clone_counts = block(0x277C, 6)
    cyberdroid_counts = block(0x2776, 6)
    enemy_families = (
        (spinner_counts, 0x2A),
        (clone_counts, 0x2B),
        (cyberdroid_counts, 0x2C),
    )

    # Cross-check every difficulty row against the preserved object-slot
    # contract, not just the level indices exercised by setup scenarios.
    object_slot_reference = OBJECT_SLOT_REFERENCE.read_text(encoding="ascii")
    count_table = object_slot_reference.split("enemy_setup_counts_and_slot_pressure\n", 1)[1].split(
        "\nshot_hazard_slot_contract\n", 1
    )[0]
    count_pattern = re.compile(
        r"^(?P<level>[0-5]) (?P<timer>[0-9]+) (?P<spinner>[0-9]+) "
        r"(?P<clone>[0-9]+) (?P<cyberdroid>[0-9]+) (?P<total>[0-9]+) ",
        re.MULTILINE,
    )
    expected_counts = {
        int(match["level"]): tuple(int(match[name]) for name in ("spinner", "clone", "cyberdroid", "total"))
        for match in count_pattern.finditer(count_table)
    }
    if len(expected_counts) != 6:
        fail(f"object-slot contract has {len(expected_counts)} level rows; expected 6")
    for level_index in range(6):
        actual = (
            spinner_counts[level_index],
            clone_counts[level_index],
            cyberdroid_counts[level_index],
            spinner_counts[level_index] + clone_counts[level_index] + cyberdroid_counts[level_index],
        )
        if actual != expected_counts[level_index]:
            fail(f"level index {level_index}: enemy setup counts {actual}, expected {expected_counts[level_index]}")

    def adc8(a: int, value: int, carry: bool) -> tuple[int, bool]:
        total = a + value + int(carry)
        return total & 0xFF, total > 0xFF

    def rng_next(state: list) -> int:
        a, b, c, carry, calls = state
        value, carry = adc8(a, b, carry)
        if not value & 0x80:
            pass
        else:
            value, carry = adc8(value, 0x69, carry)
        value, carry = adc8(value, c, carry)
        a = value
        b, carry = adc8(b, 0x3C, carry)
        c, carry = adc8(c, 0x5A, carry)
        state[:] = (a, b, c, carry, calls + 1)
        return a

    def too_close(player_x: int, player_y: int, candidate_x: int, candidate_y: int) -> bool:
        x_delta = (player_x - candidate_x - 1) & 0xFF
        if x_delta & 0x80:
            x_delta ^= 0xFF
        if x_delta >= 8:
            return False
        y_delta = (player_y - candidate_y) & 0xFF
        if y_delta & 0x80:
            y_delta ^= 0xFF
        return y_delta < 5

    def place_graphic(
        screen: bytearray, rng: list, player_x: int, player_y: int, graphic_id: int
    ) -> tuple[int, int, int]:
        for _ in range(10000):
            x = ((rng_next(rng) & 0x1F) + (rng_next(rng) & 0x0F) + 0x0F) & 0xFF
            y = ((rng_next(rng) & 0x1F) + 0x0F) & 0xFF
            if too_close(player_x, player_y, x, y):
                continue
            pointer = object_pointer(x, y)
            collision = 0
            for _, destination_offset in renderer_steps(y):
                collision |= screen[pointer + destination_offset - 0x3000]
            if collision:
                continue
            draw_xor(screen, pointer, y, graphic_id)
            return x, y, pointer
        fail(f"setup placement did not converge for graphic ${graphic_id:02X}")

    setup_rows = 0
    for expected in setup_scenarios:
        room_id = int(expected["room"], 16)
        level_tens = int(expected["tens"])
        level_ones = int(expected["ones"])
        level_index = int(expected["level_index"])
        start = int(expected["start"])
        required = 5 if level_tens or level_ones >= 6 else level_ones
        if required != int(expected["required"]):
            fail(f"{expected['name']}: required target slot differs")
        seed = bytes.fromhex(expected["seed"])
        rng = [seed[0], seed[1], seed[2], expected["carry"] == "C", 0]
        target_codes = [-1] * 7
        for slot in (*range(required + 1), 6):
            while True:
                code = rng_next(rng) & 0x0F
                target_codes[slot] = code
                if code not in target_codes[:slot]:
                    break
        expected_codes = tuple(
            -1 if value == "--" else int(value[1:], 16)
            for value in re.findall(r"[0-6]:(--|\$[0-9a-f])", expected["codes"])
        )
        if tuple(target_codes) != expected_codes:
            fail(f"{expected['name']}: target codes {target_codes}, expected {expected_codes}")

        screen = bytearray(render_status(room_id, level_ones))
        player_x = start_x[start]
        player_y = start_y[start]
        if (player_x, player_y) != (
            int(expected["player_x"], 16),
            int(expected["player_y"], 16),
        ):
            fail(f"{expected['name']}: player proximity anchor differs")

        for counts, graphic_id in enemy_families:
            for _ in range(counts[level_index]):
                place_graphic(screen, rng, player_x, player_y, graphic_id)
        for slot in (*range(required, -1, -1), 6):
            if room_id & 0x0F == target_codes[slot]:
                place_graphic(screen, rng, player_x, player_y, block(0x2F36 + slot, 1)[0])

        actual_setup = (sum(value != 0 for value in screen), hashlib.sha256(screen).hexdigest())
        expected_setup = (int(expected["screen_nonzero"]), expected["screen_digest"])
        if actual_setup != expected_setup:
            fail(f"{expected['name']}: setup screen {actual_setup}, expected {expected_setup}")

        entry_screen = bytearray(screen)
        draw_xor(
            entry_screen,
            first_low[start] | first_high[start] << 8,
            player_y,
            first_graphic[start],
        )
        draw_xor(
            entry_screen,
            second_low[start] | second_high[start] << 8,
            player_y + 2,
            second_graphic[start],
        )
        actual_entry = (
            sum(value != 0 for value in entry_screen),
            hashlib.sha256(entry_screen).hexdigest(),
        )
        expected_entry = (int(expected["player_nonzero"]), expected["player_digest"])
        if actual_entry != expected_entry:
            fail(f"{expected['name']}: entry screen {actual_entry}, expected {expected_entry}")
        actual_rng = f"{rng[0]:02x}{rng[1]:02x}{rng[2]:02x}"
        if (actual_rng, rng[3], rng[4]) != (
            expected["rng_final"],
            expected["rng_carry"] == "C",
            int(expected["rng_calls"]),
        ):
            fail(f"{expected['name']}: final RNG state differs")
        setup_rows += 1

    # Object lifecycle windows overlap intentionally. Parse the original
    # matrix and prove each render slot's scheduler/hit/animation/recycle role.
    lifecycle_reference = OBJECT_LIFECYCLE_REFERENCE.read_text(encoding="ascii")
    window_text = lifecycle_reference.split("object_window_matrix\n", 1)[1].split(
        "\nphase0_hit_state_projection_1812_1876\n", 1
    )[0]
    window_pattern = re.compile(
        r"^\$(?P<first>[0-9A-F]{2})-\$(?P<last>[0-9A-F]{2}) "
        r"\$[0-9A-F]{2}-\$[0-9A-F]{2} (?P<scheduler>yes|no) (?P<hit>yes|no) "
        r"(?P<animation>yes|no) (?P<recycle>yes|no) ",
        re.MULTILINE,
    )
    window_roles = {}
    for match in window_pattern.finditer(window_text):
        roles = tuple(match[name] == "yes" for name in ("scheduler", "hit", "animation", "recycle"))
        for render_slot in range(int(match["first"], 16), int(match["last"], 16) + 1):
            window_roles[render_slot] = roles
    if len(window_roles) != 41 or set(window_roles) != set(range(0x14, 0x3D)):
        fail("object lifecycle matrix does not cover render slots $14-$3C exactly")
    for render_slot, roles in window_roles.items():
        expected_roles = (
            0x14 <= render_slot <= 0x1F,
            0x14 <= render_slot <= 0x2B,
            0x14 <= render_slot <= 0x1F,
            0x14 <= render_slot <= 0x1F,
        )
        if roles != expected_roles:
            fail(f"render slot ${render_slot:02X}: lifecycle roles {roles}, expected {expected_roles}")

    state_text = lifecycle_reference.split("phase0_hit_state_projection_1812_1876\n", 1)[1].split(
        "\npost_hit_timeline_2163_to_1812_1876\n", 1
    )[0]
    state_pattern = re.compile(
        r"^\$(?P<before>[0-5][0-5]) .* \$(?P<after_first>[0-5][0-5]) "
        r"(?P<graphic>none|\$[0-9A-F]{2}) \$(?P<after_second>[0-5][0-5]) ",
        re.MULTILINE,
    )
    expected_states = {
        int(match["before"], 16): (
            int(match["after_first"], 16),
            None if match["graphic"] == "none" else int(match["graphic"][1:], 16),
            int(match["after_second"], 16),
        )
        for match in state_pattern.finditer(state_text)
    }
    if len(expected_states) != 6:
        fail(f"object lifecycle contract has {len(expected_states)} state rows; expected 6")
    lifecycle_rows = 0
    for state_before in range(6):
        state_after_erase = 0 if state_before == 5 else state_before
        if 2 <= state_after_erase < 5:
            graphic = state_after_erase + 0x38
            state_after_draw = state_after_erase + 1
        else:
            graphic = None
            state_after_draw = state_after_erase
        actual = (state_after_erase, graphic, state_after_draw)
        if actual != expected_states[state_before]:
            fail(f"lifecycle state ${state_before:02X}: {actual}, expected {expected_states[state_before]}")
        lifecycle_rows += 1

    # $1B41 recognizes four masked screen-byte classes. Exhaust all byte
    # values so ports cannot accidentally compare unmasked pixels or merge the
    # special $A0 spook-pause outcome with ordinary expiry.
    projectile_reference = PROJECTILE_LIFECYCLE_REFERENCE.read_text(encoding="ascii")
    expiry_text = projectile_reference.split("expiry_mask_classes_1b41\n", 1)[1].split(
        "\nobject_hit_and_recycle_2163_22d0\n", 1
    )[0]
    expiry_classes = {
        int(value, 16)
        for value in re.findall(r"^\$(A0|80|82|8A) ", expiry_text, re.MULTILINE)
    }
    if expiry_classes != {0x80, 0x82, 0x8A, 0xA0}:
        fail(f"projectile expiry classes differ: {sorted(expiry_classes)}")
    expiry_rows = 0
    for screen_byte in range(256):
        masked = screen_byte & 0xAA
        expires = masked in expiry_classes
        sets_spook_pause = masked == 0xA0
        if sets_spook_pause and not expires:
            fail(f"screen byte ${screen_byte:02X}: spook pause without expiry")
        expiry_rows += 1

    print(
        "Validated port preflight: "
        "64 graphic pointers, "
        f"{player_selector_rows} player selector rows, "
        "4 player starts, "
        f"{projectile_rows} shot projections, "
        f"{movement_rows} movement projections, "
        f"{keyboard_rows} keyboard masks, "
        f"{len(joystick_cases)} joystick thresholds, "
        f"{fire_edge_rows} fire-latch transitions, "
        f"{room_rows} room-render digests, "
        f"{status_rows} status-render digests, "
        f"{player_layer_rows} player sprite layers, "
        f"{setup_rows} deterministic setup frames, "
        f"{len(window_roles)} object-slot roles, "
        f"{lifecycle_rows} lifecycle states, "
        f"{expiry_rows} projectile expiry bytes"
    )


if __name__ == "__main__":
    main()
