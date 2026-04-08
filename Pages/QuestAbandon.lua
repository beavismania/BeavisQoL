local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

local GetQuestLogInfo = C_QuestLog and C_QuestLog.GetInfo
local GetNumQuestLogEntries = C_QuestLog and C_QuestLog.GetNumQuestLogEntries
local GetNumQuestLeaderBoards = rawget(_G, "GetNumQuestLeaderBoards")
local GetQuestObjectiveInfo = rawget(_G, "GetQuestObjectiveInfo")
local SetSelectedQuest = C_QuestLog and C_QuestLog.SetSelectedQuest
local SelectQuestLogEntry = rawget(_G, "SelectQuestLogEntry")
local SetAbandonQuest = rawget(_G, "SetAbandonQuest") or (C_QuestLog and C_QuestLog["SetAbandonQuest"])
local AbandonQuest = rawget(_G, "AbandonQuest") or (C_QuestLog and C_QuestLog["AbandonQuest"])
local StaticPopupNumDialogs = rawget(_G, "STATICPOPUP_NUMDIALOGS")

BeavisQoL.QuestAbandon = BeavisQoL.QuestAbandon or {}
local QuestAbandon = BeavisQoL.QuestAbandon

QuestAbandon.selectedQuestIDs = QuestAbandon.selectedQuestIDs or {}

local IntroTitle
local IntroText
local AbandonTitle
local AbandonHint
local AbandonStatusText
local AbandonSelectedButton
local AbandonSelectAllButton
local AbandonClearAllButton
local AbandonQuestRows = {}
local AbandonScrollFrame
local AbandonScrollContent
local isQuickViewMode = false

local ABANDON_SELECTED_QUESTS_POPUP_KEY = "BEAVISQOL_ABANDON_SELECTED_QUESTS"
local ABANDON_ROW_HEIGHT = 40

local function PrintQuestMessage(messageText)
    if not messageText or messageText == "" then
        return
    end

    print(L("ADDON_MESSAGE"):format(messageText))
end

local function IsVisibleQuestLogEntry(questInfo)
    if not questInfo or questInfo.isHeader or not questInfo.questID or questInfo.questID <= 0 then
        return false
    end

    -- Das Blizzard-Questlog liefert hier auch Tasks, Story-/Kampagnenzeilen und
    -- weitere interne Einträge. Für den Massenabbruch wollen wir nur die
    -- "normalen" sichtbaren Questzeilen anbieten, die sich wie klassische
    -- Spieler-Quests verhalten.
    if questInfo.isHidden or questInfo.isTask or questInfo.isBounty or questInfo.isStory or questInfo.isCampaign then
        return false
    end

    if questInfo.isCalling or questInfo.isMeta then
        return false
    end

    return true
end

local function GetQuestObjectiveSummary(questLogIndex, questID)
    if not questLogIndex or questLogIndex <= 0 or not questID or not GetNumQuestLeaderBoards or not GetQuestObjectiveInfo then
        return nil
    end

    local firstObjectiveText = nil
    local numObjectives = GetNumQuestLeaderBoards(questLogIndex) or 0

    for objectiveIndex = 1, numObjectives do
        local objectiveText, _, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false)

        if objectiveText and objectiveText ~= "" then
            local trimmedObjectiveText = string.match(objectiveText, "^%s*(.-)%s*$")

            if trimmedObjectiveText and trimmedObjectiveText ~= "" then
                firstObjectiveText = firstObjectiveText or trimmedObjectiveText

                if not finished then
                    return trimmedObjectiveText
                end
            end
        end
    end

    return firstObjectiveText
end

