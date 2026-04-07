local ADDON_NAME, BeavisQoL = ...

local L = BeavisQoL.L

BeavisQoL.PortalViewerModule = BeavisQoL.PortalViewerModule or {}
local PortalViewerModule = BeavisQoL.PortalViewerModule

local DEFAULT_POINT = "CENTER"
local DEFAULT_RELATIVE_POINT = "CENTER"
local DEFAULT_OFFSET_X = 470
local DEFAULT_OFFSET_Y = 10
local FRAME_WIDTH = 336
local MIN_FRAME_HEIGHT = 278
local ROW_HEIGHT = 24
local ROW_SPACING = 4
local GENERIC_PORTAL_ICON = "Interface\\Icons\\Spell_Arcane_PortalStormwind"

local PortalFrame
local TitleText

local PortalRows = {}
local PortalStatusCache
local PortalStatusCacheDirty = true
local InvalidatePortalStatusCache

local SEASON_DUNGEON_PORTALS = {
    {
        key = "magisters_terrace",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_MAGISTERS_TERRACE",
        spellID = 1254572,
        clientDungeonNames = {
            deDE = "Terrasse der Magister",
            enUS = "Magisters' Terrace",
        },
        shortNames = {
            deDE = "Magister",
            enUS = "Magisters",
        },
        englishSpellName = "Path of Devoted Magistry",
    },
    {
        key = "maisara_caverns",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_MAISARA_CAVERNS",
        spellID = 1254559,
        clientDungeonNames = {
            deDE = "Maisarakavernen",
            enUS = "Maisara Caverns",
        },
        shortNames = {
            deDE = "Maisara",
            enUS = "Maisara",
        },
        englishSpellName = "Path of Maisara Caverns",
    },
    {
        key = "nexus_point_xenas",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_NEXUS_POINT_XENAS",
        spellID = 1254563,
        clientDungeonNames = {
            deDE = "Nexuspunkt Xenas",
            enUS = "Nexus-Point Xenas",
        },
        shortNames = {
            deDE = "Xenas",
            enUS = "Xenas",
        },
        englishSpellName = "Path of Nexus-Point Xenas",
    },
    {
        key = "windrunner_spire",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_WINDRUNNER_SPIRE",
        spellID = 1254400,
        clientDungeonNames = {
            deDE = "Windläuferturm",
            enUS = "Windrunner Spire",
        },
        shortNames = {
            deDE = "Windläufer",
            enUS = "Windrunner",
        },
        achievementAliases = {
            "Windläuferturm",
        },
        englishSpellName = "Path of the Windrunners",
    },
    {
        key = "algethar_academy",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_ALGETHAR_ACADEMY",
        spellID = 393273,
        clientDungeonNames = {
            deDE = "Akademie von Algeth'ar",
            enUS = "Algeth'ar Academy",
        },
        shortNames = {
            deDE = "Algeth'ar",
            enUS = "Algeth'ar",
        },
        englishSpellName = "Path of the Draconic Diploma",
    },
    {
        key = "pit_of_saron",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_PIT_OF_SARON",
        spellID = 1254555,
        clientDungeonNames = {
            deDE = "Die Grube von Saron",
            enUS = "Pit of Saron",
        },
        achievementAliases = {
            "Grube von Saron",
        },
        shortNames = {
            deDE = "Saron",
            enUS = "Saron",
        },
        englishSpellName = "Path of Unyielding Blight",
    },
    {
        key = "seat_of_the_triumvirate",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_SEAT_OF_THE_TRIUMVIRATE",
        spellID = 1254551,
        clientDungeonNames = {
            deDE = "Sitz des Triumvirats",
            enUS = "Seat of the Triumvirate",
        },
        shortNames = {
            deDE = "Triumvirat",
            enUS = "Triumvirate",
        },
        englishSpellName = "Path of Dark Dereliction",
    },
    {
        key = "skyreach",
        dungeonNameKey = "PORTAL_VIEWER_DUNGEON_SKYREACH",
        spellID = 1254557,
        spellIDs = {
            1254557,
            159898,
        },
        clientDungeonNames = {
            deDE = "Himmelsnadel",
            enUS = "Skyreach",
        },
        shortNames = {
            deDE = "Himmelsnadel",
            enUS = "Skyreach",
        },
        englishSpellName = "Path of the Crowning Pinnacle",
    },
}

