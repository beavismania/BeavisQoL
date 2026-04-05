local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

local COLORS = {
    gold = { 1.00, 0.82, 0.08 },
    emerald = { 0.27, 1.00, 0.43 },
    azure = { 0.18, 0.58, 1.00 },
    violet = { 0.73, 0.34, 1.00 },
    amber = { 1.00, 0.57, 0.12 },
    myth = { 1.00, 0.88, 0.20 },
    soft = { 0.84, 0.84, 0.88 },
    text = { 0.96, 0.96, 0.98 },
    danger = { 1.00, 0.36, 0.36 },
}

local function GetColor(colorKey)
    local color = COLORS[colorKey] or COLORS.text
    return color[1], color[2], color[3]
end

local function GetItemLevelColorKey(itemLevel)
    local numericItemLevel = tonumber(itemLevel) or 0

    if numericItemLevel >= 272 then
        return "myth"
    elseif numericItemLevel >= 259 then
        return "amber"
    elseif numericItemLevel >= 246 then
        return "violet"
    elseif numericItemLevel >= 233 then
        return "azure"
    end

    return "emerald"
end

local UPGRADE_ROWS = {
    { 220 }, { 224 }, { 227 }, { 230 }, { 233 }, { 237 }, { 240 }, { 243 }, { 246 }, { 250 },
    { 253 }, { 256 }, { 259 }, { 263 }, { 266 }, { 269 }, { 272 }, { 276 }, { 279 }, { 282 },
    { 285 }, { 289 },
}

local CRAFTED_ROWS = {
    { "Q1", 220, 233, 246, 259, 272 },
    { "Q2", 224, 237, 250, 263, 276 },
    { "Q3", 227, 240, 253, 266, 279 },
    { "Q4", 230, 243, 256, 269, 282 },
    { "Q5", 233, 246, 259, 272, 285 },
}

local DUNGEON_ROWS = {
    { "heroic", 230, 243 },
    { "mythic", 246, 256 },
    { "M2", 250, 259 },
    { "M3", 250, 259 },
    { "M4", 253, 263 },
    { "M5", 256, 263 },
    { "M6", 259, 266 },
    { "M7", 259, 269 },
    { "M8", 263, 269 },
    { "M9", 263, 269 },
    { "M10", 266, 272 },
}

local RAID_ROWS = {
    { "raid_finder", 233, 237, 240, 243 },
    { "normal", 246, 250, 253, 256 },
    { "heroic", 259, 263, 266, 269 },
    { "mythic", 272, 276, 279, 282 },
}

local DELVE_ROWS = {
    { "T1", 220, "-", 233 },
    { "T2", 224, "-", 237 },
    { "T3", 227, "-", 240 },
    { "T4", 230, 237, 243 },
    { "T5", 233, 243, 246 },
    { "T6", 237, 250, 253 },
    { "T7", 250, 256, 256 },
    { "T8", 250, 259, 259 },
    { "T9", 250, 259, 259 },
    { "T10", 250, 259, 259 },
    { "T11", 250, 259, 259 },
}

local function GetPathName(pathKey)
    return L("ITEM_GUIDE_PATH_" .. pathKey)
end

local function GetUpgradeRows()
    return {
        { 220, string.format("%s 1", GetPathName("ADVENTURER")), GetPathName("ADVENTURER") },
        { 224, string.format("%s 2", GetPathName("ADVENTURER")), GetPathName("ADVENTURER") },
        { 227, string.format("%s 3", GetPathName("ADVENTURER")), GetPathName("ADVENTURER") },
        { 230, string.format("%s 4", GetPathName("ADVENTURER")), GetPathName("ADVENTURER") },
        { 233, string.format("%s 5 / %s 1", GetPathName("ADVENTURER"), GetPathName("VETERAN")), GetPathName("ADVENTURER") },
        { 237, string.format("%s 6 / %s 2", GetPathName("ADVENTURER"), GetPathName("VETERAN")), string.format("%s | %s", GetPathName("ADVENTURER"), L("ITEM_GUIDE_SAVE_VETERAN")) },
        { 240, string.format("%s 3", GetPathName("VETERAN")), GetPathName("VETERAN") },
        { 243, string.format("%s 4", GetPathName("VETERAN")), GetPathName("VETERAN") },
        { 246, string.format("%s 5 / %s 1", GetPathName("VETERAN"), GetPathName("CHAMPION")), GetPathName("VETERAN") },
        { 250, string.format("%s 6 / %s 2", GetPathName("VETERAN"), GetPathName("CHAMPION")), string.format("%s | %s", GetPathName("VETERAN"), L("ITEM_GUIDE_SAVE_CHAMPION")) },
        { 253, string.format("%s 3", GetPathName("CHAMPION")), GetPathName("CHAMPION") },
        { 256, string.format("%s 4", GetPathName("CHAMPION")), GetPathName("CHAMPION") },
        { 259, string.format("%s 5 / %s 1", GetPathName("CHAMPION"), GetPathName("HERO")), GetPathName("CHAMPION") },
        { 263, string.format("%s 6 / %s 2", GetPathName("CHAMPION"), GetPathName("HERO")), string.format("%s | %s", GetPathName("CHAMPION"), L("ITEM_GUIDE_SAVE_HERO")) },
        { 266, string.format("%s 3", GetPathName("HERO")), GetPathName("HERO") },
        { 269, string.format("%s 4", GetPathName("HERO")), GetPathName("HERO") },
        { 272, string.format("%s 5 / %s 1", GetPathName("HERO"), GetPathName("MYTH")), GetPathName("HERO") },
        { 276, string.format("%s 6 / %s 2", GetPathName("HERO"), GetPathName("MYTH")), string.format("%s | %s", GetPathName("HERO"), L("ITEM_GUIDE_SAVE_MYTH")) },
        { 279, string.format("%s 3", GetPathName("MYTH")), GetPathName("MYTH") },
        { 282, string.format("%s 4", GetPathName("MYTH")), GetPathName("MYTH") },
        { 285, string.format("%s 5", GetPathName("MYTH")), GetPathName("MYTH") },
        { 289, string.format("%s 6", GetPathName("MYTH")), GetPathName("MYTH") },
    }
