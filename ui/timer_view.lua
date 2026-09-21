-- ui/timer_view.lua
-- Encapsula os botoes e o desenho de uma celula de timer.
-- main.lua só chama updateLayout / refresh / draw / collectButtons.

local Button = require("button")

local TimerView = {}
TimerView.__index = TimerView

local function rowHeightFor(cellH)
    return math.max(44, math.min(56, cellH * 0.18))
end

local function lerp(a,b,t) return a + (b-a)*t end
local function lerpColor(c1,c2,t) return {lerp(c1[1],c2[1],t), lerp(c1[2],c2[2],t), lerp(c1[3],c2[3],t)} end

function TimerView.new(timer, onEditRequest, presets)
    local self = setmetatable({}, TimerView)
    self.timer = timer
    self.onEditRequest = onEditRequest
    self._lcdBg = nil
    self._scaleT = 1
    local t = timer
    self.presetBtns = {}
    self.presetVals = {}
    for _, minutes in ipairs(presets or { 20, 10, 5 }) do
        local m = minutes
        local btn = Button.new(0, 0, 10, 10, tostring(m) .. "m", "yellow",
            function() t:addPreset(m) end)
        table.insert(self.presetBtns, btn)
        table.insert(self.presetVals, m)
    end
    self.setBtn   = Button.new(0, 0, 10, 10, "SET", "blue", function()
        if onEditRequest then onEditRequest() end
    end)
    self.startStopBtn = Button.new(0, 0, 10, 10, "START", "green", function() t:toggleStartStop() end)
    -- font será ajustada em refresh() após theme.load (evita require circular no love.load)
    self.clearBtn = Button.new(0, 0, 10, 10, "", "gray", function() t:clear() end)
    self.clearBtn.icon = "reset" -- arco vetorial desenhado por cima; label vazio (sem texto morto)
    self.clearBtn.accessibleLabel = "CLR" -- texto alternativo p/ acessibilidade/log
    self.renameBtn = Button.new(0, 0, 10, 10, "", "gray", function()
        if onEditRequest and onEditRequest("rename") then return end
        if self.onRenameRequest then self.onRenameRequest() end
    end)
    self.renameBtn.icon = "pencil"
    self.renameBtn.accessibleLabel = "RENAME"
    return self
end

