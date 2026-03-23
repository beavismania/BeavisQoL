local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.FishingModule = BeavisQoL.FishingModule or {}
local FishingModule = BeavisQoL.FishingModule

local FISHING_SPELL_ID = 131474
local WAITING_TIMEOUT = 32
local STANDARD_SFX = 1.00
local DEFAULT_MIN_SFX = STANDARD_SFX
local MIN_SFX = STANDARD_SFX
local MAX_SFX = STANDARD_SFX
local INTERACTION_COMMAND = "INTERACTTARGET"
local SOFT_INTERACT_CVAR = "SoftTargetInteract"
local SOFT_INTERACT_FISHING_VALUE = "3"

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
local waitingExpiresAt = 0
local pendingBindingRefresh = false
local pendingStateRefresh = false
local pendingCastButtonRefresh = false
local boostedFromVolume = nil
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

    if type(db.soundMinVolume) ~= "number" then
        db.soundMinVolume = DEFAULT_MIN_SFX
    end

    db.soundMinVolume = Clamp(db.soundMinVolume, MIN_SFX, MAX_SFX)

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

local function GetCurrentSFXVolume()
    if not GetCVar then
        return 0
    end

    return Clamp(tonumber(GetCVar("Sound_SFXVolume")) or 0, 0, 1)
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

local function SetCurrentSFXVolume(value)
    local normalizedValue = string.format("%.2f", Clamp(tonumber(value) or 0, 0, 1))

    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar("Sound_SFXVolume", normalizedValue)
        return
    end

    if SetCVar then
        SetCVar("Sound_SFXVolume", normalizedValue)
    end
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor((Clamp(tonumber(value) or DEFAULT_MIN_SFX, MIN_SFX, MAX_SFX) * 100) + 0.5))
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
    local shouldEnableSoftInteract = settings.enabled == true and currentMode == "waiting"

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
    if boostedFromVolume ~= nil then
        SetCurrentSFXVolume(boostedFromVolume)
        boostedFromVolume = nil
    end
end

local function RefreshSoundBoost()
    local settings = GetFishingSettings()
    local shouldBoost = settings.enabled == true and settings.soundBoostEnabled == true and currentMode == "waiting"

    if shouldBoost then
        local currentVolume = GetCurrentSFXVolume()

        if currentVolume < settings.soundMinVolume then
            if boostedFromVolume == nil then
                boostedFromVolume = currentVolume
            end

            SetCurrentSFXVolume(settings.soundMinVolume)
        end

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

    if currentMode == "waiting" then
        SetOverrideBinding(BindingOwner, true, settings.key, INTERACTION_COMMAND)
        return
    end

    if CastButton and CastButton:GetAttribute("macrotext1") then
        SetOverrideBindingClick(BindingOwner, true, settings.key, CastButton:GetName(), "LeftButton")
    end
end

local function RefreshStateFromGame()
    pendingStateRefresh = false

    if IsFishingChannelActive() then
        currentMode = "waiting"
        waitingExpiresAt = GetTime() + WAITING_TIMEOUT
    else
        currentMode = "idle"
        waitingExpiresAt = 0
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

function FishingModule.GetSoundMinVolume()
    return GetFishingSettings().soundMinVolume
end

function FishingModule.SetSoundMinVolume(value)
    GetFishingSettings().soundMinVolume = Clamp(tonumber(value) or DEFAULT_MIN_SFX, MIN_SFX, MAX_SFX)
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

local function CreateSlider(parent)
    local slider = CreateFrame("Slider", ADDON_NAME .. "FishingSoundSlider", parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(MIN_SFX, MAX_SFX)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(260)
    slider:EnableMouse(MIN_SFX < MAX_SFX)

    local lowLabel = _G[slider:GetName() .. "Low"]
    local highLabel = _G[slider:GetName() .. "High"]
    local textLabel = _G[slider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(MIN_SFX))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(MAX_SFX))
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

