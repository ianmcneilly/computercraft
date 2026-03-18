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
    f.write(textutils.serialize(state))
    f.close()
end

local function loadState()
    if fs.exists(STATE_FILE) then
        local f = fs.open(STATE_FILE, "r")
        local data = f.readAll()
        f.close()
        return textutils.unserialize(data)
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
    for attempt = 1, MAX_RETRIES do
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
    for attempt = 1, MAX_RETRIES do
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
    for attempt = 1, MAX_RETRIES do
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

-- Navigate to a specific tree position in the grid
local function navigateToTree(row, col)
    local targetX, targetZ = gridToBlocks(row, col)
    local currentX, currentZ
    if state.pos.row == 0 and state.pos.col == 0 then
        currentX, currentZ = 0, 0
    else
        currentX, currentZ = gridToBlocks(state.pos.row, state.pos.col)
    end

    local dx = targetX - currentX
    local dz = targetZ - currentZ

    -- Move east/west
    if dx > 0 then
        face(EAST)
        for i = 1, dx do
            if not tryForward() then return false end
        end
    elseif dx < 0 then
        face(WEST)
        for i = 1, -dx do
            if not tryForward() then return false end
        end
    end

    -- Move north/south
    if dz > 0 then
        face(SOUTH)
        for i = 1, dz do
            if not tryForward() then return false end
        end
    elseif dz < 0 then
        face(NORTH)
        for i = 1, -dz do
            if not tryForward() then return false end
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

    -- Navigate back to home (0, 0)
    local currentX, currentZ = gridToBlocks(state.pos.row, state.pos.col)

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
