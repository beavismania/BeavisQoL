local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.StatsModule = BeavisQoL.StatsModule or {}
local StatsModule = BeavisQoL.StatsModule

--[[
Stats.lua besteht aus zwei zusammenhaengenden Teilen:

1. Einstellungs- und Overlay-Logik
   - SavedVariables lesen und normalisieren
   - Position, Skalierung und Transparenz verwalten
   - Live-Werte sammeln und ins Overlay schreiben

2. Modulseite im Hauptfenster
   - Vorschau
   - Checkboxen und Slider
   - Reset- und Lock-Optionen

Beim Lesen lohnt sich deshalb diese Reihenfolge:
Konstanten -> Settings -> Layout-Helfer -> Overlay-Refresh -> UI-Aufbau.
]]

local LEGACY_DEFAULT_FONT_SIZE = 16
local DEFAULT_FONT_SIZE = 8
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 16
local DEFAULT_OVERLAY_SCALE = 1.00
local MIN_OVERLAY_SCALE = 0.70
local MAX_OVERLAY_SCALE = 1.60
local DEFAULT_BACKGROUND_ALPHA = 0.28
local MIN_BACKGROUND_ALPHA = 0.10
local MAX_BACKGROUND_ALPHA = 0.60
local DEFAULT_POINT = "BOTTOMRIGHT"
local DEFAULT_RELATIVE_POINT = "BOTTOMRIGHT"
local DEFAULT_OFFSET_X = -84
local DEFAULT_OFFSET_Y = 230
local BASE_OVERLAY_WIDTH = 186
local REFRESH_INTERVAL = 0.25

local sliderCounter = 0
local isRefreshing = false

local PageStats
local PreviewCard
local PreviewTopLine
local PreviewAccent
local OverlayFrame
local OverlayTopLine
local OverlayAccent

local OverlayRows = {}
local PreviewRows = {}

local ShowOverlayCheckbox
local LockOverlayCheckbox
local FontSizeSlider
local ScaleSlider
local BackgroundAlphaSlider

local STAT_DEFINITIONS = {
    { key = "crit", label = "Crit", color = { 1.00, 0.18, 0.18 } },
    { key = "haste", label = "Haste", color = { 0.23, 0.56, 1.00 } },
    { key = "mastery", label = "Mastery", color = { 0.08, 0.92, 0.25 } },
    { key = "vers", label = "Vers", color = { 1.00, 0.92, 0.10 } },
    { key = "leech", label = "Leech", color = { 0.90, 0.32, 0.92 } },
    { key = "avoidance", label = "Avoidance", color = { 0.20, 0.92, 0.92 } },
    { key = "speed", label = "Speed", color = { 1.00, 0.58, 0.10 } },
}

local function Clamp(value, minValue, maxValue)
    -- Kleine Standard-Helferfunktion:
    -- verhindert, dass Slider oder DB-Werte außerhalb des erlaubten Bereichs landen.
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function FormatPercent(value)
    return string.format("%.2f%%", tonumber(value) or 0)
end

local function GetVersatilityPercent()
    if GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
        return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
    end

    if GetVersatilityBonus then
        local value = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE or 0)
        if type(value) == "number" then
            return value
        end
    end

    return 0
end

local function GetCurrentStats()
    return {
        crit = GetCritChance and GetCritChance() or 0,
        haste = GetHaste and GetHaste() or 0,
        mastery = GetMasteryEffect and GetMasteryEffect() or 0,
        vers = GetVersatilityPercent(),
        leech = GetLifesteal and GetLifesteal() or 0,
        avoidance = GetAvoidance and GetAvoidance() or 0,
        speed = GetSpeed and GetSpeed() or 0,
    }
end

