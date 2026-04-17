local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local baseGetMiscDB = Misc.GetMiscDB
local FavoritesWatcher = CreateFrame("Frame")

local AUCTION_HOUSE_UI_ADDON_NAME = "Blizzard_AuctionHouseUI"
local FAVORITE_GROUP_SELECTION_ALL = "__BEAVISQOL_FAVORITE_GROUP_ALL__"
local FAVORITE_GROUP_SELECTION_UNGROUPED = "__BEAVISQOL_FAVORITE_GROUP_UNGROUPED__"
local CREATE_GROUP_POPUP_KEY = "BEAVISQOL_AUCTION_HOUSE_FAVORITE_GROUP_CREATE"
local RENAME_GROUP_POPUP_KEY = "BEAVISQOL_AUCTION_HOUSE_FAVORITE_GROUP_RENAME"
local DELETE_GROUP_POPUP_KEY = "BEAVISQOL_AUCTION_HOUSE_FAVORITE_GROUP_DELETE"
local FAVORITE_GROUP_ROW_HEIGHT = 30
local FAVORITE_GROUP_ROW_SPACING = 2

local hooksInstalled = false
local favoriteGroupsUI = nil
local favoriteGroupCreateButton = nil
local originalFavoriteContextMenu = nil
local RefreshFavoriteGroupsState
local pendingCreateFavoriteGroupItemKey = nil
local pendingRenameFavoriteGroupID = nil
local virtualFavoriteGroupRowsInstalled = false

local function TrimText(text)
    return string.match(tostring(text or ""), "^%s*(.-)%s*$") or ""
end

local function StripColorCodes(text)
    local cleanedText = tostring(text or "")
    cleanedText = string.gsub(cleanedText, "|c%x%x%x%x%x%x%x%x", "")
    cleanedText = string.gsub(cleanedText, "|r", "")
    return cleanedText
end

local function NormalizeGroupName(name)
    return TrimText(name)
end

local function NormalizeGroupNameForCompare(name)
    return string.lower(NormalizeGroupName(name))
end

local function PrintFavoriteGroupMessage(message)
    if type(message) == "string" and message ~= "" then
        print(L("ADDON_MESSAGE"):format(message))

        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2, 1)
        end
    end
end

local function RequestFavoriteGroupsRefresh()
    if not RefreshFavoriteGroupsState then
        return
    end

    RefreshFavoriteGroupsState()

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if RefreshFavoriteGroupsState then
                RefreshFavoriteGroupsState()
            end
        end)
    end
end

local function GetPopupEditBox(dialog)
    if type(dialog) ~= "table" then
        return nil
    end

    if dialog.GetEditBox then
        local editBox = dialog:GetEditBox()
        if editBox then
            return editBox
        end
    end

    return dialog.editBox
        or dialog.EditBox
        or dialog.wideEditBox
        or dialog.WideEditBox
        or nil
end

local function GetPopupButton(dialog, buttonIndex)
    if type(dialog) ~= "table" or type(buttonIndex) ~= "number" then
        return nil
    end

    if buttonIndex == 1 and dialog.GetButton1 then
        local button = dialog:GetButton1()
        if button then
            return button
        end
    elseif buttonIndex == 2 and dialog.GetButton2 then
        local button = dialog:GetButton2()
        if button then
            return button
        end
    end

    return dialog["button" .. buttonIndex]
        or dialog["Button" .. buttonIndex]
        or (type(dialog.Buttons) == "table" and dialog.Buttons[buttonIndex])
        or nil
end

local function GetPopupDialogFromEditBox(editBoxOrDialog)
    if type(editBoxOrDialog) ~= "table" then
        return nil
    end

    if editBoxOrDialog.which then
        return editBoxOrDialog
    end

    local parent = editBoxOrDialog.GetParent and editBoxOrDialog:GetParent() or nil
    if parent and parent.which then
        return parent
    end

    local grandParent = parent and parent.GetParent and parent:GetParent() or nil
    if grandParent and grandParent.which then
        return grandParent
    end

    local greatGrandParent = grandParent and grandParent.GetParent and grandParent:GetParent() or nil
    if greatGrandParent and greatGrandParent.which then
        return greatGrandParent
    end

    return nil
end

local function UpdatePopupPrimaryButtonState(editBoxOrDialog)
    local dialog = GetPopupDialogFromEditBox(editBoxOrDialog)
    local editBox = dialog and GetPopupEditBox(dialog) or editBoxOrDialog
    if type(editBox) ~= "table" then
        return
    end

    if type(StaticPopup_StandardNonEmptyTextHandler) == "function" then
        StaticPopup_StandardNonEmptyTextHandler(editBox)
        return
    end

    local button1 = GetPopupButton(dialog, 1)
    if button1 then
        button1:SetEnabled(NormalizeGroupName(editBox:GetText()) ~= "")
    end
end

local function PrepareCreateFavoriteGroupPopup(dialog)
    local editBox = GetPopupEditBox(dialog)
    local button1 = GetPopupButton(dialog, 1)

    if editBox then
        editBox:SetText("")
        editBox:SetFocus()
        editBox:HighlightText()
    end

    if button1 then
        button1:SetEnabled(false)
    end
end

local function PrepareRenameFavoriteGroupPopup(dialog, groupName)
    local editBox = GetPopupEditBox(dialog)
    local button1 = GetPopupButton(dialog, 1)
    local normalizedGroupName = NormalizeGroupName(groupName)

    if editBox then
        editBox:SetText(normalizedGroupName)
        editBox:SetFocus()
        editBox:HighlightText()
    end

    if button1 then
        button1:SetEnabled(normalizedGroupName ~= "")
    end
end

