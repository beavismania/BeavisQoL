local ADDON_NAME, BeavisQoL = ...

BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG
local L = BeavisQoL.L

local PLAYSTYLE_NONE = 0
local AutoFillHookFrame = CreateFrame("Frame")
local EntryCreationHooksInstalled = false
local EntryCreationUpdateHookInstalled = false
local ScheduledApplySerial = 0
local EditBoxStateByWidget = setmetatable({}, { __mode = "k" })
local EntryCreationStateByFrame = setmetatable({}, { __mode = "k" })
local SecurityLockedTextInputByWidget = setmetatable({}, { __mode = "k" })
local LISTING_TEXT_PRESET_COUNT = 5
local COPY_BUTTON_SIZE = 22
local GEAR_BUTTON_SIZE = 22
local GEAR_BUTTON_TITLE_GAP = 8
local GEAR_BUTTON_TITLE_FALLBACK_WIDTH = 96
local COPY_BUTTON_ICON = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up"
local GEAR_BUTTON_ICON = "Interface\\Buttons\\UI-OptionsButton"
local ListingCopyDialog
local ListingCopyMenuFrame

local function NormalizeLineEndings(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function TrimWhitespace(text)
    text = NormalizeLineEndings(text)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function NormalizeSingleLineText(text)
    text = TrimWhitespace(text)
    text = text:gsub("%s*\n%s*", " ")
    text = text:gsub("%s+", " ")
    return text
end

local function NormalizeMultiLineText(text)
    text = TrimWhitespace(text)
    text = text:gsub("[ \t]+\n", "\n")
    text = text:gsub("\n[ \t]+", "\n")
    return text
end

local function EscapePattern(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:gsub("([^%w])", "%%%1")
end

local function EndsWithText(text, suffix)
    text = NormalizeSingleLineText(text)
    suffix = NormalizeSingleLineText(suffix)

    if suffix == "" then
        return false
    end

    return text:match(EscapePattern(suffix) .. "$") ~= nil
end

local function TrimTrailingSuffix(text, suffix)
    text = NormalizeSingleLineText(text)
    suffix = NormalizeSingleLineText(suffix)

    if suffix == "" then
        return text
    end

    return text:gsub("%s*" .. EscapePattern(suffix) .. "%s*$", "")
end

local function TryCallMethod(target, methodName, ...)
    if not target or type(methodName) ~= "string" then
        return false
    end

    local method = target[methodName]
    if type(method) ~= "function" then
        return false
    end

    local secureCall = rawget(_G, "securecallfunction")
    if type(secureCall) == "function" then
        local ok = pcall(secureCall, method, target, ...)
        return ok == true
    end

    local ok = pcall(method, target, ...)
    return ok == true
end

local function MarkChanged(changed, didChange)
    if didChange then
        return true
    end

    return changed == true
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false
    end

    local secureCall = rawget(_G, "securecallfunction")
    if type(secureCall) == "function" then
        local ok = pcall(secureCall, func, ...)
        return ok == true
    end

    local ok = pcall(func, ...)
    return ok == true
end

local function AddChatMessage(message)
    if type(message) ~= "string" or message == "" then
        return
    end

    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66d9efBeavisQoL:|r " .. message)
    end
end

local function GetEditBoxState(editBox)
    if not editBox then
        return nil
    end

    local state = EditBoxStateByWidget[editBox]
    if state then
        return state
    end

    state = {}
    EditBoxStateByWidget[editBox] = state
    return state
end

local function GetEntryCreationState(entryCreation)
    if not entryCreation then
        return nil
    end

    local state = EntryCreationStateByFrame[entryCreation]
    if state then
        return state
    end

    state = {}
    EntryCreationStateByFrame[entryCreation] = state
    return state
end

local function GetListingAutoFillDB()
    return LFG.GetLFGDB and LFG.GetLFGDB() or nil
end

local function NormalizePresetSlots(values, normalizeFunc, fallbackValue)
    local slots = {}
    if type(normalizeFunc) ~= "function" then
        normalizeFunc = NormalizeSingleLineText
    end

    for index = 1, LISTING_TEXT_PRESET_COUNT do
        slots[index] = ""
    end

    if type(values) == "table" then
        for index = 1, LISTING_TEXT_PRESET_COUNT do
            slots[index] = normalizeFunc(values[index])
        end
    end

    local fallbackText = normalizeFunc(fallbackValue)
    if slots[1] == "" and fallbackText ~= "" then
        slots[1] = fallbackText
    end

    return slots
end

local function GetFirstPresetText(slots)
    if type(slots) ~= "table" then
        return ""
    end

    for index = 1, LISTING_TEXT_PRESET_COUNT do
        local text = slots[index]
        if type(text) == "string" and text ~= "" then
            return text
        end
    end

    return ""
end

local function GetPresetChoices(slots)
    local choices = {}
    if type(slots) ~= "table" then
        return choices
    end

    for index = 1, LISTING_TEXT_PRESET_COUNT do
        local text = slots[index]
        if type(text) == "string" and text ~= "" then
            choices[#choices + 1] = {
                index = index,
                text = text,
            }
        end
    end

    return choices
end

local function GetListingNamePresetSlotsFromDB(db)
    return NormalizePresetSlots(db and db.listingNamePresets or nil, NormalizeSingleLineText, db and db.listingNameSuffix or "")
end

local function GetListingDetailsPresetSlotsFromDB(db)
    return NormalizePresetSlots(db and db.listingDetailsPresets or nil, NormalizeMultiLineText, db and db.listingDetailsPreset or "")
end

local function StoreListingNamePresetSlots(db, slots)
    if not db then
        return
    end

    db.listingNamePresets = NormalizePresetSlots(slots, NormalizeSingleLineText)
    db.listingNameSuffix = GetFirstPresetText(db.listingNamePresets)
end

local function StoreListingDetailsPresetSlots(db, slots)
    if not db then
        return
    end

    db.listingDetailsPresets = NormalizePresetSlots(slots, NormalizeMultiLineText)
    db.listingDetailsPreset = GetFirstPresetText(db.listingDetailsPresets)
end

function LFG.IsListingAutoFillEnabled()
    local db = GetListingAutoFillDB()
    return db and db.listingAutoFillEnabled == true or false
end

function LFG.SetListingAutoFillEnabled(value)
    local db = GetListingAutoFillDB()
    if not db then
        return
    end

    db.listingAutoFillEnabled = value == true
    if LFG.RefreshListingAutoFill then
        LFG.RefreshListingAutoFill()
    end
end

function LFG.GetListingNameSuffix()
    local db = GetListingAutoFillDB()
    return GetFirstPresetText(GetListingNamePresetSlotsFromDB(db))
end

function LFG.SetListingNameSuffix(value)
    LFG.SetListingNamePreset(1, value)
end

function LFG.GetListingNamePresetSlots()
    local db = GetListingAutoFillDB()
    return GetListingNamePresetSlotsFromDB(db)
end

function LFG.GetListingNamePresetChoices()
    return GetPresetChoices(GetListingNamePresetSlotsFromDB(GetListingAutoFillDB()))
end

function LFG.SetListingNamePreset(index, value)
    local db = GetListingAutoFillDB()
    if not db then
        return
    end

    index = math.max(1, math.min(LISTING_TEXT_PRESET_COUNT, math.floor(tonumber(index) or 1)))
    local slots = GetListingNamePresetSlotsFromDB(db)
    slots[index] = NormalizeSingleLineText(value)
    StoreListingNamePresetSlots(db, slots)
    if LFG.RefreshListingAutoFill then
        LFG.RefreshListingAutoFill()
    end
end

function LFG.GetListingDetailsPreset()
    local db = GetListingAutoFillDB()
    return GetFirstPresetText(GetListingDetailsPresetSlotsFromDB(db))
end

function LFG.SetListingDetailsPreset(value)
    LFG.SetListingDetailsPresetSlot(1, value)
end

function LFG.GetListingDetailsPresetSlots()
    local db = GetListingAutoFillDB()
    return GetListingDetailsPresetSlotsFromDB(db)
end

function LFG.GetListingDetailsPresetChoices()
    return GetPresetChoices(GetListingDetailsPresetSlotsFromDB(GetListingAutoFillDB()))
end

function LFG.SetListingDetailsPresetSlot(index, value)
    local db = GetListingAutoFillDB()
    if not db then
        return
    end

    index = math.max(1, math.min(LISTING_TEXT_PRESET_COUNT, math.floor(tonumber(index) or 1)))
    local slots = GetListingDetailsPresetSlotsFromDB(db)
    slots[index] = NormalizeMultiLineText(value)
    StoreListingDetailsPresetSlots(db, slots)
    if LFG.RefreshListingAutoFill then
        LFG.RefreshListingAutoFill()
    end
end

function LFG.GetListingPlaystylePreset()
    local db = GetListingAutoFillDB()
    if not db then
        return PLAYSTYLE_NONE
    end

    return math.max(PLAYSTYLE_NONE, math.floor(tonumber(db.listingPlaystylePreset) or PLAYSTYLE_NONE))
end

function LFG.SetListingPlaystylePreset(value)
    local db = GetListingAutoFillDB()
    if not db then
        return
    end

    db.listingPlaystylePreset = math.max(PLAYSTYLE_NONE, math.floor(tonumber(value) or PLAYSTYLE_NONE))
    if LFG.RefreshListingAutoFill then
        LFG.RefreshListingAutoFill()
    end
end

local function GetPlaystyleFallbackLabel(value)
    if value == PLAYSTYLE_NONE then
        return L("LFG_LISTING_PLAYSTYLE_NONE")
    end

    local enum = Enum and Enum.LFGEntryGeneralPlaystyle or nil
    if enum and value == enum.Learning then
        return L("LFG_LISTING_PLAYSTYLE_LEARNING")
    end

    if enum and value == enum.FunRelaxed then
        return L("LFG_LISTING_PLAYSTYLE_RELAXED")
    end

    if enum and value == enum.FunSerious then
        return L("LFG_LISTING_PLAYSTYLE_COMPETITIVE")
    end

    if enum and value == enum.Expert then
        return L("LFG_LISTING_PLAYSTYLE_EXPERT")
    end

    if value == 1 then
        return L("LFG_LISTING_PLAYSTYLE_LEARNING")
    end

    if value == 2 then
        return L("LFG_LISTING_PLAYSTYLE_RELAXED")
    end

    if value == 3 then
        return L("LFG_LISTING_PLAYSTYLE_COMPETITIVE")
    end

    if value == 4 then
        return L("LFG_LISTING_PLAYSTYLE_EXPERT")
    end

    return tostring(value)
end

local function GetPlaystyleTokenPrefix(activityInfo)
    return "GROUP_FINDER_GENERAL_PLAYSTYLE"
end

function LFG.GetListingPlaystylePresetLabel(value, activityInfo)
    value = math.max(PLAYSTYLE_NONE, math.floor(tonumber(value) or PLAYSTYLE_NONE))
    if value == PLAYSTYLE_NONE then
        return L("LFG_LISTING_PLAYSTYLE_NONE")
    end

    local globalLabel = _G[GetPlaystyleTokenPrefix(activityInfo) .. tostring(value)]
    if type(globalLabel) == "string" and globalLabel ~= "" then
        return globalLabel
    end

    return GetPlaystyleFallbackLabel(value)
end

function LFG.GetListingPlaystylePresetOptions(activityInfo)
    local enum = Enum and Enum.LFGEntryGeneralPlaystyle or nil

    return {
        {
            value = PLAYSTYLE_NONE,
            label = LFG.GetListingPlaystylePresetLabel(PLAYSTYLE_NONE, activityInfo),
        },
        {
            value = enum and enum.Learning or 1,
            label = LFG.GetListingPlaystylePresetLabel(enum and enum.Learning or 1, activityInfo),
        },
        {
            value = enum and enum.FunRelaxed or 2,
            label = LFG.GetListingPlaystylePresetLabel(enum and enum.FunRelaxed or 2, activityInfo),
        },
        {
            value = enum and enum.FunSerious or 3,
            label = LFG.GetListingPlaystylePresetLabel(enum and enum.FunSerious or 3, activityInfo),
        },
        {
            value = enum and enum.Expert or 4,
            label = LFG.GetListingPlaystylePresetLabel(enum and enum.Expert or 4, activityInfo),
        },
    }
end

local function GetEntryCreationFrame()
    return LFGListFrame and LFGListFrame.EntryCreation or nil
end

local function GetEntryCreationActivityID(entryCreation)
    if not entryCreation then
        return nil
    end

    local directActivityID = tonumber(entryCreation.selectedActivityID or entryCreation.selectedActivity or entryCreation.activityID)
    if directActivityID and directActivityID > 0 then
        return directActivityID
    end

    local activityIDs = entryCreation.selectedActivityIDs or entryCreation.activityIDs
    if type(activityIDs) == "table" then
        local firstActivityID = tonumber(activityIDs[1])
        if firstActivityID and firstActivityID > 0 then
            return firstActivityID
        end
    end

    return nil
end

local function GetEntryCreationActivityInfo(entryCreation)
    if not C_LFGList or type(C_LFGList.GetActivityInfoTable) ~= "function" then
        return nil
    end

    local activityID = GetEntryCreationActivityID(entryCreation)
    if not activityID then
        return nil
    end

    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if type(activityInfo) == "table" then
        return activityInfo
    end

    return nil
end

local function BuildListingName(baseName, suffix)
    baseName = NormalizeSingleLineText(baseName)
    suffix = NormalizeSingleLineText(suffix)

    if suffix == "" then
        return baseName
    end

    if baseName == "" then
        return suffix
    end

    return string.format("%s %s", baseName, suffix)
end

local function ResolveTextInputWidget(widget)
    if not widget then
        return nil
    end

    if type(widget.GetText) == "function" and type(widget.SetText) == "function" then
        return widget
    end

    if widget.EditBox and type(widget.EditBox.GetText) == "function" and type(widget.EditBox.SetText) == "function" then
        return widget.EditBox
    end

    if widget.editBox and type(widget.editBox.GetText) == "function" and type(widget.editBox.SetText) == "function" then
        return widget.editBox
    end

    return nil
end

local function MarkSecurityLockedTextInput(widget)
    local editBox = ResolveTextInputWidget(widget)
    if editBox then
        SecurityLockedTextInputByWidget[editBox] = true
    end

    return editBox
end

local function SetEditBoxText(editBox, text)
    editBox = ResolveTextInputWidget(editBox)
    if not editBox or type(text) ~= "string" then
        return false
    end

    if SecurityLockedTextInputByWidget[editBox] then
        return false
    end

    if type(editBox.IsForbidden) == "function" and editBox:IsForbidden() then
        return false
    end

    if type(editBox.IsProtected) == "function" and editBox:IsProtected() and InCombatLockdown and InCombatLockdown() then
        return false
    end

    local currentText = editBox.GetText and editBox:GetText() or nil
    if type(currentText) == "string" and currentText == text then
        return false
    end

    if SafeCall(editBox.SetText, editBox, text) then
        local updatedText = editBox.GetText and editBox:GetText() or nil
        if type(updatedText) == "string" and updatedText == text then
            return true
        end
    end

    return false
end

local function TrackUserChanges(widget)
    local editBox = ResolveTextInputWidget(widget)
    local state = GetEditBoxState(editBox)
    if not editBox or not state or state.tracking then
        return editBox
    end

    state.tracking = true
    editBox:HookScript("OnTextChanged", function(self, userInput)
        if userInput then
            local hookState = GetEditBoxState(self)
            if hookState then
                hookState.userModified = true
            end
        end
    end)

    return editBox
end

local function ApplyListingNamePreset(entryCreation, db, forceApply)
    local nameBox = TrackUserChanges(entryCreation and entryCreation.Name or nil)
    if not nameBox then
        return false
    end

    local nameState = GetEditBoxState(nameBox)
    if not nameState then
        return false
    end

    local currentText = NormalizeSingleLineText(nameBox:GetText())
    local currentSuffix = GetFirstPresetText(GetListingNamePresetSlotsFromDB(db))
    local previousSuffix = NormalizeSingleLineText(nameState.lastSuffix or "")
    local previousApplied = NormalizeSingleLineText(nameState.lastApplied or "")

    local baseText = currentText
    if previousSuffix ~= "" and EndsWithText(baseText, previousSuffix) then
        baseText = TrimTrailingSuffix(baseText, previousSuffix)
    end
    if currentSuffix ~= "" and EndsWithText(baseText, currentSuffix) then
        baseText = TrimTrailingSuffix(baseText, currentSuffix)
    end

    local nextText = BuildListingName(baseText, currentSuffix)
    local shouldApply = false

    if currentText == "" then
        if currentSuffix ~= "" and baseText ~= "" then
            shouldApply = true
        end
    elseif currentText == previousApplied then
        shouldApply = true
    elseif previousSuffix ~= "" and EndsWithText(currentText, previousSuffix) then
        shouldApply = true
    elseif currentSuffix ~= "" and not nameState.userModified then
        shouldApply = not EndsWithText(currentText, currentSuffix)
    elseif currentSuffix == "" and previousApplied ~= "" and currentText == previousApplied then
        shouldApply = true
    end

    if forceApply and currentText ~= "" then
        if currentText == previousApplied or (previousSuffix ~= "" and EndsWithText(currentText, previousSuffix)) then
            shouldApply = true
        end
    end

    local didChange = false
    if shouldApply and nextText ~= "" and currentText ~= nextText then
        didChange = SetEditBoxText(nameBox, nextText)
        if didChange then
            nameState.userModified = false
            currentText = nextText
        end
    end

    nameState.lastApplied = currentText
    nameState.lastSuffix = currentSuffix
    return didChange
end

local function ApplyListingDescriptionPreset(entryCreation, db)
    local descriptionBox = TrackUserChanges(entryCreation and entryCreation.Description or nil)
    if not descriptionBox then
        return false
    end

    local descriptionState = GetEditBoxState(descriptionBox)
    if not descriptionState then
        return false
    end

    local presetText = GetFirstPresetText(GetListingDetailsPresetSlotsFromDB(db))
    local currentText = NormalizeMultiLineText(descriptionBox:GetText())
    local previousApplied = NormalizeMultiLineText(descriptionState.lastApplied or "")
    local shouldApply = false
    local nextText = currentText

    if presetText == "" then
        if previousApplied ~= "" and currentText == previousApplied then
            nextText = ""
            shouldApply = true
        end
    elseif currentText == "" or currentText == previousApplied then
        nextText = presetText
        shouldApply = true
    end

    local didChange = false
    if shouldApply and currentText ~= nextText then
        didChange = SetEditBoxText(descriptionBox, nextText)
        if didChange then
            descriptionState.userModified = false
            currentText = nextText
        end
    end

    descriptionState.lastApplied = currentText
    return didChange
end

local function GetListingNameClipboardText(entryCreation, presetText)
    local nameBox = ResolveTextInputWidget(entryCreation and entryCreation.Name or nil)
    local currentText = NormalizeSingleLineText(nameBox and nameBox:GetText() or "")
    local currentSuffix = NormalizeSingleLineText(presetText)
    if currentSuffix == "" then
        return ""
    end

    local baseText = currentText
    local nameState = GetEditBoxState(nameBox)
    local previousSuffix = NormalizeSingleLineText(nameState and nameState.lastSuffix or "")
    if previousSuffix ~= "" and EndsWithText(baseText, previousSuffix) then
        baseText = TrimTrailingSuffix(baseText, previousSuffix)
    end

    if EndsWithText(baseText, currentSuffix) then
        return baseText
    end

    return BuildListingName(baseText, currentSuffix)
end

local function GetListingDetailsClipboardText(presetText)
    return NormalizeMultiLineText(presetText)
end

local function AbbreviateMenuText(text)
    text = NormalizeSingleLineText(text)
    if #text > 48 then
        return text:sub(1, 45) .. "..."
    end

    return text
end

local function GetPresetMenuLabel(choice)
    if type(choice) ~= "table" then
        return ""
    end

    return string.format(L("LFG_LISTING_PRESET_MENU_LABEL"), choice.index or 1, AbbreviateMenuText(choice.text or ""))
end

local function ShowListingCopyDialog(text, label)
    text = NormalizeLineEndings(text)
    if text == "" then
        AddChatMessage(L("LFG_LISTING_COPY_EMPTY"))
        return false
    end

    if not ListingCopyDialog then
        local frameTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
        ListingCopyDialog = CreateFrame("Frame", nil, UIParent, frameTemplate)
        ListingCopyDialog:SetSize(440, 220)
        ListingCopyDialog:SetPoint("CENTER")
        ListingCopyDialog:SetFrameStrata("DIALOG")
        ListingCopyDialog:EnableMouse(true)
        ListingCopyDialog:SetMovable(true)
        ListingCopyDialog:RegisterForDrag("LeftButton")
        ListingCopyDialog:SetScript("OnDragStart", ListingCopyDialog.StartMoving)
        ListingCopyDialog:SetScript("OnDragStop", ListingCopyDialog.StopMovingOrSizing)
        ListingCopyDialog:Hide()

        if ListingCopyDialog.SetBackdrop then
            ListingCopyDialog:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 32,
                edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
        end

        ListingCopyDialog.Title = ListingCopyDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        ListingCopyDialog.Title:SetPoint("TOPLEFT", 18, -16)
        ListingCopyDialog.Title:SetPoint("RIGHT", -40, 0)
        ListingCopyDialog.Title:SetJustifyH("LEFT")

        ListingCopyDialog.CloseButton = CreateFrame("Button", nil, ListingCopyDialog, "UIPanelCloseButton")
        ListingCopyDialog.CloseButton:SetPoint("TOPRIGHT", -4, -4)

        ListingCopyDialog.Instructions = ListingCopyDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ListingCopyDialog.Instructions:SetPoint("TOPLEFT", ListingCopyDialog.Title, "BOTTOMLEFT", 0, -8)
        ListingCopyDialog.Instructions:SetPoint("RIGHT", -18, 0)
        ListingCopyDialog.Instructions:SetJustifyH("LEFT")
        ListingCopyDialog.Instructions:SetText(L("LFG_LISTING_COPY_DIALOG_HINT"))

        ListingCopyDialog.TextPanel = CreateFrame("Frame", nil, ListingCopyDialog, frameTemplate)
        ListingCopyDialog.TextPanel:SetPoint("TOPLEFT", ListingCopyDialog.Instructions, "BOTTOMLEFT", 0, -14)
        ListingCopyDialog.TextPanel:SetPoint("BOTTOMRIGHT", ListingCopyDialog, "BOTTOMRIGHT", -18, 54)
        if ListingCopyDialog.TextPanel.SetBackdrop then
            ListingCopyDialog.TextPanel:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false,
                edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            ListingCopyDialog.TextPanel:SetBackdropColor(0.035, 0.035, 0.04, 0.94)
            ListingCopyDialog.TextPanel:SetBackdropBorderColor(0.55, 0.44, 0.25, 0.95)
        end

        local editBox = CreateFrame("EditBox", nil, ListingCopyDialog.TextPanel)
        editBox:SetPoint("TOPLEFT", 10, -8)
        editBox:SetPoint("BOTTOMRIGHT", -10, 8)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(true)
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
        editBox:SetTextColor(1, 0.96, 0.86, 1)
        editBox:SetTextInsets(0, 0, 0, 0)
        editBox:SetJustifyH("LEFT")
        editBox:SetJustifyV("TOP")
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            ListingCopyDialog:Hide()
        end)
        editBox:SetScript("OnKeyDown", function(self, key)
            self.BeavisCopyKeyWasPressed = (key == "C" or key == "c") and IsControlKeyDown and IsControlKeyDown()
        end)
        editBox:SetScript("OnKeyUp", function(self, key)
            if (key == "C" or key == "c") and self.BeavisCopyKeyWasPressed then
                self.BeavisCopyKeyWasPressed = false
                if C_Timer and type(C_Timer.After) == "function" then
                    C_Timer.After(0, function()
                        if ListingCopyDialog then
                            ListingCopyDialog:Hide()
                        end
                    end)
                elseif ListingCopyDialog then
                    ListingCopyDialog:Hide()
                end
            end
        end)
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if not userInput or self.BeavisRestoringCopyText then
                return
            end

            self.BeavisRestoringCopyText = true
            self:SetText(self.BeavisCopyText or "")
            self:SetCursorPosition(0)
            self:HighlightText()
            self.BeavisRestoringCopyText = false
        end)
        editBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
        end)
        editBox:SetScript("OnMouseUp", function(self)
            self:HighlightText()
        end)
        ListingCopyDialog.EditBox = editBox

        ListingCopyDialog.CloseActionButton = CreateFrame("Button", nil, ListingCopyDialog, "UIPanelButtonTemplate")
        ListingCopyDialog.CloseActionButton:SetSize(110, 24)
        ListingCopyDialog.CloseActionButton:SetPoint("BOTTOMRIGHT", -18, 18)
        ListingCopyDialog.CloseActionButton:SetText(CLOSE)
        ListingCopyDialog.CloseActionButton:SetScript("OnClick", function()
            ListingCopyDialog:Hide()
        end)
    end

    ListingCopyDialog.Title:SetText(string.format(L("LFG_LISTING_COPY_DIALOG_TITLE"), label))
    ListingCopyDialog.EditBox.BeavisCopyText = text
    ListingCopyDialog.EditBox:SetText(text)
    ListingCopyDialog:Show()
    ListingCopyDialog.EditBox:SetCursorPosition(0)
    ListingCopyDialog.EditBox:SetFocus()
    ListingCopyDialog.EditBox:HighlightText()
    return true
