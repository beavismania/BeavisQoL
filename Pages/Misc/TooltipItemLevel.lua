local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

-- Wie lange ein bereits abgefragtes Itemlevel im lokalen Cache gültig bleibt.
-- So vermeiden wir unnötig viele Inspect-Anfragen an denselben Spieler.
local INSPECT_CACHE_TTL = 300

-- Mindestabstand zwischen zwei Inspect-Anfragen.
-- Blizzard begrenzt diese Abfragen recht streng, daher drosseln wir aktiv.
local INSPECT_REQUEST_THROTTLE = 1.5

-- Der Cache speichert Itemlevel pro festem Unit-Token wie "mouseover" oder
-- "target". Das ist weniger flexibel als GUID-basierte Zuordnung, vermeidet in
-- geschützten Tooltip-Pfaden aber geheime String-Werte als Tabellenindex.
local inspectCache = {}
local tooltipItemLevelLines = setmetatable({}, { __mode = "k" })

-- Solange eine Inspect-Anfrage läuft, merken wir uns nur den festen Unit-Token.
-- Auch hier vermeiden wir absichtlich GUIDs im Laufweg dieses Moduls.
local pendingInspectUnit = nil
local lastInspectRequestTime = 0
local inspectFrameProtectionUntil = 0
local inspectFrameHooksInstalled = false
local inspectPVPSafetyInstalled = false
local originalInspectPVPFrameUpdate = nil

-- Diese festen Unit-Tokens sind in Tooltip-Kontexten am verlässlichsten.
-- Wir arbeiten bewusst nur mit bekannten Tokens, um Taint-Probleme zu vermeiden.
local COMMON_UNIT_TOKENS = {
    "mouseover",
    "target",
    "focus",
}

-- Dieses Modul erweitert die bestehende Misc-Datenbank nur um einen weiteren
-- Schalter. Die vorhandenen Defaults bleiben deshalb komplett erhalten.
function Misc.GetMiscDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.misc = BeavisQoLDB.misc or {}

    if BeavisQoLDB.misc.autoSellJunk == nil then
        BeavisQoLDB.misc.autoSellJunk = false
    end

    if BeavisQoLDB.misc.autoRepair == nil then
        BeavisQoLDB.misc.autoRepair = false
    end

    if BeavisQoLDB.misc.autoRepairGuild == nil then
        BeavisQoLDB.misc.autoRepairGuild = false
    end

    if BeavisQoLDB.misc.easyDelete == nil then
        BeavisQoLDB.misc.easyDelete = false
    end

    if BeavisQoLDB.misc.fastLoot == nil then
        BeavisQoLDB.misc.fastLoot = false
    end

    if BeavisQoLDB.misc.cameraDistanceMode ~= nil
        and BeavisQoLDB.misc.cameraDistanceMode ~= "standard"
        and BeavisQoLDB.misc.cameraDistanceMode ~= "max" then
        BeavisQoLDB.misc.cameraDistanceMode = nil
    end

    if BeavisQoLDB.misc.tooltipItemLevel == nil then
        BeavisQoLDB.misc.tooltipItemLevel = false
    end

    return BeavisQoLDB.misc
end

-- Kleine Lesefunktion für die UI und für das Tooltip-Modul.
-- Sie kapselt den Datenbankzugriff an einer einzigen Stelle.
function Misc.IsTooltipItemLevelEnabled()
    return Misc.GetMiscDB().tooltipItemLevel == true
end

-- Schreibt den Schalter bewusst als echtes Boolean in die SavedVariables.
-- Dadurch entstehen später keine Mischformen wie nil, 0 oder "false".
function Misc.SetTooltipItemLevelEnabled(value)
    Misc.GetMiscDB().tooltipItemLevel = value and true or false
end

-- Secret-Strings aus Blizzard-Tooltips können schon in API-Aufrufen oder
-- Vergleichen Fehler auslösen. Diese Hilfen fangen solche Fälle defensiv ab.
local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local ok, result = pcall(func, ...)
    if ok then
        return result
    end

    return nil
