-- treefarm: Autonomous oak/birch tree farm
-- Usage: treefarm <rows> <cols>
-- Place wood chest to WEST, sapling chest to EAST of turtle.
-- Turtle faces SOUTH into the farm. See design spec for build layout.

-------------------------------
-- Constants
-------------------------------

local SPACING = 4          -- blocks between tree positions
local GROW_TIME = 240      -- seconds to wait between patrols
local FUEL_THRESHOLD = 500 -- refuel when below this
local SAPLING_MIN = 8      -- pull from chest if below this count
local HOME_TO_FIRST = 4    -- blocks from home to first tree position
local MAX_RETRIES = 10     -- movement retry attempts
local SAPLING_SLOT = 1     -- reserved slot for saplings
local STATE_FILE = "farm_state"

-------------------------------
-- Facing directions
-------------------------------

local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
local FACING_NAMES = { [0] = "north", "east", "south", "west" }
local FACING_DX = { [NORTH] = 0, [EAST] = 1, [SOUTH] = 0, [WEST] = -1 }
local FACING_DZ = { [NORTH] = -1, [EAST] = 0, [SOUTH] = 1, [WEST] = 0 }

-------------------------------
-- State
-------------------------------

local state = nil -- loaded or initialized in startup

-------------------------------
-- Argument parsing
-------------------------------

local args = { ... }

local function printUsage()
    print("treefarm: Autonomous oak/birch tree farm")
    print()
    print("Usage: treefarm <rows> <cols>")
    print("  rows = number of rows (north-south)")
    print("  cols = number of columns (east-west)")
    print()
    print("First run: provide dimensions.")
    print("Subsequent runs: resumes from saved state.")
end

-------------------------------
-- State persistence
-------------------------------

local function saveState()
    local f = fs.open(STATE_FILE, "w")
    if not f then
        print("Warning: failed to save state")
        return
    end
    f.write(textutils.serialize(state))
    f.close()
end

local function loadState()
    if fs.exists(STATE_FILE) then
        local f = fs.open(STATE_FILE, "r")
        local data = f.readAll()
        f.close()
        local s = textutils.unserialize(data)
        if s and s.pos and s.rows and s.cols then
            return s
        end
        print("Warning: corrupt state file, starting fresh")
    end
    return nil
end

local function initState(rows, cols)
    return {
        rows = rows,
        cols = cols,
        pos = {
            row = 0,
            col = 0,
            phase = "home",
            height = 0,
            facing = SOUTH,
        },
        patrolStartTime = 0,
    }
end

-------------------------------
-- Movement primitives
-------------------------------

local function turnLeft()
    turtle.turnLeft()
    state.pos.facing = (state.pos.facing - 1) % 4
end

local function turnRight()
    turtle.turnRight()
    state.pos.facing = (state.pos.facing + 1) % 4
end

local function face(dir)
    local diff = (dir - state.pos.facing) % 4
    if diff == 1 then
        turnRight()
    elseif diff == 2 then
        turnRight()
        turnRight()
    elseif diff == 3 then
        turnLeft()
    end
end

-- Wait for player to add fuel — last resort when completely out
local function waitForFuel()
    if turtle.getFuelLevel() == "unlimited" then return end
    if turtle.getFuelLevel() > 0 then return end

    print()
    print("*** OUT OF FUEL ***")
    print("Add logs or coal to the turtle inventory.")
    print("Waiting...")

    while turtle.getFuelLevel() == 0 do
        sleep(5)
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                if turtle.refuel(0) then
                    turtle.refuel()
                end
            end
        end
    end

    turtle.select(SAPLING_SLOT)
    print("Refueled! Fuel: " .. turtle.getFuelLevel())
end

local function tryForward()
    for _ = 1, MAX_RETRIES do
        local ok, err = turtle.forward()
        if ok then return true end
        if err == "Out of fuel" then
            waitForFuel()
        else
            turtle.dig()
            turtle.attack()
            sleep(0.5)
        end
    end
    return false, "blocked"
