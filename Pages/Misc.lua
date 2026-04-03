local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

if not rawget(_G, "UIDropDownMenuTemplate") then
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_UIDropDownMenu")
    elseif UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_UIDropDownMenu")
    end
end

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
-- Bereich: Cutscene Skip
-- ========================================

local CutsceneSkipPanel = CreateFrame("Frame", nil, PageMiscContent)
CutsceneSkipPanel:SetPoint("TOPLEFT", FastLootPanel, "BOTTOMLEFT", 0, -18)
CutsceneSkipPanel:SetPoint("TOPRIGHT", FastLootPanel, "BOTTOMRIGHT", 0, -18)
CutsceneSkipPanel:SetHeight(115)

local CutsceneSkipBg = CutsceneSkipPanel:CreateTexture(nil, "BACKGROUND")
CutsceneSkipBg:SetAllPoints()
CutsceneSkipBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local CutsceneSkipBorder = CutsceneSkipPanel:CreateTexture(nil, "ARTWORK")
CutsceneSkipBorder:SetPoint("BOTTOMLEFT", CutsceneSkipPanel, "BOTTOMLEFT", 0, 0)
CutsceneSkipBorder:SetPoint("BOTTOMRIGHT", CutsceneSkipPanel, "BOTTOMRIGHT", 0, 0)
CutsceneSkipBorder:SetHeight(1)
CutsceneSkipBorder:SetColorTexture(1, 0.82, 0, 0.9)

local CutsceneSkipTitle = CutsceneSkipPanel:CreateFontString(nil, "OVERLAY")
CutsceneSkipTitle:SetPoint("TOPLEFT", CutsceneSkipPanel, "TOPLEFT", 18, -14)
CutsceneSkipTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
CutsceneSkipTitle:SetTextColor(1, 0.82, 0, 1)
CutsceneSkipTitle:SetText(L("CUTSCENE_SKIP"))

local CutsceneSkipCheckbox = CreateFrame("CheckButton", nil, CutsceneSkipPanel, "UICheckButtonTemplate")
CutsceneSkipCheckbox:SetPoint("TOPLEFT", CutsceneSkipTitle, "BOTTOMLEFT", -4, -12)

local CutsceneSkipLabel = CutsceneSkipPanel:CreateFontString(nil, "OVERLAY")
CutsceneSkipLabel:SetPoint("LEFT", CutsceneSkipCheckbox, "RIGHT", 6, 0)
CutsceneSkipLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
CutsceneSkipLabel:SetTextColor(1, 1, 1, 1)
CutsceneSkipLabel:SetText(L("ACTIVE"))

local CutsceneSkipHint = CutsceneSkipPanel:CreateFontString(nil, "OVERLAY")
CutsceneSkipHint:SetPoint("TOPLEFT", CutsceneSkipCheckbox, "BOTTOMLEFT", 34, -2)
CutsceneSkipHint:SetPoint("RIGHT", CutsceneSkipPanel, "RIGHT", -18, 0)
CutsceneSkipHint:SetJustifyH("LEFT")
CutsceneSkipHint:SetJustifyV("TOP")
CutsceneSkipHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CutsceneSkipHint:SetTextColor(0.80, 0.80, 0.80, 1)
CutsceneSkipHint:SetText(L("CUTSCENE_SKIP_HINT"))

-- ========================================
-- Bereich: Flight Master Timer
-- ========================================

local FlightMasterTimerPanel = CreateFrame("Frame", nil, PageMiscContent)
local FLIGHT_MASTER_TIMER_PANEL_MIN_HEIGHT = 320
local FLIGHT_MASTER_TIMER_PANEL_BOTTOM_PADDING = 18
FlightMasterTimerPanel:SetPoint("TOPLEFT", CutsceneSkipPanel, "BOTTOMLEFT", 0, -18)
FlightMasterTimerPanel:SetPoint("TOPRIGHT", CutsceneSkipPanel, "BOTTOMRIGHT", 0, -18)
FlightMasterTimerPanel:SetHeight(FLIGHT_MASTER_TIMER_PANEL_MIN_HEIGHT)

local FlightMasterTimerBg = FlightMasterTimerPanel:CreateTexture(nil, "BACKGROUND")
FlightMasterTimerBg:SetAllPoints()
FlightMasterTimerBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local FlightMasterTimerBorder = FlightMasterTimerPanel:CreateTexture(nil, "ARTWORK")
FlightMasterTimerBorder:SetPoint("BOTTOMLEFT", FlightMasterTimerPanel, "BOTTOMLEFT", 0, 0)
FlightMasterTimerBorder:SetPoint("BOTTOMRIGHT", FlightMasterTimerPanel, "BOTTOMRIGHT", 0, 0)
FlightMasterTimerBorder:SetHeight(1)
FlightMasterTimerBorder:SetColorTexture(1, 0.82, 0, 0.9)

local FlightMasterTimerTitle = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerTitle:SetPoint("TOPLEFT", FlightMasterTimerPanel, "TOPLEFT", 18, -14)
FlightMasterTimerTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
FlightMasterTimerTitle:SetTextColor(1, 0.82, 0, 1)
FlightMasterTimerTitle:SetText(L("FLIGHT_MASTER_TIMER"))

local FlightMasterTimerCheckbox = CreateFrame("CheckButton", nil, FlightMasterTimerPanel, "UICheckButtonTemplate")
FlightMasterTimerCheckbox:SetPoint("TOPLEFT", FlightMasterTimerTitle, "BOTTOMLEFT", -4, -12)

local FlightMasterTimerLabel = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerLabel:SetPoint("LEFT", FlightMasterTimerCheckbox, "RIGHT", 6, 0)
FlightMasterTimerLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FlightMasterTimerLabel:SetTextColor(1, 1, 1, 1)
FlightMasterTimerLabel:SetText(L("ACTIVE"))

local FlightMasterTimerHint = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerHint:SetPoint("TOPLEFT", FlightMasterTimerCheckbox, "BOTTOMLEFT", 34, -2)
FlightMasterTimerHint:SetPoint("RIGHT", FlightMasterTimerPanel, "RIGHT", -18, 0)
FlightMasterTimerHint:SetJustifyH("LEFT")
FlightMasterTimerHint:SetJustifyV("TOP")
FlightMasterTimerHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlightMasterTimerHint:SetTextColor(0.80, 0.80, 0.80, 1)
FlightMasterTimerHint:SetText(L("FLIGHT_MASTER_TIMER_HINT"))

