local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local baseGetMiscDB = Misc.GetMiscDB
local TalentFrameScaleWatcher = CreateFrame("Frame")

local PLAYER_SPELLS_ADDON_NAME = "Blizzard_PlayerSpells"
local TALENT_TREE_TWEAKS_ADDON_NAME = "TalentTreeTweaks"
local DEFAULT_TALENT_FRAME_SCALE = 1.00
local MIN_TALENT_FRAME_SCALE = 0.50
local MAX_TALENT_FRAME_SCALE = 1.50
local TALENT_FRAME_SCALE_STEP = 0.05
local SCALE_BUTTON_NAME = "BeavisQoLTalentFrameScaleButton"
local SCALE_POPUP_NAME = "BeavisQoLTalentFrameScalePopup"
local SCALE_SLIDER_NAME = "BeavisQoLTalentFrameScaleSlider"
local SCALE_BUTTON_SIZE = 16

local ScaleButton
local ScalePopup
local ScaleSlider
local ScalePopupTitle
local ScalePopupValue
local ScalePopupLockButton
local sliderIsRefreshing = false
local pendingTalentFrameLayout = false

local abs = math.abs
local floor = math.floor
local ipairs = ipairs

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc
    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function NormalizeTalentFrameScale(value)
    local numericValue = tonumber(value) or DEFAULT_TALENT_FRAME_SCALE
    local clampedValue = Clamp(numericValue, MIN_TALENT_FRAME_SCALE, MAX_TALENT_FRAME_SCALE)
    local stepIndex = floor((((clampedValue - MIN_TALENT_FRAME_SCALE) / TALENT_FRAME_SCALE_STEP) + 0.5))
    local normalizedValue = MIN_TALENT_FRAME_SCALE + (stepIndex * TALENT_FRAME_SCALE_STEP)
    return Clamp((floor((normalizedValue * 100) + 0.5) / 100), MIN_TALENT_FRAME_SCALE, MAX_TALENT_FRAME_SCALE)
end

local function FormatScalePercent(value)
    return string.format("%d%%", floor((NormalizeTalentFrameScale(value) * 100) + 0.5))
end

local function GetTalentTreeTweaksScaleDB()
    local talentTreeTweaksDB = rawget(_G, "TalentTreeTweaksDB")
    if type(talentTreeTweaksDB) ~= "table" then
        return nil
    end

    local modules = talentTreeTweaksDB.modules
    if type(modules) ~= "table" or modules.ScaleTalentFrame ~= true then
        return nil
    end

    if type(talentTreeTweaksDB.moduleDb) ~= "table" then
        talentTreeTweaksDB.moduleDb = {}
    end

    if type(talentTreeTweaksDB.moduleDb.ScaleTalentFrame) ~= "table" then
        talentTreeTweaksDB.moduleDb.ScaleTalentFrame = {}
    end

    return talentTreeTweaksDB.moduleDb.ScaleTalentFrame
end

local function SyncTalentTreeTweaksScale(value)
    local scaleDB = GetTalentTreeTweaksScaleDB()
    if not scaleDB then
        return
    end

    scaleDB.scale = NormalizeTalentFrameScale(value)
end

local function GetPlayerSpellsFrame()
    for _, frameName in ipairs({ "PlayerSpellsFrame", "SpellBookFrame" }) do
        local frame = rawget(_G, frameName)
        if frame then
            return frame
        end
    end

    return nil
end

local function GetTalentFrameCloseButton()
    local playerSpellsFrame = GetPlayerSpellsFrame()
    return (playerSpellsFrame and playerSpellsFrame.CloseButton) or rawget(_G, "PlayerSpellsFrameCloseButton")
end

local function IsTalentFrameLayoutBlocked(frame)
    local inCombatLockdown = rawget(_G, "InCombatLockdown")
    if not frame or not frame.IsProtected or type(inCombatLockdown) ~= "function" then
        return false
    end

    return frame:IsProtected() and inCombatLockdown() == true
end

