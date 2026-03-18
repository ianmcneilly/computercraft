# parallel API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/parallel.html

Run multiple functions concurrently using coroutines.

## Functions

### parallel.waitForAny(...)
Run functions concurrently. Returns when ANY function completes.
- Parameters: `...`: `function` — one or more functions
- Returns: nothing
- Throws: if any function errors

### parallel.waitForAll(...)
Run functions concurrently. Returns when ALL functions complete.
- Parameters: `...`: `function` — one or more functions
- Returns: nothing
- Throws: if any function errors

## Critical Warning

Pass function **references**, not function call **results**:
- Correct: `parallel.waitForAny(doSleep, rednet.receive)`
- Wrong: `parallel.waitForAny(doSleep(), rednet.receive())`

## Notes

- Functions run as coroutines — cooperative multitasking, not true parallelism
- Each function MUST yield periodically (`sleep()`, `os.pullEvent()`, `rednet.receive()`, etc.)
- A function that never yields will starve all other coroutines
- Each function receives its own copy of events from the event queue
- Use closures to pass arguments: `parallel.waitForAny(function() doWork(x) end)`
- If a function errors, the parallel call propagates it immediately
- See docs/patterns/parallel-tasks.md for common patterns
