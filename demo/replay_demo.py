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
    ("05b-generations.json", "Compile generations: and its test (blinker period 2)"),
    ("05c-visualization.json", "Compile the Roassal views: drawOn:/openView/openEvolutionView/paintBoxes:"),
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

    print("\n== Add the Gosper glider gun, test-first")
    print(f"   POST /eval/  <- demo/gosper-01-test.json")
    r = post_eval(args.port, "gosper-01-test.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run gun test BEFORE implementation (expect RED)")
    red2 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(red2, ensure_ascii=False)}")
    print(f"\n   POST /eval/  <- demo/gosper-02-impl.json")
    r = post_eval(args.port, "gosper-02-impl.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run all tests with the gun (expect GREEN, 7 ran)")
    green2 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(green2, ensure_ascii=False)}")

    print("\n== Add the puffer train, test-first")
    print(f"   POST /eval/  <- demo/puffer-01-test.json")
    r = post_eval(args.port, "puffer-01-test.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run puffer test BEFORE implementation (expect RED)")
    red3 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(red3, ensure_ascii=False)}")
    print("\n   POST /eval/  <- demo/puffer-02-impl.json")
    r = post_eval(args.port, "puffer-02-impl.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run all tests with the puffer (expect GREEN, 8 ran)")
    green3 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(green3, ensure_ascii=False)}")

    print("\n== Add the diamond still life, test-first")
    print(f"   POST /eval/  <- demo/diamond-01-test.json")
    r = post_eval(args.port, "diamond-01-test.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run diamond test BEFORE implementation (expect RED)")
    red4 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(red4, ensure_ascii=False)}")
    print("\n   POST /eval/  <- demo/diamond-02-impl.json")
    r = post_eval(args.port, "diamond-02-impl.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run all tests with the diamond (expect GREEN, 9 ran)")
    green4 = run_class_test(args.port, "GameOfLifeTest")
    print(f"   GET /run-class-test?class_name=GameOfLifeTest")
    print(f"   -> {json.dumps(green4, ensure_ascii=False)}")

    print("\n== Add the fractal gallery: carpet, dragon, twindragon")
    print(f"   POST /eval/  <- demo/fractal-01-classes.json")
    r = post_eval(args.port, "fractal-01-classes.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Compile the fractal test suites")
    print(f"   POST /eval/  <- demo/fractal-02-tests.json")
    r = post_eval(args.port, "fractal-02-tests.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run the package suite BEFORE implementations (expect RED: GameOfLife green, fractals RED)")
    red5 = get(args.port, "run-package-test?package_name=GameOfLife-Tests")
    print(f"   GET /run-package-test?package_name=GameOfLife-Tests")
    print(f"   -> {json.dumps(red5, ensure_ascii=False)}")
    red5b = get(args.port, "run-package-test?package_name=Fractals-Tests")
    print(f"   GET /run-package-test?package_name=Fractals-Tests")
    print(f"   -> {json.dumps(red5b, ensure_ascii=False)}")
    print("\n   POST /eval/  <- demo/fractal-03-impl.json")
    r = post_eval(args.port, "fractal-03-impl.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")
    print("\n== Run the full package suite (expect GREEN: 9 + 13 ran)")
    green5 = get(args.port, "run-package-test?package_name=GameOfLife-Tests")
    print(f"   GET /run-package-test?package_name=GameOfLife-Tests")
    print(f"   -> {json.dumps(green5, ensure_ascii=False)}")
    green5b = get(args.port, "run-package-test?package_name=Fractals-Tests")
    print(f"   GET /run-package-test?package_name=Fractals-Tests")
    print(f"   -> {json.dumps(green5b, ensure_ascii=False)}")

    print("\n== Build the inside-out agent (AgentSession) - inert without MISTRAL_API_KEY")
    for payload_file in (
        "agent-00-create.json",
        "agent-01-core.json",
        "agent-02-api.json",
        "agent-03-loop.json",
        "agent-04-tools.json",
    ):
        print(f"   POST /eval/  <- demo/{payload_file}")
        r = post_eval(args.port, payload_file)
        print(f"   -> {json.dumps(r, ensure_ascii=False)}")

    print("\n== Harden: defuse the stale-SSL-finalizer crash (ZdcPluginSSLSession>>finalize)")
    print("   POST /eval/  <- demo/hardening-01-ssl.json")
    r = post_eval(args.port, "hardening-01-ssl.json")
    print(f"   -> {json.dumps(r, ensure_ascii=False)}")

    if not args.no_export:
        print("\n== Export durable sources (Tonel) into src/")
        for package in ("GameOfLife", "GameOfLife-Tests", "Fractals", "Fractals-Tests", "AgentTerminal"):
            path = SRC.as_posix()
            r = get(args.port, f"export-package?package_name={package}&path={path}")
            print(f"   GET /export-package?package_name={package}&path=src/")
            print(f"   -> {json.dumps(r, ensure_ascii=False)}")

        print("\n== Save the image (work survives VM restarts)")
        print(f"   POST /eval/  <- demo/06-save-image.json")
        r = post_eval(args.port, "06-save-image.json")
        print(f"   -> {json.dumps(r, ensure_ascii=False)}")

    print("\nDone. Live classes: GameOfLife, GameOfLifeTest, SierpinskiCarpet, DragonCurve, TwinDragon (+ Gosper gun, + puffer train, + fractal gallery, + AgentSession in-image agent). Sources in src/.")


if __name__ == "__main__":
    main()