local function QueueTalentFrameLayoutRetry()
    pendingTalentFrameLayout = true
    TalentFrameScaleWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
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

    if db.talentFrameScaleEnabled == nil then
        db.talentFrameScaleEnabled = true
    end

    if db.talentFrameScale == nil then
        db.talentFrameScale = DEFAULT_TALENT_FRAME_SCALE
    end

    if db.talentFrameScalePoint == nil then
        db.talentFrameScalePoint = "CENTER"
    end

    if db.talentFrameScaleRelativePoint == nil then
        db.talentFrameScaleRelativePoint = "CENTER"
    end

    if db.talentFrameScaleXOfs == nil then
        db.talentFrameScaleXOfs = 0
    end

    if db.talentFrameScaleYOfs == nil then
        db.talentFrameScaleYOfs = 0
    end

    if db.talentFrameWindowLocked == nil then
        db.talentFrameWindowLocked = true
    end

    if db.talentFrameScalePopupHasCustomPosition == nil then
        db.talentFrameScalePopupHasCustomPosition = false
    end

    db.talentFrameScale = NormalizeTalentFrameScale(db.talentFrameScale)

    return db
end

function Misc.IsTalentFrameScaleEnabled()
    return Misc.GetMiscDB().talentFrameScaleEnabled == true
end

function Misc.GetTalentFrameScale()
    return NormalizeTalentFrameScale(Misc.GetMiscDB().talentFrameScale)
end

function Misc.IsTalentFrameWindowLocked()
    return Misc.GetMiscDB().talentFrameWindowLocked ~= false
end

local function GetStoredTalentFrameAnchor()
    local db = Misc.GetMiscDB()
    return db.talentFrameScalePoint or "CENTER",
        db.talentFrameScaleRelativePoint or "CENTER",
        tonumber(db.talentFrameScaleXOfs) or 0,
        tonumber(db.talentFrameScaleYOfs) or 0
end

local function SaveTalentFrameLayout(frame)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    local db = Misc.GetMiscDB()
    db.talentFrameScalePoint = point or "CENTER"
    db.talentFrameScaleRelativePoint = relativePoint or "CENTER"
    db.talentFrameScaleXOfs = xOfs or 0
    db.talentFrameScaleYOfs = yOfs or 0
end

local function HasStoredScalePopupPosition()
    return Misc.GetMiscDB().talentFrameScalePopupHasCustomPosition == true
end

local function SaveScalePopupPosition(frame)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    local db = Misc.GetMiscDB()
    db.talentFrameScalePopupHasCustomPosition = true
    db.talentFrameScalePopupPoint = point or "CENTER"
    db.talentFrameScalePopupRelativePoint = relativePoint or "CENTER"
    db.talentFrameScalePopupXOfs = xOfs or 0
    db.talentFrameScalePopupYOfs = yOfs or 0
end

local function ApplyTalentFrameLayout(frame)
    if not frame then
        return false
    end

    local targetScale = Misc.IsTalentFrameScaleEnabled() and Misc.GetTalentFrameScale() or DEFAULT_TALENT_FRAME_SCALE
    local point, relativePoint, xOfs, yOfs = GetStoredTalentFrameAnchor()

    -- TalentTreeTweaks can actively reset PlayerSpellsFrame scale on show.
    -- Keep both addons in sync so BeavisQoL remains the visible source of truth.
    SyncTalentTreeTweaksScale(targetScale)

    if IsTalentFrameLayoutBlocked(frame) then
        QueueTalentFrameLayoutRetry()
        return false
    end

    frame:SetScale(targetScale)
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
    pendingTalentFrameLayout = false
    TalentFrameScaleWatcher:UnregisterEvent("PLAYER_REGEN_ENABLED")
    return true
end

local function RefreshScalePopupLockButton()
    if not ScalePopupLockButton or not ScalePopupLockButton.Icon then
        return
    end

    if Misc.IsTalentFrameWindowLocked() then
        ScalePopupLockButton.Icon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
        ScalePopupLockButton.Icon:SetVertexColor(1, 0.88, 0.46, 1)
    else
        ScalePopupLockButton.Icon:SetTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
        ScalePopupLockButton.Icon:SetVertexColor(0.82, 0.82, 0.82, 1)
    end
end

