local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.StreamerPlannerModule = BeavisQoL.StreamerPlannerModule or {}
local StreamerPlannerModule = BeavisQoL.StreamerPlannerModule

local DEFAULT_OVERLAY_SCALE = 1.00
local MIN_OVERLAY_SCALE = 0.80
local MAX_OVERLAY_SCALE = 1.35
local DEFAULT_MODE = "dungeon"
local DEFAULT_POINT = "CENTER"
local DEFAULT_RELATIVE_POINT = "CENTER"
local DEFAULT_OFFSET_X = 360
local DEFAULT_OFFSET_Y = 80
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local EDIT_DIALOG_WIDTH = 520
local EDIT_DIALOG_SLOT_HEIGHT = 416
local EDIT_DIALOG_DESTINATION_HEIGHT = 264
local EDIT_DIALOG_DESTINATION_KEYSTONE_HEIGHT = 308
local EDIT_CLASS_BUTTON_COLUMNS = 8
local EDIT_CLASS_BUTTON_SIZE = 36
local EDIT_CLASS_BUTTON_SPACING = 8
local EDIT_SPEC_BUTTON_SIZE = 42
local EDIT_SPEC_BUTTON_SPACING = 10
local OVERLAY_DESTINATION_HEIGHT_DUNGEON = 40
local OVERLAY_DESTINATION_HEIGHT_RAID = 54
local DEFAULT_TIMER_DURATION_SECONDS = 15 * 60
local TIMER_WARNING_THRESHOLD_SECONDS = 60
local MIN_TIMER_DURATION_MINUTES = 1
local MAX_TIMER_DURATION_MINUTES = 60

local SPEC_DATA_BY_CLASS = {
    WARRIOR = { 71, 72, 73 },
    PALADIN = { 65, 66, 70 },
    HUNTER = { 253, 254, 255 },
    ROGUE = { 259, 260, 261 },
    PRIEST = { 256, 257, 258 },
    DEATHKNIGHT = { 250, 251, 252 },
    SHAMAN = { 262, 263, 264 },
    MAGE = { 62, 63, 64 },
    WARLOCK = { 265, 266, 267 },
    MONK = { 268, 269, 270 },
    DRUID = { 102, 103, 104, 105 },
    DEMONHUNTER = { 577, 581 },
    EVOKER = { 1467, 1468, 1473 },
}

local CLASS_ROLE_SUPPORT = {
    WARRIOR = { tank = true, dps = true },
    PALADIN = { tank = true, healer = true, dps = true },
    HUNTER = { dps = true },
    ROGUE = { dps = true },
    PRIEST = { healer = true, dps = true },
    DEATHKNIGHT = { tank = true, dps = true },
    SHAMAN = { healer = true, dps = true },
    MAGE = { dps = true },
    WARLOCK = { dps = true },
    MONK = { tank = true, healer = true, dps = true },
    DRUID = { tank = true, healer = true, dps = true },
    DEMONHUNTER = { tank = true, dps = true },
    EVOKER = { healer = true, dps = true },
}

local SPEC_ROLE_SUPPORT = {
    [71] = "dps",
    [72] = "dps",
    [73] = "tank",
    [65] = "healer",
    [66] = "tank",
    [70] = "dps",
    [253] = "dps",
    [254] = "dps",
    [255] = "dps",
    [259] = "dps",
    [260] = "dps",
    [261] = "dps",
    [256] = "healer",
    [257] = "healer",
    [258] = "dps",
    [250] = "tank",
    [251] = "dps",
    [252] = "dps",
    [262] = "dps",
    [263] = "dps",
    [264] = "healer",
    [62] = "dps",
    [63] = "dps",
    [64] = "dps",
    [265] = "dps",
    [266] = "dps",
    [267] = "dps",
    [268] = "tank",
    [269] = "dps",
    [270] = "healer",
    [102] = "dps",
    [103] = "dps",
    [104] = "tank",
    [105] = "healer",
    [577] = "dps",
    [581] = "tank",
    [1467] = "dps",
    [1468] = "healer",
    [1473] = "dps",
}

local DUNGEON_SLOT_ROLE_REQUIREMENTS = {
    tank = "tank",
    healer = "healer",
    dps1 = "dps",
    dps2 = "dps",
    dps3 = "dps",
}

