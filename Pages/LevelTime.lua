local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

-- LevelTime.lua trennt bewusst:
-- 1. gespeicherte Zeit pro Level in der DB
-- 2. die gerade laufende Session im Speicher
-- 3. die reine UI-Darstellung

local MAX_LEVEL = 90
local UPDATE_INTERVAL = 0.2
-- MAX_LEVEL und UPDATE_INTERVAL sind die beiden zentralen Stellschrauben:
-- MAX_LEVEL bestimmt die Größe des Datenmodells
-- UPDATE_INTERVAL betrifft nur die UI-Aktualisierung, nicht das Speichern.

-- Die Seite trennt zwischen gespeicherten Daten und der gerade laufenden Session.
-- So können wir live anzeigen, ohne dauernd in die SavedVariables zu schreiben.
local PageLevelTime = CreateFrame("Frame", nil, Content)
PageLevelTime:SetAllPoints()
PageLevelTime:Hide()

local PageTitle = PageLevelTime:CreateFontString(nil, "OVERLAY")
PageTitle:SetPoint("TOPLEFT", PageLevelTime, "TOPLEFT", 22, -16)
PageTitle:SetPoint("RIGHT", PageLevelTime, "RIGHT", -22, 0)
PageTitle:SetJustifyH("LEFT")
PageTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
PageTitle:SetTextColor(1, 0.88, 0.62, 1)
PageTitle:SetText(BeavisQoL.GetModulePageTitle("LevelTime", L("LEVEL_TIME")))

-- Datenbank sauber anlegen
if not BeavisQoLCharDB then BeavisQoLCharDB = {} end
if not BeavisQoLCharDB.LevelTime then BeavisQoLCharDB.LevelTime = {} end
local LevelDB = BeavisQoLCharDB.LevelTime
local currentSessionLevel = nil
local currentSessionStartTime = nil

-- ========================================
-- Daten-Initialisierung
-- ========================================

-- Für jedes Level legen wir einen Eintrag an, damit später keine nil-Sonderfälle auftauchen.
local function InitializeLevelTimeData()
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.LevelTime = BeavisQoLCharDB.LevelTime or {}

    LevelDB = BeavisQoLCharDB.LevelTime

    for level = 1, MAX_LEVEL do
        if LevelDB[level] == nil then
            LevelDB[level] = 0
        end
    end
end

InitializeLevelTimeData()

-- ========================================
-- Hilfsfunktionen
-- ========================================

-- Zeiten im UI möglichst kompakt darstellen.
local function TimeToString(seconds)
    seconds = math.floor(seconds or 0)

    if seconds <= 0 then
        return "0s"
    end

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

local function GetCurrentCharLevel()
    return UnitLevel("player") or 1
end

local function IsAtMaxLevel()
    return GetCurrentCharLevel() >= MAX_LEVEL
end

-- Hier zählen wir nur die Zeit seit dem letzten Level-Up.
local function GetCurrentSessionElapsed()
    if not currentSessionStartTime or not currentSessionLevel then
        return 0
    end

    if currentSessionLevel >= MAX_LEVEL then
        return 0
    end

    return math.max(0, math.floor(GetTime() - currentSessionStartTime))
end

-- Startet die Messung für das aktuelle Level neu.
local function StartSessionForCurrentLevel()
    local currentLevel = GetCurrentCharLevel()

    if currentLevel >= MAX_LEVEL then
        currentSessionLevel = nil
        currentSessionStartTime = nil
        return
    end

    currentSessionLevel = currentLevel
    currentSessionStartTime = GetTime()
end

local function StopSessionTracking()
    currentSessionLevel = nil
    currentSessionStartTime = nil
end

-- Erst beim Speichern wandert die Session wirklich in die Datenbank.
-- So vermeiden wir unnötige Schreiberei während des Spielens.
local function SaveCurrentSessionToDatabase()
    if not currentSessionLevel or not currentSessionStartTime then
        return
    end

    if currentSessionLevel >= MAX_LEVEL then
        return
    end

    local elapsed = GetCurrentSessionElapsed()

    if elapsed > 0 then
        LevelDB[currentSessionLevel] = (LevelDB[currentSessionLevel] or 0) + elapsed
    end
end

-- Beim aktuellen Level rechnen wir die laufende Session auf den gespeicherten Wert drauf.
local function GetDisplayedLevelTime(level)
    local time = LevelDB[level] or 0

    if level == currentSessionLevel and currentSessionLevel < MAX_LEVEL then
        time = time + GetCurrentSessionElapsed()
    end

    return time