local function GetStatsSettings()
    -- Diese Funktion macht die SavedVariables bewusst "stabil":
    -- fehlende Werte werden gesetzt, alte Defaults migriert und Zahlen direkt
    -- auf sinnvolle Grenzen begrenzt.
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.stats = BeavisQoLDB.stats or {}

    local db = BeavisQoLDB.stats

    if db.overlayEnabled == nil then
        db.overlayEnabled = false
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if type(db.fontSize) ~= "number" then
        db.fontSize = DEFAULT_FONT_SIZE
    elseif db.overlayScale == nil and math.floor(db.fontSize + 0.5) == LEGACY_DEFAULT_FONT_SIZE then
        db.fontSize = DEFAULT_FONT_SIZE
    end
    db.fontSize = Clamp(math.floor(db.fontSize + 0.5), MIN_FONT_SIZE, MAX_FONT_SIZE)

    if type(db.overlayScale) ~= "number" then
        db.overlayScale = DEFAULT_OVERLAY_SCALE
    end
    db.overlayScale = Clamp(db.overlayScale, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)

    if type(db.backgroundAlpha) ~= "number" then
        db.backgroundAlpha = DEFAULT_BACKGROUND_ALPHA
    end
    db.backgroundAlpha = Clamp(db.backgroundAlpha, MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA)

    if type(db.point) ~= "string" or db.point == "" then
        db.point = DEFAULT_POINT
    end

    if type(db.relativePoint) ~= "string" or db.relativePoint == "" then
        db.relativePoint = DEFAULT_RELATIVE_POINT
    end

    if type(db.offsetX) ~= "number" then
        db.offsetX = DEFAULT_OFFSET_X
    end

    if type(db.offsetY) ~= "number" then
        db.offsetY = DEFAULT_OFFSET_Y
    end

    return db
end

function StatsModule.IsOverlayEnabled()
    return GetStatsSettings().overlayEnabled == true
end

function StatsModule.SetOverlayEnabled(enabled)
    GetStatsSettings().overlayEnabled = enabled == true
    StatsModule.RefreshOverlayWindow()
end

function StatsModule.IsOverlayLocked()
    return GetStatsSettings().overlayLocked == true
end

function StatsModule.SetOverlayLocked(locked)
    GetStatsSettings().overlayLocked = locked == true
    StatsModule.RefreshOverlayWindow()
end

function StatsModule.GetFontSize()
    return GetStatsSettings().fontSize
end

function StatsModule.SetFontSize(fontSize)
    GetStatsSettings().fontSize = Clamp(math.floor((fontSize or DEFAULT_FONT_SIZE) + 0.5), MIN_FONT_SIZE, MAX_FONT_SIZE)
    StatsModule.RefreshOverlayWindow()
end

function StatsModule.GetOverlayScale()
    return GetStatsSettings().overlayScale
end

function StatsModule.SetOverlayScale(scale)
    GetStatsSettings().overlayScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    StatsModule.RefreshOverlayWindow()
end

function StatsModule.GetBackgroundAlpha()
    return GetStatsSettings().backgroundAlpha
end

function StatsModule.SetBackgroundAlpha(alpha)
    GetStatsSettings().backgroundAlpha = Clamp(alpha or DEFAULT_BACKGROUND_ALPHA, MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA)
    StatsModule.RefreshOverlayWindow()
end

local function SaveOverlayGeometry()
    -- Gespeichert wird nur die obere linke Anker-Information des Overlay-Frames.
    -- Damit laesst sich die Position spaeter exakt wiederherstellen.
    if not OverlayFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayFrame:GetPoint(1)
    local settings = GetStatsSettings()

    settings.point = point or DEFAULT_POINT
    settings.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    settings.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    settings.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function ApplyOverlayGeometry()
    -- Die gespeicherte Geometrie wird nur hier zentral angewendet.
    -- Dadurch haben Reset, Login und manuelles Verschieben denselben Pfad.
    if not OverlayFrame then
        return
    end

    local settings = GetStatsSettings()
    OverlayFrame:ClearAllPoints()
    OverlayFrame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.offsetX, settings.offsetY)
end

function StatsModule.ResetOverlayPosition()
    local settings = GetStatsSettings()
    settings.point = DEFAULT_POINT
    settings.relativePoint = DEFAULT_RELATIVE_POINT
    settings.offsetX = DEFAULT_OFFSET_X
    settings.offsetY = DEFAULT_OFFSET_Y
    ApplyOverlayGeometry()
end

