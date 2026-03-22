-- turtle_client: WebSocket bridge client for Claude-controlled turtles
-- Connects to the MCP relay server and executes commands from Claude.
-- Usage: turtle_client [server_url]
-- Default server: ws://localhost:3001

-------------------------------
-- Configuration
-------------------------------

local args = { ... }
local SERVER_URL = args[1] or "ws://localhost:3001"
local HEARTBEAT_SEC = 5
local RECONNECT_SEC = 3
local MAX_RECONNECT_SEC = 30
local STATE_FILE = "bridge_state"

-------------------------------
-- Facing / direction constants
-------------------------------

local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
local FACING_NAMES = { [0] = "north", "east", "south", "west" }
local FACING_DX = { [NORTH] = 0, [EAST] = 1, [SOUTH] = 0, [WEST] = -1 }
local FACING_DZ = { [NORTH] = -1, [EAST] = 0, [SOUTH] = 1, [WEST] = 0 }

-------------------------------
-- State
-------------------------------

local state = {
    x = 0,
    y = 0,
    z = 0,
    facing = NORTH,
    fuel = 0,
    fuelLimit = 0,
    selectedSlot = 1,
}

-------------------------------
-- State persistence
-------------------------------

local function saveState()
    local f = fs.open(STATE_FILE, "w")
    if not f then return end
    f.write(textutils.serialize(state))
    f.close()
end

local function loadState()
    if fs.exists(STATE_FILE) then
        local f = fs.open(STATE_FILE, "r")
        local data = f.readAll()
        f.close()
        local s = textutils.unserialize(data)
        if s and s.x and s.facing then
            return s
        end
        print("Warning: corrupt state file, using defaults")
    end
    return nil
end

-------------------------------
-- State snapshot
-------------------------------

local function updateFuelState()
    state.fuel = turtle.getFuelLevel()
    state.fuelLimit = turtle.getFuelLimit()
    state.selectedSlot = turtle.getSelectedSlot()
end

local function getStateSnapshot()
    updateFuelState()
    return {
        x = state.x,
        y = state.y,
        z = state.z,
        facing = state.facing,
        facingName = FACING_NAMES[state.facing],
        fuel = state.fuel,
        fuelLimit = state.fuelLimit,
        selectedSlot = state.selectedSlot,
    }
end

-------------------------------
-- Movement wrappers (track position)
-------------------------------

local function doForward()
    local ok, err = turtle.forward()
    if ok then
        state.x = state.x + FACING_DX[state.facing]
        state.z = state.z + FACING_DZ[state.facing]
        saveState()
    end
    return { success = ok, error = err }
end

local function doBack()
    local ok, err = turtle.back()
    if ok then
        state.x = state.x - FACING_DX[state.facing]
        state.z = state.z - FACING_DZ[state.facing]
        saveState()
    end
    return { success = ok, error = err }
end

local function doUp()
    local ok, err = turtle.up()
    if ok then
        state.y = state.y + 1
        saveState()
    end
    return { success = ok, error = err }
end

local function doDown()
    local ok, err = turtle.down()
    if ok then
        state.y = state.y - 1
        saveState()
    end
    return { success = ok, error = err }
end

local function doTurnLeft()
    local ok, err = turtle.turnLeft()
    if ok then
        state.facing = (state.facing - 1) % 4
        saveState()
    end
    return { success = ok, error = err }
end

local function doTurnRight()
    local ok, err = turtle.turnRight()
    if ok then
        state.facing = (state.facing + 1) % 4
        saveState()
    end
    return { success = ok, error = err }
end

-------------------------------
-- Command handlers
-------------------------------

local handlers = {}

-- Movement
handlers["forward"] = function() return doForward() end
handlers["back"]    = function() return doBack() end
handlers["up"]      = function() return doUp() end
handlers["down"]    = function() return doDown() end
handlers["turnLeft"]  = function() return doTurnLeft() end
handlers["turnRight"] = function() return doTurnRight() end

-- Digging
handlers["dig"]     = function() local ok, err = turtle.dig()     return { success = ok, error = err } end
handlers["digUp"]   = function() local ok, err = turtle.digUp()   return { success = ok, error = err } end
handlers["digDown"] = function() local ok, err = turtle.digDown() return { success = ok, error = err } end

