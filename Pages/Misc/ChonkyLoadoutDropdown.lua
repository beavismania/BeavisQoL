local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local L = BeavisQoL.L

local CHONKY_ADDON_NAME = "ChonkyCharacterSheet"
local PAPERDOLL_ADDON_NAME = "Blizzard_UIPanels_Game"
local DROPDOWN_NAME = "BeavisQoLChonkyLoadoutDropdown"
local DROPDOWN_WIDTH = 170
local DROPDOWN_HEIGHT = 24
local DROPDOWN_REFRESH_DELAY = 0.05

local Watcher = CreateFrame("Frame")
local Dropdown
local DropdownLabel
local RefreshSerial = 0
local PaperDollHookInstalled = false

local function PrintAddonMessage(message)
    print(L("ADDON_MESSAGE"):format(message))
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

local function GetConfigName(configID)
    if not configID or not C_Traits or not C_Traits.GetConfigInfo then
        return nil
    end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if configInfo and configInfo.name and configInfo.name ~= "" then
        return configInfo.name
    end

    return nil
end

local function BuildLoadoutOptions()
    local _, specID = GetSpecInfo()
    if not specID or not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID then
        return {}
    end

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    local options = {}
    for index, configID in ipairs(configIDs) do
        options[#options + 1] = {
            configID = configID,
            index = index,
            name = GetConfigName(configID) or (L("CHONKY_LOADOUT_FALLBACK_NAME"):format(index)),
        }
    end

    return options
end

local function GetCurrentLoadoutText()
    local activeConfigID = GetActiveConfigID()
    local activeName = GetConfigName(activeConfigID)
    if activeName then
        return activeName
    end

    local options = BuildLoadoutOptions()
    if #options == 0 then
        return L("CHONKY_LOADOUT_NO_LOADOUTS")
    end

    return L("CHONKY_LOADOUT_NONE")
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

    Dropdown:SetWidth(Dropdown.beavisWidth or DROPDOWN_WIDTH)
    Dropdown.activeConfigID = GetActiveConfigID() or 0
    if Dropdown.Text then
        Dropdown.Text:SetText(GetCurrentLoadoutText())
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
    local classTalentHelper = rawget(_G, "ClassTalentHelper")
    if classTalentHelper and type(classTalentHelper.SwitchToLoadoutByIndex) == "function" and loadoutIndex then
        local ok, err = pcall(classTalentHelper.SwitchToLoadoutByIndex, loadoutIndex)
        if ok then
            return true, nil
        end

        return false, err
    end

    if type(PlayerSpellsFrame_LoadUI) == "function" and not rawget(_G, "PlayerSpellsFrame") then
        pcall(PlayerSpellsFrame_LoadUI)
    end

    local playerSpellsFrame = rawget(_G, "PlayerSpellsFrame")
    local talentsFrame = playerSpellsFrame and playerSpellsFrame.TalentsFrame
    if not talentsFrame or type(talentsFrame.LoadConfigByPredicate) ~= "function" then
        return FallbackLoadConfig(configID)
    end

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
    local activeConfigID = GetActiveConfigID()
    local options = BuildLoadoutOptions()

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
            if loadoutOption.configID == activeConfigID and menuButton and menuButton.SetIsSelected then
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
Watcher:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
Watcher:RegisterEvent("TRAIT_CONFIG_UPDATED")

Watcher:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED"
        and addonName ~= CHONKY_ADDON_NAME
        and addonName ~= PAPERDOLL_ADDON_NAME then
        return
    end

    QueueRefresh(event == "PLAYER_ENTERING_WORLD" and 0.5 or DROPDOWN_REFRESH_DELAY)
end)

QueueRefresh(0.5)
