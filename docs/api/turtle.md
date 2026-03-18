# turtle API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/turtle.html

The turtle API provides functions for turtle movement, block interaction, inventory management, fuel, and upgrades.

## Movement

### turtle.forward()
Move the turtle forward one block.
- Returns: `boolean` success, `string|nil` error reason

### turtle.back()
Move the turtle backwards one block.
- Returns: `boolean` success, `string|nil` error reason

### turtle.up()
Move the turtle up one block.
- Returns: `boolean` success, `string|nil` error reason

### turtle.down()
Move the turtle down one block.
- Returns: `boolean` success, `string|nil` error reason

### turtle.turnLeft()
Rotate the turtle 90 degrees to the left.
- Returns: `boolean` success, `string|nil` error reason

### turtle.turnRight()
Rotate the turtle 90 degrees to the right.
- Returns: `boolean` success, `string|nil` error reason

## Digging

### turtle.dig(side?)
Attempt to break the block in front of the turtle.
- Parameters: `side?`: `string` — optional tool side ("left" or "right")
- Returns: `boolean` success, `string|nil` error reason

### turtle.digUp(side?)
Attempt to break the block above the turtle.
- Parameters: `side?`: `string` — optional tool side
- Returns: `boolean` success, `string|nil` error reason

### turtle.digDown(side?)
Attempt to break the block below the turtle.
- Parameters: `side?`: `string` — optional tool side
- Returns: `boolean` success, `string|nil` error reason

## Placing

### turtle.place(text?)
Place a block or item in front of the turtle.
- Parameters: `text?`: `string` — optional text for signs
- Returns: `boolean` success, `string|nil` error reason

### turtle.placeUp(text?)
Place a block or item above the turtle.
- Parameters: `text?`: `string` — optional text for signs
- Returns: `boolean` success, `string|nil` error reason

### turtle.placeDown(text?)
Place a block or item below the turtle.
- Parameters: `text?`: `string` — optional text for signs
- Returns: `boolean` success, `string|nil` error reason

## Detection

### turtle.detect()
Check if there is a solid block in front of the turtle.
- Returns: `boolean`

### turtle.detectUp()
Check if there is a solid block above the turtle.
- Returns: `boolean`

### turtle.detectDown()
Check if there is a solid block below the turtle.
- Returns: `boolean`

## Inspection

### turtle.inspect()
Get information about the block in front of the turtle.
- Returns: `boolean` success, `table|string` — block info table or error message
- Block info: `{ name = "minecraft:stone", state = { ... }, tags = { ... } }`

### turtle.inspectUp()
Get information about the block above the turtle.
- Returns: `boolean` success, `table|string`

### turtle.inspectDown()
Get information about the block below the turtle.
- Returns: `boolean` success, `table|string`

## Comparison

### turtle.compare()
Check if the block in front matches the item in the selected slot.
- Returns: `boolean`

### turtle.compareUp()
Check if the block above matches the item in the selected slot.
- Returns: `boolean`

### turtle.compareDown()
Check if the block below matches the item in the selected slot.
- Returns: `boolean`

## Attack

### turtle.attack(side?)
Attack the entity in front of the turtle.
- Parameters: `side?`: `string` — optional tool side
- Returns: `boolean` success, `string|nil` error reason

### turtle.attackUp(side?)
Attack the entity above the turtle.
- Parameters: `side?`: `string`
- Returns: `boolean` success, `string|nil` error reason

### turtle.attackDown(side?)
Attack the entity below the turtle.
- Parameters: `side?`: `string`
- Returns: `boolean` success, `string|nil` error reason

## Inventory

### turtle.select(slot)
Change the currently selected slot.
- Parameters: `slot`: `number` — slot number (1–16)
- Returns: `true`
- Throws: if slot out of range

### turtle.getSelectedSlot()
Get the currently selected slot.
- Returns: `number` — current slot (1–16)

### turtle.getItemCount(slot?)
Get the number of items in a slot.
- Parameters: `slot?`: `number` — defaults to selected slot
- Returns: `number`
- Throws: if slot out of range

### turtle.getItemSpace(slot?)
Get the remaining space in a slot's stack.
- Parameters: `slot?`: `number` — defaults to selected slot
- Returns: `number`
- Throws: if slot out of range

### turtle.getItemDetail(slot?, detailed?)
Get detailed information about items in a slot.
- Parameters:
  - `slot?`: `number` — defaults to selected slot
  - `detailed?`: `boolean` — request extended info
- Returns: `table|nil` — item info or nil if empty
- Throws: if slot out of range

### turtle.compareTo(slot)
Compare the item in the selected slot to another slot.
- Parameters: `slot`: `number`
- Returns: `boolean`
- Throws: if slot out of range

### turtle.transferTo(slot, count?)
Move items from the selected slot to another slot.
- Parameters:
  - `slot`: `number` — destination slot
  - `count?`: `number` — max items to move
- Returns: `boolean`
- Throws: if slot or count out of range

## Drop / Suck

### turtle.drop(count?)
Drop items from the selected slot in front. Deposits into inventories.
- Parameters: `count?`: `number` — defaults to entire stack
- Returns: `boolean` success, `string|nil` error reason
- Throws: if invalid count

### turtle.dropUp(count?)
Drop items above the turtle.
- Parameters: `count?`: `number`
- Returns: `boolean` success, `string|nil` error reason

### turtle.dropDown(count?)
Drop items below the turtle.
- Parameters: `count?`: `number`
- Returns: `boolean` success, `string|nil` error reason

### turtle.suck(count?)
Pick up items from the inventory or ground in front.
- Parameters: `count?`: `number`
- Returns: `boolean` success, `string|nil` error reason
- Throws: if invalid count

### turtle.suckUp(count?)
Pick up items from above.
- Parameters: `count?`: `number`
- Returns: `boolean` success, `string|nil` error reason

### turtle.suckDown(count?)
Pick up items from below.
- Parameters: `count?`: `number`
- Returns: `boolean` success, `string|nil` error reason

## Fuel

### turtle.getFuelLevel()
Get the current fuel level.
- Returns: `number|"unlimited"`

### turtle.getFuelLimit()
Get the maximum fuel capacity.
- Returns: `number|"unlimited"`

### turtle.refuel(count?)
Refuel the turtle by consuming items from the selected slot.
- Parameters: `count?`: `number` — items to consume (pass 0 to check if item is valid fuel)
- Returns: `true` on success, or `false, string` on failure
- Throws: if count out of range

## Upgrades

### turtle.equipLeft()
Equip or unequip an item on the left side.
- Returns: `true` on success, or `false, string` error reason

### turtle.equipRight()
Equip or unequip an item on the right side.
- Returns: `true` on success, or `false, string` error reason

### turtle.getEquippedLeft()
Get the upgrade currently equipped on the left side.
- Returns: `table|nil` — upgrade info or nil if none

### turtle.getEquippedRight()
Get the upgrade currently equipped on the right side.
- Returns: `table|nil` — upgrade info or nil if none

## Crafting

### turtle.craft(limit?)
Craft a recipe using items in the turtle's inventory laid out like a crafting grid.
- Parameters: `limit?`: `number` — max items to craft (default 64)
- Returns: `true` on success, or `false, string` error reason
- Throws: if limit < 0 or > 64
- Notes: Requires a crafting table upgrade. Inventory slots map to a 3x3 grid:
  ```
  [1] [2] [3]
  [5] [6] [7]
  [9] [10][11]
  ```
  Slots 4, 8, 12–16 must be empty.