end

local function tryUp()
    for _ = 1, MAX_RETRIES do
        local ok, err = turtle.up()
        if ok then return true end
        if err == "Out of fuel" then
            waitForFuel()
        else
            turtle.digUp()
            turtle.attackUp()
            sleep(0.5)
        end
    end
    return false, "blocked"
end

local function tryDown()
    for _ = 1, MAX_RETRIES do
        local ok, err = turtle.down()
        if ok then return true end
        if err == "Out of fuel" then
            waitForFuel()
        else
            turtle.digDown()
            turtle.attackDown()
            sleep(0.5)
        end
    end
    return false, "blocked"
end

-------------------------------
-- Navigation
-------------------------------

-- Convert grid position (row, col) to block offsets from home
-- Home = (0, 0) in block coords
-- Row 1, Col 1 = (HOME_TO_FIRST south, 0 east) — first column aligns with home
-- Note: chunk unload during travel can desync position. No GPS fallback.
local function gridToBlocks(row, col)
    local z = HOME_TO_FIRST + (row - 1) * (SPACING + 1)
    local x = (col - 1) * (SPACING + 1)
    return x, z
end

-- Get next tree position in snake pattern
-- Returns row, col or nil if patrol is complete
local function nextTreePos(row, col)
    local isLeftToRight = (row % 2) == 1

    if isLeftToRight then
        if col < state.cols then
            return row, col + 1
        end
    else
        if col > 1 then
            return row, col - 1
        end
    end

    -- End of row — move to next row
    if row < state.rows then
        local nextRow = row + 1
        local nextCol
        if nextRow % 2 == 1 then
            nextCol = 1
        else
            nextCol = state.cols
        end
        return nextRow, nextCol
    end

    return nil, nil -- patrol complete
end

-- Navigate to the walkway position for a tree (one block NORTH of the tree).
-- The turtle stands in the walkway and faces south to interact with the tree.
-- Uses dead reckoning — chunk unload or external movement will desync
-- the turtle's tracked position. No GPS fallback is implemented.
local function navigateToTree(row, col)
    local targetX, targetZ = gridToBlocks(row, col)
    local walkwayZ = targetZ - 1  -- stand one block north of tree

    local currentX, currentZ
    if state.pos.row == 0 and state.pos.col == 0 then
        currentX, currentZ = 0, 0  -- home position
    else
        local cx, cz = gridToBlocks(state.pos.row, state.pos.col)
        currentX, currentZ = cx, cz - 1  -- walkway of current tree
    end

    local dx = targetX - currentX
    local dz = walkwayZ - currentZ

    if dz > 0 then
        -- Moving south. Path may cross tree positions where saplings sit.
        -- Move east/west first (at current walkway z, always safe), then
        -- move south with sapling detection: if we hit a sapling, dig
        -- through it, step one more south to clear the spot, turn around
        -- and replant it, then continue. No sidestep needed.
        if dx > 0 then
            face(EAST)
            for _ = 1, dx do
                if not tryForward() then return false end
            end
        elseif dx < 0 then
            face(WEST)
            for _ = 1, -dx do
                if not tryForward() then return false end
            end
        end

        face(SOUTH)
        local step = 0
        while step < dz do
            -- Check if next block is a sapling we need to preserve
            local needReplant = false
            local ok, data = turtle.inspect()
            if ok and data.name and string.find(data.name, "sapling") then
                needReplant = true
            end

            if not tryForward() then return false end
            step = step + 1

            if needReplant and step < dz then
                -- Move one more step south to clear the sapling position
                if not tryForward() then return false end
                step = step + 1
                -- Turn around and replant
                face(NORTH)
                if turtle.getItemCount(SAPLING_SLOT) > 0 then
                    turtle.select(SAPLING_SLOT)
                    turtle.place()
                end
                face(SOUTH)
            end
        end
    else
        -- Same row or moving north — no tree positions in the way
        if dx > 0 then
            face(EAST)
            for _ = 1, dx do
                if not tryForward() then return false end
            end
        elseif dx < 0 then
            face(WEST)
            for _ = 1, -dx do
                if not tryForward() then return false end
            end
        end

        if dz < 0 then
            face(NORTH)
            for _ = 1, -dz do
                if not tryForward() then return false end
            end
        end
    end

    state.pos.row = row
    state.pos.col = col
    return true
