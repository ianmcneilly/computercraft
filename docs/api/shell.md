# shell API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/shell.html

The shell API provides access to CraftOS's command shell functionality.

## Functions

### shell.execute(command, ...)
Run a program with arguments passed verbatim (not parsed as command line).
- Parameters: `command`: `string`, `...`: `string` — arguments
- Returns: `boolean`

### shell.run(...)
Run a program by concatenating and parsing arguments as a command line.
- Parameters: `...`: `string` — program and arguments
- Returns: `boolean`
- Notes: Unlike `execute`, arguments are concatenated and split.

### shell.exit()
Exit the current shell. Shuts down the computer if this is the top-level shell.

### shell.dir()
Get the current working directory.
- Returns: `string`

### shell.setDir(dir)
Set the current working directory.
- Parameters: `dir`: `string`
- Throws: if directory doesn't exist

### shell.path()
Get the program search path (colon-separated).
- Returns: `string` — e.g., `.:/rom/programs:/rom/programs/turtle`

### shell.setPath(path)
Set the program search path.
- Parameters: `path`: `string` — colon-separated directories

### shell.resolve(path)
Resolve a relative path to absolute using the current directory.
- Parameters: `path`: `string`
- Returns: `string`

### shell.resolveProgram(command)
Find a program's full path using the search path and aliases.
- Parameters: `command`: `string`
- Returns: `string|nil`

### shell.programs(includeHidden?)
List all available programs on the search path.
- Parameters: `includeHidden?`: `boolean` — include `.`-prefixed files
- Returns: `{ string... }`

### shell.complete(line)
Get auto-completion suggestions for a command line.
- Parameters: `line`: `string`
- Returns: `{ string... }|nil`

### shell.completeProgram(program)
Get completions for a program name.
- Parameters: `program`: `string`
- Returns: `{ string... }`

### shell.setCompletionFunction(program, complete)
Register a tab-completion function for a program.
- Parameters:
  - `program`: `string` — absolute program path (without leading `/`)
  - `complete`: `function(shell, index, argument, previous): { string... }|nil`

### shell.getCompletionInfo()
Get all registered completion functions.
- Returns: `table` — map of program path to `{ fnComplete = function }`

### shell.getRunningProgram()
Get the path of the currently executing program.
- Returns: `string`

### shell.setAlias(command, program)
Create a command alias.
- Parameters: `command`: `string`, `program`: `string`

### shell.clearAlias(command)
Remove a command alias.
- Parameters: `command`: `string`

### shell.aliases()
Get all current aliases.
- Returns: `table` — map of alias name to program path

### shell.openTab(...)
Open a new multishell tab (advanced computers only).
- Parameters: `...`: `string` — command line
- Returns: `number` — tab ID

### shell.switchTab(id)
Switch to a multishell tab.
- Parameters: `id`: `number`

## Notes

- `shell.run()` concatenates and parses; `shell.execute()` passes arguments verbatim
- The search path uses `:` as separator
- Tab functions only work on advanced computers with multishell
