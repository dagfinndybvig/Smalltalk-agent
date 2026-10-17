#!/usr/bin/env python3
"""Replay the agent demo: develop Conway's Game of Life test-first,
entirely inside a running headless Pharo image, via the SIS HTTP API.

Usage: python demo/replay_demo.py [--port 8086] [--no-export]

Requires the image server to be running (see start-pharo-server.cmd).
Safe to run repeatedly; every step is idempotent.
"""

import argparse
import json
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent
SRC = PROJECT / "src"

EVALS = [
    ("01-create-gol.json", "Create GameOfLife class (empty shell, no behaviour yet)"),
    ("02-compile-storage.json", "Compile storage: initialize/withAll:/liveCells/isAliveAt:"),
    ("03-create-test-class.json", "Create GameOfLifeTest (TestCase subclass)"),
    ("04-compile-tests.json", "Compile 5 tests describing the rules of the game"),
    ("05-compile-evolution.json", "Compile the evolution rules: neighbours + nextGeneration"),
]
# 04 is a deliberate RED step (nextGeneration does not exist yet);
# 05 makes it GREEN. Tests run between them and after.


def post_eval(port, payload_file):
    body = (HERE / payload_file).read_bytes()
    req = urllib.request.Request(
        f"http://localhost:{port}/eval/",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read())


def get(port, path):
    with urllib.request.urlopen(f"http://localhost:{port}/{path}", timeout=600) as resp:
        return json.loads(resp.read())


def run_class_test(port, class_name):
    return get(port, f"run-class-test?class_name={class_name}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8086)
    ap.add_argument("--no-export", action="store_true")
    args = ap.parse_args()

    print("Checking image server...", end=" ", flush=True)
    try:
        pong = post_eval(args.port, "01-create-gol.json")
    except OSError as e:
        sys.exit(f"not reachable: {e}\nStart it first: start-pharo-server.cmd")
    print("up")

    for payload_file, description in EVALS:
        print(f"\n== {description}")
        print(f"   POST /eval/  <- demo/{payload_file}")
        if payload_file == "01-create-gol.json":
            result = pong  # already sent as the health check
        else:
            result = post_eval(args.port, payload_file)
        print(f"   -> {json.dumps(result, ensure_ascii=False)}")

        if payload_file == "04-compile-tests.json":
            print("\n== Run tests BEFORE implementation (expect RED)")
            red = run_class_test(args.port, "GameOfLifeTest")
            print(f"   GET /run-class-test?class_name=GameOfLifeTest")
            print(f"   -> {json.dumps(red, ensure_ascii=False)}")

    print("\n== Run tests AFTER implementation (expect GREEN)")
    green = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(green, ensure_ascii=False)}")

    if not args.no_export:
        print("\n== Export durable sources (Tonel) into src/")
        for package in ("GameOfLife", "GameOfLife-Tests"):
            path = SRC.as_posix()
            r = get(args.port, f"export-package?package_name={package}&path={path}")
            print(f"   GET /export-package?package_name={package}&path=src/")
            print(f"   -> {json.dumps(r, ensure_ascii=False)}")

        print("\n== Save the image (work survives VM restarts)")
        print(f"   POST /eval/  <- demo/06-save-image.json")
        r = post_eval(args.port, "06-save-image.json")
        print(f"   -> {json.dumps(r, ensure_ascii=False)}")

    print("\nDone. Live classes: GameOfLife, GameOfLifeTest. Sources in src/.")


if __name__ == "__main__":
    main()
