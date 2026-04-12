local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local baseGetMiscDB = Misc.GetMiscDB
local AuctionHouseWatcher = CreateFrame("Frame")

local AUCTION_HOUSE_UI_ADDON_NAME = "Blizzard_AuctionHouseUI"
local FILTER_REFRESH_INTERVAL = 0.5
local MAX_FILTER_SEARCH_DEPTH = 8

local function GetCurrentExpansionFilterID()
    return Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly
end

local function GetPoorQualityFilterID()
    return Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.PoorQuality
end

local function GetCommonQualityFilterID()
    return Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CommonQuality
end

local function NormalizeText(text)
    local normalizedText = tostring(text or "")
    normalizedText = string.lower(normalizedText)
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""
    return normalizedText
end

local function BuildFilterNeedles(...)
    local needles = {}
    local seen = {}

    for index = 1, select("#", ...) do
        local needle = NormalizeText(select(index, ...))
        if needle ~= "" and not seen[needle] then
            seen[needle] = true
            table.insert(needles, needle)
        end
    end

    return needles
end

local function GetAuctionHouseFilterNeedles()
    return BuildFilterNeedles(
        rawget(_G, "AUCTION_HOUSE_FILTER_CURRENTEXPANSION_ONLY"),
        "nur diese erweiterung",
        "diese erweiterung",
        "aktuelle erweiterung",
        "nur aktuelle erweiterung",
        "this expansion",
        "current expansion",
        "current expansion only",
        "this expansion only"
    )
end

local function GetPoorQualityFilterNeedles()
    return BuildFilterNeedles(
        rawget(_G, "ITEM_QUALITY0_DESC"),
        "schlecht",
        "poor"
    )
end

local function GetCommonQualityFilterNeedles()
    return BuildFilterNeedles(
        rawget(_G, "ITEM_QUALITY1_DESC"),
        "gewoehnlich",
        "common"
    )
end

local function GetAuctionHouseFilterDefinitions()
    return {
        {
            filterID = GetCurrentExpansionFilterID(),
            enabledState = true,
            disabledState = false,
            needles = GetAuctionHouseFilterNeedles(),
            isAutomationEnabled = function()
                return Misc.IsAuctionHouseCurrentExpansionFilterEnabled and Misc.IsAuctionHouseCurrentExpansionFilterEnabled()
            end,
        },
        {
            filterID = GetPoorQualityFilterID(),
            enabledState = false,
            disabledState = true,
            needles = GetPoorQualityFilterNeedles(),
            isAutomationEnabled = function()
                return Misc.IsAuctionHousePoorQualityFilterAutoDisabled and Misc.IsAuctionHousePoorQualityFilterAutoDisabled()
            end,
        },
        {
            filterID = GetCommonQualityFilterID(),
            enabledState = false,
            disabledState = true,
            needles = GetCommonQualityFilterNeedles(),
            isAutomationEnabled = function()
                return Misc.IsAuctionHouseCommonQualityFilterAutoDisabled and Misc.IsAuctionHouseCommonQualityFilterAutoDisabled()
            end,
        },
    }
end

local function IsAuctionHouseUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(AUCTION_HOUSE_UI_ADDON_NAME) == true
    end

    return rawget(_G, "AuctionHouseFrame") ~= nil
end

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc
    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

local function GetDesiredFilterState(filterDefinition)
    if filterDefinition.isAutomationEnabled and filterDefinition.isAutomationEnabled() then
        return filterDefinition.enabledState
    end

    return filterDefinition.disabledState
end

local function ApplyAuctionHouseDefaultFilterStates()
    if type(AUCTION_HOUSE_DEFAULT_FILTERS) ~= "table" then
        return false
    end

    local applied = false

    for _, filterDefinition in ipairs(GetAuctionHouseFilterDefinitions()) do
        if filterDefinition.filterID then
            AUCTION_HOUSE_DEFAULT_FILTERS[filterDefinition.filterID] = GetDesiredFilterState(filterDefinition)
            applied = true
        end
    end

    return applied
