local ADDON_NAME, BeavisQoL = ...

BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG
local L = BeavisQoL.L

-- Flags.lua ist das technische Herz des LFG-Moduls:
-- Realm erkennen, Land ableiten, kleine Flagge zeichnen und Blizzard-Zeilen hooken.

-- Dieses Modul liest Realm-Namen aus dem Group Finder, ordnet sie einem Land zu
-- und rendert kleine Flaggen direkt mit WoW-Texturen statt mit externen Bildern.

-- Applicant- und Suchergebnis-Hooks kommen getrennt rein, weil Blizzard beides zu unterschiedlichen Zeitpunkten laden kann.
local applicantHookInstalled = false
local searchResultHookInstalled = false
local DEFAULT_EASY_LFG_SCALE = 0.90
local MIN_EASY_LFG_SCALE = 0.70
local MAX_EASY_LFG_SCALE = 1.15
local DEFAULT_EASY_LFG_TEXT_SCALE = 1.00
local MIN_EASY_LFG_TEXT_SCALE = 0.75
local MAX_EASY_LFG_TEXT_SCALE = 1.50
local DEFAULT_EASY_LFG_ALPHA = 0.58
local MIN_EASY_LFG_ALPHA = 0.25
local MAX_EASY_LFG_ALPHA = 0.85
local DEFAULT_EASY_LFG_POINT = "CENTER"
local DEFAULT_EASY_LFG_RELATIVE_POINT = "CENTER"
local DEFAULT_EASY_LFG_OFFSET_X = 420
local DEFAULT_EASY_LFG_OFFSET_Y = -40
local DEFAULT_EASY_LFG_WIDTH = 328
local DEFAULT_EASY_LFG_HEIGHT = 288
local MIN_EASY_LFG_WIDTH = 328
local MAX_EASY_LFG_WIDTH = 520
local MIN_EASY_LFG_HEIGHT = 144
local MAX_EASY_LFG_HEIGHT = 640
local EASY_LFG_REMOVAL_GRACE_SECONDS = 2.0
local EASY_LFG_HOVER_REMOVAL_RECHECK_SECONDS = 0.25
local LISTING_TEXT_PRESET_COUNT = 5
local EasyLFGOverlay = nil
local EasyLFGRows = {}
local EasyLFGExpandedApplicants = {}
local EasyLFGSuppressed = false
local EasyLFGWasActiveListing = false
local EasyLFGApplicantStates = {}
local EasyLFGNextApplicantOrder = 1
local EasyLFGRemovalRefreshAt = nil
local EasyLFGRemovalRefreshSerial = 0
local EasyLFGRioTooltip = nil
local EasyLFGRioAnchor = nil
local EasyLFGRioPanel = nil
local EasyLFGRioSelectedFullName = nil
local EasyLFGRioSelectedDisplayName = nil
local EASY_LFG_RIO_PANEL_WIDTH = 300
local EASY_LFG_RIO_PANEL_MIN_HEIGHT = 96
local EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING = 18
local EASY_LFG_RIO_PANEL_TOP_PADDING = 16
local EASY_LFG_RIO_PANEL_BOTTOM_PADDING = 14
local EASY_LFG_RIO_PANEL_LINE_SPACING = 4
local EASY_LFG_RIO_PANEL_MAX_DUNGEONS = 8
local EASY_LFG_RIO_PANEL_MAX_RAIDS = 6
local EASY_LFG_ACTION_BUTTON_WIDTH = 34
local EASY_LFG_ACTION_BUTTON_HEIGHT = 22
local EASY_LFG_ACTION_BUTTON_GAP = 6
local EASY_LFG_ACTION_AREA_WIDTH = (EASY_LFG_ACTION_BUTTON_WIDTH * 2) + EASY_LFG_ACTION_BUTTON_GAP
local EASY_LFG_RIO_DIFFICULTY_LABELS = {
    [1] = "LFR",
    [2] = "N",
    [3] = "HC",
    [4] = "M",
}

local floor = math.floor

local function SafeSecureCall(func, ...)
    if type(func) ~= "function" then
        return false
    end

    local secureCall = rawget(_G, "securecallfunction")
    if type(secureCall) == "function" then
        local ok = pcall(secureCall, func, ...)
        return ok == true
    end

    local ok = pcall(func, ...)
    return ok == true
end

local function SafeSecureCallMethod(target, methodName, ...)
    if not target or type(methodName) ~= "string" or methodName == "" then
        return false
    end

    local method = target[methodName]
    if type(method) ~= "function" then
        return false
    end

    local secureCall = rawget(_G, "securecallfunction")
    if type(secureCall) == "function" then
        local ok = pcall(secureCall, method, target, ...)
        return ok == true
    end

    local ok = pcall(method, target, ...)
    return ok == true
end

local function SanitizeInteger(value)
    local numericValue = tonumber(value)
    if type(numericValue) ~= "number" then
        return nil
    end

    return floor(numericValue + 0.5)
end

local function SanitizeDecimal(value, decimals)
    local numericValue = tonumber(value)
    if type(numericValue) ~= "number" then
        return nil
    end

    return tonumber(string.format("%." .. tostring(decimals or 0) .. "f", numericValue))
end

local function SanitizeApplicantStatus(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

local function GetApplicantSortKey(applicantGroup)
    local primaryMember = applicantGroup and applicantGroup.members and applicantGroup.members[1] or nil
    if primaryMember and type(primaryMember.fullName) == "string" and primaryMember.fullName ~= "" then
        return primaryMember.fullName
    end

    if primaryMember and type(primaryMember.displayName) == "string" and primaryMember.displayName ~= "" then
        return primaryMember.displayName
    end

    return ""
end

local function NormalizeListingPresetLineEndings(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function NormalizeListingSingleLinePreset(text)
    text = NormalizeListingPresetLineEndings(text)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("%s*\n%s*", " ")
    text = text:gsub("%s+", " ")
    return text
end

local function NormalizeListingMultiLinePreset(text)
    text = NormalizeListingPresetLineEndings(text)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("[ \t]+\n", "\n")
    text = text:gsub("\n[ \t]+", "\n")
    return text
end

local function EnsureListingPresetSlots(db, listKey, legacyKey, normalizeFunc)
    local slots = {}
    local existingSlots = type(db[listKey]) == "table" and db[listKey] or nil

    for index = 1, LISTING_TEXT_PRESET_COUNT do
        slots[index] = existingSlots and normalizeFunc(existingSlots[index]) or ""
    end

    local legacyValue = normalizeFunc(db[legacyKey])
    if slots[1] == "" and legacyValue ~= "" then
        slots[1] = legacyValue
    end

    db[listKey] = slots
    db[legacyKey] = ""
    for index = 1, LISTING_TEXT_PRESET_COUNT do
        if slots[index] ~= "" then
            db[legacyKey] = slots[index]
            break
        end
    end
end

-- Realm -> Flagge.
-- Blizzard liefert uns kein direktes "Land", also leiten wir es hier über den Realm ab.
-- Die Tabellen enthalten nur Realms mit Nicht-Default-Flagge plus bekannte Alias-Schreibweisen.
-- EU fällt weiterhin auf GB zurück, US auf US.
local EU_REALM_FLAG_GROUPS = {
    DE = {
        "aegwynn",
        "alexstrasza",
        "alleria",
        "aman'thul",
        "ambossar",
        "anetheron",
        "anub'arak",
        "antonidas",
        "area52",
        "arygos",
        "arthas",
        "azshara",
        "baelgun",
        "blackhand",
        "blackmoore",
        "blackrock",
        "blutkessel",
        "daskonsortium",
        "dassyndikat",
        "dalvengyr",
        "derabyssischerat",
        "dermithrilorden",
        "derratvondalaran",
        "dethecus",
        "diealdor",
        "diearguswacht",
        "dieewigewacht",
        "dienachtwache",
        "diesilbernehand",
        "dietodeskrallen",
        "dunmorogh",
        "durotan",
        "echsenkessel",
        "eredar",
        "festungderstürme",
        "forscherliga",
        "frostmourne",
        "frostwolf",
        "garrosh",
        "gilneas",
        "gorgonnash",
        "gul'dan",
        "kargath",
        "kel'thuzad",
        "khaz'goroth",
        "kil'jaeden",
        "krag'jin",
        "kultderverdammten",
        "lordaeron",
        "lothar",
        "madmortem",
        "mal'ganis",
        "malfurion",
        "malorne",
        "malygos",
        "mannoroth",
        "mug'thol",
        "nathrezim",
        "nazjatar",
        "nefarian",
        "nera'thor",
        "nethersturm",
        "norgannon",
        "nozdormu",
        "onyxia",
        "perenolde",
        "proudmoore",
        "rajaxx",
        "rexxar",
        "rubinwacht",
        "sen'jin",
        "shattrath",
        "taerar",
        "teldrassil",
        "terrordar",
        "theradras",
        "thrall",
        "tichondrius",
        "tirion",
        "todeswache",
        "ulduar",
        "un'goro",
        "vek'lor",
        "wrathbringer",
        "ysera",
        "zirkeldescenarius",
        "zuluhed",
    },
    ES = {
        "c'thun",
        "colinaspardas",
        "dunmodr",
        "exodar",
        "loserrantes",
        "mandokir",
        "minahonda",
        "sanguino",
        "shen'dralar",
        "tyrande",
        "uldum",
        "zul'jin",
    },
    PT = {
        "aggra(português)",
        "aggra(portuguese)",
        "aggra(portugues)",
    },
    IT = {
        "nemesis",
        "pozzodell'eternità",
        "pozzodell'eternita",
    },
    FR = {
        "arakarahm",
        "arathi",
        "archimonde",
        "chantséternels",
        "cho'gall",
        "confrérieduthorium",
        "conseildesombres",
        "cultedelarivenoire",
        "dalaran",
        "drek'thar",
        "eldre'thalas",
        "eitrigg",
        "elune",
        "garona",
        "hyjal",
        "illidan",
        "kael'thas",
        "khazmodan",
        "kirintor",
        "krasus",
        "lacroisadeécarlate",
        "lesclairvoyants",
        "lessentinelles",
        "marécagedezangar",
        "medivh",
        "naxxramas",
        "ner'zhul",
        "rashgarroth",
        "sargeras",
        "sinstralis",
        "suramar",
        "templenoir",
        "throk'feroth",
        "uldaman",
        "varimathras",
        "vol'jin",
        "ysondre",
    },
    RU = {
        "Азурегос",
        "Борейская тундра",
        "Вечная Песня",
        "Галакронд",
        "Голдринн",
        "Гордунни",
        "Гром",
        "Дракономор",
        "Король-лич",
        "Пиратская Бухта",
        "Подземье",
        "Разувий",
        "Ревущий фьорд",
        "Свежеватель Душ",
        "Седогрив",
        "Страж Смерти",
        "Термоштепсель",
        "Ткач Смерти",
        "Черный Шрам",
        "Ясеневый лес",
        "Azuregos",
        "Borean Tundra",
        "Eversong",
        "Galakrond",
        "Goldrinn",
        "Gordunni",
        "Grom",
        "Drakonomor",
        "Lich King",
        "Booty Bay",
        "Deepholm",
        "Razuvious",
        "Howling Fjord",
        "Soulflayer",
        "Greymane",
        "Deathguard",
        "Thermaplugg",
        "Deathweaver",
        "Blackscar",
        "Ashenvale",
    },
}

local US_REALM_FLAG_GROUPS = {
    BR = {
        "azralon",
        "gallywix",
        "goldrinn",
        "nemesis",
        "tolbarad",
    },
    AU = {
        "aman'thul",
        "barthilas",
        "caelestrasz",
        "dath'remar",
        "dreadmaul",
        "frostmourne",
        "gundrak",
        "jubei'thos",
        "khaz'goroth",
        "nagrand",
        "saurfang",
        "thaurissan",
    },
    MX = {
        "drakkari",
        "quel'thalas",
        "ragnaros",
    },
}

local EU_REALM_FLAGS = nil
local US_REALM_FLAGS = nil

function LFG.GetLFGDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.lfg = BeavisQoLDB.lfg or {}

    if BeavisQoLDB.lfg.flagsEnabled == nil then
        BeavisQoLDB.lfg.flagsEnabled = false
    end

    if BeavisQoLDB.lfg.easyLFGEnabled == nil then
        BeavisQoLDB.lfg.easyLFGEnabled = false
    end

    if BeavisQoLDB.lfg.easyLFGLocked == nil then
        BeavisQoLDB.lfg.easyLFGLocked = false
    end

    if BeavisQoLDB.lfg.easyLFGRioExpanded == nil then
        BeavisQoLDB.lfg.easyLFGRioExpanded = false
    end

    if type(BeavisQoLDB.lfg.easyLFGScale) ~= "number" then
        BeavisQoLDB.lfg.easyLFGScale = DEFAULT_EASY_LFG_SCALE
    end
    BeavisQoLDB.lfg.easyLFGScale = math.max(MIN_EASY_LFG_SCALE, math.min(MAX_EASY_LFG_SCALE, BeavisQoLDB.lfg.easyLFGScale))

    if type(BeavisQoLDB.lfg.easyLFGTextScale) ~= "number" then
        BeavisQoLDB.lfg.easyLFGTextScale = DEFAULT_EASY_LFG_TEXT_SCALE
    end
    BeavisQoLDB.lfg.easyLFGTextScale = math.max(MIN_EASY_LFG_TEXT_SCALE, math.min(MAX_EASY_LFG_TEXT_SCALE, BeavisQoLDB.lfg.easyLFGTextScale))

    if type(BeavisQoLDB.lfg.easyLFGAlpha) ~= "number" then
        BeavisQoLDB.lfg.easyLFGAlpha = DEFAULT_EASY_LFG_ALPHA
    end
    BeavisQoLDB.lfg.easyLFGAlpha = math.max(MIN_EASY_LFG_ALPHA, math.min(MAX_EASY_LFG_ALPHA, BeavisQoLDB.lfg.easyLFGAlpha))

    if type(BeavisQoLDB.lfg.easyLFGPoint) ~= "string" or BeavisQoLDB.lfg.easyLFGPoint == "" then
        BeavisQoLDB.lfg.easyLFGPoint = DEFAULT_EASY_LFG_POINT
    end

    if type(BeavisQoLDB.lfg.easyLFGRelativePoint) ~= "string" or BeavisQoLDB.lfg.easyLFGRelativePoint == "" then
        BeavisQoLDB.lfg.easyLFGRelativePoint = DEFAULT_EASY_LFG_RELATIVE_POINT
    end

    if type(BeavisQoLDB.lfg.easyLFGOffsetX) ~= "number" then
        BeavisQoLDB.lfg.easyLFGOffsetX = DEFAULT_EASY_LFG_OFFSET_X
    end

    if type(BeavisQoLDB.lfg.easyLFGOffsetY) ~= "number" then
        BeavisQoLDB.lfg.easyLFGOffsetY = DEFAULT_EASY_LFG_OFFSET_Y
    end

    if type(BeavisQoLDB.lfg.easyLFGWidth) ~= "number" then
        BeavisQoLDB.lfg.easyLFGWidth = DEFAULT_EASY_LFG_WIDTH
    end
    BeavisQoLDB.lfg.easyLFGWidth = math.max(MIN_EASY_LFG_WIDTH, math.min(MAX_EASY_LFG_WIDTH, BeavisQoLDB.lfg.easyLFGWidth))

    if type(BeavisQoLDB.lfg.easyLFGHeight) ~= "number" then
        BeavisQoLDB.lfg.easyLFGHeight = DEFAULT_EASY_LFG_HEIGHT
    end
    BeavisQoLDB.lfg.easyLFGHeight = math.max(MIN_EASY_LFG_HEIGHT, math.min(MAX_EASY_LFG_HEIGHT, BeavisQoLDB.lfg.easyLFGHeight))

    if BeavisQoLDB.lfg.listingAutoFillEnabled == nil then
        BeavisQoLDB.lfg.listingAutoFillEnabled = true
    end

    if type(BeavisQoLDB.lfg.listingNameSuffix) ~= "string" then
        BeavisQoLDB.lfg.listingNameSuffix = ""
    end
    EnsureListingPresetSlots(BeavisQoLDB.lfg, "listingNamePresets", "listingNameSuffix", NormalizeListingSingleLinePreset)

    if type(BeavisQoLDB.lfg.listingDetailsPreset) ~= "string" then
        BeavisQoLDB.lfg.listingDetailsPreset = ""
    end
    EnsureListingPresetSlots(BeavisQoLDB.lfg, "listingDetailsPresets", "listingDetailsPreset", NormalizeListingMultiLinePreset)

    if type(BeavisQoLDB.lfg.listingPlaystylePreset) ~= "number" then
        BeavisQoLDB.lfg.listingPlaystylePreset = 0
    end
    BeavisQoLDB.lfg.listingPlaystylePreset = math.max(0, math.floor(BeavisQoLDB.lfg.listingPlaystylePreset + 0.5))

    return BeavisQoLDB.lfg
end

local function IsEasyLFGRioExpanded()
    return LFG.GetLFGDB().easyLFGRioExpanded == true
end

local function GetRaiderIOAPI()
    local api = rawget(_G, "RaiderIO")
    if type(api) ~= "table" then
        return nil
    end

    return api
end

local function IsRaiderIOAvailable()
    local api = GetRaiderIOAPI()
    return api ~= nil and (type(api.ShowProfile) == "function" or type(api.GetProfile) == "function")
end

function LFG.IsFlagsEnabled()
    return LFG.GetLFGDB().flagsEnabled == true
end

-- Manche Blizzard-Felder kommen inzwischen als "secret value" rein.
-- Solche Werte dürfen wir nicht wie normale Strings behandeln.
local function IsSecretValue(value)
    if not issecretvalue then
        return false
    end

    local ok, isSecret = pcall(issecretvalue, value)
    return ok and isSecret or false
end

local function IsUsablePlainString(value)
    if IsSecretValue(value) then
        return false
    end

    local ok, isUsable = pcall(function()
        return type(value) == "string" and value ~= ""
    end)

    return ok and isUsable or false
end

-- Realmnamen kommen je nach Quelle mit Bindestrich oder etwas seltsamen Leerzeichen rein.
local function NormalizeRealmName(realmName)
    if not IsUsablePlainString(realmName) then
        return nil
    end

    realmName = realmName:gsub("%s+", " ")
    realmName = realmName:gsub("^%s+", "")
    realmName = realmName:gsub("%s+$", "")

    return realmName
end

local function NormalizeRealmLookupKey(realmName)
    realmName = NormalizeRealmName(realmName)
    if not realmName then
        return nil
    end

    realmName = realmName:gsub("[%s%-]+", "")
    realmName = realmName:gsub("[A-Z]", function(letter)
        return string.lower(letter)
    end)

    return realmName
end

local function BuildRealmFlagMap(groups)
    local realmFlags = {}

    for countryCode, realms in pairs(groups) do
        for _, realmName in ipairs(realms) do
            local realmKey = NormalizeRealmLookupKey(realmName)
            if realmKey then
                realmFlags[realmKey] = countryCode
            end
        end
    end

    return realmFlags
end

EU_REALM_FLAGS = BuildRealmFlagMap(EU_REALM_FLAG_GROUPS)
US_REALM_FLAGS = BuildRealmFlagMap(US_REALM_FLAG_GROUPS)

-- Applicant-Namen kommen als "Name-Realm". Für denselben Realm wie wir selbst gibt es nicht immer einen Bindestrich.
local function GetRealmNameFromFullName(fullName)
    if not IsUsablePlainString(fullName) then
        return nil
    end

    local realmName = fullName:match("%-(.+)$")
    if IsUsablePlainString(realmName) then
        return NormalizeRealmName(realmName)
    end

    if GetRealmName then
        return NormalizeRealmName(GetRealmName())
    end
end

local function GetDisplayNameFromFullName(fullName)
    if not IsUsablePlainString(fullName) then
        return nil
    end

    if Ambiguate then
        local ok, shortName = pcall(Ambiguate, fullName, "short")
        if ok and IsUsablePlainString(shortName) then
            return shortName
        end
    end

    return fullName:match("^[^-]+") or fullName
end

-- Fallback, falls ein Realm noch nicht in unserer Liste steht.
local function GetDefaultFlagForRegion()
    if not GetCurrentRegion then
        return nil
    end

    local region = GetCurrentRegion()
    if region == 3 then
        return "GB"
    end

    if region == 1 then
        return "US"
    end
end

-- Die eigentliche Zuordnung läuft absichtlich separat, damit man die Realm-Listen später leichter erweitern kann.
function LFG.GetCountryCodeForRealm(realmName)
    local realmKey = NormalizeRealmLookupKey(realmName)
    if not realmKey then
        return nil
    end

    if GetCurrentRegion and GetCurrentRegion() == 3 then
        return EU_REALM_FLAGS[realmKey] or GetDefaultFlagForRegion()
    end

    if GetCurrentRegion and GetCurrentRegion() == 1 then
        return US_REALM_FLAGS[realmKey] or GetDefaultFlagForRegion()
    end

    return nil
end

-- Vor jedem Rendern setzen wir den Flaggen-Frame wieder komplett in einen neutralen Zustand.
local function HideFlagParts(flagFrame)
    flagFrame.Background:Hide()

    for _, texture in ipairs(flagFrame.Parts) do
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetRotation(0)
    end
end

local function SetTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], 1)
end

