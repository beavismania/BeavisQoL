local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local baseGetMiscDB = Misc.GetMiscDB
local ReminderWatcher = CreateFrame("Frame")
local ReminderFrame = nil
local ReminderTimer = nil
local REMINDER_DURATION_SECONDS = 10

local function CancelReminderTimer()
    if ReminderTimer and ReminderTimer.Cancel then
        pcall(ReminderTimer.Cancel, ReminderTimer)
    end

    ReminderTimer = nil
end

local function HideReminderFrame()
    CancelReminderTimer()

    if ReminderFrame then
        ReminderFrame:Hide()
    end
end

local function GetCurrentSpecInfo()
    if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
        return nil, nil, nil
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        return nil, nil, nil
    end

    local specID, specName = GetSpecializationInfo(specIndex)
    return specIndex, specID, specName
end

local function GetConfigName(configID)
    if type(configID) ~= "number" or not C_Traits or type(C_Traits.GetConfigInfo) ~= "function" then
        return nil
    end

    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if ok and type(configInfo) == "table" and type(configInfo.name) == "string" and configInfo.name ~= "" then
        return configInfo.name
    end

    return nil
end

local function GetConfigExportString(configID)
    if type(configID) ~= "number" or not C_Traits or type(C_Traits.GenerateImportString) ~= "function" then
        return nil
    end

    local ok, exportString = pcall(C_Traits.GenerateImportString, configID)
    if ok and type(exportString) == "string" and exportString ~= "" then
        return exportString
    end

    return nil
end

local function GetActiveConfigID()
    if C_ClassTalents and type(C_ClassTalents.GetActiveConfigID) == "function" then
        return C_ClassTalents.GetActiveConfigID()
    end

    return nil
end

local function GetLastSelectedSavedConfigID(specID)
    if type(specID) ~= "number" or not C_ClassTalents or type(C_ClassTalents.GetLastSelectedSavedConfigID) ~= "function" then
        return nil
    end

    return C_ClassTalents.GetLastSelectedSavedConfigID(specID)
end

