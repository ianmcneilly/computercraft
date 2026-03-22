import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { WebSocketServer } from "ws";
import { randomUUID } from "crypto";
import { z } from "zod";

// ---------------------------------------------------------------------------
// Turtle connection registry
// ---------------------------------------------------------------------------

const turtles = new Map();   // turtleId -> { ws, state, lastSeen, label, computerId }
const pending = new Map();    // requestId -> { resolve, reject, timer }

const COMMAND_TIMEOUT_MS = 30_000;
const EVAL_TIMEOUT_MS = 60_000;

function getDefaultTurtle() {
  for (const [id, t] of turtles) {
    if (t.ws.readyState === 1) return { ...t, id };
  }
  return null;
}

function getTurtle(turtleId) {
  if (turtleId) {
    const t = turtles.get(turtleId);
    return t ? { ...t, id: turtleId } : null;
  }
  return getDefaultTurtle();
}

function sendCommand(turtleId, cmd, args, timeoutMs = COMMAND_TIMEOUT_MS) {
  return new Promise((resolve, reject) => {
    const turtle = getTurtle(turtleId);
    if (!turtle || turtle.ws.readyState !== 1) {
      return reject(new Error("Turtle not connected"));
    }
    const id = randomUUID();
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error("Command timed out — turtle may be in an unloaded chunk"));
    }, timeoutMs);
    const resolvedTurtleId = turtleId || turtle.id;
    pending.set(id, { resolve, reject, timer, turtleId: resolvedTurtleId });
    turtle.ws.send(JSON.stringify({ id, cmd, args: args || {} }));
  });
}

// ---------------------------------------------------------------------------
// WebSocket server for turtle connections
// ---------------------------------------------------------------------------

const WS_PORT = parseInt(process.env.WS_PORT || "3001", 10);
const wss = new WebSocketServer({ port: WS_PORT });

wss.on("listening", () => {
  process.stderr.write(`[turtle-bridge] WebSocket server listening on port ${WS_PORT}\n`);
});

wss.on("connection", (ws) => {
  let turtleId = null;

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }

    // Registration message
    if (msg.type === "hello") {
      turtleId = msg.turtleId || `turtle_${msg.computerId}`;
      turtles.set(turtleId, {
        ws,
        state: msg.state || {},
        lastSeen: Date.now(),
        label: msg.label,
        computerId: msg.computerId,
      });
      process.stderr.write(`[turtle-bridge] Turtle connected: ${turtleId} (${msg.label || "unnamed"})\n`);
      return;
    }

    // Heartbeat
    if (msg.type === "heartbeat") {
      if (turtleId && turtles.has(turtleId)) {
        const t = turtles.get(turtleId);
        t.state = msg.state || t.state;
        t.lastSeen = Date.now();
      }
      return;
    }

    // Command response
    if (msg.id && pending.has(msg.id)) {
      const { resolve, timer } = pending.get(msg.id);
      clearTimeout(timer);
      pending.delete(msg.id);
      resolve(msg);
      // Update cached state
      if (turtleId && turtles.has(turtleId) && msg.state) {
        turtles.get(turtleId).state = msg.state;
        turtles.get(turtleId).lastSeen = Date.now();
      }
    }
  });

  ws.on("close", () => {
    if (turtleId) {
      process.stderr.write(`[turtle-bridge] Turtle disconnected: ${turtleId}\n`);
      turtles.delete(turtleId);
    }
    // Reject pending commands for this specific turtle only
    for (const [id, p] of pending) {
      if (p.turtleId === turtleId) {
        clearTimeout(p.timer);
        p.reject(new Error("Turtle disconnected"));
        pending.delete(id);
      }
    }
  });

  ws.on("error", (err) => {
    process.stderr.write(`[turtle-bridge] WebSocket error: ${err.message}\n`);
  });
});

