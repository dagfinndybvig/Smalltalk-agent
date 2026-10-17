<img width="994" height="884" alt="image" src="https://github.com/user-attachments/assets/2d2d90df-6894-46d0-bbaa-5eea1c10944b" />

# MANUAL.md — A Plain User's Guide

This guide explains how to use this project without assuming you know
Smalltalk, Pharo, or how any of it works inside. If you can open a
terminal and double-click a file, you're qualified.

## What is this, in one paragraph

You have a *live Smalltalk system* — a complete programming environment
where code, data, and running programs all exist together in one
"image" file. On top of that sits a small server (SIS) that lets an AI
agent — or you, with a terminal — look inside that image, change it,
run tests, and open windows, while it's running. You can use the classic
Smalltalk desktop yourself at the same time; human and agent share the
same live world.

## What you need

- Windows (this guide's commands assume it)
- Git Bash (comes with [Git for Windows](https://git-scm.com/download/win))
- Python 3.10 or later and [uv](https://docs.astral.sh/uv/) (only for the
  AI-agent part and the replay demo)
- Internet access

Linux and macOS users: everything here works too - use the bash
commands in the README's "Rebuilding the environment" section in place of the
`.cmd` files, which are Windows shortcuts.

## First-time setup

Only needed once. From Git Bash, in this folder:

```bash
# 1. Download Pharo 13 (the Smalltalk system) - image + VM
curl -sS -L https://get.pharo.org/64/stable+vm | sh

# 2. Install the SIS server into the image
./pharo Pharo.image metacello install \
  github://mumez/PharoSmalltalkInteropServer:main/src \
  BaselineOfPharoSmalltalkInteropServer

# 3. (Optional) Start the image and load the demo code:
#    - double-click start-pharo-server.cmd and wait ~10 seconds, or run
#      ./pharo --headless Pharo.image st keepalive.st in a second terminal
python demo/replay_demo.py
```

After step 2, the server will start automatically every time the image
starts. After step 3, the image also contains the GameOfLife example, the Gosper glider gun, and the in-image agent class AgentSession (inert unless MISTRAL_API_KEY is set - see the advanced section)
(see "A tour of the demo" below).

If someone already built the image and you just cloned this repository:
run step 1, then step 3 (the demo rebuilds and loads everything else).

## Daily use: two ways to start the image

| File | What you get |
|---|---|
| `start-pharo-server.cmd` | A windowless server. For agents and terminals. |
| `start-pharo-desktop.cmd` | The full Smalltalk desktop, with windows and menus. |

Double-click either one. The server (or desktop) takes about ten
seconds to come up. It is ready when this answers:

```bash
curl -X POST http://localhost:8086/eval/ -H "Content-Type: application/json" -d '{"code":"Smalltalk version"}'
```

**The one rule that really matters: never run both at the same time.**
They would be two programs writing to the same files. Before opening the
desktop, close the server's console window (or run
`taskkill /F /IM PharoConsole.exe`). Before starting the server, quit
the desktop.

To stop either: close its window, or press Ctrl+C in its console.

## Using the desktop for the first time

The Pharo desktop looks like a blue empty screen. That screen is called
the *World*. The main menus live on it:

- **Left-click the blue background** — this opens the World menu, the
  main menu of the whole system.
- **Playground** — a scratch editor. You type Smalltalk code and run it
  immediately. This is where most experimenting happens.
- **System Browser** — the code explorer, like an IDE without files.
  All code in the image lives here.

### Running code in the Playground

1. World menu → Playground.
2. Type or paste a line of code.
3. **Select the text you want to run**, then:
   - **Ctrl+D** — do it (run, show nothing)
   - **Ctrl+P** — print the result inline
   - **Ctrl+I** — open an inspector on the result

The selecting matters: if the Playground holds several lines, running
without a selection runs *everything*.

### A tour of the demo

Run these one line at a time in the Playground (select the line first):

```smalltalk
"Make a small world: three live cells in a vertical line (a 'blinker')"
GameOfLife new withAll: { 0@1. 1@1. 2@1 }
```

```smalltalk
"Ask it for the next generation, and print it"
(GameOfLife new withAll: { 0@1. 1@1. 2@1 }) nextGeneration
```

```smalltalk
"Same, but see it graphically - a window opens"
(GameOfLife new withAll: { 0@1. 1@1. 2@1 }) openView
```

```smalltalk
"Animated: watch the blinker flip forever"
(GameOfLife new withAll: { 0@1. 1@1. 2@1 }) openEvolutionView
```

```smalltalk
"The showpiece: Gosper's glider gun, firing gliders forever.
 This opens a big grid; every 7.5 seconds a new glider is born."
GameOfLife gosperGun openGunView
```

To see the code behind all this: World menu → System Browser, search
for `GameOfLife`, and click around. Everything is readable, and — this
is the point of Smalltalk — everything is editable while it runs.

### Running the test suite from a terminal

```bash
curl "http://localhost:8086/run-class-test?class_name=GameOfLifeTest"
```

You should see `"N ran, N passed"` with zero failures.

## Saving, and not losing work

This is the part of Smalltalk that surprises people:

- The **image** (`Pharo.image`) is the state of the whole world.
  Nothing is "written to disk" until the world is *saved*.
- **Saving** happens explicitly:
  - In the desktop: World menu → Save (or Ctrl+S in most versions).
  - From a terminal: evaluate
    `Smalltalk snapshot: true andQuit: false` via `/eval/` (the
    demo's replay script does this automatically at the end).
- If the image quits without saving, code compiled since the last save
  is gone from the image (a `.changes` file keeps the source text, but
  nothing reloads it automatically).

Because of that, there are two safety nets:

1. **`src/` folder** — plain-text copies of all demo code (Tonel
   format). To reload them into a fresh image:
   ```bash
   curl "http://localhost:8086/import-package?package_name=GameOfLife&path=<this-folder>/src"
   curl "http://localhost:8086/import-package?package_name=GameOfLife-Tests&path=<this-folder>/src"
   ```
   (note: `path` is the *folder*, not the package; the name comes from
   `package_name`)
2. **`snapshot.cmd`** — copies the entire image state to
   `snapshots\Pharo-<timestamp>.*`. Restore with
   `restore.cmd snapshots\Pharo-<timestamp>` (image must be stopped
   first). This rolls back *everything* — code, objects, running
   processes — in one step.

## Letting an AI agent work on it

The same server a terminal talks to is exposed to AI agents through
MCP (Model Context Protocol) — a standard way for assistants to call
tools. Any MCP-capable agent client can be pointed at this image by
giving it this server (no installation; it is fetched on demand):

```json
{
  "mcpServers": {
    "smalltalk-interop": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/mumez/smalltalk-interop-mcp-server.git", "smalltalk-interop-mcp-server"],
      "env": { "SIS_PORT": "8086" }
    }
  }
}
```

Once connected, the agent can evaluate Smalltalk, read and edit any
class or method, search the system, run the tests, install projects,
and even open windows on your screen. AGENTS.md in this folder is the
rulebook agents are given — it exists so they handle the environment
correctly (for example: never start a second copy of the image).

To replay, on demand, the whole "agent develops a program live" story:

```bash
python demo/replay_demo.py
```

You will watch tests fail on purpose, then pass, then the code being
exported to `src/` and the image saved.

## An agent inside the image (advanced)

The image also contains its own agent. `AgentSession` talks directly
to the Mistral API and runs the model's tool calls as Smalltalk
messages - it modifies the very image it lives in. Try, from a
terminal (server running) or the Playground:

```bash
curl -X POST http://localhost:8086/eval/ -H "Content-Type: application/json" -d "{\"code\":\"AgentSession new ask: ''Run the GameOfLifeTest suite and report.''\"}"
```

Requirement: the image must have `MISTRAL_API_KEY` in its environment
(a server started from an agent shell has it; a double-clicked
launcher does not). The key is read at each call, never saved.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Connection refused` on port 8086 | The image isn't running. Start `start-pharo-server.cmd` (or the desktop — the server runs in both). |
| `KeyNotFound: #GameOfLife` | The image was never saved with the demo code. Run `python demo/replay_demo.py`, or import from `src/` (see above). |
| Windows/other things break after starting the desktop | You started it while the server was still running. Stop one before starting the other. |
| `exceeds safe integer domain for JSON floats` | You asked an agent to evaluate something like `42 factorial` and return the number. JSON can't carry it. Return it as a string: `42 factorial printString`. |
| During `metacello install` you see "authentication error while cloning" and SSH warnings | Harmless: Pharo tries SSH first, then falls back to HTTPS on its own. Wait for "finished baseline". |
| Re-running the Pharo download over an existing folder asks to "replace" DLLs | Answer `A` (all); it is refreshing the VM. |
| A file named `nul`, `stderr` or `stdout` appeared | Windows/VM artifacts. `nul` can be deleted anytime; `stderr`/`stdout` only after the image quits. All are gitignored. |
| Agent "does not see" the tools | MCP servers load when the agent session starts. Restart the session, or run its reload command. |
| Tests unexpectedly fail after restoring a snapshot | The snapshot predates the code. Re-run the replay demo, or import from `src/`. |

## Glossary

- **Image** — one file holding the entire live world: all code, all
  objects, all running processes. Not a "disk layout" like a project
  folder; more like a running program's memory, saved.
- **.changes** — a log of every code edit, used for source recovery.
- **World** — the desktop background of the Pharo GUI; its menu is the
  system's main menu.
- **Playground** — an immediate code scratchpad.
- **SIS** — the little web server (from
  [mumez/PharoSmalltalkInteropServer](https://github.com/mumez/PharoSmalltalkInteropServer))
  running inside the image, port 8086, that makes all of this
  scriptable.
- **MCP** — Model Context Protocol; how AI agents call tools.
- **Tonel** — the plain-text format used for code in `src/`, so live
  code can be stored in git like any other source.
- **VM** — the program (in `pharo-vm/`) that runs the image.

For what this project *is*, read `README.md`. For the roadmap, read
`TODO.md`. Agent operating rules live in `AGENTS.md`.
