# Autonomous Oak Tree Farm — Design Spec

## Overview

A single crafty turtle autonomously farms oak (or birch) trees in a configurable grid layout. The turtle patrols the grid, harvests grown trees, collects dropped saplings, replants, self-fuels by crafting logs into planks, and persists state to survive chunk unloads and server restarts.

## Version Pins

- Minecraft: 1.21.1 (Forge)
- CC: Tweaked: 1.115.1
- Modpack: Direwolf20 1.21 (pack version 1.14.2)

## Key Assumptions

- **Instant leaf decay:** In this modpack, leaves decay instantly after the last log of a tree is removed, provided those leaves are not touching logs from an adjacent tree. This eliminates the need to wait for decay.
- **Oak/birch only:** 1x1 trunk trees. A ceiling prevents oak from growing the large branching variant.
- **Sapling drop rate:** ~5% per leaf block, ~40-60 leaves per oak = 2-3 saplings per tree on average. With 4-block spacing, canopies don't overlap, preserving full sapling yield.
- **Ceiling height:** 6 air blocks above ground (ceiling at Y+7). Large oak needs 7+ air blocks to form branches — capping at 6 reliably prevents this. Must be verified in-game; adjust to Y+8 if normal oaks fail to grow at Y+7.

## Physical Build

### Required Materials

- 1x Crafty Turtle (turtle + crafting table)
- 1x Chest (wood/output)
- 1x Chest (sapling buffer)
- Dirt/grass blocks for the farm floor (saplings must be planted on dirt/grass)
- Building blocks for ceiling (any solid block)
- Oak saplings to bootstrap (1 per planting position + a few extra)
- Fuel to bootstrap the turtle (a few coal or logs for the first run)

### Layout (Top-Down View)

```
Facing: Turtle faces SOUTH (into the farm)
Grid: Configurable ROWS x COLS at program startup

        North
          ↑
     [W] [T] [S]       W = Wood chest (WEST of turtle)
          |             S = Sapling chest (EAST of turtle)
          |             T = Turtle home (faces south)
          ↓ (4 blocks south to first tree)
     . . .P . . . . P . . . . P . . . . P     ← Row 1 (left to right)
                                          |
          P . . . . P . . . . P . . . . P     ← Row 2 (right to left)
          |
          P . . . . P . . . . P . . . . P     ← Row 3 (left to right)
                                          |
          ...continues for configured rows...

P = Planting position (sapling goes here)
. = Air / walkway (ground level is dirt/grass)

Spacing: 4 blocks between planting positions (both axes)
```

### Side View

```
Height 7:  [CEILING — solid blocks across entire farm]
Height 6:  (air — max leaf canopy)
Height 5:  (air — leaf canopy)
Height 4:  (air — upper trunk / leaves)
Height 3:  (air — trunk)
Height 2:  (air — trunk)
Height 1:  (air — trunk base, turtle moves here)
Height 0:  [GROUND — dirt/grass, saplings planted here]
```

The ceiling at height 7 (6 air blocks above ground) prevents oak trees from growing the large branching variant. Birch never branches regardless. If normal oaks fail to grow at this height, raise the ceiling to height 8 and test again.

### Chest Placement

```
Top-down view (turtle faces south):

        North
          ↑
     [W] [T] [S]
          |
          ↓ South (into farm)

W = Wood chest — WEST of turtle (turtle's RIGHT when facing south)
S = Sapling chest — EAST of turtle (turtle's LEFT when facing south)
T = Turtle home position — ground level, facing south

All three blocks are at ground level.
```

**Dump procedure at home (turtle facing south):**
1. `turtle.turnRight()` → now facing west (wood chest)
2. Dump logs/apples/sticks via `turtle.drop()`
3. `turtle.turnRight()` + `turtle.turnRight()` → now facing east (sapling chest)
4. Dump excess saplings via `turtle.drop()`
5. If saplings low, `turtle.suck()` from sapling chest
6. `turtle.turnRight()` → restored to facing south (east → turnRight → south)

## Turtle Inventory Management

**Crafting grid constraint:** The crafty turtle's 3x3 crafting grid maps to inventory slots 1, 2, 3, 5, 6, 7, 9, 10, 11. Slots 4, 8, 12, 13, 14, 15, 16 are NOT part of the grid. To call `turtle.craft()`, all non-recipe grid slots must be empty, and all non-grid slots (4, 8, 12-16) must also be empty or contain items that won't interfere.

