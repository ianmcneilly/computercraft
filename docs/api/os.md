# os API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/os.html

The os API provides functions for events, timers, time, and computer control.

## Event Functions

### os.pullEvent(filter?)
Wait for an event. Terminates the program on Ctrl+T (`terminate` event).
- Parameters: `filter?`: `string` — only return events of this type
- Returns: `string` event name, `any...` event parameters

### os.pullEventRaw(filter?)
Wait for an event without terminate handling. Use to catch or ignore Ctrl+T.
- Parameters: `filter?`: `string` — event type filter
- Returns: `string` event name, `any...` event parameters

### os.queueEvent(name, ...)
Queue a custom event.
- Parameters:
  - `name`: `string` — event name
  - `...`: `any` — event parameters (primitives and tables only)

## Timer / Alarm Functions

### os.startTimer(time)
Start a timer that fires a `timer` event after the given seconds.
- Parameters: `time`: `number` — seconds (minimum 0.05, rounded to nearest tick)
- Returns: `number` — timer ID
- Throws: if time is negative

### os.cancelTimer(token)
Cancel a running timer.
- Parameters: `token`: `number` — timer ID from `startTimer()`

### os.setAlarm(time)
Set an alarm for an in-game time. Fires an `alarm` event.
- Parameters: `time`: `number` — in-game time (0.0–24.0)
- Returns: `number` — alarm ID
- Throws: if time out of range

### os.cancelAlarm(token)
Cancel a set alarm.
- Parameters: `token`: `number` — alarm ID from `setAlarm()`

## Sleep

### os.sleep(time)
Pause execution for the given number of seconds.
- Parameters: `time`: `number` — seconds (rounded to nearest 0.05)
- Notes: Also available as the global `sleep()`. Yields the coroutine.

## Time Functions

### os.clock()
Get time since the computer started.
- Returns: `number` — uptime in seconds

### os.time(locale?)
Get the current time.
- Parameters: `locale?`: `string` — `"ingame"` (default), `"utc"`, or `"local"`
- Returns: `number` — hour (0.0–24.0) for string locales
- Notes: Can also accept a date table to convert to UNIX timestamp.

### os.day(locale?)
Get the current day number.
- Parameters: `locale?`: `string` — `"ingame"` (default), `"utc"`, or `"local"`
- Returns: `number` — days since epoch

### os.epoch(locale?)
Get milliseconds since epoch.
- Parameters: `locale?`: `string` — `"ingame"` (default), `"utc"`, or `"local"`
- Returns: `number` — milliseconds
- Notes: For ingame, 1 real second = 72,000 in-game milliseconds.

### os.date(format?, time?)
Format a date/time string.
- Parameters:
  - `format?`: `string` — strftime format (default `"%c"`). Use `"*t"` for table, prefix `"!"` for UTC.
  - `time?`: `number` — timestamp (default current time)
- Returns: `string` or `table` — `{ year, month, day, hour, min, sec, wday, yday, isdst }`

## Computer Control

### os.shutdown()
Shut down the computer immediately.

### os.reboot()
Reboot the computer immediately.

### os.getComputerID()
Get this computer's unique ID.
- Returns: `number`
- Aliases: `os.computerID()`

### os.getComputerLabel()
Get this computer's label.
- Returns: `string|nil`
- Aliases: `os.computerLabel()`

### os.setComputerLabel(label?)
Set or clear this computer's label.
- Parameters: `label?`: `string` — new label, or nil to clear

## Program Execution

### os.run(env, path, ...)
Run a program with a given environment.
- Parameters:
  - `env`: `table` — execution environment
  - `path`: `string` — exact program path (does not resolve like shell.run)
  - `...`: `any` — arguments
- Returns: `boolean`

## Deprecated

### os.loadAPI(path)
Load an API file into the global namespace. Use `require()` instead.
- Returns: `boolean`

### os.unloadAPI(name)
Unload a previously loaded API.
