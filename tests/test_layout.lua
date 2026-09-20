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

-- lcdFontFor: texto real (MM:SS) libera fonte maior que o pior caso (H:MM:SS).
do
    -- Fontes falsas com as larguras medidas (DSEG7Classic-Bold).
    local widths = { lcdHuge = 636, lcdBig = 448, lcdMed = 298, lcdSmall = 188 }
    local narrow = { lcdHuge = 416, lcdBig = 293, lcdMed = 195, lcdSmall = 123 }
    local heights = { lcdHuge = 120, lcdBig = 84, lcdMed = 56, lcdSmall = 36 }
    local fakeTheme = { fonts = {} }
    for name, w in pairs(widths) do
        local n = narrow[name]
        local h = heights[name]
        fakeTheme.fonts[name] = {
            getWidth = function(self, txt)
                if txt and txt:find(":.*:") then return w end
                return n
            end,
            getHeight = function(self) return h end,
        }
    end
    -- Janela 900x700, modo 2: célula ~399px -> útil ~367px p/ dígitos.
    local cell = { w = 399, h = 400 }
    local wide = layout.lcdFontFor(fakeTheme, 2, cell, "20:00")
    local hours = layout.lcdFontFor(fakeTheme, 2, cell, "1:00:00")
    check("MM:SS usa lcdBig", wide == fakeTheme.fonts.lcdBig)
    check("H:MM:SS usa lcdMed", hours == fakeTheme.fonts.lcdMed)
    -- Sem displayText: comportamento antigo (pior caso).
    check("nil mantém pior caso", layout.lcdFontFor(fakeTheme, 2, cell) == fakeTheme.fonts.lcdMed)
end

-- lcdScaleFor: escala contínua preenche a área útil (limitada por largura/altura).
do
    local base = {
        getWidth = function(self, txt)
            if txt and txt:find(":.*:") then return 636 end
            return 416
        end,
        getHeight = function(self) return 120 end,
    }
    -- Área 400x200 com "20:00": min(400/416, 200/120) = 400/416.
    local s = layout.lcdScaleFor(base, 400, 200, "20:00")
    check("scale limitado por largura", math.abs(s - 400 / 416) < 1e-9)
    -- Área 800x100: altura limita -> 100/120.
    check("scale limitado por altura", math.abs(layout.lcdScaleFor(base, 800, 100, "20:00") - 100 / 120) < 1e-9)
    -- Com horas a referência é mais larga -> escala menor.
    check("scale horas menor", layout.lcdScaleFor(base, 400, 200, "1:00:00") < s)
    -- Teto maxScale (ampliação além dos 120pt, limitada).
    check("scale respeita teto", layout.lcdScaleFor(base, 5000, 5000, "20:00") == 2.5)
    check("scale teto custom", layout.lcdScaleFor(base, 5000, 5000, "20:00", 1.0) == 1.0)
    -- Base inválida -> 1.
    check("scale base inválida", layout.lcdScaleFor(nil, 400, 200, "20:00") == 1)
end

if failures > 0 then print(failures .. " FALHA(S)") os.exit(1)
else print("todos os testes passaram") end
