local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

local FLOOR = math.floor
local MAX = math.max
local MIN = math.min
local SQRT = math.sqrt

local GetAchievementInfoValue = rawget(_G, "GetAchievementInfo")
local GetFactionGroup = rawget(_G, "UnitFactionGroup")
local GetLocaleValue = rawget(_G, "GetLocale")
local GetMinimapZoneTextValue = rawget(_G, "GetMinimapZoneText")
local GetNumRoutesValue = rawget(_G, "GetNumRoutes")
local PlaySoundFileValue = rawget(_G, "PlaySoundFile")
local GetTaxiMapIDValue = rawget(_G, "GetTaxiMapID")
local GetViewedTaxiMapIDValue = rawget(_G, "GetViewedTaxiMapID")
local GetTimeValue = rawget(_G, "GetTime")
local HookSecureFuncValue = rawget(_G, "hooksecurefunc")
local IsSpellKnownValue = rawget(_G, "IsSpellKnown")
local NumTaxiNodesValue = rawget(_G, "NumTaxiNodes")
local TaxiGetNodeSlotValue = rawget(_G, "TaxiGetNodeSlot")
local TaxiNodeGetTypeValue = rawget(_G, "TaxiNodeGetType")
local TaxiNodeNameValue = rawget(_G, "TaxiNodeName")
local UnitOnTaxiValue = rawget(_G, "UnitOnTaxi")

local AddOnsAPI = rawget(_G, "C_AddOns")
local TaxiMapAPI = rawget(_G, "C_TaxiMap")
local TimerAPI = rawget(_G, "C_Timer")

local DEFAULT_ARRIVAL_SOUND_KEY = "builtin:squire_horn"
local KHAZ_ALGAR_MAP_ID = 2274
local KHAZ_ALGAR_FLIGHT_MASTER_ACHIEVEMENT_ID = 40430
local RIDE_LIKE_THE_WIND_SPELL_ID = 117983
local FLIGHT_TIMER_UPDATE_INTERVAL = 0.05
local DEFAULT_OVERLAY_POINT = "CENTER"
local DEFAULT_OVERLAY_RELATIVE_POINT = "CENTER"
local DEFAULT_OVERLAY_OFFSET_X = 0
local DEFAULT_OVERLAY_OFFSET_Y = -116

local FlightMasterWatcher = CreateFrame("Frame")
local OverlayFrame = nil
local OverlayPreviewData = nil
local HideOverlay
local RefreshOverlay
local TakeTaxiNodeHookInstalled = false
local OriginalTakeTaxiNode = nil
local CurrentSourceNodeID = nil
local CurrentSourceName = nil
local PendingFlight = nil
local ActiveFlight = nil
local KhazAlgarTaxiNodes = nil
local DurationGraphCache = nil
local DurationGraphFactionKey = nil
local DurationGraphAverageEdgeDuration = nil
local StandardSpecialFlightHookInstalled = false
local ImmersionSpecialFlightHookInstalled = false
local BUILTIN_ARRIVAL_SOUND_OPTIONS = {
    {
        key = DEFAULT_ARRIVAL_SOUND_KEY,
        legacyKeys = { "boxing_bell", "builtin:boxing_bell" },
        labelKey = "FLIGHT_MASTER_TIMER_SOUND_SQUIRE_HORN",
        fileDataID = 598079,
        repeatDelay = 1.08,
    },
    {
        key = "builtin:dwarf_horn",
        legacyKeys = { "temple_bell", "builtin:temple_bell" },
        labelKey = "FLIGHT_MASTER_TIMER_SOUND_DWARF_HORN",
        fileDataID = 566064,
        repeatDelay = 0.96,
    },
    {
        key = "builtin:simon_chime",
        legacyKeys = { "crystal_chime", "builtin:crystal_chime" },
        labelKey = "FLIGHT_MASTER_TIMER_SOUND_SIMON_CHIME",
        fileDataID = 566076,
        repeatDelay = 0.74,
    },
    {
        key = "builtin:scourge_horn",
        labelKey = "FLIGHT_MASTER_TIMER_SOUND_SCOURGE_HORN",
        fileDataID = 567386,
        repeatDelay = 1.12,
    },
    {
        key = "builtin:grimrail_train_horn",
        labelKey = "FLIGHT_MASTER_TIMER_SOUND_GRIMRAIL_TRAIN_HORN",
        fileDataID = 1023633,
        repeatDelay = 1.2,
    },
}
local ArrivalSoundOptionByKey = {}
local FindArrivalSoundOption
local IsArrivalSoundKeyAvailable

for _, soundOption in ipairs(BUILTIN_ARRIVAL_SOUND_OPTIONS) do
    ArrivalSoundOptionByKey[soundOption.key] = soundOption
    if type(soundOption.legacyKey) == "string" and soundOption.legacyKey ~= "" then
        ArrivalSoundOptionByKey[soundOption.legacyKey] = soundOption
    end
    if type(soundOption.legacyKeys) == "table" then
        for _, legacyKey in ipairs(soundOption.legacyKeys) do
            if type(legacyKey) == "string" and legacyKey ~= "" then
                ArrivalSoundOptionByKey[legacyKey] = soundOption
            end
        end
    end
end

local function L(key)
    return BeavisQoL.L and BeavisQoL.L(key) or key
end

