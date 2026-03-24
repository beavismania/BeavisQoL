local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.BossGuidesModule = BeavisQoL.BossGuidesModule or {}
local BossGuidesModule = BeavisQoL.BossGuidesModule

local DEFAULT_POINT = "TOPLEFT"
local DEFAULT_RELATIVE_POINT = "TOPLEFT"
local DEFAULT_OFFSET_X = 8
local DEFAULT_OFFSET_Y = -8

local DEFAULT_WINDOW_POINT = "TOPLEFT"
local DEFAULT_WINDOW_RELATIVE_POINT = "TOPLEFT"
local DEFAULT_WINDOW_OFFSET_X = 8
local DEFAULT_WINDOW_OFFSET_Y = -42

local DEFAULT_SCALE = 1.00
local MIN_SCALE = 0.80
local MAX_SCALE = 1.40

local DEFAULT_WINDOW_WIDTH  = 450
local DEFAULT_WINDOW_HEIGHT = 500
local MIN_WINDOW_WIDTH      = 300
local MIN_WINDOW_HEIGHT     = 180

local DEFAULT_FONT_SIZE = 10
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 18

local FONT_PATH = "Interface\\AddOns\\BeavisQoL\\Media\\Fonts\\Expressway.ttf"

local GUIDE_DATA = {
    voidspire = {
        titleKey = "BOSS_GUIDES_INSTANCE_VOIDSPIRE_TITLE",
        type = "raid",
        matchTokensKey = "BOSS_GUIDES_INSTANCE_VOIDSPIRE_TOKENS",
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_IMPERATOR_AVERZIAN_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_IMPERATOR_AVERZIAN_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_VORASIUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_VORASIUS_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_FALLEN_KING_SALHADAAR_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_FALLEN_KING_SALHADAAR_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_VAELGOR_EZZORAK_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_VAELGOR_EZZORAK_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_LIGHTBLINDED_VANGUARD_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_LIGHTBLINDED_VANGUARD_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_CROWN_OF_COSMOS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_CROWN_OF_COSMOS_BODY",
            },
        },
    },
    dreamrift = {
        titleKey = "BOSS_GUIDES_INSTANCE_DREAMRIFT_TITLE",
        type = "raid",
        matchTokensKey = "BOSS_GUIDES_INSTANCE_DREAMRIFT_TOKENS",
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_CHIMAERUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_CHIMAERUS_BODY",
            },
        },
    },
}

local OverlayButton
local GuideWindow
local BossMenuPanel
local ContentScrollFrame
local ContentScrollChild
local ContentText
local CategoryDropdown
local InstanceDropdown
local TabButtons = {}
local isRefreshingPage = false
local activeGuideKey = nil
local activeBossIndex = 1
local selectedCategory = "raid"

local PageBossGuides
local ShowOverlayCheckbox
local OverlayModeDropdown
local LockOverlayCheckbox
local ScaleSlider
local ScaleSliderText
local FontSizeSlider
local FontSizeSliderText
local CurrentInstanceText
local LegendFontStrings = {}
local PinBtn
local GuideTextSegments = {}
local GuideSpellButtons = {}
local GetBossGuidesSettings

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor(((tonumber(value) or DEFAULT_SCALE) * 100) + 0.5))
end

local function GetRoleIcon(role, size)
    size = size or 14
    if role == "TANK" then
        local icon = _G["INLINE_TANK_ICON"]
        if icon then return icon end
        return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:%d:%d:0:0:64:64:0:19:22:41|t", size, size)
    end
    if role == "HEAL" then
        local icon = _G["INLINE_HEALER_ICON"]
        if icon then return icon end
        return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:%d:%d:0:0:64:64:20:39:1:20|t", size, size)
    end
    if role == "DD" then
        local icon = _G["INLINE_DAMAGER_ICON"]
        if icon then return icon end
        return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:%d:%d:0:0:64:64:20:39:22:41|t", size, size)
    end
    if role == "HC" then
        return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:%d|t", size)
    end
    if role == "M" then
        return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:%d|t", size)
    end
    return ""
end

local function ResolveIcons(text, size)
    size = size or 14
    text = string.gsub(text, "{TANK}", function() return GetRoleIcon("TANK", size) end)
    text = string.gsub(text, "{DD}", function() return GetRoleIcon("DD", size) end)
    text = string.gsub(text, "{HEAL}", function() return GetRoleIcon("HEAL", size) end)
    text = string.gsub(text, "{HC}", function() return GetRoleIcon("HC", size) end)
    text = string.gsub(text, "{M}", function() return GetRoleIcon("M", size) end)
    return text
end

local KNOWN_SPELL_NAMES = {
    "Oblivion's Wrath",
    "Shadow Phalanx",
    "Dark Barrage",
    "Void Infusion",
    "Black Miasma",
    "Cosmic Shell",
    "Void Marked",
    "Pitch Bulwark",
    "Void Fall",
    "Overpowering Pulse",
    "Blisterburst",
    "Void Breath",
    "Primordial Roar",
    "Creep Spit",
    "Dark Goo",
    "Smashed",
    "Torturous Extract",
    "Shattering Twilight",
    "Destabilizing Strikes",
    "Concentrated Void",
    "Fractured Images",
    "Entropic Unraveling",
    "Twisting Obscurity",
    "Despotic Command",
    "Oppressive Darkness",
    "Dark Radiation",
    "Enduring Void",
    "Nexus Shield",
    "Twilight Bond",
    "Vaelwing",
    "Rakfang",
    "Nullbeam",
    "Gloom",
    "Dread Breath",
    "Nullzone",
    "Shadowmark",
    "Nullsnap",
    "Midnight Flames",
    "Gloomtouched",
    "Diminish",
    "Nullscatter",
    "Cosmosis",
    "Retribution",
    "Judgment",
    "Exorcism",
    "Execution Sentence",
    "Sacred Shield",
    "Blinding Light",
    "Divine Hammer",
    "Light Infused",
    "Searing Radiance",
    "Tyr's Wrath",
    "Divine Toll",
    "Consecration",
    "Zealous Spirit",
    "Divine Consecration",
    "Echoing Darkness",
    "Empowering Darkness",
    "Rift Slash",
    "Silverstrike",
    "Cosmic Barrier",
    "Coalesced Form",
    "Null Corona",
    "Voidstalker Sting",
    "Devouring Cosmos",
    "Void Expulsion",
    "Barrage",
    "Silver Residue",
    "Grasp of Emptiness",
    "Upheaval",
    "Colossal Horrors",
    "Alnshroud",
    "Fearsome Cry",
    "Essence Bolt",
    "Ravenous Dive",
    "Rift Sickness",
    "Caustic Phlegm",
    "Cannibalized Essence",
    "Consuming Miasma",
    "Alndust Essence",
    "Rift Madness",
    "Dissonance",
}

local function GetCentralSpellNameMap()
    local map = L("BOSS_GUIDES_SPELL_NAMES")
    if type(map) == "table" then
        return map
    end
    return {}
end

