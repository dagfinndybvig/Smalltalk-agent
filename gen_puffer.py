"""Verify the puffer train pattern, then generate the SIS eval payloads.

Pattern: the classic puffer train - a B-heptomino perturbed by two LWSS
escorts, travelling at c/2 and leaving a dirty debris trail. Canonical
source: Golly's pattern collection, Patterns/Life/Puffers/puffer-train.rle
(Alan Hensel's "lifebc" collection), mirrored on GitHub (jimblandy/golly).
LifeWiki (conwaylife.com/wiki/Puffer_train) is the same pattern,
Cloudflare-walled; the lexicon's ASCII rendering lost its alignment.
"""
import json
import re
from pathlib import Path

RLE = "3bo$4bo$o3bo$b4o4$o$boo$bbo$bbo$bo3$3bo$4bo$o3bo$b4o!"


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
xs = [p[0] for p in cells]; ys = [p[1] for p in cells]
print(f"initial: {len(cells)} cells, x {min(xs)}..{max(xs)}, y {min(ys)}..{max(ys)}")
assert len(cells) == 22, "puffer train must have 22 cells"

snapshots = {}
for gen in range(1, 61):
    cells = step(cells)
    snapshots[gen] = set(cells)
    if gen % 20 == 0:
        gx = [p[0] for p in cells]
        front = max(gx)
        print(f"gen {gen:2d}: pop={len(cells):2d} front-x={front:3d} behind={len([p for p in cells if p[0] < front - 8])}")

front0 = max(p[0] for p in parse_rle(RLE))
front40 = max(p[0] for p in snapshots[40])
pop40 = len(snapshots[40])
behind40 = len([p for p in snapshots[40] if p[0] < front40 - 8])
behind60 = len([p for p in snapshots[60] if p[0] < max(p[0] for p in snapshots[60]) - 8])

assert front40 == front0 + 20, f"engine must advance 20 cells in 40 gens (c/2, +x), got {front40 - front0}"
assert pop40 > 22, f"population must grow (debris trail), got {pop40}"
assert behind60 > behind40 > 0, "debris behind the engine must accumulate"
print(f"VERIFIED: c/2 engine (+x, front {front0} -> {front40} over 40 gens), pop {pop40} and growing, trail accumulating")

# --- generate Smalltalk method sources ---
pts = parse_rle(RLE)
rows = {}
for (x, y) in sorted(pts, key=lambda p: (p[1], p[0])):
    rows.setdefault(y, []).append(x)
array_lines = []
for y in sorted(rows):
    array_lines.append("\t\t" + ". ".join(f"{x}@{y}" for x in sorted(rows[y])) + ".")
array_st = "\n".join(array_lines)

puffer_st = (
    "pufferTrain\n"
    "\t\"The classic puffer train: a B-heptomino whose sides are\n"
    "\tperturbed by two LWSS escorts. It lurches forward at c/2\n"
    "\twhile leaving a dirty debris trail behind (the tail keeps\n"
    "\tevolving for thousands of generations). Coordinates from\n"
    "\tGolly's Patterns/Life/Puffers/puffer-train.rle (Alan Hensel's\n"
    "\tlifebc collection); same pattern as conwaylife.com's Puffer\n"
    "\ttrain.\"\n"
    "\t^ self new withAll: {\n" + array_st + " }"
)

test_st = (
    "testPufferTrainTravelsAndLeavesDebris\n"
    "\t| train after |\n"
    "\ttrain := GameOfLife pufferTrain.\n"
    "\tafter := train generations: 40.\n"
    "\tself assert: after liveCells size > train liveCells size.\n"
    "\tself assert: ((after liveCells collect: #x) max - (train liveCells collect: #x) max) >= 15"
)

view_st = (
    "openPufferView\n"
    "\t\"The puffer train crawling across the screen, smoke trail behind.\"\n"
    "\t| canvas boxes extent origin train |\n"
    "\textent := 60.\n"
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
    "\ttrain := GameOfLife pufferTrain translatedBy: (origin negated + 5) @ (origin negated + (extent - 18 // 2)).\n"
    "\ttrain paintBoxes: boxes.\n"
    "\tcanvas open.\n"
    "\t[ | life |\n"
    "\t\tlife := train.\n"
    "\t\t600 timesRepeat: [\n"
    "\t\t\t(Delay forMilliseconds: 250) wait.\n"
    "\t\t\tlife := life nextGeneration.\n"
    "\t\t\tlife paintBoxes: boxes.\n"
    "\t\t\tcanvas signalUpdate ] ] fork"
)


def st_str(s):
    """Encode a method source as a Smalltalk string literal."""
    return "'" + s.replace("'", "''") + "'"


payloads = {
    "puffer-01-test.json":
        f"GameOfLifeTest compile: {st_str(test_st)}. #pufferTestCompiled",
    "puffer-02-impl.json":
        f"GameOfLife class compile: {st_str(puffer_st)}. "
        f"GameOfLife compile: {st_str(view_st)}. #pufferImplemented",
    "puffer-03-open.json":
        "GameOfLife pufferTrain openPufferView. #pufferViewOpened",
}
out = Path(__file__).resolve().parent / "demo"
for name, code in payloads.items():
    (out / name).write_text(json.dumps({"code": code}), encoding="utf-8")
    print(f"wrote demo/{name}")
