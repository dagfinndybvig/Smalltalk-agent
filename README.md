<img width="986" height="875" alt="image" src="https://github.com/user-attachments/assets/a0fe3dbc-2a05-407a-9675-74626ad1acb1" />

# Reverse Smalltalk — Agentic Control PoC

A proof of concept for putting Smalltalk under agentic control: a live Pharo 13
image, running headless, that a coding agent can inspect, modify, and execute
directly — the original Smalltalk vision of an integrated live environment,
with an LLM agent in the loop instead of (or alongside) a human at the browser.

## Architecture

```
Agent (Vibe / Claude / any MCP client)
   │  MCP stdio, 22 tools
   ▼
smalltalk-interop-mcp-server (Python, via uvx)
   │  HTTP (localhost:8086)
   ▼
SIS — PharoSmalltalkInteropServer (in-image, Teapot + NeoJSON)
   │
   ▼
Live Pharo 13 image (headless)
```

And the other direction, entirely inside the image:

```
AgentSession (a Smalltalk object in the image) --Zinc--> Mistral API
   ^-- tool calls executed as native messages --v
Live Pharo object memory
```

The agent's unit of change is the *method*, not the file: it evaluates
Smalltalk code, reads and writes class/method sources, searches
implementors/references, imports/exports Tonel packages, and runs test
suites — all against the running image.

## What's here

| Path | Purpose |
|---|---|
| `Pharo.image` / `Pharo.changes` | The live image (SIS loaded, auto-starts on boot) |
| `pharo`, `pharo-ui`, `pharo-vm/` | Pharo 13 launcher scripts and VM |
| `keepalive.st` | Startup script that keeps the headless image alive |
| `start-pharo-server.cmd` | Double-click launcher for the headless server |
| `start-pharo-desktop.cmd` | Double-click launcher for the Pharo desktop (GUI) |
| `restart-server.cmd` | Health check + restart: starts the headless server if it is down, never a second VM |
| `snapshot.cmd` / `restore.cmd` | Whole-world undo: copy/restore the image files |
| `demo/` | The agent's actual eval payloads + one-command replay script |
| `gen_gosper.py` | RLE verifier + eval-payload generator for the Gosper gun |
| `gen_agent.py` | Generator for the AgentSession build payloads (`demo/agent-*.json`) |
| `src/` | Durable source of truth: Tonel export of live packages |
| `AGENTS.md` | Operating rules for AI agents working in this directory |
| `MANUAL.md` | Plain user's guide: setup, desktop tour, troubleshooting |
| `TODO.md` | Roadmap / next steps |

## Starting the server

Double-click `start-pharo-server.cmd`, or from Git Bash:

```
./pharo --headless Pharo.image st keepalive.st
```

SIS auto-starts on image boot and listens on **port 8086**
(`PHARO_SIS_PORT` to change). Stop with Ctrl+C.

Persistence caveat: the image on disk only changes when it is *saved*
(`Smalltalk snapshot: true andQuit: false`). Code compiled into a running
image is lost if the VM dies unsaved — which is why the demo exports
Tonel sources to `src/` and saves the image at the end.

## The Pharo desktop

`start-pharo-desktop.cmd` opens the same image with the full Pharo GUI —
browser, playground, inspector, the original live environment. SIS still
serves on 8086, so an agent session and a human share the same live
world: the agent can compile methods (they appear in the browser),
evaluate code, open windows on your screen, and verify its own UI work
via `/read-screen`.

One hard rule: **never run two VMs on the same image files** — stop the
headless server (close its console or `taskkill /IM PharoConsole.exe`)
before opening the desktop, and vice versa.

Verify it is up:

```
curl -X POST http://localhost:8086/eval/ \
  -H "Content-Type: application/json" \
  -d '{"code":"3+4"}'
```

## Connecting an agent

Register the MCP server with your client. Vibe / Claude Code / Cursor
`mcp.json` entry:

