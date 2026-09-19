-- tests/test_store.lua
-- Testes de store.collect/apply/serialize (sem LÖVE). Rode com: lua tests/test_store.lua
package.path = package.path .. ";./?.lua"

local Timer = require("timer")
local Store = require("store")

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

-- Relógio falso determinístico.
local fake = 1000
Timer.setClock(function() return fake end)

-- Timer running: apply recalcula remaining via endTimestamp.
do
    local t = Timer.new(1, "T1")
    t:addPreset(10) -- 600s
    t:start()       -- endTime = 1600
    local collected = Store.collect({ t }, { mode = 2, focusIndex = 1,
        presets = { 20, 10, 5 }, sound = "beep", now = fake })
    check("collect endTimestamp", collected.timers[1].endTimestamp == 1600)
    -- Simula reload 100s depois.
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return 1100 end, 1)
    check("running restaura running", t2.state == "running")
    check("running remaining ~500", math.abs(t2.remaining - 500) < 1e-6)
end

-- Reload com base de relógio zerada (navegador): nunca ganha tempo.
do
    local t = Timer.new(1, "T1")
    t:addPreset(10) -- 600s
    t:start()       -- endTime = 1600
    local collected = Store.collect({ t }, { now = fake })
    -- endTimestamp absoluto da sessão anterior + relógio recomeçado do zero:
    -- sem teto, left seria 1600 (muito além dos 600 configurados).
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return 0 end, 1)
    check("reload web não ganha tempo", t2.remaining <= 600)
    check("reload web usa último salvo", math.abs(t2.remaining - 600) < 1e-6)
    check("reload web running", t2.state == "running")
end

-- Timer expirado durante reload vira finished.
do
    local t = Timer.new(1, "T1")
    t:addPreset(1)
    t:start()
    local collected = Store.collect({ t }, { now = fake })
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return fake + 61 end, 1)
    check("expirado vira finished", t2.state == "finished")
end

-- Pausado permanece pausado; finalizado permanece finalizado.
do
    local t = Timer.new(1, "T1")
    t:addPreset(5) t:start() t:pause()
    local collected = Store.collect({ t }, { now = fake })
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return fake + 9999 end, 1)
    check("pausado permanece", t2.state == "paused")
    check("pausado remaining preservado", t2.remaining == 300)
end
do
    local t = Timer.new(1, "T1")
    t:addPreset(1) t:start()
    t.remaining = 0.001 t.endTime = nil t:update(0.01)
    local collected = Store.collect({ t }, { now = fake })
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return fake end, 1)
    check("finished permanece", t2.state == "finished")
end

-- Serialize gera Lua válido.
do
    local s = "return " .. Store.serialize({ a = 1, b = "x", c = { 1, 2 } })
    local fn = assert(loadstring and loadstring(s) or load(s))
    local d = fn()
    check("serialize roundtrip", d.a == 1 and d.b == "x" and d.c[2] == 2)
end

-- Longo determinístico: timer de 1h sem esperar tempo real.
do
    local t = Timer.new(1, "T1")
    t:addPreset(60)
    t:start()
    fake = fake + 3599
    t:update(0)
    check("1h quase no fim ainda running", t.state == "running")
    fake = fake + 2
    t:update(0)
    check("1h termina", t.state == "finished")
end

Timer.resetClock()

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
