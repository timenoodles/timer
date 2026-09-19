-- tests/smoke_love.lua
-- Smoke test headless: stubs da API love.* e exercita os callbacks reais
-- de main.lua (load/draw/update/mouse/teclado, settings, temas, rename).
-- Rode com: lua tests/smoke_love.lua
package.path = package.path .. ";./?.lua"

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

-- ===== Stubs love.* =====
local fsFiles = {}
love = {
    window = {
        setTitle = function() end,
        setMode = function() end,
        getFullscreen = function() return false end,
        setFullscreen = function() end,
    },
    graphics = {
        setBackgroundColor = function() end,
        setColor = function() end,
        setFont = function() end,
        setLineWidth = function() end,
        rectangle = function() end,
        printf = function() end,
        polygon = function() end,
        circle = function() end,
        line = function() end,
        arc = function() end,
        getDimensions = function() return 900, 700 end,
        newFont = function()
            return {
                getWidth = function() return 10 end,
                getHeight = function() return 10 end,
            }
        end,
    },
    timer = { getTime = function() return 1000 end },
    keyboard = { isDown = function() return false end },
    mouse = { getPosition = function() return -1, -1 end },
    filesystem = {
        write = function(name, data) fsFiles[name] = data return true end,
        getInfo = function(name) return fsFiles[name] and {} or nil end,
        load = function(name)
            local chunk = fsFiles[name]
            if not chunk then return nil, "not found" end
            return loadstring and loadstring(chunk) or load(chunk)
        end,
        remove = function(name) fsFiles[name] = nil return true end,
    },
    audio = { play = function() end },
    sound = {
        newSoundData = function(samples)
            return {
                getSampleCount = function() return samples end,
                setSample = function() end,
            }
        end,
    },
}

-- love.audio.newSource precisa existir p/ notification
love.audio.newSource = function()
    return { isPlaying = function() return false end }
end

-- ===== Carrega main e exercita =====
dofile("main.lua")

local ok, err = pcall(love.load)
check("love.load sem erro", ok)
if not ok then print("  erro: " .. tostring(err)) end

ok, err = pcall(love.draw)
check("love.draw sem erro", ok)
if not ok then print("  erro: " .. tostring(err)) end

ok, err = pcall(love.update, 0.016)
check("love.update sem erro", ok)
if not ok then print("  erro: " .. tostring(err)) end

-- Teclas normais
for _, k in ipairs({ "space", "r", "t", "tab", "1", "2", "3", "n", "s", "f11", "p" }) do
    ok, err = pcall(love.keypressed, k)
    check("key " .. k, ok)
    if not ok then print("  erro: " .. tostring(err)) end
end

-- Settings aberto: navega e desenha
ok, err = pcall(love.draw)
check("draw com settings aberto", ok)
for _, k in ipairs({ "down", "right", "left", "up", "return", "escape" }) do
    ok, err = pcall(love.keypressed, k)
    check("settings key " .. k, ok)
    if not ok then print("  erro: " .. tostring(err)) end
end

-- Rename via textinput
pcall(love.keypressed, "n")
ok, err = pcall(love.textinput, "a")
check("textinput rename", ok)
ok, err = pcall(love.keypressed, "return")
check("rename confirm", ok)
ok, err = pcall(love.draw)
check("draw rename overlay fechado", ok)

-- Mouse: clique em célula e botões
ok, err = pcall(love.mousepressed, 450, 400, 1)
check("mousepressed célula", ok)
ok, err = pcall(love.mousereleased, 450, 400, 1)
check("mousereleased", ok)

-- Resize
ok, err = pcall(love.resize, 640, 480)
check("resize 640x480", ok)
ok, err = pcall(love.draw)
check("draw 640x480", ok)
ok, err = pcall(love.resize, 500, 800)
check("resize retrato", ok)
ok, err = pcall(love.draw)
check("draw retrato", ok)

-- Edição via keypad
pcall(love.keypressed, "t")
for _, k in ipairs({ "1", "3", "0", "backspace", "return" }) do
    ok, err = pcall(love.keypressed, k)
    check("keypad key " .. k, ok)
end
ok, err = pcall(love.draw)
check("draw keypad", ok)
pcall(love.keypressed, "escape")

-- Temas: troca direta
do
    local theme = require("theme")
    check("tema dark", theme.setTheme("dark") == "dark")
    ok, err = pcall(love.draw)
    check("draw tema dark", ok)
    check("tema contrast", theme.setTheme("contrast") == "contrast")
    ok, err = pcall(love.draw)
    check("draw tema contrast", ok)
    check("tema classic restore", theme.setTheme("classic") == "classic")
    ok, err = pcall(love.draw)
    check("draw tema classic", ok)
end

-- Save/load roundtrip através do Store real
do
    local Store = require("store")
    check("save escreveu arquivo", fsFiles["multitimer_state.lua"] ~= nil)
    local data = Store.load("multitimer_state.lua")
    check("save legível", type(data) == "table" and data.timers ~= nil)
end

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