end

local function SafeUnitExists(unit)
    return SafeCall(UnitExists, unit) == true
end

local function SafeUnitIsPlayer(unit)
    return SafeCall(UnitIsPlayer, unit) == true
end

local function SafeUnitIsUnit(unitA, unitB)
    return SafeCall(UnitIsUnit, unitA, unitB) == true
end

local function SafeCanInspect(unit)
    return SafeCall(CanInspect, unit) == true
end

local function SafeUnitGUID(unit)
    local guid = SafeCall(UnitGUID, unit)
    if type(guid) == "string" then
        return guid
    end

    return nil
end

local function GetInspectCacheKey(unit)
    if type(unit) == "string" and unit ~= "" then
        return "unit:" .. unit
    end

    return nil
end

local function SafeGetInspectItemLevel(unit)
    if not C_PaperDollInfo or type(C_PaperDollInfo.GetInspectItemLevel) ~= "function" then
        return nil
    end

    local itemLevel = SafeCall(C_PaperDollInfo.GetInspectItemLevel, unit)
    if type(itemLevel) == "number" and itemLevel > 0 then
        return itemLevel
    end

    return nil
end

local function SafeNotifyInspect(unit)
    SafeCall(NotifyInspect, unit)
end

local function SafeStringsEqual(left, right)
    if left == nil or right == nil then
        return false
    end

    local ok, isEqual = pcall(function()
        return left == right
    end)

    return ok and isEqual == true
end

local function IsUsablePlayerUnit(unit)
    return type(unit) == "string"
        and SafeUnitExists(unit)
        and SafeUnitIsPlayer(unit)
end

-- Liefert eine möglichst präzise Zeitbasis.
-- Falls die genaue API nicht existiert, fallen wir sauber auf GetTime zurück.
local function GetNow()
    if GetTimePreciseSec then
        return GetTimePreciseSec()
    end

    return GetTime and GetTime() or 0
end

local function MarkInspectFrameProtected(durationSeconds)
    local duration = tonumber(durationSeconds) or 0
    if duration <= 0 then
        duration = 1
    end

    inspectFrameProtectionUntil = math.max(inspectFrameProtectionUntil, GetNow() + duration)
end

local function EnsureInspectFrameHooks()
    if inspectFrameHooksInstalled then
        return
    end

    local inspectFrame = rawget(_G, "InspectFrame")
    if not inspectFrame or not inspectFrame.HookScript then
        return
    end

    inspectFrame:HookScript("OnShow", function()
        MarkInspectFrameProtected(2)
    end)

    inspectFrame:HookScript("OnHide", function()
        MarkInspectFrameProtected(1)
    end)

    inspectFrameHooksInstalled = true
end

local function IsBlizzardInspectFrameActive()
    EnsureInspectFrameHooks()

    local inspectFrame = rawget(_G, "InspectFrame")
    if inspectFrame then
        if inspectFrame.IsVisible and inspectFrame:IsVisible() then
            MarkInspectFrameProtected(2)
            return true
        end

        if inspectFrame.IsShown and inspectFrame:IsShown() then
            MarkInspectFrameProtected(2)
            return true
        end
    end

    return inspectFrameProtectionUntil > GetNow()
end

local function HasValidInspectFrameUnit(parent)
    local inspectParent = parent
    if type(inspectParent) ~= "table" or inspectParent.unit == nil then
        inspectParent = rawget(_G, "InspectFrame")
    end

    local unit = inspectParent and inspectParent.unit or nil
    if type(unit) ~= "string" then
        return false
    end

    if not SafeUnitExists(unit) then
        return false
    end

    return true
end

