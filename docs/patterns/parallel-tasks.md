# Parallel Tasks Pattern

Running multiple concurrent operations in CC:T using the `parallel` API.

## parallel.waitForAll

Run multiple functions concurrently; returns when ALL complete:

```lua
local function monitorDisplay()
    while true do
        updateDisplay()
        sleep(1)
    end
end

local function handleInput()
    while true do
        local event, key = os.pullEvent("key")
        processKey(key)
    end
end

local function networkListener()
    while true do
        local sender, msg = rednet.receive()
        processMessage(sender, msg)
    end
end

parallel.waitForAll(monitorDisplay, handleInput, networkListener)
```

## parallel.waitForAny

Run multiple functions concurrently; returns when ANY ONE completes:

```lua
local function doWork()
    -- long-running task
    turtle.dig()
    turtle.forward()
end

local function timeout()
    sleep(30)
end

parallel.waitForAny(doWork, timeout)
-- continues here when either doWork finishes or 30s elapses
```

## Common Pattern: Main Loop + Quit Handler

```lua
local running = true

local function mainLoop()
    while running do
        -- do work
        sleep(0.5)
    end
end

local function quitHandler()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.q then
            running = false
            return
        end
    end
end

parallel.waitForAny(mainLoop, quitHandler)
print("Program exited.")
```

## Notes

- Each function runs as a coroutine — they don't truly run simultaneously, they yield cooperatively
- Functions MUST yield (via `sleep()`, `os.pullEvent()`, `rednet.receive()`, etc.) to allow other coroutines to run
- A tight loop without yielding (`while true do end`) will starve all other coroutines
- You cannot pass arguments to parallel functions directly — use closures or upvalues
- If a function errors, `parallel.waitForAny` returns immediately; `parallel.waitForAll` propagates the error