-- Kleine Bauhelfer für simple Flaggen, die nur aus Streifen bestehen.
local function DrawHorizontalStripes(flagFrame, colors, ratios)
    local totalRatio = 0
    for _, ratio in ipairs(ratios) do
        totalRatio = totalRatio + ratio
    end

    local offsetY = 0
    for index, color in ipairs(colors) do
        local texture = flagFrame.Parts[index]
        local height = flagFrame:GetHeight() * (ratios[index] / totalRatio)

        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, -offsetY)
        texture:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, -offsetY)
        texture:SetHeight(height)
        SetTextureColor(texture, color)
        texture:Show()

        offsetY = offsetY + height
    end
end

local function DrawVerticalStripes(flagFrame, colors, ratios)
    local totalRatio = 0
    for _, ratio in ipairs(ratios) do
        totalRatio = totalRatio + ratio
    end

    local offsetX = 0
    for index, color in ipairs(colors) do
        local texture = flagFrame.Parts[index]
        local width = flagFrame:GetWidth() * (ratios[index] / totalRatio)

        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", offsetX, 0)
        texture:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", offsetX, 0)
        texture:SetWidth(width)
        SetTextureColor(texture, color)
        texture:Show()

        offsetX = offsetX + width
    end
end

-- Die komplexeren Flaggen bauen wir bewusst selbst aus Texturen auf,
-- damit wir keine externen Assets mitschleppen müssen.
local function DrawUnionJack(flagFrame)
    local angle = math.atan(12 / 18)

    flagFrame.Background:SetColorTexture(0.0, 0.16, 0.53, 1)
    flagFrame.Background:Show()

    local diagWhiteA = flagFrame.Parts[1]
    diagWhiteA:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagWhiteA:SetSize(24, 3)
    diagWhiteA:SetRotation(angle)
    SetTextureColor(diagWhiteA, { 1, 1, 1 })
    diagWhiteA:Show()

    local diagWhiteB = flagFrame.Parts[2]
    diagWhiteB:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagWhiteB:SetSize(24, 3)
    diagWhiteB:SetRotation(-angle)
    SetTextureColor(diagWhiteB, { 1, 1, 1 })
    diagWhiteB:Show()

    local crossWhiteH = flagFrame.Parts[3]
    crossWhiteH:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossWhiteH:SetSize(flagFrame:GetWidth(), 4)
    SetTextureColor(crossWhiteH, { 1, 1, 1 })
    crossWhiteH:Show()

    local crossWhiteV = flagFrame.Parts[4]
    crossWhiteV:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossWhiteV:SetSize(4, flagFrame:GetHeight())
    SetTextureColor(crossWhiteV, { 1, 1, 1 })
    crossWhiteV:Show()

    local diagRedA = flagFrame.Parts[5]
    diagRedA:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagRedA:SetSize(24, 1)
    diagRedA:SetRotation(angle)
    SetTextureColor(diagRedA, { 0.78, 0.0, 0.13 })
    diagRedA:Show()

    local diagRedB = flagFrame.Parts[6]
    diagRedB:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagRedB:SetSize(24, 1)
    diagRedB:SetRotation(-angle)
    SetTextureColor(diagRedB, { 0.78, 0.0, 0.13 })
    diagRedB:Show()

    local crossRedH = flagFrame.Parts[7]
    crossRedH:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossRedH:SetSize(flagFrame:GetWidth(), 2)
    SetTextureColor(crossRedH, { 0.78, 0.0, 0.13 })
    crossRedH:Show()

    local crossRedV = flagFrame.Parts[8]
    crossRedV:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossRedV:SetSize(2, flagFrame:GetHeight())
    SetTextureColor(crossRedV, { 0.78, 0.0, 0.13 })
    crossRedV:Show()
end

local function DrawUSFlag(flagFrame)
    DrawHorizontalStripes(flagFrame, {
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
    }, { 1, 1, 1, 1, 1, 1, 1 })

    local canton = flagFrame.Parts[8]
    canton:ClearAllPoints()
    canton:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    canton:SetSize(8, 6)
    SetTextureColor(canton, { 0.16, 0.21, 0.58 })
    canton:Show()
end

local function DrawBrazilFlag(flagFrame)
    flagFrame.Background:SetColorTexture(0.0, 0.61, 0.28, 1)
    flagFrame.Background:Show()

    local diamond = flagFrame.Parts[1]
    diamond:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diamond:SetSize(10, 10)
    diamond:SetRotation(math.rad(45))
    SetTextureColor(diamond, { 1.0, 0.87, 0.0 })
    diamond:Show()

    local orb = flagFrame.Parts[2]
    orb:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    orb:SetSize(4, 4)
    SetTextureColor(orb, { 0.0, 0.15, 0.55 })
    orb:Show()
end

local function DrawMexicoFlag(flagFrame)
    DrawVerticalStripes(flagFrame, {
        { 0.0, 0.40, 0.21 },
        { 1.0, 1.0, 1.0 },
        { 0.81, 0.12, 0.17 },
    }, { 1, 1, 1 })

    local emblem = flagFrame.Parts[4]
    emblem:ClearAllPoints()
    emblem:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    emblem:SetSize(2, 2)
    SetTextureColor(emblem, { 0.42, 0.29, 0.10 })
    emblem:Show()
end

local function DrawAustraliaFlag(flagFrame)
    flagFrame.Background:SetColorTexture(0.0, 0.16, 0.53, 1)
    flagFrame.Background:Show()

    local star = flagFrame.Parts[1]
    star:SetPoint("CENTER", flagFrame, "CENTER", 4, -1)
    star:SetSize(3, 3)
    SetTextureColor(star, { 1, 1, 1 })
    star:Show()

    local cantonH = flagFrame.Parts[2]
    cantonH:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    cantonH:SetSize(8, 2)
    SetTextureColor(cantonH, { 1, 1, 1 })
    cantonH:Show()

    local cantonV = flagFrame.Parts[3]
    cantonV:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 3, 0)
    cantonV:SetSize(2, 6)
    SetTextureColor(cantonV, { 1, 1, 1 })
    cantonV:Show()

    local cantonRedH = flagFrame.Parts[4]
    cantonRedH:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    cantonRedH:SetSize(8, 1)
    SetTextureColor(cantonRedH, { 0.78, 0.0, 0.13 })
    cantonRedH:Show()

    local cantonRedV = flagFrame.Parts[5]
    cantonRedV:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 3, 0)
    cantonRedV:SetSize(1, 6)
    SetTextureColor(cantonRedV, { 0.78, 0.0, 0.13 })
    cantonRedV:Show()
end

-- Jeder Applicant-Row bekommt genau einen wiederverwendbaren Flaggen-Frame.
local function EnsureFlagFrame(parent)
    if parent.BeavisCountryFlag then
        return parent.BeavisCountryFlag
    end

    -- Der Frame wird nur einmal erzeugt und danach für spätere Updates
    -- wiederverwendet. Das spart Arbeit bei jeder Listen-Aktualisierung.
    local flagFrame = CreateFrame("Frame", nil, parent)
    flagFrame:SetSize(18, 12)
    flagFrame:Hide()

    flagFrame.Background = flagFrame:CreateTexture(nil, "BACKGROUND")
    flagFrame.Background:SetAllPoints()
    flagFrame.Background:Hide()

    flagFrame.Parts = {}
    for index = 1, 8 do
        local texture = flagFrame:CreateTexture(nil, "ARTWORK")
        texture:Hide()
        flagFrame.Parts[index] = texture
    end

    local borderTop = flagFrame:CreateTexture(nil, "OVERLAY")
    borderTop:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0, 0, 0, 0.9)

    local borderBottom = flagFrame:CreateTexture(nil, "OVERLAY")
    borderBottom:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", flagFrame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0, 0, 0, 0.9)

    local borderLeft = flagFrame:CreateTexture(nil, "OVERLAY")
    borderLeft:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0, 0, 0, 0.9)

    local borderRight = flagFrame:CreateTexture(nil, "OVERLAY")
    borderRight:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", flagFrame, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0, 0, 0, 0.9)

    parent.BeavisCountryFlag = flagFrame
    return flagFrame
end