end

local function GetTotalLevelingTime()
    local total = 0

    for level = 1, MAX_LEVEL do
        total = total + GetDisplayedLevelTime(level)
    end

    return total
end

-- Der Balken zeigt nur den Fortschritt über die Levelnummern, nicht die aktuellen XP.
local function GetProgressPercent()
    local currentLevel = GetCurrentCharLevel()

    if currentLevel <= 1 then
        return 0
    end

    if currentLevel >= MAX_LEVEL then
        return 1
    end

    return (currentLevel - 1) / (MAX_LEVEL - 1)
end

-- ========================================
-- Übersichtsbereich
-- ========================================

local OverviewPanel = CreateFrame("Frame", nil, PageLevelTime)
OverviewPanel:SetPoint("TOPLEFT", PageLevelTime, "TOPLEFT", 20, -52)
OverviewPanel:SetPoint("TOPRIGHT", PageLevelTime, "TOPRIGHT", -20, -52)
OverviewPanel:SetHeight(138)

local OverviewBg = OverviewPanel:CreateTexture(nil, "BACKGROUND")
OverviewBg:SetAllPoints()
OverviewBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local OverviewBorder = OverviewPanel:CreateTexture(nil, "ARTWORK")
OverviewBorder:SetPoint("BOTTOMLEFT", OverviewPanel, "BOTTOMLEFT", 0, 0)
OverviewBorder:SetPoint("BOTTOMRIGHT", OverviewPanel, "BOTTOMRIGHT", 0, 0)
OverviewBorder:SetHeight(1)
OverviewBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

-- Der kleine Info-Button erklärt den Tracker, ohne die Seite mit Text vollzupacken.
local InfoButton = CreateFrame("Button", nil, OverviewPanel)
InfoButton:SetSize(24, 24)
InfoButton:SetPoint("TOPRIGHT", OverviewPanel, "TOPRIGHT", -8, -8)

local InfoCircle = InfoButton:CreateTexture(nil, "ARTWORK")
InfoCircle:SetAllPoints()
InfoCircle:SetColorTexture(0.15, 0.6, 1, 0.18)
InfoCircle:SetDrawLayer("ARTWORK", 1)
InfoButton.Circle = InfoCircle

local InfoText = InfoButton:CreateFontString(nil, "OVERLAY")
InfoText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
InfoText:SetTextColor(0.15, 0.6, 1, 1)
InfoText:SetPoint("CENTER", InfoButton, "CENTER", 0, -1)
InfoText:SetText("i")
InfoButton.Text = InfoText

InfoButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L("LEVELTIME_TOOLTIP_TITLE"), 1, 1, 1)
    GameTooltip:AddLine(L("LEVELTIME_TOOLTIP_TEXT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
    InfoCircle:SetColorTexture(0.15, 0.6, 1, 0.35)
end)

InfoButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    InfoCircle:SetColorTexture(0.15, 0.6, 1, 0.18)
end)

-- Karte 1: aktuelles Level
local CurrentLevelCard = CreateFrame("Frame", nil, OverviewPanel)
CurrentLevelCard:SetPoint("TOPLEFT", OverviewPanel, "TOPLEFT", 14, -14)
CurrentLevelCard:SetSize(180, 60)

local CurrentLevelCardBg = CurrentLevelCard:CreateTexture(nil, "BACKGROUND")
CurrentLevelCardBg:SetAllPoints()
CurrentLevelCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local CurrentLevelLabel = CurrentLevelCard:CreateFontString(nil, "OVERLAY")
CurrentLevelLabel:SetPoint("TOPLEFT", CurrentLevelCard, "TOPLEFT", 10, -8)
CurrentLevelLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CurrentLevelLabel:SetTextColor(0.85, 0.85, 0.85, 1)
CurrentLevelLabel:SetText(L("CURRENT_LEVEL"))

local CurrentLevelValue = CurrentLevelCard:CreateFontString(nil, "OVERLAY")
CurrentLevelValue:SetPoint("TOPLEFT", CurrentLevelLabel, "BOTTOMLEFT", 0, -6)
CurrentLevelValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentLevelValue:SetTextColor(1, 0.88, 0.62, 1)
CurrentLevelValue:SetText("1 / 90")

