-- main.lua
-- Orquestra timers, views, keypad, layout e foco.
-- Aviso de término é só visual (sem áudio).
-- Desenho de célula em ui/timer_view.lua, modal em ui/keypad.lua,
-- teclado/clique em célula em input/controls.lua.

local theme    = require("theme")
local Timer    = require("timer")
local Button   = require("button")
local layout   = require("layout")
local TimerView = require("ui.timer_view")
local Keypad    = require("ui.keypad")
local Controls  = require("input.controls")

local screenW, screenH = 900, 700

local mode = 1
local focusIndex = 1

local timers = {}
local views = {}
local modeButtons = {}

local editingTimer = nil
local keypad = nil

local allButtons = {}

local function setFocus(i)
    if i >= 1 and i <= mode then
        focusIndex = i
    end
end

-- Forward (recursão mútua repositionAll <-> refreshAllButtons).
local repositionAll, refreshAllButtons

local function confirmEditingAndClose()
    if editingTimer then
        editingTimer:confirmEditing()
        editingTimer = nil
        refreshAllButtons()
    end
end

local function cancelEditingAndClose()
    if editingTimer then
        editingTimer:cancelEditing()
        editingTimer = nil
        refreshAllButtons()
    end
end

local function startEditing(i)
    if editingTimer and editingTimer ~= timers[i] then
        editingTimer:cancelEditing()
    end
    timers[i]:beginEditing()
    editingTimer = timers[i]
    keypad:clearSelection()
    refreshAllButtons()
end

local function setMode(m)
    mode = m
    if focusIndex > mode then focusIndex = mode end
    repositionAll()
end

repositionAll = function()
    local bx = screenW - layout.padding
    local by = 12
    local size = 26
    for i = 3, 1, -1 do
        bx = bx - size
        modeButtons[i]:setRect(bx, by, size, size)
        bx = bx - 6
    end
    local cells = layout.cellsFor(mode, screenW, screenH)
    for i = 1, mode do
        views[i]:updateLayout(cells[i])
    end
    keypad:reposition(screenW, screenH)
    refreshAllButtons()
end

refreshAllButtons = function()
    allButtons = {}
    for i = 1, 3 do table.insert(allButtons, modeButtons[i]) end
    if editingTimer then
        keypad:collectButtons(allButtons)
    else
        for i = 1, mode do
            views[i]:collectButtons(allButtons)
        end
    end
    for i = 1, mode do
        views[i]:refresh()
    end
end

-- ==========================================================
-- LOVE callbacks
-- ==========================================================

function love.load()
    love.window.setTitle("Multi Timer - Japanese Style")
    love.window.setMode(screenW, screenH, { resizable = true, minwidth = 640, minheight = 480 })
    love.graphics.setBackgroundColor(theme.colors.bg)

    theme.load()

    for i = 1, 3 do
        timers[i] = Timer.new(i, "T" .. i)
    end
    for i = 1, 3 do
        local idx = i
        views[i] = TimerView.new(timers[i], function() startEditing(idx) end)
    end
    for i = 1, 3 do
        local idx = i
        -- Seletor discreto: pequeno, só o ativo ganha destaque.
        modeButtons[i] = Button.new(0, 0, 26, 26, tostring(i), "gray", function() setMode(idx) end)
        modeButtons[i].font = theme.fonts.uiSmall
    end

    keypad = Keypad.new({
        onConfirm = function() confirmEditingAndClose() end,
        onCancel = function() cancelEditingAndClose() end,
        onClear = function() if editingTimer then editingTimer.inputBuffer = "" end end,
        onDigit = function(d) if editingTimer then editingTimer:typeDigit(d) end end,
        onBackspace = function() if editingTimer then editingTimer:backspace() end end,
    })
    screenW, screenH = love.graphics.getDimensions()
    repositionAll()
end

function love.resize(w, h)
    screenW, screenH = w, h
    repositionAll()
end

function love.update(dt)
    for i = 1, 3 do
        local t = timers[i]
        if not t.editing then
            t:update(dt)
        end
    end
    for i = 1, mode do
        views[i]:refresh()
    end
end

local function drawModeButtons()
    -- Rótulo discreto + 3 números; só o ativo em destaque.
    love.graphics.setFont(theme.fonts.uiSmall)
    love.graphics.setColor(theme.colors.label)
    local bx = screenW - layout.padding
    for i = 3, 1, -1 do
        bx = bx - 26
        if i < 3 then bx = bx - 6 end
    end
    love.graphics.printf("TIMERS", bx - 70, 14, 64, "right")
    for i = 1, 3 do
        local btn = modeButtons[i]
        local wasStyle = btn.style
        btn.style = (i == mode) and "blue" or "gray"
        btn:draw()
        btn.style = wasStyle
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function love.draw()
    drawModeButtons()
    local cells = layout.cellsFor(mode, screenW, screenH)
    for i = 1, mode do
        local focused = (i == focusIndex) and not editingTimer
        views[i]:draw(cells[i], theme, layout, mode, focused)
    end
    keypad:draw(theme, editingTimer, screenW, screenH)
end

function love.mousepressed(x, y, mbtn)
    for _, btn in ipairs(allButtons) do
        if btn:mousepressed(x, y, mbtn) then
            return
        end
    end
    if editingTimer then return end
    local cells = layout.cellsFor(mode, screenW, screenH)
    local hit = Controls.cellAt(x, y, cells)
    if hit then setFocus(hit) end
end

function love.mousereleased(x, y, mbtn)
    for _, btn in ipairs(allButtons) do
        btn:mousereleased(x, y, mbtn)
    end
end

local function controlContext()
    return {
        editingTimer = editingTimer,
        timers = timers,
        focusIndex = focusIndex,
        mode = mode,
        onTypeDigit = function(d) editingTimer:typeDigit(d) end,
        onBackspace = function() editingTimer:backspace() end,
        onConfirm = function() confirmEditingAndClose() end,
        onCancel = function() cancelEditingAndClose() end,
        onKeypadMove = function(step) keypad:moveSel(step) end,
        onKeypadActivate = function() keypad:activateSelected() end,
        onKeypadConfirmOrActivate = function()
            -- Sem seleção por setas/Tab, Enter confirma (comportamento antigo);
            -- com seleção, Enter ativa o botão focado.
            if not keypad:activateSelected() then confirmEditingAndClose() end
        end,
        onToggleFocus = function(dir)
            local nxt = focusIndex + dir
            if nxt > mode then nxt = 1 end
            if nxt < 1 then nxt = mode end
            setFocus(nxt)
        end,
        onToggleStart = function() timers[focusIndex]:toggleStartStop() end,
        onClear = function() timers[focusIndex]:clear() end,
        onEdit = function(i) startEditing(i) end,
        onMode = function(m) setMode(m) end,
    }
end

function love.keypressed(key)
    Controls.keypressed(key, controlContext())
end
