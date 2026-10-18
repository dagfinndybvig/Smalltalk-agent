# AGENTS.md — Reverse Smalltalk (Agentic PoC)

This directory contains a live Pharo 13 image under agentic control. Read this
before doing anything here.

## Environment model

- `Pharo.image` + `Pharo.changes` are **live state**, not artifacts. They hold
  running processes, the loaded SIS server, and any classes created at runtime.
- **The image on disk is only updated on save.** Classes compiled into a
  running image exist in memory; if the VM dies without saving, they are gone
  (the `.changes` file keeps source text, but nothing reloads it
  automatically). After meaningful live changes, do both:
  1. Export affected packages as Tonel to `src/` (durable, git-committable), and
  2. Save the image: eval `Smalltalk snapshot: true andQuit: false`
     (`Smalltalk saveImage` does NOT exist in Pharo 13).
- If classes are missing after a fresh boot (unsaved work was lost), restore
  from the Tonel sources: `GET /import-package?package_name=X&path=src`
  — or re-run `demo/replay_demo.py`, which rebuilds and saves.
- The image normally runs headless as a long-lived process, with
  `PharoSmalltalkInteropServer` (SIS) on **http://localhost:8086**.
- Source of truth for anything durable should be Tonel export (via SIS) or a
  fileout — do not assume the image contents are reproducible.

## Server lifecycle

Check whether the image is running before anything else:

```
curl -sS -X POST http://localhost:8086/eval/ -H "Content-Type: application/json" -d '{"code":"Smalltalk version"}'
```

- **If running:** use it. Do not start a second instance (the image files are
  single-writer; a second VM on the same image corrupts state).
- **If not running:** start it as a **background process** —
  `./pharo --headless Pharo.image st keepalive.st` from this directory
  (this is what `start-pharo-server.cmd` runs, but the .cmd is a blocking
  launcher meant for double-click use; an agent calling it in the
  foreground will time out and the kill takes the VM down with it).
  `restart-server.cmd` wraps this for humans (health check, detached
  start, two-VM guard) — if you use it, run it detached/background too,
  because it polls until the server is up.
- Never launch the GUI (`pharo-ui`) from an agent session.
- **Before telling the user to relaunch the desktop, STOP the headless
  server.** A desktop started while a headless VM still holds the image is
  the forbidden two-VM state, and it splits the bridge silently: the
  headless VM keeps port 8086 (SIS binds at boot; the desktop's SIS just
  fails to bind), so every eval lands in a world nobody is looking at.
  Symptoms: evals succeed but the user sees no change, read-screen shows a
  degenerate world (e.g. 240x120 with windows overflowing it). Recovery:
  kill `PharoConsole.exe`, have the user relaunch the desktop, then
  verify the bridge reaches the real world (`/read-screen` bounds should
  match the actual screen before trusting any GUI-visible change).
- **Fastest visual confirmation that the bridge reaches the world the
  user is watching: cycle the world color** —
  `World color: Color red.` followed by restoring it. If the user's
  desktop flashes, the connection is live and attached to the right
  process; evals alone can never prove that (they succeed against a
  phantom world too). Use this before trusting any GUI-visible change
  after a VM restart or hand-off.

## Talking to the image

Preferred order: MCP tools (`smalltalk-interop` server: `eval`,
`get_class_source`, `get_method_source`, `search_*`, `run_*_test`, ...) if
registered in this session; otherwise the HTTP API directly.

For any eval payload containing Smalltalk quotes, **write the JSON body to a
temporary file and use `curl --data-binary @file`**. Inline shell quoting is
brittle on Windows and has already caused two spurious failures here.

Key endpoints (all return JSON with `success`, and on failure a structured
`error` with `description`, `stack_trace`, and `receiver` including its
instance variables — read these, they are the debugger):

| Endpoint | Purpose |
|---|---|
| `POST /eval/` `{"code": "..."}` | Evaluate Smalltalk |
| `GET /get-class-source?class_name=X` | Class definition source |
| `GET /get-method-source?class_name=X&method_name=y` | Method source |
| `GET /search-classes-like?class_name_query=X` / `search-methods-like`, `search-implementors`, `search-references` | Navigation |
| `GET /list-packages` / `export-package` / `import-package` | Tonel in/out |

`export-package` takes `package_name` + `path` (target directory, it
creates a `path/<package>/` tree). `import-package` takes `package_name`
+ `path` where `path` is the **parent** directory of the package — this
differs from the example in the upstream API.md, which is misleading.
When an endpoint 500s on a missing param, read the handler source live:
`GET /get-method-source?class_name=SisServer&method_name=handleX:` —
the image is the authority, not the docs.
| `GET /run-package-test?package_name=X` / `run-class-test` | Tests |
| `GET /install-project` | Metacello install |