**Design decision:** Crafting only happens at home AFTER dumping inventory to chests. This avoids complex mid-patrol inventory juggling. The procedure is:

1. Dump all items to chests (inventory is mostly empty)
2. Keep saplings in slot 1
3. Move 1 log into slot 2 (a grid slot)
4. Ensure all other grid slots are empty
5. `turtle.craft()` → 4 planks appear in first available slot
6. `turtle.refuel()` on the planks

**Slot usage during patrol:**

| Slots | Purpose | Notes |
|-------|---------|-------|
| 1 | Saplings (reserved) | Never dumped to wood chest. |
| 2-16 | Harvested items | Logs, apples, sticks, saplings accumulate freely. |

No rigid slot assignments during patrol — items go wherever there's space. Sorting happens only at home during the dump phase.

**Dump phase sorting (at home, using `turtle.getItemDetail()`):**
1. Scan slots 2-16
2. If item is a sapling → consolidate into slot 1, dump excess to sapling chest
3. If item is anything else → dump to wood chest

## Program Behavior

### Startup

1. Check for saved state file (`farm_state`)
   - If exists: load state, resume from saved position and phase
   - If not: prompt user for grid dimensions (rows, cols), initialize state
2. Verify inventory: check sapling count in slot 1
   - If low and sapling chest is accessible, pull saplings
3. Check fuel level, refuel if below threshold
4. Begin main loop

### Main Loop

The entire main loop is wrapped in `xpcall` for graceful error handling. On unexpected error, the handler saves state and prints a diagnostic before exiting.

```
┌──────────────────────────────────────────────┐
│              MAIN LOOP                       │
├──────────────────────────────────────────────┤
│                                              │
│  1. Record patrol start time (os.epoch)      │
│  2. Navigate to first tree position          │
│  3. For each position in snake order:        │
│     a. turtle.inspect() forward              │
│     b. If LOG detected:                      │
│        - Harvest (chop up, return down)      │
│        - Suck patrol (collect drops)         │
│        - Replant sapling                     │
│     c. If nothing / sapling:                 │
│        - Skip, move to next position         │
│     d. Save state                            │
│     e. If inventory full, return home early  │
│  4. Return home                              │
│  5. Sort and dump inventory to chests        │
│  6. Refuel if needed (craft at home)         │
│  7. Calculate sleep time:                    │
│     elapsed = os.epoch("utc") - patrol_start │
│     remaining = GROW_TIME_MS - elapsed       │
│     if remaining > 0: os.sleep(remaining/1000│
│  8. Repeat from 1                            │
│                                              │
└──────────────────────────────────────────────┘
```

### Harvesting a Tree

1. Turtle is at ground level, one block back from the tree, facing the tree trunk
2. `turtle.dig()` — break the bottom log
3. `turtle.forward()` — move into trunk position
4. Save state: `phase = "harvesting_up", height = 0`
5. Loop: `turtle.inspectUp()` → if log, `turtle.digUp()` + `turtle.up()`, increment height, save state
6. When `turtle.inspectUp()` is not a log (air or ceiling): switch to descending
7. Save state: `phase = "harvesting_down"`
8. Loop: `turtle.down()` × height to return to ground, decrement height each step
9. Leaves have already decayed instantly (modpack behavior) — items are on ground

**Resume behavior:**
- `harvesting_up`: re-enter the dig-up loop. `turtle.inspectUp()` naturally stops at air/ceiling.
- `harvesting_down`: descend `height` blocks to reach ground.

### Suck Patrol (Collecting Drops)

After harvesting, the turtle is standing where the trunk was at ground level, facing south (original facing preserved during harvest since it only went up/down).

First, collect items at the center: `turtle.suckDown()` and `turtle.suck()` in current facing direction.

Then sweep a ring around the trunk base. The turtle does a simple box sweep:

```
Movement sequence (starts and ends at center, facing south):

1. turtle.suckDown() at center
2. Forward, suck + suckDown          (south)
3. Turn left, forward, suck + suckDown (east-ish)
4. Turn left, forward, suck + suckDown (north)
5. Forward, suck + suckDown           (north)
6. Turn left, forward, suck + suckDown (west)
7. Forward, suck + suckDown           (west)
8. Turn left, forward, suck + suckDown (south)
9. Forward → back to center
10. Turn left twice to face south again (if needed)

Simplified: walk a square around the trunk, suck at each step.
```