end

local function ShowListingCopyMenu(owner, choices, textProvider, labelKey)
    if type(choices) ~= "table" or #choices == 0 or type(textProvider) ~= "function" then
        AddChatMessage(L("LFG_LISTING_COPY_EMPTY"))
        return
    end

    if #choices == 1 then
        ShowListingCopyDialog(textProvider(choices[1]), L(labelKey))
        return
    end

    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
            if rootDescription.CreateTitle then
                rootDescription:CreateTitle(L(labelKey))
            end
            for _, choice in ipairs(choices) do
                local presetChoice = choice
                local menuLabel = GetPresetMenuLabel(presetChoice)
                rootDescription:CreateButton(menuLabel, function()
                    ShowListingCopyDialog(textProvider(presetChoice), menuLabel)
                end)
            end
        end)
        return
    end

    if not ListingCopyMenuFrame then
        ListingCopyMenuFrame = CreateFrame("Frame", "BeavisQoLListingCopyMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = {}
    for _, choice in ipairs(choices) do
        local presetChoice = choice
        local menuLabel = GetPresetMenuLabel(presetChoice)
        menu[#menu + 1] = {
            text = menuLabel,
            notCheckable = true,
            func = function()
                ShowListingCopyDialog(textProvider(presetChoice), menuLabel)
            end,
        }
    end

    if type(EasyMenu) == "function" then
        EasyMenu(menu, ListingCopyMenuFrame, owner, 0, 0, "MENU")
    else
        ShowListingCopyDialog(textProvider(choices[1]), L(labelKey))
    end
end

local function CreateListingCopyButton(entryCreation, key, relativeTo, point, relativePoint, x, y)
    local entryState = GetEntryCreationState(entryCreation)
    if not entryCreation or not entryState or not relativeTo then
        return nil
    end

    entryState.copyButtons = entryState.copyButtons or {}
    local button = entryState.copyButtons[key]
    if button then
        button:ClearAllPoints()
        button:SetPoint(point, relativeTo, relativePoint, x, y)
        return button
    end

    button = CreateFrame("Button", nil, entryCreation)
    button:SetSize(COPY_BUTTON_SIZE, COPY_BUTTON_SIZE)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetFrameLevel((entryCreation:GetFrameLevel() or 0) + 20)
    button:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
    button:SetDisabledTexture("Interface\\Buttons\\UI-SquareButton-Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetTexture(COPY_BUTTON_ICON)
    button.Icon:SetSize(14, 14)
    button.Icon:SetPoint("CENTER", -1, 0)

    button:SetScript("OnMouseDown", function(self)
        if self.Icon then
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", -2, -1)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        if self.Icon then
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", -1, 0)
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L(self.tooltipTitleKey), 1, 0.82, 0)
        GameTooltip:AddLine(L(self.tooltipTextKey), 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ShowListingCopyMenu(self, self:GetChoices(), function(choice)
            return self:GetCopyText(choice)
        end, self.copyLabelKey)
    end)

    entryState.copyButtons[key] = button
    return button
end

local function OpenListingPresetSettings()
    if BeavisQoL and BeavisQoL.OpenPage then
        BeavisQoL.OpenPage("LFG")
    end

    local function ScrollToPresets()
        local page = BeavisQoL and BeavisQoL.Pages and BeavisQoL.Pages.LFG or nil
        if page and page.ScrollToListingPresets then
            page:ScrollToListingPresets()
        end
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, ScrollToPresets)
    else
        ScrollToPresets()
    end
end

local function AnchorListingSettingsButton(button, entryCreation)
    button:ClearAllPoints()

    local title = entryCreation and entryCreation.Label or nil
    if title then
        local titleWidth = GEAR_BUTTON_TITLE_FALLBACK_WIDTH
        if title.GetStringWidth then
            titleWidth = title:GetStringWidth() or titleWidth
            if titleWidth <= 0 then
                titleWidth = GEAR_BUTTON_TITLE_FALLBACK_WIDTH
            end
        end

        button:SetPoint("LEFT", title, "CENTER", (titleWidth / 2) + GEAR_BUTTON_TITLE_GAP, 0)
        return
    end

    button:SetPoint("TOP", entryCreation, "TOP", 60, -35)
end

local function CreateListingSettingsButton(entryCreation)
    local entryState = GetEntryCreationState(entryCreation)
    if not entryCreation or not entryState then
        return nil
    end

    if entryState.settingsButton then
        AnchorListingSettingsButton(entryState.settingsButton, entryCreation)
        return entryState.settingsButton
    end

    local button = CreateFrame("Button", nil, entryCreation)
    button:SetSize(GEAR_BUTTON_SIZE, GEAR_BUTTON_SIZE)
    AnchorListingSettingsButton(button, entryCreation)
    button:SetFrameLevel((entryCreation:GetFrameLevel() or 0) + 20)
    button:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
    button:SetDisabledTexture("Interface\\Buttons\\UI-SquareButton-Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button.Icon:SetTexture(GEAR_BUTTON_ICON)
    button.Icon:SetSize(15, 15)
    button.Icon:SetPoint("CENTER", -1, 0)

    button:SetScript("OnMouseDown", function(self)
        if self.Icon then
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", -2, -1)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        if self.Icon then
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", -1, 0)
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("LFG_LISTING_SETTINGS_BUTTON_TOOLTIP"), 1, 0.82, 0)
        GameTooltip:AddLine(L("LFG_LISTING_SETTINGS_BUTTON_TOOLTIP_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        OpenListingPresetSettings()
    end)

    entryState.settingsButton = button
    return button
end

local function UpdateListingCopyButtons(entryCreation, db)
    local entryState = GetEntryCreationState(entryCreation)
    if not entryCreation or not entryState then
        return
    end

    CreateListingSettingsButton(entryCreation)

    local nameButton = CreateListingCopyButton(entryCreation, "name", entryCreation.NameLabel or entryCreation.Name, "LEFT", "RIGHT", 6, 0)
    if nameButton then
        nameButton.tooltipTitleKey = "LFG_LISTING_COPY_NAME_TOOLTIP"
        nameButton.tooltipTextKey = "LFG_LISTING_COPY_NAME_TOOLTIP_DESC"
        nameButton.copyLabelKey = "LFG_LISTING_COPY_NAME_LABEL"
        nameButton.GetChoices = function()
            return GetPresetChoices(GetListingNamePresetSlotsFromDB(GetListingAutoFillDB()))
        end
        nameButton.GetCopyText = function(_, choice)
            return GetListingNameClipboardText(entryCreation, choice and choice.text or "")
        end
    end

    local descriptionButton = CreateListingCopyButton(entryCreation, "description", entryCreation.DescriptionLabel or entryCreation.Description, "LEFT", "RIGHT", 6, 0)
    if descriptionButton then
        descriptionButton.tooltipTitleKey = "LFG_LISTING_COPY_DETAILS_TOOLTIP"
        descriptionButton.tooltipTextKey = "LFG_LISTING_COPY_DETAILS_TOOLTIP_DESC"
        descriptionButton.copyLabelKey = "LFG_LISTING_COPY_DETAILS_LABEL"
        descriptionButton.GetChoices = function()
            return GetPresetChoices(GetListingDetailsPresetSlotsFromDB(GetListingAutoFillDB()))
        end
        descriptionButton.GetCopyText = function(_, choice)
            return GetListingDetailsClipboardText(choice and choice.text or "")
        end
    end

    local presetsEnabled = db and db.listingAutoFillEnabled == true
    local showNameButton = presetsEnabled and nameButton and #nameButton:GetChoices() > 0
    local showDescriptionButton = presetsEnabled and descriptionButton and #descriptionButton:GetChoices() > 0

    if nameButton then
        nameButton:SetShown(showNameButton == true)
    end

    if descriptionButton then
        descriptionButton:SetShown(showDescriptionButton == true)
    end
end

local function VisitFrameTree(frame, callback)
    if not frame or type(callback) ~= "function" then
        return
    end

    callback(frame)

    for _, child in ipairs({ frame:GetChildren() }) do
        VisitFrameTree(child, callback)
    end
end

local function NormalizePlaystyleWidgetCandidate(candidate)
    if not candidate then
        return nil
    end

    local parent = candidate.GetParent and candidate:GetParent() or nil
    local parentName = parent and parent.GetName and parent:GetName() or nil

    if type(parentName) == "string" and string.find(string.lower(parentName), "playstyle", 1, true) then
        return parent
    end

    return candidate
end

local function FindEntryCreationPlaystyleWidget(entryCreation)
    if not entryCreation then
        return nil
    end

    local entryState = GetEntryCreationState(entryCreation)
    local cachedWidget = entryState and entryState.playstyleWidget or nil
    if cachedWidget and cachedWidget.GetObjectType then
        return cachedWidget
    end

    local preferredKeys = {
        "PlaystyleDropdown",
        "PlayStyleDropdown",
        "PlaystyleDropDown",
        "PlayStyleDropDown",
        "Playstyle",
        "PlayStyle",
    }

    for _, key in ipairs(preferredKeys) do
        if entryCreation[key] then
            local directMatch = NormalizePlaystyleWidgetCandidate(entryCreation[key])
            if entryState then
                entryState.playstyleWidget = directMatch
            end
            return directMatch
        end
    end

    for key, value in pairs(entryCreation) do
        if type(key) == "string" and string.find(string.lower(key), "playstyle", 1, true) and type(value) == "table" then
            local namedMatch = NormalizePlaystyleWidgetCandidate(value)
            if entryState then
                entryState.playstyleWidget = namedMatch
            end
            return namedMatch
        end
    end

    local foundWidget = nil
    VisitFrameTree(entryCreation, function(frame)
        if foundWidget then
            return
        end

        local frameName = frame.GetName and frame:GetName() or nil
        if type(frameName) == "string" and string.find(string.lower(frameName), "playstyle", 1, true) then
            foundWidget = NormalizePlaystyleWidgetCandidate(frame)
        end
    end)

    if entryState then
        entryState.playstyleWidget = foundWidget
    end
    return foundWidget
end

local function RefreshPlaystyleWidget(widget)
    if not widget then
        return false
    end

    local changed = false

    changed = MarkChanged(changed, TryCallMethod(widget, "GenerateMenu"))
    changed = MarkChanged(changed, TryCallMethod(widget, "Update"))
    return changed
end

local function SetEntryCreationGeneralPlaystyle(entryCreation, value)
    if not entryCreation then
        return false
    end

    if entryCreation.generalPlaystyle == value then
        local updateValidState = rawget(_G, "LFGListEntryCreation_UpdateValidState")
        SafeCall(updateValidState, entryCreation)
        return false
    end

    local onPlayStyleSelected = rawget(_G, "LFGListEntryCreation_OnPlayStyleSelectedInternal")
    if type(onPlayStyleSelected) ~= "function" then
        return false
    end

    if not SafeCall(onPlayStyleSelected, entryCreation, value) then
        return false
    end

    return entryCreation.generalPlaystyle == value
end

local function ApplyListingPlaystylePreset(entryCreation, db)
    local playstyleValue = math.max(PLAYSTYLE_NONE, math.floor(tonumber(db.listingPlaystylePreset) or PLAYSTYLE_NONE))
    if playstyleValue <= PLAYSTYLE_NONE then
        return false
    end

    local activityInfo = GetEntryCreationActivityInfo(entryCreation)
    if activityInfo and C_LFGList and type(C_LFGList.GetLfgCategoryInfo) == "function" then
        local categoryInfo = C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID)
        if type(categoryInfo) == "table" and categoryInfo.showPlaystyleDropdown ~= true then
            return false
        end
    end

    local changed = false
    local widget = FindEntryCreationPlaystyleWidget(entryCreation)

    changed = MarkChanged(changed, SetEntryCreationGeneralPlaystyle(entryCreation, playstyleValue))

    if widget then
        changed = MarkChanged(changed, RefreshPlaystyleWidget(widget))
    end

    return changed
end

local function ApplyEntryCreationPresets(forceApply)
    local entryCreation = GetEntryCreationFrame()
    if not entryCreation or not entryCreation.IsShown or not entryCreation:IsShown() then
        return
    end

    local db = GetListingAutoFillDB()
    if not db or db.listingAutoFillEnabled ~= true then
        UpdateListingCopyButtons(entryCreation, db)
        return
    end

    MarkSecurityLockedTextInput(entryCreation.Name)
    MarkSecurityLockedTextInput(entryCreation.Description)

    UpdateListingCopyButtons(entryCreation, db)
    ApplyListingPlaystylePreset(entryCreation, db)
    ApplyListingNamePreset(entryCreation, db, forceApply == true)
    ApplyListingDescriptionPreset(entryCreation, db)
end

function LFG.RefreshListingAutoFill(forceApply)
    ScheduledApplySerial = ScheduledApplySerial + 1
    local applySerial = ScheduledApplySerial

    local function RunApply()
        if applySerial ~= ScheduledApplySerial then
            return
        end

        ApplyEntryCreationPresets(forceApply == true)
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, RunApply)
        C_Timer.After(0.1, RunApply)
        C_Timer.After(0.3, RunApply)
    else
        RunApply()
    end
end

local function HookEntryCreationFrame(entryCreation)
    local entryState = GetEntryCreationState(entryCreation)
    if not entryCreation or not entryState or entryState.hooksInstalled then
        return
    end

    entryState.hooksInstalled = true

    if entryCreation.Name then
        TrackUserChanges(entryCreation.Name)
    end

    if entryCreation.Description then
        TrackUserChanges(entryCreation.Description)
    end

    entryCreation:HookScript("OnShow", function(self)
        local nameBox = ResolveTextInputWidget(self.Name)
        if nameBox then
            local nameState = GetEditBoxState(nameBox)
            if nameState then
                nameState.userModified = false
            end
        end

        local descriptionBox = ResolveTextInputWidget(self.Description)
        if descriptionBox then
            local descriptionState = GetEditBoxState(descriptionBox)
            if descriptionState then
                descriptionState.userModified = false
            end
        end

        if LFG.RefreshListingAutoFill then
            LFG.RefreshListingAutoFill()
        end
    end)

    if entryCreation.ListGroupButton then
        entryCreation.ListGroupButton:HookScript("PreClick", function()
            ApplyEntryCreationPresets(true)
        end)
    end
end

local function TryInstallEntryCreationHooks()
    local entryCreation = GetEntryCreationFrame()
    if entryCreation then
        HookEntryCreationFrame(entryCreation)
        EntryCreationHooksInstalled = true
    end

    if not EntryCreationUpdateHookInstalled and type(rawget(_G, "LFGListEntryCreation_Update")) == "function" then
        hooksecurefunc("LFGListEntryCreation_Update", function()
            if LFG.RefreshListingAutoFill then
                LFG.RefreshListingAutoFill()
            end
        end)

        EntryCreationUpdateHookInstalled = true
    end
end

AutoFillHookFrame:RegisterEvent("PLAYER_LOGIN")
AutoFillHookFrame:RegisterEvent("ADDON_LOADED")
AutoFillHookFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "Blizzard_GroupFinder" then
            return
        end
    end

    TryInstallEntryCreationHooks()
    if EntryCreationHooksInstalled and LFG.RefreshListingAutoFill then
        LFG.RefreshListingAutoFill()
    end
end)
