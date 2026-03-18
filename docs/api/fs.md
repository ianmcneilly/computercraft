# fs API

> Source: CC:T 1.115.1 — https://tweaked.cc/module/fs.html

Interact with the computer's filesystem — read, write, list, and manipulate files and directories.

## Functions

### fs.complete(path, location, includeFiles?, includeDirs?)
Provide completion candidates for a file path.
- Parameters:
  - `path`: `string` — partial path to complete
  - `location`: `string` — base directory
  - `includeFiles?`: `boolean`
  - `includeDirs?`: `boolean`
- Returns: `{ string... }` — completion candidates

### fs.find(path)
Find files matching a wildcard pattern.
- Parameters: `path`: `string` — pattern with `?` (single char) and `*` (any chars)
- Returns: `{ string... }` — matching file paths

### fs.isDriveRoot(path)
Check if a path is a filesystem mount point (e.g., `/`, `/rom`, `/disk`).
- Parameters: `path`: `string`
- Returns: `boolean`

### fs.list(path)
List directory contents.
- Parameters: `path`: `string`
- Returns: `{ string... }` — filenames (not full paths)
- Throws: if path is not a directory or doesn't exist

### fs.combine(path, ...)
Join path components.
- Parameters: `path`: `string`, `...`: `string` — path segments
- Returns: `string` — combined, normalized path

### fs.getName(path)
Get the filename from a path.
- Parameters: `path`: `string`
- Returns: `string`

### fs.getDir(path)
Get the parent directory from a path.
- Parameters: `path`: `string`
- Returns: `string`

### fs.getSize(path)
Get file size in bytes.
- Parameters: `path`: `string`
- Returns: `number`
- Throws: if path doesn't exist

### fs.exists(path)
Check if a path exists.
- Parameters: `path`: `string`
- Returns: `boolean`

### fs.isDir(path)
Check if a path is a directory.
- Parameters: `path`: `string`
- Returns: `boolean`

### fs.isReadOnly(path)
Check if a path is read-only.
- Parameters: `path`: `string`
- Returns: `boolean`

### fs.makeDir(path)
Create a directory (and parents as needed).
- Parameters: `path`: `string`
- Throws: on failure

### fs.move(path, dest)
Move a file or directory.
- Parameters: `path`: `string`, `dest`: `string`
- Throws: on failure

### fs.copy(path, dest)
Copy a file or directory tree.
- Parameters: `path`: `string`, `dest`: `string`
- Throws: on failure

### fs.delete(path)
Delete a file or directory tree.
- Parameters: `path`: `string`

### fs.open(path, mode)
Open a file. Returns a handle or nil + error message.
- Parameters:
  - `path`: `string`
  - `mode`: `string` — `"r"` (read), `"w"` (write), `"a"` (append), `"r+"` (read-write update), `"w+"` (read-write truncate). Append `"b"` for binary mode (e.g., `"rb"`, `"wb"`).
- Returns: `ReadHandle|WriteHandle|ReadWriteHandle` or `nil, string`

### fs.getDrive(path)
Get the mount name for a path.
- Parameters: `path`: `string`
- Returns: `string|nil` — e.g., `"hdd"`, `"rom"`, `"disk"`

### fs.getFreeSpace(path)
Get available space on the drive containing the path.
- Parameters: `path`: `string`
- Returns: `number|"unlimited"`

### fs.getCapacity(path)
Get total drive capacity.
- Parameters: `path`: `string`
- Returns: `number|nil` — nil for read-only drives

### fs.attributes(path)
Get comprehensive file metadata.
- Parameters: `path`: `string`
- Returns: `table` — `{ size: number, isDir: boolean, isReadOnly: boolean, created: number, modified: number }` (timestamps in ms since UNIX epoch)

## ReadHandle Methods

### handle.read(count?)
- Without count: returns next byte as `number|nil`
- With count: returns `string|nil` of up to `count` characters

### handle.readAll()
- Returns: `string|nil` — entire remaining file contents

### handle.readLine(withTrailing?)
- Parameters: `withTrailing?`: `boolean` — include newline character
- Returns: `string|nil` — next line or nil at EOF

### handle.close()
Close the file handle.

## WriteHandle Methods

### handle.write(...)
Write string or number values.
- Parameters: `...`: `string|number`

### handle.writeLine(text)
Write a line with trailing newline.
- Parameters: `text`: `string`

### handle.flush()
Flush buffered data to disk.

### handle.close()
Close the file handle.

## BinaryReadHandle Methods

Same as ReadHandle, plus:

### handle.seek(whence?, offset?)
Move the read position.
- Parameters: `whence?`: `string` — `"set"`, `"cur"`, or `"end"` (default `"cur"`), `offset?`: `number` (default 0)
- Returns: `number` new position, or `nil, string` on error

## BinaryWriteHandle Methods

Same as WriteHandle, plus:

### handle.seek(whence?, offset?)
Move the write position.
- Parameters: `whence?`: `string`, `offset?`: `number`
- Returns: `number` new position, or `nil, string` on error

## ReadWriteHandle Methods

Combines all ReadHandle and WriteHandle methods (available with `"r+"` and `"w+"` modes).

## Notes

- All paths are relative to the computer's root — no leading slash needed
- Forward slashes only
- `fs.open()` handles MUST be closed explicitly — use `handle.close()`
- Binary mode (`"rb"`, `"wb"`) works with raw bytes; text mode handles line endings