end

function Misc.GetMiscDB()
    local db

    if baseGetMiscDB then
        db = baseGetMiscDB()
    else
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.auctionHouseCurrentExpansionFilterEnabled == nil then
        db.auctionHouseCurrentExpansionFilterEnabled = true
    end

    if db.auctionHousePoorQualityFilterAutoDisabled == nil then
        db.auctionHousePoorQualityFilterAutoDisabled = true
    end

    if db.auctionHouseCommonQualityFilterAutoDisabled == nil then
        db.auctionHouseCommonQualityFilterAutoDisabled = true
    end

    return db
end

function Misc.IsAuctionHouseCurrentExpansionFilterEnabled()
    return Misc.GetMiscDB().auctionHouseCurrentExpansionFilterEnabled == true
end

function Misc.IsAuctionHousePoorQualityFilterAutoDisabled()
    return Misc.GetMiscDB().auctionHousePoorQualityFilterAutoDisabled == true
end

function Misc.IsAuctionHouseCommonQualityFilterAutoDisabled()
    return Misc.GetMiscDB().auctionHouseCommonQualityFilterAutoDisabled == true
end

local function IsAnyAuctionHouseFilterAutomationEnabled()
    return Misc.IsAuctionHouseCurrentExpansionFilterEnabled()
        or Misc.IsAuctionHousePoorQualityFilterAutoDisabled()
        or Misc.IsAuctionHouseCommonQualityFilterAutoDisabled()
end

local function SafeCallMethod(target, methodName, ...)
    if not target or type(methodName) ~= "string" or methodName == "" then
        return false
    end

    local method = target[methodName]
    if type(method) ~= "function" then
        return false
    end

    return pcall(method, target, ...)
end

local function IsVisibleFrame(frame)
    local okShown, isShown = SafeCallMethod(frame, "IsShown")
    if not okShown or isShown ~= true then
        return false
    end

    if not frame.GetAlpha then
        return true
    end

    local okAlpha, alpha = SafeCallMethod(frame, "GetAlpha")
    if not okAlpha then
        return false
    end

    return (alpha or 0) > 0
end

local function TextMatchesFilter(text, needles)
    local normalizedText = NormalizeText(text)
    if normalizedText == "" then
        return false
    end

    for _, needle in ipairs(needles) do
        if needle ~= "" and normalizedText:find(needle, 1, true) ~= nil then
            return true
        end
    end

    return false
end

local function ControlMatchesFilter(control, needles)
    if not control or not IsVisibleFrame(control) then
        return false
    end

    local okControlText, controlText = SafeCallMethod(control, "GetText")
    if okControlText and TextMatchesFilter(controlText, needles) then
        return true
    end

    local regionResults = { SafeCallMethod(control, "GetRegions") }
    if not regionResults[1] then
        return false
    end

    for index = 2, #regionResults do
        local region = regionResults[index]
        local okObjectType, objectType = SafeCallMethod(region, "GetObjectType")
        if region and okObjectType and objectType == "FontString" then
            local okRegionText, regionText = SafeCallMethod(region, "GetText")
            if okRegionText and TextMatchesFilter(regionText, needles) then
                return true
            end
        end
    end

    return false
end

local function FindFilterControl(owner, depth, needles)
    if not owner or depth > MAX_FILTER_SEARCH_DEPTH or not IsVisibleFrame(owner) then
        return nil
    end

    local okObjectType, objectType = SafeCallMethod(owner, "GetObjectType")
    if okObjectType then
        if (objectType == "CheckButton" or objectType == "Button") and owner.GetChecked and owner.Click then
            if ControlMatchesFilter(owner, needles) then
                return owner
            end
        end
    end

    local childResults = { SafeCallMethod(owner, "GetChildren") }
    if not childResults[1] then
        return nil
    end

    for index = 2, #childResults do
        local child = childResults[index]
        local foundControl = FindFilterControl(child, depth + 1, needles)
        if foundControl then
            return foundControl
        end
    end

    return nil
end