// ---------------------------------------------------------------------------
// Helper: wrap a command as an MCP tool result
// ---------------------------------------------------------------------------

async function runCommand(cmd, args, timeoutMs) {
  try {
    const result = await sendCommand(null, cmd, args, timeoutMs);
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  } catch (err) {
    return {
      content: [{ type: "text", text: JSON.stringify({ ok: false, error: err.message }) }],
      isError: true,
    };
  }
}

// Direction parameter helper — maps "up"/"down" to separate CC:T commands
function dirCmd(base, direction) {
  if (direction === "up") return base + "Up";
  if (direction === "down") return base + "Down";
  return base;
}

// ---------------------------------------------------------------------------
// MCP Server
// ---------------------------------------------------------------------------

const mcp = new McpServer({
  name: "turtle-bridge",
  version: "1.0.0",
});

// -- Movement tools --

mcp.tool("turtle_forward", "Move the turtle forward one block", async () => {
  return runCommand("forward");
});

mcp.tool("turtle_back", "Move the turtle backward one block", async () => {
  return runCommand("back");
});

mcp.tool("turtle_up", "Move the turtle up one block", async () => {
  return runCommand("up");
});

mcp.tool("turtle_down", "Move the turtle down one block", async () => {
  return runCommand("down");
});

mcp.tool("turtle_turnLeft", "Turn the turtle 90 degrees left", async () => {
  return runCommand("turnLeft");
});

mcp.tool("turtle_turnRight", "Turn the turtle 90 degrees right", async () => {
  return runCommand("turnRight");
});

// -- Digging --

mcp.tool(
  "turtle_dig",
  "Break the block in the given direction (default: front)",
  { direction: z.enum(["front", "up", "down"]).optional().describe("Direction to dig") },
  async ({ direction }) => {
    return runCommand(dirCmd("dig", direction));
  }
);

// -- Placing --

mcp.tool(
  "turtle_place",
  "Place a block/item from the selected slot",
  {
    direction: z.enum(["front", "up", "down"]).optional().describe("Direction to place"),
    text: z.string().optional().describe("Text for signs"),
  },
  async ({ direction, text }) => {
    return runCommand(dirCmd("place", direction), { text });
  }
);

// -- Inspection --

mcp.tool(
  "turtle_inspect",
  "Get detailed block info in the given direction (name, state, tags)",
  { direction: z.enum(["front", "up", "down"]).optional().describe("Direction to inspect") },
  async ({ direction }) => {
    return runCommand(dirCmd("inspect", direction));
  }
);

mcp.tool(
  "turtle_detect",
  "Check if there is a solid block in the given direction",
  { direction: z.enum(["front", "up", "down"]).optional().describe("Direction to detect") },
  async ({ direction }) => {
    return runCommand(dirCmd("detect", direction));
  }
);

mcp.tool("turtle_surroundings", "Inspect all three directions (front, up, down) at once", async () => {
  return runCommand("surroundings");
});

// -- Combat --

mcp.tool(
  "turtle_attack",
  "Attack an entity in the given direction",
  { direction: z.enum(["front", "up", "down"]).optional().describe("Direction to attack") },
  async ({ direction }) => {
    return runCommand(dirCmd("attack", direction));
  }
);

// -- Inventory --

mcp.tool(
  "turtle_inventory",
  "Scan all 16 inventory slots and return their contents",
  { detailed: z.boolean().optional().describe("Include full item details (NBT data)") },
  async ({ detailed }) => {
    return runCommand("inventory", { detailed });
  }
);

mcp.tool(
  "turtle_select",
  "Select an inventory slot (1-16)",
  { slot: z.number().min(1).max(16).describe("Slot number to select") },
  async ({ slot }) => {
    return runCommand("select", { slot });
  }
);

mcp.tool(
  "turtle_transferTo",
  "Transfer items from the selected slot to another slot",
  {
    slot: z.number().min(1).max(16).describe("Destination slot"),
    count: z.number().optional().describe("Number of items to transfer"),
  },
  async ({ slot, count }) => {
    return runCommand("transferTo", { slot, count });
  }
);