local DESTINATION_CATEGORIES = {
    { key = "s1", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_S1" },
    { key = "delves", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_DELVES" },
    { key = "midnight", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_MIDNIGHT" },
    { key = "raids", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_RAIDS" },
}

local DESTINATION_OPTIONS = {
    s1 = {
        "STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE",
        "STREAMER_PLANNER_DESTINATION_S1_MAISARA_CAVERNS",
        "STREAMER_PLANNER_DESTINATION_S1_NEXUS_POINT_XENAS",
        "STREAMER_PLANNER_DESTINATION_S1_WINDRUNNER_SPIRE",
        "STREAMER_PLANNER_DESTINATION_S1_ALGETHAR_ACADEMY",
        "STREAMER_PLANNER_DESTINATION_S1_PIT_OF_SARON",
        "STREAMER_PLANNER_DESTINATION_S1_SEAT_OF_THE_TRIUMVIRATE",
        "STREAMER_PLANNER_DESTINATION_S1_SKYREACH",
    },
    delves = {
        "STREAMER_PLANNER_DESTINATION_DELVE_ATAL_AMAN",
        "STREAMER_PLANNER_DESTINATION_DELVE_COLLEGIATE_CALAMITY",
        "STREAMER_PLANNER_DESTINATION_DELVE_DEN_OF_ECHOES",
        "STREAMER_PLANNER_DESTINATION_DELVE_PARHELION_PLAZA",
        "STREAMER_PLANNER_DESTINATION_DELVE_SHADOWGUARD_POINT",
        "STREAMER_PLANNER_DESTINATION_DELVE_SUNKILLER_SANCTUM",
        "STREAMER_PLANNER_DESTINATION_DELVE_THE_DARKWAY",
        "STREAMER_PLANNER_DESTINATION_DELVE_THE_GRUDGE_PIT",
        "STREAMER_PLANNER_DESTINATION_DELVE_THE_GULF_OF_MEMORY",
        "STREAMER_PLANNER_DESTINATION_DELVE_THE_SHADOW_ENCLAVE",
        "STREAMER_PLANNER_DESTINATION_DELVE_TORMENTS_RISE",
        "STREAMER_PLANNER_DESTINATION_DELVE_TWILIGHT_CRYPTS",
    },
    midnight = {
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_WINDRUNNER_SPIRE",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_MAGISTERS_TERRACE",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_MURDER_ROW",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_DEN_OF_NALORAKK",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_MAISARA_CAVERNS",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_THE_BLINDING_VALE",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_VOIDSCAR_ARENA",
        "STREAMER_PLANNER_DESTINATION_MIDNIGHT_NEXUS_POINT_XENAS",
        "STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE",
        "STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT",
        "STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS",
    },
    raids = {
        "STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE",
        "STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT",
        "STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS",
    },
}

local DUNGEON_LAYOUT = {
    { key = "tank", labelKey = "STREAMER_PLANNER_ROLE_TANK" },
    { key = "healer", labelKey = "STREAMER_PLANNER_ROLE_HEALER" },
    { key = "dps1", labelKey = "STREAMER_PLANNER_ROLE_DPS1" },
    { key = "dps2", labelKey = "STREAMER_PLANNER_ROLE_DPS2" },
    { key = "dps3", labelKey = "STREAMER_PLANNER_ROLE_DPS3" },
}

local RAID_GROUP_COUNT = 4
local RAID_GROUP_SIZE = 5
local RAID_SLOT_COUNT = RAID_GROUP_COUNT * RAID_GROUP_SIZE
local RAID_GROUP_COLUMN_SPACING = 14
local RAID_GROUP_ROW_SPACING = 16
local RAID_GROUP_TITLE_GAP = 6

local PageStreamerPlanner
local PageScrollFrame
local PageContentFrame
local OverlayFrame
local OverlayTitle
local OverlayDestinationButton
local OverlayDestinationLabel
local OverlayDestinationValue
local OverlayRaidSummary
local OverlayDungeonModeButton
local OverlayRaidModeButton
local OverlayDungeonContainer
local OverlayRaidContainer
local OverlayTimer = {}
local PreviewTitle
local PreviewHint
local PreviewDungeonContainer
local PreviewRaidContainer
local ShowOverlayCheckbox
local LockOverlayCheckbox
local ScaleSlider
local ScaleSliderText
local TimerDurationSlider
local TimerDurationSliderText
local DungeonModeButton
local RaidModeButton
local DestinationInput
local DestinationCategoryDropdown
local DestinationSuggestionDropdown
local DestinationKeystoneDropdown
local EditDialog
local EditDialogTitle
local EditDialogHint
local EditDialogInput
local EditDialogTargetLabel
local EditClassTitle
local EditSpecTitle
local EditDestinationCategoryLabel
local EditDestinationSuggestionLabel
local EditDestinationKeystoneLabel
local isRefreshingPage = false

local PreviewDungeonButtons = {}
local PreviewRaidButtons = {}
local OverlayDungeonButtons = {}
local OverlayRaidButtons = {}

local editingLayout = nil
local editingSlotIndex = nil
local editingField = nil
local editingClassFile = nil
local editingSpecID = nil

local ClassOptionsCache
local ClassInfoByFileCache
local SpecOptionsCache = {}
local EditClassButtons = {}
local EditSpecButtons = {}
local SaveSlotButton
local ClearSlotButton
local CancelSlotButton
local HideEditDialog
local GetStreamerPlannerSettings
local GetDungeonSlotInfo
local LayoutEditDialogOptionButtons
local timerRefreshElapsed = 0

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function GetCurrentTimestamp()
    if GetServerTime then
        return GetServerTime()
    end

    return time()
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor(((tonumber(value) or DEFAULT_OVERLAY_SCALE) * 100) + 0.5))
end

local function GetTimerDurationMinutes()
    return math.floor(((GetStreamerPlannerSettings().timerDurationSeconds or DEFAULT_TIMER_DURATION_SECONDS) / 60) + 0.5)
end

local function GetTimerDurationText(minutes)
    local resolvedMinutes = Clamp(math.floor((tonumber(minutes) or GetTimerDurationMinutes()) + 0.5), MIN_TIMER_DURATION_MINUTES, MAX_TIMER_DURATION_MINUTES)
    return string.format(L("STREAMER_PLANNER_TIMER_DURATION_VALUE"), resolvedMinutes)
end

local function GetDestinationCategoryOptions()
    return DESTINATION_CATEGORIES
end

local function GetDestinationSuggestions(categoryKey)
    local suggestionKeys = DESTINATION_OPTIONS[categoryKey] or {}
    local suggestions = {}

    for _, suggestionKey in ipairs(suggestionKeys) do
        suggestions[#suggestions + 1] = L(suggestionKey)
    end

    return suggestions
end

local function GetDestinationCategoryLabel(categoryKey)
    for _, categoryInfo in ipairs(GetDestinationCategoryOptions()) do
        if categoryInfo.key == categoryKey then
            return L(categoryInfo.labelKey)
        end
    end

    return L("STREAMER_PLANNER_DESTINATION_CATEGORY_S1")
end

local function GetKeystoneLabel(level)
    return string.format("M+%d", Clamp(math.floor((tonumber(level) or 0) + 0.5), 0, 20))
end

local function FindDestinationSuggestion(categoryKey, destinationText)
    local normalizedText = tostring(destinationText or "")
    for _, suggestion in ipairs(GetDestinationSuggestions(categoryKey)) do
        if suggestion == normalizedText then
            return suggestion
        end
    end

    return nil
end

local function NormalizeSlotEntry(entry)
    if type(entry) == "table" then
        return {
            name = tostring(entry.name or ""),
            classFile = type(entry.classFile) == "string" and entry.classFile or nil,
            specID = type(entry.specID) == "number" and entry.specID or nil,
        }
    end

    if type(entry) == "string" then
        return {
            name = entry,
            classFile = nil,
            specID = nil,
        }
    end

    return {
        name = "",
        classFile = nil,
        specID = nil,
    }
end

local function BuildClassOptions()
    if ClassOptionsCache and ClassInfoByFileCache then
        return ClassOptionsCache, ClassInfoByFileCache
    end

    local options = {
        {
            file = nil,
            classID = nil,
            name = L("STREAMER_PLANNER_CLASS_NONE"),
        },
    }
    local infoByFile = {}

    if GetNumClasses and GetClassInfo then
        for classIndex = 1, GetNumClasses() do
            local localizedName, classFile, classID = GetClassInfo(classIndex)
            if type(localizedName) == "string" and localizedName ~= "" and type(classFile) == "string" and classFile ~= "" then
                local info = {
                    file = classFile,
                    classID = type(classID) == "number" and classID or classIndex,
                    name = localizedName,
                }
                options[#options + 1] = info
                infoByFile[classFile] = info
            end
        end
    end

    if #options == 1 and RAID_CLASS_COLORS then
        for classFile in pairs(RAID_CLASS_COLORS) do
            local localizedName = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile])
                or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[classFile])
                or classFile
            local info = {
                file = classFile,
                classID = nil,
                name = localizedName,
            }
            options[#options + 1] = info
            infoByFile[classFile] = info
        end
    end

    table.sort(options, function(left, right)
        if left.file == nil then
            return true
        end

        if right.file == nil then
            return false
        end

        return left.name < right.name
    end)

    ClassOptionsCache = options
    ClassInfoByFileCache = infoByFile
    return ClassOptionsCache, ClassInfoByFileCache
end

local function GetClassColor(classFile)
    local color = RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile] or nil
    if color then
        return color.r, color.g, color.b
    end

    return 1, 1, 1
end

local function GetLocalizedClassName(classFile)
    if not classFile then
        return nil
    end

    local _, infoByFile = BuildClassOptions()
    local info = infoByFile[classFile]
    return info and info.name or classFile
end

local function GetClassIconCoords(classFile)
    if CLASS_ICON_TCOORDS and classFile and CLASS_ICON_TCOORDS[classFile] then
        local coords = CLASS_ICON_TCOORDS[classFile]
        return coords[1], coords[2], coords[3], coords[4]
    end

    return 0, 1, 0, 1
end

local function GetSlotRoleRequirement(layout, index)
    if layout ~= "dungeon" then
        return nil
    end

    local slotInfo = GetDungeonSlotInfo(index)
    return slotInfo and DUNGEON_SLOT_ROLE_REQUIREMENTS[slotInfo.key] or nil
end

local function IsClassAllowedForRole(classFile, roleRequirement)
    if not classFile or not roleRequirement then
        return true
    end

    local supportedRoles = CLASS_ROLE_SUPPORT[classFile]
    return supportedRoles ~= nil and supportedRoles[roleRequirement] == true
end

local function IsSpecAllowedForRole(specID, roleRequirement)
    if type(specID) ~= "number" or not roleRequirement then
        return true
    end

    return SPEC_ROLE_SUPPORT[specID] == roleRequirement
end

local function BuildSpecOptions(classFile, roleRequirement)
    local cacheKey = string.format("%s|%s", classFile or "__none", roleRequirement or "any")
    if SpecOptionsCache[cacheKey] then
        return SpecOptionsCache[cacheKey]
    end

    local options = {
        {
            id = nil,
            name = L("STREAMER_PLANNER_SPEC_NONE"),
            icon = nil,
        },
    }

    for _, specID in ipairs(SPEC_DATA_BY_CLASS[classFile] or {}) do
        if IsSpecAllowedForRole(specID, roleRequirement) then
            local specName
            local specIcon
            if GetSpecializationInfoByID then
                local _, resolvedSpecName, _, resolvedSpecIcon = GetSpecializationInfoByID(specID)
                specName = resolvedSpecName
                specIcon = resolvedSpecIcon
            end

            options[#options + 1] = {
                id = specID,
                name = specName or tostring(specID),
                icon = specIcon,
            }
        end
    end

    SpecOptionsCache[cacheKey] = options
    return options
end

local function GetSpecName(classFile, specID)
    if not classFile or type(specID) ~= "number" then
        return nil
    end

    for _, specInfo in ipairs(BuildSpecOptions(classFile, nil)) do
        if specInfo.id == specID then
            return specInfo.name
        end
    end

    return nil
end

local function GetEntryAssignedRole(entry)
    if type(entry) ~= "table" then
        return nil
    end

    if type(entry.specID) == "number" then
        return SPEC_ROLE_SUPPORT[entry.specID]
    end

    local supportedRoles = entry.classFile and CLASS_ROLE_SUPPORT[entry.classFile] or nil
    if not supportedRoles then
        return nil
    end

    local resolvedRole = nil
    for _, roleKey in ipairs({ "tank", "healer", "dps" }) do
        if supportedRoles[roleKey] then
            if resolvedRole then
                return nil
            end
            resolvedRole = roleKey
        end
    end

    return resolvedRole
end

local function FormatTimerSeconds(totalSeconds)
    local clampedSeconds = math.max(0, math.floor((tonumber(totalSeconds) or 0) + 0.5))
    local minutes = math.floor(clampedSeconds / 60)
    local seconds = clampedSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

local function SyncPlannerTimerState()
    local settings = GetStreamerPlannerSettings()
    if settings.timerRunning ~= true then
        return settings
    end

    local now = GetCurrentTimestamp()
    if type(settings.timerLastUpdatedAt) ~= "number" then
        settings.timerLastUpdatedAt = now
        return settings
    end

    local elapsed = now - settings.timerLastUpdatedAt
    if elapsed <= 0 then
        return settings
    end

    settings.timerRemainingSeconds = math.max(0, math.floor((settings.timerRemainingSeconds or 0) - elapsed))
    settings.timerLastUpdatedAt = now

    if settings.timerRemainingSeconds <= 0 then
        settings.timerRemainingSeconds = 0
        settings.timerRunning = false
        settings.timerLastUpdatedAt = nil
    end

    return settings
end

local function ResetPlannerTimerState()
    local settings = GetStreamerPlannerSettings()
    settings.timerRunning = false
    settings.timerLastUpdatedAt = nil
    settings.timerRemainingSeconds = settings.timerDurationSeconds or DEFAULT_TIMER_DURATION_SECONDS
end

local function StartPlannerTimer()
    local settings = SyncPlannerTimerState()
    if (settings.timerRemainingSeconds or 0) <= 0 then
        settings.timerRemainingSeconds = settings.timerDurationSeconds or DEFAULT_TIMER_DURATION_SECONDS
    end

    settings.timerRunning = true
    settings.timerLastUpdatedAt = GetCurrentTimestamp()
end

local function PausePlannerTimer()
    local settings = SyncPlannerTimerState()
    settings.timerRunning = false
    settings.timerLastUpdatedAt = nil
end

local function SetPlannerTimerDurationMinutes(minutes)
    local settings = GetStreamerPlannerSettings()
    local resolvedMinutes = Clamp(math.floor((tonumber(minutes) or (DEFAULT_TIMER_DURATION_SECONDS / 60)) + 0.5), MIN_TIMER_DURATION_MINUTES, MAX_TIMER_DURATION_MINUTES)
    local previousDurationSeconds = settings.timerDurationSeconds or DEFAULT_TIMER_DURATION_SECONDS
    local newDurationSeconds = resolvedMinutes * 60

    settings.timerDurationSeconds = newDurationSeconds

    if settings.timerRunning == true then
        settings.timerRemainingSeconds = math.min(settings.timerRemainingSeconds or newDurationSeconds, newDurationSeconds)
    elseif (settings.timerRemainingSeconds or previousDurationSeconds) == previousDurationSeconds then
        settings.timerRemainingSeconds = newDurationSeconds
    else
        settings.timerRemainingSeconds = math.min(settings.timerRemainingSeconds or newDurationSeconds, newDurationSeconds)
    end

    if (settings.timerRemainingSeconds or 0) <= 0 then
        settings.timerRunning = false
        settings.timerLastUpdatedAt = nil
    end
end

local function RefreshTimerDisplay()
    if not OverlayTimer.Value then
        return
    end

    local settings = SyncPlannerTimerState()
    local remainingSeconds = math.max(0, math.floor(settings.timerRemainingSeconds or 0))

    OverlayTimer.Value:SetText(FormatTimerSeconds(remainingSeconds))

    if remainingSeconds == 0 then
        OverlayTimer.Value:SetTextColor(1, 0.34, 0.34, 1)
        OverlayTimer.Status:SetText(L("STREAMER_PLANNER_TIMER_EXPIRED"))
        OverlayTimer.Status:SetTextColor(1, 0.48, 0.30, 1)
    elseif settings.timerRunning then
        if remainingSeconds <= TIMER_WARNING_THRESHOLD_SECONDS then
            OverlayTimer.Value:SetTextColor(1, 0.82, 0.22, 1)
        else
            OverlayTimer.Value:SetTextColor(1, 1, 1, 1)
        end
        OverlayTimer.Status:SetText(L("STREAMER_PLANNER_TIMER_RUNNING"))
        OverlayTimer.Status:SetTextColor(0.78, 0.92, 0.78, 1)
    else
        OverlayTimer.Value:SetTextColor(0.92, 0.92, 0.92, 1)
        OverlayTimer.Status:SetText(L("STREAMER_PLANNER_TIMER_PAUSED"))
        OverlayTimer.Status:SetTextColor(0.76, 0.76, 0.80, 1)
    end

    if OverlayTimer.StartButton then
        OverlayTimer.StartButton:SetEnabled(settings.timerRunning ~= true)
    end

    if OverlayTimer.PauseButton then
        OverlayTimer.PauseButton:SetEnabled(settings.timerRunning == true)
    end
end

GetStreamerPlannerSettings = function()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.streamerPlanner = BeavisQoLDB.streamerPlanner or {}

    local db = BeavisQoLDB.streamerPlanner

    if db.overlayEnabled == nil then
        db.overlayEnabled = false
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if type(db.overlayScale) ~= "number" then
        db.overlayScale = DEFAULT_OVERLAY_SCALE
    end
    db.overlayScale = Clamp(db.overlayScale, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)

    if db.mode ~= "raid" then
        db.mode = DEFAULT_MODE
    end

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

    if type(db.destination) ~= "string" then
        db.destination = ""
    end

    if type(db.destinationCategory) ~= "string" or not DESTINATION_OPTIONS[db.destinationCategory] then
        db.destinationCategory = DESTINATION_CATEGORIES[1].key
    end

    if type(db.destinationKeystoneLevel) == "number" then
        db.destinationKeystoneLevel = Clamp(math.floor(db.destinationKeystoneLevel + 0.5), 0, 20)
    else
        db.destinationKeystoneLevel = nil
    end

    if type(db.timerDurationSeconds) ~= "number" or db.timerDurationSeconds < 60 then
        db.timerDurationSeconds = DEFAULT_TIMER_DURATION_SECONDS
    end

    if type(db.timerRemainingSeconds) ~= "number" or db.timerRemainingSeconds < 0 then
        db.timerRemainingSeconds = db.timerDurationSeconds
    end

    if db.timerRemainingSeconds > db.timerDurationSeconds then
        db.timerRemainingSeconds = db.timerDurationSeconds
    end

    if db.timerRunning == nil then
        db.timerRunning = false
    else
        db.timerRunning = db.timerRunning == true
    end

    if type(db.timerLastUpdatedAt) ~= "number" then
        db.timerLastUpdatedAt = nil
    end

    if db.timerRemainingSeconds <= 0 then
        db.timerRemainingSeconds = 0
        db.timerRunning = false
        db.timerLastUpdatedAt = nil
    end

    if type(db.slots) ~= "table" then
        db.slots = {}
    end

    if type(db.slots.dungeon) ~= "table" then
        db.slots.dungeon = {}
    end

    for _, slotInfo in ipairs(DUNGEON_LAYOUT) do
        db.slots.dungeon[slotInfo.key] = NormalizeSlotEntry(db.slots.dungeon[slotInfo.key])
    end

    if type(db.slots.raid) ~= "table" then
        db.slots.raid = {}
    end

    for index = 1, RAID_SLOT_COUNT do
        db.slots.raid[index] = NormalizeSlotEntry(db.slots.raid[index])
    end

    return db
end

local function GetDestinationBaseText()
    return GetStreamerPlannerSettings().destination or ""
end

local function GetCurrentMode()
    return GetStreamerPlannerSettings().mode
end

local function GetDestinationText()
    local settings = GetStreamerPlannerSettings()
    local destinationText = settings.destination or ""

    if destinationText ~= "" and settings.destinationCategory == "s1" and type(settings.destinationKeystoneLevel) == "number" then
        return string.format("%s %s", destinationText, GetKeystoneLabel(settings.destinationKeystoneLevel))
    end

    return destinationText
end

local function GetDestinationCategory()
    return GetStreamerPlannerSettings().destinationCategory
end

local function GetDestinationKeystoneLevel()
    return GetStreamerPlannerSettings().destinationKeystoneLevel
end

local function SetDestinationText(value)
    GetStreamerPlannerSettings().destination = tostring(value or "")
end

local function SetDestinationKeystoneLevel(level)
    local settings = GetStreamerPlannerSettings()
    if type(level) ~= "number" then
        settings.destinationKeystoneLevel = nil
        return
    end

    settings.destinationKeystoneLevel = Clamp(math.floor(level + 0.5), 0, 20)
end

local function SetDestinationCategory(categoryKey)
    local settings = GetStreamerPlannerSettings()
    settings.destinationCategory = DESTINATION_OPTIONS[categoryKey] and categoryKey or DESTINATION_CATEGORIES[1].key
end

local function SetCurrentMode(mode)
    local settings = GetStreamerPlannerSettings()
    settings.mode = mode == "raid" and "raid" or "dungeon"

    if settings.mode == "raid" then
        if settings.destinationCategory == "s1" or settings.destinationCategory == "delves" then
            settings.destinationCategory = "raids"
        end
    elseif settings.destinationCategory == "raids" then
        settings.destinationCategory = DESTINATION_CATEGORIES[1].key
    end
end

GetDungeonSlotInfo = function(index)
    return DUNGEON_LAYOUT[index]
end

local function GetRaidGroupAndPosition(index)
    local groupIndex = math.floor((index - 1) / RAID_GROUP_SIZE) + 1
    local positionIndex = ((index - 1) % RAID_GROUP_SIZE) + 1
    return groupIndex, positionIndex
end

local function GetSlotLabel(layout, index)
    if layout == "raid" then
        local groupIndex, positionIndex = GetRaidGroupAndPosition(index)
        return L("STREAMER_PLANNER_RAID_SLOT"):format(groupIndex, positionIndex)
    end

    local slotInfo = GetDungeonSlotInfo(index)
    if not slotInfo then
        return ""
    end

    return L(slotInfo.labelKey)
end

local function GetSlotValue(layout, index)
    local entry
    local settings = GetStreamerPlannerSettings()

    if layout == "raid" then
        entry = settings.slots.raid[index]
    else
        local slotInfo = GetDungeonSlotInfo(index)
        if not slotInfo then
            return ""
        end

        entry = settings.slots.dungeon[slotInfo.key]
    end

    return NormalizeSlotEntry(entry).name
end

local function GetSlotEntry(layout, index)
    local settings = GetStreamerPlannerSettings()

    if layout == "raid" then
        return NormalizeSlotEntry(settings.slots.raid[index])
    end

    local slotInfo = GetDungeonSlotInfo(index)
    if not slotInfo then
        return NormalizeSlotEntry(nil)
    end

    return NormalizeSlotEntry(settings.slots.dungeon[slotInfo.key])
end

local function GetRaidRoleCounts()
    local counts = {
        tank = 0,
        healer = 0,
        dps = 0,
    }

    for index = 1, RAID_SLOT_COUNT do
        local entry = GetSlotEntry("raid", index)
        if entry.name ~= "" or entry.classFile ~= nil or entry.specID ~= nil then
            local role = GetEntryAssignedRole(entry)
            if role and counts[role] then
                counts[role] = counts[role] + 1
            end
        end
    end

    return counts
end

local function GetRaidSummaryText()
    local counts = GetRaidRoleCounts()
    return L("STREAMER_PLANNER_RAID_SUMMARY"):format(counts.tank, counts.healer, counts.dps)
end

local function SetSlotEntry(layout, index, entry)
    local settings = GetStreamerPlannerSettings()
    local normalizedEntry = NormalizeSlotEntry(entry)

    if layout == "raid" then
        settings.slots.raid[index] = normalizedEntry
        return
    end

    local slotInfo = GetDungeonSlotInfo(index)
    if slotInfo then
        settings.slots.dungeon[slotInfo.key] = normalizedEntry
    end
end

local function SetSlotValue(layout, index, value)
    local entry = GetSlotEntry(layout, index)
    entry.name = tostring(value or "")
    SetSlotEntry(layout, index, entry)
end

local function ClearLayout(layout)
    local settings = GetStreamerPlannerSettings()

    if layout == "raid" then
        for index = 1, RAID_SLOT_COUNT do
            settings.slots.raid[index] = NormalizeSlotEntry(nil)
        end
        return
    end

    for _, slotInfo in ipairs(DUNGEON_LAYOUT) do
        settings.slots.dungeon[slotInfo.key] = NormalizeSlotEntry(nil)
    end
end

local function ClearAllLayouts()
    ClearLayout("dungeon")
    ClearLayout("raid")
end

local function OpenStreamerPlannerSettings()
    HideEditDialog()

    if BeavisQoL and BeavisQoL.OpenPage then
        BeavisQoL.OpenPage("StreamerPlanner")
    end
end

local function SaveOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayFrame:GetPoint(1)
    local settings = GetStreamerPlannerSettings()

    settings.point = point or DEFAULT_POINT
    settings.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    settings.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    settings.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function ApplyOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local settings = GetStreamerPlannerSettings()
    OverlayFrame:ClearAllPoints()
    OverlayFrame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.offsetX, settings.offsetY)
end

local function RefreshScaleSliderText()
    if not ScaleSlider or not ScaleSliderText then
        return
    end

    ScaleSliderText:SetText(string.format("%s: %s", L("STREAMER_PLANNER_SCALE"), GetSliderPercentText(ScaleSlider:GetValue())))
end

local function RefreshTimerDurationSliderText()
    if not TimerDurationSlider or not TimerDurationSliderText then
        return
    end

    TimerDurationSliderText:SetText(string.format("%s: %s", L("STREAMER_PLANNER_TIMER_DURATION"), GetTimerDurationText(TimerDurationSlider:GetValue())))
end

local function RefreshDestinationCategoryDropdown()
    if not DestinationCategoryDropdown then
        return
    end

    local categoryKey = GetDestinationCategory()
    UIDropDownMenu_SetWidth(DestinationCategoryDropdown, 132)
    UIDropDownMenu_SetSelectedValue(DestinationCategoryDropdown, categoryKey)
    UIDropDownMenu_SetText(DestinationCategoryDropdown, GetDestinationCategoryLabel(categoryKey))
end

local function RefreshDestinationSuggestionDropdown()
    if not DestinationSuggestionDropdown then
        return
    end

    local categoryKey = GetDestinationCategory()
    local destinationText = GetDestinationBaseText()
    if editingField == "destination" and DestinationInput and DestinationInput:IsShown() then
        destinationText = DestinationInput:GetText()
    end
    local selectedSuggestion = FindDestinationSuggestion(categoryKey, destinationText)

    UIDropDownMenu_SetWidth(DestinationSuggestionDropdown, 232)
    UIDropDownMenu_SetSelectedValue(DestinationSuggestionDropdown, selectedSuggestion)
    UIDropDownMenu_SetText(DestinationSuggestionDropdown, selectedSuggestion or L("STREAMER_PLANNER_DESTINATION_MANUAL"))
end

local function ShouldShowDestinationKeystoneControls()
    if GetDestinationCategory() ~= "s1" then
        return false
    end

    local destinationText = GetDestinationBaseText()
    if editingField == "destination" and DestinationInput and DestinationInput:IsShown() then
        destinationText = DestinationInput:GetText()
    end

    return FindDestinationSuggestion("s1", destinationText) ~= nil
end

local function RefreshDestinationKeystoneDropdown()
    if not DestinationKeystoneDropdown or not DestinationInput or not EditDialog then
        return
    end

    local shouldShow = editingField == "destination" and ShouldShowDestinationKeystoneControls()

    if EditDestinationKeystoneLabel then
        EditDestinationKeystoneLabel:SetShown(shouldShow)
    end

    if shouldShow then
        local selectedLevel = GetDestinationKeystoneLevel()
        if type(selectedLevel) ~= "number" then
            selectedLevel = 0
            SetDestinationKeystoneLevel(selectedLevel)
        end

        DestinationKeystoneDropdown:Show()
        UIDropDownMenu_SetWidth(DestinationKeystoneDropdown, 88)
        UIDropDownMenu_SetSelectedValue(DestinationKeystoneDropdown, selectedLevel)
        UIDropDownMenu_SetText(DestinationKeystoneDropdown, GetKeystoneLabel(selectedLevel))

        DestinationInput:ClearAllPoints()
        DestinationInput:SetPoint("TOPLEFT", EditDestinationKeystoneLabel, "BOTTOMLEFT", 0, -20)
        EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_DESTINATION_KEYSTONE_HEIGHT)
    else
        DestinationKeystoneDropdown:Hide()
        DestinationInput:ClearAllPoints()
        DestinationInput:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "BOTTOMLEFT", 0, -20)
        EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_DESTINATION_HEIGHT)
    end