local function GetActiveQuestEntries()
    local questEntries = {}

    if not GetQuestLogInfo or not GetNumQuestLogEntries then
        return questEntries
    end

    local numEntries = GetNumQuestLogEntries() or 0

    for questLogIndex = 1, numEntries do
        local questInfo = GetQuestLogInfo(questLogIndex)

        if questInfo and IsVisibleQuestLogEntry(questInfo) then
            local questID = tonumber(questInfo.questID)

            if questID and questID > 0 then
                local questTitle = questInfo.title or ""
                local objectiveText = GetQuestObjectiveSummary(questLogIndex, questID)

                questEntries[#questEntries + 1] = {
                    questID = questID,
                    questLogIndex = questLogIndex,
                    title = questTitle,
                    objectiveText = objectiveText,
                }
            end
        end
    end

    return questEntries
end

local function CountSelectedAbandonQuests(questEntries)
    local selectedCount = 0

    for _, questEntry in ipairs(questEntries or GetActiveQuestEntries()) do
        if QuestAbandon.selectedQuestIDs[questEntry.questID] then
            selectedCount = selectedCount + 1
        end
    end

    return selectedCount
end

local function NormalizeAbandonSelections(questEntries)
    local activeLookup = {}

    for _, questEntry in ipairs(questEntries) do
        activeLookup[questEntry.questID] = true
    end

    for questID in pairs(QuestAbandon.selectedQuestIDs) do
        if not activeLookup[questID] then
            QuestAbandon.selectedQuestIDs[questID] = nil
        end
    end
end

local function SetAllAbandonSelections(isSelected)
    local questEntries = GetActiveQuestEntries()
    NormalizeAbandonSelections(questEntries)

    for _, questEntry in ipairs(questEntries) do
        QuestAbandon.selectedQuestIDs[questEntry.questID] = isSelected and true or nil
    end
end

local function RunAbandonSelectedQuests()
    local questEntries = GetActiveQuestEntries()
    local abandonedCount = 0

    NormalizeAbandonSelections(questEntries)

    for index = #questEntries, 1, -1 do
        local questEntry = questEntries[index]

        if QuestAbandon.selectedQuestIDs[questEntry.questID] then
            if SetSelectedQuest then
                SetSelectedQuest(questEntry.questID)
            elseif SelectQuestLogEntry then
                SelectQuestLogEntry(questEntry.questLogIndex)
            end

            if SetAbandonQuest and AbandonQuest then
                SetAbandonQuest()
                AbandonQuest()
                abandonedCount = abandonedCount + 1
            end

            QuestAbandon.selectedQuestIDs[questEntry.questID] = nil
        end
    end

    if abandonedCount > 0 then
        PrintQuestMessage(L("QUEST_ABANDON_DONE"):format(abandonedCount))
    else
        PrintQuestMessage(L("QUEST_ABANDON_SELECTED_NONE"))
    end
end

local function ConfirmAbandonSelectedQuests()
    local questEntries = GetActiveQuestEntries()
    local selectedCount = CountSelectedAbandonQuests(questEntries)

    if selectedCount <= 0 then
        PrintQuestMessage(L("QUEST_ABANDON_SELECTED_NONE"))
        return
    end

    if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs[ABANDON_SELECTED_QUESTS_POPUP_KEY] then
        StaticPopup_Show(ABANDON_SELECTED_QUESTS_POPUP_KEY, L("QUEST_ABANDON_CONFIRM"):format(selectedCount))
        return
    end

    RunAbandonSelectedQuests()
end

if StaticPopupDialogs and not StaticPopupDialogs[ABANDON_SELECTED_QUESTS_POPUP_KEY] then
    StaticPopupDialogs[ABANDON_SELECTED_QUESTS_POPUP_KEY] = {
        text = "%s",
        button1 = YES,
        button2 = CANCEL,
        OnAccept = function()
            RunAbandonSelectedQuests()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = StaticPopupNumDialogs,
    }
end

