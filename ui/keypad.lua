-- ui/keypad.lua
-- Teclado numérico modal para digitar o tempo.

local Button = require("button")

local Keypad = {}
Keypad.__index = Keypad

function Keypad.new(callbacks)
    local self = setmetatable({}, Keypad)
    self.cb = callbacks or {}
    self.digitButtons = {}
    -- Grade estilo calculadora: última linha BKSP 0 C (C = limpar).
    local labels = { "7", "8", "9", "4", "5", "6", "1", "2", "3", "BKSP", "0", "C" }
    for idx, lab in ipairs(labels) do
        local style = "blue"
        local action
        if lab == "BKSP" then
            style = "gray"
            action = function() if self.cb.onBackspace then self.cb.onBackspace() end end
        elseif lab == "C" then
            style = "red"
            action = function() if self.cb.onClear then self.cb.onClear() end end
        else
            action = function() if self.cb.onDigit then self.cb.onDigit(lab) end end
        end
        self.digitButtons[idx] = Button.new(0, 0, 10, 10, lab, style, action)
    end
    self.cancelBtn = Button.new(0, 0, 10, 10, "X", "gray", function()
        if self.cb.onCancel then self.cb.onCancel() end
    end)
    self.okBtn = Button.new(0, 0, 10, 10, "OK", "green", function()
        if self.cb.onConfirm then self.cb.onConfirm() end
    end)
    self.sel = nil -- índice 1..14 da seleção por teclado (nil = sem seleção)
    return self
end

function Keypad:reposition(screenW, screenH)
    local cols = 3
    local kw = 300
    local cellW = kw / cols
    local cellH = 52
    local pad = 8
    local modalW = kw + 40
    local titleH = 30
    local digitH = 76
    local actionRowH = 42
    local gridH = cellH * 4
    local topPad, midPad, bottomPad = 12, 10, 14
    -- Grade do teclado + linha final CANCELAR | OK.
    local modalH = topPad + titleH + digitH + midPad + gridH + midPad + actionRowH + bottomPad
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2
    local x0 = modalX + 20
    local y0 = modalY + topPad + titleH + digitH + midPad
    for idx, btn in ipairs(self.digitButtons) do
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        btn:setRect(x0 + col * cellW + pad / 2, y0 + row * cellH + pad / 2, cellW - pad, cellH - pad)
    end
    local actionY = y0 + gridH + midPad
    self.cancelBtn:setRect(x0, actionY, (kw / 2) - 4, actionRowH)
    self.okBtn:setRect(x0 + kw / 2 + 4, actionY, (kw / 2) - 4, actionRowH)
    self.x, self.y, self.w, self.h = modalX, modalY, modalW, modalH
    self.titleY = modalY + topPad
    self.digitY = modalY + topPad + titleH
    self.digitH = digitH
end

function Keypad:collectButtons(list)
    for _, btn in ipairs(self.digitButtons) do table.insert(list, btn) end
    table.insert(list, self.cancelBtn)
    table.insert(list, self.okBtn)
end

local function keypadButtonCount() return 14 end -- 12 dígitos + X + OK

function Keypad:allButtons()
    local list = {}
    self:collectButtons(list)
    return list
end

-- Move a seleção por teclado (setas/Tab); wrap 1..14. Primeira chamada seleciona a ponta.
function Keypad:moveSel(step)
    local n = keypadButtonCount()
    if not self.sel then
        self.sel = (step or 1) < 0 and n or 1
    else
        self.sel = ((self.sel - 1 + (step or 1)) % n) + 1
    end
end

function Keypad:hasSelection() return self.sel ~= nil end

function Keypad:clearSelection() self.sel = nil end

-- Ativa o botão selecionado (Space/Enter); sem seleção retorna false.
function Keypad:activateSelected()
    if not self.sel then return false end
    local btns = self:allButtons()
    local btn = btns[self.sel]
    if btn then btn:trigger() end
    return true
end

function Keypad:draw(theme, editingTimer, screenW, screenH)
    if not editingTimer then return end
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    love.graphics.setColor(theme.colors.caseBg)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 16, 16)
    love.graphics.setColor(theme.colors.caseBorder)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 16, 16)
    love.graphics.setFont(theme.fonts.uiLarge)
    love.graphics.setColor(theme.colors.label)
    love.graphics.printf(editingTimer.label or "", self.x, self.titleY, self.w, "center")
    love.graphics.setFont(theme.fonts.lcdMed)
    -- Painel LCD escuro atrás dos dígitos (contraste: dígitos claros sobre fundo escuro).
    local lcdMarginX = 20
    local lcdX, lcdW = self.x + lcdMarginX, self.w - lcdMarginX * 2
    love.graphics.setColor(theme.colors.lcdBg)
    love.graphics.rectangle("fill", lcdX, self.digitY + 4, lcdW, self.digitH - 8, 8, 8)
    -- Auto-ajuste: encolhe a fonte se o texto (ex: 8:88:88) estourar o painel.
    local text = editingTimer:getDisplayText()
    local dFont = theme.fonts.lcdMed
    for _, cand in ipairs({ theme.fonts.lcdMed, theme.fonts.lcdSmall }) do
        if cand and cand:getWidth(text) <= lcdW - 16 then
            dFont = cand
            break
        end
        dFont = cand or dFont
    end
    love.graphics.setFont(dFont)
    love.graphics.setColor(theme.colors.lcdDigitOn)
    local dy = self.digitY + (self.digitH - dFont:getHeight()) / 2
    love.graphics.printf(text, lcdX + 8, dy, lcdW - 16, "center")
    for _, btn in ipairs(self.digitButtons) do btn:draw() end
    self.cancelBtn:draw()
    self.okBtn:draw()
    -- Anel de foco da seleção por teclado.
    if self.sel then
        local btns = self:allButtons()
        local btn = btns[self.sel]
        if btn then
            love.graphics.setColor(theme.colors.focusRing)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", btn.x - 2, btn.y - 2, btn.w + 4, btn.h + 4, 6, 6)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Keypad
