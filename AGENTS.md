# AGENTS.md — Reverse Smalltalk (Agentic PoC)

This directory contains a live Pharo 13 image under agentic control. Read this
before doing anything here.

## Environment model

- `Pharo.image` + `Pharo.changes` are **live state**, not artifacts. They hold
  running processes, the loaded SIS server, and any classes created at runtime.
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
- Never launch the GUI (`pharo-ui`) from an agent session.

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

5. `crLog` does not exist in Pharo 13; use `traceCr` or `Transcript`.

## Shell gotchas on Windows (Git Bash)

- The `bash` tool is Git Bash, not cmd.exe: use POSIX syntax
  (`ls`, `cat`, `/dev/null`), not Windows syntax. `dir /b` and friends
  either fail or, with a redirect, create a literal file named `nul`.
- Redirect to `/dev/null`, never `> nul`. If a stray `nul` file appears,
  delete it (`rm nul` works in Git Bash) — it is gitignored.
- Never run two VMs on the same image files. Before starting the server,
  check whether it is already up (health check above); another agent
  session may have started it.

## Safety

- The eval endpoint executes arbitrary code in a live system. Before risky
   operations (package loads, bulk refactoring, anything destructive),
   run `snapshot.cmd` (whole-world backup of the image); restore with
   `restore.cmd snapshots\<timestamp>` while the image is stopped.
- Do not commit `Pharo.image` / `Pharo.changes` / `PharoDebug.log` to
  version control (`.gitignore` already excludes them).
- Prefer small, idempotent evals over large scripts.
- After meaningful live changes, keep the durable source of truth in sync:
  export the affected package as Tonel to `src/` via
  `GET /export-package?package_name=X&path=<abs src path>`, and commit.
- `demo/replay_demo.py` is the reference for how a structured agent session
  against the image should look (health check -> evals -> test runs -> export).

## Reference

- SIS backend: https://github.com/mumez/PharoSmalltalkInteropServer
- MCP wrapper: https://github.com/mumez/smalltalk-interop-mcp-server
- Human-facing overview: README.md; roadmap: TODO.md
