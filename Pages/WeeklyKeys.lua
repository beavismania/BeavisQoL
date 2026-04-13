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
local GROUP_KEYS_RESPONSE_TIMEOUT = 0.8
local GROUP_KEYS_OPENRAID_RESPONSE_TIMEOUT = 1.4
local GROUP_KEYS_DEBUG_ENABLED = true
local GROUP_KEYS_DEBUG_MODULE_KEY = "grpkeys"
local OPENRAID_ADDON_PREFIX = "LRS"
local TRACKED_DUNGEON_CONTEXT_TTL = 20
local MAX_TRACKED_DUNGEON_RUNS = 40
local GROUP_KEYS_PREFIX = "BEAVISQOLWK"
local GROUP_KEYS_MESSAGE_QUERY = "QUERY"
local GROUP_KEYS_MESSAGE_REPLY = "REPLY"
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
local HideInRaidCheckbox
local FontSizeSlider
local ScaleSlider
local BackgroundAlphaSlider
local GroupKeysButton

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
local recentChallengeModeActivityAt = 0

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
local CachedDisplayRows = nil
local CachedDisplaySummaryText = nil
local DisplayRowsDirty = true
local pendingGroupKeyRequest = nil
local groupKeyRequestSequence = 0
local AddChatMessage
local SendGroupKeysMessage
local AddGroupKeysDebugMessage
local GetShortName
local GetDefaultRealmName
local NormalizePlayerName
local GetUnitFullNameSafe
local GetPlayerFullName
local OpenRaidLib
local OpenRaidCallbackRegistered = false
local OpenRaidCallbackBridge = {}

if BeavisQoL.DebugConsole and BeavisQoL.DebugConsole.RegisterModule then
    BeavisQoL.DebugConsole.RegisterModule(
        GROUP_KEYS_DEBUG_MODULE_KEY,
        { titleText = "GRP-Keys" }
    )
end

OpenRaidCallbackBridge.OnKeystoneUpdate = function(unitName, keystoneInfo)
    local request = pendingGroupKeyRequest
    if not request or request.openRaidAttempted ~= true or request.allowOpenRaidFallback ~= true then
        return
    end

    local normalizedUnitName = NormalizePlayerName(unitName)
    if AddGroupKeysDebugMessage and request.debugEnabled == true then
        AddGroupKeysDebugMessage(string.format(
            "Details KeystoneUpdate raw=%s normalized=%s",
            tostring(unitName),
            tostring(normalizedUnitName)
        ))
    end
    if not normalizedUnitName
        or not request.membersByName
        or not request.membersByName[normalizedUnitName]
    then
        if AddGroupKeysDebugMessage and request.debugEnabled == true then
            AddGroupKeysDebugMessage("Details KeystoneUpdate verworfen: kein passendes Gruppenmitglied")
        end
        return
    end

    request.openRaidResponders = request.openRaidResponders or {}
    request.openRaidResponders[normalizedUnitName] = keystoneInfo or true
    if AddGroupKeysDebugMessage and request.debugEnabled == true then
        AddGroupKeysDebugMessage(string.format(
            "Details KeystoneUpdate %s level=%s map=%s challenge=%s mythic=%s",
            GetShortName(normalizedUnitName),
            tostring(keystoneInfo and keystoneInfo.level or nil),
            tostring(keystoneInfo and keystoneInfo.mapID or nil),
            tostring(keystoneInfo and keystoneInfo.challengeMapID or nil),
            tostring(keystoneInfo and keystoneInfo.mythicPlusMapID or nil)
        ))
    end
end

OpenRaidCallbackBridge.OnRatingUpdate = function(unitName)
    local request = pendingGroupKeyRequest
    if not request or request.openRaidAttempted ~= true or request.allowOpenRaidFallback ~= true then
        return
    end

    local normalizedUnitName = NormalizePlayerName(unitName)
    if AddGroupKeysDebugMessage and request.debugEnabled == true then
        AddGroupKeysDebugMessage(string.format(
            "Details RatingUpdate raw=%s normalized=%s",
            tostring(unitName),
            tostring(normalizedUnitName)
        ))
    end
    if not normalizedUnitName
        or not request.membersByName
        or not request.membersByName[normalizedUnitName]
    then
        if AddGroupKeysDebugMessage and request.debugEnabled == true then
            AddGroupKeysDebugMessage("Details RatingUpdate verworfen: kein passendes Gruppenmitglied")
        end
        return
    end

    request.openRaidRatingResponders = request.openRaidRatingResponders or {}
    request.openRaidRatingResponders[normalizedUnitName] = true
    if AddGroupKeysDebugMessage and request.debugEnabled == true then
        AddGroupKeysDebugMessage(string.format(
            "Details RatingUpdate %s",
            GetShortName(normalizedUnitName)
        ))
    end
end

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

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
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

local function IsKeystoneDifficulty(difficultyID, difficultyName)
    if (tonumber(difficultyID) or 0) == 8 then
        return true
    end

    local normalizedDifficultyName = string.lower(tostring(difficultyName or ""))
    if normalizedDifficultyName ~= "" then
        if string.find(normalizedDifficultyName, "keystone", 1, true)
            or string.find(normalizedDifficultyName, "schlüssel", 1, true)
            or string.find(normalizedDifficultyName, "challenge", 1, true)
        then
            return true
        end
    end

    return false
end

local function IsCurrentChallengeModeDungeon()
    if not GetInstanceInfo then
        return false
    end

    local _, instanceType, difficultyID, difficultyName = GetInstanceInfo()
    if instanceType ~= "party" then
        return false
    end

    if IsKeystoneDifficulty(difficultyID, difficultyName) then
        return true
    end

    return C_ChallengeMode
        and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive() == true
end

local function MarkChallengeModeActivityIfNeeded()
    if IsCurrentChallengeModeDungeon() then
        recentChallengeModeActivityAt = GetTimestamp()
        return true
    end

    return false
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

    if IsKeystoneDifficulty(difficultyID, difficultyName) then
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

            -- Sobald ein Key in diesem Instanzkontext erkannt wurde, darf ein
            -- vorher gesehener Mythic-0-Kontext nicht mehr als Non-Key-Ende
            -- wiederverwendet werden.
            if MarkChallengeModeActivityIfNeeded()
                or (recentChallengeModeActivityAt > 0 and (now - recentChallengeModeActivityAt) <= TRACKED_DUNGEON_CONTEXT_TTL)
            then
                trackedDungeonContext.completionLogged = true
            end
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
    local now = GetTimestamp()
    if MarkChallengeModeActivityIfNeeded()
        or (recentChallengeModeActivityAt > 0 and (now - recentChallengeModeActivityAt) <= TRACKED_DUNGEON_CONTEXT_TTL)
    then
        if trackedDungeonContext.key then
            trackedDungeonContext.completionLogged = true
        end

        return false
    end

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
        timestamp = now,
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
    -- Die Requests stoßen nur an, dass Blizzard seine internen Daten auffrischt.
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