-- Karte 2: Zeit auf aktuellem Level / Status
local CurrentLevelTimeCard = CreateFrame("Frame", nil, OverviewPanel)
CurrentLevelTimeCard:SetPoint("LEFT", CurrentLevelCard, "RIGHT", 14, 0)
CurrentLevelTimeCard:SetSize(220, 60)

local CurrentLevelTimeCardBg = CurrentLevelTimeCard:CreateTexture(nil, "BACKGROUND")
CurrentLevelTimeCardBg:SetAllPoints()
CurrentLevelTimeCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local CurrentLevelTimeLabel = CurrentLevelTimeCard:CreateFontString(nil, "OVERLAY")
CurrentLevelTimeLabel:SetPoint("TOPLEFT", CurrentLevelTimeCard, "TOPLEFT", 10, -8)
CurrentLevelTimeLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CurrentLevelTimeLabel:SetTextColor(0.85, 0.85, 0.85, 1)
CurrentLevelTimeLabel:SetText(L("TIME_ON_CURRENT_LEVEL"))

local CurrentLevelTimeValue = CurrentLevelTimeCard:CreateFontString(nil, "OVERLAY")
CurrentLevelTimeValue:SetPoint("TOPLEFT", CurrentLevelTimeLabel, "BOTTOMLEFT", 0, -6)
CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentLevelTimeValue:SetTextColor(0.95, 0.91, 0.85, 1)
CurrentLevelTimeValue:SetText("0s")

-- Karte 3: Gesamtzeit
local TotalTimeCard = CreateFrame("Frame", nil, OverviewPanel)
TotalTimeCard:SetPoint("LEFT", CurrentLevelTimeCard, "RIGHT", 14, 0)
TotalTimeCard:SetPoint("RIGHT", OverviewPanel, "RIGHT", -40, 0)
TotalTimeCard:SetHeight(60)

local TotalTimeCardBg = TotalTimeCard:CreateTexture(nil, "BACKGROUND")
TotalTimeCardBg:SetAllPoints()
TotalTimeCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local TotalTimeLabel = TotalTimeCard:CreateFontString(nil, "OVERLAY")
TotalTimeLabel:SetPoint("TOPLEFT", TotalTimeCard, "TOPLEFT", 10, -8)
TotalTimeLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TotalTimeLabel:SetTextColor(0.85, 0.85, 0.85, 1)
TotalTimeLabel:SetText(L("TOTAL_TIME"))

local TotalTimeValue = TotalTimeCard:CreateFontString(nil, "OVERLAY")
TotalTimeValue:SetPoint("TOPLEFT", TotalTimeLabel, "BOTTOMLEFT", 0, -6)
TotalTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
TotalTimeValue:SetTextColor(0.95, 0.91, 0.85, 1)
TotalTimeValue:SetText("0s")

local LevelTimeMinimapContextCheckbox = CreateFrame("CheckButton", nil, OverviewPanel, "UICheckButtonTemplate")
LevelTimeMinimapContextCheckbox:SetPoint("TOPLEFT", CurrentLevelCard, "BOTTOMLEFT", -4, -12)
LevelTimeMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("levelTime") or true)
LevelTimeMinimapContextCheckbox:SetScript("OnClick", function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("levelTime", self:GetChecked())
    end
end)

local LevelTimeMinimapContextLabel = OverviewPanel:CreateFontString(nil, "OVERLAY")
LevelTimeMinimapContextLabel:SetPoint("LEFT", LevelTimeMinimapContextCheckbox, "RIGHT", 6, 0)
LevelTimeMinimapContextLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
LevelTimeMinimapContextLabel:SetTextColor(0.95, 0.91, 0.85, 1)
LevelTimeMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))

local LevelTimeMinimapContextHint = OverviewPanel:CreateFontString(nil, "OVERLAY")
LevelTimeMinimapContextHint:SetPoint("TOPLEFT", LevelTimeMinimapContextCheckbox, "BOTTOMLEFT", 34, -2)
LevelTimeMinimapContextHint:SetPoint("RIGHT", OverviewPanel, "RIGHT", -18, 0)
LevelTimeMinimapContextHint:SetJustifyH("LEFT")
LevelTimeMinimapContextHint:SetJustifyV("TOP")
LevelTimeMinimapContextHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
LevelTimeMinimapContextHint:SetTextColor(0.75, 0.75, 0.75, 1)
LevelTimeMinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))