local function RefreshAbandonQuestSelectionUI()
    if not AbandonStatusText or not AbandonSelectedButton or not AbandonSelectAllButton or not AbandonClearAllButton then
        return
    end

    local questEntries = GetActiveQuestEntries()
    NormalizeAbandonSelections(questEntries)

    local selectedCount = CountSelectedAbandonQuests(questEntries)
    local questCount = #questEntries

    if not SetAbandonQuest or not AbandonQuest then
        AbandonStatusText:SetText(L("QUEST_ABANDON_UNAVAILABLE"))
        AbandonStatusText:SetTextColor(1, 0.45, 0.45, 1)
        AbandonSelectedButton:SetEnabled(false)
        AbandonSelectAllButton:SetEnabled(false)
        AbandonClearAllButton:SetEnabled(false)
    elseif questCount <= 0 then
        AbandonStatusText:SetText(L("QUEST_ABANDON_NONE"))
        AbandonStatusText:SetTextColor(0.78, 0.74, 0.69, 1)
        AbandonSelectedButton:SetEnabled(false)
        AbandonSelectAllButton:SetEnabled(false)
        AbandonClearAllButton:SetEnabled(false)
    else
        AbandonStatusText:SetText(L("QUEST_ABANDON_SELECTION_COUNT"):format(selectedCount, questCount))
        AbandonStatusText:SetTextColor(1, 0.88, 0.62, 1)
        AbandonSelectedButton:SetEnabled(selectedCount > 0)
        AbandonSelectAllButton:SetEnabled(selectedCount < questCount)
        AbandonClearAllButton:SetEnabled(selectedCount > 0)
    end

    if not AbandonScrollFrame or not AbandonScrollContent then
        return
    end

    local contentWidth = math.max(1, AbandonScrollFrame:GetWidth())
    AbandonScrollContent:SetWidth(contentWidth)

    for index, questEntry in ipairs(questEntries) do
        local row = AbandonQuestRows[index]

        if not row then
            row = CreateFrame("Frame", nil, AbandonScrollContent)
            row:SetHeight(ABANDON_ROW_HEIGHT)

            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -4)
            row.checkbox = checkbox

            local title = row:CreateFontString(nil, "OVERLAY")
            title:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 4, -2)
            title:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            title:SetJustifyH("LEFT")
            title:SetJustifyV("TOP")
            title:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
            title:SetTextColor(0.92, 0.92, 0.92, 1)
            if title.SetWordWrap then
                title:SetWordWrap(false)
            end
            row.title = title

            local objective = row:CreateFontString(nil, "OVERLAY")
            objective:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
            objective:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            objective:SetJustifyH("LEFT")
            objective:SetJustifyV("TOP")
            objective:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            objective:SetTextColor(0.74, 0.74, 0.78, 1)
            if objective.SetWordWrap then
                objective:SetWordWrap(false)
            end
            row.objective = objective

            checkbox:SetScript("OnClick", function(self)
                if self.questID then
                    QuestAbandon.selectedQuestIDs[self.questID] = self:GetChecked() and true or nil
                end

                RefreshAbandonQuestSelectionUI()
            end)

            AbandonQuestRows[index] = row
        end

        row:SetPoint("TOPLEFT", AbandonScrollContent, "TOPLEFT", 0, -((index - 1) * ABANDON_ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", AbandonScrollContent, "TOPRIGHT", -6, -((index - 1) * ABANDON_ROW_HEIGHT))
        row.checkbox.questID = questEntry.questID
        row.checkbox:SetChecked(QuestAbandon.selectedQuestIDs[questEntry.questID] == true)
        row.title:SetText(string.format("[%d] %s", questEntry.questID, questEntry.title or L("QUEST_ID_LABEL"):format(questEntry.questID)))

        if questEntry.objectiveText and questEntry.objectiveText ~= "" then
            row.objective:SetText("- " .. questEntry.objectiveText)
            row.objective:Show()
        else
            row.objective:SetText("")
            row.objective:Hide()
        end

        row:Show()
    end

    for index = #questEntries + 1, #AbandonQuestRows do
        AbandonQuestRows[index]:Hide()
    end

    AbandonScrollContent:SetHeight(math.max(1, questCount * ABANDON_ROW_HEIGHT))
end

local PageQuestAbandon = CreateFrame("Frame", nil, Content)
PageQuestAbandon:SetAllPoints()
PageQuestAbandon:Hide()

local IntroPanel = CreateFrame("Frame", nil, PageQuestAbandon)
IntroPanel:SetPoint("TOPLEFT", PageQuestAbandon, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageQuestAbandon, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(154)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.09, 0.05, 0.05, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(1, 0.45, 0.25, 0.95)

IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
IntroTitle:SetTextColor(1, 0.55, 0.35, 1)
IntroTitle:SetText(BeavisQoL.GetModulePageTitle("QuestAbandon", L("QUEST_ABANDON_TITLE")))

IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
IntroText:SetText(L("QUEST_ABANDON_DESC"))

local QuestAbandonMinimapContextCheckbox = CreateFrame("CheckButton", nil, IntroPanel, "UICheckButtonTemplate")
QuestAbandonMinimapContextCheckbox:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", -4, -12)
QuestAbandonMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("questAbandon") or true)
QuestAbandonMinimapContextCheckbox:SetScript("OnClick", function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("questAbandon", self:GetChecked())
    end
end)

local QuestAbandonMinimapContextLabel = IntroPanel:CreateFontString(nil, "OVERLAY")
QuestAbandonMinimapContextLabel:SetPoint("LEFT", QuestAbandonMinimapContextCheckbox, "RIGHT", 6, 0)
QuestAbandonMinimapContextLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
QuestAbandonMinimapContextLabel:SetTextColor(0.95, 0.91, 0.85, 1)
QuestAbandonMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))

