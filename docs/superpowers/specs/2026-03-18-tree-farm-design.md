# Autonomous Oak Tree Farm — Design Spec

## Overview

A single crafty turtle autonomously farms oak (or birch) trees in a configurable grid layout. The turtle patrols the grid, harvests grown trees, collects dropped saplings, replants, self-fuels by crafting logs into planks, and persists state to survive chunk unloads and server restarts.

## Version Pins

- Minecraft: 1.21.1 (Forge)
- CC: Tweaked: 1.115.1
- Modpack: Direwolf20 1.21 (pack version 1.14.2)

## Key Assumptions

- **Instant leaf decay:** In this modpack, leaves decay instantly after the last log of a tree is removed, provided those leaves are not touching logs from an adjacent tree. This eliminates the need to wait for decay.
- **Oak/birch only:** 1x1 trunk trees. A ceiling at Y+8 above ground prevents oak from growing the large branching variant.
- **Sapling drop rate:** ~5% per leaf block, ~40-60 leaves per oak = 2-3 saplings per tree on average. With 4-block spacing, canopies don't overlap, preserving full sapling yield.

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
  |
 [W] [S]          W = Wood chest    S = Sapling chest
  [T] →            T = Turtle home (faces south into farm)
   .
   .  . . . P . . . . P . . . . P . . . . P     ← Row 1 (left to right)
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
Height 8:  [CEILING — solid blocks across entire farm]
Height 7:  (air — max leaf canopy)
Height 6:  (air — leaf canopy)
Height 5:  (air — leaf canopy)
Height 4:  (air — upper trunk / leaves)
Height 3:  (air — trunk)
Height 2:  (air — trunk)
Height 1:  (air — trunk base, turtle moves here)
Height 0:  [GROUND — dirt/grass, saplings planted here]
```

The ceiling at height 8 (7 air blocks above ground) prevents oak trees from growing the large variant with branches. Birch never branches regardless.

### Chest Placement

```
Side view from east:

     [W] [S]
      [T]
  ____ground____

