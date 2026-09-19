-- tests/test_timer.lua
-- Testes da lógica pura de timer.lua (sem LÖVE). Rode com: lua tests/test_timer.lua
package.path = package.path .. ";./?.lua"

local Timer = require("timer")

local failures = 0
local function check(name, cond)
    if cond then
        print("ok - " .. name)
    else
        failures = failures + 1
        print("FAIL - " .. name)
    end
end

-- new / estado inicial
do
    local t = Timer.new(1, "T1")
    check("new state idle", t.state == "idle")
    check("new remaining 0", t.remaining == 0)
    check("new display 00:00", t:getDisplayText() == "00:00")
    check("new progress 0", t:getProgress() == 0)
end

-- addPreset soma e define duration
do
    local t = Timer.new(1)
    t:addPreset(5)
    check("preset 5m remaining", t.remaining == 300)
    check("preset duration", t.duration == 300)
    t:addPreset(10)
    check("preset acumula", t.remaining == 900)
    check("preset display 15:00", t:getDisplayText() == "15:00")
end

-- start/pause/toggle
do
    local t = Timer.new(1)
    t:start()
    check("start sem tempo não roda", t.state == "idle")
    t:addPreset(1)
    t:start()
    check("start roda", t.state == "running")
    t:pause()
    check("pause", t.state == "paused")
    t:toggleStartStop()
    check("toggle resume", t.state == "running")
    t:toggleStartStop()
    check("toggle pause", t.state == "paused")
end

-- edição estilo micro-ondas: "130" -> 01:30
do
    local t = Timer.new(1)
    t:beginEditing()
    t:typeDigit("1"); t:typeDigit("3"); t:typeDigit("0")
    t:confirmEditing()
    check("edicao 130 = 90s", t.remaining == 90)
    check("edicao display 01:30", t:getDisplayText() == "01:30")
    check("edicao volta idle", t.state == "idle")
end

-- backspace / cancel
do
    local t = Timer.new(1)
    t:beginEditing()
    t:typeDigit("9"); t:backspace()
    t:confirmEditing()
    check("backspace limpa", t.remaining == 0)
    t:addPreset(5)
    t:beginEditing()
    t:typeDigit("1")
    t:cancelEditing()
    check("cancel mantém 5m", t.remaining == 300)
    check("cancel sai editing", t.editing == false)
end

-- horas: "10000" -> 1:00:00
do
    local t = Timer.new(1)
    t:beginEditing()
    for _, d in ipairs({ "1", "0", "0", "0", "0" }) do t:typeDigit(d) end
    t:confirmEditing()
    check("edicao horas display", t:getDisplayText() == "1:00:00")
end

-- finished: aviso só visual (sem som); restart usa duration
do
    local t = Timer.new(1)
    local finishedCalls = 0
    t:setOnFinished(function() finishedCalls = finishedCalls + 1 end)
    t:addPreset(1)
    t:start()
    -- força término sem esperar tempo real
    t.endTime = nil
    t.remaining = 0.001
    t:update(0.01)
    check("termina finished", t.state == "finished")
    check("callback 1x ao terminar", finishedCalls == 1)
    check("display zerado", t:getDisplayText() == "00:00")
    t:update(0.1)
    check("visível pisca (início)", t:isBlinkVisible() == true)
    t:update(0.5)
    check("pisca alterna", t:isBlinkVisible() == false)
    t:update(2.0)
    check("sem repetição de callback", finishedCalls == 1)
    t:start() -- restart com duration
    check("restart roda", t.state == "running")
    check("restart remaining=duration", t.remaining == t.duration)
end

-- clear zera tudo
do
    local t = Timer.new(1)
    t:addPreset(5)
    t:start()
    t:clear()
    check("clear idle", t.state == "idle")
    check("clear remaining", t.remaining == 0)
    check("clear duration", t.duration == 0)
end

-- progresso
do
    local t = Timer.new(1)
    t:addPreset(10)
    t.remaining = 300 -- metade
    local p = t:getProgress()
    check("progresso metade", math.abs(p - 0.5) < 1e-9)
end

if failures > 0 then
    print(failures .. " FALHA(S)")
    os.exit(1)
else
    print("todos os testes passaram")
end
