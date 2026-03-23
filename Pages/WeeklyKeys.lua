local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.WeeklyKeysModule = BeavisQoL.WeeklyKeysModule or {}
local WeeklyKeysModule = BeavisQoL.WeeklyKeysModule

--[[
WeeklyKeys.lua sammelt zwei Datenquellen und macht daraus eine einzige Anzeige:

1. Mythic-Plus-Laufhistorie
2. Weekly-Vault-Aktivitäten für die Belohnungsstufen 1 / 4 / 8

Das Ergebnis landet sowohl in einer Vorschau auf der Modulseite als auch in
einem frei verschiebbaren Overlay.
]]

local LEGACY_DEFAULT_FONT_SIZE = 12
local DEFAULT_FONT_SIZE = 10
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 16
local DEFAULT_OVERLAY_SCALE = 0.90
local MIN_OVERLAY_SCALE = 0.70
local MAX_OVERLAY_SCALE = 1.40
local DEFAULT_BACKGROUND_ALPHA = 0.18
local MIN_BACKGROUND_ALPHA = 0.05
local MAX_BACKGROUND_ALPHA = 0.40
local DEFAULT_POINT = "BOTTOMRIGHT"
local DEFAULT_RELATIVE_POINT = "BOTTOMRIGHT"
local DEFAULT_OFFSET_X = -86
local DEFAULT_OFFSET_Y = 420
local BASE_OVERLAY_WIDTH = 344
local REFRESH_INTERVAL = 0.35
local TRACKED_DUNGEON_CONTEXT_TTL = 20
local MAX_TRACKED_DUNGEON_RUNS = 40
local DIM_COLOR = { 0.60, 0.60, 0.64 }
local TEXT_COLOR = { 0.96, 0.96, 0.96 }
local GOLD_COLOR = { 1.00, 0.82, 0.00 }
local SLOT_COLORS = {
    [1] = { 1.00, 0.56, 0.12 },
    [4] = { 0.28, 0.66, 1.00 },
    [8] = { 0.24, 0.90, 0.34 },
}

local sliderCounter = 0
local isRefreshing = false

local PageWeeklyKeys
local OverlayFrame
local OverlayRows = {}
local PreviewRows = {}

local ShowOverlayCheckbox
local LockOverlayCheckbox
local FontSizeSlider
local ScaleSlider
local BackgroundAlphaSlider

local trackedDungeonContext = {
    key = nil,
    name = nil,
    instanceID = 0,
    difficultyID = 0,
    difficultyLabel = nil,
    difficultyCategory = nil,
    enteredAt = 0,
    lastSeenAt = 0,
    completionLogged = false,
    isActive = false,
}

local PreviewCard
local PreviewBackground
local PreviewGlow
local PreviewAccent
local PreviewTitle
local PreviewSummary

local OverlayBackground
local OverlayGlow
local OverlayAccent
local OverlayTitle
local OverlaySummary

local function Clamp(value, minValue, maxValue)
    -- Schutz gegen kaputte DB-Werte und Slider-Ausreisser.
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function GetDungeonActivityType()
    if Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Activities then
        return Enum.WeeklyRewardChestThresholdType.Activities
    end

    return 3
end

local function GetTimestamp()
    if GetServerTime then
        return GetServerTime()
    end

    return time()
end

local function GetCurrentWeekKey()
    local now = GetTimestamp()

    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local secondsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
        if type(secondsUntilReset) == "number" and secondsUntilReset > 0 then
            return now + math.floor(secondsUntilReset + 0.5)
        end
    end

    return tonumber(date("%Y%W", now)) or now
end

local function GetWeeklyKeysCharacterData()
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.weeklyKeys = BeavisQoLCharDB.weeklyKeys or {}

    local db = BeavisQoLCharDB.weeklyKeys
    local currentWeekKey = GetCurrentWeekKey()

    if type(db.trackedRuns) ~= "table" then
        db.trackedRuns = {}
    end

    if db.currentWeekKey ~= currentWeekKey then
        db.currentWeekKey = currentWeekKey
        db.trackedRuns = {}
    end

    for index = #db.trackedRuns, 1, -1 do
        local entry = db.trackedRuns[index]
        if type(entry) ~= "table"
            or entry.weekKey ~= currentWeekKey
            or type(entry.name) ~= "string"
            or entry.name == ""
            or type(entry.difficultyCategory) ~= "string"
            or entry.difficultyCategory == ""
        then
            table.remove(db.trackedRuns, index)
        end
    end

    while #db.trackedRuns > MAX_TRACKED_DUNGEON_RUNS do
        table.remove(db.trackedRuns, 1)
    end

    return db
end

local function GetNonKeystoneDifficultyCategory(difficultyID, difficultyName)
    local numericDifficultyID = tonumber(difficultyID) or 0
    local heroicDifficultyID = DifficultyUtil and DifficultyUtil.ID and DifficultyUtil.ID.DungeonHeroic or 2
    local mythicDifficultyID = DifficultyUtil and DifficultyUtil.ID and DifficultyUtil.ID.DungeonMythic or 23

    if numericDifficultyID == 8 then
        return nil
    end

    if numericDifficultyID == heroicDifficultyID or numericDifficultyID == 174 then
        return "heroic", L("WEEKLY_KEYS_HEROIC")
    end

    if numericDifficultyID == mythicDifficultyID or numericDifficultyID == 40 then
        return "mythic", L("WEEKLY_KEYS_MYTHIC")
    end

    local normalizedDifficultyName = string.lower(tostring(difficultyName or ""))
    if normalizedDifficultyName ~= "" then
        if string.find(normalizedDifficultyName, "keystone", 1, true)
            or string.find(normalizedDifficultyName, "schluessel", 1, true)
            or string.find(normalizedDifficultyName, "challenge", 1, true)
        then
            return nil
        end

        if string.find(normalizedDifficultyName, "hero", 1, true) or string.find(normalizedDifficultyName, "hc", 1, true) then
            return "heroic", L("WEEKLY_KEYS_HEROIC")
        end

        if string.find(normalizedDifficultyName, "myth", 1, true) then
            return "mythic", L("WEEKLY_KEYS_MYTHIC")
        end
    end

    return nil
end

local function GetNonKeystoneRunText(difficultyCategory, dungeonName)
    local prefix = difficultyCategory == "heroic" and L("WEEKLY_KEYS_HEROIC") or L("WEEKLY_KEYS_MYTHIC")
    if dungeonName and dungeonName ~= "" then
        return string.format("%s %s", prefix, dungeonName)
    end

    if difficultyCategory == "heroic" then
        return L("WEEKLY_KEYS_HEROIC_RECORDED")
    end

    return L("WEEKLY_KEYS_MYTHIC_RECORDED")
end