end

local function GetDungeonLabel(labelKey)
    if labelKey == "heroic" then
        return L("ITEM_GUIDE_LABEL_HEROIC")
    elseif labelKey == "mythic" then
        return L("ITEM_GUIDE_LABEL_MYTHIC")
    end

    return labelKey
end

local function GetRaidLabel(labelKey)
    if labelKey == "raid_finder" then
        return L("ITEM_GUIDE_LABEL_RAID_FINDER")
    elseif labelKey == "normal" then
        return L("ITEM_GUIDE_LABEL_NORMAL")
    elseif labelKey == "heroic" then
        return L("ITEM_GUIDE_LABEL_HEROIC")
    elseif labelKey == "mythic" then
        return L("ITEM_GUIDE_LABEL_MYTHIC")
    end

    return labelKey
end

local function SetTableHeaders(tableFrame, titles)
    for index, title in ipairs(titles) do
        tableFrame.Columns[index].title = title
        tableFrame.Headers[index]:SetText(title)
    end
end

local LayoutPage

local PageItemLevelGuide = CreateFrame("Frame", nil, Content)
PageItemLevelGuide:SetAllPoints()
PageItemLevelGuide:Hide()

local PageScrollFrame = CreateFrame("ScrollFrame", nil, PageItemLevelGuide, "UIPanelScrollFrameTemplate")
PageScrollFrame:SetPoint("TOPLEFT", PageItemLevelGuide, "TOPLEFT", 0, 0)
PageScrollFrame:SetPoint("BOTTOMRIGHT", PageItemLevelGuide, "BOTTOMRIGHT", -28, 0)
PageScrollFrame:EnableMouseWheel(true)

local PageContent = CreateFrame("Frame", nil, PageScrollFrame)
PageContent:SetSize(1, 1)
PageScrollFrame:SetScrollChild(PageContent)

local function CreatePanelSurface(frame, accentKey, isHero)
    local r, g, b = GetColor(accentKey)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.08, 0.09, isHero and 0.98 or 0.94)

    local topGlow = frame:CreateTexture(nil, "BORDER")
    topGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topGlow:SetHeight(isHero and 34 or 26)
    topGlow:SetColorTexture(r, g, b, isHero and 0.12 or 0.08)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    accent:SetHeight(2)
    accent:SetColorTexture(r, g, b, 0.95)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(r, g, b, 0.55)

    local sideAccent = frame:CreateTexture(nil, "ARTWORK")
    sideAccent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -14)
    sideAccent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 14)
    sideAccent:SetWidth(3)
    sideAccent:SetColorTexture(r, g, b, 0.72)
end

local function CreateCard(parent, accentKey, eyebrowText, titleText, subtitleText)
    local frame = CreateFrame("Frame", nil, parent)
    frame.HeaderInset = subtitleText and subtitleText ~= "" and 54 or 42
    frame.BottomInset = 12

    CreatePanelSurface(frame, accentKey, false)

    local eyebrow = frame:CreateFontString(nil, "OVERLAY")
    eyebrow:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    eyebrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    eyebrow:SetTextColor(GetColor(accentKey))
    eyebrow:SetText(eyebrowText)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -3)
    title:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    title:SetTextColor(1, 1, 1, 1)
    title:SetText(titleText)

    if subtitleText and subtitleText ~= "" then
        local subtitle = frame:CreateFontString(nil, "OVERLAY")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        subtitle:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
        subtitle:SetJustifyH("LEFT")
        subtitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        subtitle:SetTextColor(0.8, 0.8, 0.84, 1)
        subtitle:SetText(subtitleText)
        frame.Subtitle = subtitle
    end

    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -frame.HeaderInset)
    body:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -frame.HeaderInset)
    body:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, frame.BottomInset)
    body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, frame.BottomInset)
    frame.Body = body
    frame.Eyebrow = eyebrow
    frame.Title = title

    return frame
end

local function SetCardFootnote(card, text, colorKey)
    local note = card:CreateFontString(nil, "OVERLAY")
    note:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, 9)
    note:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    note:SetJustifyH("LEFT")
    note:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    note:SetTextColor(GetColor(colorKey or "soft"))
    note:SetText(text)

    card.Note = note

    card.BottomInset = 20
    card.Body:ClearAllPoints()
    card.Body:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -card.HeaderInset)
    card.Body:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -card.HeaderInset)
    card.Body:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, card.BottomInset)
    card.Body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -16, card.BottomInset)
end

