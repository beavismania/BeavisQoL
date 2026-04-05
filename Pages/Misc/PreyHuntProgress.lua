local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local GetActivePreyQuest = C_QuestLog and C_QuestLog.GetActivePreyQuest
local GetLogIndexForQuestID = C_QuestLog and C_QuestLog.GetLogIndexForQuestID
local GetAllWidgetsBySetID = C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID
local GetStatusBarWidgetVisualizationInfo = C_UIWidgetManager and C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo
local GetPreyHuntProgressWidgetVisualizationInfo = C_UIWidgetManager and C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo
local GetNumQuestLeaderBoards = rawget(_G, "GetNumQuestLeaderBoards")
local GetQuestObjectiveInfo = rawget(_G, "GetQuestObjectiveInfo")
local GetQuestProgressBarPercent = rawget(_G, "GetQuestProgressBarPercent")

local PREY_UPDATE_INTERVAL = 0.25
local PREY_HUNT_WIDGET_TYPE = (Enum and Enum.UIWidgetVisualizationType and Enum.UIWidgetVisualizationType.PreyHuntProgress) or 31
-- Stand 12.0.1 nutzt Blizzard für die Jagd-Widgets dieses Set.
-- Die Suche läuft trotzdem erst dynamisch über registrierte Container
-- und fällt nur im Zweifel auf diese bekannte ID zurück.
local KNOWN_PREY_WIDGET_SET_ID = 1843
local PREY_STAGE_PERCENT = {
    [0] = 0,
    [1] = 34,
    [2] = 67,
    [3] = 100,
}

local baseGetMiscDB = Misc.GetMiscDB
local watcherActive = false
local cachedWidgetSetID = nil
local livePreyWidgetID = nil
local livePreyWidgetSetID = nil

local PreyHuntOverlay = CreateFrame("Frame", "BeavisQoLPreyHuntProgressOverlay", UIParent)
PreyHuntOverlay:SetSize(40, 16)
PreyHuntOverlay:SetFrameStrata("MEDIUM")
PreyHuntOverlay:SetFrameLevel(1)
PreyHuntOverlay:SetClampedToScreen(true)
PreyHuntOverlay:EnableMouse(false)
PreyHuntOverlay:Hide()

local PreyHuntOverlayBg = PreyHuntOverlay:CreateTexture(nil, "BACKGROUND")
PreyHuntOverlayBg:SetAllPoints()
PreyHuntOverlayBg:SetColorTexture(0, 0, 0, 0.55)

local PreyHuntOverlayText = PreyHuntOverlay:CreateFontString(nil, "OVERLAY")
PreyHuntOverlayText:SetPoint("CENTER", PreyHuntOverlay, "CENTER", 0, 0)
PreyHuntOverlayText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
PreyHuntOverlayText:SetTextColor(1, 0.82, 0, 1)
PreyHuntOverlayText:SetJustifyH("CENTER")
PreyHuntOverlayText:SetJustifyV("MIDDLE")

local function GetWidgetManager()
    return rawget(_G, "UIWidgetManager")
end

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc

    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

function Misc.GetMiscDB()
    local db

    if baseGetMiscDB then
        db = baseGetMiscDB()
    else
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.preyHuntProgress == nil then
        db.preyHuntProgress = false
    end

    return db
end

function Misc.IsPreyHuntProgressEnabled()
    return Misc.GetMiscDB().preyHuntProgress == true
end

local function HidePreyHuntOverlay()
    if PreyHuntOverlay:GetParent() ~= UIParent then
        PreyHuntOverlay:SetParent(UIParent)
    end

    PreyHuntOverlay:Hide()
end

local function ClearPreyHuntCache()
    cachedWidgetSetID = nil
    livePreyWidgetID = nil
    livePreyWidgetSetID = nil
end

local function SafeIsFrameShown(frame)
    if not frame or not frame.IsShown then
        return false
    end

    local ok, isShown = pcall(frame.IsShown, frame)
    if not ok then
        return false
    end

    return isShown == true
end