local QuestAbandonMinimapContextHint = IntroPanel:CreateFontString(nil, "OVERLAY")
QuestAbandonMinimapContextHint:SetPoint("TOPLEFT", QuestAbandonMinimapContextCheckbox, "BOTTOMLEFT", 34, -2)
QuestAbandonMinimapContextHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
QuestAbandonMinimapContextHint:SetJustifyH("LEFT")
QuestAbandonMinimapContextHint:SetJustifyV("TOP")
QuestAbandonMinimapContextHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
QuestAbandonMinimapContextHint:SetTextColor(0.75, 0.75, 0.75, 1)
QuestAbandonMinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))

local AbandonPanel = CreateFrame("Frame", nil, PageQuestAbandon)
AbandonPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
AbandonPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
AbandonPanel:SetPoint("BOTTOMRIGHT", PageQuestAbandon, "BOTTOMRIGHT", -20, 8)

local AbandonBg = AbandonPanel:CreateTexture(nil, "BACKGROUND")
AbandonBg:SetAllPoints()
AbandonBg:SetColorTexture(0.09, 0.05, 0.05, 0.94)

local AbandonBorder = AbandonPanel:CreateTexture(nil, "ARTWORK")
AbandonBorder:SetPoint("BOTTOMLEFT", AbandonPanel, "BOTTOMLEFT", 0, 0)
AbandonBorder:SetPoint("BOTTOMRIGHT", AbandonPanel, "BOTTOMRIGHT", 0, 0)
AbandonBorder:SetHeight(1)
AbandonBorder:SetColorTexture(1, 0.45, 0.25, 0.95)

AbandonTitle = AbandonPanel:CreateFontString(nil, "OVERLAY")
AbandonTitle:SetPoint("TOPLEFT", AbandonPanel, "TOPLEFT", 18, -14)
AbandonTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
AbandonTitle:SetTextColor(1, 0.55, 0.35, 1)
AbandonTitle:SetText(L("QUEST_ABANDON_LIST_TITLE"))