local function CreateTable(parent, columns, rows, options)
    local frame = CreateFrame("Frame", nil, parent)
    frame.Columns = columns
    frame.RowsData = rows
    frame.RowHeight = options and options.rowHeight or 24
    frame.HeaderHeight = options and options.headerHeight or 28
    frame.CellFontSize = options and options.cellFontSize or 12
    frame.HeaderFontSize = options and options.headerFontSize or 12
    frame.CellPaddingX = options and options.cellPaddingX or 6
    frame.HeaderPaddingX = options and options.headerPaddingX or 6
    frame.HeaderTextOffsetY = options and options.headerTextOffsetY or 6
    frame.AllowHeaderWrap = options and options.allowHeaderWrap ~= false or false
    frame.AllowHeaderWordBreak = options and options.allowHeaderWordBreak or false
    frame.RequiredHeight = frame.HeaderHeight + (#rows * frame.RowHeight) + 4

    local headerBg = frame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    headerBg:SetHeight(frame.HeaderHeight)
    headerBg:SetColorTexture(1, 1, 1, 0.04)

    local headerBorder = frame:CreateTexture(nil, "ARTWORK")
    headerBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -frame.HeaderHeight)
    headerBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -frame.HeaderHeight)
    headerBorder:SetHeight(1)
    headerBorder:SetColorTexture(1, 1, 1, 0.08)

    frame.Headers = {}
    for index, column in ipairs(columns) do
        local header = frame:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\FRIZQT__.TTF", frame.HeaderFontSize, "OUTLINE")
        header:SetTextColor(0.84, 0.84, 0.88, 1)
        header:SetJustifyV("MIDDLE")
        if header.SetWordWrap then
            header:SetWordWrap(frame.AllowHeaderWrap)
        end
        if header.SetNonSpaceWrap then
            header:SetNonSpaceWrap(frame.AllowHeaderWordBreak)
        end
        header:SetText(column.title)
        frame.Headers[index] = header
    end

    frame.Rows = {}
    for rowIndex, rowData in ipairs(rows) do
        local rowFrame = CreateFrame("Frame", nil, frame)
        rowFrame:SetHeight(frame.RowHeight)

        local rowBg = rowFrame:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(1, 1, 1, rowIndex % 2 == 0 and 0.03 or 0.01)

        local rowBorder = rowFrame:CreateTexture(nil, "ARTWORK")
        rowBorder:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 0, 0)
        rowBorder:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
        rowBorder:SetHeight(1)
        rowBorder:SetColorTexture(1, 1, 1, 0.03)

        rowFrame.Cells = {}
        for columnIndex = 1, #columns do
            local cellText = rowFrame:CreateFontString(nil, "OVERLAY")
            cellText:SetFont("Fonts\\FRIZQT__.TTF", frame.CellFontSize, "")
            cellText:SetTextColor(0.96, 0.96, 0.98, 1)
            rowFrame.Cells[columnIndex] = cellText
        end

        frame.Rows[rowIndex] = rowFrame
    end

    function frame:UpdateLayout()
        local width = math.max(1, self:GetWidth())
        local columnBounds = {}
        local cursorX = 0

        for columnIndex, column in ipairs(self.Columns) do
            local columnWidth = columnIndex == #self.Columns and (width - cursorX) or math.floor(width * column.width)
            columnBounds[columnIndex] = {
                left = cursorX,
                width = columnWidth,
                justify = column.justify or "LEFT",
            }
            cursorX = cursorX + columnWidth
        end

        for columnIndex, header in ipairs(self.Headers) do
            local bounds = columnBounds[columnIndex]
            header:ClearAllPoints()
            header:SetWidth(math.max(1, bounds.width - (self.HeaderPaddingX * 2)))
            header:SetJustifyH(bounds.justify)
            header:SetPoint(
                "TOPLEFT",
                self,
                "TOPLEFT",
                bounds.left + self.HeaderPaddingX,
                -math.max(2, math.floor((self.HeaderHeight - header:GetStringHeight()) / 2))
            )
        end

        for rowIndex, rowFrame in ipairs(self.Rows) do
            rowFrame:ClearAllPoints()
            rowFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(self.HeaderHeight + ((rowIndex - 1) * self.RowHeight)))
            rowFrame:SetWidth(width)

            for columnIndex, cell in ipairs(rowFrame.Cells) do
                local bounds = columnBounds[columnIndex]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", rowFrame, "LEFT", bounds.left + self.CellPaddingX, 0)
                cell:SetWidth(math.max(1, bounds.width - (self.CellPaddingX * 2)))
                cell:SetJustifyH(bounds.justify)
            end
        end

        self:SetHeight(self.RequiredHeight)
    end

    frame:SetHeight(frame.RequiredHeight)
    return frame
end

local function SetPlainCell(cell, value, colorKey)
    cell:SetText(tostring(value or ""))
    cell:SetTextColor(GetColor(colorKey or "text"))
end

local function SetItemLevelCell(cell, value)
    if type(value) == "number" then
        cell:SetText(tostring(value))
        cell:SetTextColor(GetColor(GetItemLevelColorKey(value)))
        return
    end

    cell:SetText(tostring(value or ""))
    cell:SetTextColor(GetColor("soft"))
end

local function FillUpgradeTable(tableFrame)
    local rows = GetUpgradeRows()

    for rowIndex, rowData in ipairs(rows) do
        local rowFrame = tableFrame.Rows[rowIndex]
        SetItemLevelCell(rowFrame.Cells[1], rowData[1])
        SetPlainCell(rowFrame.Cells[2], rowData[2], GetItemLevelColorKey(rowData[1]))

        if string.find(rowData[3], "sparen", 1, true) then
            SetPlainCell(rowFrame.Cells[3], rowData[3], "danger")
        else
            SetPlainCell(rowFrame.Cells[3], rowData[3], GetItemLevelColorKey(rowData[1]))
        end
    end
end