end

local function RefreshClassSpecButtons()
    local isSlotEditing = editingField == "slot"
    local isDestinationEditing = editingField == "destination"
    local roleRequirement = GetSlotRoleRequirement(editingLayout, editingSlotIndex)

    if EditDialogInput then
        if isSlotEditing then
            EditDialogInput:Show()
        else
            EditDialogInput:Hide()
        end
    end

    if EditDialogTargetLabel then
        if isSlotEditing then
            EditDialogTargetLabel:Show()
        else
            EditDialogTargetLabel:Hide()
        end
    end

    if EditDestinationCategoryLabel then
        if isDestinationEditing then
            EditDestinationCategoryLabel:Show()
        else
            EditDestinationCategoryLabel:Hide()
        end
    end

    if EditDestinationSuggestionLabel then
        if isDestinationEditing then
            EditDestinationSuggestionLabel:Show()
        else
            EditDestinationSuggestionLabel:Hide()
        end
    end

    if DestinationCategoryDropdown then
        if isDestinationEditing then
            DestinationCategoryDropdown:Show()
        else
            DestinationCategoryDropdown:Hide()
        end
    end

    if DestinationSuggestionDropdown then
        if isDestinationEditing then
            DestinationSuggestionDropdown:Show()
        else
            DestinationSuggestionDropdown:Hide()
        end
    end

    if DestinationInput then
        if isDestinationEditing then
            DestinationInput:Show()
        else
            DestinationInput:Hide()
        end
    end

    RefreshDestinationKeystoneDropdown()

    if EditClassTitle then
        if isSlotEditing then
            EditClassTitle:Show()
        else
            EditClassTitle:Hide()
        end
    end

    if EditSpecTitle then
        if isSlotEditing then
            EditSpecTitle:Show()
        else
            EditSpecTitle:Hide()
        end
    end

    if isSlotEditing and editingClassFile and not IsClassAllowedForRole(editingClassFile, roleRequirement) then
        editingClassFile = nil
        editingSpecID = nil
    elseif isSlotEditing and editingSpecID and not IsSpecAllowedForRole(editingSpecID, roleRequirement) then
        editingSpecID = nil
    end

    for _, button in ipairs(EditClassButtons) do
        if isSlotEditing then
            local isAllowed = IsClassAllowedForRole(button.ClassFile, roleRequirement)
            button:SetShown(isAllowed)
            if isAllowed then
                local active = button.ClassFile == editingClassFile
                local red, green, blue = GetClassColor(button.ClassFile)
                button.Icon:SetVertexColor(active and 1 or red, active and 1 or green, active and 1 or blue, 1)
                button.Selected:SetShown(active)
            end
        else
            button:Hide()
        end
    end

    for _, button in ipairs(EditSpecButtons) do
        button:Hide()
    end

    if not isSlotEditing or not editingClassFile then
        LayoutEditDialogOptionButtons()
        return
    end

    local specOptions = BuildSpecOptions(editingClassFile, roleRequirement)
    local visibleIndex = 0
    for _, specInfo in ipairs(specOptions) do
        if specInfo.id ~= nil then
            visibleIndex = visibleIndex + 1
            local button = EditSpecButtons[visibleIndex]
            if button then
                button.SpecID = specInfo.id
                button.DisplayName = specInfo.name
                button.Icon:SetTexture(specInfo.icon or 134400)
                button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                button.Label:SetText(specInfo.name)
                button.Selected:SetShown(editingSpecID == specInfo.id)
                button:Show()
            end
        end
    end

    LayoutEditDialogOptionButtons()
