local ADDON_NAME, BeavisQoL = ...

BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG

local INVITE_TIMER_BAR_HEIGHT = 12
local DEFAULT_LFG_INVITE_DURATION = 40
local STATIC_POPUP_NUM_DIALOGS = rawget(_G, "STATICPOPUP_NUMDIALOGS") or 4
local COUNTDOWN_SOUND_BASE_PATH = "Interface\\AddOns\\BeavisQoL\\Media\\Sounds\\Countdown\\"
local COUNTDOWN_SOUND_PATHS = {
    [5] = COUNTDOWN_SOUND_BASE_PATH .. "five.wav",
    [4] = COUNTDOWN_SOUND_BASE_PATH .. "four.wav",
    [3] = COUNTDOWN_SOUND_BASE_PATH .. "three.wav",
    [2] = COUNTDOWN_SOUND_BASE_PATH .. "two.wav",
    [1] = COUNTDOWN_SOUND_BASE_PATH .. "one.wav",
}

local QueueInviteWatcher = CreateFrame("Frame")
local HookedFrames = {}

local STATIC_POPUP_QUEUE_TYPES = {
    CONFIRM_BATTLEFIELD_ENTRY = true,
    BATTLEFIELD_MGR_ENTRY_INVITE = true,
    BATTLEFIELD_MGR_QUEUE_INVITE = true,
}

local REMAINING_TIME_FIELDS = {
    "timeOut",
    "timeout",
    "timeleft",
    "timeLeft",
    "remainingTime",
    "timeRemaining",
}

local function SafeRegisterEvent(frame, eventName)
    if not frame or type(eventName) ~= "string" or eventName == "" then
        return false
    end

    local ok = pcall(frame.RegisterEvent, frame, eventName)
    return ok == true
end

local function EnsureInviteTimerDefaults()
    local db = LFG.GetLFGDB and LFG.GetLFGDB() or nil
    if not db then
        return nil
    end

    if db.inviteTimerEnabled == nil then
        db.inviteTimerEnabled = true
    end

    if db.inviteTimerCountdownEnabled == nil then
        db.inviteTimerCountdownEnabled = true
    end

    return db
end

local function NormalizeRemainingSeconds(value)
    if type(value) ~= "number" or value <= 0 then
        return nil
    end

    if value > 1000 then
        return value / 1000
    end

    return value
end

local function ReadDialogRemainingTime(frame)
    if not frame then
        return nil
    end

    for _, fieldName in ipairs(REMAINING_TIME_FIELDS) do
        local value = NormalizeRemainingSeconds(frame[fieldName])
        if value then
            return value
        end
    end

    return nil
end

local function FormatRemainingSeconds(seconds)
    if type(seconds) ~= "number" then
        return ""
    end

    if seconds >= 10 then
        return string.format("%ds", math.floor(seconds + 0.5))
    end

    return string.format("%.1fs", seconds)
end

local function GetTimerBarColor(remainingSeconds, totalSeconds)
    local ratio = 0
    if type(remainingSeconds) == "number" and type(totalSeconds) == "number" and totalSeconds > 0 then
        ratio = remainingSeconds / totalSeconds
    end

    if ratio > 0.50 then
        return 0.18, 0.86, 0.30
    end

    if ratio > 0.25 then
        return 1.00, 0.78, 0.22
    end

    return 0.96, 0.24, 0.24
end

local function GetTrackedBattlefieldIndex()
    if type(GetBattlefieldStatus) ~= "function" then
        return nil
    end

    local maxQueues = 0
    if type(GetMaxBattlefieldID) == "function" then
        maxQueues = GetMaxBattlefieldID() or 0
    elseif type(MAX_BATTLEFIELD_QUEUES) == "number" then
        maxQueues = MAX_BATTLEFIELD_QUEUES
    end

    for queueIndex = 1, maxQueues do
        local status = GetBattlefieldStatus(queueIndex)
        if status == "confirm" then
            return queueIndex
        end
    end

    return nil
end

