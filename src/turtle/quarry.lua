-- quarry: BuildCraft-style quarry mining program
-- Usage: quarry <width> <length>
-- Place a chest directly behind the turtle before starting.
-- Turtle starts at front-left corner, facing into the quarry.

local args = { ... }
if #args < 2 then
    print("Usage: quarry <width> <length>")
    print("  width  = left-to-right size")
    print("  length = forward-back size")
    return
end

local WIDTH = tonumber(args[1])
local LENGTH = tonumber(args[2])

if not WIDTH or not LENGTH or WIDTH < 1 or LENGTH < 1 then
    print("Width and length must be positive numbers.")
    return
end

-------------------------------
-- State
-------------------------------

local pos = { x = 0, y = 0, z = 0 }
local FORWARD, RIGHT, BACK, LEFT = 0, 1, 2, 3
local facing = FORWARD

local totalMined = 0
local MAX_RETRIES = 30

local dx = { [FORWARD] = 0, [RIGHT] = 1, [BACK] = 0, [LEFT] = -1 }
local dz = { [FORWARD] = 1, [RIGHT] = 0, [BACK] = -1, [LEFT] = 0 }

-------------------------------
-- Fuel (defined early so movement can use it)
-------------------------------

local FUEL_BUFFER = 500 -- try to keep at least this much fuel

local function tryRefuel(targetLevel)
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end

    targetLevel = targetLevel or FUEL_BUFFER

    for slot = 1, 16 do
        if turtle.getFuelLevel() >= targetLevel then break end
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
            end
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() > 0
end

-- Called periodically to top up fuel from mined coal/charcoal
local function autoRefuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return end
    if fuel < FUEL_BUFFER then
        tryRefuel(FUEL_BUFFER)
    end
end

-- Wait indefinitely for the player to add fuel
local function waitForFuel()
    if turtle.getFuelLevel() == "unlimited" then return end
    tryRefuel()
    if turtle.getFuelLevel() > 0 then return end

    print()
    print("*** OUT OF FUEL ***")
    print("Add fuel items to the turtle inventory.")
    print("Waiting...")

    while turtle.getFuelLevel() == 0 do
        sleep(2)
        tryRefuel()
    end

    print("Refueled! Fuel: " .. turtle.getFuelLevel() .. ". Resuming...")
    print()
end

-------------------------------
-- Movement primitives
-------------------------------

local function turnLeft()
    turtle.turnLeft()
    facing = (facing - 1) % 4
end

local function turnRight()
    turtle.turnRight()
    facing = (facing + 1) % 4
end

local function face(dir)
    local diff = (dir - facing) % 4
    if diff == 1 then
        turnRight()
    elseif diff == 2 then
        turnRight()
        turnRight()
    elseif diff == 3 then
        turnLeft()
    end
end

local function digForward()
    local tries = 0
    while turtle.detect() do
        turtle.dig()
        tries = tries + 1
        if tries > MAX_RETRIES then return false end
        sleep(0.1)
    end
    return true
end

local function digUp()
    local tries = 0
    while turtle.detectUp() do
        turtle.digUp()
        tries = tries + 1
        if tries > MAX_RETRIES then return false end
        sleep(0.1)
    end
    return true
end

local function digDown()
    if turtle.detectDown() then
        if turtle.digDown() then
            totalMined = totalMined + 1
            return true
        end
        return false
    end
    return true
end

local function forward()
    while true do
        for _ = 1, MAX_RETRIES do
            digForward()
            local ok, err = turtle.forward()
            if ok then
                pos.x = pos.x + dx[facing]
                pos.z = pos.z + dz[facing]
                return true
            end
            if err == "Out of fuel" then
                waitForFuel()
            else
                turtle.attack()
                sleep(0.2)
            end
        end
        -- Still stuck after retries — likely a mob or obstruction, keep trying
        print("Stuck moving forward at " .. pos.x .. "," .. pos.y .. "," .. pos.z .. " — retrying...")
        sleep(1)
    end
end

local function up()
    while true do
        for _ = 1, MAX_RETRIES do
            digUp()
            local ok, err = turtle.up()
            if ok then
                pos.y = pos.y + 1
                return true
            end
            if err == "Out of fuel" then
                waitForFuel()
            else
                turtle.attackUp()
                sleep(0.2)
            end
        end
        print("Stuck moving up at " .. pos.x .. "," .. pos.y .. "," .. pos.z .. " — retrying...")
        sleep(1)
    end
end

local function down()
    while true do
        for _ = 1, MAX_RETRIES do
            digDown()
            local ok, err = turtle.down()
            if ok then
                pos.y = pos.y - 1
                return true
            end
            if err == "Out of fuel" then
                waitForFuel()
            elseif err == "Movement obstructed" then
                -- Might be bedrock — caller needs to check
                turtle.attackDown()
                sleep(0.2)
            else
                turtle.attackDown()
                sleep(0.2)
            end
        end
        -- For down(), we might genuinely be blocked by bedrock
        -- Return false so caller can handle it
        return false
    end
