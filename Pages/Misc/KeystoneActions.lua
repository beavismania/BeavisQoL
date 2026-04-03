local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local baseGetMiscDB = Misc.GetMiscDB
local KeystoneActionsWatcher = CreateFrame("Frame")
local DEFAULT_COUNTDOWN_SECONDS = 10
local MIN_COUNTDOWN_SECONDS = 1
local MAX_COUNTDOWN_SECONDS = 30
local BUTTON_GAP = 6
local ChallengesUIInitialized = false
local KeystoneFrame = nil
local ButtonsContainer = nil
local AutoTimerCheckbox = nil
local AutoTimerLabel = nil
local ReadyCheckButton = nil
local PullTimerButton = nil
local PendingStartTimer = nil
local PendingReadyCheck = nil
local AutoTimerReadyCheckRequestedAt = 0

local function GetChallengesUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") == true
    end

    return rawget(_G, "ChallengesKeystoneFrame") ~= nil
end

local function GetCountdownAPI()
    return C_PartyInfo and C_PartyInfo.DoCountdown or nil
end

local function GetReadyCheckAPI()
    return rawget(_G, "DoReadyCheck")
end

local function GetStartChallengeModeAPI()
    return C_ChallengeMode and C_ChallengeMode.StartChallengeMode or nil
end

local function GetHasSlottedKeystoneAPI()
    return C_ChallengeMode and C_ChallengeMode.HasSlottedKeystone or nil
end

local function GetTimerAPI()
    return C_Timer and C_Timer.NewTimer or nil
end

local function GetNow()
    if GetTimePreciseSec then
        return GetTimePreciseSec()
    end

    return GetTime and GetTime() or 0
end

local function FitButtonWidth(button, minWidth)
    if not button then
        return
    end

    local textWidth = button.GetTextWidth and button:GetTextWidth() or 0
    button:SetWidth(math.max(minWidth or 80, math.ceil((textWidth or 0) + 28)))
end

local function NormalizeCountdownSeconds(value)
    local numericValue = tonumber(value)
    if not numericValue then
        return DEFAULT_COUNTDOWN_SECONDS
    end

    numericValue = math.floor(numericValue + 0.5)
    if numericValue < MIN_COUNTDOWN_SECONDS then
        return MIN_COUNTDOWN_SECONDS
    end

    if numericValue > MAX_COUNTDOWN_SECONDS then
        return MAX_COUNTDOWN_SECONDS
    end

    return numericValue
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

    if db.keystoneActions == nil then
        db.keystoneActions = true
    end

    if db.keystoneAutoTimer == nil then
        db.keystoneAutoTimer = false
    end

    if db.keystoneGroupLock == nil then
        db.keystoneGroupLock = true
    end

    db.keystoneCountdownSeconds = NormalizeCountdownSeconds(db.keystoneCountdownSeconds)

    return db
end

function Misc.IsKeystoneActionsEnabled()
    return Misc.GetMiscDB().keystoneActions == true
end

function Misc.IsKeystoneAutoTimerEnabled()
    return Misc.GetMiscDB().keystoneAutoTimer == true
end

function Misc.IsKeystoneGroupLockEnabled()
    return Misc.GetMiscDB().keystoneGroupLock == true
end

function Misc.GetKeystoneCountdownSeconds()
    return NormalizeCountdownSeconds(Misc.GetMiscDB().keystoneCountdownSeconds)
end

local function ClearPendingReadyCheck()
    PendingReadyCheck = nil
    AutoTimerReadyCheckRequestedAt = 0
end

local function CancelAutoTimerPreparation()
    PendingReadyCheck = nil
    AutoTimerReadyCheckRequestedAt = 0
end

local function IsPlayerReadyCheckInitiator(initiatorName)
    if type(initiatorName) ~= "string" or initiatorName == "" then
        return false
    end

    local playerName = UnitName and UnitName("player") or nil
    if not playerName or playerName == "" then
        return false
    end

    if Ambiguate then
        return Ambiguate(initiatorName, "short") == playerName
    end

    return initiatorName == playerName
end

local function BuildPendingReadyCheckState(initiatorName)
    local awaiting = {}

    if IsInRaid and IsInRaid() then
        local raidMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, raidMembers do
            local unit = "raid" .. index
            if UnitExists and UnitExists(unit) and UnitGUID then
                local guid = UnitGUID(unit)
                if guid then
                    awaiting[guid] = true
                end
            end
        end
    else
        if UnitExists and UnitExists("player") and UnitGUID then
            local playerGUID = UnitGUID("player")
            if playerGUID then
                awaiting[playerGUID] = true
            end
        end

        local partyMembers = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, partyMembers do
            local unit = "party" .. index
            if UnitExists and UnitExists(unit) and UnitGUID then
                local guid = UnitGUID(unit)
                if guid then
                    awaiting[guid] = true
                end
            end
        end
    end

    if IsPlayerReadyCheckInitiator(initiatorName) and UnitGUID then
        local playerGUID = UnitGUID("player")
        if playerGUID then
            awaiting[playerGUID] = nil
        end
    end

    return {
        awaiting = awaiting,
    }