local SPECIAL_FLIGHT_GOSSIP_ROUTES_BY_LOCALE = {
    deDE = {
        ["Bernsteinflöz"] = {
            {
                match = "Ich möchte Durchgang zum Transitusschild",
                sourceKey = "Amber Ledge",
                sourceName = "Bernsteinflöz",
                destinationKey = "Transitus Shield (Scenic Route)",
                destinationName = "Transitusschild (Freiflug)",
            },
        },
        ["Argentumturnierplatz"] = {
            {
                match = "Schwingt Euch auf den Hippogryphen und macht Euch bereit zum Kampf",
                sourceKey = "Argent Tournament Grounds",
                sourceName = "Argentumturnierplatz",
                destinationKey = "Return",
                destinationName = "Zurück zum Startpunkt",
            },
        },
        ["Schattenwindlager"] = {
            {
                match = "Bringt mich zum Außenposten der Himmelswache",
                sourceKey = "Blackwind Landing",
                sourceName = "Schattenwindlager",
                destinationKey = "Skyguard Outpost",
                destinationName = "Außenposten der Himmelswache",
            },
        },
        ["Höhlen der Zeit"] = {
            {
                match = "Bringt mich bitte zum Hort des Meisters",
                sourceKey = "Caverns of Time",
                sourceName = "Höhlen der Zeit",
                destinationKey = "Nozdormu's Lair",
                destinationName = "Nozdormus Versteck",
            },
        },
        ["Expeditionsposten"] = {
            {
                match = "Schickt mich zum Trümmerposten",
                sourceKey = "Expedition Point",
                sourceName = "Expeditionsposten",
                destinationKey = "Shatter Point",
                destinationName = "Trümmerposten",
            },
        },
        ["Höllenfeuerhalbinsel"] = {
            {
                match = "Schickt mich zum Trümmerposten",
                sourceKey = "Honor Point",
                sourceName = "Ehrenposten",
                destinationKey = "Shatter Point",
                destinationName = "Trümmerposten",
            },
        },
        ["Nachthafen"] = {
            {
                match = "Ich würde gerne nach Rut'theran fliegen",
                sourceKey = "Nighthaven",
                sourceName = "Nachthafen",
                destinationKey = "Rut'theran Village",
                destinationName = "Rut'theran",
            },
            {
                match = "Ich würde gerne nach Donnerfels fliegen",
                sourceKey = "Nighthaven",
                sourceName = "Nachthafen",
                destinationKey = "Thunder Bluff",
                destinationName = "Donnerfels",
            },
        },
        ["Vorgebirge des Alten Hügellands"] = {
            {
                match = "Ich bin bereit, nach Burg Durnholde zu gehen",
                sourceKey = "Old Hillsbrad Foothills",
                sourceName = "Vorgebirge des Alten Hügellands",
                destinationKey = "Durnholde Keep",
                destinationName = "Burg Durnholde",
            },
        },
        ["Ring der Übertragung"] = {
            {
                match = "Ich muss zurück zur Bastion",
                sourceKey = "Oribos",
                sourceName = "Oribos",
                destinationKey = "Bastion",
                destinationName = "Bastion",
            },
        },
        ["Trümmerposten"] = {
            {
                match = "Schickt mich zum Ehrenposten",
                sourceKey = "Shatter Point",
                sourceName = "Trümmerposten",
                destinationKey = "Honor Point",
                destinationName = "Ehrenposten",
            },
        },
        ["Außenposten der Himmelswache"] = {
            {
                match = "Ja, ich würde gerne zum Schattenwindlager fliegen",
                sourceKey = "Skyguard Outpost",
                sourceName = "Außenposten der Himmelswache",
                destinationKey = "Blackwind Landing",
                destinationName = "Schattenwindlager",
            },
        },
        ["Sturmwind"] = {
            {
                match = "Ich möchte durch den Hafen von Sturmwind fliegen",
                sourceKey = "Stormwind City",
                sourceName = "Sturmwind",
                destinationKey = "Return",
                destinationName = "Zurück zum Startpunkt",
            },
        },
        ["Hafen der Sonnenweiten"] = {
            {
                match = "Wo wir gerade von Kämpfen sprechen, ich habe die Order, einen Luftangriff zu starten",
                sourceKey = "Shattered Sun Staging Area",
                sourceName = "Sammelpunkt der Zerschmetterten Sonne",
                destinationKey = "Return",
                destinationName = "Zurück zum Startpunkt",
            },
            {
                match = "Ich muss die Verstärkung der Dämmerklingen abfangen",
                sourceKey = "Shattered Sun Staging Area",
                sourceName = "Sammelpunkt der Zerschmetterten Sonne",
                destinationKey = "The Sin'loren",
                destinationName = "Die Sin'loren",
            },
        },
        ["Die Sin'loren"] = {
            {
                match = "Fliegt auf dem Drachenfalken in die Sonnenweiten",
                sourceKey = "The Sin'loren",
                sourceName = "Die Sin'loren",
                destinationKey = "Shattered Sun Staging Area",
                destinationName = "Sammelpunkt der Zerschmetterten Sonne",
            },
        },
        ["Valgarde"] = {
            {
                match = "Bringt mich zum Außenposten der Forscherliga",
                sourceKey = "Valgarde",
                sourceName = "Valgarde",
                destinationKey = "Explorers' League Outpost",
                destinationName = "Außenposten der Forscherliga",
            },
        },
    },
    enUS = {
        ["Amber Ledge"] = {
            {
                match = "I'd like passage to the Transitus Shield",
                sourceKey = "Amber Ledge",
                sourceName = "Amber Ledge",
                destinationKey = "Transitus Shield (Scenic Route)",
                destinationName = "Transitus Shield (Scenic Route)",
            },
        },
        ["Argent Tournament Grounds"] = {
            {
                match = "Mount the Hippogryph and prepare for battle",
                sourceKey = "Argent Tournament Grounds",
                sourceName = "Argent Tournament Grounds",
                destinationKey = "Return",
                destinationName = "Return",
            },
        },
        ["Blackwind Landing"] = {
            {
                match = "Send me to the Skyguard Outpost",
                sourceKey = "Blackwind Landing",
                sourceName = "Blackwind Landing",
                destinationKey = "Skyguard Outpost",
                destinationName = "Skyguard Outpost",
            },
        },
        ["Caverns of Time"] = {
            {
                match = "Please take me to the master's lair",
                sourceKey = "Caverns of Time",
                sourceName = "Caverns of Time",
                destinationKey = "Nozdormu's Lair",
                destinationName = "Nozdormu's Lair",
            },
        },
        ["Expedition Point"] = {
            {
                match = "Send me to Shatter Point",
                sourceKey = "Expedition Point",
                sourceName = "Expedition Point",
                destinationKey = "Shatter Point",
                destinationName = "Shatter Point",
            },
        },
        ["Hellfire Peninsula"] = {
            {
                match = "Send me to Shatter Point",
                sourceKey = "Honor Point",
                sourceName = "Honor Point",
                destinationKey = "Shatter Point",
                destinationName = "Shatter Point",
            },
        },
        ["Nighthaven"] = {
            {
                match = "I'd like to fly to Rut'theran Village",
                sourceKey = "Nighthaven",
                sourceName = "Nighthaven",
                destinationKey = "Rut'theran Village",
                destinationName = "Rut'theran Village",
            },
            {
                match = "I'd like to fly to Thunder Bluff",
                sourceKey = "Nighthaven",
                sourceName = "Nighthaven",
                destinationKey = "Thunder Bluff",
                destinationName = "Thunder Bluff",
            },
        },
        ["Old Hillsbrad Foothills"] = {
            {
                match = "I'm ready to go to Durnholde Keep",
                sourceKey = "Old Hillsbrad Foothills",
                sourceName = "Old Hillsbrad Foothills",
                destinationKey = "Durnholde Keep",
                destinationName = "Durnholde Keep",
            },
        },
        ["Ring of Transference"] = {
            {
                match = "I am ready. Send me to Bastion",
                sourceKey = "Oribos",
                sourceName = "Oribos",
                destinationKey = "Bastion",
                destinationName = "Bastion",
            },
            {
                match = "I need to get back to Bastion",
                sourceKey = "Oribos",
                sourceName = "Oribos",
                destinationKey = "Bastion",
                destinationName = "Bastion",
            },
        },
        ["Shatter Point"] = {
            {
                match = "Send me to Honor Point",
                sourceKey = "Shatter Point",
                sourceName = "Shatter Point",
                destinationKey = "Honor Point",
                destinationName = "Honor Point",
            },
        },
        ["Skyguard Outpost"] = {
            {
                match = "Yes, I'd love a ride to Blackwind Landing",
                sourceKey = "Skyguard Outpost",
                sourceName = "Skyguard Outpost",
                destinationKey = "Blackwind Landing",
                destinationName = "Blackwind Landing",
            },
        },
        ["Stormwind City"] = {
            {
                match = "I'd like to take a flight around Stormwind Harbor",
                sourceKey = "Stormwind City",
                sourceName = "Stormwind City",
                destinationKey = "Return",
                destinationName = "Return",
            },
        },
        ["Sun's Reach Harbor"] = {
            {
                match = "Speaking of action, I've been ordered to undertake an air strike",
                sourceKey = "Shattered Sun Staging Area",
                sourceName = "Shattered Sun Staging Area",
                destinationKey = "Return",
                destinationName = "Return",
            },
            {
                match = "I need to intercept the Dawnblade reinforcements",
                sourceKey = "Shattered Sun Staging Area",
                sourceName = "Shattered Sun Staging Area",
                destinationKey = "The Sin'loren",
                destinationName = "The Sin'loren",
            },
        },
        ["The Sin'loren"] = {
            {
                match = "Ride the dragonhawk to Sun's Reach",
                sourceKey = "The Sin'loren",
                sourceName = "The Sin'loren",
                destinationKey = "Shattered Sun Staging Area",
                destinationName = "Shattered Sun Staging Area",
            },
        },
        ["Valgarde"] = {
            {
                match = "Take me to the Explorers' League Outpost",
                sourceKey = "Valgarde",
                sourceName = "Valgarde",
                destinationKey = "Explorers' League Outpost",
                destinationName = "Explorers' League Outpost",
            },
        },
    },
}

local function GetSpecialFlightRouteDefinitions()
    local localeKey = GetLocaleValue and GetLocaleValue() or "enUS"
    return SPECIAL_FLIGHT_GOSSIP_ROUTES_BY_LOCALE[localeKey] or SPECIAL_FLIGHT_GOSSIP_ROUTES_BY_LOCALE.enUS
end

local function NormalizeArrivalSoundStorageKey(soundKey)
    local builtInSoundOption = ArrivalSoundOptionByKey[soundKey]
    if builtInSoundOption then
        return builtInSoundOption.key
    end

    return DEFAULT_ARRIVAL_SOUND_KEY