local FlightMasterTimerSoundCheckbox = CreateFrame("CheckButton", nil, FlightMasterTimerPanel, "UICheckButtonTemplate")
FlightMasterTimerSoundCheckbox:SetPoint("TOPLEFT", FlightMasterTimerHint, "BOTTOMLEFT", -14, -16)
FlightMasterTimerSoundCheckbox:SetScale(0.85)

local FlightMasterTimerSoundLabel = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerSoundLabel:SetPoint("LEFT", FlightMasterTimerSoundCheckbox, "RIGHT", 4, 0)
FlightMasterTimerSoundLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlightMasterTimerSoundLabel:SetTextColor(1, 1, 1, 1)
FlightMasterTimerSoundLabel:SetText(L("FLIGHT_MASTER_TIMER_SOUND"))

local FlightMasterTimerSoundHint = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerSoundHint:SetPoint("TOPLEFT", FlightMasterTimerSoundCheckbox, "BOTTOMLEFT", 30, -4)
FlightMasterTimerSoundHint:SetPoint("RIGHT", FlightMasterTimerPanel, "RIGHT", -18, 0)
FlightMasterTimerSoundHint:SetJustifyH("LEFT")
FlightMasterTimerSoundHint:SetJustifyV("TOP")
FlightMasterTimerSoundHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
FlightMasterTimerSoundHint:SetTextColor(0.80, 0.80, 0.80, 1)
FlightMasterTimerSoundHint:SetText(L("FLIGHT_MASTER_TIMER_SOUND_HINT"))

local FlightMasterTimerSoundSelectLabel = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerSoundSelectLabel:SetPoint("TOPLEFT", FlightMasterTimerSoundHint, "BOTTOMLEFT", 0, -14)
FlightMasterTimerSoundSelectLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlightMasterTimerSoundSelectLabel:SetTextColor(1, 1, 1, 1)
FlightMasterTimerSoundSelectLabel:SetText(L("FLIGHT_MASTER_TIMER_SOUND_SELECT"))

local FlightMasterTimerSoundDropdown = CreateFrame("Frame", "BeavisQoLFlightMasterTimerSoundDropdown", FlightMasterTimerPanel, "UIDropDownMenuTemplate")
FlightMasterTimerSoundDropdown:SetPoint("TOPLEFT", FlightMasterTimerSoundSelectLabel, "BOTTOMLEFT", -18, -2)
UIDropDownMenu_SetWidth(FlightMasterTimerSoundDropdown, 175)
UIDropDownMenu_SetText(FlightMasterTimerSoundDropdown, L("UNKNOWN"))

local FlightMasterTimerSoundTestButton = CreateFrame("Button", nil, FlightMasterTimerPanel, "UIPanelButtonTemplate")
FlightMasterTimerSoundTestButton:SetSize(26, 22)
FlightMasterTimerSoundTestButton:SetPoint("TOPLEFT", FlightMasterTimerSoundDropdown, "TOPRIGHT", -4, -2)
FlightMasterTimerSoundTestButton:SetText(">")

local FlightMasterTimerLockCheckbox = CreateFrame("CheckButton", nil, FlightMasterTimerPanel, "UICheckButtonTemplate")
FlightMasterTimerLockCheckbox:SetPoint("TOPLEFT", FlightMasterTimerSoundDropdown, "BOTTOMLEFT", 18, -10)
FlightMasterTimerLockCheckbox:SetScale(0.85)

local FlightMasterTimerLockLabel = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerLockLabel:SetPoint("LEFT", FlightMasterTimerLockCheckbox, "RIGHT", 4, 0)
FlightMasterTimerLockLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlightMasterTimerLockLabel:SetTextColor(1, 1, 1, 1)
FlightMasterTimerLockLabel:SetText(L("FLIGHT_MASTER_TIMER_LOCK_OVERLAY"))

local FlightMasterTimerLockHint = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerLockHint:SetPoint("TOPLEFT", FlightMasterTimerLockCheckbox, "BOTTOMLEFT", 30, -4)
FlightMasterTimerLockHint:SetPoint("RIGHT", FlightMasterTimerPanel, "RIGHT", -18, 0)
FlightMasterTimerLockHint:SetJustifyH("LEFT")
FlightMasterTimerLockHint:SetJustifyV("TOP")
FlightMasterTimerLockHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
FlightMasterTimerLockHint:SetTextColor(0.80, 0.80, 0.80, 1)
FlightMasterTimerLockHint:SetText(L("FLIGHT_MASTER_TIMER_LOCK_OVERLAY_HINT"))

local FlightMasterTimerPreviewButton = CreateFrame("Button", nil, FlightMasterTimerPanel, "UIPanelButtonTemplate")
FlightMasterTimerPreviewButton:SetSize(170, 22)
FlightMasterTimerPreviewButton:SetPoint("TOPLEFT", FlightMasterTimerLockHint, "BOTTOMLEFT", 0, -14)
FlightMasterTimerPreviewButton:SetText(L("FLIGHT_MASTER_TIMER_POSITION_MODE"))

local FlightMasterTimerPreviewHint = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerPreviewHint:SetPoint("TOPLEFT", FlightMasterTimerPreviewButton, "TOPRIGHT", 10, -3)
FlightMasterTimerPreviewHint:SetPoint("RIGHT", FlightMasterTimerPanel, "RIGHT", -18, 0)
FlightMasterTimerPreviewHint:SetJustifyH("LEFT")
FlightMasterTimerPreviewHint:SetJustifyV("TOP")
FlightMasterTimerPreviewHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
FlightMasterTimerPreviewHint:SetTextColor(0.72, 0.72, 0.72, 1)
FlightMasterTimerPreviewHint:SetText(L("FLIGHT_MASTER_TIMER_POSITION_MODE_HINT"))

local FlightMasterTimerResetButton = CreateFrame("Button", nil, FlightMasterTimerPanel, "UIPanelButtonTemplate")
FlightMasterTimerResetButton:SetSize(170, 22)
FlightMasterTimerResetButton:SetPoint("TOPLEFT", FlightMasterTimerPreviewButton, "BOTTOMLEFT", 0, -14)
FlightMasterTimerResetButton:SetText(L("RESET_POSITION"))

