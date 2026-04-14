local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local baseGetMiscDB = Misc.GetMiscDB
local ReminderWatcher = CreateFrame("Frame")
local ReminderFrame = nil
local ReminderTimer = nil
local REMINDER_DURATION_SECONDS = 10
local REMINDER_FRAME_WIDTH = 324
local REMINDER_FRAME_HEIGHT = 134
local REMINDER_ICON_SIZE = 18
local REMINDER_ROW_HEIGHT = 38
local UpdateReminderFrameAnchor

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
        return nil, nil, nil, nil
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        return nil, nil, nil, nil
    end

    local specID, specName, _, specIcon = GetSpecializationInfo(specIndex)
    return specIndex, specID, specName, specIcon
end

local function GetSpecDisplayInfo(specID)
    if type(specID) ~= "number" or specID <= 0 or type(GetSpecializationInfoByID) ~= "function" then
        return nil, nil
    end

    local _, specName, _, specIcon = GetSpecializationInfoByID(specID)
    return specName, specIcon
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

local function GetCurrentLoadoutDisplayInfo()
    local _, _, _, specIcon = GetCurrentSpecInfo()
    return GetCurrentLoadoutName(), specIcon
end

local function GetCurrentLootSettingDisplayInfo()
    local _, currentSpecID, currentSpecName, currentSpecIcon = GetCurrentSpecInfo()

    if type(GetLootSpecialization) == "function" then
        local lootSpecID = GetLootSpecialization()
        if type(lootSpecID) == "number" and lootSpecID > 0 then
            local lootSpecName, lootSpecIcon = GetSpecDisplayInfo(lootSpecID)
            if type(lootSpecName) == "string" and lootSpecName ~= "" then
                return lootSpecName, lootSpecIcon
            end
        end
    end

    if type(currentSpecName) == "string" and currentSpecName ~= "" then
        return L("TALENT_LOADOUT_REMINDER_LOOT_CURRENT_SPEC_FORMAT"):format(currentSpecName), currentSpecIcon
    end

    if type(currentSpecID) == "number" and currentSpecID > 0 then
        local fallbackSpecName, fallbackSpecIcon = GetSpecDisplayInfo(currentSpecID)
        if type(fallbackSpecName) == "string" and fallbackSpecName ~= "" then
            return L("TALENT_LOADOUT_REMINDER_LOOT_CURRENT_SPEC_FORMAT"):format(fallbackSpecName), fallbackSpecIcon
        end
    end

    return L("TALENT_LOADOUT_REMINDER_LOOT_UNKNOWN"), nil
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
    frame:SetSize(REMINDER_FRAME_WIDTH, REMINDER_FRAME_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:Hide()
    UpdateReminderFrameAnchor(frame)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.05, 0.035, 0.02, 0.84)

    local innerShade = frame:CreateTexture(nil, "ARTWORK")
    innerShade:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    innerShade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    innerShade:SetColorTexture(0.18, 0.11, 0.06, 0.28)

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
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)

    local closeButtonText = closeButton:CreateFontString(nil, "OVERLAY")
    closeButtonText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeButtonText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    closeButtonText:SetTextColor(0.95, 0.86, 0.72, 0.82)
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
    warningText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    warningText:SetPoint("RIGHT", closeButton, "LEFT", -8, 0)
    warningText:SetJustifyH("LEFT")
    warningText:SetJustifyV("TOP")
    warningText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    warningText:SetTextColor(1, 0.36, 0.28, 1)
    warningText:SetText(L("TALENT_LOADOUT_REMINDER_WARNING"))

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", warningText, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(0.95, 0.78, 0.48, 0.28)

    local function CreateReminderInfoRow(anchorTo)
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -10)
        row:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
        row:SetHeight(REMINDER_ROW_HEIGHT)

        row.Background = row:CreateTexture(nil, "BACKGROUND")
        row.Background:SetAllPoints()
        row.Background:SetColorTexture(0.10, 0.07, 0.045, 0.88)

        row.Border = row:CreateTexture(nil, "ARTWORK")
        row.Border:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.Border:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        row.Border:SetWidth(2)
        row.Border:SetColorTexture(0.95, 0.78, 0.48, 0.85)

        row.Highlight = row:CreateTexture(nil, "ARTWORK")
        row.Highlight:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.Highlight:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        row.Highlight:SetHeight(1)
        row.Highlight:SetColorTexture(1, 0.88, 0.62, 0.18)

        row.Label = row:CreateFontString(nil, "OVERLAY")
        row.Label:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
        row.Label:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.Label:SetJustifyH("LEFT")
        row.Label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        row.Label:SetTextColor(0.98, 0.84, 0.56, 0.92)

        row.Icon = row:CreateTexture(nil, "OVERLAY")
        row.Icon:SetSize(REMINDER_ICON_SIZE, REMINDER_ICON_SIZE)
        row.Icon:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 7)
        row.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.Value = row:CreateFontString(nil, "OVERLAY")
        row.Value:SetPoint("LEFT", row.Icon, "RIGHT", 8, 0)
        row.Value:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.Value:SetJustifyH("LEFT")
        row.Value:SetJustifyV("MIDDLE")
        row.Value:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        row.Value:SetWordWrap(false)

        return row
    end

    local loadoutRow = CreateReminderInfoRow(divider)
    local lootRow = CreateReminderInfoRow(loadoutRow)
    loadoutRow.Value:SetTextColor(1, 0.90, 0.66, 1)
    lootRow.Value:SetTextColor(0.94, 0.94, 0.96, 1)

    frame.WarningText = warningText
    frame.CurrentLoadoutLabel = loadoutRow.Label
    frame.CurrentLootLabel = lootRow.Label
    frame.LoadoutIcon = loadoutRow.Icon
    frame.LoadoutNameText = loadoutRow.Value
    frame.LootIcon = lootRow.Icon
    frame.LootSettingText = lootRow.Value

    ReminderFrame = frame
    return frame
end

UpdateReminderFrameAnchor = function(frame)
    if not frame then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, -118)
end

local function SetReminderRowDisplay(icon, textWidget, textValue, iconTexture)
    local parent = textWidget and textWidget:GetParent() or nil

    if icon and iconTexture then
        icon:SetTexture(iconTexture)
        icon:Show()
        textWidget:ClearAllPoints()
        textWidget:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        textWidget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    elseif icon then
        icon:SetTexture(nil)
        icon:Hide()
        textWidget:ClearAllPoints()
        textWidget:SetPoint("LEFT", parent, "LEFT", 0, 0)
        textWidget:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    end

    textWidget:SetText(textValue or "")
end

local function ShowReminderFrame()
    local frame = EnsureReminderFrame()
    local loadoutName, loadoutIcon = GetCurrentLoadoutDisplayInfo()
    local lootSettingName, lootSettingIcon = GetCurrentLootSettingDisplayInfo()

    UpdateReminderFrameAnchor(frame)
    frame.WarningText:SetText(L("TALENT_LOADOUT_REMINDER_WARNING"))
    frame.CurrentLoadoutLabel:SetText(L("TALENT_LOADOUT_REMINDER_CURRENT"))
    frame.CurrentLootLabel:SetText(L("TALENT_LOADOUT_REMINDER_LOOT"))
    SetReminderRowDisplay(frame.LoadoutIcon, frame.LoadoutNameText, loadoutName, loadoutIcon)
    SetReminderRowDisplay(frame.LootIcon, frame.LootSettingText, lootSettingName, lootSettingIcon)
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