end

local function IsCountdownRunning()
    return PendingStartTimer ~= nil
end

local function CancelGroupCountdown()
    local doCountdown = GetCountdownAPI()
    if type(doCountdown) == "function" then
        pcall(doCountdown, 0)
    end
end

local function StopPendingCountdown(cancelGroupCountdown)
    local timerHandle = PendingStartTimer
    if not timerHandle then
        return
    end

    PendingStartTimer = nil
    if timerHandle.Cancel then
        pcall(timerHandle.Cancel, timerHandle)
    end

    if cancelGroupCountdown ~= false then
        CancelGroupCountdown()
    end
end

local function IsActivationReady()
    if not KeystoneFrame or (KeystoneFrame.IsShown and not KeystoneFrame:IsShown()) then
        return false
    end

    local hasSlottedKeystone = GetHasSlottedKeystoneAPI()
    if type(hasSlottedKeystone) == "function" and hasSlottedKeystone() ~= true then
        return false
    end

    return type(GetStartChallengeModeAPI()) == "function"
end

local function UpdateOriginalStartButtonVisibility()
    if not KeystoneFrame or not KeystoneFrame.StartButton then
        return
    end

    if Misc.IsKeystoneActionsEnabled() then
        KeystoneFrame.StartButton:Hide()
    else
        KeystoneFrame.StartButton:Show()
    end
end

local function PositionKeystoneButtons()
    if not KeystoneFrame or not ButtonsContainer or not AutoTimerCheckbox or not AutoTimerLabel or not ReadyCheckButton or not PullTimerButton then
        return
    end

    local autoTimerBlockWidth = (AutoTimerCheckbox:GetWidth() or 24) + math.ceil(AutoTimerLabel:GetStringWidth() or 0) + 2
    local totalWidth = autoTimerBlockWidth + BUTTON_GAP + ReadyCheckButton:GetWidth() + BUTTON_GAP + PullTimerButton:GetWidth()
    local buttonHeight = math.max(ReadyCheckButton:GetHeight() or 0, PullTimerButton:GetHeight() or 0)

    ButtonsContainer:ClearAllPoints()
    ButtonsContainer:SetSize(totalWidth, buttonHeight)
    ButtonsContainer:SetPoint("BOTTOM", KeystoneFrame, "BOTTOM", 0, 20)

    AutoTimerCheckbox:ClearAllPoints()
    AutoTimerLabel:ClearAllPoints()
    ReadyCheckButton:ClearAllPoints()
    PullTimerButton:ClearAllPoints()

    AutoTimerCheckbox:SetPoint("LEFT", ButtonsContainer, "LEFT", 0, 0)
    AutoTimerLabel:SetPoint("LEFT", AutoTimerCheckbox, "RIGHT", 0, 1)
    ReadyCheckButton:SetPoint("LEFT", ButtonsContainer, "LEFT", autoTimerBlockWidth + BUTTON_GAP, 0)
    PullTimerButton:SetPoint("LEFT", ReadyCheckButton, "RIGHT", BUTTON_GAP, 0)
end

local RefreshKeystoneButtons

local function StartAutomaticActivationCountdown()
    PendingReadyCheck = nil

    if IsCountdownRunning() then
        StopPendingCountdown(true)
        RefreshKeystoneButtons()
        return
    end

    local doCountdown = GetCountdownAPI()
    local createTimer = GetTimerAPI()
    local inGroup = IsInGroup and IsInGroup() or false
    local countdownSeconds = Misc.GetKeystoneCountdownSeconds()

    if type(createTimer) ~= "function" or not IsActivationReady() then
        RefreshKeystoneButtons()
        return
    end

    if inGroup and type(doCountdown) == "function" then
        local ok, success = pcall(doCountdown, countdownSeconds)
        if not ok or success == false then
            RefreshKeystoneButtons()
            return
        end
    end

    PendingStartTimer = createTimer(countdownSeconds, function()
        PendingStartTimer = nil

        if not Misc.IsKeystoneActionsEnabled() or not IsActivationReady() then
            RefreshKeystoneButtons()
            return
        end

        local startChallengeMode = GetStartChallengeModeAPI()
        if type(startChallengeMode) ~= "function" then
            RefreshKeystoneButtons()
            return
        end

        local startOk, startSuccess = pcall(startChallengeMode)
        if not startOk or startSuccess == false then
            RefreshKeystoneButtons()
            return
        end

        RefreshKeystoneButtons()
    end)

    RefreshKeystoneButtons()