end

-------------------------------
-- Navigation
-------------------------------

local function goToY(targetY)
    while pos.y < targetY do
        if not up() then return false end
    end
    while pos.y > targetY do
        if not down() then return false end
    end
    return true
end

local function goToX(targetX)
    if targetX > pos.x then
        face(RIGHT)
    elseif targetX < pos.x then
        face(LEFT)
    end
    while pos.x ~= targetX do
        if not forward() then return false end
    end
    return true
end

local function goToZ(targetZ)
    if targetZ > pos.z then
        face(FORWARD)
    elseif targetZ < pos.z then
        face(BACK)
    end
    while pos.z ~= targetZ do
        if not forward() then return false end
    end
    return true
end

local function goTo(x, y, z)
    if y > pos.y then goToY(y) end
    goToX(x)
    goToZ(z)
    if y < pos.y then goToY(y) end
    return true
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

local function dumpInventory()
    face(BACK)
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(1)
end

local function returnAndDump()
    local sx, sy, sz = pos.x, pos.y, pos.z
    print("Inventory full. Returning to dump...")
    goTo(0, 0, 0)
    dumpInventory()
    print("Resuming mining...")
    goTo(sx, sy, sz)
end

-------------------------------
-- Fuel check (uses goTo, so defined after navigation)
-------------------------------

local function checkFuel()
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return end

    local returnCost = math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z) + 10
    if fuel <= returnCost then
        tryRefuel()
        fuel = turtle.getFuelLevel()
        if fuel <= returnCost then
            -- Not enough fuel to get home — wait here for player to add fuel
            waitForFuel()
        end
    end
end

-------------------------------
-- Bedrock detection
-------------------------------

local function isBedrockBelow()
    local ok, data = turtle.inspectDown()
    return ok and data.name == "minecraft:bedrock"
end

-------------------------------
-- Main quarry logic
-------------------------------

local function printStatus(layer)
    local fuel = turtle.getFuelLevel()
    print(string.format("Layer %d | Mined: %d | Fuel: %s | Pos: %d,%d,%d",
        layer, totalMined, tostring(fuel), pos.x, pos.y, pos.z))
end

local function mineLayer()
    local bedrockCount = 0
    local totalPositions = WIDTH * LENGTH

    for row = 0, LENGTH - 1 do
        if row > 0 then
            face(FORWARD)
            if not forward() then return false end
        end

        local movesInRow = WIDTH - 1
        local rowDir
        if row % 2 == 0 then
            rowDir = RIGHT
        else
            rowDir = LEFT
        end

        -- Mine block below current position
        if isBedrockBelow() then
            bedrockCount = bedrockCount + 1
        else
            digDown()
        end
        autoRefuel()

        -- Traverse the row
        if movesInRow > 0 then
            face(rowDir)
        end
        for _ = 1, movesInRow do
            if not forward() then return false end

            if isBedrockBelow() then
                bedrockCount = bedrockCount + 1
            else
                digDown()
            end

            autoRefuel()

            if isInventoryFull() then
                returnAndDump()
            end

            checkFuel()
        end
    end

    if bedrockCount >= totalPositions then
        return nil
    end

    return true
end

local function quarry()
    print("=== Quarry Program ===")
    print(string.format("Size: %dx%d, mining to bedrock", WIDTH, LENGTH))
    print("Chest should be directly behind starting position.")
    print()

    -- Auto-refuel from any fuel in inventory
    local fuel = turtle.getFuelLevel()
    if fuel ~= "unlimited" then
        print("Fuel: " .. fuel)
        tryRefuel()
        fuel = turtle.getFuelLevel()
        print("Fuel after auto-refuel: " .. fuel)

        if fuel == 0 then
            waitForFuel()
        end

        fuel = turtle.getFuelLevel()
        if fuel < WIDTH * LENGTH * 3 then
            print(string.format("WARNING: Fuel (%d) may be low for %dx%d.", fuel, WIDTH, LENGTH))
            print("Will auto-refuel from mined coal.")
        end
    end

    print()
    local layer = 0

    while true do
        printStatus(layer)

        goToX(0)
        goToZ(0)

        local result = mineLayer()
        if result == nil then
            print("Hit bedrock everywhere! Quarry complete.")
            break
        end

        goToX(0)
        goToZ(0)

        if isBedrockBelow() then
            print("Bedrock at origin. Quarry complete.")
            break
        end

        if not down() then
            print("Cannot descend. Quarry complete.")
            break
        end

        layer = layer + 1

        if isInventoryFull() then
            returnAndDump()
        end
    end

    print("Returning to surface...")
    goTo(0, 0, 0)
    dumpInventory()
    face(FORWARD)

    print()
    print("=== Quarry Complete ===")
    print(string.format("Blocks mined: %d", totalMined))
    print(string.format("Layers dug: %d", layer + 1))
    print(string.format("Fuel remaining: %s", tostring(turtle.getFuelLevel())))
end

quarry()
