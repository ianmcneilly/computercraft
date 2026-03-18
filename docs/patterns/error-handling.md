# Error Handling Pattern

Robust error handling strategies for CC:T programs.

## Basic pcall

```lua
local ok, err = pcall(function()
    -- code that might error
    turtle.forward()
    turtle.dig()
end)

if not ok then
    print("Error: " .. tostring(err))
end
```

## xpcall with Traceback

```lua
local ok, err = xpcall(function()
    riskyOperation()
end, function(e)
    return tostring(e) .. "\n" .. debug.traceback()
end)

if not ok then
    print("Error with trace: " .. err)
end
```

## Retry Pattern

```lua
local function retry(fn, maxAttempts, delay)
    for attempt = 1, maxAttempts do
        local ok, result = pcall(fn)
        if ok then
            return result
        end
        if attempt < maxAttempts then
            print("Attempt " .. attempt .. " failed, retrying...")
            sleep(delay or 1)
        else
            error("Failed after " .. maxAttempts .. " attempts: " .. tostring(result), 2)
        end
    end
end

-- Usage
local data = retry(function()
    return http.get("https://example.com/data")
end, 3, 2)
```

## Graceful Shutdown

```lua
local function main()
    -- program logic here
    while true do
        doWork()
        sleep(1)
    end
end

local function cleanup()
    -- save state, close files, etc.
    print("Saving state...")
    local f = fs.open("state.dat", "w")
    f.write(textutils.serialize(state))
    f.close()
end

local ok, err = pcall(main)
cleanup()
if not ok then
    print("Program crashed: " .. tostring(err))
end
```

## Handling Terminate (Ctrl+T)

```lua
-- os.pullEvent throws on terminate — use pullEventRaw to catch it
local function terminableLoop()
    while true do
        local event = os.pullEventRaw()
        if event == "terminate" then
            print("Caught terminate, cleaning up...")
            cleanup()
            return
        end
        -- handle other events
    end
end
```

## Peripheral Error Handling

```lua
local function safePeripheralCall(name, method, ...)
    local p = peripheral.wrap(name)
    if not p then
        return nil, "Peripheral not found: " .. name
    end
    local ok, result = pcall(p[method], ...)
    if not ok then
        return nil, "Call failed: " .. tostring(result)
    end
    return result
end

-- Usage
local items, err = safePeripheralCall("minecraft:chest_0", "list")
if not items then
    print("Error: " .. err)
end
```

## Logging Errors to File

```lua
local function log(msg)
    local f = fs.open("error.log", "a")
    f.writeLine("[" .. os.date() .. "] " .. msg)
    f.close()
end

local ok, err = pcall(main)
if not ok then
    log("CRASH: " .. tostring(err))
    print("Error logged to error.log")
end
```

## Notes

- `pcall` catches all errors including runtime errors and explicitly thrown errors
- `error("msg", 2)` sets the error level — 2 means the error points to the caller
- CC:T has limited `debug` library — `debug.traceback()` works but not all debug functions
- Always close file handles in cleanup, even on error
- `os.pullEvent()` internally uses `error()` to handle terminate — that's why `pcall` around `os.pullEvent` can behave unexpectedly if you don't re-throw terminate events
