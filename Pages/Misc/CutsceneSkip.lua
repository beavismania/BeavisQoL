local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

local GetBestMapForUnit = C_Map and C_Map.GetBestMapForUnit
local GetSubZoneTextValue = rawget(_G, "GetSubZoneText")
local GetZoneTextValue = rawget(_G, "GetZoneText")

local function GetCutsceneSkipDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.misc = BeavisQoLDB.misc or {}

    local db = BeavisQoLDB.misc

    if db.cutsceneSkip == nil then
        db.cutsceneSkip = false
    end

    if type(db.cutsceneSkipSeenKeys) ~= "table" then
        db.cutsceneSkipSeenKeys = {}
    end

    return db
end

function Misc.IsCutsceneSkipEnabled()
    return GetCutsceneSkipDB().cutsceneSkip == true
end

function Misc.SetCutsceneSkipEnabled(value)
    GetCutsceneSkipDB().cutsceneSkip = value == true
end

local function NormalizeContextText(text)
    local normalizedText = string.lower(tostring(text or ""))
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""

    return normalizedText
end

local function GetSeenKeys()
    return GetCutsceneSkipDB().cutsceneSkipSeenKeys
end

local function HasSeenKey(key)
    if type(key) ~= "string" or key == "" then
        return false
    end

    return GetSeenKeys()[key] == true
end

local function MarkSeenKey(key)
    if type(key) ~= "string" or key == "" then
        return
    end

    GetSeenKeys()[key] = true
end

local function BuildMovieKey(movieID)
    local numericMovieID = tonumber(movieID)
    if not numericMovieID then
        return nil
    end

    return string.format("movie:%d", numericMovieID)
end

local function BuildCinematicKey()
    local mapID = GetBestMapForUnit and GetBestMapForUnit("player") or nil
    local subZoneText = NormalizeContextText(GetSubZoneTextValue and GetSubZoneTextValue() or "")
    local zoneText = NormalizeContextText(GetZoneTextValue and GetZoneTextValue() or "")

    if type(mapID) == "number" and subZoneText ~= "" then
        return string.format("cinematic:%d:%s", mapID, subZoneText)
    end

    if type(mapID) == "number" and zoneText ~= "" then
        return string.format("cinematic:%d:%s", mapID, zoneText)
    end

    if type(mapID) == "number" then
        return string.format("cinematic:%d", mapID)
    end

    if zoneText ~= "" then
        return string.format("cinematic:zone:%s", zoneText)
    end

    return nil
end

local function SkipCurrentMovie()
    if MovieFrame and MovieFrame.Hide then
        MovieFrame:Hide()
        return
    end

    if StopMovie then
        StopMovie()
    end
end

local function SkipCurrentCinematic()
    if CinematicFrame_CancelCinematic then
        CinematicFrame_CancelCinematic()
        return
    end

    if StopCinematic then
        StopCinematic()
    end
end

local function ShouldHandleCutsceneSkip()
    return Misc.IsCutsceneSkipEnabled()
end

local function HandleMovieEvent(movieID)
    local key = BuildMovieKey(movieID)
    if not key then
        return
    end

    if HasSeenKey(key) then
        SkipCurrentMovie()
        return
    end

    MarkSeenKey(key)
end

local function HandleCinematicEvent()
    local key = BuildCinematicKey()
    if not key then
        return
    end

    if HasSeenKey(key) then
        SkipCurrentCinematic()
        return
    end

    MarkSeenKey(key)
end

local CutsceneWatcher = CreateFrame("Frame")
CutsceneWatcher:RegisterEvent("PLAY_MOVIE")
CutsceneWatcher:RegisterEvent("CINEMATIC_START")
CutsceneWatcher:SetScript("OnEvent", function(_, event, ...)
    if not ShouldHandleCutsceneSkip() then
        return
    end

    if event == "PLAY_MOVIE" then
        HandleMovieEvent(...)
        return
    end

    if event == "CINEMATIC_START" then
        HandleCinematicEvent()
    end
end)