-- Hier landet die Auswahl der Flaggen-Optik.
local function RenderFlag(flagFrame, countryCode)
    HideFlagParts(flagFrame)

    if countryCode == "DE" then
        DrawHorizontalStripes(flagFrame, {
            { 0.0, 0.0, 0.0 },
            { 0.87, 0.0, 0.0 },
            { 1.0, 0.81, 0.0 },
        }, { 1, 1, 1 })
    elseif countryCode == "GB" then
        DrawUnionJack(flagFrame)
    elseif countryCode == "ES" then
        DrawHorizontalStripes(flagFrame, {
            { 0.67, 0.0, 0.12 },
            { 1.0, 0.80, 0.0 },
            { 0.67, 0.0, 0.12 },
        }, { 1, 2, 1 })
    elseif countryCode == "PT" then
        DrawVerticalStripes(flagFrame, {
            { 0.0, 0.40, 0.18 },
            { 0.82, 0.0, 0.0 },
        }, { 2, 3 })
    elseif countryCode == "IT" then
        DrawVerticalStripes(flagFrame, {
            { 0.0, 0.57, 0.27 },
            { 1.0, 1.0, 1.0 },
            { 0.81, 0.0, 0.0 },
        }, { 1, 1, 1 })
    elseif countryCode == "FR" then
        DrawVerticalStripes(flagFrame, {
            { 0.0, 0.19, 0.57 },
            { 1.0, 1.0, 1.0 },
            { 0.86, 0.14, 0.20 },
        }, { 1, 1, 1 })
    elseif countryCode == "RU" then
        DrawHorizontalStripes(flagFrame, {
            { 1.0, 1.0, 1.0 },
            { 0.0, 0.22, 0.72 },
            { 0.84, 0.17, 0.22 },
        }, { 1, 1, 1 })
    elseif countryCode == "US" then
        DrawUSFlag(flagFrame)
    elseif countryCode == "BR" then
        DrawBrazilFlag(flagFrame)
    elseif countryCode == "MX" then
        DrawMexicoFlag(flagFrame)
    elseif countryCode == "AU" then
        DrawAustraliaFlag(flagFrame)
    else
        flagFrame:Hide()
        return
    end

    flagFrame:Show()
end

local function GetFontStringByKeys(frame, preferredKeys)
    for _, key in ipairs(preferredKeys) do
        local region = frame[key]
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function GetAllFontStrings(frame)
    local fontStrings = {}

    -- Blizzard benennt Text-Regionen nicht in jeder Ansicht gleich.
    -- Darum sammeln wir rekursiv alle FontStrings eines Frame-Baums ein.
    local function CollectFontStrings(owner)
        for _, region in ipairs({ owner:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                table.insert(fontStrings, region)
            end
        end

        for _, child in ipairs({ owner:GetChildren() }) do
            CollectFontStrings(child)
        end
    end

    CollectFontStrings(frame)
    return fontStrings
end

local function FontStringContainsDisplayName(fontString, displayName)
    if not fontString or not displayName or not fontString.GetText then
        return false
    end

    local text = fontString:GetText()
    if not IsUsablePlainString(text) then
        return false
    end

    return text == displayName or text:find(displayName, 1, true) ~= nil
end

local function GetVisibleFontStringWidth(fontString)
    if not fontString or not fontString.GetStringWidth then
        return nil
    end

    local width = fontString:GetStringWidth() or 0
    if width <= 0 then
        return nil
    end

    local regionWidth = fontString:GetWidth() or 0
    if regionWidth > 0 then
        width = math.min(width, regionWidth)
    end

    return width
end

local function AnchorFlagBehindName(flagFrame, anchorRegion, paddingX, offsetY)
    flagFrame:ClearAllPoints()

    if not anchorRegion or not anchorRegion.GetObjectType or anchorRegion:GetObjectType() ~= "FontString" then
        flagFrame:SetPoint("LEFT", anchorRegion, "RIGHT", paddingX or 6, offsetY or 0)
        return
    end

    local regionWidth = anchorRegion:GetWidth() or 0
    local visibleWidth = GetVisibleFontStringWidth(anchorRegion) or 0
    local justifyH = anchorRegion.GetJustifyH and anchorRegion:GetJustifyH() or "LEFT"
    local anchorOffset = visibleWidth

    if regionWidth > 0 then
        if justifyH == "RIGHT" then
            anchorOffset = regionWidth
        elseif justifyH == "CENTER" then
            anchorOffset = (regionWidth + visibleWidth) / 2
        end
    end

    if anchorOffset <= 0 then
        flagFrame:SetPoint("LEFT", anchorRegion, "RIGHT", paddingX or 6, offsetY or 0)
        return
    end

    -- Wir verankern an der sichtbaren Textbreite statt am gesamten Namensfeld,
    -- damit die Flagge wirklich hinter dem Namen bleibt und nicht in Score-Spalten rutscht.
    flagFrame:SetPoint("LEFT", anchorRegion, "LEFT", anchorOffset + (paddingX or 6), offsetY or 0)
end

-- Der Blizzard-Applicant-Row ist nicht super konsistent benannt.
-- Deshalb suchen wir zuerst nach bekannten Keys und fallen dann auf die Regionen des Frames zurück.
local function GetApplicantNameRegion(memberFrame)
    local preferredKeys = {
        "Name",
        "name",
        "MemberName",
        "PlayerName",
    }

    local region = GetFontStringByKeys(memberFrame, preferredKeys)
    if region then
        return region
    end

    for _, fontString in ipairs(GetAllFontStrings(memberFrame)) do
        local text = fontString.GetText and fontString:GetText()
        if IsUsablePlainString(text) and text ~= INVITE then
            return fontString
        end
    end
end

-- Bei Suchergebnissen hängen wir die Flagge an den sichtbaren Gruppentitel.
local function GetSearchResultNameRegion(resultFrame, leaderFullName)
    local displayName = GetDisplayNameFromFullName(leaderFullName)
    local preferredKeys = {
        "LeaderName",
        "Leader",
        "LeaderText",
        "LeaderNameText",
        "Name",
        "name",
        "Title",
        "TitleText",
        "NameString",
        "ActivityName",
    }

    if displayName then
        for _, key in ipairs(preferredKeys) do
            local region = GetFontStringByKeys(resultFrame, { key })
            if region and FontStringContainsDisplayName(region, displayName) then
                return region
            end
        end

        for _, fontString in ipairs(GetAllFontStrings(resultFrame)) do
            if FontStringContainsDisplayName(fontString, displayName) then
                return fontString
            end
        end
    end

    local region = GetFontStringByKeys(resultFrame, preferredKeys)
    if region then
        return region
    end

    for _, fontString in ipairs(GetAllFontStrings(resultFrame)) do
        return fontString
    end

    return resultFrame
end

-- Je nach Blizzard-Version oder Hook-Signatur liegt die SearchResult-ID an
-- unterschiedlichen Stellen. Diese Funktion normalisiert alle Varianten.
local function GetSearchResultID(resultFrame, ...)
    local function ReturnIfNumber(value)
        if type(value) == "number" then
            return value
        end
    end

    local searchResultID = ReturnIfNumber(resultFrame.searchResultID)
    if searchResultID then
        return searchResultID
    end

    local resultID = ReturnIfNumber(resultFrame.resultID)
    if resultID then
        return resultID
    end

    if resultFrame.data then
        searchResultID = ReturnIfNumber(resultFrame.data.searchResultID)
        if searchResultID then
            return searchResultID
        end

        resultID = ReturnIfNumber(resultFrame.data.resultID)
        if resultID then
            return resultID
        end
    end

    if resultFrame.searchResultInfo then
        searchResultID = ReturnIfNumber(resultFrame.searchResultInfo.searchResultID)
        if searchResultID then
            return searchResultID
        end

        resultID = ReturnIfNumber(resultFrame.searchResultInfo.resultID)
        if resultID then
            return resultID
        end
    end

    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "number" then
            return value
        end

        if type(value) == "table" then
            if type(value.searchResultID) == "number" then
                return value.searchResultID
            end

            if type(value.resultID) == "number" then
                return value.resultID
            end

            if value.data and type(value.data.searchResultID) == "number" then
                return value.data.searchResultID
            end
        end
    end
end

-- Diese Funktion hängt die Flagge konkret an einen Bewerber-Row.
function LFG.ApplyFlagToApplicantMember(memberFrame, applicantID, memberIdx)
    if not memberFrame then
        return
    end

    local flagFrame = EnsureFlagFrame(memberFrame)
    memberFrame.BeavisApplicantID = applicantID
    memberFrame.BeavisMemberIdx = memberIdx

    if not LFG.IsFlagsEnabled() then
        flagFrame:Hide()
        return
    end

    if not applicantID or not memberIdx then
        flagFrame:Hide()
        return
    end

    local fullName = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
    local realmName = GetRealmNameFromFullName(fullName)
    local countryCode = LFG.GetCountryCodeForRealm(realmName)
    local nameRegion = GetApplicantNameRegion(memberFrame)

    if not countryCode or not nameRegion then
        flagFrame:Hide()
        return
    end

    AnchorFlagBehindName(flagFrame, nameRegion, 4, 0)
    RenderFlag(flagFrame, countryCode)
end

function LFG.ApplyFlagToFullName(parent, fullName, anchorRegion, offsetX, offsetY)
    if not parent then
        return
    end

    local flagFrame = EnsureFlagFrame(parent)

    if not LFG.IsFlagsEnabled() then
        flagFrame:Hide()
        return
    end

    local realmName = GetRealmNameFromFullName(fullName)
    local countryCode = LFG.GetCountryCodeForRealm(realmName)

    if not countryCode or not anchorRegion then
        flagFrame:Hide()
        return
    end

    flagFrame:ClearAllPoints()
    flagFrame:SetPoint("LEFT", anchorRegion, "RIGHT", offsetX or 6, offsetY or 0)
    RenderFlag(flagFrame, countryCode)
end

-- Auch die eigentliche Suchergebnis-Liste kann eine Flagge bekommen, weil Blizzard uns dort den leaderName mitliefert.
function LFG.ApplyFlagToSearchResult(resultFrame, ...)
    if not resultFrame then
        return
    end

    local flagFrame = EnsureFlagFrame(resultFrame)
    local searchResultID = GetSearchResultID(resultFrame, ...)
    resultFrame.BeavisSearchResultID = searchResultID

    if not LFG.IsFlagsEnabled() then
        flagFrame:Hide()
        return
    end

    if not searchResultID or not C_LFGList or not C_LFGList.GetSearchResultInfo then
        flagFrame:Hide()
        return
    end

    local searchResultInfo = C_LFGList.GetSearchResultInfo(searchResultID)
    if type(searchResultInfo) ~= "table" then
        flagFrame:Hide()
        return
    end

    -- leaderName kann inzwischen als Secret geliefert werden. Dann dürfen wir ihn nicht zerlegen.
    if IsSecretValue(searchResultInfo.leaderName) then
        flagFrame:Hide()
        return
    end

    local realmName = GetRealmNameFromFullName(searchResultInfo.leaderName)
    local countryCode = LFG.GetCountryCodeForRealm(realmName)
    local nameRegion = GetSearchResultNameRegion(resultFrame, searchResultInfo.leaderName)

    if not countryCode or not nameRegion then
        flagFrame:Hide()
        return
    end

    AnchorFlagBehindName(flagFrame, nameRegion, 4, 0)
    RenderFlag(flagFrame, countryCode)
end

-- Kleiner Tiefenlauf durch den Frame-Baum.
-- Den brauchen wir, um bereits sichtbare Zeilen später gezielt zu aktualisieren.
local function VisitFrameTree(frame, callback)
    if not frame then
        return
    end

    callback(frame)

    for _, child in ipairs({ frame:GetChildren() }) do
        VisitFrameTree(child, callback)
    end
end

-- Wenn sich die Applicant-Liste ändert, ziehen wir über alle sichtbaren Rows und aktualisieren nur unsere Extras.
local function RefreshVisibleApplicantFlags()
    local applicationViewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not applicationViewer then
        return
    end

    VisitFrameTree(applicationViewer, function(frame)
        if frame.BeavisCountryFlag and frame.BeavisApplicantID and frame.BeavisMemberIdx then
            LFG.ApplyFlagToApplicantMember(frame, frame.BeavisApplicantID, frame.BeavisMemberIdx)
        end
    end)
end

-- Dasselbe Prinzip für die Suchergebnis-Liste: nur sichtbare Zeilen anfassen, nichts neu aufbauen.
local function RefreshVisibleSearchResultFlags()
    local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
    if not searchPanel then
        return
    end

    VisitFrameTree(searchPanel, function(frame)
        if frame.BeavisCountryFlag and frame.BeavisSearchResultID then
            LFG.ApplyFlagToSearchResult(frame, frame.BeavisSearchResultID)
        end
    end)
end

-- Wir hooken bewusst die Blizzard-Update-Funktion statt selbst die ganze Liste nachzubauen.
local function TryInstallHooks()
    if not applicantHookInstalled and type(LFGListApplicationViewer_UpdateApplicantMember) == "function" then
        -- hooksecurefunc hängt unser Verhalten nur an Blizzard an und ersetzt
        -- keine Originalfunktion. Das ist für UI-Addons deutlich robuster.
        hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(memberFrame, applicantID, memberIdx)
            LFG.ApplyFlagToApplicantMember(memberFrame, applicantID, memberIdx)
        end)

        applicantHookInstalled = true
    end

    if not searchResultHookInstalled and type(LFGListSearchEntry_Update) == "function" then
        hooksecurefunc("LFGListSearchEntry_Update", function(resultFrame, ...)
            LFG.ApplyFlagToSearchResult(resultFrame, ...)
        end)

        searchResultHookInstalled = true
    end
end

function LFG.SetFlagsEnabled(value)
    LFG.GetLFGDB().flagsEnabled = value and true or false
    TryInstallHooks()
    RefreshVisibleApplicantFlags()
    RefreshVisibleSearchResultFlags()
    if LFG.RefreshEasyLFGOverlay then
        LFG.RefreshEasyLFGOverlay()
    end
end

local function HasActiveListing()
    if not C_LFGList then
        return false
    end

    if C_LFGList.HasActiveEntryInfo then
        return C_LFGList.HasActiveEntryInfo() == true
    end

    if C_LFGList.GetActiveEntryInfo then
        return type(C_LFGList.GetActiveEntryInfo()) == "table"
    end

    return false
end

local function IsPlayerListingLeader()
    local partyCategory = LE_PARTY_CATEGORY_HOME

    if IsInRaid and IsInRaid(partyCategory) then
        if UnitIsGroupLeader then
            return UnitIsGroupLeader("player", partyCategory) == true
        end

        local isRaidLeader = rawget(_G, "IsRaidLeader")
        if type(isRaidLeader) == "function" then
            return isRaidLeader() == true
        end

        return false
    end

    if IsInGroup and IsInGroup(partyCategory) then
        if UnitIsGroupLeader then
            return UnitIsGroupLeader("player", partyCategory) == true
        end

        local isPartyLeader = rawget(_G, "IsPartyLeader")
        if type(isPartyLeader) == "function" then
            return isPartyLeader() == true
        end

        return false
    end

    -- Solo-Listungen dürfen weiterhin sichtbar sein.
    return true
end

local function OpenActiveEasyLFGListingEditor()
    if not HasActiveListing() or not IsPlayerListingLeader() then
        return
    end

    if type(PVEFrame_ShowFrame) == "function" then
        SafeSecureCall(PVEFrame_ShowFrame, "GroupFinderFrame", rawget(_G, "LFGListPVEStub"))
    elseif type(PVEFrame_ToggleFrame) == "function" and (not PVEFrame or not PVEFrame:IsShown()) then
        SafeSecureCall(PVEFrame_ToggleFrame)
    end

    if C_LFGList and type(C_LFGList.EditEntry) == "function" then
        SafeSecureCall(C_LFGList.EditEntry)
    end

    local applicationViewer = LFGListFrame and LFGListFrame.ApplicationViewer or nil
    if applicationViewer and applicationViewer.EditButton and applicationViewer.EditButton.Click then
        if applicationViewer.EditButton.IsEnabled == nil or applicationViewer.EditButton:IsEnabled() then
            SafeSecureCallMethod(applicationViewer.EditButton, "Click")
            return
        end
    end

    local entryCreation = LFGListFrame and LFGListFrame.EntryCreation or nil
    if not entryCreation then
        return
    end

    if type(C_LFGList.CopyActiveEntryInfoToCreationFields) == "function" then
        SafeSecureCall(C_LFGList.CopyActiveEntryInfoToCreationFields)
    end

    if type(LFGListFrame_SetActivePanel) == "function" and LFGListFrame then
        SafeSecureCall(LFGListFrame_SetActivePanel, LFGListFrame, entryCreation)
    elseif entryCreation.Show then
        SafeSecureCallMethod(entryCreation, "Show")
    end

    if type(LFGListEntryCreation_Update) == "function" then
        SafeSecureCall(LFGListEntryCreation_Update, entryCreation)
    end
end

local function RemoveActiveEasyLFGListing()
    if not C_LFGList or type(C_LFGList.RemoveListing) ~= "function" then
        return
    end

    if not HasActiveListing() or not IsPlayerListingLeader() then
        return
    end

    C_LFGList.RemoveListing()
    EasyLFGSuppressed = false

    if LFG.RefreshEasyLFGOverlay then
        LFG.RefreshEasyLFGOverlay()
    end
end

local function HideEasyLFGRioTooltip()
    local raiderIOProfileTooltip = rawget(_G, "RaiderIO_ProfileTooltip")
    if raiderIOProfileTooltip and raiderIOProfileTooltip.Hide then
        raiderIOProfileTooltip:Hide()
    end

    if EasyLFGRioTooltip and EasyLFGRioTooltip.Hide then
        EasyLFGRioTooltip:Hide()
    end

    if EasyLFGRioPanel and EasyLFGRioPanel.Hide then
        EasyLFGRioPanel:Hide()
    end
end

local function PopulateEasyLFGRioFallbackTooltip(tooltip, fullName, displayName, profile)
    if not tooltip then
        return
    end

    local titleText = displayName
    if not IsUsablePlainString(titleText) then
        titleText = GetDisplayNameFromFullName(fullName)
    end
    if not IsUsablePlainString(titleText) then
        titleText = fullName
    end

    local realmName = profile and profile.realm or GetRealmNameFromFullName(fullName)
    local keystoneProfile = profile and profile.mythicKeystoneProfile or nil
    local currentScore = keystoneProfile and keystoneProfile.mplusCurrent and tonumber(keystoneProfile.mplusCurrent.score) or 0
    local bestDungeon = keystoneProfile and keystoneProfile.maxDungeon or nil
    local bestLevel = keystoneProfile and tonumber(keystoneProfile.maxDungeonLevel) or 0
    local bestRunText = nil

    if bestDungeon and bestLevel and bestLevel > 0 then
        local bestDungeonName = bestDungeon.shortNameLocale or bestDungeon.shortName or bestDungeon.name or bestDungeon.nameLocale
        if IsUsablePlainString(bestDungeonName) then
            bestRunText = string.format("+%d %s", bestLevel, bestDungeonName)
        else
            bestRunText = string.format("+%d", bestLevel)
        end
    end

    tooltip:ClearLines()

    if IsUsablePlainString(realmName) and realmName ~= titleText then
        tooltip:AddLine(string.format("%s (%s)", titleText or UNKNOWN or "Unknown", realmName), 1, 1, 1)
    else
        tooltip:AddLine(titleText or UNKNOWN or "Unknown", 1, 1, 1)
    end

    tooltip:AddLine(" ")

    if currentScore and currentScore > 0 then
        local scoreColorRed, scoreColorGreen, scoreColorBlue = 1, 1, 1
        local api = GetRaiderIOAPI()
        if api and type(api.GetScoreColor) == "function" then
            local red, green, blue = api.GetScoreColor(currentScore)
            if type(red) == "number" and type(green) == "number" and type(blue) == "number" then
                scoreColorRed, scoreColorGreen, scoreColorBlue = red, green, blue
            end
        end

        tooltip:AddDoubleLine(L("EASY_LFG_OVERLAY_RIO_SCORE"), tostring(math.floor(currentScore + 0.5)), 1, 0.85, 0, scoreColorRed, scoreColorGreen, scoreColorBlue)
    end

    if IsUsablePlainString(bestRunText) then
        tooltip:AddDoubleLine(L("EASY_LFG_OVERLAY_RIO_BEST_RUN"), bestRunText, 1, 1, 1, 1, 1, 1)
    end

    if (not currentScore or currentScore <= 0) and not IsUsablePlainString(bestRunText) then
        tooltip:AddLine(L("EASY_LFG_OVERLAY_RIO_NO_PROFILE"), 0.88, 0.88, 0.88, true)
    end

    tooltip:AddLine(L("EASY_LFG_OVERLAY_RIO_RENDER_HINT"), 0.70, 0.70, 0.72, true)
    tooltip:Show()
end

local function EnsureEasyLFGRioTooltip()
    if EasyLFGRioAnchor then
        return EasyLFGRioAnchor
    end

    if not EasyLFGOverlay then
        return nil
    end

    EasyLFGRioAnchor = CreateFrame("Frame", nil, EasyLFGOverlay)
    EasyLFGRioAnchor:SetSize(1, 1)
    EasyLFGRioAnchor:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPRIGHT", 14, -10)

    return EasyLFGRioAnchor
end

local function GetEasyLFGScaledFontSize(baseSize)
    local db = LFG.GetLFGDB and LFG.GetLFGDB() or nil
    local textScale = db and db.easyLFGTextScale or DEFAULT_EASY_LFG_TEXT_SCALE
    return math.max(1, math.floor((baseSize * textScale) + 0.5))
end

local function EnsureEasyLFGRioPanel()
    if EasyLFGRioPanel then
        return EasyLFGRioPanel
    end

    local panel = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    panel:SetFrameStrata("TOOLTIP")
    panel:SetClampedToScreen(true)
    panel:SetSize(EASY_LFG_RIO_PANEL_WIDTH, EASY_LFG_RIO_PANEL_MIN_HEIGHT)
    panel:Hide()

    panel.Background = panel:CreateTexture(nil, "BACKGROUND")
    panel.Background:SetAllPoints()
    panel.Background:SetColorTexture(0.02, 0.02, 0.03, DEFAULT_EASY_LFG_ALPHA)

    panel.TopLine = panel:CreateTexture(nil, "ARTWORK")
    panel.TopLine:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    panel.TopLine:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -8)
    panel.TopLine:SetHeight(1)
    panel.TopLine:SetColorTexture(0.88, 0.72, 0.46, 0.70)

    panel.Accent = panel:CreateTexture(nil, "BACKGROUND")
    panel.Accent:SetPoint("TOPLEFT", panel, "TOPLEFT", 9, -10)
    panel.Accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 9, 10)
    panel.Accent:SetWidth(2)
    panel.Accent:SetColorTexture(0.88, 0.72, 0.46, 0.18)

    panel.Title = panel:CreateFontString(nil, "OVERLAY")
    panel.Title:SetPoint("TOPLEFT", panel, "TOPLEFT", EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, -EASY_LFG_RIO_PANEL_TOP_PADDING)
    panel.Title:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, -EASY_LFG_RIO_PANEL_TOP_PADDING)
    panel.Title:SetJustifyH("LEFT")
    panel.Title:SetJustifyV("TOP")
    panel.Title:SetWordWrap(true)
    panel.Title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    panel.Title:SetTextColor(1, 0.88, 0.62, 1)

    panel.Lines = {}
    EasyLFGRioPanel = panel
    return panel
