# Peripheral Wrapping Pattern

How to safely find, wrap, and use peripherals in CC:T.

## Finding by Type (Preferred)

```lua
local monitor = peripheral.find("monitor")
if not monitor then
    print("No monitor found!")
    return
end
```

## Wrapping by Side/Name

```lua
-- By side
local modem = peripheral.wrap("back")

-- By network name (wired modem)
local chest = peripheral.wrap("minecraft:chest_0")
```

## Safe Peripheral Access

Always guard against detachment:

```lua
local function getMonitor()
    local mon = peripheral.find("monitor")
    if not mon then
        error("Monitor not connected!", 2)
    end
    return mon
end

local function safeCall(peripheral, method, ...)
    if peripheral and peripheral[method] then
        return peripheral[method](...)
    end
    return nil, "Peripheral unavailable"
end
```

## Listing Available Peripherals

```lua
local names = peripheral.getNames()
for _, name in ipairs(names) do
    print(name .. " [" .. peripheral.getType(name) .. "]")
end
```

## Listening for Attach/Detach

```lua
parallel.waitForAny(
    function()
        -- main program
        mainLoop()
    end,
    function()
        while true do
            local event, side = os.pullEvent()
            if event == "peripheral" then
                print("Peripheral attached: " .. side)
                reconnect()
            elseif event == "peripheral_detach" then
                print("Peripheral detached: " .. side)
                handleDisconnect()
            end
        end
    end
)
```

## Multiple Peripherals of Same Type

```lua
-- peripheral.find() returns all matches
local mon1, mon2 = peripheral.find("monitor")

-- Or collect into a table
local monitors = { peripheral.find("monitor") }
for i, mon in ipairs(monitors) do
    mon.clear()
    mon.write("Monitor " .. i)
end
```

## Wired Modem Networks

When using wired modems, peripherals appear by their network name:

```lua
-- Open the modem first
peripheral.find("modem", function(name, modem)
    if modem.isWireless and not modem.isWireless() then
        modem.open(1) -- not needed for peripheral access, but for rednet
    end
end)

-- Remote peripherals are now accessible by name
local remoteMonitor = peripheral.wrap("monitor_3")
```

## Notes

- `peripheral.find()` scans all sides and wired network names
- `peripheral.wrap()` returns nil if nothing at that location — always nil-check
- Wrapped peripherals become invalid if detached — re-wrap after `peripheral` event
- Method calls on a detached peripheral throw errors — use pcall if unsure
- `peripheral.hasType(name, type)` checks if a peripheral matches a type (useful for multi-type peripherals)