local function GetBattlefieldInviteRemainingTime(frame)
    local remainingSeconds = nil
    local queueIndex = GetTrackedBattlefieldIndex()

    if queueIndex and type(GetBattlefieldPortExpiration) == "function" then
        remainingSeconds = NormalizeRemainingSeconds(GetBattlefieldPortExpiration(queueIndex))
    end

    if not remainingSeconds then
        remainingSeconds = ReadDialogRemainingTime(frame)
    end

    if not remainingSeconds then
        return nil
    end

    local totalSeconds = frame.BeavisInviteTimerTotalSeconds
    if type(totalSeconds) ~= "number" or remainingSeconds > totalSeconds then
        totalSeconds = remainingSeconds
        frame.BeavisInviteTimerTotalSeconds = totalSeconds
    end

    return remainingSeconds, totalSeconds
end

local function GetLFGInviteRemainingTime(frame)
    if type(GetLFGProposal) ~= "function" then
        return nil
    end

    local proposalExists = GetLFGProposal()
    if not proposalExists then
        return nil
    end

    local remainingSeconds = ReadDialogRemainingTime(frame)
    if not remainingSeconds then
        local shownAt = frame.BeavisInviteTimerShownAt or GetTime()
        remainingSeconds = math.max(0, DEFAULT_LFG_INVITE_DURATION - (GetTime() - shownAt))
    end

    local totalSeconds = frame.BeavisInviteTimerTotalSeconds
    if type(totalSeconds) ~= "number" or totalSeconds <= 0 then
        totalSeconds = DEFAULT_LFG_INVITE_DURATION
    end
    if remainingSeconds > totalSeconds then
        totalSeconds = remainingSeconds
    end

    frame.BeavisInviteTimerTotalSeconds = totalSeconds
    return remainingSeconds, totalSeconds
end

local function HideTimerBarForFrame(frame)
    local timerBar = frame and frame.BeavisInviteTimerBar or nil
    if not timerBar then
        return
    end

    if frame then
        frame.BeavisInviteTimerLastCountdownSecond = nil
    end

    timerBar:SetScript("OnUpdate", nil)
    timerBar:Hide()
end

local function PlayCountdownSound(second)
    local soundPath = COUNTDOWN_SOUND_PATHS[second]
    if not soundPath or type(PlaySoundFile) ~= "function" then
        return
    end

    pcall(PlaySoundFile, soundPath, "Master")
end

local function MaybePlayCountdownSound(frame, remainingSeconds)
    if not frame or type(remainingSeconds) ~= "number" then
        return
    end

    local db = EnsureInviteTimerDefaults()
    if not db or db.inviteTimerCountdownEnabled ~= true then
        return
    end

    local countdownSecond = math.ceil(remainingSeconds)
    if countdownSecond < 1 or countdownSecond > 5 then
        return
    end

    if frame.BeavisInviteTimerLastCountdownSecond == countdownSecond then
        return
    end

    frame.BeavisInviteTimerLastCountdownSecond = countdownSecond
    PlayCountdownSound(countdownSecond)
end

local function UpdateTimerBar(timerBar)
    if not timerBar or not timerBar.ParentFrame or not timerBar.Provider then
        return
    end

    local parentFrame = timerBar.ParentFrame
    if not parentFrame:IsShown() then
        HideTimerBarForFrame(parentFrame)
        return
    end

    local remainingSeconds, totalSeconds = timerBar.Provider(parentFrame)
    if type(remainingSeconds) ~= "number" or remainingSeconds <= 0 then
        HideTimerBarForFrame(parentFrame)
        return
    end

    totalSeconds = math.max(totalSeconds or remainingSeconds, remainingSeconds, 0.01)

    local red, green, blue = GetTimerBarColor(remainingSeconds, totalSeconds)
    timerBar:SetMinMaxValues(0, totalSeconds)
    timerBar:SetValue(remainingSeconds)
    timerBar:SetStatusBarColor(red, green, blue, 0.92)
    timerBar.Text:SetText(FormatRemainingSeconds(remainingSeconds))
    MaybePlayCountdownSound(parentFrame, remainingSeconds)
    timerBar:Show()
end

local function TimerBarOnUpdate(self, elapsed)
    self.ElapsedSinceUpdate = (self.ElapsedSinceUpdate or 0) + elapsed
    if self.ElapsedSinceUpdate < 0.05 then
        return
    end

    self.ElapsedSinceUpdate = 0
    UpdateTimerBar(self)
end