end

LayoutEditDialogOptionButtons = function()
    local visibleClassButtons = {}
    local visibleSpecButtons = {}

    for _, button in ipairs(EditClassButtons) do
        if button:IsShown() then
            visibleClassButtons[#visibleClassButtons + 1] = button
        end
    end

    for _, button in ipairs(EditSpecButtons) do
        if button:IsShown() then
            visibleSpecButtons[#visibleSpecButtons + 1] = button
        end
    end

    local classRowCount = math.max(1, math.ceil(#visibleClassButtons / EDIT_CLASS_BUTTON_COLUMNS))

    for index, button in ipairs(visibleClassButtons) do
        local columnIndex = (index - 1) % EDIT_CLASS_BUTTON_COLUMNS
        local rowIndex = math.floor((index - 1) / EDIT_CLASS_BUTTON_COLUMNS)
        button:ClearAllPoints()
        button:SetPoint(
            "TOPLEFT",
            EditClassTitle,
            "BOTTOMLEFT",
            columnIndex * (EDIT_CLASS_BUTTON_SIZE + EDIT_CLASS_BUTTON_SPACING),
            -8 - (rowIndex * (EDIT_CLASS_BUTTON_SIZE + EDIT_CLASS_BUTTON_SPACING))
        )
    end

    EditSpecTitle:ClearAllPoints()
    EditSpecTitle:SetPoint(
        "TOPLEFT",
        EditClassTitle,
        "BOTTOMLEFT",
        0,
        -24 - (classRowCount * (EDIT_CLASS_BUTTON_SIZE + EDIT_CLASS_BUTTON_SPACING))
    )

    for index, button in ipairs(visibleSpecButtons) do
        button:ClearAllPoints()
        button:SetPoint(
            "TOPLEFT",
            EditSpecTitle,
            "BOTTOMLEFT",
            (index - 1) * (EDIT_SPEC_BUTTON_SIZE + EDIT_SPEC_BUTTON_SPACING),
            -8
        )
    end

    if editingField == "slot" and SaveSlotButton and ClearSlotButton and CancelSlotButton and EditDialog then
        SaveSlotButton:ClearAllPoints()

        if #visibleSpecButtons > 0 then
            SaveSlotButton:SetPoint("TOPLEFT", visibleSpecButtons[1], "BOTTOMLEFT", 0, -18)
        else
            SaveSlotButton:SetPoint("TOPLEFT", EditSpecTitle, "BOTTOMLEFT", 0, -18)
        end

        ClearSlotButton:ClearAllPoints()
        ClearSlotButton:SetPoint("LEFT", SaveSlotButton, "RIGHT", 10, 0)

        CancelSlotButton:ClearAllPoints()
        CancelSlotButton:SetPoint("LEFT", ClearSlotButton, "RIGHT", 10, 0)

        EditDialog:SetHeight(EDIT_DIALOG_SLOT_HEIGHT + math.max(0, classRowCount - 1) * (EDIT_CLASS_BUTTON_SIZE + EDIT_CLASS_BUTTON_SPACING))
    elseif SaveSlotButton and ClearSlotButton and CancelSlotButton then
        SaveSlotButton:ClearAllPoints()
        SaveSlotButton:SetPoint("BOTTOMLEFT", EditDialog, "BOTTOMLEFT", 16, 20)

        ClearSlotButton:ClearAllPoints()
        ClearSlotButton:SetPoint("LEFT", SaveSlotButton, "RIGHT", 10, 0)

        CancelSlotButton:ClearAllPoints()
        CancelSlotButton:SetPoint("LEFT", ClearSlotButton, "RIGHT", 10, 0)
    end
end

HideEditDialog = function()
    editingLayout = nil
    editingSlotIndex = nil
    editingField = nil
    editingClassFile = nil
    editingSpecID = nil
    RefreshClassSpecButtons()

    if EditDialog then
        EditDialog:Hide()
    end
end

local function CreateIconPickerButton(parent, size, showLabel)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:RegisterForClicks("AnyUp")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.92)
    button.Background = background

    local selected = button:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetColorTexture(1, 0.82, 0, 0.22)
    selected:Hide()
    button.Selected = selected

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.34)

    local borderBottom = button:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(1, 0.82, 0, 0.22)

    local icon = button:CreateTexture(nil, "OVERLAY")
    if showLabel then
        icon:SetPoint("TOP", button, "TOP", 0, -5)
        icon:SetSize(size - 10, size - 18)
    else
        icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        icon:SetSize(size - 10, size - 10)
    end
    button.Icon = icon

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 4)
    label:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    label:SetJustifyH("CENTER")
    label:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    label:SetTextColor(0.92, 0.92, 0.92, 1)
    label:SetShown(showLabel == true)
    button.Label = label

    button:SetScript("OnEnter", function(self)
        if self.DisplayName and self.DisplayName ~= "" and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.DisplayName, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

local function CreatePanel(parent, anchor, offsetY, height)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offsetY)
    panel:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, offsetY)
    panel:SetHeight(height)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

    local border = panel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.9)

    return panel
end

local function CreateCheckbox(parent, text, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetScript("OnClick", onClick)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(text)

    checkbox.Label = label
    return checkbox
end

local function CreateActionButton(parent, width, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function CreateOverlayHeaderButton(parent, width, labelText, onClick, tooltipTitle, tooltipText)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 22)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.58)
    button.Background = background

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.34)
    button.Border = border

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetTextColor(1, 0.82, 0, 1)
    label:SetText(labelText)
    button.Label = label

    button:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
        self.Border:SetColorTexture(1, 0.90, 0.35, 0.72)

        if tooltipTitle and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipTitle, 1, 0.82, 0)
            if tooltipText and tooltipText ~= "" then
                GameTooltip:AddLine(tooltipText, 0.85, 0.85, 0.85, true)
            end
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.Background:SetColorTexture(0.05, 0.05, 0.06, 0.58)
        self.Border:SetColorTexture(1, 0.82, 0, 0.34)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", onClick)
    return button
end

local function CreateModeButton(parent, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(126, 26)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function CreateScaleSlider(parent, nameSuffix)
    local resolvedSuffix = type(nameSuffix) == "string" and nameSuffix ~= "" and nameSuffix or "Scale"
    local slider = CreateFrame("Slider", ADDON_NAME .. "StreamerPlanner" .. resolvedSuffix .. "Slider", parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(250)

    local lowLabel = _G[slider:GetName() .. "Low"]
    local highLabel = _G[slider:GetName() .. "High"]
    local textLabel = _G[slider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(MIN_OVERLAY_SCALE))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(MAX_OVERLAY_SCALE))
    end

    if textLabel then
        textLabel:SetText("")
    end

    return slider, textLabel
end

local function CreateSlotButton(parent, width, height, layout, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:RegisterForClicks("AnyUp")
    button.Layout = layout
    button.Index = index

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.60)
    button.Background = background

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.34)
    button.Border = border

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(1)
    accent:SetColorTexture(1, 0.82, 0, 0.22)
    button.Accent = accent

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -7)
    label:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    label:SetTextColor(1, 0.82, 0, 1)
    button.Label = label

    local value = button:CreateFontString(nil, "OVERLAY")
    value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, 6)
    value:SetJustifyH("LEFT")
    value:SetJustifyV("TOP")
    value:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    value:SetTextColor(1, 1, 1, 1)
    value:SetWordWrap(false)
    button.Value = value

    if height <= 24 then
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -4)
        label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

        value:ClearAllPoints()
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, 0)
        value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 4)
        value:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    elseif height <= 30 then
        value:ClearAllPoints()
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, 0)
        value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, 4)
        value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end

    button:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
        self.Border:SetColorTexture(1, 0.90, 0.35, 0.78)
        self.Accent:SetColorTexture(1, 0.90, 0.35, 0.62)
    end)

    button:SetScript("OnLeave", function(self)
        self.Background:SetColorTexture(0.05, 0.05, 0.06, 0.60)
        self.Border:SetColorTexture(1, 0.82, 0, 0.34)
        self.Accent:SetColorTexture(1, 0.82, 0, 0.22)
    end)

    return button
end

local function OpenEditor(layout, index)
    if not EditDialog or not EditDialogInput then
        return
    end

    editingField = "slot"
    editingLayout = layout
    editingSlotIndex = index
    local slotEntry = GetSlotEntry(layout, index)
    editingClassFile = slotEntry.classFile
    editingSpecID = slotEntry.specID
    EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_SLOT_HEIGHT)

    EditDialogTitle:SetText(string.format("%s: %s", L("STREAMER_PLANNER_SLOT_EDIT"), GetSlotLabel(layout, index)))
    EditDialogHint:SetText(L("STREAMER_PLANNER_SLOT_EDIT_HINT"))
    EditDialogTargetLabel:SetText("")
    EditDialogInput:SetText(slotEntry.name)
    RefreshClassSpecButtons()
    EditDialog:Show()
    EditDialogInput:SetFocus()
    EditDialogInput:HighlightText()
end

local function OpenDestinationEditor()
    if not EditDialog or not EditDialogInput then
        return
    end

    editingField = "destination"
    editingLayout = nil
    editingSlotIndex = nil
    editingClassFile = nil
    editingSpecID = nil
    EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_DESTINATION_HEIGHT)

    EditDialogTitle:SetText(L("STREAMER_PLANNER_DESTINATION_EDIT"))
    EditDialogHint:SetText(L("STREAMER_PLANNER_DESTINATION_EDIT_HINT"))
    DestinationInput:SetText(GetDestinationBaseText())
    RefreshDestinationCategoryDropdown()
    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
    RefreshClassSpecButtons()
    EditDialog:Show()
    DestinationInput:SetFocus()
    DestinationInput:HighlightText()
end

local function RefreshSlotButton(button)
    if not button then
        return
    end

    local slotLabel = GetSlotLabel(button.Layout, button.Index)
    local slotEntry = GetSlotEntry(button.Layout, button.Index)
    local slotValue = slotEntry.name
    local classRed, classGreen, classBlue = GetClassColor(slotEntry.classFile)
    local specName = GetSpecName(slotEntry.classFile, slotEntry.specID)

    button.Label:SetText(slotLabel)
    if slotValue ~= "" then
        if specName then
            button.Value:SetText(string.format("%s (%s)", slotValue, specName))
        else
            button.Value:SetText(slotValue)
        end
        button.Value:SetTextColor(classRed, classGreen, classBlue, 1)
    else
        button.Value:SetText(L("STREAMER_PLANNER_EMPTY_SLOT"))
        button.Value:SetTextColor(0.62, 0.62, 0.66, 1)
    end

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            SetSlotEntry(button.Layout, button.Index, NormalizeSlotEntry(nil))
            HideEditDialog()
            StreamerPlannerModule.RefreshAllDisplays()
            return
        end

        OpenEditor(button.Layout, button.Index)
    end)
