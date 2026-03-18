# textutils API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/textutils.html

Utilities for formatting, serialization, and text output.

## Display Functions

### textutils.slowWrite(text, rate?)
Write text character-by-character (typewriter effect).
- Parameters: `text`: `string`, `rate?`: `number` — chars per second (default 20)

### textutils.slowPrint(text, rate?)
Like `slowWrite` but appends a newline.
- Parameters: `text`: `string`, `rate?`: `number` — chars per second (default 20)

### textutils.formatTime(time, twentyFourHour?)
Format a time value from `os.time()`.
- Parameters: `time`: `number`, `twentyFourHour?`: `boolean` — 24h format (default false, uses 12h AM/PM)
- Returns: `string` — e.g., `"6:30 PM"`

### textutils.pagedPrint(text, freeLines?)
Print text with "Press any key" pagination if it exceeds the screen.
- Parameters: `text`: `string`, `freeLines?`: `number` — free lines before first prompt
- Returns: `number` — total lines printed

### textutils.tabulate(...)
Print data in aligned columns.
- Parameters: `...`: `table|number` — alternating row tables and `colors.*` values to change text color

### textutils.pagedTabulate(...)
Like `tabulate` but with "Press any key" pagination.
- Parameters: `...`: `table|number`

## Serialization

### textutils.serialize(t, opts?)
Serialize a value to a Lua-readable string.
- Parameters:
  - `t`: `any` — value to serialize
  - `opts?`: `table` — `{ compact?: boolean, allow_repetitions?: boolean }`
- Returns: `string`
- Throws: if value contains functions or problematic recursive tables
- Aliases: `serialise`

### textutils.unserialize(s)
Deserialize a string back to a value.
- Parameters: `s`: `string`
- Returns: `any|nil` — deserialized value, or nil if invalid
- Aliases: `unserialise`

### textutils.serializeJSON(t, options?)
Serialize a value to JSON.
- Parameters:
  - `t`: `any`
  - `options?`: `table|boolean` — `{ nbt_style?: boolean, unicode_strings?: boolean, allow_repetitions?: boolean }`, or `boolean` for legacy NBT style
- Returns: `string`
- Throws: if value contains functions
- Notes: Tables with only numeric keys become JSON arrays; empty tables become objects by default.
- Aliases: `serialiseJSON`

### textutils.unserializeJSON(s, options?)
Parse a JSON string.
- Parameters:
  - `s`: `string`
  - `options?`: `table` — `{ nbt_style?: boolean, parse_null?: boolean, parse_empty_array?: boolean }`
- Returns: `any` on success, or `nil, string` error message on failure
- Aliases: `unserialiseJSON`

## URL Encoding

### textutils.urlEncode(str)
URL-encode a string.
- Parameters: `str`: `string`
- Returns: `string`

## Completion

### textutils.complete(searchText, searchTable?)
Complete a Lua expression.
- Parameters:
  - `searchText`: `string` — partial Lua expression
  - `searchTable?`: `table` — search environment (default `_G`)
- Returns: `{ string... }` — completion candidates

## Constants

### textutils.empty_json_array
Sentinel value representing an empty JSON array (distinguishes from empty object `{}`). Do not modify.

### textutils.json_null
Sentinel value representing JSON `null`. Use for explicit null in serialization.

## Notes

- `serialize`/`unserialize` produce Lua-formatted strings (not JSON)
- `serializeJSON`/`unserializeJSON` produce/parse standard JSON
- British spelling variants (`serialise`, `unserialise`, etc.) are available
