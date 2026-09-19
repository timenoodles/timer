-- tests/test_controls.lua
-- Testes da camada input/controls.lua (sem LÖVE). Rode com: lua tests/test_controls.lua
package.path = package.path .. ";./?.lua"

local Controls = require("input.controls")

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

local function ctx(t)
    t = t or {}
    t.editingTimer = t.editingTimer or nil
    t.focusIndex = t.focusIndex or 1
    t.mode = t.mode or 3
    t.calls = {}
    local c = t.calls
    t.onTypeDigit = function(d) table.insert(c, { "digit", d }) end
    t.onBackspace = function() table.insert(c, { "back" }) end
    t.onConfirm = function() table.insert(c, { "confirm" }) end
    t.onCancel = function() table.insert(c, { "cancel" }) end
    t.onKeypadMove = function(s) table.insert(c, { "move", s }) end
    t.onKeypadActivate = function() table.insert(c, { "activate" }) end
    t.onKeypadConfirmOrActivate = function() table.insert(c, { "confirmOrActivate" }) end
    t.onToggleFocus = function(d) table.insert(c, { "focus", d }) end
    t.onToggleStart = function() table.insert(c, { "start" }) end
    t.onClear = function() table.insert(c, { "clear" }) end
    t.onEdit = function(i) table.insert(c, { "edit", i }) end
    t.onMode = function(m) table.insert(c, { "mode", m }) end
    t.onRename = function(i) table.insert(c, { "rename", i }) end
    t.onCycleSound = function() table.insert(c, { "sound" }) end
    t.onClearSaved = function() table.insert(c, { "clearsaved" }) end
    t.onFullscreen = function() table.insert(c, { "fs" }) end
    t.isShiftDown = function() return t.shift and true or false end
    return t
end

-- Modo normal
do
    local c = ctx()
    Controls.keypressed("space", c)
    check("space start", c.calls[1][1] == "start")
end
do
    local c = ctx()
    Controls.keypressed("r", c)
    check("r clear", c.calls[1][1] == "clear")
end
do
    local c = ctx({ focusIndex = 2 })
    Controls.keypressed("t", c)
    check("t edit focus", c.calls[1][1] == "edit" and c.calls[1][2] == 2)
end
do
    local c = ctx()
    Controls.keypressed("2", c)
    check("2 mode", c.calls[1][1] == "mode" and c.calls[1][2] == 2)
end
do
    local c = ctx()
    Controls.keypressed("tab", c)
    check("tab focus +1", c.calls[1][1] == "focus" and c.calls[1][2] == 1)
end
do
    local c = ctx({ shift = true })
    Controls.keypressed("tab", c)
    check("shift+tab focus -1", c.calls[1][1] == "focus" and c.calls[1][2] == -1)
end
do
    local c = ctx({ focusIndex = 1 })
    Controls.keypressed("n", c)
    check("n rename", c.calls[1][1] == "rename")
end
do
    local c = ctx()
    Controls.keypressed("s", c)
    check("s sound", c.calls[1][1] == "sound")
end
do
    local c = ctx()
    Controls.keypressed("y", c)
    check("y clearsaved", c.calls[1][1] == "clearsaved")
end
do
    local c = ctx()
    Controls.keypressed("f11", c)
    check("f11 fullscreen", c.calls[1][1] == "fs")
end

-- Modo edição (keypad)
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("5", c)
    check("edicao digito", c.calls[1][1] == "digit" and c.calls[1][2] == "5")
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("kp7", c)
    check("edicao kp digito", c.calls[1][1] == "digit" and c.calls[1][2] == "7")
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("backspace", c)
    check("edicao backspace", c.calls[1][1] == "back")
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("left", c)
    check("edicao seta move", c.calls[1][1] == "move" and c.calls[1][2] == -1)
end
do
    local c = ctx({ editingTimer = {}, shift = true })
    Controls.keypressed("tab", c)
    check("edicao tab move -1", c.calls[1][1] == "move" and c.calls[1][2] == -1)
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("space", c)
    check("edicao space activate", c.calls[1][1] == "activate")
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("return", c)
    check("edicao enter confirmOrActivate", c.calls[1][1] == "confirmOrActivate")
end
do
    local c = ctx({ editingTimer = {} })
    Controls.keypressed("escape", c)
    check("edicao esc cancel", c.calls[1][1] == "cancel")
end

-- cellAt
do
    local cells = { { x = 0, y = 0, w = 100, h = 100 }, { x = 110, y = 0, w = 100, h = 100 } }
    check("cellAt 1", Controls.cellAt(50, 50, cells) == 1)
    check("cellAt 2", Controls.cellAt(150, 50, cells) == 2)
    check("cellAt nil", Controls.cellAt(500, 500, cells) == nil)
end

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
