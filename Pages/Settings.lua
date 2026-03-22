local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME

local function CreatePanelSurface(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    local glow = frame:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    glow:SetHeight(34)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -12)
    accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 12)
    accent:SetWidth(3)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)

    return {
        bg = bg,
        glow = glow,
        accent = accent,
        border = border,
    }
end

local function ApplyPanelSurface(surface, style, highlighted)
    local bgR = 0.085
    local bgG = 0.085
    local bgB = 0.09
    local bgA = 0.94
    local glowA = 0.05
    local accentA = 0.7
    local borderA = 0.78

    if style == "hero" then
        bgR = 0.065
        bgG = 0.065
        bgB = 0.07
        bgA = 0.97
        glowA = 0.09
        accentA = 0.88
        borderA = 0.88
    elseif style == "footer" then
        bgR = 0.075
        bgG = 0.075
        bgB = 0.08
        bgA = 0.9
        glowA = 0.04
        accentA = 0.55
        borderA = 0.6
    end

    if highlighted then
        bgR = bgR + 0.03
        bgG = bgG + 0.03
        bgB = bgB + 0.03
        glowA = glowA + 0.05
        accentA = math.min(1, accentA + 0.12)
    end

    surface.bg:SetColorTexture(bgR, bgG, bgB, bgA)
    surface.glow:SetColorTexture(1, 0.82, 0, glowA)
    surface.accent:SetColorTexture(1, 0.82, 0, accentA)
    surface.border:SetColorTexture(1, 0.82, 0, borderA)
end

local function CreateCheckbox(parent, label, checked, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)

    local text = check:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", check, "RIGHT", 8, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    text:SetTextColor(0.96, 0.96, 0.96, 1)
    text:SetText(label)

    check.Label = text

    return check
end

local PageSettings = CreateFrame("Frame", nil, Content)
PageSettings:SetAllPoints()

local SettingsPanel = CreateFrame("Frame", nil, PageSettings)
SettingsPanel:SetPoint("TOPLEFT", PageSettings, "TOPLEFT", 22, -22)
SettingsPanel:SetPoint("TOPRIGHT", PageSettings, "TOPRIGHT", -22, -22)
SettingsPanel:SetHeight(400)

local SettingsSurface = CreatePanelSurface(SettingsPanel)
ApplyPanelSurface(SettingsSurface, "hero", false)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 22, -18)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.82, 0, 1)
SettingsTitle:SetText(L("GLOBAL_SETTINGS"))

local SettingsSubtitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsSubtitle:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", 0, -8)
SettingsSubtitle:SetPoint("RIGHT", SettingsPanel, "RIGHT", -22, 0)
SettingsSubtitle:SetJustifyH("LEFT")
SettingsSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SettingsSubtitle:SetTextColor(0.84, 0.84, 0.86, 1)
SettingsSubtitle:SetText(L("GLOBAL_SETTINGS_DESC"))

local LanguageRow = CreateFrame("Frame", nil, SettingsPanel)
LanguageRow:SetPoint("TOPLEFT", SettingsSubtitle, "BOTTOMLEFT", 0, -18)
LanguageRow:SetPoint("RIGHT", SettingsPanel, "RIGHT", -22, 0)
LanguageRow:SetHeight(42)

local LanguageLabel = LanguageRow:CreateFontString(nil, "OVERLAY")
LanguageLabel:SetPoint("LEFT", LanguageRow, "LEFT", 0, 0)
LanguageLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
LanguageLabel:SetTextColor(0.96, 0.96, 0.96, 1)
LanguageLabel:SetText(L("LANGUAGE") .. ":")

local LanguageDropdown = CreateFrame("Frame", nil, LanguageRow, "UIDropDownMenuTemplate")
LanguageDropdown:SetPoint("LEFT", LanguageLabel, "RIGHT", 12, -2)

local localeLabels = {
    deDE = "Deutsch",
    enUS = "English",
}

local function GetLocaleLabel(code)
    return localeLabels[code] or code
end