local function RefreshScalePopup()
    if not ScalePopup then
        return
    end

    local enabled = Misc.IsTalentFrameScaleEnabled()
    local scale = Misc.GetTalentFrameScale()
    local accentColor = enabled and 1 or 0.55
    local hintColor = enabled and 0.95 or 0.55

    if ScalePopupTitle then
        ScalePopupTitle:SetText(L("WINDOW_SCALE"))
        ScalePopupTitle:SetTextColor(accentColor, enabled and 0.88 or 0.55, enabled and 0.62 or 0.55, 1)
    end

    if ScalePopupValue then
        ScalePopupValue:SetText(FormatScalePercent(scale))
        ScalePopupValue:SetTextColor(hintColor, hintColor, hintColor, 1)
    end

    if ScaleSlider then
        sliderIsRefreshing = true
        ScaleSlider:SetValue(scale)
        sliderIsRefreshing = false

        if enabled then
            ScaleSlider:Enable()
            ScaleSlider:SetAlpha(1)
        else
            ScaleSlider:Disable()
            ScaleSlider:SetAlpha(0.5)
        end
    end

    RefreshScalePopupLockButton()
end

local function RefreshScaleButtonVisual()
    if not ScaleButton or not ScaleButton.SetBackdropColor then
        return
    end

    local isPopupShown = ScalePopup and ScalePopup:IsShown()
    local isHovered = ScaleButton.isHovered == true
    local borderAlpha = (isPopupShown or isHovered) and 0.95 or 0.72
    local backgroundAlpha = (isPopupShown or isHovered) and 0.92 or 0.82

    ScaleButton:SetBackdropColor(0.03, 0.03, 0.04, backgroundAlpha)
    ScaleButton:SetBackdropBorderColor(0.88, 0.72, 0.46, borderAlpha)
end

local function AnchorScaleButton(playerSpellsFrame)
    if not ScaleButton or not playerSpellsFrame then
        return
    end

    local closeButton = GetTalentFrameCloseButton()

    ScaleButton:ClearAllPoints()
    if closeButton and closeButton.GetLeft then
        ScaleButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    else
        ScaleButton:SetPoint("TOPRIGHT", playerSpellsFrame, "TOPRIGHT", -32, -24)
    end
end

local function GetFramePointOnUIParent(frame, xGetter, yGetter)
    if not frame or not xGetter or not yGetter then
        return nil, nil
    end

    local x = xGetter(frame)
    local y = yGetter(frame)
    if not x or not y then
        return nil, nil
    end

    local frameScale = frame:GetEffectiveScale() or 1
    local parentScale = UIParent:GetEffectiveScale() or 1
    return (x * frameScale) / parentScale, (y * frameScale) / parentScale
end

local function PositionScalePopupNearButton()
    if not ScalePopup then
        return
    end

    ScalePopup:ClearAllPoints()
    if ScaleButton and ScaleButton:IsShown() then
        local right, bottom = GetFramePointOnUIParent(ScaleButton, ScaleButton.GetRight, ScaleButton.GetBottom)
        if right and bottom then
            ScalePopup:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right, bottom - 6)
            return
        end
    end

    local frame = GetPlayerSpellsFrame()
    if frame and frame:IsShown() then
        local right, top = GetFramePointOnUIParent(frame, frame.GetRight, frame.GetTop)
        if right and top then
            ScalePopup:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right - 24, top - 42)
            return
        end
    end

    ScalePopup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

local function ApplyStoredScalePopupPosition()
    if not ScalePopup or not HasStoredScalePopupPosition() then
        return false
    end

    local db = Misc.GetMiscDB()
    ScalePopup:ClearAllPoints()
    ScalePopup:SetPoint(
        db.talentFrameScalePopupPoint or "CENTER",
        UIParent,
        db.talentFrameScalePopupRelativePoint or "CENTER",
        tonumber(db.talentFrameScalePopupXOfs) or 0,
        tonumber(db.talentFrameScalePopupYOfs) or 0
    )
    return true
end

local function PositionScalePopup()
    if not ApplyStoredScalePopupPosition() then
        PositionScalePopupNearButton()
    end
end

local function HideScalePopup()
    if ScalePopup then
        ScalePopup:Hide()
    end

    RefreshScaleButtonVisual()
