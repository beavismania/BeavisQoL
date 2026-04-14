local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local L = BeavisQoL.L

local CHONKY_ADDON_NAME = "ChonkyCharacterSheet"
local PAPERDOLL_ADDON_NAME = "Blizzard_UIPanels_Game"
local PLAYER_SPELLS_ADDON_NAME = "Blizzard_PlayerSpells"
local DROPDOWN_NAME = "BeavisQoLChonkyLoadoutDropdown"
local DROPDOWN_WIDTH = 170
local DROPDOWN_HEIGHT = 24
local DROPDOWN_REFRESH_DELAY = 0.05
local DEBUG_MODULE_KEY = "talents"
local DEBUG_MODULE_TITLE = "Talente / Loadouts"

local Watcher = CreateFrame("Frame")
local Dropdown
local DropdownLabel
local RefreshSerial = 0
local PaperDollHookInstalled = false
local LastRequestedSavedConfigIDBySpec = {}

local function PrintAddonMessage(message)
    print(L("ADDON_MESSAGE"):format(message))
end

local function FormatDebugValue(value)
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    end

    if valueType == "boolean" then
        return value and "true" or "false"
    end

    if valueType == "string" then
        if value == "" then
            return "\"\""
        end

        return string.format("%q", value)
    end

    return tostring(value)
end