local function GetPortalViewerSettings()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.portalViewer = BeavisQoLDB.portalViewer or {}

    local db = BeavisQoLDB.portalViewer

    if db.enabled == nil then
        db.enabled = false
    end

    if db.locked == nil then
        db.locked = false
    end

    if type(db.point) ~= "string" or db.point == "" then
        db.point = DEFAULT_POINT
    end

    if type(db.relativePoint) ~= "string" or db.relativePoint == "" then
        db.relativePoint = DEFAULT_RELATIVE_POINT
    end

    if type(db.offsetX) ~= "number" then
        db.offsetX = DEFAULT_OFFSET_X
    end

    if type(db.offsetY) ~= "number" then
        db.offsetY = DEFAULT_OFFSET_Y
    end

    return db
end

local function SavePortalViewerPosition()
    if not PortalFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = PortalFrame:GetPoint(1)
    local settings = GetPortalViewerSettings()

    settings.point = point or DEFAULT_POINT
    settings.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    settings.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    settings.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function ApplyPortalViewerPosition()
    if not PortalFrame then
        return
    end

    local settings = GetPortalViewerSettings()
    PortalFrame:ClearAllPoints()
    PortalFrame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.offsetX, settings.offsetY)
end

function PortalViewerModule.IsWindowEnabled()
    return GetPortalViewerSettings().enabled == true
end

function PortalViewerModule.IsWindowLocked()
    return GetPortalViewerSettings().locked == true
end

function PortalViewerModule.SetWindowEnabled(enabled)
    local settings = GetPortalViewerSettings()
    settings.enabled = enabled == true

    if settings.enabled then
        InvalidatePortalStatusCache()
        PortalViewerModule.RefreshWindow()
    elseif PortalFrame then
        PortalFrame:Hide()
    end
end

function PortalViewerModule.ToggleWindow()
    PortalViewerModule.SetWindowEnabled(not PortalViewerModule.IsWindowEnabled())
end

function PortalViewerModule.SetWindowLocked(locked)
    local settings = GetPortalViewerSettings()
    settings.locked = locked == true

    if PortalFrame and PortalFrame.UpdateLockState then
        PortalFrame:UpdateLockState()
    end
end

function PortalViewerModule.IsMinimapContextMenuEntryVisible()
    if BeavisQoL.IsMinimapContextMenuEntryVisible then
        return BeavisQoL.IsMinimapContextMenuEntryVisible("portalViewer")
    end

    return true
end

function PortalViewerModule.SetMinimapContextMenuEntryVisible(visible)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("portalViewer", visible)
    end
end

local function GetPortalSpellCandidateIDs(dungeonData)
    if type(dungeonData) ~= "table" then
        return {}
    end

    if type(dungeonData.spellIDs) == "table" and #dungeonData.spellIDs > 0 then
        return dungeonData.spellIDs
    end

    if type(dungeonData.spellID) == "number" then
        return { dungeonData.spellID }
    end

    return {}
end

local function GetPortalSpellRenderInfo(dungeonData, preferredSpellID)
    local info
    local spellID = tonumber(preferredSpellID) or dungeonData.spellID

    if not info and spellID and C_Spell and C_Spell.GetSpellInfo then
        info = C_Spell.GetSpellInfo(spellID)
    end

    return {
        spellID = spellID,
        iconID = info and info.iconID or nil,
        spellName = (info and info.name) or dungeonData.englishSpellName,
    }
end

local function IsPortalSpellKnown(spellID)
    if type(spellID) ~= "number" then
        return false
    end

    if C_Spell and C_Spell.IsSpellKnownOrOverridesKnown then
        if C_Spell.IsSpellKnownOrOverridesKnown(spellID) == true then
            return true
        end
    end

    if C_Spell and C_Spell.IsSpellKnown then
        if C_Spell.IsSpellKnown(spellID) == true then
            return true
        end
    end

    local isSpellKnownOrOverridesKnown = rawget(_G, "IsSpellKnownOrOverridesKnown")
    if type(isSpellKnownOrOverridesKnown) == "function" and isSpellKnownOrOverridesKnown(spellID) == true then
        return true
    end

    local isPlayerSpell = rawget(_G, "IsPlayerSpell")
    if type(isPlayerSpell) == "function" and isPlayerSpell(spellID) == true then
        return true
    end

    local isSpellKnown = rawget(_G, "IsSpellKnown")
    if type(isSpellKnown) == "function" and isSpellKnown(spellID) == true then
        return true
    end

    return false