local function GetCurrentTrackableDungeonInfo()
    if not GetInstanceInfo then
        return nil
    end

    local name, instanceType, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()
    if instanceType ~= "party" or type(name) ~= "string" or name == "" then
        return nil
    end

    local difficultyCategory, difficultyLabel = GetNonKeystoneDifficultyCategory(difficultyID, difficultyName)
    if not difficultyCategory then
        return nil
    end

    return {
        name = name,
        instanceID = tonumber(instanceID) or 0,
        difficultyID = tonumber(difficultyID) or 0,
        difficultyCategory = difficultyCategory,
        difficultyLabel = difficultyLabel,
    }
end

local function UpdateTrackedDungeonContext()
    local now = GetTimestamp()
    local dungeonInfo = GetCurrentTrackableDungeonInfo()

    if not dungeonInfo then
        if trackedDungeonContext.key then
            trackedDungeonContext.lastSeenAt = now
            trackedDungeonContext.isActive = false
        end

        return nil
    end

    local contextKey = string.format("%s:%d:%d", dungeonInfo.name, dungeonInfo.instanceID, dungeonInfo.difficultyID)
    if trackedDungeonContext.key ~= contextKey or not trackedDungeonContext.isActive then
        trackedDungeonContext.key = contextKey
        trackedDungeonContext.name = dungeonInfo.name
        trackedDungeonContext.instanceID = dungeonInfo.instanceID
        trackedDungeonContext.difficultyID = dungeonInfo.difficultyID
        trackedDungeonContext.difficultyLabel = dungeonInfo.difficultyLabel
        trackedDungeonContext.difficultyCategory = dungeonInfo.difficultyCategory
        trackedDungeonContext.enteredAt = now
        trackedDungeonContext.completionLogged = false
    end

    trackedDungeonContext.lastSeenAt = now
    trackedDungeonContext.isActive = true

    return dungeonInfo
end

local function GetRecentTrackedDungeonContext()
    local dungeonInfo = UpdateTrackedDungeonContext()
    if dungeonInfo then
        return trackedDungeonContext
    end

    local now = GetTimestamp()
    if trackedDungeonContext.key
        and not trackedDungeonContext.completionLogged
        and (now - (trackedDungeonContext.lastSeenAt or 0)) <= TRACKED_DUNGEON_CONTEXT_TTL
    then
        return trackedDungeonContext
    end

    return nil
end

local function TrackCurrentDungeonCompletion()
    local context = GetRecentTrackedDungeonContext()
    if not context or context.completionLogged then
        return false
    end

    local db = GetWeeklyKeysCharacterData()
    local dedupeKey = string.format(
        "%s:%d:%d",
        context.name or "",
        tonumber(context.difficultyID) or 0,
        tonumber(context.enteredAt) or 0
    )

    for _, entry in ipairs(db.trackedRuns) do
        if entry.dedupeKey == dedupeKey then
            context.completionLogged = true
            return false
        end
    end

    db.trackedRuns[#db.trackedRuns + 1] = {
        weekKey = db.currentWeekKey,
        name = context.name,
        difficultyID = context.difficultyID,
        difficultyCategory = context.difficultyCategory,
        difficultyLabel = context.difficultyLabel,
        timestamp = GetTimestamp(),
        dedupeKey = dedupeKey,
    }

    while #db.trackedRuns > MAX_TRACKED_DUNGEON_RUNS do
        table.remove(db.trackedRuns, 1)
    end

    context.completionLogged = true
    return true
end

local function GetItemLevelFromLink(itemLink)
    if not itemLink or itemLink == "" then
        return 0
    end

    if C_Item and C_Item.GetDetailedItemLevelInfo then
        local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
        if itemLevel and itemLevel > 0 then
            return itemLevel
        end
    end

    return 0
end

local function NormalizeActivityProgress(activity)
    -- Blizzard liefert Weekly-Reward-Daten je nach Client-Version nicht immer
    -- in exakt derselben Struktur. Diese Funktion macht daraus ein stabiles
    -- Paar aus `progress` und `threshold`.
    if not activity then
        return 0, 0
    end

    local progress = activity.progress
    local threshold = activity.threshold

    if type(progress) == "table" then
        threshold = threshold or progress.threshold or progress.required or progress.total
        progress = progress.progress or progress.current or progress.value
    end

    return tonumber(progress) or 0, tonumber(threshold) or 0
end

local function GetExampleRewardItemLevel(activity)
    if not activity or not activity.id or not C_WeeklyRewards or not C_WeeklyRewards.GetExampleRewardItemHyperlinks then
        return 0
    end

    local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id)
    return GetItemLevelFromLink(itemLink)
end

local function RequestVaultData()
    -- Die Requests stossen nur an, dass Blizzard seine internen Daten auffrischt.
    -- Die eigentliche Anzeige lesen wir danach über die normalen APIs.
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end

    if C_MythicPlus and C_MythicPlus.RequestRewards then
        C_MythicPlus.RequestRewards()
    end
end

local function RequestSavedInstanceData()
    if RequestRaidInfo then
        RequestRaidInfo()
    end
end

local function GetDungeonSlotData()
    -- Hier entsteht die Lookup-Tabelle für die Vault-Slots.
    -- Beispiel: `slots[4]` steht für den 4er-Slot der Weekly Vault.
    local slots = {}

    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then
        return slots
    end

    local activityType = GetDungeonActivityType()
    local activities = C_WeeklyRewards.GetActivities() or {}

    for _, activity in ipairs(activities) do
        if activity and activity.type == activityType then
            local progress, threshold = NormalizeActivityProgress(activity)
            if threshold > 0 then
                slots[threshold] = {
                    threshold = threshold,
                    progress = progress,
                    complete = progress >= threshold,
                    itemLevel = GetExampleRewardItemLevel(activity),
                }
            end
        end
    end

    return slots
end

local function GetMapName(mapChallengeModeID)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
        if name and name ~= "" then
            return name
        end
    end

    return L("UNKNOWN_DUNGEON")
end