local function HandleCreateFavoriteGroupAccept(dialog, groupName)
    if groupName == nil then
        local editBox = GetPopupEditBox(dialog)
        groupName = editBox and editBox:GetText() or ""
    end

    local group, reason = Misc.CreateAuctionHouseFavoriteGroup(groupName)

    if not group then
        PrintFavoriteGroupMessage(L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_EMPTY"))
        RequestFavoriteGroupsRefresh()
        return false
    end

    if reason == "duplicate" then
        PrintFavoriteGroupMessage(string.format("%s (%s)", L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_DUPLICATE"), group.name))
    end

    if pendingCreateFavoriteGroupItemKey then
        Misc.AssignAuctionHouseFavoriteGroup(pendingCreateFavoriteGroupItemKey, group.id)
    end

    RequestFavoriteGroupsRefresh()
    return true
end

local function HandleRenameFavoriteGroupAccept(dialog, groupName)
    if groupName == nil then
        local editBox = GetPopupEditBox(dialog)
        groupName = editBox and editBox:GetText() or ""
    end

    local group, reason = Misc.RenameAuctionHouseFavoriteGroup(pendingRenameFavoriteGroupID, groupName)

    if not group then
        if reason == "duplicate" then
            PrintFavoriteGroupMessage(L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_DUPLICATE"))
        else
            PrintFavoriteGroupMessage(L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_EMPTY"))
        end
        RequestFavoriteGroupsRefresh()
        return false
    end

    RequestFavoriteGroupsRefresh()
    return true
end

local function TriggerFavoriteGroupPopupPrimaryAccept(dialog)
    if type(dialog) ~= "table" or (dialog.IsShown and not dialog:IsShown()) then
        return false
    end

    local dialogInfo = StaticPopupDialogs and StaticPopupDialogs[dialog.which]
    local onAccept = dialogInfo and (dialogInfo.OnAccept or dialogInfo.OnButton1) or nil
    if type(onAccept) ~= "function" then
        return false
    end

    local which = dialog.which
    local shouldHide = not onAccept(dialog, dialog.data, dialog.data2)
    if shouldHide and dialog.IsShown and dialog:IsShown() and dialog.which == which then
        dialog:Hide()
    end

    return true
end

local function HandleFavoriteGroupPopupEnter(editBox)
    local dialog = GetPopupDialogFromEditBox(editBox)
    local button1 = GetPopupButton(dialog, 1)
    if not dialog then
        return
    end

    if button1 and button1.IsEnabled and not button1:IsEnabled() then
        return
    end

    TriggerFavoriteGroupPopupPrimaryAccept(dialog)
end

local function CopyItemKey(itemKey)
    if type(itemKey) ~= "table" then
        return nil
    end

    return {
        itemID = tonumber(itemKey.itemID) or 0,
        itemLevel = tonumber(itemKey.itemLevel) or 0,
        itemSuffix = tonumber(itemKey.itemSuffix) or 0,
        battlePetSpeciesID = tonumber(itemKey.battlePetSpeciesID) or 0,
    }
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

    if type(db.auctionHouseFavoriteGroups) ~= "table" then
        db.auctionHouseFavoriteGroups = {}
    end

    if type(db.auctionHouseFavoriteAssignments) ~= "table" then
        db.auctionHouseFavoriteAssignments = {}
    end

    if type(db.auctionHouseFavoriteCollapsedGroups) ~= "table" then
        db.auctionHouseFavoriteCollapsedGroups = {}
    end

    if type(db.auctionHouseFavoriteNextGroupID) ~= "number" or db.auctionHouseFavoriteNextGroupID < 1 then
        db.auctionHouseFavoriteNextGroupID = 1
    end

    if db.auctionHouseFavoriteSelectedGroupID == nil then
        db.auctionHouseFavoriteSelectedGroupID = FAVORITE_GROUP_SELECTION_ALL
    end

    return db
end

local function GetFavoriteGroupsTable()
    return Misc.GetMiscDB().auctionHouseFavoriteGroups
end

local function GetFavoriteAssignmentsTable()
    return Misc.GetMiscDB().auctionHouseFavoriteAssignments
end

local function GetFavoriteCollapsedGroupsTable()
    return Misc.GetMiscDB().auctionHouseFavoriteCollapsedGroups
end

local function GetFavoriteGroupCollapseKey(groupID)
    return groupID or FAVORITE_GROUP_SELECTION_UNGROUPED
end

local function SerializeItemKey(itemKey)
    if type(itemKey) ~= "table" then
        return nil
    end

    return string.format(
        "%d:%d:%d:%d",
        tonumber(itemKey.itemID) or 0,
        tonumber(itemKey.itemLevel) or 0,
        tonumber(itemKey.itemSuffix) or 0,
        tonumber(itemKey.battlePetSpeciesID) or 0
    )
end

local function FindFavoriteGroupIndexByID(groupID)
    if not groupID then
        return nil
    end

    for index, group in ipairs(GetFavoriteGroupsTable()) do
        if group.id == groupID then
            return index
        end
    end

    return nil
end

function Misc.GetAuctionHouseFavoriteGroups()
    local groups = {}

    for index, group in ipairs(GetFavoriteGroupsTable()) do
        groups[index] = {
            id = group.id,
            name = group.name,
        }
    end

    return groups
end

function Misc.GetAuctionHouseFavoriteGroupByID(groupID)
    local groupIndex = FindFavoriteGroupIndexByID(groupID)
    if not groupIndex then
        return nil
    end

    return GetFavoriteGroupsTable()[groupIndex]
end

local function EnsureValidSelectedFavoriteGroupID()
    local db = Misc.GetMiscDB()
    local selectedGroupID = db.auctionHouseFavoriteSelectedGroupID

    if selectedGroupID == FAVORITE_GROUP_SELECTION_ALL or selectedGroupID == FAVORITE_GROUP_SELECTION_UNGROUPED then
        return selectedGroupID
    end

    if Misc.GetAuctionHouseFavoriteGroupByID(selectedGroupID) then
        return selectedGroupID
    end

    db.auctionHouseFavoriteSelectedGroupID = FAVORITE_GROUP_SELECTION_ALL
    return db.auctionHouseFavoriteSelectedGroupID
end

function Misc.GetAuctionHouseSelectedFavoriteGroupID()
    return EnsureValidSelectedFavoriteGroupID()
end

function Misc.SetAuctionHouseSelectedFavoriteGroupID(groupID)
    local db = Misc.GetMiscDB()

    if groupID ~= FAVORITE_GROUP_SELECTION_ALL
        and groupID ~= FAVORITE_GROUP_SELECTION_UNGROUPED
        and not Misc.GetAuctionHouseFavoriteGroupByID(groupID)
    then
        groupID = FAVORITE_GROUP_SELECTION_ALL
    end

    db.auctionHouseFavoriteSelectedGroupID = groupID
end

local function FindFavoriteGroupByNormalizedName(normalizedName)
    if normalizedName == "" then
        return nil
    end

    for _, group in ipairs(GetFavoriteGroupsTable()) do
        if NormalizeGroupNameForCompare(group.name) == normalizedName then
            return group
        end
    end

    return nil
end

function Misc.CreateAuctionHouseFavoriteGroup(name)
    local groupName = NormalizeGroupName(name)
    if groupName == "" then
        return nil, "empty"
    end

    local existingGroup = FindFavoriteGroupByNormalizedName(NormalizeGroupNameForCompare(groupName))
    if existingGroup then
        return existingGroup, "duplicate"
    end

    local db = Misc.GetMiscDB()
    local groupID = "favoriteGroup" .. tostring(db.auctionHouseFavoriteNextGroupID)
    local group = {
        id = groupID,
        name = groupName,
    }

    db.auctionHouseFavoriteNextGroupID = db.auctionHouseFavoriteNextGroupID + 1
    table.insert(db.auctionHouseFavoriteGroups, group)
    db.auctionHouseFavoriteSelectedGroupID = FAVORITE_GROUP_SELECTION_ALL

    return group
end

function Misc.RenameAuctionHouseFavoriteGroup(groupID, name)
    local groupIndex = FindFavoriteGroupIndexByID(groupID)
    if not groupIndex then
        return nil, "missing"
    end

    local groupName = NormalizeGroupName(name)
    if groupName == "" then
        return nil, "empty"
    end

    local existingGroup = FindFavoriteGroupByNormalizedName(NormalizeGroupNameForCompare(groupName))
    if existingGroup and existingGroup.id ~= groupID then
        return nil, "duplicate"
    end

    local group = GetFavoriteGroupsTable()[groupIndex]
    group.name = groupName

    return group
end

function Misc.DeleteAuctionHouseFavoriteGroup(groupID)
    local db = Misc.GetMiscDB()
    local groupIndex = FindFavoriteGroupIndexByID(groupID)
    if not groupIndex then
        return false
    end

    table.remove(db.auctionHouseFavoriteGroups, groupIndex)

    for serializedItemKey, assignedGroupID in pairs(db.auctionHouseFavoriteAssignments) do
        if assignedGroupID == groupID then
            db.auctionHouseFavoriteAssignments[serializedItemKey] = nil
        end
    end

    if db.auctionHouseFavoriteSelectedGroupID == groupID then
        db.auctionHouseFavoriteSelectedGroupID = FAVORITE_GROUP_SELECTION_ALL
    end

    db.auctionHouseFavoriteCollapsedGroups[GetFavoriteGroupCollapseKey(groupID)] = nil

    return true
end

function Misc.GetAuctionHouseFavoriteGroupID(itemKey)
    local serializedItemKey = SerializeItemKey(itemKey)
    if not serializedItemKey then
        return nil
    end

    local assignedGroupID = GetFavoriteAssignmentsTable()[serializedItemKey]
    if assignedGroupID and not Misc.GetAuctionHouseFavoriteGroupByID(assignedGroupID) then
        GetFavoriteAssignmentsTable()[serializedItemKey] = nil
        return nil
    end

    return assignedGroupID
end

function Misc.GetAuctionHouseFavoriteGroupName(itemKey)
    local assignedGroupID = Misc.GetAuctionHouseFavoriteGroupID(itemKey)
    local group = Misc.GetAuctionHouseFavoriteGroupByID(assignedGroupID)
    return group and group.name or nil
end

function Misc.AssignAuctionHouseFavoriteGroup(itemKey, groupID)
    local serializedItemKey = SerializeItemKey(itemKey)
    if not serializedItemKey then
        return false
    end

    if groupID ~= nil and not Misc.GetAuctionHouseFavoriteGroupByID(groupID) then
        return false
    end

    if groupID == nil then
        GetFavoriteAssignmentsTable()[serializedItemKey] = nil
    else
        GetFavoriteAssignmentsTable()[serializedItemKey] = groupID
    end

    return true
end

function Misc.IsAuctionHouseFavoriteGroupCollapsed(groupID)
    return GetFavoriteCollapsedGroupsTable()[GetFavoriteGroupCollapseKey(groupID)] == true
end

function Misc.SetAuctionHouseFavoriteGroupCollapsed(groupID, collapsed)
    local collapseKey = GetFavoriteGroupCollapseKey(groupID)

    if collapsed then
        GetFavoriteCollapsedGroupsTable()[collapseKey] = true
    else
        GetFavoriteCollapsedGroupsTable()[collapseKey] = nil
    end
end

function Misc.ToggleAuctionHouseFavoriteGroupCollapsed(groupID)
    local collapsed = not Misc.IsAuctionHouseFavoriteGroupCollapsed(groupID)
    Misc.SetAuctionHouseFavoriteGroupCollapsed(groupID, collapsed)
    return collapsed
end

local function GetAuctionHouseFrame()
    return rawget(_G, "AuctionHouseFrame")
end

local function IsShowingFavoriteGroupsUI(auctionHouseFrame)
    return false
end

local function IsFavoriteGroupHeaderRow(rowData)
    return type(rowData) == "table"
        and rowData.isVirtualEntry == true
        and rowData.isBeavisQoLFavoriteGroupHeader == true
end

local function CreateFavoriteGroupHeaderRow(groupName, groupID)
    local rowData

    if AuctionHouseUtil and AuctionHouseUtil.CreateVirtualRowData then
        rowData = AuctionHouseUtil.CreateVirtualRowData(groupName, false)
    else
        rowData = {
            isVirtualEntry = true,
            virtualEntryText = groupName,
            isSelectedVirtualEntry = false,
        }
    end

    rowData.isBeavisQoLFavoriteGroupHeader = true
    rowData.favoriteGroupID = groupID
    rowData.favoriteGroupCollapseKey = GetFavoriteGroupCollapseKey(groupID)
    rowData.isCollapsed = Misc.IsAuctionHouseFavoriteGroupCollapsed(groupID)

    return rowData
end

local function GetFavoriteGroupCounts(auctionHouseFrame)
    local counts = {
        [FAVORITE_GROUP_SELECTION_ALL] = 0,
        [FAVORITE_GROUP_SELECTION_UNGROUPED] = 0,
    }

    for _, group in ipairs(Misc.GetAuctionHouseFavoriteGroups()) do
        counts[group.id] = 0
    end

    local browseResultsFrame = auctionHouseFrame and auctionHouseFrame.BrowseResultsFrame
    local browseResults = browseResultsFrame and browseResultsFrame.BeavisQoLAllBrowseResults or {}
    counts[FAVORITE_GROUP_SELECTION_ALL] = #browseResults

    for _, browseResult in ipairs(browseResults) do
        local assignedGroupID = Misc.GetAuctionHouseFavoriteGroupID(browseResult.itemKey)
        if assignedGroupID and counts[assignedGroupID] ~= nil then
            counts[assignedGroupID] = counts[assignedGroupID] + 1
        else
            counts[FAVORITE_GROUP_SELECTION_UNGROUPED] = counts[FAVORITE_GROUP_SELECTION_UNGROUPED] + 1
        end
    end

    return counts
end

local function OrganizeFavoriteBrowseResults(browseResults)
    local organizedBrowseResults = {}
    local ungroupedBrowseResults = {}
    local groupedBrowseResults = {}
    local groups = Misc.GetAuctionHouseFavoriteGroups()

    for _, group in ipairs(groups) do
        groupedBrowseResults[group.id] = {}
    end

    for _, browseResult in ipairs(browseResults or {}) do
        if IsFavoriteGroupHeaderRow(browseResult) then
            -- Skip previously injected header rows before rebuilding the grouped view.
        else
            local assignedGroupID = Misc.GetAuctionHouseFavoriteGroupID(browseResult.itemKey)
            local bucket = assignedGroupID and groupedBrowseResults[assignedGroupID] or nil

            if bucket then
                table.insert(bucket, browseResult)
            else
                table.insert(ungroupedBrowseResults, browseResult)
            end
        end
    end

    for _, group in ipairs(groups) do
        local groupedResults = groupedBrowseResults[group.id] or {}
        local headerRow = CreateFavoriteGroupHeaderRow(group.name, group.id)
        table.insert(organizedBrowseResults, headerRow)

        if not headerRow.isCollapsed then
            for _, browseResult in ipairs(groupedResults) do
                table.insert(organizedBrowseResults, browseResult)
            end
        end
    end

    if #ungroupedBrowseResults > 0 then
        local headerRow = CreateFavoriteGroupHeaderRow(L("AUCTION_HOUSE_FAVORITE_GROUP_UNGROUPED"), nil)
        table.insert(organizedBrowseResults, headerRow)

        if not headerRow.isCollapsed then
            for _, browseResult in ipairs(ungroupedBrowseResults) do
                table.insert(organizedBrowseResults, browseResult)
            end
        end
    end

    return organizedBrowseResults
end

local function FilteredResultsContainEntry(filteredBrowseResults, selectedRowData)
    if not selectedRowData then
        return false
    end

    for _, browseResult in ipairs(filteredBrowseResults) do
        if browseResult == selectedRowData then
            return true
        end
    end

    return false
end

local function ApplyFavoriteGroupFilterToBrowseResults(browseResultsFrame)
    local auctionHouseFrame = GetAuctionHouseFrame()
    if not browseResultsFrame or not auctionHouseFrame or auctionHouseFrame.isDisplayingFavorites ~= true then
        return
    end

    local allBrowseResults = browseResultsFrame.BeavisQoLAllBrowseResults or browseResultsFrame.browseResults or {}
    local filteredBrowseResults = OrganizeFavoriteBrowseResults(allBrowseResults)

    browseResultsFrame.browseResults = filteredBrowseResults

    local itemList = browseResultsFrame.ItemList
    if itemList and itemList.selectedRowData and not FilteredResultsContainEntry(filteredBrowseResults, itemList.selectedRowData) then
        itemList.selectedRowData = nil
    end

    if itemList then
        itemList:DirtyScrollFrame()

        if itemList.IsShown and itemList:IsShown() then
            itemList:RefreshScrollFrame()
        end
    end
end

local function CreateActionButton(parent, labelText)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(18, 18)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.12, 0.09, 0.05, 0.95)
    button.Background = background

    local borderTop = button:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.88, 0.72, 0.46, 0.95)
    button.BorderTop = borderTop

    local borderBottom = button:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.95)
    button.BorderBottom = borderBottom

    local borderLeft = button:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0.88, 0.72, 0.46, 0.95)
    button.BorderLeft = borderLeft

    local borderRight = button:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0.88, 0.72, 0.46, 0.95)
    button.BorderRight = borderRight

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(1, 0.88, 0.62, 1)
    button.Label = label

    button:SetScript("OnMouseDown", function(self)
        self.Label:SetPoint("CENTER", self, "CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self.Label:SetPoint("CENTER", self, "CENTER", 0, 0)
    end)

    button:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.18, 0.12, 0.06, 0.98)
        self.Label:SetTextColor(1, 0.95, 0.75, 1)

        if self.tooltipText and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, 1, 0.88, 0.62, 1, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.Background:SetColorTexture(0.12, 0.09, 0.05, 0.95)
        self.Label:SetTextColor(1, 0.88, 0.62, 1)

        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

