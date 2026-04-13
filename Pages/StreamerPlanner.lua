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
local PREVIEW_PANEL_DUNGEON_WIDTH = 430
local OVERLAY_FRAME_DUNGEON_WIDTH = 334
local DEFAULT_TIMER_DURATION_SECONDS = 15 * 60
local TIMER_WARNING_THRESHOLD_SECONDS = 60
local MIN_TIMER_DURATION_MINUTES = 1
local MAX_TIMER_DURATION_MINUTES = 60
local INSPECT_REQUEST_INTERVAL_SECONDS = 2
local INSPECT_REQUEST_TIMEOUT_SECONDS = 4
local WHISPER_SPEC_REQUEST_COOLDOWN_SECONDS = 15
local STREAMER_PLANNER_ADDON_PREFIX = "BeavisQoLSP"
local STREAMER_PLANNER_ADDON_SPEC_QUERY = "SPEC_QUERY"
local STREAMER_PLANNER_ADDON_SPEC_REPLY = "SPEC_REPLY"
local WHISPER_SPEC_PROMPT_WIDTH = 264
local WHISPER_SPEC_PROMPT_MIN_HEIGHT = 126
local WHISPER_CLASS_PROMPT_BUTTON_SIZE = 40
local WHISPER_CLASS_PROMPT_BUTTON_COLUMNS = 5
local WHISPER_CLASS_PROMPT_BUTTON_SPACING = 6
local WHISPER_SPEC_PROMPT_BUTTON_SIZE = 72
local WHISPER_SPEC_PROMPT_BUTTON_COLUMNS = 2
local WHISPER_SPEC_PROMPT_BUTTON_SPACING = 12
local ROLE_ICON_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local WHISPER_ROLE_PROMPT_BUTTON_SIZE = 42
local WHISPER_ROLE_PROMPT_BUTTON_SPACING = 8

StreamerPlannerModule.SPEC_DATA_BY_CLASS = {
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

StreamerPlannerModule.CLASS_ROLE_SUPPORT = {
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

StreamerPlannerModule.SPEC_ROLE_SUPPORT = {
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

local WHISPER_ROLE_ALIAS_MAP = {
    tank = "tank",
    heal = "healer",
    healer = "healer",
    heiler = "healer",
    dps = "dps",
    dd = "dps",
    damage = "dps",
    damager = "dps",
}

StreamerPlannerModule.WHISPER_SPEC_ALIAS_HINTS = {
    [71] = { "arms", "waffen" },
    [72] = { "fury", "wut", "furor" },
    [73] = { "protection", "prot", "schutz" },
    [65] = { "holy", "heilig" },
    [66] = { "protection", "prot", "schutz" },
    [70] = { "retribution", "ret", "retri", "vergeltung" },
    [253] = { "bm", "beast mastery", "beastmastery", "beast", "tierherrschaft" },
    [254] = { "mm", "marksmanship", "marksman", "treffsicherheit" },
    [255] = { "survival", "sv", "surv", "ueberleben", "uberleben", "überleben" },
    [259] = { "assassination", "assa", "meucheln" },
    [260] = { "outlaw", "gesetzlosigkeit" },
    [261] = { "subtlety", "sub", "taeuschung", "täuschung" },
    [256] = { "discipline", "disc", "diszi", "disziplin" },
    [257] = { "holy", "heilig" },
    [258] = { "shadow", "schatten" },
    [250] = { "blood", "blut" },
    [251] = { "frost" },
    [252] = { "unholy", "unheilig" },
    [262] = { "elemental", "ele", "elementar" },
    [263] = { "enhancement", "enh", "enha", "enhance", "verstaerkung", "verstarkung", "verstärkung" },
    [264] = { "restoration", "resto", "wiederherstellung" },
    [62] = { "arcane", "arkan" },
    [63] = { "fire", "feuer" },
    [64] = { "frost" },
    [265] = { "affliction", "affli", "gebrechen" },
    [266] = { "demonology", "demo", "daemonology", "dämonologie", "daemonologie" },
    [267] = { "destruction", "destro", "zerstoerung", "zerstörung" },
    [268] = { "brewmaster", "brew", "braumeister" },
    [269] = { "windwalker", "ww", "windlaeufer", "windläufer" },
    [270] = { "mistweaver", "mist", "mw", "nebelwirker", "nebel" },
    [102] = { "balance", "boomkin", "boomy", "owlkin", "moonkin", "eule" },
    [103] = { "feral", "cat", "katze" },
    [104] = { "guardian", "bear", "baer", "bär" },
    [105] = { "restoration", "resto", "tree", "baum", "wiederherstellung" },
    [577] = { "havoc", "verwuestung", "verwüstung" },
    [581] = { "vengeance", "rache" },
    [1467] = { "devastation", "dev", "verheerung" },
    [1468] = { "preservation", "prev", "bewahrung" },
    [1473] = { "augmentation", "aug", "verstaerkung", "verstarkung", "verstärkung" },
}

local DUNGEON_SLOT_ROLE_REQUIREMENTS = {
    tank = "tank",
    healer = "healer",
    dps1 = "dps",
    dps2 = "dps",
    dps3 = "dps",
}

StreamerPlannerModule.DESTINATION_CATEGORIES = {
    { key = "s1", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_S1" },
    { key = "delves", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_DELVES" },
    { key = "midnight", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_MIDNIGHT" },
    { key = "raids", labelKey = "STREAMER_PLANNER_DESTINATION_CATEGORY_RAIDS" },
}

StreamerPlannerModule.DESTINATION_OPTIONS = {
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

StreamerPlannerModule.DUNGEON_LAYOUT = {
    { key = "tank", labelKey = "STREAMER_PLANNER_ROLE_TANK" },
    { key = "healer", labelKey = "STREAMER_PLANNER_ROLE_HEALER" },
    { key = "dps1", labelKey = "STREAMER_PLANNER_ROLE_DPS1" },
    { key = "dps2", labelKey = "STREAMER_PLANNER_ROLE_DPS2" },
    { key = "dps3", labelKey = "STREAMER_PLANNER_ROLE_DPS3" },
}

local RAID_GROUP_COUNT = 8
local RAID_GROUP_SIZE = 5
local RAID_SLOT_COUNT = RAID_GROUP_COUNT * RAID_GROUP_SIZE
local RAID_GROUP_COLUMNS = 4
local RAID_GROUP_COLUMN_SPACING = 10
local RAID_GROUP_ROW_SPACING = 12
local RAID_GROUP_TITLE_GAP = 5
local PREVIEW_RAID_SLOT_HEIGHT = 22
local PREVIEW_RAID_GROUP_WIDTH = 116
local OVERLAY_RAID_SLOT_HEIGHT = 26
local OVERLAY_RAID_GROUP_WIDTH = 124
local MIN_OVERLAY_RAID_GROUP_WIDTH = 92
local OVERLAY_RAID_FRAME_BASE_HEIGHT = 292

local PageStreamerPlanner
local PageScrollFrame
local PageContentFrame
local OverlayFrame
local OverlayTitle
local OverlayDestinationButton
local OverlayInviteRow
local OverlayFullInviteButton
local OverlayAutoInviteCheckbox
local OverlayDungeonContainer
local OverlayRaidContainer
local OverlayTimer = {}
local ApplicantPanel
local WhisperSpecPromptUI = {
    Buttons = {},
    ClassButtons = {},
    RoleButtons = {},
}
local PreviewUI = {
    DungeonButtons = {},
    RaidButtons = {},
}
local ScaleSlider
local TimerDurationSlider
local DestinationInput
local DestinationCategoryDropdown
local DestinationSuggestionDropdown
local DestinationKeystoneDropdown
local EditDialog
local EditDialogInput
local EditDialogTargetLabel
local EditClassTitle
local EditSpecTitle
local EditDestinationCategoryLabel
local EditDestinationSuggestionLabel
local EditDestinationKeystoneLabel

local OverlayDungeonButtons = {}
local OverlayRaidButtons = {}
local OverlayRaidGroupFrames = nil
local ApplicantRows = {}
local HideEditDialog
local GetStreamerPlannerSettings
local GetDungeonSlotInfo
local LayoutEditDialogOptionButtons
local PlannerPrivate = {
    applicantSnapshot = nil,
    applicantByName = {},
    secretValueByString = {},
    normalizedCompareByValue = {},
    identityKeysByValue = {},
    displayNameByFullName = {},
    fullNameByCharacterAndRealm = {},
    inspectSpecByGUID = {},
    inspectSpecByName = {},
    pendingSpecPromptQueue = {},
    pendingSpecPromptLookup = {},
    activeSpecPromptIdentity = nil,
    specRequestCooldownByName = {},
    pendingInspectGUID = nil,
    pendingInspectUnit = nil,
    pendingInspectFullName = nil,
    pendingInspectClassFile = nil,
    pendingInspectExpiresAt = 0,
    nextInspectAllowedAt = 0,
    periodicSyncElapsed = 0,
    lastDungeonSyncSignature = nil,
    whisperSessionInitialized = false,
    isRefreshingPage = false,
    editingLayout = nil,
    editingSlotIndex = nil,
    editingField = nil,
    editingClassFile = nil,
    editingSpecID = nil,
    editingRoleKey = nil,
    editingUsesSelfRoleOverride = false,
    classOptionsCache = nil,
    classInfoByFileCache = nil,
    specOptionsCache = {},
    editClassButtons = {},
    editSpecButtons = {},
    editRoleButtons = {},
    saveSlotButton = nil,
    clearSlotButton = nil,
    cancelSlotButton = nil,
    timerRefreshElapsed = 0,
    watcher = nil,
    whisperSpecAliasLookupByClass = nil,
    whisperSpecAliasLookupGlobal = nil,
    currentGroupLookupCache = nil,
    currentGroupLookupDirty = true,
}

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

local function GetInspectGuardTimestamp()
    if GetTimePreciseSec then
        return GetTimePreciseSec()
    end

    if GetTime then
        return GetTime()
    end

    return time()
end

local inspectFrameProtectionUntil = 0
local inspectFrameHooksInstalled = false

local function MarkInspectFrameProtected(durationSeconds)
    local duration = tonumber(durationSeconds) or 0
    if duration <= 0 then
        duration = 1
    end

    inspectFrameProtectionUntil = math.max(inspectFrameProtectionUntil, GetInspectGuardTimestamp() + duration)
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

    return inspectFrameProtectionUntil > GetInspectGuardTimestamp()
end

PlannerPrivate.ClearPendingInspectRequest = function()
    PlannerPrivate.pendingInspectGUID = nil
    PlannerPrivate.pendingInspectUnit = nil
    PlannerPrivate.pendingInspectFullName = nil
    PlannerPrivate.pendingInspectClassFile = nil
    PlannerPrivate.pendingInspectExpiresAt = 0
end

PlannerPrivate.ExpirePendingInspectRequest = function()
    if PlannerPrivate.pendingInspectGUID == nil then
        return
    end

    local expiresAt = tonumber(PlannerPrivate.pendingInspectExpiresAt) or 0
    if expiresAt > 0 and GetCurrentTimestamp() < expiresAt then
        return
    end

    PlannerPrivate.ClearPendingInspectRequest()
end

PlannerPrivate.GetRoleKeyFromSpecID = function(specID)
    if type(specID) ~= "number" or specID <= 0 then
        return nil
    end

    return PlannerPrivate.NormalizePlannerRoleKey(StreamerPlannerModule.SPEC_ROLE_SUPPORT[specID])
end

PlannerPrivate.GetKnownSpecID = function(fullName, playerGUID)
    if PlannerPrivate.IsUsablePlainString(playerGUID) then
        local guidSpecID = PlannerPrivate.inspectSpecByGUID[playerGUID]
        if type(guidSpecID) == "number" and guidSpecID > 0 then
            return guidSpecID
        end
    end

    local identityKey = PlannerPrivate.GetIdentityKey(fullName)
    if identityKey then
        local nameSpecID = PlannerPrivate.inspectSpecByName[identityKey]
        if type(nameSpecID) == "number" and nameSpecID > 0 then
            return nameSpecID
        end
    end

    return nil
end

PlannerPrivate.StoreKnownCharacterInfo = function(fullName, playerGUID, classFile, specID)
    local changed = false

    if type(specID) == "number" and specID > 0 then
        if PlannerPrivate.IsUsablePlainString(playerGUID) and PlannerPrivate.inspectSpecByGUID[playerGUID] ~= specID then
            PlannerPrivate.inspectSpecByGUID[playerGUID] = specID
            changed = true
        end

        local identityKey = PlannerPrivate.GetIdentityKey(fullName)
        if identityKey and PlannerPrivate.inspectSpecByName[identityKey] ~= specID then
            PlannerPrivate.inspectSpecByName[identityKey] = specID
            changed = true
        end
    end

    local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(fullName)
    if whisperEntry then
        local whisperChanged = false
        local resolvedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(whisperEntry.roleKey)

        if PlannerPrivate.IsUsablePlainString(classFile) and whisperEntry.classFile ~= classFile then
            whisperEntry.classFile = classFile
            whisperChanged = true
        end

        if type(specID) == "number" and specID > 0 and whisperEntry.specID ~= specID then
            whisperEntry.specID = specID
            whisperChanged = true
        end

        if resolvedRoleKey == nil then
            resolvedRoleKey = PlannerPrivate.GetSingleSupportedRoleKey(whisperEntry.classFile or classFile)
        end

        if resolvedRoleKey ~= nil and whisperEntry.roleKey ~= resolvedRoleKey then
            whisperEntry.roleKey = resolvedRoleKey
            whisperChanged = true
        end

        if whisperChanged then
            whisperEntry.updatedAt = GetCurrentTimestamp()
            local settings = GetStreamerPlannerSettings and GetStreamerPlannerSettings() or nil
            if type(settings) == "table" then
                settings.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(settings.whisperApplicants)
            end
            if whisperEntry.command == "enter" and PlannerPrivate.NeedsWhisperSpecSelection(whisperEntry) then
                PlannerPrivate.EnqueueWhisperSpecPrompt(whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName)
            end
            changed = true
        end
    end

    return changed
end

PlannerPrivate.FindGroupUnitByGUID = function(targetGUID)
    if not PlannerPrivate.IsUsablePlainString(targetGUID) or not UnitGUID then
        return nil
    end

    if UnitExists and UnitExists("player") and UnitGUID("player") == targetGUID then
        return "player"
    end

    if IsInRaid and IsInRaid() and GetNumGroupMembers then
        for memberIndex = 1, (GetNumGroupMembers() or 0) do
            local unit = "raid" .. memberIndex
            if UnitExists and UnitExists(unit) and UnitGUID(unit) == targetGUID then
                return unit
            end
        end
    elseif IsInGroup and IsInGroup() and GetNumSubgroupMembers then
        for memberIndex = 1, (GetNumSubgroupMembers() or 0) do
            local unit = "party" .. memberIndex
            if UnitExists and UnitExists(unit) and UnitGUID(unit) == targetGUID then
                return unit
            end
        end
    end

    return nil
end

PlannerPrivate.ShouldInspectUnitParticipant = function(classFile, specID, roleKey)
    if type(specID) == "number" and specID > 0 then
        return false
    end

    if PlannerPrivate.NormalizePlannerRoleKey(roleKey) ~= nil then
        return false
    end

    local supportedRoles = classFile and StreamerPlannerModule.CLASS_ROLE_SUPPORT[classFile] or nil
    if type(supportedRoles) ~= "table" then
        return false
    end

    local supportedRoleCount = 0
    for _, candidateRoleKey in ipairs({ "tank", "healer", "dps" }) do
        if supportedRoles[candidateRoleKey] then
            supportedRoleCount = supportedRoleCount + 1
        end
    end

    return supportedRoleCount > 1
end

PlannerPrivate.QueueInspectForUnit = function(unit, fullName, classFile)
    PlannerPrivate.ExpirePendingInspectRequest()

    if not unit
        or unit == "player"
        or not UnitExists
        or not UnitExists(unit)
        or type(NotifyInspect) ~= "function"
        or type(GetInspectSpecialization) ~= "function"
        or not UnitGUID
    then
        return false
    end

    local unitGUID = UnitGUID(unit)
    if not PlannerPrivate.IsUsablePlainString(unitGUID) then
        return false
    end

    if PlannerPrivate.GetKnownSpecID(fullName, unitGUID) ~= nil then
        return false
    end

    if type(CanInspect) == "function" and CanInspect(unit) ~= true then
        return false
    end

    if IsBlizzardInspectFrameActive() then
        return false
    end

    if PlannerPrivate.pendingInspectGUID ~= nil then
        return PlannerPrivate.pendingInspectGUID == unitGUID
    end

    local currentTimestamp = GetCurrentTimestamp()
    if type(PlannerPrivate.nextInspectAllowedAt) == "number" and currentTimestamp < PlannerPrivate.nextInspectAllowedAt then
        return false
    end

    PlannerPrivate.pendingInspectGUID = unitGUID
    PlannerPrivate.pendingInspectUnit = unit
    PlannerPrivate.pendingInspectFullName = fullName
    PlannerPrivate.pendingInspectClassFile = classFile
    PlannerPrivate.pendingInspectExpiresAt = currentTimestamp + INSPECT_REQUEST_TIMEOUT_SECONDS
    PlannerPrivate.nextInspectAllowedAt = currentTimestamp + INSPECT_REQUEST_INTERVAL_SECONDS

    NotifyInspect(unit)
    return true
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

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local function GetMeasuredPanelHeight(panel, bottomObject, padding, minimumHeight)
    local fallbackHeight

    if type(minimumHeight) == "number" and minimumHeight > 0 then
        fallbackHeight = minimumHeight
    else
        fallbackHeight = (panel and panel:GetHeight()) or 0
    end

    if not panel or not bottomObject or not panel:GetTop() or not bottomObject:GetBottom() then
        return fallbackHeight
    end

    return math.max(fallbackHeight, math.ceil((panel:GetTop() - bottomObject:GetBottom()) + (padding or 0)))
end

local function LayoutStreamerPlannerSettingsPanel(settingsPanel)
    if not settingsPanel then
        return
    end

    settingsPanel.Title:ClearAllPoints()
    settingsPanel.Title:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 18, -14)

    settingsPanel.Hint:ClearAllPoints()
    settingsPanel.Hint:SetPoint("TOPLEFT", settingsPanel.Title, "BOTTOMLEFT", 0, -8)
    settingsPanel.Hint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.ShowOverlayCheckbox:ClearAllPoints()
    settingsPanel.ShowOverlayCheckbox:SetPoint("TOPLEFT", settingsPanel.Hint, "BOTTOMLEFT", -4, -14)

    settingsPanel.ShowOverlayHint:ClearAllPoints()
    settingsPanel.ShowOverlayHint:SetPoint("TOPLEFT", settingsPanel.ShowOverlayCheckbox, "BOTTOMLEFT", 34, -2)
    settingsPanel.ShowOverlayHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.LockOverlayCheckbox:ClearAllPoints()
    settingsPanel.LockOverlayCheckbox:SetPoint("TOPLEFT", settingsPanel.ShowOverlayHint, "BOTTOMLEFT", -34, -12)

    settingsPanel.LockOverlayHint:ClearAllPoints()
    settingsPanel.LockOverlayHint:SetPoint("TOPLEFT", settingsPanel.LockOverlayCheckbox, "BOTTOMLEFT", 34, -2)
    settingsPanel.LockOverlayHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.ModeTitle:ClearAllPoints()
    settingsPanel.ModeTitle:SetPoint("TOPLEFT", settingsPanel.LockOverlayHint, "BOTTOMLEFT", 0, -18)

    settingsPanel.ModeHint:ClearAllPoints()
    settingsPanel.ModeHint:SetPoint("TOPLEFT", settingsPanel.ModeTitle, "BOTTOMLEFT", 0, -6)
    settingsPanel.ModeHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.DungeonModeButton:ClearAllPoints()
    settingsPanel.DungeonModeButton:SetPoint("TOPLEFT", settingsPanel.ModeHint, "BOTTOMLEFT", 0, -12)

    settingsPanel.RaidModeButton:ClearAllPoints()
    settingsPanel.RaidModeButton:SetPoint("LEFT", settingsPanel.DungeonModeButton, "RIGHT", 12, 0)

    local sliderWidth = math.max(220, math.min(310, settingsPanel:GetWidth() - 56))

    ScaleSlider:ClearAllPoints()
    ScaleSlider:SetPoint("TOPLEFT", settingsPanel.DungeonModeButton, "BOTTOMLEFT", 18, -30)
    ScaleSlider:SetWidth(sliderWidth)

    settingsPanel.ScaleHint:ClearAllPoints()
    settingsPanel.ScaleHint:SetPoint("TOPLEFT", (ScaleSlider.LowLabel or ScaleSlider), "BOTTOMLEFT", -2, -14)
    settingsPanel.ScaleHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    TimerDurationSlider:ClearAllPoints()
    TimerDurationSlider:SetPoint("TOPLEFT", settingsPanel.ScaleHint, "BOTTOMLEFT", 0, -26)
    TimerDurationSlider:SetWidth(sliderWidth)

    settingsPanel.TimerDurationHint:ClearAllPoints()
    settingsPanel.TimerDurationHint:SetPoint("TOPLEFT", (TimerDurationSlider.LowLabel or TimerDurationSlider), "BOTTOMLEFT", -2, -14)
    settingsPanel.TimerDurationHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.ResetPositionButton:ClearAllPoints()
    settingsPanel.ResetPositionButton:SetPoint("TOPLEFT", settingsPanel.TimerDurationHint, "BOTTOMLEFT", 0, -16)

    settingsPanel.ResetPositionHint:ClearAllPoints()
    settingsPanel.ResetPositionHint:SetPoint("TOPLEFT", settingsPanel.ResetPositionButton, "BOTTOMLEFT", 0, -8)
    settingsPanel.ResetPositionHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.ClearLayoutButton:ClearAllPoints()
    settingsPanel.ClearLayoutButton:SetPoint("TOPLEFT", settingsPanel.ResetPositionHint, "BOTTOMLEFT", 0, -16)

    settingsPanel.ClearLayoutHint:ClearAllPoints()
    settingsPanel.ClearLayoutHint:SetPoint("TOPLEFT", settingsPanel.ClearLayoutButton, "BOTTOMLEFT", 0, -8)
    settingsPanel.ClearLayoutHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.ClearAllButton:ClearAllPoints()
    settingsPanel.ClearAllButton:SetPoint("TOPLEFT", settingsPanel.ClearLayoutHint, "BOTTOMLEFT", 0, -16)

    settingsPanel.ClearAllHint:ClearAllPoints()
    settingsPanel.ClearAllHint:SetPoint("TOPLEFT", settingsPanel.ClearAllButton, "BOTTOMLEFT", 0, -8)
    settingsPanel.ClearAllHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)

    settingsPanel.EditHint:ClearAllPoints()
    settingsPanel.EditHint:SetPoint("TOPLEFT", settingsPanel.ClearAllHint, "BOTTOMLEFT", 0, -16)
    settingsPanel.EditHint:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)
end

local function GetRaidLayoutRowCount()
    return math.ceil(RAID_GROUP_COUNT / RAID_GROUP_COLUMNS)
end

local function GetRaidLayoutContainerWidth(groupWidth)
    local resolvedGroupWidth = groupWidth or OVERLAY_RAID_GROUP_WIDTH
    return (RAID_GROUP_COLUMNS * resolvedGroupWidth) + ((math.max(RAID_GROUP_COLUMNS - 1, 0)) * RAID_GROUP_COLUMN_SPACING)
end

local function GetRaidLayoutGroupHeight(slotHeight)
    local resolvedSlotHeight = slotHeight or OVERLAY_RAID_SLOT_HEIGHT
    return 20 + RAID_GROUP_TITLE_GAP + (RAID_GROUP_SIZE * resolvedSlotHeight) + ((RAID_GROUP_SIZE - 1) * 4)
end

local function GetRaidLayoutContainerHeight(slotHeight, extraPadding)
    local rowCount = GetRaidLayoutRowCount()
    local groupHeight = GetRaidLayoutGroupHeight(slotHeight)
    return (rowCount * groupHeight) + ((math.max(rowCount - 1, 0)) * RAID_GROUP_ROW_SPACING) + (extraPadding or 0)
end

local function GetOverlayRaidGroupWidth()
    local parentWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1024
    local overlayScale = GetStreamerPlannerSettings and GetStreamerPlannerSettings().overlayScale or DEFAULT_OVERLAY_SCALE
    local safeFrameWidth = math.max(420, math.floor((parentWidth - 32) / math.max(overlayScale or 1, 0.01)))
    local safeContainerWidth = math.max(
        (RAID_GROUP_COLUMNS * MIN_OVERLAY_RAID_GROUP_WIDTH) + ((RAID_GROUP_COLUMNS - 1) * RAID_GROUP_COLUMN_SPACING),
        safeFrameWidth - 44
    )
    local computedWidth = math.floor((safeContainerWidth - ((RAID_GROUP_COLUMNS - 1) * RAID_GROUP_COLUMN_SPACING)) / RAID_GROUP_COLUMNS)
    return Clamp(computedWidth, MIN_OVERLAY_RAID_GROUP_WIDTH, OVERLAY_RAID_GROUP_WIDTH)
end

local function GetPreviewPanelWidthForMode(mode)
    if mode == "raid" then
        return GetRaidLayoutContainerWidth(PREVIEW_RAID_GROUP_WIDTH) + 38
    end

    return PREVIEW_PANEL_DUNGEON_WIDTH
end

local function GetOverlayFrameWidthForMode(mode, raidGroupWidth)
    if mode == "raid" then
        return GetRaidLayoutContainerWidth(raidGroupWidth or GetOverlayRaidGroupWidth()) + 44
    end

    return OVERLAY_FRAME_DUNGEON_WIDTH
end

local function GetDestinationCategoryOptions()
    return StreamerPlannerModule.DESTINATION_CATEGORIES
end

local function GetDestinationSuggestions(categoryKey)
    local suggestionKeys = StreamerPlannerModule.DESTINATION_OPTIONS[categoryKey] or {}
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

PlannerPrivate.destinationAliasCache = nil

local function CanUsePlannerStringCacheKey(value)
    if type(value) ~= "string" then
        return false
    end

    if not issecretvalue then
        return true
    end

    local ok, isSecret = pcall(issecretvalue, value)
    return ok and isSecret ~= true
end

PlannerPrivate.IsSecretValue = function(value)
    if not issecretvalue then
        return false
    end

    if type(value) ~= "string" then
        local ok, isSecret = pcall(issecretvalue, value)
        return ok and isSecret == true
    end

    local ok, isSecret = pcall(issecretvalue, value)
    if not ok then
        return false
    end

    if isSecret == true then
        return true
    end

    if CanUsePlannerStringCacheKey(value) then
        local cachedIsSecret = PlannerPrivate.secretValueByString[value]
        if cachedIsSecret ~= nil then
            return cachedIsSecret == true
        end

        PlannerPrivate.secretValueByString[value] = false
    end

    return false
end


-- Schutz vor zu langen Strings und Endlosschleifen
local MAX_STRING_LENGTH = 1000
local MAX_RECURSION_DEPTH = 5

local function IsUsablePlainStringInternal(value, depth)
    if depth > MAX_RECURSION_DEPTH then
        return false
    end
    if type(value) ~= "string" then
        return false
    end
    if PlannerPrivate.IsSecretValue(value) then
        return false
    end
    if #value > MAX_STRING_LENGTH then
        return false
    end
    return value ~= ""
end

PlannerPrivate.IsUsablePlainString = function(value)
    return IsUsablePlainStringInternal(value, 1)
end

PlannerPrivate.NormalizePlannerRoleKey = function(roleKey)
    if roleKey == "tank" or roleKey == "healer" or roleKey == "dps" then
        return roleKey
    end

    if type(roleKey) ~= "string" then
        return nil
    end

    local normalized = roleKey:upper()
    if normalized == "TANK" then
        return "tank"
    end

    if normalized == "HEALER" then
        return "healer"
    end

    if normalized == "DAMAGER" or normalized == "DAMAGE" or normalized == "DPS" then
        return "dps"
    end

    return nil
end

PlannerPrivate.GetPlannerRoleLabel = function(roleKey)
    local normalizedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(roleKey)
    if normalizedRoleKey == "tank" then
        return L("STREAMER_PLANNER_ROLE_TANK")
    end

    if normalizedRoleKey == "healer" then
        return L("STREAMER_PLANNER_ROLE_HEALER")
    end

    if normalizedRoleKey == "dps" then
        return "DPS"
    end

    return nil
end

PlannerPrivate.GetRoleIconTexCoords = function(roleKey)
    local normalizedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(roleKey)
    if normalizedRoleKey == "tank" then
        return 0, 0.26171875, 0.26171875, 0.5234375
    end

    if normalizedRoleKey == "healer" then
        return 0.26171875, 0.5234375, 0, 0.26171875
    end

    if normalizedRoleKey == "dps" then
        return 0.26171875, 0.5234375, 0.26171875, 0.5234375
    end

    return 0, 1, 0, 1
end

PlannerPrivate.NormalizeCompareText = function(value)
    if type(value) ~= "string" then
        return nil
    end

    local canCacheByValue = CanUsePlannerStringCacheKey(value)
    if canCacheByValue then
        local cachedValue = PlannerPrivate.normalizedCompareByValue[value]
        if cachedValue ~= nil then
            return cachedValue or nil
        end
    end

    if not PlannerPrivate.IsUsablePlainString(value) then
        if canCacheByValue then
            PlannerPrivate.normalizedCompareByValue[value] = false
        end
        return nil
    end

    local normalized = value:lower()
    normalized = normalized:gsub("[%p|]", " ")
    normalized = normalized:gsub("%s+", " ")
    normalized = normalized:match("^%s*(.-)%s*$")
    if normalized == "" then
        if canCacheByValue then
            PlannerPrivate.normalizedCompareByValue[value] = false
        end
        return nil
    end

    if canCacheByValue then
        PlannerPrivate.normalizedCompareByValue[value] = normalized
    end
    return normalized
end

local function AddWhisperSpecAlias(target, aliasText, specID)
    local normalizedAlias = PlannerPrivate.NormalizeCompareText(aliasText)
    if normalizedAlias == nil or type(specID) ~= "number" or specID <= 0 then
        return
    end

    if target[normalizedAlias] == nil then
        target[normalizedAlias] = specID
    elseif target[normalizedAlias] ~= specID then
        target[normalizedAlias] = false
    end
end

local function BuildWhisperSpecAliasLookups()
    if PlannerPrivate.whisperSpecAliasLookupByClass ~= nil and PlannerPrivate.whisperSpecAliasLookupGlobal ~= nil then
        return PlannerPrivate.whisperSpecAliasLookupByClass, PlannerPrivate.whisperSpecAliasLookupGlobal
    end

    local byClass = {}
    local global = {}

    for classFile, specList in pairs(StreamerPlannerModule.SPEC_DATA_BY_CLASS) do
        byClass[classFile] = byClass[classFile] or {}

        for _, specID in ipairs(specList or {}) do
            AddWhisperSpecAlias(byClass[classFile], tostring(specID), specID)
            AddWhisperSpecAlias(global, tostring(specID), specID)

            local localizedSpecName = nil
            if GetSpecializationInfoByID then
                local _, resolvedSpecName = GetSpecializationInfoByID(specID)
                localizedSpecName = resolvedSpecName
            end

            if localizedSpecName then
                AddWhisperSpecAlias(byClass[classFile], localizedSpecName, specID)
                AddWhisperSpecAlias(global, localizedSpecName, specID)
            end

            for _, aliasText in ipairs(StreamerPlannerModule.WHISPER_SPEC_ALIAS_HINTS[specID] or {}) do
                AddWhisperSpecAlias(byClass[classFile], aliasText, specID)
                AddWhisperSpecAlias(global, aliasText, specID)
            end
        end
    end

    PlannerPrivate.whisperSpecAliasLookupByClass = byClass
    PlannerPrivate.whisperSpecAliasLookupGlobal = global
    return PlannerPrivate.whisperSpecAliasLookupByClass, PlannerPrivate.whisperSpecAliasLookupGlobal
end

local function PayloadContainsAlias(payloadText, aliasText)
    if payloadText == nil or aliasText == nil then
        return false
    end

    if payloadText == aliasText then
        return true
    end

    return (" " .. payloadText .. " "):find(" " .. aliasText .. " ", 1, true) ~= nil
end

local RAID_DIFFICULTY_OPTIONS = {
    { key = "normal", labelKey = "ITEM_GUIDE_LABEL_NORMAL", aliases = { "normal", "nhc" } },
    { key = "heroic", labelKey = "ITEM_GUIDE_LABEL_HEROIC", aliases = { "heroic", "heroisch", "hc" } },
    { key = "mythic", labelKey = "ITEM_GUIDE_LABEL_MYTHIC", aliases = { "mythic", "mythisch" } },
}

PlannerPrivate.NormalizeRaidDifficultyKey = function(value)
    local normalizedValue = PlannerPrivate.NormalizeCompareText(value)
    if normalizedValue == nil then
        return nil
    end

    for _, difficultyInfo in ipairs(RAID_DIFFICULTY_OPTIONS) do
        if normalizedValue == difficultyInfo.key then
            return difficultyInfo.key
        end

        for _, aliasText in ipairs(difficultyInfo.aliases) do
            if normalizedValue == aliasText then
                return difficultyInfo.key
            end
        end
    end

    return nil
end

PlannerPrivate.GetRaidDifficultyLabel = function(value)
    local difficultyKey = PlannerPrivate.NormalizeRaidDifficultyKey(value)
    if difficultyKey == nil then
        return nil
    end

    for _, difficultyInfo in ipairs(RAID_DIFFICULTY_OPTIONS) do
        if difficultyInfo.key == difficultyKey then
            return L(difficultyInfo.labelKey)
        end
    end

    return nil
end

PlannerPrivate.ParseRaidDifficultyFromText = function(textCandidates)
    for _, candidateText in ipairs(textCandidates or {}) do
        local normalizedCandidate = PlannerPrivate.NormalizeCompareText(candidateText)
        if normalizedCandidate ~= nil then
            for _, difficultyInfo in ipairs(RAID_DIFFICULTY_OPTIONS) do
                for _, aliasText in ipairs(difficultyInfo.aliases) do
                    if PayloadContainsAlias(normalizedCandidate, aliasText) then
                        return difficultyInfo.key
                    end
                end
            end
        end
    end

    return nil
end

PlannerPrivate.GetWhisperCommandPayload = function(messageText)
    if type(messageText) ~= "string" then
        return nil
    end

    local trimmedMessage = messageText:match("^%s*(.-)%s*$") or ""
    local commandName, payloadText = trimmedMessage:match("^!(%S+)%s*(.-)%s*$")
    if type(commandName) ~= "string" then
        return nil
    end

    commandName = commandName:lower()
    if commandName ~= "enter" and commandName ~= "inv" then
        return nil
    end

    if payloadText == "" then
        return nil
    end

    return payloadText
end

PlannerPrivate.ResolveWhisperRoleHint = function(messageText)
    local payloadText = PlannerPrivate.NormalizeCompareText(PlannerPrivate.GetWhisperCommandPayload(messageText))
    if payloadText == nil then
        return nil
    end

    local matchedRoleKey = nil
    for aliasText, roleKey in pairs(WHISPER_ROLE_ALIAS_MAP) do
        if PayloadContainsAlias(payloadText, aliasText) then
            if matchedRoleKey ~= nil and matchedRoleKey ~= roleKey then
                return nil
            end
            matchedRoleKey = roleKey
        end
    end

    return PlannerPrivate.NormalizePlannerRoleKey(matchedRoleKey)
end

PlannerPrivate.ResolveWhisperSpecHint = function(messageText, classFile)
    local payloadText = PlannerPrivate.NormalizeCompareText(PlannerPrivate.GetWhisperCommandPayload(messageText))
    if payloadText == nil then
        return nil
    end

    local lookupByClass, globalLookup = BuildWhisperSpecAliasLookups()
    local aliasLookup = globalLookup
    if classFile and type(lookupByClass) == "table" then
        aliasLookup = lookupByClass[classFile] or aliasLookup
    end
    if type(aliasLookup) ~= "table" then
        return nil
    end

    local matchedSpecID = nil
    for aliasText, specID in pairs(aliasLookup) do
        if specID ~= false and PayloadContainsAlias(payloadText, aliasText) then
            if matchedSpecID ~= nil and matchedSpecID ~= specID then
                return nil
            end
            matchedSpecID = specID
        end
    end

    return type(matchedSpecID) == "number" and matchedSpecID or nil
end

PlannerPrivate.GetIdentityKey = function(value)
    return PlannerPrivate.NormalizeCompareText(value)
end


-- Schutz vor Endlosschleifen und zu vielen Iterationen
local MAX_IDENTITY_KEYS = 10

PlannerPrivate.GetIdentityKeys = function(value)
    local canCacheByValue = CanUsePlannerStringCacheKey(value)
    if canCacheByValue then
        local cachedIdentityKeys = PlannerPrivate.identityKeysByValue[value]
        if cachedIdentityKeys ~= nil then
            return cachedIdentityKeys
        end
    end

    local identityKeys = {}
    local seen = {}
    local count = 0

    local function AddCandidate(candidate)
        if count >= MAX_IDENTITY_KEYS then return end
        local identityKey = PlannerPrivate.GetIdentityKey(candidate)
        if identityKey ~= nil and not seen[identityKey] then
            seen[identityKey] = true
            identityKeys[#identityKeys + 1] = identityKey
            count = count + 1
        end
    end

    AddCandidate(value)

    if PlannerPrivate.IsUsablePlainString(value) and count < MAX_IDENTITY_KEYS then
        AddCandidate(PlannerPrivate.GetDisplayNameFromFullName(value))
    end

    if canCacheByValue then
        PlannerPrivate.identityKeysByValue[value] = identityKeys
    end

    return identityKeys
end

PlannerPrivate.GetDisplayNameFromFullName = function(fullName)
    local canCacheByValue = CanUsePlannerStringCacheKey(fullName)
    if canCacheByValue then
        local cachedDisplayName = PlannerPrivate.displayNameByFullName[fullName]
        if cachedDisplayName ~= nil then
            return cachedDisplayName
        end
    end

    if not PlannerPrivate.IsUsablePlainString(fullName) then
        return UNKNOWN or "Unknown"
    end

    if Ambiguate then
        local ok, shortName = pcall(Ambiguate, fullName, "short")
        if ok and PlannerPrivate.IsUsablePlainString(shortName) then
            if canCacheByValue then
                PlannerPrivate.displayNameByFullName[fullName] = shortName
            end
            return shortName
        end
    end

    local displayName = fullName:match("^[^-]+") or fullName
    if canCacheByValue then
        PlannerPrivate.displayNameByFullName[fullName] = displayName
    end
    return displayName
end

PlannerPrivate.AddUniqueCandidate = function(target, seen, value)
    if not PlannerPrivate.IsUsablePlainString(value) then
        return
    end

    local trimmed = value:match("^%s*(.-)%s*$")
    if trimmed == "" or seen[trimmed] then
        return
    end

    seen[trimmed] = true
    target[#target + 1] = trimmed
end

PlannerPrivate.NormalizeDestinationLevel = function(categoryKey, level)
    if categoryKey == "raids" then
        return PlannerPrivate.NormalizeRaidDifficultyKey(level)
    end

    if type(level) ~= "number" then
        return nil
    end

    local roundedLevel = math.floor(level + 0.5)
    if categoryKey == "delves" then
        return Clamp(roundedLevel, 1, 11)
    end

    if categoryKey == "s1" then
        return Clamp(roundedLevel, 0, 20)
    end

    return nil
end

PlannerPrivate.GetDestinationLevelLabel = function(categoryKey, level)
    local normalizedLevel = PlannerPrivate.NormalizeDestinationLevel(categoryKey, level)
    if normalizedLevel == nil then
        return nil
    end

    if categoryKey == "raids" then
        return PlannerPrivate.GetRaidDifficultyLabel(normalizedLevel)
    end

    if categoryKey == "delves" then
        return tostring(normalizedLevel)
    end

    return GetKeystoneLabel(normalizedLevel)
end

PlannerPrivate.RegisterDestinationAlias = function(cache, aliasText, categoryKey, destinationText, allowOverride)
    local normalizedAlias = PlannerPrivate.NormalizeCompareText(aliasText)
    if not normalizedAlias or not PlannerPrivate.IsUsablePlainString(destinationText) then
        return
    end

    local existingEntry = cache.byText[normalizedAlias]
    if existingEntry then
        if allowOverride == true then
            existingEntry.categoryKey = categoryKey
            existingEntry.destinationText = destinationText
        end
        return
    end

    local aliasEntry = {
        normalized = normalizedAlias,
        categoryKey = categoryKey,
        destinationText = destinationText,
    }

    cache.byText[normalizedAlias] = aliasEntry
    cache.ordered[#cache.ordered + 1] = aliasEntry
end

PlannerPrivate.BuildDestinationAliasCache = function()
    if PlannerPrivate.destinationAliasCache then
        return PlannerPrivate.destinationAliasCache
    end

    local cache = {
        byText = {},
        ordered = {},
    }

    for _, categoryInfo in ipairs(StreamerPlannerModule.DESTINATION_CATEGORIES) do
        for _, suggestionText in ipairs(GetDestinationSuggestions(categoryInfo.key)) do
            PlannerPrivate.RegisterDestinationAlias(cache, suggestionText, categoryInfo.key, suggestionText, categoryInfo.key == "raids")
        end
    end

    PlannerPrivate.RegisterDestinationAlias(cache, "Terrasse der Magister", "s1", L("STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE"))
    PlannerPrivate.RegisterDestinationAlias(cache, "Die Terrasse der Magister", "s1", L("STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE"))
    PlannerPrivate.RegisterDestinationAlias(cache, "Magisters' Terrace", "s1", L("STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE"))
    PlannerPrivate.RegisterDestinationAlias(cache, "Magisters Terrace", "s1", L("STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE"))
    PlannerPrivate.RegisterDestinationAlias(cache, "Voidspire", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "The Voidspire", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "Leerspitze", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "Dreamrift", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "The Dreamrift", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "Dream Rift", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "March on Quel'Danas", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "March on Quel Danas", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS"), true)
    PlannerPrivate.RegisterDestinationAlias(cache, "Marsch auf Quel Danas", "raids", L("STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS"), true)

    table.sort(cache.ordered, function(left, right)
        if #left.normalized ~= #right.normalized then
            return #left.normalized > #right.normalized
        end

        return left.destinationText < right.destinationText
    end)

    PlannerPrivate.destinationAliasCache = cache
    return PlannerPrivate.destinationAliasCache
end

PlannerPrivate.IsRaidDestinationText = function(destinationText)
    for _, raidSuggestion in ipairs(GetDestinationSuggestions("raids")) do
        if raidSuggestion == destinationText then
            return true
        end
    end

    return false
end

PlannerPrivate.ResolveDestinationFromCandidates = function(textCandidates)
    local cache = PlannerPrivate.BuildDestinationAliasCache()

    for _, candidateText in ipairs(textCandidates) do
        local normalizedCandidate = PlannerPrivate.NormalizeCompareText(candidateText)
        if normalizedCandidate then
            local directMatch = cache.byText[normalizedCandidate]
            if directMatch then
                return directMatch.categoryKey, directMatch.destinationText
            end

            for _, aliasEntry in ipairs(cache.ordered) do
                if normalizedCandidate:find(aliasEntry.normalized, 1, true) then
                    return aliasEntry.categoryKey, aliasEntry.destinationText
                end
            end
        end
    end

    return nil, nil
end

PlannerPrivate.GetActiveEntryInfoTable = function()
    if not C_LFGList then
        return nil
    end

    local hasActiveEntry = false

    if C_LFGList.HasActiveEntryInfo then
        hasActiveEntry = C_LFGList.HasActiveEntryInfo() == true
    elseif C_LFGList.GetActiveEntryInfo then
        hasActiveEntry = C_LFGList.GetActiveEntryInfo() ~= nil
    end

    if not hasActiveEntry then
        return nil
    end

    local activeEntryInfo = {
        hasActiveEntry = true,
    }

    if LFGListFrame and LFGListFrame.EntryCreation then
        local entryCreation = LFGListFrame.EntryCreation
        local selectedActivityID = tonumber(entryCreation.selectedActivityID or entryCreation.selectedActivity)
        if selectedActivityID then
            activeEntryInfo.activityID = selectedActivityID
        end
    end

    return activeEntryInfo
end

PlannerPrivate.GetActiveEntryActivityID = function(activeEntryInfo)
    if type(activeEntryInfo) ~= "table" then
        return nil
    end

    if type(activeEntryInfo.activityID) == "number" then
        return activeEntryInfo.activityID
    end

    if type(activeEntryInfo.activityIDs) == "table" then
        local firstActivityID = tonumber(activeEntryInfo.activityIDs[1])
        if firstActivityID then
            return firstActivityID
        end
    end

    return nil
end

PlannerPrivate.GetEntryCreationTextCandidates = function()
    local candidates = {}
    local seenCandidates = {}
    local activeEntryInfo = PlannerPrivate.GetActiveEntryInfoTable()
    if not activeEntryInfo then
        return candidates, nil, nil
    end

    local activityInfo = nil
    local activityID = PlannerPrivate.GetActiveEntryActivityID(activeEntryInfo)
    if activityID and C_LFGList then
        if C_LFGList.GetActivityInfoTable then
            activityInfo = C_LFGList.GetActivityInfoTable(activityID)
            if type(activityInfo) == "table" then
                PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, activityInfo.shortName)
                PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, activityInfo.fullName)
                PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, activityInfo["activityName"])
            end
        end

        if C_LFGList.GetActivityInfo then
            PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, C_LFGList.GetActivityInfo(activityID))
        end
    end

    if LFGListFrame and LFGListFrame.EntryCreation then
        if LFGListFrame.EntryCreation.Name and LFGListFrame.EntryCreation.Name.GetText then
            PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, LFGListFrame.EntryCreation.Name:GetText())
        end

        if LFGListFrame.EntryCreation.Description and LFGListFrame.EntryCreation.Description.GetText then
            PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, LFGListFrame.EntryCreation.Description:GetText())
        end
    end

    if LFGListFrame and LFGListFrame.ApplicationViewer then
        if LFGListFrame.ApplicationViewer.EntryName and LFGListFrame.ApplicationViewer.EntryName.GetText then
            PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, LFGListFrame.ApplicationViewer.EntryName:GetText())
        end

        if LFGListFrame.ApplicationViewer.DescriptionFrame then
            local descriptionFrame = LFGListFrame.ApplicationViewer.DescriptionFrame

            if descriptionFrame.Description and descriptionFrame.Description.GetText then
                PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, descriptionFrame.Description:GetText())
            end

            if descriptionFrame.Text and descriptionFrame.Text.GetText then
                PlannerPrivate.AddUniqueCandidate(candidates, seenCandidates, descriptionFrame.Text:GetText())
            end
        end
    end

    return candidates, activeEntryInfo, activityInfo