local function BuildLoadoutOptions(specID)
    if type(specID) ~= "number" or not C_ClassTalents or type(C_ClassTalents.GetConfigIDsBySpecID) ~= "function" then
        return {}
    end

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    local orderedEntries = {}
    for order, configID in pairs(configIDs) do
        if type(configID) == "number" then
            orderedEntries[#orderedEntries + 1] = {
                order = type(order) == "number" and order or (#orderedEntries + 1),
                configID = configID,
            }
        end
    end

    table.sort(orderedEntries, function(left, right)
        if left.order == right.order then
            return left.configID < right.configID
        end

        return left.order < right.order
    end)

    local options = {}
    for index, entry in ipairs(orderedEntries) do
        local configID = entry.configID
        local name = GetConfigName(configID)
        if not name or name == "" then
            name = L("CHONKY_LOADOUT_FALLBACK_NAME"):format(index)
        end

        options[#options + 1] = {
            configID = configID,
            name = name,
        }
    end

    return options
end

local function FindLoadoutOptionByConfigID(options, configID)
    if type(configID) ~= "number" then
        return nil
    end

    for _, option in ipairs(options or {}) do
        if option.configID == configID then
            return option
        end
    end

    return nil
end

local function FindLoadoutOptionByExportString(options, exportString)
    if type(exportString) ~= "string" or exportString == "" then
        return nil
    end

    for _, option in ipairs(options or {}) do
        if option.exportString == nil then
            option.exportString = GetConfigExportString(option.configID) or false
        end

        if option.exportString == exportString then
            return option
        end
    end

    return nil
end

local function GetCurrentLoadoutName()
    local _, specID, specName = GetCurrentSpecInfo()
    local options = BuildLoadoutOptions(specID)
    local activeConfigID = GetActiveConfigID()
    local selectedSavedConfigID = GetLastSelectedSavedConfigID(specID)

    local activeOption = FindLoadoutOptionByConfigID(options, activeConfigID)
    if activeOption then
        return activeOption.name
    end

    local activeExportString = GetConfigExportString(activeConfigID)
    local activeExportOption = FindLoadoutOptionByExportString(options, activeExportString)
    if activeExportOption then
        return activeExportOption.name
    end

    local selectedSavedOption = FindLoadoutOptionByConfigID(options, selectedSavedConfigID)
    if selectedSavedOption then
        return selectedSavedOption.name
    end

    local selectedSavedName = GetConfigName(selectedSavedConfigID)
    if selectedSavedName and selectedSavedName ~= specName then
        return selectedSavedName
    end

    local activeConfigName = GetConfigName(activeConfigID)
    if activeConfigName and activeConfigName ~= specName then
        return activeConfigName
    end

    if #options == 0 then
        return L("CHONKY_LOADOUT_NO_LOADOUTS")
    end

    return L("CHONKY_LOADOUT_NONE")
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

    if db.talentLoadoutReminder == nil then
        db.talentLoadoutReminder = false
    end

    return db
end

function Misc.IsTalentLoadoutReminderEnabled()
    return Misc.GetMiscDB().talentLoadoutReminder == true
end

function Misc.SetTalentLoadoutReminderEnabled(value)
    Misc.GetMiscDB().talentLoadoutReminder = value and true or false

    if not Misc.IsTalentLoadoutReminderEnabled() then
        HideReminderFrame()
    end
end

local function EnsureReminderFrame()
    if ReminderFrame then
        return ReminderFrame
    end

    local frame = CreateFrame("Frame", "BeavisQoLTalentLoadoutReminderFrame", UIParent)
    frame:SetSize(340, 126)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -118)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:Hide()

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.03, 0.02, 0.62)

    local innerShade = frame:CreateTexture(nil, "ARTWORK")
    innerShade:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    innerShade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    innerShade:SetColorTexture(0.12, 0.08, 0.05, 0.32)

    local borderTop = frame:CreateTexture(nil, "OVERLAY")
    borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.95, 0.78, 0.48, 0.82)

    local borderBottom = frame:CreateTexture(nil, "OVERLAY")
    borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.95, 0.78, 0.48, 0.82)

    local borderLeft = frame:CreateTexture(nil, "OVERLAY")
    borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -1)
    borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0.95, 0.78, 0.48, 0.62)

    local borderRight = frame:CreateTexture(nil, "OVERLAY")
    borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -1)
    borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0.95, 0.78, 0.48, 0.62)

    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    local closeButtonText = closeButton:CreateFontString(nil, "OVERLAY")
    closeButtonText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeButtonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    closeButtonText:SetTextColor(0.95, 0.86, 0.72, 0.92)
    closeButtonText:SetText("x")

    closeButton:SetScript("OnClick", function()
        HideReminderFrame()
    end)

    closeButton:SetScript("OnEnter", function()
        closeButtonText:SetTextColor(1, 0.95, 0.88, 1)
    end)

    closeButton:SetScript("OnLeave", function()
        closeButtonText:SetTextColor(0.95, 0.86, 0.72, 0.92)
    end)

    local warningText = frame:CreateFontString(nil, "OVERLAY")
    warningText:SetPoint("TOP", frame, "TOP", 0, -18)
    warningText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    warningText:SetTextColor(1, 0.36, 0.28, 1)
    warningText:SetText(L("TALENT_LOADOUT_REMINDER_WARNING"))

    local currentLoadoutLabel = frame:CreateFontString(nil, "OVERLAY")
    currentLoadoutLabel:SetPoint("TOP", warningText, "BOTTOM", 0, -12)
    currentLoadoutLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    currentLoadoutLabel:SetTextColor(0.95, 0.91, 0.85, 0.96)
    currentLoadoutLabel:SetText(L("TALENT_LOADOUT_REMINDER_CURRENT"))

    local loadoutNameText = frame:CreateFontString(nil, "OVERLAY")
    loadoutNameText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -78)
    loadoutNameText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -78)
    loadoutNameText:SetJustifyH("CENTER")
    loadoutNameText:SetJustifyV("TOP")
    loadoutNameText:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
    loadoutNameText:SetTextColor(1, 0.88, 0.62, 1)
    loadoutNameText:SetWordWrap(true)
    loadoutNameText:SetText("")

    frame.WarningText = warningText
    frame.CurrentLoadoutLabel = currentLoadoutLabel
    frame.LoadoutNameText = loadoutNameText

    ReminderFrame = frame
    return frame
end

local function ShowReminderFrame()
    local frame = EnsureReminderFrame()
    frame.WarningText:SetText(L("TALENT_LOADOUT_REMINDER_WARNING"))
    frame.CurrentLoadoutLabel:SetText(L("TALENT_LOADOUT_REMINDER_CURRENT"))
    frame.LoadoutNameText:SetText(GetCurrentLoadoutName())
    frame:Show()

    CancelReminderTimer()
    if C_Timer and type(C_Timer.NewTimer) == "function" then
        ReminderTimer = C_Timer.NewTimer(REMINDER_DURATION_SECONDS, function()
            HideReminderFrame()
        end)
    end
end

ReminderWatcher:RegisterEvent("READY_CHECK")
ReminderWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ReminderWatcher:SetScript("OnEvent", function(_, event)
    if event == "READY_CHECK" then
        if Misc.IsTalentLoadoutReminderEnabled and Misc.IsTalentLoadoutReminderEnabled() then
            ShowReminderFrame()
        end
        return
    end

    HideReminderFrame()
end)
