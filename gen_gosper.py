"""Verify the Gosper glider gun RLE, then generate the SIS eval payloads."""
import json
import re
from pathlib import Path

RLE = """24bo11b$22bobo11b$12b2o6b2o12b2o$11bo3bo4b2o12b2o$2o8bo5bo3b2o14b$2o8bo
3bob2o4bobo11b$10bo5bo7bo11b$11bo3bo20b$12b2o!"""

def parse_rle(rle):
    cells = set()
    i, x, y = 0, 0, 0
    while i < len(rle):
        m = re.match(r"(\d+)", rle[i:])
        n = int(m.group(1)) if m else 1
        i += len(m.group(1)) if m else 0
        c = rle[i]
        i += 1
        if c == "b":
            x += n
        elif c == "o":
            for _ in range(n):
                cells.add((x, y)); x += 1
        elif c == "$":
            x, y = 0, y + n
        elif c == "!":
            break
    return cells

def step(cells):
    counts = {}
    for (x, y) in cells:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx or dy:
                    counts[(x+dx, y+dy)] = counts.get((x+dx, y+dy), 0) + 1
    return {p for p, n in counts.items()
            if n == 3 or (n == 2 and p in cells)}

cells = parse_rle(RLE)
print(f"initial: {len(cells)} cells (expect 36)")
assert len(cells) == 36, "gun must have 36 cells"

for gen in range(1, 61):
    cells = step(cells)
    if gen % 15 == 0:
        gun_zone = [p for p in cells if p[0] <= 36]
        far = [p for p in cells if p[0] > 40]
        print(f"gen {gen:2d}: pop={len(cells):2d} gun-zone={len(gun_zone):2d} far-glider-cells={len(far)}")

assert len(cells) == 46, f"gen 60 should hold gun(36) + 2 gliders(10), got {len(cells)}"
assert all(p[0] <= 36 for p in [p for p in cells if p[1] <= 12]) , "gun zone check"
print("VERIFIED: period-30 gun, 2 detached gliders at gen 60")

# --- generate Smalltalk method sources ---
pts = parse_rle(RLE)
rows = {}
for (x, y) in sorted(pts, key=lambda p: (p[1], p[0])):
    rows.setdefault(y, []).append(x)
array_lines = []
for y in sorted(rows):
    array_lines.append("\t\t" + ". ".join(f"{x}@{y}" for x in sorted(rows[y])) + ".")
array_st = "\n".join(array_lines)

gosper_st = (
    "gosperGun\n"
    "\t\"Bill Gosper, 1970: the first known glider gun. True period 30:\n"
    "\tfires one glider every 30 generations, forever. Coordinates from\n"
    "\tthe canonical RLE (conwaylife.com/wiki/Gosper_glider_gun).\"\n"
    "\t^ self new withAll: {\n" + array_st + " }"
)
translated_st = (
    "translatedBy: aPoint\n"
    "\t^ self class new withAll: (liveCells collect: [ :p | p + aPoint ])"
)
test_st = (
    "testGosperGunFiresGliders\n"
    "\t| gun after |\n"
    "\tgun := GameOfLife gosperGun.\n"
    "\tafter := gun generations: 60.\n"
    "\tself assert: after liveCells size > (gun liveCells size + 5)"
)
view_st = (
    "openGunView\n"
    "\t| canvas boxes extent origin gun |\n"
    "\textent := 50.\n"
    "\torigin := extent // 2.\n"
    "\tcanvas := RSCanvas new.\n"
    "\tcanvas color: Color veryLightGray.\n"
    "\tboxes := Dictionary new.\n"
    "\torigin negated to: (extent - origin) do: [ :gx |\n"
    "\t\torigin negated to: (extent - origin) do: [ :gy |\n"
    "\t\t\t| box |\n"
    "\t\t\tbox := RSBox new\n"
    "\t\t\t\tsize: 16;\n"
    "\t\t\t\tcolor: Color white.\n"
    "\t\t\tbox position: (gx * 20) @ (gy negated * 20).\n"
    "\t\t\tcanvas add: box.\n"
    "\t\t\tboxes at: gx @ gy put: box ] ].\n"
    "\tgun := GameOfLife gosperGun translatedBy: "
    "(origin negated + (extent - 36 // 2)) @ (origin negated + (extent - 9 // 2)).\n"
    "\tgun paintBoxes: boxes.\n"
    "\tcanvas open.\n"
    "\t[ | life |\n"
    "\t\tlife := gun.\n"
    "\t\t500 timesRepeat: [\n"
    "\t\t\t(Delay forMilliseconds: 250) wait.\n"
    "\t\t\tlife := life nextGeneration.\n"
    "\t\t\tlife paintBoxes: boxes.\n"
    "\t\t\tcanvas signalUpdate ] ] fork"
)

def st_str(s):
    """Encode a method source as a Smalltalk string literal."""
    return "'" + s.replace("'", "''") + "'"

payloads = {
    "gosper-01-test.json":
        f"GameOfLifeTest compile: {st_str(test_st)}. #gunTestCompiled",
    "gosper-02-impl.json":
        f"GameOfLife class compile: {st_str(gosper_st)}. "
        f"GameOfLife compile: {st_str(translated_st)}. "
        f"GameOfLife compile: {st_str(view_st)}. #gunImplemented",
    "gosper-03-open.json":
        "GameOfLife gosperGun openGunView. #gunViewOpened",
}
out = Path(__file__).resolve().parent / "demo"
for name, code in payloads.items():
    (out / name).write_text(json.dumps({"code": code}), encoding="utf-8")
    print(f"wrote demo/{name}")
