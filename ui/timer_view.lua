-- ui/timer_view.lua
-- Encapsula os botoes e o desenho de uma celula de timer.
-- main.lua só chama updateLayout / refresh / draw / collectButtons.

local Button = require("button")

local TimerView = {}
TimerView.__index = TimerView

local function rowHeightFor(cellH)
    return math.max(36, math.min(56, cellH * 0.18))
end

function TimerView.new(timer, onEditRequest)
    local self = setmetatable({}, TimerView)
    self.timer = timer
    self.onEditRequest = onEditRequest
    local t = timer
    self.preset20 = Button.new(0, 0, 10, 10, "20m", "yellow", function() t:addPreset(20) end)
    self.preset10 = Button.new(0, 0, 10, 10, "10m", "yellow", function() t:addPreset(10) end)
    self.preset5  = Button.new(0, 0, 10, 10, "5m",  "yellow", function() t:addPreset(5) end)
    self.setBtn   = Button.new(0, 0, 10, 10, "SET", "blue", function()
        if onEditRequest then onEditRequest() end
    end)
    self.startStopBtn = Button.new(0, 0, 10, 10, "START", "green", function() t:toggleStartStop() end)
    self.clearBtn = Button.new(0, 0, 10, 10, "", "gray", function() t:clear() end)
    self.clearBtn.icon = "reset" -- arco vetorial desenhado por cima; label vazio (sem texto morto)
    self.clearBtn.accessibleLabel = "CLR" -- texto alternativo p/ acessibilidade/log
    return self
end