local function SyncOverlayFrameOrder(anchorFrame)
    if not anchorFrame then
        if PreyHuntOverlay:GetParent() ~= UIParent then
            PreyHuntOverlay:SetParent(UIParent)
        end

        PreyHuntOverlay:SetFrameStrata("MEDIUM")
        PreyHuntOverlay:SetFrameLevel(1)
        return
    end

    if PreyHuntOverlay:GetParent() ~= anchorFrame then
        PreyHuntOverlay:SetParent(anchorFrame)
    end

    if anchorFrame.GetFrameStrata then
        PreyHuntOverlay:SetFrameStrata(anchorFrame:GetFrameStrata())
    end

    local anchorFrameLevel = anchorFrame.GetFrameLevel and anchorFrame:GetFrameLevel() or 0
    PreyHuntOverlay:SetFrameLevel(math.max(0, anchorFrameLevel + 5))
end

local function GetOverlayColorForProgressState(progressState)
    if progressState == 0 then
        return 0.62, 0.82, 1.00
    end

    if progressState == 1 then
        return 1.00, 0.86, 0.18
    end

    if progressState == 2 then
        return 1.00, 0.56, 0.16
    end

    if progressState == 3 then
        return 1.00, 0.30, 0.30
    end

    return 1.00, 0.82, 0.00
end

local function GetProgressPercentFromStage(progressState)
    if progressState == nil then
        return nil
    end

    return PREY_STAGE_PERCENT[progressState]
end

local function GetStageIndexFromProgress(progressState, progressPercent)
    if progressState ~= nil then
        return math.max(1, math.min(4, progressState + 1))
    end

    local numericPercent = tonumber(progressPercent)
    if not numericPercent then
        return nil
    end

    if numericPercent >= 100 then
        return 4
    end

    if numericPercent >= 67 then
        return 3
    end

    if numericPercent >= 34 then
        return 2
    end

    return 1
end

local function GetStageDisplayText(progressState, progressPercent)
    local stageIndex = GetStageIndexFromProgress(progressState, progressPercent)
    if not stageIndex then
        return nil
    end

    if stageIndex >= 4 then
        return L("PREY_HUNT_STAGE_READY")
    end

    return L("PREY_HUNT_STAGE_FORMAT"):format(stageIndex, 4)
end

local function GetProgressPercentFromWidget(progressInfo)
    if not progressInfo then
        return nil
    end

    local currentValue = tonumber(progressInfo.barValue)
    local maxValue = tonumber(progressInfo.barMax)
    if not currentValue or not maxValue or maxValue <= 0 then
        return nil
    end

    return math.max(0, math.min(100, math.floor(((currentValue / maxValue) * 100) + 0.5)))
end

local function GetQuestProgressPercent(questID)
    if not questID or not GetLogIndexForQuestID or not GetNumQuestLeaderBoards or not GetQuestObjectiveInfo then
        return nil
    end

    local questLogIndex = GetLogIndexForQuestID(questID)
    if not questLogIndex or questLogIndex == 0 then
        return nil
    end

    local totalValue = 0
    local totalMax = 0
    local numObjectives = GetNumQuestLeaderBoards(questLogIndex) or 0

    for objectiveIndex = 1, numObjectives do
        local _, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, objectiveIndex, false)
        fulfilled = tonumber(fulfilled)
        required = tonumber(required)

        if objectiveType == "progressbar" and GetQuestProgressBarPercent then
            local progressPercent = tonumber(GetQuestProgressBarPercent(questID))
            if progressPercent then
                fulfilled = math.max(0, math.min(100, progressPercent)) * 0.01
                required = 1
            end
        end

        if fulfilled and required and required > 0 then
            if fulfilled > required then
                fulfilled = required
            end

            if objectiveType ~= "progressbar" and not finished and fulfilled == required then
                -- Manche Quests liefern direkt bei Annahme 1/1 für nicht
                -- gestartete Teilziele. Das zählt noch nicht als echter Fortschritt.
                fulfilled = 0
            end

            totalValue = totalValue + fulfilled
            totalMax = totalMax + required
        end
    end

    if totalMax <= 0 then
        return nil
    end

    return math.max(0, math.min(100, math.floor(((totalValue / totalMax) * 100) + 0.5)))
end

