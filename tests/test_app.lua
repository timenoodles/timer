-- tests/test_app.lua
-- Testes do controlador App (sem LÖVE). Rode com: lua tests/test_app.lua
package.path = package.path .. ";./?.lua"

local App = require("app")

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

do
    local a = App.new()
    check("modo inicial 1", a.mode == 1 and a.focusIndex == 1)
    check("setMode 3", a:setMode(3) and a.mode == 3)
    check("setMode inválido", (not a:setMode(9)) and a.mode == 3)
end
do
    local a = App.new({ mode = 3 })
    a:setFocus(2)
    check("setFocus", a.focusIndex == 2)
    check("setFocus fora do modo", (not a:setFocus(3) or true) and a:setFocus(2))
    a:setMode(1)
    check("setMode recolhe foco", a.focusIndex == 1)
end
do
    local a = App.new({ mode = 3 })
    a:moveFocus(1)
    check("moveFocus +1", a.focusIndex == 2)
    a:setFocus(3) a:moveFocus(1)
    check("moveFocus wrap fim", a.focusIndex == 1)
    a:moveFocus(-1)
    check("moveFocus wrap início", a.focusIndex == 3)
end
do
    local a = App.new({ soundMode = "off" })
    check("cycle off->beep", a:cycleSound() == "beep")
    check("cycle beep->repeat3", a:cycleSound() == "repeat3")
    check("cycle repeat3->repeat", a:cycleSound() == "repeat")
    check("cycle repeat->off", a:cycleSound() == "off")
end
do
    local a = App.new()
    a:startRename(2, "T2")
    check("renaming ativo", a:isRenaming() and a.renameBuffer == "T2")
    a:renameInput("a")
    check("rename upper", a.renameBuffer == "T2A")
    a:renameBackspace()
    check("rename backspace", a.renameBuffer == "T2")
    a:cancelRename()
    check("rename cancel", not a:isRenaming())
end
do
    local a = App.new({ maxLabelLen = 3 })
    a:startRename(1, "")
    a:renameInput("a") a:renameInput("b") a:renameInput("c")
    check("rename limite", a.renameBuffer == "ABC" and a:renameInput("d") == false)
end
do
    -- Regressão: README documenta CAFÉ como nome válido (%w rejeitava É).
    local a = App.new()
    a:startRename(1, "")
    check("rename aceita É", a:renameInput("É") and a.renameBuffer == "É")
    a:cancelRename()
    a:startRename(1, "")
    for _, ch in ipairs({ "c", "a", "f", "é" }) do a:renameInput(ch) end
    check("rename café→CAFÉ", a.renameBuffer == "CAFÉ")
    a:renameBackspace()
    check("rename backspace acento", a.renameBuffer == "CAF")
    a:cancelRename()
    a:startRename(1, "")
    check("rename rejeita controle", (not a:renameInput("\7")) and a.renameBuffer == "")
end

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
