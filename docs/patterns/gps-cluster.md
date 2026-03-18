# GPS Cluster Pattern

Setting up a GPS satellite network for turtle/computer positioning.

## GPS Cluster Requirements

- Minimum 4 computers with wireless/ender modems at known positions
- Computers should be spread out (not in a line) for triangulation
- Higher altitude = better range
- Each GPS host runs `gps host <x> <y> <z>`

## Recommended Layout

Place 4 computers at known coordinates forming a non-planar shape:

```
Computer 1: (0, 255, 0)    -- high altitude corners
Computer 2: (100, 255, 0)
Computer 3: (0, 255, 100)
Computer 4: (50, 255, 50)  -- offset to avoid coplanar
```

## GPS Host Startup Script

Each GPS satellite computer needs this as its `startup.lua`:

```lua
-- startup.lua for GPS host
-- Set these to this computer's ACTUAL coordinates
local X = 0
local Y = 255
local Z = 0

shell.run("gps", "host", X, Y, Z)
```

Or via the built-in command:

```
> gps host 0 255 0
```

## Querying Position

From any computer/turtle with a wireless modem:

```lua
-- Open modem if not already open
local modem = peripheral.find("modem", function(name, m)
    return m.isWireless()
end)

if not modem then
    print("No wireless modem!")
    return
end

local x, y, z = gps.locate(5) -- 5 second timeout
if x then
    print(string.format("Position: %d, %d, %d", x, y, z))
else
    print("Could not determine position")
end
```

## Automated GPS Cluster Deployer

```lua
-- Deploy GPS hosts using a turtle
-- Turtle starts at a known position with 4 computers and modems

local positions = {
    { 0,  255, 0   },
    { 10, 255, 0   },
    { 0,  255, 10  },
    { 5,  255, 5   },
}

-- For each position: fly there, place computer, etc.
-- (Implementation depends on your specific setup)
```

## Notes

- GPS uses `rednet` protocol "gps" internally — don't use that protocol name for other things
- `gps.locate()` returns nil if fewer than 4 hosts respond or triangulation fails
- Ender modems have cross-dimension range; wireless modems have limited range (default 64 blocks in survival)
- GPS coordinates are absolute world coordinates
- The locate timeout parameter is how long to wait for responses (default 2 seconds)
- More GPS hosts = more reliable positioning (redundancy)
- GPS hosts must be at known, accurate positions — a wrong coordinate breaks triangulation