local function EscapeLuaPattern(text)
    return (text:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
end

local function GetSortedSpellNames()
    local sortedNames = {}

    for index, spellName in ipairs(KNOWN_SPELL_NAMES) do
        sortedNames[index] = spellName
    end

    table.sort(sortedNames, function(a, b) return #a > #b end)
    return sortedNames
end

local SORTED_SPELL_NAMES = GetSortedSpellNames()
local SPELL_RENDER_CACHE = {}

local function ParseSpellIDFromLink(link)
    if type(link) ~= "string" then
        return nil
    end

    local spellID = link:match("|Hspell:(%d+)") or link:match("spell:(%d+)")
    if spellID then
        return tonumber(spellID)
    end

    return nil
end

local function GetSpellRenderInfo(englishSpellName)
    if SPELL_RENDER_CACHE[englishSpellName] then
        return SPELL_RENDER_CACHE[englishSpellName]
    end

    local centralMap = GetCentralSpellNameMap()
    local mapEntry = centralMap[englishSpellName]
    local localizedSpellName = englishSpellName
    local mappedSpellID

    if type(mapEntry) == "table" then
        mappedSpellID = tonumber(mapEntry.spellID or mapEntry.id)
        localizedSpellName = mapEntry.localizedName or mapEntry.name or englishSpellName
    elseif type(mapEntry) == "string" then
        localizedSpellName = mapEntry
    end

    local info
    local spellLink

    if mappedSpellID and C_Spell and C_Spell.GetSpellInfo then
        info = C_Spell.GetSpellInfo(mappedSpellID)
    end

    if mappedSpellID and C_Spell and C_Spell.GetSpellLink then
        spellLink = C_Spell.GetSpellLink(mappedSpellID)
    end

    if C_Spell and C_Spell.GetSpellInfo then
        info = info or C_Spell.GetSpellInfo(localizedSpellName) or C_Spell.GetSpellInfo(englishSpellName)
    end

    if C_Spell and C_Spell.GetSpellLink then
        spellLink = spellLink or C_Spell.GetSpellLink(localizedSpellName) or C_Spell.GetSpellLink(englishSpellName)
    end

    local spellID = mappedSpellID or (info and info.spellID) or ParseSpellIDFromLink(spellLink)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        info = info or C_Spell.GetSpellInfo(spellID)
    end

    if spellID and not spellLink and C_Spell and C_Spell.GetSpellLink then
        spellLink = C_Spell.GetSpellLink(spellID)
    end

    local renderInfo = {
        englishName = englishSpellName,
        localizedName = (info and info.name) or localizedSpellName,
        spellID = spellID,
        iconID = info and info.iconID or nil,
        spellLink = spellLink,
    }

    SPELL_RENDER_CACHE[englishSpellName] = renderInfo
    return renderInfo
end

local function SplitGuideLineSegments(line)
    local segments = {}
    local cursor = 1

    while cursor <= #line do
        local bestStart, bestEnd, bestSpell

        for _, englishSpellName in ipairs(SORTED_SPELL_NAMES) do
            local startPos, endPos = line:find(EscapeLuaPattern(englishSpellName), cursor)
            if startPos and (not bestStart or startPos < bestStart) then
                bestStart = startPos
                bestEnd = endPos
                bestSpell = englishSpellName
            end
        end

        if not bestStart then
            local tailText = line:sub(cursor)
            if tailText ~= "" then
                table.insert(segments, { kind = "text", text = ResolveIcons(tailText, 14) })
            end
            break
        end

        if bestStart > cursor then
            local plainText = line:sub(cursor, bestStart - 1)
            if plainText ~= "" then
                table.insert(segments, { kind = "text", text = ResolveIcons(plainText, 14) })
            end
        end

        table.insert(segments, { kind = "spell", spell = GetSpellRenderInfo(bestSpell) })
        cursor = bestEnd + 1
    end

    if #segments == 0 then
        table.insert(segments, { kind = "text", text = ResolveIcons(line, 14) })
    end

    return segments
end

local function AcquireGuideTextSegment(index)
    local widget = GuideTextSegments[index]
    if widget then
        return widget
    end

    widget = ContentScrollChild:CreateFontString(nil, "OVERLAY")
    widget:SetJustifyH("LEFT")
    widget:SetJustifyV("TOP")
    widget:SetWordWrap(false)
    GuideTextSegments[index] = widget
    return widget
end

local function AcquireGuideSpellButton(index)
    local button = GuideSpellButtons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, ContentScrollChild)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:SetFrameStrata(GuideWindow and GuideWindow:GetFrameStrata() or "DIALOG")
    button:SetFrameLevel((GuideWindow and GuideWindow:GetFrameLevel() or 1) + 20)
    button:SetHitRectInsets(-4, -4, -3, -3)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(false)
    button.Text = text

    local function ShowSpellTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        if self.spellLink then
            GameTooltip:SetHyperlink(self.spellLink)
        elseif self.spellID and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(self.spellID)
        elseif self.spellID then
            GameTooltip:SetHyperlink("spell:" .. self.spellID)
        elseif self.spellName then
            GameTooltip:SetText(self.spellName, 1, 0.82, 0, 1, true)
        end

        local description
        if C_Spell and C_Spell.GetSpellDescription then
            description = C_Spell.GetSpellDescription(self.spellID or self.spellName)
        end

        if type(description) == "string" and description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(description, 0.90, 0.90, 0.90, true)
        end

        GameTooltip:Show()
    end

    button:SetScript("OnEnter", function(self)
        self.Text:SetTextColor(1, 0.9, 0.35, 1)
        ShowSpellTooltip(self)
    end)

    button:SetScript("OnLeave", function()
        button.Text:SetTextColor(1.00, 0.82, 0.20, 1)
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self)
        if self.spellLink and SetItemRef then
            SetItemRef(self.spellLink, self.spellLink, "LeftButton", self)
            return
        end

        if self.spellID and SetItemRef then
            local simpleLink = "spell:" .. self.spellID
            SetItemRef(simpleLink, simpleLink, "LeftButton", self)
            return
        end

        ShowSpellTooltip(self)
    end)

    GuideSpellButtons[index] = button
    return button
end

local function HideGuideContentWidgets()
    for _, widget in ipairs(GuideTextSegments) do
        widget:Hide()
    end

    for _, button in ipairs(GuideSpellButtons) do
        button:Hide()
    end
end

local function RenderGuideBody(body)
    if not ContentText or not ContentScrollFrame then
        return 220
    end

    HideGuideContentWidgets()

    local db = GetBossGuidesSettings()
    local baseX = 6
    local x = baseX
    local y = -4
    local lineGap = 3
    local availableWidth = math.max(ContentScrollFrame:GetWidth() - 12, 40)
    local textIndex = 0
    local spellIndex = 0

    for line in tostring(body or ""):gmatch("[^\n]+") do
        local segments = SplitGuideLineSegments(line)
        local currentLineHeight = db.fontSize + 6

        for _, segment in ipairs(segments) do
            local widget
            local segmentWidth
            local segmentHeight

            if segment.kind == "spell" then
                spellIndex = spellIndex + 1
                widget = AcquireGuideSpellButton(spellIndex)
                widget.Text:SetFont(FONT_PATH, db.fontSize, "OUTLINE")
                widget.Text:SetTextColor(1.00, 0.82, 0.20, 1)

                local spellText = string.format("[%s]", segment.spell.localizedName)
                if segment.spell.iconID then
                    spellText = string.format("|T%d:14:14:0:0|t %s", segment.spell.iconID, spellText)
                end

                widget.Text:SetText(spellText)
                segmentWidth = widget.Text:GetStringWidth() + 2
                segmentHeight = math.max(widget.Text:GetStringHeight(), db.fontSize + 4)
                widget.spellID = segment.spell.spellID
                widget.spellLink = segment.spell.spellLink
                widget.spellName = segment.spell.localizedName
                widget:SetSize(segmentWidth, segmentHeight)
            else
                textIndex = textIndex + 1
                widget = AcquireGuideTextSegment(textIndex)
                widget:SetFont(FONT_PATH, db.fontSize, "OUTLINE")
                widget:SetTextColor(0.93, 0.90, 0.83, 1)
                widget:SetText(segment.text)
                segmentWidth = widget:GetStringWidth()
                segmentHeight = math.max(widget:GetStringHeight(), db.fontSize + 4)
            end

            if x > baseX and (x + segmentWidth) > availableWidth then
                x = baseX
                y = y - currentLineHeight
                currentLineHeight = segmentHeight
            else
                currentLineHeight = math.max(currentLineHeight, segmentHeight)
            end

            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", ContentScrollChild, "TOPLEFT", x, y)
            widget:Show()

            x = x + segmentWidth
        end

        x = baseX
        y = y - currentLineHeight - lineGap
    end

    return math.max((-y) + 8, 32)
end