local function CreatePlusIconButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(20, 20)

    button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    button:SetDisabledTexture("Interface\\Buttons\\UI-PlusButton-Disabled")

    button:SetScript("OnEnter", function(self)
        if self.tooltipText and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, 1, 0.88, 0.62, 1, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

local function CreateFavoriteGroupEditButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(20, 20)

    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    icon:SetTexture("Interface\\Icons\\INV_Inscription_Tradeskill01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.Icon = icon

    button:SetScript("OnMouseDown", function(self)
        if self.Icon then
            self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -5)
            self.Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        if self.Icon then
            self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -4)
            self.Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
        end
    end)

    return button
end

local function ShowCreateFavoriteGroupPopup(itemKey)
    pendingCreateFavoriteGroupItemKey = CopyItemKey(itemKey)

    if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs[CREATE_GROUP_POPUP_KEY] then
        local dialog = StaticPopup_Show(CREATE_GROUP_POPUP_KEY)
        if dialog then
            PrepareCreateFavoriteGroupPopup(dialog)
        end
    end
end

local function ShowRenameFavoriteGroupPopup(groupID)
    local group = Misc.GetAuctionHouseFavoriteGroupByID(groupID)
    if not group then
        return
    end

    pendingRenameFavoriteGroupID = groupID

    if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs[RENAME_GROUP_POPUP_KEY] then
        local dialog = StaticPopup_Show(RENAME_GROUP_POPUP_KEY)
        if dialog then
            PrepareRenameFavoriteGroupPopup(dialog, group.name)
        end
    end
