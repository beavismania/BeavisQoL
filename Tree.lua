local ADDON_NAME, BeavisAddon = ...

local Sidebar = BeavisAddon.Sidebar
local Pages = BeavisAddon.Pages

local GeneralExpanded = false
local ModuleExpanded = false

-- Hilfsfunktion: Seite anzeigen
local function ShowPage(pageToShow)
    if not pageToShow then
        return
    end

    for _, page in pairs(Pages) do
        page:Hide()
    end

    pageToShow:Show()
end

-- ========================================
-- Tree Gruppe: Allgemein
-- ========================================

local TreeGeneralButton = CreateFrame("Button", nil, Sidebar)
TreeGeneralButton:SetSize(160, 20)

local TreeGeneralIndicator = TreeGeneralButton:CreateFontString(nil, "OVERLAY")
TreeGeneralIndicator:SetPoint("LEFT", TreeGeneralButton, "LEFT", 0, 0)
TreeGeneralIndicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeGeneralIndicator:SetTextColor(1, 0.82, 0, 1)
TreeGeneralIndicator:SetText("+")

local TreeGeneralText = TreeGeneralButton:CreateFontString(nil, "OVERLAY")
TreeGeneralText:SetPoint("LEFT", TreeGeneralIndicator, "RIGHT", 6, 0)
TreeGeneralText:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
TreeGeneralText:SetTextColor(1, 0.82, 0, 1)
TreeGeneralText:SetText("Allgemein")

-- Eintrag: Home
local TreeHomeButton = CreateFrame("Button", nil, Sidebar)
TreeHomeButton:SetSize(140, 20)

local TreeHomeText = TreeHomeButton:CreateFontString(nil, "OVERLAY")
TreeHomeText:SetAllPoints()
TreeHomeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeHomeText:SetJustifyH("LEFT")
TreeHomeText:SetTextColor(1, 1, 1, 1)
TreeHomeText:SetText("Home")

-- Eintrag: Version
local TreeVersionButton = CreateFrame("Button", nil, Sidebar)
TreeVersionButton:SetSize(140, 20)

local TreeVersionText = TreeVersionButton:CreateFontString(nil, "OVERLAY")
TreeVersionText:SetAllPoints()
TreeVersionText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeVersionText:SetJustifyH("LEFT")
TreeVersionText:SetTextColor(1, 1, 1, 1)
TreeVersionText:SetText("Version")

-- Eintrag: Einstellungen
local TreeSettingsButton = CreateFrame("Button", nil, Sidebar)
TreeSettingsButton:SetSize(140, 20)

local TreeSettingsText = TreeSettingsButton:CreateFontString(nil, "OVERLAY")
TreeSettingsText:SetAllPoints()
TreeSettingsText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeSettingsText:SetJustifyH("LEFT")
TreeSettingsText:SetTextColor(1, 1, 1, 1)
TreeSettingsText:SetText("Einstellungen")

-- ========================================
-- Tree Gruppe: Module
-- ========================================

local TreeModuleButton = CreateFrame("Button", nil, Sidebar)
TreeModuleButton:SetSize(160, 20)

local TreeModuleIndicator = TreeModuleButton:CreateFontString(nil, "OVERLAY")
TreeModuleIndicator:SetPoint("LEFT", TreeModuleButton, "LEFT", 0, 0)
TreeModuleIndicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeModuleIndicator:SetTextColor(1, 0.82, 0, 1)
TreeModuleIndicator:SetText("+")

local TreeModuleText = TreeModuleButton:CreateFontString(nil, "OVERLAY")
TreeModuleText:SetPoint("LEFT", TreeModuleIndicator, "RIGHT", 6, 0)
TreeModuleText:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
TreeModuleText:SetTextColor(1, 0.82, 0, 1)
TreeModuleText:SetText("Module")

-- Eintrag: Levelzeit
local TreeLevelTimeButton = CreateFrame("Button", nil, Sidebar)
TreeLevelTimeButton:SetSize(140, 20)

local TreeLevelTimeText = TreeLevelTimeButton:CreateFontString(nil, "OVERLAY")
TreeLevelTimeText:SetAllPoints()
TreeLevelTimeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeLevelTimeText:SetJustifyH("LEFT")
TreeLevelTimeText:SetTextColor(1, 1, 1, 1)
TreeLevelTimeText:SetText("Levelzeit")

-- ========================================
-- Aktiven Tree-Eintrag färben
-- ========================================

local function SetActiveTreeItem(activeText)
    TreeHomeText:SetTextColor(1, 1, 1, 1)
    TreeSettingsText:SetTextColor(1, 1, 1, 1)
    TreeVersionText:SetTextColor(1, 1, 1, 1)
    TreeLevelTimeText:SetTextColor(1, 1, 1, 1)

    if activeText then
        activeText:SetTextColor(1, 0.82, 0, 1)
    end
end

-- ========================================
-- Tree Layout dynamisch aufbauen
-- ========================================

local function UpdateTreeLayout()
    TreeGeneralButton:ClearAllPoints()
    TreeHomeButton:ClearAllPoints()
    TreeSettingsButton:ClearAllPoints()
    TreeModuleButton:ClearAllPoints()
    TreeLevelTimeButton:ClearAllPoints()

    TreeHomeButton:Hide()
    TreeSettingsButton:Hide()
    TreeLevelTimeButton:Hide()
    TreeVersionButton:Hide()

    local groupX = 12
    local childX = 28
    local currentY = -20

-- Allgemein
TreeGeneralButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

if GeneralExpanded then
    TreeGeneralIndicator:SetText("-")

    currentY = currentY - 28
    TreeHomeButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
    TreeHomeButton:Show()

    currentY = currentY - 26
    TreeVersionButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
    TreeVersionButton:Show()

    currentY = currentY - 26
    TreeSettingsButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
    TreeSettingsButton:Show()

    currentY = currentY - 32
else
    TreeGeneralIndicator:SetText("+")
    currentY = currentY - 38
end


    -- Module
    TreeModuleButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if ModuleExpanded then
        TreeModuleIndicator:SetText("-")

        currentY = currentY - 28
        TreeLevelTimeButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreeLevelTimeButton:Show()
    else
        TreeModuleIndicator:SetText("+")
    end
end

-- ========================================
-- Klicklogik
-- ========================================

TreeGeneralButton:SetScript("OnClick", function()
    GeneralExpanded = not GeneralExpanded
    UpdateTreeLayout()
end)

TreeModuleButton:SetScript("OnClick", function()
    ModuleExpanded = not ModuleExpanded
    UpdateTreeLayout()
end)
TreeVersionButton:SetScript("OnClick", function()
    ShowPage(Pages.Version)
    SetActiveTreeItem(TreeVersionText)
end)

TreeHomeButton:SetScript("OnClick", function()
    ShowPage(Pages.Home)
    SetActiveTreeItem(TreeHomeText)
end)

TreeSettingsButton:SetScript("OnClick", function()
    ShowPage(Pages.Settings)
    SetActiveTreeItem(TreeSettingsText)
end)

TreeLevelTimeButton:SetScript("OnClick", function()
    ShowPage(Pages.LevelTime)
    SetActiveTreeItem(TreeLevelTimeText)
end)

-- ========================================
-- Startzustand
-- ========================================

UpdateTreeLayout()
ShowPage(Pages.Home)
SetActiveTreeItem(TreeHomeText)