end

RefreshKeystoneButtons = function()
    if not AutoTimerCheckbox or not AutoTimerLabel or not ReadyCheckButton or not PullTimerButton then
        return
    end

    local countdownRunning = IsCountdownRunning()
    local groupLockEnabled = Misc.IsKeystoneGroupLockEnabled()
    local inGroup = IsInGroup and IsInGroup() or false

    if countdownRunning and (not IsActivationReady() or (groupLockEnabled and not inGroup)) then
        StopPendingCountdown(true)
        countdownRunning = false
    end

    UpdateOriginalStartButtonVisibility()
    AutoTimerLabel:SetText(L("KEYSTONE_ACTIONS_AUTOTIMER"))
    AutoTimerCheckbox:SetChecked(Misc.IsKeystoneAutoTimerEnabled())
    ReadyCheckButton:SetText(L("KEYSTONE_ACTIONS_READYCHECK"))
    PullTimerButton:SetText(countdownRunning and L("KEYSTONE_ACTIONS_CANCEL") or L("KEYSTONE_ACTIONS_PULLTIMER"))
    FitButtonWidth(ReadyCheckButton, 84)
    FitButtonWidth(PullTimerButton, countdownRunning and 84 or 108)
    PositionKeystoneButtons()

    if not Misc.IsKeystoneActionsEnabled() then
        StopPendingCountdown(true)
        CancelAutoTimerPreparation()
        AutoTimerCheckbox:Hide()
        AutoTimerLabel:Hide()
        ReadyCheckButton:Hide()
        PullTimerButton:Hide()
        return
    end

    if ButtonsContainer then
        ButtonsContainer:Show()
    end

    AutoTimerCheckbox:Enable()
    AutoTimerCheckbox:Show()
    AutoTimerLabel:Show()
    ReadyCheckButton:SetEnabled(type(GetReadyCheckAPI()) == "function" and not countdownRunning and ((not groupLockEnabled) or inGroup))
    if countdownRunning then
        PullTimerButton:SetEnabled(true)
    else
        PullTimerButton:SetEnabled(type(GetTimerAPI()) == "function" and IsActivationReady() and ((not groupLockEnabled) or inGroup))
    end

    ReadyCheckButton:Show()
    PullTimerButton:Show()
end

local function EnsureKeystoneButtons()
    if not KeystoneFrame then
        return false
    end

    if ButtonsContainer and AutoTimerCheckbox and AutoTimerLabel and ReadyCheckButton and PullTimerButton then
        return true
    end

    ButtonsContainer = CreateFrame("Frame", nil, KeystoneFrame)
    ButtonsContainer:SetSize(1, 24)

    AutoTimerCheckbox = CreateFrame("CheckButton", nil, ButtonsContainer, "UICheckButtonTemplate")
    AutoTimerCheckbox:SetSize(24, 24)
    AutoTimerCheckbox:SetScript("OnClick", function(self)
        Misc.SetKeystoneAutoTimerEnabled(self:GetChecked())
    end)

    AutoTimerLabel = ButtonsContainer:CreateFontString(nil, "OVERLAY")
    AutoTimerLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    AutoTimerLabel:SetTextColor(1, 1, 1, 1)
    AutoTimerLabel:SetJustifyH("LEFT")
    AutoTimerLabel:SetJustifyV("MIDDLE")

    ReadyCheckButton = CreateFrame("Button", nil, ButtonsContainer, "UIPanelButtonTemplate")
    ReadyCheckButton:SetHeight(24)
    ReadyCheckButton:SetScript("OnClick", function()
        local doReadyCheck = GetReadyCheckAPI()
        if Misc.IsKeystoneAutoTimerEnabled() and IsActivationReady() then
            AutoTimerReadyCheckRequestedAt = GetNow()
            PendingReadyCheck = nil
        else
            CancelAutoTimerPreparation()
        end

        if type(doReadyCheck) == "function" then
            pcall(doReadyCheck)
        end
    end)

    PullTimerButton = CreateFrame("Button", nil, ButtonsContainer, "UIPanelButtonTemplate")
    PullTimerButton:SetHeight(24)
    PullTimerButton:SetScript("OnClick", function()
        StartAutomaticActivationCountdown()
    end)

    return true
end

