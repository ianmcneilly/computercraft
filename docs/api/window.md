# window API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/window.html

Create terminal redirect objects that render to a sub-area of a parent terminal.

## Constructor

### window.create(parent, nX, nY, nWidth, nHeight, bStartVisible?)
Create a new window.
- Parameters:
  - `parent`: `term.Redirect` — parent terminal to draw to
  - `nX`: `number` — x position in parent
  - `nY`: `number` — y position in parent
  - `nWidth`: `number` — window width
  - `nHeight`: `number` — window height
  - `bStartVisible?`: `boolean` — start visible (default true)
- Returns: `Window` — a terminal redirect object

## Window Methods

Windows implement all `term` API methods (`write`, `blit`, `clear`, `clearLine`, `scroll`, `getCursorPos`, `setCursorPos`, `getCursorBlink`, `setCursorBlink`, `getSize`, `setTextColour`, `getTextColour`, `setBackgroundColour`, `getBackgroundColour`, `isColour`, `setPaletteColour`, `getPaletteColour`), plus:

### window.getLine(y)
Get the contents and colors of a line.
- Parameters: `y`: `number` — line number
- Returns: `string` text, `string` textColors, `string` bgColors

### window.setVisible(visible)
Show or hide the window. Invisible windows don't render to the parent.
- Parameters: `visible`: `boolean`

### window.isVisible()
Check if the window is visible.
- Returns: `boolean`

### window.redraw()
Force redraw to the parent terminal.

### window.restoreCursor()
Sync the parent terminal's cursor position and blink state with this window's.

### window.getPosition()
Get the window's position in the parent terminal.
- Returns: `number` x, `number` y

### window.reposition(new_x, new_y, new_width?, new_height?, new_parent?)
Move and/or resize the window.
- Parameters:
  - `new_x`: `number`
  - `new_y`: `number`
  - `new_width?`: `number`
  - `new_height?`: `number`
  - `new_parent?`: `term.Redirect` — change parent terminal

## Notes

- Windows buffer their content — they retain rendered text even when invisible
- Each window maintains its own cursor state independently of the parent
- Windows are terminal redirect objects — usable with `term.redirect(win)`
- American spelling variants are available for all colour methods