local IntroPanel = CreateFrame("Frame", nil, PageFishing)
IntroPanel:SetPoint("TOPLEFT", PageFishing, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageFishing, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(146)

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
UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
UsageHint:SetJustifyH("LEFT")
UsageHint:SetJustifyV("TOP")
UsageHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
UsageHint:SetTextColor(0.84, 0.84, 0.86, 1)

local ControlPanel = CreatePanel(PageFishing, IntroPanel, -18, 188)

local ControlTitle = ControlPanel:CreateFontString(nil, "OVERLAY")
ControlTitle:SetPoint("TOPLEFT", ControlPanel, "TOPLEFT", 18, -14)
ControlTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
ControlTitle:SetTextColor(1, 0.82, 0, 1)
ControlTitle:SetText(L("DISPLAY"))

EnableCheckbox = CreateCheckbox(ControlPanel, L("FISHING_HELPER_ENABLE"), function(self)
    FishingModule.SetEnabled(self:GetChecked())
end)
EnableCheckbox:SetPoint("TOPLEFT", ControlTitle, "BOTTOMLEFT", -4, -12)

SetKeyButton = CreateActionButton(ControlPanel, 160, L("FISHING_HELPER_SET_KEY"), function()
    BeginCaptureMode()
end)
SetKeyButton:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", 8, -18)

ClearKeyButton = CreateActionButton(ControlPanel, 160, L("FISHING_HELPER_CLEAR_KEY"), function()
    FishingModule.ClearKey()
end)
ClearKeyButton:SetPoint("LEFT", SetKeyButton, "RIGHT", 12, 0)

local CurrentKeyLabel = ControlPanel:CreateFontString(nil, "OVERLAY")
CurrentKeyLabel:SetPoint("TOPLEFT", SetKeyButton, "BOTTOMLEFT", 0, -16)
CurrentKeyLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CurrentKeyLabel:SetTextColor(0.85, 0.85, 0.85, 1)

CurrentKeyValue = ControlPanel:CreateFontString(nil, "OVERLAY")
CurrentKeyValue:SetPoint("TOPLEFT", CurrentKeyLabel, "BOTTOMLEFT", 0, -4)
CurrentKeyValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
CurrentKeyValue:SetJustifyH("LEFT")
CurrentKeyValue:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CurrentKeyValue:SetTextColor(1, 1, 1, 1)

local StatusLabel = ControlPanel:CreateFontString(nil, "OVERLAY")
StatusLabel:SetPoint("TOPLEFT", CurrentKeyValue, "BOTTOMLEFT", 0, -14)
StatusLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
StatusLabel:SetTextColor(0.85, 0.85, 0.85, 1)

StatusValue = ControlPanel:CreateFontString(nil, "OVERLAY")
StatusValue:SetPoint("TOPLEFT", StatusLabel, "BOTTOMLEFT", 0, -4)
StatusValue:SetPoint("RIGHT", ControlPanel, "RIGHT", -18, 0)
StatusValue:SetJustifyH("LEFT")
StatusValue:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
StatusValue:SetTextColor(1, 0.82, 0, 1)

local InteractionPanel = CreatePanel(PageFishing, ControlPanel, -18, 120)

local InteractionTitle = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractionTitle:SetPoint("TOPLEFT", InteractionPanel, "TOPLEFT", 18, -14)
InteractionTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
InteractionTitle:SetTextColor(1, 0.82, 0, 1)

InteractValue = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractValue:SetPoint("TOPLEFT", InteractionTitle, "BOTTOMLEFT", 0, -10)
InteractValue:SetPoint("RIGHT", InteractionPanel, "RIGHT", -18, 0)
InteractValue:SetJustifyH("LEFT")
InteractValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
InteractValue:SetTextColor(1, 1, 1, 1)

local InteractionHint = InteractionPanel:CreateFontString(nil, "OVERLAY")
InteractionHint:SetPoint("TOPLEFT", InteractValue, "BOTTOMLEFT", 0, -8)
InteractionHint:SetPoint("RIGHT", InteractionPanel, "RIGHT", -18, 0)
InteractionHint:SetJustifyH("LEFT")
InteractionHint:SetJustifyV("TOP")
InteractionHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
InteractionHint:SetTextColor(0.80, 0.80, 0.80, 1)

local SoundPanel = CreatePanel(PageFishing, InteractionPanel, -18, 160)

local SoundTitle = SoundPanel:CreateFontString(nil, "OVERLAY")
SoundTitle:SetPoint("TOPLEFT", SoundPanel, "TOPLEFT", 18, -14)
SoundTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SoundTitle:SetTextColor(1, 0.82, 0, 1)
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

    FishingModule.SetSoundMinVolume(value)
    RefreshSoundSliderText()
end)

