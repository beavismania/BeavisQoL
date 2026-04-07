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

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local function GetSectionHeight(section)
    if not section then
        return 0
    end

    return GetTextHeight(section.Title, 15)
        + 6
        + GetTextHeight(section.Description, 11)
        + 8
        + 1
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

local function CreateSectionHeader(parent, titleText, descriptionText)
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)

    local description = parent:CreateFontString(nil, "OVERLAY")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    description:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    description:SetJustifyH("LEFT")
    description:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    description:SetTextColor(0.76, 0.76, 0.79, 1)
    description:SetText(descriptionText)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 0.82, 0, 0.18)

    return {
        Title = title,
        Description = description,
        Divider = divider,
    }
end

local PageSettings = CreateFrame("Frame", nil, Content)
PageSettings:SetAllPoints()

local PageSettingsScrollFrame = CreateFrame("ScrollFrame", nil, PageSettings, "UIPanelScrollFrameTemplate")
PageSettingsScrollFrame:SetPoint("TOPLEFT", PageSettings, "TOPLEFT", 0, 0)
PageSettingsScrollFrame:SetPoint("BOTTOMRIGHT", PageSettings, "BOTTOMRIGHT", -28, 0)
PageSettingsScrollFrame:EnableMouseWheel(true)

local PageSettingsContent = CreateFrame("Frame", nil, PageSettingsScrollFrame)
PageSettingsContent:SetSize(1, 1)
PageSettingsScrollFrame:SetScrollChild(PageSettingsContent)

local SettingsPanel = CreateFrame("Frame", nil, PageSettingsContent)
SettingsPanel:SetPoint("TOPLEFT", PageSettingsContent, "TOPLEFT", 22, -22)
SettingsPanel:SetPoint("TOPRIGHT", PageSettingsContent, "TOPRIGHT", -22, -22)
SettingsPanel:SetHeight(1)

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

local QuickHideOverlaysCheckbox
local QuickHideChecklistOverlayCheckbox
local QuickHideWeeklyOverlayCheckbox
local QuickHideStatsOverlayCheckbox
local QuickHideOverlaysInCombatCheckbox
local GeneralSection
local MinimapSection
local QuickHideSection
local ResetSection

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
end

local function GetSettingsDB()
    if BeavisQoL.GetGlobalSettings then
        return BeavisQoL.GetGlobalSettings()
    end

    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.settings = BeavisQoLDB.settings or {}
    return BeavisQoLDB.settings
end

GeneralSection = CreateSectionHeader(SettingsPanel, L("SETTINGS_SECTION_GENERAL"), L("SETTINGS_SECTION_GENERAL_DESC"))
GeneralSection.Title:SetPoint("TOPLEFT", LanguageRow, "BOTTOMLEFT", 0, -8)

-- Checkbox für Fenster fixieren
local LockCheckbox = CreateCheckbox(SettingsPanel, L("LOCK_WINDOW"), GetSettingsDB().lockWindow or false, function(self)
    local settings = GetSettingsDB()
    settings.lockWindow = self:GetChecked()
    if BeavisQoL.Frame then
        BeavisQoL.Frame:SetMovable(not settings.lockWindow)
    end
end)
LockCheckbox:SetPoint("TOPLEFT", GeneralSection.Divider, "BOTTOMLEFT", 0, -10)

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

MinimapSection = CreateSectionHeader(SettingsPanel, L("SETTINGS_SECTION_MINIMAP"), L("SETTINGS_SECTION_MINIMAP_DESC"))
MinimapSection.Title:SetPoint("TOPLEFT", LockCheckbox, "BOTTOMLEFT", 0, -22)

-- Checkbox für Minimap Button ein/ausblenden
local MinimapCheckbox = CreateCheckbox(SettingsPanel, L("MINIMAP_BUTTON_HIDE"), GetSettingsDB().hideMinimap or false, function(self)
    local settings = GetSettingsDB()
    settings.hideMinimap = self:GetChecked()
    BeavisQoLDB.minimap = BeavisQoLDB.minimap or {}
    BeavisQoLDB.minimap.hide = settings.hideMinimap
    if BeavisQoL.MinimapIcon then
        BeavisQoL.MinimapIcon:Refresh(ADDON_NAME, BeavisQoLDB.minimap)
    end
end)
MinimapCheckbox:SetPoint("TOPLEFT", MinimapSection.Divider, "BOTTOMLEFT", 0, -10)

QuickHideSection = CreateSectionHeader(SettingsPanel, L("SETTINGS_SECTION_QUICK_HIDE"), L("SETTINGS_SECTION_QUICK_HIDE_DESC"))
QuickHideSection.Title:SetPoint("TOPLEFT", MinimapCheckbox, "BOTTOMLEFT", 0, -22)