end

local function ShowDeleteFavoriteGroupPopup(groupID)
    local group = Misc.GetAuctionHouseFavoriteGroupByID(groupID)
    if not group then
        return
    end

    if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs[DELETE_GROUP_POPUP_KEY] then
        StaticPopup_Show(DELETE_GROUP_POPUP_KEY, group.name, nil, groupID)
        return
    end

    Misc.DeleteAuctionHouseFavoriteGroup(groupID)

    if RefreshFavoriteGroupsState then
        RefreshFavoriteGroupsState()
    end
end

local function ShowFavoriteGroupEditMenu(frame, groupID)
    local group = Misc.GetAuctionHouseFavoriteGroupByID(groupID)
    if not group then
        return
    end

    if not MenuUtil or not MenuUtil.CreateContextMenu then
        ShowRenameFavoriteGroupPopup(groupID)
        return
    end

    MenuUtil.CreateContextMenu(frame, function(_, rootDescription)
        rootDescription:SetTag("MENU_BEAVISQOL_AUCTION_HOUSE_FAVORITE_GROUP_EDIT")
        rootDescription:CreateTitle(group.name)

        rootDescription:CreateButton(L("AUCTION_HOUSE_FAVORITE_GROUP_EDIT_BUTTON"), function()
            ShowRenameFavoriteGroupPopup(groupID)
        end)

        rootDescription:CreateButton(DELETE, function()
            ShowDeleteFavoriteGroupPopup(groupID)
        end)
    end)
end

local function InitializeFavoriteGroupRowButton(button, elementData)
    button:SetHeight(FAVORITE_GROUP_ROW_HEIGHT)

    if not button.BeavisQoLCountText then
        local countText = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        countText:SetPoint("RIGHT", button, "RIGHT", -28, 0)
        countText:SetJustifyH("RIGHT")
        countText:SetTextColor(0.82, 0.78, 0.72, 1)
        button.BeavisQoLCountText = countText

        button.Text:ClearAllPoints()
        button.Text:SetPoint("LEFT", button, "LEFT", 4, 0)
        button.Text:SetPoint("RIGHT", countText, "LEFT", -6, 0)

        local deleteButton = CreateActionButton(button, "X")
        deleteButton:SetSize(16, 16)
        deleteButton:SetPoint("RIGHT", button, "RIGHT", -4, 0)
        deleteButton:SetFrameLevel(button:GetFrameLevel() + 10)
        deleteButton:SetScript("OnClick", function(self)
            if self.groupID then
                ShowDeleteFavoriteGroupPopup(self.groupID)
            end
        end)
        button.BeavisQoLDeleteButton = deleteButton
    end

    button:SetScript("OnClick", function()
        Misc.SetAuctionHouseSelectedFavoriteGroupID(elementData.groupSelectionID)

        if RefreshFavoriteGroupsState then
            RefreshFavoriteGroupsState()
        end
    end)

    button.Text:SetText(elementData.name or "")
    button.BeavisQoLCountText:SetText(tostring(elementData.count or 0))
    button.BeavisQoLDeleteButton.groupID = elementData.groupID
    button.BeavisQoLDeleteButton.tooltipText = elementData.allowDelete
        and L("AUCTION_HOUSE_FAVORITE_GROUP_DELETE_TOOLTIP"):format(elementData.name or "")
        or nil
    button.BeavisQoLDeleteButton:SetShown(elementData.allowDelete == true)

    if button.SelectedTexture then
        button.SelectedTexture:SetShown(elementData.selected == true)
    end
end

local function EnsureFavoriteGroupsUI(auctionHouseFrame)
    if favoriteGroupsUI then
        return favoriteGroupsUI
    end

    if not auctionHouseFrame
        or not auctionHouseFrame.CategoriesList
        or not CreateScrollBoxListLinearView
        or not ScrollUtil
        or not ScrollUtil.InitScrollBoxListWithScrollBar
    then
        return nil
    end

    local parent = auctionHouseFrame.CategoriesList
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    frame:SetFrameLevel(parent:GetFrameLevel() + 20)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
    title:SetPoint("RIGHT", frame, "RIGHT", -36, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetTextColor(1, 0.88, 0.62, 1)
    title:SetText(L("AUCTION_HOUSE_FAVORITE_GROUPS_TITLE"))
    frame.Title = title

    local addButton = CreateActionButton(frame, "+")
    addButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    addButton.tooltipText = L("AUCTION_HOUSE_FAVORITE_GROUP_ADD_TOOLTIP")
    addButton:SetScript("OnClick", function()
        ShowCreateFavoriteGroupPopup()
    end)
    frame.AddButton = addButton

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -34)
    scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 2)
    frame.ScrollBox = scrollBox

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 4)
    frame.ScrollBar = scrollBar

    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("AuctionCategoryButtonTemplate", function(button, elementData)
        InitializeFavoriteGroupRowButton(button, elementData)
    end)
    view:SetElementExtent(FAVORITE_GROUP_ROW_HEIGHT)
    view:SetPadding(0, 0, 3, 0, 0, FAVORITE_GROUP_ROW_SPACING)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    favoriteGroupsUI = frame
    return frame
end

local function BuildFavoriteGroupEntries(auctionHouseFrame)
    local counts = GetFavoriteGroupCounts(auctionHouseFrame)
    local selectedGroupID = Misc.GetAuctionHouseSelectedFavoriteGroupID()
    local entries = {
        {
            groupSelectionID = FAVORITE_GROUP_SELECTION_ALL,
            name = L("AUCTION_HOUSE_FAVORITE_GROUP_ALL"),
            count = counts[FAVORITE_GROUP_SELECTION_ALL] or 0,
            selected = selectedGroupID == FAVORITE_GROUP_SELECTION_ALL,
            allowDelete = false,
        },
        {
            groupSelectionID = FAVORITE_GROUP_SELECTION_UNGROUPED,
            name = L("AUCTION_HOUSE_FAVORITE_GROUP_UNGROUPED"),
            count = counts[FAVORITE_GROUP_SELECTION_UNGROUPED] or 0,
            selected = selectedGroupID == FAVORITE_GROUP_SELECTION_UNGROUPED,
            allowDelete = false,
        },
    }

    for _, group in ipairs(Misc.GetAuctionHouseFavoriteGroups()) do
        table.insert(entries, {
            groupSelectionID = group.id,
            groupID = group.id,
            name = group.name,
            count = counts[group.id] or 0,
            selected = selectedGroupID == group.id,
            allowDelete = true,
        })
    end

    return entries
end

local function RefreshFavoriteGroupsDataProvider(auctionHouseFrame)
    local frame = EnsureFavoriteGroupsUI(auctionHouseFrame)
    if not frame or not CreateDataProvider or not ScrollBoxConstants then
        return
    end

    frame.Title:SetText(L("AUCTION_HOUSE_FAVORITE_GROUPS_TITLE"))
    frame.AddButton.tooltipText = L("AUCTION_HOUSE_FAVORITE_GROUP_ADD_TOOLTIP")
    local scrollBox = frame.ScrollBox
    if scrollBox and scrollBox.SetDataProvider then
        ---@diagnostic disable-next-line: param-type-mismatch
        scrollBox:SetDataProvider(CreateDataProvider(BuildFavoriteGroupEntries(auctionHouseFrame)), ScrollBoxConstants.RetainScrollPosition)
    end
end