SoundHint = SoundPanel:CreateFontString(nil, "OVERLAY")
SoundHint:SetPoint("TOPLEFT", SoundSlider, "BOTTOMLEFT", -2, -14)
SoundHint:SetPoint("RIGHT", SoundPanel, "RIGHT", -18, 0)
SoundHint:SetJustifyH("LEFT")
SoundHint:SetJustifyV("TOP")
SoundHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SoundHint:SetTextColor(0.80, 0.80, 0.80, 1)

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
CapturePanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

CaptureTitle = CapturePanel:CreateFontString(nil, "OVERLAY")
CaptureTitle:SetPoint("TOPLEFT", CapturePanel, "TOPLEFT", 18, -18)
CaptureTitle:SetPoint("RIGHT", CapturePanel, "RIGHT", -18, 0)
CaptureTitle:SetJustifyH("LEFT")
CaptureTitle:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
CaptureTitle:SetTextColor(1, 0.82, 0, 1)

CaptureHint = CapturePanel:CreateFontString(nil, "OVERLAY")
CaptureHint:SetPoint("TOPLEFT", CaptureTitle, "BOTTOMLEFT", 0, -12)
CaptureHint:SetPoint("RIGHT", CapturePanel, "RIGHT", -18, 0)
CaptureHint:SetJustifyH("LEFT")
CaptureHint:SetJustifyV("TOP")
CaptureHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CaptureHint:SetTextColor(1, 1, 1, 1)

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
    StatusValue:SetTextColor(hasSpell and 1 or 1, hasSpell and 0.82 or 0.35, hasSpell and 0 or 0.35, 1)

    InteractionTitle:SetText(L("FISHING_HELPER_INTERACT_BINDING"))
    InteractValue:SetText(GetInteractionBindingText())
    InteractionHint:SetText(L("FISHING_HELPER_INTERACT_HINT"))

    SoundTitle:SetText(SOUND)
    SoundCheckbox.Label:SetText(L("FISHING_HELPER_SOUND_ENABLE"))
    SoundHint:SetText(L("FISHING_HELPER_SOUND_HINT"))
    CaptureTitle:SetText(L("FISHING_HELPER_SET_KEY"))
    CaptureHint:SetText(L("FISHING_HELPER_CAPTURE_HINT"))

    EnableCheckbox:SetChecked(settings.enabled == true)
    ClearKeyButton:SetEnabled(hasKey)
    SetKeyButton:SetEnabled(settings.enabled == true)

    SoundCheckbox:SetChecked(settings.soundBoostEnabled == true)
    SoundCheckbox:SetEnabled(settings.enabled == true)
    SoundSlider:SetEnabled(false)
    SoundSlider:SetValue(settings.soundMinVolume)
    RefreshSoundSliderText()

    isRefreshingPage = false
end

PageFishing:SetScript("OnShow", function()
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
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGOUT" then
        ClearFishingOverrideBinding()
        RestoreSoundBoost()
        RestoreSoftInteractCVar()
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

    if currentMode == "waiting" and waitingExpiresAt > 0 and GetTime() >= waitingExpiresAt then
        RefreshStateFromGame()
    end
end)

BeavisQoL.UpdateFishing = function()
    RefreshCastButtonAttributes()
    RefreshStateFromGame()
end

RefreshCastButtonAttributes()
RefreshStateFromGame()

BeavisQoL.Pages.Fishing = PageFishing