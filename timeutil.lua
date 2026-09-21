-- timeutil.lua
-- Fonte única de tempo monotônico; evita duplicar (love.timer.getTime or os.clock).
local M = {}

function M.now()
    if love and love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return os.clock()
end

return M
