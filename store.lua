-- store.lua
-- Persistência simples do estado (love.filesystem, formato Lua serializado).
-- Salva: remaining, duration, state, endTimestampWall, label, mode, focus, presets, sound.
-- endTimestampWall usa relógio de parede (os.time(), época Unix, em segundos):
-- love.timer.getTime() zera a cada carregamento de página no Web, então um
-- timestamp monotônico da sessão anterior não é comparável ao "agora" da
-- sessão seguinte. O tique intra-sessão continua em getTime() (Timer:update).

local Store = {}

local StrUtil = nil
pcall(function() StrUtil = require("strutil") end)

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

Store.VERSION = 1

-- Aplica estado carregado aos timers; nowFn = tempo monotônico atual
-- (love.timer.getTime, p/ reconstruir endTime intra-sessão),
-- nowWallFn = relógio de parede atual (os.time, p/ descontar tempo real).
-- Retorna {mode, focusIndex} para o app aplicar.
function Store.apply(data, timers, nowFn, maxTimers, nowWallFn)
    if type(data) ~= "table" then return nil end
    -- Versionamento: ignora graciosamente schemas futuros incompatíveis
    if data.version and tonumber(data.version) and tonumber(data.version) > Store.VERSION then
        return nil
    end
    nowFn = nowFn or os.clock
    nowWallFn = nowWallFn or os.time
    maxTimers = maxTimers or 3
    local function truncLabel(s)
        s = tostring(s)
        if StrUtil and StrUtil.truncateUtf8 then return StrUtil.truncateUtf8(s, 6) end
        return s:sub(1, 6)
    end
    for i = 1, maxTimers do
        local t, saved = timers[i], data.timers and data.timers[i]
        if t and type(saved) == "table" then
            t.remaining = tonumber(saved.remaining) or 0
            t.duration = tonumber(saved.duration) or 0
            t.endTime = nil
            t.state = "idle"
            if saved.label then t.label = truncLabel(saved.label) end
            local st = saved.state
            if st == "running" and saved.endTimestampWall then
                local left = tonumber(saved.endTimestampWall) - nowWallFn()
                if left > 0 then
                    -- Teto de segurança: nunca restaura além do último salvo.
                    local cap = math.min(tonumber(saved.remaining) or left,
                        tonumber(saved.duration) or left)
                    left = math.min(left, cap)
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
    -- Validação defensiva: sanitiza presets/sound/theme
    local presets = nil
    if type(data.presets) == "table" then
        presets = {}
        for i = 1, 3 do
            local v = tonumber(data.presets[i])
            if v and v >= 1 and v <= 99 then presets[i] = math.floor(v) end
        end
        if #presets == 0 then presets = nil end
    end
    local sound = nil
    if type(data.sound) == "string" and ({off=true, beep=true, repeat3=true, ["repeat"]=true})[data.sound] then
        sound = data.sound
    end
    local theme = nil
    if type(data.theme) == "string" and ({classic=true, dark=true, contrast=true})[data.theme] then
        theme = data.theme
    end
    local fullscreen = nil
    if type(data.fullscreen) == "boolean" then fullscreen = data.fullscreen end
    return { mode = data.mode, focusIndex = data.focusIndex, presets = presets, sound = sound, theme = theme, fullscreen = fullscreen }
end

-- Coleta estado atual para salvar. opts.now = tempo monotônico atual
-- (para medir `left` via endTime); opts.nowWall = relógio de parede atual
-- (para endTimestampWall; padrão os.time()).
function Store.collect(timers, opts)
    opts = opts or {}
    local out = { version = Store.VERSION, timers = {}, mode = opts.mode or 1, focusIndex = opts.focusIndex or 1,
        presets = opts.presets, sound = opts.sound, theme = opts.theme, fullscreen = opts.fullscreen }
    local nowWall = opts.nowWall or os.time()
    for i, t in ipairs(timers) do
        local entry = { remaining = t.remaining, duration = t.duration,
            state = t.state, label = t.label }
        if t.state == "running" then
            -- endTime interno usa base monotônica; reconstrói o restante.
            local left = t.remaining
            if t.endTime and opts.now then
                left = math.max(0, t.endTime - opts.now)
            end
            entry.endTimestampWall = nowWall + left
            entry.remaining = left
        end
        out.timers[i] = entry
    end
    return out
end

Store.serialize = serialize -- exposto p/ testes fora do LÖVE

return Store