end

local function RefreshButtonList(buttons)
    for _, button in ipairs(buttons) do
        RefreshSlotButton(button)
    end
end

local function CreateDungeonLayout(parent, targetButtons, width)
    local previousButton

    for index = 1, #DUNGEON_LAYOUT do
        local button = CreateSlotButton(parent, width, 44, "dungeon", index)

        if previousButton then
            button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -8)
        else
            button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        end

        targetButtons[#targetButtons + 1] = button
        previousButton = button
    end
end

local function CreateRaidLayout(parent, targetButtons, width, slotHeight)
    local groupWidth = width
    local resolvedSlotHeight = slotHeight or 30
    local groupHeight = 20 + RAID_GROUP_TITLE_GAP + (RAID_GROUP_SIZE * resolvedSlotHeight) + ((RAID_GROUP_SIZE - 1) * 4)
    local groupFrames = {}

    for groupIndex = 1, RAID_GROUP_COUNT do
        local groupFrame = CreateFrame("Frame", nil, parent)
        groupFrame:SetSize(groupWidth, groupHeight)

        local rowIndex = math.floor((groupIndex - 1) / 2)
        local columnIndex = (groupIndex - 1) % 2
        groupFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", columnIndex * (groupWidth + RAID_GROUP_COLUMN_SPACING), -(rowIndex * (groupHeight + RAID_GROUP_ROW_SPACING)))

        local title = groupFrame:CreateFontString(nil, "OVERLAY")
        title:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, 0)
        title:SetPoint("RIGHT", groupFrame, "RIGHT", 0, 0)
        title:SetJustifyH("LEFT")
        title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        title:SetTextColor(1, 0.82, 0, 1)
        title:SetText(L("STREAMER_PLANNER_RAID_GROUP"):format(groupIndex))
        groupFrame.Title = title

        groupFrames[#groupFrames + 1] = groupFrame

        local previousButton
        for positionIndex = 1, RAID_GROUP_SIZE do
            local slotIndex = ((groupIndex - 1) * RAID_GROUP_SIZE) + positionIndex
            local button = CreateSlotButton(groupFrame, groupWidth, resolvedSlotHeight, "raid", slotIndex)

            if previousButton then
                button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -4)
            else
                button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -RAID_GROUP_TITLE_GAP)
            end

            targetButtons[#targetButtons + 1] = button
            previousButton = button
        end
    end

    return groupFrames
end

local function RefreshModeButtons()
    local mode = GetCurrentMode()
    local dungeonActive = mode == "dungeon"
    local raidActive = mode == "raid"

    if DungeonModeButton then
        DungeonModeButton:SetEnabled(not dungeonActive)
    end

    if RaidModeButton then
        RaidModeButton:SetEnabled(not raidActive)
    end

    if OverlayDungeonModeButton then
        OverlayDungeonModeButton:SetEnabled(not dungeonActive)
    end

    if OverlayRaidModeButton then
        OverlayRaidModeButton:SetEnabled(not raidActive)
    end

    if OverlayDungeonModeButton and OverlayDungeonModeButton.Text then
        OverlayDungeonModeButton.Text:SetTextColor(dungeonActive and 1 or 0.82, dungeonActive and 0.82 or 0.82, dungeonActive and 0 or 0.82)
    end

    if OverlayRaidModeButton and OverlayRaidModeButton.Text then
        OverlayRaidModeButton.Text:SetTextColor(raidActive and 1 or 0.82, raidActive and 0.82 or 0.82, raidActive and 0 or 0.82)
    end
end

local function RefreshLayoutVisibility()
    local mode = GetCurrentMode()
    local showRaid = mode == "raid"
    local destinationText = GetDestinationText()

    if PreviewDungeonContainer then
        if showRaid then
            PreviewDungeonContainer:Hide()
        else
            PreviewDungeonContainer:Show()
        end
    end

    if PreviewRaidContainer then
        if showRaid then
            PreviewRaidContainer:Show()
        else
            PreviewRaidContainer:Hide()
        end
    end

    if OverlayDungeonContainer then
        if showRaid then
            OverlayDungeonContainer:Hide()
        else
            OverlayDungeonContainer:Show()
        end
    end

    if OverlayRaidContainer then
        if showRaid then
            OverlayRaidContainer:Show()
        else
            OverlayRaidContainer:Hide()
        end
    end

    if OverlayDestinationLabel then
        OverlayDestinationLabel:SetText(L("STREAMER_PLANNER_DESTINATION"))
    end

    if OverlayRaidSummary then
        OverlayRaidSummary:ClearAllPoints()
        if OverlayTimer.Panel then
            OverlayRaidSummary:SetPoint("TOPLEFT", OverlayTimer.Panel, "BOTTOMLEFT", 0, -8)
        else
            OverlayRaidSummary:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
        end
        OverlayRaidSummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)

        if showRaid then
            OverlayRaidSummary:SetText(GetRaidSummaryText())
            OverlayRaidSummary:Show()
        else
            OverlayRaidSummary:Hide()
        end
    end

    if OverlayTimer.Panel then
        OverlayTimer.Panel:ClearAllPoints()
        if OverlayFrame and OverlayFrame.ModeRow then
            OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
        else
            OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -10)
        end
    end

    if OverlayDestinationButton then
        OverlayDestinationButton:ClearAllPoints()
        if showRaid and OverlayRaidSummary then
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayRaidSummary, "BOTTOMLEFT", 0, -8)
        elseif OverlayTimer.Panel then
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayTimer.Panel, "BOTTOMLEFT", 0, -12)
        else
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -10)
        end
        OverlayDestinationButton:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
        OverlayDestinationButton:SetHeight(showRaid and OVERLAY_DESTINATION_HEIGHT_RAID or OVERLAY_DESTINATION_HEIGHT_DUNGEON)
    end

    if OverlayDestinationValue then
        if destinationText ~= "" then
            OverlayDestinationValue:SetText(destinationText)
            OverlayDestinationValue:SetTextColor(1, 1, 1, 1)
        else
            OverlayDestinationValue:SetText(L("STREAMER_PLANNER_DESTINATION_EMPTY"))
            OverlayDestinationValue:SetTextColor(0.62, 0.62, 0.66, 1)
        end

        OverlayDestinationValue:SetWordWrap(showRaid)
    end

    if OverlayFrame then
        if showRaid then
            OverlayFrame:SetSize(458, 612)
        else
            OverlayFrame:SetSize(334, 482)
        end
    end

    RefreshTimerDisplay()
end

function StreamerPlannerModule.RefreshOverlayWindow()
    if not OverlayFrame then
        return
    end

    local settings = GetStreamerPlannerSettings()
    OverlayFrame:SetScale(settings.overlayScale)
    OverlayFrame:SetMovable(settings.overlayLocked ~= true)
    OverlayFrame:EnableMouse(true)
    ApplyOverlayGeometry()
    RefreshLayoutVisibility()
    RefreshTimerDisplay()

    if settings.overlayEnabled then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end
end

function StreamerPlannerModule.IsOverlayEnabled()
    return GetStreamerPlannerSettings().overlayEnabled == true
end

function StreamerPlannerModule.SetOverlayEnabled(enabled)
    GetStreamerPlannerSettings().overlayEnabled = enabled == true
    StreamerPlannerModule.RefreshOverlayWindow()
end

function StreamerPlannerModule.IsOverlayLocked()
    return GetStreamerPlannerSettings().overlayLocked == true
end

function StreamerPlannerModule.SetOverlayLocked(locked)
    GetStreamerPlannerSettings().overlayLocked = locked == true
    StreamerPlannerModule.RefreshOverlayWindow()
end

function StreamerPlannerModule.GetOverlayScale()
    return GetStreamerPlannerSettings().overlayScale
end

function StreamerPlannerModule.SetOverlayScale(scale)
    GetStreamerPlannerSettings().overlayScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    StreamerPlannerModule.RefreshOverlayWindow()
end

function StreamerPlannerModule.ResetOverlayPosition()
    local settings = GetStreamerPlannerSettings()
    settings.point = DEFAULT_POINT
    settings.relativePoint = DEFAULT_RELATIVE_POINT
    settings.offsetX = DEFAULT_OFFSET_X
    settings.offsetY = DEFAULT_OFFSET_Y
    StreamerPlannerModule.RefreshOverlayWindow()
end

function StreamerPlannerModule.SetMode(mode)
    SetCurrentMode(mode)
    StreamerPlannerModule.RefreshAllDisplays()
end

function StreamerPlannerModule.GetDestinationText()
    return GetDestinationText()
end

function StreamerPlannerModule.SetDestinationText(value)
    SetDestinationText(value)
    StreamerPlannerModule.RefreshAllDisplays()
end

function StreamerPlannerModule.ClearCurrentLayout()
    ClearLayout(GetCurrentMode())
    HideEditDialog()
    StreamerPlannerModule.RefreshAllDisplays()
end

function StreamerPlannerModule.ClearAllLayouts()
    ClearAllLayouts()
    HideEditDialog()
    StreamerPlannerModule.RefreshAllDisplays()
end

function StreamerPlannerModule.RefreshAllDisplays()
    RefreshButtonList(PreviewDungeonButtons)
    RefreshButtonList(PreviewRaidButtons)
    RefreshButtonList(OverlayDungeonButtons)
    RefreshButtonList(OverlayRaidButtons)
    RefreshModeButtons()
    RefreshLayoutVisibility()
    StreamerPlannerModule.RefreshOverlayWindow()

    if PageStreamerPlanner and PageStreamerPlanner:IsShown() then
        PageStreamerPlanner:RefreshState()
    end
end

PageStreamerPlanner = CreateFrame("Frame", nil, Content)
PageStreamerPlanner:SetAllPoints()
PageStreamerPlanner:Hide()

PageScrollFrame = CreateFrame("ScrollFrame", nil, PageStreamerPlanner, "UIPanelScrollFrameTemplate")
PageScrollFrame:SetPoint("TOPLEFT", PageStreamerPlanner, "TOPLEFT", 0, 0)
PageScrollFrame:SetPoint("BOTTOMRIGHT", PageStreamerPlanner, "BOTTOMRIGHT", -28, 0)
PageScrollFrame:EnableMouseWheel(true)

PageContentFrame = CreateFrame("Frame", nil, PageScrollFrame)
PageContentFrame:SetSize(1, 1)
PageScrollFrame:SetScrollChild(PageContentFrame)

local IntroPanel = CreateFrame("Frame", nil, PageContentFrame)
IntroPanel:SetPoint("TOPLEFT", PageContentFrame, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageContentFrame, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(132)

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

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)

local UsageHint = IntroPanel:CreateFontString(nil, "OVERLAY")
UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -10)
UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
UsageHint:SetJustifyH("LEFT")
UsageHint:SetJustifyV("TOP")
UsageHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
UsageHint:SetTextColor(0.84, 0.84, 0.86, 1)

local PreviewPanel = CreateFrame("Frame", nil, PageContentFrame)
PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
PreviewPanel:SetSize(430, 424)

local PreviewPanelBg = PreviewPanel:CreateTexture(nil, "BACKGROUND")
PreviewPanelBg:SetAllPoints()
PreviewPanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local PreviewPanelBorder = PreviewPanel:CreateTexture(nil, "ARTWORK")
PreviewPanelBorder:SetPoint("BOTTOMLEFT", PreviewPanel, "BOTTOMLEFT", 0, 0)
PreviewPanelBorder:SetPoint("BOTTOMRIGHT", PreviewPanel, "BOTTOMRIGHT", 0, 0)
PreviewPanelBorder:SetHeight(1)
PreviewPanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

PreviewTitle = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewTitle:SetPoint("TOPLEFT", PreviewPanel, "TOPLEFT", 18, -14)
PreviewTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
PreviewTitle:SetTextColor(1, 0.82, 0, 1)