end

local function ResolveKnownPortalSpellID(dungeonData)
    for _, candidateSpellID in ipairs(GetPortalSpellCandidateIDs(dungeonData)) do
        if IsPortalSpellKnown(candidateSpellID) then
            return candidateSpellID
        end
    end

    return nil
end

local function GetDungeonDisplayName(dungeonData)
    return L(dungeonData.dungeonNameKey)
end

local function CreateSectionDivider(parent)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 0.82, 0, 0.16)
    return divider
end

local function CreatePortalRow(parent)
    local rowTemplate = BackdropTemplateMixin and "SecureActionButtonTemplate,BackdropTemplate" or "SecureActionButtonTemplate"
    local row = CreateFrame("Button", nil, parent, rowTemplate)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = {
            left = 1,
            right = 1,
            top = 1,
            bottom = 1,
        },
    })

    row.Accent = row:CreateTexture(nil, "ARTWORK")
    row.Accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.Accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.Accent:SetWidth(3)

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(14, 14)
    row.Icon:SetPoint("LEFT", row, "LEFT", 9, 0)
    row.Icon:SetTexture(GENERIC_PORTAL_ICON)

    row.DungeonText = row:CreateFontString(nil, "OVERLAY")
    row.DungeonText:SetPoint("LEFT", row.Icon, "RIGHT", 7, 0)
    row.DungeonText:SetPoint("RIGHT", row, "RIGHT", -54, 0)
    row.DungeonText:SetJustifyH("LEFT")
    row.DungeonText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    if row.DungeonText.SetWordWrap then
        row.DungeonText:SetWordWrap(false)
    end

    row.StateText = row:CreateFontString(nil, "OVERLAY")
    row.StateText:SetPoint("RIGHT", row, "RIGHT", -9, 0)
    row.StateText:SetJustifyH("RIGHT")
    row.StateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

    row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.Highlight:SetAllPoints()
    row.Highlight:SetColorTexture(1, 1, 1, 0.05)

    row:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.fullDungeonName or self.DungeonText:GetText() or "", 1, 0.82, 0)

        if self.unlocked then
            GameTooltip:AddLine(self.spellName or "", 0.92, 0.92, 0.96)
            GameTooltip:AddLine(L("PORTAL_VIEWER_CLICK_HINT"), 0.30, 0.90, 0.40)
        else
            GameTooltip:AddLine(L("PORTAL_VIEWER_LOCKED"), 1.00, 0.42, 0.32)
            GameTooltip:AddLine(L("PORTAL_VIEWER_REQUIREMENT"), 0.82, 0.82, 0.86)
        end

        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return row
end

InvalidatePortalStatusCache = function()
    PortalStatusCache = nil
    PortalStatusCacheDirty = true
end

local function GetPortalStatusByDungeon()
    if not PortalStatusCacheDirty and type(PortalStatusCache) == "table" then
        return PortalStatusCache
    end

    local statusByKey = {}

    for _, dungeonData in ipairs(SEASON_DUNGEON_PORTALS) do
        local knownSpellID = ResolveKnownPortalSpellID(dungeonData)
        local spellRenderInfo = GetPortalSpellRenderInfo(dungeonData, knownSpellID)
        statusByKey[dungeonData.key] = {
            unlocked = knownSpellID ~= nil,
            iconID = spellRenderInfo.iconID,
            spellID = spellRenderInfo.spellID,
            spellName = spellRenderInfo.spellName,
        }
    end

    PortalStatusCache = statusByKey
    PortalStatusCacheDirty = false

    return PortalStatusCache
end