local function GetMapNameByChallengeMapID(mapChallengeModeID)
    mapChallengeModeID = tonumber(mapChallengeModeID) or 0
    if mapChallengeModeID <= 0 then
        return nil
    end

    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
        if name and name ~= "" then
            return name
        end
    end

    return nil
end

local function GetMapName(mapChallengeModeID)
    local name = GetMapNameByChallengeMapID(mapChallengeModeID)
    if name then
        return name
    end

    return L("UNKNOWN_DUNGEON")
end

local function ResolveKeystoneMapName(challengeMapID, mapID, mythicPlusMapID)
    return GetMapNameByChallengeMapID(challengeMapID)
        or GetMapNameByChallengeMapID(mapID)
        or GetMapNameByChallengeMapID(mythicPlusMapID)
        or L("UNKNOWN_DUNGEON")
end

local function BuildKeystoneText(keystoneLevel, challengeMapID, mapID, mythicPlusMapID)
    keystoneLevel = tonumber(keystoneLevel) or 0
    if keystoneLevel <= 0 then
        return nil
    end

    return string.format("+%d %s", keystoneLevel, ResolveKeystoneMapName(challengeMapID, mapID, mythicPlusMapID))
end

local function GetOwnedKeystoneData()
    if not C_MythicPlus then
        return 0, 0, 0
    end

    local mapID = C_MythicPlus.GetOwnedKeystoneMapID and C_MythicPlus.GetOwnedKeystoneMapID() or 0
    local challengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID() or 0
    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel() or 0

    mapID = tonumber(mapID) or 0
    challengeMapID = tonumber(challengeMapID) or 0
    keystoneLevel = tonumber(keystoneLevel) or 0

    return keystoneLevel, challengeMapID, mapID
end

local function GetOwnedKeystoneText()
    local keystoneLevel, challengeMapID, mapID = GetOwnedKeystoneData()
    return BuildKeystoneText(keystoneLevel, challengeMapID, mapID)
end

local function GetGroupKeysChannel()
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

local function GetOpenRaidLib()
    if OpenRaidLib then
        local request = pendingGroupKeyRequest
        if request
            and request.debugEnabled == true
            and request.debugLoggedLibState ~= true
            and AddGroupKeysDebugMessage
        then
            request.debugLoggedLibState = true
            AddGroupKeysDebugMessage(string.format(
                "LibOpenRaid gefunden, callbacksRegistered=%s",
                tostring(OpenRaidCallbackRegistered == true)
            ))
        end
        return OpenRaidLib
    end

    if type(LibStub) == "table" and type(LibStub.GetLibrary) == "function" then
        OpenRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true)
    end

    if OpenRaidLib
        and OpenRaidCallbackRegistered ~= true
        and type(OpenRaidLib.RegisterCallback) == "function"
    then
        local ok, registered = pcall(
            OpenRaidLib.RegisterCallback,
            OpenRaidCallbackBridge,
            "KeystoneUpdate",
            "OnKeystoneUpdate"
        )
        local ratingOk, ratingRegistered = pcall(
            OpenRaidLib.RegisterCallback,
            OpenRaidCallbackBridge,
            "RatingUpdate",
            "OnRatingUpdate"
        )
        if ok and registered == true and ratingOk and ratingRegistered == true then
            OpenRaidCallbackRegistered = true
        end
    end

    local request = pendingGroupKeyRequest
    if request
        and request.debugEnabled == true
        and request.debugLoggedLibState ~= true
        and AddGroupKeysDebugMessage
    then
        request.debugLoggedLibState = true
        AddGroupKeysDebugMessage(string.format(
            "LibOpenRaid load=%s callbacksRegistered=%s",
            tostring(OpenRaidLib ~= nil),
            tostring(OpenRaidCallbackRegistered == true)
        ))
    end

    return OpenRaidLib
end

local function RequestOpenRaidGroupKeys()
    local openRaidLib = GetOpenRaidLib()
    if not openRaidLib then
        if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage("Details Keystone-Request: LibOpenRaid nicht gefunden")
        end
        return false
    end

    local requestFunc = nil
    local requestTarget = "none"
    if IsInRaid() then
        requestFunc = openRaidLib.RequestKeystoneDataFromRaid
        requestTarget = "raid"
    elseif IsInGroup() then
        requestFunc = openRaidLib.RequestKeystoneDataFromParty
        requestTarget = "party"
    end

    if type(requestFunc) ~= "function" then
        if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage("Details Keystone-Request: keine passende Request-Funktion")
        end
        return false
    end

    local ok, requested = pcall(requestFunc)
    if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Details Keystone-Request %s ok=%s requested=%s",
            requestTarget,
            tostring(ok),
            tostring(requested)
        ))
    end
    return ok and requested == true
end

local function RequestOpenRaidGroupRatings()
    local openRaidLib = GetOpenRaidLib()
    if not openRaidLib then
        if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage("Details Rating-Request: LibOpenRaid nicht gefunden")
        end
        return false
    end

    local requestFunc = nil
    local requestTarget = "none"
    if IsInRaid() then
        requestFunc = openRaidLib.RequestRatingDataFromRaid
        requestTarget = "raid"
    elseif IsInGroup() then
        requestFunc = openRaidLib.RequestRatingDataFromParty
        requestTarget = "party"
    end

    if type(requestFunc) ~= "function" then
        if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage("Details Rating-Request: keine passende Request-Funktion")
        end
        return false
    end

    local ok, requested = pcall(requestFunc)
    if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Details Rating-Request %s ok=%s requested=%s",
            requestTarget,
            tostring(ok),
            tostring(requested)
        ))
    end
    return ok and requested == true
end

local function GetAllOpenRaidKeystones()
    local openRaidLib = GetOpenRaidLib()
    if not openRaidLib or type(openRaidLib.GetAllKeystonesInfo) ~= "function" then
        return nil
    end

    local ok, keystoneData = pcall(openRaidLib.GetAllKeystonesInfo)
    if ok and type(keystoneData) == "table" then
        return keystoneData
    end

    return nil
end

local function FindOpenRaidKeystoneInfo(playerName)
    local normalizedPlayerName = NormalizePlayerName(playerName)
    if not normalizedPlayerName then
        return nil
    end

    local allKeystones = GetAllOpenRaidKeystones()
    if type(allKeystones) ~= "table" then
        return nil
    end

    if type(allKeystones[normalizedPlayerName]) == "table" then
        return allKeystones[normalizedPlayerName]
    end

    if type(allKeystones[playerName]) == "table" then
        return allKeystones[playerName]
    end

    local shortName = GetShortName(normalizedPlayerName)
    if shortName and type(allKeystones[shortName]) == "table" then
        return allKeystones[shortName]
    end

    for openRaidName, keystoneInfo in pairs(allKeystones) do
        if type(openRaidName) == "string"
            and type(keystoneInfo) == "table"
            and NormalizePlayerName(openRaidName) == normalizedPlayerName
        then
            return keystoneInfo
        end
    end

    return nil