function TimerView:updateLayout(cell)
    -- Hierarquia: START/PAUSE primário (largo), presets+SET secundários,
    -- reset ↻ terciário (pequeno, discreto).
    local rowH = rowHeightFor(cell.h)
    local rowY = cell.y + cell.h - rowH - 8
    local rowX = cell.x + 10
    local rowW = cell.w - 20
    local gap = 8
    local resetW = math.min(46, rowW * 0.08)
    local availW = rowW - resetW - gap
    local weights = { 1, 1, 1, 1, 1.6 } -- 20m, 10m, 5m, SET, START/PAUSE
    local totalW = 0
    for _, w in ipairs(weights) do totalW = totalW + w end
    local unit = (availW - gap * (#weights - 1)) / totalW
    local x = rowX
    local btns = { self.preset20, self.preset10, self.preset5, self.setBtn, self.startStopBtn }
    for i, btn in ipairs(btns) do
        local w = unit * weights[i]
        btn:setRect(x, rowY, w, rowH)
        x = x + w + gap
    end
    self.clearBtn:setRect(x, rowY + (rowH - math.min(rowH, 34)) / 2, resetW, math.min(rowH, 34))
end

function TimerView:refresh()
    local t = self.timer
    if t.state == "running" then
        self.startStopBtn.label = "PAUSE"
    else
        self.startStopBtn.label = "START"
    end
    self.startStopBtn.enabled = (t.remaining > 0) or (t.state == "running")
        or (t.state == "finished" and (t.duration or 0) > 0)
    self.setBtn.enabled = true
    -- Reset discreto: só aparece quando há algo a limpar.
    self.clearBtn.visible = (t.remaining > 0) or (t.duration > 0)
        or (t.state == "running") or (t.state == "paused") or (t.state == "finished")
end

function TimerView:collectButtons(list)
    table.insert(list, self.preset20)
    table.insert(list, self.preset10)
    table.insert(list, self.preset5)
    table.insert(list, self.setBtn)
    table.insert(list, self.startStopBtn)
    table.insert(list, self.clearBtn)
end

-- Paleta enxuta: neutro cinza, ação azul, confirmar verde, perigo vermelho.
-- Presets sempre amarelos; pausa usa azul (ação) para não competir com o amarelo.
local stateColors = {
    idle = {0.6, 0.6, 0.6},
    running = {0.3, 0.75, 0.35},
    paused = {0.35, 0.55, 0.85},
    finished = {0.85, 0.25, 0.2},
}

function TimerView:draw(cell, theme, layout, mode, focused)
    local t = self.timer
    love.graphics.setColor(theme.colors.caseBg)
    love.graphics.rectangle("fill", cell.x, cell.y, cell.w, cell.h, 14, 14)
    -- Foco estrutural: borda neutra mais espessa (sem azul de "formulário").
    love.graphics.setColor(focused and theme.colors.label or theme.colors.caseBorder)
    love.graphics.setLineWidth(focused and 4 or 1.5)
    love.graphics.rectangle("line", cell.x, cell.y, cell.w, cell.h, 14, 14)

    local rowH = rowHeightFor(cell.h)
    local lcdX = cell.x + 10
    local lcdY = cell.y + 10
    local lcdW = cell.w - 20
    -- Faixa reservada p/ barra de progresso (evita overlap com fileira de botões).
    local barH, barGap = 5, 5
    local lcdH = cell.h - rowH - 18 - barH - barGap

    local lcdBg = focused and theme.colors.lcdBgFocus or theme.colors.lcdBg
    love.graphics.setColor(lcdBg)
    love.graphics.rectangle("fill", lcdX, lcdY, lcdW, lcdH, 8, 8)

    -- Barra de progresso discreta dentro da área reservada (nunca sob botões).
    local prog = t.getProgress and t:getProgress() or 0
    if prog > 0 then
        local barY = lcdY + lcdH + 3
        love.graphics.setColor(0, 0, 0, 0.12)
        love.graphics.rectangle("fill", lcdX, barY, lcdW, barH, 2, 2)
        -- Cor acompanha urgência: verde → amarelo (últimos 25%) → vermelho (últimos 10%).
        local barColor = theme.colors.btnGreenDown or theme.colors.label
        if prog >= 0.9 then
            barColor = theme.colors.btnRedDown or theme.colors.btnRed
        elseif prog >= 0.75 then
            barColor = theme.colors.btnYellowDown or theme.colors.btnYellow
        end
        love.graphics.setColor(barColor)
        love.graphics.rectangle("fill", lcdX, barY, lcdW * prog, barH, 2, 2)
    end

    local sc = stateColors[t.state] or {0.6, 0.6, 0.6}
    -- Cabeçalho minimalista: rótulo T1 discreto + triângulo de foco + indicador de estado por forma+cor.
    love.graphics.setFont(theme.fonts.uiSmall)
    love.graphics.setColor(theme.colors.lcdLabel or theme.colors.label)
    love.graphics.printf(t.label or "", lcdX + 8, lcdY + 9, 60, "left")
    local labelW = theme.fonts.uiSmall:getWidth(t.label or "") + 16
    if focused then
        love.graphics.setColor(theme.colors.lcdLabel or theme.colors.label)
        love.graphics.polygon("fill", lcdX + 8 + labelW, lcdY + 9, lcdX + 8 + labelW, lcdY + 21, lcdX + 17 + labelW, lcdY + 15)
    end
    local sx, sy = lcdX + lcdW - 16, lcdY + 16
    if t.state == "running" then
        love.graphics.circle("fill", sx, sy, 7) -- sólido = rodando
    elseif t.state == "paused" then
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", sx, sy, 6) -- anel vazado = pausado
    elseif t.state == "finished" then
        love.graphics.setLineWidth(2.5)
        love.graphics.line(sx - 5, sy - 5, sx + 5, sy + 5)
        love.graphics.line(sx - 5, sy + 5, sx + 5, sy - 5)
    else
        love.graphics.circle("fill", sx, sy, 4) -- idle: ponto pequeno neutro
    end

    local font = layout.lcdFontFor(theme, mode, { w = lcdW, h = lcdH })
    love.graphics.setFont(font)

    local text = t:getDisplayText()
    local visible = t:isBlinkVisible()
    local digitColor = theme.colors.lcdDigitOn
    if t.state == "finished" then
        digitColor = theme.colors.lcdDigitFinished
    end

    love.graphics.setColor(theme.colors.lcdDigitGhost)
    local hasHours = string.find(text, ":.*:") ~= nil
    local ghostText = hasHours and "88:88:88" or "88:88"
    -- Dígitos centralizados na área livre abaixo do cabeçalho (só indicadores).
    local headerH = 26
    local digitAreaY = lcdY + headerH
    local digitAreaH = lcdH - headerH
    love.graphics.printf(ghostText, lcdX, digitAreaY + (digitAreaH - font:getHeight()) / 2, lcdW, "center")

    if visible then
        love.graphics.setColor(digitColor)
        love.graphics.printf(text, lcdX, digitAreaY + (digitAreaH - font:getHeight()) / 2, lcdW, "center")
    end

    love.graphics.setColor(1, 1, 1, 1)

    self.preset20:draw()
    self.preset10:draw()
    self.preset5:draw()
    self.setBtn:draw()
    self.startStopBtn:draw()
    self.clearBtn:draw()
end

return TimerView
