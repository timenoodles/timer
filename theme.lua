-- theme.lua
-- Cores, fontes e constantes visuais compartilhadas.
-- Paleta inspirada nos timers de cozinha japoneses: caixa branca/creme,
-- visor LCD verde-acinzentado, botoes pastel redondos.

local theme = {}

theme.colors = {
    caseBg        = {0.82, 0.83, 0.84},   -- corpo do timer (cinza claro)
    caseBorder    = {0.65, 0.66, 0.68},

    lcdBg         = {0.30, 0.38, 0.30},   -- fundo do visor LCD (escurecido p/ contraste)
    lcdBgFocus    = {0.40, 0.49, 0.39},   -- visor focado: claramente mais claro (<1s perceptível)
    lcdBgDim      = {0.26, 0.33, 0.26},   -- visor não-focado em modo multi: secundário
    lcdDigitOn    = {0.92, 0.95, 0.88},   -- digitos "acesos" (claros sobre fundo escuro)
    lcdDigitGhost = {0.38, 0.46, 0.38},   -- segmentos "apagados" (efeito LCD real)
    lcdDigitFinished = {0.75, 0.20, 0.18},-- digitos quando o tempo acaba

    label         = {0.35, 0.37, 0.34},   -- texto sobre fundos claros (rodapé, modal)
    lcdLabel      = {0.88, 0.90, 0.86},   -- texto do cabeçalho dentro do LCD escuro

    btnYellow     = {0.95, 0.84, 0.35},
    btnYellowDown = {0.85, 0.74, 0.25},
    btnBlue       = {0.55, 0.75, 0.90},
    btnBlueDown   = {0.42, 0.62, 0.78},
    btnGray       = {0.85, 0.85, 0.83},
    btnGrayDown   = {0.72, 0.72, 0.70},
    btnRed        = {0.85, 0.45, 0.42},
    btnRedDown    = {0.72, 0.34, 0.32},
    btnGreen      = {0.55, 0.80, 0.55},
    btnGreenDown  = {0.42, 0.68, 0.42},

    btnText       = {0.20, 0.20, 0.18},
    focusRing     = {0.30, 0.55, 0.85},

    bg            = {0.90, 0.90, 0.88},
}

-- Variações discretas; o japonês claro continua padrão ("classic").
-- Somente paleta: layout, fontes e geometria não mudam.
theme.themes = {
    classic = nil, -- preenchido abaixo (paleta padrão acima)
    dark = {
        caseBg        = {0.22, 0.23, 0.25},
        caseBorder    = {0.35, 0.36, 0.38},
        lcdBg         = {0.10, 0.16, 0.12},
        lcdBgFocus    = {0.16, 0.23, 0.17},
        lcdBgDim      = {0.08, 0.13, 0.10},
        lcdDigitOn    = {0.75, 0.95, 0.78},
        lcdDigitGhost = {0.16, 0.24, 0.18},
        lcdDigitFinished = {0.95, 0.35, 0.30},
        label         = {0.85, 0.86, 0.84},
        lcdLabel      = {0.75, 0.85, 0.76},
        btnText       = {0.12, 0.12, 0.10},
        bg            = {0.13, 0.14, 0.15},
    },
    contrast = {
        caseBg        = {1.0, 1.0, 1.0},
        caseBorder    = {0.10, 0.10, 0.10},
        lcdBg         = {0.0, 0.0, 0.0},
        lcdBgFocus    = {0.10, 0.10, 0.10},
        lcdBgDim      = {0.0, 0.0, 0.0},
        lcdDigitOn    = {1.0, 1.0, 1.0},
        lcdDigitGhost = {0.25, 0.25, 0.25},
        lcdDigitFinished = {1.0, 0.30, 0.25},
        label         = {0.0, 0.0, 0.0},
        lcdLabel      = {1.0, 1.0, 1.0},
        btnText       = {0.0, 0.0, 0.0},
        bg            = {1.0, 1.0, 1.0},
    },
}

theme.currentTheme = "classic"

-- Foto da paleta base para restaurar "classic" após trocar de tema.
local baseColors = {}
for k, v in pairs(theme.colors) do baseColors[k] = v end

-- Aplica uma variação sobre a paleta base (preserva botões/focusRing).
function theme.setTheme(name)
    if name == nil or name == "classic" or theme.themes[name] == nil then
        for k, v in pairs(baseColors) do theme.colors[k] = v end
        theme.currentTheme = "classic"
    else
        for k, v in pairs(baseColors) do theme.colors[k] = v end
        for k, v in pairs(theme.themes[name]) do
            theme.colors[k] = v
        end
        theme.currentTheme = name
    end
    if love and love.graphics and love.graphics.setBackgroundColor then
        love.graphics.setBackgroundColor(theme.colors.bg)
    end
    return theme.currentTheme
end

theme.fonts = {}

function theme.load()
    local boldPath = "assets/fonts/DSEG7Classic-Bold.ttf"

    local function loadFont(path, size)
        local ok, font = pcall(love.graphics.newFont, path, size)
        if ok and font then
            -- LCD nítido em HiDPI: nearest evita blur de upscaling
            pcall(function() font:setFilter("nearest", "nearest") end)
            return font
        end
        -- Fallback visível para diagnóstico (assets faltando no build web)
        if love and love.system then
            pcall(function() print("[theme] fallback font for " .. tostring(path)) end)
        end
        local fb = love.graphics.newFont(size)
        pcall(function() fb:setFilter("linear", "linear") end)
        return fb
    end

    -- Fontes LCD (7 segmentos) em varios tamanhos para os diferentes layouts.
    theme.fonts.lcdHuge   = loadFont(boldPath, 120) -- modo 1 timer
    theme.fonts.lcdBig    = loadFont(boldPath, 84)  -- modo 2 timers
    theme.fonts.lcdMed    = loadFont(boldPath, 56)  -- modo 3 timers
    theme.fonts.lcdSmall  = loadFont(boldPath, 36)  -- fallback p/ células pequenas

    -- Fonte arredondada (M PLUS Rounded 1c Medium) para labels e botoes.
    theme.fonts.uiSmall  = loadFont("assets/fonts/MPLUSRounded1c-Medium.ttf", 14)
    theme.fonts.uiMed    = loadFont("assets/fonts/MPLUSRounded1c-Medium.ttf", 18)
    theme.fonts.uiLarge  = loadFont("assets/fonts/MPLUSRounded1c-Medium.ttf", 24)
    theme.fonts.uiLabel  = loadFont("assets/fonts/MPLUSRounded1c-Medium.ttf", 16)
    -- UI fica melhor com filtro linear (curvas suaves)
    for _, k in ipairs({ "uiSmall", "uiMed", "uiLarge", "uiLabel" }) do
        local f = theme.fonts[k]
        if f then pcall(function() f:setFilter("linear", "linear") end) end
    end
end

return theme