local FlightMasterTimerResetHint = FlightMasterTimerPanel:CreateFontString(nil, "OVERLAY")
FlightMasterTimerResetHint:SetPoint("TOPLEFT", FlightMasterTimerResetButton, "TOPRIGHT", 10, -3)
FlightMasterTimerResetHint:SetPoint("RIGHT", FlightMasterTimerPanel, "RIGHT", -18, 0)
FlightMasterTimerResetHint:SetJustifyH("LEFT")
FlightMasterTimerResetHint:SetJustifyV("TOP")
FlightMasterTimerResetHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
FlightMasterTimerResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
FlightMasterTimerResetHint:SetText(L("FLIGHT_MASTER_TIMER_RESET_HINT"))

local function UpdateFlightMasterTimerPanelLayout()
    local panelTop = FlightMasterTimerPanel:GetTop()
    local lowestBottom = nil

    if not panelTop then
        FlightMasterTimerPanel:SetHeight(FLIGHT_MASTER_TIMER_PANEL_MIN_HEIGHT)
        return false
    end

    for _, region in ipairs({
        FlightMasterTimerPreviewHint,
        FlightMasterTimerResetHint,
        FlightMasterTimerResetButton,
    }) do
        local bottom = region and region:GetBottom()
        if bottom and (not lowestBottom or bottom < lowestBottom) then
            lowestBottom = bottom
        end
    end

    if not lowestBottom then
        FlightMasterTimerPanel:SetHeight(FLIGHT_MASTER_TIMER_PANEL_MIN_HEIGHT)
        return false
    end

    local targetHeight = math.max(
        FLIGHT_MASTER_TIMER_PANEL_MIN_HEIGHT,
        math.ceil((panelTop - lowestBottom) + FLIGHT_MASTER_TIMER_PANEL_BOTTOM_PADDING)
    )

    if FlightMasterTimerPanel:GetHeight() ~= targetHeight then
        FlightMasterTimerPanel:SetHeight(targetHeight)
        return true
    end

    return false
end

-- ========================================
-- Bereich: Tooltip Itemlevel
-- ========================================

-- Diese Karte schaltet das neue Tooltip-Modul ein oder aus.
-- Der eigentliche Inspect- und Tooltip-Code lebt in Pages/Misc/TooltipItemLevel.lua,
-- die UI hier ist nur die sichtbare Bedienoberfläche dafür.
local TooltipItemLevelPanel = CreateFrame("Frame", nil, PageMiscContent)
TooltipItemLevelPanel:SetPoint("TOPLEFT", FlightMasterTimerPanel, "BOTTOMLEFT", 0, -18)
TooltipItemLevelPanel:SetPoint("TOPRIGHT", FlightMasterTimerPanel, "BOTTOMRIGHT", 0, -18)
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

-- ========================================
-- Bereich: Prey Hunt Progress
-- ========================================

local PreyHuntProgressPanel = CreateFrame("Frame", nil, PageMiscContent)
PreyHuntProgressPanel:SetPoint("TOPLEFT", CameraDistancePanel, "BOTTOMLEFT", 0, -18)
PreyHuntProgressPanel:SetPoint("TOPRIGHT", CameraDistancePanel, "BOTTOMRIGHT", 0, -18)
PreyHuntProgressPanel:SetHeight(115)

local PreyHuntProgressBg = PreyHuntProgressPanel:CreateTexture(nil, "BACKGROUND")
PreyHuntProgressBg:SetAllPoints()
PreyHuntProgressBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local PreyHuntProgressBorder = PreyHuntProgressPanel:CreateTexture(nil, "ARTWORK")
PreyHuntProgressBorder:SetPoint("BOTTOMLEFT", PreyHuntProgressPanel, "BOTTOMLEFT", 0, 0)
PreyHuntProgressBorder:SetPoint("BOTTOMRIGHT", PreyHuntProgressPanel, "BOTTOMRIGHT", 0, 0)
PreyHuntProgressBorder:SetHeight(1)
PreyHuntProgressBorder:SetColorTexture(1, 0.82, 0, 0.9)

local PreyHuntProgressTitle = PreyHuntProgressPanel:CreateFontString(nil, "OVERLAY")
PreyHuntProgressTitle:SetPoint("TOPLEFT", PreyHuntProgressPanel, "TOPLEFT", 18, -14)
PreyHuntProgressTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
PreyHuntProgressTitle:SetTextColor(1, 0.82, 0, 1)
PreyHuntProgressTitle:SetText(L("PREY_HUNT_PROGRESS"))

local PreyHuntProgressCheckbox = CreateFrame("CheckButton", nil, PreyHuntProgressPanel, "UICheckButtonTemplate")
PreyHuntProgressCheckbox:SetPoint("TOPLEFT", PreyHuntProgressTitle, "BOTTOMLEFT", -4, -12)

local PreyHuntProgressLabel = PreyHuntProgressPanel:CreateFontString(nil, "OVERLAY")
PreyHuntProgressLabel:SetPoint("LEFT", PreyHuntProgressCheckbox, "RIGHT", 6, 0)
PreyHuntProgressLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
PreyHuntProgressLabel:SetTextColor(1, 1, 1, 1)
PreyHuntProgressLabel:SetText(L("ACTIVE"))

local PreyHuntProgressHint = PreyHuntProgressPanel:CreateFontString(nil, "OVERLAY")
PreyHuntProgressHint:SetPoint("TOPLEFT", PreyHuntProgressCheckbox, "BOTTOMLEFT", 34, -2)
PreyHuntProgressHint:SetPoint("RIGHT", PreyHuntProgressPanel, "RIGHT", -18, 0)
PreyHuntProgressHint:SetJustifyH("LEFT")
PreyHuntProgressHint:SetJustifyV("TOP")
PreyHuntProgressHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
PreyHuntProgressHint:SetTextColor(0.80, 0.80, 0.80, 1)
PreyHuntProgressHint:SetText(L("PREY_HUNT_PROGRESS_HINT"))

-- ========================================
-- Bereich: Keystone Buttons
-- ========================================