local function ApplyTimerBarLayout(timerBar, parentFrame)
    if not timerBar or not parentFrame then
        return
    end

    timerBar:ClearAllPoints()

    if parentFrame == rawget(_G, "LFGDungeonReadyDialog") then
        local frameWidth = parentFrame:GetWidth() or 520
        timerBar:SetWidth(math.max(280, math.min(frameWidth - 220, 360)))
        timerBar:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 10)
        return
    end

    if parentFrame == rawget(_G, "PVPReadyDialog") or STATIC_POPUP_QUEUE_TYPES[parentFrame.which] == true then
        local frameWidth = parentFrame:GetWidth() or 520
        timerBar:SetWidth(math.max(280, math.min(frameWidth - 220, 360)))
        timerBar:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 10)
        return
    end

    if parentFrame.button1 and parentFrame.button2 then
        timerBar:SetPoint("BOTTOMLEFT", parentFrame.button1, "TOPLEFT", 0, 8)
        timerBar:SetPoint("BOTTOMRIGHT", parentFrame.button2, "TOPRIGHT", 0, 8)
        return
    end

    if parentFrame.button1 then
        timerBar:SetPoint("BOTTOMLEFT", parentFrame.button1, "TOPLEFT", -2, 8)
        timerBar:SetPoint("BOTTOMRIGHT", parentFrame.button1, "TOPRIGHT", 2, 8)
        return
    end

    timerBar:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 22, 38)
    timerBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -22, 38)
end

local function CreateTimerBar(parentFrame)
    if parentFrame.BeavisInviteTimerBar then
        return parentFrame.BeavisInviteTimerBar
    end

    local timerBar = CreateFrame("StatusBar", nil, parentFrame)
    timerBar:SetHeight(INVITE_TIMER_BAR_HEIGHT)
    timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBar:SetFrameStrata(parentFrame:GetFrameStrata())
    timerBar:SetFrameLevel(parentFrame:GetFrameLevel() + 6)
    timerBar:EnableMouse(false)
    ApplyTimerBarLayout(timerBar, parentFrame)

    local background = timerBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.04, 0.05, 0.72)
    timerBar.Background = background

    local borderTop = timerBar:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", timerBar, "TOPLEFT", -1, 1)
    borderTop:SetPoint("TOPRIGHT", timerBar, "TOPRIGHT", 1, 1)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.92, 0.78, 0.18, 0.78)

    local borderBottom = timerBar:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", timerBar, "BOTTOMLEFT", -1, -1)
    borderBottom:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", 1, -1)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.92, 0.78, 0.18, 0.52)

    local borderLeft = timerBar:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", timerBar, "TOPLEFT", -1, 1)
    borderLeft:SetPoint("BOTTOMLEFT", timerBar, "BOTTOMLEFT", -1, -1)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0.92, 0.78, 0.18, 0.52)

    local borderRight = timerBar:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", timerBar, "TOPRIGHT", 1, 1)
    borderRight:SetPoint("BOTTOMRIGHT", timerBar, "BOTTOMRIGHT", 1, -1)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0.92, 0.78, 0.18, 0.52)

    local text = timerBar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", timerBar, "CENTER", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    timerBar.Text = text

    timerBar.ParentFrame = parentFrame
    timerBar:Hide()

    parentFrame.BeavisInviteTimerBar = timerBar
    return timerBar
end

local function ActivateTimerBar(frame, provider)
    if not frame or not provider then
        return
    end

    local db = EnsureInviteTimerDefaults()
    if not db or db.inviteTimerEnabled ~= true then
        HideTimerBarForFrame(frame)
        return
    end

    local timerBar = CreateTimerBar(frame)
    ApplyTimerBarLayout(timerBar, frame)
    if type(frame.BeavisInviteTimerShownAt) ~= "number" then
        frame.BeavisInviteTimerShownAt = GetTime()
    end
    timerBar.Provider = provider
    timerBar.ElapsedSinceUpdate = 0
    UpdateTimerBar(timerBar)

    if timerBar:IsShown() then
        timerBar:SetScript("OnUpdate", TimerBarOnUpdate)
    end
end

local function IsRelevantStaticPopup(frame)
    if not frame or not frame:IsShown() then
        return false
    end

    return STATIC_POPUP_QUEUE_TYPES[frame.which] == true