local function FormatExportPreview(exportString)
    if type(exportString) ~= "string" or exportString == "" then
        return "nil"
    end

    local previewLength = math.min(24, #exportString)
    local preview = string.sub(exportString, 1, previewLength)
    if previewLength < #exportString then
        preview = preview .. "..."
    end

    return string.format("%q (len=%d)", preview, #exportString)
end

local function AppendScalarTable(moduleKey, heading, values)
    if not BeavisQoL.DebugConsole or not BeavisQoL.DebugConsole.AppendLine then
        return
    end

    BeavisQoL.DebugConsole.AppendLine(moduleKey, heading)

    local entries = {}
    for key, value in pairs(values or {}) do
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            entries[#entries + 1] = {
                key = tostring(key),
                value = FormatDebugValue(value),
            }
        end
    end

    table.sort(entries, function(left, right)
        return left.key < right.key
    end)

    if #entries == 0 then
        BeavisQoL.DebugConsole.AppendLine(moduleKey, "  (keine skalaren Felder)")
        return
    end

    for _, entry in ipairs(entries) do
        BeavisQoL.DebugConsole.AppendLine(moduleKey, string.format("  %s = %s", entry.key, entry.value))
    end
end

local function IsChonkyLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(CHONKY_ADDON_NAME) == true
    end

    return rawget(_G, "CCS_PSpecBtn1") ~= nil
end

local function GetSpecInfo()
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

local function GetActiveConfigID()
    if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        return C_ClassTalents.GetActiveConfigID()
    end

    return nil
end

local function GetLastSelectedSavedConfigID(specID)
    if not specID or not C_ClassTalents or not C_ClassTalents.GetLastSelectedSavedConfigID then
        return nil
    end

    return C_ClassTalents.GetLastSelectedSavedConfigID(specID)
end

local function GetConfigInfo(configID)
    if type(configID) ~= "number" or not C_Traits or type(C_Traits.GetConfigInfo) ~= "function" then
        return nil
    end

    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if ok and type(configInfo) == "table" then
        return configInfo
    end

    return nil
end

local function GetConfigName(configID)
    local configInfo = GetConfigInfo(configID)
    if configInfo and type(configInfo.name) == "string" and configInfo.name ~= "" then
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

local function GetOrderedConfigIDs(configIDs)
    local orderedEntries = {}

    for order, configID in pairs(configIDs or {}) do
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

    return orderedEntries
end

local function BuildLoadoutOptions()
    local _, specID = GetSpecInfo()
    if not specID or not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID then
        return {}
    end

    local configIDs = GetOrderedConfigIDs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {})
    local options = {}
    for index, entry in ipairs(configIDs) do
        local configID = entry.configID
        options[#options + 1] = {
            configID = configID,
            index = index,
            name = GetConfigName(configID) or (L("CHONKY_LOADOUT_FALLBACK_NAME"):format(index)),
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

local function FindActiveLoadoutOption(options, activeConfigID)
    local activeOption = FindLoadoutOptionByConfigID(options, activeConfigID)
    if activeOption then
        return activeOption, "configID"
    end

    local activeExportString = GetConfigExportString(activeConfigID)
    local activeExportOption = FindLoadoutOptionByExportString(options, activeExportString)
    if activeExportOption then
        return activeExportOption, "exportString"
    end

    return nil, nil
end

local function SyncLastSelectedSavedConfigID(specID, configID)
    if type(specID) ~= "number"
        or type(configID) ~= "number"
        or not C_ClassTalents
        or type(C_ClassTalents.UpdateLastSelectedSavedConfigID) ~= "function"
    then
        return false
    end

    local currentSavedConfigID = GetLastSelectedSavedConfigID(specID)
    if currentSavedConfigID == configID then
        LastRequestedSavedConfigIDBySpec[specID] = configID
        return false
    end

    if LastRequestedSavedConfigIDBySpec[specID] == configID then
        return false
    end

    local ok = pcall(C_ClassTalents.UpdateLastSelectedSavedConfigID, specID, configID)
    if ok then
        LastRequestedSavedConfigIDBySpec[specID] = configID
    end

    return ok
end

local function TrySyncSavedLoadoutSelection()
    local _, specID = GetSpecInfo()
    if type(specID) ~= "number" then
        return nil, nil
    end

    local options = BuildLoadoutOptions()
    local activeConfigID = GetActiveConfigID()
    local matchedOption, matchMethod = FindActiveLoadoutOption(options, activeConfigID)
    if matchedOption then
        SyncLastSelectedSavedConfigID(specID, matchedOption.configID)
    end

    return matchedOption, matchMethod
end

local function ResolveCurrentLoadoutState()
    local _, specID, specName = GetSpecInfo()
    local options = BuildLoadoutOptions()
    local activeConfigID = GetActiveConfigID()
    local selectedSavedConfigID = GetLastSelectedSavedConfigID(specID)

    local activeOption = FindLoadoutOptionByConfigID(options, activeConfigID)
    if activeOption then
        return activeOption.configID, activeOption.name, options
    end

    local activeExportOption = FindLoadoutOptionByExportString(options, GetConfigExportString(activeConfigID))
    if activeExportOption then
        return activeExportOption.configID, activeExportOption.name, options
    end

    local selectedSavedOption = FindLoadoutOptionByConfigID(options, selectedSavedConfigID)
    if selectedSavedOption then
        return selectedSavedOption.configID, selectedSavedOption.name, options
    end

    local selectedSavedName = GetConfigName(selectedSavedConfigID)
    if selectedSavedName and selectedSavedName ~= specName then
        return selectedSavedConfigID, selectedSavedName, options
    end

    local activeName = GetConfigName(activeConfigID)
    if activeName and activeName ~= specName then
        return activeConfigID, activeName, options
    end

    if #options == 0 then
        return nil, L("CHONKY_LOADOUT_NO_LOADOUTS"), options
    end

    return nil, L("CHONKY_LOADOUT_NONE"), options
end

local function GetLastVisibleChonkySpecButton()
    local lastVisibleButton
    for index = 1, 4 do
        local button = rawget(_G, "CCS_PSpecBtn" .. index)
        if button and button.IsShown and button:IsShown() then
            lastVisibleButton = button
        end
    end

    return lastVisibleButton
end

local function GetFirstVisibleChonkyLootButton()
    for index = 0, 4 do
        local button = rawget(_G, "CCS_loot_Btn" .. index)
        if button and button.IsShown and button:IsShown() then
            return button
        end
    end

    return nil
end

local function GetDropdownWidth(anchorButton)
    local lootButton = GetFirstVisibleChonkyLootButton()
    if not anchorButton or not lootButton or not anchorButton.GetRight or not lootButton.GetLeft then
        return DROPDOWN_WIDTH
    end

    local anchorRight = anchorButton:GetRight()
    local lootLeft = lootButton:GetLeft()
    if not anchorRight or not lootLeft or lootLeft <= anchorRight then
        return DROPDOWN_WIDTH
    end

    local availableWidth = lootLeft - anchorRight - 14
    if availableWidth < 120 then
        return 120
    end

    return math.min(DROPDOWN_WIDTH, availableWidth)
end

local function RefreshDropdownText()
    if not Dropdown then
        return
    end

    local selectedConfigID, currentText = ResolveCurrentLoadoutState()
    Dropdown:SetWidth(Dropdown.beavisWidth or DROPDOWN_WIDTH)
    Dropdown.activeConfigID = selectedConfigID or 0
    if Dropdown.Text then
        Dropdown.Text:SetText(currentText)
    end
end

local function QueueRefresh(delay)
    RefreshSerial = RefreshSerial + 1
    local serial = RefreshSerial

    if C_Timer and C_Timer.After then
        C_Timer.After(delay or DROPDOWN_REFRESH_DELAY, function()
            if serial == RefreshSerial and BeavisQoL.RefreshChonkyLoadoutDropdown then
                BeavisQoL.RefreshChonkyLoadoutDropdown()
            end
        end)
    elseif BeavisQoL.RefreshChonkyLoadoutDropdown then
        BeavisQoL.RefreshChonkyLoadoutDropdown()
    end
end

local function FallbackLoadConfig(configID)
    if not C_ClassTalents or not C_ClassTalents.LoadConfig then
        return false, L("CHONKY_LOADOUT_API_MISSING")
    end

    local ok, result, changeError = pcall(C_ClassTalents.LoadConfig, configID, true)
    if not ok then
        return false, result
    end

    if Enum and Enum.LoadConfigResult and result == Enum.LoadConfigResult.Error then
        return false, changeError or L("UNKNOWN")
    end

    local _, specID = GetSpecInfo()
    if specID and C_ClassTalents.UpdateLastSelectedSavedConfigID then
        pcall(C_ClassTalents.UpdateLastSelectedSavedConfigID, specID, configID)
    end

    return true, nil
end

local function LoadConfigThroughTalentFrame(configID, loadoutIndex)
    if type(PlayerSpellsFrame_LoadUI) == "function" and not rawget(_G, "PlayerSpellsFrame") then
        pcall(PlayerSpellsFrame_LoadUI)
    end

    local playerSpellsFrame = rawget(_G, "PlayerSpellsFrame")
    local talentsFrame = playerSpellsFrame and playerSpellsFrame.TalentsFrame
    if not talentsFrame or type(talentsFrame.LoadConfigByPredicate) ~= "function" then
        local classTalentHelper = rawget(_G, "ClassTalentHelper")
        if classTalentHelper and type(classTalentHelper.SwitchToLoadoutByIndex) == "function" and loadoutIndex then
            local helperOk, helperErr = pcall(classTalentHelper.SwitchToLoadoutByIndex, loadoutIndex)
            if helperOk then
                return true, nil
            end

            return false, helperErr
        end

        return FallbackLoadConfig(configID)
    end

    -- Prefer the configID-based Blizzard path.
    -- Index-based helper switching can drift when Blizzard's visible list is stale.
    local ok, err = pcall(function()
        talentsFrame:LoadConfigByPredicate(function(_, candidateConfigID)
            return candidateConfigID == configID
        end)
    end)

    if not ok then
        return false, err
    end

    return true, nil
end

local function DumpTalentLoadoutDebug(openConsole)
    local debugConsole = BeavisQoL.DebugConsole
    local moduleKey = DEBUG_MODULE_KEY

    if not debugConsole or not debugConsole.Clear or not debugConsole.AppendLine then
        PrintAddonMessage("Talent-Debug-Konsole ist nicht verfügbar.")
        return false
    end

    debugConsole.Clear(moduleKey, { titleText = DEBUG_MODULE_TITLE, select = true })

    if date then
        debugConsole.AppendLine(moduleKey, "Zeit: " .. date("%Y-%m-%d %H:%M:%S"))
    end

    local _, specID, specName = GetSpecInfo()
    local activeConfigID = GetActiveConfigID()
    local selectedSavedConfigID = GetLastSelectedSavedConfigID(specID)
    local rawConfigIDs = {}
    local options = BuildLoadoutOptions()

    if type(specID) == "number" and C_ClassTalents and type(C_ClassTalents.GetConfigIDsBySpecID) == "function" then
        rawConfigIDs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    end

    local orderedConfigEntries = GetOrderedConfigIDs(rawConfigIDs)
    local playerSpellsFrame = rawget(_G, "PlayerSpellsFrame")
    local talentsFrame = playerSpellsFrame and playerSpellsFrame.TalentsFrame
    local blizzardPlayerSpellsLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(PLAYER_SPELLS_ADDON_NAME) == true or false

    debugConsole.AppendLine(moduleKey, string.format(
        "Spec: specID=%s | Name=%s",
        tostring(specID),
        tostring(specName or "?")
    ))
    debugConsole.AppendLine(moduleKey, string.format(
        "ConfigIDs: active=%s | lastSelectedSaved=%s | savedCount=%d",
        tostring(activeConfigID),
        tostring(selectedSavedConfigID),
        #orderedConfigEntries
    ))
    debugConsole.AppendLine(moduleKey, string.format(
        "Frames: Blizzard_PlayerSpells=%s | PlayerSpellsFrame=%s | shown=%s | TalentsFrame=%s | LoadConfigByPredicate=%s",
        tostring(blizzardPlayerSpellsLoaded),
        tostring(playerSpellsFrame ~= nil),
        tostring(playerSpellsFrame and playerSpellsFrame:IsShown() or false),
        tostring(talentsFrame ~= nil),
        tostring(talentsFrame and type(talentsFrame.LoadConfigByPredicate) == "function" or false)
    ))
    debugConsole.AppendLine(moduleKey, "")
    debugConsole.AppendLine(moduleKey, "Raw ConfigIDs von Blizzard:")

    local rawEntries = {}
    for order, configID in pairs(rawConfigIDs) do
        rawEntries[#rawEntries + 1] = {
            order = order,
            configID = configID,
        }
    end

    table.sort(rawEntries, function(left, right)
        local leftOrder = tostring(left.order)
        local rightOrder = tostring(right.order)
        if leftOrder == rightOrder then
            return tostring(left.configID) < tostring(right.configID)
        end

        return leftOrder < rightOrder
    end)

    if #rawEntries == 0 then
        debugConsole.AppendLine(moduleKey, "  (leer)")
    else
        for _, entry in ipairs(rawEntries) do
            debugConsole.AppendLine(moduleKey, string.format("  [%s] = %s", tostring(entry.order), tostring(entry.configID)))
        end
    end

    debugConsole.AppendLine(moduleKey, "")
    debugConsole.AppendLine(moduleKey, "Gespeicherte Loadouts:")

    if #orderedConfigEntries == 0 then
        debugConsole.AppendLine(moduleKey, "  (keine gespeicherten Loadouts für diese Spec)")
    else
        for index, entry in ipairs(orderedConfigEntries) do
            local configID = entry.configID
            local configName = GetConfigName(configID)
            local exportString = GetConfigExportString(configID)
            debugConsole.AppendLine(moduleKey, string.format(
                "  %d. configID=%s | name=%s | export=%s",
                index,
                tostring(configID),
                tostring(configName or "?"),
                FormatExportPreview(exportString)
            ))
        end
    end

    debugConsole.AppendLine(moduleKey, "")
    debugConsole.AppendLine(moduleKey, string.format(
        "Aktive Config: name=%s | export=%s",
        tostring(GetConfigName(activeConfigID) or "?"),
        FormatExportPreview(GetConfigExportString(activeConfigID))
    ))
    local matchedActiveOption, matchedBy = FindActiveLoadoutOption(options, activeConfigID)
    debugConsole.AppendLine(moduleKey, string.format(
        "Aktive Config-Match: method=%s | savedConfigID=%s | name=%s",
        tostring(matchedBy or "none"),
        tostring(matchedActiveOption and matchedActiveOption.configID or nil),
        tostring(matchedActiveOption and matchedActiveOption.name or nil)
    ))
    debugConsole.AppendLine(moduleKey, string.format(
        "Last Selected Saved: name=%s | export=%s",
        tostring(GetConfigName(selectedSavedConfigID) or "?"),
        FormatExportPreview(GetConfigExportString(selectedSavedConfigID))
    ))
    debugConsole.AppendLine(moduleKey, "")

    AppendScalarTable(moduleKey, "Aktive ConfigInfo:", GetConfigInfo(activeConfigID))
    debugConsole.AppendLine(moduleKey, "")
    AppendScalarTable(moduleKey, "LastSelectedSaved ConfigInfo:", GetConfigInfo(selectedSavedConfigID))

    if openConsole and debugConsole.Open then
        debugConsole.Open(moduleKey)
    end

    PrintAddonMessage("Talent-Debug-Snapshot wurde in der Debug-Konsole aktualisiert.")
    return true
end

BeavisQoL.DebugTalentLoadouts = DumpTalentLoadoutDebug

local function SelectLoadout(option)
    if not option or not option.configID then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        PrintAddonMessage(L("CHONKY_LOADOUT_COMBAT_BLOCKED"))
        return
    end

    local success, errorText = LoadConfigThroughTalentFrame(option.configID, option.index)
    if not success then
        PrintAddonMessage(L("CHONKY_LOADOUT_FAILED"):format(errorText or L("UNKNOWN")))
        return
    end

    if PlaySound and SOUNDKIT then
        PlaySound(SOUNDKIT.UI_CLASS_TALENT_APPLY_CHANGES or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end

    QueueRefresh(0.25)
end

local function ShowLoadoutMenu(owner)
    local selectedConfigID, _, options = ResolveCurrentLoadoutState()

    if not MenuUtil or type(MenuUtil.CreateContextMenu) ~= "function" then
        PrintAddonMessage(L("CHONKY_LOADOUT_MENU_MISSING"))
        return
    end

    MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
        if rootDescription.CreateTitle then
            rootDescription:CreateTitle(L("CHONKY_LOADOUT_LABEL"))
        end

        if #options == 0 then
            local disabledButton = rootDescription:CreateButton(L("CHONKY_LOADOUT_NO_LOADOUTS"), function()
            end)
            if disabledButton and disabledButton.SetEnabled then
                disabledButton:SetEnabled(false)
            end
            return
        end

        for _, option in ipairs(options) do
            local loadoutOption = option
            local menuButton = rootDescription:CreateButton(loadoutOption.name, function()
                SelectLoadout(loadoutOption)
            end)
            if loadoutOption.configID == selectedConfigID and menuButton and menuButton.SetIsSelected then
                menuButton:SetIsSelected(true)
            end
        end
    end)
end

local function EnsureDropdown()
    if Dropdown then
        return true
    end

    if not rawget(_G, "PaperDollItemsFrame") then
        return false
    end

    Dropdown = CreateFrame("Button", DROPDOWN_NAME, PaperDollItemsFrame, BackdropTemplateMixin and "BackdropTemplate")
    Dropdown:SetSize(DROPDOWN_WIDTH, DROPDOWN_HEIGHT)
    Dropdown:SetFrameStrata("HIGH")
    Dropdown:SetFrameLevel((PaperDollItemsFrame:GetFrameLevel() or 0) + 30)
    if Dropdown.SetBackdrop then
        Dropdown:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        Dropdown:SetBackdropColor(0, 0, 0, 0.78)
        Dropdown:SetBackdropBorderColor(0.85, 0.76, 0.35, 0.9)
    end

    Dropdown.Text = Dropdown:CreateFontString(nil, "OVERLAY")
    Dropdown.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    Dropdown.Text:SetTextColor(1, 0.82, 0, 1)
    Dropdown.Text:SetJustifyH("LEFT")
    Dropdown.Text:SetPoint("LEFT", Dropdown, "LEFT", 8, 0)
    Dropdown.Text:SetPoint("RIGHT", Dropdown, "RIGHT", -24, 0)

    Dropdown.Arrow = Dropdown:CreateTexture(nil, "ARTWORK")
    Dropdown.Arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    Dropdown.Arrow:SetSize(18, 18)
    Dropdown.Arrow:SetPoint("RIGHT", Dropdown, "RIGHT", -4, 0)

    DropdownLabel = Dropdown:CreateFontString(nil, "OVERLAY")
    DropdownLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    DropdownLabel:SetTextColor(1, 1, 1, 1)
    DropdownLabel:SetText(L("CHONKY_LOADOUT_LABEL"))
    DropdownLabel:SetPoint("BOTTOMLEFT", Dropdown, "TOPLEFT", 0, 2)

    Dropdown:SetScript("OnEnter", function(self)
        if self.SetBackdropBorderColor then
            self:SetBackdropBorderColor(1, 0.82, 0, 1)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("CHONKY_LOADOUT_LABEL"), 1, 0.82, 0)
        GameTooltip:AddLine(L("CHONKY_LOADOUT_TOOLTIP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    Dropdown:SetScript("OnLeave", function(self)
        if self.SetBackdropBorderColor then
            self:SetBackdropBorderColor(0.85, 0.76, 0.35, 0.9)
        end
        GameTooltip_Hide()
    end)
    Dropdown:SetScript("OnMouseDown", function(self)
        if self.Text then
            self.Text:SetPoint("LEFT", self, "LEFT", 9, -1)
        end
    end)
    Dropdown:SetScript("OnMouseUp", function(self)
        if self.Text then
            self.Text:SetPoint("LEFT", self, "LEFT", 8, 0)
        end
    end)
    Dropdown:SetScript("OnClick", function(self)
        ShowLoadoutMenu(self)
    end)

    Dropdown:Hide()
    return true
end

local function AnchorDropdown(anchorButton)
    if not Dropdown or not anchorButton then
        return
    end

    local width = GetDropdownWidth(anchorButton)
    Dropdown.beavisWidth = width
    Dropdown:SetWidth(width)

    Dropdown:ClearAllPoints()
    Dropdown:SetPoint("LEFT", anchorButton, "RIGHT", 8, 0)

    if DropdownLabel then
        DropdownLabel:ClearAllPoints()
        DropdownLabel:SetPoint("BOTTOMLEFT", Dropdown, "TOPLEFT", 0, 2)
    end
end

local function InstallPaperDollHook()
    if PaperDollHookInstalled or not PaperDollItemsFrame or not PaperDollItemsFrame.HookScript then
        return
    end

    PaperDollItemsFrame:HookScript("OnShow", function()
        QueueRefresh()
    end)
    PaperDollHookInstalled = true
end

function BeavisQoL.RefreshChonkyLoadoutDropdown()
    InstallPaperDollHook()

    if not IsChonkyLoaded() then
        if Dropdown then
            Dropdown:Hide()
        end
        return
    end

    local anchorButton = GetLastVisibleChonkySpecButton()
    if not anchorButton then
        if Dropdown then
            Dropdown:Hide()
        end
        return
    end

    if not EnsureDropdown() then
        return
    end

    AnchorDropdown(anchorButton)
    RefreshDropdownText()
    Dropdown:Show()
end

Watcher:RegisterEvent("ADDON_LOADED")
Watcher:RegisterEvent("PLAYER_LOGIN")
Watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
Watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
Watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Watcher:RegisterEvent("PLAYER_TALENT_UPDATE")
Watcher:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
Watcher:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
Watcher:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
Watcher:RegisterEvent("TRAIT_CONFIG_UPDATED")

Watcher:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED"
        and addonName ~= CHONKY_ADDON_NAME
        and addonName ~= PAPERDOLL_ADDON_NAME then
        return
    end

    TrySyncSavedLoadoutSelection()
    QueueRefresh(event == "PLAYER_ENTERING_WORLD" and 0.5 or DROPDOWN_REFRESH_DELAY)
end)

QueueRefresh(0.5)