-- Placing
handlers["place"]     = function(a) local ok, err = turtle.place(a.text)     return { success = ok, error = err } end
handlers["placeUp"]   = function(a) local ok, err = turtle.placeUp(a.text)   return { success = ok, error = err } end
handlers["placeDown"] = function(a) local ok, err = turtle.placeDown(a.text) return { success = ok, error = err } end

-- Detection
handlers["detect"]     = function() return { detected = turtle.detect() } end
handlers["detectUp"]   = function() return { detected = turtle.detectUp() } end
handlers["detectDown"] = function() return { detected = turtle.detectDown() } end

-- Inspection
handlers["inspect"] = function()
    local ok, data = turtle.inspect()
    return { hasBlock = ok, block = ok and data or nil }
end
handlers["inspectUp"] = function()
    local ok, data = turtle.inspectUp()
    return { hasBlock = ok, block = ok and data or nil }
end
handlers["inspectDown"] = function()
    local ok, data = turtle.inspectDown()
    return { hasBlock = ok, block = ok and data or nil }
end

-- Surroundings (compound)
handlers["surroundings"] = function()
    local fOk, fData = turtle.inspect()
    local uOk, uData = turtle.inspectUp()
    local dOk, dData = turtle.inspectDown()
    return {
        front = { hasBlock = fOk, block = fOk and fData or nil },
        up    = { hasBlock = uOk, block = uOk and uData or nil },
        down  = { hasBlock = dOk, block = dOk and dData or nil },
    }
end

-- Combat
handlers["attack"]     = function() local ok, err = turtle.attack()     return { success = ok, error = err } end
handlers["attackUp"]   = function() local ok, err = turtle.attackUp()   return { success = ok, error = err } end
handlers["attackDown"] = function() local ok, err = turtle.attackDown() return { success = ok, error = err } end

