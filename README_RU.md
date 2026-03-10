# kySwitcher — JSON helper (AutoHotkey v2)

Этот репозиторий содержит простой модуль [JSON.ahk](JSON.ahk) для разбора (parse) и сериализации (dump) JSON в **AutoHotkey v2**.

> В проекте модуль используется в [KeysHandler.ahk](KeysHandler.ahk) для загрузки правил из [data/schemes.json](data/schemes.json).

---

🇬🇧 [English version / Английская версия](README.md)

---

## Требования

- AutoHotkey **v2.0+** (см. `#Requires AutoHotkey v2.0` в [JSON.ahk](JSON.ahk)).
- Для чтения файлов с JSON рекомендуется `FileRead(..., "UTF-8")`.

## Быстрый старт

Подключите модуль и вызовите `JSON_Load`:

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

Сериализация обратно в JSON:

```ahk
#Requires AutoHotkey v2.0
#Include "JSON.ahk"

m := Map("lang", "ru", "enabled", true)
arr := [1, 2, 3]
m["nums"] := arr

jsonCompact := JSON_Dump(m)           ; компактно
jsonPretty  := JSON_Dump(m, , 2)      ; pretty-print, 2 пробела

MsgBox jsonCompact
MsgBox jsonPretty
```

## API

### `JSON_Load(text, reviver := "")`

Парсит строку JSON и возвращает:

- JSON object → `Map()`
- JSON array → `Array` (`[]`)
- number → `Integer` или `Float`
- string → `String`
- `true`/`false` → `true`/`false`
- `null` → пустая строка `""`

Если JSON некорректный — бросает `Error(...)`.

#### Reviver

Опционально можно передать `reviver` как callable-объект (функцию), который будет вызван для каждого значения (аналог `JSON.parse(..., reviver)` в JS).

Ожидаемая сигнатура:

```ahk
reviver(parent, key, value)
```

- Возвращаемое значение:
  - любое значение → будет записано обратно
  - **не вернуть значение** (unset) → ключ будет удалён

Пример: удалить все `null` (пустые строки) из результата:

```ahk
#Include "JSON.ahk"

RemoveNull(parent, key, value) {
    if (value == "")
        return  ; unset => удалит key
    return value
}

obj := JSON_Load('{"a":null,"b":1}', Func("RemoveNull"))
; obj теперь содержит только b
```

### `JSON_Dump(value, replacer := "", space := "")`

Сериализует значение AHK в JSON.

Поддерживаются:

- `Map` → JSON object
- `Array` → JSON array
- `Number` → JSON number
- `true`/`false`
- `""` → `null`
- остальные значения → строка (через `String(value)` + экранирование)

Параметры:

- `space`:
  - `""` (по умолчанию) → компактный JSON
  - `Integer` → количество пробелов (максимум 10)
  - `String` → строка отступа (берутся первые 10 символов)
- `replacer`:
  - callable-объект (функция), вызывается на корневом значении (минимальная реализация в модуле).

## Формат данных в этом проекте

Файл [data/schemes.json](data/schemes.json) — это массив объектов, например:

```json
[
  {
    "id": "1",
    "patterns": ["cerf"],
    "action": { "functionName": "switchToRussian" }
  }
]
```

В [KeysHandler.ahk](KeysHandler.ahk) этот JSON загружается так:

- читается файл `schemes.json`
- парсится через `JSON_Load`
- перебираются `patterns`, и при совпадении вызывается `switchToEnglish()` / `switchToRussian()`

## Ограничения / заметки

- `null` преобразуется в `""` (пустую строку) и при `JSON_Dump("")` будет записан как `null`.
- Модуль рассчитан на типичные JSON-данные (объекты/массивы/числа/строки/булевы/null).
- В строках поддерживаются `\uXXXX` escape-последовательности (в пределах 4 hex цифр).

## Лицензия

Лицензия в репозитории не указана. Если нужно — скажите, какую предпочитаете (MIT/Apache-2.0 и т.п.), добавлю файл лицензии.
