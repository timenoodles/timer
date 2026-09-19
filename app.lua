-- app.lua
-- Controlador da aplicação: estado (mode, foco, rename, som) e ações.
-- input/controls.lua decide "qual ação aconteceu"; App decide "o que fazer".
-- Sem desenho, sem love direto (testável fora do LÖVE).

local StrUtil = require("strutil")

local App = {}
App.__index = App

App.SOUND_MODES = { "off", "beep", "repeat3", "repeat" }

-- Reexportado p/ compatibilidade (main.lua/testes usam App.upperLabel).
App.upperLabel = StrUtil.upperLabel

function App.new(opts)
    opts = opts or {}
    local self = setmetatable({}, App)
    self.mode = opts.mode or 1
    self.focusIndex = opts.focusIndex or 1
    self.maxTimers = opts.maxTimers or 3
    self.maxLabelLen = opts.maxLabelLen or 6
    self.soundMode = opts.soundMode or "repeat3"
    self.renamingIndex = nil
    self.renameBuffer = ""
    return self
end

function App:setMode(m)
    if m >= 1 and m <= self.maxTimers then
        self.mode = m
        if self.focusIndex > m then self.focusIndex = m end
        return true
    end
    return false
end

function App:setFocus(i)
    if i >= 1 and i <= self.mode then
        self.focusIndex = i
        return true
    end
    return false
end

function App:moveFocus(dir)
    local nxt = self.focusIndex + dir
    if nxt > self.mode then nxt = 1 end
    if nxt < 1 then nxt = self.mode end
    self.focusIndex = nxt
    return self.focusIndex
end

function App:cycleSound()
    local idx = 1
    for i, m in ipairs(App.SOUND_MODES) do
        if m == self.soundMode then idx = i break end
    end
    idx = idx % #App.SOUND_MODES + 1
    self.soundMode = App.SOUND_MODES[idx]
    return self.soundMode
end

function App:startRename(i, currentLabel)
    self.renamingIndex = i
    self.renameBuffer = currentLabel or ""
end

function App:cancelRename()
    self.renamingIndex = nil
    self.renameBuffer = ""
end

function App:renameBackspace()
    self.renameBuffer = StrUtil.stripLastChar(self.renameBuffer)
end

function App:renameInput(text)
    -- Aceita qualquer caractere imprimível (inclui acentos que %w rejeita);
    -- só bloqueia vazio e caracteres de controle.
    if text == "" or text:match("%c") then return false end
    if #self.renameBuffer >= self.maxLabelLen then return false end
    self.renameBuffer = StrUtil.upperLabel(self.renameBuffer .. text)
    return true
end

function App:isRenaming()
    return self.renamingIndex ~= nil
end

return App