local function RefreshLanguageDropdown()
    local currentLocale = BeavisQoL.GetLocale()
    UIDropDownMenu_SetWidth(LanguageDropdown, 120)
    UIDropDownMenu_SetText(LanguageDropdown, GetLocaleLabel(currentLocale))
    UIDropDownMenu_SetSelectedValue(LanguageDropdown, currentLocale)
end

-- Checkbox für Fenster fixieren
local LockCheckbox = CreateCheckbox(SettingsPanel, L("LOCK_WINDOW"), (BeavisQoLDB.settings and BeavisQoLDB.settings.lockWindow) or false, function(self)
    if not BeavisQoLDB.settings then BeavisQoLDB.settings = {} end
    BeavisQoLDB.settings.lockWindow = self:GetChecked()
    if BeavisQoL.Frame then
        BeavisQoL.Frame:SetMovable(not BeavisQoLDB.settings.lockWindow)
    end
end)
LockCheckbox:SetPoint("TOPLEFT", LanguageRow, "BOTTOMLEFT", 0, -8)

local function SetLanguage(lang)
    BeavisQoL.SetLocale(lang)
    ReloadUI()
end

UIDropDownMenu_Initialize(LanguageDropdown, function(self, level)
    local current = BeavisQoL.GetLocale()
    for _, code in ipairs(BeavisQoL.AvailableLocales or {"deDE", "enUS"}) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = GetLocaleLabel(code)
        info.value = code
        info.checked = (current == code)
        info.func = function() SetLanguage(code) end
        UIDropDownMenu_AddButton(info, level)
    end
end)
RefreshLanguageDropdown()

-- Checkbox für Minimap Button ein/ausblenden
local MinimapCheckbox = CreateCheckbox(SettingsPanel, L("MINIMAP_BUTTON_HIDE"), (BeavisQoLDB.settings and BeavisQoLDB.settings.hideMinimap) or false, function(self)
    if not BeavisQoLDB.settings then BeavisQoLDB.settings = {} end
    BeavisQoLDB.settings.hideMinimap = self:GetChecked()
    BeavisQoLDB.minimap = BeavisQoLDB.minimap or {}
    BeavisQoLDB.minimap.hide = BeavisQoLDB.settings.hideMinimap
    if BeavisQoL.MinimapIcon then
        BeavisQoL.MinimapIcon:Refresh(ADDON_NAME, BeavisQoLDB.minimap)
    end
end)
MinimapCheckbox:SetPoint("TOPLEFT", LockCheckbox, "BOTTOMLEFT", 0, -20)

-- Button für Position zurücksetzen
local ResetButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetButton:SetSize(150, 30)
ResetButton:SetPoint("TOPLEFT", MinimapCheckbox, "BOTTOMLEFT", 0, -20)
ResetButton:SetText(L("RESET_POSITION"))
ResetButton:SetScript("OnClick", function()
    if BeavisQoL.Frame then
        BeavisQoL.Frame:ClearAllPoints()
        BeavisQoL.Frame:SetPoint("CENTER")
    end
end)

BeavisQoL.UpdateSettings = function()
    if LockCheckbox then
        LockCheckbox:SetChecked((BeavisQoLDB.settings and BeavisQoLDB.settings.lockWindow) or false)
        LockCheckbox.Label:SetText(L("LOCK_WINDOW"))
    end
    if MinimapCheckbox then
        MinimapCheckbox:SetChecked((BeavisQoLDB.settings and BeavisQoLDB.settings.hideMinimap) or false)
        MinimapCheckbox.Label:SetText(L("MINIMAP_BUTTON_HIDE"))
    end
    SettingsTitle:SetText(L("GLOBAL_SETTINGS"))
    SettingsSubtitle:SetText(L("GLOBAL_SETTINGS_DESC"))
    LanguageLabel:SetText(L("LANGUAGE") .. ":")
    ResetButton:SetText(L("RESET_POSITION"))
    RefreshLanguageDropdown()
end

BeavisQoL.Pages.Settings = PageSettings