local function UpdateFavoriteGroupsVisibility(auctionHouseFrame)
    if not auctionHouseFrame or not auctionHouseFrame.CategoriesList then
        return
    end

    if favoriteGroupsUI then
        favoriteGroupsUI:Hide()
    end

    if auctionHouseFrame.CategoriesList.ScrollBox then
        auctionHouseFrame.CategoriesList.ScrollBox:Show()
    end

    if auctionHouseFrame.CategoriesList.ScrollBar then
        auctionHouseFrame.CategoriesList.ScrollBar:Show()
    end

    if not favoriteGroupCreateButton then
        local searchBar = auctionHouseFrame.SearchBar
        local filterButton = searchBar and searchBar.FilterButton

        if searchBar and filterButton then
            favoriteGroupCreateButton = CreatePlusIconButton(searchBar)
            favoriteGroupCreateButton:SetPoint("RIGHT", filterButton, "LEFT", -5, 0)
            favoriteGroupCreateButton:SetFrameLevel(searchBar:GetFrameLevel() + 25)
            favoriteGroupCreateButton.tooltipText = L("AUCTION_HOUSE_FAVORITE_GROUP_ADD_TOOLTIP")
            favoriteGroupCreateButton:SetScript("OnClick", function()
                ShowCreateFavoriteGroupPopup()
            end)
        end
    end

    if favoriteGroupCreateButton then
        favoriteGroupCreateButton:SetShown(auctionHouseFrame.isDisplayingFavorites == true)
    end
end

local function EnsureFavoriteRowAssignButton(rowButton)
    if rowButton.BeavisQoLAssignButton then
        return rowButton.BeavisQoLAssignButton
    end

    local assignButton = CreateActionButton(rowButton, "+")
    assignButton:SetSize(14, 14)
    assignButton:SetPoint("LEFT", rowButton, "LEFT", 4, 0)
    assignButton:SetFrameLevel(rowButton:GetFrameLevel() + 20)
    assignButton:SetScript("OnClick", function(self)
        if self.itemKey and AuctionHouseFavoriteContextMenu then
            AuctionHouseFavoriteContextMenu(self, self.itemKey)
        end
    end)
    assignButton:SetScript("OnEnter", function(self)
        self.Background:SetColorTexture(0.18, 0.12, 0.06, 0.98)
        self.Label:SetTextColor(1, 0.95, 0.75, 1)

        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L("AUCTION_HOUSE_FAVORITE_GROUP_ASSIGN_TOOLTIP"), 1, 0.88, 0.62, 1, true)

            local currentGroupName = self.itemKey and Misc.GetAuctionHouseFavoriteGroupName(self.itemKey)
            if currentGroupName then
                GameTooltip:AddLine(L("AUCTION_HOUSE_FAVORITE_GROUP_CURRENT_LABEL"):format(currentGroupName), 0.95, 0.91, 0.85, true)
            else
                GameTooltip:AddLine(L("AUCTION_HOUSE_FAVORITE_GROUP_CURRENT_NONE"), 0.78, 0.74, 0.69, true)
            end

            GameTooltip:Show()
        end
    end)
    assignButton:SetScript("OnLeave", function(self)
        self.Background:SetColorTexture(0.12, 0.09, 0.05, 0.95)
        self.Label:SetTextColor(1, 0.88, 0.62, 1)

        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    rowButton.BeavisQoLAssignButton = assignButton
    return assignButton
end

local function EnsureFavoriteRowEditButton(rowButton)
    if rowButton.BeavisQoLEditButton then
        return rowButton.BeavisQoLEditButton
    end

    local editButton = CreateFavoriteGroupEditButton(rowButton)
    editButton:SetPoint("RIGHT", rowButton, "RIGHT", -8, 0)
    editButton:SetFrameLevel(rowButton:GetFrameLevel() + 20)
    editButton:SetScript("OnClick", function(self)
        if self.groupID then
            ShowFavoriteGroupEditMenu(self, self.groupID)
        end
    end)
    editButton:SetScript("OnEnter", function(self)
        if self.tooltipText and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(self.tooltipText, 1, 0.88, 0.62, 1, true)
            GameTooltip:Show()
        end
    end)
    editButton:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    rowButton.BeavisQoLEditButton = editButton
    return editButton
end

local function EnsureFavoriteRowHeaderDecoration(rowButton)
    if rowButton.BeavisQoLHeaderDecoration then
        return rowButton.BeavisQoLHeaderDecoration
    end

    local background = rowButton:CreateTexture(nil, "BACKGROUND", nil, 2)
    background:SetPoint("TOPLEFT", rowButton, "TOPLEFT", 2, -1)
    background:SetPoint("BOTTOMRIGHT", rowButton, "BOTTOMRIGHT", -2, 1)
    background:SetColorTexture(0.12, 0.08, 0.03, 0.88)

    local inset = rowButton:CreateTexture(nil, "BACKGROUND", nil, 3)
    inset:SetPoint("TOPLEFT", background, "TOPLEFT", 1, -1)
    inset:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -1, 1)
    inset:SetColorTexture(0.18, 0.12, 0.05, 0.72)

    local accent = rowButton:CreateTexture(nil, "ARTWORK", nil, 1)
    accent:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", background, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(3)
    accent:SetColorTexture(1, 0.86, 0.45, 0.95)

    local borderTop = rowButton:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", background, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.95, 0.78, 0.35, 0.85)

    local borderBottom = rowButton:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", background, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.95, 0.78, 0.35, 0.85)

    local borderLeft = rowButton:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", background, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0.95, 0.78, 0.35, 0.85)

    local borderRight = rowButton:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", background, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0.95, 0.78, 0.35, 0.85)

    local glow = rowButton:CreateTexture(nil, "ARTWORK", nil, 2)
    glow:SetPoint("TOPLEFT", background, "TOPLEFT", 1, -1)
    glow:SetPoint("TOPRIGHT", background, "TOPRIGHT", -1, -1)
    glow:SetHeight(6)
    glow:SetColorTexture(1, 0.88, 0.55, 0.10)

    local decoration = {
        Background = background,
        Inset = inset,
        Accent = accent,
        BorderTop = borderTop,
        BorderBottom = borderBottom,
        BorderLeft = borderLeft,
        BorderRight = borderRight,
        Glow = glow,
    }

    rowButton.BeavisQoLHeaderDecoration = decoration
    return decoration
end

local function EnsureFavoriteRowHeaderLabel(rowButton)
    if rowButton.BeavisQoLHeaderLabel then
        return rowButton.BeavisQoLHeaderLabel
    end

    local label = rowButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetJustifyH("LEFT")
    label:SetPoint("LEFT", rowButton, "LEFT", 58, 0)
    label:SetPoint("RIGHT", rowButton, "RIGHT", -64, 0)
    label:SetTextColor(1, 0.88, 0.62, 1)
    label:SetShadowColor(0, 0, 0, 1)
    label:SetShadowOffset(1, -1)
    rowButton.BeavisQoLHeaderLabel = label

    return label
end

local function SetFavoriteRowHeaderDecorationShown(rowButton, shown)
    local decoration = EnsureFavoriteRowHeaderDecoration(rowButton)

    decoration.Background:SetShown(shown)
    decoration.Inset:SetShown(shown)
    decoration.Accent:SetShown(shown)
    decoration.BorderTop:SetShown(shown)
    decoration.BorderBottom:SetShown(shown)
    decoration.BorderLeft:SetShown(shown)
    decoration.BorderRight:SetShown(shown)
    decoration.Glow:SetShown(shown)
end

local function EnsureFavoriteRowCollapseIndicator(rowButton)
    if rowButton.BeavisQoLCollapseIndicator then
        return rowButton.BeavisQoLCollapseIndicator
    end

    local indicator = rowButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    indicator:SetPoint("LEFT", rowButton, "LEFT", 34, 0)
    indicator:SetTextColor(1, 0.88, 0.62, 1)
    indicator:SetShadowColor(0, 0, 0, 1)
    indicator:SetShadowOffset(1, -1)
    rowButton.BeavisQoLCollapseIndicator = indicator

    return indicator
end

local function GetFavoriteRowItemName(rowData)
    if not rowData or not rowData.itemKey or not C_AuctionHouse or not C_AuctionHouse.GetItemKeyInfo then
        return nil
    end

    local itemKeyInfo = C_AuctionHouse.GetItemKeyInfo(rowData.itemKey)
    return itemKeyInfo and itemKeyInfo.itemName or nil
end