-- Define presets em tempo de execução (botões amarelos refeitos na mesma ordem).
function TimerView:setPresets(presets)
    local t = self.timer
    self.presetBtns = {}
    self.presetVals = {}
    for _, minutes in ipairs(presets or {}) do
        local m = minutes
        table.insert(self.presetBtns,
            Button.new(0, 0, 10, 10, tostring(m) .. "m", "yellow",
                function() t:addPreset(m) end))
        table.insert(self.presetVals, m)
    end
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
    -- Pesos: presets peso 1, SET peso 1, START peso 1.6.
    local weights = {}
    for _ in ipairs(self.presetBtns) do table.insert(weights, 1) end
    table.insert(weights, 1)   -- SET
    table.insert(weights, 1.6) -- START/PAUSE
    local totalW = 0
    for _, w in ipairs(weights) do totalW = totalW + w end
    local unit = (availW - gap * (#weights - 1)) / totalW
    local x = rowX
    local btns = {}
    for _, b in ipairs(self.presetBtns) do table.insert(btns, b) end
    table.insert(btns, self.setBtn)
    table.insert(btns, self.startStopBtn)
    for i, btn in ipairs(btns) do
        local w = unit * weights[i]
        btn:setRect(x, rowY, w, rowH)
        x = x + w + gap
    end
    self.clearBtn:setRect(x, rowY + (rowH - math.min(rowH, 34)) / 2, resetW, math.min(rowH, 34))
end

function TimerView:updateHeaderButton(cell)
    -- Botão ✎ discreto no canto do LCD (renomear), 28x22.
    if not self.renameBtn then return end
    local lcdX = cell.x + 10
    local lcdY = cell.y + 10
    local lcdW = cell.w - 20
    self.renameBtn:setRect(lcdX + lcdW - 36, lcdY + 4, 28, 22)
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
    -- Hierarquia: START/PAUSE maior (uiLarge se couber)
    local theme = require("theme")
    if theme.fonts and theme.fonts.uiLarge then self.startStopBtn.font = theme.fonts.uiLarge end
    self.setBtn.enabled = true
    -- Reset discreto: só aparece quando há algo a limpar. Tooltip via hover handled in button draw (title).
    self.clearBtn.visible = (t.remaining > 0) or (t.duration > 0)
        or (t.state == "running") or (t.state == "paused") or (t.state == "finished")
end

function TimerView:update(dt, focused, mode)
    -- lerp lcdBg para transição suave de foco
    local dimmed = (mode > 1) and not focused
    local theme = require("theme")
    local target
    if focused then target = theme.colors.lcdBgFocus
    elseif dimmed then target = theme.colors.lcdBgDim or theme.colors.lcdBg
    else target = theme.colors.lcdBg end
    self._lcdBg = self._lcdBg or {target[1], target[2], target[3]}
    local k = 1 - math.exp(-12 * dt) -- ~150ms
    self._lcdBg[1] = lerp(self._lcdBg[1], target[1], k)
    self._lcdBg[2] = lerp(self._lcdBg[2], target[2], k)
    self._lcdBg[3] = lerp(self._lcdBg[3], target[3], k)
    -- scale transition for mode change (pop 0.97->1)
    if self._scaleT < 1 then
        self._scaleT = math.min(1, self._scaleT + dt*6)
    end
end

function TimerView:triggerScale()
    self._scaleT = 0.96
end

function TimerView:collectButtons(list)
    for _, b in ipairs(self.presetBtns) do table.insert(list, b) end
    table.insert(list, self.setBtn)
    table.insert(list, self.startStopBtn)
    table.insert(list, self.clearBtn)
    if self.renameBtn then table.insert(list, self.renameBtn) end
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
    -- Timer não-focado em modo multi fica visualmente secundário.
    local dimmed = (mode > 1) and not focused
    -- Sombra suave do case (objeto físico)
    love.graphics.setColor(0, 0, 0, 0.10)
    love.graphics.rectangle("fill", cell.x + 2, cell.y + 4, cell.w, cell.h, 14, 14)
    love.graphics.setColor(theme.colors.caseBg)
    love.graphics.rectangle("fill", cell.x, cell.y, cell.w, cell.h, 14, 14)
    -- Foco estrutural: borda neutra mais espessa + anel externo sutil.
    if focused then
        love.graphics.setColor(theme.colors.label)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", cell.x, cell.y, cell.w, cell.h, 14, 14)
        love.graphics.setColor(theme.colors.label[1], theme.colors.label[2], theme.colors.label[3], 0.25)
        love.graphics.setLineWidth(7)
        love.graphics.rectangle("line", cell.x - 2, cell.y - 2, cell.w + 4, cell.h + 4, 16, 16)
    else
        love.graphics.setColor(theme.colors.caseBorder)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", cell.x, cell.y, cell.w, cell.h, 14, 14)
    end

    local rowH = rowHeightFor(cell.h)
    local lcdX = cell.x + 10
    local lcdY = cell.y + 10
    local lcdW = cell.w - 20
    -- Faixa da barra de progresso só reserva espaço quando há algo a mostrar
    -- (duration > 0); timer ocioso devolve esses 10px aos dígitos.
    local barH, barGap = 0, 0
    local prog = t.getProgress and t:getProgress() or 0
    if (t.duration or 0) > 0 then barH, barGap = 5, 5 end
    local lcdH = cell.h - rowH - 18 - barH - barGap

    local lcdBg = self._lcdBg
    if not lcdBg then
        if focused then lcdBg = theme.colors.lcdBgFocus
        elseif dimmed then lcdBg = theme.colors.lcdBgDim or theme.colors.lcdBg
        else lcdBg = theme.colors.lcdBg end
    end
    -- scale pop for mode transition
    local cellScale = self._scaleT or 1
    local scOffX, scOffY = 0,0
    if cellScale ~= 1 then
        scOffX = (cell.w * (1-cellScale))/2
        scOffY = (cell.h * (1-cellScale))/2
        cell = {x=cell.x+scOffX, y=cell.y+scOffY, w=cell.w*cellScale, h=cell.h*cellScale}
        lcdX = cell.x + 10
        lcdY = cell.y + 10
        lcdW = cell.w - 20
        lcdH = cell.h - rowH - 18 - barH - barGap
    end
    love.graphics.setColor(lcdBg)
    love.graphics.rectangle("fill", lcdX, lcdY, lcdW, lcdH, 8, 8)
    -- Gradiente sutil vertical (brilho LCD) - overlay claro no topo
    love.graphics.setColor(1, 1, 1, 0.06)
    love.graphics.rectangle("fill", lcdX, lcdY, lcdW, lcdH * 0.45, 8, 8)
    love.graphics.setColor(0, 0, 0, 0.07)
    love.graphics.rectangle("fill", lcdX, lcdY + lcdH * 0.7, lcdW, lcdH * 0.30, 8, 8)

    -- Barra de progresso discreta dentro da área reservada (nunca sob botões).
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
    -- Cabeçalho: rótulo + triângulo vetorial de foco + indicador de estado.
    -- Um único indicador de foco (triângulo); sem prefixo Unicode no texto.
    love.graphics.setFont(theme.fonts.uiSmall)
    local headerColor = theme.colors.lcdLabel or theme.colors.label
    love.graphics.setColor(headerColor[1], headerColor[2], headerColor[3], dimmed and 0.55 or 1)
    local labelText = t.label or ""
    love.graphics.printf(labelText, lcdX + 8, lcdY + 9, 120, "left")
    local labelW = theme.fonts.uiSmall:getWidth(labelText) + 14
    if focused then
        love.graphics.setColor(theme.colors.lcdLabel or theme.colors.label)
        local tx = lcdX + 8 + labelW
        love.graphics.polygon("fill", tx, lcdY + 10, tx, lcdY + 20, tx + 9, lcdY + 15)
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

    local text = t:getDisplayText()
    local hasHours = string.find(text, ":.*:") ~= nil
    local ghostText = hasHours and "88:88:88" or "88:88"
    -- Dígitos centralizados na área livre abaixo do cabeçalho (só indicadores).
    local headerH = 26
    local digitAreaY = lcdY + headerH
    local digitAreaH = lcdH - headerH
    local availW = math.max(40, lcdW - 12)
    local availH = math.max(24, digitAreaH - 8)
    local visible = t:isBlinkVisible()
    local digitColor = theme.colors.lcdDigitOn
    if t.state == "finished" then
        digitColor = theme.colors.lcdDigitFinished
    end

    local base = theme.fonts and theme.fonts.lcdHuge
    if base and base.getWidth and base.getHeight and love.graphics.print then
        -- Escala contínua a partir da fonte grande: tamanho exato da célula,
        -- podendo ampliar além dos 120pt (teto maxScale). Redução é nítida;
        -- ampliação limitada p/ não pixelar em células gigantes.
        local scale = layout.lcdScaleFor(base, availW, availH, text)
        -- Pulso sutil quando finished (reforço visual além do blink)
        if t.state == "finished" and visible then
            local pulse = 1 + 0.025 * math.sin((t.animT or 0) * 6)
            scale = scale * pulse
        end
        love.graphics.setFont(base)
        local function drawScaled(str)
            local tw, th = base:getWidth(str) * scale, base:getHeight() * scale
            local x = lcdX + (lcdW - tw) / 2
            local y = digitAreaY + (digitAreaH - th) / 2
            love.graphics.print(str, x, y, 0, scale, scale)
        end
        love.graphics.setColor(theme.colors.lcdDigitGhost)
        drawScaled(ghostText)
        if visible then
            love.graphics.setColor(digitColor)
            drawScaled(text)
        end
    else
        -- Fallback: escada discreta de fontes (ex. testes sem LÖVE gráfico).
        local font = layout.lcdFontFor(theme, mode, { w = lcdW, h = lcdH }, text)
        love.graphics.setFont(font)
        love.graphics.setColor(theme.colors.lcdDigitGhost)
        love.graphics.printf(ghostText, lcdX, digitAreaY + (digitAreaH - font:getHeight()) / 2, lcdW, "center")
        if visible then
            love.graphics.setColor(digitColor)
            love.graphics.printf(text, lcdX, digitAreaY + (digitAreaH - font:getHeight()) / 2, lcdW, "center")
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    for _, b in ipairs(self.presetBtns) do b:draw() end
    self.setBtn:draw()
    self.startStopBtn:draw()
    self.clearBtn:draw()
    if self.renameBtn and focused then self.renameBtn:draw() end
end

return TimerView