-- ========================================
-- Fortschrittsbereich
-- ========================================

local ProgressPanel = CreateFrame("Frame", nil, PageLevelTime)
ProgressPanel:SetPoint("TOPLEFT", OverviewPanel, "BOTTOMLEFT", 0, -14)
ProgressPanel:SetPoint("TOPRIGHT", OverviewPanel, "BOTTOMRIGHT", 0, -14)
ProgressPanel:SetHeight(72)

local ProgressBg = ProgressPanel:CreateTexture(nil, "BACKGROUND")
ProgressBg:SetAllPoints()
ProgressBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local ProgressBorder = ProgressPanel:CreateTexture(nil, "ARTWORK")
ProgressBorder:SetPoint("BOTTOMLEFT", ProgressPanel, "BOTTOMLEFT", 0, 0)
ProgressBorder:SetPoint("BOTTOMRIGHT", ProgressPanel, "BOTTOMRIGHT", 0, 0)
ProgressBorder:SetHeight(1)
ProgressBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local ProgressBarBg = ProgressPanel:CreateTexture(nil, "BACKGROUND")
ProgressBarBg:SetPoint("TOPLEFT", ProgressPanel, "TOPLEFT", 18, -16)
ProgressBarBg:SetPoint("TOPRIGHT", ProgressPanel, "TOPRIGHT", -18, -16)
ProgressBarBg:SetHeight(24)
ProgressBarBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local ProgressBar = ProgressPanel:CreateTexture(nil, "ARTWORK")
ProgressBar:SetPoint("TOPLEFT", ProgressBarBg, "TOPLEFT", 0, 0)
ProgressBar:SetPoint("BOTTOMLEFT", ProgressBarBg, "BOTTOMLEFT", 0, 0)
ProgressBar:SetWidth(0)
ProgressBar:SetColorTexture(0.2, 0.8, 0.2, 0.85)

local ProgressPercentText = ProgressPanel:CreateFontString(nil, "OVERLAY")
ProgressPercentText:SetPoint("CENTER", ProgressBarBg, "CENTER", 0, 0)
ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
ProgressPercentText:SetTextColor(0.95, 0.91, 0.85, 1)
ProgressPercentText:SetText("0.0%")

-- ========================================
-- Level-Liste
-- ========================================

local LevelListContainer = CreateFrame("Frame", nil, PageLevelTime)
LevelListContainer:SetPoint("TOPLEFT", ProgressPanel, "BOTTOMLEFT", 0, -12)
LevelListContainer:SetPoint("BOTTOMRIGHT", PageLevelTime, "BOTTOMRIGHT", -20, 8)

local LevelListBg = LevelListContainer:CreateTexture(nil, "BACKGROUND")
LevelListBg:SetAllPoints()
LevelListBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local LevelListTitle = LevelListContainer:CreateFontString(nil, "OVERLAY")
LevelListTitle:SetPoint("TOPLEFT", LevelListContainer, "TOPLEFT", 10, -10)
LevelListTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
LevelListTitle:SetTextColor(1, 0.88, 0.62, 1)
LevelListTitle:SetText(L("TRACKED_LEVEL_TIMES"))

local LevelListScrollFrame = CreateFrame("ScrollFrame", nil, LevelListContainer, "UIPanelScrollFrameTemplate")
LevelListScrollFrame:SetPoint("TOPLEFT", LevelListContainer, "TOPLEFT", 8, -30)
LevelListScrollFrame:SetPoint("BOTTOMRIGHT", LevelListContainer, "BOTTOMRIGHT", -28, 8)

local LevelListContent = CreateFrame("Frame", nil, LevelListScrollFrame)
LevelListContent:SetSize(1, 1)
LevelListScrollFrame:SetScrollChild(LevelListContent)

local LevelRows = {}