local function FillCraftedTable(tableFrame)
    for rowIndex, rowData in ipairs(CRAFTED_ROWS) do
        local rowFrame = tableFrame.Rows[rowIndex]
        SetPlainCell(rowFrame.Cells[1], rowData[1], "soft")
        for columnIndex = 2, 6 do
            SetItemLevelCell(rowFrame.Cells[columnIndex], rowData[columnIndex])
        end
    end
end

local function FillDungeonTable(tableFrame)
    for rowIndex, rowData in ipairs(DUNGEON_ROWS) do
        local rowFrame = tableFrame.Rows[rowIndex]
        SetPlainCell(rowFrame.Cells[1], GetDungeonLabel(rowData[1]), "text")
        SetItemLevelCell(rowFrame.Cells[2], rowData[2])
        SetItemLevelCell(rowFrame.Cells[3], rowData[3])
    end
end

local function FillRaidTable(tableFrame)
    for rowIndex, rowData in ipairs(RAID_ROWS) do
        local rowFrame = tableFrame.Rows[rowIndex]
        SetPlainCell(rowFrame.Cells[1], GetRaidLabel(rowData[1]), "text")
        for columnIndex = 2, 5 do
            SetItemLevelCell(rowFrame.Cells[columnIndex], rowData[columnIndex])
        end
    end
end

local function FillDelveTable(tableFrame)
    for rowIndex, rowData in ipairs(DELVE_ROWS) do
        local rowFrame = tableFrame.Rows[rowIndex]
        SetPlainCell(rowFrame.Cells[1], rowData[1], "text")
        SetItemLevelCell(rowFrame.Cells[2], rowData[2])
        SetItemLevelCell(rowFrame.Cells[3], rowData[3])
        SetItemLevelCell(rowFrame.Cells[4], rowData[4])
    end
end

local HeroPanel = CreateFrame("Frame", nil, PageContent)
CreatePanelSurface(HeroPanel, "gold", true)

local HeroEyebrow = HeroPanel:CreateFontString(nil, "OVERLAY")
HeroEyebrow:SetPoint("TOPLEFT", HeroPanel, "TOPLEFT", 22, -16)
HeroEyebrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
HeroEyebrow:SetTextColor(GetColor("gold"))
HeroEyebrow:SetText(L("ITEM_GUIDE_EYEBROW"))

local HeroTitle = HeroPanel:CreateFontString(nil, "OVERLAY")
HeroTitle:SetPoint("TOPLEFT", HeroEyebrow, "BOTTOMLEFT", 0, -6)
HeroTitle:SetPoint("RIGHT", HeroPanel, "RIGHT", -16, 0)
HeroTitle:SetJustifyH("LEFT")
HeroTitle:SetJustifyV("TOP")
HeroTitle:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
HeroTitle:SetTextColor(1, 1, 1, 1)
HeroTitle:SetText(L("ITEM_GUIDE_TITLE"))

local HeroSubtitle = HeroPanel:CreateFontString(nil, "OVERLAY")
HeroSubtitle:SetPoint("TOPLEFT", HeroTitle, "BOTTOMLEFT", 0, -10)
HeroSubtitle:SetPoint("RIGHT", HeroPanel, "RIGHT", -16, 0)
HeroSubtitle:SetJustifyH("LEFT")
HeroSubtitle:SetJustifyV("TOP")
HeroSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
HeroSubtitle:SetTextColor(0.85, 0.85, 0.88, 1)
HeroSubtitle:SetText(L("ITEM_GUIDE_SUBTITLE"))

local HeroDescription = HeroPanel:CreateFontString(nil, "OVERLAY")
HeroDescription:SetPoint("TOPLEFT", HeroSubtitle, "BOTTOMLEFT", 0, -9)
HeroDescription:SetPoint("RIGHT", HeroPanel, "RIGHT", -16, 0)
HeroDescription:SetJustifyH("LEFT")
HeroDescription:SetJustifyV("TOP")
HeroDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
HeroDescription:SetTextColor(0.93, 0.93, 0.95, 1)
HeroDescription:SetText(L("ITEM_GUIDE_DESC"))
HeroDescription:Hide()

local SeasonBadge = CreateFrame("Frame", nil, HeroPanel)
SeasonBadge:SetSize(154, 58)

local SeasonBadgeBg = SeasonBadge:CreateTexture(nil, "BACKGROUND")
SeasonBadgeBg:SetAllPoints()
SeasonBadgeBg:SetColorTexture(1, 0.82, 0.08, 0.08)

local SeasonBadgeAccent = SeasonBadge:CreateTexture(nil, "ARTWORK")
SeasonBadgeAccent:SetPoint("TOPLEFT", SeasonBadge, "TOPLEFT", 0, 0)
SeasonBadgeAccent:SetPoint("BOTTOMLEFT", SeasonBadge, "BOTTOMLEFT", 0, 0)
SeasonBadgeAccent:SetWidth(3)
SeasonBadgeAccent:SetColorTexture(1, 0.82, 0.08, 0.88)

local SeasonBadgeLabel = SeasonBadge:CreateFontString(nil, "OVERLAY")
SeasonBadgeLabel:SetPoint("TOPLEFT", SeasonBadge, "TOPLEFT", 14, -12)
SeasonBadgeLabel:SetPoint("RIGHT", SeasonBadge, "RIGHT", -12, 0)
SeasonBadgeLabel:SetJustifyH("LEFT")
SeasonBadgeLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
SeasonBadgeLabel:SetTextColor(1, 0.88, 0.38, 1)
SeasonBadgeLabel:SetText(L("SEASON_REFERENCE"))