local KeystoneActionsPanel = CreateFrame("Frame", nil, PageMiscContent)
KeystoneActionsPanel:SetPoint("TOPLEFT", PreyHuntProgressPanel, "BOTTOMLEFT", 0, -18)
KeystoneActionsPanel:SetPoint("TOPRIGHT", PreyHuntProgressPanel, "BOTTOMRIGHT", 0, -18)
KeystoneActionsPanel:SetHeight(250)

local KeystoneActionsBg = KeystoneActionsPanel:CreateTexture(nil, "BACKGROUND")
KeystoneActionsBg:SetAllPoints()
KeystoneActionsBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local KeystoneActionsBorder = KeystoneActionsPanel:CreateTexture(nil, "ARTWORK")
KeystoneActionsBorder:SetPoint("BOTTOMLEFT", KeystoneActionsPanel, "BOTTOMLEFT", 0, 0)
KeystoneActionsBorder:SetPoint("BOTTOMRIGHT", KeystoneActionsPanel, "BOTTOMRIGHT", 0, 0)
KeystoneActionsBorder:SetHeight(1)
KeystoneActionsBorder:SetColorTexture(1, 0.82, 0, 0.9)

local KeystoneActionsTitle = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsTitle:SetPoint("TOPLEFT", KeystoneActionsPanel, "TOPLEFT", 18, -14)
KeystoneActionsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
KeystoneActionsTitle:SetTextColor(1, 0.82, 0, 1)
KeystoneActionsTitle:SetText(L("KEYSTONE_ACTIONS"))

local KeystoneActionsCheckbox = CreateFrame("CheckButton", nil, KeystoneActionsPanel, "UICheckButtonTemplate")
KeystoneActionsCheckbox:SetPoint("TOPLEFT", KeystoneActionsTitle, "BOTTOMLEFT", -4, -12)

local KeystoneActionsLabel = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsLabel:SetPoint("LEFT", KeystoneActionsCheckbox, "RIGHT", 6, 0)
KeystoneActionsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
KeystoneActionsLabel:SetTextColor(1, 1, 1, 1)
KeystoneActionsLabel:SetText(L("ACTIVE"))

local KeystoneActionsHint = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsHint:SetPoint("TOPLEFT", KeystoneActionsCheckbox, "BOTTOMLEFT", 34, -2)
KeystoneActionsHint:SetPoint("RIGHT", KeystoneActionsPanel, "RIGHT", -18, 0)
KeystoneActionsHint:SetJustifyH("LEFT")
KeystoneActionsHint:SetJustifyV("TOP")
KeystoneActionsHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
KeystoneActionsHint:SetTextColor(0.80, 0.80, 0.80, 1)
KeystoneActionsHint:SetText(L("KEYSTONE_ACTIONS_HINT"))

local KeystoneActionsGroupLockCheckbox = CreateFrame("CheckButton", nil, KeystoneActionsPanel, "UICheckButtonTemplate")
KeystoneActionsGroupLockCheckbox:SetPoint("TOPLEFT", KeystoneActionsHint, "BOTTOMLEFT", -14, -14)
KeystoneActionsGroupLockCheckbox:SetScale(0.85)

local KeystoneActionsGroupLockLabel = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsGroupLockLabel:SetPoint("LEFT", KeystoneActionsGroupLockCheckbox, "RIGHT", 4, 0)
KeystoneActionsGroupLockLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
KeystoneActionsGroupLockLabel:SetTextColor(1, 1, 1, 1)
KeystoneActionsGroupLockLabel:SetText(L("KEYSTONE_ACTIONS_GROUP_LOCK"))

local KeystoneActionsGroupLockHint = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsGroupLockHint:SetPoint("TOPLEFT", KeystoneActionsGroupLockCheckbox, "BOTTOMLEFT", 30, -4)
KeystoneActionsGroupLockHint:SetPoint("RIGHT", KeystoneActionsPanel, "RIGHT", -18, 0)
KeystoneActionsGroupLockHint:SetJustifyH("LEFT")
KeystoneActionsGroupLockHint:SetJustifyV("TOP")
KeystoneActionsGroupLockHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
KeystoneActionsGroupLockHint:SetTextColor(0.80, 0.80, 0.80, 1)
KeystoneActionsGroupLockHint:SetText(L("KEYSTONE_ACTIONS_GROUP_LOCK_HINT"))

local KeystoneActionsSecondsLabel = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsSecondsLabel:SetPoint("TOPLEFT", KeystoneActionsGroupLockHint, "BOTTOMLEFT", 0, -14)
KeystoneActionsSecondsLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
KeystoneActionsSecondsLabel:SetTextColor(1, 1, 1, 1)
KeystoneActionsSecondsLabel:SetText(L("KEYSTONE_ACTIONS_SECONDS"))

local KeystoneActionsSecondsInput = CreateFrame("EditBox", nil, KeystoneActionsPanel, "InputBoxTemplate")
KeystoneActionsSecondsInput:SetSize(54, 24)
KeystoneActionsSecondsInput:SetPoint("LEFT", KeystoneActionsSecondsLabel, "RIGHT", 10, 0)
KeystoneActionsSecondsInput:SetAutoFocus(false)
KeystoneActionsSecondsInput:SetNumeric(true)
KeystoneActionsSecondsInput:SetMaxLetters(2)
KeystoneActionsSecondsInput:SetJustifyH("CENTER")

local KeystoneActionsSecondsHint = KeystoneActionsPanel:CreateFontString(nil, "OVERLAY")
KeystoneActionsSecondsHint:SetPoint("TOPLEFT", KeystoneActionsSecondsLabel, "BOTTOMLEFT", 0, -4)
KeystoneActionsSecondsHint:SetPoint("RIGHT", KeystoneActionsPanel, "RIGHT", -18, 0)
KeystoneActionsSecondsHint:SetJustifyH("LEFT")
KeystoneActionsSecondsHint:SetJustifyV("TOP")
KeystoneActionsSecondsHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
KeystoneActionsSecondsHint:SetTextColor(0.80, 0.80, 0.80, 1)
KeystoneActionsSecondsHint:SetText(L("KEYSTONE_ACTIONS_SECONDS_HINT"))