```json
{
  "mcpServers": {
    "smalltalk-interop": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/mumez/smalltalk-interop-mcp-server.git",
        "smalltalk-interop-mcp-server"
      ],
      "env": { "SIS_PORT": "8086" }
    }
  }
}
```

Exposed tools: `eval`, `get_class_source`, `get_method_source`,
`get_class_comment`, `search_classes_like`, `search_methods_like`,
`search_implementors`, `search_references`, `list_packages`, `list_classes`,
`export_package`, `import_package` (Tonel), `run_package_test`,
`run_class_test`, `install_project`, `read_screen`, `get_settings`,
`apply_settings`, and more.

## The MVP: an agent develops Conway's Game of Life, live

A coding agent built a package with a test suite — no files, no build
system, no IDE. Every change was compiled into the running image through
the SIS API, test-first. The exact payloads it sent are in `demo/`, and the
whole sequence replays with one command:

```
python demo/replay_demo.py
```

What happens (actual output, abridged):

```
== Create GameOfLife class (empty shell, no behaviour yet)
   -> {"result": "created", "success": true}
== Compile storage: initialize/withAll:/liveCells/isAliveAt:
   -> {"result": "storageCompiled", "success": true}
== Create GameOfLifeTest (TestCase subclass)
   -> {"result": "testClassCreated", "success": true}
== Compile 5 tests describing the rules of the game
   -> {"result": "testsCompiled", "success": true}
== Run tests BEFORE implementation (expect RED)
   -> "5 ran, 0 passed, 0 failures, 5 errors"
== Compile the evolution rules: neighbours + nextGeneration
   -> {"result": "evolutionCompiled", "success": true}
== Run tests AFTER implementation (expect GREEN)
   -> "5 ran, 5 passed, 0 failures, 0 errors"
== Export durable sources (Tonel) into src/
   -> GameOfLife exported, GameOfLife-Tests exported
```

The red run fails because `nextGeneration` does not exist yet — the tests
describe the rules of the game before any implementation exists. Then the
agent compiles the evolution rules into the live classes, re-runs, and the
suite goes green. Full transcript: `demo/replay-output.txt`. Durable
sources land in `src/` as plain Tonel files, reviewable in git.

The package also has a graphical view, added live by an agent while the
desktop was open: `(GameOfLife new withAll: { 1@1. 2@2. 0@3. 1@3. 2@3 })
openEvolutionView` opens an animated Roassal grid — watch a glider crawl
while SIS's screen-structure endpoint (`/read-screen`) lets the agent
verify what it drew. Human and agent share the same live world.

The showpiece is Bill Gosper's 1970 glider gun — the first known pattern
with unbounded growth, firing a glider every 30 generations, forever:

```smalltalk
GameOfLife gosperGun openGunView
```

It was added the disciplined way: the canonical RLE was fetched from a
GitHub mirror (LifeWiki is Cloudflare-walled), verified by local
simulation *before* touching the image (36 cells, one extra glider per
30-generation cycle), then driven test-first into the live system —
red, implement, green (7/7). The replay demo builds it too, so a fresh install gets the complete package. `gen_gosper.py` holds the verifier and
payload generator; `demo/gosper-*.json` are the exact evals used.

