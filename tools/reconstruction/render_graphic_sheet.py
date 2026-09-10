"""Render composed Cybertron Mode 2 sprites and standalone graphics."""

from pathlib import Path
import re

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "source_acorn_electron" / "cyber1.asm"
OUTPUT = ROOT / "analysis" / "reconstruction" / "composed_sprite_sheet.png"
RECORD_SIZE = 24

LOGICAL_REVIEW_COLOURS = (
    (0, 0, 0),
    (255, 0, 0),
    (0, 255, 0),
    (255, 255, 0),
    (0, 0, 255),
    (255, 0, 255),
    (0, 255, 255),
    (255, 255, 255),
    (96, 96, 96),
    (255, 128, 0),
    (128, 255, 0),
    (255, 192, 0),
    (64, 128, 255),
    (255, 96, 192),
    (64, 192, 192),
    (192, 192, 192),
)


def logical_colour_index(value: int, packed_pixel: int) -> int:
    """Decode one of the two four-bit BBC Mode 2 pixels in a byte."""
    shift = 1 - packed_pixel
    return (
        ((value >> (6 + shift)) & 1)
        | (((value >> (4 + shift)) & 1) << 1)
        | (((value >> (2 + shift)) & 1) << 2)
        | (((value >> shift) & 1) << 3)
    )


def colour(value: int, packed_pixel: int) -> tuple[int, int, int]:
    logical = logical_colour_index(value, packed_pixel)
    # Use a stable diagnostic colour for each logical index. The runtime
    # repeatedly remaps indices 8-15, so flattening one live palette phase can
    # make valid records disappear into black on a static sheet.
    return LOGICAL_REVIEW_COLOURS[logical]


def read_records(source: str) -> list[tuple[int, str, list[int]]]:
    start = source.index(".player_down_upper_graphic")
    end = source.index(".object_graphic_id_by_index", start)
    block = source[start:end]
    records = []
    pattern = (
        r"(?ms)^\.([a-z][a-z0-9_]*)\s*$\n"
        r"(?=\s*; graphic_id \$[0-9A-F]{2}\s*$\n"
        r"\s*; 24-byte renderer graphic record)(.*?)"
        r"(?=^\.[a-z][a-z0-9_]*\s*$|\Z)"
    )
    for record_match in re.finditer(pattern, block):
        record_id = len(records)
        source_label = record_match.group(1)
        body = record_match.group(2)
        data_lines = "\n".join(line for line in body.splitlines() if "EQUB" in line)
        values = [int(value, 16) for value in re.findall(r"&([0-9A-Fa-f]{2})", data_lines)]
        if len(values) != RECORD_SIZE:
            raise ValueError(f"{source_label} (graphic ${record_id:02X}) has {len(values)} bytes")
        role_match = re.search(r"(?m)^\s*; graphic_role (.+)$", body)
        role = role_match.group(1).strip() if role_match else "identity_not_proven"
        records.append((record_id, role, values))
    if len(records) != 64:
        raise ValueError(f"expected 64 consecutive graphic records, found {len(records)}")
    return records


def decode_record(record: list[int]) -> list[list[tuple[int, int, int]]]:
    pixels = []
    for y in range(8):
        row = []
        for byte_column in range(3):
            value = record[y + byte_column * 8]
            row.extend(colour(value, packed_pixel) for packed_pixel in range(2))
        pixels.append(row)
    return pixels


def main() -> None:
    records = read_records(SOURCE.read_text(encoding="ascii"))
    direction_names = (
        "down", "up", "right", "left",
        "up_right", "down_right", "up_left", "down_left",
    )
    images = []
    for direction, direction_name in enumerate(direction_names):
        base = direction * 4
        upper = decode_record(records[base][2])
        for lower_offset in (1, 2, 3):
            lower = decode_record(records[base + lower_offset][2])
            images.append((f"player_{direction_name}_frame_{lower_offset}", upper + lower))

    # The spook uses adjacent object slots with a two-unit Y difference, the
    # same eight-pixel vertical composition used by the player pair.
    images.append(("spook", decode_record(records[0x2E][2]) + decode_record(records[0x2F][2])))

    # Records $20-$3F are independently drawn glyphs, enemies, hit frames, or
    # targets. The spook halves are excluded because their meaningful view is
    # the composition above.
    for record_id in range(0x20, 0x40):
        if record_id in (0x2E, 0x2F):
            continue
        role = records[record_id][1]
        images.append((f"${record_id:02X}  {role}", decode_record(records[record_id][2])))

    columns = 4
    x_scale = 16
    y_scale = 8
    cell_width = 300
    cell_height = 172
    rows = (len(images) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_width, rows * cell_height), (224, 224, 224))
    draw = ImageDraw.Draw(sheet)

    for index, (label, pixels) in enumerate(images):
        column = index % columns
        row = index // columns
        ox = column * cell_width
        oy = row * cell_height
        draw.text((ox + 8, oy + 6), label, fill=(0, 0, 0))
        sprite_x = ox + 8
        sprite_y = oy + 28
        for y, pixel_row in enumerate(pixels):
            for x, pixel_colour in enumerate(pixel_row):
                draw.rectangle(
                    (
                        sprite_x + x * x_scale,
                        sprite_y + y * y_scale,
                        sprite_x + (x + 1) * x_scale - 1,
                        sprite_y + (y + 1) * y_scale - 1,
                    ),
                    fill=pixel_colour,
                )
        draw.rectangle(
            (sprite_x - 1, sprite_y - 1, sprite_x + 6 * x_scale, sprite_y + len(pixels) * y_scale),
            outline=(96, 96, 96),
        )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_name(f"{OUTPUT.stem}.new{OUTPUT.suffix}")
    sheet.save(temporary)
    temporary.replace(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