local SectionPanels = {
    AutoSell = AutoSellPanel,
    AutoRepair = AutoRepairPanel,
    EasyDelete = EasyDeletePanel,
    FastLoot = FastLootPanel,
    CutsceneSkip = CutsceneSkipPanel,
    FlightMasterTimer = FlightMasterTimerPanel,
    -- Der Schlüsselname muss zum Tree-Eintrag passen, damit die Sidebar diese
    -- Karte gezielt ansteuern und sichtbar machen kann.
    TooltipItemLevel = TooltipItemLevelPanel,
    CameraDistance = CameraDistancePanel,
    PreyHuntProgress = PreyHuntProgressPanel,
    KeystoneActions = KeystoneActionsPanel,
}

PageMisc.Widgets = {
    IntroTitle = IntroTitle,
    IntroText = IntroText,
    AutoSellTitle = AutoSellTitle,
    AutoSellLabel = AutoSellLabel,
    AutoSellHint = AutoSellHint,
    AutoSellCheckbox = AutoSellCheckbox,
    AutoRepairTitle = AutoRepairTitle,
    AutoRepairLabel = AutoRepairLabel,
    AutoRepairHint = AutoRepairHint,
    AutoRepairCheckbox = AutoRepairCheckbox,
    AutoRepairGuildLabel = AutoRepairGuildLabel,
    AutoRepairGuildHint = AutoRepairGuildHint,
    AutoRepairGuildCheckbox = AutoRepairGuildCheckbox,
    EasyDeleteTitle = EasyDeleteTitle,
    EasyDeleteLabel = EasyDeleteLabel,
    EasyDeleteHint = EasyDeleteHint,
    EasyDeleteCheckbox = EasyDeleteCheckbox,
    FastLootTitle = FastLootTitle,
    FastLootLabel = FastLootLabel,
    FastLootHint = FastLootHint,
    FastLootCheckbox = FastLootCheckbox,
    CutsceneSkipTitle = CutsceneSkipTitle,
    CutsceneSkipLabel = CutsceneSkipLabel,
    CutsceneSkipHint = CutsceneSkipHint,
    CutsceneSkipCheckbox = CutsceneSkipCheckbox,
    FlightMasterTimerTitle = FlightMasterTimerTitle,
    FlightMasterTimerLabel = FlightMasterTimerLabel,
    FlightMasterTimerHint = FlightMasterTimerHint,
    FlightMasterTimerCheckbox = FlightMasterTimerCheckbox,
    FlightMasterTimerSoundLabel = FlightMasterTimerSoundLabel,
    FlightMasterTimerSoundHint = FlightMasterTimerSoundHint,
    FlightMasterTimerSoundSelectLabel = FlightMasterTimerSoundSelectLabel,
    FlightMasterTimerSoundCheckbox = FlightMasterTimerSoundCheckbox,
    FlightMasterTimerSoundDropdown = FlightMasterTimerSoundDropdown,
    FlightMasterTimerSoundTestButton = FlightMasterTimerSoundTestButton,
    FlightMasterTimerLockCheckbox = FlightMasterTimerLockCheckbox,
    FlightMasterTimerLockLabel = FlightMasterTimerLockLabel,
    FlightMasterTimerLockHint = FlightMasterTimerLockHint,
    FlightMasterTimerPreviewButton = FlightMasterTimerPreviewButton,
    FlightMasterTimerPreviewHint = FlightMasterTimerPreviewHint,
    FlightMasterTimerResetButton = FlightMasterTimerResetButton,
    FlightMasterTimerResetHint = FlightMasterTimerResetHint,
    TooltipItemLevelTitle = TooltipItemLevelTitle,
    TooltipItemLevelLabel = TooltipItemLevelLabel,
    TooltipItemLevelHint = TooltipItemLevelHint,
    TooltipItemLevelCheckbox = TooltipItemLevelCheckbox,
    CameraDistanceTitle = CameraDistanceTitle,
    CameraDistanceHint = CameraDistanceHint,
    CameraDistanceStatusLabel = CameraDistanceStatusLabel,
    CameraDistanceStatusValue = CameraDistanceStatusValue,
    CameraDistanceMaxButton = CameraDistanceMaxButton,
    CameraDistanceStandardButton = CameraDistanceStandardButton,
    PreyHuntProgressTitle = PreyHuntProgressTitle,
    PreyHuntProgressLabel = PreyHuntProgressLabel,
    PreyHuntProgressHint = PreyHuntProgressHint,
    PreyHuntProgressCheckbox = PreyHuntProgressCheckbox,
    KeystoneActionsTitle = KeystoneActionsTitle,
    KeystoneActionsLabel = KeystoneActionsLabel,
    KeystoneActionsHint = KeystoneActionsHint,
    KeystoneActionsCheckbox = KeystoneActionsCheckbox,
    KeystoneActionsGroupLockCheckbox = KeystoneActionsGroupLockCheckbox,
    KeystoneActionsGroupLockLabel = KeystoneActionsGroupLockLabel,
    KeystoneActionsGroupLockHint = KeystoneActionsGroupLockHint,
    KeystoneActionsSecondsLabel = KeystoneActionsSecondsLabel,
    KeystoneActionsSecondsInput = KeystoneActionsSecondsInput,
    KeystoneActionsSecondsHint = KeystoneActionsSecondsHint,
}

local function RefreshFlightMasterTimerSoundDropdown()
    if not FlightMasterTimerSoundDropdown then
        return
    end

    local currentSoundKey = Misc.GetFlightMasterTimerArrivalSoundKey and Misc.GetFlightMasterTimerArrivalSoundKey() or nil
    local arrivalSoundOptions = Misc.GetFlightMasterTimerArrivalSoundOptions and Misc.GetFlightMasterTimerArrivalSoundOptions() or {}
    local selectedLabel = L("UNKNOWN")

    for _, soundOption in ipairs(arrivalSoundOptions) do
        if soundOption.key == currentSoundKey then
            selectedLabel = soundOption.label
            break
        end
    end

    UIDropDownMenu_SetSelectedValue(FlightMasterTimerSoundDropdown, currentSoundKey)
    UIDropDownMenu_SetText(FlightMasterTimerSoundDropdown, selectedLabel)
end

