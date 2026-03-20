local ADDON_NAME, BeavisQoL = ...

-- Tree.lua setzt auf die UI-Teile aus UI.lua auf:
-- Sidebar = linker Navigationsbereich
-- Pages   = Sammlung aller Seiten-Frames, die spaeter ein-/ausgeblendet werden.
local Sidebar = BeavisQoL.Sidebar
local Pages = BeavisQoL.Pages

-- Die Gruppen starten eingeklappt, damit die Sidebar auch mit mehr Modulen ruhig bleibt.
local GeneralExpanded = false
local ModuleExpanded = false

-- Die Seiten liegen einfach übereinander. Darum reicht es, immer nur eine einzublenden.
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

-- Die Buttons werden alle sofort erzeugt, aber ihre Positionen kommen erst
-- spaeter in UpdateTreeLayout(). So kann dieselbe Layout-Funktion sowohl
-- eingeklappte als auch aufgeklappte Gruppen sauber behandeln.
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

local TreeHomeButton = CreateFrame("Button", nil, Sidebar)
TreeHomeButton:SetSize(140, 20)

local TreeHomeText = TreeHomeButton:CreateFontString(nil, "OVERLAY")
TreeHomeText:SetAllPoints()
TreeHomeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeHomeText:SetJustifyH("LEFT")
TreeHomeText:SetTextColor(1, 1, 1, 1)
TreeHomeText:SetText("Home")

local TreeVersionButton = CreateFrame("Button", nil, Sidebar)
TreeVersionButton:SetSize(140, 20)

local TreeVersionText = TreeVersionButton:CreateFontString(nil, "OVERLAY")
TreeVersionText:SetAllPoints()
TreeVersionText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeVersionText:SetJustifyH("LEFT")
TreeVersionText:SetTextColor(1, 1, 1, 1)
TreeVersionText:SetText("Version")

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

local TreeLevelTimeButton = CreateFrame("Button", nil, Sidebar)
TreeLevelTimeButton:SetSize(140, 20)

local TreeLevelTimeText = TreeLevelTimeButton:CreateFontString(nil, "OVERLAY")
TreeLevelTimeText:SetAllPoints()
TreeLevelTimeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeLevelTimeText:SetJustifyH("LEFT")
TreeLevelTimeText:SetTextColor(1, 1, 1, 1)
TreeLevelTimeText:SetText("Levelzeit")

local TreeMiscButton = CreateFrame("Button", nil, Sidebar)
TreeMiscButton:SetSize(140, 20)

local TreeMiscText = TreeMiscButton:CreateFontString(nil, "OVERLAY")
TreeMiscText:SetAllPoints()
TreeMiscText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeMiscText:SetJustifyH("LEFT")
TreeMiscText:SetTextColor(1, 1, 1, 1)
TreeMiscText:SetText("Misc")

local TreePetStuffButton = CreateFrame("Button", nil, Sidebar)
TreePetStuffButton:SetSize(140, 20)

local TreePetStuffText = TreePetStuffButton:CreateFontString(nil, "OVERLAY")
TreePetStuffText:SetAllPoints()
TreePetStuffText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreePetStuffText:SetJustifyH("LEFT")
TreePetStuffText:SetTextColor(1, 1, 1, 1)
TreePetStuffText:SetText("Pet Stuff")

local TreeLFGButton = CreateFrame("Button", nil, Sidebar)
TreeLFGButton:SetSize(140, 20)

local TreeLFGText = TreeLFGButton:CreateFontString(nil, "OVERLAY")
TreeLFGText:SetAllPoints()
TreeLFGText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeLFGText:SetJustifyH("LEFT")
TreeLFGText:SetTextColor(1, 1, 1, 1)
TreeLFGText:SetText("Gruppensuche")

local TreeDamageTextButton = CreateFrame("Button", nil, Sidebar)
TreeDamageTextButton:SetSize(140, 20)

local TreeDamageTextText = TreeDamageTextButton:CreateFontString(nil, "OVERLAY")
TreeDamageTextText:SetAllPoints()
TreeDamageTextText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TreeDamageTextText:SetJustifyH("LEFT")
TreeDamageTextText:SetTextColor(1, 1, 1, 1)
TreeDamageTextText:SetText("Combat Text")

-- ========================================
-- Aktiven Tree-Eintrag färben
-- ========================================

