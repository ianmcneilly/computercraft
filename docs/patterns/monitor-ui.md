# Monitor UI Pattern

Building touch-screen interfaces on CC:T monitors.

## Basic Monitor Setup

```lua
local monitor = peripheral.find("monitor")
if not monitor then
    print("No monitor found!")
    return
end

monitor.setTextScale(0.5) -- smallest text = highest resolution
monitor.setBackgroundColor(colors.black)
monitor.clear()

local w, h = monitor.getSize()
```

## Drawing Buttons

```lua
local buttons = {}

local function addButton(name, x, y, width, height, bgColor, textColor, callback)
    buttons[name] = {
        x = x, y = y,
        width = width, height = height,
        bg = bgColor, fg = textColor,
        callback = callback,
    }
end

local function drawButton(name)
    local b = buttons[name]
    monitor.setBackgroundColor(b.bg)
    monitor.setTextColor(b.fg)
    for row = b.y, b.y + b.height - 1 do
        monitor.setCursorPos(b.x, row)
        monitor.write(string.rep(" ", b.width))
    end
    -- center the label
    local labelY = b.y + math.floor(b.height / 2)
    local labelX = b.x + math.floor((b.width - #name) / 2)
    monitor.setCursorPos(labelX, labelY)
    monitor.write(name)
end

local function drawAllButtons()
    for name in pairs(buttons) do
        drawButton(name)
    end
end
```

## Touch Event Handling

```lua
local function checkButtonPress(x, y)
    for name, b in pairs(buttons) do
        if x >= b.x and x < b.x + b.width
           and y >= b.y and y < b.y + b.height then
            return name, b
        end
    end
    return nil
end

local function touchHandler()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local name, button = checkButtonPress(x, y)
        if name and button.callback then
            button.callback(name)
        end
    end
end
```

## Full Example: Toggle Buttons

```lua
local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.clear()

local states = { On = false, Off = false }

addButton("On", 2, 2, 10, 3, colors.green, colors.white, function()
    states.On = not states.On
    print("On toggled: " .. tostring(states.On))
end)

addButton("Off", 14, 2, 10, 3, colors.red, colors.white, function()
    states.Off = not states.Off
    print("Off toggled: " .. tostring(states.Off))
end)

drawAllButtons()

-- Run touch handler
touchHandler()
```

## Redirecting Term Output to Monitor

```lua
local monitor = peripheral.find("monitor")
local oldTerm = term.redirect(monitor)

-- All print/write now goes to monitor
print("Hello monitor!")

-- Restore terminal
term.redirect(oldTerm)
```

## Text Scale vs Resolution

| Text Scale | Approx Chars (4x3 monitor) |
|-----------|---------------------------|
| 5.0       | ~7 x 5                   |
| 1.0       | ~36 x 26                 |
| 0.5       | ~71 x 52                 |

## Notes

- Monitor coordinates are 1-based (top-left is 1,1)
- `monitor.setTextScale()` must be between 0.5 and 5.0
- Touch events fire `monitor_touch` with side, x, y — coordinates match the monitor's character grid
- Use `term.redirect(monitor)` to send `print()`/`write()` output to a monitor
- Colors require an advanced monitor (gold border in-game)
- Basic monitors (stone border) only support black and white
