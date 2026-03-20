local ADDON_NAME, BeavisAddon = ...

local Content = BeavisAddon.Content
local MAX_LEVEL = 90
local UPDATE_INTERVAL = 0.2

-- Die Seite trennt zwischen gespeicherten Daten und der gerade laufenden Session.
-- So können wir live anzeigen, ohne dauernd in die SavedVariables zu schreiben.
local PageLevelTime = CreateFrame("Frame", nil, Content)
PageLevelTime:SetAllPoints()
PageLevelTime:Hide()

-- Datenbank sauber anlegen
if not BeavisAddonCharDB then BeavisAddonCharDB = {} end
if not BeavisAddonCharDB.LevelTime then BeavisAddonCharDB.LevelTime = {} end
local LevelDB = BeavisAddonCharDB.LevelTime
local currentSessionLevel = nil
local currentSessionStartTime = nil

-- ========================================
-- Daten-Initialisierung
-- ========================================

-- Für jedes Level legen wir einen Eintrag an, damit später keine nil-Sonderfälle auftauchen.
local function InitializeLevelTimeData()
    BeavisAddonCharDB = BeavisAddonCharDB or {}
    BeavisAddonCharDB.LevelTime = BeavisAddonCharDB.LevelTime or {}

    LevelDB = BeavisAddonCharDB.LevelTime

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
OverviewPanel:SetPoint("TOPLEFT", PageLevelTime, "TOPLEFT", 20, -20)
OverviewPanel:SetPoint("TOPRIGHT", PageLevelTime, "TOPRIGHT", -20, -20)
OverviewPanel:SetHeight(92)

local OverviewBg = OverviewPanel:CreateTexture(nil, "BACKGROUND")
OverviewBg:SetAllPoints()
OverviewBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local OverviewBorder = OverviewPanel:CreateTexture(nil, "ARTWORK")
OverviewBorder:SetPoint("BOTTOMLEFT", OverviewPanel, "BOTTOMLEFT", 0, 0)
OverviewBorder:SetPoint("BOTTOMRIGHT", OverviewPanel, "BOTTOMRIGHT", 0, 0)
OverviewBorder:SetHeight(1)
OverviewBorder:SetColorTexture(1, 0.82, 0, 0.9)

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
InfoText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
InfoText:SetTextColor(0.15, 0.6, 1, 1)
InfoText:SetPoint("CENTER", InfoButton, "CENTER", 0, -1)
InfoText:SetText("i")
InfoButton.Text = InfoText

InfoButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Levelzeit-Tracker", 1, 1, 1)
    GameTooltip:AddLine("Der Levelzeit-Tracker zählt nur die tatsächlich gespielte Zeit, während das Addon aktiv ist.", 0.9, 0.9, 0.9, true)
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
CurrentLevelLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
CurrentLevelLabel:SetTextColor(0.85, 0.85, 0.85, 1)
CurrentLevelLabel:SetText("Aktuelles Level")

local CurrentLevelValue = CurrentLevelCard:CreateFontString(nil, "OVERLAY")
CurrentLevelValue:SetPoint("TOPLEFT", CurrentLevelLabel, "BOTTOMLEFT", 0, -6)
CurrentLevelValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
CurrentLevelValue:SetTextColor(1, 0.82, 0, 1)
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
CurrentLevelTimeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
CurrentLevelTimeLabel:SetTextColor(0.85, 0.85, 0.85, 1)
CurrentLevelTimeLabel:SetText("Zeit auf aktuellem Level")

local CurrentLevelTimeValue = CurrentLevelTimeCard:CreateFontString(nil, "OVERLAY")
CurrentLevelTimeValue:SetPoint("TOPLEFT", CurrentLevelTimeLabel, "BOTTOMLEFT", 0, -6)
CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
CurrentLevelTimeValue:SetTextColor(1, 1, 1, 1)
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
TotalTimeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
TotalTimeLabel:SetTextColor(0.85, 0.85, 0.85, 1)
TotalTimeLabel:SetText("Gesamtzeit")

local TotalTimeValue = TotalTimeCard:CreateFontString(nil, "OVERLAY")
TotalTimeValue:SetPoint("TOPLEFT", TotalTimeLabel, "BOTTOMLEFT", 0, -6)
TotalTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
TotalTimeValue:SetTextColor(1, 1, 1, 1)
TotalTimeValue:SetText("0s")

-- ========================================
-- Fortschrittsbereich
-- ========================================

local ProgressPanel = CreateFrame("Frame", nil, PageLevelTime)
ProgressPanel:SetPoint("TOPLEFT", OverviewPanel, "BOTTOMLEFT", 0, -14)
ProgressPanel:SetPoint("TOPRIGHT", OverviewPanel, "BOTTOMRIGHT", 0, -14)
ProgressPanel:SetHeight(72)