local function ApplyRowVisual(row, unlocked)
    if unlocked then
        row:SetBackdropColor(0.05, 0.09, 0.07, 0.58)
        row:SetBackdropBorderColor(0.24, 0.72, 0.36, 0.58)
        row.Accent:SetColorTexture(0.24, 0.84, 0.38, 0.92)
        row.Icon:SetVertexColor(1, 1, 1, 1)
        if row.Icon.SetDesaturated then
            row.Icon:SetDesaturated(false)
        end
        row.DungeonText:SetTextColor(0.96, 0.96, 0.98, 1)
        row.StateText:SetTextColor(0.30, 0.96, 0.40, 1)
        return
    end

    row:SetBackdropColor(0.09, 0.06, 0.06, 0.56)
    row:SetBackdropBorderColor(0.52, 0.24, 0.24, 0.56)
    row.Accent:SetColorTexture(0.96, 0.32, 0.24, 0.88)
    row.Icon:SetVertexColor(1, 1, 1, 0.82)
    if row.Icon.SetDesaturated then
        row.Icon:SetDesaturated(true)
    end
    row.DungeonText:SetTextColor(0.94, 0.94, 0.96, 1)
    row.StateText:SetTextColor(1.00, 0.48, 0.34, 1)
end

local function ConfigureRow(row, dungeonData, dungeonStatus)
    row.unlocked = dungeonStatus.unlocked == true
    row.spellID = dungeonStatus.spellID or dungeonData.spellID
    row.spellName = dungeonStatus.spellName or dungeonData.englishSpellName
    row.fullDungeonName = L(dungeonData.dungeonNameKey)
    row.DungeonText:SetText(GetDungeonDisplayName(dungeonData))
    row.StateText:SetText(row.unlocked and L("PORTAL_VIEWER_ACTION_USE") or L("PORTAL_VIEWER_ACTION_MISSING"))
    row.Icon:SetTexture(dungeonStatus.iconID or GENERIC_PORTAL_ICON)

    if not (InCombatLockdown and InCombatLockdown()) then
        row:SetAttribute("type", nil)
        row:SetAttribute("type1", nil)
        row:SetAttribute("spell", nil)
        row:SetAttribute("spell1", nil)

        if row.unlocked and type(row.spellID) == "number" then
            row:SetAttribute("type", "spell")
            row:SetAttribute("type1", "spell")
            row:SetAttribute("spell", row.spellID)
            row:SetAttribute("spell1", row.spellID)
        end
    end

    ApplyRowVisual(row, row.unlocked)
end

local function EnsureRow(pool, parent, index)
    if not pool[index] then
        pool[index] = CreatePortalRow(parent)
    end

    return pool[index]
end

local function RefreshPortalViewerTexts()
    TitleText:SetText(L("PORTAL_VIEWER_TITLE"))
end

local function LayoutPortalRows(statusByKey)
    RefreshPortalViewerTexts()

    for _, row in ipairs(PortalRows) do
        row:Hide()
    end

    local currentY = -44

    for index, dungeonData in ipairs(SEASON_DUNGEON_PORTALS) do
        local row = EnsureRow(PortalRows, PortalFrame, index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 12, currentY)
        row:SetPoint("TOPRIGHT", PortalFrame, "TOPRIGHT", -12, currentY)
        ConfigureRow(row, dungeonData, statusByKey[dungeonData.key] or {})
        row:Show()
        currentY = currentY - (ROW_HEIGHT + ROW_SPACING)
    end

    PortalFrame:SetHeight(math.max(MIN_FRAME_HEIGHT, (-currentY) + 12))
end