W = Wood chest — placed one block above ground, to the LEFT of the turtle home
S = Sapling chest — placed one block above ground, to the RIGHT of the turtle home
T = Turtle home position — ground level, facing south
```

When at home position:
- Turtle drops LEFT → wood chest (logs, apples, sticks)
- Turtle drops RIGHT → sapling chest (excess saplings)
- Turtle sucks RIGHT → pull saplings from sapling chest when buffer is low

## Turtle Inventory Management

| Slot | Purpose | Behavior |
|------|---------|----------|
| 1 | Saplings (reserved) | Never dumped to wood chest. Topped up from sapling chest if low. Excess saplings dumped to sapling chest. |
| 2-14 | Harvested items | Logs, apples, sticks accumulate during patrol. All dumped to wood chest on return home. |
| 15 | Crafting buffer | Used when crafting logs → planks for fuel. |
| 16 | Fuel planks | Crafted planks for self-fueling. Consumed as needed. |

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

```
┌─────────────────────────────────────────┐
│              MAIN LOOP                  │
├─────────────────────────────────────────┤
│                                         │
│  1. Record patrol start time            │
│  2. Navigate to first tree position     │
│  3. For each position in snake order:   │
│     a. turtle.inspect() forward         │
│     b. If LOG detected:                 │
│        - Harvest (chop up, return down) │
│        - Suck patrol (collect drops)    │
│        - Replant sapling               │
│     c. If nothing / sapling:            │
│        - Skip, move to next position    │
│     d. Save state                       │
│  4. Return home                         │
│  5. Dump inventory to chests            │
│  6. Refuel if needed                    │
│  7. Calculate sleep time:               │
│     elapsed = os.clock() - patrol_start │
│     remaining = GROW_TIME - elapsed     │
│     if remaining > 0: os.sleep(remaining│
│  8. Repeat from 1                       │
│                                         │
└─────────────────────────────────────────┘
```

### Harvesting a Tree

1. Turtle is at ground level, facing the tree trunk
2. `turtle.dig()` — break the bottom log
3. `turtle.forward()` — move into trunk position
4. Loop: `turtle.digUp()` + `turtle.up()` until `turtle.inspectUp()` is not a log (hit air or ceiling)
5. Track height climbed
6. Loop: `turtle.down()` × height to return to ground
7. Leaves have already decayed instantly (modpack behavior) — items on ground

### Suck Patrol (Collecting Drops)

After harvesting, the turtle is standing where the trunk was at ground level. It sweeps a 3x3 area around the trunk base:

```
Step sequence (turtle starts at T, facing south):

    1 ← 2 ← 3
    ↓       ↑
    4   T   5        T = trunk base (start/end)
    ↓       ↑        Numbers = suck positions
    6 → 7 → 8

At each position: turtle.suck() + turtle.suckDown()
After sweep: return to trunk base position
```

The turtle executes `turtle.suck()` (picks up items in front at ground level) and `turtle.suckDown()` (picks up items below, in case ground is one block lower or items settled) at each of the 8 surrounding positions, then returns to the center.

### Replanting

After the suck patrol, the turtle is back at the trunk base position:
1. `turtle.back()` — step back to the walkway
2. `turtle.select(1)` — select sapling slot
3. `turtle.place()` — place sapling on the dirt/grass where the tree was

### Self-Fueling

When fuel level drops below a threshold (e.g., enough fuel for 2 full patrols):

1. Select a slot with logs (scan slots 2-14)
2. Transfer 1 log to slot 15 (crafting buffer)
3. `turtle.craft()` — 1 log → 4 planks (requires crafty turtle)
4. Transfer planks to slot 16
5. `turtle.select(16)` → `turtle.refuel()` — burn planks
6. Each plank = 15 fuel units, so 4 planks = 60 fuel (1 log worth)
7. Repeat until fuel is above threshold

Fuel cost estimate per tree:
- Travel between trees: ~5-8 moves (depending on spacing)
- Harvest climb/descend: ~14 moves (up 7, down 7)
- Suck patrol: ~12 moves (8 positions + returns)
- Total per tree: ~30-35 fuel units ≈ 1 plank

### Navigation

**Dead-reckoning:** The turtle tracks its position as an (row, col) index in the grid. Movement between positions is a fixed number of blocks (4 per spacing). No GPS needed.

**Snake pattern:**
- Row 1: left to right (cols 1, 2, 3, ...)
- Row 2: right to left (cols N, N-1, N-2, ...)
- Row 3: left to right
- ...alternating

**Coordinate tracking:**
- `pos.row` — current row (1-based)
- `pos.col` — current column (1-based)
- `pos.phase` — "traveling" | "harvesting" | "suck_patrol" | "returning" | "home"
- `pos.height` — blocks above ground (during harvest climb)

### State Persistence

State saved to file `farm_state` using `textutils.serialize()`:

```lua
{
  rows = 4,
  cols = 5,
  pos = { row = 2, col = 3, phase = "traveling", height = 0 },
  facing = "south",
  saplingCount = 12,
  fuelLevel = 1500,
  patrolStartTime = 1234567,
}
```

**When state is saved:**
- After arriving at each new tree position
- After completing a harvest
- After completing a suck patrol
- After returning home
- Before sleeping

**On resume after chunk reload:**
- Load state from file
- Determine current position and phase
- If mid-harvest (height > 0): continue chopping up or descending
- If mid-suck-patrol: restart the suck patrol from the beginning (safe to re-suck)
- If traveling: continue to next tree position
- If home/sleeping: start a new patrol

### Grow Time and Sleep

- Oak average grow time: ~3-5 minutes with adequate light and space
- Default `GROW_TIME = 240` seconds (4 minutes)
- After a patrol, the turtle calculates how long the patrol took and sleeps only the remaining time
- On a large farm (many trees), the patrol itself may exceed `GROW_TIME`, in which case the turtle skips sleep entirely and starts the next patrol immediately
- Timer starts when the turtle **leaves home**, so the first trees planted during a patrol have maximum grow time

### Error Handling

- **Movement blocked:** If `turtle.forward()` / `turtle.up()` fails, retry 3 times with a short delay. If still blocked (mob, player, falling block), skip current tree and move to next. Log the error.
- **Inventory full:** If inventory is full mid-patrol, return home early, dump, then resume from where it left off.
- **Out of saplings:** If slot 1 is empty and sapling chest is empty, continue patrol without replanting. Trees will still grow from previously planted saplings; sapling drops will replenish the supply over time.
- **Out of fuel:** If fuel is critically low and no logs available to craft, park at home position and wait. Print a message to the terminal: "Out of fuel — add logs or coal to inventory."
- **Chest full:** If wood chest is full (drop returns false), print warning but continue operating. Items stay in turtle inventory until next successful dump.

## Program Configuration

Set at first run, saved in state file:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rows` | Number of rows in the grid | (user input) |
| `cols` | Number of columns per row | (user input) |
| `GROW_TIME` | Seconds to wait between patrols | 240 |
| `FUEL_THRESHOLD` | Refuel when below this level | 500 |
| `SAPLING_MIN` | Pull from chest if below this count | 8 |
| `SPACING` | Blocks between tree positions | 4 |

## Build Instructions (Step-by-Step)

These are the in-game instructions for the player:

1. **Choose a flat area.** Clear the ground to a flat dirt/grass surface. Size needed: `(cols × 5 + 2)` blocks wide × `(rows × 5 + 2)` blocks deep.

2. **Place the turtle.** Put the crafty turtle on the ground at the north edge of the farm, facing south. This is the home position.

3. **Place chests.** Standing behind the turtle (facing same direction as turtle):
   - Place the **wood chest** one block to the turtle's LEFT (and one block up, level with turtle's side)
   - Place the **sapling chest** one block to the turtle's RIGHT (same height)

4. **Mark the grid.** From the turtle's home position, the first tree is 2 blocks forward (south). Then every 5 blocks (4 gap + 1 tree position) is the next column. Rows are spaced the same way (5 blocks apart). Place a sapling at each grid position.

5. **Build the ceiling.** Place solid blocks across the entire farm at height 8 (7 blocks above ground). This prevents large oak variants.

6. **Ensure lighting.** Place torches or glowstone on the ceiling to keep light level high. Saplings need light level ≥ 9 to grow. Also prevents mob spawns.

7. **Stock the turtle.** Put oak saplings in the turtle's inventory slot 1. Put a few logs or coal in any other slot for initial fuel.

8. **Stock the sapling chest.** Put a stack of oak saplings in the sapling chest as a bootstrap buffer.

9. **Install and run the program.** `pastebin get <code> treefarm` then `treefarm`.

10. **Enter grid size** when prompted (rows and columns).

## File Structure

Single file deployment: `src/turtle/treefarm.lua`

The program is self-contained for easy pastebin deployment. No external library dependencies.
