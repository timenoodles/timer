-- main.lua
-- Orquestra timers, views, keypad, layout e foco.
-- Aviso de término é só visual (sem áudio).
-- Desenho de célula em ui/timer_view.lua, modal em ui/keypad.lua,
-- teclado/clique em célula em input/controls.lua.

local theme    = require("theme")
local Timer    = require("timer")
local Button   = require("button")
local layout   = require("layout")
local config   = require("config")
local App      = require("app")
local Notification = require("notification")
local Store    = require("store")
local TimerView = require("ui.timer_view")
local Keypad    = require("ui.keypad")
local Settings  = require("ui.settings")
local Controls  = require("input.controls")

local screenW, screenH = 900, 700

-- Controlador: mode, foco, rename e som vivem no App; main espelha p/ desenho.
local app = App.new({ mode = 1, focusIndex = 1, maxLabelLen = config.maxLabelLen,
    soundMode = config.sound })
local mode = app.mode
local focusIndex = app.focusIndex

local timers = {}
local views = {}
local modeButtons = {}
local fullscreenBtn = nil

local editingTimer = nil
local keypad = nil

local notif = Notification.new({ mode = app.soundMode })
local settings = nil
local settingsBtn = nil
local renamingIndex = nil
local renameBuffer = ""
local saveT = 0

local allButtons = {}

local function syncFromApp()
    mode = app.mode
    focusIndex = app.focusIndex
    renamingIndex = app.renamingIndex
    renameBuffer = app.renameBuffer
end

local function setFocus(i)
    app:setFocus(i)
    syncFromApp()
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
    if app:setMode(m) then
        syncFromApp()
        repositionAll()
    end
end

local function saveNow()
    if not config.autosave then return end
    local nowV = (love.timer and love.timer.getTime) and love.timer.getTime() or os.clock()
    Store.save(config.stateFile, Store.collect(timers,
        { mode = mode, focusIndex = focusIndex, presets = config.presets,
          sound = notif.mode, theme = theme.currentTheme, now = nowV }))
end

local function cycleSound()
    notif:setMode(app:cycleSound())
    config.sound = notif.mode
    saveNow()
end

local function startRenaming(i)
    if editingTimer then return end
    app:startRename(i, timers[i].label)
    syncFromApp()
end

local function confirmRenaming()
    if app:isRenaming() then
        timers[app.renamingIndex]:setLabel(app.renameBuffer, config.maxLabelLen)
        app:cancelRename()
        syncFromApp()
        saveNow()
    end
end

local function cancelRenaming()
    app:cancelRename()
    syncFromApp()
end

local function toggleFullscreen()
    local fs = love.window.getFullscreen()
    love.window.setFullscreen(not fs)
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
    -- Botão discreto de tela cheia à esquerda do rótulo TIMERS.
    local labelW = 70
    local fsX = bx - labelW - 6 - size
    fullscreenBtn:setRect(fsX, by, size, size)
    -- Engrenagem de configurações à esquerda do fullscreen.
    settingsBtn:setRect(fsX - 6 - size, by, size, size)
    local cells = layout.cellsFor(mode, screenW, screenH)
    for i = 1, mode do
        views[i]:updateLayout(cells[i])
        views[i]:updateHeaderButton(cells[i])
    end
    keypad:reposition(screenW, screenH)
    settings:reposition(screenW, screenH)
    refreshAllButtons()
end