local function FormatSliderValue(value, mode)
    if mode == "alpha" or mode == "scale" then
        return string.format("%d%%", math.floor((value * 100) + 0.5))
    end

    return tostring(math.floor((value or 0) + 0.5))
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step, mode)
    -- WoW-Slider mit `OptionsSliderTemplate` brauchen einen echten Frame-Namen,
    -- weil Blizzard die eingebauten Textregionen über Globals zusammensetzt.
    sliderCounter = sliderCounter + 1

    local sliderName = "BeavisQoLStatsSlider" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetWidth(320)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.Text = _G[sliderName .. "Text"]
    slider.Low = _G[sliderName .. "Low"]
    slider.High = _G[sliderName .. "High"]

    slider.Text:SetText(labelText)
    slider.Text:SetTextColor(1, 0.82, 0, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(1, 1, 1, 1)

    slider:SetScript("OnValueChanged", function(self, value)
        self.ValueText:SetText(FormatSliderValue(value, mode))

        if isRefreshing or not self.ApplyValue then
            return
        end

        self:ApplyValue(value)
    end)

    return slider
end

local function CreateSectionCheckbox(parent, anchor, titleText, hintText)
    -- Viele Addon-Seiten nutzen denselben Aufbau:
    -- Checkbox links, Titel daneben, Hinweissatz darunter.
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(titleText)

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    hint:SetTextColor(0.80, 0.80, 0.80, 1)
    hint:SetText(hintText)

    return checkbox, label, hint
end

local function CreateStatRows(parent, targetTable)
    -- Die Zeilen werden einmal gebaut und spaeter nur noch neu befuellt.
    -- Das ist deutlich guenstiger, als bei jedem Refresh neue FontStrings anzulegen.
    for index, definition in ipairs(STAT_DEFINITIONS) do
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(22)

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetJustifyH("RIGHT")
        label:SetJustifyV("MIDDLE")
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)
        label:SetFont("Fonts\\FRIZQT__.TTF", DEFAULT_FONT_SIZE, "OUTLINE")
        label:SetText(definition.label .. ":")
        label:SetTextColor(definition.color[1], definition.color[2], definition.color[3], 1)
        row.Label = label

        local value = row:CreateFontString(nil, "OVERLAY")
        value:SetJustifyH("LEFT")
        value:SetJustifyV("MIDDLE")
        value:SetShadowColor(0, 0, 0, 1)
        value:SetShadowOffset(1, -1)
        value:SetFont("Fonts\\FRIZQT__.TTF", DEFAULT_FONT_SIZE, "OUTLINE")
        value:SetTextColor(1, 1, 1, 1)
        row.Value = value

        targetTable[index] = row
    end
end

local function GetLayoutMetrics(fontSize, scale)
    -- Hier entsteht das komplette "Design in Zahlen":
    -- Breite, Innenabstaende, Label-/Value-Aufteilung und Zeilenhoehe.
    local effectiveScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    local width = math.floor((BASE_OVERLAY_WIDTH * effectiveScale) + 0.5)
    local horizontalPadding = math.max(8, math.floor((10 * effectiveScale) + 0.5))
    local gap = math.max(5, math.floor((6 * effectiveScale) + 0.5))
    local contentWidth = width - (horizontalPadding * 2)
    local labelWidth = math.max(48, math.floor(contentWidth * 0.43))
    local valueWidth = math.max(56, contentWidth - labelWidth - gap)
    local topPadding = math.max(10, math.floor(((fontSize + 4) * effectiveScale) + 0.5))
    local bottomPadding = math.max(8, math.floor((8 * effectiveScale) + 0.5))
    local lineHeight = math.max(fontSize + 1, math.floor(((fontSize + 3) * effectiveScale) + 0.5))
    local rowSpacing = math.max(1, math.floor((2 * effectiveScale) + 0.5))

    return {
        width = width,
        horizontalPadding = horizontalPadding,
        gap = gap,
        labelWidth = labelWidth,
        valueWidth = valueWidth,
        topPadding = topPadding,
        bottomPadding = bottomPadding,
        lineHeight = lineHeight,
        rowSpacing = rowSpacing,
    }
end