Its companion is the classic puffer train - a B-heptomino kept alive by
two LWSS escorts, lurching across the grid at c/2 while laying a dirty
debris trail (`GameOfLife pufferTrain openPufferView`). Same
discipline: the canonical RLE (Golly's pattern collection, from Alan
Hensel's lifebc) was verified by local simulation before touching the
image - the population must grow and the engine must advance exactly
c/2 - then driven test-first into the live system (red, implement,
green, 8/8). `gen_puffer.py` holds the verifier and payload generator;
`demo/puffer-*.json` are the exact evals used; the replay demo builds
it into fresh images too.

The image also carries a small fractal gallery — generator programs,
not data: `SierpinskiCarpet level: n` (ternary-digit exclusion rule,
8^n cells), `DragonCurve order: n` (the Heighway dragon by
deterministic doubling), and `TwinDragon order: n` (two dragons tail
to tail — the plane-tiling Davis-Knuth twindragon). Each was built
test-first and cross-verified against a Python reference point for
point, and each opens a full-screen view: `openCarpetView`,
`openDragonView`, `openTwinDragonView`.

## Whole-world undo

The live image is single mutable state. Before risky work, snapshot it:

```
snapshot.cmd          → snapshots\Pharo-<timestamp>.image/.changes
restore.cmd snapshots\Pharo-20261017-140137   (stop the image first)
```

This rolls back *everything* — all classes, methods, running processes,
objects — in one file copy. No other development environment gives an
agent that.

## Rebuilding the environment from scratch

The live image files are intentionally not in git (single-writer, ~50 MB,
unmergeable). Everything needed to reconstruct the environment is:

```bash
# 1. Pharo 13 image + VM (zeroconf installer)
curl -sS -L https://get.pharo.org/64/stable+vm | sh

# 2. Load SIS into the image (auto-starts on 8086 now and on every boot)
./pharo Pharo.image metacello install \
  github://mumez/PharoSmalltalkInteropServer:main/src \
  BaselineOfPharoSmalltalkInteropServer

# 3. Start the headless server
./pharo --headless Pharo.image st keepalive.st
```

The MCP server needs no install at all — it is fetched on demand by
`uvx` (requires Python 3.10+ and [uv](https://docs.astral.sh/uv/)).

To restore previously developed code into a fresh image, import the
Tonel sources from `src/` (`path` is the *parent* directory; the package
is selected by `package_name` — the upstream API.md example is
misleading about this):

```
GET /import-package?package_name=GameOfLife&path=<repo>/src
```

(or re-run `demo/replay_demo.py`, which rebuilds everything live).

## The other direction: an agent inside the image

AgentSession (in `src/AgentTerminal`) is a coding agent that lives *in*
the image: it calls the Mistral API over Zinc and executes the model's
tool calls as native Smalltalk messages - no MCP, no serialization
boundary, no separate process. Tools: `eval`, `run_tests`,
`get_method_source`. The API key is read at call time from the
`MISTRAL_API_KEY` environment variable and never stored in the image.

```smalltalk
AgentSession new ask: 'Add a class-side blinker method to GameOfLife, test-first.'
```

In a validated session the in-image agent: compiled the failing test,
saw the suite go red (8 ran, 1 error), read the failure's stack trace,
implemented the method, and reported green - a development loop running
entirely inside the live object memory. Build payloads are in
`demo/agent-*.json` (generated by `gen_agent.py`); the replay demo builds it into fresh images too. Note: the image
process must have `MISTRAL_API_KEY` in its environment - start it from
a shell that carries the key, not a double-clicked launcher.

## Why this matters

Smalltalk is uniquely suited to agentic control because the tools *are* the
environment — the browser, debugger, and inspector are ordinary objects.
An agent doesn't simulate an IDE; it sends the same messages the IDE would.
Unique capabilities worth exploiting:

- **Whole-world undo** — copy `Pharo.image`/`Pharo.changes` to snapshot all
  live state; restore to roll back everything, atomically.
- **Agent-shaped errors** — failures return structured JSON with the full
  stack trace, receiver, and instance variables.
- **Live introspection** — the agent can query the running system, not just
  source text.

## Credits

The bridge stack is existing work, not ours:

- [mumez/PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer) — in-image HTTP API
- [mumez/smalltalk-interop-mcp-server](https://github.com/mumez/smalltalk-interop-mcp-server) — MCP wrapper (also supports Squeak)
- [mumez/pharo-agentic-browser](https://github.com/mumez/pharo-agentic-browser) — full multi-agent workspace UI (not installed here)
- [mumez/smalltalk-dev-plugin](https://github.com/mumez/smalltalk-dev-plugin) — agent skills for Smalltalk dev

This repo is the proof of concept and staging ground for our own deeper
integration work (see TODO.md).

## License

MIT — see [LICENSE](LICENSE). The bridge components above are separate
projects with their own licenses; this repository contains only our own
code, docs, and demo payloads.