-- Die Zeilen bauen wir einmal und zeigen sie später nur noch an oder aus.
for level = 1, MAX_LEVEL do
    local Row = CreateFrame("Frame", nil, LevelListContent)
    Row:SetHeight(24)

    local RowBg = Row:CreateTexture(nil, "BACKGROUND")
    RowBg:SetAllPoints()
    RowBg:SetColorTexture(0.09, 0.09, 0.09, 0.0)
    Row.Background = RowBg

    local LevelNumText = Row:CreateFontString(nil, "OVERLAY")
    LevelNumText:SetPoint("LEFT", Row, "LEFT", 10, 0)
    LevelNumText:SetWidth(90)
    LevelNumText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    LevelNumText:SetTextColor(1, 0.88, 0.62, 1)
    LevelNumText:SetJustifyH("LEFT")
    LevelNumText:SetText(L("LEVEL_LABEL"):format(level))
    Row.LevelNumText = LevelNumText

    local StatusText = Row:CreateFontString(nil, "OVERLAY")
    StatusText:SetPoint("LEFT", LevelNumText, "RIGHT", 10, 0)
    StatusText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    StatusText:SetTextColor(0.70, 0.70, 0.70, 1)
    StatusText:SetJustifyH("LEFT")
    StatusText:SetText("")
    Row.StatusText = StatusText

    local TimeText = Row:CreateFontString(nil, "OVERLAY")
    TimeText:SetPoint("RIGHT", Row, "RIGHT", -14, 0)
    TimeText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    TimeText:SetTextColor(0.85, 0.85, 0.85, 1)
    TimeText:SetJustifyH("RIGHT")
    TimeText:SetText("0s")
    Row.TimeText = TimeText

    Row.Level = level
    Row:Hide()

    LevelRows[level] = Row
end

-- ========================================
-- Refresh
-- ========================================

-- Hier bauen wir die komplette Anzeige neu auf.
local function RefreshLevelList()
    local currentLevel = GetCurrentCharLevel()
    local visibleLevels = {}
    -- Die Liste zeigt absichtlich nur Level mit bereits gemessener Zeit.
    -- Das bleibt für neue Charaktere deutlich lesbarer als 90 Null-Zeilen.

    -- Nur Level mit erfasster Zeit werden angezeigt. Das hält die Liste kompakt.
    for level = 1, MAX_LEVEL do
        local displayTime = GetDisplayedLevelTime(level)

        if displayTime > 0 then
            table.insert(visibleLevels, {
                level = level,
                time = displayTime,
            })
        end
    end

    for level = 1, MAX_LEVEL do
        local row = LevelRows[level]
        row:Hide()
        row:ClearAllPoints()
    end

    local contentWidth = math.max(1, LevelListScrollFrame:GetWidth())
    LevelListContent:SetWidth(contentWidth)

    for index, levelData in ipairs(visibleLevels) do
        local row = LevelRows[levelData.level]
        row:SetWidth(contentWidth)

        if index == 1 then
            row:SetPoint("TOPLEFT", LevelListContent, "TOPLEFT", 0, 0)
        else
            local previousRow = LevelRows[visibleLevels[index - 1].level]
            row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, 0)
        end

        row.TimeText:SetText(TimeToString(levelData.time))

        -- Das aktuelle Level bekommt eine eigene Markierung, damit man es sofort sieht.
        if levelData.level == currentLevel and currentLevel < MAX_LEVEL then
            row.Background:SetColorTexture(0.18, 0.30, 0.18, 0.75)
            row.LevelNumText:SetTextColor(1, 0.88, 0.62, 1)
            row.StatusText:SetText(L("LEVEL_RUNNING"))
            row.StatusText:SetTextColor(0.55, 1.00, 0.55, 1)
            row.TimeText:SetTextColor(0.95, 0.91, 0.85, 1)
        else
            if index % 2 == 0 then
                row.Background:SetColorTexture(0.09, 0.09, 0.09, 0.45)
            else
                row.Background:SetColorTexture(0.09, 0.09, 0.09, 0.15)
            end

            row.LevelNumText:SetTextColor(1, 0.88, 0.62, 1)
            row.StatusText:SetText("")
            row.TimeText:SetTextColor(0.85, 0.85, 0.85, 1)
        end

        row:Show()
    end

    LevelListContent:SetHeight(math.max(1, #visibleLevels * 24))

    local currentLevelTime = GetDisplayedLevelTime(currentLevel)
    local totalTime = GetTotalLevelingTime()

    CurrentLevelValue:SetText(currentLevel .. " / " .. MAX_LEVEL)
    TotalTimeValue:SetText(TimeToString(totalTime))

    if currentLevel >= MAX_LEVEL then
        CurrentLevelTimeLabel:SetText(L("STATUS"))
        CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        CurrentLevelTimeValue:SetTextColor(1, 0.88, 0.62, 1)
        CurrentLevelTimeValue:SetText(L("MAX_LEVEL_REACHED"))

        ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        ProgressPercentText:SetTextColor(1, 0.88, 0.62, 1)
        ProgressPercentText:SetText(L("MAX_LEVEL_CONGRATS"))
    else
        CurrentLevelTimeLabel:SetText(L("TIME_ON_CURRENT_LEVEL"))
        CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        CurrentLevelTimeValue:SetTextColor(0.95, 0.91, 0.85, 1)
        CurrentLevelTimeValue:SetText(TimeToString(currentLevelTime))

        ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        ProgressPercentText:SetTextColor(0.95, 0.91, 0.85, 1)
        ProgressPercentText:SetText(string.format("%.1f%%", GetProgressPercent() * 100))
    end

    local progressPercent = GetProgressPercent()
    local barWidth = ProgressBarBg:GetWidth() * progressPercent
    ProgressBar:SetWidth(math.max(0, barWidth))
end

BeavisQoL.UpdateLevelTime = function()
    PageTitle:SetText(BeavisQoL.GetModulePageTitle("LevelTime", L("LEVEL_TIME")))
    CurrentLevelLabel:SetText(L("CURRENT_LEVEL"))
    CurrentLevelTimeLabel:SetText(L("TIME_ON_CURRENT_LEVEL"))
    TotalTimeLabel:SetText(L("TOTAL_TIME"))
    LevelListTitle:SetText(L("TRACKED_LEVEL_TIMES"))
    LevelTimeMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    LevelTimeMinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))
    LevelTimeMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("levelTime") or true)

    for level = 1, MAX_LEVEL do
        local row = LevelRows[level]
        row.LevelNumText:SetText(L("LEVEL_LABEL"):format(level))
    end

    RefreshLevelList()