UIDropDownMenu_Initialize(FlightMasterTimerSoundDropdown, function(_, level)
    local currentSoundKey = Misc.GetFlightMasterTimerArrivalSoundKey and Misc.GetFlightMasterTimerArrivalSoundKey() or nil
    local arrivalSoundOptions = Misc.GetFlightMasterTimerArrivalSoundOptions and Misc.GetFlightMasterTimerArrivalSoundOptions() or {}

    for _, soundOption in ipairs(arrivalSoundOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = soundOption.label
        info.value = soundOption.key
        info.func = function()
            if Misc.SetFlightMasterTimerArrivalSound then
                Misc.SetFlightMasterTimerArrivalSound(soundOption.key)
            end

            UIDropDownMenu_SetSelectedValue(FlightMasterTimerSoundDropdown, soundOption.key)
            PageMisc:RefreshState()
        end
        info.checked = currentSoundKey == soundOption.key
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- ========================================
-- UI-Status
-- ========================================

-- Die Checkboxen lesen ihren Zustand direkt aus den Modulen.
function PageMisc:RefreshState()
    local widgets = self.Widgets
    local autoSellEnabled = false
    local autoRepairEnabled = false
    local autoRepairGuildEnabled = false
    local easyDeleteEnabled = false
    local fastLootEnabled = false
    local cutsceneSkipEnabled = false
    local flightMasterTimerEnabled = false
    local flightMasterTimerSoundEnabled = false
    local flightMasterTimerLocked = true
    local flightMasterTimerPreviewVisible = false
    local tooltipItemLevelEnabled = false
    local preyHuntProgressEnabled = false
    local keystoneActionsEnabled = false
    local keystoneActionsGroupLockEnabled = true
    local keystoneActionsSeconds = 10
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

    if Misc.IsCutsceneSkipEnabled then
        cutsceneSkipEnabled = Misc.IsCutsceneSkipEnabled()
    end

    if Misc.IsFlightMasterTimerEnabled then
        flightMasterTimerEnabled = Misc.IsFlightMasterTimerEnabled()
    end

    if Misc.IsFlightMasterTimerArrivalSoundEnabled then
        flightMasterTimerSoundEnabled = Misc.IsFlightMasterTimerArrivalSoundEnabled()
    end

    if Misc.IsFlightMasterTimerLocked then
        flightMasterTimerLocked = Misc.IsFlightMasterTimerLocked()
    end

    if Misc.IsFlightMasterTimerPreviewVisible then
        flightMasterTimerPreviewVisible = Misc.IsFlightMasterTimerPreviewVisible()
    end

    -- Der Tooltip-Schalter wird direkt aus dem Modul gelesen, damit UI und
    -- SavedVariables immer denselben Wahrheitswert anzeigen.
    if Misc.IsTooltipItemLevelEnabled then
        tooltipItemLevelEnabled = Misc.IsTooltipItemLevelEnabled()
    end

    if Misc.IsPreyHuntProgressEnabled then
        preyHuntProgressEnabled = Misc.IsPreyHuntProgressEnabled()
    end

    if Misc.IsKeystoneActionsEnabled then
        keystoneActionsEnabled = Misc.IsKeystoneActionsEnabled()
    end

    if Misc.IsKeystoneGroupLockEnabled then
        keystoneActionsGroupLockEnabled = Misc.IsKeystoneGroupLockEnabled()
    end

    if Misc.GetKeystoneCountdownSeconds then
        keystoneActionsSeconds = Misc.GetKeystoneCountdownSeconds()
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

    widgets.IntroTitle:SetText(L("MISC_TITLE"))
    widgets.IntroText:SetText(L("MISC_DESC"))
    widgets.AutoSellTitle:SetText(L("AUTOSELL_JUNK"))
    widgets.AutoSellLabel:SetText(L("ACTIVE"))
    widgets.AutoSellHint:SetText(L("AUTOSELL_HINT"))
    widgets.AutoRepairTitle:SetText(L("AUTOREPAIR"))
    widgets.AutoRepairLabel:SetText(L("ACTIVE"))
    widgets.AutoRepairHint:SetText(L("AUTOREPAIR_HINT"))
    widgets.AutoRepairGuildLabel:SetText(L("AUTOREPAIR_GUILD"))
    widgets.AutoRepairGuildHint:SetText(L("AUTOREPAIR_GUILD_HINT"))
    widgets.EasyDeleteTitle:SetText(L("EASY_DELETE"))
    widgets.EasyDeleteLabel:SetText(L("ACTIVE"))
    widgets.EasyDeleteHint:SetText(L("EASY_DELETE_HINT"))
    widgets.FastLootTitle:SetText(L("FAST_LOOT"))
    widgets.FastLootLabel:SetText(L("ACTIVE"))
    widgets.FastLootHint:SetText(L("FAST_LOOT_HINT"))
    widgets.CutsceneSkipTitle:SetText(L("CUTSCENE_SKIP"))
    widgets.CutsceneSkipLabel:SetText(L("ACTIVE"))
    widgets.CutsceneSkipHint:SetText(L("CUTSCENE_SKIP_HINT"))
    widgets.FlightMasterTimerTitle:SetText(L("FLIGHT_MASTER_TIMER"))
    widgets.FlightMasterTimerLabel:SetText(L("ACTIVE"))
    widgets.FlightMasterTimerHint:SetText(L("FLIGHT_MASTER_TIMER_HINT"))
    widgets.FlightMasterTimerSoundLabel:SetText(L("FLIGHT_MASTER_TIMER_SOUND"))
    widgets.FlightMasterTimerSoundHint:SetText(L("FLIGHT_MASTER_TIMER_SOUND_HINT"))
    widgets.FlightMasterTimerSoundSelectLabel:SetText(L("FLIGHT_MASTER_TIMER_SOUND_SELECT"))
    RefreshFlightMasterTimerSoundDropdown()
    widgets.FlightMasterTimerLockLabel:SetText(L("FLIGHT_MASTER_TIMER_LOCK_OVERLAY"))
    widgets.FlightMasterTimerLockHint:SetText(L("FLIGHT_MASTER_TIMER_LOCK_OVERLAY_HINT"))
    if flightMasterTimerPreviewVisible then
        widgets.FlightMasterTimerPreviewButton:SetText(L("FLIGHT_MASTER_TIMER_POSITION_MODE_STOP"))
    else
        widgets.FlightMasterTimerPreviewButton:SetText(L("FLIGHT_MASTER_TIMER_POSITION_MODE"))
    end
    widgets.FlightMasterTimerPreviewHint:SetText(L("FLIGHT_MASTER_TIMER_POSITION_MODE_HINT"))
    widgets.FlightMasterTimerResetButton:SetText(L("RESET_POSITION"))
    widgets.FlightMasterTimerResetHint:SetText(L("FLIGHT_MASTER_TIMER_RESET_HINT"))
    widgets.TooltipItemLevelTitle:SetText(L("TOOLTIP_ITEMLEVEL"))
    widgets.TooltipItemLevelLabel:SetText(L("ACTIVE"))
    widgets.TooltipItemLevelHint:SetText(L("TOOLTIP_ITEMLEVEL_HINT"))
    widgets.CameraDistanceTitle:SetText(L("CAMERA_DISTANCE"))
    widgets.CameraDistanceHint:SetText(L("CAMERA_DISTANCE_HINT"))
    widgets.CameraDistanceStatusLabel:SetText(L("CURRENT_SETTING"))
    widgets.CameraDistanceMaxButton:SetText(L("CAMERA_DISTANCE_MAX"))
    widgets.CameraDistanceStandardButton:SetText(L("STANDARD"))
    widgets.PreyHuntProgressTitle:SetText(L("PREY_HUNT_PROGRESS"))
    widgets.PreyHuntProgressLabel:SetText(L("ACTIVE"))
    widgets.PreyHuntProgressHint:SetText(L("PREY_HUNT_PROGRESS_HINT"))
    widgets.KeystoneActionsTitle:SetText(L("KEYSTONE_ACTIONS"))
    widgets.KeystoneActionsLabel:SetText(L("ACTIVE"))
    widgets.KeystoneActionsHint:SetText(L("KEYSTONE_ACTIONS_HINT"))
    widgets.KeystoneActionsGroupLockLabel:SetText(L("KEYSTONE_ACTIONS_GROUP_LOCK"))
    widgets.KeystoneActionsGroupLockHint:SetText(L("KEYSTONE_ACTIONS_GROUP_LOCK_HINT"))
    widgets.KeystoneActionsSecondsLabel:SetText(L("KEYSTONE_ACTIONS_SECONDS"))
    widgets.KeystoneActionsSecondsHint:SetText(L("KEYSTONE_ACTIONS_SECONDS_HINT"))
    if not widgets.KeystoneActionsSecondsInput:HasFocus() then
        widgets.KeystoneActionsSecondsInput:SetText(tostring(keystoneActionsSeconds))
    end

    widgets.AutoSellCheckbox:SetChecked(autoSellEnabled)
    widgets.AutoRepairCheckbox:SetChecked(autoRepairEnabled)
    widgets.AutoRepairGuildCheckbox:SetChecked(autoRepairGuildEnabled)
    widgets.EasyDeleteCheckbox:SetChecked(easyDeleteEnabled)
    widgets.FastLootCheckbox:SetChecked(fastLootEnabled)
    widgets.CutsceneSkipCheckbox:SetChecked(cutsceneSkipEnabled)
    widgets.FlightMasterTimerCheckbox:SetChecked(flightMasterTimerEnabled)
    widgets.FlightMasterTimerSoundCheckbox:SetChecked(flightMasterTimerSoundEnabled)
    widgets.FlightMasterTimerLockCheckbox:SetChecked(flightMasterTimerLocked)
    widgets.TooltipItemLevelCheckbox:SetChecked(tooltipItemLevelEnabled)
    widgets.PreyHuntProgressCheckbox:SetChecked(preyHuntProgressEnabled)
    widgets.KeystoneActionsCheckbox:SetChecked(keystoneActionsEnabled)
    widgets.KeystoneActionsGroupLockCheckbox:SetChecked(keystoneActionsGroupLockEnabled)
    -- Die Kamera-Karte zeigt bewusst den echten Status aus dem Modul an,
    -- nicht bloß den letzten Button-Klick.
    widgets.CameraDistanceStatusValue:SetText(cameraDistanceStatusText)
    -- Der bereits aktive Preset-Button wird deaktiviert.
    -- Das macht die Karte lesbarer und verhindert unnötige Wiederhol-Klicks.
    widgets.CameraDistanceMaxButton:SetEnabled(cameraDistanceMode ~= "max")
    widgets.CameraDistanceStandardButton:SetEnabled(cameraDistanceMode ~= "standard")

    -- Die Gilden-Option ergibt nur Sinn, wenn Auto Repair aktiv ist.
    widgets.AutoRepairGuildCheckbox:SetEnabled(autoRepairEnabled)
    widgets.FlightMasterTimerSoundCheckbox:SetEnabled(flightMasterTimerEnabled)
    widgets.FlightMasterTimerSoundTestButton:SetEnabled(flightMasterTimerEnabled and flightMasterTimerSoundEnabled)
    widgets.FlightMasterTimerLockCheckbox:SetEnabled(flightMasterTimerEnabled)
    widgets.FlightMasterTimerPreviewButton:SetEnabled(flightMasterTimerEnabled)
    widgets.FlightMasterTimerResetButton:SetEnabled(flightMasterTimerEnabled)
    widgets.KeystoneActionsGroupLockCheckbox:SetEnabled(keystoneActionsEnabled)
    if keystoneActionsEnabled then
        widgets.KeystoneActionsSecondsInput:Enable()
    else
        widgets.KeystoneActionsSecondsInput:Disable()
    end

    if flightMasterTimerEnabled and flightMasterTimerSoundEnabled then
        UIDropDownMenu_EnableDropDown(widgets.FlightMasterTimerSoundDropdown)
    else
        UIDropDownMenu_DisableDropDown(widgets.FlightMasterTimerSoundDropdown)
    end

    if autoRepairEnabled then
        widgets.AutoRepairGuildLabel:SetTextColor(1, 1, 1, 1)
        widgets.AutoRepairGuildHint:SetTextColor(0.80, 0.80, 0.80, 1)
    else
        widgets.AutoRepairGuildLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.AutoRepairGuildHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.AutoRepairGuildCheckbox:SetChecked(false)
    end

    if flightMasterTimerEnabled then
        widgets.FlightMasterTimerSoundLabel:SetTextColor(1, 1, 1, 1)
        widgets.FlightMasterTimerSoundSelectLabel:SetTextColor(1, 1, 1, 1)

        if flightMasterTimerSoundEnabled then
            widgets.FlightMasterTimerSoundHint:SetTextColor(0.80, 0.80, 0.80, 1)
        else
            widgets.FlightMasterTimerSoundHint:SetTextColor(0.55, 0.55, 0.55, 1)
        end

        widgets.FlightMasterTimerLockLabel:SetTextColor(1, 1, 1, 1)
        widgets.FlightMasterTimerResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
        widgets.FlightMasterTimerLockHint:SetTextColor(0.80, 0.80, 0.80, 1)
        widgets.FlightMasterTimerPreviewHint:SetTextColor(0.72, 0.72, 0.72, 1)
    else
        widgets.FlightMasterTimerSoundLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.FlightMasterTimerSoundHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.FlightMasterTimerSoundSelectLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.FlightMasterTimerSoundCheckbox:SetChecked(false)
        widgets.FlightMasterTimerLockLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.FlightMasterTimerLockHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.FlightMasterTimerPreviewHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.FlightMasterTimerResetHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.FlightMasterTimerLockCheckbox:SetChecked(true)
    end

    if keystoneActionsEnabled then
        widgets.KeystoneActionsGroupLockLabel:SetTextColor(1, 1, 1, 1)
        widgets.KeystoneActionsGroupLockHint:SetTextColor(0.80, 0.80, 0.80, 1)
        widgets.KeystoneActionsSecondsLabel:SetTextColor(1, 1, 1, 1)
        widgets.KeystoneActionsSecondsHint:SetTextColor(0.80, 0.80, 0.80, 1)
        widgets.KeystoneActionsSecondsInput:SetTextColor(1, 1, 1, 1)
    else
        widgets.KeystoneActionsGroupLockLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.KeystoneActionsGroupLockHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.KeystoneActionsSecondsLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        widgets.KeystoneActionsSecondsHint:SetTextColor(0.45, 0.45, 0.45, 1)
        widgets.KeystoneActionsSecondsInput:SetTextColor(0.70, 0.70, 0.70, 1)
    end

    if UpdateFlightMasterTimerPanelLayout() and self.UpdateScrollLayout then
        self:UpdateScrollLayout()
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
        + 18 + CutsceneSkipPanel:GetHeight()
        + 18 + FlightMasterTimerPanel:GetHeight()
        + 18 + TooltipItemLevelPanel:GetHeight()
        -- Die neue Kamera-Karte gehört fest in die Gesamthöhe,
        -- damit der Scrollbereich unten nicht zu früh endet.
        + 18 + CameraDistancePanel:GetHeight()
        + 18 + PreyHuntProgressPanel:GetHeight()
        + 18 + KeystoneActionsPanel:GetHeight()
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

    if UpdateFlightMasterTimerPanelLayout() then
        PageMisc:UpdateScrollLayout()
    end
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

CutsceneSkipCheckbox:SetScript("OnClick", function(self)
    if Misc.SetCutsceneSkipEnabled then
        Misc.SetCutsceneSkipEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FlightMasterTimerCheckbox:SetScript("OnClick", function(self)
    if Misc.SetFlightMasterTimerEnabled then
        Misc.SetFlightMasterTimerEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FlightMasterTimerSoundCheckbox:SetScript("OnClick", function(self)
    if Misc.SetFlightMasterTimerArrivalSoundEnabled then
        Misc.SetFlightMasterTimerArrivalSoundEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FlightMasterTimerSoundTestButton:SetScript("OnClick", function()
    if Misc.TestFlightMasterTimerArrivalSound then
        Misc.TestFlightMasterTimerArrivalSound()
    end
end)

FlightMasterTimerSoundTestButton:SetScript("OnEnter", function(self)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L("FLIGHT_MASTER_TIMER_SOUND_PLAY_HINT"), 1, 1, 1)
    GameTooltip:Show()
end)

FlightMasterTimerSoundTestButton:SetScript("OnLeave", function()
    if GameTooltip then
        GameTooltip:Hide()
    end
end)

FlightMasterTimerLockCheckbox:SetScript("OnClick", function(self)
    if Misc.SetFlightMasterTimerLocked then
        Misc.SetFlightMasterTimerLocked(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FlightMasterTimerPreviewButton:SetScript("OnClick", function()
    if Misc.ToggleFlightMasterTimerPreview then
        Misc.ToggleFlightMasterTimerPreview()
    end

    PageMisc:RefreshState()
end)

FlightMasterTimerResetButton:SetScript("OnClick", function()
    if Misc.ResetFlightMasterTimerPosition then
        Misc.ResetFlightMasterTimerPosition()
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

PreyHuntProgressCheckbox:SetScript("OnClick", function(self)
    if Misc.SetPreyHuntProgressEnabled then
        Misc.SetPreyHuntProgressEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

KeystoneActionsCheckbox:SetScript("OnClick", function(self)
    if Misc.SetKeystoneActionsEnabled then
        Misc.SetKeystoneActionsEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

KeystoneActionsGroupLockCheckbox:SetScript("OnClick", function(self)
    if Misc.SetKeystoneGroupLockEnabled then
        Misc.SetKeystoneGroupLockEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

local function ApplyKeystoneActionsSecondsInput()
    local rawValue = KeystoneActionsSecondsInput:GetText()
    if Misc.SetKeystoneCountdownSeconds then
        Misc.SetKeystoneCountdownSeconds(rawValue)
    end

    PageMisc:RefreshState()
end

KeystoneActionsSecondsInput:SetScript("OnEnterPressed", function(self)
    ApplyKeystoneActionsSecondsInput()
    self:ClearFocus()
end)

KeystoneActionsSecondsInput:SetScript("OnEditFocusLost", function()
    ApplyKeystoneActionsSecondsInput()
end)

KeystoneActionsSecondsInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
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

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not PageMisc:IsShown() then
                return
            end

            if UpdateFlightMasterTimerPanelLayout() then
                PageMisc:UpdateScrollLayout()
                PageMiscScrollFrame:SetVerticalScroll(0)
            end
        end)
    end
end)

PageMisc:UpdateScrollLayout()
PageMisc:RefreshState()

BeavisQoL.Pages.Misc = PageMisc