## Pharo 13 rules (learned the hard way — do not repeat these mistakes)

1. **Class creation is the fluid builder API only.** The classic
   `Object subclass: #Foo instanceVariableNames: '' ... package: 'P'` and
   `subclass:package:` selectors were removed in Pharo 13. Use:
   ```smalltalk
   Object << #ClassName slots: {}; package: 'PackageName'; install
   ```
   The class does not exist until `install` is sent.

2. **One eval is compiled before any of it runs.** You cannot create a class
   and use its name in the same eval — the compiler resolves globals at
   parse time and reports "Undeclared variable". Send a second eval.

3. **String literals use single quotes.** `''` is the empty string; `""` is a
   comment. `''string in a string''` doubles embedded quotes.

4. **Eval results must be JSON-serializable.** SIS cannot map arbitrary
   objects (`ShiftClassBuilder`, class objects) and reports
   `"JSON mapping not found for: X"` even though the code ran. End evals with
   a symbol, string, or number: `... install. #created`.
   Arbitrary-precision integers (factorials, big sums) exceed JSON's
   safe-integer domain and are rejected by the MCP layer with
   "exceeds safe integer domain for JSON floats" — return them as strings:
   `42 factorial printString`.

5. `crLog` does not exist in Pharo 13; use `traceCr` or `Transcript`.
6. **A saved image can carry a stale SSL session that kills the VM at
   GC time.** If the image was saved after `AgentSession` talked to the
   API, a `ZdcPluginSSLSession` with an invalid handle can survive into
   the next boot; when the garbage collector finalizes it, the VM exits
   with `PrimitiveFailed: primitive #primitiveSSLDestroy:` (check
   `PharoDebug.log` for `THERE_BE_DRAGONS_HERE`). Nothing durable is
   lost: restore from `snapshots/` or rebuild fresh and re-run
   `demo/replay_demo.py`. **Defused in this repo:**
   `ZdcPluginSSLSession>>finalize` now tolerates stale handles — the
   replay installs the patch (`demo/hardening-01-ssl.json`). Snapshots
   saved before the patch can still die this way; restoring them and
   immediately re-running the replay's hardening step fixes them.

## In-image agent (AgentSession)

The AgentTerminal package contains AgentSession - the inside-out
variant: LLM tool calls executed as native Smalltalk messages.

- The API key comes from MISTRAL_API_KEY via OSEnvironment at request
  time. If the image process lacks it, ask: raises a clear error;
  restart the image from a key-carrying shell instead of storing keys
  in the image (keys in the image would survive into snapshots).
- Its eval tool returns printString of results, so arbitrary-precision
  integers cross fine (no JSON float limit - the boundary is text).