-- Die aktive Farbe setzen wir zentral, damit die Buttons simpel bleiben.
local function SetActiveTreeItem(activeText)
    TreeHomeText:SetTextColor(1, 1, 1, 1)
    TreeSettingsText:SetTextColor(1, 1, 1, 1)
    TreeVersionText:SetTextColor(1, 1, 1, 1)
    TreeLevelTimeText:SetTextColor(1, 1, 1, 1)
    TreeMiscText:SetTextColor(1, 1, 1, 1)
    TreePetStuffText:SetTextColor(1, 1, 1, 1)
    TreeLFGText:SetTextColor(1, 1, 1, 1)
    TreeDamageTextText:SetTextColor(1, 1, 1, 1)

    if activeText then
        activeText:SetTextColor(1, 0.82, 0, 1)
    end
end

-- ========================================
-- Tree Layout dynamisch aufbauen
-- ========================================

-- Das Layout wird nach jedem Auf- oder Zuklappen neu aufgebaut.
-- Bei der kleinen Zahl an Einträgen ist das robuster als feste Y-Offsets.
local function UpdateTreeLayout()
    -- Wir starten jeden Neuaufbau mit einem neutralen Zustand:
    -- Positionen loeschen, Unterpunkte verstecken und danach von oben nach unten
    -- frisch setzen. Das ist robuster als viele voneinander abhaengige Offsets.
    TreeGeneralButton:ClearAllPoints()
    TreeHomeButton:ClearAllPoints()
    TreeVersionButton:ClearAllPoints()
    TreeSettingsButton:ClearAllPoints()
    TreeModuleButton:ClearAllPoints()
    TreeLevelTimeButton:ClearAllPoints()
    TreeMiscButton:ClearAllPoints()
    TreePetStuffButton:ClearAllPoints()
    TreeLFGButton:ClearAllPoints()
    TreeDamageTextButton:ClearAllPoints()

    TreeHomeButton:Hide()
    TreeVersionButton:Hide()
    TreeSettingsButton:Hide()
    TreeLevelTimeButton:Hide()
    TreeMiscButton:Hide()
    TreePetStuffButton:Hide()
    TreeLFGButton:Hide()
    TreeDamageTextButton:Hide()

    local groupX = 12
    local childX = 28
    local currentY = -20

    -- Erst "Allgemein", danach hängt die Modulgruppe direkt darunter.
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

    TreeModuleButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if ModuleExpanded then
        TreeModuleIndicator:SetText("-")

        currentY = currentY - 28
        TreeLevelTimeButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreeLevelTimeButton:Show()

        currentY = currentY - 26
        TreeMiscButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreeMiscButton:Show()

        currentY = currentY - 26
        TreePetStuffButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreePetStuffButton:Show()

        currentY = currentY - 26
        TreeLFGButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreeLFGButton:Show()

        currentY = currentY - 26
        TreeDamageTextButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
        TreeDamageTextButton:Show()
    else
        TreeModuleIndicator:SetText("+")
    end
end

-- ========================================
-- Klicklogik
-- ========================================

-- Die Buttons klappen Gruppen auf oder wechseln die Seite.
-- Alles, was den eigentlichen Inhalt betrifft, bleibt in den Seiten-Dateien.
TreeGeneralButton:SetScript("OnClick", function()
    GeneralExpanded = not GeneralExpanded
    UpdateTreeLayout()
end)

TreeModuleButton:SetScript("OnClick", function()
    ModuleExpanded = not ModuleExpanded
    UpdateTreeLayout()
end)

TreeHomeButton:SetScript("OnClick", function()
    ShowPage(Pages.Home)
    SetActiveTreeItem(TreeHomeText)
end)

TreeVersionButton:SetScript("OnClick", function()
    ShowPage(Pages.Version)
    SetActiveTreeItem(TreeVersionText)
end)

TreeSettingsButton:SetScript("OnClick", function()
    ShowPage(Pages.Settings)
    SetActiveTreeItem(TreeSettingsText)
end)

TreeLevelTimeButton:SetScript("OnClick", function()
    ShowPage(Pages.LevelTime)
    SetActiveTreeItem(TreeLevelTimeText)
end)

TreeMiscButton:SetScript("OnClick", function()
    ShowPage(Pages.Misc)
    SetActiveTreeItem(TreeMiscText)
end)

TreePetStuffButton:SetScript("OnClick", function()
    ShowPage(Pages.PetStuff)
    SetActiveTreeItem(TreePetStuffText)
end)

TreeLFGButton:SetScript("OnClick", function()
    ShowPage(Pages.LFG)
    SetActiveTreeItem(TreeLFGText)
end)

TreeDamageTextButton:SetScript("OnClick", function()
    ShowPage(Pages.DamageText)
    SetActiveTreeItem(TreeDamageTextText)
end)

-- ========================================
-- Startzustand
-- ========================================

-- Home ist die neutralste Startseite und bleibt deshalb der Standard.
UpdateTreeLayout()
ShowPage(Pages.Home)
SetActiveTreeItem(TreeHomeText)