PreviewHint = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewHint:SetPoint("TOPLEFT", PreviewTitle, "BOTTOMLEFT", 0, -8)
PreviewHint:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewHint:SetJustifyH("LEFT")
PreviewHint:SetJustifyV("TOP")
PreviewHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
PreviewHint:SetTextColor(0.80, 0.80, 0.80, 1)

PreviewDungeonContainer = CreateFrame("Frame", nil, PreviewPanel)
PreviewDungeonContainer:SetPoint("TOPLEFT", PreviewHint, "BOTTOMLEFT", 0, -18)
PreviewDungeonContainer:SetSize(392, 280)
CreateDungeonLayout(PreviewDungeonContainer, PreviewDungeonButtons, 392)

PreviewRaidContainer = CreateFrame("Frame", nil, PreviewPanel)
PreviewRaidContainer:SetPoint("TOPLEFT", PreviewHint, "BOTTOMLEFT", 0, -18)
PreviewRaidContainer:SetSize(372, 338)
CreateRaidLayout(PreviewRaidContainer, PreviewRaidButtons, 178, 24)

local SettingsPanel = CreateFrame("Frame", nil, PageContentFrame)
SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", 18, 0)
SettingsPanel:SetPoint("TOPRIGHT", PageContentFrame, "TOPRIGHT", -20, 0)
SettingsPanel:SetHeight(PreviewPanel:GetHeight())

local SettingsPanelBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsPanelBg:SetAllPoints()
SettingsPanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local SettingsPanelBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsPanelBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsPanelBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsPanelBorder:SetHeight(1)
SettingsPanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

SettingsPanel.Title = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.Title:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsPanel.Title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SettingsPanel.Title:SetTextColor(1, 0.82, 0, 1)

SettingsPanel.Hint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.Hint:SetPoint("TOPLEFT", SettingsPanel.Title, "BOTTOMLEFT", 0, -8)
SettingsPanel.Hint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.Hint:SetJustifyH("LEFT")
SettingsPanel.Hint:SetJustifyV("TOP")
SettingsPanel.Hint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SettingsPanel.Hint:SetTextColor(0.80, 0.80, 0.80, 1)

ShowOverlayCheckbox = CreateCheckbox(SettingsPanel, "", function(self)
    StreamerPlannerModule.SetOverlayEnabled(self:GetChecked())
    PageStreamerPlanner:RefreshState()
end)
ShowOverlayCheckbox:SetPoint("TOPLEFT", SettingsPanel.Hint, "BOTTOMLEFT", -4, -18)

SettingsPanel.ShowOverlayHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ShowOverlayHint:SetPoint("TOPLEFT", ShowOverlayCheckbox, "BOTTOMLEFT", 34, -2)
SettingsPanel.ShowOverlayHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ShowOverlayHint:SetJustifyH("LEFT")
SettingsPanel.ShowOverlayHint:SetJustifyV("TOP")
SettingsPanel.ShowOverlayHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ShowOverlayHint:SetTextColor(0.74, 0.74, 0.74, 1)

LockOverlayCheckbox = CreateCheckbox(SettingsPanel, "", function(self)
    StreamerPlannerModule.SetOverlayLocked(self:GetChecked())
end)
LockOverlayCheckbox:SetPoint("TOPLEFT", SettingsPanel.ShowOverlayHint, "BOTTOMLEFT", -34, -14)

SettingsPanel.LockOverlayHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.LockOverlayHint:SetPoint("TOPLEFT", LockOverlayCheckbox, "BOTTOMLEFT", 34, -2)
SettingsPanel.LockOverlayHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.LockOverlayHint:SetJustifyH("LEFT")
SettingsPanel.LockOverlayHint:SetJustifyV("TOP")
SettingsPanel.LockOverlayHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.LockOverlayHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.ModeTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ModeTitle:SetPoint("TOPLEFT", SettingsPanel.LockOverlayHint, "BOTTOMLEFT", 0, -22)
SettingsPanel.ModeTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsPanel.ModeTitle:SetTextColor(1, 0.82, 0, 1)

SettingsPanel.ModeHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ModeHint:SetPoint("TOPLEFT", SettingsPanel.ModeTitle, "BOTTOMLEFT", 0, -6)
SettingsPanel.ModeHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ModeHint:SetJustifyH("LEFT")
SettingsPanel.ModeHint:SetJustifyV("TOP")
SettingsPanel.ModeHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ModeHint:SetTextColor(0.74, 0.74, 0.74, 1)

DungeonModeButton = CreateModeButton(SettingsPanel, "", function()
    StreamerPlannerModule.SetMode("dungeon")
end)
DungeonModeButton:SetPoint("TOPLEFT", SettingsPanel.ModeHint, "BOTTOMLEFT", 0, -14)

RaidModeButton = CreateModeButton(SettingsPanel, "", function()
    StreamerPlannerModule.SetMode("raid")
end)
RaidModeButton:SetPoint("LEFT", DungeonModeButton, "RIGHT", 12, 0)

ScaleSlider, ScaleSliderText = CreateScaleSlider(SettingsPanel, "Scale")
ScaleSlider:SetPoint("TOPLEFT", DungeonModeButton, "BOTTOMLEFT", 18, -28)
ScaleSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    StreamerPlannerModule.SetOverlayScale(value)
    RefreshScaleSliderText()
end)

TimerDurationSlider, TimerDurationSliderText = CreateScaleSlider(SettingsPanel, "TimerDuration")
TimerDurationSlider:SetMinMaxValues(MIN_TIMER_DURATION_MINUTES, MAX_TIMER_DURATION_MINUTES)
TimerDurationSlider:SetValueStep(1)
TimerDurationSlider:SetObeyStepOnDrag(true)
TimerDurationSlider:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 0, -44)

local timerLowLabel = _G[TimerDurationSlider:GetName() .. "Low"]
local timerHighLabel = _G[TimerDurationSlider:GetName() .. "High"]
if timerLowLabel then
    timerLowLabel:SetText(GetTimerDurationText(MIN_TIMER_DURATION_MINUTES))
end
if timerHighLabel then
    timerHighLabel:SetText(GetTimerDurationText(MAX_TIMER_DURATION_MINUTES))
end

TimerDurationSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    SetPlannerTimerDurationMinutes(value)
    RefreshTimerDurationSliderText()
    RefreshTimerDisplay()
end)

SettingsPanel.ScaleHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ScaleHint:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", -2, -12)
SettingsPanel.ScaleHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ScaleHint:SetJustifyH("LEFT")
SettingsPanel.ScaleHint:SetJustifyV("TOP")
SettingsPanel.ScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ScaleHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.TimerDurationHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.TimerDurationHint:SetPoint("TOPLEFT", TimerDurationSlider, "BOTTOMLEFT", -2, -12)
SettingsPanel.TimerDurationHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.TimerDurationHint:SetJustifyH("LEFT")
SettingsPanel.TimerDurationHint:SetJustifyV("TOP")
SettingsPanel.TimerDurationHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.TimerDurationHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.ResetPositionButton = CreateActionButton(SettingsPanel, 158, "", function()
    StreamerPlannerModule.ResetOverlayPosition()
end)
SettingsPanel.ResetPositionButton:SetPoint("TOPLEFT", SettingsPanel.TimerDurationHint, "BOTTOMLEFT", 0, -18)

SettingsPanel.ResetPositionHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ResetPositionHint:SetPoint("TOPLEFT", SettingsPanel.ResetPositionButton, "BOTTOMLEFT", 0, -8)
SettingsPanel.ResetPositionHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ResetPositionHint:SetJustifyH("LEFT")
SettingsPanel.ResetPositionHint:SetJustifyV("TOP")
SettingsPanel.ResetPositionHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ResetPositionHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.ClearLayoutButton = CreateActionButton(SettingsPanel, 158, "", function()
    StreamerPlannerModule.ClearCurrentLayout()
end)
SettingsPanel.ClearLayoutButton:SetPoint("TOPLEFT", SettingsPanel.ResetPositionHint, "BOTTOMLEFT", 0, -18)

SettingsPanel.ClearLayoutHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ClearLayoutHint:SetPoint("TOPLEFT", SettingsPanel.ClearLayoutButton, "BOTTOMLEFT", 0, -8)
SettingsPanel.ClearLayoutHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ClearLayoutHint:SetJustifyH("LEFT")
SettingsPanel.ClearLayoutHint:SetJustifyV("TOP")
SettingsPanel.ClearLayoutHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ClearLayoutHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.ClearAllButton = CreateActionButton(SettingsPanel, 158, "", function()
    StreamerPlannerModule.ClearAllLayouts()
end)
SettingsPanel.ClearAllButton:SetPoint("TOPLEFT", SettingsPanel.ClearLayoutHint, "BOTTOMLEFT", 0, -18)

SettingsPanel.ClearAllHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ClearAllHint:SetPoint("TOPLEFT", SettingsPanel.ClearAllButton, "BOTTOMLEFT", 0, -8)
SettingsPanel.ClearAllHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ClearAllHint:SetJustifyH("LEFT")
SettingsPanel.ClearAllHint:SetJustifyV("TOP")
SettingsPanel.ClearAllHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SettingsPanel.ClearAllHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.EditHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.EditHint:SetPoint("TOPLEFT", SettingsPanel.ClearAllHint, "BOTTOMLEFT", 0, -18)
SettingsPanel.EditHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.EditHint:SetJustifyH("LEFT")
SettingsPanel.EditHint:SetJustifyV("TOP")
SettingsPanel.EditHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SettingsPanel.EditHint:SetTextColor(0.84, 0.84, 0.86, 1)

OverlayFrame = CreateFrame("Frame", "BeavisQoLStreamerPlannerOverlay", UIParent, BackdropTemplateMixin and "BackdropTemplate")
OverlayFrame:SetClampedToScreen(true)
OverlayFrame:SetMovable(true)
OverlayFrame:SetToplevel(true)
OverlayFrame:SetFrameStrata("MEDIUM")
OverlayFrame:EnableMouse(true)
OverlayFrame:SetClipsChildren(true)
OverlayFrame:RegisterForDrag("LeftButton")
OverlayFrame:SetScript("OnDragStart", function(self)
    if StreamerPlannerModule.IsOverlayLocked() then
        return
    end

    self:StartMoving()
end)
OverlayFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveOverlayGeometry()
end)

do
    local background = OverlayFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.02, 0.02, 0.03, 0.62)

    local topLine = OverlayFrame:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 10, -8)
    topLine:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", -10, -8)
    topLine:SetHeight(1)
    topLine:SetColorTexture(1, 0.82, 0, 0.70)

    local accent = OverlayFrame:CreateTexture(nil, "BACKGROUND")
    accent:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 9, -10)
    accent:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 9, 10)
    accent:SetWidth(2)
    accent:SetColorTexture(1, 0.82, 0, 0.18)
end

OverlayTitle = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlayTitle:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 18, -18)
OverlayTitle:SetJustifyH("LEFT")
OverlayTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
OverlayTitle:SetTextColor(1, 0.82, 0, 1)
OverlayTitle:SetWordWrap(false)

OverlayFrame.CloseButton = CreateOverlayHeaderButton(
    OverlayFrame,
    24,
    "X",
    function()
        StreamerPlannerModule.SetOverlayEnabled(false)
    end,
    L("STREAMER_PLANNER_OVERLAY_CLOSE_TOOLTIP"),
    L("STREAMER_PLANNER_OVERLAY_CLOSE_TOOLTIP_HINT")
)
OverlayFrame.CloseButton:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", -12, -13)

OverlayFrame.SettingsButton = CreateOverlayHeaderButton(
    OverlayFrame,
    46,
    L("STREAMER_PLANNER_OVERLAY_SETTINGS_BUTTON"),
    function()
        OpenStreamerPlannerSettings()
    end,
    L("STREAMER_PLANNER_OVERLAY_SETTINGS_TOOLTIP"),
    L("STREAMER_PLANNER_OVERLAY_SETTINGS_TOOLTIP_HINT")
)
OverlayFrame.SettingsButton:SetPoint("RIGHT", OverlayFrame.CloseButton, "LEFT", -4, 0)

