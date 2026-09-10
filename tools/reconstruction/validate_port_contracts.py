"""Validate reusable Cybertron port preflight contracts against built CYBRUN."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNTIME = ROOT / "build" / "reconstruction" / "CYBRUN"
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

    print(
        "Validated port preflight: "
        "64 graphic pointers, "
        f"{player_selector_rows} player selector rows, "
        "4 player starts, "
        f"{projectile_rows} shot projections, "
        f"{movement_rows} movement projections"
    )


if __name__ == "__main__":
    main()