end

local function AcquireEasyLFGRioPanelLine(panel, index)
    local line = panel.Lines[index]
    if line then
        return line
    end

    line = panel:CreateFontString(nil, "OVERLAY")
    line:SetPoint("LEFT", panel, "LEFT", EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, 0)
    line:SetPoint("RIGHT", panel, "RIGHT", -EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, 0)
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetWordWrap(true)
    panel.Lines[index] = line
    return line
end

local function AddEasyLFGRioPanelLine(lines, text, red, green, blue, fontSize, flags)
    if not IsUsablePlainString(text) then
        return
    end

    lines[#lines + 1] = {
        text = text,
        red = red or 1,
        green = green or 1,
        blue = blue or 1,
        fontSize = fontSize or 10,
        flags = flags or "",
    }
end

local function BuildEasyLFGRioPanelData(fullName, displayName, profile)
    local titleText = displayName
    if not IsUsablePlainString(titleText) then
        titleText = GetDisplayNameFromFullName(fullName)
    end
    if not IsUsablePlainString(titleText) then
        titleText = fullName
    end

    local realmName = profile and profile.realm or GetRealmNameFromFullName(fullName)
    if IsUsablePlainString(realmName) and realmName ~= titleText then
        titleText = string.format("%s (%s)", titleText or UNKNOWN or "Unknown", realmName)
    end

    local lines = {}
    local api = GetRaiderIOAPI()
    local keystoneProfile = profile and profile.mythicKeystoneProfile or nil
    local currentScore = keystoneProfile and keystoneProfile.mplusCurrent and tonumber(keystoneProfile.mplusCurrent.score) or 0
    local bestDungeon = keystoneProfile and keystoneProfile.maxDungeon or nil
    local bestLevel = keystoneProfile and tonumber(keystoneProfile.maxDungeonLevel) or 0
    local bestRunText = nil

    if bestDungeon and bestLevel and bestLevel > 0 then
        local bestDungeonName = bestDungeon.shortNameLocale or bestDungeon.shortName or bestDungeon.name or bestDungeon.nameLocale
        if IsUsablePlainString(bestDungeonName) then
            bestRunText = string.format("+%d %s", bestLevel, bestDungeonName)
        else
            bestRunText = string.format("+%d", bestLevel)
        end
    end

    if currentScore and currentScore > 0 then
        local scoreColorRed, scoreColorGreen, scoreColorBlue = 1, 1, 1
        if api and type(api.GetScoreColor) == "function" then
            local red, green, blue = api.GetScoreColor(currentScore)
            if type(red) == "number" and type(green) == "number" and type(blue) == "number" then
                scoreColorRed, scoreColorGreen, scoreColorBlue = red, green, blue
            end
        end

        AddEasyLFGRioPanelLine(lines, string.format("%s: %d", L("EASY_LFG_OVERLAY_RIO_SCORE"), math.floor(currentScore + 0.5)), scoreColorRed, scoreColorGreen, scoreColorBlue, 11, "OUTLINE")
    end

    if IsUsablePlainString(bestRunText) then
        AddEasyLFGRioPanelLine(lines, string.format("%s: %s", L("EASY_LFG_OVERLAY_RIO_BEST_RUN"), bestRunText), 0.95, 0.95, 0.95, 10, "")
    end

    local shownDungeonHeader = false
    if keystoneProfile and type(keystoneProfile.sortedDungeons) == "table" then
        local shownDungeons = 0
        for _, sortedDungeon in ipairs(keystoneProfile.sortedDungeons) do
            local level = tonumber(sortedDungeon and sortedDungeon.level) or 0
            if level > 0 then
                if not shownDungeonHeader then
                    AddEasyLFGRioPanelLine(lines, " ", 1, 1, 1, 4, "")
                    AddEasyLFGRioPanelLine(lines, L("EASY_LFG_OVERLAY_RIO_TOP_DUNGEONS"), 1, 0.85, 0, 11, "OUTLINE")
                    shownDungeonHeader = true
                end

                local dungeonInfo = sortedDungeon.dungeon or nil
                local dungeonName = dungeonInfo and (dungeonInfo.shortNameLocale or dungeonInfo.shortName or dungeonInfo.nameLocale or dungeonInfo.name) or nil
                local chestText = ""
                local chests = tonumber(sortedDungeon.chests) or 0
                if chests > 0 then
                    chestText = string.rep("+", chests)
                end

                AddEasyLFGRioPanelLine(
                    lines,
                    string.format("%s %s%d", dungeonName or UNKNOWN or "Unknown", chestText, level),
                    0.88,
                    0.88,
                    0.90,
                    10,
                    ""
                )
                shownDungeons = shownDungeons + 1
                if shownDungeons >= EASY_LFG_RIO_PANEL_MAX_DUNGEONS then
                    break
                end
            end
        end
    end

    local shownRaidHeader = false
    local raidProfile = profile and profile.raidProfile or nil
    if raidProfile and type(raidProfile.raidProgress) == "table" then
        local shownRaids = 0
        for _, raidGroup in ipairs(raidProfile.raidProgress) do
            local raidInfo = raidGroup and raidGroup.raid or nil
            local progressGroups = raidGroup and raidGroup.progress or nil
            if raidInfo and type(progressGroups) == "table" then
                local progressParts = {}
                for _, progress in ipairs(progressGroups) do
                    if progress and progress.obsolete ~= true then
                        local difficultyLabel = EASY_LFG_RIO_DIFFICULTY_LABELS[tonumber(progress.difficulty) or 0] or tostring(progress.difficulty or "?")
                        local kills = tonumber(progress.kills) or 0
                        progressParts[#progressParts + 1] = string.format("%s %d/%d", difficultyLabel, kills, tonumber(raidInfo.bossCount) or 0)
                    end
                end

                if #progressParts > 0 then
                    if not shownRaidHeader then
                        AddEasyLFGRioPanelLine(lines, " ", 1, 1, 1, 4, "")
                        AddEasyLFGRioPanelLine(lines, L("EASY_LFG_OVERLAY_RIO_RAID_PROGRESS"), 1, 0.85, 0, 11, "OUTLINE")
                        shownRaidHeader = true
                    end

                    local raidName = raidInfo.shortName or raidInfo.shortNameLocale or raidInfo.name or raidInfo.nameLocale or UNKNOWN or "Unknown"
                    AddEasyLFGRioPanelLine(lines, string.format("%s: %s", raidName, table.concat(progressParts, "  ")), 0.88, 0.88, 0.90, 10, "")
                    shownRaids = shownRaids + 1
                    if shownRaids >= EASY_LFG_RIO_PANEL_MAX_RAIDS then
                        break
                    end
                end
            end
        end
    end

    if #lines == 0 then
        AddEasyLFGRioPanelLine(lines, L("EASY_LFG_OVERLAY_RIO_NO_PROFILE"), 0.88, 0.88, 0.88, 10, "")
    end

    return titleText or UNKNOWN or "Unknown", lines
end

local function RenderEasyLFGRioPanel(panel, fullName, displayName, profile)
    local titleText, lines = BuildEasyLFGRioPanelData(fullName, displayName, profile)
    local db = LFG.GetLFGDB()
    local titleFontSize = GetEasyLFGScaledFontSize(11)

    panel:SetWidth(EASY_LFG_RIO_PANEL_WIDTH)
    if panel.Background then
        panel.Background:SetColorTexture(0.02, 0.02, 0.03, db.easyLFGAlpha or DEFAULT_EASY_LFG_ALPHA)
    end

    panel.Title:SetFont("Fonts\\FRIZQT__.TTF", titleFontSize, "OUTLINE")
    panel.Title:SetText(titleText)
    local titleHeight = math.max(panel.Title:GetStringHeight() or 0, titleFontSize)

    local cursor = -(EASY_LFG_RIO_PANEL_TOP_PADDING + titleHeight + 10)
    for index, entry in ipairs(lines) do
        local line = AcquireEasyLFGRioPanelLine(panel, index)
        local fontSize = GetEasyLFGScaledFontSize(entry.fontSize or 10)
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, cursor)
        line:SetPoint("RIGHT", panel, "RIGHT", -EASY_LFG_RIO_PANEL_HORIZONTAL_PADDING, 0)
        line:SetFont("Fonts\\FRIZQT__.TTF", fontSize, entry.flags or "")
        line:SetTextColor(entry.red or 1, entry.green or 1, entry.blue or 1, 1)
        line:SetText(entry.text or "")
        line:Show()
        local lineHeight = math.max(line:GetStringHeight() or 0, fontSize)
        cursor = cursor - lineHeight - EASY_LFG_RIO_PANEL_LINE_SPACING
    end

    for index = #lines + 1, #panel.Lines do
        panel.Lines[index]:Hide()
    end

    local panelHeight = math.max(EASY_LFG_RIO_PANEL_MIN_HEIGHT, -cursor + EASY_LFG_RIO_PANEL_BOTTOM_PADDING)
    panel:SetSize(EASY_LFG_RIO_PANEL_WIDTH, panelHeight)
    panel:Show()