end

local function IsUnknownGroupKeyText(keyText)
    local unknownDungeonName = L("UNKNOWN_DUNGEON")
    return type(keyText) == "string"
        and type(unknownDungeonName) == "string"
        and unknownDungeonName ~= ""
        and string.find(keyText, unknownDungeonName, 1, true) ~= nil
end

local function TrySupplementGroupKeyEntryFromOpenRaid(entry, request)
    if type(entry) ~= "table" or entry.respondedViaOpenRaid == true then
        return false
    end

    if entry.responded == true and (not entry.keyText or entry.keyText == "") then
        return false
    end

    if entry.responded == true and not IsUnknownGroupKeyText(entry.keyText) then
        return false
    end

    local normalizedName = NormalizePlayerName(entry.fullName)
    local openRaidResponse = normalizedName
        and request
        and type(request.openRaidResponders) == "table"
        and request.openRaidResponders[normalizedName]
        or nil
    local ratingResponder = normalizedName
        and request
        and type(request.openRaidRatingResponders) == "table"
        and request.openRaidRatingResponders[normalizedName] == true
        or false
    if openRaidResponse == nil and ratingResponder ~= true then
        return false
    end

    local keystoneInfo = nil
    if type(openRaidResponse) == "table" then
        keystoneInfo = openRaidResponse
    elseif openRaidResponse ~= nil then
        keystoneInfo = FindOpenRaidKeystoneInfo(entry.fullName)
    end
    local keyText = BuildKeystoneText(
        keystoneInfo and keystoneInfo.level,
        keystoneInfo and keystoneInfo.challengeMapID,
        keystoneInfo and keystoneInfo.mapID,
        keystoneInfo and keystoneInfo.mythicPlusMapID
    )

    entry.respondedViaOpenRaid = true
    entry.keyText = keyText
    if request and request.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Details Auswertung %s keystoneReply=%s ratingReply=%s keyText=%s",
            entry.shortName or GetShortName(entry.fullName),
            tostring(openRaidResponse ~= nil),
            tostring(ratingResponder == true),
            tostring(keyText or "nil")
        ))
    end
    return true
end

local function DoesGroupKeyEntryNeedOpenRaidFallback(entry)
    if type(entry) ~= "table" then
        return false
    end

    if entry.responded ~= true then
        return true
    end

    return IsUnknownGroupKeyText(entry.keyText)
end

local function BuildGroupKeysRoster()
    local playerFullName = GetPlayerFullName()
    local members = {}
    local membersByName = {}

    local function AddUnit(unit)
        local fullName = GetUnitFullNameSafe(unit)
        if not fullName or membersByName[fullName] then
            return
        end

        local entry = {
            fullName = fullName,
            shortName = GetShortName(fullName),
            responded = false,
            respondedViaOpenRaid = false,
            keyText = nil,
        }

        members[#members + 1] = entry
        membersByName[fullName] = entry
    end

    AddUnit("player")

    if IsInRaid() then
        for index = 1, (GetNumGroupMembers() or 0) do
            AddUnit("raid" .. index)
        end
    elseif IsInGroup() then
        for index = 1, (GetNumSubgroupMembers() or 0) do
            AddUnit("party" .. index)
        end
    end

    table.sort(members, function(a, b)
        if a.fullName == playerFullName then
            return true
        end

        if b.fullName == playerFullName then
            return false
        end

        return a.shortName < b.shortName
    end)

    return members, membersByName
end

local function ParseGroupKeysMessage(message)
    if type(strsplit) == "function" then
        return strsplit("\t", tostring(message or ""))
    end

    local values = {}
    for value in string.gmatch(tostring(message or "") .. "\t", "(.-)\t") do
        values[#values + 1] = value
    end

    return values[1], values[2], values[3], values[4], values[5], values[6]
end

local function FinalizeGroupKeyRequest(requestID)
    local request = pendingGroupKeyRequest
    if not request or request.id ~= requestID then
        return
    end

    local outputChannel = GetGroupKeysChannel() or request.channelName

    SendGroupKeysMessage(L("WEEKLY_KEYS_GROUP_KEYS_HEADER"), outputChannel)

    for _, entry in ipairs(request.members) do
        local usedOpenRaidFallback = false
        if request.allowOpenRaidFallback == true then
            usedOpenRaidFallback = TrySupplementGroupKeyEntryFromOpenRaid(entry, request)
        end

        local keyText = entry.keyText

        if entry.responded ~= true and usedOpenRaidFallback ~= true then
            keyText = L("WEEKLY_KEYS_GROUP_KEYS_NO_RESPONSE")
        elseif not keyText or keyText == "" then
            keyText = L("WEEKLY_KEYS_GROUP_KEYS_NONE")
        end

        if request.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage(string.format(
                "Final %s responded=%s viaDetails=%s keyText=%s",
                entry.shortName,
                tostring(entry.responded == true),
                tostring(usedOpenRaidFallback == true),
                tostring(keyText)
            ))
        end

        SendGroupKeysMessage(string.format(L("WEEKLY_KEYS_GROUP_KEYS_ENTRY"), entry.shortName, keyText), outputChannel)
    end

    pendingGroupKeyRequest = nil
end

local function ContinueGroupKeyRequestWithFallback(requestID)
    local request = pendingGroupKeyRequest
    if not request or request.id ~= requestID then
        return
    end

    if request.openRaidAttempted == true then
        FinalizeGroupKeyRequest(requestID)
        return
    end

    local needsOpenRaidFallback = false
    for _, entry in ipairs(request.members) do
        if DoesGroupKeyEntryNeedOpenRaidFallback(entry) then
            needsOpenRaidFallback = true
            break
        end
    end

    if not needsOpenRaidFallback then
        if request.debugEnabled == true and AddGroupKeysDebugMessage then
            AddGroupKeysDebugMessage("Details Fallback nicht nötig")
        end
        FinalizeGroupKeyRequest(requestID)
        return
    end

    if request.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage("Details Fallback gestartet")
    end

    request.openRaidAttempted = true
    request.openRaidResponders = {}
    request.openRaidRatingResponders = {}
    local requestedKeystoneData = RequestOpenRaidGroupKeys()
    local requestedRatingData = RequestOpenRaidGroupRatings()
    request.allowOpenRaidFallback = requestedKeystoneData == true or requestedRatingData == true
    if request.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Details Fallback Ergebnis keystone=%s rating=%s active=%s",
            tostring(requestedKeystoneData == true),
            tostring(requestedRatingData == true),
            tostring(request.allowOpenRaidFallback == true)
        ))
    end
    if request.allowOpenRaidFallback ~= true then
        FinalizeGroupKeyRequest(requestID)
        return
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(GROUP_KEYS_OPENRAID_RESPONSE_TIMEOUT, function()
            FinalizeGroupKeyRequest(requestID)
        end)
    else
        FinalizeGroupKeyRequest(requestID)
    end
