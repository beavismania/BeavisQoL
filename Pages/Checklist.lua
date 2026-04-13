local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.Checklist = BeavisQoL.Checklist or {}
local Checklist = BeavisQoL.Checklist

--[[
Checklist.lua ist gleichzeitig Datenmodell, Tracker und Modulseite.

Die Datei vereint:
1. feste Aufgaben des Addons
2. manuelle Aufgaben pro Charakter
3. Reset-Logik für Daily und Weekly
4. das kleine Tracker-Fenster außerhalb des Hauptfensters
5. die große Checklisten-Seite im Addon

Wenn du die Datei lesen willst, geh am besten so vor:
Konstanten -> SavedVariables -> Aufgabenlogik -> Tracker -> Hauptseiten-UI -> Events.
]]

local BUILT_IN_TODOS = {
    { id = "weekly_vault", labelKey = "CHECKLIST_TODO_WEEKLY_VAULT", cadence = "weekly" },
    { id = "weekly_raid", labelKey = "CHECKLIST_TODO_WEEKLY_RAID", cadence = "weekly" },
    { id = "weekly_pvp_quests", labelKey = "CHECKLIST_TODO_WEEKLY_PVP_QUESTS", cadence = "weekly" },
    { id = "weekly_hunts", labelKey = "CHECKLIST_TODO_WEEKLY_HUNTS", cadence = "weekly" },
    { id = "weekly_optional_hunts", labelKey = "CHECKLIST_TODO_WEEKLY_OPTIONAL_HUNTS", cadence = "weekly" },
    { id = "weekly_soiree", labelKey = "CHECKLIST_TODO_WEEKLY_SOIREE", cadence = "weekly" },
    { id = "weekly_overflow", labelKey = "CHECKLIST_TODO_WEEKLY_OVERFLOW", cadence = "weekly" },
    { id = "weekly_stormarion", labelKey = "CHECKLIST_TODO_WEEKLY_STORMARION", cadence = "weekly" },
    { id = "weekly_harandir", labelKey = "CHECKLIST_TODO_WEEKLY_HARANDIR", cadence = "weekly" },
    { id = "weekly_housing_quest", labelKey = "CHECKLIST_TODO_WEEKLY_HOUSING_QUEST", cadence = "weekly" },
    { id = "weekly_voidstorm", labelKey = "CHECKLIST_TODO_WEEKLY_VOIDSTORM", cadence = "weekly" },
    { id = "weekly_delve_progress", labelKey = "CHECKLIST_TODO_WEEKLY_DELVE_PROGRESS", cadence = "weekly" },
    { id = "weekly_delve_hero_map", labelKey = "CHECKLIST_TODO_WEEKLY_DELVE_HERO_MAP", cadence = "weekly" },
    { id = "daily_delves", labelKey = "CHECKLIST_TODO_DAILY_DELVES", cadence = "daily" },
    { id = "daily_worldquests", labelKey = "CHECKLIST_TODO_DAILY_WORLDQUESTS", cadence = "daily" },
    { id = "daily_harandir", labelKey = "CHECKLIST_TODO_DAILY_HARANDIR", cadence = "daily" },
    { id = "watch_tier_set", labelKey = "CHECKLIST_TODO_WATCH_TIER", cadence = "watch" },
}

local REMOVED_BUILT_IN_TODO_IDS = {
    daily_m0_tour = true,
}

local DEFAULT_TRACKER_WIDTH = 300
local DEFAULT_TRACKER_HEIGHT = 250
local COLLAPSED_TRACKER_HEIGHT = 30
local MIN_TRACKER_WIDTH = 220
local MIN_TRACKER_HEIGHT = 160
local MAX_TRACKER_WIDTH = 520
local MAX_TRACKER_HEIGHT = 520

local PageChecklist
local TrackerFrame
local TrackerScrollFrame
local TrackerContent
local TrackerTitle
local TrackerBuiltInHeader
local TrackerManualHeader
local TrackerWatchHeader
local TrackerEmptyText
local TrackerLockButton
local TrackerCollapseButton
local TrackerVaultButton
local TrackerHeaderBorder
local TrackerResizeHandle
local TrackerAddPopup
local TrackerAddPopupInputBox
local TrackerAddPopupCadenceDailyButton
local TrackerAddPopupCadenceWeeklyButton
local TrackerAddPopupCadenceWatchButton
local UpdateTrackerLockState
local UpdateTrackerLockButtonVisual
local UpdateTrackerCollapsedState
local UpdateTrackerAddPopupCadenceButtons
local OpenChecklistSettingsSection
local OpenTrackerAddPopup
local CloseTrackerAddPopup

local DailyRows = {}
local WeeklyRows = {}
local WatchRows = {}
local TrackerBuiltInRows = {}
local TrackerManualRows = {}
local TrackerWatchRows = {}

local ManualInputBox
local IntroSummaryValue
local DailyEmptyText
local WeeklyEmptyText
local WatchEmptyText
local ManualCadenceDailyButton
local ManualCadenceWeeklyButton
local ManualCadenceWatchButton

local TrackerEnabledCheckbox
local TrackerShowBuiltInCheckbox
local TrackerShowManualCheckbox
local TrackerHideCompletedCheckbox
local TrackerMinimapContextCheckbox

local FontSizeSlider
local BackgroundAlphaSlider
local isRefreshing = false
local sliderCounter = 0
local selectedManualCadence = "daily"
local selectedTrackerPopupCadence = "daily"
local CHECKLIST_TRACKER_VISIBILITY_INTERVAL = 0.20
local CHECKLIST_RESET_INTERVAL = 30

