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
- [x] Inside-out agent: AgentSession lives in the image (Zinc +
      NeoJSON tool-calling loop, native eval/run_tests/get_method_source,
      key via OSEnvironment, never stored); validated TDD session red ->
      green 8/8 by the in-image agent itself
- [x] Cold-start acceptance test by a different agent session:
      recovered lost image from src/, live TDD red -> green (6/6),
      saved, committed, pushed

## Near term — harden the PoC

- [x] Verify the `smalltalk-interop` MCP tools appear in a fresh Vibe session
      (`/mcp` status), and run a real coding task through them — done via
      full cold-start acceptance test: a different agent session recovered
      the lost image from src/, TDD'd `generations:` red -> green (6/6),
      saved the image, committed and pushed
- [x] A `restart-server.cmd` / health-check helper — created. Checks :8086,
      refuses to start a second VM if a Pharo process already holds the
      image, otherwise starts the headless image detached and waits for
      SIS. Validated from the up state, the down state, and as the boot
      step of the fresh-install validation.
- [x] Image lifecycle decided: **on-demand**, not auto-started. The image
      is single-writer, so an unattended auto-started VM (Task Scheduler /
      nssm) can collide with the desktop GUI or an agent-started VM and
      corrupt state. Both humans and agents have one-command starters
      (`restart-server.cmd`, the AGENTS.md health check); revisit only if
      headless use becomes continuous.
- [x] Defuse the stale-SSL-finalizer crash: `ZdcPluginSSLSession>>finalize`
      now tolerates a stale handle (catches the error, nils the handle,
      deregisters) instead of killing the VM inside the finalization
      process. Applied as a replay step (`demo/hardening-01-ssl.json`),
      verified with a forced-GC stale-handle stress test, included in the
      fresh-install validation. Still worth reporting upstream to Pharo/Zdc.

## Before going public (LinkedIn / GitHub)

Repo: https://github.com/dagfinndybvig/Smalltalk-agent

- [x] Choose a license — MIT (see LICENSE)
- [x] Set the GitHub repo description and topics
- [x] Record a screen/asciinema capture for the post — README lead
      screenshot (glider gun view) added by the author; live capture of
      `demo/replay_demo.py` still worth doing for the post itself
- [x] Tag a release (v0.1.0) — MCP tools verified in a fresh session; release
      includes the cold-start acceptance test story

## Mid term — better agent ergonomics

- [x] Fix AgentSession's `get_method_source` tool: it only saw instance-side
      methods. A live fix session concluded the class-side `GameOfLife
      class >> diamond` "does not exist" (its tool could not look at the class
      side), compiled a duplicate on the instance side, and burned all 25
      iterations chasing the contradiction. Fixed: instance-side lookup first,
      class-side fallback (result tagged "(class side)"), tool description
      updated; verified red -> green on `gosperGun` and rebuilt into the
      image via the regenerated `demo/agent-02/04` payloads.

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
- [ ] AgentChatWindow: a proper Morphic/Spec terminal window for
      AgentSession (transcript + input + object inspector), instead of
      driving it from the Playground/eval
- [ ] Streaming responses and richer tools for AgentSession (snapshot,
      class browsing, debugger interaction via live exception objects)
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