local function GetWeeklyRunHistory()
    -- Die Rohdaten aus der API werden direkt nach "wichtigster Lauf zuerst"
    -- sortiert: hoehere Stufe, dann timed vor depleted, dann Name.
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then
        return {}
    end

    local rawRunHistory = C_MythicPlus.GetRunHistory(false, true) or {}
    local runHistory = {}

    for _, runInfo in ipairs(rawRunHistory) do
        if runInfo and (runInfo.thisWeek == nil or runInfo.thisWeek == true) then
            runHistory[#runHistory + 1] = runInfo
        end
    end

    table.sort(runHistory, function(a, b)
        local aLevel = tonumber(a and a.level) or 0
        local bLevel = tonumber(b and b.level) or 0
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end

        local aTimed = tonumber(a and a.completedInTime) or 0
        local bTimed = tonumber(b and b.completedInTime) or 0
        if aTimed ~= bTimed then
            return aTimed > bTimed
        end

        return GetMapName(a and a.mapChallengeModeID) < GetMapName(b and b.mapChallengeModeID)
    end)

    return runHistory
end

local function GetWeeklyDungeonRunCounts(runHistoryCount)
    local heroicRuns = 0
    local mythicRuns = 0
    local mythicPlusRuns = tonumber(runHistoryCount) or 0

    if C_WeeklyRewards and C_WeeklyRewards.GetNumCompletedDungeonRuns then
        local heroicCount, mythicCount, mythicPlusCount = C_WeeklyRewards.GetNumCompletedDungeonRuns()
        heroicRuns = math.max(0, tonumber(heroicCount) or 0)
        mythicRuns = math.max(0, tonumber(mythicCount) or 0)
        mythicPlusRuns = math.max(mythicPlusRuns, tonumber(mythicPlusCount) or 0)
    end

    return heroicRuns, mythicRuns, mythicPlusRuns
end

local function GetSavedInstanceDungeonRuns()
    local entries = {}

    if not GetNumSavedInstances or not GetSavedInstanceInfo then
        return entries
    end

    for index = 1, GetNumSavedInstances() do
        local name, _, resetSeconds, difficultyID, locked, _, _, isRaid, _, difficultyName = GetSavedInstanceInfo(index)
        if not isRaid and type(name) == "string" and name ~= "" then
            local difficultyCategory, difficultyLabel = GetNonKeystoneDifficultyCategory(difficultyID, difficultyName)
            if difficultyCategory and ((tonumber(resetSeconds) or 0) > 0 or locked) then
                entries[#entries + 1] = {
                    name = name,
                    difficultyID = tonumber(difficultyID) or 0,
                    difficultyCategory = difficultyCategory,
                    difficultyLabel = difficultyLabel,
                    timestamp = 0,
                    source = "savedInstance",
                }
            end
        end
    end

    return entries
end

local function GetTrackedNonKeystoneDungeonRuns()
    local db = GetWeeklyKeysCharacterData()
    local entries = {}
    local seenByName = {}

    for _, entry in ipairs(db.trackedRuns) do
        if entry.difficultyCategory == "heroic" or entry.difficultyCategory == "mythic" then
            entries[#entries + 1] = {
                name = entry.name,
                difficultyID = tonumber(entry.difficultyID) or 0,
                difficultyCategory = entry.difficultyCategory,
                difficultyLabel = entry.difficultyLabel,
                timestamp = tonumber(entry.timestamp) or 0,
                source = "tracked",
            }

            seenByName[string.format("%s:%s", string.lower(entry.name), entry.difficultyCategory)] = true
        end
    end

    for _, entry in ipairs(GetSavedInstanceDungeonRuns()) do
        local dedupeKey = string.format("%s:%s", string.lower(entry.name), entry.difficultyCategory)
        if not seenByName[dedupeKey] then
            entries[#entries + 1] = entry
            seenByName[dedupeKey] = true
        end
    end

    table.sort(entries, function(a, b)
        local aPriority = a.difficultyCategory == "mythic" and 2 or 1
        local bPriority = b.difficultyCategory == "mythic" and 2 or 1
        if aPriority ~= bPriority then
            return aPriority > bPriority
        end

        local aTimestamp = tonumber(a.timestamp) or 0
        local bTimestamp = tonumber(b.timestamp) or 0
        if aTimestamp ~= bTimestamp then
            return aTimestamp > bTimestamp
        end

        return GetNonKeystoneRunText(a.difficultyCategory, a.name) < GetNonKeystoneRunText(b.difficultyCategory, b.name)
    end)

    return entries
end

local function GetWeeklyKeysSettings()
    -- Wie im Stats-Modul normalisieren wir alle SavedVariables an einer Stelle.
    -- So bleibt die restliche Datei frei von nil- und Altwert-Sonderfaellen.
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.weeklyKeys = BeavisQoLDB.weeklyKeys or {}

    local db = BeavisQoLDB.weeklyKeys

    if db.overlayEnabled == nil then
        db.overlayEnabled = false
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if type(db.fontSize) ~= "number" then
        db.fontSize = DEFAULT_FONT_SIZE
    elseif db.overlayScale == nil and math.floor(db.fontSize + 0.5) == LEGACY_DEFAULT_FONT_SIZE then
        db.fontSize = DEFAULT_FONT_SIZE
    end
    db.fontSize = Clamp(math.floor(db.fontSize + 0.5), MIN_FONT_SIZE, MAX_FONT_SIZE)

    if type(db.overlayScale) ~= "number" then
        db.overlayScale = DEFAULT_OVERLAY_SCALE
    end
    db.overlayScale = Clamp(db.overlayScale, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)

    if type(db.backgroundAlpha) ~= "number" then
        db.backgroundAlpha = DEFAULT_BACKGROUND_ALPHA
    end
    db.backgroundAlpha = Clamp(db.backgroundAlpha, MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA)

    if type(db.point) ~= "string" or db.point == "" then
        db.point = DEFAULT_POINT
    end

    if type(db.relativePoint) ~= "string" or db.relativePoint == "" then
        db.relativePoint = DEFAULT_RELATIVE_POINT
    end

    if type(db.offsetX) ~= "number" then
        db.offsetX = DEFAULT_OFFSET_X
    end

    if type(db.offsetY) ~= "number" then
        db.offsetY = DEFAULT_OFFSET_Y
    end

    return db
end

local function ShouldHideOverlayInCombat()
    return BeavisQoL.ShouldHideOverlay
        and BeavisQoL.ShouldHideOverlay("weekly")
end

function WeeklyKeysModule.IsOverlayEnabled()
    return GetWeeklyKeysSettings().overlayEnabled == true
end

function WeeklyKeysModule.SetOverlayEnabled(enabled)
    GetWeeklyKeysSettings().overlayEnabled = enabled == true
    WeeklyKeysModule.RefreshOverlayWindow()
end

function WeeklyKeysModule.IsOverlayLocked()
    return GetWeeklyKeysSettings().overlayLocked == true
end

function WeeklyKeysModule.SetOverlayLocked(locked)
    GetWeeklyKeysSettings().overlayLocked = locked == true
    WeeklyKeysModule.RefreshOverlayWindow()
end

function WeeklyKeysModule.SetFontSize(fontSize)
    GetWeeklyKeysSettings().fontSize = Clamp(math.floor((fontSize or DEFAULT_FONT_SIZE) + 0.5), MIN_FONT_SIZE, MAX_FONT_SIZE)
    WeeklyKeysModule.RefreshOverlayWindow()
end

function WeeklyKeysModule.GetOverlayScale()
    return GetWeeklyKeysSettings().overlayScale
end

function WeeklyKeysModule.SetOverlayScale(scale)
    GetWeeklyKeysSettings().overlayScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    WeeklyKeysModule.RefreshOverlayWindow()
end

function WeeklyKeysModule.SetBackgroundAlpha(alpha)
    GetWeeklyKeysSettings().backgroundAlpha = Clamp(alpha or DEFAULT_BACKGROUND_ALPHA, MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA)
    WeeklyKeysModule.RefreshOverlayWindow()
end

local function SaveOverlayGeometry()
    -- Nur speichern, wenn das Overlay wirklich existiert.
    if not OverlayFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayFrame:GetPoint(1)
    local settings = GetWeeklyKeysSettings()

    settings.point = point or DEFAULT_POINT
    settings.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    settings.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    settings.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function ApplyOverlayGeometry()
    -- Diese Funktion setzt die gespeicherte Position nur aktiv auf den Frame.
    -- Sie wird bewusst nicht in jedem Refresh aufgerufen, damit man das
    -- Overlay ohne "Zurueckspringen" verschieben kann.
    if not OverlayFrame then
        return
    end

    local settings = GetWeeklyKeysSettings()
    OverlayFrame:ClearAllPoints()
    OverlayFrame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.offsetX, settings.offsetY)
end

function WeeklyKeysModule.ResetOverlayPosition()
    local settings = GetWeeklyKeysSettings()
    settings.point = DEFAULT_POINT
    settings.relativePoint = DEFAULT_RELATIVE_POINT
    settings.offsetX = DEFAULT_OFFSET_X
    settings.offsetY = DEFAULT_OFFSET_Y
    ApplyOverlayGeometry()
end

local function FormatSliderValue(value, mode)
    if mode == "alpha" or mode == "scale" then
        return string.format("%d%%", math.floor((value * 100) + 0.5))
    end

    return tostring(math.floor((value or 0) + 0.5))
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step, mode)
    -- Gleiche Idee wie in Stats.lua:
    -- Blizzard-Slider brauchen einen festen Namen für ihre eingebauten Labels.
    sliderCounter = sliderCounter + 1

    local sliderName = "BeavisQoLWeeklyKeysSlider" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetWidth(320)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.Text = _G[sliderName .. "Text"]
    slider.Low = _G[sliderName .. "Low"]
    slider.High = _G[sliderName .. "High"]

    slider.Text:SetText(labelText)
    slider.Text:SetTextColor(1, 0.82, 0, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(1, 1, 1, 1)

    slider:SetScript("OnValueChanged", function(self, value)
        self.ValueText:SetText(FormatSliderValue(value, mode))

        if isRefreshing or not self.ApplyValue then
            return
        end

        self:ApplyValue(value)
    end)

    return slider
end

local function CreateSectionCheckbox(parent, anchor, titleText, hintText)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(titleText)

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    hint:SetTextColor(0.80, 0.80, 0.80, 1)
    hint:SetText(hintText)

    return checkbox, label, hint
end

local function CreateRunRows(parent, targetTable)
    -- Acht feste Zeilen reichen hier, weil auch die Weekly Vault maximal
    -- acht relevante Dungeon-Slots beruecksichtigt.
    for index = 1, 8 do
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(18)

        local rankText = row:CreateFontString(nil, "OVERLAY")
        rankText:SetJustifyH("LEFT")
        rankText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        rankText:SetTextColor(DIM_COLOR[1], DIM_COLOR[2], DIM_COLOR[3], 1)
        row.RankText = rankText

        local statusText = row:CreateFontString(nil, "OVERLAY")
        statusText:SetJustifyH("LEFT")
        statusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        row.StatusText = statusText

        local runText = row:CreateFontString(nil, "OVERLAY")
        runText:SetJustifyH("LEFT")
        runText:SetJustifyV("MIDDLE")
        runText:SetShadowColor(0, 0, 0, 1)
        runText:SetShadowOffset(1, -1)
        if runText.SetWordWrap then
            runText:SetWordWrap(false)
        end
        if runText.SetNonSpaceWrap then
            runText:SetNonSpaceWrap(false)
        end
        if runText.SetMaxLines then
            runText:SetMaxLines(1)
        end
        row.RunText = runText

        local rewardText = row:CreateFontString(nil, "OVERLAY")
        rewardText:SetJustifyH("RIGHT")
        rewardText:SetJustifyV("MIDDLE")
        rewardText:SetShadowColor(0, 0, 0, 1)
        rewardText:SetShadowOffset(1, -1)
        if rewardText.SetWordWrap then
            rewardText:SetWordWrap(false)
        end
        if rewardText.SetNonSpaceWrap then
            rewardText:SetNonSpaceWrap(false)
        end
        if rewardText.SetMaxLines then
            rewardText:SetMaxLines(1)
        end
        row.RewardText = rewardText

        targetTable[index] = row
    end
end

local function ApplyOverlaySurface(frame, backgroundTexture, glowTexture, accentTexture, alpha)
    -- Weekly Keys ist bewusst "fensterloser" gestaltet als Stats:
    -- keine volle Tooltip-Umrandung, sondern nur ein dezenter Hintergrund,
    -- Glow und eine linke Akzentlinie.
    backgroundTexture:SetColorTexture(0.03, 0.03, 0.05, alpha)
    glowTexture:SetColorTexture(1, 1, 1, 0.05 + (alpha * 0.12))
    accentTexture:SetColorTexture(1, 0.82, 0, 0.12 + (alpha * 0.30))
end

local function GetSlotDisplayInfo(slotLookup, threshold)
    local slotInfo = slotLookup[threshold]
    if not slotInfo then
        return 0, false
    end

    return tonumber(slotInfo.itemLevel) or 0, slotInfo.complete == true
end

local function GetTrackedDungeonCount(slotLookup, runHistoryCount)
    local trackedCount = tonumber(runHistoryCount) or 0

    for _, slotInfo in pairs(slotLookup) do
        local progress = tonumber(slotInfo and slotInfo.progress) or 0
        if progress > trackedCount then
            trackedCount = progress
        end
    end

    return math.min(trackedCount, 8)
end

local function BuildDisplayRows()
    -- Diese Funktion ist die eigentliche Übersetzung von API-Daten in UI-Zeilen.
    -- Sie entscheidet:
    -- - welche Runs sichtbar sind
    -- - wann Platzhalter gezeigt werden
    -- - welcher Loot an Slot 1 / 4 / 8 steht
    local slotLookup = GetDungeonSlotData()
    local runHistory = GetWeeklyRunHistory()
    local heroicRunCount, mythicRunCount, mythicPlusRunCount = GetWeeklyDungeonRunCounts(#runHistory)
    local trackedNonKeystoneRuns = GetTrackedNonKeystoneDungeonRuns()
    local completedEntries = {}
    local trackedHeroicRuns = 0
    local trackedMythicRuns = 0
    local rows = {}

    for _, runInfo in ipairs(runHistory) do
        local keystoneLevel = tonumber(runInfo.level) or 0
        local timedRun = (tonumber(runInfo.completedInTime) or 0) > 0

        completedEntries[#completedEntries + 1] = {
            priority = 300000 + (keystoneLevel * 10) + (timedRun and 1 or 0),
            timestamp = 0,
            status = timedRun and "v" or "x",
            statusColor = timedRun and { 0.28, 0.92, 0.38 } or { 1.00, 0.28, 0.28 },
            runText = string.format("+%d %s", keystoneLevel, GetMapName(runInfo.mapChallengeModeID)),
        }
    end

    for _, entry in ipairs(trackedNonKeystoneRuns) do
        local shouldAddEntry = false

        if entry.difficultyCategory == "mythic" then
            if mythicRunCount <= 0 or trackedMythicRuns < mythicRunCount then
                trackedMythicRuns = trackedMythicRuns + 1
                shouldAddEntry = true
            end
        elseif entry.difficultyCategory == "heroic" then
            if heroicRunCount <= 0 or trackedHeroicRuns < heroicRunCount then
                trackedHeroicRuns = trackedHeroicRuns + 1
                shouldAddEntry = true
            end
        end

        if shouldAddEntry then
            completedEntries[#completedEntries + 1] = {
                priority = entry.difficultyCategory == "mythic" and 200000 or 100000,
                timestamp = tonumber(entry.timestamp) or 0,
                status = "v",
                statusColor = { 0.28, 0.92, 0.38 },
                runText = GetNonKeystoneRunText(entry.difficultyCategory, entry.name),
            }
        end
    end

    for index = trackedMythicRuns + 1, mythicRunCount do
        completedEntries[#completedEntries + 1] = {
            priority = 200000,
            timestamp = 0,
            status = "v",
            statusColor = { 0.28, 0.92, 0.38 },
            runText = GetNonKeystoneRunText("mythic"),
        }
    end

    for index = trackedHeroicRuns + 1, heroicRunCount do
        completedEntries[#completedEntries + 1] = {
            priority = 100000,
            timestamp = 0,
            status = "v",
            statusColor = { 0.28, 0.92, 0.38 },
            runText = GetNonKeystoneRunText("heroic"),
        }
    end

    table.sort(completedEntries, function(a, b)
        local aPriority = tonumber(a.priority) or 0
        local bPriority = tonumber(b.priority) or 0
        if aPriority ~= bPriority then
            return aPriority > bPriority
        end

        local aTimestamp = tonumber(a.timestamp) or 0
        local bTimestamp = tonumber(b.timestamp) or 0
        if aTimestamp ~= bTimestamp then
            return aTimestamp > bTimestamp
        end

        return (a.runText or "") < (b.runText or "")
    end)

    local nonKeystoneRunCount = heroicRunCount + mythicRunCount
    local totalDungeonCount = mythicPlusRunCount + (nonKeystoneRunCount > 0 and nonKeystoneRunCount or #trackedNonKeystoneRuns)
    local trackedDungeonCount = math.min(math.max(totalDungeonCount, GetTrackedDungeonCount(slotLookup, #runHistory)), 8)

    for index = 1, 8 do
        local completedEntry = completedEntries[index]
        local rewardLevel = 0

        if index == 1 or index == 4 or index == 8 then
            rewardLevel = GetSlotDisplayInfo(slotLookup, index)
        end

        local rowColor = TEXT_COLOR
        if index == 1 or index == 4 or index == 8 then
            rowColor = SLOT_COLORS[index] or TEXT_COLOR
        end

        if completedEntry then
            rows[index] = {
                status = completedEntry.status,
                statusColor = completedEntry.statusColor,
                runText = completedEntry.runText,
                runColor = rowColor,
                rewardText = rewardLevel > 0 and string.format("%d ilvl", rewardLevel) or "",
                rewardColor = rowColor,
            }
        elseif index <= trackedDungeonCount then
            rows[index] = {
                status = "v",
                statusColor = { 0.28, 0.92, 0.38 },
                runText = L("WEEKLY_KEYS_NAMELESS"),
                runColor = rowColor,
                rewardText = rewardLevel > 0 and string.format("%d ilvl", rewardLevel) or "",
                rewardColor = rowColor,
            }
        else
            local missingRuns = math.max(1, index - trackedDungeonCount)
            local placeholder = L("WEEKLY_KEYS_NONE_THIS_WEEK")

            if index == 4 or index == 8 then
                placeholder = L("WEEKLY_KEYS_MORE_NEEDED"):format(missingRuns, missingRuns == 1 and L("DUNGEON_SINGULAR") or L("DUNGEON_PLURAL"))
            elseif index == 1 then
                placeholder = L("WEEKLY_KEYS_NONE_WEEKLY")
            end

            rows[index] = {
                status = "-",
                statusColor = DIM_COLOR,
                runText = placeholder,
                runColor = DIM_COLOR,
                rewardText = rewardLevel > 0 and string.format("%d ilvl", rewardLevel) or "",
                rewardColor = rowColor,
            }
        end
    end

    local slotOneLevel = GetSlotDisplayInfo(slotLookup, 1)
    local slotFourLevel = GetSlotDisplayInfo(slotLookup, 4)
    local slotEightLevel = GetSlotDisplayInfo(slotLookup, 8)

    local summaryText = L("WEEKLY_KEYS_SUMMARY"):format(
        trackedDungeonCount,
        (slotOneLevel > 0 and tostring(slotOneLevel) or "-"),
        (slotFourLevel > 0 and tostring(slotFourLevel) or "-"),
        (slotEightLevel > 0 and tostring(slotEightLevel) or "-")
    )

    return rows, summaryText
end

local function GetLayoutMetrics(fontSize, scale)
    -- Auch hier steckt das Overlay-Design in einer reinen Zahlenfunktion.
    local effectiveScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    local width = math.floor((BASE_OVERLAY_WIDTH * effectiveScale) + 0.5)
    local horizontalPadding = math.max(10, math.floor((12 * effectiveScale) + 0.5))
    local rankWidth = math.max(14, math.floor((16 * effectiveScale) + 0.5))
    local statusWidth = math.max(10, math.floor((11 * effectiveScale) + 0.5))
    local rankGap = math.max(2, math.floor((3 * effectiveScale) + 0.5))
    local textGap = math.max(4, math.floor((6 * effectiveScale) + 0.5))
    local rewardWidth = math.max(72, math.floor((84 * effectiveScale) + 0.5))
    local lineHeight = math.max(fontSize + 2, math.floor(((fontSize + 3) * math.max(0.9, effectiveScale)) + 0.5))
    local rowSpacing = math.max(1, math.floor((2 * effectiveScale) + 0.5))
    local topPadding = math.max(34, math.floor((36 * effectiveScale) + 0.5))
    local bottomPadding = math.max(8, math.floor((10 * effectiveScale) + 0.5))

    return {
        width = width,
        horizontalPadding = horizontalPadding,
        rankWidth = rankWidth,
        statusWidth = statusWidth,
        rankGap = rankGap,
        textGap = textGap,
        rewardWidth = rewardWidth,
        lineHeight = lineHeight,
        rowSpacing = rowSpacing,
        topPadding = topPadding,
        bottomPadding = bottomPadding,
    }
end

local function UpdateRunRows(parent, targetRows, fontSize, summaryFontSize, scale, titleTextObject, summaryTextObject, backgroundTexture, glowTexture, accentTexture)
    -- Layout und Datenfluss treffen sich genau hier:
    -- Zuerst werden die Zeileninhalte gebaut, danach werden Fonts, Abstaende
    -- und Positionen auf die sichtbaren Rows verteilt.
    local settings = GetWeeklyKeysSettings()
    local rowsData, summaryText = BuildDisplayRows()
    local metrics = GetLayoutMetrics(fontSize, scale)
    local currentY = -metrics.topPadding

    titleTextObject:SetFont("Fonts\\FRIZQT__.TTF", math.max(10, fontSize + 1), "OUTLINE")
    summaryTextObject:SetFont("Fonts\\FRIZQT__.TTF", summaryFontSize, "")
    summaryTextObject:SetText(summaryText)

    for index, row in ipairs(targetRows) do
        local data = rowsData[index]

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.horizontalPadding, currentY)
        row:SetPoint("RIGHT", parent, "RIGHT", -metrics.horizontalPadding, 0)
        row:SetHeight(metrics.lineHeight)

        row.RankText:ClearAllPoints()
        row.RankText:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.RankText:SetWidth(metrics.rankWidth)
        row.RankText:SetFont("Fonts\\FRIZQT__.TTF", math.max(8, fontSize - 1), "OUTLINE")
        row.RankText:SetText(index .. ".")

        row.StatusText:ClearAllPoints()
        row.StatusText:SetPoint("LEFT", row.RankText, "RIGHT", metrics.rankGap, 0)
        row.StatusText:SetWidth(metrics.statusWidth)
        row.StatusText:SetFont("Fonts\\FRIZQT__.TTF", math.max(8, fontSize), "OUTLINE")
        row.StatusText:SetTextColor(data.statusColor[1], data.statusColor[2], data.statusColor[3], 1)
        row.StatusText:SetText(data.status)

        row.RewardText:ClearAllPoints()
        row.RewardText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.RewardText:SetWidth(metrics.rewardWidth)
        row.RewardText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        row.RewardText:SetTextColor(data.rewardColor[1], data.rewardColor[2], data.rewardColor[3], 1)
        row.RewardText:SetText(data.rewardText)

        row.RunText:ClearAllPoints()
        row.RunText:SetPoint("LEFT", row.StatusText, "RIGHT", metrics.textGap, 0)
        row.RunText:SetPoint("RIGHT", row.RewardText, "LEFT", -metrics.textGap, 0)
        row.RunText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        row.RunText:SetTextColor(data.runColor[1], data.runColor[2], data.runColor[3], 1)
        row.RunText:SetText(data.runText)

        row:Show()
        currentY = currentY - metrics.lineHeight - metrics.rowSpacing
    end

    local totalHeight = metrics.topPadding + metrics.bottomPadding + (#targetRows * metrics.lineHeight) + ((#targetRows - 1) * metrics.rowSpacing)
    parent:SetSize(metrics.width, totalHeight)
    ApplyOverlaySurface(parent, backgroundTexture, glowTexture, accentTexture, settings.backgroundAlpha)
end

local function RefreshPreview()
    -- Die Vorschau nutzt denselben Renderpfad wie das Overlay.
    if not PreviewCard then
        return
    end

    local settings = GetWeeklyKeysSettings()
    UpdateRunRows(
        PreviewCard,
        PreviewRows,
        settings.fontSize,
        math.max(8, settings.fontSize - 1),
        settings.overlayScale,
        PreviewTitle,
        PreviewSummary,
        PreviewBackground,
        PreviewGlow,
        PreviewAccent
    )
end

function WeeklyKeysModule.RefreshOverlayWindow()
    -- Zentraler Overlay-Refresh für Weekly Keys.
    if not OverlayFrame then
        return
    end

    local settings = GetWeeklyKeysSettings()

    UpdateRunRows(
        OverlayFrame,
        OverlayRows,
        settings.fontSize,
        math.max(8, settings.fontSize - 1),
        settings.overlayScale,
        OverlayTitle,
        OverlaySummary,
        OverlayBackground,
        OverlayGlow,
        OverlayAccent
    )

    OverlayFrame:EnableMouse(true)

    if settings.overlayEnabled and not ShouldHideOverlayInCombat() then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end
end

local RefreshTicker = CreateFrame("Frame")
RefreshTicker.elapsed = 0
RefreshTicker:SetScript("OnUpdate", function(self, elapsed)
    -- Nur aktualisieren, wenn Vorschau oder Overlay wirklich sichtbar sind.
    local needsRefresh = (PageWeeklyKeys and PageWeeklyKeys:IsShown()) or (OverlayFrame and OverlayFrame:IsShown())
    if not needsRefresh then
        self.elapsed = 0
        return
    end

    self.elapsed = self.elapsed + elapsed
    if self.elapsed < REFRESH_INTERVAL then
        return
    end

    self.elapsed = 0

    if PageWeeklyKeys and PageWeeklyKeys:IsShown() then
        RefreshPreview()
    end

    if OverlayFrame and OverlayFrame:IsShown() then
        WeeklyKeysModule.RefreshOverlayWindow()
    end
end)

local function RefreshAllDisplays()
    -- Ein Aufruf für Vorschau, Overlay und Datenanfrage.
    RequestVaultData()
    RefreshPreview()
    WeeklyKeysModule.RefreshOverlayWindow()
end

PageWeeklyKeys = CreateFrame("Frame", nil, Content)
PageWeeklyKeys:SetAllPoints()
PageWeeklyKeys:Hide()

local IntroPanel = CreateFrame("Frame", nil, PageWeeklyKeys)
IntroPanel:SetPoint("TOPLEFT", PageWeeklyKeys, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageWeeklyKeys, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(112)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(1, 0.82, 0, 0.9)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
IntroTitle:SetTextColor(1, 0.82, 0, 1)
IntroTitle:SetText(L("WEEKLY_KEYS"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("WEEKLY_KEYS_DESC"))

local PreviewPanel = CreateFrame("Frame", nil, PageWeeklyKeys)
PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
PreviewPanel:SetSize(392, 326)

local PreviewPanelBg = PreviewPanel:CreateTexture(nil, "BACKGROUND")
PreviewPanelBg:SetAllPoints()
PreviewPanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local PreviewPanelBorder = PreviewPanel:CreateTexture(nil, "ARTWORK")
PreviewPanelBorder:SetPoint("BOTTOMLEFT", PreviewPanel, "BOTTOMLEFT", 0, 0)
PreviewPanelBorder:SetPoint("BOTTOMRIGHT", PreviewPanel, "BOTTOMRIGHT", 0, 0)
PreviewPanelBorder:SetHeight(1)
PreviewPanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

local PreviewPanelTitle = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewPanelTitle:SetPoint("TOPLEFT", PreviewPanel, "TOPLEFT", 18, -14)
PreviewPanelTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
PreviewPanelTitle:SetTextColor(1, 0.82, 0, 1)
PreviewPanelTitle:SetText(L("LIVE_PREVIEW"))

local PreviewPanelHint = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewPanelHint:SetPoint("TOPLEFT", PreviewPanelTitle, "BOTTOMLEFT", 0, -8)
PreviewPanelHint:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewPanelHint:SetJustifyH("LEFT")
PreviewPanelHint:SetJustifyV("TOP")
PreviewPanelHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
PreviewPanelHint:SetTextColor(0.80, 0.80, 0.80, 1)
PreviewPanelHint:SetText(L("WEEKLY_KEYS_PREVIEW_HINT"))

PreviewCard = CreateFrame("Frame", nil, PreviewPanel)
PreviewCard:SetPoint("TOPLEFT", PreviewPanelHint, "BOTTOMLEFT", 0, -18)
PreviewCard:SetWidth(BASE_OVERLAY_WIDTH)
if PreviewCard.SetClipsChildren then
    PreviewCard:SetClipsChildren(true)
end

PreviewBackground = PreviewCard:CreateTexture(nil, "BACKGROUND")
PreviewBackground:SetAllPoints()

PreviewGlow = PreviewCard:CreateTexture(nil, "BORDER")
PreviewGlow:SetPoint("TOPLEFT", PreviewCard, "TOPLEFT", 0, 0)
PreviewGlow:SetPoint("TOPRIGHT", PreviewCard, "TOPRIGHT", 0, 0)
PreviewGlow:SetHeight(28)

PreviewAccent = PreviewCard:CreateTexture(nil, "ARTWORK")
PreviewAccent:SetPoint("TOPLEFT", PreviewCard, "TOPLEFT", 0, -12)
PreviewAccent:SetPoint("BOTTOMLEFT", PreviewCard, "BOTTOMLEFT", 0, 12)
PreviewAccent:SetWidth(2)

PreviewTitle = PreviewCard:CreateFontString(nil, "OVERLAY")
PreviewTitle:SetPoint("TOPLEFT", PreviewCard, "TOPLEFT", 12, -10)
PreviewTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
PreviewTitle:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3], 1)
PreviewTitle:SetText(L("WEEKLY_KEYS"))

PreviewSummary = PreviewCard:CreateFontString(nil, "OVERLAY")
PreviewSummary:SetPoint("TOPLEFT", PreviewTitle, "BOTTOMLEFT", 0, -4)
PreviewSummary:SetPoint("RIGHT", PreviewCard, "RIGHT", -12, 0)
PreviewSummary:SetJustifyH("LEFT")
PreviewSummary:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
PreviewSummary:SetTextColor(0.80, 0.80, 0.80, 1)

CreateRunRows(PreviewCard, PreviewRows)

local PreviewFooter = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewFooter:SetPoint("TOPLEFT", PreviewCard, "BOTTOMLEFT", 0, -14)
PreviewFooter:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewFooter:SetJustifyH("LEFT")
PreviewFooter:SetJustifyV("TOP")
PreviewFooter:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
PreviewFooter:SetTextColor(0.72, 0.72, 0.72, 1)
PreviewFooter:SetText(L("WEEKLY_KEYS_PREVIEW_FOOTER"))

local SettingsPanel = CreateFrame("Frame", nil, PageWeeklyKeys)
SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", 18, 0)
SettingsPanel:SetPoint("TOPRIGHT", PageWeeklyKeys, "TOPRIGHT", -20, -150)
-- Etwas mehr Hoehe, damit der Reset-Bereich sauber innerhalb des Panels bleibt
-- und unten sichtbar Luft zur Abschlusslinie hat.
SettingsPanel:SetHeight(452)

local SettingsBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsBg:SetAllPoints()
SettingsBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local SettingsBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsBorder:SetHeight(1)
SettingsBorder:SetColorTexture(1, 0.82, 0, 0.9)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.82, 0, 1)
SettingsTitle:SetText(L("DISPLAY_POSITION"))

local SettingsHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsHint:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", 0, -8)
SettingsHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsHint:SetJustifyH("LEFT")
SettingsHint:SetJustifyV("TOP")
SettingsHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SettingsHint:SetTextColor(0.80, 0.80, 0.80, 1)
SettingsHint:SetText(L("WEEKLY_KEYS_SETTINGS_HINT"))

local showOverlayLabel, showOverlayHint
ShowOverlayCheckbox, showOverlayLabel, showOverlayHint = CreateSectionCheckbox(
    SettingsPanel,
    SettingsHint,
    L("WEEKLY_KEYS_SHOW_OVERLAY"),
    L("WEEKLY_KEYS_SHOW_OVERLAY_HINT")
)

local lockOverlayLabel, lockOverlayHint
LockOverlayCheckbox, lockOverlayLabel, lockOverlayHint = CreateSectionCheckbox(
    SettingsPanel,
    showOverlayHint,
    L("WEEKLY_KEYS_LOCK_OVERLAY"),
    L("WEEKLY_KEYS_LOCK_OVERLAY_HINT")
)

FontSizeSlider = CreateValueSlider(SettingsPanel, L("FONT_SIZE_OVERLAY"), MIN_FONT_SIZE, MAX_FONT_SIZE, 1, "font")
FontSizeSlider:SetPoint("TOPLEFT", lockOverlayHint, "BOTTOMLEFT", 18, -34)

ScaleSlider = CreateValueSlider(SettingsPanel, L("WINDOW_SCALE"), MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE, 0.05, "scale")
ScaleSlider:SetPoint("TOPLEFT", FontSizeSlider, "BOTTOMLEFT", 0, -44)

BackgroundAlphaSlider = CreateValueSlider(SettingsPanel, L("BACKGROUND_ALPHA"), MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA, 0.05, "alpha")
BackgroundAlphaSlider:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 0, -44)

local ResetPositionButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetPositionButton:SetSize(182, 26)
ResetPositionButton:SetPoint("TOPLEFT", BackgroundAlphaSlider, "BOTTOMLEFT", -18, -28)
ResetPositionButton:SetText(L("RESET_POSITION"))

local ResetHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
ResetHint:SetPoint("LEFT", ResetPositionButton, "RIGHT", 12, 0)
ResetHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
ResetHint:SetJustifyH("LEFT")
ResetHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
ResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
ResetHint:SetText(L("WEEKLY_KEYS_RESET_HINT"))

OverlayFrame = CreateFrame("Frame", "BeavisQoLWeeklyKeysOverlayFrame", UIParent)
OverlayFrame:SetClampedToScreen(true)
OverlayFrame:SetMovable(true)
OverlayFrame:SetToplevel(false)
-- Weekly Keys soll im normalen Spielbild sichtbar bleiben, aber Blizzard-
-- und Battle.net-Overlays nicht ueberdecken.
OverlayFrame:SetFrameStrata("LOW")
OverlayFrame:SetFrameLevel(1)
if OverlayFrame.SetClipsChildren then
    OverlayFrame:SetClipsChildren(true)
end
OverlayFrame:EnableMouse(true)
if OverlayFrame.SetPropagateMouseClicks then
    OverlayFrame:SetPropagateMouseClicks(false)
end
if OverlayFrame.SetPropagateMouseMotion then
    OverlayFrame:SetPropagateMouseMotion(false)
end
OverlayFrame:RegisterForDrag("LeftButton")
OverlayFrame:SetScript("OnEnter", function()
    if GameTooltip and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end)
OverlayFrame:SetScript("OnDragStart", function(self)
    if WeeklyKeysModule.IsOverlayLocked() then
        return
    end

    self:StartMoving()
end)
OverlayFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveOverlayGeometry()
end)
OverlayFrame:Hide()
ApplyOverlayGeometry()

OverlayBackground = OverlayFrame:CreateTexture(nil, "BACKGROUND")
OverlayBackground:SetAllPoints()

OverlayGlow = OverlayFrame:CreateTexture(nil, "BORDER")
OverlayGlow:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 0, 0)
OverlayGlow:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", 0, 0)
OverlayGlow:SetHeight(28)

OverlayAccent = OverlayFrame:CreateTexture(nil, "ARTWORK")
OverlayAccent:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 0, -12)
OverlayAccent:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 0, 12)
OverlayAccent:SetWidth(2)