local function BuildPortalViewerFrame()
    if PortalFrame then
        return
    end

    PortalFrame = CreateFrame("Frame", "BeavisQoLPortalViewerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    PortalFrame:SetSize(FRAME_WIDTH, MIN_FRAME_HEIGHT)
    PortalFrame:SetFrameStrata("MEDIUM")
    PortalFrame:SetClampedToScreen(true)
    PortalFrame:SetMovable(true)
    PortalFrame:SetToplevel(true)
    PortalFrame:EnableMouse(true)
    PortalFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = {
            left = 1,
            right = 1,
            top = 1,
            bottom = 1,
        },
    })
    PortalFrame:SetBackdropColor(0.03, 0.03, 0.04, 0.78)
    PortalFrame:SetBackdropBorderColor(1.00, 0.82, 0.00, 0.42)
    PortalFrame:Hide()

    local topGlow = PortalFrame:CreateTexture(nil, "BORDER")
    topGlow:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", PortalFrame, "TOPRIGHT", 0, 0)
    topGlow:SetHeight(28)
    topGlow:SetColorTexture(1, 0.82, 0, 0.08)

    local accent = PortalFrame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 10, -10)
    accent:SetPoint("BOTTOMLEFT", PortalFrame, "BOTTOMLEFT", 10, 10)
    accent:SetWidth(2)
    accent:SetColorTexture(1, 0.82, 0, 0.14)

    local topLine = PortalFrame:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 12, -10)
    topLine:SetPoint("TOPRIGHT", PortalFrame, "TOPRIGHT", -12, -10)
    topLine:SetHeight(1)
    topLine:SetColorTexture(1, 0.82, 0, 0.70)

    TitleText = PortalFrame:CreateFontString(nil, "OVERLAY")
    TitleText:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 18, -18)
    TitleText:SetPoint("RIGHT", PortalFrame, "RIGHT", -40, 0)
    TitleText:SetJustifyH("LEFT")
    TitleText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    TitleText:SetTextColor(1, 0.82, 0, 1)

    local closeButton = CreateFrame("Button", nil, PortalFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("TOPRIGHT", PortalFrame, "TOPRIGHT", -10, -12)
    closeButton:SetText("X")
    if closeButton.GetFontString then
        closeButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    closeButton:SetScript("OnClick", function()
        PortalViewerModule.SetWindowEnabled(false)
    end)
    closeButton:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L("PORTAL_VIEWER_CLOSE_TOOLTIP"), 1, 1, 1)
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    local dragHandle = CreateFrame("Frame", nil, PortalFrame)
    dragHandle:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 12, -10)
    dragHandle:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -6, 0)
    dragHandle:SetHeight(22)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function(self)
        if PortalViewerModule.IsWindowLocked and PortalViewerModule.IsWindowLocked() then
            return
        end

        self:GetParent():StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function(self)
        local parent = self:GetParent()
        parent:StopMovingOrSizing()
        SavePortalViewerPosition()
    end)
    PortalFrame.DragHandle = dragHandle

    PortalFrame.UpdateLockState = function(self)
        local isLocked = PortalViewerModule.IsWindowLocked and PortalViewerModule.IsWindowLocked() or false
        self:SetMovable(not isLocked)

        if self.DragHandle then
            self.DragHandle:EnableMouse(not isLocked)
        end
    end

    local divider = CreateSectionDivider(PortalFrame)
    divider:SetPoint("TOPLEFT", PortalFrame, "TOPLEFT", 12, -34)
    divider:SetPoint("TOPRIGHT", PortalFrame, "TOPRIGHT", -12, -34)
    divider:SetHeight(1)

    ApplyPortalViewerPosition()
    PortalFrame:UpdateLockState()
end

function PortalViewerModule.RefreshWindow()
    local settings = GetPortalViewerSettings()

    if not settings.enabled then
        if PortalFrame then
            PortalFrame:Hide()
        end

        return
    end

    BuildPortalViewerFrame()
    if PortalFrame and PortalFrame.UpdateLockState then
        PortalFrame:UpdateLockState()
    end
    LayoutPortalRows(GetPortalStatusByDungeon())

    if PortalFrame then
        PortalFrame:Show()
    end
end

BeavisQoL.UpdatePortalViewer = function()
    if PortalViewerModule and PortalViewerModule.RefreshWindow and PortalViewerModule.IsWindowEnabled and PortalViewerModule.IsWindowEnabled() then
        PortalViewerModule.RefreshWindow()
    end
end

local PortalViewerEvents = CreateFrame("Frame")
PortalViewerEvents:RegisterEvent("PLAYER_LOGIN")
PortalViewerEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
PortalViewerEvents:RegisterEvent("SPELLS_CHANGED")
PortalViewerEvents:SetScript("OnEvent", function()
    InvalidatePortalStatusCache()
end)