local function GetFirstVisibleChild(frame)
    if not frame or not frame.GetChildren then
        return nil
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if SafeIsFrameShown(child) then
            return child
        end
    end

    return nil
end

local function GetWidgetContainerBySetID(widgetSetID)
    local widgetManager = GetWidgetManager()
    local registeredContainers = widgetManager and widgetManager.registeredWidgetContainers
    if not registeredContainers then
        return nil
    end

    for widgetContainer in pairs(registeredContainers) do
        if widgetContainer and widgetContainer.widgetSetID == widgetSetID then
            return widgetContainer
        end
    end

    return nil
end

local function GetLivePreyWidgetData()
    if not livePreyWidgetID or not livePreyWidgetSetID or not GetPreyHuntProgressWidgetVisualizationInfo then
        return nil
    end

    local preyInfo = GetPreyHuntProgressWidgetVisualizationInfo(livePreyWidgetID)
    if not preyInfo or preyInfo.shownState ~= 1 then
        return nil
    end

    return {
        widgetSetID = livePreyWidgetSetID,
        anchorWidgetID = livePreyWidgetID,
        progressWidgetID = nil,
        preyInfo = preyInfo,
        progressInfo = nil,
    }
end

local function GetPreyWidgetDataForSet(widgetSetID)
    if not widgetSetID or not GetAllWidgetsBySetID then
        return nil
    end

    local widgets = GetAllWidgetsBySetID(widgetSetID)
    if not widgets then
        return nil
    end

    local preyInfo
    local anchorWidgetID
    local progressInfo
    local progressWidgetID

    for _, widget in ipairs(widgets) do
        if not preyInfo and GetPreyHuntProgressWidgetVisualizationInfo then
            local currentPreyInfo = GetPreyHuntProgressWidgetVisualizationInfo(widget.widgetID)
            if currentPreyInfo and currentPreyInfo.shownState == 1 then
                preyInfo = currentPreyInfo
                anchorWidgetID = widget.widgetID
            end
        end

        if not progressInfo and GetStatusBarWidgetVisualizationInfo then
            local currentProgressInfo = GetStatusBarWidgetVisualizationInfo(widget.widgetID)
            local maxValue = currentProgressInfo and tonumber(currentProgressInfo.barMax)
            if currentProgressInfo
                and currentProgressInfo.shownState == 1
                and maxValue
                and maxValue > 0
                and currentProgressInfo.barValue ~= nil then
                progressInfo = currentProgressInfo
                progressWidgetID = widget.widgetID
            end
        end

        if preyInfo and progressInfo then
            break
        end
    end

    if not preyInfo then
        -- Ohne echtes Prey-Hunt-Widget wuerden normale Statusleisten
        -- faelschlich als "Phase 1/4" interpretiert werden.
        return nil
    end

    return {
        widgetSetID = widgetSetID,
        anchorWidgetID = anchorWidgetID,
        progressWidgetID = progressWidgetID,
        preyInfo = preyInfo,
        progressInfo = progressInfo,
    }
end

local function FindActivePreyWidgetData()
    local liveWidgetData = GetLivePreyWidgetData()
    if liveWidgetData then
        return liveWidgetData
    end

    if cachedWidgetSetID then
        local cachedData = GetPreyWidgetDataForSet(cachedWidgetSetID)
        if cachedData then
            return cachedData
        end
    end

    local widgetManager = GetWidgetManager()
    local registeredContainers = widgetManager and widgetManager.registeredWidgetContainers
    if registeredContainers then
        for widgetContainer in pairs(registeredContainers) do
            local widgetSetID = widgetContainer and widgetContainer.widgetSetID
            if widgetSetID and widgetSetID ~= 0 and widgetSetID ~= cachedWidgetSetID then
                local widgetData = GetPreyWidgetDataForSet(widgetSetID)
                if widgetData then
                    return widgetData
                end
            end
        end
    end

    if KNOWN_PREY_WIDGET_SET_ID ~= cachedWidgetSetID then
        return GetPreyWidgetDataForSet(KNOWN_PREY_WIDGET_SET_ID)
    end

    return nil
end

