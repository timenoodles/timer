-- tests/test_layout.lua
-- Testes de layout.cellsFor (sem LÖVE). Rode com: lua tests/test_layout.lua
package.path = package.path .. ";./?.lua"

local layout = require("layout")

local failures = 0
local function check(name, cond)
    if cond then print("ok - " .. name)
    else failures = failures + 1 print("FAIL - " .. name) end
end

local function inside(c, W, H)
    return c.x >= 0 and c.y >= 0 and c.x + c.w <= W + 1 and c.y + c.h <= H + 1 and c.w > 0 and c.h > 0
end

local sizes = {
    { 640, 480 }, { 800, 600 }, { 1024, 768 }, { 1280, 720 }, { 500, 800 }, { 400, 400 },
}
for _, sz in ipairs(sizes) do
    local W, H = sz[1], sz[2]
    for mode = 1, 3 do
        local cells = layout.cellsFor(mode, W, H)
        check(string.format("mode %d %dx%d count", mode, W, H), #cells == mode)
        local okAll = true
        for _, c in ipairs(cells) do okAll = okAll and inside(c, W, H) end
        check(string.format("mode %d %dx%d dentro da tela", mode, W, H), okAll)
    end
end

-- Sem sobreposição no modo 3 wide.
do
    local cells = layout.cellsFor(3, 1280, 720)
    local function overlap(a, b)
        return not (a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y)
    end
    check("wide 3 sem overlap 1-2", not overlap(cells[1], cells[2]))
    check("wide 3 sem overlap 1-3", not overlap(cells[1], cells[3]))
    check("wide 3 sem overlap 2-3", not overlap(cells[2], cells[3]))
end

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
