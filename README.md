# 🌿 ivy's luau table serializer 🌿

<p align="center">
  <em>make your tables ✨pretty✨ • readable • git-diff friendly</em>
</p>
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
![luau](https://img.shields.io/badge/lang-luau-ff69b4)
![stars](https://img.shields.io/github/stars/IvyyDev/luau-signal?style=social)

---

## 🌸 what is this?
tiny luau utility that turns tables into **valid, neat lua source**.  
sorted keys, trailing commas, pretty indents. your diffs will thank you.

---

## 🌱 install (2 lines!)
```lua
local src = game:HttpGet("https://raw.githubusercontent.com/IvyyDev/luau-serializer/main/Serializer.luau")
local Serializer = loadstring(src)()
```

---

## 🍃 quick taste
```lua
print(Serializer.serialize({
  hello = "world",
  nums = { 1, 2, 3 },
}))
```

➡️ spits out:

```lua
local tbl = {
  hello = "world",
  nums = {
    1,
    2,
    3,
  },
}

return tbl
```

---

## 🌼 options
```luau
type Options = {
  pretty: boolean?,        -- default true
  indent: string?,         -- default "  "
  sortKeys: boolean?,      -- default true
  trailingComma: boolean?, -- default true
  maxDepth: number?,       -- default math.huge
  detectCycles: boolean?,  -- default true
  customSerialize: ((any, string) -> string?)?, -- your own magic
}
```

---

## 🌷 custom serialize example
```lua
local out = Serializer.serialize({
  color = Color3.fromRGB(10, 20, 30),
}, {
  customSerialize = function(v)
    if typeof(v) == "Color3" then
      return string.format("Color3.fromRGB(%d, %d, %d)", v.R*255, v.G*255, v.B*255)
    end
  end,
})
print(out)
```

---

## 🌻 notes
- outputs a **chunk** (`local tbl = ...; return tbl`)  
- `nil` fields vanish (because lua can’t encode them)  
- cycles get caught & throw (no infinite loops here!)  

---

## 🪻 license
[MIT](./LICENSE) — use it, break it, ship it, whatever.  
just don’t forget to 🌸 credit 🌸
