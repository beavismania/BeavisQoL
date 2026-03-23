local ADDON_NAME = ...

-- Bootstrap.lua greift bewusst sehr früh in den Combat-Text-Font ein.
-- Ziel ist, dass die gewählte Schrift möglichst schon aktiv ist, bevor
-- später andere UI-Teile sie sichtbar benutzen.

-- Der Welttext zieht sich den Basis-Font sehr früh.
-- SavedVariables stehen beim bloßen Parsen der Lua-Datei aber noch nicht
-- verlässlich zur Verfügung. Deshalb wartet der Bootstrap bewusst auf
-- ADDON_LOADED und setzt den Font dann so früh wie möglich.

local function GetConfiguredFontKey()
    local db = rawget(_G, "BeavisQoLDB")
    if type(db) ~= "table" or type(db.damageText) ~= "table" then
        return nil
    end

    if db.damageText.enabled ~= true then
        return nil
    end

    if type(db.damageText.fontKey) == "string" and db.damageText.fontKey ~= "" then
        return db.damageText.fontKey
    end

    return nil
end

local function GetBuiltinFontPath(fontKey)
    local builtinPaths = {
        blizzard = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        frizqt = "Fonts\\FRIZQT__.TTF",
        morpheus = "Fonts\\MORPHEUS.TTF",
        skurri = "Fonts\\SKURRI.TTF",
        arialn = "Fonts\\ARIALN.TTF",
    }

    return builtinPaths[fontKey]
end

local function GetCustomFontPath(fontKey)
    local customFonts = rawget(_G, "BeavisQoL_CustomFonts")
    if type(customFonts) ~= "table" then
        return nil
    end

    for _, fontOption in ipairs(customFonts) do
        if type(fontOption) == "table"
            and fontOption.key == fontKey
            and type(fontOption.path) == "string"
            and fontOption.path ~= "" then
            return fontOption.path
        end
    end

    return nil
end

local function ResolveConfiguredFontPath()
    local fontKey = GetConfiguredFontKey()
    if not fontKey then
        return nil
    end

    -- Erst eingebaute Fonts prüfen, danach die Custom-Font-Liste.
    -- So bleibt "blizzard" ohne Zusatzdateien gültig, während eigene Fonts
    -- denselben Auswahlweg nutzen.
    return GetBuiltinFontPath(fontKey) or GetCustomFontPath(fontKey)
end

local function ApplyBootstrapFont()
    local fontPath = ResolveConfiguredFontPath()
    if type(fontPath) ~= "string" or fontPath == "" then
        _G.BeavisDamageTextBootstrapFont = nil
        return
    end

    _G.BeavisDamageTextOriginalFont = _G.BeavisDamageTextOriginalFont or DAMAGE_TEXT_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    _G.BeavisDamageTextBootstrapFont = fontPath
    -- DAMAGE_TEXT_FONT wird hier schon im Bootstrap gesetzt, damit der frühe
    -- Combat Text möglichst gar nicht erst mit der alten Schrift sichtbar wird.
    DAMAGE_TEXT_FONT = fontPath
end

local BootstrapWatcher = CreateFrame("Frame")
BootstrapWatcher:RegisterEvent("ADDON_LOADED")
BootstrapWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

BootstrapWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME and loadedAddon ~= "Blizzard_CombatText" then
            return
        end
    end

    ApplyBootstrapFont()
end)