local SeasonBadgeTitle = SeasonBadge:CreateFontString(nil, "OVERLAY")
SeasonBadgeTitle:SetPoint("TOPLEFT", SeasonBadgeLabel, "BOTTOMLEFT", 0, -4)
SeasonBadgeTitle:SetPoint("RIGHT", SeasonBadge, "RIGHT", -12, 0)
SeasonBadgeTitle:SetJustifyH("LEFT")
SeasonBadgeTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
SeasonBadgeTitle:SetTextColor(1, 1, 1, 1)
SeasonBadgeTitle:SetText(L("SEASON_NAME_MIDNIGHT"))

local SeasonBadgeText = SeasonBadge:CreateFontString(nil, "OVERLAY")
SeasonBadgeText:SetPoint("TOPLEFT", SeasonBadgeTitle, "BOTTOMLEFT", 0, -6)
SeasonBadgeText:SetPoint("RIGHT", SeasonBadge, "RIGHT", -12, 0)
SeasonBadgeText:SetJustifyH("LEFT")
SeasonBadgeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
SeasonBadgeText:SetTextColor(0.9, 0.9, 0.92, 1)
SeasonBadgeText:SetText(L("ITEM_GUIDE_BADGE_TEXT"))
SeasonBadge:Hide()

local LegendLine = HeroPanel:CreateFontString(nil, "OVERLAY")
LegendLine:SetPoint("TOPLEFT", HeroSubtitle, "BOTTOMLEFT", 0, -14)
LegendLine:SetPoint("RIGHT", HeroPanel, "RIGHT", -16, 0)
LegendLine:SetJustifyH("LEFT")
LegendLine:SetJustifyV("TOP")
LegendLine:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
LegendLine:SetTextColor(1, 1, 1, 1)
LegendLine:SetText(L("ITEM_GUIDE_LEGEND"))

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    return math.max(minimumHeight or 0, math.ceil(textHeight))
end

local function UpdateHeroHeight(minimumHeight)
    local heroHeight = 16
        + GetTextHeight(HeroEyebrow, 10)
        + 6
        + GetTextHeight(HeroTitle, 22)
        + 10
        + GetTextHeight(HeroSubtitle, 11)
        + 14
        + GetTextHeight(LegendLine, 10)
        + 16

    HeroPanel:SetHeight(math.max(minimumHeight or 0, heroHeight))
end

local UpgradeCard = CreateCard(PageContent, "emerald", L("ITEM_GUIDE_UPGRADE_CARD_TITLE"), L("ITEM_GUIDE_UPGRADE_CARD_SUBTITLE"), L("ITEM_GUIDE_UPGRADE_CARD_NOTE"))
local CraftedCard = CreateCard(PageContent, "violet", L("ITEM_GUIDE_CRAFTED_CARD_TITLE"), L("ITEM_GUIDE_CRAFTED_CARD_SUBTITLE"), L("ITEM_GUIDE_CRAFTED_CARD_NOTE"))
local DungeonCard = CreateCard(PageContent, "azure", L("ITEM_GUIDE_DUNGEON_CARD_TITLE"), L("ITEM_GUIDE_DUNGEON_CARD_SUBTITLE"), L("ITEM_GUIDE_DUNGEON_CARD_NOTE"))
local RaidCard = CreateCard(PageContent, "amber", L("ITEM_GUIDE_RAID_CARD_TITLE"), L("ITEM_GUIDE_RAID_CARD_SUBTITLE"), L("ITEM_GUIDE_RAID_CARD_NOTE"))
local DelveCard = CreateCard(PageContent, "gold", L("ITEM_GUIDE_DELVE_CARD_TITLE"), L("ITEM_GUIDE_DELVE_CARD_SUBTITLE"), L("ITEM_GUIDE_DELVE_CARD_NOTE"))