end

local function returnHome()
    state.pos.phase = "returning"
    saveState()

    if state.pos.row == 0 and state.pos.col == 0 then
        face(SOUTH)
        return true
    end

    -- Navigate back to home (0, 0) from walkway position
    local treeX, treeZ = gridToBlocks(state.pos.row, state.pos.col)
    local currentX = treeX
    local currentZ = treeZ - 1  -- turtle is at walkway, one block north of tree

    -- Move west to x=0
    if currentX > 0 then
        face(WEST)
        for i = 1, currentX do
            if not tryForward() then return false end
        end
    end

    -- Move north to z=0
    if currentZ > 0 then
        face(NORTH)
        for i = 1, currentZ do
            if not tryForward() then return false end
        end
    end

    state.pos.row = 0
    state.pos.col = 0
    face(SOUTH)
    state.pos.phase = "home"
    saveState()
    return true
end

-------------------------------
-- Tree detection & harvesting
-------------------------------

local function isLog(inspectFn)
    local ok, data = inspectFn()
    if not ok then return false end
    -- Match any log block (oak, birch, spruce, etc.)
    return data and data.name and string.find(data.name, "log")
end

local function isSapling(inspectFn)
    local ok, data = inspectFn()
    if not ok then return false end
    return data and data.name and string.find(data.name, "sapling")
end

local function harvestTree()
    -- Turtle is one block back from tree, facing the tree
    -- Step 1: dig bottom log and move into trunk
    turtle.dig()
    if not tryForward() then return false end

    -- Step 2: dig upward
    state.pos.phase = "harvesting_up"
    state.pos.height = 0
    saveState()

    while isLog(turtle.inspectUp) do
        turtle.digUp()
        if not tryUp() then break end
        state.pos.height = state.pos.height + 1
        saveState()
    end

    -- Step 3: descend back to ground
    state.pos.phase = "harvesting_down"
    saveState()

    while state.pos.height > 0 do
        if not tryDown() then break end
        state.pos.height = state.pos.height - 1
        saveState()
    end

    return true
end

-------------------------------
-- Suck patrol
-------------------------------

local function suckHere()
    turtle.suck()
    turtle.suckDown()
    turtle.suckUp()
end

local function suckPatrol()
    -- Note: suck patrol moves the turtle in a 3x3 area around the trunk.
    -- If interrupted, position will be slightly desynced. Resume logic
    -- handles this by abandoning the patrol and returning home.
    state.pos.phase = "suck_patrol"
    saveState()

    -- Turtle is at trunk base, facing south
    -- First, suck at center
    suckHere()

    -- Walk a box: south, turn left (east), north x2, turn left (west),
    -- south x2, arrive back near start

    -- South 1
    tryForward()
    suckHere()

    -- Turn left, go east 1
    turnLeft()
    tryForward()
    suckHere()

    -- Turn left, go north 1
    turnLeft()
    tryForward()
    suckHere()

    -- North 1 more
    tryForward()
    suckHere()

    -- Turn left, go west 1
    turnLeft()
    tryForward()
    suckHere()

    -- West 1 more
    tryForward()
    suckHere()

    -- Turn left, go south 1
    turnLeft()
    tryForward()
    suckHere()

    -- South 1 more — back to starting row, west column
    tryForward()
    suckHere()

    -- Now at (south+1, west-1) from center — move back to center
    -- Turn left (now facing east), forward 1 = center column
    turnLeft()
    tryForward()

    -- Turn left (now facing north), forward 1 = center row
    turnLeft()
    tryForward()

    -- Now at center, facing north — face south to restore
    turnRight()
    turnRight()

    return true
