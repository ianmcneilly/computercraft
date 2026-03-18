# colors API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/colors.html

Color constants and utility functions. Used with `term`, monitors, and bundled cables.

## Color Constants

| Constant | Value | Blit Code | Default Color |
|----------|-------|-----------|---------------|
| `colors.white` | 1 | `"0"` | #F0F0F0 |
| `colors.orange` | 2 | `"1"` | #F2B233 |
| `colors.magenta` | 4 | `"2"` | #E57FD8 |
| `colors.lightBlue` | 8 | `"3"` | #99B2F2 |
| `colors.yellow` | 16 | `"4"` | #DEDE6C |
| `colors.lime` | 32 | `"5"` | #7FCC19 |
| `colors.pink` | 64 | `"6"` | #F2B2CC |
| `colors.gray` | 128 | `"7"` | #4C4C4C |
| `colors.lightGray` | 256 | `"8"` | #999999 |
| `colors.cyan` | 512 | `"9"` | #4C99B2 |
| `colors.purple` | 1024 | `"a"` | #B266E5 |
| `colors.blue` | 2048 | `"b"` | #3366CC |
| `colors.brown` | 4096 | `"c"` | #7F664C |
| `colors.green` | 8192 | `"d"` | #57A64E |
| `colors.red` | 16384 | `"e"` | #CC4C4C |
| `colors.black` | 32768 | `"f"` | #111111 |

## Functions

### colors.combine(...)
Combine multiple colors into a color set (bitwise OR).
- Parameters: `...`: `number` — color values
- Returns: `number` — combined bitmask

### colors.subtract(colors, ...)
Remove colors from a color set.
- Parameters: `colors`: `number` — base set, `...`: `number` — colors to remove
- Returns: `number`

### colors.test(colors, color)
Check if a color set contains a specific color.
- Parameters: `colors`: `number` — set to test, `color`: `number` — color to check
- Returns: `boolean`

### colors.packRGB(r, g, b)
Convert RGB values to a packed hex number.
- Parameters: `r, g, b`: `number` — each 0.0–1.0
- Returns: `number`

### colors.unpackRGB(rgb)
Convert a packed hex number to RGB values.
- Parameters: `rgb`: `number`
- Returns: `number` r, `number` g, `number` b — each 0.0–1.0

### colors.toBlit(color)
Convert a color constant to its blit character (0–9, a–f).
- Parameters: `color`: `number`
- Returns: `string` — single hex character

### colors.fromBlit(hex)
Convert a blit hex character to a color constant.
- Parameters: `hex`: `string` — single hex character
- Returns: `number`

## Deprecated

### colors.rgb8(...)
Use `packRGB`/`unpackRGB` instead.

## Notes

- Color values are powers of 2 — use `colors.combine()` for bitmask operations
- `colours` is a British spelling alias for the entire module
- Blit codes are used with `term.blit()` for per-character coloring
- Basic computers only support `colors.white` and `colors.black`
- Advanced computers support all 16 colors with customizable palettes
