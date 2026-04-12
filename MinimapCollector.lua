local ADDON_NAME, BeavisQoL = ...

BeavisQoL.MinimapCollectorModule = BeavisQoL.MinimapCollectorModule or {}

local Module = BeavisQoL.MinimapCollectorModule
local L = BeavisQoL.L
local C_Timer = _G.C_Timer
local legacyGetNumAddOns = rawget(_G, "GetNumAddOns")
local legacyGetAddOnInfo = rawget(_G, "GetAddOnInfo")
local legacyGetAddOnMetadata = rawget(_G, "GetAddOnMetadata")

local LAUNCHER_SIZE = 32
local PANEL_PADDING = 4
local PANEL_SPACING = 2
local PANEL_BUTTON_SIZE = 31
local PANEL_MAX_COLUMNS = 7
local SCAN_INTERVAL_SECONDS = 3
local DEFAULT_POINT = "TOPRIGHT"
local DEFAULT_RELATIVE_POINT = "TOPRIGHT"
local DEFAULT_X = -92
local DEFAULT_Y = -228
local DEFAULT_LAUNCHER_SCALE = 1.05
local DEFAULT_WINDOW_SCALE = 1.05
local MIN_SCALE = 0.85
local MAX_SCALE = 1.40

local LauncherButton
local CollectorPanel
local EmptyText
local CollectedButtonHost
local HiddenButtonHost
local KnownButtons = {}
local OrderedButtonKeys = {}
local ScheduledRefresh = false
local DeferredPageRefresh = false
local LastKnownButtonsSignature = ""
local InstalledAddonEntries
local InstalledAddonByLookup
local GetButtonMode
local ApplyCollectedButtonLayout

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local EXACT_BUTTON_BLACKLIST = {
    AddonCompartmentFrame = true,
    ExpansionLandingPageMinimapButton = true,
    GameTimeFrame = true,
    GarrisonLandingPageMinimapButton = true,
    GuildInstanceDifficulty = true,
    MiniMapBattlefieldFrame = true,
    MiniMapChallengeMode = true,
    MiniMapInstanceDifficulty = true,
    MiniMapMailFrame = true,
    MiniMapTracking = true,
    MiniMapVoiceChatFrame = true,
    MiniMapWorldMapButton = true,
    QueueStatusMinimapButton = true,
    TimeManagerClockButton = true,
}

local BUTTON_NAME_PATTERNS = {
    "^HybridMinimap",
    "^MiniMapBattlefield",
    "^MiniMapCompass",
    "^MiniMapLFG",
    "^MiniMapMail",
    "^MiniMapNorth",
    "^MiniMapPing",
    "^MiniMapRecording",
    "^MiniMapTracking",
    "^MiniMapVoice",
    "^MiniMapWorldMap",
    "^MiniMapZoom",
    "^MinimapBackdrop",
    "^MinimapBorder",
    "^MinimapCluster",
    "^MinimapCompass",
    "^MinimapZoneText",
}

local function GetModuleDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.minimapCollector = BeavisQoLDB.minimapCollector or {}

    local db = BeavisQoLDB.minimapCollector

    if db.enabled == nil then
        db.enabled = true
    end

    if type(db.excludedButtons) ~= "table" then
        db.excludedButtons = {}
    end

    if type(db.hiddenButtons) ~= "table" then
        db.hiddenButtons = {}
    end

    if db.point == nil then
        db.point = DEFAULT_POINT
    end

    if db.relativePoint == nil then
        db.relativePoint = DEFAULT_RELATIVE_POINT
    end

    if db.x == nil then
        db.x = DEFAULT_X
    end

    if db.y == nil then
        db.y = DEFAULT_Y
    end

    local legacyScale = Clamp(tonumber(db.scale) or DEFAULT_WINDOW_SCALE, MIN_SCALE, MAX_SCALE)

    if db.launcherScale == nil then
        db.launcherScale = legacyScale
    end

    if db.windowScale == nil then
        db.windowScale = legacyScale
    end

    return db
end

local function GetLauncherScale()
    return Clamp(GetModuleDB().launcherScale or DEFAULT_LAUNCHER_SCALE, MIN_SCALE, MAX_SCALE)
end

local function GetWindowScale()
    return Clamp(GetModuleDB().windowScale or DEFAULT_WINDOW_SCALE, MIN_SCALE, MAX_SCALE)
end

local function NormalizeLabelText(text)
    if type(text) ~= "string" then
        return nil
    end

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    text = text:gsub("%s+", " ")

    if text == "" then
        return nil
    end

    return text
end

local function NormalizeAddonLookupText(text)
    text = NormalizeLabelText(text)
    if not text then
        return nil
    end

    text = string.lower(text)
    text = text:gsub("[^%w]", "")

    if text == "" then
        return nil
    end

    return text
end

