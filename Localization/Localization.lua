local ADDON_NAME, BeavisQoL = ...

local clientLocale = GetLocale()
local defaultLocale = "deDE"
local fallbackLocale = "enUS"

BeavisQoL = BeavisQoL or {}
BeavisQoL.Localization = BeavisQoL.Localization or {}

local availableLocales = {
    "deDE",
    "enUS",
}

local localeAliases = {
    enGB = "enUS",
}

local function NormalizeLocale(code)
    if not code or code == "" then
        return defaultLocale
    end

    return localeAliases[code] or code
end

local function LoadLocale(code)
    local normalizedCode = NormalizeLocale(code)
    return BeavisQoL.Localization[normalizedCode]
end

local function GetCurrentLocale()
    local selectedLocale = BeavisQoLDB and BeavisQoLDB.language or clientLocale
    return NormalizeLocale(selectedLocale)
end

local function SetCurrentLocale(code)
    local normalizedCode = NormalizeLocale(code)

    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.language = normalizedCode
end

local function L(key)
    local activeLocale = LoadLocale(GetCurrentLocale())
    local primaryFallback = LoadLocale(defaultLocale)
    local secondaryFallback = LoadLocale(fallbackLocale)

    if activeLocale and activeLocale[key] ~= nil then
        return activeLocale[key]
    end

    if primaryFallback and primaryFallback[key] ~= nil then
        return primaryFallback[key]
    end

    if secondaryFallback and secondaryFallback[key] ~= nil then
        return secondaryFallback[key]
    end

    return key
end

BeavisQoL.L = L
BeavisQoL.AvailableLocales = availableLocales
BeavisQoL.SetLocale = SetCurrentLocale
BeavisQoL.GetLocale = GetCurrentLocale
BeavisQoL.LoadLocale = LoadLocale