local UpgradeTable = CreateTable(
    UpgradeCard.Body,
    {
        { title = "ilvl", width = 0.12, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_PATH_RANK"), width = 0.42, justify = "LEFT" },
        { title = L("ITEM_GUIDE_HEADER_CRESTS"), width = 0.46, justify = "LEFT" },
    },
    UPGRADE_ROWS,
    { rowHeight = 18, headerHeight = 22, cellFontSize = 10, headerFontSize = 10, cellPaddingX = 5, headerPaddingX = 5 }
)
UpgradeTable:SetAllPoints()
SetCardFootnote(UpgradeCard, L("ITEM_GUIDE_UPGRADE_FOOTNOTE"), "danger")
FillUpgradeTable(UpgradeTable)

local CraftedTable = CreateTable(
    CraftedCard.Body,
    {
        { title = L("ITEM_GUIDE_HEADER_QUALITY"), width = 0.15, justify = "CENTER" },
        { title = L("ITEM_GUIDE_PATH_ADVENTURER"), width = 0.21, justify = "CENTER" },
        { title = L("ITEM_GUIDE_PATH_VETERAN"), width = 0.15, justify = "CENTER" },
        { title = L("ITEM_GUIDE_PATH_CHAMPION"), width = 0.20, justify = "CENTER" },
        { title = L("ITEM_GUIDE_PATH_HERO"), width = 0.11, justify = "CENTER" },
        { title = L("ITEM_GUIDE_PATH_MYTH"), width = 0.18, justify = "CENTER" },
    },
    CRAFTED_ROWS,
    { rowHeight = 20, headerHeight = 36, cellFontSize = 10, headerFontSize = 8, cellPaddingX = 4, headerPaddingX = 4, allowHeaderWrap = true, allowHeaderWordBreak = true }
)
CraftedTable:SetAllPoints()
FillCraftedTable(CraftedTable)

local DungeonTable = CreateTable(
    DungeonCard.Body,
    {
        { title = L("ITEM_GUIDE_HEADER_SOURCE"), width = 0.24, justify = "LEFT" },
        { title = L("ITEM_GUIDE_HEADER_END_REWARD"), width = 0.28, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_GREAT_VAULT"), width = 0.48, justify = "CENTER" },
    },
    DUNGEON_ROWS,
    { rowHeight = 19, headerHeight = 32, cellFontSize = 10, headerFontSize = 9, cellPaddingX = 5, headerPaddingX = 5, allowHeaderWrap = true }
)
DungeonTable:SetAllPoints()
FillDungeonTable(DungeonTable)

local RaidTable = CreateTable(
    RaidCard.Body,
    {
        { title = L("ITEM_GUIDE_HEADER_DIFFICULTY"), width = 0.44, justify = "LEFT" },
        { title = L("ITEM_GUIDE_HEADER_EARLY"), width = 0.14, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_MID"), width = 0.14, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_LATE"), width = 0.14, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_END"), width = 0.14, justify = "CENTER" },
    },
    RAID_ROWS,
    { rowHeight = 21, headerHeight = 28, cellFontSize = 10, headerFontSize = 9, cellPaddingX = 4, headerPaddingX = 4, allowHeaderWrap = true }
)
RaidTable:SetAllPoints()
SetCardFootnote(RaidCard, L("ITEM_GUIDE_RAID_FOOTNOTE"), "soft")
FillRaidTable(RaidTable)

local DelveTable = CreateTable(
    DelveCard.Body,
    {
        { title = L("ITEM_GUIDE_HEADER_LEVEL"), width = 0.14, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_END_REWARD"), width = 0.22, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_MAP_DROP"), width = 0.20, justify = "CENTER" },
        { title = L("ITEM_GUIDE_HEADER_GREAT_VAULT"), width = 0.44, justify = "CENTER" },
    },
    DELVE_ROWS,
    { rowHeight = 19, headerHeight = 34, cellFontSize = 10, headerFontSize = 9, cellPaddingX = 5, headerPaddingX = 5, allowHeaderWrap = true }
)
DelveTable:SetAllPoints()
FillDelveTable(DelveTable)

local FooterPanel = CreateFrame("Frame", nil, PageContent)
CreatePanelSurface(FooterPanel, "gold", false)
FooterPanel:Hide()

local FooterText = FooterPanel:CreateFontString(nil, "OVERLAY")
FooterText:SetPoint("LEFT", FooterPanel, "LEFT", 18, 0)
FooterText:SetPoint("RIGHT", FooterPanel, "RIGHT", -18, 0)
FooterText:SetJustifyH("LEFT")
FooterText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
FooterText:SetTextColor(0.9, 0.9, 0.92, 1)
FooterText:SetText(L("ITEM_GUIDE_FOOTER"))

BeavisQoL.UpdateItemLevelGuide = function()
    HeroEyebrow:SetText(L("ITEM_GUIDE_EYEBROW"))
    HeroTitle:SetText(L("ITEM_GUIDE_TITLE"))
    HeroSubtitle:SetText(L("ITEM_GUIDE_SUBTITLE"))
    HeroDescription:SetText(L("ITEM_GUIDE_DESC"))
    SeasonBadgeLabel:SetText(L("SEASON_REFERENCE"))
    SeasonBadgeTitle:SetText(L("SEASON_NAME_MIDNIGHT"))
    SeasonBadgeText:SetText(L("ITEM_GUIDE_BADGE_TEXT"))
    LegendLine:SetText(L("ITEM_GUIDE_LEGEND"))
    UpgradeCard.Eyebrow:SetText(L("ITEM_GUIDE_UPGRADE_CARD_TITLE"))
    UpgradeCard.Title:SetText(L("ITEM_GUIDE_UPGRADE_CARD_SUBTITLE"))
    if UpgradeCard.Subtitle then
        UpgradeCard.Subtitle:SetText(L("ITEM_GUIDE_UPGRADE_CARD_NOTE"))
    end
    CraftedCard.Eyebrow:SetText(L("ITEM_GUIDE_CRAFTED_CARD_TITLE"))
    CraftedCard.Title:SetText(L("ITEM_GUIDE_CRAFTED_CARD_SUBTITLE"))
    if CraftedCard.Subtitle then
        CraftedCard.Subtitle:SetText(L("ITEM_GUIDE_CRAFTED_CARD_NOTE"))
    end
    DungeonCard.Eyebrow:SetText(L("ITEM_GUIDE_DUNGEON_CARD_TITLE"))
    DungeonCard.Title:SetText(L("ITEM_GUIDE_DUNGEON_CARD_SUBTITLE"))
    if DungeonCard.Subtitle then
        DungeonCard.Subtitle:SetText(L("ITEM_GUIDE_DUNGEON_CARD_NOTE"))
    end
    RaidCard.Eyebrow:SetText(L("ITEM_GUIDE_RAID_CARD_TITLE"))
    RaidCard.Title:SetText(L("ITEM_GUIDE_RAID_CARD_SUBTITLE"))
    if RaidCard.Subtitle then
        RaidCard.Subtitle:SetText(L("ITEM_GUIDE_RAID_CARD_NOTE"))
    end
    DelveCard.Eyebrow:SetText(L("ITEM_GUIDE_DELVE_CARD_TITLE"))
    DelveCard.Title:SetText(L("ITEM_GUIDE_DELVE_CARD_SUBTITLE"))
    if DelveCard.Subtitle then
        DelveCard.Subtitle:SetText(L("ITEM_GUIDE_DELVE_CARD_NOTE"))
    end
    if UpgradeCard.Note then
        UpgradeCard.Note:SetText(L("ITEM_GUIDE_UPGRADE_FOOTNOTE"))
    end
    if RaidCard.Note then
        RaidCard.Note:SetText(L("ITEM_GUIDE_RAID_FOOTNOTE"))
    end
    SetTableHeaders(UpgradeTable, { "ilvl", L("ITEM_GUIDE_HEADER_PATH_RANK"), L("ITEM_GUIDE_HEADER_CRESTS") })
    SetTableHeaders(CraftedTable, {
        L("ITEM_GUIDE_HEADER_QUALITY"),
        L("ITEM_GUIDE_PATH_ADVENTURER"),
        L("ITEM_GUIDE_PATH_VETERAN"),
        L("ITEM_GUIDE_PATH_CHAMPION"),
        L("ITEM_GUIDE_PATH_HERO"),
        L("ITEM_GUIDE_PATH_MYTH"),
    })
    SetTableHeaders(DungeonTable, {
        L("ITEM_GUIDE_HEADER_SOURCE"),
        L("ITEM_GUIDE_HEADER_END_REWARD"),
        L("ITEM_GUIDE_HEADER_GREAT_VAULT"),
    })
    SetTableHeaders(RaidTable, {
        L("ITEM_GUIDE_HEADER_DIFFICULTY"),
        L("ITEM_GUIDE_HEADER_EARLY"),
        L("ITEM_GUIDE_HEADER_MID"),
        L("ITEM_GUIDE_HEADER_LATE"),
        L("ITEM_GUIDE_HEADER_END"),
    })
    SetTableHeaders(DelveTable, {
        L("ITEM_GUIDE_HEADER_LEVEL"),
        L("ITEM_GUIDE_HEADER_END_REWARD"),
        L("ITEM_GUIDE_HEADER_MAP_DROP"),
        L("ITEM_GUIDE_HEADER_GREAT_VAULT"),
    })
    FillUpgradeTable(UpgradeTable)
    FillCraftedTable(CraftedTable)
    FillDungeonTable(DungeonTable)
    FillRaidTable(RaidTable)
    FillDelveTable(DelveTable)
    FooterText:SetText(L("ITEM_GUIDE_FOOTER"))
    LayoutPage()
end

local function ApplyCardHeight(card, tableFrame)
    card.RequiredHeight = card.HeaderInset + tableFrame.RequiredHeight + card.BottomInset + 2
    card:SetHeight(card.RequiredHeight)
end

ApplyCardHeight(UpgradeCard, UpgradeTable)
ApplyCardHeight(CraftedCard, CraftedTable)
ApplyCardHeight(DungeonCard, DungeonTable)
ApplyCardHeight(RaidCard, RaidTable)
ApplyCardHeight(DelveCard, DelveTable)

local function UpdateTables()
    UpgradeTable:UpdateLayout()
    CraftedTable:UpdateLayout()
    DungeonTable:UpdateLayout()
    RaidTable:UpdateLayout()
    DelveTable:UpdateLayout()
end

local function ResetCardHeights()
    UpgradeCard:SetHeight(UpgradeCard.RequiredHeight)
    CraftedCard:SetHeight(CraftedCard.RequiredHeight)
    DungeonCard:SetHeight(DungeonCard.RequiredHeight)
    RaidCard:SetHeight(RaidCard.RequiredHeight)
    DelveCard:SetHeight(DelveCard.RequiredHeight)
end

local function LayoutWide(contentWidth)
    local outerGap = 16
    local columnGap = 12
    local rowGap = 12
    local topY = -12
    local workingWidth = contentWidth - (outerGap * 2)
    local leftWidth = math.floor(workingWidth * 0.34)
    local rightWidth = workingWidth - leftWidth - columnGap
    local middleWidth = math.floor((rightWidth - columnGap) * 0.53)
    local rightColumnWidth = rightWidth - middleWidth - columnGap

    ResetCardHeights()

    local tallestColumnHeight = math.max(
        UpgradeCard.RequiredHeight,
        CraftedCard.RequiredHeight + rowGap + DungeonCard.RequiredHeight,
        RaidCard.RequiredHeight + rowGap + DelveCard.RequiredHeight
    )

    UpgradeCard:SetHeight(tallestColumnHeight)
    DungeonCard:SetHeight(math.max(DungeonCard.RequiredHeight, tallestColumnHeight - CraftedCard.RequiredHeight - rowGap))
    DelveCard:SetHeight(math.max(DelveCard.RequiredHeight, tallestColumnHeight - RaidCard.RequiredHeight - rowGap))

    HeroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", outerGap, topY)
    HeroPanel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -outerGap, topY)
    UpdateHeroHeight(104)

    UpgradeCard:ClearAllPoints()
    UpgradeCard:SetPoint("TOPLEFT", HeroPanel, "BOTTOMLEFT", 0, -12)
    UpgradeCard:SetWidth(leftWidth)

    CraftedCard:ClearAllPoints()
    CraftedCard:SetPoint("TOPLEFT", UpgradeCard, "TOPRIGHT", columnGap, 0)
    CraftedCard:SetWidth(middleWidth)

    RaidCard:ClearAllPoints()
    RaidCard:SetPoint("TOPLEFT", CraftedCard, "TOPRIGHT", columnGap, 0)
    RaidCard:SetWidth(rightColumnWidth)

    DungeonCard:ClearAllPoints()
    DungeonCard:SetPoint("TOPLEFT", CraftedCard, "BOTTOMLEFT", 0, -rowGap)
    DungeonCard:SetWidth(middleWidth)

    DelveCard:ClearAllPoints()
    DelveCard:SetPoint("TOPLEFT", RaidCard, "BOTTOMLEFT", 0, -rowGap)
    DelveCard:SetWidth(rightColumnWidth)

    PageContent:SetHeight(HeroPanel:GetHeight() + tallestColumnHeight + 40)