OverlayTitle:SetPoint("RIGHT", OverlayFrame.SettingsButton, "LEFT", -10, 0)

OverlayFrame.ModeRow = CreateFrame("Frame", nil, OverlayFrame)
OverlayFrame.ModeRow:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -8)
OverlayFrame.ModeRow:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
OverlayFrame.ModeRow:SetHeight(22)

OverlayDungeonModeButton = CreateModeButton(OverlayFrame, "", function()
    StreamerPlannerModule.SetMode("dungeon")
end)
OverlayDungeonModeButton:SetParent(OverlayFrame.ModeRow)
OverlayDungeonModeButton:SetSize(78, 22)
OverlayDungeonModeButton:SetPoint("TOPRIGHT", OverlayFrame.ModeRow, "TOPRIGHT", 0, 0)

OverlayRaidModeButton = CreateModeButton(OverlayFrame, "", function()
    StreamerPlannerModule.SetMode("raid")
end)
OverlayRaidModeButton:SetParent(OverlayFrame.ModeRow)
OverlayRaidModeButton:SetSize(78, 22)
OverlayRaidModeButton:SetPoint("RIGHT", OverlayDungeonModeButton, "LEFT", -6, 0)

OverlayRaidSummary = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlayRaidSummary:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
OverlayRaidSummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
OverlayRaidSummary:SetJustifyH("LEFT")
OverlayRaidSummary:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
OverlayRaidSummary:SetTextColor(0.92, 0.92, 0.92, 1)
OverlayRaidSummary:SetWordWrap(false)

OverlayDestinationButton = CreateFrame("Button", nil, OverlayFrame)
OverlayDestinationButton:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -12)
OverlayDestinationButton:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
OverlayDestinationButton:SetHeight(OVERLAY_DESTINATION_HEIGHT_DUNGEON)
OverlayDestinationButton:RegisterForClicks("AnyUp")

do
    local background = OverlayDestinationButton:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.54)
    OverlayDestinationButton.Background = background

    local border = OverlayDestinationButton:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", OverlayDestinationButton, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", OverlayDestinationButton, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.34)
end

OverlayDestinationLabel = OverlayDestinationButton:CreateFontString(nil, "OVERLAY")
OverlayDestinationLabel:SetPoint("TOPLEFT", OverlayDestinationButton, "TOPLEFT", 10, -5)
OverlayDestinationLabel:SetPoint("TOPRIGHT", OverlayDestinationButton, "TOPRIGHT", -10, -5)
OverlayDestinationLabel:SetJustifyH("LEFT")
OverlayDestinationLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
OverlayDestinationLabel:SetTextColor(1, 0.82, 0, 1)
OverlayDestinationLabel:SetWordWrap(false)

OverlayDestinationValue = OverlayDestinationButton:CreateFontString(nil, "OVERLAY")
OverlayDestinationValue:SetPoint("TOPLEFT", OverlayDestinationLabel, "BOTTOMLEFT", 0, -2)
OverlayDestinationValue:SetPoint("BOTTOMRIGHT", OverlayDestinationButton, "BOTTOMRIGHT", -10, 7)
OverlayDestinationValue:SetJustifyH("LEFT")
OverlayDestinationValue:SetJustifyV("TOP")
OverlayDestinationValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
OverlayDestinationValue:SetWordWrap(true)

OverlayDestinationButton:SetScript("OnEnter", function(self)
    self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
end)
OverlayDestinationButton:SetScript("OnLeave", function(self)
    self.Background:SetColorTexture(0.05, 0.05, 0.06, 0.54)
end)
OverlayDestinationButton:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
        StreamerPlannerModule.SetDestinationText("")
        return
    end

    OpenDestinationEditor()
end)

OverlayDungeonContainer = CreateFrame("Frame", nil, OverlayFrame)
OverlayDungeonContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -16)
OverlayDungeonContainer:SetSize(294, 260)
OverlayDungeonContainer:SetClipsChildren(true)
CreateDungeonLayout(OverlayDungeonContainer, OverlayDungeonButtons, 294)

OverlayRaidContainer = CreateFrame("Frame", nil, OverlayFrame)
OverlayRaidContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -16)
OverlayRaidContainer:SetSize(414, 396)
OverlayRaidContainer:SetClipsChildren(true)
CreateRaidLayout(OverlayRaidContainer, OverlayRaidButtons, 200, 30)

OverlayTimer.Panel = CreateFrame("Frame", nil, OverlayFrame)
OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
OverlayTimer.Panel:SetSize(298, 74)

do
    local background = OverlayTimer.Panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.54)

    local border = OverlayTimer.Panel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", OverlayTimer.Panel, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", OverlayTimer.Panel, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.34)
end

OverlayTimer.Label = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Label:SetPoint("TOPLEFT", OverlayTimer.Panel, "TOPLEFT", 10, -5)
OverlayTimer.Label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
OverlayTimer.Label:SetTextColor(1, 0.82, 0, 1)

OverlayTimer.Status = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Status:SetPoint("RIGHT", OverlayTimer.Panel, "RIGHT", -10, 0)
OverlayTimer.Status:SetPoint("TOP", OverlayTimer.Panel, "TOP", 0, -5)
OverlayTimer.Status:SetJustifyH("RIGHT")
OverlayTimer.Status:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
OverlayTimer.Status:SetTextColor(0.76, 0.76, 0.80, 1)

OverlayTimer.Value = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Value:SetPoint("TOPLEFT", OverlayTimer.Label, "BOTTOMLEFT", 0, -4)
OverlayTimer.Value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
OverlayTimer.Value:SetTextColor(0.92, 0.92, 0.92, 1)

OverlayTimer.ClearAllButton = CreateActionButton(OverlayTimer.Panel, 92, "", function()
    StreamerPlannerModule.ClearAllLayouts()
end)
OverlayTimer.ClearAllButton:SetPoint("BOTTOMLEFT", OverlayTimer.Panel, "BOTTOMLEFT", 10, 8)

OverlayTimer.StartButton = CreateActionButton(OverlayTimer.Panel, 56, "", function()
    StartPlannerTimer()
    RefreshTimerDisplay()
end)
OverlayTimer.StartButton:SetPoint("LEFT", OverlayTimer.ClearAllButton, "RIGHT", 8, 0)

OverlayTimer.PauseButton = CreateActionButton(OverlayTimer.Panel, 56, "", function()
    PausePlannerTimer()
    RefreshTimerDisplay()
end)
OverlayTimer.PauseButton:SetPoint("LEFT", OverlayTimer.StartButton, "RIGHT", 6, 0)

OverlayTimer.ResetButton = CreateActionButton(OverlayTimer.Panel, 56, "", function()
    ResetPlannerTimerState()
    RefreshTimerDisplay()
end)
OverlayTimer.ResetButton:SetPoint("LEFT", OverlayTimer.PauseButton, "RIGHT", 6, 0)

OverlayFrame:SetScript("OnUpdate", function(_, elapsed)
    if not OverlayFrame:IsShown() then
        return
    end

    local settings = GetStreamerPlannerSettings()
    if settings.timerRunning ~= true then
        timerRefreshElapsed = 0
        return
    end

    timerRefreshElapsed = timerRefreshElapsed + (elapsed or 0)
    if timerRefreshElapsed < 0.2 then
        return
    end

    timerRefreshElapsed = 0
    RefreshTimerDisplay()
end)

OverlayFrame:Hide()
ApplyOverlayGeometry()

EditDialog = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
EditDialog:SetSize(520, 292)
EditDialog:SetPoint("CENTER")
EditDialog:SetFrameStrata("DIALOG")
EditDialog:EnableMouse(true)
EditDialog:Hide()

do
    local background = EditDialog:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.07, 0.08, 0.96)

    local border = EditDialog:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", EditDialog, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", EditDialog, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.9)
end

EditDialogTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialogTitle:SetPoint("TOPLEFT", EditDialog, "TOPLEFT", 16, -14)
EditDialogTitle:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialogTitle:SetJustifyH("LEFT")
EditDialogTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
EditDialogTitle:SetTextColor(1, 0.82, 0, 1)

EditDialogHint = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialogHint:SetPoint("TOPLEFT", EditDialogTitle, "BOTTOMLEFT", 0, -8)
EditDialogHint:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialogHint:SetJustifyH("LEFT")
EditDialogHint:SetJustifyV("TOP")
EditDialogHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
EditDialogHint:SetTextColor(0.82, 0.82, 0.86, 1)

EditDialogInput = CreateFrame("EditBox", nil, EditDialog, "InputBoxTemplate")
EditDialogInput:SetSize(484, 28)
EditDialogInput:SetPoint("TOPLEFT", EditDialogHint, "BOTTOMLEFT", 0, -12)
EditDialogInput:SetAutoFocus(false)
EditDialogInput:SetMaxLetters(64)

EditDialogTargetLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialogTargetLabel:SetPoint("BOTTOMLEFT", EditDialogInput, "TOPLEFT", 0, 8)
EditDialogTargetLabel:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialogTargetLabel:SetJustifyH("LEFT")
EditDialogTargetLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
EditDialogTargetLabel:SetTextColor(0.78, 0.78, 0.82, 1)

EditDestinationCategoryLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationCategoryLabel:SetPoint("TOPLEFT", EditDialogHint, "BOTTOMLEFT", 0, -16)
EditDestinationCategoryLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EditDestinationCategoryLabel:SetTextColor(0.92, 0.92, 0.92, 1)

EditDestinationSuggestionLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationSuggestionLabel:SetPoint("TOPLEFT", EditDestinationCategoryLabel, "BOTTOMLEFT", 0, -38)
EditDestinationSuggestionLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EditDestinationSuggestionLabel:SetTextColor(0.92, 0.92, 0.92, 1)

EditDestinationKeystoneLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationKeystoneLabel:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "BOTTOMLEFT", 0, -38)
EditDestinationKeystoneLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EditDestinationKeystoneLabel:SetTextColor(0.92, 0.92, 0.92, 1)

DestinationCategoryDropdown = CreateFrame("Frame", nil, EditDialog, "UIDropDownMenuTemplate")
DestinationCategoryDropdown:SetPoint("TOPLEFT", EditDestinationCategoryLabel, "TOPRIGHT", 8, 2)

DestinationSuggestionDropdown = CreateFrame("Frame", nil, EditDialog, "UIDropDownMenuTemplate")
DestinationSuggestionDropdown:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "TOPRIGHT", 8, 2)

DestinationKeystoneDropdown = CreateFrame("Frame", nil, EditDialog, "UIDropDownMenuTemplate")
DestinationKeystoneDropdown:SetPoint("TOPLEFT", EditDestinationKeystoneLabel, "TOPRIGHT", 8, 2)

