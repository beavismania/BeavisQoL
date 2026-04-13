local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.FishingModule = BeavisQoL.FishingModule or {}
local FishingModule = BeavisQoL.FishingModule

local FISHING_SPELL_ID = 131474
local WAITING_TIMEOUT = 32
local BITE_READY_MIN_DELAY = 1.25
local STANDARD_SFX = 1.00
local DEFAULT_SOUND_MULTIPLIER = 1.00
local MIN_SOUND_MULTIPLIER = 1.00
local MAX_SOUND_MULTIPLIER = 2.00
local INTERACTION_COMMAND = "INTERACTTARGET"
local SOFT_INTERACT_CVAR = "SoftTargetInteract"
local SOFT_INTERACT_FISHING_VALUE = "3"
local FISHING_SOUND_CVARS = {
    "Sound_MasterVolume",
    "Sound_SFXVolume",
    "Sound_EnableAmbience",
    "Sound_MusicVolume",
    "Sound_EnableAllSound",
    "Sound_EnablePetSounds",
    "Sound_EnableSoundWhenGameIsInBG",
    "Sound_EnableSFX",
}

local PageFishing
local EnableCheckbox
local SetKeyButton
local ClearKeyButton
local CurrentKeyValue
local StatusValue
local InteractValue
local SoundCheckbox
local SoundSlider
local SoundSliderText
local SoundHint
local CaptureOverlay
local CaptureTitle
local CaptureHint

local BindingOwner
local CastButton

local isRefreshingPage = false
local isCapturingKey = false
local currentMode = "idle"
local waitingStartedAt = 0
local waitingExpiresAt = 0
local waitingInitialSoftTargetGUID = nil
local waitingInitialSoftTargetPresent = false
local waitingInitialSoftTargetInteractable = false
local waitingReadyTriggered = false
local lastSoftInteractGUID = nil
local pendingBindingRefresh = false
local pendingStateRefresh = false
local pendingCastButtonRefresh = false
local cachedFishingSoundSettings = nil
local overriddenSoftInteractValue = nil

local function Clamp(value, minValue, maxValue)
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

local function GetFishingSettings()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.fishing = BeavisQoLDB.fishing or {}

    local db = BeavisQoLDB.fishing

    if db.enabled == nil then
        db.enabled = false
    end

    if type(db.key) ~= "string" or db.key == "" then
        db.key = nil
    end

    if db.soundBoostEnabled == nil then
        db.soundBoostEnabled = true
    end

    if db.bitePromptEnabled ~= nil then
        db.bitePromptEnabled = nil
    end

    if type(db.soundMultiplier) ~= "number" then
        db.soundMultiplier = DEFAULT_SOUND_MULTIPLIER
    end

    db.soundMultiplier = Clamp(db.soundMultiplier, MIN_SOUND_MULTIPLIER, MAX_SOUND_MULTIPLIER)

    return db
end

local function GetFishingSpellName()
    local spellName

    if C_Spell and C_Spell.GetSpellName then
        spellName = C_Spell.GetSpellName(FISHING_SPELL_ID)
    end

    if type(spellName) ~= "string" or spellName == "" then
        return nil
    end

    return spellName
end

local function IsFishingKnown()
    if C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell then
        local spellBookItemSlotIndex = C_SpellBook.FindSpellBookSlotForSpell(FISHING_SPELL_ID, false, true, false, false)
        return spellBookItemSlotIndex ~= nil
    end

    return GetFishingSpellName() ~= nil
end

local function IsFishingChannelActive()
    if not UnitChannelInfo then
        return false
    end

    local channelName = UnitChannelInfo("player")
    local fishingSpellName = GetFishingSpellName()

    return channelName ~= nil and fishingSpellName ~= nil and channelName == fishingSpellName
end

local function GetCurrentCVarValue(cvarName)
    if not GetCVar then
        return nil
    end

    local value = GetCVar(cvarName)
    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

local function SetCurrentCVarValue(cvarName, value)
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(cvarName, tostring(value))
        return
    end

    if SetCVar then
        SetCVar(cvarName, tostring(value))
    end
end

local function SetCurrentVolumeCVar(cvarName, value)
    local normalizedValue = string.format("%.2f", Clamp(tonumber(value) or 0, 0, STANDARD_SFX))

    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar(cvarName, normalizedValue)
        return
    end

    if SetCVar then
        SetCVar(cvarName, normalizedValue)
    end
end

local function SetCurrentSFXVolume(value)
    SetCurrentVolumeCVar("Sound_SFXVolume", value)
end

local function SetCurrentMasterVolume(value)
    SetCurrentVolumeCVar("Sound_MasterVolume", value)
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor((Clamp(tonumber(value) or DEFAULT_SOUND_MULTIPLIER, MIN_SOUND_MULTIPLIER, MAX_SOUND_MULTIPLIER) * 100) + 0.5))
end

local function IsFishingActiveMode(mode)
    return mode == "waiting" or mode == "ready"
end

