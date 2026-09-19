-- notification.lua
-- Camada de notificação de término: conectada via timer:setOnFinished.
-- timer.lua continua sem áudio. Modos: "off" | "beep" | "repeat3" | "repeat".
-- Visual (piscar 00:00) continua em timer.lua; aqui só som + título da janela.

local Notification = {}
Notification.__index = Notification

function Notification.new(opts)
    local self = setmetatable({}, Notification)
    self.mode = (opts and opts.mode) or "repeat3"
    self.sources = {}
    self.repeatTimer = nil
    self.repeatCount = 0
    self.titleFlashT = 0
    self.flashing = false
    self.baseTitle = "Multi Timer - Japanese Style"
    return self
end

function Notification:setMode(mode)
    self.mode = mode
    if mode == "off" then self:dismiss() end
end

-- Gera um bip senoidal de 880Hz, 0.25s, sem asset externo.
local function makeBeep()
    if not (love and love.audio and love.sound) then return nil end
    local rate, dur, freq = 22050, 0.25, 880
    local data = love.sound.newSoundData(math.floor(rate * dur), rate, 16, 1)
    for i = 0, data:getSampleCount() - 1 do
        local t = i / rate
        local env = math.min(1, t / 0.02) * math.min(1, (dur - t) / 0.05)
        data:setSample(i, math.sin(2 * math.pi * freq * t) * 0.5 * env)
    end
    return love.audio.newSource(data, "static")
end

function Notification:_playOnce()
    if self.mode == "off" then return end
    local src = makeBeep()
    if src then
        love.audio.play(src)
        table.insert(self.sources, src)
    end
end

-- Chamada 1x por término (via onFinished). Retorna true se notificou.
function Notification:notify(timer)
    if self.mode == "off" then return false end
    self:dismiss()
    self.flashing = true
    self.titleFlashT = 0
    if self.mode == "beep" then
        self:_playOnce()
    elseif self.mode == "repeat3" then
        self.repeatCount = 0
        self.repeatTimer = 0 -- dispara update() com 3 bips espaçados
    elseif self.mode == "repeat" then
        self.repeatCount = 0
        self.repeatTimer = 0 -- repete até dismiss()
    end
    return true
end

function Notification:dismiss()
    self.flashing = false
    self.repeatTimer = nil
    self.repeatCount = 0
    if love and love.window and love.window.setTitle then
        love.window.setTitle(self.baseTitle)
    end
end

function Notification:update(dt)
    -- Limpa sources terminadas.
    for i = #self.sources, 1, -1 do
        local s = self.sources[i]
        if not s:isPlaying() then table.remove(self.sources, i) end
    end
    if self.repeatTimer ~= nil and self.mode ~= "off" then
        self.repeatTimer = self.repeatTimer - dt
        if self.repeatTimer <= 0 then
            self:_playOnce()
            self.repeatCount = self.repeatCount + 1
            local maxBeeps = (self.mode == "repeat3") and 3 or math.huge
            if self.repeatCount >= maxBeeps then
                self.repeatTimer = nil
            else
                self.repeatTimer = 0.45
            end
        end
    end
    -- Pisca o título da janela enquanto não dispensado (modo repeat) ou 6s nos demais.
    if self.flashing and love and love.window and love.window.setTitle then
        self.titleFlashT = self.titleFlashT + dt
        local active = (self.mode == "repeat") or self.titleFlashT < 6
        if not active then
            self.flashing = false
            love.window.setTitle(self.baseTitle)
        elseif math.floor(self.titleFlashT * 2) % 2 == 0 then
            love.window.setTitle("⏰ TEMPO! — " .. self.baseTitle)
        else
            love.window.setTitle(self.baseTitle)
        end
    end
end

return Notification
