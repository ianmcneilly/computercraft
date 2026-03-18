# term API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/term.html

Interact with the computer's terminal — write text, control cursor, manage colors.

## Writing

### term.write(text)
Write text at the current cursor position, moving the cursor to the end.
- Parameters: `text`: `string`

### term.blit(text, textColour, backgroundColour)
Write text with per-character foreground and background colors.
- Parameters:
  - `text`: `string`
  - `textColour`: `string` — hex color string (same length as text, using blit codes 0–9, a–f)
  - `backgroundColour`: `string` — hex color string (same length as text)

## Cursor

### term.getCursorPos()
Get current cursor position.
- Returns: `number` x, `number` y

### term.setCursorPos(x, y)
Set the cursor position.
- Parameters: `x`: `number`, `y`: `number`

### term.getCursorBlink()
Check if the cursor is blinking.
- Returns: `boolean`

### term.setCursorBlink(blink)
Enable or disable cursor blinking.
- Parameters: `blink`: `boolean`

## Screen

### term.getSize()
Get the terminal dimensions.
- Returns: `number` width, `number` height

### term.clear()
Clear the entire terminal with the current background color.

### term.clearLine()
Clear the current line with the current background color.

### term.scroll(y)
Scroll the terminal content.
- Parameters: `y`: `number` — lines to scroll (positive = up, negative = down)

## Colors

### term.setTextColour(colour)
Set the text (foreground) color.
- Parameters: `colour`: `number` — a `colors.*` constant
- Aliases: `setTextColor`

### term.getTextColour()
Get the current text color.
- Returns: `number`
- Aliases: `getTextColor`

### term.setBackgroundColour(colour)
Set the background color.
- Parameters: `colour`: `number` — a `colors.*` constant
- Aliases: `setBackgroundColor`

### term.getBackgroundColour()
Get the current background color.
- Returns: `number`
- Aliases: `getBackgroundColor`

### term.isColour()
Check if this terminal supports color.
- Returns: `boolean`
- Aliases: `isColor`

## Palette

### term.setPaletteColour(index, colour)
### term.setPaletteColour(index, r, g, b)
Set the RGB value for a palette color.
- Parameters:
  - `index`: `number` — `colors.*` constant
  - `colour`: `number` — packed RGB hex value, OR
  - `r, g, b`: `number` — RGB values 0.0–1.0
- Aliases: `setPaletteColor`

### term.getPaletteColour(colour)
Get the RGB values for a palette color.
- Parameters: `colour`: `number` — `colors.*` constant
- Returns: `number` r, `number` g, `number` b — each 0.0–1.0
- Aliases: `getPaletteColor`

### term.nativePaletteColour(colour)
Get the default (original) palette value for a color.
- Parameters: `colour`: `number`
- Returns: `number` r, `number` g, `number` b
- Aliases: `nativePaletteColor`

## Redirection

### term.redirect(target)
Redirect terminal output to another target (monitor, window, etc.).
- Parameters: `target`: `Redirect` — the terminal redirect object
- Returns: `Redirect` — the previous redirect target

### term.current()
Get the current terminal object.
- Returns: `Redirect`

### term.native()
Get the native (original) terminal object of this computer.
- Returns: `Redirect`

## Notes

- All coordinates are 1-based (top-left is 1,1)
- American spelling variants (`Color` instead of `Colour`) are available for all color functions
- Blit codes: `0`=white, `1`=orange, `2`=magenta, ..., `f`=black (matches `colors.toBlit()`)
- Advanced computers support 16 colors; basic computers only black and white
