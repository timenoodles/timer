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
-- cell: {w, h} da área do LCD (ou da célula); mede contra texto de referência.
function layout.lcdFontFor(theme, _mode, cell)
    -- Sem teto por modo: sempre testa do maior ao menor; o tamanho real da célula decide.
    local order = { "lcdHuge", "lcdBig", "lcdMed", "lcdSmall" }
    if not cell or not cell.w or not theme.fonts[order[1]] then
        return theme.fonts.lcdMed
    end
    -- Área útil p/ dígitos: desconta cabeçalho (~28px) e margens.
    local availW = math.max(40, cell.w - 32)
    local availH = math.max(24, (cell.h or 100) - 36)
    local refText = "88:88:88" -- pior caso (mais largo); garante que horas cabem
    for _, name in ipairs(order) do
        local f = theme.fonts[name]
        if f and f:getWidth(refText) <= availW and f:getHeight() <= availH then
            return f
        end
    end
    return theme.fonts[order[#order]]
end

return layout