end

local function ToggleScalePopup()
    if not ScalePopup then
        return
    end

    if ScalePopup:IsShown() then
        HideScalePopup()
        return
    end

    PositionScalePopup()
    RefreshScalePopup()
    ScalePopup:Show()
    RefreshScaleButtonVisual()
end

local function CreateScalePopup(playerSpellsFrame)
    if ScalePopup then
        return
    end

    ScalePopup = CreateFrame("Frame", SCALE_POPUP_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    ScalePopup:SetSize(214, 98)
    ScalePopup:SetClampedToScreen(true)
    ScalePopup:EnableMouse(true)
    ScalePopup:SetMovable(true)
    ScalePopup:SetFrameStrata("DIALOG")
    ScalePopup:SetFrameLevel(30)

    if ScalePopup.SetBackdrop then
        ScalePopup:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        ScalePopup:SetBackdropColor(0, 0, 0, 0.92)
        ScalePopup:SetBackdropBorderColor(0.88, 0.72, 0.46, 0.78)
    end

    ScalePopupTitle = ScalePopup:CreateFontString(nil, "OVERLAY")
    ScalePopupTitle:SetPoint("TOPLEFT", ScalePopup, "TOPLEFT", 12, -10)
    ScalePopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    ScalePopupValue = ScalePopup:CreateFontString(nil, "OVERLAY")
    ScalePopupValue:SetPoint("TOPRIGHT", ScalePopup, "TOPRIGHT", -34, -11)
    ScalePopupValue:SetFont("Fonts\\FRIZQT__.TTF", 12, "")

    ScalePopupLockButton = CreateFrame("Button", nil, ScalePopup)
    ScalePopupLockButton:SetSize(18, 18)
    ScalePopupLockButton:SetPoint("TOPRIGHT", ScalePopup, "TOPRIGHT", -10, -8)
    ScalePopupLockButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    ScalePopupLockButton.Icon = ScalePopupLockButton:CreateTexture(nil, "ARTWORK")
    ScalePopupLockButton.Icon:SetSize(14, 14)
    ScalePopupLockButton.Icon:SetPoint("CENTER", ScalePopupLockButton, "CENTER", 0, 0)
    ScalePopupLockButton:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if Misc.IsTalentFrameWindowLocked() then
            GameTooltip:SetText(L("TALENT_FRAME_SCALE_WINDOW_UNLOCK_TOOLTIP"), 1, 0.82, 0)
        else
            GameTooltip:SetText(L("TALENT_FRAME_SCALE_WINDOW_LOCK_TOOLTIP"), 1, 0.82, 0)
        end
        GameTooltip:AddLine(L("TALENT_FRAME_SCALE_WINDOW_LOCK_TOOLTIP_HINT"), 0.95, 0.95, 0.95, true)
        GameTooltip:Show()
    end)
    ScalePopupLockButton:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    ScalePopupLockButton:SetScript("OnClick", function()
        Misc.SetTalentFrameWindowLocked(not Misc.IsTalentFrameWindowLocked())
    end)

    local popupDragHandle = CreateFrame("Frame", nil, ScalePopup)
    popupDragHandle:SetPoint("TOPLEFT", ScalePopup, "TOPLEFT", 10, -7)
    popupDragHandle:SetPoint("TOPRIGHT", ScalePopupLockButton, "TOPLEFT", -6, 0)
    popupDragHandle:SetHeight(18)
    popupDragHandle:EnableMouse(true)
    popupDragHandle:RegisterForDrag("LeftButton")
    popupDragHandle:SetScript("OnDragStart", function()
        ScalePopup:StartMoving()
    end)
    popupDragHandle:SetScript("OnDragStop", function()
        ScalePopup:StopMovingOrSizing()
        SaveScalePopupPosition(ScalePopup)
    end)
    ScalePopup.DragHandle = popupDragHandle

    ScaleSlider = CreateFrame("Slider", SCALE_SLIDER_NAME, ScalePopup, "OptionsSliderTemplate")
    ScaleSlider:SetPoint("TOPLEFT", ScalePopup, "TOPLEFT", 14, -36)
    ScaleSlider:SetWidth(180)
    ScaleSlider:SetMinMaxValues(MIN_TALENT_FRAME_SCALE, MAX_TALENT_FRAME_SCALE)
    ScaleSlider:SetValueStep(TALENT_FRAME_SCALE_STEP)
    ScaleSlider:SetObeyStepOnDrag(true)

    local lowLabel = _G[ScaleSlider:GetName() .. "Low"]
    local highLabel = _G[ScaleSlider:GetName() .. "High"]
    local textLabel = _G[ScaleSlider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(FormatScalePercent(MIN_TALENT_FRAME_SCALE))
    end

    if highLabel then
        highLabel:SetText(FormatScalePercent(MAX_TALENT_FRAME_SCALE))
    end

    if textLabel then
        textLabel:SetText("")
    end

    ScaleSlider:SetScript("OnValueChanged", function(self, value)
        local normalizedValue = NormalizeTalentFrameScale(value)
        if abs((value or normalizedValue) - normalizedValue) > 0.001 then
            self:SetValue(normalizedValue)
            return
        end

        if sliderIsRefreshing then
            return
        end

        Misc.SetTalentFrameScale(normalizedValue)
    end)

    ScalePopup:SetScript("OnHide", RefreshScaleButtonVisual)
    PositionScalePopupNearButton()
    ScalePopup:Hide()
end

local function CreateScaleButton(playerSpellsFrame)
    if ScaleButton then
        return
    end

    ScaleButton = CreateFrame("Button", SCALE_BUTTON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    ScaleButton:SetSize(SCALE_BUTTON_SIZE, SCALE_BUTTON_SIZE)
    ScaleButton:EnableMouse(true)
    ScaleButton:SetClampedToScreen(true)
    ScaleButton:SetFrameStrata("DIALOG")
    ScaleButton:SetFrameLevel(20)

    if ScaleButton.SetBackdrop then
        ScaleButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
    end

    local label = ScaleButton:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER", ScaleButton, "CENTER", 0, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    label:SetTextColor(1, 0.88, 0.62, 1)
    label:SetText("%")
    ScaleButton.Label = label

    ScaleButton:SetScript("OnEnter", function(self)
        self.isHovered = true
        RefreshScaleButtonVisual()

        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L("TALENT_FRAME_SCALE_BUTTON_TOOLTIP"), 1, 0.82, 0)
            GameTooltip:AddLine(L("TALENT_FRAME_SCALE_BUTTON_TOOLTIP_HINT"), 0.95, 0.95, 0.95, true)
            GameTooltip:Show()
        end
    end)

    ScaleButton:SetScript("OnLeave", function(self)
        self.isHovered = false
        RefreshScaleButtonVisual()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    ScaleButton:SetScript("OnClick", ToggleScalePopup)
    ScaleButton:Hide()
    RefreshScaleButtonVisual()
end

local function RefreshTalentFrameScaleUI()
    local playerSpellsFrame = GetPlayerSpellsFrame()
    if not playerSpellsFrame then
        return
    end

    CreateScaleButton(playerSpellsFrame)
    CreateScalePopup(playerSpellsFrame)
    AnchorScaleButton(playerSpellsFrame)

    local showButton = Misc.IsTalentFrameScaleEnabled() and playerSpellsFrame:IsShown()
    ScaleButton:SetShown(showButton)

    if not showButton then
        HideScalePopup()
    end

    RefreshScalePopup()
    RefreshScaleButtonVisual()
end

local function EndTalentFrameMove(frame)
    frame:StopMovingOrSizing()
    SaveTalentFrameLayout(frame)
    RefreshTalentFrameScaleUI()
end

local function UpdateTalentFrameMoveState(frame)
    if not frame or not frame.BeavisQoLTalentFrameMoveOverlay then
        return
    end

    local isLocked = Misc.IsTalentFrameWindowLocked()
    frame:SetMovable(not isLocked)
    frame.BeavisQoLTalentFrameMoveOverlay:SetShown(not isLocked)
    frame.BeavisQoLTalentFrameMoveOverlay:EnableMouse(not isLocked)
end

local function InstallTalentFrameMoveOverlay(frame)
    if frame.BeavisQoLTalentFrameMoveOverlay then
        return frame.BeavisQoLTalentFrameMoveOverlay
    end

    local moveOverlay = CreateFrame("Frame", nil, frame)
    frame.BeavisQoLTalentFrameMoveOverlay = moveOverlay

    moveOverlay:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    local closeButton = frame.CloseButton or rawget(_G, "PlayerSpellsFrameCloseButton")
    if closeButton then
        moveOverlay:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -28, 0)
    else
        moveOverlay:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -52, -8)
    end
    moveOverlay:SetHeight(24)
    moveOverlay:EnableMouse(true)
    moveOverlay:RegisterForDrag("LeftButton")

    frame:SetClampedToScreen(true)

    moveOverlay:SetScript("OnDragStart", function()
        if Misc.IsTalentFrameWindowLocked() then
            return
        end

        frame:StartMoving()
    end)

    moveOverlay:SetScript("OnDragStop", function()
        EndTalentFrameMove(frame)
    end)

    UpdateTalentFrameMoveState(frame)
    return moveOverlay