local function NormalizeText(text)
    local normalized = string.lower(tostring(text or ""))
    normalized = string.gsub(normalized, "[%c%p]", " ")
    normalized = string.gsub(normalized, "%s+", " ")
    normalized = string.match(normalized, "^%s*(.-)%s*$") or ""
    return normalized
end

local function GetLocalizedGuideTokens(guideData)
    if guideData and guideData.matchTokensKey then
        local tokens = L(guideData.matchTokensKey)
        if type(tokens) == "table" then
            return tokens
        end
    end

    if guideData and type(guideData.matchTokens) == "table" then
        return guideData.matchTokens
    end

    return {}
end

local function GetGuideTitle(guideData)
    if guideData and guideData.titleKey then
        return L(guideData.titleKey)
    end

    return guideData and guideData.title or ""
end

local function GetBossName(bossData)
    if bossData and bossData.nameKey then
        return L(bossData.nameKey)
    end

    return bossData and bossData.name or ""
end

local function GetBossBody(bossData)
    if bossData and bossData.bodyKey then
        return L(bossData.bodyKey)
    end

    return bossData and bossData.body or ""
end

function GetBossGuidesSettings()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.bossGuides = BeavisQoLDB.bossGuides or {}

    local db = BeavisQoLDB.bossGuides

    if db.overlayEnabled == nil then
        db.overlayEnabled = true
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if db.overlayMode ~= "always" and db.overlayMode ~= "instance_only" then
        db.overlayMode = "instance_only"
    end

    if type(db.overlayScale) ~= "number" then
        db.overlayScale = DEFAULT_SCALE
    end
    db.overlayScale = Clamp(db.overlayScale, MIN_SCALE, MAX_SCALE)

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

    if db.point == "TOPLEFT" and db.relativePoint == "TOPLEFT" and db.offsetX == 24 and db.offsetY == -160 then
        db.offsetX = DEFAULT_OFFSET_X
        db.offsetY = DEFAULT_OFFSET_Y
    end

    if type(db.windowPoint) ~= "string" or db.windowPoint == "" then
        db.windowPoint = DEFAULT_WINDOW_POINT
    end

    if type(db.windowRelativePoint) ~= "string" or db.windowRelativePoint == "" then
        db.windowRelativePoint = DEFAULT_WINDOW_RELATIVE_POINT
    end

    if type(db.windowOffsetX) ~= "number" then
        db.windowOffsetX = DEFAULT_WINDOW_OFFSET_X
    end

    if type(db.windowOffsetY) ~= "number" then
        db.windowOffsetY = DEFAULT_WINDOW_OFFSET_Y
    end

    if type(db.windowWidth) ~= "number" or db.windowWidth < MIN_WINDOW_WIDTH then
        db.windowWidth = DEFAULT_WINDOW_WIDTH
    end

    if type(db.windowHeight) ~= "number" or db.windowHeight < MIN_WINDOW_HEIGHT then
        db.windowHeight = DEFAULT_WINDOW_HEIGHT
    end

    -- Migration alter Standardgröße auf neue kompakte Standardgröße.
    if db.windowWidth == 680 and db.windowHeight == 340 then
        db.windowWidth = DEFAULT_WINDOW_WIDTH
        db.windowHeight = DEFAULT_WINDOW_HEIGHT
    end

    if db.windowWidth == 560 and db.windowHeight == 360 then
        db.windowWidth = DEFAULT_WINDOW_WIDTH
        db.windowHeight = DEFAULT_WINDOW_HEIGHT
    end

    if db.windowPoint == "CENTER" and db.windowRelativePoint == "CENTER" and db.windowOffsetX == 0 and db.windowOffsetY == 0 then
        db.windowPoint = DEFAULT_WINDOW_POINT
        db.windowRelativePoint = DEFAULT_WINDOW_RELATIVE_POINT
        db.windowOffsetX = DEFAULT_WINDOW_OFFSET_X
        db.windowOffsetY = DEFAULT_WINDOW_OFFSET_Y
    end

    if type(db.fontSize) ~= "number" then
        db.fontSize = DEFAULT_FONT_SIZE
    end
    db.fontSize = Clamp(db.fontSize, MIN_FONT_SIZE, MAX_FONT_SIZE)

    return db
end

local function SaveOverlayButtonGeometry()
    if not OverlayButton then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayButton:GetPoint(1)
    local db = GetBossGuidesSettings()

    db.point = point or DEFAULT_POINT
    db.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    db.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    db.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function SaveGuideWindowGeometry()
    if not GuideWindow then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = GuideWindow:GetPoint(1)
    local db = GetBossGuidesSettings()

    db.windowPoint = point or DEFAULT_WINDOW_POINT
    db.windowRelativePoint = relativePoint or DEFAULT_WINDOW_RELATIVE_POINT
    db.windowOffsetX = math.floor((offsetX or DEFAULT_WINDOW_OFFSET_X) + 0.5)
    db.windowOffsetY = math.floor((offsetY or DEFAULT_WINDOW_OFFSET_Y) + 0.5)
    db.windowWidth   = math.floor(GuideWindow:GetWidth()  + 0.5)
    db.windowHeight  = math.floor(GuideWindow:GetHeight() + 0.5)
end

local function ApplyOverlayButtonGeometry()
    if not OverlayButton then
        return
    end

    local db = GetBossGuidesSettings()
    OverlayButton:ClearAllPoints()
    OverlayButton:SetPoint(db.point, UIParent, db.relativePoint, db.offsetX, db.offsetY)
end

local function ApplyGuideWindowGeometry()
    if not GuideWindow then
        return
    end

    local db = GetBossGuidesSettings()
    GuideWindow:SetSize(db.windowWidth, db.windowHeight)
    GuideWindow:ClearAllPoints()
    GuideWindow:SetPoint(db.windowPoint, UIParent, db.windowRelativePoint, db.windowOffsetX, db.windowOffsetY)
end

local function GetCurrentInstanceNameAndType()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return nil, nil
    end

    local instanceName = GetInstanceInfo()
    if type(instanceName) ~= "string" or instanceName == "" then
        instanceName = GetRealZoneText() or ""
    end

    return instanceName, instanceType
end

local function ResolveGuideKeyForCurrentInstance()
    local instanceName, instanceType = GetCurrentInstanceNameAndType()
    if not instanceName then
        return nil
    end

    if instanceType ~= "party" and instanceType ~= "raid" then
        return nil
    end

    local normalizedInstanceName = NormalizeText(instanceName)

    for guideKey, guideData in pairs(GUIDE_DATA) do
        for _, token in ipairs(GetLocalizedGuideTokens(guideData)) do
            local normalizedToken = NormalizeText(token)
            if normalizedToken ~= "" and string.find(normalizedInstanceName, normalizedToken, 1, true) then
                return guideKey
            end
        end
    end

    return nil
end

local function GetActiveGuideData()
    if not activeGuideKey then
        return nil
    end

    return GUIDE_DATA[activeGuideKey]
end

local function ApplyBossButtonVisual(btn, isActive)
    if isActive then
        btn.Bg:SetColorTexture(1, 0.94, 0.47, 0.12)
        btn.Accent:Show()
        btn.Text:SetTextColor(1, 0.94, 0.47, 1)
        return
    end

    btn.Bg:SetColorTexture(0, 0, 0, 0)
    btn.Accent:Hide()
    btn.Text:SetTextColor(0.26, 0.75, 0.63, 1)
end

local SEP_ROLE = "|cFF2B6B5A" .. string.rep("-", 34) .. "|r"
local SEP_HC   = "|cFF444444" .. string.rep("-", 34) .. "|r"

