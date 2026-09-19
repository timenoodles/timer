-- input/controls.lua
-- Camada de entrada: teclado + clique em célula. Sem desenho, sem love direto
-- além de love.keyboard para Shift (injetável via ctx.isShiftDown em testes).

local Controls = {}

local digitKeys = {
    ["0"] = "0", ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4",
    ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9",
    ["kp0"] = "0", ["kp1"] = "1", ["kp2"] = "2", ["kp3"] = "3", ["kp4"] = "4",
    ["kp5"] = "5", ["kp6"] = "6", ["kp7"] = "7", ["kp8"] = "8", ["kp9"] = "9",
}

-- ctx: { editingTimer, timers, focusIndex, mode,
--   onTypeDigit(d), onBackspace(), onConfirm(), onCancel(),
--   onFocus(i), onToggleFocus(dir), onToggleStart(), onClear(),
--   onEdit(i), onMode(m), isShiftDown(),
--   onKeypadMove(step), onKeypadActivate(), onKeypadConfirmOrActivate() }
local function isShiftDown(ctx)
    if ctx.isShiftDown ~= nil then
        return ctx.isShiftDown()
    end
    return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function Controls.keypressed(key, ctx)
    if ctx.editingTimer then
        if digitKeys[key] then
            ctx.onTypeDigit(digitKeys[key])
        elseif key == "backspace" then
            ctx.onBackspace()
        elseif key == "left" then
            ctx.onKeypadMove(-1)
        elseif key == "right" then
            ctx.onKeypadMove(1)
        elseif key == "up" then
            ctx.onKeypadMove(-3)
        elseif key == "down" then
            ctx.onKeypadMove(3)
        elseif key == "tab" then
            ctx.onKeypadMove(isShiftDown(ctx) and -1 or 1)
        elseif key == "space" then
            ctx.onKeypadActivate()
        elseif key == "return" or key == "kpenter" then
            ctx.onKeypadConfirmOrActivate()
        elseif key == "escape" then
            ctx.onCancel()
        end
        return
    end
    if key == "tab" then
        ctx.onToggleFocus(isShiftDown(ctx) and -1 or 1)
    elseif key == "space" then
        ctx.onToggleStart()
    elseif key == "r" then
        ctx.onClear()
    elseif key == "t" then
        ctx.onEdit(ctx.focusIndex)
    elseif key == "1" or key == "2" or key == "3" then
        ctx.onMode(tonumber(key))
    end
end

-- Retorna índice da célula clicada ou nil.
function Controls.cellAt(x, y, cells)
    for i, c in ipairs(cells) do
        if x >= c.x and x <= c.x + c.w and y >= c.y and y <= c.y + c.h then
            return i
        end
    end
    return nil
end

return Controls