At each position: `turtle.suck()` + `turtle.suckDown()` to collect items at and below foot level.

**Resume behavior:** If interrupted mid-suck-patrol, the safest recovery is to abandon the current patrol cycle and return home. Items left on the ground will be picked up on the next full patrol. The suck patrol is at most 8 moves — not worth complex sub-position tracking.

### Replanting

After the suck patrol, the turtle is back at the trunk base position, facing south:
1. Turn 180 (face north, toward home): `turtle.turnLeft()` + `turtle.turnLeft()`
2. `turtle.forward()` — step back to the walkway (uses forward, not back, so we can dig if blocked)
3. Turn 180 again to face south (toward the tree spot): `turtle.turnLeft()` + `turtle.turnLeft()`
4. `turtle.select(1)` — select sapling slot
5. `turtle.place()` — place sapling on the dirt/grass where the tree was

Note: `turtle.forward()` is used instead of `turtle.back()` because `turtle.back()` cannot dig through obstructions. By turning and moving forward, the turtle can `turtle.dig()` + retry if blocked.

### Self-Fueling

Crafting happens ONLY at home after dumping inventory to chests. This ensures the crafting grid slots are clear.

1. Check fuel level against `FUEL_THRESHOLD`
2. If low, scan inventory for logs (check `turtle.getItemDetail()` for `minecraft:oak_log` etc.)
3. If no logs in inventory but logs in wood chest: turn to face west (wood chest), `turtle.suck()` one log
4. Dump saplings from slot 1 to sapling chest: turn to face east, `turtle.drop()` from slot 1
5. Move 1 log to slot 2 (a crafting grid slot), ensure ALL other slots are empty (slots 4, 8, 12-16 must be empty per `turtle.craft()` API)
6. `turtle.select(2)` → `turtle.craft()` — 1 log → 4 planks in first available slot
7. Select the planks slot → `turtle.refuel()` — 4 planks = 60 fuel
8. Pull saplings back: turn to face east (sapling chest), `turtle.suck()` to refill slot 1
9. Restore facing to south
10. Repeat from step 1 until fuel is above threshold

Fuel cost estimate per tree:
- Travel between trees: ~5-8 moves
- Harvest climb/descend: ~12 moves (up 6, down 6 with capped ceiling)
- Suck patrol: ~10 moves (ring sweep)
- Total per tree: ~25-30 fuel units ≈ 1 plank (15 fuel each)

### Navigation

**Dead-reckoning:** The turtle tracks its position as an (row, col) index in the grid. Movement between positions is a fixed number of blocks (spacing between trees). No GPS needed.

**Snake pattern:**
- Row 1: left to right (cols 1, 2, 3, ...)
- Row 2: right to left (cols N, N-1, N-2, ...)
- Row 3: left to right
- ...alternating

**Coordinate tracking:**
- `pos.row` — current row (1-based)
- `pos.col` — current column (1-based)
- `pos.phase` — "home" | "traveling" | "harvesting_up" | "harvesting_down" | "suck_patrol" | "returning"
- `pos.height` — blocks above ground (during harvest)
- `pos.facing` — "north" | "south" | "east" | "west"

**Turning:** `turtle.turnLeft()` and `turtle.turnRight()` always return true under normal CC:T conditions. The facing direction is updated after each turn call.

### State Persistence

State saved to file `farm_state` using `textutils.serialize()`:

```lua
{
  rows = 4,
  cols = 5,
  pos = {
    row = 2,
    col = 3,
    phase = "traveling",
    height = 0,
    facing = "south",
  },
  patrolStartTime = 1710000000000,  -- os.epoch("utc") milliseconds
}
```

**When state is saved:**
- After arriving at each new tree position
- After starting a harvest (phase change)
- After each height change during harvest
- After completing a harvest
- After returning home
- Before sleeping

**On resume after chunk reload:**
- Load state from file
- Determine current position and phase
- If `harvesting_up`: re-enter chop-up loop (inspectUp handles stopping)
- If `harvesting_down`: descend `height` blocks to ground
- If `suck_patrol`: abandon suck patrol, return home, start fresh patrol
- If `traveling`: continue to next tree position
- If `home`: skip remaining sleep, start a new patrol (trees likely had time to grow while chunk was unloaded)
- If `returning`: continue return-to-home navigation