local function FindFavoriteRowNameFontString(rowButton, rowData)
    if rowButton.BeavisQoLNameFontString and rowButton.BeavisQoLNameFontString.GetText then
        return rowButton.BeavisQoLNameFontString
    end

    local desiredItemName = StripColorCodes(GetFavoriteRowItemName(rowData))
    local bestFontString = nil
    local bestScore = -1

    local function ScoreFontString(fontString)
        if not fontString or not fontString.GetText then
            return
        end

        local text = StripColorCodes(fontString:GetText())
        if text == "" then
            return
        end

        local score = #text
        if string.find(text, "%a") then
            score = score + 100
        end

        if not string.match(text, "^[%d%.,%s]+$") then
            score = score + 20
        end

        if desiredItemName ~= "" and string.find(text, desiredItemName, 1, true) then
            score = score + 1000
        end

        if score > bestScore then
            bestScore = score
            bestFontString = fontString
        end
    end

    local function ScanFrame(frame)
        if not frame then
            return
        end

        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                ScoreFontString(region)
            end
        end
    end

    ScanFrame(rowButton)
    for _, child in ipairs({ rowButton:GetChildren() }) do
        ScanFrame(child)
    end

    rowButton.BeavisQoLNameFontString = bestFontString
    return bestFontString
end

local function RestoreFavoriteRowName(rowButton)
    local nameFontString = rowButton and rowButton.BeavisQoLNameFontString or nil
    if not nameFontString or not rowButton.BeavisQoLInjectedNameText then
        return
    end

    if rowButton.BeavisQoLOriginalNameText and nameFontString:GetText() == rowButton.BeavisQoLInjectedNameText then
        nameFontString:SetText(rowButton.BeavisQoLOriginalNameText)
    end

    rowButton.BeavisQoLInjectedNameText = nil
end

local function UpdateFavoriteRowName(rowButton, rowData, shouldShow)
    if not rowButton then
        return
    end

    local nameFontString = FindFavoriteRowNameFontString(rowButton, rowData)
    if not nameFontString then
        return
    end

    local currentText = nameFontString:GetText() or ""
    if rowButton.BeavisQoLInjectedNameText and currentText == rowButton.BeavisQoLInjectedNameText then
        currentText = rowButton.BeavisQoLOriginalNameText or currentText
    end

    rowButton.BeavisQoLOriginalNameText = currentText

    local groupName = shouldShow and rowData and rowData.itemKey and Misc.GetAuctionHouseFavoriteGroupName(rowData.itemKey) or nil
    if type(groupName) == "string" and groupName ~= "" and currentText ~= "" then
        local injectedText = string.format("|cffffd25a[%s]|r %s", groupName, currentText)
        if nameFontString:GetText() ~= injectedText then
            nameFontString:SetText(injectedText)
        end
        rowButton.BeavisQoLInjectedNameText = injectedText
        return
    end

    RestoreFavoriteRowName(rowButton)
end

local function UpdateVisibleFavoriteRowButtons(auctionHouseFrame)
    local browseResultsFrame = auctionHouseFrame and auctionHouseFrame.BrowseResultsFrame
    local itemList = browseResultsFrame and browseResultsFrame.ItemList
    local scrollBox = itemList and itemList.ScrollBox

    if not scrollBox or not scrollBox.FindFrame then
        return
    end

    if scrollBox.HasView and not scrollBox:HasView() then
        return
    end

    if scrollBox.HasDataProvider and not scrollBox:HasDataProvider() then
        return
    end

    local shouldShow = auctionHouseFrame
        and auctionHouseFrame.isDisplayingFavorites == true
        and browseResultsFrame
        and browseResultsFrame.IsShown
        and browseResultsFrame:IsShown()

    local dataProviderSize = scrollBox.GetDataProviderSize and scrollBox:GetDataProviderSize() or 0
    if type(dataProviderSize) ~= "number" or dataProviderSize <= 0 then
        return
    end

    local dataIndexBegin = scrollBox.GetDataIndexBegin and scrollBox:GetDataIndexBegin() or 0
    local dataIndexEnd = scrollBox.GetDataIndexEnd and scrollBox:GetDataIndexEnd() or 0
    if type(dataIndexBegin) ~= "number" or type(dataIndexEnd) ~= "number" then
        return
    end

    dataIndexBegin = math.max(1, math.floor(dataIndexBegin))
    dataIndexEnd = math.min(dataProviderSize, math.floor(dataIndexEnd))
    if dataIndexEnd < dataIndexBegin then
        return
    end

    for dataIndex = dataIndexBegin, dataIndexEnd do
        local ok, rowButton = pcall(scrollBox.FindFrame, scrollBox, dataIndex)
        if not ok then
            return
        end

        if rowButton then
            local assignButton = rowButton.BeavisQoLAssignButton
            local editButton = EnsureFavoriteRowEditButton(rowButton)
            local collapseIndicator = EnsureFavoriteRowCollapseIndicator(rowButton)
            local headerLabel = EnsureFavoriteRowHeaderLabel(rowButton)
            local rowData = rowButton.rowData or (rowButton.GetRowData and rowButton:GetRowData()) or nil
            local isHeaderRow = IsFavoriteGroupHeaderRow(rowData)
            local isVisibleHeaderRow = shouldShow and isHeaderRow
            local headerRowData = type(rowData) == "table" and rowData or nil

            if assignButton then
                assignButton.itemKey = nil
                assignButton:SetShown(false)
            end

            SetFavoriteRowHeaderDecorationShown(rowButton, isVisibleHeaderRow)
            collapseIndicator:SetShown(isVisibleHeaderRow)
            collapseIndicator:SetText((isHeaderRow and headerRowData and headerRowData.isCollapsed) and "+" or "-")
            headerLabel:SetShown(isVisibleHeaderRow)
            headerLabel:SetText(isHeaderRow and headerRowData and (headerRowData.virtualEntryText or "") or "")

            collapseIndicator:ClearAllPoints()
            headerLabel:ClearAllPoints()
            if isVisibleHeaderRow and rowButton.BeavisQoLHeaderDecoration and rowButton.BeavisQoLHeaderDecoration.Background then
                collapseIndicator:SetPoint("LEFT", rowButton.BeavisQoLHeaderDecoration.Background, "LEFT", 10, 0)
                headerLabel:SetPoint("LEFT", collapseIndicator, "RIGHT", 8, 0)
            else
                collapseIndicator:SetPoint("LEFT", rowButton, "LEFT", 10, 0)
                headerLabel:SetPoint("LEFT", rowButton, "LEFT", 30, 0)
            end

            editButton:ClearAllPoints()
            if isVisibleHeaderRow and rowButton.BeavisQoLHeaderDecoration and rowButton.BeavisQoLHeaderDecoration.Background then
                editButton:SetPoint("RIGHT", rowButton.BeavisQoLHeaderDecoration.Background, "RIGHT", -8, 0)
            else
                editButton:SetPoint("RIGHT", rowButton, "RIGHT", -8, 0)
            end
            headerLabel:SetPoint("RIGHT", editButton, "LEFT", -8, 0)

            editButton.groupID = isHeaderRow and headerRowData and headerRowData.favoriteGroupID or nil
            editButton.tooltipText = editButton.groupID
                and L("AUCTION_HOUSE_FAVORITE_GROUP_EDIT_TOOLTIP")
                or nil
            editButton:SetShown(isVisibleHeaderRow and editButton.groupID ~= nil)
        end
    end
end

