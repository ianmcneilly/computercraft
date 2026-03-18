# peripheral API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/peripheral.html

Find, wrap, and interact with peripherals attached to the computer.

## Functions

### peripheral.getNames()
Get the names of all attached peripherals.
- Returns: `{ string... }` — list of peripheral names
- Notes: Directly-adjacent peripherals use directional names ("top", "bottom", etc.); wired peripherals use network names.

### peripheral.isPresent(name)
Check if a peripheral is present.
- Parameters: `name`: `string` — side or network name
- Returns: `boolean`

### peripheral.getType(peripheral)
Get the type(s) of a peripheral.
- Parameters: `peripheral`: `string|table` — peripheral name or wrapped instance
- Returns: `string...` — one or more type identifiers, or nil if absent
- Notes: Can return multiple types. Accepts wrapped peripheral tables since 1.88.0.

### peripheral.hasType(peripheral, peripheral_type)
Check if a peripheral has a specific type.
- Parameters:
  - `peripheral`: `string|table` — peripheral name or wrapped instance
  - `peripheral_type`: `string` — type to check for
- Returns: `boolean|nil` — true if matches, nil if peripheral absent
- Notes: Added in 1.99.

### peripheral.getMethods(name)
Get the methods available on a peripheral.
- Parameters: `name`: `string` — peripheral name
- Returns: `{ string... }|nil` — list of method names, or nil if absent

### peripheral.getName(peripheral)
Get the name of a wrapped peripheral.
- Parameters: `peripheral`: `table` — wrapped peripheral instance
- Returns: `string`
- Notes: Added in 1.88.0.

### peripheral.call(name, method, ...)
Call a method on a peripheral.
- Parameters:
  - `name`: `string` — peripheral name
  - `method`: `string` — method to call
  - `...`: `any` — method arguments
- Returns: whatever the method returns

### peripheral.wrap(name)
Wrap a peripheral into a callable table.
- Parameters: `name`: `string` — peripheral name
- Returns: `table|nil` — table of callable methods, or nil if not present

### peripheral.find(ty, filter?)
Find all peripherals of a given type.
- Parameters:
  - `ty`: `string` — peripheral type to find
  - `filter?`: `function(name: string, wrapped: table): boolean` — optional filter predicate
- Returns: `table...` — zero or more wrapped peripheral tables
- Notes: Added in 1.6.

## Common Peripheral Types

| Type | Description |
|------|-------------|
| `"monitor"` | Monitor |
| `"computer"` | Other computer |
| `"modem"` | Modem (wired or wireless) |
| `"drive"` | Disk drive |
| `"printer"` | Printer |
| `"speaker"` | Speaker |
| `"command"` | Command block |
| `"inventory"` | Generic inventory (chests, machines) |
| `"fluid_storage"` | Generic fluid container |
| `"energy_storage"` | Generic energy storage |

## Events

### peripheral
Fired when a peripheral is attached.
- Parameters: `side`: `string`

### peripheral_detach
Fired when a peripheral is detached.
- Parameters: `side`: `string`
