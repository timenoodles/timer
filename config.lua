-- config.lua
-- Configuração central: presets, som, persistência, limites de rótulo.
-- Mudar valores aqui não exige tocar em timer_view.lua.

local config = {}

-- Presets em minutos (botões amarelos, nesta ordem).
config.presets = { 20, 10, 5 }

-- Som de término: "off" | "beep" (1 bip) | "repeat3" (3 bips) | "repeat" (até dispensar).
config.sound = "repeat3"

-- Tema: "classic" (japonês claro, padrão) | "dark" | "contrast".
config.theme = "classic"

-- Persistência do estado (store.lua).
config.autosave = true
config.saveInterval = 2.0 -- segundos entre autosaves

-- Rótulos curtos para preservar a estética LCD.
config.maxLabelLen = 6

-- Nome do arquivo de estado (love.filesystem, save directory).
config.stateFile = "multitimer_state.lua"

return config