### Grow Time and Sleep

- Oak average grow time: ~3-5 minutes with adequate light and space
- Default `GROW_TIME = 240000` milliseconds (4 minutes)
- Timing uses `os.epoch("utc")` which returns wall-clock milliseconds and survives computer restarts (unlike `os.clock()` which resets)
- After a patrol, the turtle calculates elapsed time and sleeps only the remainder
- On a large farm (many trees), the patrol itself may exceed `GROW_TIME`, in which case the turtle skips sleep entirely
- Timer starts when the turtle **leaves home**, so the first trees planted during a patrol have maximum grow time

### Error Handling

The main loop is wrapped in `xpcall`. On unexpected error, the handler saves current state to disk and prints the error traceback to the terminal before exiting.

- **Movement blocked:** If `turtle.forward()` / `turtle.up()` / `turtle.down()` fails, retry 3 times with a short `os.sleep(1)` delay. If still blocked (mob, player, falling block), skip current tree and move to next. Print warning.
- **Inventory full:** If inventory is full mid-patrol, return home early, dump, then resume from saved position.
- **Out of saplings:** If slot 1 is empty and sapling chest is empty, continue patrol without replanting. Sapling drops from future harvests will replenish supply.
- **Out of fuel:** If fuel is critically low and no logs available to craft, park at home position and wait. Print: "Out of fuel — add logs or coal to inventory." Enter a polling loop checking for fuel items periodically.
- **Chest full:** If `turtle.drop()` returns false, print warning but continue operating. Items stay in turtle inventory until next successful dump.

## Program Configuration

Set at first run, saved in state file:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rows` | Number of rows in the grid | (user input) |
| `cols` | Number of columns per row | (user input) |
| `GROW_TIME` | Milliseconds to wait between patrols | 240000 |
| `FUEL_THRESHOLD` | Refuel when below this level | 500 |
| `SAPLING_MIN` | Pull from chest if below this count | 8 |
| `SPACING` | Blocks between tree positions | 4 |

## Build Instructions (Step-by-Step)

These are the in-game instructions for the player:

1. **Choose a flat area.** Clear the ground to a flat dirt/grass surface. Size needed: `((cols - 1) × 5 + 1)` blocks wide (east-west) × `(4 + (rows - 1) × 5 + 1)` blocks deep (north-south). Example: 4 cols × 3 rows = 16 wide × 15 deep.

2. **Place the turtle.** Put the crafty turtle on the ground at the north edge of the farm, centered on the grid, facing south. This is the home position.

3. **Place chests.** Standing behind the turtle (looking south):
   - Place the **wood chest** one block to the WEST of the turtle (turtle's right when facing south), at ground level
   - Place the **sapling chest** one block to the EAST of the turtle (turtle's left when facing south), at ground level

4. **Mark the grid.** From the turtle's home position:
   - The first tree (row 1, col 1) is **4 blocks south** and aligned with the turtle's column
   - Subsequent columns in the same row are **5 blocks apart** east-west (4 gap + 1 position)
   - Subsequent rows are **5 blocks apart** north-south
   - Place a sapling at each grid position on dirt/grass

5. **Build the ceiling.** Place solid blocks across the entire farm at **7 blocks above ground** (6 air blocks of clearance). This prevents large oak variants. If normal oaks also fail to grow, raise to 8 blocks above ground and re-test.

6. **Ensure lighting.** Place torches or glowstone on the ceiling to keep light level ≥ 9. Also prevents mob spawns inside the farm.

7. **Stock the turtle.** Put oak saplings in the turtle's inventory (any slot). Put a few logs or coal in any other slot for initial fuel.

8. **Stock the sapling chest.** Put a stack of oak saplings in the sapling chest as a bootstrap buffer.

9. **Install and run the program.** `pastebin get <code> treefarm` then `treefarm`.

10. **Enter grid size** when prompted (rows and columns).

### Auto-Restart on Chunk Reload

To make the farm resume automatically after chunk unloads or server restarts, create a `startup.lua` file on the turtle:

```
shell.run("treefarm")
```

Or simply name the program `startup` instead of `treefarm`. The state persistence system handles resuming from the correct position.

## File Structure

Single file deployment: `src/turtle/treefarm.lua`

The program is self-contained for easy pastebin deployment. No external library dependencies.