local function ResolvePreyOverlayAnchor(widgetData)
    if widgetData then
        local widgetContainer = GetWidgetContainerBySetID(widgetData.widgetSetID)
        if widgetContainer and widgetContainer.widgetFrames then
            local anchorFrame = widgetContainer.widgetFrames[widgetData.anchorWidgetID]
                or (widgetData.progressWidgetID and widgetContainer.widgetFrames[widgetData.progressWidgetID])
            if anchorFrame then
                return anchorFrame
            end
        end

        if widgetContainer then
            local visibleChild = GetFirstVisibleChild(widgetContainer)
            if visibleChild then
                return visibleChild
            end

            return widgetContainer
        end
    end

    local fallbackFrame = _G.UIWidgetBelowMinimapContainerFrame
    if fallbackFrame then
        local visibleChild = GetFirstVisibleChild(fallbackFrame)
        if visibleChild then
            return visibleChild
        end

        if SafeIsFrameShown(fallbackFrame) then
            return fallbackFrame
        end
    end

    fallbackFrame = _G.UIWidgetTopCenterContainerFrame
    if fallbackFrame then
        local visibleChild = GetFirstVisibleChild(fallbackFrame)
        if visibleChild then
            return visibleChild
        end

        if SafeIsFrameShown(fallbackFrame) then
            return fallbackFrame
        end
    end

    return _G.UIWidgetBelowMinimapContainerFrame or _G.UIWidgetTopCenterContainerFrame
end

local function UpdatePreyHuntOverlay()
    if not Misc.IsPreyHuntProgressEnabled() then
        HidePreyHuntOverlay()
        return
    end

    local inInstance = IsInInstance and select(1, IsInInstance())
    if inInstance then
        HidePreyHuntOverlay()
        ClearPreyHuntCache()
        return
    end

    local activeQuestID = GetActivePreyQuest and GetActivePreyQuest()
    local widgetData = FindActivePreyWidgetData()
    if not activeQuestID and not widgetData then
        HidePreyHuntOverlay()
        ClearPreyHuntCache()
        return
    end

    local anchorFrame = ResolvePreyOverlayAnchor(widgetData)
    -- Die eigentliche Jagd-Anzeige soll sich am Blizzard-Prey-Widget
    -- orientieren. Questziele zaehlen oft den Endboss noch mit und zeigen
    -- dadurch am Bossstein irrefuehrend nur 50%.
    local progressValue = (widgetData and widgetData.preyInfo and GetProgressPercentFromStage(widgetData.preyInfo.progressState))
        or (widgetData and GetProgressPercentFromWidget(widgetData.progressInfo))
        or (activeQuestID and GetQuestProgressPercent(activeQuestID))
    local displayText = GetStageDisplayText(widgetData and widgetData.preyInfo and widgetData.preyInfo.progressState, progressValue)
    if not anchorFrame or not displayText then
        HidePreyHuntOverlay()
        return
    end

    if anchorFrame and anchorFrame.IsShown and not SafeIsFrameShown(anchorFrame) then
        local fallbackFrame = (widgetData and GetWidgetContainerBySetID(widgetData.widgetSetID))
            or _G.UIWidgetBelowMinimapContainerFrame
            or _G.UIWidgetTopCenterContainerFrame
        if not fallbackFrame or not SafeIsFrameShown(fallbackFrame) then
            HidePreyHuntOverlay()
            return
        end

        anchorFrame = fallbackFrame
    end

    cachedWidgetSetID = widgetData and widgetData.widgetSetID or cachedWidgetSetID

    local red, green, blue = GetOverlayColorForProgressState(widgetData and widgetData.preyInfo and widgetData.preyInfo.progressState)
    SyncOverlayFrameOrder(anchorFrame)
    PreyHuntOverlayText:SetText(displayText)
    PreyHuntOverlayText:SetTextColor(red, green, blue, 1)

    local textWidth = PreyHuntOverlayText:GetUnboundedStringWidth() or 0
    PreyHuntOverlay:SetWidth(math.max(42, math.floor(textWidth + 12)))
    PreyHuntOverlay:ClearAllPoints()
    -- Das Jagd-Symbol sitzt oft sehr weit unten im Bild.
    -- Darum platzieren wir die Zahl oberhalb statt darunter.
    PreyHuntOverlay:SetPoint("BOTTOM", anchorFrame, "TOP", 0, 4)
    PreyHuntOverlay:Show()