QuickHideOverlaysCheckbox = CreateCheckbox(SettingsPanel, L("QUICK_HIDE_OVERLAYS"), BeavisQoL.GetQuickHideOverlaysEnabled and BeavisQoL.GetQuickHideOverlaysEnabled() or false, function(self)
    if BeavisQoL.SetQuickHideOverlaysEnabled then
        BeavisQoL.SetQuickHideOverlaysEnabled(self:GetChecked())
        return
    end

    GetSettingsDB().quickHideOverlays = self:GetChecked()
end)
QuickHideOverlaysCheckbox:SetPoint("TOPLEFT", QuickHideSection.Divider, "BOTTOMLEFT", 0, -10)

QuickHideChecklistOverlayCheckbox = CreateCheckbox(SettingsPanel, L("QUICK_HIDE_CHECKLIST_OVERLAY"), BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("checklist") or false, function(self)
    if BeavisQoL.SetQuickHideOverlayEnabled then
        BeavisQoL.SetQuickHideOverlayEnabled("checklist", self:GetChecked())
        return
    end

    GetSettingsDB().quickHideChecklistOverlay = self:GetChecked()
end)
QuickHideChecklistOverlayCheckbox:SetPoint("TOPLEFT", QuickHideOverlaysCheckbox, "BOTTOMLEFT", 24, -8)

QuickHideWeeklyOverlayCheckbox = CreateCheckbox(SettingsPanel, L("QUICK_HIDE_WEEKLY_OVERLAY"), BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("weekly") or false, function(self)
    if BeavisQoL.SetQuickHideOverlayEnabled then
        BeavisQoL.SetQuickHideOverlayEnabled("weekly", self:GetChecked())
        return
    end

    GetSettingsDB().quickHideWeeklyOverlay = self:GetChecked()
end)
QuickHideWeeklyOverlayCheckbox:SetPoint("TOPLEFT", QuickHideChecklistOverlayCheckbox, "BOTTOMLEFT", 0, -8)

QuickHideStatsOverlayCheckbox = CreateCheckbox(SettingsPanel, L("QUICK_HIDE_STATS_OVERLAY"), BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("stats") or false, function(self)
    if BeavisQoL.SetQuickHideOverlayEnabled then
        BeavisQoL.SetQuickHideOverlayEnabled("stats", self:GetChecked())
        return
    end

    GetSettingsDB().quickHideStatsOverlay = self:GetChecked()
end)
QuickHideStatsOverlayCheckbox:SetPoint("TOPLEFT", QuickHideWeeklyOverlayCheckbox, "BOTTOMLEFT", 0, -8)

QuickHideOverlaysInCombatCheckbox = CreateCheckbox(SettingsPanel, L("QUICK_HIDE_OVERLAYS_IN_COMBAT"), BeavisQoL.GetQuickHideOverlaysInCombat and BeavisQoL.GetQuickHideOverlaysInCombat() or false, function(self)
    if BeavisQoL.SetQuickHideOverlaysInCombat then
        BeavisQoL.SetQuickHideOverlaysInCombat(self:GetChecked())
        return
    end

    GetSettingsDB().quickHideOverlaysInCombat = self:GetChecked()
end)
QuickHideOverlaysInCombatCheckbox:SetPoint("TOPLEFT", QuickHideStatsOverlayCheckbox, "BOTTOMLEFT", 24, -8)

local QuickHideMinimapContextCheckbox = CreateCheckbox(SettingsPanel, L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"), BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("quickHideOverlays") or true, function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("quickHideOverlays", self:GetChecked())
    end
end)
QuickHideMinimapContextCheckbox:SetPoint("TOPLEFT", QuickHideOverlaysInCombatCheckbox, "BOTTOMLEFT", -24, -16)

ResetSection = CreateSectionHeader(SettingsPanel, L("SETTINGS_SECTION_RESET"), L("SETTINGS_SECTION_RESET_DESC"))
ResetSection.Title:SetPoint("TOPLEFT", QuickHideMinimapContextCheckbox, "BOTTOMLEFT", 0, -24)

-- Button für Position zurücksetzen
local ResetButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetButton:SetSize(150, 30)
ResetButton:SetPoint("TOPLEFT", ResetSection.Divider, "BOTTOMLEFT", 0, -10)
ResetButton:SetText(L("RESET_POSITION"))
ResetButton:SetScript("OnClick", function()
    if BeavisQoL.Frame then
        BeavisQoL.Frame:ClearAllPoints()
        BeavisQoL.Frame:SetPoint("CENTER")
    end
end)

local function LayoutSettingsPage()
    local contentWidth = math.max(1, PageSettingsScrollFrame:GetWidth())

    if contentWidth <= 1 then
        return
    end

    PageSettingsContent:SetWidth(contentWidth)

    local requiredHeight = 18
        + GetTextHeight(SettingsTitle, 24)
        + 8
        + GetTextHeight(SettingsSubtitle, 12)
        + 18
        + LanguageRow:GetHeight()
        + 8
        + GetSectionHeight(GeneralSection)
        + 10
        + LockCheckbox:GetHeight()
        + 22
        + GetSectionHeight(MinimapSection)
        + 10
        + MinimapCheckbox:GetHeight()
        + 22
        + GetSectionHeight(QuickHideSection)
        + 10
        + QuickHideOverlaysCheckbox:GetHeight()
        + 8
        + QuickHideChecklistOverlayCheckbox:GetHeight()
        + 8
        + QuickHideWeeklyOverlayCheckbox:GetHeight()
        + 8
        + QuickHideStatsOverlayCheckbox:GetHeight()
        + 8
        + QuickHideOverlaysInCombatCheckbox:GetHeight()
        + 16
        + QuickHideMinimapContextCheckbox:GetHeight()
        + 24
        + GetSectionHeight(ResetSection)
        + 10
        + ResetButton:GetHeight()
        + 22

    SettingsPanel:SetHeight(math.max(1, math.ceil(requiredHeight)))
    PageSettingsContent:SetHeight(math.max(PageSettingsScrollFrame:GetHeight(), SettingsPanel:GetHeight() + 44))