end

local function StartGroupKeyRequest()
    local channelName = GetGroupKeysChannel()
    if not channelName then
        AddChatMessage(L("WEEKLY_KEYS_GROUP_KEYS_NO_GROUP"))
        return
    end

    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        AddChatMessage(L("WEEKLY_KEYS_GROUP_KEYS_UNAVAILABLE"))
        return
    end

    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end

    local members, membersByName = BuildGroupKeysRoster()
    if #members <= 0 then
        AddChatMessage(L("WEEKLY_KEYS_GROUP_KEYS_NO_GROUP"))
        return
    end

    groupKeyRequestSequence = groupKeyRequestSequence + 1

    local requestID = string.format("%d-%d", GetTimestamp(), groupKeyRequestSequence)
    local playerFullName = GetPlayerFullName()

    if GROUP_KEYS_DEBUG_ENABLED == true
        and BeavisQoL.DebugConsole
        and BeavisQoL.DebugConsole.Clear
    then
        BeavisQoL.DebugConsole.Clear(
            GROUP_KEYS_DEBUG_MODULE_KEY,
            { titleText = "GRP-Keys", select = true }
        )
    end

    pendingGroupKeyRequest = {
        id = requestID,
        channelName = channelName,
        members = members,
        membersByName = membersByName,
        allowOpenRaidFallback = false,
        openRaidAttempted = false,
        openRaidResponders = nil,
        openRaidRatingResponders = nil,
        debugEnabled = GROUP_KEYS_DEBUG_ENABLED == true,
        debugLoggedLibState = false,
        debugLines = {},
    }

    local ownEntry = playerFullName and membersByName[playerFullName] or nil
    if ownEntry then
        ownEntry.responded = true
        ownEntry.keyText = GetOwnedKeystoneText()
    end

    if pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Start req=%s channel=%s members=%d own=%s",
            requestID,
            tostring(channelName),
            #members,
            tostring((ownEntry and ownEntry.keyText) or "nil")
        ))
    end

    C_ChatInfo.SendAddonMessage(
        GROUP_KEYS_PREFIX,
        GROUP_KEYS_MESSAGE_QUERY .. "\t" .. requestID,
        channelName
    )

    if C_Timer and C_Timer.After then
        C_Timer.After(GROUP_KEYS_RESPONSE_TIMEOUT, function()
            ContinueGroupKeyRequestWithFallback(requestID)
        end)
    else
        ContinueGroupKeyRequestWithFallback(requestID)
    end
end

local function HandleGroupKeysAddonMessage(prefix, message, channelName, sender)
    if prefix ~= GROUP_KEYS_PREFIX then
        return false
    end

    local messageType, requestID, mapIDText, levelText, challengeMapIDText, mythicPlusMapIDText = ParseGroupKeysMessage(message)
    local normalizedSender = NormalizePlayerName(sender)

    if messageType == GROUP_KEYS_MESSAGE_QUERY then
        if normalizedSender ~= GetPlayerFullName()
            and C_ChatInfo
            and C_ChatInfo.SendAddonMessage
            and channelName
            and requestID
            and requestID ~= ""
        then
            local keystoneLevel, challengeMapID, mapID = GetOwnedKeystoneData()

            C_ChatInfo.SendAddonMessage(
                GROUP_KEYS_PREFIX,
                table.concat({
                    GROUP_KEYS_MESSAGE_REPLY,
                    requestID,
                    tostring(tonumber(mapID) or 0),
                    tostring(tonumber(keystoneLevel) or 0),
                    tostring(tonumber(challengeMapID) or 0),
                }, "\t"),
                channelName
            )
        end

        return true
    end

    if messageType ~= GROUP_KEYS_MESSAGE_REPLY
        or not pendingGroupKeyRequest
        or requestID ~= pendingGroupKeyRequest.id
        or not normalizedSender
    then
        return true
    end

    local entry = pendingGroupKeyRequest.membersByName and pendingGroupKeyRequest.membersByName[normalizedSender] or nil
    if not entry then
        return true
    end

    local mapID = tonumber(mapIDText) or 0
    local keystoneLevel = tonumber(levelText) or 0
    local challengeMapID = tonumber(challengeMapIDText) or 0
    local mythicPlusMapID = tonumber(mythicPlusMapIDText) or 0

    entry.responded = true
    entry.keyText = BuildKeystoneText(keystoneLevel, challengeMapID, mapID, mythicPlusMapID)
    if pendingGroupKeyRequest and pendingGroupKeyRequest.debugEnabled == true and AddGroupKeysDebugMessage then
        AddGroupKeysDebugMessage(string.format(
            "Beavis Reply %s level=%s map=%s challenge=%s mythic=%s keyText=%s",
            entry.shortName,
            tostring(keystoneLevel),
            tostring(mapID),
            tostring(challengeMapID),
            tostring(mythicPlusMapID),
            tostring(entry.keyText or "nil")
        ))
    end

    return true
end

local function GetWeeklyRunHistory()
    -- Die Rohdaten aus der API werden direkt nach "wichtigster Lauf zuerst"
    -- sortiert: höhere Stufe, dann timed vor depleted, dann Name.
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
    local hasNonKeystoneRunCounts = false

    if C_WeeklyRewards and C_WeeklyRewards.GetNumCompletedDungeonRuns then
        local heroicCount, mythicCount, mythicPlusCount = C_WeeklyRewards.GetNumCompletedDungeonRuns()
        if heroicCount ~= nil or mythicCount ~= nil then
            hasNonKeystoneRunCounts = true
        end

        heroicRuns = math.max(0, tonumber(heroicCount) or 0)
        mythicRuns = math.max(0, tonumber(mythicCount) or 0)
        mythicPlusRuns = math.max(mythicPlusRuns, tonumber(mythicPlusCount) or 0)
    end

    return heroicRuns, mythicRuns, mythicPlusRuns, hasNonKeystoneRunCounts
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
    -- So bleibt die restliche Datei frei von nil- und Altwert-Sonderfällen.
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.weeklyKeys = BeavisQoLDB.weeklyKeys or {}

    local db = BeavisQoLDB.weeklyKeys

    if db.overlayEnabled == nil then
        db.overlayEnabled = false
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if db.hideOverlayInRaid == nil then
        db.hideOverlayInRaid = false
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

AddChatMessage = function(message)
    if type(message) ~= "string" or message == "" then
        return
    end

    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66d9efBeavisQoL:|r " .. message)
    end
end

SendGroupKeysMessage = function(message, channelName)
    if type(message) ~= "string" or message == "" then
        return
    end

    local effectiveChannel = channelName
    if type(effectiveChannel) ~= "string" or effectiveChannel == "" then
        effectiveChannel = GetGroupKeysChannel()
    end

    if type(effectiveChannel) == "string"
        and effectiveChannel ~= ""
        and type(SendChatMessage) == "function"
    then
        local ok = pcall(SendChatMessage, message, effectiveChannel)
        if ok then
            return
        end
    end

    AddChatMessage(message)
