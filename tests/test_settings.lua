-- tests/test_settings.lua
-- Testes do modal ui/settings.lua (sem LÖVE; sem draw). Rode com: lua tests/test_settings.lua
package.path = package.path .. ";./?.lua"

local Settings = require("ui.settings")

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

local sound, themeName, autosave = "repeat3", "classic", true
local presets = { 20, 10, 5 }
local cleared = false
local s = Settings.new({
    getSound = function() return sound end,
    setSound = function(m) sound = m end,
    getTheme = function() return themeName end,
    setTheme = function(n) themeName = n end,
    getAutosave = function() return autosave end,
    setAutosave = function(v) autosave = v end,
    getPresets = function() return presets end,
    adjustPreset = function(i, dir)
        presets[i] = math.max(1, math.min(99, presets[i] + dir))
    end,
    onClearSaved = function() cleared = true end,
})

check("fechado inicial", not s:isOpen())
s:show()
check("abre", s:isOpen())
s:keypressed("down", false)
check("down move sel", s.sel == 2)
s:keypressed("right", false) -- tema classic -> dark
check("right troca tema", themeName == "dark")
s:keypressed("up", false)
s:keypressed("right", false) -- som repeat3 -> repeat
check("right troca som", sound == "repeat")
s:keypressed("down", false) s:keypressed("down", false) -- sel 3 (autosave)
s:keypressed("space", false)
check("space alterna autosave", autosave == false)
s.sel = 4
s:keypressed("right", false) -- preset 1 +1
check("preset +1", presets[1] == 21)
s:keypressed("left", false)
check("preset -1", presets[1] == 20)
s.sel = 7
s:keypressed("return", false)
check("enter limpa save", cleared == true)
s:keypressed("escape", false)
check("esc fecha", not s:isOpen())

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
