# settings API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/settings.html

Read and write persistent configuration values. Saved to `.settings` by default.

## Functions

### settings.define(name, options?)
Define a setting with metadata.
- Parameters:
  - `name`: `string`
  - `options?`: `table` — `{ description?: string, default?: any, type?: string }`
- Notes: `type` can be `"number"`, `"string"`, `"boolean"`, or `"table"`

### settings.undefine(name)
Remove a setting definition (preserves set value — use `unset()` to clear).
- Parameters: `name`: `string`

### settings.set(name, value)
Set a setting's value. Does NOT save to disk — call `settings.save()` to persist.
- Parameters: `name`: `string`, `value`: `any` — must be serializable, non-nil
- Throws: if value cannot be serialized

### settings.get(name, default?)
Get a setting's value.
- Parameters: `name`: `string`, `default?`: `any` — fallback if unset
- Returns: `any` — the value, the defined default, or the provided default

### settings.getDetails(name)
Get full metadata about a setting.
- Parameters: `name`: `string`
- Returns: `table` — `{ description?, default?, type?, value?, changed? }`

### settings.unset(name)
Remove a setting's value (reverts to default).
- Parameters: `name`: `string`

### settings.clear()
Remove all setting values. Equivalent to calling `unset()` on every setting.

### settings.getNames()
Get all defined/set setting names.
- Returns: `{ string... }` — alphabetically sorted

### settings.load(path?)
Load settings from a file. Merges with existing; conflicts overwritten.
- Parameters: `path?`: `string` — default `".settings"`
- Returns: `boolean`

### settings.save(path?)
Save settings to a file. Overwrites entirely.
- Parameters: `path?`: `string` — default `".settings"`
- Returns: `boolean`

## Notes

- CraftOS loads `.settings` automatically on startup
- `settings.set()` only changes the in-memory value — always call `settings.save()` to persist
- Use `settings.define()` to provide defaults and help text for the `set` program
