# [Mod Name] — [Peripheral Type]

> Source: [where this was documented from]
> CC:T Peripheral Type: `"peripheral_type_string"`
> Mod Version: [version if known]

## Overview
Brief description of what this peripheral does and how CC:T interacts with it.

## Wrapping
```lua
local device = peripheral.find("peripheral_type_string")
-- or
local device = peripheral.wrap("side_or_network_name")
```

## Methods

### device.methodName(param1, param2)
Description of what this method does.
- Parameters:
  - `param1`: `type` — description
  - `param2`: `type` — description
- Returns: `type` — description
- Notes: Any edge cases or important behavior

## Events
List any custom events this peripheral fires (if applicable).

### event_name
- Parameters: `p1`, `p2`
- Fired when: description

## Example
```lua
-- Minimal working example
local device = peripheral.find("peripheral_type_string")
if not device then
  print("Peripheral not found!")
  return
end

-- Basic usage
local result = device.methodName()
print(result)
```

## Notes
- Any version-specific quirks
- Known limitations
- Interaction with other mods/peripherals