local function InstallInspectPVPSafetyHook()
    if inspectPVPSafetyInstalled then
        return
    end

    local inspectPVPFrameUpdate = rawget(_G, "InspectPVPFrame_Update")
    if type(inspectPVPFrameUpdate) ~= "function" then
        return
    end

    originalInspectPVPFrameUpdate = inspectPVPFrameUpdate
    _G.InspectPVPFrame_Update = function(parent, ...)
        if not HasValidInspectFrameUnit(parent) then
            return
        end

        return originalInspectPVPFrameUpdate(parent, ...)
    end

    inspectPVPSafetyInstalled = true
end

-- Formatiert das Itemlevel so, wie es im Tooltip lesbar wirken soll.
-- Ganze Werte erscheinen ohne Nachkommastelle, gemischte Werte mit einer.
local function FormatItemLevel(itemLevel)
    local numericItemLevel = tonumber(itemLevel)
    if not numericItemLevel or numericItemLevel <= 0 then
        return nil
    end

    if numericItemLevel % 1 == 0 then
        return tostring(math.floor(numericItemLevel + 0.5))
    end

    return string.format("%.1f", numericItemLevel)
end

-- Holt einen Cache-Eintrag nur dann zurück, wenn er noch gültig ist.
-- Abgelaufene Daten werden direkt entfernt, damit der Cache klein bleibt.
local function GetCachedItemLevel(unit)
    local cacheKey = GetInspectCacheKey(unit)
    if not cacheKey then
        return nil
    end

    local cacheEntry = inspectCache[cacheKey]
    if not cacheEntry then
        return nil
    end

    if cacheEntry.expiresAt <= GetNow() then
        inspectCache[cacheKey] = nil
        return nil
    end

    return cacheEntry.itemLevel
end

-- Legt ein erfolgreich ausgelesenes Itemlevel im Cache ab.
-- Ungültige oder leere Werte werden bewusst ignoriert.
local function SetCachedItemLevel(unit, itemLevel)
    local numericItemLevel = tonumber(itemLevel)
    local cacheKey = GetInspectCacheKey(unit)
    if not cacheKey or not numericItemLevel or numericItemLevel <= 0 then
        return
    end

    inspectCache[cacheKey] = {
        itemLevel = numericItemLevel,
        expiresAt = GetNow() + INSPECT_CACHE_TTL,
    }
end

-- Statt vorhandene Tooltip-Texte zu durchsuchen, merken wir uns die einmal
-- erzeugten FontStrings direkt pro Tooltip. Das vermeidet Textvergleiche in
-- geschützten Tooltip-Callbacks und ist damit deutlich Taint-ärmer.
local function GetTooltipItemLevelLine(tooltip)
    if not tooltip then
        return nil, nil
    end

    local lineInfo = tooltipItemLevelLines[tooltip]
    if not lineInfo then
        return nil, nil
    end

    if tooltip.GetName and tooltip.NumLines then
        local tooltipName = tooltip:GetName()
        local lineCount = tooltip:NumLines() or 0
        if tooltipName and lineCount > 0 then
            for lineIndex = 1, lineCount do
                local currentLeftLine = _G[tooltipName .. "TextLeft" .. lineIndex]
                local currentRightLine = _G[tooltipName .. "TextRight" .. lineIndex]
                if currentLeftLine == lineInfo.leftLine and currentRightLine == lineInfo.rightLine then
                    return lineInfo.leftLine, lineInfo.rightLine
                end
            end
        end
    end

    tooltipItemLevelLines[tooltip] = nil

    return nil, nil
end

