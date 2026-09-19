-- button.lua
-- Botao retangular com cantos arredondados, estilo botoes fisicos de timer.

local theme = require("theme")

local Button = {}
Button.__index = Button

-- style: "yellow" | "blue" | "gray" | "red" | "green"
function Button.new(x, y, w, h, label, style, onClick)
    local self = setmetatable({}, Button)
    self.x, self.y, self.w, self.h = x, y, w, h
    self.label = label
    self.style = style or "gray"
    self.onClick = onClick
    self.pressed = false
    self.visible = true
    self.enabled = true
    self.font = theme.fonts.uiMed
    return self
end

function Button:setRect(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
end

function Button:contains(px, py)
    return self.visible and self.enabled
        and px >= self.x and px <= self.x + self.w
        and py >= self.y and py <= self.y + self.h
end

function Button:mousepressed(px, py, mbtn)
    if mbtn ~= 1 then return false end
    if self:contains(px, py) then
        self.pressed = true
        return true
    end
    return false
end

function Button:mousereleased(px, py, mbtn)
    if mbtn ~= 1 then return end
    if self.pressed and self:contains(px, py) then
        if self.onClick then self.onClick() end
    end
    self.pressed = false
end

function Button:trigger()
    -- Ativacao via teclado (sem passar pelas coordenadas do mouse).
    if self.onClick and self.enabled and self.visible then
        self.onClick()
    end
end

local function colorsFor(style, down, enabled)
    local c = theme.colors
    local map = {
        yellow = { c.btnYellow, c.btnYellowDown },
        blue   = { c.btnBlue,   c.btnBlueDown   },
        gray   = { c.btnGray,   c.btnGrayDown   },
        red    = { c.btnRed,    c.btnRedDown    },
        green  = { c.btnGreen,  c.btnGreenDown  },
    }
    local pair = map[style] or map.gray
    local col = down and pair[2] or pair[1]
    if not enabled then
        return {0.88, 0.88, 0.87}
    end
    return col
end

function Button:draw()
    if not self.visible then return end
    -- Hover (mouse) dá feedback imediato sem depender de toque; toque usa pressed.
    local hovered = false
    if love and love.mouse and love.mouse.getPosition and self.enabled then
        local mx, my = love.mouse.getPosition()
        hovered = mx >= self.x and mx <= self.x + self.w
            and my >= self.y and my <= self.y + self.h
    end
    local col = colorsFor(self.style, self.pressed, self.enabled)
    local radius = math.min(self.h, self.w) * 0.28

    -- sombra sutil (relevo fisico)
    if not self.pressed then
        love.graphics.setColor(0, 0, 0, 0.12)
        love.graphics.rectangle("fill", self.x + 2, self.y + 3, self.w, self.h, radius, radius)
    end

    love.graphics.setColor(col)
    local yOff = self.pressed and 2 or 0
    love.graphics.rectangle("fill", self.x, self.y + yOff, self.w, self.h, radius, radius)

    -- Realce de hover: borda clara imediata (só quando não pressionado).
    if hovered and not self.pressed then
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x, self.y + yOff, self.w, self.h, radius, radius)
    end

    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", self.x, self.y + yOff, self.w, self.h, radius, radius)

    love.graphics.setColor(theme.colors.btnText)
    love.graphics.setFont(self.font)
    if self.icon == "reset" then
        -- Ícone vetorial de reset (arco + ponta de seta), sem glifo Unicode.
        local cx, cy = self.x + self.w / 2, self.y + yOff + self.h / 2
        local r = math.min(self.w, self.h) * 0.22
        love.graphics.setLineWidth(2)
        love.graphics.arc("line", "open", cx, cy, r, -0.6, math.pi * 1.5)
        local ax, ay = cx + r * math.cos(math.pi * 1.5), cy + r * math.sin(math.pi * 1.5)
        love.graphics.polygon("fill", ax - 5, ay - 1, ax + 3, ay - 5, ax + 3, ay + 4)
    elseif self.icon == "expand" then
        -- Tela cheia: 4 cantos (suporta qualquer fonte, sem Unicode).
        local x0, y0 = self.x + self.w / 2, self.y + yOff + self.h / 2
        local d, l = 5.5, 4.5 -- meio-tamanho e comprimento da perna
        love.graphics.setLineWidth(2)
        for _, sx in ipairs({ -1, 1 }) do
            for _, sy in ipairs({ -1, 1 }) do
                local cx, cy = x0 + sx * d, y0 + sy * d
                love.graphics.line(cx, cy, cx - sx * l, cy)
                love.graphics.line(cx, cy, cx, cy - sy * l)
            end
        end
    elseif self.icon == "gear" then
        -- Engrenagem simplificada: anel + 6 dentes.
        local cx, cy = self.x + self.w / 2, self.y + yOff + self.h / 2
        local r = math.min(self.w, self.h) * 0.20
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", cx, cy, r)
        for i = 0, 5 do
            local a = i * math.pi / 3
            local c, s = math.cos(a), math.sin(a)
            love.graphics.line(cx + c * (r + 1), cy + s * (r + 1),
                cx + c * (r + 4), cy + s * (r + 4))
        end
    elseif self.icon == "pencil" then
        -- Lápis: corpo diagonal + ponta.
        local cx, cy = self.x + self.w / 2, self.y + yOff + self.h / 2
        love.graphics.setLineWidth(2)
        love.graphics.line(cx - 4, cy + 4, cx + 3, cy - 3)
        love.graphics.line(cx - 4, cy + 4, cx - 5.5, cy + 1.5)
        love.graphics.line(cx - 4, cy + 4, cx - 1.5, cy + 5.5)
        love.graphics.circle("fill", cx + 4.5, cy - 4.5, 1.4)
    else
        local _, lineCount = string.gsub(self.label, "\n", "\n")
        lineCount = lineCount + 1
        local totalH = self.font:getHeight() * lineCount
        local textY = self.y + yOff + (self.h - totalH) / 2
        love.graphics.printf(self.label, self.x, textY, self.w, "center")
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Button