end

PlannerPrivate.ParseDestinationLevelFromText = function(textCandidates, categoryKey)
    if categoryKey == "raids" then
        return PlannerPrivate.ParseRaidDifficultyFromText(textCandidates)
    end

    local minLevel = categoryKey == "delves" and 1 or 0
    local maxLevel = categoryKey == "delves" and 11 or 20

    local function NormalizeParsedLevel(parsedLevel)
        if type(parsedLevel) ~= "number" then
            return nil
        end

        local roundedLevel = math.floor(parsedLevel + 0.5)
        if roundedLevel < minLevel or roundedLevel > maxLevel then
            return nil
        end

        return roundedLevel
    end

    for _, candidateText in ipairs(textCandidates) do
        local mythicLevel = type(candidateText) == "string" and candidateText:match("[Mm]%+%s*(%d+)") or nil
        if mythicLevel then
            local normalizedLevel = NormalizeParsedLevel(tonumber(mythicLevel))
            if normalizedLevel ~= nil then
                return normalizedLevel
            end
        end

        local plusLevel = type(candidateText) == "string" and candidateText:match("%+(%d+)") or nil
        if plusLevel then
            local normalizedLevel = NormalizeParsedLevel(tonumber(plusLevel))
            if normalizedLevel ~= nil then
                return normalizedLevel
            end
        end

        if categoryKey == "delves" then
            local delveLevel = type(candidateText) == "string" and (candidateText:match("[Tt]ier%s*(%d+)")
                or candidateText:match("[Tt](%d+)")
                or candidateText:match("(%d+)%s*$")) or nil
            if delveLevel then
                local normalizedLevel = NormalizeParsedLevel(tonumber(delveLevel))
                if normalizedLevel ~= nil then
                    return normalizedLevel
                end
            end
        end
    end

    return nil
end

PlannerPrivate.FindDestinationSuggestion = function(categoryKey, destinationText)
    local normalizedText = tostring(destinationText or "")
    for _, suggestion in ipairs(GetDestinationSuggestions(categoryKey)) do
        if suggestion == normalizedText then
            return suggestion
        end
    end

    return nil
end

PlannerPrivate.NormalizeSlotEntry = function(entry)
    if type(entry) == "table" then
        local inviteName = PlannerPrivate.IsUsablePlainString(entry.inviteName) and entry.inviteName
            or (PlannerPrivate.IsUsablePlainString(entry.name) and entry.name or nil)
        inviteName = PlannerPrivate.BuildCharacterFullName(inviteName, nil)

        return {
            name = tostring(entry.name or ""),
            classFile = PlannerPrivate.IsUsablePlainString(entry.classFile) and entry.classFile or nil,
            specID = type(entry.specID) == "number" and entry.specID or nil,
            roleKey = PlannerPrivate.NormalizePlannerRoleKey(entry.roleKey),
            inviteName = inviteName,
            sourceKey = PlannerPrivate.IsUsablePlainString(entry.sourceKey) and entry.sourceKey or nil,
        }
    end

    if type(entry) == "string" then
        return {
            name = entry,
            classFile = nil,
            specID = nil,
            roleKey = nil,
            inviteName = nil,
            sourceKey = nil,
        }
    end

    return {
        name = "",
        classFile = nil,
        specID = nil,
        roleKey = nil,
        inviteName = nil,
        sourceKey = nil,
    }
end

PlannerPrivate.NormalizeWhisperApplicantEntry = function(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local fullName = PlannerPrivate.IsUsablePlainString(entry.fullName) and PlannerPrivate.BuildCharacterFullName(entry.fullName, nil) or nil
    local inviteName = PlannerPrivate.IsUsablePlainString(entry.inviteName) and PlannerPrivate.BuildCharacterFullName(entry.inviteName, nil) or fullName
    local displayName = PlannerPrivate.IsUsablePlainString(entry.displayName) and entry.displayName
        or PlannerPrivate.GetDisplayNameFromFullName(fullName or inviteName)
    local createdAt = type(entry.createdAt) == "number" and entry.createdAt or GetCurrentTimestamp()
    local updatedAt = type(entry.updatedAt) == "number" and entry.updatedAt or createdAt
    local command = entry.command == "inv" and "inv" or "enter"
    local identitySource = fullName or inviteName or displayName
    local identityKey = PlannerPrivate.GetIdentityKey(identitySource)

    if not identityKey then
        return nil
    end

    return {
        fullName = fullName,
        displayName = displayName or "",
        inviteName = inviteName,
        classFile = PlannerPrivate.IsUsablePlainString(entry.classFile) and entry.classFile or nil,
        specID = type(entry.specID) == "number" and entry.specID or nil,
        roleKey = PlannerPrivate.NormalizePlannerRoleKey(entry.roleKey),
        sourceKey = PlannerPrivate.IsUsablePlainString(entry.sourceKey) and entry.sourceKey or ("whisper:" .. identityKey),
        command = command,
        createdAt = createdAt,
        updatedAt = updatedAt,
        lastInvitedAt = type(entry.lastInvitedAt) == "number" and entry.lastInvitedAt or nil,
    }
end

PlannerPrivate.NormalizeWhisperApplicantList = function(entries)
    local normalizedEntries = {}
    local seenIdentities = {}
    local cutoffTimestamp = GetCurrentTimestamp() - (7 * 24 * 60 * 60)

    if type(entries) == "table" then
        for _, entry in ipairs(entries) do
            local normalizedEntry = PlannerPrivate.NormalizeWhisperApplicantEntry(entry)
            if normalizedEntry and normalizedEntry.updatedAt >= cutoffTimestamp then
                local identityKey = PlannerPrivate.GetIdentityKey(normalizedEntry.fullName or normalizedEntry.inviteName or normalizedEntry.displayName)
                if identityKey and not seenIdentities[identityKey] then
                    seenIdentities[identityKey] = true
                    normalizedEntries[#normalizedEntries + 1] = normalizedEntry
                end
            end
        end
    end

    table.sort(normalizedEntries, function(left, right)
        if (left.updatedAt or 0) ~= (right.updatedAt or 0) then
            return (left.updatedAt or 0) > (right.updatedAt or 0)
        end

        return tostring(left.displayName or left.inviteName or "") < tostring(right.displayName or right.inviteName or "")
    end)

    while #normalizedEntries > 80 do
        table.remove(normalizedEntries)
    end

    return normalizedEntries
end

PlannerPrivate.ResolveWhisperCommand = function(messageText)
    if type(messageText) ~= "string" then
        return nil
    end

    local normalizedMessage = messageText:lower():match("^%s*(.-)%s*$") or ""
    if normalizedMessage:find("^!enter") then
        return "enter"
    end

    if normalizedMessage:find("^!inv") then
        return "inv"
    end

    return nil
end

PlannerPrivate.BuildCharacterFullName = function(characterName, realmName)
    if type(characterName) ~= "string" then
        return nil
    end

    if not PlannerPrivate.IsUsablePlainString(characterName) then
        return nil
    end

    local canCacheByValue = CanUsePlannerStringCacheKey(characterName)
    local cacheKey = nil
    if canCacheByValue and CanUsePlannerStringCacheKey(tostring(realmName or "")) then
        cacheKey = characterName .. "\031" .. tostring(realmName or "")
        local cachedFullName = PlannerPrivate.fullNameByCharacterAndRealm[cacheKey]
        if cachedFullName ~= nil then
            return cachedFullName or nil
        end
    end

    local function CollapseDuplicateRealmPart(realmText)
        if not PlannerPrivate.IsUsablePlainString(realmText) then
            return realmText
        end

        local collapsedRealmText = realmText
        local changed = true
        while changed do
            changed = false
            local searchStart = 1
            while true do
                local splitPos = collapsedRealmText:find("-", searchStart, true)
                if not splitPos then
                    break
                end

                local leftPart = collapsedRealmText:sub(1, splitPos - 1)
                local rightPart = collapsedRealmText:sub(splitPos + 1)
                if leftPart == rightPart then
                    collapsedRealmText = leftPart
                    changed = true
                    break
                end

                searchStart = splitPos + 1
            end
        end

        return collapsedRealmText
    end

    local trimmedName = characterName:match("^%s*(.-)%s*$") or characterName
    local existingCharacterName, existingRealmName = trimmedName:match("^([^-]+)%-(.+)$")
    local normalizedRealmName = PlannerPrivate.IsUsablePlainString(realmName) and (realmName:gsub("%s+", "")) or nil

    if existingCharacterName and existingRealmName then
        local collapsedRealmName = CollapseDuplicateRealmPart(existingRealmName)
        if normalizedRealmName and collapsedRealmName:gsub("%s+", "") == normalizedRealmName then
            local fullName = string.format("%s-%s", existingCharacterName, normalizedRealmName)
            if cacheKey ~= nil then
                PlannerPrivate.fullNameByCharacterAndRealm[cacheKey] = fullName
            end
            return fullName
        end

        local fullName = string.format("%s-%s", existingCharacterName, collapsedRealmName)
        if cacheKey ~= nil then
            PlannerPrivate.fullNameByCharacterAndRealm[cacheKey] = fullName
        end
        return fullName
    end

    if normalizedRealmName and normalizedRealmName ~= "" then
        local fullName = string.format("%s-%s", trimmedName, normalizedRealmName)
        if cacheKey ~= nil then
            PlannerPrivate.fullNameByCharacterAndRealm[cacheKey] = fullName
        end
        return fullName
    end

    if cacheKey ~= nil then
        PlannerPrivate.fullNameByCharacterAndRealm[cacheKey] = trimmedName
    end
    return trimmedName
end

PlannerPrivate.GetPlayerFullName = function()
    if UnitFullName then
        local playerName, realmName = UnitFullName("player")
        if PlannerPrivate.IsUsablePlainString(playerName) then
            return PlannerPrivate.BuildCharacterFullName(playerName, realmName)
        end
    end

    local unitFullName = PlannerPrivate.GetUnitFullName and PlannerPrivate.GetUnitFullName("player") or nil
    if PlannerPrivate.IsUsablePlainString(unitFullName) then
        return unitFullName
    end

    local shortName = UnitName and UnitName("player") or nil
    if PlannerPrivate.IsUsablePlainString(shortName) then
        return shortName
    end

    return nil
end

PlannerPrivate.FindPlayerGUIDInEventArgs = function(...)
    for argumentIndex = 1, select("#", ...) do
        local guidCandidate = select(argumentIndex, ...)
        if type(guidCandidate) == "string" and guidCandidate:find("^Player%-") then
            return guidCandidate
        end
    end

    return nil
end

PlannerPrivate.NormalizeClassFile = function(classValue)
    if not PlannerPrivate.IsUsablePlainString(classValue) then
        return nil
    end

    if StreamerPlannerModule.CLASS_ROLE_SUPPORT[classValue] then
        return classValue
    end

    for classFile, localizedName in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
        if classValue == localizedName then
            return classFile
        end
    end

    for classFile, localizedName in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
        if classValue == localizedName then
            return classFile
        end
    end

    return nil
end

PlannerPrivate.GetSupportedRoleInfo = function(classFile)
    local supportedRoles = classFile and StreamerPlannerModule.CLASS_ROLE_SUPPORT[classFile] or nil
    if type(supportedRoles) ~= "table" then
        return 0, nil
    end

    local supportedRoleCount = 0
    local singleRoleKey = nil
    for _, candidateRoleKey in ipairs({ "tank", "healer", "dps" }) do
        if supportedRoles[candidateRoleKey] then
            supportedRoleCount = supportedRoleCount + 1
            if supportedRoleCount == 1 then
                singleRoleKey = candidateRoleKey
            else
                singleRoleKey = nil
            end
        end
    end

    return supportedRoleCount, singleRoleKey
end

PlannerPrivate.GetSingleSupportedRoleKey = function(classFile)
    local supportedRoleCount, singleRoleKey = PlannerPrivate.GetSupportedRoleInfo(classFile)
    if supportedRoleCount == 1 then
        return singleRoleKey
    end

    return nil
end

PlannerPrivate.RefreshSelectionButton = function(button, selected)
    if not button then
        return
    end

    if button.Selected then
        button.Selected:SetShown(selected == true)
    end

    if button.Label then
        if selected == true then
            button.Label:SetTextColor(1, 0.92, 0.32, 1)
        else
            button.Label:SetTextColor(1, 0.88, 0.62, 1)
        end
    end
end

PlannerPrivate.IsPlayerName = function(name)
    local playerFullName = PlannerPrivate.GetPlayerFullName()
    local playerIdentityKey = PlannerPrivate.GetIdentityKey(playerFullName)
    local candidateIdentityKey = PlannerPrivate.GetIdentityKey(name)
    return playerIdentityKey ~= nil and playerIdentityKey == candidateIdentityKey
end

PlannerPrivate.SendPlannerAddonWhisper = function(targetName, payloadText)
    if not C_ChatInfo
        or type(C_ChatInfo.SendAddonMessage) ~= "function"
        or not PlannerPrivate.IsUsablePlainString(targetName)
        or not PlannerPrivate.IsUsablePlainString(payloadText) then
        return false
    end

    C_ChatInfo.SendAddonMessage(STREAMER_PLANNER_ADDON_PREFIX, payloadText, "WHISPER", targetName)
    return true
end

PlannerPrivate.RequestWhisperApplicantSpec = function(whisperEntry)
    if type(whisperEntry) ~= "table" then
        return false
    end

    if type(whisperEntry.specID) == "number" and whisperEntry.specID > 0 then
        return false
    end

    local targetName = whisperEntry.inviteName or whisperEntry.fullName or whisperEntry.displayName
    local identityKey = PlannerPrivate.GetIdentityKey(targetName)
    if identityKey == nil or PlannerPrivate.IsPlayerName(targetName) then
        return false
    end

    local now = GetCurrentTimestamp()
    if type(PlannerPrivate.specRequestCooldownByName[identityKey]) == "number"
        and (now - PlannerPrivate.specRequestCooldownByName[identityKey]) < WHISPER_SPEC_REQUEST_COOLDOWN_SECONDS then
        return false
    end

    if PlannerPrivate.SendPlannerAddonWhisper(targetName, STREAMER_PLANNER_ADDON_SPEC_QUERY) then
        PlannerPrivate.specRequestCooldownByName[identityKey] = now
        return true
    end

    return false
end

PlannerPrivate.HandlePlannerAddonMessage = function(prefix, message, distribution, senderName)
    if prefix ~= STREAMER_PLANNER_ADDON_PREFIX or not PlannerPrivate.IsUsablePlainString(message) then
        return false
    end

    if PlannerPrivate.IsPlayerName(senderName) then
        return false
    end

    local messageType, firstValue, secondValue = strsplit("\t", message)
    if messageType == STREAMER_PLANNER_ADDON_SPEC_QUERY then
        if distribution == "WHISPER" and PlannerPrivate.IsUsablePlainString(senderName) then
            local playerClassFile = nil
            if UnitClass then
                local _, resolvedClassFile = UnitClass("player")
                playerClassFile = resolvedClassFile
            end
            local playerSpecID = PlannerPrivate.GetPlayerSpecID()
            PlannerPrivate.SendPlannerAddonWhisper(
                senderName,
                table.concat({
                    STREAMER_PLANNER_ADDON_SPEC_REPLY,
                    tostring(playerSpecID or 0),
                    playerClassFile or "",
                }, "\t")
            )
        end

        return false
    end

    if messageType ~= STREAMER_PLANNER_ADDON_SPEC_REPLY then
        return false
    end

    local specID = tonumber(firstValue)
    if type(specID) ~= "number" or specID <= 0 then
        specID = nil
    end

    local classFile = PlannerPrivate.IsUsablePlainString(secondValue) and secondValue or nil
    return PlannerPrivate.StoreKnownCharacterInfo(senderName, nil, classFile, specID)
end

PlannerPrivate.ResolveBattleNetWhisperAuthorInfo = function(senderBnetIDAccount)
    if type(senderBnetIDAccount) ~= "number" then
        return nil, nil
    end

    local battleNetAPI = rawget(_G, "C_BattleNet")
    if type(battleNetAPI) ~= "table" or type(battleNetAPI.GetFriendAccountInfo) ~= "function" then
        return nil, nil
    end

    local getNumFriends = rawget(_G, "BNGetNumFriends")
    if type(getNumFriends) ~= "function" then
        return nil, nil
    end

    local friendCount = tonumber((getNumFriends())) or 0
    local wowProjectID = rawget(_G, "WOW_PROJECT_MAINLINE")
    local wowClientProgram = rawget(_G, "BNET_CLIENT_WOW")

    local function ResolveGameAccountInfo(gameAccountInfo)
        if type(gameAccountInfo) ~= "table" then
            return nil, nil
        end

        local isRightClient = wowClientProgram == nil or gameAccountInfo.clientProgram == wowClientProgram
        local isRightProject = wowProjectID == nil or gameAccountInfo.wowProjectID == wowProjectID
        if not isRightClient or not isRightProject or gameAccountInfo.isInCurrentRegion == false then
            return nil, nil
        end

        return PlannerPrivate.BuildCharacterFullName(gameAccountInfo.characterName, gameAccountInfo.realmName),
            PlannerPrivate.NormalizeClassFile(gameAccountInfo.className)
    end

    for friendIndex = 1, (friendCount or 0) do
        local accountInfo = battleNetAPI.GetFriendAccountInfo(friendIndex)
        if type(accountInfo) == "table" and accountInfo.bnetAccountID == senderBnetIDAccount then
            local resolvedName, resolvedClassFile = ResolveGameAccountInfo(accountInfo.gameAccountInfo)
            if resolvedName then
                return resolvedName, resolvedClassFile
            end

            if type(battleNetAPI.GetFriendNumGameAccounts) == "function" and type(battleNetAPI.GetFriendGameAccountInfo) == "function" then
                for accountIndex = 1, (battleNetAPI.GetFriendNumGameAccounts(friendIndex) or 0) do
                    resolvedName, resolvedClassFile = ResolveGameAccountInfo(battleNetAPI.GetFriendGameAccountInfo(friendIndex, accountIndex))
                    if resolvedName then
                        return resolvedName, resolvedClassFile
                    end
                end
            end
        end
    end

    return nil, nil
end

PlannerPrivate.ResolveWhisperAuthorName = function(authorName, playerGUID, senderBnetIDAccount)
    local resolvedName = PlannerPrivate.IsUsablePlainString(authorName) and authorName or nil
    local resolvedClassFile = nil

    local battleNetName, battleNetClassFile = PlannerPrivate.ResolveBattleNetWhisperAuthorInfo(senderBnetIDAccount)
    if battleNetName then
        resolvedName = battleNetName
    end
    if battleNetClassFile then
        resolvedClassFile = battleNetClassFile
    end

    local getPlayerInfoByGUID = rawget(_G, "GetPlayerInfoByGUID")
    if type(getPlayerInfoByGUID) == "function" and PlannerPrivate.IsUsablePlainString(playerGUID) then
        local _, classFile, _, _, _, playerName, realmName = getPlayerInfoByGUID(playerGUID)
        resolvedClassFile = resolvedClassFile or PlannerPrivate.NormalizeClassFile(classFile)
        if resolvedName == nil and PlannerPrivate.IsUsablePlainString(playerName) then
            resolvedName = playerName
        end

        if PlannerPrivate.IsUsablePlainString(playerName) and PlannerPrivate.IsUsablePlainString(realmName) and realmName ~= "" then
            return PlannerPrivate.BuildCharacterFullName(playerName, realmName), resolvedClassFile
        end

        if resolvedName and PlannerPrivate.IsUsablePlainString(realmName) and realmName ~= "" then
            return PlannerPrivate.BuildCharacterFullName(resolvedName, realmName), resolvedClassFile
        end

        if resolvedName then
            return resolvedName, resolvedClassFile
        end

        if PlannerPrivate.IsUsablePlainString(playerName) then
            return playerName, resolvedClassFile
        end

        if classFile then
            return resolvedName, resolvedClassFile
        end
    end

    return resolvedName, resolvedClassFile
end

PlannerPrivate.FindWhisperApplicantByName = function(name)
    local settings = GetStreamerPlannerSettings()
    local identityKeys = PlannerPrivate.GetIdentityKeys(name)
    if #identityKeys == 0 then
        return nil, nil
    end

    local identityLookup = {}
    for _, identityKey in ipairs(identityKeys) do
        identityLookup[identityKey] = true
    end

    for index, entry in ipairs(settings.whisperApplicants or {}) do
        for _, entryIdentityKey in ipairs(PlannerPrivate.GetIdentityKeys(entry.fullName or entry.inviteName or entry.displayName)) do
            if identityLookup[entryIdentityKey] then
                return entry, index
            end
        end
    end

    return nil, nil
end

PlannerPrivate.IsWhisperSourceKey = function(sourceKey)
    return type(sourceKey) == "string" and sourceKey:sub(1, 8) == "whisper:"
end

PlannerPrivate.IsSelfSourceKey = function(sourceKey)
    return type(sourceKey) == "string" and sourceKey:sub(1, 5) == "self:"
end

PlannerPrivate.IsSelfSlotEntry = function(entry)
    if type(entry) ~= "table" then
        return false
    end

    if PlannerPrivate.IsSelfSourceKey(entry.sourceKey) then
        return true
    end

    local playerFullName = PlannerPrivate.GetPlayerFullName()
    local playerDisplayName = PlannerPrivate.GetDisplayNameFromFullName(playerFullName)
    local playerIdentityKey = PlannerPrivate.GetIdentityKey(playerFullName)
    local playerDisplayIdentityKey = PlannerPrivate.GetIdentityKey(playerDisplayName)

    -- Prüfe alle möglichen Namensfelder im Slot-Eintrag
    local entryNames = {
        entry.inviteName,
        entry.name,
        entry.displayName,
    }
    for _, entryName in ipairs(entryNames) do
        local entryIdentityKey = PlannerPrivate.GetIdentityKey(entryName)
        if entryIdentityKey ~= nil then
            if (playerIdentityKey ~= nil and playerIdentityKey == entryIdentityKey)
                or (playerDisplayIdentityKey ~= nil and playerDisplayIdentityKey == entryIdentityKey)
            then
                return true
            end
        end
    end

    return false
end

PlannerPrivate.GetAssignedSelfDungeonSlotKey = function(settings)
    local resolvedSettings = settings or GetStreamerPlannerSettings()
    local fallbackSlotKey = nil

    for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
        local currentEntry = PlannerPrivate.NormalizeSlotEntry(resolvedSettings.slots.dungeon[slotInfo.key])
        if PlannerPrivate.IsSelfSlotEntry(currentEntry) then
            if PlannerPrivate.IsSelfSourceKey(currentEntry.sourceKey) then
                return slotInfo.key
            end

            fallbackSlotKey = fallbackSlotKey or slotInfo.key
        end
    end

    return fallbackSlotKey
end

PlannerPrivate.ShouldOpenSelfRoleEditor = function(layout, index, slotEntry)
    if layout ~= "dungeon" then
        return false
    end

    local currentEntry = type(slotEntry) == "table" and slotEntry or nil
    if PlannerPrivate.IsSelfSlotEntry(currentEntry) then
        return true
    end

    local slotInfo = GetDungeonSlotInfo and GetDungeonSlotInfo(index) or nil
    if not slotInfo or not slotInfo.key then
        return false
    end

    local selfSlotKey = PlannerPrivate.GetAssignedSelfDungeonSlotKey()
    return selfSlotKey ~= nil and selfSlotKey == slotInfo.key
end

PlannerPrivate.MarkWhisperApplicantInvited = function(name)
    local settings = GetStreamerPlannerSettings()
    local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(name)
    if not whisperEntry then
        return
    end

    whisperEntry.lastInvitedAt = GetCurrentTimestamp()
    whisperEntry.updatedAt = whisperEntry.lastInvitedAt
    settings.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(settings.whisperApplicants)
end

PlannerPrivate.RemoveWhisperApplicantByName = function(name, skipSync)
    local settings = GetStreamerPlannerSettings()
    local _, whisperIndex = PlannerPrivate.FindWhisperApplicantByName(name)
    if type(whisperIndex) ~= "number" then
        return false
    end

    table.remove(settings.whisperApplicants, whisperIndex)
    settings.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(settings.whisperApplicants)

    if skipSync == true then
        return true
    end

    PlannerPrivate.periodicSyncElapsed = 0
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
    return true
end

PlannerPrivate.ClearWhisperManagedSlots = function(settings)
    if type(settings) ~= "table" or type(settings.slots) ~= "table" then
        return
    end

    if type(settings.slots.dungeon) == "table" and type(StreamerPlannerModule.DUNGEON_LAYOUT) == "table" then
        for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
            local currentEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.dungeon[slotInfo.key])
            if PlannerPrivate.IsWhisperSourceKey(currentEntry.sourceKey) then
                settings.slots.dungeon[slotInfo.key] = PlannerPrivate.NormalizeSlotEntry(nil)
            end
        end
    end

    if type(settings.slots.raid) == "table" then
        for index = 1, RAID_SLOT_COUNT do
            local currentEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.raid[index])
            if PlannerPrivate.IsWhisperSourceKey(currentEntry.sourceKey) then
                settings.slots.raid[index] = PlannerPrivate.NormalizeSlotEntry(nil)
            end
        end
    end