-- Schreibt die sichtbare Itemlevel-Zeile in den Tooltip.
-- Existiert die Zeile schon, wird sie aktualisiert. Sonst wird sie neu angelegt.
local function SetTooltipItemLevelLine(tooltip, valueText, red, green, blue)
    if not tooltip or not tooltip.AddDoubleLine then
        return
    end

    local leftLine, rightLine = GetTooltipItemLevelLine(tooltip)
    if leftLine and rightLine then
        leftLine:SetText(L("TOOLTIP_ITEMLEVEL_LABEL"))
        leftLine:SetTextColor(1, 0.88, 0.62, 1)
        rightLine:SetText(valueText or "")
        rightLine:SetTextColor(red or 1, green or 1, blue or 1, 1)
        return
    end

    tooltip:AddDoubleLine(
        L("TOOLTIP_ITEMLEVEL_LABEL"),
        valueText or "",
        1, 0.82, 0,
        red or 1, green or 1, blue or 1
    )

    if tooltip.GetName and tooltip.NumLines then
        local tooltipName = tooltip:GetName()
        local lineIndex = tooltip:NumLines()
        if tooltipName and lineIndex and lineIndex > 0 then
            tooltipItemLevelLines[tooltip] = {
                leftLine = _G[tooltipName .. "TextLeft" .. lineIndex],
                rightLine = _G[tooltipName .. "TextRight" .. lineIndex],
            }
        end
    end
end

-- Ermittelt, auf welchen Spieler sich der aktuelle Tooltip bezieht.
-- Die Funktion arbeitet absichtlich konservativ: lieber kein Treffer als Taint.
-- Im sicheren Tooltip-Laufweg bleiben wir komplett bei festen Unit-Tokens.
-- Wir lesen bewusst weder Tooltip-GUIDs noch `tooltip:GetUnit()`, weil Blizzard
-- dort Secret-Strings liefern kann, die wir nicht vergleichen dürfen.
local function ResolveTooltipUnit(tooltip, tooltipData)
    if IsUsablePlayerUnit("mouseover") then
        return "mouseover"
    end

    for _, unit in ipairs(COMMON_UNIT_TOKENS) do
        if IsUsablePlayerUnit(unit) then
            return unit
        end
    end

    return nil
end

-- Setzt den aktuellen Inspect-Zustand komplett zurück.
-- Das ist wichtig, damit keine alte Anfrage später falsche Tooltips verändert.
local function ClearPendingInspect()
    pendingInspectUnit = nil
end

-- Zeigt ein Itemlevel sofort aus dem Cache an.
-- Rückgabewert true bedeutet: Es war kein neuer Inspect mehr nötig.
local function ShowCachedItemLevel(tooltip, unit)
    local cachedItemLevel = GetCachedItemLevel(unit)
    local formattedItemLevel = FormatItemLevel(cachedItemLevel)
    if not formattedItemLevel then
        return false
    end

    SetTooltipItemLevelLine(tooltip, formattedItemLevel, 0.25, 0.85, 0.25)
    tooltip:Show()
    return true
end

-- Startet eine neue Inspect-Anfrage für den Spieler im Tooltip.
-- Hier sitzen fast alle Sicherheitsprüfungen: Feature aktiv, Spieler vorhanden,
-- kein Self-Inspect, in Reichweite und nicht zu schnell hintereinander.
local function RequestInspectForTooltip(tooltip, unit)
    if not Misc.IsTooltipItemLevelEnabled or not Misc.IsTooltipItemLevelEnabled() then
        return
    end

    if not tooltip or not unit or not SafeUnitExists(unit) then
        return
    end

    if not SafeUnitIsPlayer(unit) then
        return
    end

    if SafeUnitIsUnit(unit, "player") then
        return
    end

    if ShowCachedItemLevel(tooltip, unit) then
        return
    end

    if SafeStringsEqual(pendingInspectUnit, unit) then
        SetTooltipItemLevelLine(tooltip, L("TOOLTIP_ITEMLEVEL_LOADING"), 0.8, 0.8, 0.8)
        tooltip:Show()
        return
    end

    if IsBlizzardInspectFrameActive() then
        return
    end

    if not NotifyInspect or not CanInspect or not C_PaperDollInfo or not C_PaperDollInfo.GetInspectItemLevel then
        return
    end

    if not SafeCanInspect(unit) then
        return
    end

    local now = GetNow()
    if now - lastInspectRequestTime < INSPECT_REQUEST_THROTTLE then
        return
    end

    pendingInspectUnit = unit
    lastInspectRequestTime = now

    SafeNotifyInspect(unit)
    SetTooltipItemLevelLine(tooltip, L("TOOLTIP_ITEMLEVEL_LOADING"), 0.8, 0.8, 0.8)
    tooltip:Show()
