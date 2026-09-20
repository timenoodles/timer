-- timer.lua
-- Logica pura de um timer de contagem regressiva.
-- Nao sabe desenhar nada: so controla estado e tempo.

local StrUtil = require("strutil")

local Timer = {}
Timer.__index = Timer

local MAX_SECONDS = 99 * 3600 + 59 * 60 + 59 -- 99:59:59

-- Fonte de tempo monotônica; funciona dentro do LÖVE e em testes fora dele.
local function now()
    if Timer.nowFn then return Timer.nowFn() end
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

-- Fonte de tempo injetável (testes determinísticos).
-- Produção: padrão (love.timer.getTime ou os.clock).
-- Testes: Timer.setClock(function() return fakeTime end)
function Timer.setClock(fn)
    Timer.nowFn = fn
end

function Timer.resetClock()
    Timer.nowFn = nil
end

function Timer.new(id, label)
    local self = setmetatable({}, Timer)
    self.id = id
    self.label = label or ("T" .. id)
    self.remaining = 0        -- segundos restantes
    self.duration = 0         -- ultimo valor "cheio" configurado (para reset/progresso)
    self.endTime = nil        -- hora de término (tempo real) quando running
    self.state = "idle"       -- idle | running | paused | finished
    self.editing = false
    self.inputBuffer = ""     -- digitos sendo digitados no modo de edicao
    self.finishedFlashT = 0   -- acumulador para o efeito de piscar ao terminar
    self.animT = 0            -- relógio p/ microanimações (dot pulsante em RUN)
    self.onFinished = nil     -- callback opcional chamado 1x ao terminar
    return self
end

-- Registra callback de término: t:onFinished(function(timer) ... end)
function Timer:setOnFinished(cb)
    self.onFinished = cb
end

-- Nome curto (máx. maxLen, maiúsculas, sem espaços extras).
function Timer:setLabel(name, maxLen)
    maxLen = maxLen or 6
    local s = StrUtil.upperLabel(name):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #s == 0 then return false end
    if #s > maxLen then s = StrUtil.truncateUtf8(s, maxLen) end
    self.label = s
    return true
end

function Timer:addPreset(minutes)
    if self.editing then return end
    local add = minutes * 60
    if self.state == "running" and self.endTime then
        self.remaining = math.max(0, self.endTime - now())
    end
    self.remaining = math.min(MAX_SECONDS, self.remaining + add)
    self.duration = self.remaining
    if self.state == "running" then
        self.endTime = now() + self.remaining
    elseif self.state == "finished" then
        self.state = "idle"
    end
end

function Timer:start()
    if self.editing then return end
    if self.state == "finished" and (self.duration or 0) > 0 then
        self.remaining = self.duration
    end
    if self.remaining > 0 and self.state ~= "running" then
        self.state = "running"
        self.endTime = now() + self.remaining
    end
end

function Timer:pause()
    if self.state == "running" then
        if self.endTime then
            self.remaining = math.max(0, self.endTime - now())
        end
        self.endTime = nil
        self.state = "paused"
    end
end

function Timer:toggleStartStop()
    if self.editing then return end
    if self.state == "running" then
        self:pause()
    else
        self:start()
    end
end

-- Permite ao store/app restaurar endTime absoluto (reload) e a testes injetar relógio.
function Timer:setEndTime(t)
    self.endTime = t
end

function Timer:clear()
    self.editing = false
    self.inputBuffer = ""
    self.remaining = 0
    self.duration = 0
    self.endTime = nil
    self.state = "idle"
    self.finishedFlashT = 0
end

-- ===== Modo de digitacao direta (estilo microondas) =====
-- Digitos entram pela direita: SS, depois MM, depois HH.

function Timer:beginEditing()
    if self.state == "running" then
        self:pause()
    end
    self.editing = true
    self.inputBuffer = ""
end

function Timer:cancelEditing()
    self.editing = false
    self.inputBuffer = ""
end

function Timer:typeDigit(d)
    if not self.editing then return end
    if #self.inputBuffer < 6 then
        self.inputBuffer = self.inputBuffer .. tostring(d)
    end
end

function Timer:backspace()
    if not self.editing then return end
    self.inputBuffer = self.inputBuffer:sub(1, -2)
end

function Timer:confirmEditing()
    if not self.editing then return end
    local buf = self.inputBuffer
    if #buf == 0 then buf = "0" end
    buf = string.rep("0", math.max(0, 6 - #buf)) .. buf
    local hh = tonumber(buf:sub(1, 2)) or 0
    local mm = tonumber(buf:sub(3, 4)) or 0
    local ss = tonumber(buf:sub(5, 6)) or 0
    -- normaliza minutos/segundos "invalidos" (ex: 90 segundos) de forma tolerante
    local total = hh * 3600 + mm * 60 + ss
    self.remaining = math.min(MAX_SECONDS, total)
    self.duration = self.remaining
    self.endTime = nil
    self.editing = false
    self.inputBuffer = ""
    self.state = "idle"
end

function Timer:update(dt)
    self.animT = (self.animT or 0) + dt
    if self.state == "running" then
        if self.endTime then
            self.remaining = self.endTime - now()
        else
            self.remaining = self.remaining - dt
        end
        if self.remaining <= 0 then
            self.remaining = 0
            self.endTime = nil
            self.state = "finished"
            self.finishedFlashT = 0
            if self.onFinished then self.onFinished(self) end
            return true -- acabou de terminar neste frame
        end
        return false
    elseif self.state == "finished" then
        -- Aviso só visual: 00:00 pisca via isBlinkVisible (sem som, sem repetição).
        self.finishedFlashT = self.finishedFlashT + dt
    end
end

    -- Retorna hh, mm, ss (inteiros) para exibicao.
function Timer:getDisplayParts()
    local secs
    if self.editing then
        local buf = string.rep("0", math.max(0, 6 - #self.inputBuffer)) .. self.inputBuffer
        local hh = tonumber(buf:sub(1, 2)) or 0
        local mm = tonumber(buf:sub(3, 4)) or 0
        local ss = tonumber(buf:sub(5, 6)) or 0
        return hh, mm, ss
    else
        secs = math.ceil(self.remaining)
    end
    local hh = math.floor(secs / 3600)
    local mm = math.floor((secs % 3600) / 60)
    local ss = secs % 60
    return hh, mm, ss
end

-- Texto formatado: "MM:SS" normalmente, ou "H:MM:SS" se >= 1 hora.
function Timer:getDisplayText()
    local hh, mm, ss = self:getDisplayParts()
    if hh > 0 then
        return string.format("%d:%02d:%02d", hh, mm, ss)
    else
        return string.format("%02d:%02d", mm, ss)
    end
end

-- Progresso 0..1 (para futura barra de progresso); 0 se sem duration.
function Timer:getProgress()
    if not self.duration or self.duration <= 0 then return 0 end
    local p = 1 - (self.remaining / self.duration)
    if p < 0 then p = 0 end
    if p > 1 then p = 1 end
    return p
end

-- Alpha do indicador ●: pulsante lento em RUN, estático nos demais.
-- Em DONE o texto 00:00 pisca (isBlinkVisible); a célula não pisca.
function Timer:dotAlpha()
    if self.state == "running" then
        return 0.55 + 0.45 * math.sin((self.animT or 0) * 4)
    end
    return 1
end

-- Enquanto "finished", pisca (alterna visivel/invisivel) para chamar atencao.
function Timer:isBlinkVisible()
    if self.state ~= "finished" then return true end
    return math.floor(self.finishedFlashT * 2) % 2 == 0
end

Timer.MAX_SECONDS = MAX_SECONDS

return Timer
