-- layout.lua
-- Calcula a posicao/tamanho de cada "celula" de timer na tela,
-- dependendo do modo (1, 2 ou 3 timers visiveis).

local layout = {}

-- Area reservada no topo para os botoes de selecao de modo (canto).
layout.topBarHeight = 56
layout.padding = 16

-- Retorna uma lista de retangulos {x, y, w, h} para o numero de timers.
-- Em telas largas (aspectRatio >= 1.0): 2 timers lado a lado, 3 em grade 2+1.
-- Em telas estreitas: empilhamento vertical.
function layout.cellsFor(mode, screenW, screenH)
    local pad = layout.padding
    local top = layout.topBarHeight
    local usableW = screenW - pad * 2
    local usableH = screenH - top - pad * 2
    local wide = (screenW / screenH) >= 1.0

    local cells = {}

    if mode == 1 then
        table.insert(cells, { x = pad, y = top + pad, w = usableW, h = usableH })
    elseif mode == 2 then
        if wide then
            local w = (usableW - pad) / 2
            table.insert(cells, { x = pad, y = top + pad, w = w, h = usableH })
            table.insert(cells, { x = pad + w + pad, y = top + pad, w = w, h = usableH })
        else
            local h = (usableH - pad) / 2
            table.insert(cells, { x = pad, y = top + pad, w = usableW, h = h })
            table.insert(cells, { x = pad, y = top + pad + h + pad, w = usableW, h = h })
        end
    elseif mode == 3 then
        if wide then
            local topH = (usableH - pad) * 0.5
            local w = (usableW - pad) / 2
            table.insert(cells, { x = pad, y = top + pad, w = w, h = topH })
            table.insert(cells, { x = pad + w + pad, y = top + pad, w = w, h = topH })
            table.insert(cells, { x = pad, y = top + pad + topH + pad, w = usableW, h = usableH - topH - pad })
        else
            local h = (usableH - pad * 2) / 3
            for i = 0, 2 do
                table.insert(cells, { x = pad, y = top + pad + i * (h + pad), w = usableW, h = h })
            end
        end
    end

    return cells
end

-- Escolhe qual tamanho de fonte LCD usar: maior que caiba na célula real.
-- cell: {w, h} da área do LCD (ou da célula); mede contra o texto de referência.
-- displayText (opcional): texto real a desenhar; sem horas ("MM:SS") usa a
-- referência estreita "88:88", liberando uma categoria maior de fonte no caso
-- comum < 1h. Sem displayText, mantém o pior caso "88:88:88" (seguro).
function layout.lcdFontFor(theme, _mode, cell, displayText)
    -- Sem teto por modo: sempre testa do maior ao menor; o tamanho real da célula decide.
    local order = { "lcdHuge", "lcdBig", "lcdMed", "lcdSmall" }
    if not cell or not cell.w or not theme.fonts[order[1]] then
        return theme.fonts.lcdMed
    end
    -- Área útil p/ dígitos: desconta cabeçalho (~28px) e margens.
    local availW = math.max(40, cell.w - 32)
    local availH = math.max(24, (cell.h or 100) - 36)
    local hasHours = displayText and displayText:find(":.*:") ~= nil
    local refText = hasHours and "88:88:88" or "88:88"
    if displayText == nil then refText = "88:88:88" end -- chamadores antigos: pior caso
    for _, name in ipairs(order) do
        local f = theme.fonts[name]
        if f and f:getWidth(refText) <= availW and f:getHeight() <= availH then
            return f
        end
    end
    return theme.fonts[order[#order]]
end

-- Escala contínua: fator que faz o texto de referência preencher a área
-- útil (availW x availH) a partir de uma fonte base (ex. lcdHuge).
-- displayText escolhe a referência ("88:88" vs "88:88:88"), como em lcdFontFor.
-- maxScale limita ampliação (padrão 2.5× da base); redução nunca é limitada.
-- Retorna 1 se a base for inválida.
function layout.lcdScaleFor(baseFont, availW, availH, displayText, maxScale)
    maxScale = maxScale or 2.5
    if not baseFont or not baseFont.getWidth or not baseFont.getHeight then return 1 end
    availW = math.max(1, availW or 1)
    availH = math.max(1, availH or 1)
    local hasHours = displayText and displayText:find(":.*:") ~= nil
    local refText = hasHours and "88:88:88" or "88:88"
    if displayText == nil then refText = "88:88:88" end
    local rw, rh = baseFont:getWidth(refText), baseFont:getHeight()
    if not rw or not rh or rw <= 0 or rh <= 0 then return 1 end
    local scale = math.min(availW / rw, availH / rh)
    if scale > maxScale then scale = maxScale end
    if scale <= 0 then return 1 end
    return scale
end

return layout