end

PlannerPrivate.UpsertWhisperApplicant = function(authorName, playerGUID, command, senderBnetIDAccount, messageText)
    local settings = GetStreamerPlannerSettings()
    local resolvedCommand = command == "inv" and "inv" or "enter"
    local fullName, resolvedAuthorClassFile = PlannerPrivate.ResolveWhisperAuthorName(authorName, playerGUID, senderBnetIDAccount)
    local identityKey = PlannerPrivate.GetIdentityKey(fullName)

    if not identityKey then
        return nil
    end

    local existingEntry, existingIndex = PlannerPrivate.FindWhisperApplicantByName(fullName)
    local applicantData = PlannerPrivate.FindApplicantByName(fullName)
    local displayName = PlannerPrivate.GetDisplayNameFromFullName(fullName) or fullName
    local classFile = PlannerPrivate.NormalizeClassFile(existingEntry and existingEntry.classFile or nil)
    if classFile == nil and resolvedAuthorClassFile then
        classFile = PlannerPrivate.NormalizeClassFile(resolvedAuthorClassFile)
    end
    if classFile == nil and applicantData and applicantData.classFile then
        classFile = PlannerPrivate.NormalizeClassFile(applicantData.classFile)
    end
    local getPlayerInfoByGUID = rawget(_G, "GetPlayerInfoByGUID")
    if classFile == nil and type(getPlayerInfoByGUID) == "function" and PlannerPrivate.IsUsablePlainString(playerGUID) then
        local _, guidClassFile = getPlayerInfoByGUID(playerGUID)
        guidClassFile = PlannerPrivate.NormalizeClassFile(guidClassFile)
        if PlannerPrivate.IsUsablePlainString(guidClassFile) then
            classFile = guidClassFile
        end
    end

    local whisperedSpecID = PlannerPrivate.ResolveWhisperSpecHint(messageText, classFile)
    local whisperedRoleKey = PlannerPrivate.ResolveWhisperRoleHint(messageText)
    local specID = whisperedSpecID
        or (existingEntry and existingEntry.specID)
        or (applicantData and applicantData.specID)
        or PlannerPrivate.GetKnownSpecID(fullName, playerGUID)
        or nil
    local roleKey = whisperedRoleKey
        or (existingEntry and existingEntry.roleKey)
        or (applicantData and PlannerPrivate.GetApplicantRoleKey(applicantData))
        or nil
    if roleKey == nil and PlannerPrivate.IsUsablePlainString(classFile) then
        roleKey = PlannerPrivate.GetSingleSupportedRoleKey(classFile)
    end

    local normalizedEntry = PlannerPrivate.NormalizeWhisperApplicantEntry({
        fullName = fullName,
        displayName = displayName,
        inviteName = fullName,
        classFile = classFile,
        specID = specID,
        roleKey = roleKey,
        sourceKey = "whisper:" .. identityKey,
        command = resolvedCommand,
        createdAt = existingEntry and existingEntry.createdAt or GetCurrentTimestamp(),
        updatedAt = GetCurrentTimestamp(),
        lastInvitedAt = existingEntry and existingEntry.lastInvitedAt or nil,
    })

    if not normalizedEntry then
        return nil
    end

    if existingIndex then
        settings.whisperApplicants[existingIndex] = normalizedEntry
    else
        settings.whisperApplicants[#settings.whisperApplicants + 1] = normalizedEntry
    end

    settings.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(settings.whisperApplicants)
    return normalizedEntry
end

local function BuildClassOptions()
    if PlannerPrivate.classOptionsCache and PlannerPrivate.classInfoByFileCache then
        return PlannerPrivate.classOptionsCache, PlannerPrivate.classInfoByFileCache
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

    PlannerPrivate.classOptionsCache = options
    PlannerPrivate.classInfoByFileCache = infoByFile
    return PlannerPrivate.classOptionsCache, PlannerPrivate.classInfoByFileCache
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
    if type(infoByFile) ~= "table" then
        return classFile
    end

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

    local supportedRoles = StreamerPlannerModule.CLASS_ROLE_SUPPORT[classFile]
    return supportedRoles ~= nil and supportedRoles[roleRequirement] == true
end

local function IsSpecAllowedForRole(specID, roleRequirement)
    if type(specID) ~= "number" or not roleRequirement then
        return true
    end

    return StreamerPlannerModule.SPEC_ROLE_SUPPORT[specID] == roleRequirement
end

local function BuildSpecOptions(classFile, roleRequirement)
    local cacheKey = string.format("%s|%s", classFile or "__none", roleRequirement or "any")
    if PlannerPrivate.specOptionsCache[cacheKey] then
        return PlannerPrivate.specOptionsCache[cacheKey]
    end

    local options = {
        {
            id = nil,
            name = L("STREAMER_PLANNER_SPEC_NONE"),
            icon = nil,
        },
    }

    for _, specID in ipairs(StreamerPlannerModule.SPEC_DATA_BY_CLASS[classFile] or {}) do
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

    PlannerPrivate.specOptionsCache[cacheKey] = options
    return options
end

PlannerPrivate.GetSpecName = function(classFile, specID)
    if type(specID) ~= "number" then
        return nil
    end

    if GetSpecializationInfoByID then
        local _, resolvedSpecName = GetSpecializationInfoByID(specID)
        if PlannerPrivate.IsUsablePlainString(resolvedSpecName) then
            return resolvedSpecName
        end
    end

    if not classFile then
        return nil
    end

    for _, specInfo in ipairs(BuildSpecOptions(classFile, nil)) do
        if specInfo.id == specID then
            return specInfo.name
        end
    end

    return nil
end

PlannerPrivate.IsSpecForClass = function(classFile, specID)
    if not PlannerPrivate.IsUsablePlainString(classFile) or type(specID) ~= "number" then
        return false
    end

    for _, candidateSpecID in ipairs(StreamerPlannerModule.SPEC_DATA_BY_CLASS[classFile] or {}) do
        if candidateSpecID == specID then
            return true
        end
    end

    return false
end

PlannerPrivate.GetEntryAssignedRole = function(entry)
    if type(entry) ~= "table" then
        return nil
    end

    if entry.roleKey then
        return PlannerPrivate.NormalizePlannerRoleKey(entry.roleKey)
    end

    if type(entry.specID) == "number" then
        return PlannerPrivate.NormalizePlannerRoleKey(StreamerPlannerModule.SPEC_ROLE_SUPPORT[entry.specID])
    end

    local supportedRoles = entry.classFile and StreamerPlannerModule.CLASS_ROLE_SUPPORT[entry.classFile] or nil
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
            OverlayTimer.Value:SetTextColor(0.95, 0.91, 0.85, 1)
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
    local needsWhisperSessionReset = PlannerPrivate.whisperSessionInitialized ~= true

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

    if type(db.destinationCategory) ~= "string" or not StreamerPlannerModule.DESTINATION_OPTIONS[db.destinationCategory] then
        db.destinationCategory = StreamerPlannerModule.DESTINATION_CATEGORIES[1].key
    end

    db.destinationKeystoneLevel = PlannerPrivate.NormalizeDestinationLevel(db.destinationCategory, db.destinationKeystoneLevel)

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

    db.whisperCommandAutoInvite = db.whisperCommandAutoInvite == true
    db.selfRoleOverride = PlannerPrivate.NormalizePlannerRoleKey(db.selfRoleOverride)

    if type(db.whisperApplicants) ~= "table" then
        db.whisperApplicants = {}
    end

    if needsWhisperSessionReset then
        db.whisperApplicants = {}
    end

    db.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(db.whisperApplicants)

    if type(db.slots.dungeon) ~= "table" then
        db.slots.dungeon = {}
    end

    for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
        db.slots.dungeon[slotInfo.key] = PlannerPrivate.NormalizeSlotEntry(db.slots.dungeon[slotInfo.key])
    end

    if type(db.slots.raid) ~= "table" then
        db.slots.raid = {}
    end

    for index = 1, RAID_SLOT_COUNT do
        db.slots.raid[index] = PlannerPrivate.NormalizeSlotEntry(db.slots.raid[index])
    end

    if needsWhisperSessionReset then
        PlannerPrivate.ClearWhisperManagedSlots(db)
        PlannerPrivate.whisperSessionInitialized = true
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
    local destinationLevelLabel = PlannerPrivate.GetDestinationLevelLabel(settings.destinationCategory, settings.destinationKeystoneLevel)

    if destinationText ~= "" and destinationLevelLabel then
        return string.format("%s %s", destinationText, destinationLevelLabel)
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
    settings.destinationKeystoneLevel = PlannerPrivate.NormalizeDestinationLevel(settings.destinationCategory, level)
end

local function SetDestinationCategory(categoryKey)
    local settings = GetStreamerPlannerSettings()
    settings.destinationCategory = StreamerPlannerModule.DESTINATION_OPTIONS[categoryKey] and categoryKey or StreamerPlannerModule.DESTINATION_CATEGORIES[1].key
    settings.destinationKeystoneLevel = PlannerPrivate.NormalizeDestinationLevel(settings.destinationCategory, settings.destinationKeystoneLevel)
end

local function SetCurrentMode(mode)
    local settings = GetStreamerPlannerSettings()
    settings.mode = mode == "raid" and "raid" or "dungeon"

    if settings.mode == "raid" then
        if settings.destinationCategory == "s1" or settings.destinationCategory == "delves" then
            settings.destinationCategory = "raids"
        end
    elseif settings.destinationCategory == "raids" then
        settings.destinationCategory = StreamerPlannerModule.DESTINATION_CATEGORIES[1].key
    end
end

GetDungeonSlotInfo = function(index)
    return StreamerPlannerModule.DUNGEON_LAYOUT[index]
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

    return PlannerPrivate.NormalizeSlotEntry(entry).name
end

local function GetSlotEntry(layout, index, settings)
    local resolvedSettings = settings or GetStreamerPlannerSettings()

    if layout == "raid" then
        return PlannerPrivate.NormalizeSlotEntry(resolvedSettings.slots.raid[index])
    end

    local slotInfo = GetDungeonSlotInfo(index)
    if not slotInfo then
        return PlannerPrivate.NormalizeSlotEntry(nil)
    end

    return PlannerPrivate.NormalizeSlotEntry(resolvedSettings.slots.dungeon[slotInfo.key])
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
            local role = PlannerPrivate.GetEntryAssignedRole(entry)
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
    local normalizedEntry = PlannerPrivate.NormalizeSlotEntry(entry)

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
            settings.slots.raid[index] = PlannerPrivate.NormalizeSlotEntry(nil)
        end
        return
    end

    for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
        settings.slots.dungeon[slotInfo.key] = PlannerPrivate.NormalizeSlotEntry(nil)
    end
end

local function ClearAllLayouts()
    ClearLayout("dungeon")
    ClearLayout("raid")
end

PlannerPrivate.IsVisibleApplicantStatus = function(status)
    if status == "failed" or status == "cancelled" or status == "timedout" then
        return false
    end

    if status == "declined" or status == "declined_full" or status == "declined_delisted" or status == "invitedeclined" then
        return false
    end

    return true
end

PlannerPrivate.CanInviteApplicantStatus = function(status)
    return status == "applied"
end

PlannerPrivate.GetApplicantStatusLabel = function(status)
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

PlannerPrivate.GetApplicantRoleKey = function(memberData)
    if type(memberData) ~= "table" then
        return nil
    end

    local assignedRole = PlannerPrivate.NormalizePlannerRoleKey(memberData.assignedRole)
    if assignedRole then
        return assignedRole
    end

    if type(memberData.specID) == "number" then
        local specRole = PlannerPrivate.GetRoleKeyFromSpecID(memberData.specID)
        if specRole then
            return specRole
        end
    end

    local resolvedRole = nil
    if memberData.canTank then
        resolvedRole = resolvedRole and nil or "tank"
    end
    if memberData.canHealer then
        resolvedRole = resolvedRole and nil or "healer"
    end
    if memberData.canDamage then
        resolvedRole = resolvedRole and nil or "dps"
    end

    return resolvedRole
end

PlannerPrivate.GetApplicantPanelRoleOrder = function(roleKey)
    local normalizedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(roleKey)
    if normalizedRoleKey == "tank" then
        return 1
    end

    if normalizedRoleKey == "healer" then
        return 2
    end

    if normalizedRoleKey == "dps" then
        return 3
    end

    return 4
end

PlannerPrivate.GetApplicantSnapshot = function()
    local snapshot = {}

    if not C_LFGList or not C_LFGList.GetApplicants or not C_LFGList.GetApplicantInfo or not C_LFGList.GetApplicantMemberInfo then
        return snapshot
    end

    local orderedApplicants = {}
    for applicantOrderIndex, applicantID in ipairs(C_LFGList.GetApplicants() or {}) do
        local applicantInfo = C_LFGList.GetApplicantInfo(applicantID)
        if type(applicantInfo) == "table" then
            orderedApplicants[#orderedApplicants + 1] = {
                applicantID = applicantID,
                -- Blizzard can expose `displayOrderID` as a protected secret value.
                -- We only need a stable local order for planner sorting, so we keep the
                -- order returned by `GetApplicants()` instead of carrying the protected value.
                displayOrderID = applicantOrderIndex,
                applicationStatus = applicantInfo.applicationStatus,
                numMembers = tonumber(applicantInfo.numMembers) or 0,
            }
        end
    end

    for _, applicant in ipairs(orderedApplicants) do
        if PlannerPrivate.IsVisibleApplicantStatus(applicant.applicationStatus) then
            local applicantEntry = {
                applicantID = applicant.applicantID,
                applicationStatus = applicant.applicationStatus,
                displayOrderID = applicant.displayOrderID,
                memberCount = math.max(0, applicant.numMembers or 0),
                members = {},
            }

            for memberIndex = 1, applicantEntry.memberCount do
                local fullName, classFile, localizedClass, level, itemLevel, honorLevel, canTank, canHealer, canDamage, assignedRole, relationship, dungeonScore, pvpItemLevel, factionGroup, raceID, specID, isLeaver = C_LFGList.GetApplicantMemberInfo(applicant.applicantID, memberIndex)
                local displayName = PlannerPrivate.GetDisplayNameFromFullName(fullName) or tostring(fullName or "")

                applicantEntry.members[#applicantEntry.members + 1] = {
                    applicantID = applicant.applicantID,
                    memberIndex = memberIndex,
                    applicationStatus = applicant.applicationStatus,
                    fullName = fullName,
                    displayName = displayName,
                    classFile = classFile,
                    localizedClass = localizedClass,
                    level = level,
                    itemLevel = itemLevel,
                    dungeonScore = dungeonScore,
                    assignedRole = assignedRole,
                    specID = type(specID) == "number" and specID > 0 and specID or nil,
                    canTank = canTank == true,
                    canHealer = canHealer == true,
                    canDamage = canDamage == true,
                    isPrimary = memberIndex == 1,
                    memberCount = applicantEntry.memberCount,
                    isLeaver = isLeaver == true,
                }
            end

            snapshot[#snapshot + 1] = applicantEntry
        end
    end

    return snapshot
end

PlannerPrivate.RebuildApplicantIndex = function(snapshot)
    local applicantByName = {}

    for _, applicantEntry in ipairs(snapshot or {}) do
        for _, memberData in ipairs(applicantEntry.members or {}) do
            local fullNameKey = PlannerPrivate.GetIdentityKey(memberData.fullName)
            if fullNameKey and applicantByName[fullNameKey] == nil then
                applicantByName[fullNameKey] = memberData
            end

            local displayNameKey = PlannerPrivate.GetIdentityKey(memberData.displayName)
            if displayNameKey and applicantByName[displayNameKey] == nil then
                applicantByName[displayNameKey] = memberData
            end
        end
    end

    PlannerPrivate.applicantByName = applicantByName
end

PlannerPrivate.RefreshApplicantSnapshot = function()
    local snapshot = PlannerPrivate.GetApplicantSnapshot()
    PlannerPrivate.applicantSnapshot = snapshot
    PlannerPrivate.RebuildApplicantIndex(snapshot)
    return snapshot
end

PlannerPrivate.FindApplicantByName = function(name)
    local identityKey = PlannerPrivate.GetIdentityKey(name)
    if not identityKey then
        return nil
    end

    return PlannerPrivate.applicantByName[identityKey]
end

PlannerPrivate.IsAutoManagedSourceKey = function(sourceKey)
    return type(sourceKey) == "string"
        and (sourceKey:sub(1, 5) == "self:"
            or sourceKey:sub(1, 6) == "group:"
            or sourceKey:sub(1, 8) == "whisper:"
            or sourceKey:sub(1, 10) == "applicant:")
end

PlannerPrivate.IsAutoManagedEntry = function(entry)
    return type(entry) == "table" and PlannerPrivate.IsAutoManagedSourceKey(entry.sourceKey)
end

PlannerPrivate.GetPlayerSpecID = function()
    if not GetSpecialization or not GetSpecializationInfo then
        return nil
    end

    local currentSpecIndex = GetSpecialization()
    if type(currentSpecIndex) ~= "number" then
        return nil
    end

    local specID = select(1, GetSpecializationInfo(currentSpecIndex))
    return type(specID) == "number" and specID > 0 and specID or nil
end

PlannerPrivate.GetUnitFullName = function(unit)
    if not unit or not UnitExists or not UnitExists(unit) then
        return nil
    end

    local fullName = GetUnitName and GetUnitName(unit, true) or nil
    if PlannerPrivate.IsUsablePlainString(fullName) then
        return fullName
    end

    local shortName = GetUnitName and GetUnitName(unit, false) or nil
    return PlannerPrivate.IsUsablePlainString(shortName) and shortName or nil
end

PlannerPrivate.GetUnitParticipant = function(unit)
    if not unit or not UnitExists or not UnitExists(unit) then
        return nil
    end

    local fullName = PlannerPrivate.GetUnitFullName(unit)
    if not fullName then
        return nil
    end

    local displayName = PlannerPrivate.GetDisplayNameFromFullName(fullName) or fullName
    local _, classFile = UnitClass(unit)
    local playerGUID = UnitGUID and UnitGUID(unit) or nil
    local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(fullName)
    local specID = nil
    if unit == "player" then
        specID = PlannerPrivate.GetPlayerSpecID()
    elseif GetInspectSpecialization then
        local inspectSpecID = GetInspectSpecialization(unit)
        if type(inspectSpecID) == "number" and inspectSpecID > 0 then
            specID = inspectSpecID
        end
    end

    if specID == nil then
        specID = PlannerPrivate.GetKnownSpecID(fullName, playerGUID)
    end

    if specID == nil and type(whisperEntry) == "table" then
        specID = whisperEntry.specID
    end

    local applicantData = PlannerPrivate.FindApplicantByName(fullName)
    if specID == nil and type(applicantData) == "table" then
        specID = applicantData.specID
    end

    local roleKey = nil
    if unit == "player" then
        roleKey = PlannerPrivate.NormalizePlannerRoleKey(GetStreamerPlannerSettings().selfRoleOverride)
    end

    if roleKey == nil and type(whisperEntry) == "table" then
        roleKey = PlannerPrivate.NormalizePlannerRoleKey(whisperEntry.roleKey)
    end

    if roleKey == nil then
        roleKey = PlannerPrivate.NormalizePlannerRoleKey(UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or nil)
    end

    if roleKey == nil and type(applicantData) == "table" then
        roleKey = PlannerPrivate.GetApplicantRoleKey(applicantData)
    end

    if roleKey == nil and specID ~= nil then
        roleKey = PlannerPrivate.GetRoleKeyFromSpecID(specID)
    end

    if roleKey == nil then
        roleKey = PlannerPrivate.GetEntryAssignedRole({
            classFile = classFile,
            specID = specID,
        })
    end

    if unit ~= "player" then
        if specID ~= nil then
            PlannerPrivate.StoreKnownCharacterInfo(fullName, playerGUID, classFile, specID)
        elseif PlannerPrivate.ShouldInspectUnitParticipant(classFile, specID, roleKey) then
            PlannerPrivate.QueueInspectForUnit(unit, fullName, classFile)
        end
    end

    return {
        name = displayName,
        fullName = fullName,
        inviteName = fullName,
        classFile = classFile,
        specID = specID,
        roleKey = roleKey,
        sourceKey = (unit == "player" and "self:" or "group:") .. (PlannerPrivate.GetIdentityKey(fullName) or tostring(fullName)),
    }
end

PlannerPrivate.AddParticipant = function(target, seen, blocked, participant)
    if type(participant) ~= "table" then
        return
    end

    local identityLookup = {}
    for _, candidate in ipairs({
        participant.fullName,
        participant.inviteName,
        participant.name,
    }) do
        for _, identityKey in ipairs(PlannerPrivate.GetIdentityKeys(candidate)) do
            identityLookup[identityKey] = true
        end
    end

    for identityKey in pairs(identityLookup) do
        if blocked[identityKey] or seen[identityKey] then
            return
        end
    end

    for identityKey in pairs(identityLookup) do
        seen[identityKey] = true
    end

    target[#target + 1] = participant
end

PlannerPrivate.GetApplicantParticipants = function(blocked, seen)
    local participants = {}

    for _, applicantEntry in ipairs(PlannerPrivate.applicantSnapshot or {}) do
        for _, memberData in ipairs(applicantEntry.members or {}) do
            local applicantParticipant = {
                name = memberData.displayName or memberData.fullName or "",
                fullName = memberData.fullName,
                inviteName = memberData.fullName,
                classFile = memberData.classFile,
                specID = memberData.specID,
                roleKey = PlannerPrivate.GetApplicantRoleKey(memberData),
                applicantID = memberData.applicantID,
                memberIndex = memberData.memberIndex,
                applicantStatus = memberData.applicationStatus,
                displayOrderID = applicantEntry.displayOrderID or applicantEntry.applicantID or 0,
                sourcePriority = memberData.applicationStatus == "inviteaccepted" and 1 or (memberData.applicationStatus == "invited" and 2 or 3),
                sourceKey = string.format("applicant:%s:%s", tostring(memberData.applicantID or ""), tostring(memberData.memberIndex or "")),
            }

            PlannerPrivate.AddParticipant(participants, seen, blocked, applicantParticipant)
        end
    end

    table.sort(participants, function(left, right)
        if left.sourcePriority ~= right.sourcePriority then
            return left.sourcePriority < right.sourcePriority
        end

        if left.displayOrderID ~= right.displayOrderID then
            return left.displayOrderID < right.displayOrderID
        end

        return (left.memberIndex or 0) < (right.memberIndex or 0)
    end)

    return participants
end

PlannerPrivate.GetWhisperParticipants = function(settings, blocked, seen)
    local participants = {}

    for _, whisperEntry in ipairs(settings.whisperApplicants or {}) do
        if PlannerPrivate.IsWhisperApplicantReadyForPlanner(whisperEntry) then
            local fullName = whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName
            local applicantData = PlannerPrivate.FindApplicantByName(fullName)
            local specID = whisperEntry.specID
                or (applicantData and applicantData.specID)
                or PlannerPrivate.GetKnownSpecID(fullName, nil)
                or nil
            local roleKey = whisperEntry.roleKey
                or (applicantData and PlannerPrivate.GetApplicantRoleKey(applicantData))
                or PlannerPrivate.GetSingleSupportedRoleKey(whisperEntry.classFile)
                or nil

            PlannerPrivate.AddParticipant(participants, seen, blocked, {
                name = whisperEntry.displayName ~= "" and whisperEntry.displayName
                    or PlannerPrivate.GetDisplayNameFromFullName(fullName)
                    or tostring(fullName or ""),
                fullName = fullName,
                inviteName = whisperEntry.inviteName or fullName,
                classFile = whisperEntry.classFile or (applicantData and applicantData.classFile) or nil,
                specID = specID,
                roleKey = roleKey,
                sourceKey = whisperEntry.sourceKey or ("whisper:" .. tostring(PlannerPrivate.GetIdentityKey(fullName) or "")),
            })
        end
    end

    return participants
end

PlannerPrivate.BuildManualDungeonBlocklist = function(settings)
    local blocked = {}

    for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
        local slotKey = slotInfo.key
        local currentEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.dungeon[slotKey])

        if PlannerPrivate.IsAutoManagedEntry(currentEntry) then
            settings.slots.dungeon[slotKey] = PlannerPrivate.NormalizeSlotEntry(nil)
        else
            local inviteNameKey = PlannerPrivate.GetIdentityKey(currentEntry.inviteName)
            if inviteNameKey then
                blocked[inviteNameKey] = true
            end

            local entryNameKey = PlannerPrivate.GetIdentityKey(currentEntry.name)
            if entryNameKey then
                blocked[entryNameKey] = true
            end
        end
    end

    return blocked
end

PlannerPrivate.BuildManualRaidBlocklist = function(settings)
    local blocked = {}

    for index = 1, RAID_SLOT_COUNT do
        local currentEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.raid[index])

        if PlannerPrivate.IsAutoManagedEntry(currentEntry) then
            settings.slots.raid[index] = PlannerPrivate.NormalizeSlotEntry(nil)
        else
            local inviteNameKey = PlannerPrivate.GetIdentityKey(currentEntry.inviteName)
            if inviteNameKey then
                blocked[inviteNameKey] = true
            end

            local entryNameKey = PlannerPrivate.GetIdentityKey(currentEntry.name)
            if entryNameKey then
                blocked[entryNameKey] = true
            end
        end
    end

    return blocked
end

PlannerPrivate.GetLiveDungeonParticipants = function(settings)
    local participants = {}
    local seen = {}
    local blocked = PlannerPrivate.BuildManualDungeonBlocklist(settings)
    local isRaidGroup = IsInRaid and IsInRaid() or false
    local isGrouped = IsInGroup and IsInGroup() or false

    -- Den eigenen Charakter wollen wir auch im Dungeon-Planer sehen,
    -- selbst wenn wir parallel in einem Raid sind.
    PlannerPrivate.AddParticipant(participants, seen, blocked, PlannerPrivate.GetUnitParticipant("player"))

    if not isRaidGroup and isGrouped then
        local subgroupMemberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for memberIndex = 1, subgroupMemberCount do
            PlannerPrivate.AddParticipant(participants, seen, blocked, PlannerPrivate.GetUnitParticipant("party" .. memberIndex))
        end
    end

    for _, participant in ipairs(PlannerPrivate.GetWhisperParticipants(settings, blocked, seen)) do
        participants[#participants + 1] = participant
    end

    return participants
end

PlannerPrivate.GetLiveRaidParticipants = function(settings)
    local participants = {}
    local seen = {}
    local blocked = PlannerPrivate.BuildManualRaidBlocklist(settings)
    local isRaidGroup = IsInRaid and IsInRaid() or false
    local isGrouped = IsInGroup and IsInGroup() or false

    PlannerPrivate.AddParticipant(participants, seen, blocked, PlannerPrivate.GetUnitParticipant("player"))

    if isRaidGroup and GetNumGroupMembers then
        for memberIndex = 1, (GetNumGroupMembers() or 0) do
            PlannerPrivate.AddParticipant(participants, seen, blocked, PlannerPrivate.GetUnitParticipant("raid" .. memberIndex))
        end
    elseif isGrouped and GetNumSubgroupMembers then
        for memberIndex = 1, (GetNumSubgroupMembers() or 0) do
            PlannerPrivate.AddParticipant(participants, seen, blocked, PlannerPrivate.GetUnitParticipant("party" .. memberIndex))
        end
    end

    for _, participant in ipairs(PlannerPrivate.GetWhisperParticipants(settings, blocked, seen)) do
        participants[#participants + 1] = participant
    end

    return participants
end

PlannerPrivate.GetParticipantRoleKey = function(participant)
    if type(participant) ~= "table" then
        return nil
    end

    if participant.roleKey then
        return PlannerPrivate.NormalizePlannerRoleKey(participant.roleKey)
    end

    return PlannerPrivate.GetEntryAssignedRole(participant)
end

PlannerPrivate.FindDungeonSlotForParticipant = function(settings, participant)
    local preferredSlotKey = nil
    local fallbackSlotKey = nil
    local participantRole = PlannerPrivate.GetParticipantRoleKey(participant)

    for _, slotInfo in ipairs(StreamerPlannerModule.DUNGEON_LAYOUT) do
        local slotKey = slotInfo.key
        local slotEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.dungeon[slotKey])
        local isEmptySlot = slotEntry.name == ""
            and slotEntry.classFile == nil
            and slotEntry.specID == nil
            and slotEntry.roleKey == nil
            and slotEntry.inviteName == nil
            and slotEntry.sourceKey == nil

        if isEmptySlot then
            fallbackSlotKey = fallbackSlotKey or slotKey

            if preferredSlotKey == nil and participantRole ~= nil and DUNGEON_SLOT_ROLE_REQUIREMENTS[slotKey] == participantRole then
                preferredSlotKey = slotKey
            end
        end
    end

    return preferredSlotKey or fallbackSlotKey
end

PlannerPrivate.ApplyDungeonParticipantsToSlots = function(settings, participants)
    for _, participant in ipairs(participants) do
        local targetSlotKey = PlannerPrivate.FindDungeonSlotForParticipant(settings, participant)
        if targetSlotKey then
            settings.slots.dungeon[targetSlotKey] = PlannerPrivate.NormalizeSlotEntry({
                name = participant.name,
                classFile = participant.classFile,
                specID = participant.specID,
                roleKey = PlannerPrivate.GetParticipantRoleKey(participant),
                inviteName = participant.inviteName,
                sourceKey = participant.sourceKey,
            })
        end
    end
end

PlannerPrivate.FindRaidSlotForParticipant = function(settings)
    for index = 1, RAID_SLOT_COUNT do
        local slotEntry = PlannerPrivate.NormalizeSlotEntry(settings.slots.raid[index])
        local isEmptySlot = slotEntry.name == ""
            and slotEntry.classFile == nil
            and slotEntry.specID == nil
            and slotEntry.roleKey == nil
            and slotEntry.inviteName == nil
            and slotEntry.sourceKey == nil

        if isEmptySlot then
            return index
        end
    end

    return nil
end

PlannerPrivate.ApplyRaidParticipantsToSlots = function(settings, participants)
    for _, participant in ipairs(participants) do
        local targetSlotIndex = PlannerPrivate.FindRaidSlotForParticipant(settings)
        if targetSlotIndex then
            settings.slots.raid[targetSlotIndex] = PlannerPrivate.NormalizeSlotEntry({
                name = participant.name,
                classFile = participant.classFile,
                specID = participant.specID,
                roleKey = PlannerPrivate.GetParticipantRoleKey(participant),
                inviteName = participant.inviteName,
                sourceKey = participant.sourceKey,
            })
        end
    end
end

PlannerPrivate.GetActiveListingState = function()
    local textCandidates, activeEntryInfo = PlannerPrivate.GetEntryCreationTextCandidates()
    if type(activeEntryInfo) ~= "table" then
        return nil
    end

    local categoryKey, destinationText = PlannerPrivate.ResolveDestinationFromCandidates(textCandidates)
    if categoryKey == nil and destinationText == nil then
        return nil
    end

    if PlannerPrivate.IsRaidDestinationText(destinationText) then
        categoryKey = "raids"
    end

    local level = categoryKey and PlannerPrivate.ParseDestinationLevelFromText(textCandidates, categoryKey) or nil
    local mode = nil
    if categoryKey == "raids" or PlannerPrivate.IsRaidDestinationText(destinationText) then
        mode = "raid"
    else
        mode = "dungeon"
    end

    return {
        mode = mode,
        categoryKey = categoryKey,
        destinationText = destinationText,
        level = level,
    }
end

PlannerPrivate.ApplyActiveListingState = function(listingState)
    if type(listingState) ~= "table" then
        return
    end

    local settings = GetStreamerPlannerSettings()

    if listingState.mode == "raid" or listingState.mode == "dungeon" then
        settings.mode = listingState.mode
    end

    if type(listingState.categoryKey) == "string" and StreamerPlannerModule.DESTINATION_OPTIONS[listingState.categoryKey] then
        settings.destinationCategory = listingState.categoryKey
    end

    if PlannerPrivate.IsUsablePlainString(listingState.destinationText) then
        settings.destination = listingState.destinationText
    end

    if settings.mode == "raid" then
        if settings.destinationCategory == "s1" or settings.destinationCategory == "delves" then
            settings.destinationCategory = "raids"
        end
    elseif settings.destinationCategory == "raids" and not PlannerPrivate.IsRaidDestinationText(settings.destination) then
        settings.destinationCategory = StreamerPlannerModule.DESTINATION_CATEGORIES[1].key
    end

    if listingState.categoryKey ~= nil then
        settings.destinationKeystoneLevel = PlannerPrivate.NormalizeDestinationLevel(settings.destinationCategory, listingState.level)
    end
end

PlannerPrivate.BuildDungeonSyncSignature = function(listingState, dungeonParticipants, raidParticipants)
    local signatureParts = {
        listingState and listingState.mode or "",
        listingState and listingState.categoryKey or "",
        listingState and listingState.destinationText or "",
        listingState and tostring(listingState.level or "") or "",
    }

    local function AddParticipants(prefix, participants)
        for _, participant in ipairs(participants or {}) do
            signatureParts[#signatureParts + 1] = table.concat({
                prefix,
                tostring(participant.sourceKey or ""),
                tostring(participant.fullName or participant.name or ""),
                tostring(participant.roleKey or ""),
                tostring(participant.specID or ""),
                tostring(participant.classFile or ""),
                tostring(participant.applicantStatus or ""),
            }, "|")
        end
    end

    AddParticipants("dungeon", dungeonParticipants)
    AddParticipants("raid", raidParticipants)

    return table.concat(signatureParts, "||")
end

PlannerPrivate.SyncDynamicPlannerState = function(forceRefresh)
    PlannerPrivate.ExpirePendingInspectRequest()

    local snapshot = PlannerPrivate.RefreshApplicantSnapshot()
    local listingState = PlannerPrivate.GetActiveListingState()
    local settings = GetStreamerPlannerSettings()
    local dungeonParticipants = PlannerPrivate.GetLiveDungeonParticipants(settings)
    local raidParticipants = PlannerPrivate.GetLiveRaidParticipants(settings)
    local nextSignature = PlannerPrivate.BuildDungeonSyncSignature(listingState, dungeonParticipants, raidParticipants)
    local previousSignature = PlannerPrivate.lastDungeonSyncSignature

    if not forceRefresh and previousSignature == nextSignature then
        return false
    end

    PlannerPrivate.ApplyActiveListingState(listingState)
    PlannerPrivate.ApplyDungeonParticipantsToSlots(settings, dungeonParticipants)
    PlannerPrivate.ApplyRaidParticipantsToSlots(settings, raidParticipants)
    PlannerPrivate.lastDungeonSyncSignature = nextSignature

    if PlannerPrivate.RefreshDynamicDisplays then
        PlannerPrivate.RefreshDynamicDisplays(snapshot)
    elseif StreamerPlannerModule and StreamerPlannerModule.RefreshAllDisplays then
        StreamerPlannerModule.RefreshAllDisplays()
    end

    return true
end

PlannerPrivate.InviteApplicantByID = function(applicantID)
    if not applicantID or not C_LFGList or not C_LFGList.InviteApplicant then
        return false
    end

    C_LFGList.InviteApplicant(applicantID)
    return true
end

PlannerPrivate.InviteApplicantByName = function(name)
    local applicantData = PlannerPrivate.FindApplicantByName(name)
    if not applicantData or not PlannerPrivate.CanInviteApplicantStatus(applicantData.applicationStatus) then
        return false
    end

    return PlannerPrivate.InviteApplicantByID(applicantData.applicantID)
end

PlannerPrivate.BuildCurrentGroupLookup = function()
    if PlannerPrivate.currentGroupLookupDirty ~= true and type(PlannerPrivate.currentGroupLookupCache) == "table" then
        return PlannerPrivate.currentGroupLookupCache
    end

    local lookup = {}

    local function AddName(name)
        for _, identityKey in ipairs(PlannerPrivate.GetIdentityKeys(name)) do
            lookup[identityKey] = true
        end
    end

    AddName(PlannerPrivate.GetUnitFullName("player") or (UnitName and UnitName("player")) or nil)

    if IsInRaid and IsInRaid() and GetNumGroupMembers and GetRaidRosterInfo then
        for memberIndex = 1, (GetNumGroupMembers() or 0) do
            AddName(GetRaidRosterInfo(memberIndex))
        end
    elseif IsInGroup and IsInGroup() and GetNumSubgroupMembers then
        for memberIndex = 1, (GetNumSubgroupMembers() or 0) do
            AddName(PlannerPrivate.GetUnitFullName("party" .. memberIndex))
        end
    end

    PlannerPrivate.currentGroupLookupCache = lookup
    PlannerPrivate.currentGroupLookupDirty = false
    return lookup
end

PlannerPrivate.IsNameInCurrentGroup = function(name, groupLookup)
    local identityKeys = PlannerPrivate.GetIdentityKeys(name)
    if #identityKeys == 0 then
        return false
    end

    local resolvedLookup = type(groupLookup) == "table" and groupLookup or PlannerPrivate.BuildCurrentGroupLookup()
    for _, identityKey in ipairs(identityKeys) do
        if resolvedLookup[identityKey] == true then
            return true
        end
    end

    return false
end

PlannerPrivate.SendRegularInvite = function(inviteName)
    if not PlannerPrivate.IsUsablePlainString(inviteName) then
        return false
    end

    local partyInfoAPI = rawget(_G, "C_PartyInfo")
    if type(partyInfoAPI) == "table" and type(partyInfoAPI.InviteUnit) == "function" then
        partyInfoAPI.InviteUnit(inviteName)
        return true
    end

    local inviteUnitValue = rawget(_G, "InviteUnit")
    if type(inviteUnitValue) == "function" then
        inviteUnitValue(inviteName)
        return true
    end

    return false
end

PlannerPrivate.InvitePlayerByName = function(inviteName)
    if not PlannerPrivate.IsUsablePlainString(inviteName) then
        return false
    end

    if PlannerPrivate.IsNameInCurrentGroup(inviteName) then
        return false
    end

    local isGrouped = IsInGroup and IsInGroup() or false
    local isRaid = IsInRaid and IsInRaid() or false
    local groupMemberCount = GetNumGroupMembers and GetNumGroupMembers() or 0

    local convertToRaidValue = rawget(_G, "ConvertToRaid")
    local timerAPI = rawget(_G, "C_Timer")
    if isGrouped and not isRaid and groupMemberCount >= 5 and type(convertToRaidValue) == "function" then
        convertToRaidValue()
        if type(timerAPI) == "table" and type(timerAPI.After) == "function" then
            timerAPI.After(0.2, function()
                PlannerPrivate.SendRegularInvite(inviteName)
            end)
        else
            PlannerPrivate.SendRegularInvite(inviteName)
        end
    else
        if not PlannerPrivate.SendRegularInvite(inviteName) then
            return false
        end
    end

    PlannerPrivate.MarkWhisperApplicantInvited(inviteName)
    return true
end

PlannerPrivate.ResolveInviteTarget = function(rowData, groupLookup)
    if type(rowData) ~= "table" then
        return nil
    end

    if rowData.applicantID and PlannerPrivate.CanInviteApplicantStatus(rowData.applicationStatus) then
        return {
            mode = "applicant",
            applicantID = rowData.applicantID,
        }
    end

    if rowData.applicationStatus == "invited" or rowData.applicationStatus == "inviteaccepted" then
        return nil
    end

    local inviteName = rowData.inviteName or rowData.fullName or rowData.name
    if not PlannerPrivate.IsUsablePlainString(inviteName) then
        return nil
    end

    if PlannerPrivate.IsNameInCurrentGroup(inviteName, groupLookup) then
        return nil
    end

    return {
        mode = "unit",
        inviteName = inviteName,
    }
end

PlannerPrivate.InviteResolvedTarget = function(target)
    if type(target) ~= "table" then
        return false
    end

    if target.mode == "applicant" then
        return PlannerPrivate.InviteApplicantByID(target.applicantID)
    end

    if target.mode == "unit" then
        return PlannerPrivate.InvitePlayerByName(target.inviteName)
    end

    return false
end

PlannerPrivate.AddSourceLabel = function(rowData, labelText)
    if type(rowData) ~= "table" or type(labelText) ~= "string" or labelText == "" then
        return
    end

    rowData.sourceLabels = rowData.sourceLabels or {}
    rowData.sourceLabelLookup = rowData.sourceLabelLookup or {}

    if rowData.sourceLabelLookup[labelText] then
        return
    end

    rowData.sourceLabelLookup[labelText] = true
    rowData.sourceLabels[#rowData.sourceLabels + 1] = labelText
end

PlannerPrivate.BuildApplicantPanelRowData = function(snapshot)
    local settings = GetStreamerPlannerSettings()
    local groupLookup = PlannerPrivate.BuildCurrentGroupLookup()
    local rowByIdentity = {}
    local orderedRows = {}

    local function GetOrCreateRow(identityKey, rowData)
        local existingRow = rowByIdentity[identityKey]
        if existingRow then
            return existingRow
        end

        rowData.sourceLabels = rowData.sourceLabels or {}
        rowData.sourceLabelLookup = rowData.sourceLabelLookup or {}
        rowByIdentity[identityKey] = rowData
        orderedRows[#orderedRows + 1] = rowData
        return rowData
    end

    local function MergeApplicantPanelRow(rowData)
        local identityKey = PlannerPrivate.GetIdentityKey(rowData.fullName or rowData.inviteName or rowData.name)
        if not identityKey then
            return
        end

        local targetRow = GetOrCreateRow(identityKey, rowData)
        if targetRow ~= rowData then
            targetRow.fullName = targetRow.fullName or rowData.fullName
            targetRow.inviteName = targetRow.inviteName or rowData.inviteName
            targetRow.name = targetRow.name ~= "" and targetRow.name or rowData.name
            targetRow.whisperIdentityName = targetRow.whisperIdentityName or rowData.whisperIdentityName
            targetRow.classFile = targetRow.classFile or rowData.classFile
            targetRow.specID = targetRow.specID or rowData.specID
            targetRow.roleKey = targetRow.roleKey or rowData.roleKey
            targetRow.itemLevel = targetRow.itemLevel or rowData.itemLevel
            targetRow.dungeonScore = targetRow.dungeonScore or rowData.dungeonScore
            targetRow.displayOrderID = math.min(targetRow.displayOrderID or math.huge, rowData.displayOrderID or math.huge)
            targetRow.updatedAt = math.max(targetRow.updatedAt or 0, rowData.updatedAt or 0)
            targetRow.memberCount = targetRow.memberCount or rowData.memberCount
            targetRow.isPrimary = targetRow.isPrimary or rowData.isPrimary

            if targetRow.statusKey ~= "grouped" then
                if rowData.statusKey == "grouped" or targetRow.statusKey == nil or rowData.applicantID then
                    targetRow.statusKey = rowData.statusKey
                    targetRow.statusText = rowData.statusText
                end
            end

            if rowData.applicantID then
                targetRow.applicantID = rowData.applicantID
                targetRow.applicationStatus = rowData.applicationStatus
            end

            if rowData.inviteTarget and (targetRow.inviteTarget == nil or rowData.applicantID) then
                targetRow.inviteTarget = rowData.inviteTarget
            end

            if rowData.sortPriority and ((targetRow.sortPriority or rowData.sortPriority) > rowData.sortPriority) then
                targetRow.sortPriority = rowData.sortPriority
            end
        end

        for _, labelText in ipairs(rowData.sourceLabels or {}) do
            PlannerPrivate.AddSourceLabel(targetRow, labelText)
        end

        targetRow.inviteTarget = PlannerPrivate.ResolveInviteTarget(targetRow, groupLookup)
        targetRow.canInvite = targetRow.inviteTarget ~= nil
        if targetRow.statusKey == "grouped" then
            targetRow.canInvite = false
            targetRow.inviteTarget = nil
            targetRow.sortPriority = 4
        elseif targetRow.canInvite then
            targetRow.sortPriority = math.min(targetRow.sortPriority or 3, 1)
        else
            targetRow.sortPriority = targetRow.sortPriority or 3
        end
    end

    for _, whisperEntry in ipairs(settings.whisperApplicants or {}) do
        local applicantData = PlannerPrivate.FindApplicantByName(whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName)
        local specID = whisperEntry.specID
            or (applicantData and applicantData.specID)
            or PlannerPrivate.GetKnownSpecID(whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName, nil)
            or nil
        local roleKey = whisperEntry.roleKey
            or (applicantData and PlannerPrivate.GetApplicantRoleKey(applicantData))
            or PlannerPrivate.GetSingleSupportedRoleKey(whisperEntry.classFile)
            or nil
        local rowData = {
            name = whisperEntry.displayName ~= "" and whisperEntry.displayName
                or PlannerPrivate.GetDisplayNameFromFullName(whisperEntry.fullName or whisperEntry.inviteName)
                or "",
            fullName = whisperEntry.fullName,
            inviteName = whisperEntry.inviteName,
            whisperIdentityName = whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName,
            classFile = whisperEntry.classFile or (applicantData and applicantData.classFile) or nil,
            specID = specID,
            roleKey = roleKey,
            itemLevel = applicantData and applicantData.itemLevel or nil,
            dungeonScore = applicantData and applicantData.dungeonScore or nil,
            applicantID = applicantData and applicantData.applicantID or nil,
            applicationStatus = applicantData and applicantData.applicationStatus or nil,
            updatedAt = whisperEntry.updatedAt or 0,
            displayOrderID = whisperEntry.createdAt or 0,
            sourceLabels = {},
            sourceLabelLookup = {},
            sortPriority = 2,
            roleOrder = PlannerPrivate.GetApplicantPanelRoleOrder(roleKey),
        }

        PlannerPrivate.AddSourceLabel(rowData, whisperEntry.command == "inv"
            and L("STREAMER_PLANNER_SOURCE_WHISPER_INV")
            or L("STREAMER_PLANNER_SOURCE_WHISPER_ENTER"))

        if PlannerPrivate.IsNameInCurrentGroup(rowData.inviteName or rowData.fullName, groupLookup) then
            rowData.statusKey = "grouped"
            rowData.statusText = L("STREAMER_PLANNER_STATUS_GROUPED")
            rowData.sortPriority = 4
        elseif applicantData and applicantData.applicationStatus then
            rowData.statusKey = applicantData.applicationStatus
            rowData.statusText = PlannerPrivate.GetApplicantStatusLabel(applicantData.applicationStatus)
            rowData.sortPriority = PlannerPrivate.CanInviteApplicantStatus(applicantData.applicationStatus) and 1 or 3
        elseif type(whisperEntry.lastInvitedAt) == "number" and (GetCurrentTimestamp() - whisperEntry.lastInvitedAt) < 600 then
            rowData.statusKey = "invited"
            rowData.statusText = L("STREAMER_PLANNER_STATUS_INVITED")
            rowData.sortPriority = 3
        else
            rowData.statusKey = whisperEntry.command == "inv" and "whisper_inv" or "whisper_enter"
            rowData.statusText = whisperEntry.command == "inv"
                and L("STREAMER_PLANNER_STATUS_WHISPER_INV")
                or L("STREAMER_PLANNER_STATUS_WHISPER_ENTER")
            rowData.sortPriority = 2
        end

        rowData.inviteTarget = PlannerPrivate.ResolveInviteTarget(rowData, groupLookup)
        MergeApplicantPanelRow(rowData)
    end

    table.sort(orderedRows, function(left, right)
        if (left.sortPriority or 99) ~= (right.sortPriority or 99) then
            return (left.sortPriority or 99) < (right.sortPriority or 99)
        end

        if (left.roleOrder or 99) ~= (right.roleOrder or 99) then
            return (left.roleOrder or 99) < (right.roleOrder or 99)
        end

        if (left.updatedAt or 0) ~= (right.updatedAt or 0) then
            return (left.updatedAt or 0) > (right.updatedAt or 0)
        end

        if (left.displayOrderID or 0) ~= (right.displayOrderID or 0) then
            return (left.displayOrderID or 0) < (right.displayOrderID or 0)
        end

        return tostring(left.name or left.fullName or "") < tostring(right.name or right.fullName or "")
    end)

    return orderedRows
end

PlannerPrivate.CollectLayoutInviteTargets = function(layout, inviteTargets, seenTargets)
    local groupLookup = PlannerPrivate.BuildCurrentGroupLookup()
    local slotCount = layout == "raid" and RAID_SLOT_COUNT or #StreamerPlannerModule.DUNGEON_LAYOUT

    for index = 1, slotCount do
        local slotEntry = GetSlotEntry(layout, index)
        local applicantData = PlannerPrivate.FindApplicantByName(slotEntry.inviteName or slotEntry.name)
        local inviteTarget = PlannerPrivate.ResolveInviteTarget({
            name = slotEntry.name,
            fullName = slotEntry.inviteName,
            inviteName = slotEntry.inviteName,
            applicantID = applicantData and applicantData.applicantID or nil,
            applicationStatus = applicantData and applicantData.applicationStatus or nil,
        }, groupLookup)

        local targetKey = nil
        if inviteTarget and inviteTarget.mode == "applicant" then
            targetKey = string.format("applicant:%s", tostring(inviteTarget.applicantID or ""))
        elseif inviteTarget and inviteTarget.mode == "unit" then
            targetKey = string.format("unit:%s", tostring(PlannerPrivate.GetIdentityKey(inviteTarget.inviteName) or inviteTarget.inviteName or ""))
        end

        if inviteTarget and targetKey and not seenTargets[targetKey] then
            seenTargets[targetKey] = true
            inviteTargets[#inviteTargets + 1] = inviteTarget
        end
    end
end

PlannerPrivate.InviteAllApplicantRows = function(rowDataList, layout)
    if layout ~= "raid" then
        return false
    end

    local inviteTargets = {}
    local seenTargets = {}

    for _, rowData in ipairs(rowDataList or {}) do
        local inviteTarget = rowData and rowData.inviteTarget or nil
        local targetKey = nil
        if inviteTarget and inviteTarget.mode == "applicant" then
            targetKey = string.format("applicant:%s", tostring(inviteTarget.applicantID or ""))
        elseif inviteTarget and inviteTarget.mode == "unit" then
            targetKey = string.format("unit:%s", tostring(PlannerPrivate.GetIdentityKey(inviteTarget.inviteName) or inviteTarget.inviteName or ""))
        end

        if inviteTarget and targetKey and not seenTargets[targetKey] then
            seenTargets[targetKey] = true
            inviteTargets[#inviteTargets + 1] = inviteTarget
        end
    end

    PlannerPrivate.CollectLayoutInviteTargets(layout == "raid" and "raid" or "dungeon", inviteTargets, seenTargets)

    for index, inviteTarget in ipairs(inviteTargets) do
        local timerAPI = rawget(_G, "C_Timer")
        if type(timerAPI) == "table" and type(timerAPI.After) == "function" then
            timerAPI.After((index - 1) * 0.15, function()
                PlannerPrivate.InviteResolvedTarget(inviteTarget)
            end)
        else
            PlannerPrivate.InviteResolvedTarget(inviteTarget)
        end
    end

    return #inviteTargets > 0
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
    if not ScaleSlider or not ScaleSlider.TextLabel then
        return
    end

    ScaleSlider.TextLabel:SetText(string.format("%s: %s", L("STREAMER_PLANNER_SCALE"), GetSliderPercentText(ScaleSlider:GetValue())))
end

local function RefreshTimerDurationSliderText()
    if not TimerDurationSlider or not TimerDurationSlider.TextLabel then
        return
    end

    TimerDurationSlider.TextLabel:SetText(string.format("%s: %s", L("STREAMER_PLANNER_TIMER_DURATION"), GetTimerDurationText(TimerDurationSlider:GetValue())))
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
    if PlannerPrivate.editingField == "destination" and DestinationInput and DestinationInput:IsShown() then
        destinationText = DestinationInput:GetText()
    end
    local selectedSuggestion = PlannerPrivate.FindDestinationSuggestion(categoryKey, destinationText)

    UIDropDownMenu_SetWidth(DestinationSuggestionDropdown, 232)
    UIDropDownMenu_SetSelectedValue(DestinationSuggestionDropdown, selectedSuggestion)
    UIDropDownMenu_SetText(DestinationSuggestionDropdown, selectedSuggestion or L("STREAMER_PLANNER_DESTINATION_MANUAL"))
end

local function ShouldShowDestinationKeystoneControls()
    local categoryKey = GetDestinationCategory()
    if categoryKey ~= "s1" and categoryKey ~= "delves" and categoryKey ~= "raids" then
        return false
    end

    local destinationText = GetDestinationBaseText()
    if PlannerPrivate.editingField == "destination" and DestinationInput and DestinationInput:IsShown() then
        destinationText = DestinationInput:GetText()
    end

    return PlannerPrivate.FindDestinationSuggestion(categoryKey, destinationText) ~= nil
end

local function RefreshDestinationKeystoneDropdown()
    if not DestinationKeystoneDropdown or not DestinationInput or not EditDialog then
        return
    end

    local shouldShow = PlannerPrivate.editingField == "destination" and ShouldShowDestinationKeystoneControls()

    if EditDestinationKeystoneLabel then
        if GetDestinationCategory() == "raids" then
            EditDestinationKeystoneLabel:SetText(L("ITEM_GUIDE_HEADER_DIFFICULTY"))
        else
            EditDestinationKeystoneLabel:SetText(L("STREAMER_PLANNER_DESTINATION_KEYSTONE"))
        end
        EditDestinationKeystoneLabel:SetShown(shouldShow)
    end

    if shouldShow then
        local categoryKey = GetDestinationCategory()
        local selectedLevel = GetDestinationKeystoneLevel()
        if categoryKey == "raids" then
            if type(selectedLevel) ~= "string" then
                selectedLevel = "normal"
                SetDestinationKeystoneLevel(selectedLevel)
            end
        elseif type(selectedLevel) ~= "number" then
            selectedLevel = categoryKey == "delves" and 1 or 0
            SetDestinationKeystoneLevel(selectedLevel)
        end

        DestinationKeystoneDropdown:Show()
        UIDropDownMenu_SetWidth(DestinationKeystoneDropdown, categoryKey == "raids" and 116 or 88)
        UIDropDownMenu_SetSelectedValue(DestinationKeystoneDropdown, selectedLevel)
        UIDropDownMenu_SetText(DestinationKeystoneDropdown, PlannerPrivate.GetDestinationLevelLabel(categoryKey, selectedLevel) or "")

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
    local isSlotEditing = PlannerPrivate.editingField == "slot"
    local isDestinationEditing = PlannerPrivate.editingField == "destination"
    local isSelfRoleEditing = isSlotEditing and PlannerPrivate.editingUsesSelfRoleOverride == true
    local roleRequirement = GetSlotRoleRequirement(PlannerPrivate.editingLayout, PlannerPrivate.editingSlotIndex)

    if EditDialogInput then
        if isSlotEditing and not isSelfRoleEditing then
            EditDialogInput:Show()
        else
            EditDialogInput:Hide()
        end
    end

    if EditDialogTargetLabel then
        if isSlotEditing and not isSelfRoleEditing then
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

    if EditDialog and EditDialog.RoleTitle then
        EditDialog.RoleTitle:SetText(L("STREAMER_PLANNER_ROLE"))
        EditDialog.RoleTitle:SetShown(isSelfRoleEditing)
    end

    if isSelfRoleEditing then
        for _, button in ipairs(PlannerPrivate.editRoleButtons) do
            local isAuto = button.RoleKey == false
            local active = (isAuto and PlannerPrivate.editingRoleKey == nil) or (button.RoleKey == PlannerPrivate.editingRoleKey)
            PlannerPrivate.RefreshSelectionButton(button, active)
            button:Show()
        end

        if EditClassTitle then
            EditClassTitle:Hide()
        end

        if EditSpecTitle then
            EditSpecTitle:Hide()
        end

        for _, button in ipairs(PlannerPrivate.editClassButtons) do
            button:Hide()
        end

        for _, button in ipairs(PlannerPrivate.editSpecButtons) do
            button:Hide()
        end

        LayoutEditDialogOptionButtons()
        return
    end

    for _, button in ipairs(PlannerPrivate.editRoleButtons) do
        button:Hide()
    end

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

    if isSlotEditing and PlannerPrivate.editingClassFile and not IsClassAllowedForRole(PlannerPrivate.editingClassFile, roleRequirement) then
        PlannerPrivate.editingClassFile = nil
        PlannerPrivate.editingSpecID = nil
    elseif isSlotEditing and PlannerPrivate.editingSpecID and not IsSpecAllowedForRole(PlannerPrivate.editingSpecID, roleRequirement) then
        PlannerPrivate.editingSpecID = nil
    end

    for _, button in ipairs(PlannerPrivate.editClassButtons) do
        if isSlotEditing then
            local isAllowed = IsClassAllowedForRole(button.ClassFile, roleRequirement)
            button:SetShown(isAllowed)
            if isAllowed then
                local active = button.ClassFile == PlannerPrivate.editingClassFile
                local red, green, blue = GetClassColor(button.ClassFile)
                button.Icon:SetVertexColor(active and 1 or red, active and 1 or green, active and 1 or blue, 1)
                button.Selected:SetShown(active)
            end
        else
            button:Hide()
        end
    end

    for _, button in ipairs(PlannerPrivate.editSpecButtons) do
        button:Hide()
    end

    if not isSlotEditing or not PlannerPrivate.editingClassFile then
        LayoutEditDialogOptionButtons()
        return
    end

    local specOptions = BuildSpecOptions(PlannerPrivate.editingClassFile, roleRequirement)
    local visibleIndex = 0
    for _, specInfo in ipairs(specOptions) do
        if specInfo.id ~= nil then
            visibleIndex = visibleIndex + 1
            local button = PlannerPrivate.editSpecButtons[visibleIndex]
            if button then
                button.SpecID = specInfo.id
                button.DisplayName = specInfo.name
                button.Icon:SetTexture(specInfo.icon or 134400)
                button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                button.Label:SetText(specInfo.name)
                button.Selected:SetShown(PlannerPrivate.editingSpecID == specInfo.id)
                button:Show()
            end
        end
    end

    LayoutEditDialogOptionButtons()
end

LayoutEditDialogOptionButtons = function()
    local visibleRoleButtons = {}
    local visibleClassButtons = {}
    local visibleSpecButtons = {}

    for _, button in ipairs(PlannerPrivate.editRoleButtons) do
        if button:IsShown() then
            visibleRoleButtons[#visibleRoleButtons + 1] = button
        end
    end

    for _, button in ipairs(PlannerPrivate.editClassButtons) do
        if button:IsShown() then
            visibleClassButtons[#visibleClassButtons + 1] = button
        end
    end

    for _, button in ipairs(PlannerPrivate.editSpecButtons) do
        if button:IsShown() then
            visibleSpecButtons[#visibleSpecButtons + 1] = button
        end
    end

    if PlannerPrivate.editingUsesSelfRoleOverride == true and EditDialog and EditDialog.RoleTitle then
        EditDialog.RoleTitle:ClearAllPoints()
        EditDialog.RoleTitle:SetPoint("TOPLEFT", EditDialog.Hint, "BOTTOMLEFT", 0, -18)

        for index, button in ipairs(visibleRoleButtons) do
            button:ClearAllPoints()
            button:SetPoint(
                "TOPLEFT",
                EditDialog.RoleTitle,
                "BOTTOMLEFT",
                ((index - 1) % 2) * 132,
                -8 - (math.floor((index - 1) / 2) * 34)
            )
        end

        if PlannerPrivate.saveSlotButton and PlannerPrivate.clearSlotButton and PlannerPrivate.cancelSlotButton then
            PlannerPrivate.saveSlotButton:ClearAllPoints()
            if #visibleRoleButtons > 0 then
                PlannerPrivate.saveSlotButton:SetPoint("TOPLEFT", visibleRoleButtons[#visibleRoleButtons], "BOTTOMLEFT", 0, -18)
            else
                PlannerPrivate.saveSlotButton:SetPoint("TOPLEFT", EditDialog.RoleTitle, "BOTTOMLEFT", 0, -18)
            end

            PlannerPrivate.clearSlotButton:ClearAllPoints()
            PlannerPrivate.clearSlotButton:SetPoint("LEFT", PlannerPrivate.saveSlotButton, "RIGHT", 10, 0)

            PlannerPrivate.cancelSlotButton:ClearAllPoints()
            PlannerPrivate.cancelSlotButton:SetPoint("LEFT", PlannerPrivate.clearSlotButton, "RIGHT", 10, 0)
        end

        EditDialog:SetHeight(244)
        return
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

    if PlannerPrivate.editingField == "slot"
        and PlannerPrivate.saveSlotButton
        and PlannerPrivate.clearSlotButton
        and PlannerPrivate.cancelSlotButton
        and EditDialog then
        PlannerPrivate.saveSlotButton:ClearAllPoints()

        if #visibleSpecButtons > 0 then
            PlannerPrivate.saveSlotButton:SetPoint("TOPLEFT", visibleSpecButtons[1], "BOTTOMLEFT", 0, -18)
        else
            PlannerPrivate.saveSlotButton:SetPoint("TOPLEFT", EditSpecTitle, "BOTTOMLEFT", 0, -18)
        end

        PlannerPrivate.clearSlotButton:ClearAllPoints()
        PlannerPrivate.clearSlotButton:SetPoint("LEFT", PlannerPrivate.saveSlotButton, "RIGHT", 10, 0)

        PlannerPrivate.cancelSlotButton:ClearAllPoints()
        PlannerPrivate.cancelSlotButton:SetPoint("LEFT", PlannerPrivate.clearSlotButton, "RIGHT", 10, 0)

        EditDialog:SetHeight(EDIT_DIALOG_SLOT_HEIGHT + math.max(0, classRowCount - 1) * (EDIT_CLASS_BUTTON_SIZE + EDIT_CLASS_BUTTON_SPACING))
    elseif PlannerPrivate.saveSlotButton and PlannerPrivate.clearSlotButton and PlannerPrivate.cancelSlotButton then
        PlannerPrivate.saveSlotButton:ClearAllPoints()
        PlannerPrivate.saveSlotButton:SetPoint("BOTTOMLEFT", EditDialog, "BOTTOMLEFT", 16, 20)

        PlannerPrivate.clearSlotButton:ClearAllPoints()
        PlannerPrivate.clearSlotButton:SetPoint("LEFT", PlannerPrivate.saveSlotButton, "RIGHT", 10, 0)

        PlannerPrivate.cancelSlotButton:ClearAllPoints()
        PlannerPrivate.cancelSlotButton:SetPoint("LEFT", PlannerPrivate.clearSlotButton, "RIGHT", 10, 0)
    end
end

HideEditDialog = function()
    PlannerPrivate.editingLayout = nil
    PlannerPrivate.editingSlotIndex = nil
    PlannerPrivate.editingField = nil
    PlannerPrivate.editingClassFile = nil
    PlannerPrivate.editingSpecID = nil
    PlannerPrivate.editingRoleKey = nil
    PlannerPrivate.editingUsesSelfRoleOverride = false
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
    selected:SetColorTexture(0.88, 0.72, 0.46, 0.22)
    selected:Hide()
    button.Selected = selected

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)

    local borderBottom = button:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.22)

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
    bg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

    local border = panel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.82)

    return panel
end

local function CreateCheckbox(parent, text, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetScript("OnClick", onClick)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
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

PlannerPrivate.NeedsWhisperSpecSelection = function(whisperEntry)
    if type(whisperEntry) ~= "table" then
        return false
    end

    if not PlannerPrivate.IsUsablePlainString(whisperEntry.classFile) then
        return true
    end

    local supportedRoleCount = PlannerPrivate.GetSupportedRoleInfo(whisperEntry.classFile)
    return supportedRoleCount > 1
end

PlannerPrivate.GetWhisperApplicantResolvedRoleKey = function(whisperEntry)
    if type(whisperEntry) ~= "table" then
        return nil
    end

    local classFile = whisperEntry.classFile
    local roleKey = PlannerPrivate.NormalizePlannerRoleKey(whisperEntry.roleKey)
    local supportedRoles = classFile and StreamerPlannerModule.CLASS_ROLE_SUPPORT[classFile] or nil
    if roleKey ~= nil and type(supportedRoles) == "table" and supportedRoles[roleKey] ~= true then
        roleKey = nil
    end

    return roleKey or PlannerPrivate.GetSingleSupportedRoleKey(classFile)
end

PlannerPrivate.IsWhisperApplicantReadyForPlanner = function(whisperEntry)
    if type(whisperEntry) ~= "table" then
        return false
    end

    if not PlannerPrivate.IsUsablePlainString(whisperEntry.classFile) then
        return false
    end

    return PlannerPrivate.GetWhisperApplicantResolvedRoleKey(whisperEntry) ~= nil
end

PlannerPrivate.DismissActiveWhisperSpecPrompt = function()
    PlannerPrivate.activeSpecPromptIdentity = nil
    WhisperSpecPromptUI.ActiveIdentity = nil
    WhisperSpecPromptUI.SelectedClassFile = nil
    WhisperSpecPromptUI.SelectedRoleKey = nil
    WhisperSpecPromptUI.SelectedSpecID = nil

    if WhisperSpecPromptUI.Frame then
        WhisperSpecPromptUI.Frame.ActiveName = nil
        WhisperSpecPromptUI.Frame:Hide()
    end
end

PlannerPrivate.ApplyWhisperPromptSelection = function(name, classFile, roleKey, specID)
    local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(name)
    if type(whisperEntry) ~= "table" then
        PlannerPrivate.DismissActiveWhisperSpecPrompt()
        return false
    end

    local resolvedClassFile = PlannerPrivate.IsUsablePlainString(classFile) and classFile or whisperEntry.classFile
    if not PlannerPrivate.IsUsablePlainString(resolvedClassFile) then
        return false
    end

    local supportedRoles = StreamerPlannerModule.CLASS_ROLE_SUPPORT[resolvedClassFile] or {}
    local resolvedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(roleKey)
        or PlannerPrivate.NormalizePlannerRoleKey(whisperEntry.roleKey)
        or PlannerPrivate.GetSingleSupportedRoleKey(resolvedClassFile)
    if resolvedRoleKey ~= nil and supportedRoles[resolvedRoleKey] ~= true then
        resolvedRoleKey = nil
    end

    local resolvedSpecID = type(specID) == "number" and specID > 0 and specID or nil
    if resolvedSpecID ~= nil and not PlannerPrivate.IsSpecForClass(resolvedClassFile, resolvedSpecID) then
        resolvedSpecID = nil
    end
    if resolvedSpecID == nil and not PlannerPrivate.IsSpecForClass(resolvedClassFile, whisperEntry.specID) then
        resolvedSpecID = nil
    elseif resolvedSpecID == nil then
        resolvedSpecID = whisperEntry.specID
    end

    if resolvedRoleKey == nil then
        return false
    end

    whisperEntry.classFile = resolvedClassFile
    whisperEntry.specID = resolvedSpecID
    whisperEntry.roleKey = resolvedRoleKey
    whisperEntry.updatedAt = GetCurrentTimestamp()

    local settings = GetStreamerPlannerSettings()
    settings.whisperApplicants = PlannerPrivate.NormalizeWhisperApplicantList(settings.whisperApplicants)

    PlannerPrivate.DismissActiveWhisperSpecPrompt()
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
    return true
end

PlannerPrivate.RefreshWhisperSpecPromptButtons = function(whisperEntry)
    if not WhisperSpecPromptUI.Frame or not WhisperSpecPromptUI.Frame.SpecButtonAnchor then
        return
    end

    local promptWidth = WHISPER_SPEC_PROMPT_WIDTH - 32
    local selectedClassFile = PlannerPrivate.IsUsablePlainString(WhisperSpecPromptUI.SelectedClassFile)
        and WhisperSpecPromptUI.SelectedClassFile
        or whisperEntry.classFile

    local supportedRoleCount, singleRoleKey = PlannerPrivate.GetSupportedRoleInfo(selectedClassFile)
    local supportedRoles = selectedClassFile and StreamerPlannerModule.CLASS_ROLE_SUPPORT[selectedClassFile] or {}
    local selectedRoleKey = PlannerPrivate.NormalizePlannerRoleKey(WhisperSpecPromptUI.SelectedRoleKey)
        or PlannerPrivate.NormalizePlannerRoleKey(whisperEntry.roleKey)
    if selectedRoleKey ~= nil and type(supportedRoles) == "table" and supportedRoles[selectedRoleKey] ~= true then
        selectedRoleKey = nil
    end
    if supportedRoleCount == 1 then
        selectedRoleKey = singleRoleKey
    end

    WhisperSpecPromptUI.SelectedClassFile = selectedClassFile
    WhisperSpecPromptUI.SelectedRoleKey = selectedRoleKey

    local classText = GetLocalizedClassName(selectedClassFile)
    local showClassText = PlannerPrivate.IsUsablePlainString(classText)
    WhisperSpecPromptUI.Class:SetShown(showClassText)
    WhisperSpecPromptUI.Class:SetText(showClassText and classText or "")
    if showClassText then
        local classRed, classGreen, classBlue = GetClassColor(selectedClassFile)
        WhisperSpecPromptUI.Class:SetTextColor(classRed, classGreen, classBlue, 0.96)
    else
        WhisperSpecPromptUI.Class:SetTextColor(1, 0.82, 0, 0.92)
    end

    local showClassChooser = not PlannerPrivate.IsUsablePlainString(selectedClassFile)
    local classAnchor = showClassText and WhisperSpecPromptUI.Class or WhisperSpecPromptUI.Name
    local classButtonsHeight = 0
    if WhisperSpecPromptUI.ClassTitle then
        WhisperSpecPromptUI.ClassTitle:Hide()
    end

    if showClassChooser and WhisperSpecPromptUI.Frame.ClassButtonAnchor then
        WhisperSpecPromptUI.Frame.ClassButtonAnchor:ClearAllPoints()
        WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetPoint("TOPLEFT", classAnchor, "BOTTOMLEFT", 0, -8)
        WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)

        local classVisibleIndex = 0
        local classOptions = BuildClassOptions()
        for _, classInfo in ipairs(classOptions or {}) do
            if classInfo.file then
                classVisibleIndex = classVisibleIndex + 1
                local button = WhisperSpecPromptUI.ClassButtons[classVisibleIndex]
                if not button then
                    button = CreateIconPickerButton(WhisperSpecPromptUI.Frame, WHISPER_CLASS_PROMPT_BUTTON_SIZE, false)
                    button:SetScript("OnClick", function(self)
                        WhisperSpecPromptUI.SelectedClassFile = self.ClassFile

                        local nextRoleKey = PlannerPrivate.NormalizePlannerRoleKey(WhisperSpecPromptUI.SelectedRoleKey)
                        local nextSupportedRoles = StreamerPlannerModule.CLASS_ROLE_SUPPORT[self.ClassFile] or {}
                        local nextSupportedRoleCount, nextSingleRoleKey = PlannerPrivate.GetSupportedRoleInfo(self.ClassFile)
                        if nextRoleKey ~= nil and nextSupportedRoles[nextRoleKey] ~= true then
                            nextRoleKey = nil
                        end
                        if nextSupportedRoleCount == 1 then
                            nextRoleKey = nextSingleRoleKey
                        end

                        WhisperSpecPromptUI.SelectedRoleKey = nextRoleKey
                        local targetName = WhisperSpecPromptUI.Frame.ActiveName
                        if nextSingleRoleKey ~= nil and PlannerPrivate.IsUsablePlainString(targetName) then
                            PlannerPrivate.ApplyWhisperPromptSelection(targetName, self.ClassFile, nextSingleRoleKey, nil)
                            return
                        end

                        PlannerPrivate.RefreshWhisperSpecPrompt()
                    end)
                    WhisperSpecPromptUI.ClassButtons[classVisibleIndex] = button
                end

                local classColumnIndex = (classVisibleIndex - 1) % WHISPER_CLASS_PROMPT_BUTTON_COLUMNS
                local classRowIndex = math.floor((classVisibleIndex - 1) / WHISPER_CLASS_PROMPT_BUTTON_COLUMNS)
                button.ClassFile = classInfo.file
                button.DisplayName = classInfo.name
                button:ClearAllPoints()
                button:SetPoint(
                    "TOPLEFT",
                    WhisperSpecPromptUI.Frame.ClassButtonAnchor,
                    "TOPLEFT",
                    classColumnIndex * (WHISPER_CLASS_PROMPT_BUTTON_SIZE + WHISPER_CLASS_PROMPT_BUTTON_SPACING),
                    -(classRowIndex * (WHISPER_CLASS_PROMPT_BUTTON_SIZE + WHISPER_CLASS_PROMPT_BUTTON_SPACING))
                )
                button:SetSize(WHISPER_CLASS_PROMPT_BUTTON_SIZE, WHISPER_CLASS_PROMPT_BUTTON_SIZE)
                button.Icon:SetTexture(CLASS_ICON_TEXTURE)
                button.Icon:SetTexCoord(GetClassIconCoords(classInfo.file))
                button.Label:SetText("")
                button.Label:Hide()
                button.Selected:SetShown(selectedClassFile == classInfo.file)
                button:Show()
            end
        end

        for index = classVisibleIndex + 1, #WhisperSpecPromptUI.ClassButtons do
            WhisperSpecPromptUI.ClassButtons[index]:Hide()
        end

        local classRowCount = math.max(1, math.ceil(classVisibleIndex / WHISPER_CLASS_PROMPT_BUTTON_COLUMNS))
        classButtonsHeight = classRowCount * WHISPER_CLASS_PROMPT_BUTTON_SIZE
            + math.max(0, classRowCount - 1) * WHISPER_CLASS_PROMPT_BUTTON_SPACING
        WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetHeight(classButtonsHeight)
    else
        if WhisperSpecPromptUI.Frame.ClassButtonAnchor then
            WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetHeight(0)
        end

        for _, button in ipairs(WhisperSpecPromptUI.ClassButtons) do
            button:Hide()
        end
    end

    local roleVisibleIndex = 0
    local roleButtonSize = WHISPER_ROLE_PROMPT_BUTTON_SIZE
    local showRoleChooser = selectedClassFile ~= nil and supportedRoleCount > 1
    local roleButtonRowWidth = showRoleChooser
            and ((supportedRoleCount * roleButtonSize) + (math.max(0, supportedRoleCount - 1) * WHISPER_ROLE_PROMPT_BUTTON_SPACING))
        or 0
    local roleButtonStartOffset = math.max(0, math.floor((promptWidth - roleButtonRowWidth) / 2))

    WhisperSpecPromptUI.RoleTitle:Hide()
    WhisperSpecPromptUI.Frame.RoleButtonAnchor:ClearAllPoints()
    WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetPoint(
        "TOPLEFT",
        classButtonsHeight > 0 and WhisperSpecPromptUI.Frame.ClassButtonAnchor or classAnchor,
        classButtonsHeight > 0 and "BOTTOMLEFT" or "BOTTOMLEFT",
        0,
        classButtonsHeight > 0 and -10 or -12
    )
    WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)

    for _, roleKey in ipairs({ "tank", "healer", "dps" }) do
        if showRoleChooser and supportedRoles[roleKey] then
            roleVisibleIndex = roleVisibleIndex + 1
            local button = WhisperSpecPromptUI.RoleButtons[roleVisibleIndex]
            if not button then
                button = CreateIconPickerButton(WhisperSpecPromptUI.Frame, roleButtonSize, false)
                button:SetScript("OnClick", function(self)
                    WhisperSpecPromptUI.SelectedRoleKey = self.RoleKey
                    local targetName = WhisperSpecPromptUI.Frame.ActiveName
                    if PlannerPrivate.IsUsablePlainString(targetName) then
                        PlannerPrivate.ApplyWhisperPromptSelection(
                            targetName,
                            WhisperSpecPromptUI.SelectedClassFile,
                            self.RoleKey,
                            nil
                        )
                        return
                    end

                    PlannerPrivate.RefreshWhisperSpecPrompt()
                end)
                WhisperSpecPromptUI.RoleButtons[roleVisibleIndex] = button
            end

            button.RoleKey = roleKey
            button.DisplayName = PlannerPrivate.GetPlannerRoleLabel(roleKey) or tostring(roleKey)
            button:SetSize(roleButtonSize, roleButtonSize)
            button.Icon:SetTexture(ROLE_ICON_TEXTURE)
            button.Icon:SetTexCoord(PlannerPrivate.GetRoleIconTexCoords(roleKey))
            button.Label:SetText("")
            button.Label:Hide()
            button:ClearAllPoints()
            button:SetPoint(
                "TOPLEFT",
                WhisperSpecPromptUI.Frame.RoleButtonAnchor,
                "TOPLEFT",
                roleButtonStartOffset + ((roleVisibleIndex - 1) * (roleButtonSize + WHISPER_ROLE_PROMPT_BUTTON_SPACING)),
                0
            )
            PlannerPrivate.RefreshSelectionButton(button, selectedRoleKey == roleKey)
            button:Show()
        end
    end

    for index = roleVisibleIndex + 1, #WhisperSpecPromptUI.RoleButtons do
        WhisperSpecPromptUI.RoleButtons[index]:Hide()
    end

    local roleButtonsHeight = roleVisibleIndex > 0 and roleButtonSize or 0
    WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetHeight(roleButtonsHeight)

    WhisperSpecPromptUI.SpecTitle:Hide()
    WhisperSpecPromptUI.Frame.SpecButtonAnchor:SetHeight(0)
    for index = 1, #WhisperSpecPromptUI.Buttons do
        WhisperSpecPromptUI.Buttons[index]:Hide()
    end

    WhisperSpecPromptUI.Frame.ApplyButton:Hide()
    WhisperSpecPromptUI.Frame:SetHeight(math.max(
        WHISPER_SPEC_PROMPT_MIN_HEIGHT,
        78
            + (showClassText and 14 or 0)
            + classButtonsHeight
            + roleButtonsHeight
            + (showClassChooser and 8 or 0)
            + (showRoleChooser and 12 or 0)
    ))
end

PlannerPrivate.RefreshWhisperSpecPrompt = function()
    if not WhisperSpecPromptUI.Frame then
        return
    end

    if PlannerPrivate.activeSpecPromptIdentity then
        local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(PlannerPrivate.activeSpecPromptIdentity)
        if type(whisperEntry) ~= "table" then
            PlannerPrivate.DismissActiveWhisperSpecPrompt()
        elseif not PlannerPrivate.NeedsWhisperSpecSelection(whisperEntry) then
            PlannerPrivate.DismissActiveWhisperSpecPrompt()
        else
            if WhisperSpecPromptUI.ActiveIdentity ~= PlannerPrivate.activeSpecPromptIdentity then
                WhisperSpecPromptUI.ActiveIdentity = PlannerPrivate.activeSpecPromptIdentity
                WhisperSpecPromptUI.SelectedClassFile = whisperEntry.classFile
                WhisperSpecPromptUI.SelectedRoleKey = PlannerPrivate.GetWhisperApplicantResolvedRoleKey(whisperEntry)
            else
                if WhisperSpecPromptUI.SelectedClassFile == nil and whisperEntry.classFile ~= nil then
                    WhisperSpecPromptUI.SelectedClassFile = whisperEntry.classFile
                end
                if WhisperSpecPromptUI.SelectedRoleKey == nil then
                    WhisperSpecPromptUI.SelectedRoleKey = PlannerPrivate.GetWhisperApplicantResolvedRoleKey(whisperEntry)
                end
            end

            local displayName = whisperEntry.displayName or ""
            local activeName = whisperEntry.fullName or whisperEntry.inviteName or displayName
            local selectedClassFile = WhisperSpecPromptUI.SelectedClassFile or whisperEntry.classFile

            WhisperSpecPromptUI.Frame.ActiveName = activeName
            local showClassChooser = not PlannerPrivate.IsUsablePlainString(selectedClassFile)
            WhisperSpecPromptUI.Title:SetText(L("STREAMER_PLANNER_SPEC_PROMPT_TITLE"))
            WhisperSpecPromptUI.Hint:SetText(showClassChooser and L("STREAMER_PLANNER_SPEC_PROMPT_HINT_CLASS") or L("STREAMER_PLANNER_SPEC_PROMPT_HINT_ROLE"))
            WhisperSpecPromptUI.Name:SetText(displayName ~= "" and displayName or activeName or "")
            WhisperSpecPromptUI.Frame.LaterButton:Hide()
            if WhisperSpecPromptUI.Frame.RemoveButton.Label then
                WhisperSpecPromptUI.Frame.RemoveButton.Label:SetText("X")
            end
            WhisperSpecPromptUI.Frame.RemoveButton:Show()
            local classRed, classGreen, classBlue = GetClassColor(selectedClassFile)
            WhisperSpecPromptUI.Name:SetTextColor(classRed, classGreen, classBlue, 1)
            PlannerPrivate.RefreshWhisperSpecPromptButtons(whisperEntry)
            WhisperSpecPromptUI.Frame:Show()
            return
        end
    end

    while #PlannerPrivate.pendingSpecPromptQueue > 0 do
        local promptIdentity = table.remove(PlannerPrivate.pendingSpecPromptQueue, 1)
        PlannerPrivate.pendingSpecPromptLookup[promptIdentity] = nil

        local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(promptIdentity)
        if PlannerPrivate.NeedsWhisperSpecSelection(whisperEntry) then
            PlannerPrivate.activeSpecPromptIdentity = promptIdentity
            PlannerPrivate.RefreshWhisperSpecPrompt()
            return
        end
    end

    WhisperSpecPromptUI.Frame:Hide()
end

PlannerPrivate.EnqueueWhisperSpecPrompt = function(name)
    local whisperEntry = PlannerPrivate.FindWhisperApplicantByName(name)
    if type(whisperEntry) ~= "table" or not PlannerPrivate.NeedsWhisperSpecSelection(whisperEntry) then
        return false
    end

    local identityKeySource = whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName or ""
    local identityKey = PlannerPrivate.GetIdentityKey(identityKeySource)
    if identityKey == nil then
        return false
    end

    if PlannerPrivate.activeSpecPromptIdentity == identityKey then
        PlannerPrivate.RefreshWhisperSpecPrompt()
        return true
    end

    if PlannerPrivate.pendingSpecPromptLookup[identityKey] ~= true then
        PlannerPrivate.pendingSpecPromptLookup[identityKey] = true
        PlannerPrivate.pendingSpecPromptQueue[#PlannerPrivate.pendingSpecPromptQueue + 1] = identityKey
    end

    PlannerPrivate.RefreshWhisperSpecPrompt()
    return true
end

PlannerPrivate.EnsureApplicantRow = function(index)
    if ApplicantRows[index] then
        return ApplicantRows[index]
    end

    local row = CreateFrame("Frame", nil, ApplicantPanel)
    row:EnableMouse(true)
    row:SetHeight(34)
    row:SetPoint("TOPLEFT", ApplicantPanel.RowAnchor, "TOPLEFT", 0, -((index - 1) * 38))
    row:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -14, 0)

    row.Background = row:CreateTexture(nil, "BACKGROUND")
    row.Background:SetAllPoints()
    row.Background:SetColorTexture(0.05, 0.05, 0.06, 0.72)

    row.Border = row:CreateTexture(nil, "ARTWORK")
    row.Border:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.Border:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    row.Border:SetHeight(1)
    row.Border:SetColorTexture(0.88, 0.72, 0.46, 0.18)

    row.Name = row:CreateFontString(nil, "OVERLAY")
    row.Name:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
    row.Name:SetPoint("RIGHT", row, "RIGHT", -168, 0)
    row.Name:SetJustifyH("LEFT")
    row.Name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    row.Meta = row:CreateFontString(nil, "OVERLAY")
    row.Meta:SetPoint("TOPLEFT", row.Name, "BOTTOMLEFT", 0, -1)
    row.Meta:SetPoint("RIGHT", row, "RIGHT", -168, 0)
    row.Meta:SetJustifyH("LEFT")
    row.Meta:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    row.Meta:SetTextColor(0.78, 0.78, 0.80, 1)

    row.Status = row:CreateFontString(nil, "OVERLAY")
    row.Status:SetPoint("RIGHT", row, "RIGHT", -84, 0)
    row.Status:SetJustifyH("RIGHT")
    row.Status:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    row.Status:SetTextColor(1, 0.88, 0.62, 1)

    row.InviteButton = CreateActionButton(row, 72, "", function(self)
        if self.InviteTarget then
            PlannerPrivate.InviteResolvedTarget(self.InviteTarget)
        end
    end)
    row.InviteButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    row:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "LeftButton" and self.CanChooseSpec and PlannerPrivate.IsUsablePlainString(self.WhisperIdentityName) then
            PlannerPrivate.EnqueueWhisperSpecPrompt(self.WhisperIdentityName)
            return
        end

        if mouseButton == "RightButton" and PlannerPrivate.IsUsablePlainString(self.WhisperIdentityName) then
            PlannerPrivate.RemoveWhisperApplicantByName(self.WhisperIdentityName)
        end
    end)

    ApplicantRows[index] = row
    return row
end

PlannerPrivate.RefreshApplicantPanel = function(snapshot)
    if not ApplicantPanel or not ApplicantPanel.Title or not ApplicantPanel.Hint or not ApplicantPanel.EmptyText then
        return
    end

    local settings = GetStreamerPlannerSettings()
    local allowRaidInviteAutomation = GetCurrentMode() == "raid"
    local allowWhisperInviteAutomation = true
    local showPanel = true
    ApplicantPanel:SetShown(showPanel)

    if not showPanel then
        ApplicantPanel:SetHeight(0)
        return
    end

    ApplicantPanel.Title:SetText(L("STREAMER_PLANNER_QUEUE_TITLE"))
    ApplicantPanel.Hint:SetText(L("STREAMER_PLANNER_QUEUE_HINT"))

    if ApplicantPanel and ApplicantPanel.AutoInviteCheckbox then
        ApplicantPanel.AutoInviteCheckbox.Label:SetText(L("STREAMER_PLANNER_AUTO_INVITE_WHISPER"))
        ApplicantPanel.AutoInviteCheckbox:SetChecked(settings.whisperCommandAutoInvite == true)
        ApplicantPanel.AutoInviteCheckbox:SetEnabled(allowWhisperInviteAutomation)
    end

    local rowDataList = PlannerPrivate.BuildApplicantPanelRowData(snapshot)
    local hasInviteableRow = false
    for _, rowData in ipairs(rowDataList) do
        if rowData.canInvite then
            hasInviteableRow = true
            break
        end
    end

    local layoutInviteTargets = {}
    if allowRaidInviteAutomation then
        PlannerPrivate.CollectLayoutInviteTargets(GetCurrentMode(), layoutInviteTargets, {})
    end
    local hasInviteableTarget = allowRaidInviteAutomation and (hasInviteableRow or #layoutInviteTargets > 0)

    if ApplicantPanel and ApplicantPanel.FullInviteButton then
        ApplicantPanel.FullInviteButton:SetText(L("STREAMER_PLANNER_FULL_INVITE"))
        ApplicantPanel.FullInviteButton:SetEnabled(hasInviteableTarget)
    end

    if OverlayFullInviteButton then
        OverlayFullInviteButton:SetText(L("STREAMER_PLANNER_FULL_INVITE"))
        OverlayFullInviteButton:SetEnabled(hasInviteableTarget)
    end

    if OverlayAutoInviteCheckbox then
        OverlayAutoInviteCheckbox.Label:SetText(L("STREAMER_PLANNER_AUTO_INVITE_WHISPER"))
        OverlayAutoInviteCheckbox:SetChecked(settings.whisperCommandAutoInvite == true)
        OverlayAutoInviteCheckbox:SetEnabled(allowWhisperInviteAutomation)
    end

    local maxRows = 10
    local visibleRowCount = math.min(#rowDataList, maxRows)
    local lastVisibleRow = nil

    for index = 1, visibleRowCount do
        local row = PlannerPrivate.EnsureApplicantRow(index)
        local rowData = rowDataList[index]
        row.WhisperIdentityName = rowData.whisperIdentityName
        local classRed, classGreen, classBlue = GetClassColor(rowData.classFile)
        local roleLabel = PlannerPrivate.GetPlannerRoleLabel(rowData.roleKey)
        local specName = PlannerPrivate.GetSpecName(rowData.classFile, rowData.specID)
        local metaParts = {}

        if roleLabel then
            metaParts[#metaParts + 1] = roleLabel
        end

        if specName and specName ~= roleLabel then
            metaParts[#metaParts + 1] = specName
        end

        if type(rowData.itemLevel) == "number" and rowData.itemLevel > 0 then
            metaParts[#metaParts + 1] = L("EASY_LFG_ITEM_LEVEL"):format(string.format("%.1f", rowData.itemLevel))
        end

        if type(rowData.dungeonScore) == "number" and rowData.dungeonScore > 0 then
            metaParts[#metaParts + 1] = L("EASY_LFG_SCORE"):format(math.floor(rowData.dungeonScore + 0.5))
        end

        if type(rowData.sourceLabels) == "table" and #rowData.sourceLabels > 0 then
            metaParts[#metaParts + 1] = table.concat(rowData.sourceLabels, " | ")
        end

        local canInvite = rowData.canInvite == true
        local canChooseSpec = PlannerPrivate.IsUsablePlainString(rowData.whisperIdentityName)
            and PlannerPrivate.NeedsWhisperSpecSelection({
                classFile = rowData.classFile,
                specID = rowData.specID,
            })
        local statusText = rowData.statusText or ""
        if rowData.isPrimary and type(rowData.memberCount) == "number" and rowData.memberCount > 1 and rowData.statusKey ~= "grouped" then
            statusText = string.format("%s | %s", statusText, L("EASY_LFG_GROUP_BADGE"):format(rowData.memberCount))
        end

        row.Name:SetText(rowData.name or rowData.displayName or rowData.fullName or "")
        row.Name:SetTextColor(classRed, classGreen, classBlue, 1)
        row.Meta:SetText(table.concat(metaParts, " | "))
        row.Status:SetText(statusText)
        row.CanChooseSpec = canChooseSpec
        row.InviteButton:SetText(L("EASY_LFG_INVITE"))
        row.InviteButton.InviteTarget = canInvite and rowData.inviteTarget or nil
        row.InviteButton:SetShown(canInvite)
        row:Show()
        lastVisibleRow = row
    end

    for index = visibleRowCount + 1, #ApplicantRows do
        ApplicantRows[index]:Hide()
    end

    ApplicantPanel.EmptyText:SetShown(visibleRowCount == 0)
    ApplicantPanel.EmptyText:SetText(L("STREAMER_PLANNER_QUEUE_EMPTY"))

    local bottomObject = visibleRowCount == 0 and ApplicantPanel.EmptyText or lastVisibleRow

    if ApplicantPanel.MoreText then
        local extraCount = math.max(0, #rowDataList - maxRows)
        ApplicantPanel.MoreText:ClearAllPoints()
        if extraCount > 0 and lastVisibleRow then
            ApplicantPanel.MoreText:SetPoint("TOPLEFT", lastVisibleRow, "BOTTOMLEFT", 0, -8)
            ApplicantPanel.MoreText:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -18, 0)
        end
        ApplicantPanel.MoreText:SetShown(extraCount > 0)
        ApplicantPanel.MoreText:SetText(extraCount > 0 and L("EASY_LFG_OVERLAY_MORE"):format(extraCount) or "")
        if extraCount > 0 then
            bottomObject = ApplicantPanel.MoreText
        end
    end

    ApplicantPanel:SetHeight(GetMeasuredPanelHeight(ApplicantPanel, bottomObject, 18, 122))

    if PageStreamerPlanner and PageStreamerPlanner:IsShown() then
        PageStreamerPlanner:UpdateScrollLayout()
    end
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
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
    button.Border = border

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetTextColor(1, 0.88, 0.62, 1)
    label:SetText(labelText)
    button.Label = label

    button:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
        self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.72)

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
        self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
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
    slider.LowLabel = lowLabel
    slider.HighLabel = highLabel
    slider.TextLabel = textLabel

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(MIN_OVERLAY_SCALE))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(MAX_OVERLAY_SCALE))
    end

    if textLabel then
        textLabel:SetText("")
    end

    return slider
end

local function CreateSlotButton(parent, width, height, layout, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:RegisterForClicks("AnyUp")
    button.Layout = layout
    button.Index = index
    button.SlotHeight = height

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.05, 0.06, 0.60)
    button.Background = background

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
    button.Border = border

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    accent:SetHeight(1)
    accent:SetColorTexture(0.88, 0.72, 0.46, 0.22)
    button.Accent = accent

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -7)
    label:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(1, 0.88, 0.62, 1)
    button.Label = label

    local value = button:CreateFontString(nil, "OVERLAY")
    value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, 6)
    value:SetJustifyH("LEFT")
    value:SetJustifyV("TOP")
    value:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    value:SetTextColor(0.95, 0.91, 0.85, 1)
    value:SetWordWrap(false)
    button.Value = value

    button.InviteButton = CreateActionButton(button, 54, "", function(self)
        if self.InviteTarget then
            PlannerPrivate.InviteResolvedTarget(self.InviteTarget)
        end
    end)
    button.InviteButton:SetSize(54, 20)
    button.InviteButton:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    button.InviteButton:Hide()

    if height <= 24 then
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -4)
        label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

        value:ClearAllPoints()
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, 0)
        value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 4)
        value:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    elseif height <= 30 then
        value:ClearAllPoints()
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, 0)
        value:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, 4)
        value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end

    button:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.17, 0.17, 0.19, 0.92)
        self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.78)
        self.Accent:SetColorTexture(0.88, 0.72, 0.46, 0.62)
    end)

    button:SetScript("OnLeave", function(self)
        self.Background:SetColorTexture(0.05, 0.05, 0.06, 0.60)
        self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
        self.Accent:SetColorTexture(0.88, 0.72, 0.46, 0.22)
    end)

    return button