end

AddGroupKeysDebugMessage = function(message)
    if GROUP_KEYS_DEBUG_ENABLED ~= true then
        return
    end

    local request = pendingGroupKeyRequest
    if not request or request.debugEnabled ~= true then
        return
    end

    local debugLine = "GRP-Keys Debug: " .. tostring(message)
    request.debugLines = request.debugLines or {}
    request.debugLines[#request.debugLines + 1] = debugLine

    if BeavisQoL.DebugConsole and BeavisQoL.DebugConsole.AppendLine then
        BeavisQoL.DebugConsole.AppendLine(
            GROUP_KEYS_DEBUG_MODULE_KEY,
            debugLine,
            { titleText = "GRP-Keys", select = true }
        )
    end
end

GetShortName = function(name)
    if not name or name == "" then
        return L("UNKNOWN")
    end

    if Ambiguate then
        return Ambiguate(name, "short")
    end

    return name
end

GetDefaultRealmName = function()
    if GetNormalizedRealmName then
        local normalizedRealmName = GetNormalizedRealmName()
        if normalizedRealmName and normalizedRealmName ~= "" then
            return normalizedRealmName
        end
    end

    local _, realmName = UnitFullName("player")
    if realmName and realmName ~= "" then
        return realmName
    end

    return nil
end

NormalizePlayerName = function(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    if string.find(name, "-", 1, true) then
        return name
    end

    local realmName = GetDefaultRealmName()
    if realmName and realmName ~= "" then
        return name .. "-" .. realmName
    end

    return name
end

GetUnitFullNameSafe = function(unit)
    if not unit or not UnitExists or not UnitExists(unit) then
        return nil
    end

    local playerName, realmName = UnitFullName(unit)
    if not playerName or playerName == "" then
        return nil
    end

    realmName = realmName or GetDefaultRealmName()
    if realmName and realmName ~= "" then
        return playerName .. "-" .. realmName
    end

    return playerName
end

GetPlayerFullName = function()
    return GetUnitFullNameSafe("player")
end

local function IsPlayerInAnyRaidGroup()
    if type(IsInRaid) ~= "function" then
        return false
    end

    if LE_PARTY_CATEGORY_HOME and IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return true
    end

    if LE_PARTY_CATEGORY_INSTANCE and IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
        return true
    end

    return IsInRaid() == true
end

local function ShouldHideOverlayInRaidGroup()
    local settings = GetWeeklyKeysSettings()
    return settings.hideOverlayInRaid == true and IsPlayerInAnyRaidGroup()
end

local function ShouldHideWeeklyKeysOverlay()
    return ShouldHideOverlayInCombat() or ShouldHideOverlayInRaidGroup()
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

function WeeklyKeysModule.IsHideOverlayInRaidEnabled()
    return GetWeeklyKeysSettings().hideOverlayInRaid == true
end

function WeeklyKeysModule.SetHideOverlayInRaidEnabled(enabled)
    GetWeeklyKeysSettings().hideOverlayInRaid = enabled == true
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
    -- Overlay ohne "Zurückspringen" verschieben kann.
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
    slider.Text:SetTextColor(1, 0.88, 0.62, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(0.95, 0.91, 0.85, 1)

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
    local anchorOffsetX = anchor and anchor.BeavisNextCheckboxOffsetX or -4
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorOffsetX, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    label:SetText(titleText)

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    hint:SetTextColor(0.78, 0.74, 0.69, 1)
    hint:SetText(hintText)
    hint.BeavisNextCheckboxOffsetX = -34
    checkbox.BeavisNextCheckboxOffsetX = 0

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
        rankText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        rankText:SetTextColor(DIM_COLOR[1], DIM_COLOR[2], DIM_COLOR[3], 1)
        row.RankText = rankText

        local statusText = row:CreateFontString(nil, "OVERLAY")
        statusText:SetJustifyH("LEFT")
        statusText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
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
    glowTexture:SetColorTexture(0.88, 0.72, 0.46, 0.05 + (alpha * 0.12))
    accentTexture:SetColorTexture(0.88, 0.72, 0.46, 0.12 + (alpha * 0.30))
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
    local heroicRunCount, mythicRunCount, mythicPlusRunCount, hasNonKeystoneRunCounts = GetWeeklyDungeonRunCounts(#runHistory)
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
            if not hasNonKeystoneRunCounts or trackedMythicRuns < mythicRunCount then
                trackedMythicRuns = trackedMythicRuns + 1
                shouldAddEntry = true
            end
        elseif entry.difficultyCategory == "heroic" then
            if not hasNonKeystoneRunCounts or trackedHeroicRuns < heroicRunCount then
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

    if hasNonKeystoneRunCounts then
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

    local nonKeystoneRunCount = hasNonKeystoneRunCounts and (heroicRunCount + mythicRunCount) or #trackedNonKeystoneRuns
    local totalDungeonCount = mythicPlusRunCount + nonKeystoneRunCount
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

local function InvalidateDisplayRowsCache()
    DisplayRowsDirty = true
end

local function GetCachedDisplayRows()
    if DisplayRowsDirty or CachedDisplayRows == nil or CachedDisplaySummaryText == nil then
        CachedDisplayRows, CachedDisplaySummaryText = BuildDisplayRows()
        DisplayRowsDirty = false
    end

    return CachedDisplayRows, CachedDisplaySummaryText
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

local function GetPreviewCardSizeFromSettings(settings)
    local metrics = GetLayoutMetrics(settings.fontSize, settings.overlayScale)
    local rowCount = #PreviewRows > 0 and #PreviewRows or 8
    local totalHeight = metrics.topPadding
        + metrics.bottomPadding
        + (rowCount * metrics.lineHeight)
        + ((rowCount - 1) * metrics.rowSpacing)

    return metrics.width, totalHeight
end

local function UpdateRunRows(parent, targetRows, fontSize, summaryFontSize, scale, titleTextObject, summaryTextObject, backgroundTexture, glowTexture, accentTexture)
    -- Layout und Datenfluss treffen sich genau hier:
    -- Zuerst werden die Zeileninhalte gebaut, danach werden Fonts, Abstaende
    -- und Positionen auf die sichtbaren Rows verteilt.
    local settings = GetWeeklyKeysSettings()
    local rowsData, summaryText = GetCachedDisplayRows()
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

local UpdateWeeklyKeysRefreshTickerState
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

    if settings.overlayEnabled and not ShouldHideWeeklyKeysOverlay() then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end

    if UpdateWeeklyKeysRefreshTickerState then
        UpdateWeeklyKeysRefreshTickerState()
    end
end

local RefreshTicker = CreateFrame("Frame")
local RefreshTickerHandle = nil
local function RunWeeklyKeysRefreshTicker()
    local profiler = BeavisQoL.PerformanceProfiler
    local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
    local needsRefresh = (PageWeeklyKeys and PageWeeklyKeys:IsShown()) or (OverlayFrame and OverlayFrame:IsShown())
    if not needsRefresh then
        if UpdateWeeklyKeysRefreshTickerState then
            UpdateWeeklyKeysRefreshTickerState()
        end
        if profiler and profiler.EndSample then
            profiler.EndSample("WeeklyKeys.RefreshTicker", sampleToken)
        end
        return
    end

    local settings = GetWeeklyKeysSettings()

    if not DisplayRowsDirty then
        if OverlayFrame then
            if settings.overlayEnabled and not ShouldHideWeeklyKeysOverlay() then
                OverlayFrame:Show()
            else
                OverlayFrame:Hide()
            end
        end

        if profiler and profiler.EndSample then
            profiler.EndSample("WeeklyKeys.RefreshTicker", sampleToken)
        end
        return
    end

    if PageWeeklyKeys and PageWeeklyKeys:IsShown() then
        RefreshPreview()
    end

    if OverlayFrame and (OverlayFrame:IsShown() or settings.overlayEnabled) then
        WeeklyKeysModule.RefreshOverlayWindow()
    end

    if profiler and profiler.EndSample then
        profiler.EndSample("WeeklyKeys.RefreshTicker", sampleToken)
    end
end

UpdateWeeklyKeysRefreshTickerState = function()
    local shouldRefresh = (PageWeeklyKeys and PageWeeklyKeys:IsShown()) or (OverlayFrame and OverlayFrame:IsShown())

    if shouldRefresh then
        if RefreshTickerHandle == nil and C_Timer and C_Timer.NewTicker then
            RefreshTickerHandle = C_Timer.NewTicker(REFRESH_INTERVAL, RunWeeklyKeysRefreshTicker)
        elseif RefreshTickerHandle == nil then
            RefreshTicker.elapsed = 0
            RefreshTicker:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed < REFRESH_INTERVAL then
                    return
                end

                self.elapsed = 0
                RunWeeklyKeysRefreshTicker()
            end)
        end
    else
        if RefreshTickerHandle then
            RefreshTickerHandle:Cancel()
            RefreshTickerHandle = nil
        end

        RefreshTicker.elapsed = 0
        RefreshTicker:SetScript("OnUpdate", nil)
    end
end

local function RefreshAllDisplays()
    InvalidateDisplayRowsCache()
    -- Ein Aufruf für Vorschau, Overlay und Datenanfrage.
    RequestVaultData()
    RefreshPreview()
    WeeklyKeysModule.RefreshOverlayWindow()
end

PageWeeklyKeys = CreateFrame("Frame", nil, Content)
PageWeeklyKeys:SetAllPoints()
PageWeeklyKeys:Hide()

local PageWeeklyKeysScrollFrame = CreateFrame("ScrollFrame", nil, PageWeeklyKeys, "UIPanelScrollFrameTemplate")
PageWeeklyKeysScrollFrame:SetPoint("TOPLEFT", PageWeeklyKeys, "TOPLEFT", 0, 0)
PageWeeklyKeysScrollFrame:SetPoint("BOTTOMRIGHT", PageWeeklyKeys, "BOTTOMRIGHT", -28, 0)
PageWeeklyKeysScrollFrame:EnableMouseWheel(true)

local PageWeeklyKeysContent = CreateFrame("Frame", nil, PageWeeklyKeysScrollFrame)
PageWeeklyKeysContent:SetSize(1, 1)
PageWeeklyKeysScrollFrame:SetScrollChild(PageWeeklyKeysContent)

local IntroPanel = CreateFrame("Frame", nil, PageWeeklyKeysContent)
IntroPanel:SetPoint("TOPLEFT", PageWeeklyKeysContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageWeeklyKeysContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(1)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
IntroTitle:SetTextColor(1, 0.88, 0.62, 1)
IntroTitle:SetText(BeavisQoL.GetModulePageTitle("WeeklyKeys", L("WEEKLY_KEYS")))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
IntroText:SetText(L("WEEKLY_KEYS_DESC"))

local PreviewPanel = CreateFrame("Frame", nil, PageWeeklyKeysContent)
PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
PreviewPanel:SetSize(1, 1)

local PreviewPanelBg = PreviewPanel:CreateTexture(nil, "BACKGROUND")
PreviewPanelBg:SetAllPoints()
PreviewPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local PreviewPanelBorder = PreviewPanel:CreateTexture(nil, "ARTWORK")
PreviewPanelBorder:SetPoint("BOTTOMLEFT", PreviewPanel, "BOTTOMLEFT", 0, 0)
PreviewPanelBorder:SetPoint("BOTTOMRIGHT", PreviewPanel, "BOTTOMRIGHT", 0, 0)
PreviewPanelBorder:SetHeight(1)
PreviewPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local PreviewPanelTitle = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewPanelTitle:SetPoint("TOPLEFT", PreviewPanel, "TOPLEFT", 18, -14)
PreviewPanelTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
PreviewPanelTitle:SetTextColor(1, 0.88, 0.62, 1)
PreviewPanelTitle:SetText(L("LIVE_PREVIEW"))

local PreviewPanelHint = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewPanelHint:SetPoint("TOPLEFT", PreviewPanelTitle, "BOTTOMLEFT", 0, -8)
PreviewPanelHint:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewPanelHint:SetJustifyH("LEFT")
PreviewPanelHint:SetJustifyV("TOP")
PreviewPanelHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
PreviewPanelHint:SetTextColor(0.78, 0.74, 0.69, 1)
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
PreviewTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
PreviewTitle:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3], 1)
PreviewTitle:SetText(L("WEEKLY_KEYS"))

PreviewSummary = PreviewCard:CreateFontString(nil, "OVERLAY")
PreviewSummary:SetPoint("TOPLEFT", PreviewTitle, "BOTTOMLEFT", 0, -4)
PreviewSummary:SetPoint("RIGHT", PreviewCard, "RIGHT", -12, 0)
PreviewSummary:SetJustifyH("LEFT")
PreviewSummary:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
PreviewSummary:SetTextColor(0.78, 0.74, 0.69, 1)

CreateRunRows(PreviewCard, PreviewRows)

local PreviewFooter = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewFooter:SetPoint("TOPLEFT", PreviewCard, "BOTTOMLEFT", 0, -14)
PreviewFooter:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewFooter:SetJustifyH("LEFT")
PreviewFooter:SetJustifyV("TOP")
PreviewFooter:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
PreviewFooter:SetTextColor(0.72, 0.72, 0.72, 1)
PreviewFooter:SetText(L("WEEKLY_KEYS_PREVIEW_FOOTER"))

local SettingsPanel = CreateFrame("Frame", nil, PageWeeklyKeysContent)
SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", 18, 0)
SettingsPanel:SetSize(1, 1)

local SettingsBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsBg:SetAllPoints()
SettingsBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local SettingsBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsBorder:SetHeight(1)
SettingsBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.88, 0.62, 1)
SettingsTitle:SetText(L("DISPLAY_POSITION"))

local SettingsHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsHint:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", 0, -8)
SettingsHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsHint:SetJustifyH("LEFT")
SettingsHint:SetJustifyV("TOP")
SettingsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsHint:SetTextColor(0.78, 0.74, 0.69, 1)
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

local hideInRaidLabel, hideInRaidHint
HideInRaidCheckbox, hideInRaidLabel, hideInRaidHint = CreateSectionCheckbox(
    SettingsPanel,
    lockOverlayHint,
    L("WEEKLY_KEYS_HIDE_IN_RAID"),
    L("WEEKLY_KEYS_HIDE_IN_RAID_HINT")
)

local minimapContextLabel, minimapContextHint
local MinimapContextCheckbox
MinimapContextCheckbox, minimapContextLabel, minimapContextHint = CreateSectionCheckbox(
    SettingsPanel,
    hideInRaidHint,
    L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"),
    L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT")
)

FontSizeSlider = CreateValueSlider(SettingsPanel, L("FONT_SIZE_OVERLAY"), MIN_FONT_SIZE, MAX_FONT_SIZE, 1, "font")
FontSizeSlider:SetPoint("TOPLEFT", minimapContextHint, "BOTTOMLEFT", 18, -34)

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
ResetHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
ResetHint:SetText(L("WEEKLY_KEYS_RESET_HINT"))

function PageWeeklyKeys:UpdateScrollLayout()
    local contentWidth = math.max(1, PageWeeklyKeysScrollFrame:GetWidth())

    if contentWidth <= 1 then
        return
    end

    local settings = GetWeeklyKeysSettings()
    local previewCardWidth, previewCardHeight = GetPreviewCardSizeFromSettings(settings)

    if PreviewCard and PreviewCard:GetWidth() and PreviewCard:GetWidth() > 0 then
        previewCardWidth = PreviewCard:GetWidth()
    end

    if PreviewCard and PreviewCard:GetHeight() and PreviewCard:GetHeight() > 0 then
        previewCardHeight = PreviewCard:GetHeight()
    end

    local outerPadding = 20
    local columnGap = 18
    local availableWidth = math.max(1, contentWidth - (outerPadding * 2))
    local previewNeededWidth = math.max(392, previewCardWidth + 36)
    local settingsMinWidth = 360
    local useTwoColumns = availableWidth >= (previewNeededWidth + columnGap + settingsMinWidth)

    PageWeeklyKeysContent:SetWidth(contentWidth)

    IntroPanel:SetHeight(math.max(
        112,
        math.ceil(
            16
            + GetTextHeight(IntroTitle, 24)
            + 10
            + GetTextHeight(IntroText, 13)
            + 18
        )
    ))

    PreviewPanel:ClearAllPoints()
    PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)

    if useTwoColumns then
        local settingsWidth = availableWidth - previewNeededWidth - columnGap

        PreviewPanel:SetWidth(previewNeededWidth)

        SettingsPanel:ClearAllPoints()
        SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", columnGap, 0)
        SettingsPanel:SetWidth(settingsWidth)
    else
        PreviewPanel:SetWidth(availableWidth)

        SettingsPanel:ClearAllPoints()
        SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "BOTTOMLEFT", 0, -18)
        SettingsPanel:SetWidth(availableWidth)
    end

    local sliderWidth = math.max(220, math.min(360, SettingsPanel:GetWidth() - 36))
    FontSizeSlider:SetWidth(sliderWidth)
    ScaleSlider:SetWidth(sliderWidth)
    BackgroundAlphaSlider:SetWidth(sliderWidth)

    local previewPanelHeight = math.max(
        326,
        math.ceil(
            14
            + GetTextHeight(PreviewPanelTitle, 16)
            + 8
            + GetTextHeight(PreviewPanelHint, 12)
            + 18
            + previewCardHeight
            + 14
            + GetTextHeight(PreviewFooter, 11)
            + 18
        )
    )
    PreviewPanel:SetHeight(previewPanelHeight)

    local settingsPanelHeight = math.max(
        452,
        math.ceil(
            14
            + GetTextHeight(SettingsTitle, 16)
            + 8
            + GetTextHeight(SettingsHint, 12)
            + 14 + ShowOverlayCheckbox:GetHeight() + 2 + GetTextHeight(showOverlayHint, 12)
            + 14 + LockOverlayCheckbox:GetHeight() + 2 + GetTextHeight(lockOverlayHint, 12)
            + 14 + HideInRaidCheckbox:GetHeight() + 2 + GetTextHeight(hideInRaidHint, 12)
            + 14 + MinimapContextCheckbox:GetHeight() + 2 + GetTextHeight(minimapContextHint, 12)
            + 34 + FontSizeSlider:GetHeight()
            + 44 + ScaleSlider:GetHeight()
            + 44 + BackgroundAlphaSlider:GetHeight()
            + 28 + math.max(ResetPositionButton:GetHeight(), GetTextHeight(ResetHint, 11))
            + 18
        )
    )
    SettingsPanel:SetHeight(settingsPanelHeight)

    local contentHeight = 20 + IntroPanel:GetHeight() + 18
    if useTwoColumns then
        contentHeight = contentHeight + math.max(PreviewPanel:GetHeight(), SettingsPanel:GetHeight()) + 20
    else
        contentHeight = contentHeight + PreviewPanel:GetHeight() + 18 + SettingsPanel:GetHeight() + 20
    end

    PageWeeklyKeysContent:SetHeight(math.max(PageWeeklyKeysScrollFrame:GetHeight(), math.ceil(contentHeight)))
