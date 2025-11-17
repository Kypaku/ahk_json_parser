#Requires AutoHotkey v2.0
; Lightweight JSON (no classes)

; Extracted helper functions for parsing
skipWhitespace(&pos, len, text) {
    while (pos <= len) {
        ch := SubStr(text, pos, 1)
        if !InStr(" `t`r`n", ch)
            break
        pos++
    }
}

parseValue(&pos, len, text) {
    skipWhitespace(&pos, len, text)
    if (pos > len)
        throw Error("Unexpected end of JSON")
    ch := SubStr(text, pos, 1)
    if (ch = "{")
        return parseObject(&pos, len, text)
    if (ch = "[")
        return parseArray(&pos, len, text)
    if (ch = Chr(34))
        return parseString(&pos, text)
    if RegExMatch(SubStr(text, pos), "^-?\d")
        return parseNumber(&pos, text)
    if (SubStr(text, pos, 4) = "true") {
        pos += 4
        return true
    }
    if (SubStr(text, pos, 5) = "false") {
        pos += 5
        return false
    }
    if (SubStr(text, pos, 4) = "null") {
        pos += 4
        return ""
    }
    throw Error("Invalid token at pos " . pos)
}

parseObject(&pos, len, text) {
    obj := Map()
    pos++ ; skip {
    skipWhitespace(&pos, len, text)
    if (SubStr(text, pos, 1) = "}") {
        pos++
        return obj
    }
    loop {
        skipWhitespace(&pos, len, text)
        if (SubStr(text, pos, 1) != Chr(34))
            throw Error("Expected ' at pos " . pos)
        key := parseString(&pos, text)
        skipWhitespace(&pos, len, text)
        if (SubStr(text, pos, 1) != ":")
            throw Error("Expected ':' after key at pos " . pos)
        pos++
        val := parseValue(&pos, len, text)
        obj[key] := val
        skipWhitespace(&pos, len, text)
        ch := SubStr(text, pos, 1)
        if (ch = "}") {
            pos++
            break
        }
        if (ch != ",")
            throw Error("Expected ',' or '}' at pos " . pos)
        pos++
    }
    return obj
}

parseArray(&pos, len, text) {
    arr := []
    pos++ ; skip [
    skipWhitespace(&pos, len, text)
    if (SubStr(text, pos, 1) = "]") {
        pos++
        return arr
    }
    loop {
        val := parseValue(&pos, len, text)
        arr.Push(val)
        skipWhitespace(&pos, len, text)
        ch := SubStr(text, pos, 1)
        if (ch = "]") {
            pos++
            break
        }
        if (ch != ",")
            throw Error("Expected ',' or ']' at pos " . pos)
        pos++
    }
    return arr
}

parseString(&pos, text) {
    if (SubStr(text, pos, 1) != Chr(34))
        throw Error("Expected ' at pos " . pos)
    pos++
    out := ""
    while (pos <= StrLen(text)) {
        ch := SubStr(text, pos, 1)
        if (ch = Chr(34)) {
            pos++
            return out
        }
        if (ch = "\") {
            pos++
            esc := SubStr(text, pos, 1)
            if (esc = Chr(34))
                out .= Chr(34)
            else if (esc = "\")
                out .= "\\"
            else if (esc = "/")
                out .= "/"
            else if (esc = "b")
                out .= "`b"
            else if (esc = "f")
                out .= "`f"
            else if (esc = "n")
                out .= "`n"
            else if (esc = "r")
                out .= "`r"
            else if (esc = "t")
                out .= "`t"
            else if (esc = "u") {
                hex := SubStr(text, pos+1, 4)
                if !RegExMatch(hex, "^[0-9A-Fa-f]{4}$")
                    throw Error("Bad \u escape at pos " . pos)
                out .= Chr(Integer("0x" . hex))
                pos += 4
            } else
                throw Error("Bad escape at pos " . pos)
        } else {
            out .= ch
        }
        pos++
    }
    throw Error("Unterminated string")
}

parseNumber(&pos, text) {
    m := ""
    if !RegExMatch(SubStr(text, pos), "^-?\d+(\.\d+)?([eE][+-]?\d+)?", &m)
        throw Error("Invalid number at pos " . pos)
    pos += StrLen(m[0])
    num := m[0]
    if InStr(num, ".") || RegExMatch(num, "[eE]")
        return Float(num)
    return Integer(num)
}

Walk(parent, key, reviver) {
    val := parent[key]
    if IsObject(val) {
        if (val is Array) {
            loop val.Length
                Walk(val, A_Index, reviver)
        } else { ; Map
            for k, _ in val
                Walk(val, k, reviver)
        }
    }
    newVal := reviver.Call(parent, key, val)
    if !IsSet(newVal)
        parent.Delete(key)
    else
        parent[key] := newVal
}

JSON_Load(text, reviver:="") {
    pos := 1
    len := StrLen(text)
    root := parseValue(&pos, len, text)
    skipWhitespace(&pos, len, text)
    if (pos <= len)
        throw Error("Extra data at pos " . pos)
    if (IsObject(reviver)) {
        tmp := Map("", root)
        Walk(tmp, "", reviver)
        return tmp[""]
    }
    return root
}

; Extracted helper functions for dumping
quote(s) {
    static q := Chr(34), rx := "[^\x20-\x21\x23-\x5B\x5D-\x7E]"
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, q, "\" . q) ; escape quotes
    s := StrReplace(s, "`b", "\b")
    s := StrReplace(s, "`f", "\f")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`t", "\t")
    while RegExMatch(s, rx, &m)
        s := StrReplace(s, m.Value, Format("\u{1:04X}", Ord(m.Value)))
    return q . s . q
}

dump(val, level, gap, indent, isFunc, replacer) {
    if (isFunc)
        val := replacer.Call(Map(), "", val)

    if (val is Map) {
        keys := []
        for k, _ in val
            keys.Push(k)
        out := ""
        for i, k in keys {
            v := dump(val[k], level+1, gap, indent, isFunc, replacer)
            if (v = "")
                continue
            entry := quote(k) . (gap != "" ? ": " : ":") . v
            if (gap != "")
                out .= indent . gap . entry . ","
            else
                out .= entry . ","
        }
        if (out != "") {
            out := RTrim(out, ",")
            if (gap != "")
                return "{" . out . indent . (level>0 ? SubStr(gap, 1, StrLen(gap)*(level-1)) : "") . "}"
            return "{" . out . "}"
        }
        return "{}"
    } else if (val is Array) {
        out := ""
        for i, v in val {
            sv := dump(v, level+1, gap, indent, isFunc, replacer)
            if (sv = "")
                sv := "null"
            if (gap != "")
                out .= indent . gap . sv . ","
            else
                out .= sv . ","
        }
        if (out != "") {
            out := RTrim(out, ",")
            if (gap != "")
                return "[" . out . indent . SubStr(gap, 1, (level>0)?StrLen(gap)*(level-1):0) . "]"
            return "[" . out . "]"
        }
        return "[]"
    } else if (val is Number) {
        return val
    } else if (val == true)
        return "true"
    else if (val == false)
        return "false"
    else if (val == "")
        return "null"
    else
        return quote(String(val))
}

JSON_Dump(value, replacer:="", space:="") {
    gap := ""
    indent := ""
    if (space != "") {
        if space is Integer {
            Loop ((n := Abs(Integer(space)))>10 ? 10 : n)
                gap .= " "
        } else
            gap := SubStr(space, 1, 10)
        indent := "`n"
    }

    isFunc := IsObject(replacer)

    return dump(value, 0, gap, indent, isFunc, replacer)
}