refreshAllButtons = function()
    allButtons = {}
    for i = 1, 3 do table.insert(allButtons, modeButtons[i]) end
    table.insert(allButtons, fullscreenBtn)
    table.insert(allButtons, settingsBtn)
    if settings:isOpen() then
        settings:collectButtons(allButtons)
    elseif editingTimer then
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
    -- Restaura estado salvo (remaining/endTimestamp, labels, mode, presets, som).
    do
        local data = Store.load(config.stateFile)
        if data then
            local nowV = (love.timer and love.timer.getTime) and love.timer.getTime() or os.clock()
            local res = Store.apply(data, timers, function() return nowV end, 3)
            if res then
                if res.mode and res.mode >= 1 and res.mode <= 3 then app.mode = res.mode end
                if res.focusIndex and res.focusIndex >= 1 and res.focusIndex <= 3 then
                    app.focusIndex = res.focusIndex
                end
                if type(res.presets) == "table" and #res.presets > 0 then
                    config.presets = res.presets
                end
                if res.sound then
                    app.soundMode = res.sound
                    notif:setMode(res.sound)
                    config.sound = res.sound
                end
                if res.theme then
                    config.theme = theme.setTheme(res.theme)
                end
                syncFromApp()
            end
        end
    end
    for i = 1, 3 do
        local idx = i
        views[i] = TimerView.new(timers[i], function() startEditing(idx) end, config.presets)
        views[i].onRenameRequest = function() startRenaming(idx) end
        -- Notificação 1x por término; dispensada ao reiniciar/usar o timer.
        timers[i]:setOnFinished(function() notif:notify(timers[idx]) end)
    end
    for i = 1, 3 do
        local idx = i
        -- Seletor discreto: pequeno, só o ativo ganha destaque.
        modeButtons[i] = Button.new(0, 0, 26, 26, tostring(i), "gray", function() setMode(idx) end)
        modeButtons[i].font = theme.fonts.uiSmall
    end
    fullscreenBtn = Button.new(0, 0, 26, 26, "", "gray", toggleFullscreen)
    fullscreenBtn.icon = "expand"
    fullscreenBtn.font = theme.fonts.uiSmall
    fullscreenBtn.accessibleLabel = "FULLSCREEN"
    settingsBtn = Button.new(0, 0, 26, 26, "", "gray", function()
        settings:show()
        refreshAllButtons()
    end)
    settingsBtn.icon = "gear"
    settingsBtn.font = theme.fonts.uiSmall
    settingsBtn.accessibleLabel = "SETTINGS"

    local function applyPresets(presets)
        config.presets = presets
        for i = 1, 3 do
            if views[i] and views[i].setPresets then views[i]:setPresets(presets) end
        end
        repositionAll()
        saveNow()
    end

    settings = Settings.new({
        getSound = function() return notif.mode end,
        setSound = function(m)
            notif:setMode(m)
            app.soundMode = notif.mode
            config.sound = notif.mode
            saveNow()
        end,
        getTheme = function() return theme.currentTheme or "classic" end,
        setTheme = function(name)
            config.theme = theme.setTheme(name)
            saveNow()
        end,
        getAutosave = function() return config.autosave end,
        setAutosave = function(v) config.autosave = v saveNow() end,
        getPresets = function() return config.presets end,
        adjustPreset = function(i, dir)
            local p = { config.presets[1], config.presets[2], config.presets[3] }
            p[i] = math.max(1, math.min(99, (p[i] or 5) + dir))
            applyPresets(p)
        end,
        onClearSaved = function() Store.clear(config.stateFile) end,
        onClose = function() refreshAllButtons() end,
    })

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
    notif:update(dt)
    for i = 1, mode do
        views[i]:refresh()
    end
    -- Autosave periódico do estado.
    if config.autosave then
        saveT = saveT + dt
        if saveT >= (config.saveInterval or 2) then
            saveT = 0
            saveNow()
        end
    end
end

function love.quit()
    saveNow()
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
    fullscreenBtn:draw()
    settingsBtn:draw()
    love.graphics.setColor(1, 1, 1, 1)
end

function love.draw()
    drawModeButtons()
    local cells = layout.cellsFor(mode, screenW, screenH)
    for i = 1, mode do
        local focused = (i == focusIndex) and not editingTimer
        views[i]:draw(cells[i], theme, layout, mode, focused)
    end
    -- Overlay de rename: caixa simples sobre o LCD focado.
    if renamingIndex and renamingIndex <= mode then
        local c = cells[renamingIndex]
        local bw, bh = 280, 64
        local bx, by = c.x + (c.w - bw) / 2, c.y + (c.h - bh) / 2
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", c.x, c.y, c.w, c.h, 14, 14)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
        love.graphics.setColor(theme.colors.label)
        love.graphics.setFont(theme.fonts.uiMed)
        love.graphics.printf("NAME (Enter confirms, Esc cancels)", bx, by + 6, bw, "center")
        love.graphics.setFont(theme.fonts.uiLarge)
        love.graphics.printf(renameBuffer .. "_", bx, by + 28, bw, "center")
    end
    keypad:draw(theme, editingTimer, screenW, screenH)
    settings:draw(theme)
end

function love.mousepressed(x, y, mbtn)
    for _, btn in ipairs(allButtons) do
        if btn:mousepressed(x, y, mbtn) then
            return
        end
    end
    if settings:isOpen() then return end
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
            app:moveFocus(dir)
            syncFromApp()
        end,
        onToggleStart = function()
            notif:dismiss() -- usar o timer dispensa a repetição do alarme
            timers[focusIndex]:toggleStartStop()
        end,
        onClear = function()
            notif:dismiss()
            timers[focusIndex]:clear()
        end,
        onEdit = function(i) startEditing(i) end,
        onMode = function(m) setMode(m) end,
        onFullscreen = function() toggleFullscreen() end,
        onRename = function(i) startRenaming(i) end,
        onCycleSound = function() cycleSound() end,
        onClearSaved = function()
            Store.clear(config.stateFile)
        end,
    }
end

function love.keypressed(key)
    -- Rename acima de tudo (digitação vai para love.textinput; aqui só controle).
    if app:isRenaming() then
        if key == "return" or key == "kpenter" then
            confirmRenaming()
        elseif key == "escape" then
            cancelRenaming()
        elseif key == "backspace" then
            app:renameBackspace()
            syncFromApp()
        end
        return
    end
    -- Settings aberto: teclado navega no modal.
    if settings:isOpen() then
        local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        settings:keypressed(key, shift)
        return
    end
    if key == "p" then
        settings:show()
        refreshAllButtons()
        return
    end
    Controls.keypressed(key, controlContext())
end

function love.textinput(text)
    if app:isRenaming() then
        app:renameInput(text)
        syncFromApp()
    end
end