end

OverlayFrame = CreateFrame("Frame", "BeavisQoLWeeklyKeysOverlayFrame", UIParent)
OverlayFrame:SetClampedToScreen(true)
OverlayFrame:SetMovable(true)
OverlayFrame:SetToplevel(false)
-- Weekly Keys soll im normalen Spielbild sichtbar bleiben, aber Blizzard-
-- und Battle.net-Overlays nicht überdecken.
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
OverlayTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
OverlayTitle:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3], 1)
OverlayTitle:SetText(L("WEEKLY_KEYS"))

OverlaySummary = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlaySummary:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -4)
OverlaySummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -86, 0)
OverlaySummary:SetJustifyH("LEFT")
OverlaySummary:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
OverlaySummary:SetTextColor(0.78, 0.74, 0.69, 1)

GroupKeysButton = CreateFrame("Button", nil, OverlayFrame, "UIPanelButtonTemplate")
GroupKeysButton:SetSize(64, 18)
GroupKeysButton:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", -10, -8)
GroupKeysButton:SetText(L("WEEKLY_KEYS_GROUP_KEYS_BUTTON"))
GroupKeysButton:SetNormalFontObject(GameFontNormalSmall)
GroupKeysButton:SetHighlightFontObject(GameFontHighlightSmall)

CreateRunRows(OverlayFrame, OverlayRows)

FontSizeSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetFontSize(value)
    RefreshPreview()
    PageWeeklyKeys:UpdateScrollLayout()
end

ScaleSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetOverlayScale(value)
    RefreshPreview()
    PageWeeklyKeys:UpdateScrollLayout()
end

BackgroundAlphaSlider.ApplyValue = function(_, value)
    WeeklyKeysModule.SetBackgroundAlpha(value)
    RefreshPreview()
    PageWeeklyKeys:UpdateScrollLayout()
end

ShowOverlayCheckbox:SetScript("OnClick", function(self)
    WeeklyKeysModule.SetOverlayEnabled(self:GetChecked())
    PageWeeklyKeys:RefreshState()
end)

LockOverlayCheckbox:SetScript("OnClick", function(self)
    WeeklyKeysModule.SetOverlayLocked(self:GetChecked())
end)

HideInRaidCheckbox:SetScript("OnClick", function(self)
    WeeklyKeysModule.SetHideOverlayInRaidEnabled(self:GetChecked())
    PageWeeklyKeys:RefreshState()
end)

MinimapContextCheckbox:SetScript("OnClick", function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("weeklyKeys", self:GetChecked())
    end
end)

ResetPositionButton:SetScript("OnClick", function()
    WeeklyKeysModule.ResetOverlayPosition()
end)