- The system prompt MUST include concrete compile-idiom examples for
  method installation (nested-quote escaping is the model's hard part);
  see AgentSession>>systemPrompt before editing it.
- Session logs go to Transcript (stdout when headless).
- Build payloads: demo/agent-*.json, generated by gen_agent.py.

## Shell gotchas on Windows (Git Bash)

- The `bash` tool is Git Bash, not cmd.exe: use POSIX syntax
  (`ls`, `cat`, `/dev/null`), not Windows syntax. `dir /b` and friends
  either fail or, with a redirect, create a literal file named `nul`.
- Redirect to `/dev/null`, never `> nul`. If a stray `nul` file appears,
  delete it (`rm nul` works in Git Bash) — it is gitignored.
- Re-running the zeroconf installer over an existing `pharo-vm/` prompts
  for every file; with non-interactive stdin this leaves the VM
  half-replaced. Agents must `rm -rf pharo-vm` first (regenerable,
  gitignored), then re-run the installer.
- Never run two VMs on the same image files. Before starting the server,
  check whether it is already up (health check above); another agent
  session may have started it.

## Desktop (GUI) mode

The user may run the Pharo desktop via `start-pharo-desktop.cmd`
(Pharo.exe on the same image). In GUI mode:

- SIS still serves :8086 — health checks and evals work as usual; do
  NOT start a second VM (headless or GUI) while one is running.
- Window geometry persists in the image: the desktop window is
  recreated at `World worldState realWindowExtent` (read by
  `OSWorldRenderer>>doActivate`), and Morphic's fullscreen preference
  lives in `WorldMorph classPool at: #LastScreenModeSelected`. An
  image saved while maximized/fullscreen relaunches screen-sized and
  the fullscreen toggle looks stuck. Fix: set
  `World worldState realWindowExtent: 1400@900` and the flag `false`,
  save the image — and save future images only from a windowed state.
  Full story in DESKTOP.md's symptom table.
- Roassal works from eval processes: `RSCanvas new ... open` opens a
  window on the user's screen. See `GameOfLife >> openEvolutionView`
  and `openGunView` in `src/` for the working pattern (grid of boxes
  in a Dictionary keyed by point, repaint + `canvas signalUpdate` in a
  forked loop).
- Verify your own UI work: `GET /read-screen` returns the World morph
  structure (classes, bounds, visibility) plus a screenshot path.
- `Color veryLighter` does not exist in Pharo 13; use named colors
  (`Color veryLightGray`) or `lighter`.
- Cat Desktop 2 is NOT a bitmap: `MistralCat installWallpaper` sets
  the world color to the light square's yellow and adds a fixed-size
  locked `ImageMorph` cat logo (cat-logo.png, transparent) at 24@48.
  Solid color + fixed logo = aspect-proof; resizing the window never
  distorts anything. `python gen_wallpaper.py` regenerates cat-logo.png
  (its `BACKGROUND_MODE` switch also has a "conformal" full-bitmap
  style, which IS extent-bound: regenerate per world size for that one).
- `MistralCat toggleWallpaper` switches between Cat Desktop 2 and the
  default (`MistralCat restoreDefaultDesktop` - logo/banner morphs
  removed, PharoDarkTheme re-applied with shadows off, default world
  color, and the Pharo banner rebuilt from pharo-banner.png at the
  top-left). The world color is the state signal: `FCDC7E` = cat
  desktop. The banner belongs to the DEFAULT state and
  installWallpaper removes it - do not treat it as a stray.
- One live patch to a STOCK class is intentional (in-image only, not
  exported): `SystemWindow>>setStripeColorsFrom:` colors the
  title-bar stripe accents light orange (the stock stripes are a
  never-recolored Morph default blue). Do not "fix" it back.
- The VM writes empty `stderr`/`stdout` files in the project root
  while running — gitignored; deletable only after the VM exits.
- When installing complex patterns (e.g. Life patterns from RLE),
  fetch canonical data from an authoritative mirror and verify by
  simulation BEFORE compiling into the image — see `gen_gosper.py`
  for the working approach.

## Safety

- The eval endpoint executes arbitrary code in a live system. Before risky
   operations (package loads, bulk refactoring, anything destructive),
   run `snapshot.cmd` (whole-world backup of the image); restore with
   `restore.cmd snapshots\<timestamp>` while the image is stopped.
- Do not commit `Pharo.image` / `Pharo.changes` / `PharoDebug.log` to
  version control (`.gitignore` already excludes them).
- Prefer small, idempotent evals over large scripts.
- Remove dead code frequently and completely. Live-image development
  accumulates superseded experiments fast: strip unused selectors,
  delete emptied classes and their tests, drop emptied packages, and
  re-export so `src/` matches the image. Snapshot first
  (`snapshot.cmd`); if the code might ever be wanted again, preserve
  it on a local branch before deleting it.
- After meaningful live changes, keep the durable source of truth in sync:
  export the affected package as Tonel to `src/` via
  `GET /export-package?package_name=X&path=<abs src path>`, save the image
  (`Smalltalk snapshot: true andQuit: false`), and commit.
- `demo/replay_demo.py` is the reference for how a structured agent session
  against the image should look (health check -> evals -> test runs -> export).

## Private Mistral material - never publish

The Mistral-brand desktop theme and cat wallpaper are third-party
copyright material and stay private to this machine:

- `src/MistralDesktop/`, `src/MistralDesktop-Tests/`,
  `gen_wallpaper.py`, `wallpaper.png`, `pharo-logo.png` are gitignored
  ON PURPOSE. Never track them, never publish their contents, and keep
  them out of public docs (README/MANUAL).
- The theme work is preserved on the local branch `mistral-theme` -
  do not push that branch anywhere.
- A generic "how to build your own Pharo theme" guide is fine to
  publish; it must not use Mistral colors, art, or branding.

## Reference

- SIS backend: https://github.com/mumez/PharoSmalltalkInteropServer
- MCP wrapper: https://github.com/mumez/smalltalk-interop-mcp-server
- Human-facing overview: README.md; roadmap: TODO.md
