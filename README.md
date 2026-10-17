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
| `AGENTS.md` | Operating rules for AI agents working in this directory |
| `TODO.md` | Roadmap / next steps |

## Starting the server

Double-click `start-pharo-server.cmd`, or from Git Bash:

```
./pharo --headless Pharo.image st keepalive.st
```

SIS auto-starts on image boot and listens on **port 8086**
(`PHARO_SIS_PORT` to change). Stop with Ctrl+C.

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

## The live demo

Performed against the running image, no files involved:

1. `Object << #Greeter slots: {}; package: 'AgenticDemo'; install`
2. `Greeter compile: 'greet ^ 42 + 1'. Greeter new greet` → `43`
3. `GET /get-method-source?class_name=Greeter&method_name=greet`
   → `"greet ^ 42 + 1"`

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