end

-------------------------------
-- Replanting
-------------------------------

local function replant()
    -- Turtle is at trunk base, facing south
    -- Step back to walkway: turn north, move forward, turn back south
    face(NORTH)
    tryForward()
    face(SOUTH)

    -- Place sapling if we have any
    local count = turtle.getItemCount(SAPLING_SLOT)
    if count > 0 then
        turtle.select(SAPLING_SLOT)
        turtle.place()
    end
end

-------------------------------
-- Inventory management
-------------------------------

local function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

local function isSaplingItem(slot)
    local detail = turtle.getItemDetail(slot)
    if not detail then return false end
    return string.find(detail.name, "sapling") ~= nil
end

local function getSaplingCount()
    local count = 0
    for slot = 1, 16 do
        if isSaplingItem(slot) then
            count = count + turtle.getItemCount(slot)
        end
    end
    return count
end

-- Consolidate all saplings into SAPLING_SLOT
local function consolidateSaplings()
    for slot = 2, 16 do
        if isSaplingItem(slot) then
            turtle.select(slot)
            turtle.transferTo(SAPLING_SLOT)
        end
    end
    turtle.select(SAPLING_SLOT)
end

-- Must be called at home position, facing south
local function sortAndDump()
    -- First consolidate saplings into slot 1
    consolidateSaplings()

    -- Face west (wood chest) — turnRight from south
    face(WEST)

    -- Dump non-sapling items from slots 2-16
    for slot = 2, 16 do
        if turtle.getItemCount(slot) > 0 and not isSaplingItem(slot) then
            turtle.select(slot)
            if not turtle.drop() then
                print("Warning: wood chest may be full")
            end
        end
    end

    -- Face east (sapling chest)
    face(EAST)

    -- Dump excess saplings beyond a full stack in slot 1
    -- Slot 1 can hold up to 64; dump anything over SAPLING_MIN
    local sapCount = turtle.getItemCount(SAPLING_SLOT)
    if sapCount > 64 then
        -- This shouldn't happen since it's one slot, but safety check
        turtle.select(SAPLING_SLOT)
        turtle.drop(sapCount - 64)
    end

    -- Dump any remaining sapling stacks in other slots
    for slot = 2, 16 do
        if turtle.getItemCount(slot) > 0 and isSaplingItem(slot) then
            turtle.select(slot)
            turtle.drop()
        end
    end

    -- If saplings low, pull from sapling chest
    if turtle.getItemCount(SAPLING_SLOT) < SAPLING_MIN then
        turtle.select(SAPLING_SLOT)
        turtle.suck(SAPLING_MIN - turtle.getItemCount(SAPLING_SLOT))
    end

    -- Restore facing south
    face(SOUTH)
    turtle.select(SAPLING_SLOT)
end

-------------------------------
-- Self-fueling
-------------------------------

local function findLogSlot()
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and string.find(detail.name, "log") then
            return slot
        end
    end
    return nil
end

local function isInventoryEmpty()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            return false
        end
    end
    return true
end