end

-- ========================================
-- Update-Timer
-- ========================================

-- Ein kleiner UI-Timer hält die Anzeige aktuell.
local UpdateFrame = CreateFrame("Frame", nil, PageLevelTime)
local elapsedSinceUpdate = 0

local function HandleLevelTimeUpdate(_, elapsed)
    -- Dieser Timer aktualisiert nur die Anzeige.
    -- Gespeichert wird weiterhin nur an Lebenszyklus-Punkten wie Level-Up oder Logout.
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed

    if elapsedSinceUpdate < UPDATE_INTERVAL then
        return
    end

    elapsedSinceUpdate = 0
    RefreshLevelList()
end

UpdateFrame:SetScript("OnUpdate", function(_, elapsed)
    local profiler = BeavisQoL.PerformanceProfiler
    local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
    HandleLevelTimeUpdate(_, elapsed)
    if profiler and profiler.EndSample then
        profiler.EndSample("LevelTime.OnUpdate", sampleToken)
    end
end)

-- ========================================
-- Events
-- ========================================

-- Start, Level-Up und Logout reichen für den ganzen Lebenszyklus des Trackers.
local LevelWatcher = CreateFrame("Frame")
LevelWatcher:RegisterEvent("PLAYER_LOGIN")
LevelWatcher:RegisterEvent("PLAYER_LEVEL_UP")
LevelWatcher:RegisterEvent("PLAYER_LOGOUT")

LevelWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeLevelTimeData()

        if IsAtMaxLevel() then
            StopSessionTracking()
        else
            StartSessionForCurrentLevel()
        end

        C_Timer.After(0.2, RefreshLevelList)

    elseif event == "PLAYER_LEVEL_UP" then
        -- Erst die alte Session sichern, dann direkt die neue für das frische Level starten.
        SaveCurrentSessionToDatabase()

        local newLevel = ...

        if newLevel >= MAX_LEVEL then
            StopSessionTracking()
        else
            currentSessionLevel = newLevel
            currentSessionStartTime = GetTime()
        end

        RefreshLevelList()

    elseif event == "PLAYER_LOGOUT" then
        SaveCurrentSessionToDatabase()
    end
end)

-- Falls die Seite vor den Events sichtbar wird, haben wir hier noch einen direkten Startpfad.
InitializeLevelTimeData()

if IsAtMaxLevel() then
    StopSessionTracking()
else
    StartSessionForCurrentLevel()
end

C_Timer.After(0.2, RefreshLevelList)

PageLevelTime:SetScript("OnShow", function()
    LevelTimeMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("levelTime") or true)
    RefreshLevelList()
end)

BeavisQoL.Pages.LevelTime = PageLevelTime