local function TrimText(text)
    if type(text) ~= "string" then
        return nil
    end

    local trimmed = string.match(text, "^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function Clamp(value, minValue, maxValue)
    -- Schützt Fenstergrößen, Slider und gespeicherte Werte vor Ausreißern.
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function RoundToNearestInteger(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end

    return math.ceil(value - 0.5)
end

local function GetTrackerVerticalAnchorFactor(anchorPoint)
    local pointText = tostring(anchorPoint or "")

    if string.find(pointText, "TOP", 1, true) then
        return 0
    end

    if string.find(pointText, "BOTTOM", 1, true) then
        return 1
    end

    return 0.5
end

local function NormalizeCadence(cadence)
    if cadence == "weekly" then
        return "weekly"
    end

    if cadence == "watch" then
        return "watch"
    end

    return "daily"
end

local function NormalizeManualCadence(cadence)
    if cadence == "weekly" then
        return "weekly"
    end

    if cadence == "watch" then
        return "watch"
    end

    return "daily"
end

local function GetManualCadenceLabel(cadence)
    if cadence == "weekly" then
        return L("WEEKLY")
    end

    if cadence == "watch" then
        return L("CHECKLIST_WATCH_SHORT")
    end

    return L("DAILY")
end

local function GetNextManualCadence(cadence)
    if cadence == "daily" then
        return "weekly"
    end

    if cadence == "weekly" then
        return "watch"
    end

    return "daily"
end

local function GetPrimaryProfessionEntries()
    local professionEntries = {}

    if not GetProfessions or not GetProfessionInfo then
        return professionEntries
    end

    local profession1, profession2 = GetProfessions()

    local function AddProfession(professionIndex)
        if not professionIndex then
            return
        end

        local professionName, _, _, _, _, _, skillLine = GetProfessionInfo(professionIndex)
        if type(professionName) ~= "string" or professionName == "" then
            return
        end

        professionEntries[#professionEntries + 1] = {
            name = professionName,
            skillLine = tonumber(skillLine) or (#professionEntries + 1),
        }
    end

    AddProfession(profession1)
    AddProfession(profession2)

    return professionEntries
end

local function GetBuiltInTodos()
    -- Die feste Starterliste wird beim Lesen noch um die beiden
    -- charakterbezogenen Berufsaufgaben erweitert.
    local builtInTodos = {}

    for _, todo in ipairs(BUILT_IN_TODOS) do
        builtInTodos[#builtInTodos + 1] = {
            id = todo.id,
            label = L(todo.labelKey),
            cadence = todo.cadence,
        }
    end

    for _, profession in ipairs(GetPrimaryProfessionEntries()) do
        builtInTodos[#builtInTodos + 1] = {
            id = "weekly_profession_" .. tostring(profession.skillLine),
            label = L("CHECKLIST_TODO_WEEKLY_PROFESSION"):format(profession.name),
            cadence = "weekly",
        }
    end

    return builtInTodos
end

local function GetBuiltInTodoByID(todoID)
    for _, todo in ipairs(GetBuiltInTodos()) do
        if todo.id == todoID then
            return todo
        end
    end

    return nil
end

local function GetChecklistSettings()
    -- Accountweite Einstellungen für das Tracker-Fenster:
    -- Sichtbarkeit, Optik, Position, Größe und Verhalten.
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.checklist = BeavisQoLDB.checklist or {}

    local db = BeavisQoLDB.checklist

    if db.trackerEnabled == nil then
        db.trackerEnabled = false
    end

    if db.showBuiltInInTracker == nil then
        db.showBuiltInInTracker = true
    end

    if db.showManualInTracker == nil then
        db.showManualInTracker = true
    end

    if db.hideCompletedInTracker == nil then
        db.hideCompletedInTracker = false
    end

    if db.trackerLocked == nil then
        db.trackerLocked = false
    end

    if db.trackerCollapsed == nil then
        db.trackerCollapsed = false
    end

    if type(db.fontSize) ~= "number" then
        db.fontSize = 11
    end
    db.fontSize = Clamp(math.floor(db.fontSize + 0.5), 10, 16)

    if type(db.backgroundAlpha) ~= "number" then
        db.backgroundAlpha = 0.34
    end
    db.backgroundAlpha = Clamp(db.backgroundAlpha, 0.15, 0.70)

    if type(db.trackerWidth) ~= "number" then
        db.trackerWidth = DEFAULT_TRACKER_WIDTH
    end
    db.trackerWidth = Clamp(math.floor(db.trackerWidth + 0.5), MIN_TRACKER_WIDTH, MAX_TRACKER_WIDTH)

    if type(db.trackerHeight) ~= "number" then
        db.trackerHeight = DEFAULT_TRACKER_HEIGHT
    end
    db.trackerHeight = Clamp(math.floor(db.trackerHeight + 0.5), MIN_TRACKER_HEIGHT, MAX_TRACKER_HEIGHT)

    if type(db.trackerPoint) ~= "string" or db.trackerPoint == "" then
        db.trackerPoint = "BOTTOMRIGHT"
    end

    if type(db.trackerRelativePoint) ~= "string" or db.trackerRelativePoint == "" then
        db.trackerRelativePoint = "BOTTOMRIGHT"
    end

    if type(db.trackerOffsetX) ~= "number" then
        db.trackerOffsetX = -70
    end

    if type(db.trackerOffsetY) ~= "number" then
        db.trackerOffsetY = 180
    end

    return db
end

local function ShouldHideTrackerInCombat()
    return BeavisQoL.ShouldHideOverlay
        and BeavisQoL.ShouldHideOverlay("checklist")
end

local function GetChecklistCharacterData()
    -- Charakterdaten für die eigentliche Checkliste:
    -- Haken, manuelle Aufgaben, deaktivierte Standardaufgaben und Reset-Zeiten.
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.checklist = BeavisQoLCharDB.checklist or {}

    local db = BeavisQoLCharDB.checklist

    if type(db.builtInState) ~= "table" then
        db.builtInState = {}
    end

    if type(db.manualItems) ~= "table" then
        db.manualItems = {}
    end

    if type(db.disabledBuiltIns) ~= "table" then
        db.disabledBuiltIns = {}
    end

    for todoID in pairs(REMOVED_BUILT_IN_TODO_IDS) do
        db.builtInState[todoID] = nil
        db.disabledBuiltIns[todoID] = nil
    end

    if type(db.nextDailyResetAt) ~= "number" then
        db.nextDailyResetAt = 0
    end

    if type(db.nextWeeklyResetAt) ~= "number" then
        db.nextWeeklyResetAt = 0
    end

    -- Vorhandene manuelle Einträge werden bewusst bereinigt, damit alte oder
    -- kaputte SavedVariables später keine Layout- oder nil-Probleme erzeugen.
    local sanitizedManualItems = {}
    local usedIDs = {}
    local nextManualID = 1

    for _, item in ipairs(db.manualItems) do
        if type(item) == "table" then
            local itemText = TrimText(item.text)
            local itemID = tonumber(item.id)

            if itemText and itemID and itemID > 0 and not usedIDs[itemID] then
                local cleanItem = {
                    id = itemID,
                    text = string.sub(itemText, 1, 120),
                    checked = item.checked == true,
                    cadence = NormalizeManualCadence(item.cadence),
                }

                sanitizedManualItems[#sanitizedManualItems + 1] = cleanItem
                usedIDs[itemID] = true

                if itemID >= nextManualID then
                    nextManualID = itemID + 1
                end
            end
        end
    end

    db.manualItems = sanitizedManualItems

    if type(db.nextManualID) ~= "number" or db.nextManualID < nextManualID then
        db.nextManualID = nextManualID
    end

    return db
end

local function GetBuiltInTodoState(todoID)
    local db = GetChecklistCharacterData()
    return db.builtInState[todoID] == true
end

local function IsBuiltInTodoEnabled(todoID)
    local db = GetChecklistCharacterData()
    return db.disabledBuiltIns[todoID] ~= true
end

local function SetBuiltInTodoState(todoID, checked)
    local db = GetChecklistCharacterData()
    db.builtInState[todoID] = checked == true
end

local function SetBuiltInTodoEnabled(todoID, enabled)
    local db = GetChecklistCharacterData()

    if enabled then
        db.disabledBuiltIns[todoID] = nil
    else
        db.disabledBuiltIns[todoID] = true
        db.builtInState[todoID] = nil
    end
end

local function GetManualItems()
    local db = GetChecklistCharacterData()
    return db.manualItems
end

local function IsProfessionWeeklyTodoID(todoID)
    return type(todoID) == "string"
        and string.match(todoID, "^weekly_profession_%d+$") ~= nil
end

local function GetTodoCadence(todoID)
    local todo = GetBuiltInTodoByID(todoID)
    if not todo then
        if IsProfessionWeeklyTodoID(todoID) then
            return "weekly"
        end

        return "daily"
    end

    return NormalizeCadence(todo.cadence)
end

local function GetManualItemByID(todoID)
    for _, item in ipairs(GetManualItems()) do
        if item.id == todoID then
            return item
        end
    end

    return nil
end

local function GetManualItemCadence(todoID)
    local item = GetManualItemByID(todoID)
    if not item then
        return "daily"
    end

    return NormalizeManualCadence(item.cadence)
end

local function SetManualItemCadence(todoID, cadence)
    local item = GetManualItemByID(todoID)
    if not item then
        return
    end

    item.cadence = NormalizeManualCadence(cadence)
    item.checked = false
end

local function GetChecklistCounts()
    local totalCount = 0
    local completedCount = 0
    local manualItems = GetManualItems()

    for _, todo in ipairs(GetBuiltInTodos()) do
        if IsBuiltInTodoEnabled(todo.id) then
            totalCount = totalCount + 1

            if GetBuiltInTodoState(todo.id) then
                completedCount = completedCount + 1
            end
        end
    end

    totalCount = totalCount + #manualItems

    for _, item in ipairs(manualItems) do
        if item.checked then
            completedCount = completedCount + 1
        end
    end

    return completedCount, totalCount
end

local function ResetTodosForCadence(cadence)
    -- Nur Daily und Weekly werden automatisch zurückgesetzt.
    -- "Im Blick halten" bleibt immer unangetastet.
    local targetCadence = NormalizeCadence(cadence)
    local db = GetChecklistCharacterData()

    -- Der Reset arbeitet absichtlich auf den gespeicherten Check-Zuständen.
    -- Dynamische Aufgaben wie Berufs-Wochenaufgaben können beim Login kurz
    -- fehlen, wenn der Client die Berufsdaten noch nicht geliefert hat.
    -- Über die gespeicherten IDs gehen diese Aufgaben trotzdem sicher durch
    -- denselben Weekly-Reset wie alle anderen Built-ins.
    for todoID in pairs(db.builtInState) do
        if GetTodoCadence(todoID) == targetCadence then
            db.builtInState[todoID] = nil
        end
    end

    for _, item in ipairs(db.manualItems) do
        if NormalizeManualCadence(item.cadence) == targetCadence then
            item.checked = false
        end
    end
end

local function GetCurrentServerTimestamp()
    if GetServerTime then
        return GetServerTime()
    end

    return time()
end

local function GetNextResetTimestamp(cadence)
    local secondsUntilReset

    if cadence == "weekly" then
        secondsUntilReset = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    else
        secondsUntilReset = C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset and C_DateAndTime.GetSecondsUntilDailyReset()
    end

    if type(secondsUntilReset) ~= "number" then
        return nil
    end

    return GetCurrentServerTimestamp() + math.max(0, secondsUntilReset)
end

local function ProcessChecklistResets()
    -- Prüft, ob einer der gespeicherten Reset-Zeitpunkte erreicht wurde,
    -- führt die nötigen Resets aus und berechnet danach direkt die
    -- nächsten bekannten Reset-Zeitpunkte neu.
    local db = GetChecklistCharacterData()
    local currentServerTime = GetCurrentServerTimestamp()
    local didResetAnything = false

    if db.nextDailyResetAt > 0 and currentServerTime >= db.nextDailyResetAt then
        ResetTodosForCadence("daily")
        didResetAnything = true
    end

    if db.nextWeeklyResetAt > 0 and currentServerTime >= db.nextWeeklyResetAt then
        ResetTodosForCadence("weekly")
        didResetAnything = true
    end

    db.nextDailyResetAt = GetNextResetTimestamp("daily") or db.nextDailyResetAt
    db.nextWeeklyResetAt = GetNextResetTimestamp("weekly") or db.nextWeeklyResetAt

    return didResetAnything
end

local function FormatSliderValue(value, mode)
    if mode == "alpha" then
        return string.format("%d%%", math.floor((value * 100) + 0.5))
    end

    return tostring(math.floor(value + 0.5))
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step, mode)
    sliderCounter = sliderCounter + 1

    local sliderName = "BeavisQoLChecklistSlider" .. sliderCounter
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
    slider.Text:SetTextColor(1, 0.88, 0.62, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(0.95, 0.91, 0.85, 1)

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
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local anchorOffsetX = anchor and anchor.BeavisNextCheckboxOffsetX or -4
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorOffsetX, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    label:SetText(titleText)

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    hint:SetTextColor(0.78, 0.74, 0.69, 1)
    hint:SetText(hintText)
    hint.BeavisNextCheckboxOffsetX = -34
    checkbox.BeavisNextCheckboxOffsetX = 0

    return checkbox, label, hint
end

local function CreateBuiltInTodoRow(parent)
    -- Standardaufgaben haben rechts zusätzlich einen Aktiv-Schalter.
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(24)

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 2)
    row.Checkbox = checkbox

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 6, -7)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    row.Label = label

    local enabledCheckbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    enabledCheckbox:SetScale(0.85)
    row.EnabledCheckbox = enabledCheckbox

    local enabledLabel = row:CreateFontString(nil, "OVERLAY")
    enabledLabel:SetPoint("LEFT", enabledCheckbox, "RIGHT", 3, 0)
    enabledLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    enabledLabel:SetTextColor(0.78, 0.78, 0.78, 1)
        enabledLabel:SetText(L("ACTIVE"))
    row.EnabledLabel = enabledLabel

    local actionButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    actionButton:SetSize(84, 20)
    actionButton:Hide()
    row.ActionButton = actionButton

    local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    deleteButton:SetSize(24, 20)
    deleteButton:SetText("X")
    deleteButton:Hide()
    row.DeleteButton = deleteButton

    return row
end

local function CreatePageTodoRow(parent, includeDeleteButton)
    -- Vereinfachte Aufgabenzeile für die Hauptseite.
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(24)

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 2)
    row.Checkbox = checkbox

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 6, -7)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    row.Label = label

    if includeDeleteButton then
        local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        deleteButton:SetSize(28, 22)
        deleteButton:SetText("X")
        row.DeleteButton = deleteButton
    end

    return row
end

local function GetMeasuredPanelHeight(panel, bottomObject, minimumHeight, bottomPadding)
    local panelTop = panel and panel.GetTop and panel:GetTop()
    local objectBottom = bottomObject and bottomObject.GetBottom and bottomObject:GetBottom()

    if panelTop and objectBottom then
        local measuredHeight = math.ceil(panelTop - objectBottom + (bottomPadding or 0))
        if measuredHeight > 0 then
            return math.max(minimumHeight or 1, measuredHeight)
        end
    end

    return minimumHeight or 1
end

local function GetChecklistPanelContentStartOffset(panel, anchorObject, fallbackOffset, extraGap)
    local panelTop = panel and panel.GetTop and panel:GetTop()
    local anchorBottom = anchorObject and anchorObject.GetBottom and anchorObject:GetBottom()

    if panelTop and anchorBottom then
        local measuredOffset = math.ceil((panelTop - anchorBottom) + (extraGap or 0))
        if measuredOffset > 0 then
            return -measuredOffset
        end
    end

    return fallbackOffset or -72
end

local function CreateTrackerTodoRow(parent)
    -- Kompakte Overlay-Zeile für das kleine Tracker-Fenster.
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(20)

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 2)
    checkbox:SetScale(0.90)
    checkbox:SetScript("OnClick", function(self)
        if self.entryType == "builtin" then
            Checklist.SetBuiltInTodoChecked(self.todoID, self:GetChecked())
        else
            Checklist.SetManualTodoChecked(self.todoID, self:GetChecked())
        end
    end)
    row.Checkbox = checkbox

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 2, -6)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    row.Label = label

    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 0)
    divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(0.88, 0.72, 0.46, 0.16)
    row.Divider = divider

    return row
end

local function SaveTrackerGeometry()
    -- Speichert Position und aktuelle Größe des Trackers.
    if not TrackerFrame then
        return
    end

    local settings = GetChecklistSettings()
    settings.trackerWidth = Clamp(math.floor(TrackerFrame:GetWidth() + 0.5), MIN_TRACKER_WIDTH, MAX_TRACKER_WIDTH)
    if not settings.trackerCollapsed then
        settings.trackerHeight = Clamp(math.floor(TrackerFrame:GetHeight() + 0.5), MIN_TRACKER_HEIGHT, MAX_TRACKER_HEIGHT)
    end

    local point, _, relativePoint, offsetX, offsetY = TrackerFrame:GetPoint(1)
    if point then
        settings.trackerPoint = point
        settings.trackerRelativePoint = relativePoint or point
        settings.trackerOffsetX = math.floor((offsetX or 0) + 0.5)
        settings.trackerOffsetY = math.floor((offsetY or 0) + 0.5)
    end
end

local function ApplyTrackerGeometry()
    -- Wendet die gespeicherten Anchor-Daten gesammelt auf den Tracker an.
    if not TrackerFrame then
        return
    end

    local settings = GetChecklistSettings()
    TrackerFrame:ClearAllPoints()
    TrackerFrame:SetSize(settings.trackerWidth, settings.trackerCollapsed and COLLAPSED_TRACKER_HEIGHT or settings.trackerHeight)
    TrackerFrame:SetPoint(
        settings.trackerPoint,
        UIParent,
        settings.trackerRelativePoint,
        settings.trackerOffsetX,
        settings.trackerOffsetY
    )
end

local function ApplyTrackerStyle()
    -- Hier werden nur Stilfragen des Overlays gepflegt:
    -- Hintergrund, Border und Schriften.
    if not TrackerFrame then
        return
    end

    local settings = GetChecklistSettings()

    TrackerFrame:SetBackdropColor(0.03, 0.03, 0.03, settings.backgroundAlpha)
    TrackerFrame:SetBackdropBorderColor(0.45, 0.45, 0.45, math.min(0.80, settings.backgroundAlpha + 0.20))
    TrackerTitle:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize + 1, "OUTLINE")
    TrackerBuiltInHeader:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize, "OUTLINE")
    TrackerManualHeader:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize, "OUTLINE")
    TrackerWatchHeader:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize, "OUTLINE")
    TrackerEmptyText:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize, "")
end

