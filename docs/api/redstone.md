# redstone API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/redstone.html

Get and set redstone signals on all six sides of a computer. The `rs` alias can be used interchangeably.

## Functions

### redstone.getSides()
Returns a table of all valid sides.
- Returns: `{ string... }` — `{ "top", "bottom", "left", "right", "front", "back" }`

### redstone.getInput(side)
Get the current redstone input on a side.
- Parameters: `side`: `string`
- Returns: `boolean`

### redstone.setOutput(side, on)
Set the redstone output on a side. Emits signal strength 15 when enabled.
- Parameters: `side`: `string`, `on`: `boolean`

### redstone.getOutput(side)
Get the current redstone output on a side.
- Parameters: `side`: `string`
- Returns: `boolean`

### redstone.getAnalogInput(side)
Get the analog redstone input signal strength.
- Parameters: `side`: `string`
- Returns: `number` — signal strength 0–15
- Aliases: `getAnalogueInput`

### redstone.setAnalogOutput(side, value)
Set the analog redstone output signal strength.
- Parameters: `side`: `string`, `value`: `number` — 0–15
- Throws: if value outside 0–15
- Aliases: `setAnalogueOutput`

### redstone.getAnalogOutput(side)
Get the analog redstone output signal strength.
- Parameters: `side`: `string`
- Returns: `number` — 0–15
- Aliases: `getAnalogueOutput`

### redstone.getBundledInput(side)
Get the bundled cable input on a side.
- Parameters: `side`: `string`
- Returns: `number` — bitmask of active colors (use `colors.test()` to check)

### redstone.setBundledOutput(side, output)
Set the bundled cable output on a side.
- Parameters: `side`: `string`, `output`: `number` — color bitmask (use `colors.combine()`)

### redstone.getBundledOutput(side)
Get the bundled cable output on a side.
- Parameters: `side`: `string`
- Returns: `number` — color bitmask

### redstone.testBundledInput(side, mask)
Check if specific colors are active in the bundled input.
- Parameters: `side`: `string`, `mask`: `number` — color bitmask
- Returns: `boolean`

## Events

### redstone
Fired when any redstone input changes on any side. No parameters — poll sides to determine what changed.

## Notes

- Sides are relative to the direction the computer faces
- `rs` is a global alias for `redstone`
- Bundled cables require a mod that provides them (e.g., Project Red)
- British spelling variants (`Analogue`) are available for all analog functions