end

local function RefreshLFGInviteDialog()
    local frame = rawget(_G, "LFGDungeonReadyDialog")
    if not frame then
        return
    end

    if frame:IsShown() then
        ActivateTimerBar(frame, GetLFGInviteRemainingTime)
    else
        HideTimerBarForFrame(frame)
    end
end

local function RefreshPvPInviteDialogs()
    local pvpDialog = rawget(_G, "PVPReadyDialog")
    if pvpDialog then
        if pvpDialog:IsShown() then
            ActivateTimerBar(pvpDialog, GetBattlefieldInviteRemainingTime)
        else
            HideTimerBarForFrame(pvpDialog)
        end
    end

    for dialogIndex = 1, STATIC_POPUP_NUM_DIALOGS do
        local popupFrame = rawget(_G, "StaticPopup" .. dialogIndex)
        if popupFrame then
            if IsRelevantStaticPopup(popupFrame) then
                ActivateTimerBar(popupFrame, GetBattlefieldInviteRemainingTime)
            else
                HideTimerBarForFrame(popupFrame)
            end
        end
    end
end

local function RefreshAllInviteTimers()
    RefreshLFGInviteDialog()
    RefreshPvPInviteDialogs()
end

local function HookFrame(frame)
    if not frame or HookedFrames[frame] then
        return
    end

    frame:HookScript("OnShow", function(self)
        self.BeavisInviteTimerShownAt = GetTime()
        self.BeavisInviteTimerTotalSeconds = ReadDialogRemainingTime(self)
        self.BeavisInviteTimerLastCountdownSecond = nil
        RefreshAllInviteTimers()
    end)

    frame:HookScript("OnHide", function(self)
        self.BeavisInviteTimerShownAt = nil
        self.BeavisInviteTimerTotalSeconds = nil
        self.BeavisInviteTimerLastCountdownSecond = nil
        HideTimerBarForFrame(self)
    end)

    HookedFrames[frame] = true
end

local function HookKnownFrames()
    HookFrame(rawget(_G, "LFGDungeonReadyDialog"))
    HookFrame(rawget(_G, "PVPReadyDialog"))

    for dialogIndex = 1, STATIC_POPUP_NUM_DIALOGS do
        HookFrame(rawget(_G, "StaticPopup" .. dialogIndex))
    end
end

function LFG.IsInviteTimerEnabled()
    local db = EnsureInviteTimerDefaults()
    return db and db.inviteTimerEnabled == true or false
end

function LFG.SetInviteTimerEnabled(value)
    local db = EnsureInviteTimerDefaults()
    if not db then
        return
    end

    db.inviteTimerEnabled = value and true or false

    if db.inviteTimerEnabled then
        RefreshAllInviteTimers()
    else
        for frame in pairs(HookedFrames) do
            HideTimerBarForFrame(frame)
        end
    end
end

function LFG.IsInviteTimerCountdownEnabled()
    local db = EnsureInviteTimerDefaults()
    return db and db.inviteTimerCountdownEnabled == true or false
end

function LFG.SetInviteTimerCountdownEnabled(value)
    local db = EnsureInviteTimerDefaults()
    if not db then
        return
    end

    db.inviteTimerCountdownEnabled = value and true or false

    if db.inviteTimerCountdownEnabled ~= true then
        for frame in pairs(HookedFrames) do
            if frame then
                frame.BeavisInviteTimerLastCountdownSecond = nil
            end
        end
    end
end

SafeRegisterEvent(QueueInviteWatcher, "PLAYER_LOGIN")
SafeRegisterEvent(QueueInviteWatcher, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(QueueInviteWatcher, "LFG_PROPOSAL_SHOW")
SafeRegisterEvent(QueueInviteWatcher, "UPDATE_BATTLEFIELD_STATUS")
SafeRegisterEvent(QueueInviteWatcher, "BATTLEFIELD_MGR_ENTRY_INVITE")
SafeRegisterEvent(QueueInviteWatcher, "BATTLEFIELD_MGR_QUEUE_INVITE")
QueueInviteWatcher:SetScript("OnEvent", function()
    HookKnownFrames()
    RefreshAllInviteTimers()
end)

HookKnownFrames()