end

local function OpenEditor(layout, index, forceSelfRoleEditor)
    if not EditDialog or not EditDialogInput then
        return
    end

    PlannerPrivate.editingField = "slot"
    PlannerPrivate.editingLayout = layout
    PlannerPrivate.editingSlotIndex = index
    local slotEntry = GetSlotEntry(layout, index)
    PlannerPrivate.editingClassFile = slotEntry.classFile
    PlannerPrivate.editingSpecID = slotEntry.specID
    PlannerPrivate.editingUsesSelfRoleOverride = forceSelfRoleEditor == true
        or PlannerPrivate.ShouldOpenSelfRoleEditor(layout, index, slotEntry)
    PlannerPrivate.editingRoleKey = PlannerPrivate.NormalizePlannerRoleKey(GetStreamerPlannerSettings().selfRoleOverride)

    if PlannerPrivate.editingUsesSelfRoleOverride then
        EditDialog:SetSize(EDIT_DIALOG_WIDTH, 244)
        EditDialog.Title:SetText(L("STREAMER_PLANNER_SELF_ROLE_TITLE"))
        EditDialog.Hint:SetText(L("STREAMER_PLANNER_SELF_ROLE_HINT"))
        PlannerPrivate.saveSlotButton:SetText(L("STREAMER_PLANNER_APPLY"))
        PlannerPrivate.clearSlotButton:SetText(L("STREAMER_PLANNER_ROLE_AUTO"))
        PlannerPrivate.cancelSlotButton:SetText(L("CANCEL"))
        RefreshClassSpecButtons()
        EditDialog:Show()
        return
    end

    EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_SLOT_HEIGHT)
    PlannerPrivate.saveSlotButton:SetText(L("STREAMER_PLANNER_SAVE_SLOT"))
    PlannerPrivate.clearSlotButton:SetText(L("STREAMER_PLANNER_CLEAR_SLOT"))
    PlannerPrivate.cancelSlotButton:SetText(L("CANCEL"))

    EditDialog.Title:SetText(string.format("%s: %s", L("STREAMER_PLANNER_SLOT_EDIT"), GetSlotLabel(layout, index)))
    EditDialog.Hint:SetText(L("STREAMER_PLANNER_SLOT_EDIT_HINT"))
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

    PlannerPrivate.editingField = "destination"
    PlannerPrivate.editingLayout = nil
    PlannerPrivate.editingSlotIndex = nil
    PlannerPrivate.editingClassFile = nil
    PlannerPrivate.editingSpecID = nil
    PlannerPrivate.editingRoleKey = nil
    PlannerPrivate.editingUsesSelfRoleOverride = false
    EditDialog:SetSize(EDIT_DIALOG_WIDTH, EDIT_DIALOG_DESTINATION_HEIGHT)
    PlannerPrivate.saveSlotButton:SetText(L("STREAMER_PLANNER_SAVE_SLOT"))
    PlannerPrivate.clearSlotButton:SetText(L("STREAMER_PLANNER_CLEAR_SLOT"))
    PlannerPrivate.cancelSlotButton:SetText(L("CANCEL"))

    EditDialog.Title:SetText(L("STREAMER_PLANNER_DESTINATION_EDIT"))
    EditDialog.Hint:SetText(L("STREAMER_PLANNER_DESTINATION_EDIT_HINT"))
    DestinationInput:SetText(GetDestinationBaseText())
    RefreshDestinationCategoryDropdown()
    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
    RefreshClassSpecButtons()
    EditDialog:Show()
    DestinationInput:SetFocus()
    DestinationInput:HighlightText()