end

local function PositionEasyLFGRioAnchor(anchor, tooltip)
    if not anchor or not EasyLFGOverlay then
        return "right"
    end

    local uiWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
    local overlayLeft = EasyLFGOverlay.GetLeft and EasyLFGOverlay:GetLeft() or nil
    local overlayRight = EasyLFGOverlay.GetRight and EasyLFGOverlay:GetRight() or nil
    local leftSpace = tonumber(overlayLeft) or 0
    local rightSpace = 0

    if uiWidth > 0 and overlayRight then
        rightSpace = math.max(0, uiWidth - overlayRight)
    end

    local openLeft = leftSpace > rightSpace

    anchor:ClearAllPoints()
    if openLeft then
        anchor:SetPoint("TOPRIGHT", EasyLFGOverlay, "TOPLEFT", -10, -8)
    else
        anchor:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPRIGHT", 10, -8)
    end

    if tooltip then
        tooltip:ClearAllPoints()
        if openLeft then
            tooltip:SetPoint("TOPRIGHT", anchor, "TOPLEFT", 0, 0)
        else
            tooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
        end
    end

    return openLeft and "left" or "right"
end

local function UpdateEasyLFGRioSelectionVisuals()
    local showSelection = IsEasyLFGRioExpanded() and IsUsablePlainString(EasyLFGRioSelectedFullName)

    for _, row in ipairs(EasyLFGRows) do
        if row.Selection then
            row.Selection:SetShown(showSelection and row:IsShown() and row.FullName == EasyLFGRioSelectedFullName)
        end
    end
end

local function RefreshEasyLFGRioTooltip()
    if not EasyLFGOverlay or not EasyLFGOverlay.IsShown or not EasyLFGOverlay:IsShown() then
        HideEasyLFGRioTooltip()
        return
    end

    if not IsEasyLFGRioExpanded() or not IsRaiderIOAvailable() or not IsUsablePlainString(EasyLFGRioSelectedFullName) then
        HideEasyLFGRioTooltip()
        return
    end

    local anchor = EnsureEasyLFGRioTooltip()
    local panel = EnsureEasyLFGRioPanel()
    local api = GetRaiderIOAPI()
    if not anchor or not panel or not api then
        HideEasyLFGRioTooltip()
        return
    end

    HideEasyLFGRioTooltip()
    PositionEasyLFGRioAnchor(anchor, panel)
    panel:SetFrameStrata("TOOLTIP")
    panel:SetFrameLevel(math.max(100, (EasyLFGOverlay.GetFrameLevel and EasyLFGOverlay:GetFrameLevel() or 0) + 20))
    panel:SetScale(EasyLFGOverlay and EasyLFGOverlay.GetScale and EasyLFGOverlay:GetScale() or 1)

    local profile = nil
    if type(api.GetProfile) == "function" then
        profile = api.GetProfile(EasyLFGRioSelectedFullName)
        if not profile then
            local characterName = GetDisplayNameFromFullName(EasyLFGRioSelectedFullName)
            local characterRealm = GetRealmNameFromFullName(EasyLFGRioSelectedFullName)
            if IsUsablePlainString(characterName) then
                profile = api.GetProfile(characterName, characterRealm)
            end
        end
    end

    if not profile and not IsUsablePlainString(EasyLFGRioSelectedFullName) then
        HideEasyLFGRioTooltip()
        return
    end

    RenderEasyLFGRioPanel(panel, EasyLFGRioSelectedFullName, EasyLFGRioSelectedDisplayName, profile)
end

local function SetEasyLFGRioSelection(fullName, displayName)
    if not IsUsablePlainString(fullName) then
        return
    end

    EasyLFGRioSelectedFullName = fullName
    EasyLFGRioSelectedDisplayName = displayName
    UpdateEasyLFGRioSelectionVisuals()
    RefreshEasyLFGRioTooltip()
end

local function GetEasyLFGClassColor(classFile)
    if RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile] then
        local color = RAID_CLASS_COLORS[classFile]
        return color.r, color.g, color.b
    end

    return 1, 1, 1
end

local function GetEasyLFGShortName(fullName)
    local shortName = GetDisplayNameFromFullName(fullName)
    if IsUsablePlainString(shortName) then
        return shortName
    end

    return UNKNOWN or "Unknown"
end

local function GetEasyLFGTextureMarkup(texturePath, width, height, left, right, top, bottom)
    if type(texturePath) ~= "number" and not IsUsablePlainString(texturePath) then
        return nil
    end

    width = width or 18
    height = height or width

    if left and right and top and bottom then
        return string.format("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t", texturePath, width, height, left, right, top, bottom)
    end

    return string.format("|T%s:%d:%d:0:0|t", texturePath, width, height)
end

local function GetEasyLFGRoleIconMarkup(assignedRole)
    local inlineTankIcon = _G and _G["INLINE_TANK_ICON"] or nil
    local inlineHealerIcon = _G and _G["INLINE_HEALER_ICON"] or nil
    local inlineDamagerIcon = _G and _G["INLINE_DAMAGER_ICON"] or nil

    if assignedRole == "TANK" then
        if inlineTankIcon then
            return inlineTankIcon
        end
        return GetEasyLFGTextureMarkup("Interface\\LFGFrame\\UI-LFG-ICON-ROLES", 18, 18, 0, 19, 22, 41)
    end

    if assignedRole == "HEALER" then
        if inlineHealerIcon then
            return inlineHealerIcon
        end
        return GetEasyLFGTextureMarkup("Interface\\LFGFrame\\UI-LFG-ICON-ROLES", 18, 18, 20, 39, 1, 20)
    end

    if assignedRole == "DAMAGER" then
        if inlineDamagerIcon then
            return inlineDamagerIcon
        end
        return GetEasyLFGTextureMarkup("Interface\\LFGFrame\\UI-LFG-ICON-ROLES", 18, 18, 20, 39, 22, 41)
    end

    return nil
end

local function GetEasyLFGSpecIconMarkup(specID, classFile, assignedRole)
    if type(specID) == "number" and specID > 0 and GetSpecializationInfoByID then
        local _, _, _, iconTexture = GetSpecializationInfoByID(specID)
        if type(iconTexture) == "number" or IsUsablePlainString(iconTexture) then
            return GetEasyLFGTextureMarkup(iconTexture, 18, 18)
        end
    end

    if IsUsablePlainString(classFile) and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
        local coords = CLASS_ICON_TCOORDS[classFile]
        if coords then
            return GetEasyLFGTextureMarkup(
                "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes",
                18,
                18,
                math.floor((coords[1] or 0) * 256 + 0.5),
                math.floor((coords[2] or 1) * 256 + 0.5),
                math.floor((coords[3] or 0) * 256 + 0.5),
                math.floor((coords[4] or 1) * 256 + 0.5)
            )
        end
    end

    return GetEasyLFGRoleIconMarkup(assignedRole)
end

local function GetEasyLFGStatusText(status)
    if status == "applied" then
        return L("EASY_LFG_STATUS_APPLIED")
    end

    if status == "invited" then
        return L("EASY_LFG_STATUS_INVITED")
    end

    if status == "inviteaccepted" then
        return L("EASY_LFG_STATUS_INVITE_ACCEPTED")
    end

    if status == "declined" or status == "declined_full" or status == "declined_delisted" then
        return L("EASY_LFG_STATUS_DECLINED")
    end

    if status == "invitedeclined" then
        return L("EASY_LFG_STATUS_INVITE_DECLINED")
    end

    if status == "failed" or status == "cancelled" or status == "timedout" then
        return L("EASY_LFG_STATUS_INACTIVE")
    end

    return tostring(status or "")
end

local function IsEasyLFGVisibleStatus(status)
    if status == "failed" or status == "cancelled" or status == "timedout" then
        return false
    end

    if status == "declined" or status == "declined_full" or status == "declined_delisted" or status == "invitedeclined" then
        return false
    end

    return true
end

local function CanInviteApplicantStatus(status)
    return status == "applied"
end

local function ResetEasyLFGApplicantState()
    EasyLFGApplicantStates = {}
    EasyLFGExpandedApplicants = {}
    EasyLFGNextApplicantOrder = 1
    EasyLFGRemovalRefreshAt = nil
    EasyLFGRemovalRefreshSerial = EasyLFGRemovalRefreshSerial + 1
end

local function ScheduleEasyLFGRefreshAt(refreshAt)
    if type(refreshAt) ~= "number" then
        return
    end

    if EasyLFGRemovalRefreshAt and EasyLFGRemovalRefreshAt <= refreshAt then
        return
    end

    EasyLFGRemovalRefreshAt = refreshAt
    EasyLFGRemovalRefreshSerial = EasyLFGRemovalRefreshSerial + 1
    local refreshSerial = EasyLFGRemovalRefreshSerial
    local now = type(GetTime) == "function" and GetTime() or 0
    local delay = math.max(0.05, refreshAt - now)

    if not C_Timer or type(C_Timer.After) ~= "function" then
        return
    end

    C_Timer.After(delay, function()
        if refreshSerial ~= EasyLFGRemovalRefreshSerial then
            return
        end

        EasyLFGRemovalRefreshAt = nil

        if LFG.IsEasyLFGEnabled and LFG.IsEasyLFGEnabled() and LFG.RefreshEasyLFGOverlay then
            LFG.RefreshEasyLFGOverlay()
        end
    end)
end

local function IsEasyLFGOverlayHovered()
    if not EasyLFGOverlay then
        return false
    end

    local mouseIsOver = rawget(_G, "MouseIsOver")
    if type(mouseIsOver) == "function" then
        return mouseIsOver(EasyLFGOverlay) == true
    end

    if EasyLFGOverlay.IsMouseOver then
        return EasyLFGOverlay:IsMouseOver() == true
    end

    return false
end

local function GetEasyLFGApplicantState(applicantID)
    if not applicantID then
        return nil
    end

    local applicantState = EasyLFGApplicantStates[applicantID]
    if applicantState then
        return applicantState
    end

    applicantState = {
        order = EasyLFGNextApplicantOrder,
        removedAt = nil,
        snapshot = nil,
    }
    EasyLFGApplicantStates[applicantID] = applicantState
    EasyLFGNextApplicantOrder = EasyLFGNextApplicantOrder + 1
    return applicantState
end

local function CreateEasyLFGInactiveApplicantEntry(applicantID, applicantState)
    local snapshot = applicantState and applicantState.snapshot or nil
    local leaderSnapshot = snapshot and snapshot.members and snapshot.members[1] or nil
    if type(leaderSnapshot) ~= "table" then
        return nil
    end

    return {
        applicantID = applicantID,
        applicationStatus = "cancelled",
        memberCount = 0,
        isInactivePlaceholder = true,
        slotOrder = applicantState.order or 0,
        members = {
            {
                applicantID = applicantID,
                memberIndex = leaderSnapshot.memberIndex,
                fullName = leaderSnapshot.fullName,
                displayName = leaderSnapshot.displayName,
                classFile = leaderSnapshot.classFile,
                localizedClass = leaderSnapshot.localizedClass,
                itemLevel = leaderSnapshot.itemLevel,
                dungeonScore = leaderSnapshot.dungeonScore,
                assignedRole = leaderSnapshot.assignedRole,
                specID = leaderSnapshot.specID,
                canTank = leaderSnapshot.canTank,
                canHealer = leaderSnapshot.canHealer,
                canDamage = leaderSnapshot.canDamage,
                applicationStatus = "cancelled",
                isPrimary = true,
                memberCount = 0,
                isLeaver = true,
                isInactivePlaceholder = true,
            },
        },
    }
end

local function SaveEasyLFGOverlayGeometry()
    if not EasyLFGOverlay then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = EasyLFGOverlay:GetPoint(1)
    local db = LFG.GetLFGDB()
    db.easyLFGPoint = point or DEFAULT_EASY_LFG_POINT
    db.easyLFGRelativePoint = relativePoint or DEFAULT_EASY_LFG_RELATIVE_POINT
    db.easyLFGOffsetX = math.floor((offsetX or DEFAULT_EASY_LFG_OFFSET_X) + 0.5)
    db.easyLFGOffsetY = math.floor((offsetY or DEFAULT_EASY_LFG_OFFSET_Y) + 0.5)
end

local function ApplyEasyLFGOverlayGeometry()
    if not EasyLFGOverlay then
        return
    end

    local db = LFG.GetLFGDB()
    EasyLFGOverlay:ClearAllPoints()
    EasyLFGOverlay:SetPoint(db.easyLFGPoint, UIParent, db.easyLFGRelativePoint, db.easyLFGOffsetX, db.easyLFGOffsetY)
end

