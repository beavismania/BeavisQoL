local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

--[[
QuestCheck.lua ist absichtlich etwas "logischer" als viele andere Seiten:

1. Eingabe lesen und in ID / Name / URL zerlegen
2. lokal bekannte Questtitel cachen
3. Ergebnis in einen einheitlichen Datensatz uebersetzen
4. diesen Datensatz in UI und Chat ausgeben

Dadurch ist die Seite nicht nur Suchfeld + Text, sondern ein kleiner lokaler
Quest-Pruefer mit eigenem Namens-Cache.
]]

local GetQuestTitleForID = C_QuestLog and C_QuestLog.GetTitleForQuestID
local RequestLoadQuestByID = C_QuestLog and C_QuestLog.RequestLoadQuestByID
local IsQuestFlaggedCompleted = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
local IsQuestFlaggedCompletedOnAccount = C_QuestLog and C_QuestLog.IsQuestFlaggedCompletedOnAccount
local GetAllCompletedQuestIDs = C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs
local GetQuestLogInfo = C_QuestLog and C_QuestLog.GetInfo
local GetNumQuestLogEntries = C_QuestLog and C_QuestLog.GetNumQuestLogEntries
local IsOnQuest = C_QuestLog and C_QuestLog.IsOnQuest
local GetTaskQuestInfoByQuestID = C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID

BeavisQoL.QuestCheck = BeavisQoL.QuestCheck or {}
local QuestCheck = BeavisQoL.QuestCheck

QuestCheck.questTitleByID = QuestCheck.questTitleByID or {}
QuestCheck.questIDsByName = QuestCheck.questIDsByName or {}
QuestCheck.completedQuestCachePrimed = QuestCheck.completedQuestCachePrimed or false
QuestCheck.scanNextQuestID = QuestCheck.scanNextQuestID or 1
QuestCheck.scanMaxQuestID = QuestCheck.scanMaxQuestID or 0
QuestCheck.pendingNameSearch = QuestCheck.pendingNameSearch or nil

local MAX_SCAN_QUEST_ID_FALLBACK = 100000
local MAX_SCAN_QUEST_ID_HARD_LIMIT = 120000
local SCAN_BATCH_SIZE = 500
local MAX_VISIBLE_RESULTS = 8

local SearchEditBox
local SearchProgressText
local ResultStateValue
local ResultText
local ResultListText
local WowheadButton

local currentWowheadTitle = nil
local currentWowheadURL = nil