end

local function BuildArrivalSoundCatalog()
    local arrivalSoundCatalog = {}

    for _, soundOption in ipairs(BUILTIN_ARRIVAL_SOUND_OPTIONS) do
        arrivalSoundCatalog[#arrivalSoundCatalog + 1] = {
            key = soundOption.key,
            label = L(soundOption.labelKey),
            fileDataID = soundOption.fileDataID,
            repeatDelay = soundOption.repeatDelay,
            source = "builtin",
        }
    end

    return arrivalSoundCatalog
end

FindArrivalSoundOption = function(soundKey)
    local normalizedSoundKey = NormalizeArrivalSoundStorageKey(soundKey)

    for _, soundOption in ipairs(BuildArrivalSoundCatalog()) do
        if soundOption.key == normalizedSoundKey then
            return soundOption
        end
    end

    local builtInSoundOption = ArrivalSoundOptionByKey[normalizedSoundKey]
    if not builtInSoundOption then
        return nil
    end

    return {
        key = builtInSoundOption.key,
        label = L(builtInSoundOption.labelKey),
        path = builtInSoundOption.path,
        repeatDelay = builtInSoundOption.repeatDelay,
        source = "builtin",
    }
end

IsArrivalSoundKeyAvailable = function(soundKey)
    return FindArrivalSoundOption(soundKey) ~= nil
end

local function GetNow()
    return GetTimeValue and GetTimeValue() or 0
end

local function RoundToNearestInteger(value)
    if value >= 0 then
        return FLOOR(value + 0.5)
    end

    return math.ceil(value - 0.5)
end

local function GetFlightMasterTimerDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.misc = BeavisQoLDB.misc or {}

    local db = BeavisQoLDB.misc

    if db.flightMasterTimer == nil then
        db.flightMasterTimer = true
    end

    if db.flightMasterTimerArrivalSoundEnabled == nil then
        db.flightMasterTimerArrivalSoundEnabled = true
    end

    if db.flightMasterTimerLocked == nil then
        db.flightMasterTimerLocked = true
    end

    local normalizedArrivalSoundKey = NormalizeArrivalSoundStorageKey(db.flightMasterTimerArrivalSoundKey)
    if not IsArrivalSoundKeyAvailable(normalizedArrivalSoundKey) then
        normalizedArrivalSoundKey = DEFAULT_ARRIVAL_SOUND_KEY
    end
    db.flightMasterTimerArrivalSoundKey = normalizedArrivalSoundKey

    if type(db.flightMasterTimerPoint) ~= "string" or db.flightMasterTimerPoint == "" then
        db.flightMasterTimerPoint = DEFAULT_OVERLAY_POINT
    end

    if type(db.flightMasterTimerRelativePoint) ~= "string" or db.flightMasterTimerRelativePoint == "" then
        db.flightMasterTimerRelativePoint = DEFAULT_OVERLAY_RELATIVE_POINT
    end

    if type(db.flightMasterTimerOffsetX) ~= "number" then
        db.flightMasterTimerOffsetX = DEFAULT_OVERLAY_OFFSET_X
    end

    if type(db.flightMasterTimerOffsetY) ~= "number" then
        db.flightMasterTimerOffsetY = DEFAULT_OVERLAY_OFFSET_Y
    end

    if type(db.flightMasterTimerLearnedDurations) ~= "table" then
        db.flightMasterTimerLearnedDurations = {}
    end

    return db
end

function Misc.IsFlightMasterTimerEnabled()
    return GetFlightMasterTimerDB().flightMasterTimer == true
end

function Misc.IsFlightMasterTimerArrivalSoundEnabled()
    return GetFlightMasterTimerDB().flightMasterTimerArrivalSoundEnabled == true
end

function Misc.IsFlightMasterTimerLocked()
    return GetFlightMasterTimerDB().flightMasterTimerLocked == true
end

function Misc.SetFlightMasterTimerArrivalSoundEnabled(value)
    GetFlightMasterTimerDB().flightMasterTimerArrivalSoundEnabled = value == true
end

local function ApplyOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local db = GetFlightMasterTimerDB()
    OverlayFrame:ClearAllPoints()
    OverlayFrame:SetPoint(
        db.flightMasterTimerPoint,
        UIParent,
        db.flightMasterTimerRelativePoint,
        db.flightMasterTimerOffsetX,
        db.flightMasterTimerOffsetY
    )
end

local function SaveOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayFrame:GetPoint(1)
    if not point then
        return
    end

    local db = GetFlightMasterTimerDB()
    db.flightMasterTimerPoint = point
    db.flightMasterTimerRelativePoint = relativePoint or point
    db.flightMasterTimerOffsetX = RoundToNearestInteger(offsetX or DEFAULT_OVERLAY_OFFSET_X)
    db.flightMasterTimerOffsetY = RoundToNearestInteger(offsetY or DEFAULT_OVERLAY_OFFSET_Y)
end

local function UpdateOverlayLockState()
    if not OverlayFrame then
        return
    end

    local isUnlocked = Misc.IsFlightMasterTimerLocked() ~= true
    OverlayFrame:SetMovable(isUnlocked)
    OverlayFrame:EnableMouse(isUnlocked)
end

function Misc.SetFlightMasterTimerLocked(locked)
    GetFlightMasterTimerDB().flightMasterTimerLocked = locked == true
    UpdateOverlayLockState()
end

function Misc.ResetFlightMasterTimerPosition()
    local db = GetFlightMasterTimerDB()
    db.flightMasterTimerPoint = DEFAULT_OVERLAY_POINT
    db.flightMasterTimerRelativePoint = DEFAULT_OVERLAY_RELATIVE_POINT
    db.flightMasterTimerOffsetX = DEFAULT_OVERLAY_OFFSET_X
    db.flightMasterTimerOffsetY = DEFAULT_OVERLAY_OFFSET_Y
    ApplyOverlayGeometry()
end

function Misc.IsFlightMasterTimerPreviewVisible()
    return type(OverlayPreviewData) == "table"
end

local function GetPreviewFlightData()
    return {
        destinationName = L("FLIGHT_MASTER_TIMER_PREVIEW_DESTINATION"),
        totalSeconds = 95,
        previewRemainingSeconds = 43,
    }
end

function Misc.ToggleFlightMasterTimerPreview()
    if Misc.IsFlightMasterTimerPreviewVisible() then
        OverlayPreviewData = nil
        UpdateOverlayLockState()

        if ActiveFlight then
            RefreshOverlay()
        else
            HideOverlay()
        end

        return false
    end

    OverlayPreviewData = GetPreviewFlightData()
    UpdateOverlayLockState()
    RefreshOverlay()
    return true
end

local function GetCurrentArrivalSoundOption()
    local selectedKey = GetFlightMasterTimerDB().flightMasterTimerArrivalSoundKey
    return FindArrivalSoundOption(selectedKey) or FindArrivalSoundOption(DEFAULT_ARRIVAL_SOUND_KEY)
end

function Misc.GetFlightMasterTimerArrivalSoundKey()
    return GetFlightMasterTimerDB().flightMasterTimerArrivalSoundKey
end

function Misc.GetFlightMasterTimerArrivalSoundOptions()
    return BuildArrivalSoundCatalog()
end

function Misc.GetFlightMasterTimerArrivalSoundLabel()
    local soundOption = GetCurrentArrivalSoundOption()
    return soundOption and soundOption.label or L("UNKNOWN")
end

function Misc.SetFlightMasterTimerArrivalSound(soundKey)
    local db = GetFlightMasterTimerDB()
    local normalizedSoundKey = NormalizeArrivalSoundStorageKey(soundKey)

    if not IsArrivalSoundKeyAvailable(normalizedSoundKey) then
        normalizedSoundKey = DEFAULT_ARRIVAL_SOUND_KEY
    end

    db.flightMasterTimerArrivalSoundKey = normalizedSoundKey
end