local function GetCurrentSoftInteractState()
    local state = {
        exists = false,
        guid = lastSoftInteractGUID,
        isGameObject = true,
        interactable = false,
    }

    if state.guid ~= nil then
        state.exists = true
    end

    if UnitExists and UnitExists("softinteract") then
        state.exists = true

        if UnitGUID then
            state.guid = UnitGUID("softinteract") or state.guid
        end

        if state.guid == nil then
            state.guid = "softinteract"
        end

        if UnitIsGameObject then
            state.isGameObject = UnitIsGameObject("softinteract") == true
        end

        if UnitIsInteractable then
            state.interactable = UnitIsInteractable("softinteract") == true
        else
            state.interactable = true
        end
    end

    return state
end

local function GetCurrentSoftInteractGUID(requireInteractable)
    local state = GetCurrentSoftInteractState()
    if not state.exists or state.isGameObject ~= true then
        return nil
    end

    if requireInteractable == true and state.interactable ~= true then
        return nil
    end

    return state.guid
end

local function MarkFishingBiteReady(softTargetGUID)
    if softTargetGUID ~= nil then
        lastSoftInteractGUID = softTargetGUID
    end

    if waitingStartedAt <= 0 or GetTime() < (waitingStartedAt + BITE_READY_MIN_DELAY) then
        return
    end

    if softTargetGUID == nil and GetCurrentSoftInteractGUID(false) == nil then
        return
    end

    waitingReadyTriggered = true
end

local function HasFishingBiteReadyTarget(checkTime)
    local now = tonumber(checkTime) or GetTime()
    if waitingStartedAt <= 0 or now < (waitingStartedAt + BITE_READY_MIN_DELAY) then
        return false
    end

    local currentSoftTargetState = GetCurrentSoftInteractState()
    if not currentSoftTargetState.exists or currentSoftTargetState.isGameObject ~= true then
        return false
    end

    if currentSoftTargetState.interactable == true and waitingInitialSoftTargetInteractable ~= true then
        return true
    end

    if waitingInitialSoftTargetPresent ~= true then
        return currentSoftTargetState.guid ~= nil
    end

    if waitingInitialSoftTargetGUID ~= nil and currentSoftTargetState.guid ~= nil and currentSoftTargetState.guid ~= waitingInitialSoftTargetGUID then
        return true
    end

    return waitingReadyTriggered == true
end

local function CaptureFishingSoundSettings()
    local snapshot = {}

    for _, cvarName in ipairs(FISHING_SOUND_CVARS) do
        local currentValue = GetCurrentCVarValue(cvarName)
        if currentValue ~= nil then
            snapshot[cvarName] = currentValue
        end
    end

    return snapshot
end

local function GetSnapshotVolume(snapshot, cvarName)
    return Clamp(tonumber(snapshot and snapshot[cvarName]) or STANDARD_SFX, 0, STANDARD_SFX)
end

local function RestoreFishingSoundSettings()
    if cachedFishingSoundSettings == nil then
        return
    end

    for _, cvarName in ipairs(FISHING_SOUND_CVARS) do
        local originalValue = cachedFishingSoundSettings[cvarName]
        if originalValue ~= nil then
            SetCurrentCVarValue(cvarName, originalValue)
        end
    end

    cachedFishingSoundSettings = nil
end

local function ApplyFishingSoundSettings(multiplier)
    if cachedFishingSoundSettings == nil then
        cachedFishingSoundSettings = CaptureFishingSoundSettings()
    end

    SetCurrentCVarValue("Sound_EnableAllSound", "1")
    SetCurrentCVarValue("Sound_EnableSFX", "1")
    SetCurrentCVarValue("Sound_EnableSoundWhenGameIsInBG", "1")
    SetCurrentCVarValue("Sound_EnableAmbience", "0")
    SetCurrentCVarValue("Sound_MusicVolume", "0")
    SetCurrentCVarValue("Sound_EnablePetSounds", "0")

    SetCurrentMasterVolume(GetSnapshotVolume(cachedFishingSoundSettings, "Sound_MasterVolume") * multiplier)
    SetCurrentSFXVolume(GetSnapshotVolume(cachedFishingSoundSettings, "Sound_SFXVolume") * multiplier)
end

