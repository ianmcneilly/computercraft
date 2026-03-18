# http API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/http.html

Make HTTP requests and open WebSocket connections.

## Synchronous Functions

### http.get(url, headers?, binary?)
### http.get(options)
Make a synchronous GET request.
- Parameters (positional):
  - `url`: `string`
  - `headers?`: `table` — key-value header pairs
  - `binary?`: `boolean` — open response in binary mode (default false)
- Parameters (table form): `{ url, headers?, binary?, method?, redirect?, timeout? }`
- Returns: `Response` handle on success, or `nil, string, Response?` on failure

### http.post(url, body, headers?, binary?)
### http.post(options)
Make a synchronous POST request.
- Parameters (positional):
  - `url`: `string`
  - `body`: `string` — request body
  - `headers?`: `table`
  - `binary?`: `boolean`
- Parameters (table form): `{ url, body?, headers?, binary?, method?, redirect?, timeout? }`
- Returns: `Response` handle on success, or `nil, string, Response?` on failure

## Asynchronous Functions

### http.request(url, body?, headers?, binary?)
### http.request(options)
Make an asynchronous HTTP request.
- Parameters (positional):
  - `url`: `string`
  - `body?`: `string` — if provided, POST is used instead of GET
  - `headers?`: `table`
  - `binary?`: `boolean`
- Parameters (table form): additionally supports:
  - `method`: `string` — HTTP verb ("PATCH", "DELETE", etc.)
  - `redirect`: `boolean` — follow redirects (default true)
  - `timeout`: `number` — connection timeout in seconds
- Returns: nothing — fires `http_success` or `http_failure` event

### http.checkURL(url)
Synchronously validate a URL.
- Parameters: `url`: `string`
- Returns: `true` on success, or `false, string` reason on failure

### http.checkURLAsync(url)
Asynchronously validate a URL. Fires `http_check` event.
- Parameters: `url`: `string`

## WebSocket Functions

### http.websocket(url, headers?)
### http.websocket(options)
Open a synchronous WebSocket connection.
- Parameters:
  - `url`: `string` — `ws://` or `wss://` URL
  - `headers?`: `table`
- Table form also accepts `timeout`: `number`
- Returns: `Websocket` handle on success, or `false, string` on failure

### http.websocketAsync(url, headers?)
### http.websocketAsync(options)
Open an asynchronous WebSocket connection. Fires `websocket_success` or `websocket_failure`.
- Parameters: same as `http.websocket`

## Response Handle Methods

### response.getResponseCode()
- Returns: `number` status code, `string` status message

### response.getResponseHeaders()
- Returns: `table` — header key-value pairs

### response.read(count?)
Read from the response body.
- Returns: `string|number|nil`

### response.readAll()
- Returns: `string|nil`

### response.readLine(withTrailing?)
- Returns: `string|nil`

### response.seek(whence?, offset?)
Seek in the response (binary mode only).
- Returns: `number` or `nil, string`

### response.close()
Close the response handle.

## WebSocket Handle Methods

### ws.receive(timeout?)
Wait for a message.
- Parameters: `timeout?`: `number` — seconds to wait
- Returns: `string` message, `boolean` isBinary — or `nil, string` on timeout/close
- Throws: if connection is closed

### ws.send(message, binary?)
Send a message.
- Parameters: `message`: `string`, `binary?`: `boolean`
- Throws: on oversized message or closed connection

### ws.close()
Close the WebSocket connection.

## Events

- `http_success`: `url`, `Response` handle
- `http_failure`: `url`, `string` error, `Response?` handle
- `http_check`: `url`, `boolean` success, `string?` reason
- `websocket_success`: `url`, `Websocket` handle
- `websocket_failure`: `url`, `string` error
- `websocket_message`: `url`, `string` message, `boolean` isBinary
- `websocket_closed`: `url`, `string?` reason

## Notes

- HTTP must be enabled in the server config
- URLs are validated against a whitelist/blacklist in the config
- `http.get()`/`http.post()` block; `http.request()` is async
- As of v1.109.0, responses read raw bytes rather than UTF-8 decoded text