local function ApplyEasyLFGOverlayStyle()
    if not EasyLFGOverlay then
        return
    end

    local db = LFG.GetLFGDB()
    EasyLFGOverlay:SetScale(db.easyLFGScale)
    EasyLFGOverlay:SetMovable(db.easyLFGLocked ~= true)

    if EasyLFGOverlay.Background then
        EasyLFGOverlay.Background:SetColorTexture(0.02, 0.02, 0.03, db.easyLFGAlpha)
    end
end

local function ApplyEasyLFGOverlayTextScale()
    if not EasyLFGOverlay then
        return
    end

    local db = LFG.GetLFGDB()
    local textScale = db.easyLFGTextScale or DEFAULT_EASY_LFG_TEXT_SCALE

    local function ApplyScaledFont(fontString, baseSize, flags)
        if not fontString or not fontString.SetFont then
            return
        end

        fontString:SetFont("Fonts\\FRIZQT__.TTF", math.max(1, math.floor((baseSize * textScale) + 0.5)), flags or "")
    end

    ApplyScaledFont(EasyLFGOverlay.Title, 11, "OUTLINE")
    ApplyScaledFont(EasyLFGOverlay.Summary, 9, "")
    ApplyScaledFont(EasyLFGOverlay.EmptyText, 10, "")
    ApplyScaledFont(EasyLFGOverlay.Footer, 10, "")

    if EasyLFGOverlay.CloseButton and EasyLFGOverlay.CloseButton.Label then
        ApplyScaledFont(EasyLFGOverlay.CloseButton.Label, 9, "OUTLINE")
    end

    if EasyLFGOverlay.PinButton and EasyLFGOverlay.PinButton.Label then
        ApplyScaledFont(EasyLFGOverlay.PinButton.Label, 9, "OUTLINE")
    end

    if EasyLFGOverlay.EditButton and EasyLFGOverlay.EditButton.Label then
        ApplyScaledFont(EasyLFGOverlay.EditButton.Label, 9, "OUTLINE")
    end

    if EasyLFGOverlay.DelistButton and EasyLFGOverlay.DelistButton.Label then
        ApplyScaledFont(EasyLFGOverlay.DelistButton.Label, 9, "OUTLINE")
    end

    if EasyLFGOverlay.RioButton and EasyLFGOverlay.RioButton.Label then
        ApplyScaledFont(EasyLFGOverlay.RioButton.Label, 9, "OUTLINE")
    end

    for _, row in ipairs(EasyLFGRows) do
        ApplyScaledFont(row.ToggleButton and row.ToggleButton.Label, 10, "OUTLINE")
        ApplyScaledFont(row.Name, 10, "OUTLINE")
        ApplyScaledFont(row.Meta, 9, "")
        ApplyScaledFont(row.Badge, 9, "OUTLINE")

        local declineButtonText = row.DeclineButton and row.DeclineButton.GetFontString and row.DeclineButton:GetFontString() or nil
        if declineButtonText then
            ApplyScaledFont(declineButtonText, 9, "OUTLINE")
        end

        local inviteButtonText = row.InviteButton and row.InviteButton.GetFontString and row.InviteButton:GetFontString() or nil
        if inviteButtonText then
            ApplyScaledFont(inviteButtonText, 9, "OUTLINE")
        end
    end
end

local function GetEasyLFGApplicants()
    local applicantsByGroup = {}
    local applicantCount = 0
    local memberCount = 0
    local visibleApplicantIDs = {}
    local now = type(GetTime) == "function" and GetTime() or 0
    local nextScheduledRefreshAt = nil

    if not C_LFGList or not C_LFGList.GetApplicants or not C_LFGList.GetApplicantInfo or not C_LFGList.GetApplicantMemberInfo then
        return applicantsByGroup, applicantCount, memberCount
    end

    local applicants = C_LFGList.GetApplicants() or {}

    -- Blizzard liefert hier inzwischen Secret-Werte mit. Wir behalten deshalb
    -- keine Applicant-Tabellen, sondern nur die Felder, die das Overlay braucht.
    for _, applicantID in ipairs(applicants) do
        local applicantData = C_LFGList.GetApplicantInfo(applicantID)
        if type(applicantData) == "table" then
            local applicantState = GetEasyLFGApplicantState(applicantID)
            local applicationStatus = SanitizeApplicantStatus(applicantData.applicationStatus)

            if not IsEasyLFGVisibleStatus(applicationStatus) then
                EasyLFGExpandedApplicants[applicantID] = nil
                if applicantState and applicantState.snapshot then
                    applicantState.removedAt = applicantState.removedAt or now
                else
                    EasyLFGApplicantStates[applicantID] = nil
                end
            else
                local numMembers = math.max(0, SanitizeInteger(applicantData.numMembers) or 0)
                local applicantEntry = {
                    applicantID = applicantID,
                    applicationStatus = applicationStatus,
                    memberCount = numMembers,
                    members = {},
                    slotOrder = (applicantState and applicantState.order) or 0,
                }

                applicantState.removedAt = nil
                visibleApplicantIDs[applicantID] = true

                for memberIndex = 1, numMembers do
                    local fullName, classFile, localizedClass, level, itemLevel, honorLevel, canTank, canHealer, canDamage, assignedRole, relationship, dungeonScore, pvpItemLevel, factionGroup, raceID, specID, isLeaver = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

                    memberCount = memberCount + 1
                    applicantEntry.members[#applicantEntry.members + 1] = {
                        applicantID = applicantID,
                        memberIndex = SanitizeInteger(memberIndex) or memberIndex,
                        fullName = fullName,
                        displayName = GetEasyLFGShortName(fullName),
                        classFile = classFile,
                        localizedClass = localizedClass,
                        itemLevel = SanitizeDecimal(itemLevel, 1),
                        dungeonScore = SanitizeDecimal(dungeonScore, 0),
                        assignedRole = assignedRole,
                        specID = SanitizeInteger(specID),
                        canTank = canTank,
                        canHealer = canHealer,
                        canDamage = canDamage,
                        applicationStatus = applicationStatus,
                        isPrimary = memberIndex == 1,
                        memberCount = numMembers,
                        isLeaver = isLeaver == true,
                    }
                end

                applicantState.snapshot = applicantEntry
                applicantCount = applicantCount + 1
                applicantsByGroup[#applicantsByGroup + 1] = applicantEntry
            end
        end
    end

    for applicantID, applicantState in pairs(EasyLFGApplicantStates) do
        if not visibleApplicantIDs[applicantID] then
            local inactiveApplicantEntry = CreateEasyLFGInactiveApplicantEntry(applicantID, applicantState)

            if not inactiveApplicantEntry then
                EasyLFGApplicantStates[applicantID] = nil
                EasyLFGExpandedApplicants[applicantID] = nil
            else
                local removedAt = applicantState.removedAt or now
                local expiresAt = removedAt + EASY_LFG_REMOVAL_GRACE_SECONDS

                applicantState.removedAt = removedAt

                if now < expiresAt then
                    applicantsByGroup[#applicantsByGroup + 1] = inactiveApplicantEntry
                    if nextScheduledRefreshAt == nil or expiresAt < nextScheduledRefreshAt then
                        nextScheduledRefreshAt = expiresAt
                    end
                elseif IsEasyLFGOverlayHovered() then
                    applicantsByGroup[#applicantsByGroup + 1] = inactiveApplicantEntry
                    local recheckAt = now + EASY_LFG_HOVER_REMOVAL_RECHECK_SECONDS
                    if nextScheduledRefreshAt == nil or recheckAt < nextScheduledRefreshAt then
                        nextScheduledRefreshAt = recheckAt
                    end
                else
                    EasyLFGApplicantStates[applicantID] = nil
                    EasyLFGExpandedApplicants[applicantID] = nil
                end
            end
        end
    end

    table.sort(applicantsByGroup, function(left, right)
        local leftOrder = SanitizeInteger(left and left.slotOrder) or 0
        local rightOrder = SanitizeInteger(right and right.slotOrder) or 0
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end

        return GetApplicantSortKey(left) < GetApplicantSortKey(right)
    end)

    if nextScheduledRefreshAt ~= nil then
        ScheduleEasyLFGRefreshAt(nextScheduledRefreshAt)
    end

    return applicantsByGroup, applicantCount, memberCount
end

local function CreateEasyLFGActionButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(EASY_LFG_ACTION_BUTTON_WIDTH, EASY_LFG_ACTION_BUTTON_HEIGHT)

    if button.SetNormalFontObject then
        button:SetNormalFontObject(GameFontNormalSmall)
        button:SetHighlightFontObject(GameFontHighlightSmall)
        button:SetDisabledFontObject(GameFontDisableSmall)
    end

    local buttonText = button.GetFontString and button:GetFontString() or nil
    if buttonText then
        buttonText:SetWidth(26)
        buttonText:SetJustifyH("CENTER")
    end

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(16, 16)
    icon:Hide()
    button.Icon = icon

    return button
end

local function CreateEasyLFGHeaderButton(parent, width, labelText, onClick, tooltipTitle, tooltipText)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 20)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.58)
    button.Background = background

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
    button.Border = border

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    label:SetTextColor(1, 0.88, 0.62, 1)
    label:SetText(labelText)
    button.Label = label

    button.TooltipTitle = tooltipTitle
    button.TooltipText = tooltipText

    local function ApplyVisualState(self, isHovered)
        local isActive = self.Active == true

        if isHovered then
            if isActive then
                self.Background:SetColorTexture(0.24, 0.18, 0.06, 0.96)
                self.Border:SetColorTexture(1.00, 0.84, 0.24, 0.90)
                self.Label:SetTextColor(1, 0.94, 0.54, 1)
            else
                self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
                self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.72)
                self.Label:SetTextColor(1, 0.88, 0.62, 1)
            end
            return
        end

        if isActive then
            self.Background:SetColorTexture(0.15, 0.11, 0.04, 0.86)
            self.Border:SetColorTexture(1.00, 0.80, 0.22, 0.74)
            self.Label:SetTextColor(1, 0.92, 0.42, 1)
        else
            self.Background:SetColorTexture(0.05, 0.05, 0.06, 0.58)
            self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
            self.Label:SetTextColor(1, 0.88, 0.62, 1)
        end
    end

    button:SetScript("OnEnter", function(self)
        ApplyVisualState(self, true)

        if self.TooltipTitle and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.TooltipTitle, 1, 0.82, 0)
            if self.TooltipText and self.TooltipText ~= "" then
                GameTooltip:AddLine(self.TooltipText, 0.85, 0.85, 0.85, true)
            end
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        ApplyVisualState(self, false)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    button:SetScript("OnClick", onClick)
    button.ApplyVisualState = ApplyVisualState
    ApplyVisualState(button, false)

    return button
end

local function UpdateEasyLFGHeaderButtons()
    if not EasyLFGOverlay or not EasyLFGOverlay.PinButton then
        return
    end

    local hasControllableListing = HasActiveListing() and IsPlayerListingLeader()
    local showRioButton = hasControllableListing and IsRaiderIOAvailable()

    if EasyLFGOverlay.EditButton then
        EasyLFGOverlay.EditButton:SetShown(hasControllableListing)
        EasyLFGOverlay.EditButton:SetEnabled(hasControllableListing)
    end

    if EasyLFGOverlay.DelistButton then
        EasyLFGOverlay.DelistButton:SetShown(hasControllableListing)
        EasyLFGOverlay.DelistButton:SetEnabled(hasControllableListing and C_LFGList and type(C_LFGList.RemoveListing) == "function")
    end

    if EasyLFGOverlay.RioButton then
        EasyLFGOverlay.RioButton:SetShown(showRioButton)
        EasyLFGOverlay.RioButton:SetEnabled(showRioButton)
        EasyLFGOverlay.RioButton.Active = showRioButton and IsEasyLFGRioExpanded()
        EasyLFGOverlay.RioButton.TooltipTitle = L(IsEasyLFGRioExpanded() and "EASY_LFG_OVERLAY_RIO_HIDE_TOOLTIP" or "EASY_LFG_OVERLAY_RIO_SHOW_TOOLTIP")
        EasyLFGOverlay.RioButton.TooltipText = L("EASY_LFG_OVERLAY_RIO_TOOLTIP_HINT")
        if EasyLFGOverlay.RioButton.ApplyVisualState then
            EasyLFGOverlay.RioButton:ApplyVisualState(EasyLFGOverlay.RioButton.IsMouseOver and EasyLFGOverlay.RioButton:IsMouseOver())
        end
    end

    if not showRioButton then
        HideEasyLFGRioTooltip()
    end

    if EasyLFGOverlay.Title then
        local titleAnchor = EasyLFGOverlay.PinButton
        if EasyLFGOverlay.DelistButton and EasyLFGOverlay.DelistButton:IsShown() then
            titleAnchor = EasyLFGOverlay.DelistButton
        end
        if EasyLFGOverlay.EditButton and EasyLFGOverlay.EditButton:IsShown() then
            titleAnchor = EasyLFGOverlay.EditButton
        end
        if EasyLFGOverlay.RioButton and EasyLFGOverlay.RioButton:IsShown() then
            titleAnchor = EasyLFGOverlay.RioButton
        end

        EasyLFGOverlay.Title:ClearAllPoints()
        EasyLFGOverlay.Title:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPLEFT", 18, -16)
        EasyLFGOverlay.Title:SetPoint("RIGHT", titleAnchor, "LEFT", -8, 0)
    end

    if LFG.IsEasyLFGLocked and LFG.IsEasyLFGLocked() then
        EasyLFGOverlay.PinButton.Label:SetText("")
        EasyLFGOverlay.PinButton.TooltipTitle = L("EASY_LFG_OVERLAY_UNPIN_TOOLTIP")
        if EasyLFGOverlay.PinButton.Icon then
            EasyLFGOverlay.PinButton.Icon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
        end
    else
        EasyLFGOverlay.PinButton.Label:SetText("")
        EasyLFGOverlay.PinButton.TooltipTitle = L("EASY_LFG_OVERLAY_PIN_TOOLTIP")
        if EasyLFGOverlay.PinButton.Icon then
            EasyLFGOverlay.PinButton.Icon:SetTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
        end
    end
end

local function CanDeclineApplicantStatus(status)
    return status == "applied" or status == "invited"
end

local function SaveEasyLFGOverlaySize()
    if not EasyLFGOverlay then
        return
    end

    local db = LFG.GetLFGDB()
    db.easyLFGWidth = math.floor(math.max(MIN_EASY_LFG_WIDTH, math.min(MAX_EASY_LFG_WIDTH, EasyLFGOverlay:GetWidth())) + 0.5)
    db.easyLFGHeight = math.floor(math.max(MIN_EASY_LFG_HEIGHT, math.min(MAX_EASY_LFG_HEIGHT, EasyLFGOverlay:GetHeight())) + 0.5)
end

local function ApplyEasyLFGOverlaySize()
    if not EasyLFGOverlay then
        return
    end

    local db = LFG.GetLFGDB()
    EasyLFGOverlay:SetSize(db.easyLFGWidth, db.easyLFGHeight)
end