local function LayoutStatRows(parent, rows, fontSize, scale)
    -- Diese Funktion berechnet nur die Geometrie.
    -- Sie schreibt bewusst noch keine Werte, sondern positioniert erst einmal
    -- alle Zeilen passend zur gewählten Schriftgröße und Skalierung.
    local metrics = GetLayoutMetrics(fontSize, scale)
    local currentY = -metrics.topPadding

    for _, row in ipairs(rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", metrics.horizontalPadding, currentY)
        row:SetSize(metrics.width - (metrics.horizontalPadding * 2), metrics.lineHeight)

        row.Label:ClearAllPoints()
        row.Label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.Label:SetWidth(metrics.labelWidth)
        row.Label:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")

        row.Value:ClearAllPoints()
        row.Value:SetPoint("LEFT", row.Label, "RIGHT", metrics.gap, 0)
        row.Value:SetWidth(metrics.valueWidth)
        row.Value:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")

        row:Show()
        currentY = currentY - metrics.lineHeight - metrics.rowSpacing
    end

    return metrics.width, (metrics.topPadding + metrics.bottomPadding) + (#rows * metrics.lineHeight) + ((#rows - 1) * metrics.rowSpacing)
end

local function RefreshStatRows(rows)
    -- Die Textwerte werden getrennt vom Layout aktualisiert.
    -- So kann der Ticker spaeter nur die Zahlen erneuern, ohne das ganze
    -- Overlay jedes Mal neu anzukern.
    local values = GetCurrentStats()

    for index, definition in ipairs(STAT_DEFINITIONS) do
        local row = rows[index]
        if row then
            row.Value:SetText(FormatPercent(values[definition.key]))
        end
    end
end

local function ApplyCardStyle(frame, alpha)
    -- Vorschaukarte und echtes Overlay teilen sich absichtlich denselben Stil.
    -- Das haelt beide Ansichten optisch synchron.
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.05, alpha)
    frame:SetBackdropBorderColor(1, 0.82, 0, 0.14 + (alpha * 0.65))
end

local function RefreshPreviewCard()
    -- Die Vorschau ist keine "Fake-Demo", sondern nutzt dieselben
    -- Layout-Helfer und dieselben Live-Werte wie das echte Overlay.
    if not PreviewCard then
        return
    end

    local backgroundAlpha = StatsModule.GetBackgroundAlpha()
    local fontSize = StatsModule.GetFontSize()
    local scale = StatsModule.GetOverlayScale()
    local width, height = LayoutStatRows(PreviewCard, PreviewRows, fontSize, scale)
    PreviewCard:SetSize(width, height)
    PreviewCard:SetBackdropColor(0.04, 0.04, 0.05, backgroundAlpha)
    PreviewCard:SetBackdropBorderColor(1, 0.82, 0, 0.10 + (backgroundAlpha * 0.50))

    if PreviewTopLine then
        PreviewTopLine:SetColorTexture(1, 0.82, 0, 0.70)
    end

    if PreviewAccent then
        PreviewAccent:SetColorTexture(1, 0.82, 0, 0.14 + (backgroundAlpha * 0.30))
    end

    RefreshStatRows(PreviewRows)
end

local function ShouldHideStatsOverlay()
    return BeavisQoL.ShouldHideOverlay
        and BeavisQoL.ShouldHideOverlay("stats")
end

function StatsModule.RefreshOverlayWindow()
    -- Zentraler Refresh für alles, was das sichtbare Overlay betrifft:
    -- Layout, Farben, Mausverhalten und Show/Hide.
    if not OverlayFrame then
        return
    end

    local settings = GetStatsSettings()
    local overlayWidth, overlayHeight = LayoutStatRows(OverlayFrame, OverlayRows, settings.fontSize, settings.overlayScale)

    OverlayFrame:SetSize(overlayWidth, overlayHeight)
    OverlayFrame:SetBackdropColor(0.04, 0.04, 0.05, settings.backgroundAlpha)
    OverlayFrame:SetBackdropBorderColor(1, 0.82, 0, 0.10 + (settings.backgroundAlpha * 0.50))
    OverlayFrame:EnableMouse(not settings.overlayLocked)

    if OverlayTopLine then
        OverlayTopLine:SetColorTexture(1, 0.82, 0, 0.70)
    end

    if OverlayAccent then
        OverlayAccent:SetColorTexture(1, 0.82, 0, 0.14 + (settings.backgroundAlpha * 0.30))
    end

    RefreshStatRows(OverlayRows)

    if settings.overlayEnabled and not ShouldHideStatsOverlay() then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end
end

local RefreshTicker = CreateFrame("Frame")
RefreshTicker.elapsed = 0
RefreshTicker:SetScript("OnUpdate", function(self, elapsed)
    -- Der Ticker laeuft nur dann sinnvoll weiter, wenn wenigstens Vorschau oder
    -- Overlay gerade sichtbar sind. Sonst setzen wir ihn direkt wieder ruhig.
    local needsRefresh = (PageStats and PageStats:IsShown()) or (OverlayFrame and OverlayFrame:IsShown())
    if not needsRefresh then
        self.elapsed = 0
        return
    end

    self.elapsed = self.elapsed + elapsed
    if self.elapsed < REFRESH_INTERVAL then
        return
    end

    self.elapsed = 0

    if PageStats and PageStats:IsShown() then
        RefreshPreviewCard()
    end

    if OverlayFrame and OverlayFrame:IsShown() then
        RefreshStatRows(OverlayRows)
    end
end)

local function RefreshAllDisplays()
    -- Eine Sammelfunktion spart Dopplungen in Events, Slidern und Buttons.
    RefreshPreviewCard()
    StatsModule.RefreshOverlayWindow()
end

PageStats = CreateFrame("Frame", nil, Content)
PageStats:SetAllPoints()
PageStats:Hide()

local IntroPanel = CreateFrame("Frame", nil, PageStats)
IntroPanel:SetPoint("TOPLEFT", PageStats, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageStats, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(112)

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
IntroTitle:SetText(L("STATS_TITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("STATS_DESC"))

local PreviewPanel = CreateFrame("Frame", nil, PageStats)
PreviewPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
PreviewPanel:SetSize(320, 298)

local PreviewBg = PreviewPanel:CreateTexture(nil, "BACKGROUND")
PreviewBg:SetAllPoints()
PreviewBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local PreviewBorder = PreviewPanel:CreateTexture(nil, "ARTWORK")
PreviewBorder:SetPoint("BOTTOMLEFT", PreviewPanel, "BOTTOMLEFT", 0, 0)
PreviewBorder:SetPoint("BOTTOMRIGHT", PreviewPanel, "BOTTOMRIGHT", 0, 0)
PreviewBorder:SetHeight(1)
PreviewBorder:SetColorTexture(1, 0.82, 0, 0.9)

local PreviewTitle = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewTitle:SetPoint("TOPLEFT", PreviewPanel, "TOPLEFT", 18, -14)
PreviewTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
PreviewTitle:SetTextColor(1, 0.82, 0, 1)
PreviewTitle:SetText(L("LIVE_PREVIEW"))

local PreviewHint = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewHint:SetPoint("TOPLEFT", PreviewTitle, "BOTTOMLEFT", 0, -8)
PreviewHint:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewHint:SetJustifyH("LEFT")
PreviewHint:SetJustifyV("TOP")
PreviewHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
PreviewHint:SetTextColor(0.80, 0.80, 0.80, 1)
PreviewHint:SetText(L("STATS_PREVIEW_HINT"))

PreviewCard = CreateFrame("Frame", nil, PreviewPanel, BackdropTemplateMixin and "BackdropTemplate")
PreviewCard:SetPoint("TOPLEFT", PreviewHint, "BOTTOMLEFT", 0, -18)
ApplyCardStyle(PreviewCard, 0.28)

PreviewTopLine = PreviewCard:CreateTexture(nil, "ARTWORK")
PreviewTopLine:SetPoint("TOPLEFT", PreviewCard, "TOPLEFT", 10, -8)
PreviewTopLine:SetPoint("TOPRIGHT", PreviewCard, "TOPRIGHT", -10, -8)
PreviewTopLine:SetHeight(1)
PreviewTopLine:SetColorTexture(1, 0.82, 0, 0.70)

PreviewAccent = PreviewCard:CreateTexture(nil, "BACKGROUND")
PreviewAccent:SetPoint("TOPLEFT", PreviewCard, "TOPLEFT", 9, -10)
PreviewAccent:SetPoint("BOTTOMLEFT", PreviewCard, "BOTTOMLEFT", 9, 10)
PreviewAccent:SetWidth(2)
PreviewAccent:SetColorTexture(1, 0.82, 0, 0.18)

CreateStatRows(PreviewCard, PreviewRows)

local PreviewFooter = PreviewPanel:CreateFontString(nil, "OVERLAY")
PreviewFooter:SetPoint("TOPLEFT", PreviewCard, "BOTTOMLEFT", 0, -14)
PreviewFooter:SetPoint("RIGHT", PreviewPanel, "RIGHT", -18, 0)
PreviewFooter:SetJustifyH("LEFT")
PreviewFooter:SetJustifyV("TOP")
PreviewFooter:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
PreviewFooter:SetTextColor(0.72, 0.72, 0.72, 1)
PreviewFooter:SetText(L("STATS_PREVIEW_FOOTER"))

local SettingsPanel = CreateFrame("Frame", nil, PageStats)
SettingsPanel:SetPoint("TOPLEFT", PreviewPanel, "TOPRIGHT", 18, 0)
SettingsPanel:SetPoint("TOPRIGHT", PageStats, "TOPRIGHT", -20, -150)
-- Etwas mehr Hoehe, damit der Reset-Bereich sauber innerhalb des Panels bleibt
-- und unten sichtbar Luft zur Abschlusslinie hat.
SettingsPanel:SetHeight(430)

local SettingsBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsBg:SetAllPoints()
SettingsBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local SettingsBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsBorder:SetHeight(1)
SettingsBorder:SetColorTexture(1, 0.82, 0, 0.9)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.82, 0, 1)
SettingsTitle:SetText(L("DISPLAY_POSITION"))

local SettingsHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsHint:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", 0, -8)
SettingsHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsHint:SetJustifyH("LEFT")
SettingsHint:SetJustifyV("TOP")
SettingsHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SettingsHint:SetTextColor(0.80, 0.80, 0.80, 1)
SettingsHint:SetText(L("STATS_SETTINGS_HINT"))

local showOverlayLabel, showOverlayHint
ShowOverlayCheckbox, showOverlayLabel, showOverlayHint = CreateSectionCheckbox(
    SettingsPanel,
    SettingsHint,
    L("STATS_SHOW_OVERLAY"),
    L("STATS_SHOW_OVERLAY_HINT")
)

local lockOverlayLabel, lockOverlayHint
LockOverlayCheckbox, lockOverlayLabel, lockOverlayHint = CreateSectionCheckbox(
    SettingsPanel,
    showOverlayHint,
    L("STATS_LOCK_OVERLAY"),
    L("STATS_LOCK_OVERLAY_HINT")
)

FontSizeSlider = CreateValueSlider(SettingsPanel, L("STATS_FONT_SIZE"), MIN_FONT_SIZE, MAX_FONT_SIZE, 1, "font")
FontSizeSlider:SetPoint("TOPLEFT", lockOverlayHint, "BOTTOMLEFT", 18, -34)

ScaleSlider = CreateValueSlider(SettingsPanel, L("WINDOW_SCALE"), MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE, 0.05, "scale")
ScaleSlider:SetPoint("TOPLEFT", FontSizeSlider, "BOTTOMLEFT", 0, -44)

BackgroundAlphaSlider = CreateValueSlider(SettingsPanel, L("BACKGROUND_ALPHA"), MIN_BACKGROUND_ALPHA, MAX_BACKGROUND_ALPHA, 0.05, "alpha")
BackgroundAlphaSlider:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 0, -44)

local ResetPositionButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetPositionButton:SetSize(182, 26)
ResetPositionButton:SetPoint("TOPLEFT", BackgroundAlphaSlider, "BOTTOMLEFT", -18, -28)
ResetPositionButton:SetText(L("RESET_POSITION"))

local ResetHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
ResetHint:SetPoint("LEFT", ResetPositionButton, "RIGHT", 12, 0)
ResetHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
ResetHint:SetJustifyH("LEFT")
ResetHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
ResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
ResetHint:SetText(L("STATS_RESET_HINT"))

OverlayFrame = CreateFrame("Frame", "BeavisQoLStatsOverlayFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
OverlayFrame:SetClampedToScreen(true)
OverlayFrame:SetMovable(true)
OverlayFrame:SetToplevel(true)
OverlayFrame:SetFrameStrata("MEDIUM")
OverlayFrame:EnableMouse(true)
OverlayFrame:RegisterForDrag("LeftButton")
OverlayFrame:SetScript("OnDragStart", function(self)
    if StatsModule.IsOverlayLocked() then
        return
    end

    self:StartMoving()
end)
OverlayFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveOverlayGeometry()
end)
ApplyCardStyle(OverlayFrame, DEFAULT_BACKGROUND_ALPHA)
OverlayFrame:Hide()
ApplyOverlayGeometry()

OverlayTopLine = OverlayFrame:CreateTexture(nil, "ARTWORK")
OverlayTopLine:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 10, -8)
OverlayTopLine:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", -10, -8)
OverlayTopLine:SetHeight(1)
OverlayTopLine:SetColorTexture(1, 0.82, 0, 0.70)

OverlayAccent = OverlayFrame:CreateTexture(nil, "BACKGROUND")
OverlayAccent:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 9, -10)
OverlayAccent:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 9, 10)
OverlayAccent:SetWidth(2)
OverlayAccent:SetColorTexture(1, 0.82, 0, 0.18)