local function TrimText(text)
    -- Nutzertexte immer zuerst bereinigen.
    -- Das spart spaeter viele kleine Sonderfaelle.
    if not text then
        return nil
    end

    local trimmed = string.match(text, "^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function NormalizeQuestName(text)
    local trimmedText = TrimText(text)
    if not trimmedText then
        return nil
    end

    local normalizedText = string.lower(trimmedText)
    normalizedText = string.gsub(normalizedText, "%s+", " ")

    return normalizedText
end

local function UrlEncode(text)
    local sourceText = text or ""

    return string.gsub(sourceText, "([^%w%-_%.~])", function(character)
        return string.format("%%%02X", string.byte(character))
    end)
end

local function GetQuestTitleByID(questID)
    local questTitle = nil

    if GetTaskQuestInfoByQuestID then
        questTitle = GetTaskQuestInfoByQuestID(questID)
    end

    if (not questTitle or questTitle == "") and GetQuestTitleForID then
        questTitle = GetQuestTitleForID(questID)
    end

    if questTitle and questTitle ~= "" then
        return questTitle
    end

    return nil
end

local function RememberQuestTitle(questID, questTitle)
    -- Wir speichern denselben Titel bewusst doppelt:
    -- 1. ID -> Titel fuer direkte Zugriffe
    -- 2. normalisierter Name -> Liste von IDs fuer Namenssuchen
    if not questID or questID <= 0 or not questTitle or questTitle == "" then
        return
    end

    QuestCheck.questTitleByID[questID] = questTitle

    local normalizedName = NormalizeQuestName(questTitle)
    if not normalizedName then
        return
    end

    local questIDs = QuestCheck.questIDsByName[normalizedName]
    if not questIDs then
        questIDs = { _lookup = {} }
        QuestCheck.questIDsByName[normalizedName] = questIDs
    end

    if not questIDs._lookup[questID] then
        questIDs._lookup[questID] = true
        questIDs[#questIDs + 1] = questID
    end
end

local function CacheQuestLogQuestNames()
    if not GetQuestLogInfo or not GetNumQuestLogEntries then
        return
    end

    local numEntries = GetNumQuestLogEntries() or 0

    for questLogIndex = 1, numEntries do
        local questInfo = GetQuestLogInfo(questLogIndex)

        if questInfo and not questInfo.isHeader and questInfo.questID and questInfo.questID > 0 and questInfo.title then
            RememberQuestTitle(questInfo.questID, questInfo.title)
        end
    end
end

local function PrimeCompletedQuestNameCache()
    -- Dieser Schritt kann einmalig etwas "groesser" sein, lohnt sich aber:
    -- Danach koennen wir viele Namenssuchen sofort lokal aufloesen.
    if QuestCheck.completedQuestCachePrimed or not GetAllCompletedQuestIDs then
        return
    end

    local completedQuestIDs = GetAllCompletedQuestIDs()
    if type(completedQuestIDs) ~= "table" then
        return
    end

    for _, questID in ipairs(completedQuestIDs) do
        local questTitle = GetQuestTitleByID(questID)

        if questTitle then
            RememberQuestTitle(questID, questTitle)
        end
    end

    QuestCheck.completedQuestCachePrimed = true
end

local function GetSuggestedMaxQuestID()
    -- Wir scannen bewusst nicht blind bis ins Unendliche, sondern leiten eine
    -- sinnvolle Obergrenze aus bereits bekannten Questdaten ab.
    local maxQuestID = MAX_SCAN_QUEST_ID_FALLBACK

    if GetAllCompletedQuestIDs then
        local completedQuestIDs = GetAllCompletedQuestIDs()

        if type(completedQuestIDs) == "table" and #completedQuestIDs > 0 then
            local lastCompletedQuestID = completedQuestIDs[#completedQuestIDs]

            if lastCompletedQuestID and lastCompletedQuestID > 0 then
                maxQuestID = math.max(maxQuestID, lastCompletedQuestID + 1000)
            end
        end
    end

    if GetQuestLogInfo and GetNumQuestLogEntries then
        local numEntries = GetNumQuestLogEntries() or 0

        for questLogIndex = 1, numEntries do
            local questInfo = GetQuestLogInfo(questLogIndex)

            if questInfo and questInfo.questID and questInfo.questID > 0 then
                maxQuestID = math.max(maxQuestID, questInfo.questID + 250)
            end
        end
    end

    if maxQuestID > MAX_SCAN_QUEST_ID_HARD_LIMIT then
        maxQuestID = MAX_SCAN_QUEST_ID_HARD_LIMIT
    end

    return maxQuestID
end

local function EnsureScanRange()
    local suggestedMaxQuestID = GetSuggestedMaxQuestID()

    if suggestedMaxQuestID > (QuestCheck.scanMaxQuestID or 0) then
        QuestCheck.scanMaxQuestID = suggestedMaxQuestID
    end
end

local function IsQuestNameScanComplete()
    return (QuestCheck.scanMaxQuestID or 0) > 0 and (QuestCheck.scanNextQuestID or 1) > (QuestCheck.scanMaxQuestID or 0)
end

local function BuildWowheadQuestURL(questID)
    return "https://www.wowhead.com/quest=" .. tostring(questID)
end

local function BuildWowheadSearchURL(searchText)
    return "https://www.wowhead.com/search?q=" .. UrlEncode(searchText or "")
end

local function SetWowheadTarget(titleText, urlText, buttonText)
    currentWowheadTitle = titleText
    currentWowheadURL = urlText

    if WowheadButton then
        WowheadButton:SetEnabled(urlText and urlText ~= "")
        WowheadButton:SetText(buttonText or L("WOWHEAD_LINK"))
    end
end

local function ShowCurrentWowheadLink()
    if not currentWowheadURL or currentWowheadURL == "" then
        return
    end

    if BeavisQoL.ShowLinkPopup then
        BeavisQoL.ShowLinkPopup(currentWowheadTitle or L("WOWHEAD_LINK"), currentWowheadURL)
        return
    end

    print(L("WOWHEAD_LINK") .. ": " .. currentWowheadURL)
end

local function PrintQuestCheckMessage(messageText)
    if not messageText or messageText == "" then
        return
    end

    print(L("ADDON_MESSAGE"):format(messageText))
end

local function SetResultState(stateText, red, green, blue)
    ResultStateValue:SetText(stateText or "")
    ResultStateValue:SetTextColor(red or 1, green or 1, blue or 1, 1)
end

local function SetSearchProgress(progressText, red, green, blue)
    SearchProgressText:SetText(progressText or "")
    SearchProgressText:SetTextColor(red or 0.80, green or 0.80, blue or 0.80, 1)
end

local function BuildQuestResult(questID)
    -- Diese Funktion baut den einheitlichen "Wahrheitsblock" fuer genau eine Quest.
    -- Danach arbeiten UI und Ausgabe nur noch mit diesem Ergebnisobjekt.
    local questTitle = QuestCheck.questTitleByID[questID] or GetQuestTitleByID(questID)

    if questTitle then
        RememberQuestTitle(questID, questTitle)
    elseif RequestLoadQuestByID then
        RequestLoadQuestByID(questID)
    end

    return {
        questID = questID,
        questTitle = questTitle,
        isCompleted = IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(questID) or false,
        isWarbandCompleted = IsQuestFlaggedCompletedOnAccount and IsQuestFlaggedCompletedOnAccount(questID) or false,
        isActive = IsOnQuest and IsOnQuest(questID) or false,
    }
end

local function GetResultsForQuestName(normalizedName)
    local questIDs = normalizedName and QuestCheck.questIDsByName[normalizedName]
    local results = {}

    if not questIDs then
        return results
    end

    for _, questID in ipairs(questIDs) do
        results[#results + 1] = BuildQuestResult(questID)
    end

    table.sort(results, function(leftResult, rightResult)
        return leftResult.questID < rightResult.questID
    end)

    return results
end

local function GetResultStatusLabel(result)
    if result.isCompleted then
        return L("QUEST_DONE")
    end

    return L("QUEST_NOT_DONE")
end

local function GetResultExtraTags(result)
    local tags = {}

    if result.isActive and not result.isCompleted then
        tags[#tags + 1] = L("QUEST_IN_LOG")
    end

    if result.isWarbandCompleted then
        tags[#tags + 1] = L("QUEST_WARBAND_DONE")
    end

    if #tags == 0 then
        return nil
    end

    return " [" .. table.concat(tags, ", ") .. "]"
end

local function BuildResultLines(results)
    local lines = {}
    local visibleCount = math.min(#results, MAX_VISIBLE_RESULTS)

    for index = 1, visibleCount do
        local result = results[index]
        local questName = result.questTitle or L("QUEST_ID_LABEL"):format(result.questID)
        local extraTags = GetResultExtraTags(result) or ""

        lines[#lines + 1] = L("QUEST_RESULT_LINE"):format(result.questID, questName, GetResultStatusLabel(result), extraTags)
    end

    if #results > visibleCount then
        lines[#lines + 1] = L("QUEST_MORE_RESULTS"):format(#results - visibleCount)
    end

    return table.concat(lines, "\n")
end

local function RenderSingleResult(result, searchSourceLabel, skipPrint)
    -- Eine einzige Treffer-Quest bekommt den prominentesten UI-Zustand:
    -- Status gross, Details darunter, WoWHead-Link direkt dazu.
    local questName = result.questTitle or L("QUEST_ID_LABEL"):format(result.questID)
    local stateText = result.isCompleted and L("QUEST_DONE_PLAIN") or L("QUEST_NOT_DONE_PLAIN")
    local stateRed = result.isCompleted and 0.35 or 1
    local stateGreen = result.isCompleted and 0.90 or 0.45
    local stateBlue = result.isCompleted and 0.35 or 0.45
    local detailParts = {
        L("QUEST_SINGLE_TEXT"):format(questName, result.questID, searchSourceLabel),
    }

    if result.isActive and not result.isCompleted then
        detailParts[#detailParts + 1] = L("QUEST_IN_LOG")
    end

    if result.isWarbandCompleted then
        detailParts[#detailParts + 1] = L("QUEST_WARBAND_DONE")
    end

    SetResultState(stateText, stateRed, stateGreen, stateBlue)
    ResultText:SetText(table.concat(detailParts, " | "))
    ResultListText:SetText(BuildResultLines({ result }))
    SetWowheadTarget(L("QUEST_WOWHEAD_TITLE"), BuildWowheadQuestURL(result.questID), L("WOWHEAD_LINK"))
    SetSearchProgress("")

    if not skipPrint then
        local chatText = L("QUEST_SINGLE_CHAT"):format(questName, result.questID, result.isCompleted and L("QUEST_DONE_PLAIN") or L("QUEST_NOT_DONE_PLAIN"))

        if result.isActive and not result.isCompleted then
            chatText = chatText .. L("QUEST_SINGLE_CHAT_ACTIVE")
        end

        if result.isWarbandCompleted then
            chatText = chatText .. L("QUEST_SINGLE_CHAT_WARBAND")
        end

        PrintQuestCheckMessage(chatText)
    end
end

local function RenderMultipleResults(searchText, results, skipPrint)
    -- Mehrere Treffer sind kein Fehler, sondern ein bewusst eigener Zustand.
    SetResultState(L("QUEST_MULTIPLE_STATE"):format(#results), 1, 0.82, 0)
    ResultText:SetText(L("QUEST_MULTIPLE_TEXT"))
    ResultListText:SetText(BuildResultLines(results))
    SetWowheadTarget(L("WOWHEAD_SEARCH"), BuildWowheadSearchURL(searchText), L("WOWHEAD_SEARCH"))
    SetSearchProgress("")

    if not skipPrint then
        PrintQuestCheckMessage(L("QUEST_MULTIPLE_CHAT"):format(#results, tostring(searchText)))
    end
end

local function RenderUnresolvedNameSearch(searchText, skipPrint)
    SetResultState(L("NOT_FOUND"), 1, 0.45, 0.45)
    ResultText:SetText(L("QUEST_UNRESOLVED_TEXT"))
    ResultListText:SetText(L("QUEST_UNRESOLVED_TIPS"))
    SetWowheadTarget(L("WOWHEAD_SEARCH"), BuildWowheadSearchURL(searchText), L("WOWHEAD_SEARCH"))
    SetSearchProgress("")

    if not skipPrint then
        PrintQuestCheckMessage(L("QUEST_UNRESOLVED_CHAT"):format(tostring(searchText)))
    end
end

local function ResolveQuestByID(questID, skipPrint)
    local result = BuildQuestResult(questID)

    RenderSingleResult(result, "Direkter ID-Check", skipPrint)
end

local function ResolveQuestByName(searchText, skipPrint)
    local normalizedName = NormalizeQuestName(searchText)
    if not normalizedName then
        return false
    end

    local results = GetResultsForQuestName(normalizedName)

    if #results == 1 then
        RenderSingleResult(results[1], "Namenssuche", skipPrint)
        return true
    end

    if #results > 1 then
        RenderMultipleResults(searchText, results, skipPrint)
        return true
    end

    return false
end

local function UpdateScanProgressText()
    -- Die Fortschrittsanzeige ist nur fuer Namensscans relevant.
    if not QuestCheck.pendingNameSearch or not QuestCheck.scanMaxQuestID or QuestCheck.scanMaxQuestID <= 0 then
        SetSearchProgress("")
        return
    end

    local progress = ((QuestCheck.scanNextQuestID or 1) - 1) / QuestCheck.scanMaxQuestID
    if progress < 0 then
        progress = 0
    elseif progress > 1 then
        progress = 1
    end

    SetSearchProgress(L("QUESTCHECK_SCAN_PROGRESS"):format(progress * 100), 1, 0.82, 0)
end

local function StopNameScan(scanWorker)
    QuestCheck.pendingNameSearch = nil
    scanWorker:Hide()
    SetSearchProgress("")
end

local QuestNameScanWorker = CreateFrame("Frame")
QuestNameScanWorker:Hide()
QuestNameScanWorker:SetScript("OnUpdate", function(self)
    -- Der Scan laeuft bewusst in kleinen Paketen pro Frame.
    -- So friert die UI nicht ein, wenn zum ersten Mal viele Quest-IDs
    -- geprueft werden muessen.
    EnsureScanRange()

    if not QuestCheck.pendingNameSearch then
        StopNameScan(self)
        return
    end

    local scanStartQuestID = QuestCheck.scanNextQuestID or 1
    local scanEndQuestID = math.min(scanStartQuestID + SCAN_BATCH_SIZE - 1, QuestCheck.scanMaxQuestID or 0)

    for questID = scanStartQuestID, scanEndQuestID do
        local questTitle = GetQuestTitleByID(questID)

        if questTitle then
            RememberQuestTitle(questID, questTitle)
        end
    end

    QuestCheck.scanNextQuestID = scanEndQuestID + 1
    UpdateScanProgressText()

    if not IsQuestNameScanComplete() then
        return
    end

    local pendingSearch = QuestCheck.pendingNameSearch

    StopNameScan(self)

    if pendingSearch and ResolveQuestByName(pendingSearch.rawName, false) then
        return
    end

    if pendingSearch then
        RenderUnresolvedNameSearch(pendingSearch.rawName, false)
    end
end)

local function StartQuestNameScan(searchText)
    QuestCheck.pendingNameSearch = {
        rawName = searchText,
    }

    SetResultState(L("QUESTCHECK_SEARCH_RUNNING"), 1, 0.82, 0)
    ResultText:SetText(L("QUESTCHECK_SCANNING"))
    ResultListText:SetText("")
    SetWowheadTarget(L("WOWHEAD_SEARCH"), BuildWowheadSearchURL(searchText), L("WOWHEAD_SEARCH"))
    UpdateScanProgressText()
    QuestNameScanWorker:Show()
end

local function ParseQuestInput(rawInput)
    -- Erlaubte Eingaben:
    -- - pure Quest-ID
    -- - WoWHead-Link
    -- - freier Questname
    local trimmedInput = TrimText(rawInput)
    if not trimmedInput then
        return nil, nil
    end

    local questID = tonumber(trimmedInput)

    if not questID then
        questID = tonumber(string.match(trimmedInput, "[%?&]quest=(%d+)"))
            or tonumber(string.match(trimmedInput, "/quest=(%d+)"))
            or tonumber(string.match(trimmedInput, "/quest/(%d+)"))
            or tonumber(string.match(trimmedInput, "quest:(%d+)"))
    end

    if questID then
        return "id", questID
    end

    return "name", trimmedInput
end

local function RunQuestSearch()
    -- Haupt-Einstieg fuer Suchbutton und Enter-Taste.
    local searchMode, searchValue = ParseQuestInput(SearchEditBox:GetText())

    if not searchMode then
        SetResultState(L("QUEST_INPUT_MISSING_STATE"), 1, 0.45, 0.45)
        ResultText:SetText(L("QUESTCHECK_INPUT_MISSING"))
        ResultListText:SetText("")
        SetWowheadTarget(nil, nil, L("WOWHEAD_LINK"))
        SetSearchProgress("")
        return
    end

    CacheQuestLogQuestNames()

    if searchMode == "id" then
        StopNameScan(QuestNameScanWorker)
        ResolveQuestByID(searchValue, false)
        return
    end

    PrimeCompletedQuestNameCache()
    local normalizedName = NormalizeQuestName(searchValue)
    local cachedResults = normalizedName and GetResultsForQuestName(normalizedName) or {}

    if #cachedResults > 1 then
        RenderMultipleResults(searchValue, cachedResults, false)
        return
    end

    EnsureScanRange()

    if IsQuestNameScanComplete() then
        if #cachedResults == 1 then
            RenderSingleResult(cachedResults[1], "Namenssuche", false)
            return
        end

        RenderUnresolvedNameSearch(searchValue, false)
        return
    end

    StartQuestNameScan(searchValue)
end

local PageQuestCheck = CreateFrame("Frame", nil, Content)
PageQuestCheck:SetAllPoints()
PageQuestCheck:Hide()

-- ========================================
-- Intro
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageQuestCheck)
IntroPanel:SetPoint("TOPLEFT", PageQuestCheck, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageQuestCheck, "TOPRIGHT", -20, -20)
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
IntroTitle:SetText(L("QUESTCHECK_TITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("QUESTCHECK_DESC"))

-- ========================================
-- Suchbereich
-- ========================================

local SearchPanel = CreateFrame("Frame", nil, PageQuestCheck)
SearchPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
SearchPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
SearchPanel:SetHeight(150)

local SearchBg = SearchPanel:CreateTexture(nil, "BACKGROUND")
SearchBg:SetAllPoints()
SearchBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local SearchBorder = SearchPanel:CreateTexture(nil, "ARTWORK")
SearchBorder:SetPoint("BOTTOMLEFT", SearchPanel, "BOTTOMLEFT", 0, 0)
SearchBorder:SetPoint("BOTTOMRIGHT", SearchPanel, "BOTTOMRIGHT", 0, 0)
SearchBorder:SetHeight(1)
SearchBorder:SetColorTexture(1, 0.82, 0, 0.9)

local SearchTitle = SearchPanel:CreateFontString(nil, "OVERLAY")
SearchTitle:SetPoint("TOPLEFT", SearchPanel, "TOPLEFT", 18, -14)
SearchTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SearchTitle:SetTextColor(1, 0.82, 0, 1)
SearchTitle:SetText(L("QUEST_SEARCH"))

local SearchHint = SearchPanel:CreateFontString(nil, "OVERLAY")
SearchHint:SetPoint("TOPLEFT", SearchTitle, "BOTTOMLEFT", 0, -10)
SearchHint:SetPoint("RIGHT", SearchPanel, "RIGHT", -18, 0)
SearchHint:SetJustifyH("LEFT")
SearchHint:SetJustifyV("TOP")
SearchHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SearchHint:SetTextColor(0.80, 0.80, 0.80, 1)
SearchHint:SetText(L("QUEST_SEARCH_HINT"))

SearchEditBox = CreateFrame("EditBox", nil, SearchPanel, "InputBoxTemplate")
SearchEditBox:SetSize(430, 30)
SearchEditBox:SetPoint("TOPLEFT", SearchHint, "BOTTOMLEFT", 4, -16)
SearchEditBox:SetAutoFocus(false)
SearchEditBox:SetMaxLetters(240)
SearchEditBox:SetFontObject(ChatFontNormal)

local SearchButton = CreateFrame("Button", nil, SearchPanel, "UIPanelButtonTemplate")
SearchButton:SetSize(130, 28)
SearchButton:SetPoint("LEFT", SearchEditBox, "RIGHT", 12, 0)
SearchButton:SetText(L("CHECK_QUEST"))
SearchButton:SetScript("OnClick", RunQuestSearch)

SearchProgressText = SearchPanel:CreateFontString(nil, "OVERLAY")
SearchProgressText:SetPoint("TOPLEFT", SearchEditBox, "BOTTOMLEFT", 0, -12)
SearchProgressText:SetPoint("RIGHT", SearchPanel, "RIGHT", -18, 0)
SearchProgressText:SetJustifyH("LEFT")
SearchProgressText:SetJustifyV("TOP")
SearchProgressText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SearchProgressText:SetTextColor(0.80, 0.80, 0.80, 1)
SearchProgressText:SetText("")

SearchEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    RunQuestSearch()
end)

SearchEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- ========================================
-- Ergebnis
-- ========================================

local ResultPanel = CreateFrame("Frame", nil, PageQuestCheck)
ResultPanel:SetPoint("TOPLEFT", SearchPanel, "BOTTOMLEFT", 0, -18)
ResultPanel:SetPoint("TOPRIGHT", SearchPanel, "BOTTOMRIGHT", 0, -18)
ResultPanel:SetPoint("BOTTOMRIGHT", PageQuestCheck, "BOTTOMRIGHT", -20, 8)

local ResultBg = ResultPanel:CreateTexture(nil, "BACKGROUND")
ResultBg:SetAllPoints()
ResultBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local ResultBorder = ResultPanel:CreateTexture(nil, "ARTWORK")
ResultBorder:SetPoint("BOTTOMLEFT", ResultPanel, "BOTTOMLEFT", 0, 0)
ResultBorder:SetPoint("BOTTOMRIGHT", ResultPanel, "BOTTOMRIGHT", 0, 0)
ResultBorder:SetHeight(1)
ResultBorder:SetColorTexture(1, 0.82, 0, 0.9)

local ResultTitle = ResultPanel:CreateFontString(nil, "OVERLAY")
ResultTitle:SetPoint("TOPLEFT", ResultPanel, "TOPLEFT", 18, -14)
ResultTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
ResultTitle:SetTextColor(1, 0.82, 0, 1)
ResultTitle:SetText(L("RESULT"))

ResultStateValue = ResultPanel:CreateFontString(nil, "OVERLAY")
ResultStateValue:SetPoint("TOPLEFT", ResultTitle, "BOTTOMLEFT", 0, -12)
ResultStateValue:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
ResultStateValue:SetTextColor(1, 0.82, 0, 1)
ResultStateValue:SetText(L("READY"))

ResultText = ResultPanel:CreateFontString(nil, "OVERLAY")
ResultText:SetPoint("TOPLEFT", ResultStateValue, "BOTTOMLEFT", 0, -10)
ResultText:SetPoint("RIGHT", ResultPanel, "RIGHT", -18, 0)
ResultText:SetJustifyH("LEFT")
ResultText:SetJustifyV("TOP")
ResultText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
ResultText:SetTextColor(1, 1, 1, 1)
ResultText:SetText(L("QUESTCHECK_RESULT_HINT"))

ResultListText = ResultPanel:CreateFontString(nil, "OVERLAY")
ResultListText:SetPoint("TOPLEFT", ResultText, "BOTTOMLEFT", 0, -14)
ResultListText:SetPoint("BOTTOMRIGHT", ResultPanel, "BOTTOMRIGHT", -18, 54)
ResultListText:SetJustifyH("LEFT")
ResultListText:SetJustifyV("TOP")
ResultListText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
ResultListText:SetTextColor(0.88, 0.88, 0.88, 1)
ResultListText:SetText(L("QUESTCHECK_NO_SEARCH"))

WowheadButton = CreateFrame("Button", nil, ResultPanel, "UIPanelButtonTemplate")
WowheadButton:SetSize(140, 28)
WowheadButton:SetPoint("BOTTOMLEFT", ResultPanel, "BOTTOMLEFT", 18, 16)
WowheadButton:SetText(L("WOWHEAD_LINK"))
WowheadButton:SetEnabled(false)
WowheadButton:SetScript("OnClick", ShowCurrentWowheadLink)

local ResultHint = ResultPanel:CreateFontString(nil, "OVERLAY")
ResultHint:SetPoint("LEFT", WowheadButton, "RIGHT", 14, 0)
ResultHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
ResultHint:SetTextColor(0.75, 0.75, 0.75, 1)
ResultHint:SetText(L("LINKS_COPY_DIALOG"))

BeavisQoL.UpdateQuestCheck = function()
    IntroTitle:SetText(L("QUESTCHECK_TITLE"))
    IntroText:SetText(L("QUESTCHECK_DESC"))
    SearchTitle:SetText(L("QUEST_SEARCH"))
    SearchHint:SetText(L("QUEST_SEARCH_HINT"))
    SearchButton:SetText(L("CHECK_QUEST"))
    ResultTitle:SetText(L("RESULT"))
    WowheadButton:SetText(L("WOWHEAD_LINK"))
    ResultHint:SetText(L("LINKS_COPY_DIALOG"))

    if not currentWowheadURL then
        ResultStateValue:SetText(L("READY"))
        ResultText:SetText(L("QUESTCHECK_RESULT_HINT"))
        ResultListText:SetText(L("QUESTCHECK_NO_SEARCH"))
    end
end

PageQuestCheck:SetScript("OnShow", function()
    CacheQuestLogQuestNames()
end)

local QuestCheckWatcher = CreateFrame("Frame")
QuestCheckWatcher:RegisterEvent("PLAYER_LOGIN")
QuestCheckWatcher:RegisterEvent("QUEST_LOG_UPDATE")
QuestCheckWatcher:RegisterEvent("QUEST_DATA_LOAD_RESULT")
QuestCheckWatcher:SetScript("OnEvent", function(_, eventName, ...)
    if eventName == "PLAYER_LOGIN" or eventName == "QUEST_LOG_UPDATE" then
        CacheQuestLogQuestNames()
        return
    end

    if eventName ~= "QUEST_DATA_LOAD_RESULT" then
        return
    end

    local questID, success = ...
    if not success then
        return
    end

    local questTitle = GetQuestTitleByID(questID)
    if questTitle then
        RememberQuestTitle(questID, questTitle)
    end

    local currentInput = SearchEditBox and SearchEditBox:GetText()
    local searchMode, searchValue = ParseQuestInput(currentInput)

    if searchMode == "id" and searchValue == questID then
        ResolveQuestByID(questID, true)
    end
end)

BeavisQoL.Pages.QuestCheck = PageQuestCheck
