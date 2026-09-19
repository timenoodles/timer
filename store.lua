-- store.lua
-- Persistência simples do estado (love.filesystem, formato Lua serializado).
-- Salva: remaining, duration, state, endTimestamp, label, mode, focus, presets, sound.
-- endTimestamp permite recalcular remaining de timers running após reload.

local Store = {}

-- Serializa tabela simples (números, strings, booleans, tabelas aninhadas).
local function serialize(v, indent)
    indent = indent or ""
    local tv = type(v)
    if tv == "number" or tv == "boolean" then
        return tostring(v)
    elseif tv == "string" then
        return string.format("%q", v)
    elseif tv == "table" then
        local parts = { "{\n" }
        for k, val in pairs(v) do
            local key
            if type(k) == "string" and k:match("^[A-Za-z_][A-Za-z0-9_]*$") then
                key = k
            else
                key = "[" .. serialize(k) .. "]"
            end
            table.insert(parts, indent .. "  " .. key .. " = " .. serialize(val, indent .. "  ") .. ",\n")
        end
        table.insert(parts, indent .. "}")
        return table.concat(parts)
    end
    return "nil"
end

function Store.save(filename, state)
    if not (love and love.filesystem) then return false, "no love.filesystem" end
    local ok, err = pcall(love.filesystem.write, filename, "return " .. serialize(state))
    if not ok then return false, tostring(err) end
    return true
end

function Store.load(filename)
    if not (love and love.filesystem) then return nil end
    if not love.filesystem.getInfo(filename) then return nil end
    local chunk, err = love.filesystem.load(filename)
    if not chunk then return nil, tostring(err) end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

function Store.clear(filename)
    if not (love and love.filesystem) then return false end
    if love.filesystem.getInfo(filename) then
        return love.filesystem.remove(filename)
    end
    return true
end

-- Aplica estado carregado aos timers; nowFn = função de tempo atual (love.timer.getTime).
-- Retorna {mode, focusIndex} para o app aplicar.
function Store.apply(data, timers, nowFn, maxTimers)
    if type(data) ~= "table" then return nil end
    nowFn = nowFn or os.clock
    maxTimers = maxTimers or 3
    for i = 1, maxTimers do
        local t, saved = timers[i], data.timers and data.timers[i]
        if t and type(saved) == "table" then
            t.remaining = tonumber(saved.remaining) or 0
            t.duration = tonumber(saved.duration) or 0
            t.endTime = nil
            t.state = "idle"
            if saved.label then t.label = tostring(saved.label):sub(1, 6) end
            local st = saved.state
            if st == "running" and saved.endTimestamp then
                local left = tonumber(saved.endTimestamp) - nowFn()
                if left > 0 then
                    t.remaining = left
                    t.state = "running"
                    if t.setEndTime then t:setEndTime(nowFn() + left) end
                else
                    t.remaining = 0
                    t.state = "finished"
                end
            elseif st == "paused" or st == "finished" or st == "idle" then
                t.state = st
            end
        end
    end
    return { mode = data.mode, focusIndex = data.focusIndex, presets = data.presets, sound = data.sound, theme = data.theme }
end

-- Coleta estado atual para salvar. endBase = tempo atual (para endTimestamp).
function Store.collect(timers, opts)
    opts = opts or {}
    local out = { timers = {}, mode = opts.mode or 1, focusIndex = opts.focusIndex or 1,
        presets = opts.presets, sound = opts.sound, theme = opts.theme }
    local nowV = opts.now or 0
    for i, t in ipairs(timers) do
        local entry = { remaining = t.remaining, duration = t.duration,
            state = t.state, label = t.label }
        if t.state == "running" then
            -- endTime interno usa mesma base de now; reconstrói timestamp absoluto.
            local left = t.remaining
            if t.endTime and opts.now then
                left = math.max(0, t.endTime - opts.now)
            end
            entry.endTimestamp = nowV + left
            entry.remaining = left
        end
        out.timers[i] = entry
    end
    return out
end

Store.serialize = serialize -- exposto p/ testes fora do LÖVE

return Store