end

local function BindPlayerSpellsFrameHooks(frame)
    if frame.BeavisQoLTalentFrameHooksBound then
        return
    end

    frame.BeavisQoLTalentFrameHooksBound = true
    frame:HookScript("OnShow", function(self)
        ApplyTalentFrameLayout(self)
        RefreshTalentFrameScaleUI()
    end)

    frame:HookScript("OnHide", function()
        HideScalePopup()
        if ScaleButton then
            ScaleButton:Hide()
        end
    end)
end

local function AttachPlayerSpellsFrame()
    local playerSpellsFrame = GetPlayerSpellsFrame()
    if not playerSpellsFrame then
        return false
    end

    InstallTalentFrameMoveOverlay(playerSpellsFrame)
    UpdateTalentFrameMoveState(playerSpellsFrame)
    BindPlayerSpellsFrameHooks(playerSpellsFrame)
    ApplyTalentFrameLayout(playerSpellsFrame)
    RefreshTalentFrameScaleUI()

    return true
end

function Misc.SetTalentFrameScaleEnabled(value)
    Misc.GetMiscDB().talentFrameScaleEnabled = value == true
    AttachPlayerSpellsFrame()
    RefreshTalentFrameScaleUI()
    RefreshMiscPageState()
end

function Misc.SetTalentFrameWindowLocked(value)
    Misc.GetMiscDB().talentFrameWindowLocked = value == true

    local playerSpellsFrame = GetPlayerSpellsFrame()
    if playerSpellsFrame then
        UpdateTalentFrameMoveState(playerSpellsFrame)
    end

    RefreshScalePopup()
