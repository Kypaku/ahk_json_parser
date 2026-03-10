# kySwitcher — JSON helper (AutoHotkey v2)

This repository contains a simple module [JSON.ahk](JSON.ahk) for parsing and serializing JSON in **AutoHotkey v2**.

> In the project, the module is used in [KeysHandler.ahk](KeysHandler.ahk) to load rules from [data/schemes.json](data/schemes.json).

---

🇷🇺 [Русская версия / Russian version](README_RU.md)

---

## Requirements

- AutoHotkey **v2.0+** (see `#Requires AutoHotkey v2.0` in [JSON.ahk](JSON.ahk)).
- For reading JSON files, `FileRead(..., "UTF-8")` is recommended.

## Quick Start

Include the module and call `JSON_Load`:

```ahk
#Requires AutoHotkey v2.0
#Include "JSON.ahk"

text := '{"a": 1, "b": [true, null, "x"]}'
obj := JSON_Load(text)

MsgBox obj["a"]            ; 1
MsgBox obj["b"][1]          ; true
MsgBox obj["b"][2]          ; ""  (null -> "")
MsgBox obj["b"][3]          ; x
```

Serialize back to JSON:

```ahk
#Requires AutoHotkey v2.0
#Include "JSON.ahk"

m := Map("lang", "ru", "enabled", true)
arr := [1, 2, 3]
m["nums"] := arr

jsonCompact := JSON_Dump(m)           ; compact
jsonPretty  := JSON_Dump(m, , 2)      ; pretty-print, 2 spaces

MsgBox jsonCompact
MsgBox jsonPretty
```

## API

### `JSON_Load(text, reviver := "")`

Parses a JSON string and returns:

- JSON object → `Map()`
- JSON array → `Array` (`[]`)
- number → `Integer` or `Float`
- string → `String`
- `true`/`false` → `true`/`false`
- `null` → empty string `""`

If the JSON is invalid, throws `Error(...)`.

#### Reviver

Optionally, a `reviver` callable (function) can be passed. It will be called for every value (similar to `JSON.parse(..., reviver)` in JS).

Expected signature:

```ahk
reviver(parent, key, value)
```

- Return value:
  - any value → will be written back
  - **no return** (unset) → the key will be deleted

Example: remove all `null` (empty strings) from the result:

```ahk
#Include "JSON.ahk"

RemoveNull(parent, key, value) {
    if (value == "")
        return  ; unset => removes the key
    return value
}

obj := JSON_Load('{"a":null,"b":1}', Func("RemoveNull"))
; obj now contains only b
```

### `JSON_Dump(value, replacer := "", space := "")`

Serializes an AHK value to JSON.

Supported types:

- `Map` → JSON object
- `Array` → JSON array
- `Number` → JSON number
- `true`/`false`
- `""` → `null`
- other values → string (via `String(value)` + escaping)

Parameters:

- `space`:
  - `""` (default) → compact JSON
  - `Integer` → number of spaces (maximum 10)
  - `String` → indent string (first 10 characters are used)
- `replacer`:
  - callable (function), called on the root value (minimal implementation in the module).

## Data Format in This Project

The file [data/schemes.json](data/schemes.json) is an array of objects, for example:

```json
[
  {
    "id": "1",
    "patterns": ["cerf"],
    "action": { "functionName": "switchToRussian" }
  }
]
```

In [KeysHandler.ahk](KeysHandler.ahk) this JSON is loaded as follows:

- the `schemes.json` file is read
- parsed via `JSON_Load`
- `patterns` are iterated, and on match `switchToEnglish()` / `switchToRussian()` is called

## Limitations / Notes

- `null` is converted to `""` (empty string), and `JSON_Dump("")` will write it as `null`.
- The module is designed for typical JSON data (objects/arrays/numbers/strings/booleans/null).
- `\uXXXX` escape sequences are supported in strings (within 4 hex digits).

## License

No license is specified in the repository. If needed, let us know which one you prefer (MIT/Apache-2.0, etc.) and a license file will be added.
