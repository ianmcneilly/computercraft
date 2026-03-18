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
