-- theme.lua
-- Cores, fontes e constantes visuais compartilhadas.
-- Paleta inspirada nos timers de cozinha japoneses: caixa branca/creme,
-- visor LCD verde-acinzentado, botoes pastel redondos.

local theme = {}

theme.colors = {
    caseBg        = {0.82, 0.83, 0.84},   -- corpo do timer (cinza claro)
    caseBorder    = {0.65, 0.66, 0.68},

    lcdBg         = {0.30, 0.38, 0.30},   -- fundo do visor LCD (escurecido p/ contraste)
    lcdBgFocus    = {0.36, 0.44, 0.36},   -- visor focado: ligeiramente mais claro
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

theme.fonts = {}

function theme.load()
    local boldPath = "assets/fonts/DSEG7Classic-Bold.ttf"

    local function loadFont(path, size)
        local ok, font = pcall(love.graphics.newFont, path, size)
        if ok and font then return font end
        return love.graphics.newFont(size) -- fallback sans se o .ttf faltar
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
end

return theme