local ProgressBg = ProgressPanel:CreateTexture(nil, "BACKGROUND")
ProgressBg:SetAllPoints()
ProgressBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local ProgressBorder = ProgressPanel:CreateTexture(nil, "ARTWORK")
ProgressBorder:SetPoint("BOTTOMLEFT", ProgressPanel, "BOTTOMLEFT", 0, 0)
ProgressBorder:SetPoint("BOTTOMRIGHT", ProgressPanel, "BOTTOMRIGHT", 0, 0)
ProgressBorder:SetHeight(1)
ProgressBorder:SetColorTexture(1, 0.82, 0, 0.9)

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
ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
ProgressPercentText:SetTextColor(1, 1, 1, 1)
ProgressPercentText:SetText("0.0%")

-- ========================================
-- Level-Liste
-- ========================================

local LevelListContainer = CreateFrame("Frame", nil, PageLevelTime)
LevelListContainer:SetPoint("TOPLEFT", ProgressPanel, "BOTTOMLEFT", 0, -12)
LevelListContainer:SetPoint("BOTTOMRIGHT", PageLevelTime, "BOTTOMRIGHT", -20, 8)

local LevelListBg = LevelListContainer:CreateTexture(nil, "BACKGROUND")
LevelListBg:SetAllPoints()
LevelListBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local LevelListTitle = LevelListContainer:CreateFontString(nil, "OVERLAY")
LevelListTitle:SetPoint("TOPLEFT", LevelListContainer, "TOPLEFT", 10, -10)
LevelListTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
LevelListTitle:SetTextColor(1, 0.82, 0, 1)
LevelListTitle:SetText("Erfasste Levelzeiten")

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
    LevelNumText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    LevelNumText:SetTextColor(1, 0.82, 0, 1)
    LevelNumText:SetJustifyH("LEFT")
    LevelNumText:SetText("Level " .. level)
    Row.LevelNumText = LevelNumText

    local StatusText = Row:CreateFontString(nil, "OVERLAY")
    StatusText:SetPoint("LEFT", LevelNumText, "RIGHT", 10, 0)
    StatusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    StatusText:SetTextColor(0.70, 0.70, 0.70, 1)
    StatusText:SetJustifyH("LEFT")
    StatusText:SetText("")
    Row.StatusText = StatusText

    local TimeText = Row:CreateFontString(nil, "OVERLAY")
    TimeText:SetPoint("RIGHT", Row, "RIGHT", -14, 0)
    TimeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
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
            row.LevelNumText:SetTextColor(1, 0.82, 0, 1)
            row.StatusText:SetText("läuft gerade")
            row.StatusText:SetTextColor(0.55, 1.00, 0.55, 1)
            row.TimeText:SetTextColor(1, 1, 1, 1)
        else
            if index % 2 == 0 then
                row.Background:SetColorTexture(0.09, 0.09, 0.09, 0.45)
            else
                row.Background:SetColorTexture(0.09, 0.09, 0.09, 0.15)
            end

            row.LevelNumText:SetTextColor(1, 0.82, 0, 1)
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
        CurrentLevelTimeLabel:SetText("Status")
        CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        CurrentLevelTimeValue:SetTextColor(1, 0.82, 0, 1)
        CurrentLevelTimeValue:SetText("Maximallevel erreicht")

        ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        ProgressPercentText:SetTextColor(1, 0.82, 0, 1)
        ProgressPercentText:SetText("Glückwunsch, du hast das Maximallevel erreicht.")
    else
        CurrentLevelTimeLabel:SetText("Zeit auf aktuellem Level")
        CurrentLevelTimeValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
        CurrentLevelTimeValue:SetTextColor(1, 1, 1, 1)
        CurrentLevelTimeValue:SetText(TimeToString(currentLevelTime))

        ProgressPercentText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        ProgressPercentText:SetTextColor(1, 1, 1, 1)
        ProgressPercentText:SetText(string.format("%.1f%%", GetProgressPercent() * 100))
    end

    local progressPercent = GetProgressPercent()
    local barWidth = ProgressBarBg:GetWidth() * progressPercent
    ProgressBar:SetWidth(math.max(0, barWidth))
end

-- ========================================
-- Update-Timer
-- ========================================

-- Ein kleiner UI-Timer hält die Anzeige aktuell.
local UpdateFrame = CreateFrame("Frame", nil, PageLevelTime)
local elapsedSinceUpdate = 0

UpdateFrame:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed

    if elapsedSinceUpdate < UPDATE_INTERVAL then
        return
    end

    elapsedSinceUpdate = 0
    RefreshLevelList()
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

BeavisAddon.Pages.LevelTime = PageLevelTime