GroupKeysButton:SetScript("OnClick", function()
    StartGroupKeyRequest()
end)

GroupKeysButton:SetScript("OnEnter", function(self)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L("WEEKLY_KEYS_GROUP_KEYS_BUTTON"), 1, 0.82, 0)
    GameTooltip:AddLine(L("WEEKLY_KEYS_GROUP_KEYS_HINT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)

GroupKeysButton:SetScript("OnLeave", function()
    if GameTooltip then
        GameTooltip:Hide()
    end
end)

function PageWeeklyKeys:RefreshState()
    -- Liest den kompletten Modulzustand aus der DB und schreibt ihn gesammelt
    -- in Checkboxen, Slider und Vorschau.
    local settings = GetWeeklyKeysSettings()

    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("WeeklyKeys", L("WEEKLY_KEYS")))
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
    hideInRaidLabel:SetText(L("WEEKLY_KEYS_HIDE_IN_RAID"))
    hideInRaidHint:SetText(L("WEEKLY_KEYS_HIDE_IN_RAID_HINT"))
    minimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    minimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))
    FontSizeSlider.Text:SetText(L("FONT_SIZE_OVERLAY"))
    ScaleSlider.Text:SetText(L("WINDOW_SCALE"))
    BackgroundAlphaSlider.Text:SetText(L("BACKGROUND_ALPHA"))
    ResetPositionButton:SetText(L("RESET_POSITION"))
    ResetHint:SetText(L("WEEKLY_KEYS_RESET_HINT"))
    GroupKeysButton:SetText(L("WEEKLY_KEYS_GROUP_KEYS_BUTTON"))
    OverlayTitle:SetText(L("WEEKLY_KEYS"))

    isRefreshing = true
    ShowOverlayCheckbox:SetChecked(settings.overlayEnabled)
    LockOverlayCheckbox:SetChecked(settings.overlayLocked)
    HideInRaidCheckbox:SetChecked(settings.hideOverlayInRaid == true)
    MinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("weeklyKeys") or true)
    FontSizeSlider:SetValue(settings.fontSize)
    ScaleSlider:SetValue(settings.overlayScale)
    BackgroundAlphaSlider:SetValue(settings.backgroundAlpha)
    isRefreshing = false

    RefreshAllDisplays()
    self:UpdateScrollLayout()
end

PageWeeklyKeysScrollFrame:SetScript("OnSizeChanged", function()
    PageWeeklyKeys:UpdateScrollLayout()
end)

PageWeeklyKeysScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageWeeklyKeysContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageWeeklyKeys:SetScript("OnShow", function()
    PageWeeklyKeys:RefreshState()
    PageWeeklyKeysScrollFrame:SetVerticalScroll(0)
    UpdateWeeklyKeysRefreshTickerState()
end)

PageWeeklyKeys:SetScript("OnHide", function()
    UpdateWeeklyKeysRefreshTickerState()
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
WeeklyKeysEvents:RegisterEvent("GROUP_ROSTER_UPDATE")
WeeklyKeysEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
WeeklyKeysEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
WeeklyKeysEvents:RegisterEvent("CHAT_MSG_ADDON")
WeeklyKeysEvents:SetScript("OnEvent", function(_, eventName, ...)
    -- Alle relevanten Weekly-Vault- und Mythic+-Änderungen laufen hier zusammen.
    if eventName == "CHAT_MSG_ADDON" then
        local prefix, message, channelName, sender = ...
        if prefix == OPENRAID_ADDON_PREFIX
            and pendingGroupKeyRequest
            and pendingGroupKeyRequest.debugEnabled == true
            and pendingGroupKeyRequest.openRaidAttempted == true
            and AddGroupKeysDebugMessage
        then
            AddGroupKeysDebugMessage(string.format(
                "Raw LRS sender=%s channel=%s bytes=%s",
                tostring(sender),
                tostring(channelName),
                tostring(message and string.len(message) or 0)
            ))
        end
        HandleGroupKeysAddonMessage(prefix, message, channelName, sender)
        return
    end

    if eventName == "PLAYER_LOGIN"
        and C_ChatInfo
        and C_ChatInfo.RegisterAddonMessagePrefix
    then
        C_ChatInfo.RegisterAddonMessagePrefix(GROUP_KEYS_PREFIX)
    end

    MarkChallengeModeActivityIfNeeded()

    if eventName == "PLAYER_ENTERING_WORLD"
        or eventName == "PLAYER_LOGIN"
        or eventName == "ZONE_CHANGED_NEW_AREA"
        or eventName == "PLAYER_DIFFICULTY_CHANGED"
    then
        UpdateTrackedDungeonContext()
        if eventName == "PLAYER_ENTERING_WORLD" or eventName == "PLAYER_LOGIN" then
            RequestSavedInstanceData()
        end
    elseif eventName == "CHALLENGE_MODE_COMPLETED" then
        recentChallengeModeActivityAt = GetTimestamp()
        trackedDungeonContext.completionLogged = true
        RequestSavedInstanceData()
    elseif eventName == "SCENARIO_COMPLETED" or eventName == "LFG_COMPLETION_REWARD" then
        TrackCurrentDungeonCompletion()
        RequestSavedInstanceData()
    end

    RefreshAllDisplays()
end)

PageWeeklyKeys:RefreshState()

BeavisQoL.Pages.WeeklyKeys = PageWeeklyKeys

