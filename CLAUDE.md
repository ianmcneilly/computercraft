# ComputerCraft Project — CC: Tweaked

## Version Pins
- Minecraft: 1.21.1 (Forge)
- CC: Tweaked: 1.115.1 (cc-tweaked-1.21.1-forge-1.115.1.jar)
- Modpack: Direwolf20 1.21 (pack version 1.14.2)
- Lua version: Lua 5.2 (CC:T's built-in subset — NOT standard Lua 5.2)

## CRITICAL: API Reference
- ALWAYS consult docs/api/ before using ANY CC:T API function
- ALWAYS consult docs/peripherals/ before scripting mod integrations
- NEVER guess at API signatures — if a doc doesn't exist yet, scrape and create it first
- CC:T Lua is NOT standard Lua 5.2 — it has restrictions (no `io`, no `debug`, no `loadfile` from outside sandbox) and additions (peripheral, rednet, turtle, etc.)

## Code Conventions
- No type annotations (not supported in CC:T Lua)
- Use `local` variables by default — avoid polluting global scope
- Use `peripheral.find()` over `peripheral.wrap()` when peripheral type is known
- Prefer `parallel.waitForAny`/`waitForAll` for concurrent tasks over raw coroutines
- Always handle peripheral detachment gracefully (check for nil)
- Use `textutils.serialize`/`unserialize` for data persistence to files
- Use `textutils.serialiseJSON`/`unserialiseJSON` for JSON data
- File paths use forward slashes, no leading slash
- Programs should be self-contained single files where practical (for pastebin deployment)
- Shared code goes in src/lib/ and is loaded via `require()` or `dofile()`
- Use `os.pullEvent()` for event handling, not `os.pullEventRaw()` unless you need to catch `terminate`
- Wrap long-running programs in `pcall`/`xpcall` for graceful error handling

## Program Structure
- src/turtle/   — Turtle automation (mining, farming, building)
- src/monitor/  — Monitor displays and touch UIs
- src/network/  — Rednet, GPS, messaging systems
- src/control/  — Peripheral control, reactor management, ME/RS systems
- src/lib/      — Shared libraries (require-able modules)

## Documentation
- docs/api/         — Core CC:T API references (one file per module)
- docs/peripherals/ — Mod-specific peripheral API docs (added on-demand)
- docs/patterns/    — Canonical implementations of common CC:T patterns

## Deployment
- Programs are deployed in-game via `pastebin get <code> <filename>`
- Keep programs as single files where possible for easy pastebin deployment
- For multi-file programs, create a bootstrapper script that pulls dependencies
- Test programs mentally against the CC:T API docs before suggesting deployment

## Common Pitfalls
- `sleep()` yields the current coroutine — don't use in event handlers without understanding implications
- `peripheral.wrap()` returns nil if peripheral not found — always nil-check
- `turtle.dig()` returns false if nothing to dig — not an error
- `rednet.receive()` blocks — use `parallel` or event loop for non-blocking
- Monitor text scale affects resolution — `monitor.setTextScale(0.5)` gives max resolution
- `http.get()` is async-capable but the simple form blocks
- CC:T uses 1-based indexing (standard Lua) — monitor coordinates are also 1-based
- `term.redirect()` changes where term writes go — remember to restore
- File handles from `fs.open()` must be closed explicitly