AbandonHint = AbandonPanel:CreateFontString(nil, "OVERLAY")
AbandonHint:SetPoint("TOPLEFT", AbandonTitle, "BOTTOMLEFT", 0, -10)
AbandonHint:SetPoint("RIGHT", AbandonPanel, "RIGHT", -18, 0)
AbandonHint:SetJustifyH("LEFT")
AbandonHint:SetJustifyV("TOP")
AbandonHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
AbandonHint:SetTextColor(0.92, 0.82, 0.82, 1)
AbandonHint:SetText(L("QUEST_ABANDON_DESC"))

AbandonSelectAllButton = CreateFrame("Button", nil, AbandonPanel, "UIPanelButtonTemplate")
AbandonSelectAllButton:SetSize(110, 24)
AbandonSelectAllButton:SetPoint("TOPLEFT", AbandonHint, "BOTTOMLEFT", 0, -12)
AbandonSelectAllButton:SetText(L("QUEST_ABANDON_SELECT_ALL"))
AbandonSelectAllButton:SetScript("OnClick", function()
    SetAllAbandonSelections(true)
    RefreshAbandonQuestSelectionUI()
end)

AbandonClearAllButton = CreateFrame("Button", nil, AbandonPanel, "UIPanelButtonTemplate")
AbandonClearAllButton:SetSize(130, 24)
AbandonClearAllButton:SetPoint("LEFT", AbandonSelectAllButton, "RIGHT", 10, 0)
AbandonClearAllButton:SetText(L("QUEST_ABANDON_CLEAR_ALL"))
AbandonClearAllButton:SetScript("OnClick", function()
    SetAllAbandonSelections(false)
    RefreshAbandonQuestSelectionUI()
end)

AbandonStatusText = AbandonPanel:CreateFontString(nil, "OVERLAY")
AbandonStatusText:SetPoint("LEFT", AbandonClearAllButton, "RIGHT", 14, 0)
AbandonStatusText:SetPoint("RIGHT", AbandonPanel, "RIGHT", -18, 0)
AbandonStatusText:SetJustifyH("LEFT")
AbandonStatusText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
AbandonStatusText:SetTextColor(1, 0.88, 0.62, 1)
AbandonStatusText:SetText("")

local AbandonListContainer = CreateFrame("Frame", nil, AbandonPanel)
AbandonListContainer:SetPoint("TOPLEFT", AbandonSelectAllButton, "BOTTOMLEFT", 0, -12)
AbandonListContainer:SetPoint("TOPRIGHT", AbandonPanel, "TOPRIGHT", -18, -92)
AbandonListContainer:SetPoint("BOTTOMLEFT", AbandonPanel, "BOTTOMLEFT", 18, 52)

local AbandonListBg = AbandonListContainer:CreateTexture(nil, "BACKGROUND")
AbandonListBg:SetAllPoints()
AbandonListBg:SetColorTexture(0.06, 0.06, 0.06, 0.92)

AbandonScrollFrame = CreateFrame("ScrollFrame", nil, AbandonListContainer, "UIPanelScrollFrameTemplate")
AbandonScrollFrame:SetPoint("TOPLEFT", AbandonListContainer, "TOPLEFT", 8, -8)
AbandonScrollFrame:SetPoint("BOTTOMRIGHT", AbandonListContainer, "BOTTOMRIGHT", -28, 8)
AbandonScrollFrame:EnableMouseWheel(true)

AbandonScrollContent = CreateFrame("Frame", nil, AbandonScrollFrame)
AbandonScrollContent:SetSize(1, 1)
AbandonScrollFrame:SetScrollChild(AbandonScrollContent)

AbandonScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = ABANDON_ROW_HEIGHT
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, AbandonScrollContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

AbandonSelectedButton = CreateFrame("Button", nil, AbandonPanel, "UIPanelButtonTemplate")
AbandonSelectedButton:SetSize(170, 28)
AbandonSelectedButton:SetPoint("BOTTOMLEFT", AbandonPanel, "BOTTOMLEFT", 18, 16)
AbandonSelectedButton:SetText(L("QUEST_ABANDON_SELECTED"))
AbandonSelectedButton:SetScript("OnClick", ConfirmAbandonSelectedQuests)

