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

-- Timer running: apply recalcula remaining via endTimestampWall.
do
    local t = Timer.new(1, "T1")
    t:addPreset(10) -- 600s
    t:start()       -- endTime = 1600
    local collected = Store.collect({ t }, { mode = 2, focusIndex = 1,
        presets = { 20, 10, 5 }, sound = "beep", now = fake, nowWall = 5000 })
    check("collect endTimestampWall", collected.timers[1].endTimestampWall == 5600)
    -- Simula reload 100s de tempo real depois (relógio monotônico zerado,
    -- como no navegador; só a parede importa).
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return 0 end, 1, function() return 5100 end)
    check("running restaura running", t2.state == "running")
    check("running remaining ~500", math.abs(t2.remaining - 500) < 1e-6)
end

-- Reload com relógio monotônico zerado (navegador): desconta tempo real,
-- nunca ganha tempo.
do
    local t = Timer.new(1, "T1")
    t:addPreset(10) -- 600s
    t:start()       -- endTime = 1600
    local collected = Store.collect({ t }, { now = fake, nowWall = 5000 })
    -- 5s reais depois, relógio novo começa do zero:
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return 0.05 end, 1, function() return 5005 end)
    check("reload web não ganha tempo", t2.remaining <= 600)
    check("reload web desconta tempo real", math.abs(t2.remaining - 595) < 1e-6)
    check("reload web running", t2.state == "running")
end

-- Timer expirado enquanto a aba estava fechada vira finished.
do
    local t = Timer.new(1, "T1")
    t:addPreset(10) -- 600s
    t:start()
    local collected = Store.collect({ t }, { now = fake, nowWall = 5000 })
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return 0.2 end, 1, function() return 5000 + 601 end)
    check("expirado após reload vira finished", t2.state == "finished")
    check("expirado remaining 0", t2.remaining == 0)
end

-- Timer expirado durante reload vira finished.
do
    local t = Timer.new(1, "T1")
    t:addPreset(1)
    t:start()
    local collected = Store.collect({ t }, { now = fake, nowWall = 8000 })
    local t2 = Timer.new(1, "T1")
    Store.apply(collected, { t2 }, function() return fake + 61 end, 1, function() return 8000 + 61 end)
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

-- Truncamento UTF-8 nunca corta caractere ao meio.
do
    local StrUtil = require("strutil")
    check("truncate ascii", StrUtil.truncateUtf8("ABCDEF12", 6) == "ABCDEF")
    check("truncate café 4B vira CAF", StrUtil.truncateUtf8("CAFÉ", 4) == "CAF")
    local t = Timer.new(1, "T1")
    t:setLabel("CAFÉ123", 4)
    check("setLabel não quebra UTF-8", t.label == "CAF")
    local t2 = Timer.new(1, "T1")
    Store.apply({ timers = { { remaining = 10, duration = 10, state = "paused", label = "CAFÉ12" } } },
        { t2 }, function() return 0 end, 1, function() return 0 end)
    check("store label não quebra UTF-8", t2.label == "CAFÉ1")
end

-- Versionamento: schema futuro ignorado, presets/sound/theme sanitizados
do
    local t = Timer.new(1, "T1")
    local future = { version = 99, timers = { { remaining = 10, duration = 10, state="paused" } }, mode=1 }
    local res = Store.apply(future, {t}, function() return 0 end, 1, function() return 0 end)
    check("version futura ignorada", res == nil)
    local bad = { timers = { { remaining=5, duration=5, state="paused"} }, presets = { 999, "x", -1 }, sound="invalid", theme="neon" }
    local t2 = Timer.new(1,"T1")
    local res2 = Store.apply(bad, {t2}, function() return 0 end, 1, function() return 0 end)
    check("presets invalidos sanitizados", res2.presets == nil)
    check("sound invalido sanitizado", res2.sound == nil)
    check("theme invalido sanitizado", res2.theme == nil)
    local withFS = Store.collect({t}, {mode=1, fullscreen=true, now=0, nowWall=0})
    check("collect fullscreen", withFS.fullscreen == true)
end

Timer.resetClock()

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
