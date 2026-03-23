local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

-- Misc.lua ist die Sammelseite für mehrere kleine Komfortmodule.
-- Die eigentliche Fachlogik lebt in den Unterdateien unter `Pages/Misc/`,
-- diese Datei baut hauptsächlich die sichtbare Seite und ihre Schalter.

-- Diese Datei ist bewusst nur die UI-Hülle der Misc-Seite.
-- Die eigentliche Logik der einzelnen Features lebt in den Dateien unter
-- Pages/Misc/*.lua, damit Anzeige und Verhalten sauber getrennt bleiben.

-- Die Misc-Seite ist lang genug für einen eigenen ScrollFrame.
-- So können neue QoL-Module dazukommen, ohne dass unten etwas abgeschnitten wirkt.
local PageMisc = CreateFrame("Frame", nil, Content)
PageMisc:SetAllPoints()
PageMisc:Hide()

local PageMiscScrollFrame = CreateFrame("ScrollFrame", nil, PageMisc, "UIPanelScrollFrameTemplate")
PageMiscScrollFrame:SetPoint("TOPLEFT", PageMisc, "TOPLEFT", 0, 0)
PageMiscScrollFrame:SetPoint("BOTTOMRIGHT", PageMisc, "BOTTOMRIGHT", -28, 0)
PageMiscScrollFrame:EnableMouseWheel(true)

local PageMiscContent = CreateFrame("Frame", nil, PageMiscScrollFrame)
PageMiscContent:SetSize(1, 1)
PageMiscScrollFrame:SetScrollChild(PageMiscContent)

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageMiscContent)
IntroPanel:SetPoint("TOPLEFT", PageMiscContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageMiscContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(110)

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
IntroTitle:SetText(L("MISC_TITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("MISC_DESC"))

-- ========================================
-- Bereich: Auto Sell Junk
-- ========================================

local AutoSellPanel = CreateFrame("Frame", nil, PageMiscContent)
AutoSellPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
AutoSellPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
AutoSellPanel:SetHeight(115)

local AutoSellBg = AutoSellPanel:CreateTexture(nil, "BACKGROUND")
AutoSellBg:SetAllPoints()
AutoSellBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AutoSellBorder = AutoSellPanel:CreateTexture(nil, "ARTWORK")
AutoSellBorder:SetPoint("BOTTOMLEFT", AutoSellPanel, "BOTTOMLEFT", 0, 0)
AutoSellBorder:SetPoint("BOTTOMRIGHT", AutoSellPanel, "BOTTOMRIGHT", 0, 0)
AutoSellBorder:SetHeight(1)
AutoSellBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AutoSellTitle = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellTitle:SetPoint("TOPLEFT", AutoSellPanel, "TOPLEFT", 18, -14)
AutoSellTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AutoSellTitle:SetTextColor(1, 0.82, 0, 1)
AutoSellTitle:SetText(L("AUTOSELL_JUNK"))

local AutoSellCheckbox = CreateFrame("CheckButton", nil, AutoSellPanel, "UICheckButtonTemplate")
AutoSellCheckbox:SetPoint("TOPLEFT", AutoSellTitle, "BOTTOMLEFT", -4, -12)

local AutoSellLabel = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellLabel:SetPoint("LEFT", AutoSellCheckbox, "RIGHT", 6, 0)
AutoSellLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
AutoSellLabel:SetTextColor(1, 1, 1, 1)
AutoSellLabel:SetText(L("ACTIVE"))

local AutoSellHint = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellHint:SetPoint("TOPLEFT", AutoSellCheckbox, "BOTTOMLEFT", 34, -2)
AutoSellHint:SetPoint("RIGHT", AutoSellPanel, "RIGHT", -18, 0)
AutoSellHint:SetJustifyH("LEFT")
AutoSellHint:SetJustifyV("TOP")
AutoSellHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoSellHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoSellHint:SetText(L("AUTOSELL_HINT"))

-- ========================================
-- Bereich: Auto Repair
-- ========================================

local AutoRepairPanel = CreateFrame("Frame", nil, PageMiscContent)
AutoRepairPanel:SetPoint("TOPLEFT", AutoSellPanel, "BOTTOMLEFT", 0, -18)
AutoRepairPanel:SetPoint("TOPRIGHT", AutoSellPanel, "BOTTOMRIGHT", 0, -18)
AutoRepairPanel:SetHeight(180)

local AutoRepairBg = AutoRepairPanel:CreateTexture(nil, "BACKGROUND")
AutoRepairBg:SetAllPoints()
AutoRepairBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AutoRepairBorder = AutoRepairPanel:CreateTexture(nil, "ARTWORK")
AutoRepairBorder:SetPoint("BOTTOMLEFT", AutoRepairPanel, "BOTTOMLEFT", 0, 0)
AutoRepairBorder:SetPoint("BOTTOMRIGHT", AutoRepairPanel, "BOTTOMRIGHT", 0, 0)
AutoRepairBorder:SetHeight(1)
AutoRepairBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AutoRepairTitle = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairTitle:SetPoint("TOPLEFT", AutoRepairPanel, "TOPLEFT", 18, -14)
AutoRepairTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AutoRepairTitle:SetTextColor(1, 0.82, 0, 1)
AutoRepairTitle:SetText(L("AUTOREPAIR"))

local AutoRepairCheckbox = CreateFrame("CheckButton", nil, AutoRepairPanel, "UICheckButtonTemplate")
AutoRepairCheckbox:SetPoint("TOPLEFT", AutoRepairTitle, "BOTTOMLEFT", -4, -12)

local AutoRepairLabel = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairLabel:SetPoint("LEFT", AutoRepairCheckbox, "RIGHT", 6, 0)
AutoRepairLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
AutoRepairLabel:SetTextColor(1, 1, 1, 1)
AutoRepairLabel:SetText(L("ACTIVE"))

local AutoRepairHint = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairHint:SetPoint("TOPLEFT", AutoRepairCheckbox, "BOTTOMLEFT", 34, -2)
AutoRepairHint:SetPoint("RIGHT", AutoRepairPanel, "RIGHT", -18, 0)
AutoRepairHint:SetJustifyH("LEFT")
AutoRepairHint:SetJustifyV("TOP")
AutoRepairHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoRepairHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoRepairHint:SetText(L("AUTOREPAIR_HINT"))

local AutoRepairGuildCheckbox = CreateFrame("CheckButton", nil, AutoRepairPanel, "UICheckButtonTemplate")
AutoRepairGuildCheckbox:SetPoint("TOPLEFT", AutoRepairHint, "BOTTOMLEFT", -14, -18)
AutoRepairGuildCheckbox:SetScale(0.85)

local AutoRepairGuildLabel = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairGuildLabel:SetPoint("LEFT", AutoRepairGuildCheckbox, "RIGHT", 4, 0)
AutoRepairGuildLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoRepairGuildLabel:SetTextColor(1, 1, 1, 1)
AutoRepairGuildLabel:SetText(L("AUTOREPAIR_GUILD"))

local AutoRepairGuildHint = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairGuildHint:SetPoint("TOPLEFT", AutoRepairGuildCheckbox, "BOTTOMLEFT", 30, -4)
AutoRepairGuildHint:SetPoint("RIGHT", AutoRepairPanel, "RIGHT", -18, 0)
AutoRepairGuildHint:SetJustifyH("LEFT")
AutoRepairGuildHint:SetJustifyV("TOP")
AutoRepairGuildHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
AutoRepairGuildHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoRepairGuildHint:SetText(L("AUTOREPAIR_GUILD_HINT"))

-- ========================================
-- Bereich: Easy Delete
-- ========================================

local EasyDeletePanel = CreateFrame("Frame", nil, PageMiscContent)
EasyDeletePanel:SetPoint("TOPLEFT", AutoRepairPanel, "BOTTOMLEFT", 0, -18)
EasyDeletePanel:SetPoint("TOPRIGHT", AutoRepairPanel, "BOTTOMRIGHT", 0, -18)
EasyDeletePanel:SetHeight(115)

local EasyDeleteBg = EasyDeletePanel:CreateTexture(nil, "BACKGROUND")
EasyDeleteBg:SetAllPoints()
EasyDeleteBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local EasyDeleteBorder = EasyDeletePanel:CreateTexture(nil, "ARTWORK")
EasyDeleteBorder:SetPoint("BOTTOMLEFT", EasyDeletePanel, "BOTTOMLEFT", 0, 0)
EasyDeleteBorder:SetPoint("BOTTOMRIGHT", EasyDeletePanel, "BOTTOMRIGHT", 0, 0)
EasyDeleteBorder:SetHeight(1)
EasyDeleteBorder:SetColorTexture(1, 0.82, 0, 0.9)

local EasyDeleteTitle = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteTitle:SetPoint("TOPLEFT", EasyDeletePanel, "TOPLEFT", 18, -14)
EasyDeleteTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
EasyDeleteTitle:SetTextColor(1, 0.82, 0, 1)
EasyDeleteTitle:SetText(L("EASY_DELETE"))

local EasyDeleteCheckbox = CreateFrame("CheckButton", nil, EasyDeletePanel, "UICheckButtonTemplate")
EasyDeleteCheckbox:SetPoint("TOPLEFT", EasyDeleteTitle, "BOTTOMLEFT", -4, -12)

local EasyDeleteLabel = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteLabel:SetPoint("LEFT", EasyDeleteCheckbox, "RIGHT", 6, 0)
EasyDeleteLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
EasyDeleteLabel:SetTextColor(1, 1, 1, 1)
EasyDeleteLabel:SetText(L("ACTIVE"))

local EasyDeleteHint = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteHint:SetPoint("TOPLEFT", EasyDeleteCheckbox, "BOTTOMLEFT", 34, -2)
EasyDeleteHint:SetPoint("RIGHT", EasyDeletePanel, "RIGHT", -18, 0)
EasyDeleteHint:SetJustifyH("LEFT")
EasyDeleteHint:SetJustifyV("TOP")
EasyDeleteHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EasyDeleteHint:SetTextColor(0.80, 0.80, 0.80, 1)
EasyDeleteHint:SetText(L("EASY_DELETE_HINT"))

-- ========================================
-- Bereich: Fast Loot
-- ========================================

local FastLootPanel = CreateFrame("Frame", nil, PageMiscContent)
FastLootPanel:SetPoint("TOPLEFT", EasyDeletePanel, "BOTTOMLEFT", 0, -18)
FastLootPanel:SetPoint("TOPRIGHT", EasyDeletePanel, "BOTTOMRIGHT", 0, -18)
FastLootPanel:SetHeight(115)

local FastLootBg = FastLootPanel:CreateTexture(nil, "BACKGROUND")
FastLootBg:SetAllPoints()
FastLootBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local FastLootBorder = FastLootPanel:CreateTexture(nil, "ARTWORK")
FastLootBorder:SetPoint("BOTTOMLEFT", FastLootPanel, "BOTTOMLEFT", 0, 0)
FastLootBorder:SetPoint("BOTTOMRIGHT", FastLootPanel, "BOTTOMRIGHT", 0, 0)
FastLootBorder:SetHeight(1)
FastLootBorder:SetColorTexture(1, 0.82, 0, 0.9)

local FastLootTitle = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootTitle:SetPoint("TOPLEFT", FastLootPanel, "TOPLEFT", 18, -14)
FastLootTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
FastLootTitle:SetTextColor(1, 0.82, 0, 1)
FastLootTitle:SetText(L("FAST_LOOT"))

local FastLootCheckbox = CreateFrame("CheckButton", nil, FastLootPanel, "UICheckButtonTemplate")
FastLootCheckbox:SetPoint("TOPLEFT", FastLootTitle, "BOTTOMLEFT", -4, -12)

local FastLootLabel = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootLabel:SetPoint("LEFT", FastLootCheckbox, "RIGHT", 6, 0)
FastLootLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FastLootLabel:SetTextColor(1, 1, 1, 1)
FastLootLabel:SetText(L("ACTIVE"))

local FastLootHint = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootHint:SetPoint("TOPLEFT", FastLootCheckbox, "BOTTOMLEFT", 34, -2)
FastLootHint:SetPoint("RIGHT", FastLootPanel, "RIGHT", -18, 0)
FastLootHint:SetJustifyH("LEFT")
FastLootHint:SetJustifyV("TOP")
FastLootHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FastLootHint:SetTextColor(0.80, 0.80, 0.80, 1)
FastLootHint:SetText(L("FAST_LOOT_HINT"))

-- ========================================
-- Bereich: Tooltip Itemlevel
-- ========================================

-- Diese Karte schaltet das neue Tooltip-Modul ein oder aus.
-- Der eigentliche Inspect- und Tooltip-Code lebt in Pages/Misc/TooltipItemLevel.lua,
-- die UI hier ist nur die sichtbare Bedienoberfläche dafür.
local TooltipItemLevelPanel = CreateFrame("Frame", nil, PageMiscContent)
TooltipItemLevelPanel:SetPoint("TOPLEFT", FastLootPanel, "BOTTOMLEFT", 0, -18)
TooltipItemLevelPanel:SetPoint("TOPRIGHT", FastLootPanel, "BOTTOMRIGHT", 0, -18)
TooltipItemLevelPanel:SetHeight(115)

local TooltipItemLevelBg = TooltipItemLevelPanel:CreateTexture(nil, "BACKGROUND")
TooltipItemLevelBg:SetAllPoints()
TooltipItemLevelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local TooltipItemLevelBorder = TooltipItemLevelPanel:CreateTexture(nil, "ARTWORK")
TooltipItemLevelBorder:SetPoint("BOTTOMLEFT", TooltipItemLevelPanel, "BOTTOMLEFT", 0, 0)
TooltipItemLevelBorder:SetPoint("BOTTOMRIGHT", TooltipItemLevelPanel, "BOTTOMRIGHT", 0, 0)
TooltipItemLevelBorder:SetHeight(1)
TooltipItemLevelBorder:SetColorTexture(1, 0.82, 0, 0.9)

local TooltipItemLevelTitle = TooltipItemLevelPanel:CreateFontString(nil, "OVERLAY")
TooltipItemLevelTitle:SetPoint("TOPLEFT", TooltipItemLevelPanel, "TOPLEFT", 18, -14)
TooltipItemLevelTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
TooltipItemLevelTitle:SetTextColor(1, 0.82, 0, 1)
TooltipItemLevelTitle:SetText(L("TOOLTIP_ITEMLEVEL"))

-- Eine einfache Checkbox reicht hier aus, weil das Modul nur einen klaren
-- Ein/Aus-Zustand kennt.
local TooltipItemLevelCheckbox = CreateFrame("CheckButton", nil, TooltipItemLevelPanel, "UICheckButtonTemplate")
TooltipItemLevelCheckbox:SetPoint("TOPLEFT", TooltipItemLevelTitle, "BOTTOMLEFT", -4, -12)

local TooltipItemLevelLabel = TooltipItemLevelPanel:CreateFontString(nil, "OVERLAY")
TooltipItemLevelLabel:SetPoint("LEFT", TooltipItemLevelCheckbox, "RIGHT", 6, 0)
TooltipItemLevelLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
TooltipItemLevelLabel:SetTextColor(1, 1, 1, 1)
TooltipItemLevelLabel:SetText(L("ACTIVE"))

local TooltipItemLevelHint = TooltipItemLevelPanel:CreateFontString(nil, "OVERLAY")
TooltipItemLevelHint:SetPoint("TOPLEFT", TooltipItemLevelCheckbox, "BOTTOMLEFT", 34, -2)
TooltipItemLevelHint:SetPoint("RIGHT", TooltipItemLevelPanel, "RIGHT", -18, 0)
TooltipItemLevelHint:SetJustifyH("LEFT")
TooltipItemLevelHint:SetJustifyV("TOP")
TooltipItemLevelHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
TooltipItemLevelHint:SetTextColor(0.80, 0.80, 0.80, 1)
TooltipItemLevelHint:SetText(L("TOOLTIP_ITEMLEVEL_HINT"))

-- ========================================
-- Bereich: Camera Distance
-- ========================================

-- Die Kamera-Distanz ist kein klassischer Ein/Aus-Schalter wie viele andere
-- Misc-Funktionen. Darum bekommt dieses Feature bewusst eine kleine Aktionskarte
-- mit Statusanzeige und zwei klaren Ziel-Buttons.
local CameraDistancePanel = CreateFrame("Frame", nil, PageMiscContent)
CameraDistancePanel:SetPoint("TOPLEFT", TooltipItemLevelPanel, "BOTTOMLEFT", 0, -18)
CameraDistancePanel:SetPoint("TOPRIGHT", TooltipItemLevelPanel, "BOTTOMRIGHT", 0, -18)
CameraDistancePanel:SetHeight(145)

local CameraDistanceBg = CameraDistancePanel:CreateTexture(nil, "BACKGROUND")
CameraDistanceBg:SetAllPoints()
CameraDistanceBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local CameraDistanceBorder = CameraDistancePanel:CreateTexture(nil, "ARTWORK")
CameraDistanceBorder:SetPoint("BOTTOMLEFT", CameraDistancePanel, "BOTTOMLEFT", 0, 0)
CameraDistanceBorder:SetPoint("BOTTOMRIGHT", CameraDistancePanel, "BOTTOMRIGHT", 0, 0)
CameraDistanceBorder:SetHeight(1)
CameraDistanceBorder:SetColorTexture(1, 0.82, 0, 0.9)

local CameraDistanceTitle = CameraDistancePanel:CreateFontString(nil, "OVERLAY")
CameraDistanceTitle:SetPoint("TOPLEFT", CameraDistancePanel, "TOPLEFT", 18, -14)
CameraDistanceTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
CameraDistanceTitle:SetTextColor(1, 0.82, 0, 1)
CameraDistanceTitle:SetText(L("CAMERA_DISTANCE"))

local CameraDistanceHint = CameraDistancePanel:CreateFontString(nil, "OVERLAY")
CameraDistanceHint:SetPoint("TOPLEFT", CameraDistanceTitle, "BOTTOMLEFT", 0, -10)
CameraDistanceHint:SetPoint("RIGHT", CameraDistancePanel, "RIGHT", -18, 0)
CameraDistanceHint:SetJustifyH("LEFT")
CameraDistanceHint:SetJustifyV("TOP")
CameraDistanceHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CameraDistanceHint:SetTextColor(0.80, 0.80, 0.80, 1)
CameraDistanceHint:SetText(L("CAMERA_DISTANCE_HINT"))

-- Links steht die feste Beschriftung, rechts daneben der tatsächlich gelesene Status.
-- So sieht man sofort, ob gerade Standard, Max Distance oder ein eigener Wert aktiv ist.
local CameraDistanceStatusLabel = CameraDistancePanel:CreateFontString(nil, "OVERLAY")
CameraDistanceStatusLabel:SetPoint("TOPLEFT", CameraDistanceHint, "BOTTOMLEFT", 0, -16)
CameraDistanceStatusLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CameraDistanceStatusLabel:SetTextColor(1, 1, 1, 1)
CameraDistanceStatusLabel:SetText(L("CURRENT_SETTING"))

local CameraDistanceStatusValue = CameraDistancePanel:CreateFontString(nil, "OVERLAY")
CameraDistanceStatusValue:SetPoint("LEFT", CameraDistanceStatusLabel, "RIGHT", 8, 0)
CameraDistanceStatusValue:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
CameraDistanceStatusValue:SetTextColor(1, 0.82, 0, 1)
CameraDistanceStatusValue:SetText(L("UNKNOWN"))

-- Die Buttons setzen keine lokalen UI-Zustände, sondern geben die Aktion direkt
-- an das Kamera-Modul weiter. Die Anzeige wird danach immer aus dem echten
-- CVar-Zustand neu aufgebaut.
local CameraDistanceMaxButton = CreateFrame("Button", nil, CameraDistancePanel, "UIPanelButtonTemplate")
CameraDistanceMaxButton:SetSize(130, 24)
CameraDistanceMaxButton:SetPoint("TOPLEFT", CameraDistanceStatusLabel, "BOTTOMLEFT", 0, -18)
CameraDistanceMaxButton:SetText(L("CAMERA_DISTANCE_MAX"))

local CameraDistanceStandardButton = CreateFrame("Button", nil, CameraDistancePanel, "UIPanelButtonTemplate")
CameraDistanceStandardButton:SetSize(110, 24)
CameraDistanceStandardButton:SetPoint("LEFT", CameraDistanceMaxButton, "RIGHT", 10, 0)
CameraDistanceStandardButton:SetText(L("STANDARD"))

local SectionPanels = {
    AutoSell = AutoSellPanel,
    AutoRepair = AutoRepairPanel,
    EasyDelete = EasyDeletePanel,
    FastLoot = FastLootPanel,
    -- Der Schlüsselname muss zum Tree-Eintrag passen, damit die Sidebar diese
    -- Karte gezielt ansteuern und sichtbar machen kann.
    TooltipItemLevel = TooltipItemLevelPanel,
    CameraDistance = CameraDistancePanel,
}

-- ========================================
-- UI-Status
-- ========================================

-- Die Checkboxen lesen ihren Zustand direkt aus den Modulen.
function PageMisc:RefreshState()
    local autoSellEnabled = false
    local autoRepairEnabled = false
    local autoRepairGuildEnabled = false
    local easyDeleteEnabled = false
    local fastLootEnabled = false
    local tooltipItemLevelEnabled = false
    -- Für die Kamera brauchen wir nicht nur "an/aus", sondern sowohl den
    -- groben Modus als auch den fertigen Text für die Anzeige.
    local cameraDistanceMode = "unknown"
    local cameraDistanceStatusText = L("UNKNOWN")

    if Misc.IsAutoSellJunkEnabled then
        autoSellEnabled = Misc.IsAutoSellJunkEnabled()
    end

    if Misc.IsAutoRepairEnabled then
        autoRepairEnabled = Misc.IsAutoRepairEnabled()
    end

    if Misc.IsAutoRepairGuildEnabled then
        autoRepairGuildEnabled = Misc.IsAutoRepairGuildEnabled()
    end

    if Misc.IsEasyDeleteEnabled then
        easyDeleteEnabled = Misc.IsEasyDeleteEnabled()
    end

    if Misc.IsFastLootEnabled then
        fastLootEnabled = Misc.IsFastLootEnabled()
    end

    -- Der Tooltip-Schalter wird direkt aus dem Modul gelesen, damit UI und
    -- SavedVariables immer denselben Wahrheitswert anzeigen.
    if Misc.IsTooltipItemLevelEnabled then
        tooltipItemLevelEnabled = Misc.IsTooltipItemLevelEnabled()
    end

    if Misc.GetCurrentCameraDistanceMode then
        cameraDistanceMode = Misc.GetCurrentCameraDistanceMode()
    end

    if Misc.GetCameraDistanceStatusText then
        cameraDistanceStatusText = Misc.GetCameraDistanceStatusText()
    end
    -- Die Seite fragt die Modul-Funktionen bewusst nur optional ab.
    -- So bleibt die UI robust, selbst wenn ein Teilmodul später einmal
    -- umgebaut oder vorübergehend nicht geladen sein sollte.

    IntroTitle:SetText(L("MISC_TITLE"))
    IntroText:SetText(L("MISC_DESC"))
    AutoSellTitle:SetText(L("AUTOSELL_JUNK"))
    AutoSellLabel:SetText(L("ACTIVE"))
    AutoSellHint:SetText(L("AUTOSELL_HINT"))
    AutoRepairTitle:SetText(L("AUTOREPAIR"))
    AutoRepairLabel:SetText(L("ACTIVE"))
    AutoRepairHint:SetText(L("AUTOREPAIR_HINT"))
    AutoRepairGuildLabel:SetText(L("AUTOREPAIR_GUILD"))
    AutoRepairGuildHint:SetText(L("AUTOREPAIR_GUILD_HINT"))
    EasyDeleteTitle:SetText(L("EASY_DELETE"))
    EasyDeleteLabel:SetText(L("ACTIVE"))
    EasyDeleteHint:SetText(L("EASY_DELETE_HINT"))
    FastLootTitle:SetText(L("FAST_LOOT"))
    FastLootLabel:SetText(L("ACTIVE"))
    FastLootHint:SetText(L("FAST_LOOT_HINT"))
    TooltipItemLevelTitle:SetText(L("TOOLTIP_ITEMLEVEL"))
    TooltipItemLevelLabel:SetText(L("ACTIVE"))
    TooltipItemLevelHint:SetText(L("TOOLTIP_ITEMLEVEL_HINT"))
    CameraDistanceTitle:SetText(L("CAMERA_DISTANCE"))
    CameraDistanceHint:SetText(L("CAMERA_DISTANCE_HINT"))
    CameraDistanceStatusLabel:SetText(L("CURRENT_SETTING"))
    CameraDistanceMaxButton:SetText(L("CAMERA_DISTANCE_MAX"))
    CameraDistanceStandardButton:SetText(L("STANDARD"))

    AutoSellCheckbox:SetChecked(autoSellEnabled)
    AutoRepairCheckbox:SetChecked(autoRepairEnabled)
    AutoRepairGuildCheckbox:SetChecked(autoRepairGuildEnabled)
    EasyDeleteCheckbox:SetChecked(easyDeleteEnabled)
    FastLootCheckbox:SetChecked(fastLootEnabled)
    TooltipItemLevelCheckbox:SetChecked(tooltipItemLevelEnabled)
    -- Die Kamera-Karte zeigt bewusst den echten Status aus dem Modul an,
    -- nicht bloß den letzten Button-Klick.
    CameraDistanceStatusValue:SetText(cameraDistanceStatusText)
    -- Der bereits aktive Preset-Button wird deaktiviert.
    -- Das macht die Karte lesbarer und verhindert unnötige Wiederhol-Klicks.
    CameraDistanceMaxButton:SetEnabled(cameraDistanceMode ~= "max")
    CameraDistanceStandardButton:SetEnabled(cameraDistanceMode ~= "standard")

    -- Die Gilden-Option ergibt nur Sinn, wenn Auto Repair aktiv ist.
    AutoRepairGuildCheckbox:SetEnabled(autoRepairEnabled)

    if autoRepairEnabled then
        AutoRepairGuildLabel:SetTextColor(1, 1, 1, 1)
        AutoRepairGuildHint:SetTextColor(0.80, 0.80, 0.80, 1)
    else
        AutoRepairGuildLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        AutoRepairGuildHint:SetTextColor(0.45, 0.45, 0.45, 1)
        AutoRepairGuildCheckbox:SetChecked(false)
    end
end

-- Die Höhe setzen wir aus den sichtbaren Blöcken zusammen.
function PageMisc:UpdateScrollLayout()
    -- Statt den Inhalt an feste Pixelpositionen zu ketten, berechnen wir die
    -- Gesamtgröße aus allen Panels. Das ist für spätere Erweiterungen
    -- deutlich wartbarer als viele verstreute Einzel-Offsets.
    local contentWidth = math.max(1, PageMiscScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + AutoSellPanel:GetHeight()
        + 18 + AutoRepairPanel:GetHeight()
        + 18 + EasyDeletePanel:GetHeight()
        + 18 + FastLootPanel:GetHeight()
        + 18 + TooltipItemLevelPanel:GetHeight()
        -- Die neue Kamera-Karte gehört fest in die Gesamthöhe,
        -- damit der Scrollbereich unten nicht zu früh endet.
        + 18 + CameraDistancePanel:GetHeight()
        + 20

    PageMiscContent:SetWidth(contentWidth)
    PageMiscContent:SetHeight(contentHeight)
end

function PageMisc:OpenSection(sectionKey)
    local targetPanel = SectionPanels[sectionKey]
    if not targetPanel then
        return
    end

    self:RefreshState()
    self:UpdateScrollLayout()

    local function ScrollToSection()
        local contentTop = PageMiscContent:GetTop()
        local panelTop = targetPanel:GetTop()

        if not contentTop or not panelTop then
            return
        end

        local maxScroll = math.max(0, PageMiscContent:GetHeight() - PageMiscScrollFrame:GetHeight())
        local targetScroll = math.max(0, math.min(maxScroll, math.floor((contentTop - panelTop) + 8)))
        PageMiscScrollFrame:SetVerticalScroll(targetScroll)
    end

    ScrollToSection()

    if C_Timer and C_Timer.After then
        C_Timer.After(0, ScrollToSection)
    end
end

PageMiscScrollFrame:SetScript("OnSizeChanged", function()
    PageMisc:UpdateScrollLayout()
end)

-- Mit dem Mausrad fühlt sich die Seite etwas angenehmer an.
PageMiscScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageMiscContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

-- ========================================
-- Klicklogik
-- ========================================

-- Jede Checkbox gibt die Änderung direkt an ihr Modul weiter.
AutoSellCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoSellJunkEnabled then
        Misc.SetAutoSellJunkEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

AutoRepairCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoRepairEnabled then
        Misc.SetAutoRepairEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

AutoRepairGuildCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoRepairGuildEnabled then
        Misc.SetAutoRepairGuildEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

EasyDeleteCheckbox:SetScript("OnClick", function(self)
    if Misc.SetEasyDeleteEnabled then
        Misc.SetEasyDeleteEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FastLootCheckbox:SetScript("OnClick", function(self)
    if Misc.SetFastLootEnabled then
        Misc.SetFastLootEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

TooltipItemLevelCheckbox:SetScript("OnClick", function(self)
    -- Die UI speichert den Zustand nicht selbst, sondern reicht ihn direkt
    -- an das Modul weiter. Danach wird die komplette Seite neu synchronisiert.
    if Misc.SetTooltipItemLevelEnabled then
        Misc.SetTooltipItemLevelEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

-- Die Kamera-Buttons arbeiten absichtlich genauso schlicht wie die Checkboxen:
-- Aktion ans Modul weitergeben, danach die Seite sofort neu zeichnen.
CameraDistanceMaxButton:SetScript("OnClick", function()
    if Misc.SetCameraDistanceMode then
        Misc.SetCameraDistanceMode("max")
    end

    PageMisc:RefreshState()
end)

CameraDistanceStandardButton:SetScript("OnClick", function()
    if Misc.SetCameraDistanceMode then
        Misc.SetCameraDistanceMode("standard")
    end

    PageMisc:RefreshState()
end)

PageMisc:SetScript("OnShow", function()
    -- Beim Öffnen springen wir wieder nach oben, damit die Seite immer gleich startet.
    PageMisc:RefreshState()
    PageMisc:UpdateScrollLayout()
    PageMiscScrollFrame:SetVerticalScroll(0)
end)

PageMisc:UpdateScrollLayout()
PageMisc:RefreshState()

BeavisQoL.Pages.Misc = PageMisc