UIDropDownMenu_Initialize(DestinationCategoryDropdown, function(_, level)
    local currentCategory = GetDestinationCategory()
    for _, categoryInfo in ipairs(GetDestinationCategoryOptions()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = L(categoryInfo.labelKey)
        info.value = categoryInfo.key
        info.checked = currentCategory == categoryInfo.key
        info.func = function()
            SetDestinationCategory(categoryInfo.key)
            RefreshDestinationCategoryDropdown()
            RefreshDestinationSuggestionDropdown()
            RefreshDestinationKeystoneDropdown()
            StreamerPlannerModule.RefreshAllDisplays()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_Initialize(DestinationSuggestionDropdown, function(_, level)
    local categoryKey = GetDestinationCategory()
    local currentSuggestion = FindDestinationSuggestion(categoryKey, GetDestinationText())

    local manualInfo = UIDropDownMenu_CreateInfo()
    manualInfo.text = L("STREAMER_PLANNER_DESTINATION_MANUAL")
    manualInfo.value = "__manual"
    manualInfo.checked = currentSuggestion == nil
    manualInfo.func = function()
        DestinationInput:SetFocus()
        RefreshDestinationSuggestionDropdown()
        RefreshDestinationKeystoneDropdown()
    end
    UIDropDownMenu_AddButton(manualInfo, level)

    for _, suggestion in ipairs(GetDestinationSuggestions(categoryKey)) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = suggestion
        info.value = suggestion
        info.checked = currentSuggestion == suggestion
        info.func = function()
            if DestinationInput then
                DestinationInput:SetText(suggestion)
                DestinationInput:ClearFocus()
            end
            RefreshDestinationSuggestionDropdown()
            RefreshDestinationKeystoneDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_Initialize(DestinationKeystoneDropdown, function(_, level)
    local currentLevel = GetDestinationKeystoneLevel()
    if type(currentLevel) ~= "number" then
        currentLevel = 0
    end

    for keystoneLevel = 0, 20 do
        local info = UIDropDownMenu_CreateInfo()
        info.text = GetKeystoneLabel(keystoneLevel)
        info.value = keystoneLevel
        info.checked = currentLevel == keystoneLevel
        info.func = function()
            SetDestinationKeystoneLevel(keystoneLevel)
            RefreshDestinationKeystoneDropdown()
            StreamerPlannerModule.RefreshAllDisplays()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

DestinationInput = CreateFrame("EditBox", nil, EditDialog, "InputBoxTemplate")
DestinationInput:SetSize(484, 28)
DestinationInput:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "BOTTOMLEFT", 0, -20)
DestinationInput:SetAutoFocus(false)
DestinationInput:SetMaxLetters(64)
DestinationInput:SetScript("OnTextChanged", function()
    if editingField ~= "destination" then
        return
    end

    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
end)
DestinationInput:SetScript("OnEnterPressed", function()
    if SaveSlotButton then
        SaveSlotButton:Click()
    end
end)
DestinationInput:SetScript("OnEscapePressed", function(self)
    self:SetText(StreamerPlannerModule.GetDestinationText())
    HideEditDialog()
end)

EditClassTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditClassTitle:SetPoint("TOPLEFT", EditDialogInput, "BOTTOMLEFT", 0, -18)
EditClassTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
EditClassTitle:SetTextColor(1, 0.82, 0, 1)

for index, classInfo in ipairs(BuildClassOptions()) do
    if classInfo.file ~= nil then
        local button = CreateIconPickerButton(EditDialog, EDIT_CLASS_BUTTON_SIZE, false)
        button.ClassFile = classInfo.file
        button.DisplayName = classInfo.name
        button.Icon:SetTexture(CLASS_ICON_TEXTURE)
        button.Icon:SetTexCoord(GetClassIconCoords(classInfo.file))
        button.Label:SetText(classInfo.name)
        button:SetScript("OnClick", function(self)
            editingClassFile = self.ClassFile
            editingSpecID = nil
            RefreshClassSpecButtons()
        end)
        EditClassButtons[#EditClassButtons + 1] = button
    end
end

EditSpecTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditSpecTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
EditSpecTitle:SetTextColor(1, 0.82, 0, 1)

for index = 1, 4 do
    local button = CreateIconPickerButton(EditDialog, EDIT_SPEC_BUTTON_SIZE, false)
    button.DisplayName = ""
    button:SetScript("OnClick", function(self)
        editingSpecID = self.SpecID
        RefreshClassSpecButtons()
    end)
    EditSpecButtons[#EditSpecButtons + 1] = button
end

LayoutEditDialogOptionButtons()

SaveSlotButton = CreateActionButton(EditDialog, 92, "", function()
    if editingField == "destination" then
        SetDestinationText(DestinationInput:GetText())
        HideEditDialog()
        StreamerPlannerModule.RefreshAllDisplays()
        return
    end

    if not editingLayout or not editingSlotIndex then
        HideEditDialog()
        return
    end

    SetSlotEntry(editingLayout, editingSlotIndex, {
        name = EditDialogInput:GetText(),
        classFile = editingClassFile,
        specID = editingSpecID,
    })
    HideEditDialog()
    StreamerPlannerModule.RefreshAllDisplays()
end)
SaveSlotButton:SetPoint("BOTTOMLEFT", EditDialog, "BOTTOMLEFT", 16, 20)

ClearSlotButton = CreateActionButton(EditDialog, 92, "", function()
    if editingField == "destination" then
        SetDestinationText("")
        HideEditDialog()
        StreamerPlannerModule.RefreshAllDisplays()
        return
    end

    if editingLayout and editingSlotIndex then
        SetSlotEntry(editingLayout, editingSlotIndex, NormalizeSlotEntry(nil))
    end

    HideEditDialog()
    StreamerPlannerModule.RefreshAllDisplays()
end)
ClearSlotButton:SetPoint("LEFT", SaveSlotButton, "RIGHT", 10, 0)

CancelSlotButton = CreateActionButton(EditDialog, 92, L("CANCEL"), function()
    HideEditDialog()
end)
CancelSlotButton:SetPoint("LEFT", ClearSlotButton, "RIGHT", 10, 0)

EditDialogInput:SetScript("OnEnterPressed", function()
    SaveSlotButton:Click()
end)
EditDialogInput:SetScript("OnEscapePressed", function()
    HideEditDialog()
end)

function PageStreamerPlanner:RefreshState()
    local settings = GetStreamerPlannerSettings()

    IntroTitle:SetText(L("STREAMER_PLANNER_TITLE"))
    IntroText:SetText(L("STREAMER_PLANNER_DESC"))
    UsageHint:SetText(L("STREAMER_PLANNER_USAGE_HINT"))
    PreviewTitle:SetText(L("LIVE_PREVIEW"))
    PreviewHint:SetText(L("STREAMER_PLANNER_PREVIEW_HINT"))
    SettingsPanel.Title:SetText(L("STREAMER_TOOLS"))
    SettingsPanel.Hint:SetText(L("STREAMER_PLANNER_SETTINGS_HINT"))
    ShowOverlayCheckbox.Label:SetText(L("STREAMER_PLANNER_SHOW_OVERLAY"))
    SettingsPanel.ShowOverlayHint:SetText(L("STREAMER_PLANNER_SHOW_OVERLAY_HINT"))
    LockOverlayCheckbox.Label:SetText(L("STREAMER_PLANNER_LOCK_OVERLAY"))
    SettingsPanel.LockOverlayHint:SetText(L("STREAMER_PLANNER_LOCK_OVERLAY_HINT"))
    SettingsPanel.ModeTitle:SetText(L("STREAMER_PLANNER_MODE"))
    SettingsPanel.ModeHint:SetText(L("STREAMER_PLANNER_MODE_HINT"))
    DungeonModeButton:SetText(L("STREAMER_PLANNER_MODE_DUNGEON"))
    RaidModeButton:SetText(L("STREAMER_PLANNER_MODE_RAID"))
    EditDestinationCategoryLabel:SetText(L("STREAMER_PLANNER_DESTINATION_CATEGORY"))
    EditDestinationSuggestionLabel:SetText(L("STREAMER_PLANNER_DESTINATION_SUGGESTION"))
    EditDestinationKeystoneLabel:SetText(L("STREAMER_PLANNER_DESTINATION_KEYSTONE"))
    SettingsPanel.ScaleHint:SetText(L("STREAMER_PLANNER_SCALE_HINT"))
    SettingsPanel.TimerDurationHint:SetText(L("STREAMER_PLANNER_TIMER_DURATION_HINT"))
    SettingsPanel.ResetPositionButton:SetText(L("RESET_POSITION"))
    SettingsPanel.ResetPositionHint:SetText(L("STREAMER_PLANNER_RESET_POSITION_HINT"))
    SettingsPanel.ClearLayoutButton:SetText(L("STREAMER_PLANNER_CLEAR_LAYOUT"))
    SettingsPanel.ClearLayoutHint:SetText(L("STREAMER_PLANNER_CLEAR_LAYOUT_HINT"))
    SettingsPanel.ClearAllButton:SetText(L("STREAMER_PLANNER_CLEAR_ALL"))
    SettingsPanel.ClearAllHint:SetText(L("STREAMER_PLANNER_CLEAR_ALL_HINT"))
    SettingsPanel.EditHint:SetText(L("STREAMER_PLANNER_EDIT_HINT"))
    OverlayTitle:SetText(L("STREAMER_PLANNER_OVERLAY_TITLE"))
    OverlayDungeonModeButton:SetText(L("STREAMER_PLANNER_MODE_DUNGEON"))
    OverlayRaidModeButton:SetText(L("STREAMER_PLANNER_MODE_RAID"))
    OverlayFrame.SettingsButton.Label:SetText(L("STREAMER_PLANNER_OVERLAY_SETTINGS_BUTTON"))
    OverlayTimer.Label:SetText(L("STREAMER_PLANNER_TIMER"))
    OverlayTimer.ClearAllButton:SetText(L("STREAMER_PLANNER_OVERLAY_CLEAR_ALL"))
    OverlayTimer.StartButton:SetText(L("STREAMER_PLANNER_TIMER_START"))
    OverlayTimer.PauseButton:SetText(L("STREAMER_PLANNER_TIMER_PAUSE"))
    OverlayTimer.ResetButton:SetText(L("STREAMER_PLANNER_TIMER_RESET"))
    EditClassTitle:SetText(L("STREAMER_PLANNER_CLASS"))
    EditSpecTitle:SetText(L("STREAMER_PLANNER_SPEC"))
    SaveSlotButton:SetText(L("STREAMER_PLANNER_SAVE_SLOT"))
    ClearSlotButton:SetText(L("STREAMER_PLANNER_CLEAR_SLOT"))
    CancelSlotButton:SetText(L("CANCEL"))

    isRefreshingPage = true
    ShowOverlayCheckbox:SetChecked(settings.overlayEnabled)
    LockOverlayCheckbox:SetChecked(settings.overlayLocked)
    ScaleSlider:SetValue(settings.overlayScale)
    TimerDurationSlider:SetValue(GetTimerDurationMinutes())
    if DestinationInput and editingField ~= "destination" then
        DestinationInput:SetText(settings.destination)
    end
    RefreshDestinationCategoryDropdown()
    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
    RefreshScaleSliderText()
    RefreshTimerDurationSliderText()
    isRefreshingPage = false

    RefreshButtonList(PreviewDungeonButtons)
    RefreshButtonList(PreviewRaidButtons)
    RefreshButtonList(OverlayDungeonButtons)
    RefreshButtonList(OverlayRaidButtons)
    RefreshModeButtons()
    RefreshLayoutVisibility()
    RefreshTimerDisplay()
    StreamerPlannerModule.RefreshOverlayWindow()
    self:UpdateScrollLayout()
end

function PageStreamerPlanner:UpdateScrollLayout()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())
    local settingsHeight = PreviewPanel:GetHeight()

    PageContentFrame:SetWidth(contentWidth)

    if SettingsPanel
        and SettingsPanel.EditHint
        and SettingsPanel:GetTop()
        and SettingsPanel.EditHint:GetBottom()
    then
        settingsHeight = math.max(
            settingsHeight,
            math.ceil((SettingsPanel:GetTop() - SettingsPanel.EditHint:GetBottom()) + 24)
        )
    end

    SettingsPanel:SetHeight(settingsHeight)

    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + math.max(PreviewPanel:GetHeight(), settingsHeight)
        + 20

    PageContentFrame:SetHeight(contentHeight)
end

PageScrollFrame:SetScript("OnSizeChanged", function()
    PageStreamerPlanner:UpdateScrollLayout()
end)

PageScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageContentFrame:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageStreamerPlanner:SetScript("OnShow", function()
    PageStreamerPlanner:RefreshState()
    PageStreamerPlanner:UpdateScrollLayout()
    PageScrollFrame:SetVerticalScroll(0)
end)

BeavisQoL.UpdateStreamerPlanner = function()
    if PageStreamerPlanner and PageStreamerPlanner.RefreshState then
        PageStreamerPlanner:RefreshState()
    else
        StreamerPlannerModule.RefreshAllDisplays()
    end
end

PageStreamerPlanner:RefreshState()
PageStreamerPlanner:UpdateScrollLayout()

BeavisQoL.Pages.StreamerPlanner = PageStreamerPlanner