-- Craft logs into planks and refuel. Must be at home, post-dump.
local function craftAndRefuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" or fuel >= FUEL_THRESHOLD then
        return true
    end

    print("Fuel low (" .. fuel .. "), crafting planks...")

    while turtle.getFuelLevel() < FUEL_THRESHOLD do
        -- Find a log
        local logSlot = findLogSlot()
        if not logSlot then
            -- Try to pull a log from wood chest
            face(WEST)
            turtle.select(2) -- use slot 2 as temp
            if not turtle.suck(1) then
                face(SOUTH)
                print("No logs available for fuel!")
                return turtle.getFuelLevel() > 0
            end
            face(SOUTH)
            logSlot = 2
        end

        -- Dump saplings to sapling chest temporarily
        local hadSaplings = turtle.getItemCount(SAPLING_SLOT) > 0
        if hadSaplings then
            turtle.select(SAPLING_SLOT)
            face(EAST)
            turtle.drop()
            face(SOUTH)
        end

        -- Clear all slots except the log
        -- (should already be clear post-dump, but ensure)
        for slot = 1, 16 do
            if slot ~= logSlot and turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                face(WEST)
                turtle.drop()
                face(SOUTH)
            end
        end

        -- Move log to slot 2 (a crafting grid slot) if not already there
        if logSlot ~= 2 then
            turtle.select(logSlot)
            turtle.transferTo(2)
        end

        -- Craft: 1 log in slot 2, everything else empty → 4 planks
        turtle.select(2)
        local ok, err = turtle.craft()
        if not ok then
            print("Craft failed: " .. tostring(err))
            -- Move the log out of the way and abort
            turtle.select(2)
            face(WEST)
            turtle.drop()
            face(SOUTH)
            break
        end

        -- Refuel from the planks (they'll be in the first available slot)
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                if turtle.refuel(0) then
                    turtle.refuel()
                end
            end
        end

        -- Pull saplings back
        if hadSaplings then
            turtle.select(SAPLING_SLOT)
            face(EAST)
            turtle.suck()
            face(SOUTH)
        end
    end

    turtle.select(SAPLING_SLOT)
    print("Fuel: " .. turtle.getFuelLevel())
    return turtle.getFuelLevel() > 0
end

-------------------------------
-- Patrol
-------------------------------

local function processTreePosition()
    -- Turtle is in the walkway, facing the tree position
    -- Check if there's a log (grown tree)
    if isLog(turtle.inspect) then
        print(string.format("Harvesting tree at row %d, col %d",
            state.pos.row, state.pos.col))
        harvestTree()
        suckPatrol()
        replant()
    elseif not isSapling(turtle.inspect) then
        -- Empty spot, no tree and no sapling — replant
        local count = turtle.getItemCount(SAPLING_SLOT)
        if count > 0 then
            turtle.select(SAPLING_SLOT)
            turtle.place()
        end
    end
    -- If sapling already there, skip
end

local function patrol()
    -- Determine starting position (check phase BEFORE overwriting it)
    local row, col = 1, 1
    if state.pos.row > 0 and state.pos.col > 0 then
        -- Resuming mid-patrol — get next position after current
        row, col = state.pos.row, state.pos.col
        -- If we were traveling, we haven't processed this position yet
        -- If we were in another phase (harvest complete, etc.), skip to next
        if state.pos.phase ~= "traveling" then
            row, col = nextTreePos(row, col)
            if not row then return true end -- patrol was on last tree
        end
    end

    state.patrolStartTime = os.epoch("utc")
    state.pos.phase = "traveling"
    saveState()

    -- Navigate to starting position
    if not navigateToTree(row, col) then return false end

    -- Process each tree position in snake order
    while row do
        state.pos.row = row
        state.pos.col = col
        state.pos.phase = "traveling"
        saveState()

        -- Face the tree (turtle approaches from walkway)
        -- After navigateToTree, turtle is at the walkway position
        -- Tree is one block to the south (in front when facing south)
        face(SOUTH)

        processTreePosition()

        -- Check if inventory is getting full
        if isInventoryFull() then
            print("Inventory full, returning home early...")
            returnHome()
            sortAndDump()
            craftAndRefuel()
            -- Resume patrol from next position
            row, col = nextTreePos(row, col)
            if not row then break end
            navigateToTree(row, col)
        else
            -- Move to next position
            local nextRow, nextCol = nextTreePos(row, col)
            if not nextRow then break end -- patrol complete
            navigateToTree(nextRow, nextCol)
            row, col = nextRow, nextCol
        end
    end

    return true
end

-------------------------------
-- Main loop
-------------------------------

local function mainLoop()
    while true do
        -- Patrol the grid
        patrol()

        -- Return home
        returnHome()

        -- Sort and dump inventory
        sortAndDump()

        -- Refuel if needed
        craftAndRefuel()

        -- Calculate sleep time
        local elapsed = os.epoch("utc") - state.patrolStartTime
        local remaining = (GROW_TIME * 1000) - elapsed
        if remaining > 0 then
            local sleepSec = math.floor(remaining / 1000)
            print(string.format("Sleeping %d seconds...", sleepSec))
            state.pos.phase = "home"
            saveState()
            sleep(sleepSec)
        else
            print("Patrol took longer than grow time, starting next patrol...")
        end
    end
end

-------------------------------
-- Startup & resume
-------------------------------

local function startup()
    print("=== Tree Farm ===")

    -- Try to load saved state
    state = loadState()

    if state then
        print(string.format("Resuming: %dx%d farm, pos=(%d,%d), phase=%s",
            state.rows, state.cols,
            state.pos.row, state.pos.col,
            state.pos.phase))

        -- Handle resume based on phase
        if state.pos.phase == "harvesting_up" then
            print("Resuming harvest (climbing)...")
            -- Re-enter the dig-up loop
            while isLog(turtle.inspectUp) do
                turtle.digUp()
                if not tryUp() then break end
                state.pos.height = state.pos.height + 1
                saveState()
            end
            state.pos.phase = "harvesting_down"
            saveState()
            while state.pos.height > 0 do
                if not tryDown() then break end
                state.pos.height = state.pos.height - 1
                saveState()
            end
            suckPatrol()
            replant()
            state.pos.phase = "home"
            -- Continue patrol from next position
        elseif state.pos.phase == "harvesting_down" then
            print("Resuming harvest (descending)...")
            while state.pos.height > 0 do
                if not tryDown() then break end
                state.pos.height = state.pos.height - 1
                saveState()
            end
            suckPatrol()
            replant()
            state.pos.phase = "home"
        elseif state.pos.phase == "suck_patrol" then
            print("Interrupted during collection, returning home...")
            returnHome()
            sortAndDump()
            craftAndRefuel()
        elseif state.pos.phase == "returning" then
            print("Resuming return home...")
            returnHome()
            sortAndDump()
            craftAndRefuel()
        elseif state.pos.phase == "home" then
            print("Was at home, starting fresh patrol...")
        elseif state.pos.phase == "traveling" then
            print("Resuming patrol...")
            -- patrol() will pick up from current position
        end
    else
        -- First run — need dimensions
        if #args < 2 then
            printUsage()
            return false
        end

        local rows = tonumber(args[1])
        local cols = tonumber(args[2])
        if not rows or not cols or rows < 1 or cols < 1 then
            print("Rows and columns must be positive numbers.")
            return false
        end

        state = initState(rows, cols)
        saveState()

        print(string.format("Starting %dx%d tree farm", rows, cols))
        print(string.format("Grid: %d tree positions", rows * cols))
        print(string.format("Fuel: %s", tostring(turtle.getFuelLevel())))
        print()
    end

    return true
end

-------------------------------
-- Entry point
-------------------------------

local function main()
    if not startup() then return end

    -- Initial sapling check — try to pull from chest (only if at home)
    if state.pos.phase == "home" and turtle.getItemCount(SAPLING_SLOT) < SAPLING_MIN then
        face(EAST)
        turtle.select(SAPLING_SLOT)
        turtle.suck()
        face(SOUTH)
    end

    mainLoop()
end

-- Run with error protection
-- Note: CC:T Lua has no debug.traceback — use tostring(e) only
local ok, err = xpcall(main, function(e)
    if state then
        pcall(saveState)
    end
    return tostring(e)
end)

if not ok then
    print()
    print("*** TREE FARM ERROR ***")
    print(err)
    print()
    print("State saved. Restart to resume.")
end