OverlayTitle = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlayTitle:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 12, -10)
OverlayTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
OverlayTitle:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3], 1)
OverlayTitle:SetText(L("WEEKLY_KEYS"))

OverlaySummary = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlaySummary:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -4)
OverlaySummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -12, 0)
OverlaySummary:SetJustifyH("LEFT")
OverlaySummary:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
OverlaySummary:SetTextColor(0.80, 0.80, 0.80, 1)

CreateRunRows(OverlayFrame, OverlayRows)

FontSizeSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetFontSize(value)
end

ScaleSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetOverlayScale(value)
end

BackgroundAlphaSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetBackgroundAlpha(value)
end

ShowOverlayCheckbox:SetScript("OnClick", function(self)
    WeeklyKeysModule.SetOverlayEnabled(self:GetChecked())
    PageWeeklyKeys:RefreshState()
end)

LockOverlayCheckbox:SetScript("OnClick", function(self)
    WeeklyKeysModule.SetOverlayLocked(self:GetChecked())
end)

ResetPositionButton:SetScript("OnClick", function()
    WeeklyKeysModule.ResetOverlayPosition()
end)

function PageWeeklyKeys:RefreshState()
    -- Liest den kompletten Modulzustand aus der DB und schreibt ihn gesammelt
    -- in Checkboxen, Slider und Vorschau.
    local settings = GetWeeklyKeysSettings()

    IntroTitle:SetText(L("WEEKLY_KEYS"))
    IntroText:SetText(L("WEEKLY_KEYS_DESC"))
    PreviewPanelTitle:SetText(L("LIVE_PREVIEW"))
    PreviewPanelHint:SetText(L("WEEKLY_KEYS_PREVIEW_HINT"))
    PreviewTitle:SetText(L("WEEKLY_KEYS"))
    PreviewFooter:SetText(L("WEEKLY_KEYS_PREVIEW_FOOTER"))
    SettingsTitle:SetText(L("DISPLAY_POSITION"))
    SettingsHint:SetText(L("WEEKLY_KEYS_SETTINGS_HINT"))
    showOverlayLabel:SetText(L("WEEKLY_KEYS_SHOW_OVERLAY"))
    showOverlayHint:SetText(L("WEEKLY_KEYS_SHOW_OVERLAY_HINT"))
    lockOverlayLabel:SetText(L("WEEKLY_KEYS_LOCK_OVERLAY"))
    lockOverlayHint:SetText(L("WEEKLY_KEYS_LOCK_OVERLAY_HINT"))
    FontSizeSlider.Text:SetText(L("FONT_SIZE_OVERLAY"))
    ScaleSlider.Text:SetText(L("WINDOW_SCALE"))
    BackgroundAlphaSlider.Text:SetText(L("BACKGROUND_ALPHA"))
    ResetPositionButton:SetText(L("RESET_POSITION"))
    ResetHint:SetText(L("WEEKLY_KEYS_RESET_HINT"))
    OverlayTitle:SetText(L("WEEKLY_KEYS"))

    isRefreshing = true
    ShowOverlayCheckbox:SetChecked(settings.overlayEnabled)
    LockOverlayCheckbox:SetChecked(settings.overlayLocked)
    FontSizeSlider:SetValue(settings.fontSize)
    ScaleSlider:SetValue(settings.overlayScale)
    BackgroundAlphaSlider:SetValue(settings.backgroundAlpha)
    isRefreshing = false

    RefreshAllDisplays()
