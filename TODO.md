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
- [x] Desktop mode (`start-pharo-desktop.cmd`): SIS serves :8086 in GUI
      mode; human and agent share the live world
- [x] Agent-driven UI: Roassal `openEvolutionView` / `openGunView`,
      agent self-verification via `/read-screen`
- [x] Gosper glider gun: canonical RLE fetched and verified by
      simulation, test-first into the image, suite 7/7
- [x] Cold-start acceptance test by a different agent session:
      recovered lost image from src/, live TDD red -> green (6/6),
      saved, committed, pushed

## Near term — harden the PoC

- [x] Verify the `smalltalk-interop` MCP tools appear in a fresh Vibe session
      (`/mcp` status), and run a real coding task through them — done via
      full cold-start acceptance test: a different agent session recovered
      the lost image from src/, TDD'd `generations:` red -> green (6/6),
      saved the image, committed and pushed
- [ ] A `restart-server.cmd` / health-check helper (is the image up? port
      8086 listening?) — partially covered by replay_demo.py's check
- [ ] Decide image lifecycle: auto-start on boot (Task Scheduler / nssm as a
      Windows service) vs on-demand by the agent

## Before going public (LinkedIn / GitHub)

Repo: https://github.com/dagfinndybvig/Smalltalk-agent

- [x] Choose a license — MIT (see LICENSE)
- [ ] Set the GitHub repo description and topics, e.g.
      "Pharo under agentic control — live-image TDD via MCP";
      topics: smalltalk, pharo, mcp, llm-agents, live-programming
- [ ] Record a screen/asciinema capture of `demo/replay_demo.py` for the post
- [x] Tag a release (v0.1.0) — MCP tools verified in a fresh session; release
      includes the cold-start acceptance test story

## Mid term — better agent ergonomics

- [ ] Write a Vibe skill encoding the Pharo 13 rules (the AGENTS.md section)
      so any agent session in this folder gets them automatically
- [ ] Evaluate mumez/smalltalk-dev-plugin (Claude Code plugin format) —
      port or reuse its Smalltalk skills
- [ ] Structured failure workflows: on error, auto-fetch receiver/stack via
      the error JSON; try a "define, then use" retry pattern automatically
- [ ] Test-runner integration: `run_package_test` output shaping, red-green
      loop conventions for agent-driven TDD
- [x] Explore `read_screen` (UI debugging) — works: morph structure JSON
      + screenshot; used for agent self-verification of Roassal views
      (Spec presenter screenshot capture still untested)
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