local function TrimText(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SplitInstructionParts(text)
    local parts = {}
    for chunk in text:gmatch("[^.;,]+[.;,]?") do
        local normalized = TrimText(chunk)
        if normalized ~= "" then
            table.insert(parts, normalized)
        end
    end

    if #parts == 0 then
        table.insert(parts, TrimText(text))
    end

    return parts
end

local function FormatRoleRows(body)
    local outputLines = {}
    local generalLabel = L("BOSS_GUIDES_SECTION_GENERAL")
    local mythicLabel = L("BOSS_GUIDES_LABEL_MYTHIC")

    for line in body:gmatch("[^\n]+") do
        local generalText = line:match("^" .. EscapeLuaPattern(generalLabel) .. ":%s*(.+)$")
        if generalText then
            local parts = SplitInstructionParts(generalText)
            table.insert(outputLines, generalLabel .. ":")
            for i = 1, #parts do
                table.insert(outputLines, "    • " .. parts[i])
            end
        else
        local token, text = line:match("^({[A-Z]+})%s*(.+)$")
        if token and text and (token == "{TANK}" or token == "{DD}" or token == "{HEAL}" or token == "{HC}" or token == "{M}") then
            local parts = SplitInstructionParts(text)
            local label = token
            if token == "{HC}" then
                label = token .. " [HC]"
            elseif token == "{M}" then
                label = token .. " [" .. mythicLabel .. "]"
            end

            table.insert(outputLines, label .. " " .. parts[1])
            for i = 2, #parts do
                table.insert(outputLines, "    • " .. parts[i])
            end
        else
            table.insert(outputLines, line)
        end
        end
    end

    return table.concat(outputLines, "\n")
end

local function AddSeparators(body)
    -- Trennlinie zwischen Allgemein und Rollenblock.
    body = body:gsub("\n({TANK}[^\n]*)", "\n" .. SEP_ROLE .. "\n%1")
    -- Trennlinie vor DD und HEAL (Tank/DD/Heal-Block)
    body = body:gsub("\n({DD}[^\n]*)",   "\n" .. SEP_ROLE .. "\n%1")
    body = body:gsub("\n({HEAL}[^\n]*)", "\n" .. SEP_ROLE .. "\n%1")
    -- Trennlinien vor HC und erneut vor Mythisch.
    body = body:gsub("\n({HC}[^\n]*)",   "\n" .. SEP_HC   .. "\n%1")
    body = body:gsub("\n({M}[^\n]*)",    "\n" .. SEP_HC   .. "\n%1")
    return body
end

local function UpdateGuideText()
    if not GuideWindow or not ContentText then
        return
    end

    local guideData = GetActiveGuideData()
    if not guideData then
        local emptyHeight = RenderGuideBody(L("BOSS_GUIDES_NO_GUIDE"))
        ContentText:SetHeight(emptyHeight)
        ContentScrollChild:SetHeight(200)
        return
    end

    local bossData = guideData.bosses[activeBossIndex]
    if not bossData then
        local emptyHeight = RenderGuideBody(L("BOSS_GUIDES_NO_GUIDE"))
        ContentText:SetHeight(emptyHeight)
        ContentScrollChild:SetHeight(200)
        return
    end

    local formattedBody = AddSeparators(FormatRoleRows(GetBossBody(bossData)))
    local expectedHeight = RenderGuideBody(formattedBody)
    ContentText:SetHeight(expectedHeight)
    local minHeight = math.max(ContentScrollFrame:GetHeight(), 220)
    ContentScrollChild:SetHeight(math.max(expectedHeight, minHeight))
    ContentScrollFrame:SetVerticalScroll(0)
end

local function RebuildBossMenu()
    if not BossMenuPanel then
        return
    end

    for _, tabButton in ipairs(TabButtons) do
        tabButton:Hide()
        tabButton:ClearAllPoints()
    end

    local guideData = GetActiveGuideData()
    if not guideData then
        BossMenuPanel:SetHeight(4)
        return
    end

    local BTN_H   = 22   -- Höhe jedes Buttons
    local BTN_GAP = 4    -- Abstand zwischen Buttons (horizontal)
    local ROW_GAP = 2    -- Abstand zwischen Reihen
    local PAD_L   = 6    -- linker/rechter Innenabstand
    local PAD_T   = 4    -- oberer Innenabstand

    local panelW = BossMenuPanel:GetWidth()
    if panelW < 10 then
        panelW = (GuideWindow and GuideWindow:GetWidth()) or 680
    end
    local availW = panelW - PAD_L * 2

    local rowX = PAD_L
    local rowY = -PAD_T

    for bossIndex, bossData in ipairs(guideData.bosses) do
        local tabButton = TabButtons[bossIndex]

        if not tabButton then
            tabButton = CreateFrame("Button", nil, BossMenuPanel)

            local bg = tabButton:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0, 0, 0, 0)
            tabButton.Bg = bg

            -- Akzent-Linie am unteren Rand (horizontal)
            local accent = tabButton:CreateTexture(nil, "ARTWORK")
            accent:SetPoint("BOTTOMLEFT",  tabButton, "BOTTOMLEFT",  0, 0)
            accent:SetPoint("BOTTOMRIGHT", tabButton, "BOTTOMRIGHT", 0, 0)
            accent:SetHeight(2)
            accent:SetColorTexture(1, 0.94, 0.47, 1)
            accent:Hide()
            tabButton.Accent = accent

            local text = tabButton:CreateFontString(nil, "OVERLAY")
            text:SetAllPoints(tabButton)
            text:SetFont(FONT_PATH, DEFAULT_FONT_SIZE, "OUTLINE")
            text:SetJustifyH("CENTER")
            text:SetJustifyV("MIDDLE")
            text:SetWordWrap(false)
            tabButton.Text = text

            tabButton:SetScript("OnEnter", function(self)
                if self.BossIndex ~= activeBossIndex then
                    self.Bg:SetColorTexture(0.26, 0.75, 0.63, 0.08)
                end
            end)

            tabButton:SetScript("OnLeave", function(self)
                ApplyBossButtonVisual(self, self.BossIndex == activeBossIndex)
            end)

            tabButton:SetScript("OnClick", function(self)
                activeBossIndex = self.BossIndex
                for _, button in ipairs(TabButtons) do
                    if button:IsShown() then
                        ApplyBossButtonVisual(button, button.BossIndex == activeBossIndex)
                    end
                end
                UpdateGuideText()
            end)

            TabButtons[bossIndex] = tabButton
        end

        tabButton.BossIndex = bossIndex
        tabButton.Text:SetText(GetBossName(bossData))

        -- Buttonbreite an Textlänge anpassen
        local btnW = math.max(tabButton.Text:GetStringWidth() + 20, 60)

        -- Zeilenumbruch wenn Button nicht mehr in die aktuelle Reihe passt
        if rowX + btnW > PAD_L + availW and rowX > PAD_L then
            rowX = PAD_L
            rowY = rowY - BTN_H - ROW_GAP
        end

        tabButton:ClearAllPoints()
        tabButton:SetPoint("TOPLEFT", BossMenuPanel, "TOPLEFT", rowX, rowY)
        tabButton:SetHeight(BTN_H)
        tabButton:SetWidth(btnW)

        rowX = rowX + btnW + BTN_GAP

        tabButton:Show()
        ApplyBossButtonVisual(tabButton, bossIndex == activeBossIndex)
    end

    -- Panel-Höhe dynamisch: letzte Reihen-Oberkante + Buttonhöhe + Innenabstand
    BossMenuPanel:SetHeight((-rowY) + BTN_H + 4)
end

local function RefreshWindowDropdowns()
    if not CategoryDropdown or not InstanceDropdown then
        return
    end

    UIDropDownMenu_SetSelectedValue(CategoryDropdown, selectedCategory)
    UIDropDownMenu_SetText(CategoryDropdown, selectedCategory == "raid" and L("BOSS_GUIDES_CAT_RAID") or L("BOSS_GUIDES_CAT_DUNGEON"))
    UIDropDownMenu_SetSelectedValue(InstanceDropdown, activeGuideKey or "")

    if activeGuideKey and GUIDE_DATA[activeGuideKey] then
        UIDropDownMenu_SetText(InstanceDropdown, GetGuideTitle(GUIDE_DATA[activeGuideKey]))
    else
        UIDropDownMenu_SetText(InstanceDropdown, L("BOSS_GUIDES_SELECT_INSTANCE"))
    end