end

local function LayoutMedium(contentWidth)
    local outerGap = 16
    local columnGap = 12
    local rowGap = 12
    local topY = -12
    local workingWidth = contentWidth - (outerGap * 2)
    local leftWidth = math.floor((workingWidth - columnGap) * 0.50)
    local rightWidth = workingWidth - leftWidth - columnGap

    ResetCardHeights()

    local stackHeight = math.max(
        CraftedCard.RequiredHeight + rowGap + DungeonCard.RequiredHeight,
        RaidCard.RequiredHeight + rowGap + DelveCard.RequiredHeight
    )

    DungeonCard:SetHeight(math.max(DungeonCard.RequiredHeight, stackHeight - CraftedCard.RequiredHeight - rowGap))
    DelveCard:SetHeight(math.max(DelveCard.RequiredHeight, stackHeight - RaidCard.RequiredHeight - rowGap))

    HeroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", outerGap, topY)
    HeroPanel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -outerGap, topY)
    UpdateHeroHeight(108)

    UpgradeCard:ClearAllPoints()
    UpgradeCard:SetPoint("TOPLEFT", HeroPanel, "BOTTOMLEFT", 0, -12)
    UpgradeCard:SetPoint("TOPRIGHT", HeroPanel, "BOTTOMRIGHT", 0, -12)

    CraftedCard:ClearAllPoints()
    CraftedCard:SetPoint("TOPLEFT", UpgradeCard, "BOTTOMLEFT", 0, -12)
    CraftedCard:SetWidth(leftWidth)

    RaidCard:ClearAllPoints()
    RaidCard:SetPoint("TOPLEFT", CraftedCard, "TOPRIGHT", columnGap, 0)
    RaidCard:SetWidth(rightWidth)

    DungeonCard:ClearAllPoints()
    DungeonCard:SetPoint("TOPLEFT", CraftedCard, "BOTTOMLEFT", 0, -rowGap)
    DungeonCard:SetWidth(leftWidth)

    DelveCard:ClearAllPoints()
    DelveCard:SetPoint("TOPLEFT", RaidCard, "BOTTOMLEFT", 0, -rowGap)
    DelveCard:SetWidth(rightWidth)

    PageContent:SetHeight(
        HeroPanel:GetHeight()
            + UpgradeCard:GetHeight()
            + stackHeight
            + 48
    )