mcp.tool(
  "turtle_drop",
  "Drop items from the selected slot",
  {
    direction: z.enum(["front", "up", "down"]).optional().describe("Direction to drop"),
    count: z.number().optional().describe("Number of items to drop"),
  },
  async ({ direction, count }) => {
    return runCommand(dirCmd("drop", direction), { count });
  }
);

mcp.tool(
  "turtle_suck",
  "Pick up items from the ground or a container",
  {
    direction: z.enum(["front", "up", "down"]).optional().describe("Direction to pick up from"),
    count: z.number().optional().describe("Max items to pick up"),
  },
  async ({ direction, count }) => {
    return runCommand(dirCmd("suck", direction), { count });
  }
);

// -- Fuel --

mcp.tool(
  "turtle_refuel",
  "Consume fuel items from the selected slot to refuel the turtle",
  { count: z.number().optional().describe("Number of items to consume") },
  async ({ count }) => {
    return runCommand("refuel", { count });
  }
);

// -- Crafting --

mcp.tool(
  "turtle_craft",
  "Craft items using the turtle's inventory as a crafting grid (requires crafting table equipped)",
  { limit: z.number().optional().describe("Max items to craft") },
  async ({ limit }) => {
    return runCommand("craft", { limit });
  }
);

// -- Equipment --

mcp.tool(
  "turtle_equip",
  "Equip or unequip an item from the selected slot to the given side",
  { side: z.enum(["left", "right"]).describe("Side to equip to") },
  async ({ side }) => {
    return runCommand(side === "left" ? "equipLeft" : "equipRight");
  }
);

// -- GPS --

mcp.tool(
  "turtle_gpsLocate",
  "Get the turtle's absolute position via GPS (requires GPS satellites in range)",
  { timeout: z.number().optional().describe("GPS timeout in seconds") },
  async ({ timeout }) => {
    return runCommand("gpsLocate", { timeout }, EVAL_TIMEOUT_MS);
  }
);

// -- State --

mcp.tool("turtle_getState", "Get the turtle's current position, facing direction, fuel level, and selected slot", async () => {
  return runCommand("getState");
});

// -- Eval --

mcp.tool(
  "turtle_eval",
  "Execute arbitrary Lua code on the turtle. The code runs in the turtle's global environment with access to all CC:T APIs. WARNING: blocks the turtle's command loop until complete.",
  { code: z.string().describe("Lua code to execute") },
  async ({ code }) => {
    return runCommand("eval", { code }, EVAL_TIMEOUT_MS);
  }
);

// -- Batch --

mcp.tool(
  "turtle_batch",
  "Execute multiple commands in sequence on the turtle. Each command is { cmd, args }. Returns array of results. Useful for multi-step operations in a single call.",
  {
    commands: z.array(z.object({
      cmd: z.string().describe("Command name (e.g. forward, dig, inspect)"),
      args: z.record(z.any()).optional().describe("Command arguments"),
    })).describe("List of commands to execute in order"),
  },
  async ({ commands }) => {
    return runCommand("batch", { commands }, EVAL_TIMEOUT_MS);
  }
);

// -- Connection management --

mcp.tool("turtle_list", "List all currently connected turtles and their state", async () => {
  const list = [];
  for (const [id, t] of turtles) {
    list.push({
      id,
      label: t.label,
      computerId: t.computerId,
      connected: t.ws.readyState === 1,
      lastSeen: t.lastSeen,
      state: t.state,
    });
  }
  return {
    content: [{ type: "text", text: JSON.stringify({ turtles: list }, null, 2) }],
  };
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const transport = new StdioServerTransport();
await mcp.connect(transport);
process.stderr.write("[turtle-bridge] MCP server connected via stdio\n");