-- Inventory
handlers["inventory"] = function(a)
    local slots = {}
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i, a.detailed)
        if detail then
            detail.slot = i
            slots[#slots + 1] = detail
        end
    end
    return { slots = slots, selectedSlot = turtle.getSelectedSlot() }
end

handlers["select"] = function(a)
    local ok = turtle.select(a.slot)
    if ok then state.selectedSlot = a.slot end
    return { success = ok }
end

handlers["transferTo"] = function(a)
    local ok, err = turtle.transferTo(a.slot, a.count)
    return { success = ok, error = err }
end

handlers["drop"]     = function(a) local ok, err = turtle.drop(a.count)     return { success = ok, error = err } end
handlers["dropUp"]   = function(a) local ok, err = turtle.dropUp(a.count)   return { success = ok, error = err } end
handlers["dropDown"] = function(a) local ok, err = turtle.dropDown(a.count) return { success = ok, error = err } end

handlers["suck"]     = function(a) local ok, err = turtle.suck(a.count)     return { success = ok, error = err } end
handlers["suckUp"]   = function(a) local ok, err = turtle.suckUp(a.count)   return { success = ok, error = err } end
handlers["suckDown"] = function(a) local ok, err = turtle.suckDown(a.count) return { success = ok, error = err } end

-- Fuel
handlers["refuel"] = function(a)
    local ok, err = turtle.refuel(a.count)
    return { success = ok, error = err, fuelLevel = turtle.getFuelLevel() }
end

-- Crafting
handlers["craft"] = function(a)
    local ok, err = turtle.craft(a.limit)
    return { success = ok, error = err }
end

-- Equipment
handlers["equipLeft"]  = function() local ok, err = turtle.equipLeft()  return { success = ok, error = err } end
handlers["equipRight"] = function() local ok, err = turtle.equipRight() return { success = ok, error = err } end

-- GPS
handlers["gpsLocate"] = function(a)
    local x, y, z = gps.locate(a.timeout or 5)
    if x then
        state.x = x
        state.y = y
        state.z = z
        saveState()
        return { x = x, y = y, z = z }
    end
    return { error = "No GPS signal" }
end

-- State
handlers["getState"] = function()
    return {}  -- state is always appended to response
end

-- Eval
handlers["eval"] = function(a)
    local fn, loadErr = load(a.code)
    if not fn then
        return { error = loadErr }
    end
    local ok, result = pcall(fn)
    if not ok then
        return { error = tostring(result) }
    end
    -- Try to return the result; if it's not serializable, tostring it
    if type(result) == "table" or type(result) == "string" or
       type(result) == "number" or type(result) == "boolean" or
       result == nil then
        return { result = result }
    end
    return { result = tostring(result) }
end

-- Batch
handlers["batch"] = function(a)
    local results = {}
    for i, cmd in ipairs(a.commands) do
        local handler = handlers[cmd.cmd]
        if handler then
            local hOk, res = pcall(handler, cmd.args or {})
            if hOk then
                results[i] = { ok = true, data = res }
            else
                results[i] = { ok = false, error = tostring(res) }
            end
        else
            results[i] = { ok = false, error = "Unknown command: " .. tostring(cmd.cmd) }
        end
    end
    return { results = results }
end

-------------------------------
-- Command processor
-------------------------------

local function processCommand(ws, msg)
    local data = textutils.unserialiseJSON(msg)
    if not data or not data.id or not data.cmd then return end

    local handler = handlers[data.cmd]
    local response

    if handler then
        local ok, res = pcall(handler, data.args or {})
        if ok then
            response = {
                id = data.id,
                ok = true,
                data = res,
                state = getStateSnapshot(),
            }
        else
            response = {
                id = data.id,
                ok = false,
                error = tostring(res),
                state = getStateSnapshot(),
            }
        end
    else
        response = {
            id = data.id,
            ok = false,
            error = "Unknown command: " .. tostring(data.cmd),
            state = getStateSnapshot(),
        }
    end

    ws.send(textutils.serialiseJSON(response))
end

-------------------------------
-- Main connection loop
-------------------------------

local function main()
    -- Load saved state
    local saved = loadState()
    if saved then
        state = saved
        print("Loaded saved state: " .. state.x .. ", " .. state.y .. ", " .. state.z ..
              " facing " .. FACING_NAMES[state.facing])
    end

    local reconnectDelay = RECONNECT_SEC

    print("Turtle Bridge Client")
    print("Server: " .. SERVER_URL)
    print("Computer ID: " .. os.getComputerID())
    print()

    while true do
        print("Connecting to " .. SERVER_URL .. "...")
        local ws, err = http.websocket(SERVER_URL)

        if ws then
            reconnectDelay = RECONNECT_SEC  -- reset backoff on success
            print("Connected!")

            -- Send hello
            ws.send(textutils.serialiseJSON({
                type = "hello",
                turtleId = "turtle_" .. os.getComputerID(),
                computerId = os.getComputerID(),
                label = os.getComputerLabel(),
                state = getStateSnapshot(),
            }))

            -- Message loop (pcall because ws.receive throws on close)
            local ok, loopErr = pcall(function()
                while true do
                    local msg, isBinary = ws.receive(HEARTBEAT_SEC)
                    if msg then
                        processCommand(ws, msg)
                    elseif msg == nil and isBinary == nil then
                        -- Timeout (no message, no error) — send heartbeat
                        ws.send(textutils.serialiseJSON({
                            type = "heartbeat",
                            state = getStateSnapshot(),
                        }))
                    else
                        -- Connection closed (msg=nil, isBinary=error string)
                        error("Connection closed: " .. tostring(isBinary))
                    end
                end
            end)

            if not ok then
                print("Disconnected: " .. tostring(loopErr))
            end

            -- Safe close attempt
            pcall(function() ws.close() end)
        else
            print("Connection failed: " .. tostring(err))
        end

        print("Reconnecting in " .. reconnectDelay .. "s...")
        sleep(reconnectDelay)
        reconnectDelay = math.min(reconnectDelay * 2, MAX_RECONNECT_SEC)
    end
end

-- Run with error recovery
while true do
    local ok, err = pcall(main)
    if not ok then
        print("Fatal error: " .. tostring(err))
        print("Restarting in 5s...")
        sleep(5)
    end
end
