local ADDON_NAME, BeavisQoL = ...

--[[
Tree.lua rendert die linke Navigation.
Die Seite selbst zeigt keine Inhalte, sondern nur:
- Hauptgruppen
- Modulsektionen
- Eintraege zum Oeffnen der Seiten
]]

local SidebarFrame = BeavisQoL.Sidebar
local Pages = BeavisQoL.Pages

local L = BeavisQoL.L
local SidebarCaption = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaption:SetPoint("TOPLEFT", SidebarFrame, "TOPLEFT", 14, -12)
SidebarCaption:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SidebarCaption:SetTextColor(1, 0.82, 0, 1)
SidebarCaption:SetText(L("NAVIGATION"))

local SidebarCaptionHint = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaptionHint:SetPoint("TOPLEFT", SidebarCaption, "BOTTOMLEFT", 0, -4)
SidebarCaptionHint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
SidebarCaptionHint:SetTextColor(0.74, 0.74, 0.76, 1)
SidebarCaptionHint:SetText(L("NAVIGATION_HINT"))

local SidebarScrollFrame = CreateFrame("ScrollFrame", nil, SidebarFrame, "UIPanelScrollFrameTemplate")
SidebarScrollFrame:SetPoint("TOPLEFT", SidebarFrame, "TOPLEFT", 10, -46)
SidebarScrollFrame:SetPoint("BOTTOMRIGHT", SidebarFrame, "BOTTOMRIGHT", -28, 10)
SidebarScrollFrame:EnableMouseWheel(true)

local Sidebar = CreateFrame("Frame", nil, SidebarScrollFrame)
Sidebar:SetSize(1, 1)
SidebarScrollFrame:SetScrollChild(Sidebar)

local GeneralExpanded = true
local ModuleExpanded = true

local GeneralEntries = {}
local ModuleSectionHeaders = {}
local ModuleEntries = {}
local AllEntries = {}

local function ShowPage(pageToShow)
    if not pageToShow then
        return
    end

    for _, page in pairs(Pages) do
        page:Hide()
    end

    pageToShow:Show()
end

local function ApplyToggleVisual(button, hovered)
    local backgroundAlpha = hovered and 0.08 or 0.04
    local indicatorAlpha = hovered and 0.22 or 0.14

    button.Bg:SetColorTexture(1, 0.82, 0, backgroundAlpha)
    button.IndicatorBg:SetColorTexture(1, 0.82, 0, indicatorAlpha)
    button.Indicator:SetText(button.IsExpanded and "-" or "+")
end

local function CreateToggleButton(labelTextKey)
    local button = CreateFrame("Button", nil, Sidebar)
    button:SetSize(192, 26)
    button:SetHitRectInsets(-4, -4, -2, -2)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0.82, 0, 0.04)
    button.Bg = bg

    local indicatorBg = button:CreateTexture(nil, "ARTWORK")
    indicatorBg:SetSize(18, 18)
    indicatorBg:SetPoint("LEFT", button, "LEFT", 8, 0)
    indicatorBg:SetColorTexture(1, 0.82, 0, 0.14)
    button.IndicatorBg = indicatorBg

    local indicator = button:CreateFontString(nil, "OVERLAY")
    indicator:SetPoint("CENTER", indicatorBg, "CENTER", 0, 0)
    indicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    indicator:SetTextColor(1, 0.92, 0.45, 1)
    indicator:SetText("+")

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", indicatorBg, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    text:SetTextColor(1, 0.82, 0, 1)
    text:SetText(L(labelTextKey))

    button.Indicator = indicator
    button.Text = text
    button.IsExpanded = false

    button:SetScript("OnEnter", function(self)
        ApplyToggleVisual(self, true)
    end)

    button:SetScript("OnLeave", function(self)
        ApplyToggleVisual(self, false)
    end)

    ApplyToggleVisual(button, false)
    return button, indicator, text
end

local function ApplyEntryVisual(entry, hovered)
    if entry.isActive then
        entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.11)
        entry.button.Accent:SetAlpha(1)
        entry.text:SetTextColor(1, 0.9, 0.35, 1)
        return
    end

    if hovered then
        entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.055)
        entry.button.Accent:SetAlpha(0.45)
        entry.text:SetTextColor(1, 1, 1, 1)
        return
    end

    entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.015)
    entry.button.Accent:SetAlpha(0)
    entry.text:SetTextColor(0.92, 0.92, 0.95, 1)
end