local function InitializeChallengesUI()
    if ChallengesUIInitialized then
        RefreshKeystoneButtons()
        return
    end

    KeystoneFrame = rawget(_G, "ChallengesKeystoneFrame")
    if not KeystoneFrame then
        return
    end

    ChallengesUIInitialized = true
    if not EnsureKeystoneButtons() then
        return
    end

    KeystoneFrame:HookScript("OnShow", function()
        RefreshKeystoneButtons()
    end)

    KeystoneFrame:HookScript("OnHide", function()
        StopPendingCountdown(true)
        CancelAutoTimerPreparation()

        if ButtonsContainer then
            ButtonsContainer:Hide()
        end

        if ReadyCheckButton then
            ReadyCheckButton:Hide()
        end

        if PullTimerButton then
            PullTimerButton:Hide()
        end

        UpdateOriginalStartButtonVisibility()
    end)

    if KeystoneFrame.StartButton then
        KeystoneFrame.StartButton:HookScript("OnShow", function()
            UpdateOriginalStartButtonVisibility()
            RefreshKeystoneButtons()
        end)

        KeystoneFrame.StartButton:HookScript("OnEnable", function()
            RefreshKeystoneButtons()
        end)

        KeystoneFrame.StartButton:HookScript("OnDisable", function()
            RefreshKeystoneButtons()
        end)
    end

    RefreshKeystoneButtons()
end

function Misc.SetKeystoneActionsEnabled(value)
    Misc.GetMiscDB().keystoneActions = value == true

    if value ~= true then
        StopPendingCountdown(true)
        CancelAutoTimerPreparation()
    end

    RefreshKeystoneButtons()
end

function Misc.SetKeystoneAutoTimerEnabled(value)
    Misc.GetMiscDB().keystoneAutoTimer = value == true

    if value ~= true then
        CancelAutoTimerPreparation()
    end

    RefreshKeystoneButtons()
end

function Misc.SetKeystoneGroupLockEnabled(value)
    Misc.GetMiscDB().keystoneGroupLock = value == true

    if value == true and not (IsInGroup and IsInGroup()) then
        StopPendingCountdown(true)
        CancelAutoTimerPreparation()
    end

    RefreshKeystoneButtons()
end

function Misc.SetKeystoneCountdownSeconds(value)
    Misc.GetMiscDB().keystoneCountdownSeconds = NormalizeCountdownSeconds(value)
    RefreshKeystoneButtons()
end

KeystoneActionsWatcher:RegisterEvent("ADDON_LOADED")
KeystoneActionsWatcher:RegisterEvent("PLAYER_LOGIN")
KeystoneActionsWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
KeystoneActionsWatcher:RegisterEvent("GROUP_ROSTER_UPDATE")
KeystoneActionsWatcher:RegisterEvent("READY_CHECK")
KeystoneActionsWatcher:RegisterEvent("READY_CHECK_CONFIRM")
KeystoneActionsWatcher:RegisterEvent("READY_CHECK_FINISHED")
KeystoneActionsWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1, eventArg2 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == "Blizzard_ChallengesUI" then
            InitializeChallengesUI()
        end

        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if GetChallengesUILoaded() then
            InitializeChallengesUI()
        else
            RefreshKeystoneButtons()
        end

        return
    end

    if event == "READY_CHECK" then
        local initiatorName = eventArg1
        local now = GetNow()
        local requestedRecently = AutoTimerReadyCheckRequestedAt > 0 and (now - AutoTimerReadyCheckRequestedAt) <= 3

        if requestedRecently and Misc.IsKeystoneAutoTimerEnabled() and Misc.IsKeystoneActionsEnabled() and IsActivationReady() and IsPlayerReadyCheckInitiator(initiatorName) then
            PendingReadyCheck = BuildPendingReadyCheckState(initiatorName)
        else
            PendingReadyCheck = nil
        end

        AutoTimerReadyCheckRequestedAt = 0
        RefreshKeystoneButtons()
        return
    end

    if event == "READY_CHECK_CONFIRM" then
        local unitTarget = eventArg1
        local isReady = eventArg2

        if PendingReadyCheck and UnitGUID and unitTarget and isReady ~= nil then
            local guid = UnitGUID(unitTarget)
            if guid and PendingReadyCheck.awaiting[guid] then
                if isReady == true then
                    PendingReadyCheck.awaiting[guid] = nil
                    if next(PendingReadyCheck.awaiting) == nil then
                        PendingReadyCheck = nil
                        StartAutomaticActivationCountdown()
                        return
                    end
                else
                    PendingReadyCheck = nil
                end
            end
        end

        RefreshKeystoneButtons()
        return
    end

    if event == "READY_CHECK_FINISHED" then
        PendingReadyCheck = nil
        AutoTimerReadyCheckRequestedAt = 0
        RefreshKeystoneButtons()
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        PendingReadyCheck = nil
    end

    RefreshKeystoneButtons()
end)