end

-- Dieses Frame empfängt das Ergebnis einer zuvor gestarteten Inspect-Anfrage.
-- Erst hier kennen wir das echte Itemlevel des inspecteten Spielers.
local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(_, event, inspecteeGUID)
    if event ~= "INSPECT_READY" or not pendingInspectUnit then
        return
    end

    -- GUID-Abgleich erst hier, nie im geschützten Tooltip-Laufweg.
    local pendingUnitGUID = SafeUnitGUID(pendingInspectUnit)
    if pendingUnitGUID and type(inspecteeGUID) == "string" then
        if not SafeStringsEqual(inspecteeGUID, pendingUnitGUID) then
            if ClearInspectPlayer then
                ClearInspectPlayer()
            end
            ClearPendingInspect()
            return
        end
    end

    if IsBlizzardInspectFrameActive() then
        lastInspectRequestTime = GetNow()
        if ClearInspectPlayer then
            ClearInspectPlayer()
        end
        ClearPendingInspect()
        return
    end

    local unit = pendingInspectUnit
    if not unit or not SafeUnitExists(unit) or not C_PaperDollInfo or not C_PaperDollInfo.GetInspectItemLevel then
        ClearPendingInspect()
        return
    end

    local itemLevel = SafeGetInspectItemLevel(unit)
    if itemLevel then
        SetCachedItemLevel(unit, itemLevel)

        -- Nur wenn der Tooltip noch immer denselben Spieler zeigt, schreiben
        -- wir das frisch geladene Itemlevel sichtbar hinein.
        local tooltipUnit = ResolveTooltipUnit(GameTooltip, nil)
        local tooltipCacheKey = GetInspectCacheKey(tooltipUnit)
        local inspectedCacheKey = GetInspectCacheKey(unit)
        if tooltipCacheKey
            and inspectedCacheKey
            and SafeStringsEqual(tooltipCacheKey, inspectedCacheKey)
            and Misc.IsTooltipItemLevelEnabled
            and Misc.IsTooltipItemLevelEnabled() then
            local formattedItemLevel = FormatItemLevel(itemLevel)
            if formattedItemLevel then
                SetTooltipItemLevelLine(GameTooltip, formattedItemLevel, 0.25, 0.85, 0.25)
                GameTooltip:Show()
            end
        end
    end

    if ClearInspectPlayer then
        ClearInspectPlayer()
    end

    ClearPendingInspect()
end)

local function HandleTooltipUnitUpdate(tooltip, tooltipData)
    local unit = ResolveTooltipUnit(tooltip, tooltipData)
    if unit then
        RequestInspectForTooltip(tooltip, unit)
    end
end

-- Retail bietet einen modernen Tooltip-Callback über TooltipDataProcessor.
-- Den nutzen wir zuerst. Der alte Hook bleibt nur als vorsichtiger Fallback.
local inspectSafetyFrame = CreateFrame("Frame")
inspectSafetyFrame:RegisterEvent("PLAYER_LOGIN")
inspectSafetyFrame:RegisterEvent("ADDON_LOADED")
inspectSafetyFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" then
        InstallInspectPVPSafetyHook()
        return
    end

    if event == "ADDON_LOADED" and addonName == "Blizzard_InspectUI" then
        InstallInspectPVPSafetyHook()
    end
end)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, HandleTooltipUnitUpdate)
end

if GameTooltip and GameTooltip.HookScript and GameTooltip.HasScript and GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        HandleTooltipUnitUpdate(tooltip, nil)
    end)
end

if GameTooltip and GameTooltip.HookScript and GameTooltip.HasScript and GameTooltip:HasScript("OnTooltipCleared") then
    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltipItemLevelLines[tooltip] = nil
    end)
end
