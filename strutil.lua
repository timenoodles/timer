-- strutil.lua
-- Utilidades de string (sem LÖVE, testável fora dele).
-- Lua puro não maiuscula acentos (("é"):upper() == "é"); tabela manual
-- pros acentos comuns. Limite de label conta bytes (#), então cada
-- acento consome 2 do maxLabelLen — aceitável e documentado.

local StrUtil = {}

local ACCENT_UPPER = {
    { "à", "À" }, { "á", "Á" }, { "â", "Â" }, { "ã", "Ã" }, { "ä", "Ä" }, { "å", "Å" },
    { "è", "È" }, { "é", "É" }, { "ê", "Ê" }, { "ë", "Ë" },
    { "ì", "Ì" }, { "í", "Í" }, { "î", "Î" }, { "ï", "Ï" },
    { "ò", "Ò" }, { "ó", "Ó" }, { "ô", "Ô" }, { "õ", "Õ" }, { "ö", "Ö" },
    { "ù", "Ù" }, { "ú", "Ú" }, { "û", "Û" }, { "ü", "Ü" },
    { "ç", "Ç" }, { "ñ", "Ñ" }, { "ý", "Ý" },
}

function StrUtil.upperLabel(s)
    s = tostring(s or ""):upper()
    for _, pair in ipairs(ACCENT_UPPER) do
        s = s:gsub(pair[1], pair[2])
    end
    return s
end

-- Remove o último caractere UTF-8 inteiro (acentos têm 2 bytes).
function StrUtil.stripLastChar(s)
    s = tostring(s or "")
    local i = #s
    while i > 1 and s:byte(i) >= 0x80 and s:byte(i) < 0xC0 do i = i - 1 end
    return s:sub(1, i - 1)
end

return StrUtil