local function BuildLookupAbbreviation(text)
    text = NormalizeLabelText(text)
    if not text then
        return nil
    end

    text = text:gsub("_", " ")
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("(%a)(%d)", "%1 %2")
    text = text:gsub("(%d)(%a)", "%1 %2")

    local abbreviationParts = {}

    for token in text:gmatch("[%w]+") do
        local firstCharacter = token:sub(1, 1)
        if firstCharacter and firstCharacter ~= "" then
            abbreviationParts[#abbreviationParts + 1] = string.lower(firstCharacter)
        end
    end

    local abbreviation = table.concat(abbreviationParts)
    if abbreviation == "" then
        return nil
    end

    return abbreviation
end

local function GetAddOnCount()
    if C_AddOns and C_AddOns.GetNumAddOns then
        return C_AddOns.GetNumAddOns()
    end

    if legacyGetNumAddOns then
        return legacyGetNumAddOns()
    end

    return 0
end

local function GetAddOnInfoCompat(index)
    local getAddOnInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or legacyGetAddOnInfo
    if type(getAddOnInfo) ~= "function" then
        return nil, nil
    end

    local info1, info2 = getAddOnInfo(index)
    if type(info1) == "table" then
        return info1.name or info1.Name, info1.title or info1.Title
    end

    return info1, info2
end

local function GetAddOnMetadataCompat(addonName, metadataKey)
    local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or legacyGetAddOnMetadata
    if type(getAddOnMetadata) ~= "function" or type(addonName) ~= "string" or addonName == "" then
        return nil
    end

    return getAddOnMetadata(addonName, metadataKey)
end

local function EnsureInstalledAddonCache()
    if InstalledAddonEntries and InstalledAddonByLookup then
        return
    end

    InstalledAddonEntries = {}
    InstalledAddonByLookup = {}

    for index = 1, GetAddOnCount() do
        local addonName, addonTitle = GetAddOnInfoCompat(index)

        if type(addonName) == "string" and addonName ~= "" then
            addonTitle = NormalizeLabelText(addonTitle) or NormalizeLabelText(GetAddOnMetadataCompat(addonName, "Title")) or addonName

            local entry = {
                name = addonName,
                title = addonTitle,
                lookupName = NormalizeAddonLookupText(addonName),
                lookupTitle = NormalizeAddonLookupText(addonTitle),
                lookupAbbreviation = BuildLookupAbbreviation(addonTitle) or BuildLookupAbbreviation(addonName),
            }

            InstalledAddonEntries[#InstalledAddonEntries + 1] = entry

            if entry.lookupName and not InstalledAddonByLookup[entry.lookupName] then
                InstalledAddonByLookup[entry.lookupName] = entry
            end

            if entry.lookupTitle and not InstalledAddonByLookup[entry.lookupTitle] then
                InstalledAddonByLookup[entry.lookupTitle] = entry
            end

            if entry.lookupAbbreviation and #entry.lookupAbbreviation >= 2 and not InstalledAddonByLookup[entry.lookupAbbreviation] then
                InstalledAddonByLookup[entry.lookupAbbreviation] = entry
            end
        end
    end

    table.sort(InstalledAddonEntries, function(leftEntry, rightEntry)
        local leftLength = math.max(
            #(leftEntry.lookupName or ""),
            #(leftEntry.lookupTitle or "")
        )
        local rightLength = math.max(
            #(rightEntry.lookupName or ""),
            #(rightEntry.lookupTitle or "")
        )

        if leftLength == rightLength then
            return string.lower(leftEntry.title or leftEntry.name or "") < string.lower(rightEntry.title or rightEntry.name or "")
        end

        return leftLength > rightLength
    end)
end

local function GetButtonKey(button)
    if not button then
        return nil
    end

    local name = button.GetName and button:GetName() or nil
    if type(name) == "string" and name ~= "" then
        return name
    end

    local dataObject = button.dataObject
    if type(dataObject) == "table" and type(dataObject.text) == "string" and dataObject.text ~= "" then
        return "LDB:" .. dataObject.text
    end

    return nil
end

local function AddUniqueCandidate(targetTable, seenTable, value)
    local normalizedValue = NormalizeLabelText(value)
    if not normalizedValue then
        return
    end

    local lookupValue = NormalizeAddonLookupText(normalizedValue)
    if not lookupValue or seenTable[lookupValue] then
        return
    end

    seenTable[lookupValue] = true
    targetTable[#targetTable + 1] = normalizedValue
end

local function BuildExplicitAddonCandidates(button, buttonKey)
    local dataObject = button and button.dataObject or nil
    local candidates = {}
    local seenCandidates = {}

    AddUniqueCandidate(candidates, seenCandidates, dataObject and dataObject.tocname or nil)
    AddUniqueCandidate(candidates, seenCandidates, dataObject and dataObject.addonName or nil)
    AddUniqueCandidate(candidates, seenCandidates, dataObject and dataObject.name or nil)
    AddUniqueCandidate(candidates, seenCandidates, dataObject and dataObject.label or nil)
    AddUniqueCandidate(candidates, seenCandidates, dataObject and dataObject.text or nil)
    AddUniqueCandidate(candidates, seenCandidates, buttonKey)

    if type(buttonKey) == "string" and buttonKey ~= "" then
        local cleanedKey = buttonKey
        cleanedKey = cleanedKey:gsub("^LibDBIcon10_", "")
        cleanedKey = cleanedKey:gsub("MinimapButton$", "")
        cleanedKey = cleanedKey:gsub("MiniMapButton$", "")
        cleanedKey = cleanedKey:gsub("MinimapIcon$", "")
        cleanedKey = cleanedKey:gsub("MiniMapIcon$", "")
        cleanedKey = cleanedKey:gsub("Launcher$", "")
        cleanedKey = cleanedKey:gsub("Button$", "")
        AddUniqueCandidate(candidates, seenCandidates, cleanedKey)
    end

    return candidates
end

local function FindInstalledAddonEntry(candidateText)
    EnsureInstalledAddonCache()

    local candidateLookup = NormalizeAddonLookupText(candidateText)
    if not candidateLookup or #candidateLookup < 2 then
        return nil
    end

    local exactMatch = InstalledAddonByLookup and InstalledAddonByLookup[candidateLookup] or nil
    if exactMatch then
        return exactMatch
    end

    for _, addonEntry in ipairs(InstalledAddonEntries or {}) do
        if addonEntry.lookupName and #addonEntry.lookupName >= 3 and string.find(candidateLookup, addonEntry.lookupName, 1, true) then
            return addonEntry
        end

        if addonEntry.lookupTitle and #addonEntry.lookupTitle >= 3 and string.find(candidateLookup, addonEntry.lookupTitle, 1, true) then
            return addonEntry
        end

        if addonEntry.lookupAbbreviation and candidateLookup == addonEntry.lookupAbbreviation then
            return addonEntry
        end
    end

    return nil
end

local function ResolveInstalledAddonEntry(button, buttonKey)
    for _, candidateText in ipairs(BuildExplicitAddonCandidates(button, buttonKey)) do
        local addonEntry = FindInstalledAddonEntry(candidateText)
        if addonEntry then
            return addonEntry
        end
    end

    return nil
end

local function CleanFallbackLabel(label)
    label = NormalizeLabelText(label)
    if not label then
        return nil
    end

    label = label:gsub("^LibDBIcon10_", "")
    label = label:gsub("^LDB:", "")
    label = label:gsub("MinimapButton$", "")
    label = label:gsub("MiniMapButton$", "")
    label = label:gsub("MinimapIcon$", "")
    label = label:gsub("MiniMapIcon$", "")
    label = label:gsub("Launcher$", "")
    label = label:gsub("Button$", "")
    label = label:gsub("_", " ")
    label = label:gsub("(%l)(%u)", "%1 %2")
    label = label:gsub("(%a)(%d)", "%1 %2")
    label = label:gsub("(%d)(%a)", "%1 %2")
    label = NormalizeLabelText(label)

    if not label or label:match("^%d+$") then
        return nil
    end

    local loweredLabel = string.lower(label)
    if loweredLabel == "icon" or loweredLabel == "launcher" or loweredLabel == "button" then
        return nil
    end

    return label
end

local function BuildButtonLabel(button, buttonKey)
    if not button then
        return buttonKey or L("UNKNOWN")
    end

    local addonEntry = ResolveInstalledAddonEntry(button, buttonKey)
    if addonEntry and addonEntry.title then
        return addonEntry.title
    end

    local dataObject = button.dataObject
    local candidates = {
        dataObject and dataObject.label or nil,
        dataObject and dataObject.text or nil,
        button.tooltipText,
        button.title,
        buttonKey,
    }

    for _, candidate in ipairs(candidates) do
        local label = CleanFallbackLabel(candidate)
        if label then
            return label
        end
    end

    return L("UNKNOWN")
end

local function CapturePoints(frame)
    local points = {}

    if not frame or not frame.GetNumPoints then
        return points
    end

    for index = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(index)
        points[#points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = offsetX,
            y = offsetY,
        }
    end

    return points
end

local function RestorePoints(frame, points, fallbackParent)
    if not frame then
        return
    end

    frame:ClearAllPoints()

    if type(points) ~= "table" or #points == 0 then
        frame:SetPoint("CENTER", fallbackParent or UIParent, "CENTER", 0, 0)
        return
    end

    for _, pointInfo in ipairs(points) do
        if pointInfo.relativeTo then
            frame:SetPoint(
                pointInfo.point or "CENTER",
                pointInfo.relativeTo,
                pointInfo.relativePoint or pointInfo.point or "CENTER",
                pointInfo.x or 0,
                pointInfo.y or 0
            )
        else
            frame:SetPoint(pointInfo.point or "CENTER", pointInfo.x or 0, pointInfo.y or 0)
        end
    end
end

local function IsBlacklistedButtonName(buttonKey)
    if type(buttonKey) ~= "string" or buttonKey == "" then
        return true
    end

    if EXACT_BUTTON_BLACKLIST[buttonKey] then
        return true
    end

    for _, pattern in ipairs(BUTTON_NAME_PATTERNS) do
        if string.find(buttonKey, pattern) then
            return true
        end
    end

    return false
end

local function IsCollectibleMinimapButton(button)
    if not button or button == LauncherButton or button == CollectorPanel then
        return false
    end

    if not button.IsObjectType or not button:IsObjectType("Button") then
        return false
    end

    local buttonKey = GetButtonKey(button)
    if not buttonKey or IsBlacklistedButtonName(buttonKey) then
        return false
    end

    local width = button.GetWidth and button:GetWidth() or 0
    local height = button.GetHeight and button:GetHeight() or 0
    if width < 12 or height < 12 or width > 80 or height > 80 then
        return false
    end

    local lowerKey = string.lower(buttonKey)
    if string.find(lowerKey, "libdbicon10_", 1, true) then
        return true
    end

    if string.find(lowerKey, "minimap", 1, true) or string.find(lowerKey, "mini_map", 1, true) then
        return true
    end

    if type(button.dataObject) == "table" then
        return true
    end

    return false
end

local function SortKnownButtons()
    wipe(OrderedButtonKeys)

    for buttonKey in pairs(KnownButtons) do
        OrderedButtonKeys[#OrderedButtonKeys + 1] = buttonKey
    end

    table.sort(OrderedButtonKeys, function(leftKey, rightKey)
        local leftEntry = KnownButtons[leftKey]
        local rightEntry = KnownButtons[rightKey]
        local leftLabel = string.lower(leftEntry and leftEntry.label or leftKey)
        local rightLabel = string.lower(rightEntry and rightEntry.label or rightKey)

        if leftLabel == rightLabel then
            return leftKey < rightKey
        end

        return leftLabel < rightLabel
    end)
end

local function BuildButtonsSignature()
    local parts = {}

    for _, buttonKey in ipairs(OrderedButtonKeys) do
        local entry = KnownButtons[buttonKey]
        local label = entry and entry.label or buttonKey
        parts[#parts + 1] = buttonKey .. "=" .. tostring(label) .. ":" .. GetButtonMode(buttonKey)
    end

    return table.concat(parts, "|")
end

local function NotifyPageStateChanged(forceRefresh)
    local currentSignature = BuildButtonsSignature()

    if not forceRefresh and currentSignature == LastKnownButtonsSignature then
        return
    end

    LastKnownButtonsSignature = currentSignature

    local page = BeavisQoL.Pages and BeavisQoL.Pages.MinimapCollector
    if page and page.RefreshState then
        page:RefreshState()
    elseif BeavisQoL.UpdateMinimapCollectorPage then
        BeavisQoL.UpdateMinimapCollectorPage()
    end
end

local function IsEnabled()
    return GetModuleDB().enabled == true
end

GetButtonMode = function(buttonKey)
    local db = GetModuleDB()

    if db.hiddenButtons[buttonKey] == true then
        return "hidden"
    end

    if db.excludedButtons[buttonKey] == true then
        return "visible"
    end

    return "collector"
end

local function IsButtonEnabled(buttonKey)
    return GetButtonMode(buttonKey) == "collector"
end

local function UpdateCollectorAnchor()
    if not CollectorPanel or not LauncherButton then
        return
    end

    CollectorPanel:ClearAllPoints()

    local buttonCenterX, buttonCenterY = LauncherButton:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()

    local horizontalSide = (buttonCenterX and uiCenterX and buttonCenterX < uiCenterX) and "LEFT" or "RIGHT"
    local verticalSide = (buttonCenterY and uiCenterY and buttonCenterY < uiCenterY) and "BOTTOM" or "TOP"
    local point = verticalSide .. horizontalSide
    local relativePoint = (verticalSide == "TOP" and "BOTTOM" or "TOP") .. horizontalSide
    local offsetX = horizontalSide == "LEFT" and 0 or 0
    local offsetY = verticalSide == "TOP" and -4 or 4

    CollectorPanel:SetPoint(point, LauncherButton, relativePoint, offsetX, offsetY)
end

local function LayoutCollectorPanel()
    if not CollectorPanel or not EmptyText then
        return
    end

    local visibleEntries = {}
    local maxButtonWidth = PANEL_BUTTON_SIZE
    local maxButtonHeight = PANEL_BUTTON_SIZE

    for _, buttonKey in ipairs(OrderedButtonKeys) do
        local entry = KnownButtons[buttonKey]
        local button = entry and entry.button or nil

        if entry and entry.collected and button and (not button.IsShown or button:IsShown()) then
            visibleEntries[#visibleEntries + 1] = entry
            maxButtonWidth = math.max(maxButtonWidth, math.ceil(button:GetWidth() or PANEL_BUTTON_SIZE))
            maxButtonHeight = math.max(maxButtonHeight, math.ceil(button:GetHeight() or PANEL_BUTTON_SIZE))
        end
    end

    UpdateCollectorAnchor()

    if #visibleEntries == 0 then
        EmptyText:SetText(L("MINIMAP_COLLECTOR_EMPTY"))
        EmptyText:Show()
        CollectorPanel:SetSize(136, 36)
        return
    end

    EmptyText:Hide()

    local columns = math.min(PANEL_MAX_COLUMNS, math.max(1, #visibleEntries))
    local rows = math.ceil(#visibleEntries / columns)
    local cellWidth = maxButtonWidth + PANEL_SPACING
    local cellHeight = maxButtonHeight + PANEL_SPACING

    for index, entry in ipairs(visibleEntries) do
        local columnIndex = (index - 1) % columns
        local rowIndex = math.floor((index - 1) / columns)

        entry.collectorOffsetX = PANEL_PADDING + (columnIndex * cellWidth)
        entry.collectorOffsetY = -PANEL_PADDING - (rowIndex * cellHeight)
        ApplyCollectedButtonLayout(entry)
    end

    local panelWidth = (PANEL_PADDING * 2)
        + (columns * maxButtonWidth)
        + ((columns - 1) * PANEL_SPACING)
    local panelHeight = (PANEL_PADDING * 2)
        + (rows * maxButtonHeight)
        + ((rows - 1) * PANEL_SPACING)

    CollectorPanel:SetSize(panelWidth, panelHeight)
end

local function ApplyCollectorScale()
    if LauncherButton then
        LauncherButton:SetScale(GetLauncherScale())
    end

    if CollectorPanel then
        CollectorPanel:SetScale(GetWindowScale())
    end

    UpdateCollectorAnchor()

    for _, entry in pairs(KnownButtons) do
        if entry and entry.collected then
            local button = entry.button
            if button and button.SetScale then
                button:SetScale(GetWindowScale())
            end
        end
    end
end

local function EnsureCollectedButtonHost()
    if CollectedButtonHost then
        return
    end

    local host = CreateFrame("Frame", "BeavisQoLMinimapCollectorButtonHost", UIParent)
    host:SetAllPoints(UIParent)
    host:SetFrameStrata("HIGH")
    host:SetFrameLevel(15)
    host:Hide()

    CollectedButtonHost = host
end

local function UpdateCollectedButtonHostVisibility()
    if not CollectedButtonHost then
        return
    end

    if CollectorPanel and CollectorPanel:IsShown() and IsEnabled() then
        CollectedButtonHost:Show()
        return
    end

    CollectedButtonHost:Hide()
end

local function EnsureHiddenButtonHost()
    if HiddenButtonHost then
        return
    end

    local host = CreateFrame("Frame", "BeavisQoLMinimapCollectorHiddenHost", UIParent)
    host:SetSize(1, 1)
    host:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    host:SetFrameStrata("BACKGROUND")
    host:SetFrameLevel(1)
    host:Hide()

    HiddenButtonHost = host
end

local function CaptureOriginalButtonState(entry)
    local button = entry and entry.button
    if not button then
        return
    end

    entry.originalParent = button:GetParent()
    entry.originalPoints = CapturePoints(button)
    entry.originalFrameStrata = button:GetFrameStrata()
    entry.originalFrameLevel = button:GetFrameLevel()
    entry.originalScale = button.GetScale and button:GetScale() or nil
end

ApplyCollectedButtonLayout = function(entry)
    local button = entry and entry.button
    if not button or not CollectorPanel or not CollectedButtonHost then
        return
    end

    local offsetX = tonumber(entry.collectorOffsetX)
    local offsetY = tonumber(entry.collectorOffsetY)
    if not offsetX or not offsetY then
        return
    end

    entry.isApplyingCollectorLayout = true

    if button:GetParent() ~= CollectedButtonHost then
        button:SetParent(CollectedButtonHost)
    end

    button:Show()
    button:SetFrameStrata(CollectorPanel:GetFrameStrata())
    button:SetFrameLevel(CollectorPanel:GetFrameLevel() + 10)

    if button.SetScale then
        button:SetScale(GetWindowScale())
    end

    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", CollectorPanel, "TOPLEFT", offsetX, offsetY)

    entry.isApplyingCollectorLayout = false
end

local function ScheduleCollectedButtonLayout(entry)
    if not entry or entry.collectorLayoutScheduled then
        return
    end

    entry.collectorLayoutScheduled = true

    local function ApplyDeferredLayout()
        entry.collectorLayoutScheduled = false

        if entry.collected then
            ApplyCollectedButtonLayout(entry)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyDeferredLayout)
        return
    end

    ApplyDeferredLayout()
end

local function EnsureCollectedButtonHooks(entry)
    local button = entry and entry.button
    if not button or entry.collectorHookedButton == button or not hooksecurefunc then
        return
    end

    entry.collectorHookedButton = button

    hooksecurefunc(button, "SetPoint", function()
        if entry.isApplyingCollectorLayout or not entry.collected then
            return
        end

        ScheduleCollectedButtonLayout(entry)
    end)

    hooksecurefunc(button, "SetParent", function()
        if entry.isApplyingCollectorLayout or not entry.collected then
            return
        end

        ScheduleCollectedButtonLayout(entry)
    end)
end

local function CollectButton(entry)
    local button = entry and entry.button
    if not button or not CollectorPanel or not CollectedButtonHost then
        return
    end

    EnsureCollectedButtonHooks(entry)

    if button:GetParent() ~= CollectedButtonHost then
        if button:GetParent() ~= HiddenButtonHost then
            CaptureOriginalButtonState(entry)
        end
        button:SetParent(CollectedButtonHost)
    end

    entry.collected = true
    entry.hidden = false

    ApplyCollectedButtonLayout(entry)
end

local function HideButton(entry)
    local button = entry and entry.button
    if not button or not HiddenButtonHost then
        return
    end

    if button:GetParent() ~= HiddenButtonHost then
        if button:GetParent() ~= CollectedButtonHost then
            CaptureOriginalButtonState(entry)
        end
        button:SetParent(HiddenButtonHost)
    end

    button:SetFrameStrata(HiddenButtonHost:GetFrameStrata())
    button:SetFrameLevel(HiddenButtonHost:GetFrameLevel() + 10)
    button:Hide()
    entry.hidden = true
    entry.collected = false
end

local function RestoreButton(entry)
    local button = entry and entry.button
    if not button or (entry.collected ~= true and entry.hidden ~= true) then
        return
    end

    local parent = entry.originalParent or Minimap or UIParent

    button:SetParent(parent)

    if entry.originalFrameStrata then
        button:SetFrameStrata(entry.originalFrameStrata)
    end

    if entry.originalFrameLevel then
        button:SetFrameLevel(entry.originalFrameLevel)
    end

    if entry.originalScale and button.SetScale then
        button:SetScale(entry.originalScale)
    end

    RestorePoints(button, entry.originalPoints, parent)
    button:Show()
    entry.collected = false
    entry.hidden = false
    entry.collectorOffsetX = nil
    entry.collectorOffsetY = nil
    entry.collectorLayoutScheduled = false
end

local function RestoreAllButtons()
    for _, entry in pairs(KnownButtons) do
        RestoreButton(entry)
    end
end

local function GetCandidateParents()
    local parents = {}
    local seenParents = {}

    local function AddParent(frame)
        if not frame or seenParents[frame] then
            return
        end

        seenParents[frame] = true
        parents[#parents + 1] = frame
    end

    AddParent(_G.Minimap)
    AddParent(_G.MinimapBackdrop)
    AddParent(_G.MinimapCluster)

    return parents
end

local function ScanForButtons()
    local discoveredChange = false
    local seenButtons = {}

    for _, parent in ipairs(GetCandidateParents()) do
        local children = { parent:GetChildren() }

        for _, child in ipairs(children) do
            if child and not seenButtons[child] and IsCollectibleMinimapButton(child) then
                seenButtons[child] = true

                local buttonKey = GetButtonKey(child)
                if buttonKey then
                    local label = BuildButtonLabel(child, buttonKey)
                    local entry = KnownButtons[buttonKey]

                    if not entry then
                        entry = {
                            button = child,
                            collected = false,
                            key = buttonKey,
                            label = label,
                        }
                        KnownButtons[buttonKey] = entry
                        discoveredChange = true
                    else
                        if entry.button ~= child then
                            entry.button = child
                        end

                        if entry.label ~= label then
                            entry.label = label
                            discoveredChange = true
                        end
                    end
                end
            end
        end
    end

    if discoveredChange then
        SortKnownButtons()
    end

    return discoveredChange
end

local function RefreshCollector(forcePageRefresh)
    ScheduledRefresh = false

    if InCombatLockdown and InCombatLockdown() then
        DeferredPageRefresh = DeferredPageRefresh or forcePageRefresh == true
        return
    end

    DeferredPageRefresh = false

    if not IsEnabled() then
        if CollectorPanel then
            CollectorPanel:Hide()
        end

        RestoreAllButtons()
        NotifyPageStateChanged(forcePageRefresh == true)
        return
    end

    local discoveredChange = ScanForButtons()

    for _, buttonKey in ipairs(OrderedButtonKeys) do
        local entry = KnownButtons[buttonKey]

        if entry then
            local buttonMode = GetButtonMode(buttonKey)

            if buttonMode == "collector" then
                CollectButton(entry)
            elseif buttonMode == "hidden" then
                HideButton(entry)
            else
                RestoreButton(entry)
            end
        end
    end

    if CollectorPanel and CollectorPanel:IsShown() then
        LayoutCollectorPanel()
    end

    NotifyPageStateChanged(forcePageRefresh == true or discoveredChange)
end

local function ScheduleCollectorRefresh(forcePageRefresh)
    DeferredPageRefresh = DeferredPageRefresh or forcePageRefresh == true

    if ScheduledRefresh then
        return
    end

    ScheduledRefresh = true

    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function()
            RefreshCollector(DeferredPageRefresh)
        end)
        return
    end

    RefreshCollector(DeferredPageRefresh)
end

local function SaveLauncherPosition()
    if not LauncherButton then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = LauncherButton:GetPoint(1)
    local db = GetModuleDB()
    db.point = point or DEFAULT_POINT
    db.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    db.x = offsetX or DEFAULT_X
    db.y = offsetY or DEFAULT_Y
end

local function ApplyLauncherPosition()
    if not LauncherButton then
        return
    end

    local db = GetModuleDB()
    LauncherButton:ClearAllPoints()
    LauncherButton:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
    ApplyCollectorScale()
    UpdateCollectorAnchor()
end

local function ApplyLauncherVisual(hovered)
    if not LauncherButton then
        return
    end

    if LauncherButton.Icon then
        LauncherButton.Icon:SetAlpha(hovered and 1 or 0.96)
    end

    if LauncherButton.Shadow then
        LauncherButton.Shadow:SetAlpha(hovered and 0.46 or 0.32)
    end
end

local function ToggleCollectorPanel()
    if not CollectorPanel then
        return
    end

    if CollectorPanel:IsShown() then
        CollectorPanel:Hide()
        return
    end

    CollectorPanel:Show()
    ScheduleCollectorRefresh(false)
    LayoutCollectorPanel()
end

local function CreateLauncher()
    if LauncherButton then
        return
    end

    local button = CreateFrame("Button", "BeavisQoLMinimapCollectorLauncher", UIParent)
    button:SetSize(LAUNCHER_SIZE + 4, LAUNCHER_SIZE + 4)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(20)

    local shadow = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetPoint("CENTER")
    shadow:SetSize(LAUNCHER_SIZE + 8, LAUNCHER_SIZE + 8)
    shadow:SetTexture(136467)
    shadow:SetVertexColor(0, 0, 0, 0.32)
    button.Shadow = shadow

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetPoint("CENTER")
    icon:SetSize(LAUNCHER_SIZE + 2, LAUNCHER_SIZE + 2)
    icon:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\launcher-logo.tga")
    button.Icon = icon

    button:SetScript("OnEnter", function(self)
        ApplyLauncherVisual(true)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("MINIMAP_COLLECTOR"), 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L("MINIMAP_COLLECTOR_LAUNCHER_CLICK"), 1, 1, 1)
        GameTooltip:AddLine(L("MINIMAP_COLLECTOR_LAUNCHER_RELOAD"), 1, 1, 1)
        GameTooltip:AddLine(L("MINIMAP_COLLECTOR_LAUNCHER_MENU"), 1, 1, 1)
        GameTooltip:AddLine(L("MINIMAP_COLLECTOR_LAUNCHER_DRAG"), 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        ApplyLauncherVisual(false)
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if self.JustDragged then
            return
        end

        if mouseButton == "LeftButton" and IsShiftKeyDown() then
            ReloadUI()
            return
        end

        if mouseButton == "RightButton" then
            if SlashCmdList and SlashCmdList["BEAVIS"] then
                SlashCmdList["BEAVIS"]("")
            elseif BeavisQoL.Frame then
                if BeavisQoL.Frame:IsShown() then
                    BeavisQoL.Frame:Hide()
                else
                    BeavisQoL.Frame:Show()
                end
            end
            return
        end

        if mouseButton ~= "LeftButton" then
            return
        end

        ToggleCollectorPanel()
    end)

    button:SetScript("OnDragStart", function(self)
        self.JustDragged = false
        self:StartMoving()
    end)

    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.JustDragged = true
        SaveLauncherPosition()
        UpdateCollectorAnchor()

        if C_Timer and C_Timer.After then
            C_Timer.After(0.05, function()
                if self then
                    self.JustDragged = false
                end
            end)
        else
            self.JustDragged = false
        end
    end)

    LauncherButton = button
    ApplyLauncherVisual(false)
    ApplyLauncherPosition()
    ApplyCollectorScale()
end

local function EnsureCollectorPanel()
    if CollectorPanel or not LauncherButton then
        return
    end

    local panel = CreateFrame("Frame", "BeavisQoLMinimapCollectorPanel", LauncherButton)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(LauncherButton:GetFrameLevel() + 5)
    panel:Hide()
    panel:SetScript("OnShow", UpdateCollectedButtonHostVisibility)
    panel:SetScript("OnHide", UpdateCollectedButtonHostVisibility)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.44)

    local topGlow = panel:CreateTexture(nil, "BORDER")
    topGlow:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    topGlow:SetHeight(10)
    topGlow:SetColorTexture(1, 0.82, 0, 0.05)

    local topBorder = panel:CreateTexture(nil, "ARTWORK")
    topBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(1, 0.82, 0, 0.24)

    local bottomBorder = panel:CreateTexture(nil, "ARTWORK")
    bottomBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(1, 0.82, 0, 0.24)

    local leftBorder = panel:CreateTexture(nil, "ARTWORK")
    leftBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    leftBorder:SetWidth(1)
    leftBorder:SetColorTexture(1, 0.82, 0, 0.24)

    local rightBorder = panel:CreateTexture(nil, "ARTWORK")
    rightBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(1)
    rightBorder:SetColorTexture(1, 0.82, 0, 0.24)

    local emptyText = panel:CreateFontString(nil, "OVERLAY")
    emptyText:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, -PANEL_PADDING)
    emptyText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PANEL_PADDING, PANEL_PADDING)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetJustifyV("MIDDLE")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    emptyText:SetTextColor(0.92, 0.92, 0.95, 1)
    emptyText:SetText(L("MINIMAP_COLLECTOR_EMPTY"))

    CollectorPanel = panel
    EmptyText = emptyText

    if UISpecialFrames then
        local alreadyRegistered = false

        for _, frameName in ipairs(UISpecialFrames) do
            if frameName == "BeavisQoLMinimapCollectorPanel" then
                alreadyRegistered = true
                break
            end
        end

        if not alreadyRegistered then
            table.insert(UISpecialFrames, "BeavisQoLMinimapCollectorPanel")
        end
    end

    UpdateCollectorAnchor()
    LayoutCollectorPanel()
end

local function UpdateLauncherVisibility()
    if not LauncherButton then
        return
    end

    if IsEnabled() then
        LauncherButton:Show()
        UpdateCollectedButtonHostVisibility()
        return
    end

    if CollectorPanel then
        CollectorPanel:Hide()
    end

    LauncherButton:Hide()
    UpdateCollectedButtonHostVisibility()
end

function Module.GetButtons()
    local buttons = {}

    for _, buttonKey in ipairs(OrderedButtonKeys) do
        local entry = KnownButtons[buttonKey]

        if entry then
            buttons[#buttons + 1] = {
                key = buttonKey,
                label = entry.label or buttonKey,
                enabled = IsButtonEnabled(buttonKey),
                collected = entry.collected == true,
                mode = GetButtonMode(buttonKey),
            }
        end
    end

    return buttons
end

function Module.IsEnabled()
    return IsEnabled()
end

function Module.SetEnabled(enabled)
    GetModuleDB().enabled = enabled == true
    UpdateLauncherVisibility()
    ScheduleCollectorRefresh(true)
    NotifyPageStateChanged(true)
end

function Module.GetScale()
    return GetWindowScale()
end

function Module.SetScale(scale)
    local clampedScale = Clamp(tonumber(scale) or DEFAULT_WINDOW_SCALE, MIN_SCALE, MAX_SCALE)
    local db = GetModuleDB()
    db.launcherScale = clampedScale
    db.windowScale = clampedScale
    ApplyCollectorScale()
    LayoutCollectorPanel()
    NotifyPageStateChanged(true)
end

function Module.GetLauncherScale()
    return GetLauncherScale()
end

function Module.SetLauncherScale(scale)
    GetModuleDB().launcherScale = Clamp(tonumber(scale) or DEFAULT_LAUNCHER_SCALE, MIN_SCALE, MAX_SCALE)
    ApplyCollectorScale()
    NotifyPageStateChanged(true)
end

function Module.GetWindowScale()
    return GetWindowScale()
end

function Module.SetWindowScale(scale)
    GetModuleDB().windowScale = Clamp(tonumber(scale) or DEFAULT_WINDOW_SCALE, MIN_SCALE, MAX_SCALE)
    ApplyCollectorScale()
    LayoutCollectorPanel()
    NotifyPageStateChanged(true)
end

function Module.IsButtonEnabled(buttonKey)
    return IsButtonEnabled(buttonKey)
end

function Module.SetButtonEnabled(buttonKey, enabled)
    if type(buttonKey) ~= "string" or buttonKey == "" then
        return
    end

    Module.SetButtonMode(buttonKey, enabled == false and "visible" or "collector")
end

function Module.GetButtonMode(buttonKey)
    if type(buttonKey) ~= "string" or buttonKey == "" then
        return "collector"
    end

    return GetButtonMode(buttonKey)
end

function Module.SetButtonMode(buttonKey, mode)
    if type(buttonKey) ~= "string" or buttonKey == "" then
        return
    end

    local db = GetModuleDB()
    local normalizedMode = mode

    if normalizedMode ~= "collector" and normalizedMode ~= "visible" and normalizedMode ~= "hidden" then
        normalizedMode = "collector"
    end

    db.excludedButtons[buttonKey] = normalizedMode == "visible" and true or nil
    db.hiddenButtons[buttonKey] = normalizedMode == "hidden" and true or nil

    ScheduleCollectorRefresh(true)
    NotifyPageStateChanged(true)
end

function Module.ResetPosition()
    local db = GetModuleDB()
    db.point = DEFAULT_POINT
    db.relativePoint = DEFAULT_RELATIVE_POINT
    db.x = DEFAULT_X
    db.y = DEFAULT_Y

    ApplyLauncherPosition()
end

function Module.Refresh(forcePageRefresh)
    ScheduleCollectorRefresh(forcePageRefresh == true)
end

function Module.TogglePanel()
    ToggleCollectorPanel()
end

local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("ADDON_LOADED")
startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
startupFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
startupFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= ADDON_NAME then
        return
    end

    CreateLauncher()
    EnsureCollectorPanel()
    EnsureCollectedButtonHost()
    EnsureHiddenButtonHost()
    UpdateLauncherVisibility()
    ScheduleCollectorRefresh(true)
end)

CreateLauncher()
EnsureCollectorPanel()
EnsureCollectedButtonHost()
EnsureHiddenButtonHost()
UpdateLauncherVisibility()
ApplyCollectorScale()

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(SCAN_INTERVAL_SECONDS, function()
        ScheduleCollectorRefresh(false)
    end)
end

BeavisQoL.GetMinimapCollectorButtons = function()
    return Module.GetButtons()
end

BeavisQoL.IsMinimapCollectorEnabled = function()
    return Module.IsEnabled()
end

BeavisQoL.SetMinimapCollectorEnabled = function(enabled)
    Module.SetEnabled(enabled)
end

BeavisQoL.GetMinimapCollectorScale = function()
    return Module.GetScale()
end

BeavisQoL.SetMinimapCollectorScale = function(scale)
    Module.SetScale(scale)
end

BeavisQoL.GetMinimapCollectorLauncherScale = function()
    return Module.GetLauncherScale()
end

BeavisQoL.SetMinimapCollectorLauncherScale = function(scale)
    Module.SetLauncherScale(scale)
end

BeavisQoL.GetMinimapCollectorWindowScale = function()
    return Module.GetWindowScale()
end

BeavisQoL.SetMinimapCollectorWindowScale = function(scale)
    Module.SetWindowScale(scale)
end

BeavisQoL.IsMinimapCollectorButtonEnabled = function(buttonKey)
    return Module.IsButtonEnabled(buttonKey)
end

BeavisQoL.SetMinimapCollectorButtonEnabled = function(buttonKey, enabled)
    Module.SetButtonEnabled(buttonKey, enabled)
end

BeavisQoL.GetMinimapCollectorButtonMode = function(buttonKey)
    return Module.GetButtonMode(buttonKey)
end

BeavisQoL.SetMinimapCollectorButtonMode = function(buttonKey, mode)
    Module.SetButtonMode(buttonKey, mode)
end

BeavisQoL.ResetMinimapCollectorPosition = function()
    Module.ResetPosition()
end

BeavisQoL.RefreshMinimapCollector = function(forcePageRefresh)
    Module.Refresh(forcePageRefresh)
end