function Misc.CycleFlightMasterTimerArrivalSound()
    local db = GetFlightMasterTimerDB()
    local arrivalSoundCatalog = BuildArrivalSoundCatalog()
    local currentKey = db.flightMasterTimerArrivalSoundKey
    local nextIndex = 1

    for index, soundOption in ipairs(arrivalSoundCatalog) do
        if soundOption.key == currentKey then
            nextIndex = (index % #arrivalSoundCatalog) + 1
            break
        end
    end

    db.flightMasterTimerArrivalSoundKey = arrivalSoundCatalog[nextIndex] and arrivalSoundCatalog[nextIndex].key or DEFAULT_ARRIVAL_SOUND_KEY
end

local function PlayArrivalSoundSequence()
    if type(PlaySoundFileValue) ~= "function" then
        return
    end

    if not Misc.IsFlightMasterTimerEnabled() or not Misc.IsFlightMasterTimerArrivalSoundEnabled() then
        return
    end

    local soundOption = GetCurrentArrivalSoundOption()
    local playbackValue = soundOption and (soundOption.fileDataID or soundOption.path) or nil
    if type(soundOption) ~= "table" then
        return
    end

    if type(playbackValue) ~= "number" and (type(playbackValue) ~= "string" or playbackValue == "") then
        return
    end

    local function PlaySingleSound()
        pcall(PlaySoundFileValue, playbackValue, "Master")
    end

    PlaySingleSound()
end

function Misc.TestFlightMasterTimerArrivalSound()
    PlayArrivalSoundSequence()
end

HideOverlay = function()
    if OverlayFrame then
        OverlayFrame:Hide()
    end
end

local function GetDisplayedFlightData()
    if type(ActiveFlight) == "table" then
        return ActiveFlight
    end

    if type(OverlayPreviewData) == "table" then
        return OverlayPreviewData
    end

    return nil
end

local function GetPlayerFactionKey()
    local factionKey = GetFactionGroup and GetFactionGroup("player") or nil
    if factionKey == "Alliance" or factionKey == "Horde" then
        return factionKey
    end

    return nil
end

local function GetLearnedDurationRoot(createMissing)
    local root = GetFlightMasterTimerDB().flightMasterTimerLearnedDurations
    if type(root) ~= "table" then
        root = {}
        GetFlightMasterTimerDB().flightMasterTimerLearnedDurations = root
    end

    local factionKey = GetPlayerFactionKey()
    if not factionKey then
        return nil
    end

    if createMissing and type(root[factionKey]) ~= "table" then
        root[factionKey] = {}
    end

    return root[factionKey]
end

local function GetRouteDurationFromTable(rootTable, sourceNodeID, destinationNodeID)
    if type(rootTable) ~= "table" then
        return nil
    end

    local destinationTable = rootTable[sourceNodeID]
    if type(destinationTable) ~= "table" then
        return nil
    end

    local storedSeconds = destinationTable[destinationNodeID]
    if type(storedSeconds) ~= "number" or storedSeconds <= 0 then
        return nil
    end

    return storedSeconds
end

local function GetLearnedRouteDuration(sourceNodeID, destinationNodeID)
    return GetRouteDurationFromTable(GetLearnedDurationRoot(false), sourceNodeID, destinationNodeID)
end

local function GetSeedRouteDurationForSource(sourceNodeID, destinationNodeID)
    local seedData = Misc.FlightMasterTimerSeedData
    if type(seedData) ~= "table" then
        return nil
    end

    local factionslessSeconds = GetRouteDurationFromTable(seedData.FactionslessZones, sourceNodeID, destinationNodeID)
    if factionslessSeconds then
        return factionslessSeconds
    end

    local factionKey = GetPlayerFactionKey()
    if factionKey then
        local storedSeconds = GetRouteDurationFromTable(seedData[factionKey], sourceNodeID, destinationNodeID)
        if storedSeconds then
            return storedSeconds
        end
    end

    local allianceSeconds = GetRouteDurationFromTable(seedData.Alliance, sourceNodeID, destinationNodeID)
    if allianceSeconds then
        return allianceSeconds
    end

    return GetRouteDurationFromTable(seedData.Horde, sourceNodeID, destinationNodeID)
end

local function GetSeedRouteDuration(sourceNodeID, destinationNodeID)
    return GetSeedRouteDurationForSource(sourceNodeID, destinationNodeID)
end

local function NormalizeDurationGraphNodeKey(nodeKey)
    local nodeType = type(nodeKey)
    if nodeType == "number" then
        return nodeKey
    end

    if nodeType == "string" and nodeKey ~= "" then
        return nodeKey
    end

    return nil
end

local function AddRouteDurationsToGraph(graph, rootTable, overwriteExisting)
    if type(graph) ~= "table" or type(rootTable) ~= "table" then
        return
    end

    for sourceKey, destinationTable in pairs(rootTable) do
        local normalizedSourceKey = NormalizeDurationGraphNodeKey(sourceKey)
        if normalizedSourceKey and type(destinationTable) == "table" then
            graph[normalizedSourceKey] = graph[normalizedSourceKey] or {}

            for destinationKey, storedSeconds in pairs(destinationTable) do
                if destinationKey ~= "name" then
                    local normalizedDestinationKey = NormalizeDurationGraphNodeKey(destinationKey)
                    if normalizedDestinationKey and type(storedSeconds) == "number" and storedSeconds > 0 then
                        if overwriteExisting or graph[normalizedSourceKey][normalizedDestinationKey] == nil then
                            graph[normalizedSourceKey][normalizedDestinationKey] = storedSeconds
                        end
                    end
                end
            end
        end
    end
end

local function InvalidateDurationGraphCache()
    DurationGraphCache = nil
    DurationGraphFactionKey = nil
    DurationGraphAverageEdgeDuration = nil
end

local function GetDurationGraph()
    local factionKey = GetPlayerFactionKey() or false
    if type(DurationGraphCache) == "table" and DurationGraphFactionKey == factionKey then
        return DurationGraphCache
    end

    local graph = {}
    local seedData = Misc.FlightMasterTimerSeedData

    if type(seedData) == "table" then
        AddRouteDurationsToGraph(graph, seedData.FactionslessZones, false)

        if factionKey and type(seedData[factionKey]) == "table" then
            AddRouteDurationsToGraph(graph, seedData[factionKey], false)
        end

        AddRouteDurationsToGraph(graph, seedData.Alliance, false)
        AddRouteDurationsToGraph(graph, seedData.Horde, false)
    end

    AddRouteDurationsToGraph(graph, GetLearnedDurationRoot(false), true)

    DurationGraphCache = graph
    DurationGraphFactionKey = factionKey
    DurationGraphAverageEdgeDuration = nil
    return DurationGraphCache
end

local function IsKhazAlgarNode(nodeID)
    if type(nodeID) ~= "number" or not TaxiMapAPI or type(TaxiMapAPI.GetTaxiNodesForMap) ~= "function" then
        return false
    end

    if KhazAlgarTaxiNodes == nil then
        KhazAlgarTaxiNodes = {}

        local taxiNodes = TaxiMapAPI.GetTaxiNodesForMap(KHAZ_ALGAR_MAP_ID)
        if type(taxiNodes) == "table" then
            for _, taxiNodeData in ipairs(taxiNodes) do
                if type(taxiNodeData) == "table" and type(taxiNodeData.nodeID) == "number" then
                    KhazAlgarTaxiNodes[taxiNodeData.nodeID] = true
                end
            end
        end

        KhazAlgarTaxiNodes[2970] = true
    end

    return KhazAlgarTaxiNodes[nodeID] == true
end

local function GetKhazAlgarFlightFactor(nodeID)
    if not IsKhazAlgarNode(nodeID) then
        return 1
    end

    if type(GetAchievementInfoValue) ~= "function" then
        return 1
    end

    local _, _, _, completed = GetAchievementInfoValue(KHAZ_ALGAR_FLIGHT_MASTER_ACHIEVEMENT_ID)
    if completed then
        return 1
    end

    return 1.25
end

local function GetRideLikeTheWindFactor()
    local currentExpansion = rawget(_G, "LE_EXPANSION_LEVEL_CURRENT")
    local mistsExpansion = rawget(_G, "LE_EXPANSION_MISTS_OF_PANDARIA")

    if currentExpansion == mistsExpansion and type(IsSpellKnownValue) == "function" and IsSpellKnownValue(RIDE_LIKE_THE_WIND_SPELL_ID) then
        return 0.8
    end

    return 1
end

local function GetRouteDurationFactor(destinationNodeID)
    return GetKhazAlgarFlightFactor(destinationNodeID) * GetRideLikeTheWindFactor()
end

local function GetAverageAdjustedGraphEdgeDuration()
    if type(DurationGraphAverageEdgeDuration) == "number" and DurationGraphAverageEdgeDuration > 0 then
        return DurationGraphAverageEdgeDuration
    end

    local graph = GetDurationGraph()
    local totalSeconds = 0
    local edgeCount = 0

    for _, destinationTable in pairs(graph) do
        if type(destinationTable) == "table" then
            for destinationKey, storedSeconds in pairs(destinationTable) do
                if type(storedSeconds) == "number" and storedSeconds > 0 then
                    totalSeconds = totalSeconds + (storedSeconds * GetRouteDurationFactor(destinationKey))
                    edgeCount = edgeCount + 1
                end
            end
        end
    end

    DurationGraphAverageEdgeDuration = edgeCount > 0 and (totalSeconds / edgeCount) or 90
    return DurationGraphAverageEdgeDuration
end

local function GetGraphEstimatedRouteDuration(sourceNodeID, destinationNodeID)
    local normalizedSourceKey = NormalizeDurationGraphNodeKey(sourceNodeID)
    local normalizedDestinationKey = NormalizeDurationGraphNodeKey(destinationNodeID)
    if normalizedSourceKey == nil or normalizedDestinationKey == nil or normalizedSourceKey == normalizedDestinationKey then
        return nil
    end

    local graph = GetDurationGraph()
    if type(graph[normalizedSourceKey]) ~= "table" then
        return nil
    end

    local frontier = {
        {
            nodeKey = normalizedSourceKey,
            cost = 0,
        },
    }
    local bestCosts = {
        [normalizedSourceKey] = 0,
    }

    while #frontier > 0 do
        local bestIndex = 1
        local bestCandidate = frontier[1]

        for index = 2, #frontier do
            if frontier[index].cost < bestCandidate.cost then
                bestIndex = index
                bestCandidate = frontier[index]
            end
        end

        table.remove(frontier, bestIndex)

        if bestCandidate.nodeKey == normalizedDestinationKey then
            return bestCandidate.cost
        end

        if bestCandidate.cost <= (bestCosts[bestCandidate.nodeKey] or math.huge) then
            for nextNodeKey, storedSeconds in pairs(graph[bestCandidate.nodeKey] or {}) do
                if type(storedSeconds) == "number" and storedSeconds > 0 then
                    local nextCost = bestCandidate.cost + (storedSeconds * GetRouteDurationFactor(nextNodeKey))
                    if bestCosts[nextNodeKey] == nil or nextCost < bestCosts[nextNodeKey] then
                        bestCosts[nextNodeKey] = nextCost
                        frontier[#frontier + 1] = {
                            nodeKey = nextNodeKey,
                            cost = nextCost,
                        }
                    end
                end
            end
        end
    end

    return nil
end

local function GetAdjustedRouteDuration(sourceNodeID, destinationNodeID, allowGraphFallback)
    local learnedSeconds = GetLearnedRouteDuration(sourceNodeID, destinationNodeID)
    if learnedSeconds then
        return learnedSeconds * GetRouteDurationFactor(destinationNodeID), false
    end

    local seedSeconds = GetSeedRouteDuration(sourceNodeID, destinationNodeID)
    if seedSeconds then
        return seedSeconds * GetRouteDurationFactor(destinationNodeID), false
    end

    if allowGraphFallback ~= false then
        local graphSeconds = GetGraphEstimatedRouteDuration(sourceNodeID, destinationNodeID)
        if graphSeconds then
            return graphSeconds, true
        end
    end

    return nil
end

local function StoreLearnedRouteDuration(sourceNodeID, destinationNodeID, observedSeconds)
    if type(sourceNodeID) ~= "number" or type(destinationNodeID) ~= "number" or type(observedSeconds) ~= "number" then
        return
    end

    if observedSeconds < 5 then
        return
    end

    local learnedDurations = GetLearnedDurationRoot(true)
    if type(learnedDurations) ~= "table" then
        return
    end

    if type(learnedDurations[sourceNodeID]) ~= "table" then
        learnedDurations[sourceNodeID] = {}
    end

    local factor = GetRouteDurationFactor(destinationNodeID)
    if factor <= 0 then
        factor = 1
    end

    learnedDurations[sourceNodeID][destinationNodeID] = FLOOR((observedSeconds / factor) + 0.5)
    InvalidateDurationGraphCache()
end

local function GetTaxiMapNodes()
    if not TaxiMapAPI or type(TaxiMapAPI.GetAllTaxiNodes) ~= "function" then
        return nil
    end

    local mapID = nil
    if type(GetViewedTaxiMapIDValue) == "function" then
        mapID = GetViewedTaxiMapIDValue()
    end

    if not mapID and type(GetTaxiMapIDValue) == "function" then
        mapID = GetTaxiMapIDValue()
    end

    if not mapID then
        return nil
    end

    return TaxiMapAPI.GetAllTaxiNodes(mapID)
end

local function GetNodeDataForSlot(slot)
    if type(slot) ~= "number" then
        return nil
    end

    local taxiNodes = GetTaxiMapNodes()
    if type(taxiNodes) ~= "table" then
        return nil
    end

    for _, taxiNodeData in ipairs(taxiNodes) do
        if type(taxiNodeData) == "table" and taxiNodeData.slotIndex == slot then
            return taxiNodeData
        end
    end

    return nil
end

local function BuildRouteNodeSequence(slot, sourceNodeID, destinationNodeID)
    local directRouteNodeIDs = {
        sourceNodeID,
        destinationNodeID,
    }

    if type(GetNumRoutesValue) ~= "function" or type(TaxiGetNodeSlotValue) ~= "function" then
        return directRouteNodeIDs, 1
    end

    local routeCount = GetNumRoutesValue(slot)
    if type(routeCount) ~= "number" or routeCount < 2 then
        return directRouteNodeIDs, 1
    end

    local routeNodeIDs = { sourceNodeID }
    for hopIndex = 2, routeCount do
        local hopSlot = TaxiGetNodeSlotValue(slot, hopIndex, true)
        local hopNodeData = GetNodeDataForSlot(hopSlot)
        local hopNodeID = hopNodeData and hopNodeData.nodeID or nil
        if type(hopNodeID) ~= "number" then
            return directRouteNodeIDs, MAX(1, routeCount)
        end

        routeNodeIDs[#routeNodeIDs + 1] = hopNodeID
    end

    routeNodeIDs[#routeNodeIDs + 1] = destinationNodeID
    return routeNodeIDs, MAX(1, #routeNodeIDs - 1)
end

local function GetTaxiNodeCoordinates(nodeData)
    if type(nodeData) ~= "table" then
        return nil, nil
    end

    local function ReadCoordinates(positionValue)
        local positionType = type(positionValue)
        if positionType ~= "table" and positionType ~= "userdata" then
            return nil, nil
        end

        if type(positionValue.x) == "number" and type(positionValue.y) == "number" then
            return positionValue.x, positionValue.y
        end

        if type(positionValue[1]) == "number" and type(positionValue[2]) == "number" then
            return positionValue[1], positionValue[2]
        end

        if type(positionValue.GetXY) == "function" then
            local ok, x, y = pcall(positionValue.GetXY, positionValue)
            if ok and type(x) == "number" and type(y) == "number" then
                return x, y
            end
        end

        return nil, nil
    end

    local x, y = ReadCoordinates(nodeData.position)
    if type(x) == "number" and type(y) == "number" then
        return x, y
    end

    x, y = ReadCoordinates(nodeData.uiMapPosition)
    if type(x) == "number" and type(y) == "number" then
        return x, y
    end

    if type(nodeData.normalizedX) == "number" and type(nodeData.normalizedY) == "number" then
        return nodeData.normalizedX, nodeData.normalizedY
    end

    if type(nodeData.x) == "number" and type(nodeData.y) == "number" then
        return nodeData.x, nodeData.y
    end

    return nil, nil
end

local function BuildTaxiNodeCoordinateLookup()
    local coordinatesByNodeID = {}
    local taxiNodes = GetTaxiMapNodes()
    if type(taxiNodes) ~= "table" then
        return coordinatesByNodeID
    end

    for _, taxiNodeData in ipairs(taxiNodes) do
        if type(taxiNodeData) == "table" and type(taxiNodeData.nodeID) == "number" then
            local x, y = GetTaxiNodeCoordinates(taxiNodeData)
            if type(x) == "number" and type(y) == "number" then
                coordinatesByNodeID[taxiNodeData.nodeID] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return coordinatesByNodeID
end

local function GetTaxiMapSecondsPerUnitDistance(coordinatesByNodeID)
    if type(coordinatesByNodeID) ~= "table" then
        return nil
    end

    local totalAdjustedSeconds = 0
    local totalDistance = 0
    local graph = GetDurationGraph()

    for sourceNodeID, coordinates in pairs(coordinatesByNodeID) do
        local destinationTable = graph[sourceNodeID]
        if type(destinationTable) == "table" then
            for destinationNodeID, storedSeconds in pairs(destinationTable) do
                local destinationCoordinates = coordinatesByNodeID[destinationNodeID]
                if destinationCoordinates and type(storedSeconds) == "number" and storedSeconds > 0 then
                    local deltaX = destinationCoordinates.x - coordinates.x
                    local deltaY = destinationCoordinates.y - coordinates.y
                    local distance = SQRT((deltaX * deltaX) + (deltaY * deltaY))
                    if distance > 0 then
                        totalAdjustedSeconds = totalAdjustedSeconds + (storedSeconds * GetRouteDurationFactor(destinationNodeID))
                        totalDistance = totalDistance + distance
                    end
                end
            end
        end
    end

    if totalDistance <= 0 then
        return nil
    end

    return totalAdjustedSeconds / totalDistance
end

local function GetCoordinateEstimatedRouteDuration(routeNodeIDs, fallbackSegmentCount)
    if type(routeNodeIDs) ~= "table" or #routeNodeIDs < 2 then
        return nil
    end

    local coordinatesByNodeID = BuildTaxiNodeCoordinateLookup()
    local totalDistance = 0
    local measuredSegmentCount = 0

    for index = 1, (#routeNodeIDs - 1) do
        local sourceCoordinates = coordinatesByNodeID[routeNodeIDs[index]]
        local destinationCoordinates = coordinatesByNodeID[routeNodeIDs[index + 1]]
        if sourceCoordinates and destinationCoordinates then
            local deltaX = destinationCoordinates.x - sourceCoordinates.x
            local deltaY = destinationCoordinates.y - sourceCoordinates.y
            local distance = SQRT((deltaX * deltaX) + (deltaY * deltaY))
            if distance > 0 then
                totalDistance = totalDistance + distance
                measuredSegmentCount = measuredSegmentCount + 1
            end
        end
    end

    local secondsPerUnitDistance = GetTaxiMapSecondsPerUnitDistance(coordinatesByNodeID)
    if secondsPerUnitDistance and totalDistance > 0 then
        return MAX(5, FLOOR((totalDistance * secondsPerUnitDistance) + 0.5))
    end

    if measuredSegmentCount > 0 then
        return MAX(5, FLOOR((GetAverageAdjustedGraphEdgeDuration() * measuredSegmentCount) + 0.5))
    end

    if type(fallbackSegmentCount) == "number" and fallbackSegmentCount > 0 then
        return MAX(5, FLOOR((GetAverageAdjustedGraphEdgeDuration() * fallbackSegmentCount) + 0.5))
    end

    return nil
end

local function GetCoarseFallbackRouteDuration(routeSegmentCount)
    local normalizedSegmentCount = type(routeSegmentCount) == "number" and routeSegmentCount > 0 and routeSegmentCount or 1
    return MAX(5, FLOOR((GetAverageAdjustedGraphEdgeDuration() * normalizedSegmentCount) + 0.5))
end

local function UpdateCurrentSourceFromTaxiMap()
    CurrentSourceNodeID = nil
    CurrentSourceName = nil

    if type(NumTaxiNodesValue) ~= "function" or type(TaxiNodeGetTypeValue) ~= "function" then
        return
    end

    for slotIndex = 1, NumTaxiNodesValue() do
        if TaxiNodeGetTypeValue(slotIndex) == "CURRENT" then
            local taxiNodeData = GetNodeDataForSlot(slotIndex)
            CurrentSourceNodeID = taxiNodeData and taxiNodeData.nodeID or nil
            CurrentSourceName = (taxiNodeData and taxiNodeData.name) or (TaxiNodeNameValue and TaxiNodeNameValue(slotIndex)) or nil
            return
        end
    end
end

local function GetEstimatedRouteDuration(slot, sourceNodeID, destinationNodeID)
    local directSeconds = GetAdjustedRouteDuration(sourceNodeID, destinationNodeID, false)
    if directSeconds then
        return directSeconds
    end

    local routeNodeIDs, routeSegmentCount = BuildRouteNodeSequence(slot, sourceNodeID, destinationNodeID)

    local estimatedSecondsByIndex = {
        [1] = 0,
    }
    local previousSourceIndex = {}
    local nextDestinationIndex = {}
    local sourceIndex = 1
    local destinationIndex = #routeNodeIDs - 1

    while sourceIndex and sourceIndex < #routeNodeIDs do
        while destinationIndex and destinationIndex > sourceIndex do
            local segmentSeconds = GetAdjustedRouteDuration(routeNodeIDs[sourceIndex], routeNodeIDs[destinationIndex], false)
            if segmentSeconds then
                if estimatedSecondsByIndex[destinationIndex] == nil then
                    estimatedSecondsByIndex[destinationIndex] = estimatedSecondsByIndex[sourceIndex] + segmentSeconds
                end

                nextDestinationIndex[sourceIndex] = destinationIndex - 1
                previousSourceIndex[destinationIndex] = sourceIndex
                sourceIndex = destinationIndex
                destinationIndex = #routeNodeIDs
            else
                destinationIndex = destinationIndex - 1
            end
        end

        if estimatedSecondsByIndex[#routeNodeIDs] then
            return estimatedSecondsByIndex[#routeNodeIDs], true
        end

        sourceIndex = previousSourceIndex[sourceIndex]
        if not sourceIndex then
            break
        end

        destinationIndex = nextDestinationIndex[sourceIndex]
    end

    local graphSeconds = GetAdjustedRouteDuration(sourceNodeID, destinationNodeID, true)
    if graphSeconds then
        return graphSeconds
    end

    local coordinateSeconds = GetCoordinateEstimatedRouteDuration(routeNodeIDs, routeSegmentCount)
    if coordinateSeconds then
        return coordinateSeconds, true
    end

    return GetCoarseFallbackRouteDuration(routeSegmentCount), true
end

local function FormatFlightTime(remainingSeconds)
    if type(remainingSeconds) ~= "number" then
        return "--:--"
    end

    local roundedSeconds = MAX(0, FLOOR(remainingSeconds + 0.999))
    local hours = FLOOR(roundedSeconds / 3600)
    local minutes = FLOOR((roundedSeconds % 3600) / 60)
    local seconds = roundedSeconds % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    end

    return string.format("%d:%02d", minutes, seconds)
end

local function GetTimerBarColor(remainingSeconds, totalSeconds)
    local ratio = 0
    if type(remainingSeconds) == "number" and type(totalSeconds) == "number" and totalSeconds > 0 then
        ratio = remainingSeconds / totalSeconds
    end

    if ratio > 0.50 then
        return 0.20, 0.82, 0.38
    end

    if ratio > 0.25 then
        return 1.00, 0.78, 0.20
    end

    return 0.95, 0.24, 0.24
end

local function ApplyDestinationTextStyle(fontString, destinationText)
    if not fontString then
        return
    end

    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = 12
    local textWidth = 0

    fontString:SetFont(fontPath, fontSize, "OUTLINE")
    fontString:SetText(destinationText or "")
    textWidth = fontString:GetStringWidth() or 0

    if textWidth > 190 then
        fontSize = 11
        fontString:SetFont(fontPath, fontSize, "OUTLINE")
        fontString:SetText(destinationText or "")
        textWidth = fontString:GetStringWidth() or 0
    end

    if textWidth > 215 then
        fontSize = 10
        fontString:SetFont(fontPath, fontSize, "OUTLINE")
        fontString:SetText(destinationText or "")
        textWidth = fontString:GetStringWidth() or 0
    end

    return MAX(150, MIN(220, textWidth + 30))
end

local function EnsureOverlayFrame()
    if OverlayFrame then
        return OverlayFrame
    end

    local frame = CreateFrame("Frame", "BeavisQoLFlightMasterTimerOverlay", UIParent)
    frame:SetSize(170, 56)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetToplevel(true)
    frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()
    frame:SetScript("OnDragStart", function(self)
        if Misc.IsFlightMasterTimerLocked() then
            return
        end

        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveOverlayGeometry()
    end)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.02, 0.02, 0.02, 0.24)
    frame.Background = background

    local topBorder = frame:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(1, 0.82, 0, 0.12)

    local bottomBorder = frame:CreateTexture(nil, "BORDER")
    bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(1, 0.82, 0, 0.12)

    local leftBorder = frame:CreateTexture(nil, "BORDER")
    leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    leftBorder:SetWidth(1)
    leftBorder:SetColorTexture(1, 0.82, 0, 0.06)

    local rightBorder = frame:CreateTexture(nil, "BORDER")
    rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(1)
    rightBorder:SetColorTexture(1, 0.82, 0, 0.06)

    local destinationText = frame:CreateFontString(nil, "OVERLAY")
    destinationText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    destinationText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    destinationText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    destinationText:SetJustifyH("CENTER")
    destinationText:SetWordWrap(false)
    destinationText:SetTextColor(0.96, 0.86, 0.48, 0.95)
    destinationText:SetShadowColor(0, 0, 0, 0.85)
    destinationText:SetShadowOffset(1, -1)
    frame.DestinationText = destinationText

    local timerText = frame:CreateFontString(nil, "OVERLAY")
    timerText:SetPoint("TOPLEFT", destinationText, "BOTTOMLEFT", 0, -6)
    timerText:SetPoint("TOPRIGHT", destinationText, "BOTTOMRIGHT", 0, -6)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    timerText:SetJustifyH("CENTER")
    timerText:SetTextColor(0.95, 0.91, 0.85, 1)
    timerText:SetShadowColor(0, 0, 0, 0.90)
    timerText:SetShadowOffset(1, -1)
    frame.TimerText = timerText

    local timerBar = CreateFrame("StatusBar", nil, frame)
    timerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 8)
    timerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 8)
    timerBar:SetHeight(4)
    timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.TimerBar = timerBar

    local timerBarBackground = timerBar:CreateTexture(nil, "BACKGROUND")
    timerBarBackground:SetAllPoints()
    timerBarBackground:SetColorTexture(0, 0, 0, 0.32)

    local timerBarBorder = frame:CreateTexture(nil, "ARTWORK")
    timerBarBorder:SetPoint("TOPLEFT", timerBar, "TOPLEFT", -1, 1)
    timerBarBorder:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", 1, -1)
    timerBarBorder:SetColorTexture(1, 0.82, 0, 0.16)

    local function HandleFlightMasterTimerOnUpdate(self, elapsed)
        self.ElapsedSinceUpdate = (self.ElapsedSinceUpdate or 0) + elapsed
        if self.ElapsedSinceUpdate < FLIGHT_TIMER_UPDATE_INTERVAL then
            return
        end

        self.ElapsedSinceUpdate = 0

        if not Misc.IsFlightMasterTimerEnabled() then
            self:Hide()
            return
        end

        local displayedFlight = GetDisplayedFlightData()
        if not displayedFlight then
            self:Hide()
            return
        end

        if ActiveFlight and UnitOnTaxiValue and not UnitOnTaxiValue("player") then
            self:Hide()
            return
        end

        local targetWidth = ApplyDestinationTextStyle(self.DestinationText, displayedFlight.destinationName or L("FLIGHT_MASTER_TIMER"))
        if type(targetWidth) == "number" then
            self:SetWidth(targetWidth)
        end

        if type(displayedFlight.previewRemainingSeconds) == "number" and type(displayedFlight.totalSeconds) == "number" then
            local remainingSeconds = MAX(0, displayedFlight.previewRemainingSeconds)
            local red, green, blue = GetTimerBarColor(remainingSeconds, displayedFlight.totalSeconds)
            self.TimerText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
            self.TimerText:SetText(FormatFlightTime(remainingSeconds))
            self.TimerBar:SetMinMaxValues(0, displayedFlight.totalSeconds)
            self.TimerBar:SetValue(remainingSeconds)
            self.TimerBar:SetStatusBarColor(red, green, blue, 0.90)
            self.TimerBar:Show()
        elseif type(displayedFlight.endTime) == "number" and type(displayedFlight.totalSeconds) == "number" then
            local remainingSeconds = MAX(0, displayedFlight.endTime - GetNow())
            local red, green, blue = GetTimerBarColor(remainingSeconds, displayedFlight.totalSeconds)
            self.TimerText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
            self.TimerText:SetText(FormatFlightTime(remainingSeconds))
            self.TimerBar:SetMinMaxValues(0, displayedFlight.totalSeconds)
            self.TimerBar:SetValue(remainingSeconds)
            self.TimerBar:SetStatusBarColor(red, green, blue, 0.90)
            self.TimerBar:Show()
        else
            self.TimerText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            self.TimerText:SetText(L("FLIGHT_MASTER_TIMER_UNKNOWN"))
            self.TimerBar:Hide()
        end

        self:Show()
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        local profiler = BeavisQoL.PerformanceProfiler
        local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
        HandleFlightMasterTimerOnUpdate(self, elapsed)
        if profiler and profiler.EndSample then
            profiler.EndSample("FlightMasterTimer.OnUpdate", sampleToken)
        end
    end)

    OverlayFrame = frame
    ApplyOverlayGeometry()
    UpdateOverlayLockState()
    return frame
end

RefreshOverlay = function()
    if not Misc.IsFlightMasterTimerEnabled() or not GetDisplayedFlightData() then
        HideOverlay()
        return
    end

    local frame = EnsureOverlayFrame()
    frame.ElapsedSinceUpdate = FLIGHT_TIMER_UPDATE_INTERVAL
    frame:Show()
end

local function StopActiveFlight(shouldLearnRoute)
    local finishedFlight = ActiveFlight
    ActiveFlight = nil

    if OverlayPreviewData then
        RefreshOverlay()
    else
        HideOverlay()
    end

    if not shouldLearnRoute or type(finishedFlight) ~= "table" then
        return
    end

    local observedSeconds = GetNow() - (finishedFlight.startTime or 0)
    if observedSeconds <= 0 then
        return
    end

    StoreLearnedRouteDuration(finishedFlight.sourceNodeID, finishedFlight.destinationNodeID, observedSeconds)
    PlayArrivalSoundSequence()
end

local function StartPendingFlight()
    if type(PendingFlight) ~= "table" then
        return
    end

    local startTime = GetNow()
    ActiveFlight = {
        sourceNodeID = PendingFlight.sourceNodeID,
        destinationNodeID = PendingFlight.destinationNodeID,
        destinationName = PendingFlight.destinationName,
        totalSeconds = PendingFlight.totalSeconds,
        startTime = startTime,
        endTime = PendingFlight.totalSeconds and (startTime + PendingFlight.totalSeconds) or nil,
    }
    PendingFlight = nil

    RefreshOverlay()
end

local function TryStartPendingFlight()
    if type(PendingFlight) ~= "table" then
        return
    end

    if UnitOnTaxiValue and not UnitOnTaxiValue("player") then
        return
    end

    StartPendingFlight()
end

local function QueuePendingFlightStartChecks()
    if not TimerAPI or type(TimerAPI.After) ~= "function" then
        TryStartPendingFlight()
        return
    end

    TimerAPI.After(0.01, TryStartPendingFlight)
    TimerAPI.After(0.10, TryStartPendingFlight)
    TimerAPI.After(0.35, TryStartPendingFlight)
    TimerAPI.After(0.75, TryStartPendingFlight)
end

local function QueuePendingFlightExpiry(pendingFlight)
    if not TimerAPI or type(TimerAPI.After) ~= "function" then
        return
    end

    TimerAPI.After(3, function()
        if PendingFlight == pendingFlight and not ActiveFlight then
            PendingFlight = nil
        end
    end)
end

local function FindSpecialFlightRoute(buttonText)
    if type(buttonText) ~= "string" or buttonText == "" or type(GetMinimapZoneTextValue) ~= "function" then
        return nil
    end

    local subzoneText = GetMinimapZoneTextValue()
    if type(subzoneText) ~= "string" or subzoneText == "" then
        return nil
    end

    local routeDefinitions = GetSpecialFlightRouteDefinitions()[subzoneText]
    if type(routeDefinitions) ~= "table" then
        return nil
    end

    for _, routeDefinition in ipairs(routeDefinitions) do
        if type(routeDefinition.match) == "string" and string.find(buttonText, routeDefinition.match, 1, true) then
            return routeDefinition
        end
    end

    return nil
end

local function PreparePendingSpecialFlight(buttonText)
    if not Misc.IsFlightMasterTimerEnabled() then
        return
    end

    local routeDefinition = FindSpecialFlightRoute(buttonText)
    if type(routeDefinition) ~= "table" then
        return
    end

    local totalSeconds = GetAdjustedRouteDuration(routeDefinition.sourceKey, routeDefinition.destinationKey, true)
        or GetCoarseFallbackRouteDuration(1)

    PendingFlight = {
        sourceNodeID = nil,
        sourceName = routeDefinition.sourceName or routeDefinition.sourceKey,
        destinationNodeID = nil,
        destinationName = routeDefinition.destinationName or routeDefinition.destinationKey,
        totalSeconds = totalSeconds,
        queuedAt = GetNow(),
    }

    QueuePendingFlightStartChecks()
    QueuePendingFlightExpiry(PendingFlight)
end

local function PreparePendingFlight(slot)
    if not Misc.IsFlightMasterTimerEnabled() then
        return
    end

    if type(slot) ~= "number" or type(TaxiNodeGetTypeValue) ~= "function" then
        return
    end

    if TaxiNodeGetTypeValue(slot) ~= "REACHABLE" then
        return
    end

    if not CurrentSourceNodeID then
        UpdateCurrentSourceFromTaxiMap()
    end

    if type(CurrentSourceNodeID) ~= "number" then
        return
    end

    local destinationNodeData = GetNodeDataForSlot(slot)
    if type(destinationNodeData) ~= "table" or type(destinationNodeData.nodeID) ~= "number" then
        return
    end

    local totalSeconds = GetEstimatedRouteDuration(slot, CurrentSourceNodeID, destinationNodeData.nodeID)
    local destinationName = (TaxiNodeNameValue and TaxiNodeNameValue(slot)) or destinationNodeData.name or L("UNKNOWN")

    PendingFlight = {
        sourceNodeID = CurrentSourceNodeID,
        sourceName = CurrentSourceName,
        destinationNodeID = destinationNodeData.nodeID,
        destinationName = destinationName,
        totalSeconds = totalSeconds,
        queuedAt = GetNow(),
    }

    QueuePendingFlightStartChecks()
    QueuePendingFlightExpiry(PendingFlight)
end

local function InstallSpecialFlightHooks()
    if not StandardSpecialFlightHookInstalled and type(HookSecureFuncValue) == "function" then
        local gossipOptionButtonMixin = rawget(_G, "GossipOptionButtonMixin")
        if type(gossipOptionButtonMixin) == "table" then
            HookSecureFuncValue(gossipOptionButtonMixin, "OnClick", function(button)
                local elementData = button and button.GetElementData and button:GetElementData() or nil
                local gossipButtonType = rawget(_G, "GOSSIP_BUTTON_TYPE_OPTION")

                if type(elementData) == "table" and gossipButtonType and elementData.buttonType ~= nil and elementData.buttonType ~= gossipButtonType then
                    return
                end

                PreparePendingSpecialFlight(button and button.GetText and button:GetText() or nil)
            end)

            StandardSpecialFlightHookInstalled = true
        end
    end

    if not ImmersionSpecialFlightHookInstalled and AddOnsAPI and type(AddOnsAPI.IsAddOnLoaded) == "function" and AddOnsAPI.IsAddOnLoaded("Immersion") then
        local immersionHookFrame = CreateFrame("Frame")
        immersionHookFrame:SetScript("OnEvent", function()
            local immersionFrame = rawget(_G, "ImmersionFrame")
            if not immersionFrame or not immersionFrame.TitleButtons then
                return
            end

            local children = { immersionFrame.TitleButtons:GetChildren() }
            for _, child in ipairs(children) do
                if not child.BeavisQoLFlightTimerSpecialHook then
                    child:HookScript("OnClick", function(self)
                        PreparePendingSpecialFlight(self:GetText())
                    end)
                    child.BeavisQoLFlightTimerSpecialHook = true
                end
            end
        end)
        immersionHookFrame:RegisterEvent("GOSSIP_SHOW")
        immersionHookFrame:RegisterEvent("QUEST_GREETING")
        immersionHookFrame:RegisterEvent("QUEST_PROGRESS")
        ImmersionSpecialFlightHookInstalled = true
    end
end

local function InstallTakeTaxiNodeHook()
    if TakeTaxiNodeHookInstalled or type(TakeTaxiNode) ~= "function" then
        return
    end

    OriginalTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        PreparePendingFlight(slot)
        return OriginalTakeTaxiNode(slot, ...)
    end

    TakeTaxiNodeHookInstalled = true
end

function Misc.SetFlightMasterTimerEnabled(value)
    GetFlightMasterTimerDB().flightMasterTimer = value == true

    if value ~= true then
        OverlayPreviewData = nil
        UpdateOverlayLockState()
        PendingFlight = nil
        StopActiveFlight(false)
        return
    end

    InstallTakeTaxiNodeHook()
    if ActiveFlight then
        RefreshOverlay()
    end
end

FlightMasterWatcher:RegisterEvent("PLAYER_LOGIN")
FlightMasterWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
FlightMasterWatcher:RegisterEvent("PLAYER_CONTROL_LOST")
FlightMasterWatcher:RegisterEvent("PLAYER_CONTROL_GAINED")
FlightMasterWatcher:RegisterEvent("TAXIMAP_OPENED")
FlightMasterWatcher:RegisterEvent("TAXIMAP_CLOSED")
FlightMasterWatcher:RegisterEvent("GOSSIP_SHOW")

FlightMasterWatcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        InstallTakeTaxiNodeHook()
        InstallSpecialFlightHooks()
        EnsureOverlayFrame()
        return
    end

    if event == "GOSSIP_SHOW" then
        InstallSpecialFlightHooks()
        return
    end

    if event == "TAXIMAP_OPENED" then
        InstallTakeTaxiNodeHook()
        UpdateCurrentSourceFromTaxiMap()
        return
    end

    if event == "TAXIMAP_CLOSED" then
        CurrentSourceNodeID = nil
        CurrentSourceName = nil
        return
    end

    if event == "PLAYER_CONTROL_LOST" then
        TryStartPendingFlight()
        return
    end

    if event == "PLAYER_CONTROL_GAINED" then
        if ActiveFlight then
            StopActiveFlight(true)
        else
            PendingFlight = nil
        end

        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if ActiveFlight then
            if UnitOnTaxiValue and UnitOnTaxiValue("player") then
                RefreshOverlay()
            else
                StopActiveFlight(true)
            end
        else
            TryStartPendingFlight()
        end
    end
end)

