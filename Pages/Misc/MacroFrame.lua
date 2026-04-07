local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

local baseGetMiscDB = Misc.GetMiscDB
local MacroFrameWatcher = CreateFrame("Frame")
local HookSecureFunction = rawget(_G, "hooksecurefunc")
local TimerAfter = C_Timer and C_Timer.After

local MACRO_UI_ADDON_NAME = "Blizzard_MacroUI"
local MACRO_FRAME_EXTRA_HEIGHT = 132

local macroUIInitialized = false
local trackedHeights = {}
local trackedPoints = {}

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc
    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

local function IsMacroUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(MACRO_UI_ADDON_NAME) == true
    end

    return rawget(_G, "MacroFrame") ~= nil
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

    if db.largeMacroFrame == nil then
        db.largeMacroFrame = false
    end

    return db
end

function Misc.IsLargeMacroFrameEnabled()
    return Misc.GetMiscDB().largeMacroFrame == true
end

local function CanRefreshMacroFrame(frame)
    return frame
        and frame.IsShown
        and frame:IsShown()
        and frame.macroBase ~= nil
end

local function ApplyTrackedHeight(key, frame, extraHeight)
    if not frame or not frame.GetHeight or not frame.SetHeight then
        return
    end

    if trackedHeights[key] == nil then
        trackedHeights[key] = frame:GetHeight()
    end

    local baseHeight = trackedHeights[key]
    local targetHeight = math.max(1, (baseHeight or 0) + (extraHeight or 0))

    if math.abs((frame:GetHeight() or 0) - targetHeight) > 0.5 then
        frame:SetHeight(targetHeight)
    end
end

local function ApplyTrackedVerticalOffset(key, frame, offset)
    if not frame or not frame.GetPoint or not frame.SetPoint or not frame.ClearAllPoints then
        return
    end

    if trackedPoints[key] == nil then
        local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint(1)
        if not point then
            return
        end

        trackedPoints[key] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOffset = xOffset or 0,
            yOffset = yOffset or 0,
        }
    end

    local basePoint = trackedPoints[key]
    frame:ClearAllPoints()
    frame:SetPoint(
        basePoint.point,
        basePoint.relativeTo,
        basePoint.relativePoint,
        basePoint.xOffset,
        basePoint.yOffset - (offset or 0)
    )
end

local function RefreshMacroFrameLayout(frame)
    if not CanRefreshMacroFrame(frame) then
        return
    end

    if frame.Update then
        pcall(frame.Update, frame)
    end

    if frame.SelectMacro and frame.GetSelectedIndex then
        pcall(frame.SelectMacro, frame, frame:GetSelectedIndex())
    end
end

local function ApplyMacroFrameSize()
    local frame = rawget(_G, "MacroFrame")
    if not frame then
        return
    end

    local extraHeight = Misc.IsLargeMacroFrameEnabled() and MACRO_FRAME_EXTRA_HEIGHT or 0
    local macroSelector = frame.MacroSelector

    ApplyTrackedHeight("MacroFrame", frame, extraHeight)
    ApplyTrackedHeight("MacroSelector", macroSelector, extraHeight)
    ApplyTrackedVerticalOffset("MacroHorizontalBarLeft", rawget(_G, "MacroHorizontalBarLeft"), extraHeight)
    ApplyTrackedVerticalOffset("MacroFrameSelectedMacroBackground", rawget(_G, "MacroFrameSelectedMacroBackground"), extraHeight)
    ApplyTrackedVerticalOffset("MacroFrameTextBackground", rawget(_G, "MacroFrameTextBackground"), extraHeight)

    if not CanRefreshMacroFrame(frame) then
        return
    end

    if TimerAfter then
        TimerAfter(0, function()
            local liveFrame = rawget(_G, "MacroFrame")
            RefreshMacroFrameLayout(liveFrame)
        end)
    else
        RefreshMacroFrameLayout(frame)
    end
end

local function InitializeMacroUI()
    local frame = rawget(_G, "MacroFrame")
    if not frame then
        return
    end

    if not macroUIInitialized then
        macroUIInitialized = true
        frame:HookScript("OnShow", ApplyMacroFrameSize)
    end

    if CanRefreshMacroFrame(frame) then
        ApplyMacroFrameSize()
    end
end

function Misc.SetLargeMacroFrameEnabled(value)
    Misc.GetMiscDB().largeMacroFrame = value == true
    local frame = rawget(_G, "MacroFrame")
    if CanRefreshMacroFrame(frame) then
        ApplyMacroFrameSize()
    end
    RefreshMiscPageState()
end

if HookSecureFunction and rawget(_G, "MacroFrame_LoadUI") then
    HookSecureFunction("MacroFrame_LoadUI", InitializeMacroUI)
end

MacroFrameWatcher:RegisterEvent("ADDON_LOADED")
MacroFrameWatcher:RegisterEvent("PLAYER_LOGIN")
MacroFrameWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == MACRO_UI_ADDON_NAME then
            InitializeMacroUI()
        end

        return
    end

    if event == "PLAYER_LOGIN" and IsMacroUILoaded() then
        InitializeMacroUI()
    end
end)