local function EnsureEasyLFGRow(index)
    if EasyLFGRows[index] then
        return EasyLFGRows[index]
    end

    local row = CreateFrame("Frame", nil, EasyLFGOverlay)
    row:SetHeight(36)
    row:EnableMouse(true)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.54)
    row.Background = background

    local selection = row:CreateTexture(nil, "ARTWORK")
    selection:SetAllPoints()
    selection:SetColorTexture(0.88, 0.72, 0.46, 0.10)
    selection:Hide()
    row.Selection = selection

    local border = row:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.18)
    row.Border = border

    local actionArea = CreateFrame("Frame", nil, row)
    actionArea:SetSize(EASY_LFG_ACTION_AREA_WIDTH, EASY_LFG_ACTION_BUTTON_HEIGHT)
    actionArea:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.ActionArea = actionArea

    local flagAnchor = CreateFrame("Frame", nil, row)
    flagAnchor:SetSize(1, 1)
    flagAnchor:SetPoint("RIGHT", actionArea, "LEFT", -24, 0)
    row.FlagAnchor = flagAnchor

    local toggleButton = CreateFrame("Button", nil, row)
    toggleButton:SetSize(14, 14)
    toggleButton:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
    toggleButton.Label = toggleButton:CreateFontString(nil, "OVERLAY")
    toggleButton.Label:SetPoint("CENTER", toggleButton, "CENTER", 0, 0)
    toggleButton.Label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    toggleButton.Label:SetTextColor(1, 0.88, 0.62, 1)
    toggleButton:SetScript("OnClick", function(self)
        if not self.ApplicantID then
            return
        end

        EasyLFGExpandedApplicants[self.ApplicantID] = not EasyLFGExpandedApplicants[self.ApplicantID]
        if LFG.RefreshEasyLFGOverlay then
            LFG.RefreshEasyLFGOverlay()
        end
    end)
    row.ToggleButton = toggleButton

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
    name:SetPoint("RIGHT", flagAnchor, "LEFT", -12, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    row.Name = name

    local meta = row:CreateFontString(nil, "OVERLAY")
    meta:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    meta:SetPoint("RIGHT", flagAnchor, "LEFT", -12, 0)
    meta:SetJustifyH("LEFT")
    meta:SetWordWrap(false)
    meta:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    meta:SetTextColor(0.78, 0.74, 0.69, 1)
    row.Meta = meta

    local declineButton = CreateEasyLFGActionButton(row)
    declineButton:SetParent(actionArea)
    declineButton:SetPoint("RIGHT", actionArea, "RIGHT", 0, 0)
    declineButton:SetScript("OnClick", function(self)
        if not self.ApplicantID or not CanDeclineApplicantStatus(self.StatusKey) or not C_LFGList or not C_LFGList.DeclineApplicant then
            return
        end

        C_LFGList.DeclineApplicant(self.ApplicantID)
        if LFG.RefreshEasyLFGOverlay then
            LFG.RefreshEasyLFGOverlay()
        end
    end)
    row.DeclineButton = declineButton

    local inviteButton = CreateEasyLFGActionButton(row)
    inviteButton:SetParent(actionArea)
    inviteButton:SetPoint("LEFT", actionArea, "LEFT", 0, 0)
    inviteButton:SetScript("OnClick", function(self)
        if not self.ApplicantID or not CanInviteApplicantStatus(self.StatusKey) then
            return
        end

        C_LFGList.InviteApplicant(self.ApplicantID)
        if LFG.RefreshEasyLFGOverlay then
            LFG.RefreshEasyLFGOverlay()
        end
    end)
    row.InviteButton = inviteButton

    local badge = row:CreateFontString(nil, "OVERLAY")
    badge:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)
    badge:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    badge:SetTextColor(1, 0.88, 0.62, 1)
    badge:SetWordWrap(false)
    badge:Hide()
    row.Badge = badge

    row:SetScript("OnEnter", function(self)
        if IsEasyLFGRioExpanded() and IsUsablePlainString(self.FullName) then
            SetEasyLFGRioSelection(self.FullName, self.DisplayName)
        end
    end)

    EasyLFGRows[index] = row
    return row
end

local function EnsureEasyLFGOverlay()
    if EasyLFGOverlay then
        return EasyLFGOverlay
    end

    EasyLFGOverlay = CreateFrame("Frame", "BeavisQoLEasyLFGOverlay", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    EasyLFGOverlay:SetClampedToScreen(true)
    EasyLFGOverlay:SetMovable(true)
    EasyLFGOverlay:SetResizable(true)
    EasyLFGOverlay:SetToplevel(true)
    EasyLFGOverlay:SetFrameStrata("MEDIUM")
    EasyLFGOverlay:EnableMouse(true)
    EasyLFGOverlay:SetClipsChildren(true)
    EasyLFGOverlay:RegisterForDrag("LeftButton")
    EasyLFGOverlay:SetScript("OnDragStart", function(self)
        if LFG.IsEasyLFGLocked and LFG.IsEasyLFGLocked() then
            return
        end

        self:StartMoving()
    end)
    EasyLFGOverlay:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveEasyLFGOverlayGeometry()
    end)
    if EasyLFGOverlay.SetResizeBounds then
        EasyLFGOverlay:SetResizeBounds(MIN_EASY_LFG_WIDTH, MIN_EASY_LFG_HEIGHT, MAX_EASY_LFG_WIDTH, MAX_EASY_LFG_HEIGHT)
    else
        EasyLFGOverlay:SetMinResize(MIN_EASY_LFG_WIDTH, MIN_EASY_LFG_HEIGHT)
        EasyLFGOverlay:SetMaxResize(MAX_EASY_LFG_WIDTH, MAX_EASY_LFG_HEIGHT)
    end

    local background = EasyLFGOverlay:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    EasyLFGOverlay.Background = background

    local topLine = EasyLFGOverlay:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPLEFT", 10, -8)
    topLine:SetPoint("TOPRIGHT", EasyLFGOverlay, "TOPRIGHT", -10, -8)
    topLine:SetHeight(1)
    topLine:SetColorTexture(0.88, 0.72, 0.46, 0.70)

    local accent = EasyLFGOverlay:CreateTexture(nil, "BACKGROUND")
    accent:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPLEFT", 9, -10)
    accent:SetPoint("BOTTOMLEFT", EasyLFGOverlay, "BOTTOMLEFT", 9, 10)
    accent:SetWidth(2)
    accent:SetColorTexture(0.88, 0.72, 0.46, 0.18)

    EasyLFGOverlay.Title = EasyLFGOverlay:CreateFontString(nil, "OVERLAY")
    EasyLFGOverlay.Title:SetPoint("TOPLEFT", EasyLFGOverlay, "TOPLEFT", 18, -16)
    EasyLFGOverlay.Title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    EasyLFGOverlay.Title:SetTextColor(1, 0.88, 0.62, 1)

    EasyLFGOverlay.CloseButton = CreateEasyLFGHeaderButton(
        EasyLFGOverlay,
        20,
        "X",
        function()
            EasyLFGSuppressed = true
            if LFG.RefreshEasyLFGOverlay then
                LFG.RefreshEasyLFGOverlay()
            end
        end,
        L("EASY_LFG_OVERLAY_CLOSE_TOOLTIP"),
        L("EASY_LFG_OVERLAY_CLOSE_TOOLTIP_HINT")
    )
    EasyLFGOverlay.CloseButton:SetPoint("TOPRIGHT", EasyLFGOverlay, "TOPRIGHT", -12, -11)

    EasyLFGOverlay.PinButton = CreateEasyLFGHeaderButton(
        EasyLFGOverlay,
        20,
        "",
        function()
            if LFG.SetEasyLFGLocked and LFG.IsEasyLFGLocked then
                LFG.SetEasyLFGLocked(not LFG.IsEasyLFGLocked())
            end

            if BeavisQoL.Pages and BeavisQoL.Pages.LFG and BeavisQoL.Pages.LFG.RefreshState then
                BeavisQoL.Pages.LFG:RefreshState()
            end
        end,
        L("EASY_LFG_OVERLAY_PIN_TOOLTIP"),
        L("EASY_LFG_OVERLAY_PIN_TOOLTIP_HINT")
    )
    EasyLFGOverlay.PinButton:SetPoint("RIGHT", EasyLFGOverlay.CloseButton, "LEFT", -4, 0)
    EasyLFGOverlay.PinButton.Icon = EasyLFGOverlay.PinButton:CreateTexture(nil, "OVERLAY")
    EasyLFGOverlay.PinButton.Icon:SetPoint("CENTER", EasyLFGOverlay.PinButton, "CENTER", 0, 0)
    EasyLFGOverlay.PinButton.Icon:SetSize(12, 12)

    EasyLFGOverlay.DelistButton = CreateEasyLFGHeaderButton(
        EasyLFGOverlay,
        84,
        L("EASY_LFG_OVERLAY_DELIST"),
        function()
            RemoveActiveEasyLFGListing()
        end,
        L("EASY_LFG_OVERLAY_DELIST_TOOLTIP"),
        L("EASY_LFG_OVERLAY_DELIST_TOOLTIP_HINT")
    )
    EasyLFGOverlay.DelistButton:SetPoint("RIGHT", EasyLFGOverlay.PinButton, "LEFT", -6, 0)
    EasyLFGOverlay.DelistButton:Hide()

    EasyLFGOverlay.EditButton = CreateEasyLFGHeaderButton(
        EasyLFGOverlay,
        50,
        L("EASY_LFG_OVERLAY_EDIT"),
        function()
            OpenActiveEasyLFGListingEditor()
        end,
        L("EASY_LFG_OVERLAY_EDIT_TOOLTIP"),
        L("EASY_LFG_OVERLAY_EDIT_TOOLTIP_HINT")
    )
    EasyLFGOverlay.EditButton:SetPoint("RIGHT", EasyLFGOverlay.DelistButton, "LEFT", -6, 0)
    EasyLFGOverlay.EditButton:Hide()

    EasyLFGOverlay.RioButton = CreateEasyLFGHeaderButton(
        EasyLFGOverlay,
        36,
        L("EASY_LFG_OVERLAY_RIO"),
        function()
            LFG.SetEasyLFGRioExpanded(not IsEasyLFGRioExpanded())
        end,
        L("EASY_LFG_OVERLAY_RIO_SHOW_TOOLTIP"),
        L("EASY_LFG_OVERLAY_RIO_TOOLTIP_HINT")
    )
    EasyLFGOverlay.RioButton:SetPoint("RIGHT", EasyLFGOverlay.EditButton, "LEFT", -6, 0)
    EasyLFGOverlay.RioButton:Hide()

    EasyLFGOverlay.Title:SetPoint("RIGHT", EasyLFGOverlay.RioButton, "LEFT", -8, 0)

    EasyLFGOverlay.Summary = EasyLFGOverlay:CreateFontString(nil, "OVERLAY")
    EasyLFGOverlay.Summary:SetPoint("TOPLEFT", EasyLFGOverlay.Title, "BOTTOMLEFT", 0, -4)
    EasyLFGOverlay.Summary:SetPoint("RIGHT", EasyLFGOverlay, "RIGHT", -14, 0)
    EasyLFGOverlay.Summary:SetJustifyH("LEFT")
    EasyLFGOverlay.Summary:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    EasyLFGOverlay.Summary:SetTextColor(0.78, 0.74, 0.69, 1)

    EasyLFGOverlay.ScrollFrame = CreateFrame("ScrollFrame", nil, EasyLFGOverlay, "UIPanelScrollFrameTemplate")
    EasyLFGOverlay.ScrollFrame:SetPoint("TOPLEFT", EasyLFGOverlay.Summary, "BOTTOMLEFT", -1, -10)
    EasyLFGOverlay.ScrollFrame:SetPoint("BOTTOMRIGHT", EasyLFGOverlay, "BOTTOMRIGHT", -24, 10)
    EasyLFGOverlay.ScrollFrame:EnableMouseWheel(true)

    EasyLFGOverlay.ScrollChild = CreateFrame("Frame", nil, EasyLFGOverlay.ScrollFrame)
    EasyLFGOverlay.ScrollChild:SetSize(1, 1)
    EasyLFGOverlay.ScrollFrame:SetScrollChild(EasyLFGOverlay.ScrollChild)
    EasyLFGOverlay.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = math.max(0, (EasyLFGOverlay.ScrollChild:GetHeight() or 0) - self:GetHeight())
        local nextScroll = currentScroll - ((delta or 0) * 24)

        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end

        self:SetVerticalScroll(nextScroll)
    end)

    EasyLFGOverlay.EmptyText = EasyLFGOverlay.ScrollChild:CreateFontString(nil, "OVERLAY")
    EasyLFGOverlay.EmptyText:SetPoint("TOPLEFT", EasyLFGOverlay.ScrollChild, "TOPLEFT", 2, -2)
    EasyLFGOverlay.EmptyText:SetPoint("RIGHT", EasyLFGOverlay.ScrollChild, "RIGHT", -2, 0)
    EasyLFGOverlay.EmptyText:SetJustifyH("LEFT")
    EasyLFGOverlay.EmptyText:SetJustifyV("TOP")
    EasyLFGOverlay.EmptyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    EasyLFGOverlay.EmptyText:SetTextColor(0.78, 0.78, 0.80, 1)

    EasyLFGOverlay.Footer = EasyLFGOverlay:CreateFontString(nil, "OVERLAY")
    EasyLFGOverlay.Footer:SetPoint("BOTTOMLEFT", EasyLFGOverlay, "BOTTOMLEFT", 18, 12)
    EasyLFGOverlay.Footer:SetPoint("RIGHT", EasyLFGOverlay, "RIGHT", -14, 0)
    EasyLFGOverlay.Footer:SetJustifyH("LEFT")
    EasyLFGOverlay.Footer:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    EasyLFGOverlay.Footer:SetTextColor(0.72, 0.72, 0.72, 1)

    EasyLFGOverlay.ResizeHandle = CreateFrame("Button", nil, EasyLFGOverlay)
    EasyLFGOverlay.ResizeHandle:SetSize(16, 16)
    EasyLFGOverlay.ResizeHandle:SetPoint("BOTTOMRIGHT", EasyLFGOverlay, "BOTTOMRIGHT", -2, 2)
    EasyLFGOverlay.ResizeHandle:SetScript("OnMouseDown", function()
        if LFG.IsEasyLFGLocked and LFG.IsEasyLFGLocked() then
            return
        end

        EasyLFGOverlay:StartSizing("BOTTOMRIGHT")
    end)
    EasyLFGOverlay.ResizeHandle:SetScript("OnMouseUp", function()
        EasyLFGOverlay:StopMovingOrSizing()
        SaveEasyLFGOverlaySize()
        if LFG.RefreshEasyLFGOverlay then
            LFG.RefreshEasyLFGOverlay()
        end
    end)
    EasyLFGOverlay.ResizeHandle.Texture = EasyLFGOverlay.ResizeHandle:CreateTexture(nil, "OVERLAY")
    EasyLFGOverlay.ResizeHandle.Texture:SetAllPoints()
    EasyLFGOverlay.ResizeHandle.Texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    ApplyEasyLFGOverlayStyle()
    ApplyEasyLFGOverlaySize()
    ApplyEasyLFGOverlayGeometry()
    ApplyEasyLFGOverlayTextScale()
    UpdateEasyLFGHeaderButtons()
    EasyLFGOverlay:Hide()
    return EasyLFGOverlay
