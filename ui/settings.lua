-- ui/settings.lua
-- Settings modal: few options, proportional to the app.
-- SOUND (off/beep/repeat3/repeat), THEME (classic/dark/contrast),
-- AUTOSAVE (on/off), PRESETS (3 editable values), CLEAR SAVE, CLOSE.
-- Keyboard: up/down selects, left/right changes, enter activates, esc closes.

local Button = require("button")

local Settings = {}
Settings.__index = Settings

local THEME_ORDER = { "classic", "dark", "contrast" }
local SOUND_ORDER = { "off", "beep", "repeat3", "repeat" }

local function cycle(list, cur, dir)
    local idx = 1
    for i, v in ipairs(list) do if v == cur then idx = i break end end
    idx = ((idx - 1 + (dir or 1)) % #list) + 1
    return list[idx]
end

function Settings.new(callbacks)
    local self = setmetatable({}, Settings)
    self.cb = callbacks or {}
    self.open = false
    self.sel = 1 -- 1..7 linhas
    self.leftBtn = Button.new(0, 0, 40, 34, "<", "gray", function() self:adjust(-1) end)
    self.rightBtn = Button.new(0, 0, 40, 34, ">", "gray", function() self:adjust(1) end)
    self.actionBtn = Button.new(0, 0, 120, 34, "OK", "green", function() self:close() end)
    self.closeBtn = Button.new(0, 0, 40, 30, "X", "gray", function() self:close() end)
    -- Botões -/+ por preset (3 presets).
    self.presetMinus, self.presetPlus = {}, {}
    for i = 1, 3 do
        self.presetMinus[i] = Button.new(0, 0, 34, 30, "-", "gray",
            function() self:adjustPreset(i, -1) end)
        self.presetPlus[i] = Button.new(0, 0, 34, 30, "+", "gray",
            function() self:adjustPreset(i, 1) end)
    end
    return self
end

function Settings:show() self.open = true self.sel = 1 end
function Settings:close()
    self.open = false
    if self.cb.onClose then self.cb.onClose() end
end
function Settings:isOpen() return self.open end

function Settings:state()
    return {
        sound = self.cb.getSound and self.cb.getSound() or "repeat3",
        theme = self.cb.getTheme and self.cb.getTheme() or "classic",
        autosave = (self.cb.getAutosave and self.cb.getAutosave()) and true or false,
        presets = self.cb.getPresets and self.cb.getPresets() or { 20, 10, 5 },
    }
end

function Settings:adjust(dir)
    if self.sel == 1 and self.cb.setSound then
        self.cb.setSound(cycle(SOUND_ORDER, self:state().sound, dir))
    elseif self.sel == 2 and self.cb.setTheme then
        self.cb.setTheme(cycle(THEME_ORDER, self:state().theme, dir))
    elseif self.sel == 3 and self.cb.setAutosave then
        self.cb.setAutosave(not self:state().autosave)
    end
end

function Settings:adjustPreset(i, dir)
    if self.cb.adjustPreset then self.cb.adjustPreset(i, dir) end
end

function Settings:activate()
    if self.sel == 1 or self.sel == 2 or self.sel == 3 then
        self:adjust(1)
    elseif self.sel == 4 or self.sel == 5 or self.sel == 6 then
        self:adjustPreset(self.sel - 3, 1)
    elseif self.sel == 7 then
        if self.cb.onClearSaved then self.cb.onClearSaved() end
    end
end

function Settings:moveSel(dir)
    self.sel = ((self.sel - 1 + dir) % 7) + 1
end

function Settings:keypressed(key, isShiftDown)
    if key == "escape" then self:close()
    elseif key == "up" then self:moveSel(-1)
    elseif key == "down" then self:moveSel(1)
    elseif key == "left" then
        if self.sel <= 3 then self:adjust(-1) else self:adjustPreset(self.sel - 3, -1) end
    elseif key == "right" then
        if self.sel <= 3 then self:adjust(1) else self:adjustPreset(self.sel - 3, 1) end
    elseif key == "tab" then self:moveSel(isShiftDown and -1 or 1)
    elseif key == "return" or key == "kpenter" or key == "space" then self:activate()
    end
end

function Settings:reposition(screenW, screenH)
    local mw, mh = 360, 400
    local mx, my = (screenW - mw) / 2, (screenH - mh) / 2
    self.x, self.y, self.w, self.h = mx, my, mw, mh
    self.closeBtn:setRect(mx + mw - 50, my + 8, 40, 30)
    -- Linha < valor > para SOM/TEMA/AUTOSAVE (linhas 1..3).
    self.rowY = {}
    for row = 1, 3 do
        local ry = my + 64 + (row - 1) * 44
        self.rowY[row] = ry
    end
    self.leftBtn:setRect(mx + 24, self.rowY[1], 40, 34)
    self.rightBtn:setRect(mx + mw - 64, self.rowY[1], 40, 34)
    -- Presets: 3 linhas com - valor +.
    self.presetY = {}
    for i = 1, 3 do
        local ry = my + 64 + (3 + i - 1) * 44
        self.presetY[i] = ry
        self.presetMinus[i]:setRect(mx + 24, ry, 40, 32)
        self.presetPlus[i]:setRect(mx + mw - 64, ry, 40, 32)
    end
    self.actionBtn:setRect(mx + (mw - 200) / 2, my + mh - 52, 200, 34)
end

function Settings:collectButtons(list)
    table.insert(list, self.closeBtn)
    table.insert(list, self.leftBtn)
    table.insert(list, self.rightBtn)
    table.insert(list, self.actionBtn)
    for i = 1, 3 do
        table.insert(list, self.presetMinus[i])
        table.insert(list, self.presetPlus[i])
    end
end

function Settings:draw(theme)
    if not self.open then return end
    local st = self:state()
    love.graphics.setColor(0, 0, 0, 0.45)
    local sw, sh = love.graphics.getDimensions()
    love.graphics.rectangle("fill", 0, 0, sw, sh)
    love.graphics.setColor(theme.colors.caseBg)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 16, 16)
    love.graphics.setColor(theme.colors.caseBorder)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 16, 16)
    love.graphics.setFont(theme.fonts.uiLarge)
    love.graphics.setColor(theme.colors.label)
    love.graphics.printf("SETTINGS", self.x, self.y + 12, self.w, "center")

    local rows = {
        "SOUND  < " .. st.sound .. " >",
        "THEME  < " .. st.theme .. " >",
        "AUTOSAVE  < " .. (st.autosave and "ON" or "OFF") .. " >",
    }
    for i = 1, 3 do
        local ry = self.rowY[i]
        if self.sel == i then
            love.graphics.setColor(theme.colors.focusRing[1], theme.colors.focusRing[2],
                theme.colors.focusRing[3], 0.25)
            love.graphics.rectangle("fill", self.x + 12, ry - 4, self.w - 24, 40, 8, 8)
        end
        love.graphics.setFont(theme.fonts.uiMed)
        love.graphics.setColor(theme.colors.label)
        love.graphics.printf(rows[i], self.x, ry + 4, self.w, "center")
    end
    for i = 1, 3 do
        local ry = self.presetY[i]
        local selRow = 3 + i
        if self.sel == selRow then
            love.graphics.setColor(theme.colors.focusRing[1], theme.colors.focusRing[2],
                theme.colors.focusRing[3], 0.25)
            love.graphics.rectangle("fill", self.x + 12, ry - 4, self.w - 24, 40, 8, 8)
        end
        love.graphics.setFont(theme.fonts.uiMed)
        love.graphics.setColor(theme.colors.label)
        love.graphics.printf("PRESET " .. i .. "   " .. tostring(st.presets[i] or "-") .. "m",
            self.x, ry + 4, self.w, "center")
    end
    -- Linha 7: limpar save.
    if self.sel == 7 then
        love.graphics.setColor(0.85, 0.3, 0.25, 0.2)
        love.graphics.rectangle("fill", self.x + 12, self.y + self.h - 96, self.w - 24, 36, 8, 8)
    end
    love.graphics.setFont(theme.fonts.uiSmall)
    love.graphics.setColor(theme.colors.label)
    love.graphics.printf("[7] CLEAR SAVE  (Enter selects)", self.x, self.y + self.h - 88, self.w, "center")

    self.leftBtn:draw()
    self.rightBtn:draw()
    self.actionBtn.label = "CLOSE"
    self.actionBtn:draw()
    self.closeBtn:draw()
    for i = 1, 3 do
        self.presetMinus[i]:draw()
        self.presetPlus[i]:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Settings