end

local function UpdateGuideUi()
    RefreshWindowDropdowns()
    RebuildBossMenu()
    UpdateGuideText()
end

local function IsGuideAvailableInCurrentInstance()
    return ResolveGuideKeyForCurrentInstance() ~= nil
end

local function RefreshOverlayVisibility()
    if not OverlayButton then
        return
    end

    local db = GetBossGuidesSettings()
    local currentGuideKey = ResolveGuideKeyForCurrentInstance()
    local shouldShowButton

    if not db.overlayEnabled then
        shouldShowButton = false
    elseif db.overlayMode == "always" then
        shouldShowButton = true
    else
        shouldShowButton = currentGuideKey ~= nil
    end

    if shouldShowButton then
        if currentGuideKey and currentGuideKey ~= activeGuideKey then
            activeGuideKey = currentGuideKey
            activeBossIndex = 1
            UpdateGuideUi()
        elseif not currentGuideKey and activeGuideKey then
            activeGuideKey = nil
            UpdateGuideUi()
        end
        OverlayButton:Show()
    else
        OverlayButton:Hide()
        GuideWindow:Hide()
        activeGuideKey = nil
    end

    if CurrentInstanceText then
        local instanceName = select(1, GetCurrentInstanceNameAndType())
        if not instanceName or instanceName == "" then
            CurrentInstanceText:SetText(string.format("%s: %s", L("BOSS_GUIDES_CURRENT_INSTANCE"), L("BOSS_GUIDES_NONE")))
        else
            CurrentInstanceText:SetText(string.format("%s: %s", L("BOSS_GUIDES_CURRENT_INSTANCE"), instanceName))
        end
    end
end

local function ApplyOverlayScale()
    local db = GetBossGuidesSettings()
    if OverlayButton then
        OverlayButton:SetScale(db.overlayScale)
    end
    if GuideWindow then
        GuideWindow:SetScale(db.overlayScale)
    end
end

local function ApplyOverlayLockState()
    local db = GetBossGuidesSettings()
    if OverlayButton then
        OverlayButton:SetMovable(db.overlayLocked ~= true)
    end
    if GuideWindow then
        GuideWindow:SetMovable(db.overlayLocked ~= true)
    end
    if PinBtn and PinBtn.RefreshVisual then
        PinBtn.RefreshVisual()
    end
end

local function ApplyFontSize()
    local db = GetBossGuidesSettings()
    local size = db.fontSize

    for _, btn in ipairs(TabButtons) do
        if btn.Text then
            btn.Text:SetFont(FONT_PATH, size, "OUTLINE")
        end
    end

    for _, fs in ipairs(LegendFontStrings) do
        fs:SetFont(FONT_PATH, math.max(size - 1, MIN_FONT_SIZE), "")
    end

    if GuideWindow and GuideWindow:IsShown() then
        UpdateGuideText()
    end
end

function BossGuidesModule.SetOverlayEnabled(enabled)
    GetBossGuidesSettings().overlayEnabled = enabled == true
    RefreshOverlayVisibility()
end

function BossGuidesModule.IsOverlayEnabled()
    return GetBossGuidesSettings().overlayEnabled == true
end

function BossGuidesModule.SetOverlayLocked(locked)
    GetBossGuidesSettings().overlayLocked = locked == true
    ApplyOverlayLockState()
end

function BossGuidesModule.IsOverlayLocked()
    return GetBossGuidesSettings().overlayLocked == true
end

function BossGuidesModule.SetOverlayScale(scale)
    GetBossGuidesSettings().overlayScale = Clamp(scale or DEFAULT_SCALE, MIN_SCALE, MAX_SCALE)
    ApplyOverlayScale()
end

function BossGuidesModule.GetOverlayScale()
    return GetBossGuidesSettings().overlayScale
end

function BossGuidesModule.SetFontSize(size)
    GetBossGuidesSettings().fontSize = Clamp(size or DEFAULT_FONT_SIZE, MIN_FONT_SIZE, MAX_FONT_SIZE)
    ApplyFontSize()
end

function BossGuidesModule.GetFontSize()
    return GetBossGuidesSettings().fontSize
end

function BossGuidesModule.ResetPositions()
    local db = GetBossGuidesSettings()

    db.point = DEFAULT_POINT
    db.relativePoint = DEFAULT_RELATIVE_POINT
    db.offsetX = DEFAULT_OFFSET_X
    db.offsetY = DEFAULT_OFFSET_Y

    db.windowPoint = DEFAULT_WINDOW_POINT
    db.windowRelativePoint = DEFAULT_WINDOW_RELATIVE_POINT
    db.windowOffsetX  = DEFAULT_WINDOW_OFFSET_X
    db.windowOffsetY  = DEFAULT_WINDOW_OFFSET_Y
    db.windowWidth    = DEFAULT_WINDOW_WIDTH
    db.windowHeight   = DEFAULT_WINDOW_HEIGHT

    ApplyOverlayButtonGeometry()
    ApplyGuideWindowGeometry()
end