local function ApplyQuestAbandonLayout()
    IntroPanel:SetShown(not isQuickViewMode)
    AbandonTitle:SetShown(not isQuickViewMode)
    AbandonHint:SetShown(not isQuickViewMode)

    AbandonPanel:ClearAllPoints()
    if isQuickViewMode then
        AbandonPanel:SetPoint("TOPLEFT", PageQuestAbandon, "TOPLEFT", 20, -20)
        AbandonPanel:SetPoint("TOPRIGHT", PageQuestAbandon, "TOPRIGHT", -20, -20)
    else
        AbandonPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
        AbandonPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
    end
    AbandonPanel:SetPoint("BOTTOMRIGHT", PageQuestAbandon, "BOTTOMRIGHT", -20, 8)

    AbandonSelectAllButton:ClearAllPoints()
    if isQuickViewMode then
        AbandonSelectAllButton:SetPoint("TOPLEFT", AbandonPanel, "TOPLEFT", 18, -16)
    else
        AbandonSelectAllButton:SetPoint("TOPLEFT", AbandonHint, "BOTTOMLEFT", 0, -12)
    end

    AbandonClearAllButton:ClearAllPoints()
    AbandonClearAllButton:SetPoint("LEFT", AbandonSelectAllButton, "RIGHT", 10, 0)

    AbandonStatusText:ClearAllPoints()
    AbandonStatusText:SetPoint("LEFT", AbandonClearAllButton, "RIGHT", 14, 0)
    AbandonStatusText:SetPoint("RIGHT", AbandonPanel, "RIGHT", -18, 0)

    AbandonListContainer:ClearAllPoints()
    AbandonListContainer:SetPoint("TOPLEFT", AbandonSelectAllButton, "BOTTOMLEFT", 0, -12)
    AbandonListContainer:SetPoint("TOPRIGHT", AbandonPanel, "TOPRIGHT", -18, isQuickViewMode and -52 or -92)
    AbandonListContainer:SetPoint("BOTTOMLEFT", AbandonPanel, "BOTTOMLEFT", 18, 52)
end

BeavisQoL.UpdateQuestAbandon = function()
    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("QuestAbandon", L("QUEST_ABANDON_TITLE")))
    IntroText:SetText(L("QUEST_ABANDON_DESC"))
    QuestAbandonMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    QuestAbandonMinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))
    QuestAbandonMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("questAbandon") or true)
    AbandonTitle:SetText(L("QUEST_ABANDON_LIST_TITLE"))
    AbandonHint:SetText(L("QUEST_ABANDON_DESC"))
    AbandonSelectAllButton:SetText(L("QUEST_ABANDON_SELECT_ALL"))
    AbandonClearAllButton:SetText(L("QUEST_ABANDON_CLEAR_ALL"))
    AbandonSelectedButton:SetText(L("QUEST_ABANDON_SELECTED"))
    RefreshAbandonQuestSelectionUI()
end

function PageQuestAbandon:SetQuickViewMode(enabled)
    isQuickViewMode = enabled == true
    ApplyQuestAbandonLayout()
    RefreshAbandonQuestSelectionUI()
end

PageQuestAbandon:SetScript("OnShow", function()
    QuestAbandonMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("questAbandon") or true)
    ApplyQuestAbandonLayout()
    RefreshAbandonQuestSelectionUI()
end)

local QuestAbandonWatcher = CreateFrame("Frame")
QuestAbandonWatcher:RegisterEvent("PLAYER_LOGIN")
QuestAbandonWatcher:RegisterEvent("QUEST_LOG_UPDATE")
QuestAbandonWatcher:SetScript("OnEvent", function()
    RefreshAbandonQuestSelectionUI()
end)

ApplyQuestAbandonLayout()

BeavisQoL.Pages.QuestAbandon = PageQuestAbandon