end

function Misc.SetTalentFrameScale(value)
    Misc.GetMiscDB().talentFrameScale = NormalizeTalentFrameScale(value)

    local playerSpellsFrame = GetPlayerSpellsFrame()
    if playerSpellsFrame then
        ApplyTalentFrameLayout(playerSpellsFrame)
        RefreshTalentFrameScaleUI()
    else
        AttachPlayerSpellsFrame()
    end

    RefreshMiscPageState()
end

TalentFrameScaleWatcher:RegisterEvent("PLAYER_LOGIN")
TalentFrameScaleWatcher:RegisterEvent("ADDON_LOADED")
TalentFrameScaleWatcher:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_REGEN_ENABLED" then
        TalentFrameScaleWatcher:UnregisterEvent("PLAYER_REGEN_ENABLED")

        if pendingTalentFrameLayout then
            pendingTalentFrameLayout = false
            AttachPlayerSpellsFrame()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        -- Do not force-load Blizzard_PlayerSpells on login.
        -- Hook lazily once Blizzard opens the talents UI itself.
        if rawget(_G, "PlayerSpellsFrame") or rawget(_G, "SpellBookFrame") then
            AttachPlayerSpellsFrame()
        end
        return
    end

    if addonName == PLAYER_SPELLS_ADDON_NAME or addonName == TALENT_TREE_TWEAKS_ADDON_NAME then
        AttachPlayerSpellsFrame()
    end
end)
