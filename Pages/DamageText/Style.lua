local ADDON_NAME, BeavisAddon = ...

BeavisAddon.DamageText = BeavisAddon.DamageText or {}
local DamageText = BeavisAddon.DamageText

local BUILTIN_FONTS = {
    { key = "blizzard", label = "Blizzard Standard" },
    { key = "frizqt", label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { key = "morpheus", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { key = "skurri", label = "Skurri", path = "Fonts\\SKURRI.TTF" },
    { key = "arialn", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
}

local WORLD_TEXT_CVARS = {
    scale = { "WorldTextScale_v2", "WorldTextScale" },
    gravity = { "WorldTextGravity_v2", "WorldTextGravity" },
    rampDuration = { "WorldTextRampDuration_v2", "WorldTextRampDuration" },
}

local RUNTIME_FONT_OBJECT_NAMES = {
    "CombatTextFont",
    "DamageNumberFont",
    "WorldFont",
}

local STARTUP_APPLY_DELAYS = { 0, 0.5 }

local originalDamageTextFont = rawget(_G, "BeavisDamageTextOriginalFont") or DAMAGE_TEXT_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local originalCVarValues = {}
local originalFontObjectStates = {}
local originalsCaptured = false
local debugProbeFrame = nil
local debugProbeFontString = nil
local legacyIsAddOnLoaded = rawget(_G, "IsAddOnLoaded")

local function CaptureRuntimeFontObjectOriginals()
    for _, fontObjectName in ipairs(RUNTIME_FONT_OBJECT_NAMES) do
        if originalFontObjectStates[fontObjectName] == nil then
            local fontObject = rawget(_G, fontObjectName)
            if fontObject and fontObject.GetFont then
                local fontFile, fontSize, fontFlags = fontObject:GetFont()
                if type(fontFile) == "string" and fontFile ~= "" then
                    originalFontObjectStates[fontObjectName] = {
                        file = fontFile,
                        size = fontSize,
                        flags = fontFlags,
                    }
                end
            end
        end
    end
end

local function CaptureOriginals()
    CaptureRuntimeFontObjectOriginals()

    if originalsCaptured then
        return
    end

    originalDamageTextFont = rawget(_G, "BeavisDamageTextOriginalFont") or originalDamageTextFont or DAMAGE_TEXT_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

    for _, cvarNames in pairs(WORLD_TEXT_CVARS) do
        for _, cvarName in ipairs(cvarNames) do
            if originalCVarValues[cvarName] == nil then
                local currentValue = GetCVar(cvarName)
                if currentValue ~= nil then
                    originalCVarValues[cvarName] = currentValue
                end
            end
        end
    end

    originalsCaptured = true
end

function DamageText.GetDamageTextDB()
    BeavisAddonDB = BeavisAddonDB or {}
    BeavisAddonDB.damageText = BeavisAddonDB.damageText or {}

    if BeavisAddonDB.damageText.enabled == nil then
        BeavisAddonDB.damageText.enabled = false
    end

    if type(BeavisAddonDB.damageText.fontKey) ~= "string" or BeavisAddonDB.damageText.fontKey == "" then
        BeavisAddonDB.damageText.fontKey = "blizzard"
    end

    if type(BeavisAddonDB.damageText.worldTextScale) ~= "number" then
        BeavisAddonDB.damageText.worldTextScale = 1.0
    end

    if type(BeavisAddonDB.damageText.worldTextGravity) ~= "number" then
        BeavisAddonDB.damageText.worldTextGravity = 0.5
    end

    if type(BeavisAddonDB.damageText.worldTextRampDuration) ~= "number" then
        BeavisAddonDB.damageText.worldTextRampDuration = 1.0
    end

    return BeavisAddonDB.damageText
end

local function GetCustomFontOptions()
    local customFonts = rawget(_G, "BeavisAddon_CustomFonts")
    if type(customFonts) ~= "table" then
        return {}
    end

    local options = {}

    for _, fontOption in ipairs(customFonts) do
        if type(fontOption) == "table"
            and type(fontOption.key) == "string"
            and fontOption.key ~= ""
            and type(fontOption.path) == "string"
            and fontOption.path ~= "" then
            table.insert(options, {
                key = fontOption.key,
                label = fontOption.label or fontOption.key,
                path = fontOption.path,
            })
        end
    end

    return options
end

local function BuildFontOptions()
    local options = {}
    local seenKeys = {}

    for _, fontOption in ipairs(BUILTIN_FONTS) do
        if not seenKeys[fontOption.key] then
            table.insert(options, fontOption)
            seenKeys[fontOption.key] = true
        end
    end

    for _, fontOption in ipairs(GetCustomFontOptions()) do
        if not seenKeys[fontOption.key] then
            table.insert(options, fontOption)
            seenKeys[fontOption.key] = true
        end
    end

    return options
end

function DamageText.GetAvailableFonts()
    return BuildFontOptions()
end

local function GetFontOption(fontKey)
    local availableFonts = BuildFontOptions()

    for _, fontOption in ipairs(availableFonts) do
        if fontOption.key == fontKey then
            return fontOption
        end
    end

    return availableFonts[1] or BUILTIN_FONTS[1]
end

local function GetResolvedFontPath(fontKey)
    local fontOption = GetFontOption(fontKey)

    if type(fontOption.path) == "string" and fontOption.path ~= "" then
        return fontOption.path
    end

    return originalDamageTextFont or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

function DamageText.GetPreviewFontPath(fontKey)
    return GetResolvedFontPath(fontKey)
end

local function SetWorldTextCVar(cvarNames, value)
    for _, cvarName in ipairs(cvarNames) do
        if GetCVar(cvarName) ~= nil then
            SetCVar(cvarName, tostring(value))
        end
    end
end

local function RestoreWorldTextCVars()
    for _, cvarNames in pairs(WORLD_TEXT_CVARS) do
        for _, cvarName in ipairs(cvarNames) do
            local originalValue = originalCVarValues[cvarName]
            if originalValue ~= nil and GetCVar(cvarName) ~= nil then
                SetCVar(cvarName, originalValue)
            end
        end
    end
end

local function ClampValue(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function RoundToStep(value, step)
    return math.floor((value / step) + 0.5) * step
end

function DamageText.IsEnabled()
    return DamageText.GetDamageTextDB().enabled == true
end

function DamageText.GetSelectedFontKey()
    return DamageText.GetDamageTextDB().fontKey
end

function DamageText.GetSelectedFontLabel()
    return GetFontOption(DamageText.GetSelectedFontKey()).label
end

function DamageText.GetWorldTextScale()
    return DamageText.GetDamageTextDB().worldTextScale
end

function DamageText.GetWorldTextGravity()
    return DamageText.GetDamageTextDB().worldTextGravity
end

function DamageText.GetWorldTextRampDuration()
    return DamageText.GetDamageTextDB().worldTextRampDuration
end

function DamageText.IsConflictingAddonLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("NiceDamage") == true
    end

    if legacyIsAddOnLoaded then
        return legacyIsAddOnLoaded("NiceDamage") == true
    end

    return false
end

local function EnsureDebugProbe()
    if debugProbeFontString then
        return debugProbeFontString
    end

    debugProbeFrame = CreateFrame("Frame", nil, UIParent)
    debugProbeFrame:Hide()
    debugProbeFontString = debugProbeFrame:CreateFontString(nil, "OVERLAY")

    return debugProbeFontString
end

function DamageText.GetDebugStatusLines()
    local lines = {}
    local db = DamageText.GetDamageTextDB()
    local selectedFontPath = GetResolvedFontPath(db.fontKey)
    local probe = EnsureDebugProbe()
    local probeOk = false

    if probe and selectedFontPath and selectedFontPath ~= "" then
        probeOk = probe:SetFont(selectedFontPath, 16, "") and true or false
    end

    table.insert(lines, "Aktiv: " .. (DamageText.IsEnabled() and "ja" or "nein"))
    table.insert(lines, "Auswahl: " .. (GetFontOption(db.fontKey).label or db.fontKey))
    table.insert(lines, "Gewählter Pfad: " .. tostring(selectedFontPath or "<leer>"))
    table.insert(lines, "Bootstrap-Font: " .. tostring(rawget(_G, "BeavisDamageTextBootstrapFont") or "<leer>"))
    table.insert(lines, "Aktiver DAMAGE_TEXT_FONT: " .. tostring(DAMAGE_TEXT_FONT or "<leer>"))
    table.insert(lines, "Font-Datei direkt ladbar: " .. (probeOk and "ja" or "nein"))
    table.insert(lines, "NiceDamage geladen: " .. (DamageText.IsConflictingAddonLoaded() and "ja" or "nein"))

    for _, fontObjectName in ipairs(RUNTIME_FONT_OBJECT_NAMES) do
        local fontObject = rawget(_G, fontObjectName)
        if fontObject and fontObject.GetFont then
            local fontFile, fontSize, fontFlags = fontObject:GetFont()
            if fontFile ~= nil then
                table.insert(lines, string.format("%s: %s | %s | %s", fontObjectName, tostring(fontFile), tostring(fontSize or "?"), tostring(fontFlags or "")))
            end
        end
    end

    for key, cvarNames in pairs(WORLD_TEXT_CVARS) do
        for _, cvarName in ipairs(cvarNames) do
            local currentValue = GetCVar(cvarName)
            if currentValue ~= nil then
                table.insert(lines, cvarName .. ": " .. tostring(currentValue))
                break
            end
        end
    end

    local damageToggle = GetCVar("floatingCombatTextCombatDamage")
    if damageToggle ~= nil then
        table.insert(lines, "floatingCombatTextCombatDamage: " .. tostring(damageToggle))
    end

    local masterToggle = GetCVar("enableFloatingCombatText")
    if masterToggle ~= nil then
        table.insert(lines, "enableFloatingCombatText: " .. tostring(masterToggle))
    end

    return lines
end

local function ApplyRuntimeFontObjects(fontPath)
    CaptureRuntimeFontObjectOriginals()

    for _, fontObjectName in ipairs(RUNTIME_FONT_OBJECT_NAMES) do
        local fontObject = rawget(_G, fontObjectName)
        if fontObject and fontObject.GetFont and fontObject.SetFont then
            local _, currentSize, currentFlags = fontObject:GetFont()
            fontObject:SetFont(fontPath, tonumber(currentSize) or 16, currentFlags or "")
        end
    end
end

local function RestoreRuntimeFontObjects()
    CaptureRuntimeFontObjectOriginals()

    for _, fontObjectName in ipairs(RUNTIME_FONT_OBJECT_NAMES) do
        local fontObject = rawget(_G, fontObjectName)
        local originalState = originalFontObjectStates[fontObjectName]
        if fontObject and originalState and fontObject.SetFont then
            fontObject:SetFont(originalDamageTextFont or originalState.file, tonumber(originalState.size) or 16, originalState.flags or "")
        end
    end
end

function DamageText.ApplyCurrentSettings()
    if not DamageText.IsEnabled() then
        return
    end

    CaptureOriginals()

    local db = DamageText.GetDamageTextDB()
    local fontPath = GetResolvedFontPath(db.fontKey)
    if type(fontPath) == "string" and fontPath ~= "" then
        DAMAGE_TEXT_FONT = fontPath
        ApplyRuntimeFontObjects(fontPath)
    end

    SetWorldTextCVar(WORLD_TEXT_CVARS.scale, db.worldTextScale)
    SetWorldTextCVar(WORLD_TEXT_CVARS.gravity, db.worldTextGravity)
    SetWorldTextCVar(WORLD_TEXT_CVARS.rampDuration, db.worldTextRampDuration)
end

function DamageText.RestoreDefaults()
    CaptureOriginals()

    DAMAGE_TEXT_FONT = originalDamageTextFont or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    RestoreRuntimeFontObjects()
    RestoreWorldTextCVars()
end

local function ScheduleStartupApplyBurst()
    if not DamageText.IsEnabled() then
        return
    end

    for _, delay in ipairs(STARTUP_APPLY_DELAYS) do
        C_Timer.After(delay, function()
            if DamageText.IsEnabled() then
                DamageText.ApplyCurrentSettings()
            end
        end)
    end
end

function DamageText.ReapplyNow()
    if DamageText.IsEnabled() then
        DamageText.ApplyCurrentSettings()
        ScheduleStartupApplyBurst()
    else
        DamageText.RestoreDefaults()
    end
end

function DamageText.SetEnabled(value)
    DamageText.GetDamageTextDB().enabled = value and true or false

    if value then
        DamageText.ReapplyNow()
    else
        DamageText.RestoreDefaults()
    end
end

function DamageText.SetSelectedFontKey(fontKey)
    DamageText.GetDamageTextDB().fontKey = GetFontOption(fontKey).key

    if DamageText.IsEnabled() then
        DamageText.ReapplyNow()
    end
end

function DamageText.SetWorldTextScale(value)
    local roundedValue = RoundToStep(tonumber(value) or 1.0, 0.1)
    DamageText.GetDamageTextDB().worldTextScale = ClampValue(roundedValue, 0.5, 5.0)

    if DamageText.IsEnabled() then
        DamageText.ApplyCurrentSettings()
    end
end

function DamageText.SetWorldTextGravity(value)
    local roundedValue = RoundToStep(tonumber(value) or 0.5, 0.1)
    DamageText.GetDamageTextDB().worldTextGravity = ClampValue(roundedValue, -10.0, 10.0)

    if DamageText.IsEnabled() then
        DamageText.ApplyCurrentSettings()
    end
end

function DamageText.SetWorldTextRampDuration(value)
    local roundedValue = RoundToStep(tonumber(value) or 1.0, 0.1)
    DamageText.GetDamageTextDB().worldTextRampDuration = ClampValue(roundedValue, 0.1, 3.0)

    if DamageText.IsEnabled() then
        DamageText.ApplyCurrentSettings()
    end
end

local DamageTextWatcher = CreateFrame("Frame")
DamageTextWatcher:RegisterEvent("PLAYER_LOGIN")
DamageTextWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
DamageTextWatcher:RegisterEvent("ADDON_LOADED")

DamageTextWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME and loadedAddon ~= "Blizzard_CombatText" then
            return
        end
    end

    if DamageText.IsEnabled() then
        ScheduleStartupApplyBurst()
    else
        CaptureOriginals()
    end
end)

CaptureOriginals()
if DamageText.IsEnabled() then
    DamageText.ApplyCurrentSettings()
end