local function FormatBindingKey(key)
    if not key or key == "" then
        return L("FISHING_HELPER_NO_KEY")
    end

    local parts = {}

    for token in string.gmatch(key, "[^-]+") do
        if token == "CTRL" or token == "ALT" or token == "SHIFT" or token == "META" then
            parts[#parts + 1] = token
        else
            parts[#parts + 1] = GetBindingText and (GetBindingText(token, "KEY_") or token) or token
        end
    end

    return table.concat(parts, "-")
end

local function GetInteractionBindingText()
    if not GetBindingKey then
        return L("FISHING_HELPER_INTERACT_BINDING_NONE")
    end

    local keys = { GetBindingKey(INTERACTION_COMMAND) }
    if #keys == 0 then
        return L("FISHING_HELPER_INTERACT_BINDING_NONE")
    end

    local formatted = {}
    for _, key in ipairs(keys) do
        formatted[#formatted + 1] = FormatBindingKey(key)
    end

    return table.concat(formatted, ", ")
end

local function RefreshSoundSliderText()
    if not SoundSliderText or not SoundSlider then
        return
    end

    SoundSliderText:SetText(string.format("%s: %s", L("FISHING_HELPER_SOUND_MIN"), GetSliderPercentText(SoundSlider:GetValue())))
end

local function RefreshCastButtonAttributes()
    if not CastButton then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        pendingCastButtonRefresh = true
        return
    end

    pendingCastButtonRefresh = false

    local fishingSpellName = IsFishingKnown() and GetFishingSpellName() or nil

    CastButton:SetAttribute("type1", "macro")
    CastButton:SetAttribute("macrotext1", fishingSpellName and ("/cast " .. fishingSpellName) or nil)
end

local function ClearFishingOverrideBinding()
    if not BindingOwner or not ClearOverrideBindings then
        return
    end

    ClearOverrideBindings(BindingOwner)
end

local function RefreshPageState()
    if PageFishing and PageFishing.RefreshState then
        PageFishing:RefreshState()
    end
end

local function RestoreSoftInteractCVar()
    if overriddenSoftInteractValue ~= nil then
        SetCurrentCVarValue(SOFT_INTERACT_CVAR, overriddenSoftInteractValue)
        overriddenSoftInteractValue = nil
    end
end

local function RefreshSoftInteractCVar()
    local settings = GetFishingSettings()
    local shouldEnableSoftInteract = settings.enabled == true and IsFishingActiveMode(currentMode)

    if shouldEnableSoftInteract then
        local currentValue = GetCurrentCVarValue(SOFT_INTERACT_CVAR)

        if currentValue ~= SOFT_INTERACT_FISHING_VALUE then
            if overriddenSoftInteractValue == nil then
                overriddenSoftInteractValue = currentValue or "0"
            end

            SetCurrentCVarValue(SOFT_INTERACT_CVAR, SOFT_INTERACT_FISHING_VALUE)
        end

        return
    end

    RestoreSoftInteractCVar()
end

local function RestoreSoundBoost()
    RestoreFishingSoundSettings()
end

local function RefreshSoundBoost()
    local settings = GetFishingSettings()
    local shouldBoost = settings.enabled == true and settings.soundBoostEnabled == true and IsFishingActiveMode(currentMode)

    if shouldBoost then
        ApplyFishingSoundSettings(settings.soundMultiplier)
        return
    end

    RestoreSoundBoost()
end

local function RefreshOverrideBinding()
    if not BindingOwner or not SetOverrideBinding or not SetOverrideBindingClick then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        pendingBindingRefresh = true
        return
    end

    pendingBindingRefresh = false

    local settings = GetFishingSettings()
    local fishingSpellName = IsFishingKnown() and GetFishingSpellName() or nil

    ClearFishingOverrideBinding()

    if isCapturingKey or settings.enabled ~= true or not settings.key or not fishingSpellName then
        return
    end

    if IsFishingActiveMode(currentMode) then
        SetOverrideBinding(BindingOwner, true, settings.key, INTERACTION_COMMAND)
        return
    end

    if CastButton and CastButton:GetAttribute("macrotext1") then
        SetOverrideBindingClick(BindingOwner, true, settings.key, CastButton:GetName(), "LeftButton")
    end
end

local function RefreshStateFromGame()
    pendingStateRefresh = false

    local now = GetTime()
    local wasActiveMode = IsFishingActiveMode(currentMode)

    if IsFishingChannelActive() then
        if not wasActiveMode then
            local initialSoftTargetState = GetCurrentSoftInteractState()
            waitingStartedAt = now
            waitingInitialSoftTargetGUID = initialSoftTargetState.guid
            waitingInitialSoftTargetPresent = initialSoftTargetState.exists and initialSoftTargetState.isGameObject == true
            waitingInitialSoftTargetInteractable = initialSoftTargetState.interactable == true
            waitingReadyTriggered = false
        end

        currentMode = HasFishingBiteReadyTarget(now) and "ready" or "waiting"
        waitingExpiresAt = now + WAITING_TIMEOUT
    else
        currentMode = "idle"
        waitingStartedAt = 0
        waitingExpiresAt = 0
        waitingInitialSoftTargetGUID = nil
        waitingInitialSoftTargetPresent = false
        waitingInitialSoftTargetInteractable = false
        waitingReadyTriggered = false
        lastSoftInteractGUID = nil
    end

    RefreshSoundBoost()
    RefreshSoftInteractCVar()
    RefreshOverrideBinding()
    RefreshPageState()
end

local function QueueStateRefresh()
    if pendingStateRefresh then
        return
    end

    pendingStateRefresh = true
end

local function StopCaptureMode()
    isCapturingKey = false

    if CaptureOverlay then
        CaptureOverlay:Hide()
    end

    RefreshOverrideBinding()
    RefreshPageState()
end

local function NormalizeCapturedKey(key)
    key = string.upper(tostring(key or ""))

    if key == "" or key == "UNKNOWN" then
        return nil
    end

    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" or key == "LMETA" or key == "RMETA" then
        return nil
    end

    local parts = {}

    if IsControlKeyDown and IsControlKeyDown() then
        parts[#parts + 1] = "CTRL"
    end

    if IsAltKeyDown and IsAltKeyDown() then
        parts[#parts + 1] = "ALT"
    end

    if IsShiftKeyDown and IsShiftKeyDown() then
        parts[#parts + 1] = "SHIFT"
    end

    if IsMetaKeyDown and IsMetaKeyDown() then
        parts[#parts + 1] = "META"
    end

    parts[#parts + 1] = key
    return table.concat(parts, "-")
end

local function BeginCaptureMode()
    isCapturingKey = true
    ClearFishingOverrideBinding()

    if CaptureOverlay then
        CaptureOverlay:Show()
    end

    RefreshPageState()
end

function FishingModule.IsEnabled()
    return GetFishingSettings().enabled == true
end

function FishingModule.SetEnabled(enabled)
    GetFishingSettings().enabled = enabled == true
    RefreshStateFromGame()
end

function FishingModule.GetKey()
    return GetFishingSettings().key
end

function FishingModule.SetKey(key)
    local settings = GetFishingSettings()

    if type(key) ~= "string" or key == "" then
        settings.key = nil
    else
        settings.key = string.upper(key)
    end

    RefreshOverrideBinding()
    RefreshPageState()
end

function FishingModule.ClearKey()
    FishingModule.SetKey(nil)
end

function FishingModule.GetSoundBoostEnabled()
    return GetFishingSettings().soundBoostEnabled == true
end

function FishingModule.SetSoundBoostEnabled(enabled)
    GetFishingSettings().soundBoostEnabled = enabled == true
    RefreshSoundBoost()
    RefreshPageState()
end

function FishingModule.GetSoundMultiplier()
    return GetFishingSettings().soundMultiplier
end

function FishingModule.SetSoundMultiplier(value)
    GetFishingSettings().soundMultiplier = Clamp(tonumber(value) or DEFAULT_SOUND_MULTIPLIER, MIN_SOUND_MULTIPLIER, MAX_SOUND_MULTIPLIER)
    RefreshSoundBoost()
    RefreshPageState()
end

local function GetStatusText()
    local settings = GetFishingSettings()

    if isCapturingKey then
        return L("FISHING_HELPER_STATUS_CAPTURE")
    end

    if settings.enabled ~= true then
        return L("FISHING_HELPER_STATUS_DISABLED")
    end

    if not IsFishingKnown() then
        return L("FISHING_HELPER_STATUS_NO_SPELL")
    end

    if currentMode == "ready" then
        return L("FISHING_HELPER_STATUS_READY")
    end

    if currentMode == "waiting" then
        return L("FISHING_HELPER_STATUS_WAITING")
    end

    return L("FISHING_HELPER_STATUS_IDLE")
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

local function CreateSlider(parent)
    local slider = CreateFrame("Slider", ADDON_NAME .. "FishingSoundSlider", parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(MIN_SOUND_MULTIPLIER, MAX_SOUND_MULTIPLIER)
    slider:SetValueStep(0.01)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end
    slider:SetWidth(260)
    slider:EnableMouse(MIN_SOUND_MULTIPLIER < MAX_SOUND_MULTIPLIER)

    local lowLabel = _G[slider:GetName() .. "Low"]
    local highLabel = _G[slider:GetName() .. "High"]
    local textLabel = _G[slider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(MIN_SOUND_MULTIPLIER))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(MAX_SOUND_MULTIPLIER))
    end

    if textLabel then
        textLabel:SetText("")
    end

    return slider, textLabel
end

local function CreateSecureFrames()
    if BindingOwner then
        return
    end

    BindingOwner = CreateFrame("Frame", ADDON_NAME .. "FishingBindingOwner", UIParent)
    BindingOwner:SetSize(1, 1)
    BindingOwner:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)

    CastButton = CreateFrame("Button", ADDON_NAME .. "FishingCastButton", UIParent, "SecureActionButtonTemplate")
    CastButton:SetSize(1, 1)
    CastButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -120, 120)
    CastButton:SetAttribute("useOnKeyDown", false)
    CastButton:RegisterForClicks("AnyUp")

    RefreshCastButtonAttributes()
end

PageFishing = CreateFrame("Frame", nil, Content)
PageFishing:SetAllPoints()
PageFishing:Hide()

local PageFishingScrollFrame = CreateFrame("ScrollFrame", nil, PageFishing, "UIPanelScrollFrameTemplate")
PageFishingScrollFrame:SetPoint("TOPLEFT", PageFishing, "TOPLEFT", 0, 0)
PageFishingScrollFrame:SetPoint("BOTTOMRIGHT", PageFishing, "BOTTOMRIGHT", -28, 0)
PageFishingScrollFrame:EnableMouseWheel(true)

local PageFishingContent = CreateFrame("Frame", nil, PageFishingScrollFrame)
PageFishingContent:SetSize(1, 1)
PageFishingScrollFrame:SetScrollChild(PageFishingContent)

local IntroPanel = CreateFrame("Frame", nil, PageFishingContent)
IntroPanel:SetPoint("TOPLEFT", PageFishingContent, "TOPLEFT", 20, -18)
IntroPanel:SetPoint("RIGHT", PageFishingContent, "RIGHT", -20, 0)
IntroPanel:SetHeight(146)

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

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)

local UsageHint = IntroPanel:CreateFontString(nil, "OVERLAY")
UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
UsageHint:SetJustifyH("LEFT")
UsageHint:SetJustifyV("TOP")
UsageHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
UsageHint:SetTextColor(0.84, 0.84, 0.86, 1)

local ControlPanel = CreatePanel(PageFishingContent, IntroPanel, -18, 188)

local ControlTitle = ControlPanel:CreateFontString(nil, "OVERLAY")
ControlTitle:SetPoint("TOPLEFT", ControlPanel, "TOPLEFT", 18, -14)
ControlTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
ControlTitle:SetTextColor(1, 0.88, 0.62, 1)
ControlTitle:SetText(L("DISPLAY"))

EnableCheckbox = CreateCheckbox(ControlPanel, L("FISHING_HELPER_ENABLE"), function(self)
    FishingModule.SetEnabled(self:GetChecked())
end)
EnableCheckbox:SetPoint("TOPLEFT", ControlTitle, "BOTTOMLEFT", -4, -12)

SetKeyButton = CreateActionButton(ControlPanel, 160, L("FISHING_HELPER_SET_KEY"), function()
    BeginCaptureMode()
end)
SetKeyButton:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", -4, -18)

ClearKeyButton = CreateActionButton(ControlPanel, 160, L("FISHING_HELPER_CLEAR_KEY"), function()
    FishingModule.ClearKey()
end)
ClearKeyButton:SetPoint("LEFT", SetKeyButton, "RIGHT", 12, 0)

local CurrentKeyLabel = ControlPanel:CreateFontString(nil, "OVERLAY")
CurrentKeyLabel:SetPoint("TOPLEFT", SetKeyButton, "BOTTOMLEFT", 0, -16)
CurrentKeyLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CurrentKeyLabel:SetTextColor(0.85, 0.85, 0.85, 1)

CurrentKeyValue = ControlPanel:CreateFontString(nil, "OVERLAY")
CurrentKeyValue:SetPoint("TOPLEFT", CurrentKeyLabel, "BOTTOMLEFT", 0, -4)
CurrentKeyValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
CurrentKeyValue:SetJustifyH("LEFT")
CurrentKeyValue:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CurrentKeyValue:SetTextColor(0.95, 0.91, 0.85, 1)

local StatusLabel = ControlPanel:CreateFontString(nil, "OVERLAY")
StatusLabel:SetPoint("TOPLEFT", CurrentKeyValue, "BOTTOMLEFT", 0, -14)
StatusLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
StatusLabel:SetTextColor(0.85, 0.85, 0.85, 1)

StatusValue = ControlPanel:CreateFontString(nil, "OVERLAY")
StatusValue:SetPoint("TOPLEFT", StatusLabel, "BOTTOMLEFT", 0, -4)
StatusValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
StatusValue:SetJustifyH("LEFT")
StatusValue:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
StatusValue:SetTextColor(1, 0.88, 0.62, 1)

local InteractionPanel = CreatePanel(PageFishingContent, ControlPanel, -18, 120)

local InteractionTitle = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractionTitle:SetPoint("TOPLEFT", InteractionPanel, "TOPLEFT", 18, -14)
InteractionTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
InteractionTitle:SetTextColor(1, 0.88, 0.62, 1)

InteractValue = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractValue:SetPoint("TOPLEFT", InteractionTitle, "BOTTOMLEFT", 0, -10)
InteractValue:SetPoint("RIGHT", InteractionPanel, "RIGHT", -18, 0)
InteractValue:SetJustifyH("LEFT")
InteractValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
InteractValue:SetTextColor(0.95, 0.91, 0.85, 1)

local InteractionHint = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractionHint:SetPoint("TOPLEFT", InteractValue, "BOTTOMLEFT", 0, -8)
InteractionHint:SetPoint("RIGHT", InteractionPanel, "RIGHT", -18, 0)
InteractionHint:SetJustifyH("LEFT")
InteractionHint:SetJustifyV("TOP")
InteractionHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
InteractionHint:SetTextColor(0.78, 0.74, 0.69, 1)
InteractionHint:Hide()

local SoundPanel = CreatePanel(PageFishingContent, InteractionPanel, -18, 160)

local SoundTitle = SoundPanel:CreateFontString(nil, "OVERLAY")
SoundTitle:SetPoint("TOPLEFT", SoundPanel, "TOPLEFT", 18, -14)
SoundTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SoundTitle:SetTextColor(1, 0.88, 0.62, 1)
SoundTitle:SetText(SOUND)

SoundCheckbox = CreateCheckbox(SoundPanel, L("FISHING_HELPER_SOUND_ENABLE"), function(self)
    FishingModule.SetSoundBoostEnabled(self:GetChecked())
end)
SoundCheckbox:SetPoint("TOPLEFT", SoundTitle, "BOTTOMLEFT", -4, -12)

SoundSlider, SoundSliderText = CreateSlider(SoundPanel)
SoundSlider:SetPoint("TOPLEFT", SoundCheckbox, "BOTTOMLEFT", 18, -28)
SoundSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    FishingModule.SetSoundMultiplier(value)
    RefreshSoundSliderText()
end)

SoundHint = SoundPanel:CreateFontString(nil, "OVERLAY")
SoundHint:SetPoint("TOPLEFT", SoundSlider, "BOTTOMLEFT", -2, -14)
SoundHint:SetPoint("RIGHT", SoundPanel, "RIGHT", -18, 0)
SoundHint:SetJustifyH("LEFT")
SoundHint:SetJustifyV("TOP")
SoundHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SoundHint:SetTextColor(0.78, 0.74, 0.69, 1)
SoundHint:Hide()

CaptureOverlay = CreateFrame("Button", nil, PageFishing)
CaptureOverlay:SetAllPoints()
CaptureOverlay:SetFrameStrata("DIALOG")
CaptureOverlay:Hide()
CaptureOverlay:EnableMouse(true)
CaptureOverlay:EnableKeyboard(true)

if CaptureOverlay.SetPropagateKeyboardInput then
    CaptureOverlay:SetPropagateKeyboardInput(false)
end

local CaptureBg = CaptureOverlay:CreateTexture(nil, "BACKGROUND")
CaptureBg:SetAllPoints()
CaptureBg:SetColorTexture(0.02, 0.02, 0.03, 0.82)

local CapturePanel = CreateFrame("Frame", nil, CaptureOverlay)
CapturePanel:SetSize(520, 128)
CapturePanel:SetPoint("CENTER", CaptureOverlay, "CENTER", 0, 0)

local CapturePanelBg = CapturePanel:CreateTexture(nil, "BACKGROUND")
CapturePanelBg:SetAllPoints()
CapturePanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.96)

local CapturePanelBorder = CapturePanel:CreateTexture(nil, "ARTWORK")
CapturePanelBorder:SetPoint("BOTTOMLEFT", CapturePanel, "BOTTOMLEFT", 0, 0)
CapturePanelBorder:SetPoint("BOTTOMRIGHT", CapturePanel, "BOTTOMRIGHT", 0, 0)
CapturePanelBorder:SetHeight(1)
CapturePanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

CaptureTitle = CapturePanel:CreateFontString(nil, "OVERLAY")
CaptureTitle:SetPoint("TOPLEFT", CapturePanel, "TOPLEFT", 18, -18)
CaptureTitle:SetPoint("RIGHT", CapturePanel, "RIGHT", -18, 0)
CaptureTitle:SetJustifyH("LEFT")
CaptureTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CaptureTitle:SetTextColor(1, 0.88, 0.62, 1)

CaptureHint = CapturePanel:CreateFontString(nil, "OVERLAY")
CaptureHint:SetPoint("TOPLEFT", CaptureTitle, "BOTTOMLEFT", 0, -12)
CaptureHint:SetPoint("RIGHT", CapturePanel, "RIGHT", -18, 0)
CaptureHint:SetJustifyH("LEFT")
CaptureHint:SetJustifyV("TOP")
CaptureHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CaptureHint:SetTextColor(0.95, 0.91, 0.85, 1)

CaptureOverlay:SetScript("OnClick", function()
    StopCaptureMode()
end)

CaptureOverlay:SetScript("OnKeyDown", function(_, key)
    if key == "ESCAPE" then
        StopCaptureMode()
        return
    end

    if key == "DELETE" or key == "BACKSPACE" then
        FishingModule.ClearKey()
        StopCaptureMode()
        return
    end

    local normalizedKey = NormalizeCapturedKey(key)
    if not normalizedKey then
        return
    end

    FishingModule.SetKey(normalizedKey)
    StopCaptureMode()
end)

local function LayoutFishingPage()
    local contentWidth = math.max(1, PageFishingScrollFrame:GetWidth())
    if contentWidth <= 1 then
        return
    end

    PageFishingContent:SetWidth(contentWidth)

    local innerWidth = math.max(320, contentWidth - 40)
    local isCompactWidth = innerWidth < 760
    local stackButtons = innerWidth < 620

    IntroPanel:ClearAllPoints()
    IntroPanel:SetPoint("TOPLEFT", PageFishingContent, "TOPLEFT", 20, -18)
    IntroPanel:SetPoint("RIGHT", PageFishingContent, "RIGHT", -20, 0)

    IntroText:ClearAllPoints()
    IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
    IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)

    local usageHintText = UsageHint:GetText()
    local hasUsageHint = usageHintText ~= nil and usageHintText ~= ""

    UsageHint:ClearAllPoints()
    if hasUsageHint then
        UsageHint:Show()
        UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -10)
        UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
    else
        UsageHint:Hide()
    end

    local introHeight = math.ceil(
        16
        + GetTextHeight(IntroTitle, 24)
        + 8
        + GetTextHeight(IntroText, 34)
        + (hasUsageHint and (10 + GetTextHeight(UsageHint, 34)) or 0)
        + 16
    )
    IntroPanel:SetHeight(math.max(hasUsageHint and 104 or 82, introHeight))

    ControlPanel:ClearAllPoints()
    ControlPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -14)
    ControlPanel:SetPoint("RIGHT", PageFishingContent, "RIGHT", -20, 0)

    EnableCheckbox:ClearAllPoints()
    EnableCheckbox:SetPoint("TOPLEFT", ControlTitle, "BOTTOMLEFT", -4, -10)

    SetKeyButton:ClearAllPoints()
    SetKeyButton:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", -4, -16)

    ClearKeyButton:ClearAllPoints()
    if stackButtons then
        ClearKeyButton:SetPoint("TOPLEFT", SetKeyButton, "BOTTOMLEFT", 0, -10)
    else
        ClearKeyButton:SetPoint("LEFT", SetKeyButton, "RIGHT", 10, 0)
    end

    CurrentKeyLabel:ClearAllPoints()
    CurrentKeyValue:ClearAllPoints()
    StatusLabel:ClearAllPoints()
    StatusValue:ClearAllPoints()

    local buttonsBottomAnchor = stackButtons and ClearKeyButton or SetKeyButton

    if isCompactWidth then
        CurrentKeyLabel:SetPoint("TOPLEFT", buttonsBottomAnchor, "BOTTOMLEFT", 0, -16)
        CurrentKeyValue:SetPoint("TOPLEFT", CurrentKeyLabel, "BOTTOMLEFT", 0, -4)
        CurrentKeyValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
        StatusLabel:SetPoint("TOPLEFT", CurrentKeyValue, "BOTTOMLEFT", 0, -12)
    else
        local rightColumnX = math.floor(innerWidth * 0.48)
        CurrentKeyLabel:SetPoint("TOPLEFT", ControlPanel, "TOPLEFT", rightColumnX, -58)
        CurrentKeyValue:SetPoint("TOPLEFT", CurrentKeyLabel, "BOTTOMLEFT", 0, -4)
        CurrentKeyValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
        StatusLabel:SetPoint("TOPLEFT", CurrentKeyValue, "BOTTOMLEFT", 0, -12)
    end

    StatusValue:SetPoint("TOPLEFT", StatusLabel, "BOTTOMLEFT", 0, -4)
    StatusValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)

    local controlHeight = math.ceil(
        14
        + GetTextHeight(ControlTitle, 15)
        + 10
        + EnableCheckbox:GetHeight()
        + 16
        + SetKeyButton:GetHeight()
        + (stackButtons and (10 + ClearKeyButton:GetHeight()) or 0)
        + (isCompactWidth and (16 + GetTextHeight(CurrentKeyLabel, 13) + 4 + GetTextHeight(CurrentKeyValue, 15) + 12 + GetTextHeight(StatusLabel, 13) + 4 + GetTextHeight(StatusValue, 15)) or 0)
        + 16
    )

    if not isCompactWidth then
        local rightColumnHeight = 58
            + GetTextHeight(CurrentKeyLabel, 13)
            + 4
            + GetTextHeight(CurrentKeyValue, 15)
            + 12
            + GetTextHeight(StatusLabel, 13)
            + 4
            + GetTextHeight(StatusValue, 15)
            + 16
        controlHeight = math.max(controlHeight, rightColumnHeight)
    end

    ControlPanel:SetHeight(math.max(132, controlHeight))

    InteractionPanel:ClearAllPoints()
    InteractionPanel:SetPoint("TOPLEFT", ControlPanel, "BOTTOMLEFT", 0, -14)
    InteractionPanel:SetPoint("RIGHT", PageFishingContent, "RIGHT", -20, 0)

    InteractionTitle:ClearAllPoints()
    InteractionTitle:SetPoint("TOPLEFT", InteractionPanel, "TOPLEFT", 18, -12)

    InteractValue:ClearAllPoints()
    InteractValue:SetPoint("TOPLEFT", InteractionTitle, "BOTTOMLEFT", 0, -8)
    InteractValue:SetPoint("RIGHT", InteractionPanel, "RIGHT", -18, 0)

    local interactionHeight = math.ceil(
        14
        + GetTextHeight(InteractionTitle, 15)
        + 8
        + GetTextHeight(InteractValue, 10)
        + 16
    )
    InteractionPanel:SetHeight(math.max(60, interactionHeight))

    SoundPanel:ClearAllPoints()
    SoundPanel:SetPoint("TOPLEFT", InteractionPanel, "BOTTOMLEFT", 0, -14)
    SoundPanel:SetPoint("RIGHT", PageFishingContent, "RIGHT", -20, 0)

    SoundTitle:ClearAllPoints()
    SoundTitle:SetPoint("TOPLEFT", SoundPanel, "TOPLEFT", 18, -12)

    SoundCheckbox:ClearAllPoints()
    SoundCheckbox:SetPoint("TOPLEFT", SoundTitle, "BOTTOMLEFT", -4, -10)

    SoundSlider:ClearAllPoints()
    SoundSlider:SetPoint("TOPLEFT", SoundCheckbox, "BOTTOMLEFT", 18, -18)
    SoundSlider:SetWidth(math.max(220, math.min(340, innerWidth - 76)))

    local soundHeight = math.ceil(
        14
        + GetTextHeight(SoundTitle, 15)
        + 10
        + SoundCheckbox:GetHeight()
        + 18
        + 42
        + 16
    )
    SoundPanel:SetHeight(math.max(96, soundHeight))

    local contentHeight = 18
        + IntroPanel:GetHeight()
        + 14 + ControlPanel:GetHeight()
        + 14 + InteractionPanel:GetHeight()
        + 14 + SoundPanel:GetHeight()
        + 20

    PageFishingContent:SetHeight(math.max(PageFishingScrollFrame:GetHeight(), contentHeight))