local function InstallVirtualFavoriteGroupRowSupport()
    if virtualFavoriteGroupRowsInstalled then
        return
    end

    if type(AuctionHouseTableCellItemDisplayMixin) == "table" then
        local originalPopulate = AuctionHouseTableCellItemDisplayMixin.Populate or (AuctionHouseTableCellItemKeyMixin and AuctionHouseTableCellItemKeyMixin.Populate)

        if type(originalPopulate) == "function" then
            AuctionHouseTableCellItemDisplayMixin.Populate = function(self, rowData, dataIndex)
                self.rowData = rowData

                if IsFavoriteGroupHeaderRow(rowData) then
                    if self.pendingItemID ~= nil and self.UnregisterEvent then
                        self:UnregisterEvent("ITEM_KEY_ITEM_INFO_RECEIVED")
                        self.pendingItemID = nil
                    end

                    self:ClearDisplay()

                    if self.IconBorder then
                        self.IconBorder:Hide()
                    end

                    self.Text:SetText("")
                    self.Text:SetShadowColor(0, 0, 0, 0)
                    self.Text:SetShadowOffset(0, 0)

                    if self.ExtraInfo then
                        self.ExtraInfo:SetText("")
                        self.ExtraInfo:Hide()
                    end

                    return
                end

                self.Text:SetFontObject(Number14FontWhite)
                self.Text:SetTextColor(1, 1, 1, 1)
                self.Text:SetShadowColor(0, 0, 0, 0)
                self.Text:SetShadowOffset(0, 0)

                if self.IconBorder then
                    self.IconBorder:Show()
                end

                return originalPopulate(self, rowData, dataIndex)
            end
        end
    end

    if type(AuctionHouseTableCellMinPriceMixin) == "table" and type(AuctionHouseTableCellMinPriceMixin.Populate) == "function" then
        local originalPopulate = AuctionHouseTableCellMinPriceMixin.Populate

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseTableCellMinPriceMixin.Populate = function(self, rowData, dataIndex)
            self.rowData = rowData

            if IsFavoriteGroupHeaderRow(rowData) then
                self.Text:SetText("")
                self.Text:Hide()
                self.MoneyDisplay:Hide()
                self.Checkmark:Hide()
                return
            end

            self.Text:Show()
            return originalPopulate(self, rowData, dataIndex)
        end
    end

    if type(AuctionHouseTableCellQuantityMixin) == "table" and type(AuctionHouseTableCellQuantityMixin.Populate) == "function" then
        local originalPopulate = AuctionHouseTableCellQuantityMixin.Populate

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseTableCellQuantityMixin.Populate = function(self, rowData, dataIndex)
            self.rowData = rowData

            if IsFavoriteGroupHeaderRow(rowData) then
                self.Text:SetText("")
                return
            end

            return originalPopulate(self, rowData, dataIndex)
        end
    end

    if type(AuctionHouseTableCellLevelMixin) == "table" and type(AuctionHouseTableCellLevelMixin.Populate) == "function" then
        local originalPopulate = AuctionHouseTableCellLevelMixin.Populate

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseTableCellLevelMixin.Populate = function(self, rowData, dataIndex)
            self.rowData = rowData

            if IsFavoriteGroupHeaderRow(rowData) then
                if self.UnregisterEvent then
                    self:UnregisterEvent("EXTRA_BROWSE_INFO_RECEIVED")
                end

                self.Text:SetText("")
                return
            end

            return originalPopulate(self, rowData, dataIndex)
        end
    end

    if type(AuctionHouseTableCellFavoriteMixin) == "table" and type(AuctionHouseTableCellFavoriteMixin.Populate) == "function" then
        local originalPopulate = AuctionHouseTableCellFavoriteMixin.Populate

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseTableCellFavoriteMixin.Populate = function(self, rowData, dataIndex)
            self.rowData = rowData

            if IsFavoriteGroupHeaderRow(rowData) then
                self.FavoriteButton:SetItemKey(nil)
                self.FavoriteButton:Hide()
                return
            end

            self.FavoriteButton:Show()
            return originalPopulate(self, rowData, dataIndex)
        end
    end

    if type(AuctionHouseBrowseResultsFrameMixin) == "table" and type(AuctionHouseBrowseResultsFrameMixin.OnBrowseResultSelected) == "function" then
        local originalOnBrowseResultSelected = AuctionHouseBrowseResultsFrameMixin.OnBrowseResultSelected

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseBrowseResultsFrameMixin.OnBrowseResultSelected = function(self, browseResult)
            if IsFavoriteGroupHeaderRow(browseResult) then
                return
            end

            return originalOnBrowseResultSelected(self, browseResult)
        end
    end

    if type(AuctionHouseFavoritableLineMixin) == "table" and type(AuctionHouseFavoritableLineMixin.OnClick) == "function" then
        local originalOnClick = AuctionHouseFavoritableLineMixin.OnClick

        ---@diagnostic disable-next-line: duplicate-set-field
        AuctionHouseFavoritableLineMixin.OnClick = function(self, buttonName, ...)
            local rowData = (self.GetRowData and self:GetRowData()) or self.rowData
            if IsFavoriteGroupHeaderRow(rowData) then
                if buttonName == "LeftButton" then
                    Misc.ToggleAuctionHouseFavoriteGroupCollapsed(rowData.favoriteGroupID)

                    if RefreshFavoriteGroupsState then
                        RefreshFavoriteGroupsState()
                    end
                end
                return
            end

            return originalOnClick(self, buttonName, ...)
        end
    end

    virtualFavoriteGroupRowsInstalled = true
end

local function InstallFavoriteContextMenuOverride()
    if originalFavoriteContextMenu ~= nil or type(rawget(_G, "AuctionHouseFavoriteContextMenu")) ~= "function" then
        return
    end

    originalFavoriteContextMenu = rawget(_G, "AuctionHouseFavoriteContextMenu")

    _G.AuctionHouseFavoriteContextMenu = function(frame, itemKey)
        if not MenuUtil or not MenuUtil.CreateContextMenu or not C_AuctionHouse then
            return originalFavoriteContextMenu(frame, itemKey)
        end

        MenuUtil.CreateContextMenu(frame, function(_, rootDescription)
            rootDescription:SetTag("MENU_AUCTION_HOUSE_FAVORITE")

            local isFavorite = C_AuctionHouse.IsFavoriteItem(itemKey)

            local function CanChangeFavoriteState()
                return C_AuctionHouse.FavoritesAreAvailable() and (isFavorite or not C_AuctionHouse.HasMaxFavorites())
            end

            local favoriteText = isFavorite and AUCTION_HOUSE_DROPDOWN_REMOVE_FAVORITE or AUCTION_HOUSE_DROPDOWN_SET_FAVORITE
            local favoriteButton = rootDescription:CreateButton(favoriteText, function()
                if CanChangeFavoriteState() then
                    C_AuctionHouse.SetFavoriteItem(itemKey, not isFavorite)

                    if isFavorite then
                        Misc.AssignAuctionHouseFavoriteGroup(itemKey, nil)
                    end

                    if RefreshFavoriteGroupsState then
                        RefreshFavoriteGroupsState()
                    end
                end
            end)

            favoriteButton:SetEnabled(CanChangeFavoriteState)

            if not isFavorite then
                return
            end

            rootDescription:CreateTitle(L("AUCTION_HOUSE_FAVORITE_GROUP_MENU_TITLE"))

            local function IsSelected(groupID)
                local assignedGroupID = Misc.GetAuctionHouseFavoriteGroupID(itemKey)
                if groupID == FAVORITE_GROUP_SELECTION_UNGROUPED then
                    return assignedGroupID == nil
                end

                return assignedGroupID == groupID
            end

            local function SetSelected(groupID)
                if groupID == FAVORITE_GROUP_SELECTION_UNGROUPED then
                    Misc.AssignAuctionHouseFavoriteGroup(itemKey, nil)
                else
                    Misc.AssignAuctionHouseFavoriteGroup(itemKey, groupID)
                end

                if RefreshFavoriteGroupsState then
                    RefreshFavoriteGroupsState()
                end
            end

            rootDescription:CreateRadio(L("AUCTION_HOUSE_FAVORITE_GROUP_UNGROUPED"), IsSelected, SetSelected, FAVORITE_GROUP_SELECTION_UNGROUPED)

            for _, group in ipairs(Misc.GetAuctionHouseFavoriteGroups()) do
                rootDescription:CreateRadio(group.name, IsSelected, SetSelected, group.id)
            end

            rootDescription:CreateButton(L("AUCTION_HOUSE_FAVORITE_GROUP_MENU_CREATE"), function()
                ShowCreateFavoriteGroupPopup(itemKey)
            end)

            local groups = Misc.GetAuctionHouseFavoriteGroups()
            if #groups > 0 then
                rootDescription:CreateTitle(L("AUCTION_HOUSE_FAVORITE_GROUPS_TITLE"))

                for _, group in ipairs(groups) do
                    rootDescription:CreateButton(L("AUCTION_HOUSE_FAVORITE_GROUP_DELETE_TOOLTIP"):format(group.name), function()
                        ShowDeleteFavoriteGroupPopup(group.id)
                    end)
                end
            end
        end)
    end
end

