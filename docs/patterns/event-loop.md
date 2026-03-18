# Event Loop Pattern

The standard way to handle multiple event types in CC:T.

## Basic Event Loop

```lua
while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" then
        handleMessage(p1, p2, p3)
    elseif event == "monitor_touch" then
        handleTouch(p1, p2, p3)
    elseif event == "key" then
        handleKey(p1, p2)
    end
end
```

## Filtered Event Loop

Pull only specific events (more efficient):

```lua
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    handleTouch(side, x, y)
end
```

## Event Loop with Timeout

```lua
local timer = os.startTimer(5)
while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "timer" and p1 == timer then
        print("Timed out!")
        timer = os.startTimer(5) -- restart timer
    elseif event == "rednet_message" then
        handleMessage(p1, p2, p3)
        timer = os.startTimer(5) -- reset timer on activity
    end
end
```

## Notes

- `os.pullEvent()` yields the coroutine — other parallel tasks can run
- `os.pullEvent()` throws on `terminate` event (Ctrl+T). Use `os.pullEventRaw()` if you need to catch or ignore termination
- Filtering with `os.pullEvent("event_name")` internally discards non-matching events — those events are lost to your program
- Events are queued — if your handler is slow, events stack up but won't be lost
- Common events: `key`, `key_up`, `char`, `mouse_click`, `mouse_up`, `mouse_scroll`, `mouse_drag`, `monitor_touch`, `monitor_resize`, `rednet_message`, `timer`, `alarm`, `disk`, `disk_eject`, `peripheral`, `peripheral_detach`, `redstone`, `terminate`
