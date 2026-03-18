# pocket API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/pocket.html

API for pocket computers. Only available on pocket computer devices.

## Functions

### pocket.equipBack()
Search the player's inventory for an upgrade and equip it, replacing any existing upgrade.
- Returns: `boolean` success, `string|nil` error reason
- Notes: Searches starting from the player's currently selected inventory slot.

### pocket.unequipBack()
Remove the current back upgrade and return it to the player's inventory.
- Returns: `boolean` success, `string|nil` error reason

## Notes

- Only available on pocket computers — check with `if pocket then ... end`
- Pocket computers have one "back" upgrade slot (wireless modem, speaker, etc.)
- Default pocket computer comes with a wireless modem equipped
- Advanced pocket computers (gold) support colors