end

local function CreateRefreshContext(settings)
    local resolvedSettings = settings or GetStreamerPlannerSettings()
    return {
        settings = resolvedSettings,
        groupLookup = PlannerPrivate.BuildCurrentGroupLookup(),
    }
end

local function RefreshSlotButton(button, refreshContext)
    if not button then
        return
    end

    local resolvedContext = type(refreshContext) == "table" and refreshContext or nil
    local settings = resolvedContext and resolvedContext.settings or GetStreamerPlannerSettings()
    local groupLookup = resolvedContext and resolvedContext.groupLookup or nil
    local slotLabel = GetSlotLabel(button.Layout, button.Index)
    local slotEntry = GetSlotEntry(button.Layout, button.Index, settings)
    local slotValue = slotEntry.name
    local isSelfSlot = PlannerPrivate.IsSelfSlotEntry(slotEntry)
    local classRed, classGreen, classBlue = GetClassColor(slotEntry.classFile)
    local specName = PlannerPrivate.GetSpecName(slotEntry.classFile, slotEntry.specID)
    local roleLabel = PlannerPrivate.GetPlannerRoleLabel(PlannerPrivate.GetEntryAssignedRole(slotEntry))
    local applicantData = PlannerPrivate.FindApplicantByName(slotEntry.inviteName or slotEntry.name)
    local inviteTarget = PlannerPrivate.ResolveInviteTarget({
        name = slotEntry.name,
        fullName = slotEntry.inviteName,
        inviteName = slotEntry.inviteName,
        applicantID = applicantData and applicantData.applicantID or nil,
        applicationStatus = applicantData and applicantData.applicationStatus or nil,
    }, groupLookup)
    local showInviteButton = inviteTarget ~= nil

    if button.InviteButton then
        button.InviteButton:SetText(L("EASY_LFG_INVITE"))
        button.InviteButton.InviteTarget = inviteTarget
        button.InviteButton:SetShown(showInviteButton)
    end

    local rightAnchor = showInviteButton and button.InviteButton or button
    local rightPoint = showInviteButton and "LEFT" or "RIGHT"
    local rightOffset = showInviteButton and -8 or (button.SlotHeight <= 24 and -8 or -10)

    button.Label:ClearAllPoints()
    button.Value:ClearAllPoints()

    if button.SlotHeight <= 24 then
        button.Label:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -4)
        button.Label:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
        button.Label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")

        button.Value:SetPoint("TOPLEFT", button.Label, "BOTTOMLEFT", 0, 0)
        button.Value:SetPoint("BOTTOMRIGHT", rightAnchor, "BOTTOMRIGHT", rightOffset, 4)
        button.Value:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    elseif button.SlotHeight <= 30 then
        button.Label:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -7)
        button.Label:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
        button.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")

        button.Value:SetPoint("TOPLEFT", button.Label, "BOTTOMLEFT", 0, 0)
        button.Value:SetPoint("BOTTOMRIGHT", rightAnchor, "BOTTOMRIGHT", rightOffset, 4)
        button.Value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    else
        button.Label:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -7)
        button.Label:SetPoint("RIGHT", rightAnchor, rightPoint, rightOffset, 0)
        button.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")

        button.Value:SetPoint("TOPLEFT", button.Label, "BOTTOMLEFT", 0, -3)
        button.Value:SetPoint("BOTTOMRIGHT", rightAnchor, "BOTTOMRIGHT", rightOffset, 6)
        button.Value:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    end

    button.Label:SetText(slotLabel)
    button.IsSelfSlot = isSelfSlot == true
    if slotValue ~= "" then
        local assignedRoleKey = PlannerPrivate.GetEntryAssignedRole(slotEntry)
        local specRoleKey = slotEntry.specID and PlannerPrivate.GetRoleKeyFromSpecID(slotEntry.specID) or nil

        if roleLabel and specName and assignedRoleKey ~= nil and specRoleKey ~= nil and assignedRoleKey ~= specRoleKey then
            button.Value:SetText(string.format("%s (%s | %s)", slotValue, roleLabel, specName))
        elseif specName then
            button.Value:SetText(string.format("%s (%s)", slotValue, specName))
        elseif roleLabel then
            button.Value:SetText(string.format("%s (%s)", slotValue, roleLabel))
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
            local currentEntry = GetSlotEntry(button.Layout, button.Index, settings)
            if PlannerPrivate.IsWhisperSourceKey(currentEntry.sourceKey) then
                PlannerPrivate.RemoveWhisperApplicantByName(currentEntry.inviteName or currentEntry.name, true)
            end

            SetSlotEntry(button.Layout, button.Index, PlannerPrivate.NormalizeSlotEntry(nil))
            HideEditDialog()
            PlannerPrivate.lastDungeonSyncSignature = nil
            PlannerPrivate.SyncDynamicPlannerState(true)
            return
        end

        local forceSelfRoleEditor = false
        if button.Layout == "dungeon" then
            local currentEntry = GetSlotEntry(button.Layout, button.Index, settings)
            local slotInfo = GetDungeonSlotInfo and GetDungeonSlotInfo(button.Index) or nil
            local selfSlotKey = PlannerPrivate.GetAssignedSelfDungeonSlotKey()
            forceSelfRoleEditor = button.IsSelfSlot == true
                or PlannerPrivate.IsSelfSlotEntry(currentEntry)
                or (slotInfo and slotInfo.key ~= nil and selfSlotKey ~= nil and slotInfo.key == selfSlotKey)
        end

        OpenEditor(button.Layout, button.Index, forceSelfRoleEditor)
    end)