end

PageWeeklyKeys:SetScript("OnShow", function()
    PageWeeklyKeys:RefreshState()
end)

local WeeklyKeysEvents = CreateFrame("Frame")
WeeklyKeysEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
WeeklyKeysEvents:RegisterEvent("PLAYER_LOGIN")
WeeklyKeysEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
WeeklyKeysEvents:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
WeeklyKeysEvents:RegisterEvent("WEEKLY_REWARDS_UPDATE")
WeeklyKeysEvents:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
WeeklyKeysEvents:RegisterEvent("CHALLENGE_MODE_COMPLETED")
WeeklyKeysEvents:RegisterEvent("CHALLENGE_MODE_RESET")
WeeklyKeysEvents:RegisterEvent("SCENARIO_COMPLETED")
WeeklyKeysEvents:RegisterEvent("LFG_COMPLETION_REWARD")
WeeklyKeysEvents:RegisterEvent("UPDATE_INSTANCE_INFO")
WeeklyKeysEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
WeeklyKeysEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
WeeklyKeysEvents:SetScript("OnEvent", function(_, eventName)
    -- Alle relevanten Weekly-Vault- und Mythic+-Aenderungen laufen hier zusammen.
    if eventName == "PLAYER_ENTERING_WORLD"
        or eventName == "PLAYER_LOGIN"
        or eventName == "ZONE_CHANGED_NEW_AREA"
        or eventName == "PLAYER_DIFFICULTY_CHANGED"
    then
        UpdateTrackedDungeonContext()
        if eventName == "PLAYER_ENTERING_WORLD" or eventName == "PLAYER_LOGIN" then
            RequestSavedInstanceData()
        end
    elseif eventName == "SCENARIO_COMPLETED" or eventName == "LFG_COMPLETION_REWARD" then
        TrackCurrentDungeonCompletion()
        RequestSavedInstanceData()
    end

    RefreshAllDisplays()
end)

PageWeeklyKeys:RefreshState()

BeavisQoL.Pages.WeeklyKeys = PageWeeklyKeys
