# gps API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/gps.html

Locate the position of a computer or turtle using GPS satellite computers.

## Constants

- `gps.CHANNEL_GPS` = `65534` — the channel used for GPS requests and responses

## Functions

### gps.locate(timeout?, debug?)
Determine the current computer's position via GPS trilateration.
- Parameters:
  - `timeout?`: `number` — seconds to wait for responses (default 2)
  - `debug?`: `boolean` — print debug messages (default false)
- Returns: `number` x, `number` y, `number` z — or `nil` if position could not be determined

## Notes

- Requires a wireless modem (or ender modem for cross-dimension)
- Needs at least 4 GPS host computers at known positions for trilateration
- GPS hosts are set up with `gps host <x> <y> <z>` or `shell.run("gps", "host", x, y, z)`
- Uses the `"gps"` rednet protocol internally on channel 65534
- Returns world coordinates (absolute, not relative)
- See docs/patterns/gps-cluster.md for setup guide