end

local function RefreshButtonList(buttons, refreshContext)
    for _, button in ipairs(buttons) do
        RefreshSlotButton(button, refreshContext)
    end
end

PlannerPrivate.CreateDungeonLayout = function(parent, targetButtons, width)
    local previousButton

    for index = 1, #StreamerPlannerModule.DUNGEON_LAYOUT do
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

PlannerPrivate.LayoutRaidLayout = function(parent, targetButtons, groupFrames, width, slotHeight)
    local groupWidth = width
    local resolvedSlotHeight = slotHeight or 30
    local groupHeight = GetRaidLayoutGroupHeight(resolvedSlotHeight)

    for groupIndex = 1, RAID_GROUP_COUNT do
        local groupFrame = groupFrames[groupIndex]
        if groupFrame then
            local rowIndex = math.floor((groupIndex - 1) / RAID_GROUP_COLUMNS)
            local columnIndex = (groupIndex - 1) % RAID_GROUP_COLUMNS

            groupFrame:SetSize(groupWidth, groupHeight)
            groupFrame:ClearAllPoints()
            groupFrame:SetPoint(
                "TOPLEFT",
                parent,
                "TOPLEFT",
                columnIndex * (groupWidth + RAID_GROUP_COLUMN_SPACING),
                -(rowIndex * (groupHeight + RAID_GROUP_ROW_SPACING))
            )

            if groupFrame.Title then
                groupFrame.Title:ClearAllPoints()
                groupFrame.Title:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, 0)
                groupFrame.Title:SetPoint("RIGHT", groupFrame, "RIGHT", 0, 0)
            end

            local previousButton
            for positionIndex = 1, RAID_GROUP_SIZE do
                local slotIndex = ((groupIndex - 1) * RAID_GROUP_SIZE) + positionIndex
                local button = targetButtons[slotIndex]
                if button then
                    button:SetSize(groupWidth, resolvedSlotHeight)
                    button.SlotHeight = resolvedSlotHeight
                    button:ClearAllPoints()

                    if previousButton then
                        button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -4)
                    else
                        button:SetPoint("TOPLEFT", groupFrame.Title, "BOTTOMLEFT", 0, -RAID_GROUP_TITLE_GAP)
                    end

                    previousButton = button
                end
            end
        end
    end
end

PlannerPrivate.CreateRaidLayout = function(parent, targetButtons, width, slotHeight)
    local groupFrames = {}

    for groupIndex = 1, RAID_GROUP_COUNT do
        local groupFrame = CreateFrame("Frame", nil, parent)

        local title = groupFrame:CreateFontString(nil, "OVERLAY")
        title:SetJustifyH("LEFT")
        title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        title:SetTextColor(1, 0.88, 0.62, 1)
        title:SetText(L("STREAMER_PLANNER_RAID_GROUP"):format(groupIndex))
        groupFrame.Title = title

        groupFrames[#groupFrames + 1] = groupFrame

        local previousButton
        for positionIndex = 1, RAID_GROUP_SIZE do
            local slotIndex = ((groupIndex - 1) * RAID_GROUP_SIZE) + positionIndex
            local button = CreateSlotButton(groupFrame, width, slotHeight or 30, "raid", slotIndex)

            targetButtons[#targetButtons + 1] = button
            previousButton = button
        end
    end

    PlannerPrivate.LayoutRaidLayout(parent, targetButtons, groupFrames, width, slotHeight)
    return groupFrames
end

PlannerPrivate.RefreshModeButtons = function()
    local mode = GetCurrentMode()
    local dungeonActive = mode == "dungeon"
    local raidActive = mode == "raid"
    local settingsPanel = PageStreamerPlanner and PageStreamerPlanner.SettingsPanel

    if settingsPanel and settingsPanel.DungeonModeButton then
        settingsPanel.DungeonModeButton:SetEnabled(not dungeonActive)
    end

    if settingsPanel and settingsPanel.RaidModeButton then
        settingsPanel.RaidModeButton:SetEnabled(not raidActive)
    end

    if OverlayFrame and OverlayFrame.DungeonModeButton then
        OverlayFrame.DungeonModeButton:SetEnabled(not dungeonActive)
    end

    if OverlayFrame and OverlayFrame.RaidModeButton then
        OverlayFrame.RaidModeButton:SetEnabled(not raidActive)
    end

    if OverlayFrame and OverlayFrame.DungeonModeButton and OverlayFrame.DungeonModeButton.Text then
        OverlayFrame.DungeonModeButton.Text:SetTextColor(dungeonActive and 1 or 0.82, dungeonActive and 0.82 or 0.82, dungeonActive and 0 or 0.82)
    end

    if OverlayFrame and OverlayFrame.RaidModeButton and OverlayFrame.RaidModeButton.Text then
        OverlayFrame.RaidModeButton.Text:SetTextColor(raidActive and 1 or 0.82, raidActive and 0.82 or 0.82, raidActive and 0 or 0.82)
    end
end

PlannerPrivate.RefreshLayoutVisibility = function()
    local mode = GetCurrentMode()
    local showRaid = mode == "raid"
    local destinationText = GetDestinationText()
    local overlayRaidGroupWidth = GetOverlayRaidGroupWidth()

    if PreviewUI.DungeonContainer then
        if showRaid then
            PreviewUI.DungeonContainer:Hide()
        else
            PreviewUI.DungeonContainer:Show()
        end
    end

    if PreviewUI.RaidContainer then
        if showRaid then
            PreviewUI.RaidContainer:Show()
        else
            PreviewUI.RaidContainer:Hide()
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

    if OverlayInviteRow then
        OverlayInviteRow:SetShown(showRaid)
    end

    if OverlayDestinationButton and OverlayDestinationButton.Label then
        OverlayDestinationButton.Label:SetText(L("STREAMER_PLANNER_DESTINATION"))
    end

    if OverlayFrame and OverlayFrame.RaidSummary then
        OverlayFrame.RaidSummary:ClearAllPoints()
        if OverlayTimer.Panel then
            OverlayFrame.RaidSummary:SetPoint("TOPLEFT", OverlayTimer.Panel, "BOTTOMLEFT", 0, -8)
        else
            OverlayFrame.RaidSummary:SetPoint("TOPLEFT", (showRaid and OverlayInviteRow) or OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
        end
        OverlayFrame.RaidSummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)

        if showRaid then
            OverlayFrame.RaidSummary:SetText(GetRaidSummaryText())
            OverlayFrame.RaidSummary:Show()
        else
            OverlayFrame.RaidSummary:Hide()
        end
    end

    if OverlayTimer.Panel then
        OverlayTimer.Panel:ClearAllPoints()
        if showRaid and OverlayInviteRow then
            OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayInviteRow, "BOTTOMLEFT", 0, -8)
        elseif OverlayFrame and OverlayFrame.ModeRow then
            OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -8)
        else
            OverlayTimer.Panel:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -10)
        end
    end

    if OverlayDestinationButton then
        OverlayDestinationButton:ClearAllPoints()
        if showRaid and OverlayFrame and OverlayFrame.RaidSummary then
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayFrame.RaidSummary, "BOTTOMLEFT", 0, -8)
        elseif OverlayTimer.Panel then
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayTimer.Panel, "BOTTOMLEFT", 0, -12)
        else
            OverlayDestinationButton:SetPoint("TOPLEFT", OverlayTitle, "BOTTOMLEFT", 0, -10)
        end
        OverlayDestinationButton:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
        OverlayDestinationButton:SetHeight(showRaid and OVERLAY_DESTINATION_HEIGHT_RAID or OVERLAY_DESTINATION_HEIGHT_DUNGEON)
    end

    if OverlayDestinationButton and OverlayDestinationButton.Value then
        if destinationText ~= "" then
            OverlayDestinationButton.Value:SetText(destinationText)
            OverlayDestinationButton.Value:SetTextColor(0.95, 0.91, 0.85, 1)
        else
            OverlayDestinationButton.Value:SetText(L("STREAMER_PLANNER_DESTINATION_EMPTY"))
            OverlayDestinationButton.Value:SetTextColor(0.62, 0.62, 0.66, 1)
        end

        OverlayDestinationButton.Value:SetWordWrap(showRaid)
    end

    if OverlayDungeonContainer and OverlayDestinationButton then
        OverlayDungeonContainer:ClearAllPoints()
        OverlayDungeonContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -12)
    end

    if OverlayRaidContainer and OverlayDestinationButton then
        OverlayRaidContainer:ClearAllPoints()
        OverlayRaidContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -12)
        OverlayRaidContainer:SetSize(
            GetRaidLayoutContainerWidth(overlayRaidGroupWidth),
            GetRaidLayoutContainerHeight(OVERLAY_RAID_SLOT_HEIGHT, 8)
        )
        if OverlayRaidGroupFrames then
            PlannerPrivate.LayoutRaidLayout(
                OverlayRaidContainer,
                OverlayRaidButtons,
                OverlayRaidGroupFrames,
                overlayRaidGroupWidth,
                OVERLAY_RAID_SLOT_HEIGHT
            )
        end
    end

    if OverlayFrame then
        if showRaid then
            OverlayFrame:SetSize(
                GetOverlayFrameWidthForMode("raid", overlayRaidGroupWidth),
                GetRaidLayoutContainerHeight(OVERLAY_RAID_SLOT_HEIGHT, 8) + OVERLAY_RAID_FRAME_BASE_HEIGHT
            )
        else
            OverlayFrame:SetSize(GetOverlayFrameWidthForMode("dungeon"), 540)
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
    PlannerPrivate.RefreshLayoutVisibility()
    RefreshTimerDisplay()

    if settings.overlayEnabled then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end

    if PlannerPrivate.UpdateWatcherPollingState then
        PlannerPrivate.UpdateWatcherPollingState()
    end