end

local function LayoutNarrow(contentWidth)
    local outerGap = 16
    local gap = 12
    local topY = -12
    local workingWidth = contentWidth - (outerGap * 2)

    ResetCardHeights()

    HeroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", outerGap, topY)
    HeroPanel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -outerGap, topY)
    UpdateHeroHeight(116)

    UpgradeCard:ClearAllPoints()
    UpgradeCard:SetPoint("TOPLEFT", HeroPanel, "BOTTOMLEFT", 0, -gap)
    UpgradeCard:SetWidth(workingWidth)

    CraftedCard:ClearAllPoints()
    CraftedCard:SetPoint("TOPLEFT", UpgradeCard, "BOTTOMLEFT", 0, -gap)
    CraftedCard:SetWidth(workingWidth)

    DungeonCard:ClearAllPoints()
    DungeonCard:SetPoint("TOPLEFT", CraftedCard, "BOTTOMLEFT", 0, -gap)
    DungeonCard:SetWidth(workingWidth)

    RaidCard:ClearAllPoints()
    RaidCard:SetPoint("TOPLEFT", DungeonCard, "BOTTOMLEFT", 0, -gap)
    RaidCard:SetWidth(workingWidth)

    DelveCard:ClearAllPoints()
    DelveCard:SetPoint("TOPLEFT", RaidCard, "BOTTOMLEFT", 0, -gap)
    DelveCard:SetWidth(workingWidth)

    PageContent:SetHeight(
        HeroPanel:GetHeight()
            + UpgradeCard:GetHeight()
            + CraftedCard:GetHeight()
            + DungeonCard:GetHeight()
            + RaidCard:GetHeight()
            + DelveCard:GetHeight()
            + 72
    )
end


function LayoutPage()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())
    PageContent:SetWidth(contentWidth)

    if contentWidth >= 1120 then
        LayoutWide(contentWidth)
    elseif contentWidth >= 840 then
        LayoutMedium(contentWidth)
    else
        LayoutNarrow(contentWidth)
    end

    UpdateTables()

    local maxScroll = math.max(0, PageContent:GetHeight() - PageScrollFrame:GetHeight())
    if PageScrollFrame:GetVerticalScroll() > maxScroll then
        PageScrollFrame:SetVerticalScroll(maxScroll)
    end
end

PageScrollFrame:SetScript("OnSizeChanged", function()
    LayoutPage()
end)

PageScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 42
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageItemLevelGuide:SetScript("OnShow", function()
    LayoutPage()
end)

C_Timer.After(0.1, LayoutPage)

BeavisQoL.Pages.ItemLevelGuide = PageItemLevelGuide