local function AttachEntryVisual(entry)
    entry.button:SetScript("OnEnter", function()
        ApplyEntryVisual(entry, true)
    end)

    entry.button:SetScript("OnLeave", function()
        ApplyEntryVisual(entry, false)
    end)

    ApplyEntryVisual(entry, false)
end

local function CreateEntryButton(labelTextKey)
    local button = CreateFrame("Button", nil, Sidebar)
    button:SetSize(192, 24)
    button:SetHitRectInsets(-4, -4, -2, -2)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0.82, 0, 0.015)
    button.Bg = bg

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    accent:SetColorTexture(1, 0.82, 0, 0.95)
    accent:SetAlpha(0)
    button.Accent = accent

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", button, "LEFT", 12, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    text:SetTextColor(0.92, 0.92, 0.95, 1)
    text:SetText(L(labelTextKey))

    return button, text
end

local function CreateSectionHeader(labelTextKey)
    local frame = CreateFrame("Frame", nil, Sidebar)
    frame:SetSize(192, 22)

    local line = frame:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("LEFT", frame, "LEFT", 0, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(1, 0.82, 0, 0.12)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("LEFT", frame, "LEFT", 0, 0)
    accent:SetSize(18, 2)
    accent:SetColorTexture(1, 0.82, 0, 0.8)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", frame, "LEFT", 0, 8)
    text:SetPoint("RIGHT", frame, "RIGHT", 0, 8)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetTextColor(1, 0.82, 0, 0.85)
    text:SetText(L(labelTextKey))

    return frame, text
end

local TreeGeneralButton, TreeGeneralIndicator = CreateToggleButton("GENERAL")
local TreeModuleButton, TreeModuleIndicator = CreateToggleButton("MODULES")

local function RegisterGeneralEntry(pageKey, labelTextKey)
    local button, text = CreateEntryButton(labelTextKey)
    local entry = {
        pageKey = pageKey,
        button = button,
        text = text,
        miscSection = nil,
        isActive = false,
    }

    GeneralEntries[#GeneralEntries + 1] = entry
    AllEntries[#AllEntries + 1] = entry
    AttachEntryVisual(entry)
    return button, text
end

local function RegisterModuleSection(labelTextKey)
    local frame, text = CreateSectionHeader(labelTextKey)
    local section = {
        frame = frame,
        text = text,
        entries = {},
    }

    ModuleSectionHeaders[#ModuleSectionHeaders + 1] = section
    return section
end

local function RegisterModuleEntry(section, labelTextKey, pageKey, options)
    local button, text = CreateEntryButton(labelTextKey)
    local entry = {
        pageKey = pageKey,
        button = button,
        text = text,
        miscSection = options and options.miscSection or nil,
        isActive = false,
    }

    section.entries[#section.entries + 1] = entry
    ModuleEntries[#ModuleEntries + 1] = entry
    AllEntries[#AllEntries + 1] = entry
    AttachEntryVisual(entry)
    return entry
end

local TreeHomeButton, TreeHomeText = RegisterGeneralEntry("Home", "HOME")
local TreeVersionButton, TreeVersionText = RegisterGeneralEntry("Version", "VERSION")
local TreeSettingsButton, TreeSettingsText = RegisterGeneralEntry("Settings", "SETTINGS")

local ProgressSection = RegisterModuleSection("PROGRESS")
local GoldSection = RegisterModuleSection("GOLD_TRADE")
local ComfortSection = RegisterModuleSection("COMFORT")
local InterfaceSection = RegisterModuleSection("INTERFACE_COMBAT")
local GroupSection = RegisterModuleSection("GROUP_SEARCH")
local CompanionSection = RegisterModuleSection("COMPANION")

local LevelTimeEntry = RegisterModuleEntry(ProgressSection, "LEVEL_TIME", "LevelTime")
local ChecklistEntry = RegisterModuleEntry(ProgressSection, "CHECKLIST", "Checklist")
local WeeklyKeysEntry = RegisterModuleEntry(ProgressSection, "WEEKLY_KEYS", "WeeklyKeys")
local ItemLevelGuideEntry = RegisterModuleEntry(ProgressSection, "ITEMLEVEL_GUIDE", "ItemLevelGuide")
local QuestCheckEntry = RegisterModuleEntry(ProgressSection, "QUEST_CHECK", "QuestCheck")

local LoggingEntry = RegisterModuleEntry(GoldSection, "LOGGING", "Logging")
local AutoSellEntry = RegisterModuleEntry(GoldSection, "AUTOSELL_JUNK", "Misc", { miscSection = "AutoSell" })
local AutoRepairEntry = RegisterModuleEntry(GoldSection, "AUTOREPAIR", "Misc", { miscSection = "AutoRepair" })

local FastLootEntry = RegisterModuleEntry(ComfortSection, "FAST_LOOT", "Misc", { miscSection = "FastLoot" })
local EasyDeleteEntry = RegisterModuleEntry(ComfortSection, "EASY_DELETE", "Misc", { miscSection = "EasyDelete" })
local CameraDistanceEntry = RegisterModuleEntry(ComfortSection, "CAMERA_DISTANCE", "Misc", { miscSection = "CameraDistance" })

local StatsEntry = RegisterModuleEntry(InterfaceSection, "STATS", "Stats")
local CombatTextEntry = RegisterModuleEntry(InterfaceSection, "COMBAT_TEXT", "DamageText")
local LFGEntry = RegisterModuleEntry(GroupSection, "LFG", "LFG")
local PetStuffEntry = RegisterModuleEntry(CompanionSection, "PET_STUFF", "PetStuff")

local function SetActiveTreeItem(activeText)
    for _, entry in ipairs(AllEntries) do
        entry.isActive = activeText ~= nil and entry.text == activeText
        ApplyEntryVisual(entry, false)
    end
end

local function UpdateTreeScrollLayout(contentBottomY)
    Sidebar:SetWidth(math.max(1, SidebarScrollFrame:GetWidth()))
    Sidebar:SetHeight(math.max(SidebarScrollFrame:GetHeight(), -contentBottomY + 28))

    local maxScroll = math.max(0, Sidebar:GetHeight() - SidebarScrollFrame:GetHeight())
    if SidebarScrollFrame:GetVerticalScroll() > maxScroll then
        SidebarScrollFrame:SetVerticalScroll(maxScroll)
    end
end

local function HideModuleSection(section)
    section.frame:Hide()
    section.frame:ClearAllPoints()

    for _, entry in ipairs(section.entries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end
end

local function UpdateTreeLayout()
    TreeGeneralButton:ClearAllPoints()
    TreeModuleButton:ClearAllPoints()

    for _, entry in ipairs(GeneralEntries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end

    for _, section in ipairs(ModuleSectionHeaders) do
        HideModuleSection(section)
    end

    TreeGeneralButton.IsExpanded = GeneralExpanded
    TreeModuleButton.IsExpanded = ModuleExpanded
    ApplyToggleVisual(TreeGeneralButton, false)
    ApplyToggleVisual(TreeModuleButton, false)

    local groupX = 6
    local childX = 16
    local sectionX = 16
    local sectionChildX = 24
    local currentY = -4

    TreeGeneralButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if GeneralExpanded then
        TreeGeneralIndicator:SetText("-")
        currentY = currentY - 34

        for _, entry in ipairs(GeneralEntries) do
            entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
            entry.button:Show()
            currentY = currentY - 30
        end

        currentY = currentY - 4
    else
        TreeGeneralIndicator:SetText("+")
        currentY = currentY - 40
    end

    TreeModuleButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if not ModuleExpanded then
        TreeModuleIndicator:SetText("+")
        UpdateTreeScrollLayout(currentY - 12)
        return
    end

    TreeModuleIndicator:SetText("-")
    currentY = currentY - 34

    for _, section in ipairs(ModuleSectionHeaders) do
        section.frame:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionX, currentY)
        section.frame:Show()
        currentY = currentY - 28

        for _, entry in ipairs(section.entries) do
            entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionChildX, currentY)
            entry.button:Show()
            currentY = currentY - 28
        end

        currentY = currentY - 10
    end

    UpdateTreeScrollLayout(currentY)
end

SidebarScrollFrame:SetScript("OnSizeChanged", function()
    UpdateTreeLayout()
end)

SidebarScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 44
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, Sidebar:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

BeavisQoL.UpdateTree = function()
    SidebarCaption:SetText(L("NAVIGATION"))
    SidebarCaptionHint:SetText(L("NAVIGATION_HINT"))

    TreeGeneralButton.Text:SetText(L("GENERAL"))
    TreeModuleButton.Text:SetText(L("MODULES"))

    TreeHomeText:SetText(L("HOME"))
    TreeVersionText:SetText(L("VERSION"))
    TreeSettingsText:SetText(L("SETTINGS"))

    ProgressSection.text:SetText(L("PROGRESS"))
    GoldSection.text:SetText(L("GOLD_TRADE"))
    ComfortSection.text:SetText(L("COMFORT"))
    InterfaceSection.text:SetText(L("INTERFACE_COMBAT"))
    GroupSection.text:SetText(L("GROUP_SEARCH"))
    CompanionSection.text:SetText(L("COMPANION"))

    LevelTimeEntry.text:SetText(L("LEVEL_TIME"))
    ChecklistEntry.text:SetText(L("CHECKLIST"))
    WeeklyKeysEntry.text:SetText(L("WEEKLY_KEYS"))
    ItemLevelGuideEntry.text:SetText(L("ITEMLEVEL_GUIDE"))
    QuestCheckEntry.text:SetText(L("QUEST_CHECK"))
    LoggingEntry.text:SetText(L("LOGGING"))
    AutoSellEntry.text:SetText(L("AUTOSELL_JUNK"))
    AutoRepairEntry.text:SetText(L("AUTOREPAIR"))
    FastLootEntry.text:SetText(L("FAST_LOOT"))
    EasyDeleteEntry.text:SetText(L("EASY_DELETE"))
    CameraDistanceEntry.text:SetText(L("CAMERA_DISTANCE"))
    StatsEntry.text:SetText(L("STATS"))
    CombatTextEntry.text:SetText(L("COMBAT_TEXT"))
    LFGEntry.text:SetText(L("LFG"))
    PetStuffEntry.text:SetText(L("PET_STUFF"))

    UpdateTreeLayout()
end

function BeavisQoL.OpenPage(pageKey, activeTextOverride)
    if not BeavisQoL.Frame or not Pages then
        return
    end

    local pageMap = {
        Home = { page = Pages.Home, text = TreeHomeText, group = "general" },
        Version = { page = Pages.Version, text = TreeVersionText, group = "general" },
        Settings = { page = Pages.Settings, text = TreeSettingsText, group = "general" },
        LevelTime = { page = Pages.LevelTime, text = LevelTimeEntry.text, group = "module" },
        Checklist = { page = Pages.Checklist, text = ChecklistEntry.text, group = "module" },
        WeeklyKeys = { page = Pages.WeeklyKeys, text = WeeklyKeysEntry.text, group = "module" },
        ItemLevelGuide = { page = Pages.ItemLevelGuide, text = ItemLevelGuideEntry.text, group = "module" },
        Logging = { page = Pages.Logging, text = LoggingEntry.text, group = "module" },
        QuestCheck = { page = Pages.QuestCheck, text = QuestCheckEntry.text, group = "module" },
        Misc = { page = Pages.Misc, text = nil, group = "module" },
        Stats = { page = Pages.Stats, text = StatsEntry.text, group = "module" },
        PetStuff = { page = Pages.PetStuff, text = PetStuffEntry.text, group = "module" },
        LFG = { page = Pages.LFG, text = LFGEntry.text, group = "module" },
        DamageText = { page = Pages.DamageText, text = CombatTextEntry.text, group = "module" },
    }

    local target = pageMap[pageKey]
    if not target or not target.page then
        return
    end

    if target.group == "general" then
        GeneralExpanded = true
    elseif target.group == "module" then
        ModuleExpanded = true
    end

    UpdateTreeLayout()

    if not BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Show()
    end

    ShowPage(target.page)
    SetActiveTreeItem(activeTextOverride or target.text)
end

function BeavisQoL.OpenMiscSection(sectionKey, activeTextOverride)
    BeavisQoL.OpenPage("Misc", activeTextOverride)

    local miscPage = Pages and Pages.Misc
    if miscPage and miscPage.OpenSection then
        miscPage:OpenSection(sectionKey)
    end
end

TreeGeneralButton:SetScript("OnClick", function()
    GeneralExpanded = not GeneralExpanded
    UpdateTreeLayout()
end)

TreeModuleButton:SetScript("OnClick", function()
    ModuleExpanded = not ModuleExpanded
    UpdateTreeLayout()
end)

TreeHomeButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Home")
end)

TreeVersionButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Version")
end)

TreeSettingsButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Settings")
end)

for _, entry in ipairs(ModuleEntries) do
    entry.button:SetScript("OnClick", function()
        if entry.miscSection then
            BeavisQoL.OpenMiscSection(entry.miscSection, entry.text)
            return
        end

        BeavisQoL.OpenPage(entry.pageKey, entry.text)
    end)
end

UpdateTreeLayout()
ShowPage(Pages.Home)
SetActiveTreeItem(TreeHomeText)