end

function StreamerPlannerModule.IsOverlayEnabled()
    return GetStreamerPlannerSettings().overlayEnabled == true
end

function StreamerPlannerModule.SetOverlayEnabled(enabled)
    GetStreamerPlannerSettings().overlayEnabled = enabled == true
    if enabled == true then
        PlannerPrivate.lastDungeonSyncSignature = nil
        PlannerPrivate.SyncDynamicPlannerState(true)
    end
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
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
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
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
end

function StreamerPlannerModule.ClearAllLayouts()
    ClearAllLayouts()
    HideEditDialog()
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
end

function StreamerPlannerModule.RefreshAllDisplays()
    local refreshContext = CreateRefreshContext()
    RefreshButtonList(PreviewUI.DungeonButtons, refreshContext)
    RefreshButtonList(PreviewUI.RaidButtons, refreshContext)
    RefreshButtonList(OverlayDungeonButtons, refreshContext)
    RefreshButtonList(OverlayRaidButtons, refreshContext)
    PlannerPrivate.RefreshModeButtons()
    if PlannerPrivate.RefreshApplicantPanel then
        PlannerPrivate.RefreshApplicantPanel()
    end
    if PlannerPrivate.RefreshWhisperSpecPrompt then
        PlannerPrivate.RefreshWhisperSpecPrompt()
    end
    StreamerPlannerModule.RefreshOverlayWindow()

    if PageStreamerPlanner and PageStreamerPlanner:IsShown() then
        PageStreamerPlanner:RefreshState()
    end
end

PlannerPrivate.RefreshDynamicDisplays = function(snapshot)
    local refreshContext = CreateRefreshContext()
    RefreshButtonList(PreviewUI.DungeonButtons, refreshContext)
    RefreshButtonList(PreviewUI.RaidButtons, refreshContext)
    RefreshButtonList(OverlayDungeonButtons, refreshContext)
    RefreshButtonList(OverlayRaidButtons, refreshContext)
    PlannerPrivate.RefreshModeButtons()
    if PlannerPrivate.RefreshApplicantPanel then
        PlannerPrivate.RefreshApplicantPanel(snapshot)
    end
    if PlannerPrivate.RefreshWhisperSpecPrompt then
        PlannerPrivate.RefreshWhisperSpecPrompt()
    end
    StreamerPlannerModule.RefreshOverlayWindow()

    if PageStreamerPlanner and PageStreamerPlanner:IsShown() then
        PageStreamerPlanner:UpdateScrollLayout()
    end
end

PlannerPrivate.BuildWhisperSpecPromptUi = function()
WhisperSpecPromptUI.Frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
WhisperSpecPromptUI.Frame:SetSize(WHISPER_SPEC_PROMPT_WIDTH, WHISPER_SPEC_PROMPT_MIN_HEIGHT)
WhisperSpecPromptUI.Frame:SetPoint("CENTER", UIParent, "CENTER", -440, 0)
WhisperSpecPromptUI.Frame:SetFrameStrata("DIALOG")
WhisperSpecPromptUI.Frame:SetClampedToScreen(true)
WhisperSpecPromptUI.Frame:EnableMouse(true)
WhisperSpecPromptUI.Frame:Hide()

do
    local background = WhisperSpecPromptUI.Frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.06, 0.06, 0.07, 0.96)

    local borderTop = WhisperSpecPromptUI.Frame:CreateTexture(nil, "ARTWORK")
    borderTop:SetPoint("TOPLEFT", WhisperSpecPromptUI.Frame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", WhisperSpecPromptUI.Frame, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.88, 0.72, 0.46, 0.36)

    local borderBottom = WhisperSpecPromptUI.Frame:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", WhisperSpecPromptUI.Frame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", WhisperSpecPromptUI.Frame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.86)
end

WhisperSpecPromptUI.Title = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.Title:SetPoint("TOPLEFT", WhisperSpecPromptUI.Frame, "TOPLEFT", 14, -12)
WhisperSpecPromptUI.Title:SetJustifyH("LEFT")
WhisperSpecPromptUI.Title:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
WhisperSpecPromptUI.Title:SetTextColor(1, 0.88, 0.62, 1)

WhisperSpecPromptUI.Hint = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.Hint:SetPoint("TOPLEFT", WhisperSpecPromptUI.Title, "BOTTOMLEFT", 0, -2)
WhisperSpecPromptUI.Hint:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Hint:SetJustifyH("LEFT")
WhisperSpecPromptUI.Hint:SetJustifyV("TOP")
WhisperSpecPromptUI.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WhisperSpecPromptUI.Hint:SetTextColor(0.82, 0.82, 0.84, 1)

WhisperSpecPromptUI.Name = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.Name:SetPoint("TOPLEFT", WhisperSpecPromptUI.Hint, "BOTTOMLEFT", 0, -6)
WhisperSpecPromptUI.Name:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Name:SetJustifyH("LEFT")
WhisperSpecPromptUI.Name:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")

WhisperSpecPromptUI.Class = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.Class:SetPoint("TOPLEFT", WhisperSpecPromptUI.Name, "BOTTOMLEFT", 0, -2)
WhisperSpecPromptUI.Class:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Class:SetJustifyH("LEFT")
WhisperSpecPromptUI.Class:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
WhisperSpecPromptUI.Class:SetTextColor(1, 0.82, 0, 0.92)

WhisperSpecPromptUI.ClassTitle = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.ClassTitle:SetJustifyH("LEFT")
WhisperSpecPromptUI.ClassTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
WhisperSpecPromptUI.ClassTitle:SetTextColor(1, 0.88, 0.62, 1)
WhisperSpecPromptUI.ClassTitle:Hide()

WhisperSpecPromptUI.Frame.ClassButtonAnchor = CreateFrame("Frame", nil, WhisperSpecPromptUI.Frame)
WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetPoint("TOPLEFT", WhisperSpecPromptUI.Name, "BOTTOMLEFT", 0, -10)
WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Frame.ClassButtonAnchor:SetHeight(1)

WhisperSpecPromptUI.RoleTitle = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.RoleTitle:SetPoint("TOPLEFT", WhisperSpecPromptUI.Class, "BOTTOMLEFT", 0, -14)
WhisperSpecPromptUI.RoleTitle:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.RoleTitle:SetJustifyH("LEFT")
WhisperSpecPromptUI.RoleTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
WhisperSpecPromptUI.RoleTitle:SetTextColor(1, 0.88, 0.62, 1)

WhisperSpecPromptUI.Frame.RoleButtonAnchor = CreateFrame("Frame", nil, WhisperSpecPromptUI.Frame)
WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetPoint("TOPLEFT", WhisperSpecPromptUI.Class, "BOTTOMLEFT", 0, -10)
WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Frame.RoleButtonAnchor:SetHeight(1)

WhisperSpecPromptUI.SpecTitle = WhisperSpecPromptUI.Frame:CreateFontString(nil, "OVERLAY")
WhisperSpecPromptUI.SpecTitle:SetJustifyH("LEFT")
WhisperSpecPromptUI.SpecTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
WhisperSpecPromptUI.SpecTitle:SetTextColor(1, 0.88, 0.62, 1)

WhisperSpecPromptUI.Frame.SpecButtonAnchor = CreateFrame("Frame", nil, WhisperSpecPromptUI.Frame)
WhisperSpecPromptUI.Frame.SpecButtonAnchor:SetPoint("TOPLEFT", WhisperSpecPromptUI.SpecTitle, "BOTTOMLEFT", 0, -8)
WhisperSpecPromptUI.Frame.SpecButtonAnchor:SetPoint("RIGHT", WhisperSpecPromptUI.Frame, "RIGHT", -16, 0)
WhisperSpecPromptUI.Frame.SpecButtonAnchor:SetHeight(1)

WhisperSpecPromptUI.Frame.ApplyButton = CreateActionButton(WhisperSpecPromptUI.Frame, 92, "", function()
    local targetName = WhisperSpecPromptUI.Frame.ActiveName
    if PlannerPrivate.IsUsablePlainString(targetName) then
        PlannerPrivate.ApplyWhisperPromptSelection(
            targetName,
            WhisperSpecPromptUI.SelectedClassFile,
            WhisperSpecPromptUI.SelectedRoleKey,
            WhisperSpecPromptUI.SelectedSpecID
        )
    end
end)
WhisperSpecPromptUI.Frame.ApplyButton:SetPoint("BOTTOMLEFT", WhisperSpecPromptUI.Frame, "BOTTOMLEFT", 16, 14)
WhisperSpecPromptUI.Frame.ApplyButton:Hide()

WhisperSpecPromptUI.Frame.LaterButton = CreateActionButton(WhisperSpecPromptUI.Frame, 92, "", function()
    PlannerPrivate.DismissActiveWhisperSpecPrompt()
    PlannerPrivate.RefreshWhisperSpecPrompt()
end)
WhisperSpecPromptUI.Frame.LaterButton:SetPoint("BOTTOMLEFT", WhisperSpecPromptUI.Frame, "BOTTOMLEFT", 16, 14)
WhisperSpecPromptUI.Frame.LaterButton:Hide()

WhisperSpecPromptUI.Frame.RemoveButton = CreateOverlayHeaderButton(WhisperSpecPromptUI.Frame, 20, "X", function()
    local targetName = WhisperSpecPromptUI.Frame.ActiveName
    if PlannerPrivate.IsUsablePlainString(targetName) then
        PlannerPrivate.DismissActiveWhisperSpecPrompt()
        PlannerPrivate.RemoveWhisperApplicantByName(targetName)
    end
end, L("EASY_LFG_DECLINE"), nil)
WhisperSpecPromptUI.Frame.RemoveButton:SetSize(20, 20)
WhisperSpecPromptUI.Frame.RemoveButton:SetPoint("TOPRIGHT", WhisperSpecPromptUI.Frame, "TOPRIGHT", -12, -11)

WhisperSpecPromptUI.Title:SetPoint("RIGHT", WhisperSpecPromptUI.Frame.RemoveButton, "LEFT", -8, 0)
end

PlannerPrivate.BuildStreamerPlannerOverlayUi = function()
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
    topLine:SetColorTexture(0.88, 0.72, 0.46, 0.70)

    local accent = OverlayFrame:CreateTexture(nil, "BACKGROUND")
    accent:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 9, -10)
    accent:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 9, 10)
    accent:SetWidth(2)
    accent:SetColorTexture(0.88, 0.72, 0.46, 0.18)
end

OverlayTitle = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlayTitle:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 18, -18)
OverlayTitle:SetJustifyH("LEFT")
OverlayTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
OverlayTitle:SetTextColor(1, 0.88, 0.62, 1)
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

OverlayFrame.DungeonModeButton = CreateModeButton(OverlayFrame, "", function()
    StreamerPlannerModule.SetMode("dungeon")
end)
OverlayFrame.DungeonModeButton:SetParent(OverlayFrame.ModeRow)
OverlayFrame.DungeonModeButton:SetSize(78, 22)
OverlayFrame.DungeonModeButton:SetPoint("TOPRIGHT", OverlayFrame.ModeRow, "TOPRIGHT", 0, 0)

OverlayFrame.RaidModeButton = CreateModeButton(OverlayFrame, "", function()
    StreamerPlannerModule.SetMode("raid")
end)
OverlayFrame.RaidModeButton:SetParent(OverlayFrame.ModeRow)
OverlayFrame.RaidModeButton:SetSize(78, 22)
OverlayFrame.RaidModeButton:SetPoint("RIGHT", OverlayFrame.DungeonModeButton, "LEFT", -6, 0)

OverlayInviteRow = CreateFrame("Frame", nil, OverlayFrame)
OverlayInviteRow:SetPoint("TOPLEFT", OverlayFrame.ModeRow, "BOTTOMLEFT", 0, -6)
OverlayInviteRow:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
OverlayInviteRow:SetHeight(24)

OverlayFullInviteButton = CreateActionButton(OverlayInviteRow, 88, "", function()
    PlannerPrivate.InviteAllApplicantRows(PlannerPrivate.BuildApplicantPanelRowData(), GetCurrentMode())
end)
OverlayFullInviteButton:SetPoint("RIGHT", OverlayInviteRow, "RIGHT", 0, 0)

OverlayAutoInviteCheckbox = CreateCheckbox(OverlayInviteRow, "", function(self)
    GetStreamerPlannerSettings().whisperCommandAutoInvite = self:GetChecked() == true
    if PlannerPrivate.UpdateWatcherPollingState then
        PlannerPrivate.UpdateWatcherPollingState()
    end
    PlannerPrivate.RefreshApplicantPanel()
end)
OverlayAutoInviteCheckbox:SetPoint("LEFT", OverlayInviteRow, "LEFT", -4, 0)
OverlayAutoInviteCheckbox.Label:ClearAllPoints()
OverlayAutoInviteCheckbox.Label:SetPoint("LEFT", OverlayAutoInviteCheckbox, "RIGHT", 4, 0)
OverlayAutoInviteCheckbox.Label:SetPoint("RIGHT", OverlayFullInviteButton, "LEFT", -8, 0)
OverlayAutoInviteCheckbox.Label:SetJustifyH("LEFT")

OverlayFrame.RaidSummary = OverlayFrame:CreateFontString(nil, "OVERLAY")
OverlayFrame.RaidSummary:SetPoint("TOPLEFT", OverlayInviteRow, "BOTTOMLEFT", 0, -8)
OverlayFrame.RaidSummary:SetPoint("RIGHT", OverlayFrame, "RIGHT", -18, 0)
OverlayFrame.RaidSummary:SetJustifyH("LEFT")
OverlayFrame.RaidSummary:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
OverlayFrame.RaidSummary:SetTextColor(0.92, 0.92, 0.92, 1)
OverlayFrame.RaidSummary:SetWordWrap(false)

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
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
end

OverlayDestinationButton.Label = OverlayDestinationButton:CreateFontString(nil, "OVERLAY")
OverlayDestinationButton.Label:SetPoint("TOPLEFT", OverlayDestinationButton, "TOPLEFT", 10, -5)
OverlayDestinationButton.Label:SetPoint("TOPRIGHT", OverlayDestinationButton, "TOPRIGHT", -10, -5)
OverlayDestinationButton.Label:SetJustifyH("LEFT")
OverlayDestinationButton.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
OverlayDestinationButton.Label:SetTextColor(1, 0.88, 0.62, 1)
OverlayDestinationButton.Label:SetWordWrap(false)

OverlayDestinationButton.Value = OverlayDestinationButton:CreateFontString(nil, "OVERLAY")
OverlayDestinationButton.Value:SetPoint("TOPLEFT", OverlayDestinationButton.Label, "BOTTOMLEFT", 0, -2)
OverlayDestinationButton.Value:SetPoint("BOTTOMRIGHT", OverlayDestinationButton, "BOTTOMRIGHT", -10, 7)
OverlayDestinationButton.Value:SetJustifyH("LEFT")
OverlayDestinationButton.Value:SetJustifyV("TOP")
OverlayDestinationButton.Value:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
OverlayDestinationButton.Value:SetWordWrap(true)

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
OverlayDungeonContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -12)
OverlayDungeonContainer:SetSize(294, 260)
OverlayDungeonContainer:SetClipsChildren(true)
PlannerPrivate.CreateDungeonLayout(OverlayDungeonContainer, OverlayDungeonButtons, 294)

OverlayRaidContainer = CreateFrame("Frame", nil, OverlayFrame)
OverlayRaidContainer:SetPoint("TOPLEFT", OverlayDestinationButton, "BOTTOMLEFT", 0, -12)
OverlayRaidContainer:SetSize(GetRaidLayoutContainerWidth(GetOverlayRaidGroupWidth()), GetRaidLayoutContainerHeight(OVERLAY_RAID_SLOT_HEIGHT, 8))
OverlayRaidContainer:SetClipsChildren(true)
OverlayRaidGroupFrames = PlannerPrivate.CreateRaidLayout(OverlayRaidContainer, OverlayRaidButtons, GetOverlayRaidGroupWidth(), OVERLAY_RAID_SLOT_HEIGHT)

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
    border:SetColorTexture(0.88, 0.72, 0.46, 0.34)
end

OverlayTimer.Label = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Label:SetPoint("TOPLEFT", OverlayTimer.Panel, "TOPLEFT", 10, -5)
OverlayTimer.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
OverlayTimer.Label:SetTextColor(1, 0.88, 0.62, 1)

OverlayTimer.Status = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Status:SetPoint("RIGHT", OverlayTimer.Panel, "RIGHT", -10, 0)
OverlayTimer.Status:SetPoint("TOP", OverlayTimer.Panel, "TOP", 0, -5)
OverlayTimer.Status:SetJustifyH("RIGHT")
OverlayTimer.Status:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
OverlayTimer.Status:SetTextColor(0.76, 0.76, 0.80, 1)

OverlayTimer.Value = OverlayTimer.Panel:CreateFontString(nil, "OVERLAY")
OverlayTimer.Value:SetPoint("TOPLEFT", OverlayTimer.Label, "BOTTOMLEFT", 0, -4)
OverlayTimer.Value:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
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

local function HandleStreamerPlannerOverlayUpdate(_, elapsed)
    if not OverlayFrame:IsShown() then
        return
    end

    local settings = GetStreamerPlannerSettings()
    if settings.timerRunning ~= true then
        PlannerPrivate.timerRefreshElapsed = 0
        return
    end

    PlannerPrivate.timerRefreshElapsed = PlannerPrivate.timerRefreshElapsed + (elapsed or 0)
    if PlannerPrivate.timerRefreshElapsed < 0.2 then
        return
    end

    PlannerPrivate.timerRefreshElapsed = 0
    RefreshTimerDisplay()
end

OverlayFrame:SetScript("OnUpdate", function(_, elapsed)
    local profiler = BeavisQoL.PerformanceProfiler
    local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
    HandleStreamerPlannerOverlayUpdate(_, elapsed)
    if profiler and profiler.EndSample then
        profiler.EndSample("StreamerPlanner.OverlayOnUpdate", sampleToken)
    end
end)

OverlayFrame:Hide()
ApplyOverlayGeometry()
end

PlannerPrivate.BuildStreamerPlannerEditDialogUi = function()
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
    border:SetColorTexture(0.88, 0.72, 0.46, 0.82)
end

EditDialog.Title = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialog.Title:SetPoint("TOPLEFT", EditDialog, "TOPLEFT", 16, -14)
EditDialog.Title:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialog.Title:SetJustifyH("LEFT")
EditDialog.Title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
EditDialog.Title:SetTextColor(1, 0.88, 0.62, 1)

EditDialog.Hint = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialog.Hint:SetPoint("TOPLEFT", EditDialog.Title, "BOTTOMLEFT", 0, -8)
EditDialog.Hint:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialog.Hint:SetJustifyH("LEFT")
EditDialog.Hint:SetJustifyV("TOP")
EditDialog.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EditDialog.Hint:SetTextColor(0.82, 0.82, 0.86, 1)

EditDialogInput = CreateFrame("EditBox", nil, EditDialog, "InputBoxTemplate")
EditDialogInput:SetSize(484, 28)
EditDialogInput:SetPoint("TOPLEFT", EditDialog.Hint, "BOTTOMLEFT", 0, -12)
EditDialogInput:SetAutoFocus(false)
EditDialogInput:SetMaxLetters(64)

EditDialogTargetLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialogTargetLabel:SetPoint("BOTTOMLEFT", EditDialogInput, "TOPLEFT", 0, 8)
EditDialogTargetLabel:SetPoint("RIGHT", EditDialog, "RIGHT", -16, 0)
EditDialogTargetLabel:SetJustifyH("LEFT")
EditDialogTargetLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EditDialogTargetLabel:SetTextColor(0.78, 0.78, 0.82, 1)

EditDialog.RoleTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditDialog.RoleTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
EditDialog.RoleTitle:SetTextColor(1, 0.88, 0.62, 1)
EditDialog.RoleTitle:Hide()

do
    local roleButtons = {
        { key = false, label = L("STREAMER_PLANNER_ROLE_AUTO") },
        { key = "tank", label = L("STREAMER_PLANNER_ROLE_TANK") },
        { key = "healer", label = L("STREAMER_PLANNER_ROLE_HEALER") },
        { key = "dps", label = "DPS" },
    }

    for _, roleInfo in ipairs(roleButtons) do
        local button = CreateActionButton(EditDialog, 124, roleInfo.label, function(self)
            PlannerPrivate.editingRoleKey = PlannerPrivate.NormalizePlannerRoleKey(self.RoleKey)
            RefreshClassSpecButtons()
        end)
        button.RoleKey = roleInfo.key
        button.Label = button:GetFontString()
        button.Selected = button:CreateTexture(nil, "BORDER")
        button.Selected:SetAllPoints()
        button.Selected:SetColorTexture(0.88, 0.72, 0.46, 0.18)
        button.Selected:Hide()
        button:Hide()
        PlannerPrivate.editRoleButtons[#PlannerPrivate.editRoleButtons + 1] = button
    end
end

EditDestinationCategoryLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationCategoryLabel:SetPoint("TOPLEFT", EditDialog.Hint, "BOTTOMLEFT", 0, -16)
EditDestinationCategoryLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EditDestinationCategoryLabel:SetTextColor(0.92, 0.92, 0.92, 1)

EditDestinationSuggestionLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationSuggestionLabel:SetPoint("TOPLEFT", EditDestinationCategoryLabel, "BOTTOMLEFT", 0, -38)
EditDestinationSuggestionLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EditDestinationSuggestionLabel:SetTextColor(0.92, 0.92, 0.92, 1)

EditDestinationKeystoneLabel = EditDialog:CreateFontString(nil, "OVERLAY")
EditDestinationKeystoneLabel:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "BOTTOMLEFT", 0, -38)
EditDestinationKeystoneLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
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
    local currentSuggestion = PlannerPrivate.FindDestinationSuggestion(categoryKey, GetDestinationBaseText())

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
    local categoryKey = GetDestinationCategory()
    local currentLevel = GetDestinationKeystoneLevel()
    if categoryKey == "raids" then
        currentLevel = PlannerPrivate.NormalizeRaidDifficultyKey(currentLevel) or "normal"
    elseif type(currentLevel) ~= "number" then
        currentLevel = categoryKey == "delves" and 1 or 0
    end

    if categoryKey == "raids" then
        for _, difficultyInfo in ipairs(RAID_DIFFICULTY_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L(difficultyInfo.labelKey)
            info.value = difficultyInfo.key
            info.checked = currentLevel == difficultyInfo.key
            info.func = function()
                SetDestinationKeystoneLevel(difficultyInfo.key)
                RefreshDestinationKeystoneDropdown()
                StreamerPlannerModule.RefreshAllDisplays()
            end
            UIDropDownMenu_AddButton(info, level)
        end
        return
    end

    if categoryKey == "delves" then
        for delveLevel = 1, 11 do
            local info = UIDropDownMenu_CreateInfo()
            info.text = PlannerPrivate.GetDestinationLevelLabel(categoryKey, delveLevel)
            info.value = delveLevel
            info.checked = currentLevel == delveLevel
            info.func = function()
                SetDestinationKeystoneLevel(delveLevel)
                RefreshDestinationKeystoneDropdown()
                StreamerPlannerModule.RefreshAllDisplays()
            end
            UIDropDownMenu_AddButton(info, level)
        end
        return
    end

    for keystoneLevel = 0, 20 do
        if keystoneLevel ~= 1 then
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
    end
end)

DestinationInput = CreateFrame("EditBox", nil, EditDialog, "InputBoxTemplate")
DestinationInput:SetSize(484, 28)
DestinationInput:SetPoint("TOPLEFT", EditDestinationSuggestionLabel, "BOTTOMLEFT", 0, -20)
DestinationInput:SetAutoFocus(false)
DestinationInput:SetMaxLetters(64)
DestinationInput:SetScript("OnTextChanged", function()
    if PlannerPrivate.editingField ~= "destination" then
        return
    end

    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
end)
DestinationInput:SetScript("OnEnterPressed", function()
    if PlannerPrivate.saveSlotButton then
        PlannerPrivate.saveSlotButton:Click()
    end
end)
DestinationInput:SetScript("OnEscapePressed", function(self)
    self:SetText(GetDestinationBaseText())
    HideEditDialog()
end)

EditClassTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditClassTitle:SetPoint("TOPLEFT", EditDialogInput, "BOTTOMLEFT", 0, -18)
EditClassTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
EditClassTitle:SetTextColor(1, 0.88, 0.62, 1)

