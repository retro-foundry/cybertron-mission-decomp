"""Render every 24-byte Cybertron Mission Mode 1 graphic record."""

from pathlib import Path
import re

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "source_acorn_electron" / "cyber1.asm"
OUTPUT = ROOT / "analysis" / "reconstruction" / "all_graphic_records.png"
RECORD_SIZE = 24
FIRST_ADDRESS = 0x2900


def colour(value: int, packed_pixel: int) -> tuple[int, int, int]:
    low = (value >> (7 - packed_pixel)) & 1
    high = (value >> (3 - packed_pixel)) & 1
    return ((0, 0, 0), (255, 0, 0), (255, 255, 0), (255, 255, 255))[low | high << 1]


def read_records(source: str) -> list[tuple[int, str, list[int]]]:
    start = source.index(".graphic_record_00")
    end = source.index(".object_graphic_id_by_index", start)
    block = source[start:end]
    records = []
    pattern = r"(?ms)^\.graphic_record_([0-9a-f]{2})\s*$\n(.*?)(?=^\.graphic_record_|\Z)"
    for record_match in re.finditer(pattern, block):
        record_id = int(record_match.group(1), 16)
        body = record_match.group(2)
        data_lines = "\n".join(line for line in body.splitlines() if "EQUB" in line)
        values = [int(value, 16) for value in re.findall(r"&([0-9A-Fa-f]{2})", data_lines)]
        if len(values) != RECORD_SIZE:
            raise ValueError(f"graphic_record_{record_id:02x} has {len(values)} bytes")
        role_match = re.search(r"(?m)^\s*; graphic_role (.+)$", body)
        role = role_match.group(1).strip() if role_match else "identity_not_proven"
        records.append((record_id, role, values))
    if [record_id for record_id, _role, _values in records] != list(range(64)):
        raise ValueError("expected consecutive graphic records 00-3f")
    return records


def main() -> None:
    records = read_records(SOURCE.read_text(encoding="ascii"))
    columns = 4
    scale = 8
    cell_width = 300
    cell_height = 104
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_width, rows * cell_height), (224, 224, 224))
    draw = ImageDraw.Draw(sheet)

    for index, (record_id, role, record) in enumerate(records):
        column = index % columns
        row = index // columns
        ox = column * cell_width
        oy = row * cell_height
        address = FIRST_ADDRESS + record_id * RECORD_SIZE
        draw.text((ox + 8, oy + 6), f"${address:04X}  ${record_id:02X}  {role}", fill=(0, 0, 0))
        sprite_x = ox + 8
        sprite_y = oy + 28
        for y in range(8):
            for byte_column in range(3):
                value = record[y + byte_column * 8]
                for packed_pixel in range(4):
                    x = byte_column * 4 + packed_pixel
                    draw.rectangle(
                        (
                            sprite_x + x * scale,
                            sprite_y + y * scale,
                            sprite_x + (x + 1) * scale - 1,
                            sprite_y + (y + 1) * scale - 1,
                        ),
                        fill=colour(value, packed_pixel),
                    )
        draw.rectangle(
            (sprite_x - 1, sprite_y - 1, sprite_x + 12 * scale, sprite_y + 8 * scale),
            outline=(96, 96, 96),
        )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    temporary = OUTPUT.with_name(f"{OUTPUT.stem}.new{OUTPUT.suffix}")
    sheet.save(temporary)
    temporary.replace(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
