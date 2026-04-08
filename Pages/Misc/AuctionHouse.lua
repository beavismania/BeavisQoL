local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local baseGetMiscDB = Misc.GetMiscDB
local AuctionHouseWatcher = CreateFrame("Frame")

local AUCTION_HOUSE_UI_ADDON_NAME = "Blizzard_AuctionHouseUI"
local FILTER_REFRESH_INTERVAL = 0.5
local MAX_FILTER_SEARCH_DEPTH = 8

local function NormalizeText(text)
    local normalizedText = tostring(text or "")
    normalizedText = string.lower(normalizedText)
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""
    return normalizedText
end

local function GetAuctionHouseFilterNeedles()
    return {
        NormalizeText(L("AUCTION_HOUSE_CURRENT_EXPANSION_FILTER")),
        "aktuelle erweiterung",
        "current expansion",
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
        db.auctionHouseCurrentExpansionFilterEnabled = false
    end

    return db
end

function Misc.IsAuctionHouseCurrentExpansionFilterEnabled()
    return Misc.GetMiscDB().auctionHouseCurrentExpansionFilterEnabled == true
end

local function IsVisibleFrame(frame)
    return frame
        and frame.IsShown
        and frame:IsShown()
        and (not frame.GetAlpha or (frame:GetAlpha() or 0) > 0)
end

local function TextMatchesCurrentExpansionFilter(text)
    local normalizedText = NormalizeText(text)
    if normalizedText == "" then
        return false
    end

    for _, needle in ipairs(GetAuctionHouseFilterNeedles()) do
        if needle ~= "" and normalizedText:find(needle, 1, true) ~= nil then
            return true
        end
    end

    return false
end

local function ControlMatchesCurrentExpansionFilter(control)
    if not control or not IsVisibleFrame(control) then
        return false
    end

    if control.GetText and TextMatchesCurrentExpansionFilter(control:GetText()) then
        return true
    end

    for _, region in ipairs({ control:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText then
            if TextMatchesCurrentExpansionFilter(region:GetText()) then
                return true
            end
        end
    end

    return false
end

local function FindCurrentExpansionFilterControl(owner, depth)
    if not owner or depth > MAX_FILTER_SEARCH_DEPTH or not IsVisibleFrame(owner) then
        return nil
    end

    if owner.GetObjectType and owner.GetObjectType then
        local objectType = owner:GetObjectType()
        if (objectType == "CheckButton" or objectType == "Button") and owner.GetChecked and owner.Click then
            if ControlMatchesCurrentExpansionFilter(owner) then
                return owner
            end
        end
    end

    for _, child in ipairs({ owner:GetChildren() }) do
        local foundControl = FindCurrentExpansionFilterControl(child, depth + 1)
        if foundControl then
            return foundControl
        end
    end

    return nil
end

local function EnsureCurrentExpansionFilterEnabled()
    if not Misc.IsAuctionHouseCurrentExpansionFilterEnabled() then
        return false
    end

    local auctionHouseFrame = rawget(_G, "AuctionHouseFrame")
    if not auctionHouseFrame or not IsVisibleFrame(auctionHouseFrame) then
        return false
    end

    local control = FindCurrentExpansionFilterControl(auctionHouseFrame, 0)
    if not control or not control.GetChecked or not control.Click then
        return false
    end

    if control:GetChecked() then
        return true
    end

    if control.IsEnabled and control:IsEnabled() == false then
        return false
    end

    control:Click()
    return true
end

local function UpdateAuctionHouseWatcherState(forceTryNow)
    local auctionHouseFrame = rawget(_G, "AuctionHouseFrame")
    local shouldWatch = Misc.IsAuctionHouseCurrentExpansionFilterEnabled()
        and IsAuctionHouseUILoaded()
        and auctionHouseFrame
        and auctionHouseFrame.IsShown
        and auctionHouseFrame:IsShown()

    if not shouldWatch then
        AuctionHouseWatcher:SetScript("OnUpdate", nil)
        AuctionHouseWatcher.elapsed = 0
        return
    end

    if forceTryNow then
        EnsureCurrentExpansionFilterEnabled()
    end

    AuctionHouseWatcher.elapsed = 0
    AuctionHouseWatcher:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < FILTER_REFRESH_INTERVAL then
            return
        end

        self.elapsed = 0
        EnsureCurrentExpansionFilterEnabled()
    end)
end

function Misc.SetAuctionHouseCurrentExpansionFilterEnabled(value)
    Misc.GetMiscDB().auctionHouseCurrentExpansionFilterEnabled = value == true
    RefreshMiscPageState()
    UpdateAuctionHouseWatcherState(value == true)
end

AuctionHouseWatcher:RegisterEvent("ADDON_LOADED")
AuctionHouseWatcher:RegisterEvent("PLAYER_LOGIN")
AuctionHouseWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
AuctionHouseWatcher:RegisterEvent("AUCTION_HOUSE_CLOSED")
AuctionHouseWatcher:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == AUCTION_HOUSE_UI_ADDON_NAME then
            UpdateAuctionHouseWatcherState(true)
        end
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        UpdateAuctionHouseWatcherState(true)
        return
    end

    if event == "AUCTION_HOUSE_CLOSED" then
        UpdateAuctionHouseWatcherState(false)
        return
    end

    if event == "PLAYER_LOGIN" then
        UpdateAuctionHouseWatcherState(true)
    end
end)