local classOptions = BuildClassOptions()
for _, classInfo in ipairs(classOptions or {}) do
    if classInfo.file ~= nil then
        local button = CreateIconPickerButton(EditDialog, EDIT_CLASS_BUTTON_SIZE, false)
        button.ClassFile = classInfo.file
        button.DisplayName = classInfo.name
        button.Icon:SetTexture(CLASS_ICON_TEXTURE)
        button.Icon:SetTexCoord(GetClassIconCoords(classInfo.file))
        button.Label:SetText(classInfo.name)
        button:SetScript("OnClick", function(self)
            PlannerPrivate.editingClassFile = self.ClassFile
            PlannerPrivate.editingSpecID = nil
            RefreshClassSpecButtons()
        end)
        PlannerPrivate.editClassButtons[#PlannerPrivate.editClassButtons + 1] = button
    end
end

EditSpecTitle = EditDialog:CreateFontString(nil, "OVERLAY")
EditSpecTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
EditSpecTitle:SetTextColor(1, 0.88, 0.62, 1)

for _ = 1, 4 do
    local button = CreateIconPickerButton(EditDialog, EDIT_SPEC_BUTTON_SIZE, false)
    button.DisplayName = ""
    button:SetScript("OnClick", function(self)
        PlannerPrivate.editingSpecID = self.SpecID
        RefreshClassSpecButtons()
    end)
    PlannerPrivate.editSpecButtons[#PlannerPrivate.editSpecButtons + 1] = button
end

LayoutEditDialogOptionButtons()

PlannerPrivate.saveSlotButton = CreateActionButton(EditDialog, 92, "", function()
    if PlannerPrivate.editingField == "destination" then
        SetDestinationText(DestinationInput:GetText())
        HideEditDialog()
        StreamerPlannerModule.RefreshAllDisplays()
        return
    end

    if PlannerPrivate.editingUsesSelfRoleOverride == true then
        GetStreamerPlannerSettings().selfRoleOverride = PlannerPrivate.NormalizePlannerRoleKey(PlannerPrivate.editingRoleKey)
        HideEditDialog()
        PlannerPrivate.lastDungeonSyncSignature = nil
        PlannerPrivate.SyncDynamicPlannerState(true)
        return
    end

    if not PlannerPrivate.editingLayout or not PlannerPrivate.editingSlotIndex then
        HideEditDialog()
        return
    end

    local currentEntry = GetSlotEntry(PlannerPrivate.editingLayout, PlannerPrivate.editingSlotIndex)
    if PlannerPrivate.IsWhisperSourceKey(currentEntry.sourceKey) then
        PlannerPrivate.RemoveWhisperApplicantByName(currentEntry.inviteName or currentEntry.name, true)
    end

    SetSlotEntry(PlannerPrivate.editingLayout, PlannerPrivate.editingSlotIndex, {
        name = EditDialogInput:GetText(),
        classFile = PlannerPrivate.editingClassFile,
        specID = PlannerPrivate.editingSpecID,
    })
    HideEditDialog()
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
end)
PlannerPrivate.saveSlotButton:SetPoint("BOTTOMLEFT", EditDialog, "BOTTOMLEFT", 16, 20)

PlannerPrivate.clearSlotButton = CreateActionButton(EditDialog, 92, "", function()
    if PlannerPrivate.editingField == "destination" then
        SetDestinationText("")
        HideEditDialog()
        StreamerPlannerModule.RefreshAllDisplays()
        return
    end

    if PlannerPrivate.editingUsesSelfRoleOverride == true then
        GetStreamerPlannerSettings().selfRoleOverride = nil
        HideEditDialog()
        PlannerPrivate.lastDungeonSyncSignature = nil
        PlannerPrivate.SyncDynamicPlannerState(true)
        return
    end

    if PlannerPrivate.editingLayout and PlannerPrivate.editingSlotIndex then
        local currentEntry = GetSlotEntry(PlannerPrivate.editingLayout, PlannerPrivate.editingSlotIndex)
        if PlannerPrivate.IsWhisperSourceKey(currentEntry.sourceKey) then
            PlannerPrivate.RemoveWhisperApplicantByName(currentEntry.inviteName or currentEntry.name, true)
        end

        SetSlotEntry(PlannerPrivate.editingLayout, PlannerPrivate.editingSlotIndex, PlannerPrivate.NormalizeSlotEntry(nil))
    end

    HideEditDialog()
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
end)
PlannerPrivate.clearSlotButton:SetPoint("LEFT", PlannerPrivate.saveSlotButton, "RIGHT", 10, 0)

PlannerPrivate.cancelSlotButton = CreateActionButton(EditDialog, 92, L("CANCEL"), function()
    HideEditDialog()
end)
PlannerPrivate.cancelSlotButton:SetPoint("LEFT", PlannerPrivate.clearSlotButton, "RIGHT", 10, 0)

EditDialogInput:SetScript("OnEnterPressed", function()
    PlannerPrivate.saveSlotButton:Click()
end)
EditDialogInput:SetScript("OnEscapePressed", function()
    HideEditDialog()
end)
end

PlannerPrivate.BuildStreamerPlannerUi = function()
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

do
local IntroPanel = CreateFrame("Frame", nil, PageContentFrame)
IntroPanel:SetPoint("TOPLEFT", PageContentFrame, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageContentFrame, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(132)
PageStreamerPlanner.IntroPanel = IntroPanel

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
PageStreamerPlanner.IntroTitle = IntroTitle

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
PageStreamerPlanner.IntroText = IntroText

local UsageHint = IntroPanel:CreateFontString(nil, "OVERLAY")
UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -10)
UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
UsageHint:SetJustifyH("LEFT")
UsageHint:SetJustifyV("TOP")
UsageHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
UsageHint:SetTextColor(0.84, 0.84, 0.86, 1)
PageStreamerPlanner.UsageHint = UsageHint

local PreviewPanel = CreateFrame("Frame", nil, PageContentFrame)
PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
PreviewPanel:SetSize(GetPreviewPanelWidthForMode("raid"), 424)
PageStreamerPlanner.PreviewPanel = PreviewPanel

local PreviewPanelBg = PreviewPanel:CreateTexture(nil, "BACKGROUND")
PreviewPanelBg:SetAllPoints()
PreviewPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local PreviewPanelBorder = PreviewPanel:CreateTexture(nil, "ARTWORK")
PreviewPanelBorder:SetPoint("BOTTOMLEFT", PreviewPanel, "BOTTOMLEFT", 0, 0)
PreviewPanelBorder:SetPoint("BOTTOMRIGHT", PreviewPanel, "BOTTOMRIGHT", 0, 0)
PreviewPanelBorder:SetHeight(1)
PreviewPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

PreviewUI.Title = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewUI.Title:SetPoint("TOPLEFT", PreviewPanel, "TOPLEFT", 18, -14)
PreviewUI.Title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
PreviewUI.Title:SetTextColor(1, 0.88, 0.62, 1)

PreviewUI.Hint = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewUI.Hint:SetPoint("TOPLEFT", PreviewUI.Title, "BOTTOMLEFT", 0, -8)
PreviewUI.Hint:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewUI.Hint:SetJustifyH("LEFT")
PreviewUI.Hint:SetJustifyV("TOP")
PreviewUI.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
PreviewUI.Hint:SetTextColor(0.78, 0.74, 0.69, 1)

PreviewUI.DungeonContainer = CreateFrame("Frame", nil, PreviewPanel)
PreviewUI.DungeonContainer:SetPoint("TOPLEFT", PreviewUI.Hint, "BOTTOMLEFT", 0, -18)
PreviewUI.DungeonContainer:SetSize(392, 280)
PreviewUI.DungeonContainer:SetClipsChildren(true)
PlannerPrivate.CreateDungeonLayout(PreviewUI.DungeonContainer, PreviewUI.DungeonButtons, 392)

PreviewUI.RaidContainer = CreateFrame("Frame", nil, PreviewPanel)
PreviewUI.RaidContainer:SetPoint("TOPLEFT", PreviewUI.Hint, "BOTTOMLEFT", 0, -18)
PreviewUI.RaidContainer:SetSize(GetRaidLayoutContainerWidth(PREVIEW_RAID_GROUP_WIDTH), GetRaidLayoutContainerHeight(PREVIEW_RAID_SLOT_HEIGHT, 4))
PreviewUI.RaidContainer:SetClipsChildren(true)
PreviewUI.RaidGroupFrames = PlannerPrivate.CreateRaidLayout(PreviewUI.RaidContainer, PreviewUI.RaidButtons, PREVIEW_RAID_GROUP_WIDTH, PREVIEW_RAID_SLOT_HEIGHT)

PreviewPanel:SetClipsChildren(true)
local SettingsPanel = CreateFrame("Frame", nil, PageContentFrame)
SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", 18, 0)
SettingsPanel:SetPoint("TOPRIGHT", PageContentFrame, "TOPRIGHT", -20, 0)
SettingsPanel:SetHeight(PreviewPanel:GetHeight())
PageStreamerPlanner.SettingsPanel = SettingsPanel

local SettingsPanelBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsPanelBg:SetAllPoints()
SettingsPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local SettingsPanelBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsPanelBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsPanelBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsPanelBorder:SetHeight(1)
SettingsPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

SettingsPanel.Title = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.Title:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsPanel.Title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsPanel.Title:SetTextColor(1, 0.88, 0.62, 1)

SettingsPanel.Hint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.Hint:SetPoint("TOPLEFT", SettingsPanel.Title, "BOTTOMLEFT", 0, -8)
SettingsPanel.Hint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.Hint:SetJustifyH("LEFT")
SettingsPanel.Hint:SetJustifyV("TOP")
SettingsPanel.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.Hint:SetTextColor(0.78, 0.74, 0.69, 1)

SettingsPanel.ShowOverlayCheckbox = CreateCheckbox(SettingsPanel, "", function(self)
    StreamerPlannerModule.SetOverlayEnabled(self:GetChecked())
    PageStreamerPlanner:RefreshState()
end)
SettingsPanel.ShowOverlayCheckbox:SetPoint("TOPLEFT", SettingsPanel.Hint, "BOTTOMLEFT", -4, -18)

SettingsPanel.ShowOverlayHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ShowOverlayHint:SetPoint("TOPLEFT", SettingsPanel.ShowOverlayCheckbox, "BOTTOMLEFT", 34, -2)
SettingsPanel.ShowOverlayHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ShowOverlayHint:SetJustifyH("LEFT")
SettingsPanel.ShowOverlayHint:SetJustifyV("TOP")
SettingsPanel.ShowOverlayHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.ShowOverlayHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.LockOverlayCheckbox = CreateCheckbox(SettingsPanel, "", function(self)
    StreamerPlannerModule.SetOverlayLocked(self:GetChecked())
end)
SettingsPanel.LockOverlayCheckbox:SetPoint("TOPLEFT", SettingsPanel.ShowOverlayHint, "BOTTOMLEFT", -34, -14)

SettingsPanel.LockOverlayHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.LockOverlayHint:SetPoint("TOPLEFT", SettingsPanel.LockOverlayCheckbox, "BOTTOMLEFT", 34, -2)
SettingsPanel.LockOverlayHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.LockOverlayHint:SetJustifyH("LEFT")
SettingsPanel.LockOverlayHint:SetJustifyV("TOP")
SettingsPanel.LockOverlayHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.LockOverlayHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.ModeTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ModeTitle:SetPoint("TOPLEFT", SettingsPanel.LockOverlayHint, "BOTTOMLEFT", 0, -22)
SettingsPanel.ModeTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsPanel.ModeTitle:SetTextColor(1, 0.88, 0.62, 1)

SettingsPanel.ModeHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.ModeHint:SetPoint("TOPLEFT", SettingsPanel.ModeTitle, "BOTTOMLEFT", 0, -6)
SettingsPanel.ModeHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.ModeHint:SetJustifyH("LEFT")
SettingsPanel.ModeHint:SetJustifyV("TOP")
SettingsPanel.ModeHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.ModeHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.DungeonModeButton = CreateModeButton(SettingsPanel, "", function()
    StreamerPlannerModule.SetMode("dungeon")
end)
SettingsPanel.DungeonModeButton:SetPoint("TOPLEFT", SettingsPanel.ModeHint, "BOTTOMLEFT", 0, -14)

SettingsPanel.RaidModeButton = CreateModeButton(SettingsPanel, "", function()
    StreamerPlannerModule.SetMode("raid")
end)
SettingsPanel.RaidModeButton:SetPoint("LEFT", SettingsPanel.DungeonModeButton, "RIGHT", 12, 0)

ScaleSlider = CreateScaleSlider(SettingsPanel, "Scale")
ScaleSlider:SetPoint("TOPLEFT", SettingsPanel.DungeonModeButton, "BOTTOMLEFT", 18, -28)
ScaleSlider:SetScript("OnValueChanged", function(self, value)
    if PlannerPrivate.isRefreshingPage then
        return
    end

    StreamerPlannerModule.SetOverlayScale(value)
    RefreshScaleSliderText()
end)

TimerDurationSlider = CreateScaleSlider(SettingsPanel, "TimerDuration")
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
    if PlannerPrivate.isRefreshingPage then
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
SettingsPanel.ScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.ScaleHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.TimerDurationHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.TimerDurationHint:SetPoint("TOPLEFT", TimerDurationSlider, "BOTTOMLEFT", -2, -12)
SettingsPanel.TimerDurationHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.TimerDurationHint:SetJustifyH("LEFT")
SettingsPanel.TimerDurationHint:SetJustifyV("TOP")
SettingsPanel.TimerDurationHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
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
SettingsPanel.ResetPositionHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
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
SettingsPanel.ClearLayoutHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
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
SettingsPanel.ClearAllHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.ClearAllHint:SetTextColor(0.74, 0.74, 0.74, 1)

SettingsPanel.EditHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsPanel.EditHint:SetPoint("TOPLEFT", SettingsPanel.ClearAllHint, "BOTTOMLEFT", 0, -18)
SettingsPanel.EditHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsPanel.EditHint:SetJustifyH("LEFT")
SettingsPanel.EditHint:SetJustifyV("TOP")
SettingsPanel.EditHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsPanel.EditHint:SetTextColor(0.84, 0.84, 0.86, 1)
end

ApplicantPanel = CreateFrame("Frame", nil, PageContentFrame)
ApplicantPanel:SetPoint("TOPLEFT", PageStreamerPlanner.PreviewPanel, "BOTTOMLEFT", 0, -18)
ApplicantPanel:SetPoint("TOPRIGHT", PageStreamerPlanner.SettingsPanel, "BOTTOMRIGHT", 0, -18)
ApplicantPanel:SetHeight(116)

do
    local background = ApplicantPanel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.1, 0.068, 0.046, 0.94)

    local border = ApplicantPanel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", ApplicantPanel, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", ApplicantPanel, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.82)
end

ApplicantPanel.Title = ApplicantPanel:CreateFontString(nil, "OVERLAY")
ApplicantPanel.Title:SetPoint("TOPLEFT", ApplicantPanel, "TOPLEFT", 18, -14)
ApplicantPanel.Title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
ApplicantPanel.Title:SetTextColor(1, 0.88, 0.62, 1)

ApplicantPanel.FullInviteButton = CreateActionButton(ApplicantPanel, 92, "", function()
    PlannerPrivate.InviteAllApplicantRows(PlannerPrivate.BuildApplicantPanelRowData(), GetCurrentMode())
end)
ApplicantPanel.FullInviteButton:SetPoint("TOPRIGHT", ApplicantPanel, "TOPRIGHT", -18, -12)

ApplicantPanel.Title:SetPoint("RIGHT", ApplicantPanel.FullInviteButton, "LEFT", -12, 0)

ApplicantPanel.Hint = ApplicantPanel:CreateFontString(nil, "OVERLAY")
ApplicantPanel.Hint:SetPoint("TOPLEFT", ApplicantPanel.Title, "BOTTOMLEFT", 0, -8)
ApplicantPanel.Hint:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -18, 0)
ApplicantPanel.Hint:SetJustifyH("LEFT")
ApplicantPanel.Hint:SetJustifyV("TOP")
ApplicantPanel.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ApplicantPanel.Hint:SetTextColor(0.78, 0.74, 0.69, 1)

ApplicantPanel.AutoInviteCheckbox = CreateCheckbox(ApplicantPanel, "", function(self)
    GetStreamerPlannerSettings().whisperCommandAutoInvite = self:GetChecked() == true
    if PlannerPrivate.UpdateWatcherPollingState then
        PlannerPrivate.UpdateWatcherPollingState()
    end
end)
ApplicantPanel.AutoInviteCheckbox:SetPoint("TOPLEFT", ApplicantPanel.Hint, "BOTTOMLEFT", 0, -10)
ApplicantPanel.AutoInviteCheckbox.Label:ClearAllPoints()
ApplicantPanel.AutoInviteCheckbox.Label:SetPoint("LEFT", ApplicantPanel.AutoInviteCheckbox, "RIGHT", 4, 0)
ApplicantPanel.AutoInviteCheckbox.Label:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -18, 0)
ApplicantPanel.AutoInviteCheckbox.Label:SetJustifyH("LEFT")

ApplicantPanel.RowAnchor = CreateFrame("Frame", nil, ApplicantPanel)
ApplicantPanel.RowAnchor:SetPoint("TOPLEFT", ApplicantPanel.AutoInviteCheckbox, "BOTTOMLEFT", 0, -10)
ApplicantPanel.RowAnchor:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -14, 0)
ApplicantPanel.RowAnchor:SetHeight(1)

ApplicantPanel.EmptyText = ApplicantPanel:CreateFontString(nil, "OVERLAY")
ApplicantPanel.EmptyText:SetPoint("TOPLEFT", ApplicantPanel.RowAnchor, "TOPLEFT", 0, 0)
ApplicantPanel.EmptyText:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -18, 0)
ApplicantPanel.EmptyText:SetJustifyH("LEFT")
ApplicantPanel.EmptyText:SetJustifyV("TOP")
ApplicantPanel.EmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ApplicantPanel.EmptyText:SetTextColor(0.82, 0.82, 0.84, 1)

ApplicantPanel.MoreText = ApplicantPanel:CreateFontString(nil, "OVERLAY")
ApplicantPanel.MoreText:SetPoint("BOTTOMLEFT", ApplicantPanel, "BOTTOMLEFT", 18, 10)
ApplicantPanel.MoreText:SetPoint("RIGHT", ApplicantPanel, "RIGHT", -18, 0)
ApplicantPanel.MoreText:SetJustifyH("LEFT")
ApplicantPanel.MoreText:SetJustifyV("TOP")
ApplicantPanel.MoreText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ApplicantPanel.MoreText:SetTextColor(0.78, 0.78, 0.80, 1)
ApplicantPanel.MoreText:Hide()

PlannerPrivate.BuildWhisperSpecPromptUi()
PlannerPrivate.BuildStreamerPlannerOverlayUi()
PlannerPrivate.BuildStreamerPlannerEditDialogUi()
end

PlannerPrivate.BuildStreamerPlannerUi()

function PageStreamerPlanner:RefreshState()
    local settings = GetStreamerPlannerSettings()
    local refreshContext = CreateRefreshContext(settings)
    local introTitle = self.IntroTitle
    local introText = self.IntroText
    local usageHint = self.UsageHint
    local settingsPanel = self.SettingsPanel

    introTitle:SetText(BeavisQoL.GetModulePageTitle("StreamerPlanner", L("STREAMER_PLANNER_TITLE")))
    introText:SetText(L("STREAMER_PLANNER_DESC"))
    usageHint:SetText(L("STREAMER_PLANNER_USAGE_HINT"))
    PreviewUI.Title:SetText(L("LIVE_PREVIEW"))
    PreviewUI.Hint:SetText(L("STREAMER_PLANNER_PREVIEW_HINT"))
    settingsPanel.Title:SetText(L("STREAMER_TOOLS"))
    settingsPanel.Hint:SetText(L("STREAMER_PLANNER_SETTINGS_HINT"))
    settingsPanel.ShowOverlayCheckbox.Label:SetText(L("STREAMER_PLANNER_SHOW_OVERLAY"))
    settingsPanel.ShowOverlayHint:SetText(L("STREAMER_PLANNER_SHOW_OVERLAY_HINT"))
    settingsPanel.LockOverlayCheckbox.Label:SetText(L("STREAMER_PLANNER_LOCK_OVERLAY"))
    settingsPanel.LockOverlayHint:SetText(L("STREAMER_PLANNER_LOCK_OVERLAY_HINT"))
    settingsPanel.ModeTitle:SetText(L("STREAMER_PLANNER_MODE"))
    settingsPanel.ModeHint:SetText(L("STREAMER_PLANNER_MODE_HINT"))
    settingsPanel.DungeonModeButton:SetText(L("STREAMER_PLANNER_MODE_DUNGEON"))
    settingsPanel.RaidModeButton:SetText(L("STREAMER_PLANNER_MODE_RAID"))
    EditDestinationCategoryLabel:SetText(L("STREAMER_PLANNER_DESTINATION_CATEGORY"))
    EditDestinationSuggestionLabel:SetText(L("STREAMER_PLANNER_DESTINATION_SUGGESTION"))
    EditDestinationKeystoneLabel:SetText(L("STREAMER_PLANNER_DESTINATION_KEYSTONE"))
    settingsPanel.ScaleHint:SetText(L("STREAMER_PLANNER_SCALE_HINT"))
    settingsPanel.TimerDurationHint:SetText(L("STREAMER_PLANNER_TIMER_DURATION_HINT"))
    settingsPanel.ResetPositionButton:SetText(L("RESET_POSITION"))
    settingsPanel.ResetPositionHint:SetText(L("STREAMER_PLANNER_RESET_POSITION_HINT"))
    settingsPanel.ClearLayoutButton:SetText(L("STREAMER_PLANNER_CLEAR_LAYOUT"))
    settingsPanel.ClearLayoutHint:SetText(L("STREAMER_PLANNER_CLEAR_LAYOUT_HINT"))
    settingsPanel.ClearAllButton:SetText(L("STREAMER_PLANNER_CLEAR_ALL"))
    settingsPanel.ClearAllHint:SetText(L("STREAMER_PLANNER_CLEAR_ALL_HINT"))
    settingsPanel.EditHint:SetText(L("STREAMER_PLANNER_EDIT_HINT"))
    OverlayTitle:SetText(L("STREAMER_PLANNER_OVERLAY_TITLE"))
    OverlayFrame.DungeonModeButton:SetText(L("STREAMER_PLANNER_MODE_DUNGEON"))
    OverlayFrame.RaidModeButton:SetText(L("STREAMER_PLANNER_MODE_RAID"))
    OverlayFrame.SettingsButton.Label:SetText(L("STREAMER_PLANNER_OVERLAY_SETTINGS_BUTTON"))
    if OverlayFullInviteButton then
        OverlayFullInviteButton:SetText(L("STREAMER_PLANNER_FULL_INVITE"))
    end
    if OverlayAutoInviteCheckbox then
        OverlayAutoInviteCheckbox.Label:SetText(L("STREAMER_PLANNER_AUTO_INVITE_WHISPER"))
        OverlayAutoInviteCheckbox:SetChecked(settings.whisperCommandAutoInvite == true)
    end
    OverlayTimer.Label:SetText(L("STREAMER_PLANNER_TIMER"))
    OverlayTimer.ClearAllButton:SetText(L("STREAMER_PLANNER_OVERLAY_CLEAR_ALL"))
    OverlayTimer.StartButton:SetText(L("STREAMER_PLANNER_TIMER_START"))
    OverlayTimer.PauseButton:SetText(L("STREAMER_PLANNER_TIMER_PAUSE"))
    OverlayTimer.ResetButton:SetText(L("STREAMER_PLANNER_TIMER_RESET"))
    EditClassTitle:SetText(L("STREAMER_PLANNER_CLASS"))
    EditSpecTitle:SetText(L("STREAMER_PLANNER_SPEC"))
    if EditDialog and EditDialog.RoleTitle then
        EditDialog.RoleTitle:SetText(L("STREAMER_PLANNER_ROLE"))
    end
    PlannerPrivate.saveSlotButton:SetText(L("STREAMER_PLANNER_SAVE_SLOT"))
    PlannerPrivate.clearSlotButton:SetText(L("STREAMER_PLANNER_CLEAR_SLOT"))
    PlannerPrivate.cancelSlotButton:SetText(L("CANCEL"))

    PlannerPrivate.isRefreshingPage = true
    settingsPanel.ShowOverlayCheckbox:SetChecked(settings.overlayEnabled)
    settingsPanel.LockOverlayCheckbox:SetChecked(settings.overlayLocked)
    ScaleSlider:SetValue(settings.overlayScale)
    TimerDurationSlider:SetValue(GetTimerDurationMinutes())
    if DestinationInput and PlannerPrivate.editingField ~= "destination" then
        DestinationInput:SetText(settings.destination)
    end
    RefreshDestinationCategoryDropdown()
    RefreshDestinationSuggestionDropdown()
    RefreshDestinationKeystoneDropdown()
    RefreshScaleSliderText()
    RefreshTimerDurationSliderText()
    PlannerPrivate.isRefreshingPage = false

    RefreshButtonList(PreviewUI.DungeonButtons, refreshContext)
    RefreshButtonList(PreviewUI.RaidButtons, refreshContext)
    RefreshButtonList(OverlayDungeonButtons, refreshContext)
    RefreshButtonList(OverlayRaidButtons, refreshContext)
    PlannerPrivate.RefreshModeButtons()
    PlannerPrivate.RefreshLayoutVisibility()
    RefreshTimerDisplay()
    PlannerPrivate.RefreshApplicantPanel()
    StreamerPlannerModule.RefreshOverlayWindow()
    self:UpdateScrollLayout()
end

function PageStreamerPlanner:UpdateScrollLayout()
    local introPanel = self.IntroPanel
    local previewPanel = self.PreviewPanel
    local settingsPanel = self.SettingsPanel
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())
    local topRowHeight

    PageContentFrame:SetWidth(contentWidth)

    local showRaid = GetCurrentMode() == "raid"
    previewPanel:SetWidth(GetPreviewPanelWidthForMode(showRaid and "raid" or "dungeon"))
    LayoutStreamerPlannerSettingsPanel(settingsPanel)
    if PreviewUI.RaidContainer and PreviewUI.RaidGroupFrames then
        PreviewUI.RaidContainer:SetSize(
            GetRaidLayoutContainerWidth(PREVIEW_RAID_GROUP_WIDTH),
            GetRaidLayoutContainerHeight(PREVIEW_RAID_SLOT_HEIGHT, 4)
        )
        PlannerPrivate.LayoutRaidLayout(
            PreviewUI.RaidContainer,
            PreviewUI.RaidButtons,
            PreviewUI.RaidGroupFrames,
            PREVIEW_RAID_GROUP_WIDTH,
            PREVIEW_RAID_SLOT_HEIGHT
        )
    end
    local introHeight = GetMeasuredPanelHeight(introPanel, self.UsageHint, 18, 96)
    local previewContent = showRaid and PreviewUI.RaidContainer or PreviewUI.DungeonContainer
    local previewHeight = GetMeasuredPanelHeight(previewPanel, previewContent, 18, 424)
    local settingsHeight = GetMeasuredPanelHeight(settingsPanel, settingsPanel and settingsPanel.EditHint, 24, 424)

    introPanel:SetHeight(introHeight)
    topRowHeight = math.max(previewHeight, settingsHeight)
    previewPanel:SetHeight(topRowHeight)
    settingsPanel:SetHeight(topRowHeight)

    local contentHeight = 20
        + introHeight
        + 18 + topRowHeight
        + (ApplicantPanel and ApplicantPanel:IsShown() and (18 + ApplicantPanel:GetHeight()) or 0)
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
    if PlannerPrivate.UpdateWatcherPollingState then
        PlannerPrivate.UpdateWatcherPollingState()
    end
end)

PageStreamerPlanner:SetScript("OnHide", function()
    if PlannerPrivate.UpdateWatcherPollingState then
        PlannerPrivate.UpdateWatcherPollingState()
    end
end)

PlannerPrivate.watcher = CreateFrame("Frame")
PlannerPrivate.watcher:RegisterEvent("PLAYER_LOGIN")
PlannerPrivate.watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
PlannerPrivate.watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
PlannerPrivate.watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
PlannerPrivate.watcher:RegisterEvent("PLAYER_ROLES_ASSIGNED")
PlannerPrivate.watcher:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
PlannerPrivate.watcher:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
PlannerPrivate.watcher:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
PlannerPrivate.watcher:RegisterEvent("CHAT_MSG_ADDON")
PlannerPrivate.watcher:RegisterEvent("INSPECT_READY")
PlannerPrivate.watcher:SetScript("OnEvent", function(_, event, ...)
    PlannerPrivate.currentGroupLookupDirty = true

    if event == "PLAYER_LOGIN" and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(STREAMER_PLANNER_ADDON_PREFIX)
    end

    if event == "CHAT_MSG_ADDON" then
        if not PlannerPrivate.HandlePlannerAddonMessage(...) then
            return
        end
    end

    if event == "INSPECT_READY" then
        if IsBlizzardInspectFrameActive() then
            PlannerPrivate.pendingInspectGUID = nil
            PlannerPrivate.pendingInspectUnit = nil
            PlannerPrivate.pendingInspectFullName = nil
            PlannerPrivate.pendingInspectClassFile = nil
            PlannerPrivate.pendingInspectExpiresAt = 0
            PlannerPrivate.nextInspectAllowedAt = GetCurrentTimestamp() + INSPECT_REQUEST_INTERVAL_SECONDS
            return
        end

        local inspectedGUID = select(1, ...)
        if PlannerPrivate.IsUsablePlainString(inspectedGUID) and inspectedGUID == PlannerPrivate.pendingInspectGUID then
            local inspectedUnit = PlannerPrivate.FindGroupUnitByGUID(inspectedGUID) or PlannerPrivate.pendingInspectUnit
            local fullName = PlannerPrivate.pendingInspectFullName
            local classFile = PlannerPrivate.pendingInspectClassFile
            local specID = nil

            if inspectedUnit and UnitExists and UnitExists(inspectedUnit) then
                fullName = PlannerPrivate.GetUnitFullName(inspectedUnit) or fullName
                classFile = classFile or select(2, UnitClass(inspectedUnit))

                local inspectSpecID = GetInspectSpecialization and GetInspectSpecialization(inspectedUnit) or nil
                if type(inspectSpecID) == "number" and inspectSpecID > 0 then
                    specID = inspectSpecID
                end
            end

            PlannerPrivate.ClearPendingInspectRequest()
            PlannerPrivate.StoreKnownCharacterInfo(fullName, inspectedGUID, classFile, specID)
        end
    end

    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
        local messageText = select(1, ...)
        local authorName = select(2, ...)
        local playerGUID = nil
        if event == "CHAT_MSG_WHISPER" then
            playerGUID = PlannerPrivate.FindPlayerGUIDInEventArgs(...)
        end
        local senderBnetIDAccount = nil
        if event == "CHAT_MSG_BN_WHISPER" then
            senderBnetIDAccount = tonumber((select(13, ...)))
        end
        local whisperCommand = PlannerPrivate.ResolveWhisperCommand(messageText)

        if whisperCommand then
            local existingWhisperEntry = nil
            if whisperCommand == "inv" then
                local resolvedWhisperName = PlannerPrivate.ResolveWhisperAuthorName(authorName, playerGUID, senderBnetIDAccount)
                existingWhisperEntry = PlannerPrivate.FindWhisperApplicantByName(resolvedWhisperName or authorName)
            end

            local whisperEntry = PlannerPrivate.UpsertWhisperApplicant(authorName, playerGUID, whisperCommand, senderBnetIDAccount, messageText)
            PlannerPrivate.RequestWhisperApplicantSpec(whisperEntry)
            if whisperEntry and whisperCommand == "enter" then
                PlannerPrivate.EnqueueWhisperSpecPrompt(whisperEntry.fullName or whisperEntry.inviteName or whisperEntry.displayName)
            end
            if whisperEntry
                and whisperCommand == "inv"
                and type(existingWhisperEntry) == "table"
                and existingWhisperEntry.command == "enter"
                and GetStreamerPlannerSettings().whisperCommandAutoInvite == true then
                local applicantData = PlannerPrivate.FindApplicantByName(whisperEntry.inviteName or whisperEntry.fullName or whisperEntry.displayName)
                local inviteTarget = PlannerPrivate.ResolveInviteTarget({
                    name = whisperEntry.displayName,
                    fullName = whisperEntry.fullName,
                    inviteName = whisperEntry.inviteName,
                    applicantID = applicantData and applicantData.applicantID or nil,
                    applicationStatus = applicantData and applicantData.applicationStatus or nil,
                })

                if inviteTarget then
                    PlannerPrivate.InviteResolvedTarget(inviteTarget)
                else
                    PlannerPrivate.InvitePlayerByName(whisperEntry.inviteName or whisperEntry.fullName or whisperEntry.displayName)
                end
            end
        else
            return
        end
    end

    PlannerPrivate.periodicSyncElapsed = 0
    PlannerPrivate.lastDungeonSyncSignature = nil
    PlannerPrivate.SyncDynamicPlannerState(true)
end)
local function RunStreamerPlannerWatcherUpdate()
    PlannerPrivate.SyncDynamicPlannerState(false)
end

-- Only watch whisper traffic when the planner UI or auto-invite actually needs it.
PlannerPrivate.ShouldListenForWhispers = function()
    local settings = GetStreamerPlannerSettings()
    if settings.whisperCommandAutoInvite == true then
        return true
    end

    if PageStreamerPlanner and PageStreamerPlanner:IsShown() then
        return true
    end

    if OverlayFrame and OverlayFrame:IsShown() then
        return true
    end

    return false
end

PlannerPrivate.UpdateWhisperEventRegistration = function()
    if not PlannerPrivate.watcher then
        return
    end

    if PlannerPrivate.ShouldListenForWhispers() then
        PlannerPrivate.watcher:RegisterEvent("CHAT_MSG_WHISPER")
        PlannerPrivate.watcher:RegisterEvent("CHAT_MSG_BN_WHISPER")
    else
        PlannerPrivate.watcher:UnregisterEvent("CHAT_MSG_WHISPER")
        PlannerPrivate.watcher:UnregisterEvent("CHAT_MSG_BN_WHISPER")
    end
end

PlannerPrivate.UpdateWatcherPollingState = function()
    PlannerPrivate.UpdateWhisperEventRegistration()

    local shouldPoll = (PageStreamerPlanner and PageStreamerPlanner:IsShown()) or (OverlayFrame and OverlayFrame:IsShown())
    PlannerPrivate.periodicSyncElapsed = 0

    if shouldPoll then
        if PlannerPrivate.watcherTicker == nil and C_Timer and C_Timer.NewTicker then
            PlannerPrivate.watcherTicker = C_Timer.NewTicker(1, function()
                local profiler = BeavisQoL.PerformanceProfiler
                local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
                RunStreamerPlannerWatcherUpdate()
                if profiler and profiler.EndSample then
                    profiler.EndSample("StreamerPlanner.WatcherOnUpdate", sampleToken)
                end
            end)
        elseif PlannerPrivate.watcherTicker == nil then
            PlannerPrivate.watcher:SetScript("OnUpdate", function(_, elapsed)
                PlannerPrivate.periodicSyncElapsed = PlannerPrivate.periodicSyncElapsed + elapsed
                if PlannerPrivate.periodicSyncElapsed < 1 then
                    return
                end

                PlannerPrivate.periodicSyncElapsed = 0
                local profiler = BeavisQoL.PerformanceProfiler
                local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
                RunStreamerPlannerWatcherUpdate()
                if profiler and profiler.EndSample then
                    profiler.EndSample("StreamerPlanner.WatcherOnUpdate", sampleToken)
                end
            end)
        end
    else
        if PlannerPrivate.watcherTicker then
            PlannerPrivate.watcherTicker:Cancel()
            PlannerPrivate.watcherTicker = nil
        end

        PlannerPrivate.watcher:SetScript("OnUpdate", nil)
    end
end

PlannerPrivate.UpdateWatcherPollingState()

BeavisQoL.UpdateStreamerPlanner = function()
    if PageStreamerPlanner and PageStreamerPlanner.RefreshState then
        PageStreamerPlanner:RefreshState()
    else
        StreamerPlannerModule.RefreshAllDisplays()
    end
end

PlannerPrivate.SyncDynamicPlannerState(true)
PageStreamerPlanner:RefreshState()
PageStreamerPlanner:UpdateScrollLayout()

BeavisQoL.Pages.StreamerPlanner = PageStreamerPlanner

