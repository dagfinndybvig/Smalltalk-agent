"""Compose the diamond + fractal replay payloads from the committed Tonel
sources in src/, so a fresh install + replay reproduces the repo exactly.

Writes demo/diamond-01-test.json, demo/diamond-02-impl.json,
demo/fractal-01-classes.json, demo/fractal-02-tests.json,
demo/fractal-03-impl.json.
"""
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "src"

FRACTAL_CLASSES = [
    "SierpinskiCarpet", "SierpinskiCarpetTest",
    "DragonCurve", "DragonCurveTest",
    "TwinDragon", "TwinDragonTest",
]


def parse_tonel(path):
    """Return (class_def, methods) where methods are dicts
    {side: 'class'|'instance', selector, source}."""
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    # class definition block
    m = re.search(r"Class \{(.*?)\n\}", text, re.S)
    if not m:
        raise ValueError(f"no class definition in {path}")
    block = m.group(1)
    def get(key):
        mm = re.search(rf"#{key} : '?([^',\n]+)'?", block)
        return mm.group(1).strip() if mm else None
    slots = re.search(r"#instVars : \[(.*?)\]", block, re.S)
    slot_names = re.findall(r"'(\w+)'", slots.group(1)) if slots else []
    class_def = {
        "name": get("name"),
        "superclass": get("superclass"),
        "slots": slot_names,
        "package": get("package"),
    }
    # methods: pattern { #category ... }\n<Name> [class] >> selector [ ... ]
    methods = []
    for mm in re.finditer(
            r"\{ #category : '([^']*)' \}\n(\w+)( class)? >> ([^\n]+) \[\n(.*?)\n\]\n",
            text, re.S):
        category, cls_name, is_class, selector, body = mm.groups()
        source = f"{selector}\n{body}"
        methods.append({
            "class": cls_name,
            "side": "class" if is_class else "instance",
            "selector": selector,
            "source": source,
            "category": category,
        })
    return class_def, methods


def st_str(s):
    """Encode method source as a Smalltalk string literal."""
    return "'" + s.replace("'", "''") + "'"


all_methods = []
classes_payload_lines = []

for name in FRACTAL_CLASSES:
    for pkg in ("GameOfLife", "GameOfLife-Tests"):
        p = SRC / pkg / f"{name}.class.st"
        if not p.exists():
            continue
        cdef, methods = parse_tonel(p)
        slots = "{" + "".join(f" #{s}." for s in cdef["slots"]) + " }"
        classes_payload_lines.append(
            f"{cdef['superclass']} << #{cdef['name']}\n"
            f"\tslots: {slots};\n"
            f"\tpackage: '{cdef['package']}';\n"
            f"\tinstall."
        )
        all_methods.extend(methods)
        break

# diamond + testDiamond from the GameOfLife files
_, gol_methods = parse_tonel(SRC / "GameOfLife" / "GameOfLife.class.st")
diamond = next(m for m in gol_methods if m["side"] == "class" and m["selector"] == "diamond")
_, golt_methods = parse_tonel(SRC / "GameOfLife-Tests" / "GameOfLifeTest.class.st")
test_diamond = next(m for m in golt_methods if m["selector"] == "testDiamond")

# split fractal methods: tests vs implementation
fractal_tests = [m for m in all_methods if m["class"].endswith("Test")]
fractal_impl = [m for m in all_methods if not m["class"].endswith("Test")]


def compile_chain(methods):
    parts = []
    for m in methods:
        recv = f"{m['class']} class" if m["side"] == "class" else m["class"]
        parts.append(
            f"{recv} compile: {st_str(m['source'])} classified: {st_str(m['category'])}."
        )
    return "\n".join(parts) + "\n"


def write_payload(name, code):
    (HERE / "demo" / name).write_text(json.dumps({"code": code}), encoding="utf-8")
    print(f"wrote demo/{name}")


write_payload("diamond-01-test.json",
              f"GameOfLifeTest compile: {st_str(test_diamond['source'])} "
              f"classified: {st_str(test_diamond['category'])}. #diamondTestCompiled")
write_payload("diamond-02-impl.json",
              f"GameOfLife class compile: {st_str(diamond['source'])} "
              f"classified: {st_str(diamond['category'])}. #diamondImplemented")

classes_code = "\n".join(classes_payload_lines) + "\n#fractalClassesCreated"
write_payload("fractal-01-classes.json", classes_code)

tests_code = compile_chain(fractal_tests) + "#fractalTestsCompiled"
write_payload("fractal-02-tests.json", tests_code)

impl_code = compile_chain(fractal_impl) + "#fractalImplemented"
write_payload("fractal-03-impl.json", impl_code)

print(f"fractal tests compiled by payload: {len(fractal_tests)}")
print(f"fractal impl methods compiled by payload: {len(fractal_impl)}")
for m in all_methods:
    print(f"  {m['class']} {m['side']:8} {m['selector']}")