end

BeavisQoL.UpdateSettings = function()
    local settings = GetSettingsDB()

    if LockCheckbox then
        LockCheckbox:SetChecked(settings.lockWindow or false)
        LockCheckbox.Label:SetText(L("LOCK_WINDOW"))
    end
    if MinimapCheckbox then
        MinimapCheckbox:SetChecked(settings.hideMinimap or false)
        MinimapCheckbox.Label:SetText(L("MINIMAP_BUTTON_HIDE"))
    end
    if QuickHideOverlaysCheckbox then
        QuickHideOverlaysCheckbox:SetChecked(BeavisQoL.GetQuickHideOverlaysEnabled and BeavisQoL.GetQuickHideOverlaysEnabled() or settings.quickHideOverlays or false)
        QuickHideOverlaysCheckbox.Label:SetText(L("QUICK_HIDE_OVERLAYS"))
    end
    if QuickHideChecklistOverlayCheckbox then
        QuickHideChecklistOverlayCheckbox:SetChecked(BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("checklist") or settings.quickHideChecklistOverlay or false)
        QuickHideChecklistOverlayCheckbox.Label:SetText(L("QUICK_HIDE_CHECKLIST_OVERLAY"))
    end
    if QuickHideWeeklyOverlayCheckbox then
        QuickHideWeeklyOverlayCheckbox:SetChecked(BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("weekly") or settings.quickHideWeeklyOverlay or false)
        QuickHideWeeklyOverlayCheckbox.Label:SetText(L("QUICK_HIDE_WEEKLY_OVERLAY"))
    end
    if QuickHideStatsOverlayCheckbox then
        QuickHideStatsOverlayCheckbox:SetChecked(BeavisQoL.GetQuickHideOverlayEnabled and BeavisQoL.GetQuickHideOverlayEnabled("stats") or settings.quickHideStatsOverlay or false)
        QuickHideStatsOverlayCheckbox.Label:SetText(L("QUICK_HIDE_STATS_OVERLAY"))
    end
    if QuickHideOverlaysInCombatCheckbox then
        QuickHideOverlaysInCombatCheckbox:SetChecked(BeavisQoL.GetQuickHideOverlaysInCombat and BeavisQoL.GetQuickHideOverlaysInCombat() or settings.quickHideOverlaysInCombat or false)
        QuickHideOverlaysInCombatCheckbox.Label:SetText(L("QUICK_HIDE_OVERLAYS_IN_COMBAT"))
    end
    if QuickHideMinimapContextCheckbox then
        QuickHideMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("quickHideOverlays") or true)
        QuickHideMinimapContextCheckbox.Label:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    end
    SettingsTitle:SetText(L("GLOBAL_SETTINGS"))
    SettingsSubtitle:SetText(L("GLOBAL_SETTINGS_DESC"))
    LanguageLabel:SetText(L("LANGUAGE") .. ":")
    if GeneralSection then
        GeneralSection.Title:SetText(L("SETTINGS_SECTION_GENERAL"))
        GeneralSection.Description:SetText(L("SETTINGS_SECTION_GENERAL_DESC"))
    end
    if MinimapSection then
        MinimapSection.Title:SetText(L("SETTINGS_SECTION_MINIMAP"))
        MinimapSection.Description:SetText(L("SETTINGS_SECTION_MINIMAP_DESC"))
    end
    if QuickHideSection then
        QuickHideSection.Title:SetText(L("SETTINGS_SECTION_QUICK_HIDE"))
        QuickHideSection.Description:SetText(L("SETTINGS_SECTION_QUICK_HIDE_DESC"))
    end
    if ResetSection then
        ResetSection.Title:SetText(L("SETTINGS_SECTION_RESET"))
        ResetSection.Description:SetText(L("SETTINGS_SECTION_RESET_DESC"))
    end
    ResetButton:SetText(L("RESET_POSITION"))
    RefreshLanguageDropdown()
    LayoutSettingsPage()
end

PageSettingsScrollFrame:SetScript("OnSizeChanged", LayoutSettingsPage)
PageSettingsScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageSettingsContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageSettings:SetScript("OnShow", function()
    LayoutSettingsPage()
    PageSettingsScrollFrame:SetVerticalScroll(0)
end)

BeavisQoL.Pages.Settings = PageSettings