function Checklist.RefreshTrackerWindow()
    -- Einziger gültiger Renderpfad für das Tracker-Fenster.
    if not TrackerFrame then
        return
    end

    if ProcessChecklistResets() and PageChecklist and PageChecklist:IsShown() then
        PageChecklist:RefreshState()
    end

    local settings = GetChecklistSettings()

    ApplyTrackerStyle()

    if UpdateTrackerLockState then
        UpdateTrackerLockState()
    end

    if not settings.trackerEnabled or ShouldHideTrackerInCombat() then
        TrackerFrame:Hide()
        return
    end

    local completedCount, totalCount = GetChecklistCounts()
    TrackerTitle:SetText(L("CHECKLIST_TRACKER_TITLE"):format(completedCount, totalCount))

    if Checklist.IsTrackerCollapsed() then
        TrackerContent:SetHeight(1)
        TrackerFrame:Show()
        return
    end

    local trackerWidth = math.max(160, TrackerScrollFrame:GetWidth())
    TrackerContent:SetWidth(trackerWidth)

    for _, row in ipairs(TrackerBuiltInRows) do
        row:Hide()
    end

    for _, row in ipairs(TrackerManualRows) do
        row:Hide()
    end

    for _, row in ipairs(TrackerWatchRows) do
        row:Hide()
    end

    TrackerBuiltInHeader:Hide()
    TrackerManualHeader:Hide()
    TrackerWatchHeader:Hide()
    TrackerEmptyText:Hide()

    local currentY = -4
    local sectionOrder = { "watch", "daily", "weekly" }
    local sectionHeaders = {
        daily = TrackerBuiltInHeader,
        weekly = TrackerManualHeader,
        watch = TrackerWatchHeader,
    }
    local sectionTitles = {
        daily = "Daily",
        weekly = "Weekly",
        watch = L("CHECKLIST_WATCH"),
    }
    local sectionRows = {
        daily = TrackerBuiltInRows,
        weekly = TrackerManualRows,
        watch = TrackerWatchRows,
    }
    local sectionIndices = {
        daily = 0,
        weekly = 0,
        watch = 0,
    }
    local sectionCounts = {
        daily = 0,
        weekly = 0,
        watch = 0,
    }

    local function AttachSectionHeader(header, titleText)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", TrackerContent, "TOPLEFT", 6, currentY)
        header:SetText(titleText)
        header:Show()
        currentY = currentY - math.max(18, settings.fontSize + 5)
    end

    local function HasVisibleSectionBefore(targetCategory)
        for _, category in ipairs(sectionOrder) do
            if category == targetCategory then
                return false
            end

            if sectionCounts[category] > 0 then
                return true
            end
        end

        return false
    end

    local function LayoutTrackerRow(row, labelText, checked)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", TrackerContent, "TOPLEFT", 4, currentY)
        row:SetPoint("TOPRIGHT", TrackerContent, "TOPRIGHT", 0, 0)

        row.Label:SetFont("Fonts\\FRIZQT__.TTF", settings.fontSize, "")
        row.Label:SetWidth(math.max(110, trackerWidth - 44))
        row.Label:SetText(labelText)
        row.Checkbox:SetChecked(checked)

        if checked then
            row.Label:SetTextColor(0.72, 0.72, 0.72, 1)
        else
            row.Label:SetTextColor(0.95, 0.91, 0.85, 1)
        end

        local rowHeight = math.max(20, math.ceil(row.Label:GetStringHeight()) + 6)
        row:SetHeight(rowHeight)
        row:Show()

        currentY = currentY - rowHeight - 4
    end

    local function AddTrackerRow(category, entryType, todoID, labelText, checked)
        if sectionCounts[category] == 0 then
            if HasVisibleSectionBefore(category) then
                currentY = currentY - 6
            end

            AttachSectionHeader(sectionHeaders[category], sectionTitles[category])
        end

        sectionCounts[category] = sectionCounts[category] + 1
        sectionIndices[category] = sectionIndices[category] + 1

        local rowPool = sectionRows[category]
        local row = rowPool[sectionIndices[category]]

        if not row then
            row = CreateTrackerTodoRow(TrackerContent)
            rowPool[sectionIndices[category]] = row
        end

        row.Checkbox.entryType = entryType
        row.Checkbox.todoID = todoID
        LayoutTrackerRow(row, labelText, checked)
    end

    for _, category in ipairs(sectionOrder) do
        if settings.showBuiltInInTracker then
            for _, todo in ipairs(GetBuiltInTodos()) do
                if GetTodoCadence(todo.id) == category and IsBuiltInTodoEnabled(todo.id) then
                    local checked = GetBuiltInTodoState(todo.id)

                    if not settings.hideCompletedInTracker or not checked then
                        AddTrackerRow(category, "builtin", todo.id, todo.label, checked)
                    end
                end
            end
        end

        if settings.showManualInTracker then
            for _, item in ipairs(GetManualItems()) do
                if NormalizeManualCadence(item.cadence) == category then
                    if not settings.hideCompletedInTracker or not item.checked then
                        AddTrackerRow(category, "manual", item.id, item.text, item.checked)
                    end
                end
            end
        end
    end

    if sectionCounts.daily == 0 and sectionCounts.weekly == 0 and sectionCounts.watch == 0 then
        TrackerEmptyText:ClearAllPoints()
        TrackerEmptyText:SetPoint("TOPLEFT", TrackerContent, "TOPLEFT", 8, -8)

        if settings.hideCompletedInTracker then
              TrackerEmptyText:SetText(L("CHECKLIST_TRACKER_EMPTY_HIDDEN"))
        else
              TrackerEmptyText:SetText(L("CHECKLIST_TRACKER_EMPTY_OPEN"))
        end

        TrackerEmptyText:Show()
        currentY = currentY - 36
    end

    TrackerContent:SetHeight(math.max(1, -currentY + 6))
    local maxScroll = math.max(0, TrackerContent:GetHeight() - TrackerScrollFrame:GetHeight())
    if TrackerScrollFrame:GetVerticalScroll() > maxScroll then
        TrackerScrollFrame:SetVerticalScroll(maxScroll)
    end

    TrackerFrame:Show()
end

function Checklist.RefreshAllViews()
    -- Gemeinsamer Refresh für Hauptseite und Tracker.
    if PageChecklist and PageChecklist.RefreshState then
        PageChecklist:RefreshState()
    end

    Checklist.RefreshTrackerWindow()
end

local function RefreshChecklistTrackerForContextChange()
    -- Kampf-, Zonen- und Instanzwechsel brauchen nur den Tracker-Refresh.
    Checklist.RefreshTrackerWindow()
end

function Checklist.SetBuiltInTodoChecked(todoID, checked)
    if not IsBuiltInTodoEnabled(todoID) then
        return
    end

    SetBuiltInTodoState(todoID, checked)
    Checklist.RefreshAllViews()
end

function Checklist.IsBuiltInTodoEnabled(todoID)
    return IsBuiltInTodoEnabled(todoID)
end

function Checklist.SetBuiltInTodoEnabled(todoID, enabled)
    SetBuiltInTodoEnabled(todoID, enabled)
    Checklist.RefreshAllViews()
end

function Checklist.SetManualTodoChecked(todoID, checked)
    local manualItems = GetManualItems()

    for _, item in ipairs(manualItems) do
        if item.id == todoID then
            item.checked = checked == true
            break
        end
    end

    Checklist.RefreshAllViews()
end

function Checklist.SetManualTodoCadence(todoID, cadence)
    SetManualItemCadence(todoID, cadence)
    Checklist.RefreshAllViews()
end