local function CreateOverlayFrames()
    if OverlayButton and GuideWindow then
        return
    end

    -- Toggle-Button (klein, positionierbar)
    OverlayButton = CreateFrame("Button", "BeavisQoLBossGuidesToggle", UIParent, "UIPanelButtonTemplate")
    OverlayButton:SetSize(164, 28)
    OverlayButton:SetText(L("BOSS_GUIDES_BUTTON"))
    OverlayButton:SetClampedToScreen(true)
    OverlayButton:SetMovable(true)
    OverlayButton:EnableMouse(true)
    OverlayButton:RegisterForDrag("LeftButton")
    OverlayButton:SetFrameStrata("HIGH")
    OverlayButton:SetScript("OnDragStart", function(self)
        if BossGuidesModule.IsOverlayLocked() then return end
        self:StartMoving()
    end)
    OverlayButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveOverlayButtonGeometry()
    end)

    -- Hauptfenster – komplett framelos/transparent wie eine WeakAura
    GuideWindow = CreateFrame("Frame", "BeavisQoLBossGuidesWindow", UIParent)
    GuideWindow:SetSize(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT)
    GuideWindow:SetClampedToScreen(true)
    GuideWindow:SetMovable(true)
    GuideWindow:SetResizable(true)
    GuideWindow:SetResizeBounds(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
    GuideWindow:EnableMouse(true)
    GuideWindow:RegisterForDrag("LeftButton")
    GuideWindow:SetFrameStrata("DIALOG")
    GuideWindow:Hide()

    GuideWindow:SetScript("OnDragStart", function(self)
        if BossGuidesModule.IsOverlayLocked() then return end
        self:StartMoving()
    end)
    GuideWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveGuideWindowGeometry()
    end)

    -- Sehr dezenter transparenter Hintergrund (WeakAura-Stil)
    local bg = GuideWindow:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.04, 0.07, 0.55)

    -- 1px Teal-Linie oben
    local lineTop = GuideWindow:CreateTexture(nil, "ARTWORK")
    lineTop:SetPoint("TOPLEFT", GuideWindow, "TOPLEFT", 0, 0)
    lineTop:SetPoint("TOPRIGHT", GuideWindow, "TOPRIGHT", 0, 0)
    lineTop:SetHeight(1)
    lineTop:SetColorTexture(0.26, 0.75, 0.63, 0.80)

    -- 1px Teal-Linie unten
    local lineBottom = GuideWindow:CreateTexture(nil, "ARTWORK")
    lineBottom:SetPoint("BOTTOMLEFT", GuideWindow, "BOTTOMLEFT", 0, 0)
    lineBottom:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 0)
    lineBottom:SetHeight(1)
    lineBottom:SetColorTexture(0.26, 0.75, 0.63, 0.40)

    -- Kopfzeile: Dropdowns + minimaler Schließen-Button, kein Hintergrund
    local headerRow = CreateFrame("Frame", nil, GuideWindow)
    headerRow:SetPoint("TOPLEFT", GuideWindow, "TOPLEFT", 0, -2)
    headerRow:SetPoint("TOPRIGHT", GuideWindow, "TOPRIGHT", 0, -2)
    headerRow:SetHeight(32)

    CategoryDropdown = CreateFrame("Frame", "BeavisQoLBossGuidesCategoryDropdown", headerRow, "UIDropDownMenuTemplate")
    CategoryDropdown:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 2, -1)
    UIDropDownMenu_SetWidth(CategoryDropdown, 92)

    InstanceDropdown = CreateFrame("Frame", "BeavisQoLBossGuidesInstanceDropdown", headerRow, "UIDropDownMenuTemplate")
    InstanceDropdown:SetPoint("LEFT", CategoryDropdown, "RIGHT", 8, 0)
    UIDropDownMenu_SetWidth(InstanceDropdown, 182)

    UIDropDownMenu_Initialize(CategoryDropdown, function(_, level)
        local categories = {
            { text = L("BOSS_GUIDES_CAT_RAID"),    value = "raid"    },
            { text = L("BOSS_GUIDES_CAT_DUNGEON"), value = "dungeon" },
        }
        for _, cat in ipairs(categories) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = cat.text
            info.value   = cat.value
            info.func    = function()
                selectedCategory = cat.value
                UIDropDownMenu_SetSelectedValue(CategoryDropdown, cat.value)
                activeGuideKey = nil
                activeBossIndex = 1
                UpdateGuideUi()
            end
            info.checked = (selectedCategory == cat.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_Initialize(InstanceDropdown, function(_, level)
        local hasEntries = false
        for guideKey, guideData in pairs(GUIDE_DATA) do
            if guideData.type == selectedCategory then
                hasEntries = true
                local info = UIDropDownMenu_CreateInfo()
                info.text    = GetGuideTitle(guideData)
                info.value   = guideKey
                info.func    = function()
                    activeGuideKey = guideKey
                    activeBossIndex = 1
                    UIDropDownMenu_SetSelectedValue(InstanceDropdown, guideKey)
                    UpdateGuideUi()
                end
                info.checked = (activeGuideKey == guideKey)
                UIDropDownMenu_AddButton(info, level)
            end
        end
        if not hasEntries then
            local info = UIDropDownMenu_CreateInfo()
            info.text         = L("BOSS_GUIDES_NO_INSTANCES")
            info.disabled     = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Klickflächen über die gesamte Dropdown-Breite, nicht nur auf den Pfeil.
    local categoryClickArea = CreateFrame("Button", nil, headerRow)
    categoryClickArea:SetPoint("TOPLEFT", CategoryDropdown, "TOPLEFT", 18, -4)
    categoryClickArea:SetSize(116, 24)
    categoryClickArea:SetScript("OnClick", function()
        ToggleDropDownMenu(1, nil, CategoryDropdown, CategoryDropdown, 16, 0)
    end)

    local instanceClickArea = CreateFrame("Button", nil, headerRow)
    instanceClickArea:SetPoint("TOPLEFT", InstanceDropdown, "TOPLEFT", 18, -4)
    instanceClickArea:SetSize(206, 24)
    instanceClickArea:SetScript("OnClick", function()
        ToggleDropDownMenu(1, nil, InstanceDropdown, InstanceDropdown, 16, 0)
    end)

    -- Header-Buttons rechts: Einstellungen | Pin | Schließen
    local function MakeHeaderIconBtn(parent, texturePath, offsetX)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(20, 20)
        btn:SetPoint("RIGHT", parent, "RIGHT", offsetX, 0)
        btn:SetHitRectInsets(-2, -2, -2, -2)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.26, 0.75, 0.63, 0)
        btn.Bg = bg

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetSize(14, 14)
        icon:SetTexture(texturePath)
        icon:SetVertexColor(0.75, 0.75, 0.75, 1)
        btn.Icon = icon

        btn:SetScript("OnEnter", function(self)
            self.Bg:SetColorTexture(0.26, 0.75, 0.63, 0.14)
            self.Icon:SetVertexColor(0.26, 0.75, 0.63, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self.Bg:SetColorTexture(0.26, 0.75, 0.63, 0)
            if self.RestoreVisual then
                self:RestoreVisual()
            else
                self.Icon:SetVertexColor(0.75, 0.75, 0.75, 1)
            end
        end)

        return btn
    end

    -- Schließen
    local closeBtn = CreateFrame("Button", nil, headerRow)
    closeBtn:SetSize(22, 20)
    closeBtn:SetPoint("RIGHT", headerRow, "RIGHT", -6, 0)
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetAllPoints()
    closeTxt:SetFont(FONT_PATH, 14, "OUTLINE")
    closeTxt:SetText("X")
    closeTxt:SetTextColor(0.55, 0.55, 0.55, 1)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetTextColor(1, 0.30, 0.30, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetTextColor(0.55, 0.55, 0.55, 1) end)
    closeBtn:SetScript("OnClick", function() GuideWindow:Hide() end)

    -- Pin-Button (fixieren): echtes Lock-Icon
    PinBtn = MakeHeaderIconBtn(headerRow, "Interface\\Buttons\\LockButton-Unlocked-Up", -32)
    PinBtn:SetSize(22, 22)
    PinBtn.Icon:SetSize(16, 16)
    local function RefreshPinVisual()
        local locked = BossGuidesModule.IsOverlayLocked()
        if locked then
            PinBtn.Icon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
            PinBtn.Icon:SetVertexColor(1, 0.94, 0.47, 1)
        else
            PinBtn.Icon:SetTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
            PinBtn.Icon:SetVertexColor(0.75, 0.75, 0.75, 1)
        end
    end
    PinBtn.RestoreVisual = function(self)
        if BossGuidesModule.IsOverlayLocked() then
            self.Icon:SetVertexColor(1, 0.94, 0.47, 1)
        else
            self.Icon:SetVertexColor(0.75, 0.75, 0.75, 1)
        end
    end
    PinBtn.RefreshVisual = RefreshPinVisual
    PinBtn:SetScript("OnClick", function()
        BossGuidesModule.SetOverlayLocked(not BossGuidesModule.IsOverlayLocked())
    end)

    -- Einstellungen-Button: echtes Zahnrad-Icon
    local settingsBtn = MakeHeaderIconBtn(headerRow, "Interface\\Buttons\\UI-OptionsButton", -58)
    settingsBtn.Icon:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    settingsBtn:SetScript("OnClick", function()
        BeavisQoL.OpenPage("BossGuides")
    end)

    -- Boss-Tabs: horizontal oben, volle Breite, Höhe dynamisch (1-3 Reihen)
    BossMenuPanel = CreateFrame("Frame", nil, GuideWindow)
    BossMenuPanel:SetPoint("TOPLEFT",  headerRow, "BOTTOMLEFT",  0, -2)
    BossMenuPanel:SetPoint("TOPRIGHT", headerRow, "BOTTOMRIGHT", 0, -2)
    BossMenuPanel:SetHeight(28)  -- Startwert; wird von RebuildBossMenu aktualisiert

    -- Teal-Linie unter der Tab-Leiste
    local menuSep = BossMenuPanel:CreateTexture(nil, "ARTWORK")
    menuSep:SetPoint("BOTTOMLEFT",  BossMenuPanel, "BOTTOMLEFT",  0, 0)
    menuSep:SetPoint("BOTTOMRIGHT", BossMenuPanel, "BOTTOMRIGHT", 0, 0)
    menuSep:SetHeight(1)
    menuSep:SetColorTexture(0.26, 0.75, 0.63, 0.30)

    -- Content-Bereich unterhalb der Tab-Leiste
    ContentScrollFrame = CreateFrame("ScrollFrame", nil, GuideWindow)
    ContentScrollFrame:SetPoint("TOPLEFT",     BossMenuPanel, "BOTTOMLEFT",  8, -4)
    ContentScrollFrame:SetPoint("BOTTOMRIGHT", GuideWindow,   "BOTTOMRIGHT", -8, 4)
    ContentScrollFrame:EnableMouseWheel(true)
    ContentScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local step    = 38
        local cur     = self:GetVerticalScroll()
        local maxVal  = math.max(0, ContentScrollChild:GetHeight() - self:GetHeight())
        local nextVal = cur - (delta * step)
        if nextVal < 0 then nextVal = 0 elseif nextVal > maxVal then nextVal = maxVal end
        self:SetVerticalScroll(nextVal)
    end)

    ContentScrollChild = CreateFrame("Frame", nil, ContentScrollFrame)
    ContentScrollChild:SetSize(ContentScrollFrame:GetWidth(), 1)
    ContentScrollFrame:SetScrollChild(ContentScrollChild)

    ContentScrollFrame:SetScript("OnSizeChanged", function(self)
        ContentScrollChild:SetWidth(self:GetWidth())
        if ContentText then
            ContentText:SetWidth(math.max(self:GetWidth() - 12, 40))
            if GuideWindow and GuideWindow:IsShown() then
                UpdateGuideText()
            end
        end
    end)

    ContentText = CreateFrame("Frame", nil, ContentScrollChild)
    ContentText:SetPoint("TOPLEFT",  ContentScrollChild, "TOPLEFT",  6, -4)
    ContentText:SetPoint("TOPRIGHT", ContentScrollChild, "TOPRIGHT", -6, -4)
    ContentText:SetWidth(math.max(ContentScrollFrame:GetWidth() - 12, 40))
    ContentText:SetHeight(220)

    OverlayButton:SetScript("OnClick", function()
        if GuideWindow:IsShown() then
            GuideWindow:Hide()
        else
            UpdateGuideUi()
            GuideWindow:Show()
        end
    end)

    -- Legende unten (kein eigener Hintergrund)
    local legendBar = CreateFrame("Frame", nil, GuideWindow)
    legendBar:SetPoint("BOTTOMLEFT",  GuideWindow, "BOTTOMLEFT",  0, 2)
    legendBar:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 2)
    legendBar:SetHeight(18)

    local legendItems = {
        { role = "TANK", label = L("BOSS_GUIDES_LEGEND_TANK") },
        { role = "DD",   label = L("BOSS_GUIDES_LEGEND_DD") },
        { role = "HEAL", label = L("BOSS_GUIDES_LEGEND_HEAL") },
        { role = "HC",   label = L("BOSS_GUIDES_LEGEND_HC") },
        { role = "M",    label = L("BOSS_GUIDES_LEGEND_M") },
    }

    local xOff = 8
    for _, item in ipairs(legendItems) do
        local legendEntry = legendBar:CreateFontString(nil, "OVERLAY")
        legendEntry:SetPoint("LEFT", legendBar, "LEFT", xOff, 0)
        legendEntry:SetFont(FONT_PATH, math.max(DEFAULT_FONT_SIZE - 1, MIN_FONT_SIZE), "")
        legendEntry:SetTextColor(0.55, 0.55, 0.55, 1)
        legendEntry:SetText(GetRoleIcon(item.role, 11) .. " " .. item.label)
        xOff = xOff + legendEntry:GetStringWidth() + 14
        table.insert(LegendFontStrings, legendEntry)
    end

    -- Resize-Griff unten rechts
    local resizeGrip = CreateFrame("Button", nil, GuideWindow)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 0)
    resizeGrip:SetFrameLevel(GuideWindow:GetFrameLevel() + 10)
    local gripTxt = resizeGrip:CreateFontString(nil, "OVERLAY")
    gripTxt:SetAllPoints()
    gripTxt:SetFont(FONT_PATH, 14, "")
    gripTxt:SetText("◿")
    gripTxt:SetJustifyH("RIGHT")
    gripTxt:SetJustifyV("BOTTOM")
    gripTxt:SetTextColor(0.26, 0.75, 0.63, 0.45)
    resizeGrip:SetScript("OnEnter",    function() gripTxt:SetTextColor(0.26, 0.75, 0.63, 0.90) end)
    resizeGrip:SetScript("OnLeave",    function() gripTxt:SetTextColor(0.26, 0.75, 0.63, 0.45) end)
    resizeGrip:SetScript("OnMouseDown", function()
        if BossGuidesModule.IsOverlayLocked() then return end
        GuideWindow:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        GuideWindow:StopMovingOrSizing()
        SaveGuideWindowGeometry()
    end)

    ApplyOverlayButtonGeometry()
    ApplyGuideWindowGeometry()
    ApplyOverlayScale()
    ApplyOverlayLockState()
    UpdateGuideUi()