end

local PreyHuntWatcher = CreateFrame("Frame")
PreyHuntWatcher.elapsed = 0
PreyHuntWatcher.needsRefresh = false

PreyHuntWatcher:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LEAVING_WORLD" then
        HidePreyHuntOverlay()
        self.needsRefresh = false
        ClearPreyHuntCache()
        return
    end

    if event == "UPDATE_UI_WIDGET" then
        local widgetInfo = ...
        if widgetInfo and widgetInfo.widgetType == PREY_HUNT_WIDGET_TYPE and GetPreyHuntProgressWidgetVisualizationInfo then
            local preyInfo = GetPreyHuntProgressWidgetVisualizationInfo(widgetInfo.widgetID)
            if preyInfo and preyInfo.shownState == 1 then
                livePreyWidgetID = widgetInfo.widgetID
                livePreyWidgetSetID = widgetInfo.widgetSetID
                cachedWidgetSetID = widgetInfo.widgetSetID or cachedWidgetSetID
            elseif livePreyWidgetID == widgetInfo.widgetID then
                livePreyWidgetID = nil
                livePreyWidgetSetID = nil
            end
        end
    end

    self.needsRefresh = true
end)

local function PreyHuntWatcherOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < PREY_UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self.needsRefresh = false
    UpdatePreyHuntOverlay()
end

local function UpdateWatcherState()
    if Misc.IsPreyHuntProgressEnabled() then
        if not watcherActive then
            watcherActive = true
            PreyHuntWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
            PreyHuntWatcher:RegisterEvent("PLAYER_LEAVING_WORLD")
            PreyHuntWatcher:RegisterEvent("QUEST_LOG_UPDATE")
            PreyHuntWatcher:RegisterEvent("ZONE_CHANGED")
            PreyHuntWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
            PreyHuntWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
            PreyHuntWatcher:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
            PreyHuntWatcher:RegisterEvent("UPDATE_UI_WIDGET")
            PreyHuntWatcher.elapsed = PREY_UPDATE_INTERVAL
            PreyHuntWatcher.needsRefresh = true
            PreyHuntWatcher:SetScript("OnUpdate", PreyHuntWatcherOnUpdate)
        else
            PreyHuntWatcher.needsRefresh = true
        end

        UpdatePreyHuntOverlay()
        return
    end

    watcherActive = false
    ClearPreyHuntCache()
    PreyHuntWatcher.elapsed = 0
    PreyHuntWatcher.needsRefresh = false
    PreyHuntWatcher:UnregisterAllEvents()
    PreyHuntWatcher:SetScript("OnUpdate", nil)
    HidePreyHuntOverlay()
end

local function ReinitializeEnabledWatcher()
    if not Misc.IsPreyHuntProgressEnabled() then
        return
    end

    watcherActive = false
    ClearPreyHuntCache()
    PreyHuntWatcher.elapsed = 0
    PreyHuntWatcher.needsRefresh = true
    PreyHuntWatcher:UnregisterAllEvents()
    PreyHuntWatcher:SetScript("OnUpdate", nil)

    UpdateWatcherState()
end

function Misc.SetPreyHuntProgressEnabled(value)
    Misc.GetMiscDB().preyHuntProgress = value == true
    UpdateWatcherState()
    RefreshMiscPageState()
end

local PreyHuntBootstrap = CreateFrame("Frame")
PreyHuntBootstrap:RegisterEvent("PLAYER_LOGIN")
PreyHuntBootstrap:RegisterEvent("PLAYER_ENTERING_WORLD")
PreyHuntBootstrap:SetScript("OnEvent", function()
    ReinitializeEnabledWatcher()

    if C_Timer and C_Timer.After and Misc.IsPreyHuntProgressEnabled() then
        C_Timer.After(0, ReinitializeEnabledWatcher)
        C_Timer.After(1, ReinitializeEnabledWatcher)
    end
end)

UpdateWatcherState()
