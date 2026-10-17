# TODO — Reverse Smalltalk

Roadmap from working PoC (done) toward a real agentic Smalltalk environment.
Items are roughly ordered; see README.md for the architecture.

## Done

- [x] Pharo 13 image + VM, SIS loaded, headless server on port 8086
- [x] MCP bridge (`smalltalk-interop-mcp-server`) verified end-to-end
- [x] MCP server registered in Vibe (`~/.vibe/config.toml`)
- [x] Live demo: class created, method compiled and executed, source read back
- [x] README.md / AGENTS.md documenting the setup and the Pharo 13 rules
- [x] Git repo; durable sources as Tonel in `src/` (plain Tonel, no Iceberg yet)
- [x] Agent-built MVP: GameOfLife developed test-first in the live image
      (red: 5 errors -> green: 5 passed), replayable via `demo/replay_demo.py`
- [x] Whole-world undo: `snapshot.cmd` / `restore.cmd`
- [x] Folder trusted in Vibe; AGENTS.md auto-loads for agent sessions

## Near term — harden the PoC

- [ ] Verify the `smalltalk-interop` MCP tools appear in a fresh Vibe session
      (`/mcp` status), and run a real coding task through them
- [ ] A `restart-server.cmd` / health-check helper (is the image up? port
      8086 listening?) — partially covered by replay_demo.py's check
- [ ] Decide image lifecycle: auto-start on boot (Task Scheduler / nssm as a
      Windows service) vs on-demand by the agent

## Before going public (LinkedIn / GitHub)

- [ ] Choose a license (bridge stack is mumez's; our repo needs its own)
- [ ] Record a screen/asciinema capture of `demo/replay_demo.py` for the post
- [ ] Tag a release (v0.1.0) once MCP tools are verified in a fresh session

## Mid term — better agent ergonomics

- [ ] Write a Vibe skill encoding the Pharo 13 rules (the AGENTS.md section)
      so any agent session in this folder gets them automatically
- [ ] Evaluate mumez/smalltalk-dev-plugin (Claude Code plugin format) —
      port or reuse its Smalltalk skills
- [ ] Structured failure workflows: on error, auto-fetch receiver/stack via
      the error JSON; try a "define, then use" retry pattern automatically
- [ ] Test-runner integration: `run_package_test` output shaping, red-green
      loop conventions for agent-driven TDD
- [ ] Explore `read_screen` (UI debugging) — agent-driven UI development with
      Spec/Morphic screenshots
- [ ] Evaluate mumez/pharo-agentic-browser as a full workspace UI / whether
      to stay with plain MCP tools

## Long term — the "Reverse" direction

- [ ] Squeak interop: SIS v4 also supports Squeak — decide whether the
      PoC should target both dialects
- [ ] Debugger control as agent tools: capture context chains on halt/error,
      inspect live objects in frames, proceed/restart programmatically
      (this is the biggest gap in the current SIS API)
- [ ] Whole-world undo as a first-class primitive: named checkpoints of the
      image, agent-visible, with rollback cost measured in file copy
- [ ] Study the Squeak/Pharo VM and SIS server implementation in depth as
      reverse-engineering targets: what would our own Smalltalk do
      differently if the agent bridge were a VM-level primitive from
      day one?
- [ ] Design notes for an agent-native Smalltalk: sandboxed eval, structured
      error protocol, image/segment snapshot API, transcript as a channel