end

local function LayoutEasyLFGRows(visibleRows, hasActiveListing)
    local overlay = EnsureEasyLFGOverlay()
    local rowHeight = 36
    local rowGap = 2
    local contentRows = visibleRows > 0 and visibleRows or 1
    local rowsHeight = (contentRows * rowHeight) + ((contentRows - 1) * rowGap)
    local emptyHeight = visibleRows == 0 and 36 or 0
    local contentHeight = math.max(rowsHeight, emptyHeight)

    ApplyEasyLFGOverlaySize()
    overlay.ScrollChild:SetWidth(math.max(1, overlay.ScrollFrame:GetWidth() or (overlay:GetWidth() - 40)))
    overlay.ScrollChild:SetHeight(math.max(1, contentHeight))
    overlay.ScrollFrame:SetVerticalScroll(0)

    if visibleRows == 0 then
        overlay.EmptyText:Show()
        if hasActiveListing then
            overlay.EmptyText:SetText(L("EASY_LFG_OVERLAY_EMPTY"))
        else
            overlay.EmptyText:SetText(L("EASY_LFG_OVERLAY_NO_GROUP"))
        end
    else
        overlay.EmptyText:Hide()
    end

    for index, row in ipairs(EasyLFGRows) do
        if index <= visibleRows then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", overlay.ScrollChild, "TOPLEFT", 1, -((index - 1) * (rowHeight + rowGap)))
            row:SetPoint("RIGHT", overlay.ScrollChild, "RIGHT", 0, 0)
            row:Show()
        else
            row:Hide()
        end
    end

    overlay.Footer:SetText("")
    overlay.Footer:Hide()
end

local function RefreshEasyLFGOverlay()
    local overlay = EnsureEasyLFGOverlay()
    local db = LFG.GetLFGDB()

    ApplyEasyLFGOverlayStyle()
    ApplyEasyLFGOverlaySize()
    ApplyEasyLFGOverlayGeometry()
    ApplyEasyLFGOverlayTextScale()

    overlay.Title:SetText(L("EASY_LFG_OVERLAY_TITLE"))
    UpdateEasyLFGHeaderButtons()

    if not db.easyLFGEnabled then
        EasyLFGSuppressed = false
        HideEasyLFGRioTooltip()
        overlay:Hide()
        return
    end

    local activeListing = HasActiveListing()
    local controllableListing = activeListing and IsPlayerListingLeader()
    if controllableListing and not EasyLFGWasActiveListing then
        EasyLFGSuppressed = false
        ResetEasyLFGApplicantState()
    elseif not controllableListing then
        EasyLFGSuppressed = false
        ResetEasyLFGApplicantState()
        EasyLFGRioSelectedFullName = nil
        EasyLFGRioSelectedDisplayName = nil
    end
    EasyLFGWasActiveListing = controllableListing

    if not controllableListing then
        overlay.Summary:SetText(L("EASY_LFG_OVERLAY_NO_GROUP_SHORT"))
        LayoutEasyLFGRows(0, false)
        UpdateEasyLFGRioSelectionVisuals()
        HideEasyLFGRioTooltip()
        overlay:Hide()
        return
    end

    if EasyLFGSuppressed then
        HideEasyLFGRioTooltip()
        overlay:Hide()
        return
    end

    local applicantGroups, applicantCount, memberCount = GetEasyLFGApplicants()
    local applicants = {}
    local visibleApplicantIDs = {}

    for _, applicantGroup in ipairs(applicantGroups) do
        visibleApplicantIDs[applicantGroup.applicantID] = true

        local leader = applicantGroup.members[1]
        if leader then
            leader.isExpandable = applicantGroup.memberCount > 1
            leader.isExpanded = EasyLFGExpandedApplicants[applicantGroup.applicantID] == true
            leader.isChildRow = false
            applicants[#applicants + 1] = leader

            if leader.isExpandable and leader.isExpanded then
                for memberIndex = 2, #applicantGroup.members do
                    local memberRow = applicantGroup.members[memberIndex]
                    memberRow.isExpandable = false
                    memberRow.isExpanded = false
                    memberRow.isChildRow = true
                    applicants[#applicants + 1] = memberRow
                end
            end
        end
    end

    for applicantID in pairs(EasyLFGExpandedApplicants) do
        if not visibleApplicantIDs[applicantID] then
            EasyLFGExpandedApplicants[applicantID] = nil
        end
    end

    local visibleRows = #applicants
    local visibleApplicantsByFullName = {}

    for _, rowData in ipairs(applicants) do
        if IsUsablePlainString(rowData.fullName) then
            visibleApplicantsByFullName[rowData.fullName] = rowData
        end
    end

    if not visibleApplicantsByFullName[EasyLFGRioSelectedFullName] then
        EasyLFGRioSelectedFullName = nil
        EasyLFGRioSelectedDisplayName = nil

        for _, rowData in ipairs(applicants) do
            if IsUsablePlainString(rowData.fullName) and rowData.isPrimary then
                EasyLFGRioSelectedFullName = rowData.fullName
                EasyLFGRioSelectedDisplayName = rowData.displayName
                break
            end
        end

        if not EasyLFGRioSelectedFullName and applicants[1] and IsUsablePlainString(applicants[1].fullName) then
            EasyLFGRioSelectedFullName = applicants[1].fullName
            EasyLFGRioSelectedDisplayName = applicants[1].displayName
        end
    elseif visibleApplicantsByFullName[EasyLFGRioSelectedFullName] then
        EasyLFGRioSelectedDisplayName = visibleApplicantsByFullName[EasyLFGRioSelectedFullName].displayName or EasyLFGRioSelectedDisplayName
    end

    overlay.Summary:SetText(L("EASY_LFG_OVERLAY_SUMMARY"):format(applicantCount, memberCount))

    for index = 1, visibleRows do
        local rowData = applicants[index]
        local row = EnsureEasyLFGRow(index)
        local classRed, classGreen, classBlue = GetEasyLFGClassColor(rowData.classFile)
        local metaParts = {}
        local roleIcon = GetEasyLFGRoleIconMarkup(rowData.assignedRole)
        local specIcon = GetEasyLFGSpecIconMarkup(rowData.specID, rowData.classFile, rowData.assignedRole)
        local nameLeft = 8
        local isInactivePlaceholder = rowData.isInactivePlaceholder == true

        if rowData.isExpandable then
            nameLeft = 26
        elseif rowData.isChildRow then
            nameLeft = 40
        end

        row.Name:ClearAllPoints()
        row.Name:SetPoint("TOPLEFT", row, "TOPLEFT", nameLeft, -4)
        row.Name:SetPoint("RIGHT", row.FlagAnchor, "LEFT", -4, 0)

        row.Meta:ClearAllPoints()
        row.Meta:SetPoint("TOPLEFT", row.Name, "BOTTOMLEFT", 0, -1)
        row.Meta:SetPoint("RIGHT", row.FlagAnchor, "LEFT", -4, 0)

        if isInactivePlaceholder then
            row.Background:SetColorTexture(0.10, 0.045, 0.045, 0.70)
            row.Border:SetColorTexture(0.88, 0.32, 0.32, 0.26)

            row.Name:SetText(rowData.displayName or "")
            row.Name:SetTextColor(0.78, 0.78, 0.78, 1)
            row.Meta:SetText(L("EASY_LFG_STATUS_INACTIVE"))
            row.Meta:SetTextColor(0.92, 0.54, 0.54, 1)
            row.FullName = nil
            row.DisplayName = nil

            row.Badge:SetText("")
            row.Badge:Hide()

            row.ToggleButton.ApplicantID = nil
            row.ToggleButton.Label:SetText("")
            row.ToggleButton:Hide()

            row.DeclineButton.ApplicantID = nil
            row.DeclineButton.StatusKey = nil
            row.DeclineButton:SetShown(false)
            row.DeclineButton:SetEnabled(false)

            row.InviteButton.ApplicantID = nil
            row.InviteButton.StatusKey = nil
            row.InviteButton:SetShown(false)
            row.InviteButton:SetEnabled(false)
        else
            row.Background:SetColorTexture(0.05, 0.05, 0.06, 0.54)
            row.Border:SetColorTexture(0.88, 0.72, 0.46, 0.18)
            row.Meta:SetTextColor(0.78, 0.74, 0.69, 1)

            if roleIcon then
                metaParts[#metaParts + 1] = roleIcon
            end

            if specIcon then
                metaParts[#metaParts + 1] = specIcon
            end

            if type(rowData.itemLevel) == "number" and rowData.itemLevel > 0 then
                metaParts[#metaParts + 1] = L("EASY_LFG_ITEM_LEVEL"):format(string.format("%.1f", rowData.itemLevel))
            end

            if type(rowData.dungeonScore) == "number" and rowData.dungeonScore > 0 then
                metaParts[#metaParts + 1] = L("EASY_LFG_SCORE"):format(math.floor(rowData.dungeonScore + 0.5))
            end

            row.Name:SetText(rowData.displayName)
            row.Name:SetTextColor(classRed, classGreen, classBlue, 1)
            row.Meta:SetText(table.concat(metaParts, " | "))
            row.FullName = rowData.fullName
            row.DisplayName = rowData.displayName

            row.Badge:SetText("")
            row.Badge:Hide()

            row.ToggleButton.ApplicantID = rowData.applicantID
            if rowData.isExpandable then
                row.ToggleButton.Label:SetText(rowData.isExpanded and "-" or "+")
                row.ToggleButton:Show()
            else
                row.ToggleButton.Label:SetText("")
                row.ToggleButton:Hide()
            end

            row.DeclineButton.ApplicantID = rowData.applicantID
            row.DeclineButton.StatusKey = rowData.applicationStatus
            row.DeclineButton:SetText("X")
            row.DeclineButton.Icon:Hide()
            row.DeclineButton:SetShown(rowData.isPrimary)
            row.DeclineButton:SetEnabled(rowData.isPrimary and CanDeclineApplicantStatus(rowData.applicationStatus))

            row.InviteButton.ApplicantID = rowData.applicantID
            row.InviteButton.StatusKey = rowData.applicationStatus
            row.InviteButton:SetText("")
            row.InviteButton.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            row.InviteButton.Icon:Show()
            row.InviteButton:SetShown(rowData.isPrimary)
            row.InviteButton:SetEnabled(rowData.isPrimary and CanInviteApplicantStatus(rowData.applicationStatus))
        end

        LFG.ApplyFlagToFullName(row, rowData.fullName, row.FlagAnchor, 0, 0)
    end

    ApplyEasyLFGOverlayTextScale()
    UpdateEasyLFGHeaderButtons()
    LayoutEasyLFGRows(visibleRows, true)
    UpdateEasyLFGRioSelectionVisuals()
    overlay:Show()
    RefreshEasyLFGRioTooltip()
end

LFG.RefreshEasyLFGOverlay = RefreshEasyLFGOverlay

function LFG.IsEasyLFGEnabled()
    return LFG.GetLFGDB().easyLFGEnabled == true
end

function LFG.SetEasyLFGEnabled(value)
    LFG.GetLFGDB().easyLFGEnabled = value and true or false
    RefreshEasyLFGOverlay()
end

function LFG.IsEasyLFGLocked()
    return LFG.GetLFGDB().easyLFGLocked == true
end

function LFG.SetEasyLFGLocked(value)
    LFG.GetLFGDB().easyLFGLocked = value and true or false
    RefreshEasyLFGOverlay()
end

function LFG.IsEasyLFGRioExpanded()
    return IsEasyLFGRioExpanded()
end

function LFG.SetEasyLFGRioExpanded(value)
    LFG.GetLFGDB().easyLFGRioExpanded = value and true or false
    if not value then
        HideEasyLFGRioTooltip()
    end
    RefreshEasyLFGOverlay()
end

function LFG.GetEasyLFGScale()
    return LFG.GetLFGDB().easyLFGScale
end

function LFG.SetEasyLFGScale(value)
    local db = LFG.GetLFGDB()
    db.easyLFGScale = math.max(MIN_EASY_LFG_SCALE, math.min(MAX_EASY_LFG_SCALE, value or DEFAULT_EASY_LFG_SCALE))
    RefreshEasyLFGOverlay()
end

function LFG.GetEasyLFGTextScale()
    return LFG.GetLFGDB().easyLFGTextScale
end

function LFG.SetEasyLFGTextScale(value)
    local db = LFG.GetLFGDB()
    db.easyLFGTextScale = math.max(MIN_EASY_LFG_TEXT_SCALE, math.min(MAX_EASY_LFG_TEXT_SCALE, value or DEFAULT_EASY_LFG_TEXT_SCALE))
    RefreshEasyLFGOverlay()
end

function LFG.GetEasyLFGBackgroundAlpha()
    return LFG.GetLFGDB().easyLFGAlpha
end

function LFG.SetEasyLFGBackgroundAlpha(value)
    local db = LFG.GetLFGDB()
    db.easyLFGAlpha = math.max(MIN_EASY_LFG_ALPHA, math.min(MAX_EASY_LFG_ALPHA, value or DEFAULT_EASY_LFG_ALPHA))
    RefreshEasyLFGOverlay()
end

function LFG.ResetEasyLFGPosition()
    local db = LFG.GetLFGDB()
    db.easyLFGPoint = DEFAULT_EASY_LFG_POINT
    db.easyLFGRelativePoint = DEFAULT_EASY_LFG_RELATIVE_POINT
    db.easyLFGOffsetX = DEFAULT_EASY_LFG_OFFSET_X
    db.easyLFGOffsetY = DEFAULT_EASY_LFG_OFFSET_Y
    db.easyLFGWidth = DEFAULT_EASY_LFG_WIDTH
    db.easyLFGHeight = DEFAULT_EASY_LFG_HEIGHT
    RefreshEasyLFGOverlay()
end

-- Die Events sind nur dazu da, den Hook im richtigen Moment zu setzen und sichtbare Einträge nachzuziehen.
local FlagWatcher = CreateFrame("Frame")
FlagWatcher:RegisterEvent("PLAYER_LOGIN")
FlagWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
FlagWatcher:RegisterEvent("ADDON_LOADED")
FlagWatcher:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
FlagWatcher:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
FlagWatcher:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
FlagWatcher:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
FlagWatcher:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
FlagWatcher:RegisterEvent("GROUP_ROSTER_UPDATE")

FlagWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "Blizzard_GroupFinder" then
            return
        end
    end

    TryInstallHooks()

    if LFG.IsFlagsEnabled() then
        RefreshVisibleApplicantFlags()
        RefreshVisibleSearchResultFlags()
    end

    if LFG.IsEasyLFGEnabled and LFG.IsEasyLFGEnabled() then
        RefreshEasyLFGOverlay()
    end
end)