local function EnsureAuctionHouseFiltersApplied()
    ApplyAuctionHouseDefaultFilterStates()

    local auctionHouseFrame = rawget(_G, "AuctionHouseFrame")
    if not auctionHouseFrame or not IsVisibleFrame(auctionHouseFrame) then
        return false
    end

    local changedAny = false

    for _, filterDefinition in ipairs(GetAuctionHouseFilterDefinitions()) do
        local control = FindFilterControl(auctionHouseFrame, 0, filterDefinition.needles)
        if not control then
            control = FindFilterControl(rawget(_G, "UIParent"), 0, filterDefinition.needles)
        end

        if control and control.GetChecked and control.Click then
            local desiredState = GetDesiredFilterState(filterDefinition)
            local okChecked, currentState = SafeCallMethod(control, "GetChecked")
            if okChecked and currentState ~= desiredState then
                local canClick = true

                if control.IsEnabled then
                    local okEnabled, isEnabled = SafeCallMethod(control, "IsEnabled")
                    canClick = okEnabled and isEnabled ~= false
                end

                if canClick then
                    SafeCallMethod(control, "Click")
                    changedAny = true
                end
            end
        end
    end

    return changedAny
end

local function UpdateAuctionHouseWatcherState(forceTryNow)
    local auctionHouseFrame = rawget(_G, "AuctionHouseFrame")
    local shouldWatch = IsAnyAuctionHouseFilterAutomationEnabled()
        and IsAuctionHouseUILoaded()
        and auctionHouseFrame
        and IsVisibleFrame(auctionHouseFrame)

    if not shouldWatch then
        AuctionHouseWatcher:SetScript("OnUpdate", nil)
        AuctionHouseWatcher.elapsed = 0
        return
    end

    if forceTryNow then
        EnsureAuctionHouseFiltersApplied()
    end

    AuctionHouseWatcher.elapsed = 0
    AuctionHouseWatcher:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < FILTER_REFRESH_INTERVAL then
            return
        end

        self.elapsed = 0
        EnsureAuctionHouseFiltersApplied()
    end)
end

function Misc.SetAuctionHouseCurrentExpansionFilterEnabled(value)
    Misc.GetMiscDB().auctionHouseCurrentExpansionFilterEnabled = value == true
    ApplyAuctionHouseDefaultFilterStates()
    RefreshMiscPageState()
    UpdateAuctionHouseWatcherState(true)
end

function Misc.SetAuctionHousePoorQualityFilterAutoDisabled(value)
    Misc.GetMiscDB().auctionHousePoorQualityFilterAutoDisabled = value == true
    ApplyAuctionHouseDefaultFilterStates()
    RefreshMiscPageState()
    UpdateAuctionHouseWatcherState(true)
end

function Misc.SetAuctionHouseCommonQualityFilterAutoDisabled(value)
    Misc.GetMiscDB().auctionHouseCommonQualityFilterAutoDisabled = value == true
    ApplyAuctionHouseDefaultFilterStates()
    RefreshMiscPageState()
    UpdateAuctionHouseWatcherState(true)
end

AuctionHouseWatcher:RegisterEvent("ADDON_LOADED")
AuctionHouseWatcher:RegisterEvent("PLAYER_LOGIN")
AuctionHouseWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
AuctionHouseWatcher:RegisterEvent("AUCTION_HOUSE_CLOSED")
AuctionHouseWatcher:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == AUCTION_HOUSE_UI_ADDON_NAME then
            ApplyAuctionHouseDefaultFilterStates()
            UpdateAuctionHouseWatcherState(true)
        end
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        ApplyAuctionHouseDefaultFilterStates()
        UpdateAuctionHouseWatcherState(true)
        return
    end

    if event == "AUCTION_HOUSE_CLOSED" then
        UpdateAuctionHouseWatcherState(false)
        return
    end

    if event == "PLAYER_LOGIN" then
        ApplyAuctionHouseDefaultFilterStates()
        UpdateAuctionHouseWatcherState(true)
    end
end)