function Checklist.AddManualTodo(text, cadence)
    -- Manuelle Aufgaben gehen immer durch denselben Validierungsweg:
    -- trimmen, begrenzen, ID vergeben, speichern, UI refreshen.
    local trimmedText = TrimText(text)
    if not trimmedText then
        return false
    end

    local resolvedCadence = NormalizeManualCadence(cadence or selectedManualCadence)
    local db = GetChecklistCharacterData()
    local item = {
        id = db.nextManualID,
        text = string.sub(trimmedText, 1, 120),
        checked = false,
        cadence = resolvedCadence,
    }

    selectedManualCadence = resolvedCadence
    db.nextManualID = db.nextManualID + 1
    db.manualItems[#db.manualItems + 1] = item

    Checklist.RefreshAllViews()
    return true
end

function Checklist.DeleteManualTodo(todoID)
    local manualItems = GetManualItems()

    for index, item in ipairs(manualItems) do
        if item.id == todoID then
            table.remove(manualItems, index)
            break
        end
    end

    Checklist.RefreshAllViews()
end

function Checklist.ResetBuiltInTodos()
    local db = GetChecklistCharacterData()
    db.builtInState = {}
    db.disabledBuiltIns = {}
    Checklist.RefreshAllViews()
end

function Checklist.ResetAllTodoChecks()
    local db = GetChecklistCharacterData()
    db.builtInState = {}

    for _, item in ipairs(db.manualItems) do
        item.checked = false
    end

    Checklist.RefreshAllViews()
end

function Checklist.ResetTrackerWindow()
    -- Setzt nur trackerbezogene Einstellungen zurück, nicht die Aufgaben selbst.
    local settings = GetChecklistSettings()
    settings.trackerWidth = DEFAULT_TRACKER_WIDTH
    settings.trackerHeight = DEFAULT_TRACKER_HEIGHT
    settings.trackerCollapsed = false
    settings.trackerPoint = "BOTTOMRIGHT"
    settings.trackerRelativePoint = "BOTTOMRIGHT"
    settings.trackerOffsetX = -70
    settings.trackerOffsetY = 180

    ApplyTrackerGeometry()
    Checklist.RefreshTrackerWindow()
end

function Checklist.IsTrackerEnabled()
    return GetChecklistSettings().trackerEnabled == true
end

function Checklist.SetTrackerEnabled(enabled)
    GetChecklistSettings().trackerEnabled = enabled == true
    Checklist.RefreshAllViews()
end

function Checklist.IsTrackerCollapsed()
    return GetChecklistSettings().trackerCollapsed == true
end

function Checklist.SetTrackerCollapsed(collapsed)
    local settings = GetChecklistSettings()
    local shouldCollapse = collapsed == true

    if settings.trackerCollapsed == shouldCollapse then
        return
    end

    local previousHeight = settings.trackerCollapsed and COLLAPSED_TRACKER_HEIGHT or settings.trackerHeight
    if TrackerFrame and TrackerFrame:IsShown() then
        previousHeight = TrackerFrame:GetHeight() or previousHeight
    end

    local nextHeight = shouldCollapse and COLLAPSED_TRACKER_HEIGHT or settings.trackerHeight
    local verticalAnchorFactor = GetTrackerVerticalAnchorFactor(settings.trackerPoint)

    if verticalAnchorFactor > 0 then
        local offsetAdjustment = (previousHeight - nextHeight) * verticalAnchorFactor
        settings.trackerOffsetY = RoundToNearestInteger((settings.trackerOffsetY or 0) + offsetAdjustment)
    end

    settings.trackerCollapsed = shouldCollapse

    if UpdateTrackerCollapsedState then
        UpdateTrackerCollapsedState()
    end

    ApplyTrackerGeometry()

    Checklist.RefreshTrackerWindow()
end

function Checklist.GetShowBuiltInInTracker()
    return GetChecklistSettings().showBuiltInInTracker == true
end

function Checklist.SetShowBuiltInInTracker(enabled)
    GetChecklistSettings().showBuiltInInTracker = enabled == true
    Checklist.RefreshTrackerWindow()
end

function Checklist.GetShowManualInTracker()
    return GetChecklistSettings().showManualInTracker == true
end

function Checklist.SetShowManualInTracker(enabled)
    GetChecklistSettings().showManualInTracker = enabled == true
    Checklist.RefreshTrackerWindow()
end

function Checklist.GetHideCompletedInTracker()
    return GetChecklistSettings().hideCompletedInTracker == true
end

function Checklist.SetHideCompletedInTracker(enabled)
    GetChecklistSettings().hideCompletedInTracker = enabled == true
    Checklist.RefreshTrackerWindow()
end

function Checklist.IsTrackerLocked()
    return GetChecklistSettings().trackerLocked == true
end

function Checklist.SetTrackerLocked(locked)
    GetChecklistSettings().trackerLocked = locked == true

    if UpdateTrackerLockState then
        UpdateTrackerLockState()
    end

    Checklist.RefreshTrackerWindow()
end

function Checklist.GetTrackerFontSize()
    return GetChecklistSettings().fontSize
end

function Checklist.SetTrackerFontSize(fontSize)
    GetChecklistSettings().fontSize = Clamp(math.floor(fontSize + 0.5), 10, 16)
    Checklist.RefreshTrackerWindow()
end

function Checklist.GetTrackerBackgroundAlpha()
    return GetChecklistSettings().backgroundAlpha
end

function Checklist.SetTrackerBackgroundAlpha(alpha)
    GetChecklistSettings().backgroundAlpha = Clamp(alpha, 0.15, 0.70)
    Checklist.RefreshTrackerWindow()
end

-- ========================================
-- Tracker-Fenster
-- ========================================

TrackerFrame = CreateFrame("Frame", "BeavisQoLChecklistTrackerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
if TrackerFrame.SetResizable then
    TrackerFrame:SetResizable(true)
end

if TrackerFrame.SetResizeBounds then
    TrackerFrame:SetResizeBounds(MIN_TRACKER_WIDTH, MIN_TRACKER_HEIGHT, MAX_TRACKER_WIDTH, MAX_TRACKER_HEIGHT)
elseif TrackerFrame.SetMinResize then
    TrackerFrame:SetMinResize(MIN_TRACKER_WIDTH, MIN_TRACKER_HEIGHT)

    if TrackerFrame.SetMaxResize then
        TrackerFrame:SetMaxResize(MAX_TRACKER_WIDTH, MAX_TRACKER_HEIGHT)
    end
end

TrackerFrame:SetClampedToScreen(true)
TrackerFrame:SetMovable(true)
TrackerFrame:SetToplevel(true)
TrackerFrame:SetFrameStrata("MEDIUM")
TrackerFrame:EnableMouse(true)
TrackerFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
TrackerFrame:Hide()

local TrackerHeader = CreateFrame("Button", nil, TrackerFrame)
TrackerHeader:SetPoint("TOPLEFT", TrackerFrame, "TOPLEFT", 8, -6)
TrackerHeader:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", -218, -6)
TrackerHeader:SetHeight(18)
TrackerHeader:RegisterForDrag("LeftButton")
TrackerHeader:SetScript("OnDragStart", function()
    if Checklist.IsTrackerLocked() then
        return
    end

    TrackerFrame:StartMoving()
end)
TrackerHeader:SetScript("OnDragStop", function()
    TrackerFrame:StopMovingOrSizing()
    SaveTrackerGeometry()
end)

TrackerTitle = TrackerHeader:CreateFontString(nil, "OVERLAY")
TrackerTitle:SetPoint("LEFT", TrackerHeader, "LEFT", 2, 0)
TrackerTitle:SetPoint("RIGHT", TrackerHeader, "RIGHT", 0, 0)
TrackerTitle:SetJustifyH("LEFT")
TrackerTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
TrackerTitle:SetTextColor(1, 0.88, 0.62, 1)
TrackerTitle:SetText(L("CHECKLIST"))

local TrackerCloseButton = CreateFrame("Button", nil, TrackerFrame, "UIPanelButtonTemplate")
TrackerCloseButton:SetSize(20, 18)
TrackerCloseButton:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", -8, -6)
TrackerCloseButton:SetText("X")
TrackerCloseButton:SetScript("OnClick", function()
    Checklist.SetTrackerEnabled(false)
end)
TrackerCloseButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L("CHECKLIST_CLOSE"), 1, 1, 1)
    GameTooltip:AddLine(L("CHECKLIST_CLOSE_HINT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
TrackerCloseButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

TrackerLockButton = CreateFrame("Button", nil, TrackerFrame)
TrackerLockButton:SetSize(20, 18)
TrackerLockButton:SetPoint("TOPRIGHT", TrackerCloseButton, "TOPLEFT", -4, 0)
TrackerLockButton:SetHitRectInsets(-2, -2, -2, -2)
TrackerLockButton:SetScript("OnClick", function()
    Checklist.SetTrackerLocked(not Checklist.IsTrackerLocked())
end)

local TrackerLockButtonBackground = TrackerLockButton:CreateTexture(nil, "BACKGROUND")
TrackerLockButtonBackground:SetAllPoints()
TrackerLockButtonBackground:SetColorTexture(1, 0.82, 0, 0.06)
TrackerLockButton.Background = TrackerLockButtonBackground

local TrackerLockButtonHead = TrackerLockButton:CreateTexture(nil, "ARTWORK")
TrackerLockButtonHead:SetSize(6, 6)
TrackerLockButtonHead:SetColorTexture(1, 0.82, 0, 1)
TrackerLockButton.Head = TrackerLockButtonHead

local TrackerLockButtonBar = TrackerLockButton:CreateTexture(nil, "ARTWORK")
TrackerLockButtonBar:SetSize(10, 3)
TrackerLockButtonBar:SetColorTexture(1, 0.82, 0, 1)
TrackerLockButton.Bar = TrackerLockButtonBar

local TrackerLockButtonNeedle = TrackerLockButton:CreateTexture(nil, "ARTWORK")
TrackerLockButtonNeedle:SetSize(2, 10)
TrackerLockButtonNeedle:SetColorTexture(1, 1, 1, 1)
TrackerLockButton.Needle = TrackerLockButtonNeedle

local TrackerLockButtonHighlight = TrackerLockButton:CreateTexture(nil, "HIGHLIGHT")
TrackerLockButtonHighlight:SetAllPoints()
TrackerLockButtonHighlight:SetColorTexture(1, 1, 1, 0.08)

UpdateTrackerLockButtonVisual = function()
    local isLocked = Checklist.IsTrackerLocked()

    TrackerLockButton.Head:ClearAllPoints()
    TrackerLockButton.Bar:ClearAllPoints()
    TrackerLockButton.Needle:ClearAllPoints()

    if isLocked then
        TrackerLockButton.Background:SetColorTexture(1, 0.82, 0, 0.10)
        TrackerLockButton.Head:SetPoint("CENTER", TrackerLockButton, "CENTER", 0, 4)
        TrackerLockButton.Bar:SetPoint("CENTER", TrackerLockButton, "CENTER", 0, 1)
        TrackerLockButton.Needle:SetPoint("CENTER", TrackerLockButton, "CENTER", 0, -5)
        TrackerLockButton.Bar:SetRotation(0)
        TrackerLockButton.Needle:SetRotation(0)
        TrackerLockButton.Head:SetColorTexture(1, 0.82, 0, 1)
        TrackerLockButton.Bar:SetColorTexture(1, 0.82, 0, 1)
        TrackerLockButton.Needle:SetColorTexture(0.95, 0.95, 0.95, 1)
    else
        TrackerLockButton.Background:SetColorTexture(1, 1, 1, 0.04)
        TrackerLockButton.Head:SetPoint("CENTER", TrackerLockButton, "CENTER", -3, 4)
        TrackerLockButton.Bar:SetPoint("CENTER", TrackerLockButton, "CENTER", -1, 2)
        TrackerLockButton.Needle:SetPoint("CENTER", TrackerLockButton, "CENTER", 3, -2)
        TrackerLockButton.Bar:SetRotation(-0.80)
        TrackerLockButton.Needle:SetRotation(-0.80)
        TrackerLockButton.Head:SetColorTexture(0.86, 0.86, 0.86, 1)
        TrackerLockButton.Bar:SetColorTexture(0.86, 0.86, 0.86, 1)
        TrackerLockButton.Needle:SetColorTexture(0.70, 0.70, 0.70, 1)
    end
end
TrackerLockButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")

    if Checklist.IsTrackerLocked() then
        GameTooltip:AddLine(L("CHECKLIST_TRACKER_LOCKED"), 1, 1, 1)
        GameTooltip:AddLine(L("CHECKLIST_TRACKER_LOCKED_HINT"), 0.9, 0.9, 0.9, true)
    else
        GameTooltip:AddLine(L("CHECKLIST_TRACKER_UNLOCKED"), 1, 1, 1)
        GameTooltip:AddLine(L("CHECKLIST_TRACKER_UNLOCKED_HINT"), 0.9, 0.9, 0.9, true)
    end

    GameTooltip:Show()
end)
TrackerLockButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local TrackerSettingsButton = CreateFrame("Button", nil, TrackerFrame, "UIPanelButtonTemplate")
TrackerSettingsButton:SetSize(48, 18)
TrackerSettingsButton:SetPoint("TOPRIGHT", TrackerLockButton, "TOPLEFT", -4, 0)
TrackerSettingsButton:SetText(L("CHECKLIST_SETTINGS_BUTTON"))
TrackerSettingsButton:SetScript("OnClick", function()
    if OpenChecklistSettingsSection then
        OpenChecklistSettingsSection()
    end
end)
TrackerSettingsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L("CHECKLIST_SETTINGS_TOOLTIP"), 1, 1, 1)
    GameTooltip:AddLine(L("CHECKLIST_SETTINGS_TOOLTIP_HINT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
TrackerSettingsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local TrackerAddButton = CreateFrame("Button", nil, TrackerFrame, "UIPanelButtonTemplate")
TrackerAddButton:SetSize(34, 18)
TrackerAddButton:SetPoint("TOPRIGHT", TrackerSettingsButton, "TOPLEFT", -4, 0)
TrackerAddButton:SetText(L("CHECKLIST_ADD_BUTTON"))
TrackerAddButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L("CHECKLIST_ADD_TOOLTIP"), 1, 1, 1)
    GameTooltip:AddLine(L("CHECKLIST_ADD_TOOLTIP_HINT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
TrackerAddButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

TrackerVaultButton = CreateFrame("Button", nil, TrackerFrame, "UIPanelButtonTemplate")
TrackerVaultButton:SetSize(42, 18)
TrackerVaultButton:SetPoint("TOPRIGHT", TrackerAddButton, "TOPLEFT", -4, 0)
TrackerVaultButton:SetText(L("VAULT"))

TrackerCollapseButton = CreateFrame("Button", nil, TrackerFrame, "UIPanelButtonTemplate")
TrackerCollapseButton:SetSize(20, 18)
TrackerCollapseButton:SetPoint("TOPRIGHT", TrackerVaultButton, "TOPLEFT", -4, 0)
TrackerCollapseButton:SetText("-")
TrackerCollapseButton:SetScript("OnClick", function()
    Checklist.SetTrackerCollapsed(not Checklist.IsTrackerCollapsed())
end)
TrackerCollapseButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")

    if Checklist.IsTrackerCollapsed() then
        GameTooltip:AddLine(L("CHECKLIST_EXPAND"), 1, 1, 1)
        GameTooltip:AddLine(L("CHECKLIST_EXPAND_HINT"), 0.9, 0.9, 0.9, true)
    else
        GameTooltip:AddLine(L("CHECKLIST_COLLAPSE"), 1, 1, 1)
        GameTooltip:AddLine(L("CHECKLIST_COLLAPSE_HINT"), 0.9, 0.9, 0.9, true)
    end

    GameTooltip:Show()
end)
TrackerCollapseButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function OpenWeeklyVault()
    -- Funktioniert als Toggle:
    -- offenes Vault-Fenster schließen, sonst öffnen.
    if WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown() then
        if HideUIPanel then
            HideUIPanel(WeeklyRewardsFrame)
        else
            WeeklyRewardsFrame:Hide()
        end

        return true
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
    elseif UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_WeeklyRewards")
    end

    if WeeklyRewardsFrame then
        if WeeklyRewardsFrame:IsShown() then
            if HideUIPanel then
                HideUIPanel(WeeklyRewardsFrame)
            else
                WeeklyRewardsFrame:Hide()
            end
        else
            if WeeklyRewards_ShowUI then
                WeeklyRewards_ShowUI()
            else
                WeeklyRewardsFrame:Show()
            end
        end

        return true
    end

    if WeeklyRewards_ShowUI then
        WeeklyRewards_ShowUI()
        return true
    end

    return false
end

TrackerVaultButton:SetScript("OnClick", function()
    if not OpenWeeklyVault() then
        print(L("CHECKLIST_VAULT_ERROR"))
    end
end)
TrackerVaultButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L("CHECKLIST_VAULT_TOOLTIP"), 1, 1, 1)
    GameTooltip:AddLine(L("CHECKLIST_VAULT_TOOLTIP_HINT"), 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
TrackerVaultButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

TrackerHeaderBorder = TrackerFrame:CreateTexture(nil, "ARTWORK")
TrackerHeaderBorder:SetPoint("TOPLEFT", TrackerFrame, "TOPLEFT", 8, -26)
TrackerHeaderBorder:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", -8, -26)
TrackerHeaderBorder:SetHeight(1)
TrackerHeaderBorder:SetColorTexture(0.88, 0.72, 0.46, 0.22)

TrackerScrollFrame = CreateFrame("ScrollFrame", nil, TrackerFrame, "UIPanelScrollFrameTemplate")
TrackerScrollFrame:SetPoint("TOPLEFT", TrackerFrame, "TOPLEFT", 8, -30)
TrackerScrollFrame:SetPoint("BOTTOMRIGHT", TrackerFrame, "BOTTOMRIGHT", -28, 18)
TrackerScrollFrame:EnableMouseWheel(true)

TrackerContent = CreateFrame("Frame", nil, TrackerScrollFrame)
TrackerContent:SetSize(1, 1)
TrackerScrollFrame:SetScrollChild(TrackerContent)

TrackerBuiltInHeader = TrackerContent:CreateFontString(nil, "OVERLAY")
TrackerBuiltInHeader:SetJustifyH("LEFT")
TrackerBuiltInHeader:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
TrackerBuiltInHeader:SetTextColor(1, 0.88, 0.62, 1)
TrackerBuiltInHeader:Hide()

TrackerManualHeader = TrackerContent:CreateFontString(nil, "OVERLAY")
TrackerManualHeader:SetJustifyH("LEFT")
TrackerManualHeader:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
TrackerManualHeader:SetTextColor(1, 0.88, 0.62, 1)
TrackerManualHeader:Hide()

TrackerWatchHeader = TrackerContent:CreateFontString(nil, "OVERLAY")
TrackerWatchHeader:SetJustifyH("LEFT")
TrackerWatchHeader:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
TrackerWatchHeader:SetTextColor(1, 0.88, 0.62, 1)
TrackerWatchHeader:Hide()

TrackerEmptyText = TrackerContent:CreateFontString(nil, "OVERLAY")
TrackerEmptyText:SetJustifyH("LEFT")
TrackerEmptyText:SetJustifyV("TOP")
TrackerEmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrackerEmptyText:SetPoint("TOPLEFT", TrackerContent, "TOPLEFT", 8, -8)
TrackerEmptyText:SetPoint("RIGHT", TrackerContent, "RIGHT", -8, 0)
TrackerEmptyText:SetTextColor(0.82, 0.82, 0.82, 1)
TrackerEmptyText:SetText("")
TrackerEmptyText:Hide()

TrackerAddPopup = CreateFrame("Frame", nil, TrackerFrame, BackdropTemplateMixin and "BackdropTemplate")
TrackerAddPopup:SetSize(268, 144)
TrackerAddPopup:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", -8, -30)
TrackerAddPopup:SetFrameStrata("HIGH")
TrackerAddPopup:SetFrameLevel(TrackerFrame:GetFrameLevel() + 20)
TrackerAddPopup:EnableMouse(true)
TrackerAddPopup:SetClampedToScreen(true)
TrackerAddPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
TrackerAddPopup:SetBackdropColor(0.05, 0.05, 0.05, 0.96)
TrackerAddPopup:SetBackdropBorderColor(1, 0.82, 0, 0.72)
TrackerAddPopup:Hide()

local TrackerAddPopupTitle = TrackerAddPopup:CreateFontString(nil, "OVERLAY")
TrackerAddPopupTitle:SetPoint("TOPLEFT", TrackerAddPopup, "TOPLEFT", 12, -10)
TrackerAddPopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
TrackerAddPopupTitle:SetTextColor(1, 0.88, 0.62, 1)
TrackerAddPopupTitle:SetText(L("CHECKLIST_NEW_TASK"))

local TrackerAddPopupHint = TrackerAddPopup:CreateFontString(nil, "OVERLAY")
TrackerAddPopupHint:SetPoint("TOPLEFT", TrackerAddPopupTitle, "BOTTOMLEFT", 0, -6)
TrackerAddPopupHint:SetPoint("RIGHT", TrackerAddPopup, "RIGHT", -12, 0)
TrackerAddPopupHint:SetJustifyH("LEFT")
TrackerAddPopupHint:SetJustifyV("TOP")
TrackerAddPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrackerAddPopupHint:SetTextColor(0.82, 0.82, 0.82, 1)
TrackerAddPopupHint:SetText(L("CHECKLIST_NEW_TASK_HINT"))

TrackerAddPopupInputBox = CreateFrame("EditBox", nil, TrackerAddPopup, "InputBoxTemplate")
TrackerAddPopupInputBox:SetPoint("TOPLEFT", TrackerAddPopupHint, "BOTTOMLEFT", 4, -10)
TrackerAddPopupInputBox:SetSize(228, 26)
TrackerAddPopupInputBox:SetAutoFocus(false)
TrackerAddPopupInputBox:SetMaxLetters(120)
TrackerAddPopupInputBox:SetFontObject(ChatFontNormal)

TrackerAddPopupCadenceDailyButton = CreateFrame("Button", nil, TrackerAddPopup, "UIPanelButtonTemplate")
TrackerAddPopupCadenceDailyButton:SetSize(60, 22)
TrackerAddPopupCadenceDailyButton:SetPoint("TOPLEFT", TrackerAddPopupInputBox, "BOTTOMLEFT", -2, -12)
TrackerAddPopupCadenceDailyButton:SetText(L("DAILY"))

TrackerAddPopupCadenceWeeklyButton = CreateFrame("Button", nil, TrackerAddPopup, "UIPanelButtonTemplate")
TrackerAddPopupCadenceWeeklyButton:SetSize(60, 22)
TrackerAddPopupCadenceWeeklyButton:SetPoint("LEFT", TrackerAddPopupCadenceDailyButton, "RIGHT", 6, 0)
TrackerAddPopupCadenceWeeklyButton:SetText(L("WEEKLY"))

TrackerAddPopupCadenceWatchButton = CreateFrame("Button", nil, TrackerAddPopup, "UIPanelButtonTemplate")
TrackerAddPopupCadenceWatchButton:SetSize(70, 22)
TrackerAddPopupCadenceWatchButton:SetPoint("LEFT", TrackerAddPopupCadenceWeeklyButton, "RIGHT", 6, 0)
TrackerAddPopupCadenceWatchButton:SetText(L("CHECKLIST_WATCH_SHORT"))

local TrackerAddPopupCancelButton = CreateFrame("Button", nil, TrackerAddPopup, "UIPanelButtonTemplate")
TrackerAddPopupCancelButton:SetSize(82, 22)
TrackerAddPopupCancelButton:SetPoint("BOTTOMRIGHT", TrackerAddPopup, "BOTTOMRIGHT", -12, 10)
TrackerAddPopupCancelButton:SetText(L("CANCEL"))

local TrackerAddPopupSubmitButton = CreateFrame("Button", nil, TrackerAddPopup, "UIPanelButtonTemplate")
TrackerAddPopupSubmitButton:SetSize(86, 22)
TrackerAddPopupSubmitButton:SetPoint("RIGHT", TrackerAddPopupCancelButton, "LEFT", -8, 0)
TrackerAddPopupSubmitButton:SetText(L("ADD_SHORT"))

UpdateTrackerAddPopupCadenceButtons = function()
    TrackerAddPopupCadenceDailyButton:SetEnabled(selectedTrackerPopupCadence ~= "daily")
    TrackerAddPopupCadenceWeeklyButton:SetEnabled(selectedTrackerPopupCadence ~= "weekly")
    TrackerAddPopupCadenceWatchButton:SetEnabled(selectedTrackerPopupCadence ~= "watch")
end

CloseTrackerAddPopup = function()
    if not TrackerAddPopup then
        return
    end

    TrackerAddPopup:Hide()
    TrackerAddPopupInputBox:SetText("")
    TrackerAddPopupInputBox:ClearFocus()
end

local function SubmitTrackerAddPopup()
    -- Das Popup nutzt absichtlich dieselbe Add-Funktion wie die Hauptseite.
    if Checklist.AddManualTodo(TrackerAddPopupInputBox:GetText(), selectedTrackerPopupCadence) then
        CloseTrackerAddPopup()
    else
        TrackerAddPopupInputBox:SetFocus()
        TrackerAddPopupInputBox:HighlightText()
    end
end

OpenTrackerAddPopup = function()
    if not TrackerAddPopup then
        return
    end

    selectedTrackerPopupCadence = NormalizeManualCadence(selectedManualCadence)
    UpdateTrackerAddPopupCadenceButtons()
    TrackerAddPopup:Show()
    TrackerAddPopupInputBox:SetText("")
    TrackerAddPopupInputBox:SetFocus()
    TrackerAddPopupInputBox:HighlightText()
end

TrackerAddButton:SetScript("OnClick", function()
    if TrackerAddPopup:IsShown() then
        CloseTrackerAddPopup()
    else
        OpenTrackerAddPopup()
    end
end)

TrackerAddPopupCadenceDailyButton:SetScript("OnClick", function()
    selectedTrackerPopupCadence = "daily"
    UpdateTrackerAddPopupCadenceButtons()
end)

TrackerAddPopupCadenceWeeklyButton:SetScript("OnClick", function()
    selectedTrackerPopupCadence = "weekly"
    UpdateTrackerAddPopupCadenceButtons()
end)

TrackerAddPopupCadenceWatchButton:SetScript("OnClick", function()
    selectedTrackerPopupCadence = "watch"
    UpdateTrackerAddPopupCadenceButtons()
end)

TrackerAddPopupCancelButton:SetScript("OnClick", function()
    CloseTrackerAddPopup()
end)

TrackerAddPopupSubmitButton:SetScript("OnClick", function()
    SubmitTrackerAddPopup()
end)

TrackerAddPopupInputBox:SetScript("OnEnterPressed", function()
    SubmitTrackerAddPopup()
end)

TrackerAddPopupInputBox:SetScript("OnEscapePressed", function()
    CloseTrackerAddPopup()
end)

TrackerFrame:HookScript("OnHide", function()
    if CloseTrackerAddPopup then
        CloseTrackerAddPopup()
    end
end)

TrackerScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 30
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, TrackerContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

TrackerFrame:SetScript("OnSizeChanged", function(self, width, height)
    local settings = GetChecklistSettings()
    local isCollapsed = Checklist.IsTrackerCollapsed()
    local clampedWidth = Clamp(math.floor(width + 0.5), MIN_TRACKER_WIDTH, MAX_TRACKER_WIDTH)
    local targetHeight

    if isCollapsed then
        targetHeight = COLLAPSED_TRACKER_HEIGHT
    else
        targetHeight = Clamp(math.floor(height + 0.5), MIN_TRACKER_HEIGHT, MAX_TRACKER_HEIGHT)
        settings.trackerHeight = targetHeight
    end

    settings.trackerWidth = clampedWidth

    if width ~= clampedWidth or height ~= targetHeight then
        self:SetSize(clampedWidth, targetHeight)
        return
    end

    if self:IsShown() then
        Checklist.RefreshTrackerWindow()
    end
end)

TrackerResizeHandle = CreateFrame("Button", nil, TrackerFrame)
TrackerResizeHandle:SetSize(16, 16)
TrackerResizeHandle:SetPoint("BOTTOMRIGHT", TrackerFrame, "BOTTOMRIGHT", -2, 2)
TrackerResizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
TrackerResizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
TrackerResizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
TrackerResizeHandle:SetScript("OnMouseDown", function()
    if Checklist.IsTrackerLocked() or Checklist.IsTrackerCollapsed() then
        return
    end

    TrackerFrame:StartSizing("BOTTOMRIGHT")
end)
TrackerResizeHandle:SetScript("OnMouseUp", function()
    TrackerFrame:StopMovingOrSizing()
    SaveTrackerGeometry()
    Checklist.RefreshTrackerWindow()
end)

UpdateTrackerCollapsedState = function()
    local isCollapsed = Checklist.IsTrackerCollapsed()

    if TrackerCollapseButton then
        TrackerCollapseButton:SetText(isCollapsed and "+" or "-")
    end

    if TrackerFrame then
        if TrackerFrame.SetResizeBounds then
            TrackerFrame:SetResizeBounds(
                MIN_TRACKER_WIDTH,
                isCollapsed and COLLAPSED_TRACKER_HEIGHT or MIN_TRACKER_HEIGHT,
                MAX_TRACKER_WIDTH,
                isCollapsed and COLLAPSED_TRACKER_HEIGHT or MAX_TRACKER_HEIGHT
            )
        elseif TrackerFrame.SetMinResize then
            TrackerFrame:SetMinResize(MIN_TRACKER_WIDTH, isCollapsed and COLLAPSED_TRACKER_HEIGHT or MIN_TRACKER_HEIGHT)

            if TrackerFrame.SetMaxResize then
                TrackerFrame:SetMaxResize(MAX_TRACKER_WIDTH, isCollapsed and COLLAPSED_TRACKER_HEIGHT or MAX_TRACKER_HEIGHT)
            end
        end
    end

    if TrackerHeaderBorder then
        if isCollapsed then
            TrackerHeaderBorder:Hide()
        else
            TrackerHeaderBorder:Show()
        end
    end

    if TrackerScrollFrame then
        if isCollapsed then
            TrackerScrollFrame:Hide()
        else
            TrackerScrollFrame:Show()
        end
    end
end

UpdateTrackerLockState = function()
    local isLocked = Checklist.IsTrackerLocked() or Checklist.IsTrackerCollapsed()

    if isLocked then
        TrackerLockButton:SetText(L("UNLOCK"))
        TrackerResizeHandle:Hide()
    else
        TrackerLockButton:SetText(L("FIX"))
        TrackerResizeHandle:Show()
    end
end

if GetChecklistSettings().trackerCollapsed then
    if TrackerFrame.SetResizeBounds then
        TrackerFrame:SetResizeBounds(MIN_TRACKER_WIDTH, COLLAPSED_TRACKER_HEIGHT, MAX_TRACKER_WIDTH, COLLAPSED_TRACKER_HEIGHT)
    elseif TrackerFrame.SetMinResize then
        TrackerFrame:SetMinResize(MIN_TRACKER_WIDTH, COLLAPSED_TRACKER_HEIGHT)

        if TrackerFrame.SetMaxResize then
            TrackerFrame:SetMaxResize(MAX_TRACKER_WIDTH, COLLAPSED_TRACKER_HEIGHT)
        end
    end
end

ApplyTrackerGeometry()
ApplyTrackerStyle()

UpdateTrackerLockState = function()
    if Checklist.IsTrackerLocked() or Checklist.IsTrackerCollapsed() then
        TrackerResizeHandle:Hide()
    else
        TrackerResizeHandle:Show()
    end

    if UpdateTrackerCollapsedState then
        UpdateTrackerCollapsedState()
    end

    if UpdateTrackerLockButtonVisual then
        UpdateTrackerLockButtonVisual()
    end
end

UpdateTrackerLockState()

-- ========================================
-- Hauptseite
-- ========================================

PageChecklist = CreateFrame("Frame", nil, Content)
PageChecklist:SetAllPoints()
PageChecklist:Hide()

local PageChecklistScrollFrame = CreateFrame("ScrollFrame", nil, PageChecklist, "UIPanelScrollFrameTemplate")
PageChecklistScrollFrame:SetPoint("TOPLEFT", PageChecklist, "TOPLEFT", 0, 0)
PageChecklistScrollFrame:SetPoint("BOTTOMRIGHT", PageChecklist, "BOTTOMRIGHT", -28, 0)
PageChecklistScrollFrame:EnableMouseWheel(true)

local PageChecklistContent = CreateFrame("Frame", nil, PageChecklistScrollFrame)
PageChecklistContent:SetSize(1, 1)
PageChecklistScrollFrame:SetScrollChild(PageChecklistContent)

local IntroPanel = CreateFrame("Frame", nil, PageChecklistContent)
IntroPanel:SetPoint("TOPLEFT", PageChecklistContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageChecklistContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(144)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
IntroTitle:SetTextColor(1, 0.88, 0.62, 1)
IntroTitle:SetText(BeavisQoL.GetModulePageTitle("Checklist", L("CHECKLIST")))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
IntroText:SetText(L("CHECKLIST_DESC"))

IntroSummaryValue = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroSummaryValue:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
IntroSummaryValue:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
IntroSummaryValue:SetTextColor(1, 0.88, 0.62, 1)
IntroSummaryValue:SetText(L("CHECKLIST_INTRO_SUMMARY_DEFAULT"))

local IntroHint = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroHint:SetPoint("TOPLEFT", IntroSummaryValue, "BOTTOMLEFT", 0, -8)
IntroHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroHint:SetJustifyH("LEFT")
IntroHint:SetJustifyV("TOP")
IntroHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroHint:SetTextColor(0.78, 0.78, 0.78, 1)
IntroHint:SetText(L("CHECKLIST_INTRO_HINT"))

local function UpdateIntroPanelHeight()
    -- Der Headerblock passt sich an den echten Textumbruch an.
    local desiredHeight = math.ceil(
        16
        + IntroTitle:GetStringHeight()
        + 10
        + IntroText:GetStringHeight()
        + 12
        + IntroSummaryValue:GetStringHeight()
        + 8
        + IntroHint:GetStringHeight()
        + 20
    )

    IntroPanel:SetHeight(math.max(144, desiredHeight))
end

local WatchPanel = CreateFrame("Frame", nil, PageChecklistContent)
WatchPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
WatchPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
WatchPanel:SetHeight(160)

local WatchBg = WatchPanel:CreateTexture(nil, "BACKGROUND")
WatchBg:SetAllPoints()
WatchBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local WatchBorder = WatchPanel:CreateTexture(nil, "ARTWORK")
WatchBorder:SetPoint("BOTTOMLEFT", WatchPanel, "BOTTOMLEFT", 0, 0)
WatchBorder:SetPoint("BOTTOMRIGHT", WatchPanel, "BOTTOMRIGHT", 0, 0)
WatchBorder:SetHeight(1)
WatchBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local WatchTitle = WatchPanel:CreateFontString(nil, "OVERLAY")
WatchTitle:SetPoint("TOPLEFT", WatchPanel, "TOPLEFT", 18, -14)
WatchTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
WatchTitle:SetTextColor(1, 0.88, 0.62, 1)
WatchTitle:SetText(L("CHECKLIST_WATCH"))

local WatchHint = WatchPanel:CreateFontString(nil, "OVERLAY")
WatchHint:SetPoint("TOPLEFT", WatchTitle, "BOTTOMLEFT", 0, -8)
WatchHint:SetPoint("RIGHT", WatchPanel, "RIGHT", -18, 0)
WatchHint:SetJustifyH("LEFT")
WatchHint:SetJustifyV("TOP")
WatchHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WatchHint:SetTextColor(0.78, 0.74, 0.69, 1)
WatchHint:SetText(L("CHECKLIST_WATCH_HINT"))
WatchPanel.ContentAnchor = WatchHint

WatchEmptyText = WatchPanel:CreateFontString(nil, "OVERLAY")
WatchEmptyText:SetJustifyH("LEFT")
WatchEmptyText:SetJustifyV("TOP")
WatchEmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WatchEmptyText:SetTextColor(0.75, 0.75, 0.75, 1)
WatchEmptyText:SetText(L("CHECKLIST_EMPTY_WATCH"))

local DailyPanel = CreateFrame("Frame", nil, PageChecklistContent)
DailyPanel:SetPoint("TOPLEFT", WatchPanel, "BOTTOMLEFT", 0, -18)
DailyPanel:SetPoint("TOPRIGHT", WatchPanel, "BOTTOMRIGHT", 0, -18)
DailyPanel:SetHeight(210)

local DailyBg = DailyPanel:CreateTexture(nil, "BACKGROUND")
DailyBg:SetAllPoints()
DailyBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local DailyBorder = DailyPanel:CreateTexture(nil, "ARTWORK")
DailyBorder:SetPoint("BOTTOMLEFT", DailyPanel, "BOTTOMLEFT", 0, 0)
DailyBorder:SetPoint("BOTTOMRIGHT", DailyPanel, "BOTTOMRIGHT", 0, 0)
DailyBorder:SetHeight(1)
DailyBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local DailyTitle = DailyPanel:CreateFontString(nil, "OVERLAY")
DailyTitle:SetPoint("TOPLEFT", DailyPanel, "TOPLEFT", 18, -14)
DailyTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
DailyTitle:SetTextColor(1, 0.88, 0.62, 1)
DailyTitle:SetText(L("DAILY"))

local DailyHint = DailyPanel:CreateFontString(nil, "OVERLAY")
DailyHint:SetPoint("TOPLEFT", DailyTitle, "BOTTOMLEFT", 0, -8)
DailyHint:SetPoint("RIGHT", DailyPanel, "RIGHT", -18, 0)
DailyHint:SetJustifyH("LEFT")
DailyHint:SetJustifyV("TOP")
DailyHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
DailyHint:SetTextColor(0.78, 0.74, 0.69, 1)
DailyHint:SetText(L("CHECKLIST_DAILY_HINT"))
DailyPanel.ContentAnchor = DailyHint

DailyEmptyText = DailyPanel:CreateFontString(nil, "OVERLAY")
DailyEmptyText:SetJustifyH("LEFT")
DailyEmptyText:SetJustifyV("TOP")
DailyEmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
DailyEmptyText:SetTextColor(0.75, 0.75, 0.75, 1)
DailyEmptyText:SetText(L("CHECKLIST_EMPTY_DAILY"))

local WeeklyPanel = CreateFrame("Frame", nil, PageChecklistContent)
WeeklyPanel:SetPoint("TOPLEFT", DailyPanel, "BOTTOMLEFT", 0, -18)
WeeklyPanel:SetPoint("TOPRIGHT", DailyPanel, "BOTTOMRIGHT", 0, -18)
WeeklyPanel:SetHeight(210)

local WeeklyBg = WeeklyPanel:CreateTexture(nil, "BACKGROUND")
WeeklyBg:SetAllPoints()
WeeklyBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local WeeklyBorder = WeeklyPanel:CreateTexture(nil, "ARTWORK")
WeeklyBorder:SetPoint("BOTTOMLEFT", WeeklyPanel, "BOTTOMLEFT", 0, 0)
WeeklyBorder:SetPoint("BOTTOMRIGHT", WeeklyPanel, "BOTTOMRIGHT", 0, 0)
WeeklyBorder:SetHeight(1)
WeeklyBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local WeeklyTitle = WeeklyPanel:CreateFontString(nil, "OVERLAY")
WeeklyTitle:SetPoint("TOPLEFT", WeeklyPanel, "TOPLEFT", 18, -14)
WeeklyTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
WeeklyTitle:SetTextColor(1, 0.88, 0.62, 1)
WeeklyTitle:SetText(L("WEEKLY"))

local WeeklyHint = WeeklyPanel:CreateFontString(nil, "OVERLAY")
WeeklyHint:SetPoint("TOPLEFT", WeeklyTitle, "BOTTOMLEFT", 0, -8)
WeeklyHint:SetPoint("RIGHT", WeeklyPanel, "RIGHT", -18, 0)
WeeklyHint:SetJustifyH("LEFT")
WeeklyHint:SetJustifyV("TOP")
WeeklyHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WeeklyHint:SetTextColor(0.78, 0.74, 0.69, 1)
WeeklyHint:SetText(L("CHECKLIST_WEEKLY_HINT"))
WeeklyPanel.ContentAnchor = WeeklyHint

WeeklyEmptyText = WeeklyPanel:CreateFontString(nil, "OVERLAY")
WeeklyEmptyText:SetJustifyH("LEFT")
WeeklyEmptyText:SetJustifyV("TOP")
WeeklyEmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WeeklyEmptyText:SetTextColor(0.75, 0.75, 0.75, 1)
WeeklyEmptyText:SetText(L("CHECKLIST_EMPTY_WEEKLY"))

local ManualControlPanel = CreateFrame("Frame", nil, PageChecklistContent)
ManualControlPanel:SetPoint("TOPLEFT", WeeklyPanel, "BOTTOMLEFT", 0, -18)
ManualControlPanel:SetPoint("TOPRIGHT", WeeklyPanel, "BOTTOMRIGHT", 0, -18)
ManualControlPanel:SetHeight(168)

local ManualControlBg = ManualControlPanel:CreateTexture(nil, "BACKGROUND")
ManualControlBg:SetAllPoints()
ManualControlBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local ManualControlBorder = ManualControlPanel:CreateTexture(nil, "ARTWORK")
ManualControlBorder:SetPoint("BOTTOMLEFT", ManualControlPanel, "BOTTOMLEFT", 0, 0)
ManualControlBorder:SetPoint("BOTTOMRIGHT", ManualControlPanel, "BOTTOMRIGHT", 0, 0)
ManualControlBorder:SetHeight(1)
ManualControlBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local ManualControlTitle = ManualControlPanel:CreateFontString(nil, "OVERLAY")
ManualControlTitle:SetPoint("TOPLEFT", ManualControlPanel, "TOPLEFT", 18, -14)
ManualControlTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
ManualControlTitle:SetTextColor(1, 0.88, 0.62, 1)
ManualControlTitle:SetText(L("CHECKLIST_MANUAL_ADD_TITLE"))

local ManualControlHint = ManualControlPanel:CreateFontString(nil, "OVERLAY")
ManualControlHint:SetPoint("TOPLEFT", ManualControlTitle, "BOTTOMLEFT", 0, -8)
ManualControlHint:SetPoint("RIGHT", ManualControlPanel, "RIGHT", -18, 0)
ManualControlHint:SetJustifyH("LEFT")
ManualControlHint:SetJustifyV("TOP")
ManualControlHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ManualControlHint:SetTextColor(0.78, 0.74, 0.69, 1)
ManualControlHint:SetText(L("CHECKLIST_MANUAL_ADD_HINT"))

local ManualAddLabel = ManualControlPanel:CreateFontString(nil, "OVERLAY")
ManualAddLabel:SetPoint("TOPLEFT", ManualControlHint, "BOTTOMLEFT", 0, -16)
ManualAddLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ManualAddLabel:SetTextColor(1, 0.88, 0.62, 1)
ManualAddLabel:SetText(L("CHECKLIST_MANUAL_ADD_LABEL"))

ManualInputBox = CreateFrame("EditBox", nil, ManualControlPanel, "InputBoxTemplate")
ManualInputBox:SetPoint("TOPLEFT", ManualAddLabel, "BOTTOMLEFT", 4, -10)
ManualInputBox:SetSize(300, 30)
ManualInputBox:SetAutoFocus(false)
ManualInputBox:SetMaxLetters(120)
ManualInputBox:SetFontObject(ChatFontNormal)

ManualCadenceDailyButton = CreateFrame("Button", nil, ManualControlPanel, "UIPanelButtonTemplate")
ManualCadenceDailyButton:SetSize(70, 28)
ManualCadenceDailyButton:SetPoint("LEFT", ManualInputBox, "RIGHT", 12, 0)
ManualCadenceDailyButton:SetText(L("DAILY"))

ManualCadenceWeeklyButton = CreateFrame("Button", nil, ManualControlPanel, "UIPanelButtonTemplate")
ManualCadenceWeeklyButton:SetSize(70, 28)
ManualCadenceWeeklyButton:SetPoint("LEFT", ManualCadenceDailyButton, "RIGHT", 8, 0)
ManualCadenceWeeklyButton:SetText(L("WEEKLY"))

ManualCadenceWatchButton = CreateFrame("Button", nil, ManualControlPanel, "UIPanelButtonTemplate")
ManualCadenceWatchButton:SetSize(78, 28)
ManualCadenceWatchButton:SetPoint("LEFT", ManualCadenceWeeklyButton, "RIGHT", 8, 0)
ManualCadenceWatchButton:SetText(L("CHECKLIST_WATCH_SHORT"))

local ManualAddButton = CreateFrame("Button", nil, ManualControlPanel, "UIPanelButtonTemplate")
ManualAddButton:SetSize(110, 28)
ManualAddButton:SetPoint("LEFT", ManualCadenceWatchButton, "RIGHT", 10, 0)
ManualAddButton:SetText(L("ADD"))
ManualAddButton:SetScript("OnClick", function()
    if Checklist.AddManualTodo(ManualInputBox:GetText()) then
        ManualInputBox:SetText("")
        ManualInputBox:ClearFocus()
    end
end)

ManualInputBox:SetScript("OnEnterPressed", function(self)
    if Checklist.AddManualTodo(self:GetText()) then
        self:SetText("")
    end
    self:ClearFocus()
end)

ManualInputBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

local ManualCategoryHint = ManualControlPanel:CreateFontString(nil, "OVERLAY")
ManualCategoryHint:SetPoint("TOPLEFT", ManualInputBox, "BOTTOMLEFT", 0, -10)
ManualCategoryHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ManualCategoryHint:SetTextColor(0.75, 0.75, 0.75, 1)
ManualCategoryHint:SetText(L("CHECKLIST_MANUAL_CATEGORY_HINT"))

local SettingsPanel = CreateFrame("Frame", nil, PageChecklistContent)
SettingsPanel:SetPoint("TOPLEFT", ManualControlPanel, "BOTTOMLEFT", 0, -18)
SettingsPanel:SetPoint("TOPRIGHT", ManualControlPanel, "BOTTOMRIGHT", 0, -18)
SettingsPanel:SetHeight(540)

local SettingsBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsBg:SetAllPoints()
SettingsBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local SettingsBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsBorder:SetHeight(1)
SettingsBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.88, 0.62, 1)
SettingsTitle:SetText(L("CHECKLIST_APPEARANCE"))

local SettingsHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsHint:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", 0, -8)
SettingsHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
SettingsHint:SetJustifyH("LEFT")
SettingsHint:SetJustifyV("TOP")
SettingsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SettingsHint:SetTextColor(0.78, 0.74, 0.69, 1)
SettingsHint:SetText(L("CHECKLIST_APPEARANCE_HINT"))

local trackerEnabledLabel, trackerEnabledHint
TrackerEnabledCheckbox, trackerEnabledLabel, trackerEnabledHint = CreateSectionCheckbox(
    SettingsPanel,
    SettingsHint,
    L("CHECKLIST_SHOW_TRACKER"),
    L("CHECKLIST_SHOW_TRACKER_HINT")
)

local showBuiltInLabel, showBuiltInHint
TrackerShowBuiltInCheckbox, showBuiltInLabel, showBuiltInHint = CreateSectionCheckbox(
    SettingsPanel,
    trackerEnabledHint,
    L("CHECKLIST_SHOW_BUILTIN"),
    L("CHECKLIST_SHOW_BUILTIN_HINT")
)

local showManualLabel, showManualHint
TrackerShowManualCheckbox, showManualLabel, showManualHint = CreateSectionCheckbox(
    SettingsPanel,
    showBuiltInHint,
    L("CHECKLIST_SHOW_MANUAL"),
    L("CHECKLIST_SHOW_MANUAL_HINT")
)
TrackerShowManualCheckbox:ClearAllPoints()
TrackerShowManualCheckbox:SetPoint("TOPLEFT", showBuiltInHint, "BOTTOMLEFT", -34, -14)

TrackerHideCompletedCheckbox = CreateFrame("CheckButton", nil, SettingsPanel, "UICheckButtonTemplate")
TrackerHideCompletedCheckbox:SetPoint("TOPLEFT", showManualHint, "BOTTOMLEFT", -34, -14)

local TrackerHideCompletedLabel = SettingsPanel:CreateFontString(nil, "OVERLAY")
TrackerHideCompletedLabel:SetPoint("LEFT", TrackerHideCompletedCheckbox, "RIGHT", 6, 0)
TrackerHideCompletedLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrackerHideCompletedLabel:SetTextColor(0.95, 0.91, 0.85, 1)
TrackerHideCompletedLabel:SetText(L("CHECKLIST_HIDE_COMPLETED"))

local TrackerHideCompletedHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
TrackerHideCompletedHint:SetPoint("TOPLEFT", TrackerHideCompletedCheckbox, "BOTTOMLEFT", 34, -2)
TrackerHideCompletedHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
TrackerHideCompletedHint:SetJustifyH("LEFT")
TrackerHideCompletedHint:SetJustifyV("TOP")
TrackerHideCompletedHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrackerHideCompletedHint:SetTextColor(0.78, 0.74, 0.69, 1)
TrackerHideCompletedHint:SetText(L("CHECKLIST_HIDE_COMPLETED_HINT"))

local trackerMinimapContextLabel, trackerMinimapContextHint
TrackerMinimapContextCheckbox, trackerMinimapContextLabel, trackerMinimapContextHint = CreateSectionCheckbox(
    SettingsPanel,
    TrackerHideCompletedHint,
    L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"),
    L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT")
)
TrackerMinimapContextCheckbox:ClearAllPoints()
TrackerMinimapContextCheckbox:SetPoint("TOPLEFT", TrackerHideCompletedHint, "BOTTOMLEFT", -64, -14)

FontSizeSlider = CreateValueSlider(SettingsPanel, L("CHECKLIST_TRACKER_FONT_SIZE"), 10, 16, 1, "font")
FontSizeSlider:SetPoint("TOPLEFT", trackerMinimapContextHint, "BOTTOMLEFT", 18, -34)

BackgroundAlphaSlider = CreateValueSlider(SettingsPanel, L("BACKGROUND_ALPHA"), 0.15, 0.70, 0.05, "alpha")
BackgroundAlphaSlider:SetPoint("TOPLEFT", FontSizeSlider, "BOTTOMLEFT", 0, -44)

local ResetChecksButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetChecksButton:SetSize(170, 26)
ResetChecksButton:SetPoint("TOPLEFT", BackgroundAlphaSlider, "BOTTOMLEFT", -18, -28)
ResetChecksButton:SetText(L("CHECKLIST_RESET_CHECKS"))
ResetChecksButton:SetScript("OnClick", function()
    Checklist.ResetAllTodoChecks()
end)

local ResetBuiltInButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetBuiltInButton:SetSize(190, 26)
ResetBuiltInButton:SetPoint("LEFT", ResetChecksButton, "RIGHT", 10, 0)
ResetBuiltInButton:SetText(L("CHECKLIST_RESET_BUILTIN"))
ResetBuiltInButton:SetScript("OnClick", function()
    Checklist.ResetBuiltInTodos()
end)

local ResetTrackerButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetTrackerButton:SetSize(210, 26)
ResetTrackerButton:SetPoint("TOPLEFT", ResetChecksButton, "BOTTOMLEFT", 0, -12)
ResetTrackerButton:SetText(L("CHECKLIST_RESET_TRACKER"))
ResetTrackerButton:SetScript("OnClick", function()
    Checklist.ResetTrackerWindow()
end)

local function UpdateManualControlPanelHeight()
    ManualControlPanel:SetHeight(GetMeasuredPanelHeight(ManualControlPanel, ManualCategoryHint, 168, 22))
end

local function UpdateChecklistSettingsPanelHeight()
    SettingsPanel:SetHeight(GetMeasuredPanelHeight(SettingsPanel, ResetTrackerButton, 540, 22))
end

FontSizeSlider.ApplyValue = function(_, value)
    Checklist.SetTrackerFontSize(value)
end

BackgroundAlphaSlider.ApplyValue = function(_, value)
    Checklist.SetTrackerBackgroundAlpha(value)
end

TrackerEnabledCheckbox:SetScript("OnClick", function(self)
    Checklist.SetTrackerEnabled(self:GetChecked())
    PageChecklist:RefreshState()
end)

TrackerShowBuiltInCheckbox:SetScript("OnClick", function(self)
    Checklist.SetShowBuiltInInTracker(self:GetChecked())
end)

TrackerShowManualCheckbox:SetScript("OnClick", function(self)
    Checklist.SetShowManualInTracker(self:GetChecked())
end)

TrackerHideCompletedCheckbox:SetScript("OnClick", function(self)
    Checklist.SetHideCompletedInTracker(self:GetChecked())
end)

TrackerMinimapContextCheckbox:SetScript("OnClick", function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("checklist", self:GetChecked())
    end
end)

local function UpdateManualCadenceSelectionButtons()
    ManualCadenceDailyButton:SetEnabled(selectedManualCadence ~= "daily")
    ManualCadenceWeeklyButton:SetEnabled(selectedManualCadence ~= "weekly")
    ManualCadenceWatchButton:SetEnabled(selectedManualCadence ~= "watch")
end

ManualCadenceDailyButton:SetScript("OnClick", function()
    selectedManualCadence = "daily"
    UpdateManualCadenceSelectionButtons()
end)

ManualCadenceWeeklyButton:SetScript("OnClick", function()
    selectedManualCadence = "weekly"
    UpdateManualCadenceSelectionButtons()
end)

ManualCadenceWatchButton:SetScript("OnClick", function()
    selectedManualCadence = "watch"
    UpdateManualCadenceSelectionButtons()
end)

local function GetOrCreateCategoryRow(rowTable, parent, index)
    -- Rows werden wiederverwendet statt jedes Mal neu gebaut.
    local row = rowTable[index]
    if row then
        return row
    end

    row = CreateBuiltInTodoRow(parent)
    row.Checkbox:SetScript("OnClick", function(self)
        local parentRow = self:GetParent()

        if parentRow.entryType == "builtin" then
            Checklist.SetBuiltInTodoChecked(parentRow.todoID, self:GetChecked())
        else
            Checklist.SetManualTodoChecked(parentRow.todoID, self:GetChecked())
        end
    end)
    row.EnabledCheckbox:SetScript("OnClick", function(self)
        Checklist.SetBuiltInTodoEnabled(self:GetParent().todoID, self:GetChecked())
    end)
    row.ActionButton:SetScript("OnClick", function(self)
        local parentRow = self:GetParent()
        local nextCadence = GetNextManualCadence(parentRow.cadence)
        Checklist.SetManualTodoCadence(parentRow.todoID, nextCadence)
    end)
    row.DeleteButton:SetScript("OnClick", function(self)
        Checklist.DeleteManualTodo(self:GetParent().todoID)
    end)

    rowTable[index] = row
    return row
end

local function LayoutChecklistPanel(panel, rowTable, emptyText, cadence)
    -- Baut einen kompletten Kategorienblock der Hauptseite neu auf.
    local currentY = GetChecklistPanelContentStartOffset(panel, panel.ContentAnchor, -72, 18)
    local rowSpacing = 8
    local panelWidth = math.max(220, panel:GetWidth())
    local visibleCount = 0

    for _, row in ipairs(rowTable) do
        row:Hide()
    end

    local function LayoutBuiltInRow(todo)
        visibleCount = visibleCount + 1
        local row = GetOrCreateCategoryRow(rowTable, panel, visibleCount)
        local checked = GetBuiltInTodoState(todo.id)
        local enabled = IsBuiltInTodoEnabled(todo.id)

        row.entryType = "builtin"
        row.todoID = todo.id
        row.cadence = cadence
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
        row:SetPoint("RIGHT", panel, "RIGHT", -18, 0)

        row.ActionButton:Hide()
        row.DeleteButton:Hide()
        row.EnabledCheckbox:Show()
        row.EnabledLabel:Show()
        row.EnabledCheckbox:ClearAllPoints()
        row.EnabledCheckbox:SetPoint("TOPRIGHT", row, "TOPRIGHT", -42, 2)

        row.Label:SetWidth(math.max(120, panelWidth - 138))
        row.Label:SetText(todo.label)
        row.Checkbox:SetChecked(checked)
        row.EnabledCheckbox:SetChecked(enabled)

        if not enabled then
            row.Checkbox:Disable()
            row.Label:SetTextColor(0.45, 0.45, 0.45, 1)
        elseif checked then
            row.Checkbox:Enable()
            row.Label:SetTextColor(0.72, 0.72, 0.72, 1)
        else
            row.Checkbox:Enable()
            row.Label:SetTextColor(0.95, 0.91, 0.85, 1)
        end

        row.EnabledLabel:SetTextColor(0.78, 0.78, 0.78, 1)

        local rowHeight = math.max(24, math.ceil(row.Label:GetStringHeight()) + 6)
        row:SetHeight(rowHeight)
        row:Show()

        currentY = currentY - rowHeight - rowSpacing
    end

    local function LayoutManualRow(item)
        visibleCount = visibleCount + 1
        local row = GetOrCreateCategoryRow(rowTable, panel, visibleCount)

        row.entryType = "manual"
        row.todoID = item.id
        row.cadence = NormalizeManualCadence(item.cadence)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
        row:SetPoint("RIGHT", panel, "RIGHT", -18, 0)

        row.EnabledCheckbox:Hide()
        row.EnabledLabel:Hide()
        row.ActionButton:Show()
        row.DeleteButton:Show()

        row.DeleteButton:ClearAllPoints()
        row.DeleteButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        row.ActionButton:ClearAllPoints()
        row.ActionButton:SetPoint("TOPRIGHT", row.DeleteButton, "TOPLEFT", -8, 0)
        row.ActionButton:SetText(GetManualCadenceLabel(GetNextManualCadence(row.cadence)))

        row.Label:SetWidth(math.max(120, panelWidth - 190))
        row.Label:SetText(item.text)
        row.Checkbox:SetChecked(item.checked)
        row.Checkbox:Enable()

        if item.checked then
            row.Label:SetTextColor(0.72, 0.72, 0.72, 1)
        else
            row.Label:SetTextColor(0.95, 0.91, 0.85, 1)
        end

        local rowHeight = math.max(24, math.ceil(row.Label:GetStringHeight()) + 6)
        row:SetHeight(rowHeight)
        row:Show()

        currentY = currentY - rowHeight - rowSpacing
    end

    for _, todo in ipairs(GetBuiltInTodos()) do
        if GetTodoCadence(todo.id) == cadence then
            LayoutBuiltInRow(todo)
        end
    end

    for _, item in ipairs(GetManualItems()) do
        if NormalizeManualCadence(item.cadence) == cadence then
            LayoutManualRow(item)
        end
    end

    if visibleCount == 0 then
        emptyText:ClearAllPoints()
        emptyText:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
        emptyText:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
        emptyText:Show()
        currentY = currentY - 34
    else
        emptyText:Hide()
    end

    panel:SetHeight((-currentY) + 14)
end

function PageChecklist:RefreshState()
    -- Zentraler Seiten-Refresh für Zahlen, Zeilen, Slider und Tracker-Optionen.
    ProcessChecklistResets()

    local completedCount, totalCount = GetChecklistCounts()
    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("Checklist", L("CHECKLIST")))
    IntroText:SetText(L("CHECKLIST_DESC"))
    IntroSummaryValue:SetText(L("CHECKLIST_SUMMARY"):format(completedCount, totalCount))
    IntroHint:SetText(L("CHECKLIST_INTRO_HINT"))
    UpdateIntroPanelHeight()

    WatchTitle:SetText(L("CHECKLIST_WATCH"))
    WatchHint:SetText(L("CHECKLIST_WATCH_HINT"))
    WatchEmptyText:SetText(L("CHECKLIST_EMPTY_WATCH"))
    DailyTitle:SetText(L("DAILY"))
    DailyHint:SetText(L("CHECKLIST_DAILY_HINT"))
    DailyEmptyText:SetText(L("CHECKLIST_EMPTY_DAILY"))
    WeeklyTitle:SetText(L("WEEKLY"))
    WeeklyHint:SetText(L("CHECKLIST_WEEKLY_HINT"))
    WeeklyEmptyText:SetText(L("CHECKLIST_EMPTY_WEEKLY"))
    ManualControlTitle:SetText(L("CHECKLIST_MANUAL_ADD_TITLE"))
    ManualControlHint:SetText(L("CHECKLIST_MANUAL_ADD_HINT"))
    ManualAddLabel:SetText(L("CHECKLIST_MANUAL_ADD_LABEL"))
    ManualCadenceDailyButton:SetText(L("DAILY"))
    ManualCadenceWeeklyButton:SetText(L("WEEKLY"))
    ManualCadenceWatchButton:SetText(L("CHECKLIST_WATCH_SHORT"))
    ManualAddButton:SetText(L("ADD"))
    ManualCategoryHint:SetText(L("CHECKLIST_MANUAL_CATEGORY_HINT"))
    SettingsTitle:SetText(L("CHECKLIST_APPEARANCE"))
    SettingsHint:SetText(L("CHECKLIST_APPEARANCE_HINT"))
    trackerEnabledLabel:SetText(L("CHECKLIST_SHOW_TRACKER"))
    trackerEnabledHint:SetText(L("CHECKLIST_SHOW_TRACKER_HINT"))
    showBuiltInLabel:SetText(L("CHECKLIST_SHOW_BUILTIN"))
    showBuiltInHint:SetText(L("CHECKLIST_SHOW_BUILTIN_HINT"))
    showManualLabel:SetText(L("CHECKLIST_SHOW_MANUAL"))
    showManualHint:SetText(L("CHECKLIST_SHOW_MANUAL_HINT"))
    TrackerHideCompletedLabel:SetText(L("CHECKLIST_HIDE_COMPLETED"))
    TrackerHideCompletedHint:SetText(L("CHECKLIST_HIDE_COMPLETED_HINT"))
    trackerMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    trackerMinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))
    ResetChecksButton:SetText(L("CHECKLIST_RESET_CHECKS"))
    ResetBuiltInButton:SetText(L("CHECKLIST_RESET_BUILTIN"))
    ResetTrackerButton:SetText(L("CHECKLIST_RESET_TRACKER"))

    LayoutChecklistPanel(WatchPanel, WatchRows, WatchEmptyText, "watch")
    LayoutChecklistPanel(DailyPanel, DailyRows, DailyEmptyText, "daily")
    LayoutChecklistPanel(WeeklyPanel, WeeklyRows, WeeklyEmptyText, "weekly")
    UpdateManualControlPanelHeight()
    UpdateChecklistSettingsPanelHeight()
    UpdateManualCadenceSelectionButtons()

    isRefreshing = true
    TrackerEnabledCheckbox:SetChecked(Checklist.IsTrackerEnabled())
    TrackerShowBuiltInCheckbox:SetChecked(Checklist.GetShowBuiltInInTracker())
    TrackerShowManualCheckbox:SetChecked(Checklist.GetShowManualInTracker())
    TrackerHideCompletedCheckbox:SetChecked(Checklist.GetHideCompletedInTracker())
    TrackerMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("checklist") or true)
    FontSizeSlider:SetValue(Checklist.GetTrackerFontSize())
    BackgroundAlphaSlider:SetValue(Checklist.GetTrackerBackgroundAlpha())
    FontSizeSlider.Text:SetText(L("CHECKLIST_TRACKER_FONT_SIZE"))
    BackgroundAlphaSlider.Text:SetText(L("BACKGROUND_ALPHA"))
    isRefreshing = false

    self:UpdateScrollLayout()