end

function PageFishing:RefreshState()
    isRefreshingPage = true

    local settings = GetFishingSettings()
    local hasSpell = IsFishingKnown()
    local hasKey = settings.key ~= nil

    IntroTitle:SetText(L("FISHING_HELPER"))
    IntroText:SetText(L("FISHING_HELPER_DESC"))
    UsageHint:SetText(L("FISHING_HELPER_USAGE_HINT"))

    ControlTitle:SetText(L("DISPLAY"))
    EnableCheckbox.Label:SetText(L("FISHING_HELPER_ENABLE"))
    SetKeyButton:SetText(L("FISHING_HELPER_SET_KEY"))
    ClearKeyButton:SetText(L("FISHING_HELPER_CLEAR_KEY"))
    CurrentKeyLabel:SetText(L("FISHING_HELPER_CURRENT_KEY"))
    CurrentKeyValue:SetText(FormatBindingKey(settings.key))
    StatusLabel:SetText(L("FISHING_HELPER_STATUS"))
    StatusValue:SetText(GetStatusText())
    if not hasSpell then
        StatusValue:SetTextColor(1, 0.35, 0.35, 1)
    elseif currentMode == "ready" then
        StatusValue:SetTextColor(1, 0.92, 0.24, 1)
    else
        StatusValue:SetTextColor(1, 0.82, 0, 1)
    end

    InteractionTitle:SetText(L("FISHING_HELPER_INTERACT_BINDING"))
    InteractValue:SetText(GetInteractionBindingText())
    InteractionHint:SetText("")

    SoundTitle:SetText(SOUND)
    SoundCheckbox.Label:SetText(L("FISHING_HELPER_SOUND_ENABLE"))
    SoundHint:SetText("")
    CaptureTitle:SetText(L("FISHING_HELPER_SET_KEY"))
    CaptureHint:SetText(L("FISHING_HELPER_CAPTURE_HINT"))

    EnableCheckbox:SetChecked(settings.enabled == true)
    ClearKeyButton:SetEnabled(hasKey)
    SetKeyButton:SetEnabled(settings.enabled == true)

    SoundCheckbox:SetChecked(settings.soundBoostEnabled == true)
    SoundCheckbox:SetEnabled(settings.enabled == true)
    SoundSlider:SetEnabled(settings.enabled == true and settings.soundBoostEnabled == true)
    SoundSlider:SetValue(settings.soundMultiplier)
    RefreshSoundSliderText()

    isRefreshingPage = false
    LayoutFishingPage()