local function EnsureFavoriteGroupPopups()
    if not StaticPopupDialogs then
        return
    end

    if not StaticPopupDialogs[CREATE_GROUP_POPUP_KEY] then
        StaticPopupDialogs[CREATE_GROUP_POPUP_KEY] = {
            text = L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_POPUP"),
            button1 = L("AUCTION_HOUSE_FAVORITE_GROUP_CREATE_BUTTON"),
            button2 = CANCEL,
            hasEditBox = 1,
            maxLetters = 36,
            editBoxWidth = 200,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = StaticPopupNumDialogs,
            OnShow = function(self)
                PrepareCreateFavoriteGroupPopup(self)
            end,
            OnHide = function()
                pendingCreateFavoriteGroupItemKey = nil
            end,
            EditBoxOnTextChanged = function(editBox)
                UpdatePopupPrimaryButtonState(editBox)
            end,
            EditBoxOnEnterPressed = function(editBox)
                HandleFavoriteGroupPopupEnter(editBox)
            end,
            OnAccept = function(self)
                HandleCreateFavoriteGroupAccept(self)
            end,
        }
    end

    if not StaticPopupDialogs[RENAME_GROUP_POPUP_KEY] then
        StaticPopupDialogs[RENAME_GROUP_POPUP_KEY] = {
            text = L("AUCTION_HOUSE_FAVORITE_GROUP_RENAME_POPUP"),
            button1 = SAVE,
            button2 = CANCEL,
            hasEditBox = 1,
            maxLetters = 36,
            editBoxWidth = 200,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = StaticPopupNumDialogs,
            OnShow = function(self)
                local group = Misc.GetAuctionHouseFavoriteGroupByID(pendingRenameFavoriteGroupID)
                PrepareRenameFavoriteGroupPopup(self, group and group.name or "")
            end,
            OnHide = function()
                pendingRenameFavoriteGroupID = nil
            end,
            EditBoxOnTextChanged = function(editBox)
                UpdatePopupPrimaryButtonState(editBox)
            end,
            EditBoxOnEnterPressed = function(editBox)
                HandleFavoriteGroupPopupEnter(editBox)
            end,
            OnAccept = function(self)
                HandleRenameFavoriteGroupAccept(self)
            end,
        }
    end

    if not StaticPopupDialogs[DELETE_GROUP_POPUP_KEY] then
        StaticPopupDialogs[DELETE_GROUP_POPUP_KEY] = {
            text = L("AUCTION_HOUSE_FAVORITE_GROUP_DELETE_CONFIRM"),
            button1 = YES,
            button2 = CANCEL,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = StaticPopupNumDialogs,
            OnAccept = function(_, groupID)
                Misc.DeleteAuctionHouseFavoriteGroup(groupID)

                if RefreshFavoriteGroupsState then
                    RefreshFavoriteGroupsState()
                end
            end,
        }
    end
end

RefreshFavoriteGroupsState = function()
    local auctionHouseFrame = GetAuctionHouseFrame()
    if not auctionHouseFrame then
        return
    end

    UpdateFavoriteGroupsVisibility(auctionHouseFrame)

    if auctionHouseFrame.isDisplayingFavorites == true and auctionHouseFrame.BrowseResultsFrame then
        ApplyFavoriteGroupFilterToBrowseResults(auctionHouseFrame.BrowseResultsFrame)
        UpdateVisibleFavoriteRowButtons(auctionHouseFrame)
    end
end

local function EnsureFavoriteGroupsHooks()
    if hooksInstalled then
        return
    end

    local auctionHouseFrame = GetAuctionHouseFrame()
    local browseResultsFrame = auctionHouseFrame and auctionHouseFrame.BrowseResultsFrame
    local itemList = browseResultsFrame and browseResultsFrame.ItemList

    if not auctionHouseFrame or not browseResultsFrame or not itemList then
        return
    end

    InstallVirtualFavoriteGroupRowSupport()
    EnsureFavoriteGroupPopups()
    InstallFavoriteContextMenuOverride()

    itemList:SetLineOnEnterCallback(function(line, rowData)
        if not IsFavoriteGroupHeaderRow(rowData) and AuctionHouseUtil and AuctionHouseUtil.LineOnEnterCallback then
            AuctionHouseUtil.LineOnEnterCallback(line, rowData)
        end
    end)

    itemList:SetLineOnLeaveCallback(function(line, rowData)
        if not IsFavoriteGroupHeaderRow(rowData) and AuctionHouseUtil and AuctionHouseUtil.LineOnLeaveCallback then
            AuctionHouseUtil.LineOnLeaveCallback(line, rowData)
        else
            GameTooltip_Hide()
            ResetCursor()
            line:SetScript("OnUpdate", nil)
        end
    end)

    if auctionHouseFrame.QueryAll then
        hooksecurefunc(auctionHouseFrame, "QueryAll", function()
            RefreshFavoriteGroupsState()
        end)
    end

    if auctionHouseFrame.QueryItem then
        hooksecurefunc(auctionHouseFrame, "QueryItem", function()
            RefreshFavoriteGroupsState()
        end)
    end

    if auctionHouseFrame.SendBrowseQueryInternal then
        hooksecurefunc(auctionHouseFrame, "SendBrowseQueryInternal", function()
            RefreshFavoriteGroupsState()
        end)
    end

    if auctionHouseFrame.SetDisplayMode then
        hooksecurefunc(auctionHouseFrame, "SetDisplayMode", function()
            RefreshFavoriteGroupsState()
        end)
    end

    if browseResultsFrame.OnBrowseSearchStarted then
        hooksecurefunc(browseResultsFrame, "OnBrowseSearchStarted", function(self)
            if auctionHouseFrame.isDisplayingFavorites == true then
                self.BeavisQoLAllBrowseResults = {}
            else
                self.BeavisQoLAllBrowseResults = nil
            end

            RefreshFavoriteGroupsState()
        end)
    end

    if browseResultsFrame.UpdateBrowseResults then
        hooksecurefunc(browseResultsFrame, "UpdateBrowseResults", function(self)
            if auctionHouseFrame.isDisplayingFavorites == true and C_AuctionHouse and C_AuctionHouse.GetBrowseResults then
                self.BeavisQoLAllBrowseResults = C_AuctionHouse.GetBrowseResults() or {}
                ApplyFavoriteGroupFilterToBrowseResults(self)
            elseif self.BeavisQoLAllBrowseResults then
                self.BeavisQoLAllBrowseResults = nil
            end

            RefreshFavoriteGroupsState()
        end)
    end

    if itemList.RefreshScrollFrame then
        hooksecurefunc(itemList, "RefreshScrollFrame", function()
            UpdateVisibleFavoriteRowButtons(auctionHouseFrame)
        end)
    end

    if itemList.ScrollBox
        and itemList.ScrollBox.RegisterCallback
        and ScrollBoxListMixin
        and ScrollBoxListMixin.Event
        and ScrollBoxListMixin.Event.OnScroll
    then
        itemList.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnScroll, function()
            UpdateVisibleFavoriteRowButtons(auctionHouseFrame)
        end)
    end

    hooksInstalled = true
    RefreshFavoriteGroupsState()
end

FavoritesWatcher:RegisterEvent("ADDON_LOADED")
FavoritesWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
FavoritesWatcher:RegisterEvent("AUCTION_HOUSE_CLOSED")
FavoritesWatcher:RegisterEvent("AUCTION_HOUSE_FAVORITES_UPDATED")
FavoritesWatcher:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == AUCTION_HOUSE_UI_ADDON_NAME then
            EnsureFavoriteGroupsHooks()
        end
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        EnsureFavoriteGroupsHooks()
        RefreshFavoriteGroupsState()
        return
    end

    if event == "AUCTION_HOUSE_CLOSED" then
        local auctionHouseFrame = GetAuctionHouseFrame()
        if auctionHouseFrame and auctionHouseFrame.CategoriesList and auctionHouseFrame.CategoriesList.ScrollBox then
            auctionHouseFrame.CategoriesList.ScrollBox:Show()
        end
        if auctionHouseFrame and auctionHouseFrame.CategoriesList and auctionHouseFrame.CategoriesList.ScrollBar then
            auctionHouseFrame.CategoriesList.ScrollBar:Show()
        end
        if favoriteGroupsUI then
            favoriteGroupsUI:Hide()
        end
        if favoriteGroupCreateButton then
            favoriteGroupCreateButton:Hide()
        end
        return
    end

    if event == "AUCTION_HOUSE_FAVORITES_UPDATED" then
        RefreshFavoriteGroupsState()
    end
end)

if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AUCTION_HOUSE_UI_ADDON_NAME) then
    EnsureFavoriteGroupsHooks()
end