end

function PageChecklist:UpdateScrollLayout()
    -- Der Scrollbereich richtet sich nach den echten Panelhoehen.
    local contentWidth = math.max(1, PageChecklistScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + WatchPanel:GetHeight()
        + 18 + DailyPanel:GetHeight()
        + 18 + WeeklyPanel:GetHeight()
        + 18 + ManualControlPanel:GetHeight()
        + 18 + SettingsPanel:GetHeight()
        + 20

    PageChecklistContent:SetWidth(contentWidth)
    PageChecklistContent:SetHeight(contentHeight)

    local maxScroll = math.max(0, PageChecklistContent:GetHeight() - PageChecklistScrollFrame:GetHeight())
    if PageChecklistScrollFrame:GetVerticalScroll() > maxScroll then
        PageChecklistScrollFrame:SetVerticalScroll(maxScroll)
    end
end

OpenChecklistSettingsSection = function()
    if BeavisQoL.OpenPage then
        BeavisQoL.OpenPage("Checklist")
    elseif BeavisQoL.Frame then
        if not BeavisQoL.Frame:IsShown() then
            BeavisQoL.Frame:Show()
        end

        if BeavisQoL.Pages then
            for _, page in pairs(BeavisQoL.Pages) do
                page:Hide()
            end
        end

        if PageChecklist then
            PageChecklist:Show()
        end
    end

    if not PageChecklist or not PageChecklistScrollFrame or not PageChecklistContent or not SettingsPanel then
        return
    end

    PageChecklist:RefreshState()

    local function ScrollToSettingsPanel()
        local contentTop = PageChecklistContent:GetTop()
        local settingsTop = SettingsPanel:GetTop()

        if not contentTop or not settingsTop then
            return
        end

        local maxScroll = math.max(0, PageChecklistContent:GetHeight() - PageChecklistScrollFrame:GetHeight())
        local targetScroll = Clamp(math.floor((contentTop - settingsTop) + 8), 0, maxScroll)
        PageChecklistScrollFrame:SetVerticalScroll(targetScroll)
    end

    ScrollToSettingsPanel()

    if C_Timer and C_Timer.After then
        C_Timer.After(0, ScrollToSettingsPanel)
    end
end

PageChecklistScrollFrame:SetScript("OnSizeChanged", function()
    PageChecklist:RefreshState()
end)

PageChecklistScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageChecklistContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageChecklist:SetScript("OnShow", function()
    PageChecklist:RefreshState()
    PageChecklistScrollFrame:SetVerticalScroll(0)
end)

PageChecklist:RefreshState()

BeavisQoL.Pages.Checklist = PageChecklist

local ChecklistWatcher = CreateFrame("Frame")
ChecklistWatcher:RegisterEvent("PLAYER_LOGIN")
ChecklistWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ChecklistWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ChecklistWatcher:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
ChecklistWatcher:RegisterEvent("UPDATE_INSTANCE_INFO")
ChecklistWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
ChecklistWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
ChecklistWatcher:SetScript("OnEvent", function(_, eventName)
    GetChecklistSettings()
    GetChecklistCharacterData()

    local didProcessResets = ProcessChecklistResets()

    if eventName == "PLAYER_LOGIN" then
        ApplyTrackerGeometry()
        Checklist.RefreshAllViews()
        return
    end

    RefreshChecklistTrackerForContextChange()

    if didProcessResets and PageChecklist and PageChecklist:IsShown() then
        PageChecklist:RefreshState()
    end
end)

local function HandleChecklistResetTicker()
    if ProcessChecklistResets() then
        Checklist.RefreshAllViews()
    end
end

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(CHECKLIST_RESET_INTERVAL, function()
        local profiler = BeavisQoL.PerformanceProfiler
        local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
        HandleChecklistResetTicker()
        if profiler and profiler.EndSample then
            profiler.EndSample("Checklist.ResetTicker", sampleToken)
        end
    end)
else
    local resetTickerElapsed = 0
    local ChecklistResetTicker = CreateFrame("Frame")
    ChecklistResetTicker:SetScript("OnUpdate", function(_, elapsed)
        resetTickerElapsed = resetTickerElapsed + elapsed
        if resetTickerElapsed < CHECKLIST_RESET_INTERVAL then
            return
        end

        resetTickerElapsed = 0
        local profiler = BeavisQoL.PerformanceProfiler
        local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
        HandleChecklistResetTicker()
        if profiler and profiler.EndSample then
            profiler.EndSample("Checklist.ResetTicker", sampleToken)
        end
    end)
end

local function HandleChecklistTrackerVisibility()
    if not TrackerFrame then
        return
    end

    local settings = GetChecklistSettings()
    local shouldShowTracker = settings.trackerEnabled and not ShouldHideTrackerInCombat()

    if TrackerFrame:IsShown() ~= shouldShowTracker then
        Checklist.RefreshTrackerWindow()
    end
end

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(CHECKLIST_TRACKER_VISIBILITY_INTERVAL, function()
        local profiler = BeavisQoL.PerformanceProfiler
        local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
        HandleChecklistTrackerVisibility()
        if profiler and profiler.EndSample then
            profiler.EndSample("Checklist.TrackerVisibility", sampleToken)
        end
    end)
else
    local trackerVisibilityCheckElapsed = 0
    local ChecklistTrackerVisibilityWatcher = CreateFrame("Frame")
    ChecklistTrackerVisibilityWatcher:SetScript("OnUpdate", function(_, elapsed)
        trackerVisibilityCheckElapsed = trackerVisibilityCheckElapsed + elapsed
        if trackerVisibilityCheckElapsed < CHECKLIST_TRACKER_VISIBILITY_INTERVAL then
            return
        end

        trackerVisibilityCheckElapsed = 0
        local profiler = BeavisQoL.PerformanceProfiler
        local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
        HandleChecklistTrackerVisibility()
        if profiler and profiler.EndSample then
            profiler.EndSample("Checklist.TrackerVisibility", sampleToken)
        end
    end)
end