end

PageFishingScrollFrame:SetScript("OnSizeChanged", LayoutFishingPage)
PageFishingScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageFishingContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageFishing:SetScript("OnShow", function()
    LayoutFishingPage()
    PageFishingScrollFrame:SetVerticalScroll(0)
    PageFishing:RefreshState()
end)

CreateSecureFrames()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
eventFrame:RegisterEvent("PLAYER_SOFT_TARGET_INTERACTION")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGOUT" then
        ClearFishingOverrideBinding()
        RestoreSoundBoost()
        RestoreSoftInteractCVar()
        currentMode = "idle"
        waitingStartedAt = 0
        waitingExpiresAt = 0
        waitingInitialSoftTargetGUID = nil
        waitingInitialSoftTargetPresent = false
        waitingInitialSoftTargetInteractable = false
        waitingReadyTriggered = false
        lastSoftInteractGUID = nil
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingCastButtonRefresh then
            RefreshCastButtonAttributes()
        end

        if pendingBindingRefresh then
            RefreshOverrideBinding()
        end

        if pendingStateRefresh then
            RefreshStateFromGame()
        end

        return
    end

    if event == "SPELLS_CHANGED" or event == "SKILL_LINES_CHANGED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if event == "PLAYER_ENTERING_WORLD" then
            lastSoftInteractGUID = nil
        end
        RefreshCastButtonAttributes()
        RefreshStateFromGame()
        return
    end

    if event == "LOOT_CLOSED" then
        if not IsFishingChannelActive() then
            RefreshStateFromGame()
        end

        return
    end

    if event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "PLAYER_SOFT_TARGET_INTERACTION" then
        local _, newTarget = ...
        if event == "PLAYER_SOFT_INTERACT_CHANGED" then
            lastSoftInteractGUID = newTarget
        end

        if not IsFishingActiveMode(currentMode) and not IsFishingChannelActive() then
            return
        end

        if InCombatLockdown and InCombatLockdown() then
            QueueStateRefresh()
            return
        end

        MarkFishingBiteReady(newTarget)
        RefreshStateFromGame()
        return
    end

    local unit = ...
    if unit ~= "player" then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        QueueStateRefresh()
        return
    end

    RefreshStateFromGame()
end)

local watchdogFrame = CreateFrame("Frame", nil, PageFishing)
local elapsedSinceCheck = 0
watchdogFrame:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceCheck = elapsedSinceCheck + elapsed

    if elapsedSinceCheck < 0.25 then
        return
    end

    elapsedSinceCheck = 0

    local now = GetTime()

    if IsFishingActiveMode(currentMode) and waitingExpiresAt > 0 and now >= waitingExpiresAt then
        RefreshStateFromGame()
        return
    end

    if IsFishingActiveMode(currentMode) then
        local shouldBeReady = HasFishingBiteReadyTarget(now)
        if (currentMode == "ready") ~= shouldBeReady then
            RefreshStateFromGame()
        end
    end
end)

BeavisQoL.UpdateFishing = function()
    RefreshCastButtonAttributes()
    RefreshStateFromGame()
end

RefreshCastButtonAttributes()
RefreshStateFromGame()

BeavisQoL.Pages.Fishing = PageFishing