end

local function CreateSlider(parent)
    local slider = CreateFrame("Slider", ADDON_NAME .. "BossGuidesScaleSlider", parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(MIN_SCALE, MAX_SCALE)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(280)

    _G[slider:GetName() .. "Low"]:SetText(string.format("%d%%", math.floor(MIN_SCALE * 100)))
    _G[slider:GetName() .. "High"]:SetText(string.format("%d%%", math.floor(MAX_SCALE * 100)))
    _G[slider:GetName() .. "Text"]:SetText("")

    slider:SetScript("OnValueChanged", function(self, value)
        if isRefreshingPage then
            return
        end

        BossGuidesModule.SetOverlayScale(value)
        if ScaleSliderText then
            ScaleSliderText:SetText(string.format("%s: %s", L("BOSS_GUIDES_SCALE"), GetSliderPercentText(value)))
        end
    end)

    return slider
end

local function CreateSettingsPage()
    PageBossGuides = CreateFrame("Frame", nil, Content)
    PageBossGuides:SetAllPoints()
    PageBossGuides:Hide()

    local introPanel = CreateFrame("Frame", nil, PageBossGuides)
    introPanel:SetPoint("TOPLEFT", PageBossGuides, "TOPLEFT", 20, -20)
    introPanel:SetPoint("TOPRIGHT", PageBossGuides, "TOPRIGHT", -20, -20)
    introPanel:SetHeight(108)

    local introBg = introPanel:CreateTexture(nil, "BACKGROUND")
    introBg:SetAllPoints()
    introBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

    local introBorder = introPanel:CreateTexture(nil, "ARTWORK")
    introBorder:SetPoint("BOTTOMLEFT", introPanel, "BOTTOMLEFT", 0, 0)
    introBorder:SetPoint("BOTTOMRIGHT", introPanel, "BOTTOMRIGHT", 0, 0)
    introBorder:SetHeight(1)
    introBorder:SetColorTexture(1, 0.82, 0, 0.9)

    local introTitle = introPanel:CreateFontString(nil, "OVERLAY")
    introTitle:SetPoint("TOPLEFT", introPanel, "TOPLEFT", 18, -14)
    introTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    introTitle:SetTextColor(1, 0.82, 0, 1)
    introTitle:SetText(L("BOSS_GUIDES"))

    local introText = introPanel:CreateFontString(nil, "OVERLAY")
    introText:SetPoint("TOPLEFT", introTitle, "BOTTOMLEFT", 0, -10)
    introText:SetPoint("RIGHT", introPanel, "RIGHT", -18, 0)
    introText:SetJustifyH("LEFT")
    introText:SetJustifyV("TOP")
    introText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    introText:SetTextColor(1, 1, 1, 1)
    introText:SetText(L("BOSS_GUIDES_DESC"))

    local settingsPanel = CreateFrame("Frame", nil, PageBossGuides)
    settingsPanel:SetPoint("TOPLEFT", introPanel, "BOTTOMLEFT", 0, -18)
    settingsPanel:SetPoint("TOPRIGHT", introPanel, "BOTTOMRIGHT", 0, -18)
    settingsPanel:SetHeight(296)

    local settingsBg = settingsPanel:CreateTexture(nil, "BACKGROUND")
    settingsBg:SetAllPoints()
    settingsBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

    local settingsBorder = settingsPanel:CreateTexture(nil, "ARTWORK")
    settingsBorder:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT", 0, 0)
    settingsBorder:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", 0, 0)
    settingsBorder:SetHeight(1)
    settingsBorder:SetColorTexture(1, 0.82, 0, 0.9)

    local settingsTitle = settingsPanel:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 18, -14)
    settingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    settingsTitle:SetTextColor(1, 0.82, 0, 1)
    settingsTitle:SetText(L("BOSS_GUIDES_SETTINGS"))

    ShowOverlayCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
    ShowOverlayCheckbox:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", -4, -10)

    local showOverlayLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    showOverlayLabel:SetPoint("LEFT", ShowOverlayCheckbox, "RIGHT", 6, 0)
    showOverlayLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    showOverlayLabel:SetTextColor(1, 1, 1, 1)
    showOverlayLabel:SetText(L("BOSS_GUIDES_SHOW_OVERLAY"))

    local overlayModeLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    overlayModeLabel:SetPoint("TOPLEFT", ShowOverlayCheckbox, "BOTTOMLEFT", 34, -8)
    overlayModeLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    overlayModeLabel:SetTextColor(1, 0.82, 0, 1)
    overlayModeLabel:SetText(L("BOSS_GUIDES_OVERLAY_MODE"))

    OverlayModeDropdown = CreateFrame("Frame", "BeavisQoLBossGuidesOverlayModeDropdown", settingsPanel, "UIDropDownMenuTemplate")
    OverlayModeDropdown:SetPoint("TOPLEFT", overlayModeLabel, "BOTTOMLEFT", -18, -2)
    UIDropDownMenu_SetWidth(OverlayModeDropdown, 200)

    LockOverlayCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
    LockOverlayCheckbox:SetPoint("TOPLEFT", OverlayModeDropdown, "BOTTOMLEFT", 18, -4)

    local lockOverlayLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    lockOverlayLabel:SetPoint("LEFT", LockOverlayCheckbox, "RIGHT", 6, 0)
    lockOverlayLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    lockOverlayLabel:SetTextColor(1, 1, 1, 1)
    lockOverlayLabel:SetText(L("BOSS_GUIDES_LOCK_OVERLAY"))

    ScaleSliderText = settingsPanel:CreateFontString(nil, "OVERLAY")
    ScaleSliderText:SetPoint("TOPLEFT", LockOverlayCheckbox, "BOTTOMLEFT", 34, -16)
    ScaleSliderText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    ScaleSliderText:SetTextColor(0.92, 0.92, 0.95, 1)

    ScaleSlider = CreateSlider(settingsPanel)
    ScaleSlider:SetPoint("TOPLEFT", ScaleSliderText, "BOTTOMLEFT", 0, -12)

    FontSizeSliderText = settingsPanel:CreateFontString(nil, "OVERLAY")
    FontSizeSliderText:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 0, -16)
    FontSizeSliderText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    FontSizeSliderText:SetTextColor(0.92, 0.92, 0.95, 1)

    FontSizeSlider = CreateFrame("Slider", ADDON_NAME .. "BossGuidesFontSizeSlider", settingsPanel, "OptionsSliderTemplate")
    FontSizeSlider:SetPoint("TOPLEFT", FontSizeSliderText, "BOTTOMLEFT", 0, -12)
    FontSizeSlider:SetMinMaxValues(MIN_FONT_SIZE, MAX_FONT_SIZE)
    FontSizeSlider:SetValueStep(1)
    FontSizeSlider:SetObeyStepOnDrag(true)
    FontSizeSlider:SetWidth(280)
    _G[FontSizeSlider:GetName() .. "Low"]:SetText(tostring(MIN_FONT_SIZE))
    _G[FontSizeSlider:GetName() .. "High"]:SetText(tostring(MAX_FONT_SIZE))
    _G[FontSizeSlider:GetName() .. "Text"]:SetText("")
    FontSizeSlider:SetScript("OnValueChanged", function(self, value)
        if isRefreshingPage then
            return
        end
        value = math.floor(value + 0.5)
        BossGuidesModule.SetFontSize(value)
        if FontSizeSliderText then
            FontSizeSliderText:SetText(string.format("%s: %d", L("BOSS_GUIDES_FONT_SIZE"), value))
        end
    end)

    local resetButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    resetButton:SetSize(188, 24)
    resetButton:SetPoint("TOPLEFT", FontSizeSlider, "BOTTOMLEFT", -8, -16)
    resetButton:SetText(L("BOSS_GUIDES_RESET_POSITION"))

    CurrentInstanceText = settingsPanel:CreateFontString(nil, "OVERLAY")
    CurrentInstanceText:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -12)
    CurrentInstanceText:SetPoint("RIGHT", settingsPanel, "RIGHT", -18, 0)
    CurrentInstanceText:SetJustifyH("LEFT")
    CurrentInstanceText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    CurrentInstanceText:SetTextColor(0.80, 0.80, 0.80, 1)

    ShowOverlayCheckbox:SetScript("OnClick", function(self)
        BossGuidesModule.SetOverlayEnabled(self:GetChecked())
        PageBossGuides:RefreshState()
    end)

    LockOverlayCheckbox:SetScript("OnClick", function(self)
        BossGuidesModule.SetOverlayLocked(self:GetChecked())
        PageBossGuides:RefreshState()
    end)

    resetButton:SetScript("OnClick", function()
        BossGuidesModule.ResetPositions()
        PageBossGuides:RefreshState()
    end)

    UIDropDownMenu_Initialize(OverlayModeDropdown, function(_, level)
        local options = {
            { text = L("BOSS_GUIDES_MODE_INSTANCE"), value = "instance_only" },
            { text = L("BOSS_GUIDES_MODE_ALWAYS"), value = "always" },
        }

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function()
                local db2 = GetBossGuidesSettings()
                db2.overlayMode = option.value
                UIDropDownMenu_SetSelectedValue(OverlayModeDropdown, option.value)
                RefreshOverlayVisibility()
            end
            info.checked = (GetBossGuidesSettings().overlayMode == option.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function PageBossGuides:RefreshState()
        local db = GetBossGuidesSettings()
        isRefreshingPage = true

        ShowOverlayCheckbox:SetChecked(db.overlayEnabled)
        UIDropDownMenu_SetSelectedValue(OverlayModeDropdown, db.overlayMode)
        UIDropDownMenu_SetText(OverlayModeDropdown, db.overlayMode == "always" and L("BOSS_GUIDES_MODE_ALWAYS") or L("BOSS_GUIDES_MODE_INSTANCE"))
        LockOverlayCheckbox:SetChecked(db.overlayLocked)
        ScaleSlider:SetValue(db.overlayScale)
        ScaleSliderText:SetText(string.format("%s: %s", L("BOSS_GUIDES_SCALE"), GetSliderPercentText(db.overlayScale)))
        FontSizeSlider:SetValue(db.fontSize)
        FontSizeSliderText:SetText(string.format("%s: %d", L("BOSS_GUIDES_FONT_SIZE"), db.fontSize))

        isRefreshingPage = false
        RefreshOverlayVisibility()
    end

    PageBossGuides:SetScript("OnShow", function()
        PageBossGuides:RefreshState()
    end)

    BeavisQoL.Pages.BossGuides = PageBossGuides
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        GetBossGuidesSettings()
        CreateOverlayFrames()
        CreateSettingsPage()
        ApplyOverlayButtonGeometry()
        ApplyGuideWindowGeometry()
        ApplyOverlayScale()
        ApplyOverlayLockState()
        ApplyFontSize()
    end

    RefreshOverlayVisibility()

    if GuideWindow and GuideWindow:IsShown() and activeGuideKey then
        UpdateGuideUi()
    end
end)