CreateStatRows(OverlayFrame, OverlayRows)

FontSizeSlider.ApplyValue = function(_, value)
    StatsModule.SetFontSize(value)
end

ScaleSlider.ApplyValue = function(_, value)
    StatsModule.SetOverlayScale(value)
end

BackgroundAlphaSlider.ApplyValue = function(_, value)
    StatsModule.SetBackgroundAlpha(value)
end

ShowOverlayCheckbox:SetScript("OnClick", function(self)
    StatsModule.SetOverlayEnabled(self:GetChecked())
    PageStats:RefreshState()
end)

LockOverlayCheckbox:SetScript("OnClick", function(self)
    StatsModule.SetOverlayLocked(self:GetChecked())
end)

ResetPositionButton:SetScript("OnClick", function()
    StatsModule.ResetOverlayPosition()
end)

function PageStats:RefreshState()
    -- Die Seite liest einmal komplett aus den SavedVariables und schreibt den
    -- Zustand gesammelt in Checkboxen, Slider und Vorschau.
    local settings = GetStatsSettings()

    IntroTitle:SetText(L("STATS_TITLE"))
    IntroText:SetText(L("STATS_DESC"))
    PreviewTitle:SetText(L("LIVE_PREVIEW"))
    PreviewHint:SetText(L("STATS_PREVIEW_HINT"))
    PreviewFooter:SetText(L("STATS_PREVIEW_FOOTER"))
    SettingsTitle:SetText(L("DISPLAY_POSITION"))
    SettingsHint:SetText(L("STATS_SETTINGS_HINT"))
    showOverlayLabel:SetText(L("STATS_SHOW_OVERLAY"))
    showOverlayHint:SetText(L("STATS_SHOW_OVERLAY_HINT"))
    lockOverlayLabel:SetText(L("STATS_LOCK_OVERLAY"))
    lockOverlayHint:SetText(L("STATS_LOCK_OVERLAY_HINT"))
    FontSizeSlider.Text:SetText(L("STATS_FONT_SIZE"))
    ScaleSlider.Text:SetText(L("WINDOW_SCALE"))
    BackgroundAlphaSlider.Text:SetText(L("BACKGROUND_ALPHA"))
    ResetPositionButton:SetText(L("RESET_POSITION"))
    ResetHint:SetText(L("STATS_RESET_HINT"))

    isRefreshing = true
    ShowOverlayCheckbox:SetChecked(settings.overlayEnabled)
    LockOverlayCheckbox:SetChecked(settings.overlayLocked)
    FontSizeSlider:SetValue(settings.fontSize)
    ScaleSlider:SetValue(settings.overlayScale)
    BackgroundAlphaSlider:SetValue(settings.backgroundAlpha)
    isRefreshing = false

    RefreshAllDisplays()
end

PageStats:SetScript("OnShow", function()
    PageStats:RefreshState()
end)

local StatsEvents = CreateFrame("Frame")
StatsEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
StatsEvents:RegisterEvent("PLAYER_LOGIN")
StatsEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
StatsEvents:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
StatsEvents:RegisterEvent("UPDATE_INSTANCE_INFO")
StatsEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
StatsEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
StatsEvents:SetScript("OnEvent", function()
    -- Beim Login oder Weltwechsel können sich Stats, Buffs und Positionen ändern.
    RefreshAllDisplays()
end)

PageStats:RefreshState()

BeavisQoL.Pages.Stats = PageStats
