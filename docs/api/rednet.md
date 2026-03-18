# rednet API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/rednet.html

High-level networking API built on modems. Provides named protocols and hostname-based service discovery.

## Constants

- `rednet.CHANNEL_BROADCAST` = `65535` — broadcast channel
- `rednet.CHANNEL_REPEAT` = `65533` — repeater channel
- `rednet.MAX_ID_CHANNELS` = `65500` — channels reserved for computer IDs

## Functions

### rednet.open(modem)
Open a modem for rednet use. Opens the computer's ID channel and the broadcast channel.
- Parameters: `modem`: `string` — side or network name of the modem

### rednet.close(modem?)
Close a modem (or all modems if no argument).
- Parameters: `modem?`: `string`

### rednet.isOpen(modem?)
Check if a modem is open for rednet.
- Parameters: `modem?`: `string` — specific modem, or nil for any
- Returns: `boolean`

### rednet.send(recipient, message, protocol?)
Send a message to a specific computer.
- Parameters:
  - `recipient`: `number` — target computer ID
  - `message`: `any` — any serializable value (primitives, tables)
  - `protocol?`: `string` — optional protocol name
- Returns: `boolean` — whether the message was sent (does not guarantee receipt)

### rednet.broadcast(message, protocol?)
Broadcast a message to all computers on the network.
- Parameters:
  - `message`: `any` — any serializable value
  - `protocol?`: `string`

### rednet.receive(protocolFilter?, timeout?)
Wait for a rednet message. Blocks until a message arrives or timeout.
- Parameters:
  - `protocolFilter?`: `string` — only receive this protocol
  - `timeout?`: `number` — seconds to wait
- Returns: `number` senderID, `any` message, `string|nil` protocol — or `nil` on timeout

### rednet.host(protocol, hostname)
Register this computer as a host for a protocol. Enables service discovery via `lookup()`.
- Parameters:
  - `protocol`: `string`
  - `hostname`: `string` — must not be "localhost" (reserved)

### rednet.unhost(protocol)
Stop hosting a protocol.
- Parameters: `protocol`: `string`

### rednet.lookup(protocol, hostname?)
Look up computers hosting a protocol.
- Parameters:
  - `protocol`: `string`
  - `hostname?`: `string` — find a specific host
- Returns: if hostname given, `number|nil` computer ID; if not, multiple `number` IDs

### rednet.run()
Internal function powering the rednet event loop. Started automatically on boot — do not call directly.

## Events

### rednet_message
Fired when a rednet message is received.
- Parameters: `senderID`: `number`, `message`: `any`, `protocol`: `string|nil`

## Notes

- You MUST call `rednet.open(side)` before sending or receiving
- `rednet.receive()` blocks — use `parallel` or an event loop for non-blocking
- `rednet.send()` returns true if the modem transmitted — not if the recipient received it
- GPS uses the `"gps"` protocol internally — avoid reusing it
- Messages are limited by modem range (default 64 blocks wireless, unlimited for ender modems)
