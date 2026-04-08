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

local GUIDE_WINDOW_ATTACH_POINT = "TOPLEFT"
local GUIDE_WINDOW_ATTACH_RELATIVE_POINT = "BOTTOMLEFT"
local GUIDE_WINDOW_ATTACH_OFFSET_X = 0
local GUIDE_WINDOW_ATTACH_OFFSET_Y = -2

local DEFAULT_SCALE = 1.00
local MIN_SCALE = 0.80
local MAX_SCALE = 1.40

local DEFAULT_WINDOW_WIDTH  = 980
local DEFAULT_WINDOW_HEIGHT = 360
local MIN_WINDOW_WIDTH      = 760
local MIN_WINDOW_HEIGHT     = 180

local DEFAULT_FONT_SIZE = 10
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 18

local GUIDE_TILE_MIN_WIDTH = 132
local GUIDE_TILE_MAX_WIDTH = 180
local GUIDE_TILE_MIN_IMAGE_HEIGHT = 76
local GUIDE_TILE_IMAGE_ASPECT_RATIO = 2.10
local GUIDE_TILE_TITLE_OVERLAY_HEIGHT = 30
local GUIDE_TILE_CARD_LEFT_CROP = 0.04
local GUIDE_TILE_CARD_RIGHT_CROP = 0.96
local GUIDE_TILE_CARD_TOP_CROP = 0.02
local GUIDE_TILE_CARD_BOTTOM_CROP = 0.60
local GUIDE_TILE_FULL_LEFT_CROP = 0.02
local GUIDE_TILE_FULL_RIGHT_CROP = 0.98
local GUIDE_TILE_FULL_TOP_CROP = 0.02
local GUIDE_TILE_FULL_BOTTOM_CROP = 0.98
local GUIDE_WINDOW_HOME_CHROME_HEIGHT = 52
local GUIDE_WINDOW_GUIDE_CHROME_HEIGHT = 60
local GUIDE_WINDOW_ATTACH_MARGIN = 12
local GUIDE_WINDOW_ATTACH_OFFSET_Y_ABOVE = 2
local HOME_WINDOW_MIN_WIDTH = 500
local HOME_WINDOW_PREFERRED_WIDTH = 540
local HOME_TILE_GAP = 8
local HOME_SECTION_GAP = 18
local HOME_SECTION_TITLE_SPACING = 10

local FONT_PATH = "Interface\\AddOns\\BeavisQoL\\Media\\Fonts\\Expressway.ttf"
local GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B = 0.01, 0.01, 0.02
local GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B = 0.30, 0.30, 0.34

local HOME_CATEGORY_ORDER = {
    { type = "raid", titleKey = "BOSS_GUIDES_HOME_CATEGORY_RAIDS" },
    { type = "dungeon", titleKey = "BOSS_GUIDES_HOME_CATEGORY_DUNGEONS" },
}

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
    march_on_queldanas = {
        titleKey = "BOSS_GUIDES_INSTANCE_MARCH_ON_QUEL_DANAS_TITLE",
        type = "raid",
        matchTokensKey = "BOSS_GUIDES_INSTANCE_MARCH_ON_QUEL_DANAS_TOKENS",
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_BELOREN_CHILD_OF_ALAR_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_BELOREN_CHILD_OF_ALAR_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_MIDNIGHT_FALLS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_MIDNIGHT_FALLS_BODY",
            },
        },
    },
    windrunner_spire = {
        titleKey = "BOSS_GUIDES_INSTANCE_WINDRUNNER_SPIRE_TITLE",
        type = "dungeon",
        sortOrder = 4,
        matchTokens = { "windrunner spire", "windlaeuferturm", "windläuferturm" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_DAEMMERGLUT_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_DAEMMERGLUT_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_HERUNTERGEKOMMENES_DUO_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_HERUNTERGEKOMMENES_DUO_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_COMMANDER_KROLUK_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_COMMANDER_KROLUK_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_DAS_RASTLOSE_HERZ_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_DAS_RASTLOSE_HERZ_BODY",
            },
        },
    },
    magisters_terrace = {
        titleKey = "BOSS_GUIDES_INSTANCE_MAGISTERS_TERRACE_TITLE",
        type = "dungeon",
        sortOrder = 3,
        matchTokens = { "magisters terrace", "magisterterrasse", "terrasse der magister" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_ARKANOTRONWAECHTER_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_ARKANOTRONWAECHTER_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_SERANEL_SONNENPEITSCHE_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_SERANEL_SONNENPEITSCHE_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_GEMELLUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_GEMELLUS_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_DEGENTRIUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_DEGENTRIUS_BODY",
            },
        },
    },
    algethar_academy = {
        titleKey = "BOSS_GUIDES_INSTANCE_ALGETHAR_ACADEMY_TITLE",
        type = "dungeon",
        sortOrder = 5,
        matchTokens = { "algethar academy", "akademie von algeth'ar", "akademie von algethar", "algethar" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_UEBERWUCHERTES_URTUM_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_UEBERWUCHERTES_URTUM_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_KRAAS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_KRAAS_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_VEXAMUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_VEXAMUS_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_ECHO_OF_DORAGOSA_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_ECHO_OF_DORAGOSA_BODY",
            },
        },
    },
    pit_of_saron = {
        titleKey = "BOSS_GUIDES_INSTANCE_PIT_OF_SARON_TITLE",
        type = "dungeon",
        sortOrder = 6,
        matchTokens = { "pit of saron", "grube von saron" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_FORGEMASTER_GARFROST_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_FORGEMASTER_GARFROST_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_ICK_AND_KRICK_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_ICK_AND_KRICK_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_SCOURGELORD_TYRANNUS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_SCOURGELORD_TYRANNUS_BODY",
            },
        },
    },
    maisara_caverns = {
        titleKey = "BOSS_GUIDES_INSTANCE_MAISARA_CAVERNS_TITLE",
        type = "dungeon",
        sortOrder = 1,
        matchTokens = { "maisara caverns", "maisara hoehlen", "maisara höhlen", "maisarakavernen" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_MUROJIN_NEKRAXX_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_MUROJIN_NEKRAXX_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_VORDAZA_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_VORDAZA_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_RAKTUL_VESSEL_OF_SOULS_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_RAKTUL_VESSEL_OF_SOULS_BODY",
            },
        },
    },
    skyreach = {
        titleKey = "BOSS_GUIDES_INSTANCE_SKYREACH_TITLE",
        type = "dungeon",
        sortOrder = 7,
        matchTokens = { "skyreach", "himmelsnadel" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_RANJIT_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_RANJIT_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_ARAKNATH_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_ARAKNATH_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_RUKHRAN_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_RUKHRAN_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_HIGH_SAGE_VIRYX_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_HIGH_SAGE_VIRYX_BODY",
            },
        },
    },
    seat_of_the_triumvirate = {
        titleKey = "BOSS_GUIDES_INSTANCE_SEAT_OF_THE_TRIUMVIRATE_TITLE",
        type = "dungeon",
        sortOrder = 8,
        matchTokens = { "seat of the triumvirate", "sitz des triumvirats", "triumvirate" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_ZURAAL_THE_ASCENDED_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_ZURAAL_THE_ASCENDED_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_SARPUSH_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_SARPUSH_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_VICEROY_NEZHAR_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_VICEROY_NEZHAR_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_LURA_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_LURA_BODY",
            },
        },
    },
    nexus_point_xenas = {
        titleKey = "BOSS_GUIDES_INSTANCE_NEXUS_POINT_XENAS_TITLE",
        type = "dungeon",
        sortOrder = 2,
        matchTokens = { "nexus point xenas", "nexuspunkt xenas" },
        bosses = {
            {
                nameKey = "BOSS_GUIDES_BOSS_OBERSTER_KERNBAUER_KASRETH_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_OBERSTER_KERNBAUER_KASRETH_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_KERNWAECHTERIN_NYSARRA_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_KERNWAECHTERIN_NYSARRA_BODY",
            },
            {
                nameKey = "BOSS_GUIDES_BOSS_LOTHRAXION_NAME",
                bodyKey = "BOSS_GUIDES_BOSS_LOTHRAXION_BODY",
            },
        },
    },
}

local OverlayButton
local GuideWindow
local GuideHomePanel
local BossMenuPanel
local LegendBar
local ContentScrollFrame
local ContentScrollChild
local ContentText
local ContentScrollbar
local CategoryDropdown
local InstanceDropdown
local TabButtons = {}
local isRefreshingPage = false
local activeGuideKey = nil
local activeBossIndex = 1
local selectedCategory = "raid"
local isUpdatingContentScrollbar = false
local CONTENT_SCROLLBAR_WIDTH = 10
local CONTENT_SCROLLBAR_GAP = 6

local PageBossGuides
local ShowOverlayCheckbox
local OverlayModeDropdown
local LockOverlayCheckbox
local ScaleSlider
local ScaleSliderText
local FontSizeSlider
local FontSizeSliderText
local CurrentInstanceText
local GuideWindowTitleText
local LegendFontStrings = {}
local PinBtn
local GuideTextSegments = {}
local GuideSpellButtons = {}
local GuideSectionButtons = {}
local GuideHomeTitleText
local GuideHomeBodyText
local GuideHomeSectionTitle
local GuideHomeEmptyText
local GuideHomeTiles = {}
local GuideHomeSections = {}
local GuideSectionExpansionState = {}
local GetBossGuidesSettings
local GuideJournalInfoCache = {}
local activeGuideSource = nil
local UpdateGuideUi
local UpdateGuideText
local AutoSizeGuideWindow
local GetGuideTitle
local GetGuideTileTexture
local GetSortedGuideKeys
local SetActiveGuide
local IsGuideSectionExpanded
local SetGuideSectionExpanded
local GetGuideSectionLabel
local ParseGuideBodySections
local CurrentGuideContentHeight = 220
local GuideHomeContentHeight = 0
local isAutoSizingGuideWindow = false

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function GetGuideTileHeight(tileWidth)
    return math.max(GUIDE_TILE_MIN_IMAGE_HEIGHT, math.floor((tileWidth / GUIDE_TILE_IMAGE_ASPECT_RATIO) + 0.5))
end

local function GetFrameBoundsInUiParent(frame)
    if not frame or not UIParent then
        return nil
    end

    local left, right = frame:GetLeft(), frame:GetRight()
    local top, bottom = frame:GetTop(), frame:GetBottom()
    if not left or not right or not top or not bottom then
        return nil
    end

    local uiScale = math.max(UIParent:GetEffectiveScale() or 1, 0.01)
    local frameScale = frame:GetEffectiveScale() or uiScale
    local scaleFactor = frameScale / uiScale

    return left * scaleFactor, right * scaleFactor, top * scaleFactor, bottom * scaleFactor
end

local function GetGuideWindowMaxWidth()
    if not UIParent then
        return DEFAULT_WINDOW_WIDTH
    end

    local scale = GuideWindow and GuideWindow:GetScale() or DEFAULT_SCALE
    scale = math.max(scale, 0.01)

    return math.max(MIN_WINDOW_WIDTH, math.floor(((UIParent:GetWidth() - (GUIDE_WINDOW_ATTACH_MARGIN * 2)) / scale) + 0.5))
end

local function GetGuideWindowAttachment(targetWidth, targetHeight)
    local scale = GuideWindow and GuideWindow:GetScale() or DEFAULT_SCALE
    scale = math.max(scale, 0.01)
    local defaultMaxHeight = math.max(MIN_WINDOW_HEIGHT, math.floor((((UIParent and UIParent:GetHeight()) or DEFAULT_WINDOW_HEIGHT) - (GUIDE_WINDOW_ATTACH_MARGIN * 2)) / scale))
    if not UIParent or not OverlayButton then
        return {
            point = DEFAULT_WINDOW_POINT,
            relativePoint = DEFAULT_WINDOW_RELATIVE_POINT,
            offsetX = DEFAULT_WINDOW_OFFSET_X,
            offsetY = DEFAULT_WINDOW_OFFSET_Y,
            maxHeight = defaultMaxHeight,
        }
    end

    local left, right, top, bottom = GetFrameBoundsInUiParent(OverlayButton)
    if not left or not right or not top or not bottom then
        return {
            point = DEFAULT_WINDOW_POINT,
            relativePoint = DEFAULT_WINDOW_RELATIVE_POINT,
            offsetX = DEFAULT_WINDOW_OFFSET_X,
            offsetY = DEFAULT_WINDOW_OFFSET_Y,
            maxHeight = defaultMaxHeight,
        }
    end

    local desiredWidth = math.max(targetWidth or DEFAULT_WINDOW_WIDTH, MIN_WINDOW_WIDTH)
    local desiredHeight = math.max(targetHeight or DEFAULT_WINDOW_HEIGHT, MIN_WINDOW_HEIGHT)
    local uiWidth = UIParent:GetWidth() or desiredWidth
    local uiHeight = UIParent:GetHeight() or desiredHeight

    local spaceToRight = math.max(0, uiWidth - left - GUIDE_WINDOW_ATTACH_MARGIN) / scale
    local spaceToLeft = math.max(0, right - GUIDE_WINDOW_ATTACH_MARGIN) / scale
    local alignLeft = spaceToRight >= desiredWidth or spaceToRight >= spaceToLeft

    local spaceBelow = math.max(0, bottom - GUIDE_WINDOW_ATTACH_MARGIN - math.abs(GUIDE_WINDOW_ATTACH_OFFSET_Y)) / scale
    local spaceAbove = math.max(0, uiHeight - top - GUIDE_WINDOW_ATTACH_MARGIN - GUIDE_WINDOW_ATTACH_OFFSET_Y_ABOVE) / scale
    local anchorBelow = spaceBelow >= desiredHeight or spaceBelow >= spaceAbove

    if anchorBelow then
        return {
            point = alignLeft and "TOPLEFT" or "TOPRIGHT",
            relativePoint = alignLeft and "BOTTOMLEFT" or "BOTTOMRIGHT",
            offsetX = 0,
            offsetY = GUIDE_WINDOW_ATTACH_OFFSET_Y,
            maxHeight = math.max(MIN_WINDOW_HEIGHT, math.floor(spaceBelow + 0.5)),
        }
    end

    return {
        point = alignLeft and "BOTTOMLEFT" or "BOTTOMRIGHT",
        relativePoint = alignLeft and "TOPLEFT" or "TOPRIGHT",
        offsetX = 0,
        offsetY = GUIDE_WINDOW_ATTACH_OFFSET_Y_ABOVE,
        maxHeight = math.max(MIN_WINDOW_HEIGHT, math.floor(spaceAbove + 0.5)),
    }
end

local function AttachGuideWindowToOverlayButton(targetWidth, targetHeight)
    if not GuideWindow then
        return nil
    end

    local attachment = GetGuideWindowAttachment(targetWidth or GuideWindow:GetWidth(), targetHeight or GuideWindow:GetHeight())
    GuideWindow:ClearAllPoints()

    if OverlayButton then
        GuideWindow:SetPoint(attachment.point, OverlayButton, attachment.relativePoint, attachment.offsetX, attachment.offsetY)
    else
        GuideWindow:SetPoint(attachment.point, UIParent, attachment.relativePoint, attachment.offsetX, attachment.offsetY)
    end

    return attachment
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
    "Dark Uproar",
    "Black Miasma",
    "Blackening Wounds",
    "Cosmic Shell",
    "Void Marked",
    "Pitch Bulwark",
    "Void Fall",
    "Rising Darkness",
    "Dark Resilience",
    "Overpowering Pulse",
    "Blisterburst",
    "Void Breath",
    "Primordial Roar",
    "Creep Spit",
    "Shadowclaw Slash",
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
    "Umbral Collapse",
    "March of the Endless",
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

local function GetSpellSearchEntries()
    local entries = {}
    local seenAliases = {}
    local centralMap = GetCentralSpellNameMap()
    local processedSpellNames = {}

    local function AddAlias(aliasText, englishSpellName)
        if type(aliasText) ~= "string" or aliasText == "" then
            return
        end

        local normalizedAlias = string.lower(aliasText)
        if seenAliases[normalizedAlias] then
            return
        end

        seenAliases[normalizedAlias] = true
        entries[#entries + 1] = {
            alias = aliasText,
            englishName = englishSpellName,
        }
    end

    local function AddMapEntryAliases(canonicalSpellName, mapEntry)
        AddAlias(canonicalSpellName, canonicalSpellName)

        if type(mapEntry) == "table" then
            AddAlias(mapEntry.localizedName or mapEntry.name, canonicalSpellName)
            AddAlias(mapEntry.englishName, canonicalSpellName)

            if type(mapEntry.aliases) == "table" then
                for _, aliasText in ipairs(mapEntry.aliases) do
                    AddAlias(aliasText, canonicalSpellName)
                end
            end
        elseif type(mapEntry) == "string" then
            AddAlias(mapEntry, canonicalSpellName)
        end
    end

    local function GetMapEntryPriority(canonicalSpellName)
        local mapEntry = centralMap[canonicalSpellName]
        if type(mapEntry) == "table" then
            if tonumber(mapEntry.spellID or mapEntry.id) then
                return 1
            end

            return 2
        end

        return 3
    end

    local function AddCanonicalSpellEntry(canonicalSpellName)
        if processedSpellNames[canonicalSpellName] then
            return
        end

        processedSpellNames[canonicalSpellName] = true
        AddMapEntryAliases(canonicalSpellName, centralMap[canonicalSpellName])
    end

    for _, englishSpellName in ipairs(KNOWN_SPELL_NAMES) do
        AddCanonicalSpellEntry(englishSpellName)
    end

    local remainingSpellNames = {}
    for canonicalSpellName in pairs(centralMap) do
        if not processedSpellNames[canonicalSpellName] then
            remainingSpellNames[#remainingSpellNames + 1] = canonicalSpellName
        end
    end

    table.sort(remainingSpellNames, function(a, b)
        local priorityA = GetMapEntryPriority(a)
        local priorityB = GetMapEntryPriority(b)

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end

        return a < b
    end)

    for _, canonicalSpellName in ipairs(remainingSpellNames) do
        AddCanonicalSpellEntry(canonicalSpellName)
    end

    table.sort(entries, function(a, b)
        if #a.alias == #b.alias then
            return a.alias < b.alias
        end

        return #a.alias > #b.alias
    end)

    return entries
end

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
    local mappedIconID
    local spellNameCandidates = {}
    local seenSpellNameCandidates = {}
    local fallbackTooltipText
    local fallbackTooltipKind = "Guide-Begriff"
    local skipClientLookup = false

    local function AddSpellNameCandidate(candidate)
        if type(candidate) ~= "string" or candidate == "" or seenSpellNameCandidates[candidate] then
            return
        end

        seenSpellNameCandidates[candidate] = true
        spellNameCandidates[#spellNameCandidates + 1] = candidate
    end

    if type(mapEntry) == "table" then
        mappedSpellID = tonumber(mapEntry.spellID or mapEntry.id)
        mappedIconID = tonumber(mapEntry.iconID or mapEntry.icon)
        localizedSpellName = mapEntry.localizedName or mapEntry.name or englishSpellName
        fallbackTooltipText = mapEntry.tooltipText
        fallbackTooltipKind = mapEntry.tooltipKind or mapEntry.kind or fallbackTooltipKind
        skipClientLookup = mapEntry.skipClientLookup == true
        AddSpellNameCandidate(mapEntry.localizedName)
        AddSpellNameCandidate(mapEntry.name)
        AddSpellNameCandidate(mapEntry.englishName)

        if type(mapEntry.aliases) == "table" then
            for _, aliasText in ipairs(mapEntry.aliases) do
                AddSpellNameCandidate(aliasText)
            end
        end
    elseif type(mapEntry) == "string" then
        localizedSpellName = mapEntry
        AddSpellNameCandidate(mapEntry)
    end

    AddSpellNameCandidate(localizedSpellName)
    AddSpellNameCandidate(englishSpellName)

    local info
    local spellLink
    local resolvedIconID = mappedIconID

    if not skipClientLookup and mappedSpellID and C_Spell and C_Spell.GetSpellInfo then
        info = C_Spell.GetSpellInfo(mappedSpellID)
    end

    if not skipClientLookup and mappedSpellID and C_Spell and C_Spell.GetSpellLink then
        spellLink = C_Spell.GetSpellLink(mappedSpellID)
    end

    if not skipClientLookup and C_Spell and C_Spell.GetSpellInfo then
        for _, candidate in ipairs(spellNameCandidates) do
            info = info or C_Spell.GetSpellInfo(candidate)
            if info then
                break
            end
        end
    end

    if not skipClientLookup and C_Spell and C_Spell.GetSpellLink then
        for _, candidate in ipairs(spellNameCandidates) do
            spellLink = spellLink or C_Spell.GetSpellLink(candidate)
            if spellLink then
                break
            end
        end
    end

    local spellID = mappedSpellID or (info and info.spellID) or ParseSpellIDFromLink(spellLink)
    if not skipClientLookup and spellID and C_Spell and C_Spell.GetSpellInfo then
        info = info or C_Spell.GetSpellInfo(spellID)
    end

    if not skipClientLookup and spellID and not spellLink and C_Spell and C_Spell.GetSpellLink then
        spellLink = C_Spell.GetSpellLink(spellID)
    end

    if not resolvedIconID and C_Spell and C_Spell.GetSpellInfo then
        local iconInfo

        if mappedSpellID then
            iconInfo = C_Spell.GetSpellInfo(mappedSpellID)
        end

        if not iconInfo then
            for _, candidate in ipairs(spellNameCandidates) do
                iconInfo = C_Spell.GetSpellInfo(candidate)
                if iconInfo and iconInfo.iconID then
                    break
                end
            end
        end

        resolvedIconID = iconInfo and iconInfo.iconID or nil
    end

    local renderInfo = {
        englishName = englishSpellName,
        localizedName = (info and info.name) or localizedSpellName,
        spellID = spellID,
        iconID = resolvedIconID or (info and info.iconID) or nil,
        spellLink = spellLink,
        isResolved = spellID ~= nil or (type(spellLink) == "string" and spellLink ~= ""),
        hasFallbackTooltip = type(fallbackTooltipText) == "string" and fallbackTooltipText ~= "",
        fallbackTooltipKind = fallbackTooltipKind,
        fallbackTooltipText = fallbackTooltipText,
    }

    SPELL_RENDER_CACHE[englishSpellName] = renderInfo
    return renderInfo
end

local function AddPlainTextSegments(segments, text)
    if type(text) ~= "string" or text == "" then
        return
    end

    local tokenCount = 0
    for token in text:gmatch("%s*%S+") do
        tokenCount = tokenCount + 1
        table.insert(segments, {
            kind = "text",
            text = ResolveIcons(token, 14),
        })
    end

    if tokenCount == 0 then
        table.insert(segments, {
            kind = "text",
            text = ResolveIcons(text, 14),
        })
    end
end

local function SplitGuideLineSegments(line)
    local segments = {}
    local cursor = 1
    local spellSearchEntries = GetSpellSearchEntries()

    while cursor <= #line do
        local bestStart, bestEnd, bestSpell

        for _, spellEntry in ipairs(spellSearchEntries) do
            local startPos, endPos = line:find(EscapeLuaPattern(spellEntry.alias), cursor)
            if startPos and (not bestStart or startPos < bestStart) then
                bestStart = startPos
                bestEnd = endPos
                bestSpell = spellEntry.englishName
            end
        end

        if not bestStart then
            local tailText = line:sub(cursor)
            if tailText ~= "" then
                AddPlainTextSegments(segments, tailText)
            end
            break
        end

        if bestStart > cursor then
            local plainText = line:sub(cursor, bestStart - 1)
            if plainText ~= "" then
                AddPlainTextSegments(segments, plainText)
            end
        end

        local renderInfo = GetSpellRenderInfo(bestSpell)
        local matchedText = line:sub(bestStart, bestEnd)

        if renderInfo.isResolved or renderInfo.hasFallbackTooltip then
            table.insert(segments, {
                kind = "spell",
                spell = renderInfo,
                matchedText = matchedText,
            })
        else
            AddPlainTextSegments(segments, matchedText)
        end

        cursor = bestEnd + 1
    end

    if #segments == 0 then
        AddPlainTextSegments(segments, line)
    end

    return segments
end

local function AcquireGuideTextSegment(index)
    local widget = GuideTextSegments[index]
    if widget then
        return widget
    end

    widget = (ContentText or ContentScrollChild):CreateFontString(nil, "OVERLAY")
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

    button = CreateFrame("Button", nil, ContentText or ContentScrollChild)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:SetFrameStrata(GuideWindow and GuideWindow:GetFrameStrata() or "DIALOG")
    button:SetFrameLevel((GuideWindow and GuideWindow:GetFrameLevel() or 1) + 20)
    button:SetHitRectInsets(-8, -8, -5, -5)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(false)
    button.Text = text

    local function GetTooltipLineCount()
        if not GameTooltip or not GameTooltip.NumLines then
            return 0
        end

        return GameTooltip:NumLines() or 0
    end

    local function TryPopulateSpellTooltip(self)
        if not GameTooltip then
            return false
        end

        local function TryPopulate(populator)
            GameTooltip:ClearLines()
            populator()
            return GetTooltipLineCount() > 0
        end

        if self.spellLink and TryPopulate(function()
            GameTooltip:SetHyperlink(self.spellLink)
        end) then
            return true
        end

        if self.spellID and GameTooltip.SetSpellByID and TryPopulate(function()
            GameTooltip:SetSpellByID(self.spellID)
        end) then
            return true
        end

        if self.spellID and TryPopulate(function()
            GameTooltip:SetHyperlink("spell:" .. self.spellID)
        end) then
            return true
        end

        return false
    end

    local function ShowSpellTooltip(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()

        local hasTooltipContent = TryPopulateSpellTooltip(self)

        if not hasTooltipContent and self.spellName then
            GameTooltip:SetText(self.spellName, 1, 0.82, 0, 1, true)
            hasTooltipContent = true

            if self.englishName and self.englishName ~= self.spellName then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("EN: " .. self.englishName, 0.78, 0.82, 0.90, true)
            end
        end

        if self.fallbackTooltipText and self.fallbackTooltipText ~= "" then
            if hasTooltipContent then
                GameTooltip:AddLine(" ")
            end

            if self.fallbackTooltipKind and self.fallbackTooltipKind ~= "" then
                GameTooltip:AddLine(self.fallbackTooltipKind, 0.65, 0.78, 1, true)
            end

            GameTooltip:AddLine(self.fallbackTooltipText, 0.90, 0.90, 0.90, true)
            hasTooltipContent = true
        end

        local description
        if C_Spell and C_Spell.GetSpellDescription then
            description = C_Spell.GetSpellDescription(self.spellID or self.spellName)
        end

        if type(description) == "string" and description ~= "" and description ~= self.fallbackTooltipText then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(description, 0.90, 0.90, 0.90, true)
            hasTooltipContent = true
        end

        if hasTooltipContent then
            GameTooltip:Show()
        else
            GameTooltip:Hide()
        end
    end

    button:SetScript("OnEnter", function(self)
        self.Text:SetTextColor(1, 0.9, 0.35, 1)
        ShowSpellTooltip(self)
    end)

    button:SetScript("OnLeave", function(self)
        self.Text:SetTextColor(1.00, 0.82, 0.20, 1)
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

    for _, button in ipairs(GuideSectionButtons) do
        button:Hide()
    end
end

local function GetGuideSectionDisplayLabel(sectionKey, label, iconSize)
    label = label or GetGuideSectionLabel(sectionKey) or ""

    if sectionKey == "TANK" or sectionKey == "DD" or sectionKey == "HEAL" or sectionKey == "HC" or sectionKey == "M" then
        return string.format("%s %s", GetRoleIcon(sectionKey, iconSize or 13), label)
    end

    return label
end

local function ApplyGuideSectionButtonVisual(button)
    if not button then
        return
    end

    local isExpanded = button.isExpanded == true
    local isHovered = button.isHovered == true
    local sectionLabel = GetGuideSectionDisplayLabel(button.SectionKey, button.SectionLabel, 13)

    button.Bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and (isExpanded and 0.22 or 0.16) or (isExpanded and 0.15 or 0.10))
    button.Accent:SetColorTexture(1.00, 0.94, 0.47, isExpanded and 0.95 or 0.60)
    button.Text:SetTextColor(isExpanded and 1.00 or 0.90, isExpanded and 0.94 or 0.88, isExpanded and 0.47 or 0.76, 1)
    button.Text:SetText(string.format("%s %s", isExpanded and "[-]" or "[+]", sectionLabel))
end

local function AcquireGuideSectionButton(index)
    local button = GuideSectionButtons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, ContentText or ContentScrollChild)
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    button.Bg = bg

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    button.Accent = accent

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", button, "LEFT", 8, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    button.Text = text

    button:SetScript("OnEnter", function(self)
        self.isHovered = true
        ApplyGuideSectionButtonVisual(self)
    end)

    button:SetScript("OnLeave", function(self)
        self.isHovered = false
        ApplyGuideSectionButtonVisual(self)
    end)

    button:SetScript("OnClick", function(self)
        if not self.SectionKey then
            return
        end

        SetGuideSectionExpanded(self.SectionKey, not IsGuideSectionExpanded(self.SectionKey))
        UpdateGuideText()
    end)

    GuideSectionButtons[index] = button
    return button
end

local function RefreshGuideHomeTileVisual(tile)
    if not tile then
        return
    end

    local isHovered = tile.isHovered == true

    tile.Glow:SetShown(isHovered)

    if isHovered then
        tile.Shade:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.02)
        tile.BorderTop:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.92)
        tile.BorderBottom:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.72)
        tile.Accent:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.95)
        tile.Title:SetTextColor(1.00, 0.96, 0.84, 1)
        tile.Subtitle:SetTextColor(0.88, 0.88, 0.92, 1)
    else
        tile.Shade:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.08)
        tile.BorderTop:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.52)
        tile.BorderBottom:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.24)
        tile.Accent:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.60)
        tile.Title:SetTextColor(0.96, 0.92, 0.70, 1)
        tile.Subtitle:SetTextColor(0.72, 0.74, 0.78, 1)
    end
end

local function ApplyGuideTileArt(tile, texturePath, cropMode)
    if not tile or not tile.Art then
        return
    end

    if texturePath then
        tile.Art:SetTexture(texturePath)

        if cropMode == "card" then
            tile.Art:SetTexCoord(
                GUIDE_TILE_CARD_LEFT_CROP,
                GUIDE_TILE_CARD_RIGHT_CROP,
                GUIDE_TILE_CARD_TOP_CROP,
                GUIDE_TILE_CARD_BOTTOM_CROP
            )
        else
            tile.Art:SetTexCoord(
                GUIDE_TILE_FULL_LEFT_CROP,
                GUIDE_TILE_FULL_RIGHT_CROP,
                GUIDE_TILE_FULL_TOP_CROP,
                GUIDE_TILE_FULL_BOTTOM_CROP
            )
        end

        return
    end

    tile.Art:SetColorTexture(0.08, 0.10, 0.12, 1)
    tile.Art:SetTexCoord(
        GUIDE_TILE_FULL_LEFT_CROP,
        GUIDE_TILE_FULL_RIGHT_CROP,
        GUIDE_TILE_FULL_TOP_CROP,
        GUIDE_TILE_FULL_BOTTOM_CROP
    )
end

local function AcquireGuideHomeTile(index)
    local tile = GuideHomeTiles[index]
    if tile then
        return tile
    end

    tile = CreateFrame("Button", nil, GuideHomePanel)
    tile:SetHeight(GUIDE_TILE_MIN_IMAGE_HEIGHT)
    tile:EnableMouse(true)

    local art = tile:CreateTexture(nil, "BACKGROUND")
    art:SetAllPoints()
    art:SetTexCoord(0.02, 0.98, 0.02, 0.98)
    tile.Art = art

    local shade = tile:CreateTexture(nil, "ARTWORK")
    shade:SetAllPoints()
    tile.Shade = shade

    local topGlow = tile:CreateTexture(nil, "BORDER")
    topGlow:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", tile, "TOPRIGHT", 0, 0)
    topGlow:SetHeight(GUIDE_TILE_TITLE_OVERLAY_HEIGHT + 6)
    topGlow:SetColorTexture(1, 1, 1, 0.04)

    local glow = tile:CreateTexture(nil, "BORDER")
    glow:SetAllPoints()
    glow:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.10)
    glow:Hide()
    tile.Glow = glow

    local borderTop = tile:CreateTexture(nil, "ARTWORK")
    borderTop:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", tile, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    tile.BorderTop = borderTop

    local borderBottom = tile:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    tile.BorderBottom = borderBottom

    local accent = tile:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    tile.Accent = accent

    local footer = tile:CreateTexture(nil, "OVERLAY")
    footer:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    footer:SetPoint("TOPRIGHT", tile, "TOPRIGHT", 0, 0)
    footer:SetHeight(GUIDE_TILE_TITLE_OVERLAY_HEIGHT)
    footer:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.56)

    local title = tile:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", tile, "TOPLEFT", 10, -6)
    title:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -10, -6)
    title:SetHeight(GUIDE_TILE_TITLE_OVERLAY_HEIGHT - 8)
    title:SetJustifyH("LEFT")
    title:SetJustifyV("TOP")
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    if title.SetWordWrap then
        title:SetWordWrap(true)
    end
    if title.SetMaxLines then
        title:SetMaxLines(2)
    end
    tile.Title = title

    local subtitle = tile:CreateFontString(nil, "OVERLAY")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetPoint("RIGHT", tile, "RIGHT", -12, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    tile.Subtitle = subtitle

    tile:SetScript("OnEnter", function(self)
        self.isHovered = true
        RefreshGuideHomeTileVisual(self)
    end)

    tile:SetScript("OnLeave", function(self)
        self.isHovered = false
        RefreshGuideHomeTileVisual(self)
    end)

    tile:SetScript("OnClick", function(self)
        SetActiveGuide(self.GuideKey, "manual", true)
        UpdateGuideUi()
    end)

    GuideHomeTiles[index] = tile
    return tile
end

local function HideGuideHomeTiles()
    for _, tile in ipairs(GuideHomeTiles) do
        tile:Hide()
        tile.Subtitle:Hide()
    end
end

local function AcquireGuideHomeSection(index)
    local section = GuideHomeSections[index]
    if section then
        return section
    end

    section = {}

    local title = GuideHomePanel:CreateFontString(nil, "OVERLAY")
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    title:SetTextColor(0.96, 0.92, 0.72, 1)
    section.Title = title

    local emptyText = GuideHomePanel:CreateFontString(nil, "OVERLAY")
    emptyText:SetJustifyH("LEFT")
    emptyText:SetJustifyV("TOP")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    emptyText:SetTextColor(0.74, 0.78, 0.82, 1)
    emptyText:SetText(L("BOSS_GUIDES_EMPTY_CATEGORY"))
    emptyText:Hide()
    section.EmptyText = emptyText

    GuideHomeSections[index] = section
    return section
end

local function HideGuideHomeSections()
    for _, section in ipairs(GuideHomeSections) do
        section.Title:Hide()
        if section.EmptyText then
            section.EmptyText:Hide()
        end
    end
end

local function LayoutGuideHome()
    if not GuideHomePanel then
        return
    end

    local panelWidth = GuideHomePanel:GetWidth()
    if not panelWidth or panelWidth <= 0 then
        panelWidth = (GuideWindow and GuideWindow:GetWidth() or DEFAULT_WINDOW_WIDTH) - 24
    end

    local tileGap = HOME_TILE_GAP

    local yOffset = 0
    local tileIndex = 0
    local visibleSectionCount = 0

    HideGuideHomeTiles()
    HideGuideHomeSections()
    GuideHomeEmptyText:Hide()

    if GuideHomeTitleText then
        GuideHomeTitleText:Hide()
    end
    if GuideHomeBodyText then
        GuideHomeBodyText:Hide()
    end
    if GuideHomeSectionTitle then
        GuideHomeSectionTitle:Hide()
    end

    for _, category in ipairs(HOME_CATEGORY_ORDER) do
        local guideKeys = GetSortedGuideKeys(category.type)
        local maxColumns = 3
        local columns = math.max(1, math.min(maxColumns, math.floor((panelWidth + tileGap) / (GUIDE_TILE_MIN_WIDTH + tileGap))))
        local tileWidth = 0

        while columns > 1 do
            local candidateWidth = math.floor((panelWidth - ((columns - 1) * tileGap)) / columns)
            if candidateWidth >= GUIDE_TILE_MIN_WIDTH then
                tileWidth = math.min(candidateWidth, GUIDE_TILE_MAX_WIDTH)
                break
            end

            columns = columns - 1
        end

        if tileWidth <= 0 then
            tileWidth = math.min(math.floor(panelWidth), GUIDE_TILE_MAX_WIDTH)
        end

        local tileHeight = GetGuideTileHeight(tileWidth)
        visibleSectionCount = visibleSectionCount + 1

        local section = AcquireGuideHomeSection(visibleSectionCount)
        section.Title:SetText(L(category.titleKey))
        section.Title:ClearAllPoints()
        section.Title:SetPoint("TOPLEFT", GuideHomePanel, "TOPLEFT", 0, -yOffset)
        section.Title:SetPoint("RIGHT", GuideHomePanel, "RIGHT", 0, 0)
        section.Title:Show()
        if section.EmptyText then
            section.EmptyText:Hide()
        end

        yOffset = yOffset + section.Title:GetStringHeight() + HOME_SECTION_TITLE_SPACING

        if #guideKeys > 0 then
            for index, guideKey in ipairs(guideKeys) do
                local tile = AcquireGuideHomeTile(tileIndex + index)
                local guideData = GUIDE_DATA[guideKey]
                local tileTexture, _, cropMode = GetGuideTileTexture(guideKey, guideData)

                tile.GuideKey = guideKey
                tile.Title:SetText(GetGuideTitle(guideData))
                tile.Subtitle:SetText("")
                tile.Subtitle:Hide()
                tile:SetSize(tileWidth, tileHeight)
                ApplyGuideTileArt(tile, tileTexture, cropMode)

                local rowIndex = math.floor((index - 1) / columns)
                local columnIndex = (index - 1) % columns
                local itemsInRow = math.min(columns, #guideKeys - (rowIndex * columns))
                local rowWidth = (itemsInRow * tileWidth) + ((itemsInRow - 1) * tileGap)
                local rowOffsetX = math.max(math.floor((panelWidth - rowWidth) / 2), 0)
                tile:ClearAllPoints()
                tile:SetPoint("TOPLEFT", GuideHomePanel, "TOPLEFT", rowOffsetX + (columnIndex * (tileWidth + tileGap)), -(yOffset + (rowIndex * (tileHeight + tileGap))))
                tile:Show()
                RefreshGuideHomeTileVisual(tile)
            end

            tileIndex = tileIndex + #guideKeys

            local rowCount = math.ceil(#guideKeys / columns)
            yOffset = yOffset + (rowCount * tileHeight) + ((rowCount - 1) * tileGap) + HOME_SECTION_GAP
        elseif section.EmptyText then
            section.EmptyText:SetText(L("BOSS_GUIDES_EMPTY_CATEGORY"))
            section.EmptyText:ClearAllPoints()
            section.EmptyText:SetPoint("TOPLEFT", GuideHomePanel, "TOPLEFT", 0, -yOffset)
            section.EmptyText:SetPoint("RIGHT", GuideHomePanel, "RIGHT", 0, 0)
            section.EmptyText:Show()
            yOffset = yOffset + section.EmptyText:GetStringHeight() + 16
        end
    end

    if visibleSectionCount == 0 then
        GuideHomeEmptyText:ClearAllPoints()
        GuideHomeEmptyText:SetPoint("TOPLEFT", GuideHomePanel, "TOPLEFT", 0, 0)
        GuideHomeEmptyText:SetPoint("RIGHT", GuideHomePanel, "RIGHT", 0, 0)
        GuideHomeEmptyText:Show()
        GuideHomeContentHeight = math.max(GuideHomeEmptyText:GetStringHeight(), 24)
    else
        GuideHomeContentHeight = math.max(yOffset - HOME_SECTION_GAP, 24)
    end

    if AutoSizeGuideWindow then
        AutoSizeGuideWindow()
    end
end

local function RenderGuideLine(line, baseX, y, rightLimit, db, textIndex, spellIndex)
    if type(line) ~= "string" or line == "" then
        return y - (db.fontSize + 6), textIndex, spellIndex
    end

    local x = baseX
    local currentLineHeight = db.fontSize + 6

    for _, segment in ipairs(SplitGuideLineSegments(line)) do
        local widget
        local segmentWidth
        local segmentHeight
        local textValue

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
            segmentWidth = math.max(
                widget.Text:GetStringWidth(),
                widget.Text.GetUnboundedStringWidth and widget.Text:GetUnboundedStringWidth() or 0
            )
            segmentHeight = math.max(widget.Text:GetStringHeight(), db.fontSize + 6) + 2
            widget.spellID = segment.spell.spellID
            widget.spellLink = segment.spell.spellLink
            widget.spellName = segment.spell.localizedName
            widget.englishName = segment.spell.englishName
            widget.fallbackTooltipKind = segment.spell.fallbackTooltipKind
            widget.fallbackTooltipText = segment.spell.fallbackTooltipText
            widget:SetSize(segmentWidth, segmentHeight)
        else
            textIndex = textIndex + 1
            widget = AcquireGuideTextSegment(textIndex)
            widget:SetFont(FONT_PATH, db.fontSize, "OUTLINE")
            widget:SetTextColor(0.93, 0.90, 0.83, 1)
            textValue = segment.text
            if x == baseX then
                textValue = textValue:gsub("^%s+", "")
            end

            if textValue == "" then
                segmentWidth = 0
                segmentHeight = currentLineHeight
                widget:Hide()
            else
                widget:SetText(textValue)
                segmentWidth = widget:GetStringWidth()
                segmentHeight = math.max(widget:GetStringHeight(), db.fontSize + 4)
            end
        end

        if x > baseX and (x + segmentWidth) > rightLimit then
            x = baseX
            y = y - currentLineHeight
            if segment.kind == "text" and textValue then
                local wrappedTextValue = textValue:gsub("^%s+", "")
                if wrappedTextValue ~= textValue then
                    textValue = wrappedTextValue

                    if textValue == "" then
                        segmentWidth = 0
                        segmentHeight = currentLineHeight
                        widget:Hide()
                    else
                        widget:SetText(textValue)
                        segmentWidth = widget:GetStringWidth()
                        segmentHeight = math.max(widget:GetStringHeight(), db.fontSize + 4)
                    end
                end
            end

            currentLineHeight = segmentHeight
        else
            currentLineHeight = math.max(currentLineHeight, segmentHeight)
        end

        if segmentWidth > 0 then
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", ContentText or ContentScrollChild, "TOPLEFT", x, y)
            widget:Show()
        end

        x = x + segmentWidth
    end

    return y - currentLineHeight - 3, textIndex, spellIndex
end

local function RenderGuideBody(body)
    if not ContentText or not ContentScrollFrame then
        return 220
    end

    HideGuideContentWidgets()

    local db = GetBossGuidesSettings()
    local baseX = 4
    local y = -4
    local headerGap = 4
    local sectionGap = 6
    local rightLimit = math.max(ContentScrollFrame:GetWidth() - 8, 40)
    local textIndex = 0
    local spellIndex = 0
    local sectionButtonIndex = 0
    local sections = ParseGuideBodySections(body)

    if #sections == 0 then
        sections = {
            {
                key = "general",
                label = nil,
                lines = { tostring(body or "") },
                collapsible = false,
                showHeader = false,
            },
        }
    end

    for sectionIndex, section in ipairs(sections) do
        if section.collapsible then
            sectionButtonIndex = sectionButtonIndex + 1

            local button = AcquireGuideSectionButton(sectionButtonIndex)
            local isExpanded = IsGuideSectionExpanded(section.key)
            local buttonHeight = math.max(db.fontSize + 10, 22)

            button.SectionKey = section.key
            button.SectionLabel = section.label or GetGuideSectionLabel(section.key)
            button.isExpanded = isExpanded
            button.isHovered = false
            button.Text:SetFont(FONT_PATH, db.fontSize + 1, "OUTLINE")
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", ContentText or ContentScrollChild, "TOPLEFT", baseX, y)
            button:SetSize(math.max(rightLimit - baseX, 40), buttonHeight)
            ApplyGuideSectionButtonVisual(button)
            button:Show()

            y = y - buttonHeight - headerGap

            if isExpanded then
                for _, line in ipairs(section.lines) do
                    y, textIndex, spellIndex = RenderGuideLine(line, baseX + 12, y, rightLimit, db, textIndex, spellIndex)
                end
            end
        else
            if section.showHeader ~= false and section.label and section.label ~= "" then
                textIndex = textIndex + 1

                local titleWidget = AcquireGuideTextSegment(textIndex)
                titleWidget:SetFont(FONT_PATH, db.fontSize + 1, "OUTLINE")
                titleWidget:SetTextColor(1.00, 0.94, 0.47, 1)
                titleWidget:SetText(GetGuideSectionDisplayLabel(section.key, section.label, 14) .. ":")
                titleWidget:ClearAllPoints()
                titleWidget:SetPoint("TOPLEFT", ContentText or ContentScrollChild, "TOPLEFT", baseX, y)
                titleWidget:Show()

                y = y - math.max(titleWidget:GetStringHeight(), db.fontSize + 7) - headerGap
            end

            for _, line in ipairs(section.lines) do
                y, textIndex, spellIndex = RenderGuideLine(line, baseX, y, rightLimit, db, textIndex, spellIndex)
            end
        end

        if sectionIndex < #sections then
            y = y - sectionGap
        end
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

GetGuideTitle = function(guideData)
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

local function EnsureEncounterJournalApi()
    if EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex and EJ_GetInstanceInfo then
        return true
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
    elseif UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_EncounterJournal")
    end

    return EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex and EJ_GetInstanceInfo
end

local function GuideMatchesInstanceName(guideData, instanceName)
    local normalizedInstanceName = NormalizeText(instanceName)
    if normalizedInstanceName == "" then
        return false
    end

    for _, token in ipairs(GetLocalizedGuideTokens(guideData)) do
        local normalizedToken = NormalizeText(token)
        if normalizedToken ~= "" and string.find(normalizedInstanceName, normalizedToken, 1, true) then
            return true
        end
    end

    return false
end

local function GetGuideJournalInfo(guideKey, guideData)
    local cachedInfo = GuideJournalInfoCache[guideKey]
    if cachedInfo ~= nil then
        return cachedInfo or nil
    end

    local resolvedInfo

    if EnsureEncounterJournalApi() then
        local previousTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
        local numTiers = EJ_GetNumTiers() or 0

        for tierIndex = 1, numTiers do
            EJ_SelectTier(tierIndex)

            local entryIndex = 1
            while true do
                local journalInstanceID, instanceName = EJ_GetInstanceByIndex(entryIndex, guideData.type == "raid")
                if not journalInstanceID then
                    break
                end

                if GuideMatchesInstanceName(guideData, instanceName) then
                    local resolvedName, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, mapID, covenantID, isRaid = EJ_GetInstanceInfo(journalInstanceID)
                    resolvedInfo = {
                        journalInstanceID = journalInstanceID,
                        name = resolvedName or instanceName,
                        description = description,
                        bgImage = bgImage,
                        buttonImage1 = buttonImage1,
                        buttonImage2 = buttonImage2,
                        loreImage = loreImage,
                        mapID = mapID or dungeonAreaMapID,
                        isRaid = isRaid,
                        link = link,
                    }
                    break
                end

                entryIndex = entryIndex + 1
            end

            if resolvedInfo then
                break
            end
        end

        if previousTier and EJ_SelectTier then
            EJ_SelectTier(previousTier)
        end
    end

    GuideJournalInfoCache[guideKey] = resolvedInfo or false
    return resolvedInfo or nil
end

GetGuideTileTexture = function(guideKey, guideData)
    local journalInfo = GetGuideJournalInfo(guideKey, guideData)
    if not journalInfo then
        return nil, nil, nil
    end

    if journalInfo.buttonImage2 then
        return journalInfo.buttonImage2, journalInfo, "card"
    end

    if journalInfo.buttonImage1 then
        return journalInfo.buttonImage1, journalInfo, "card"
    end

    if journalInfo.loreImage then
        return journalInfo.loreImage, journalInfo, "full"
    end

    if journalInfo.bgImage then
        return journalInfo.bgImage, journalInfo, "full"
    end

    return nil, journalInfo, nil
end

GetSortedGuideKeys = function(filterType)
    local guideKeys = {}

    for guideKey, guideData in pairs(GUIDE_DATA) do
        if not filterType or guideData.type == filterType then
            guideKeys[#guideKeys + 1] = guideKey
        end
    end

    table.sort(guideKeys, function(leftKey, rightKey)
        local leftData = GUIDE_DATA[leftKey]
        local rightData = GUIDE_DATA[rightKey]
        local leftOrder = leftData and leftData.sortOrder
        local rightOrder = rightData and rightData.sortOrder

        if leftOrder ~= nil or rightOrder ~= nil then
            if leftOrder == nil then
                return false
            end

            if rightOrder == nil then
                return true
            end

            if leftOrder ~= rightOrder then
                return leftOrder < rightOrder
            end
        end

        return GetGuideTitle(leftData) < GetGuideTitle(rightData)
    end)

    return guideKeys
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
    if db.windowWidth == 450 and db.windowHeight == 500 then
        db.windowWidth = DEFAULT_WINDOW_WIDTH
        db.windowHeight = DEFAULT_WINDOW_HEIGHT
    end

    if db.windowWidth == 404 then
        db.windowWidth = DEFAULT_WINDOW_WIDTH
    end

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

    db.windowWidth = Clamp(db.windowWidth, MIN_WINDOW_WIDTH, GetGuideWindowMaxWidth())

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

    local db = GetBossGuidesSettings()
    db.windowWidth = Clamp(math.floor(GuideWindow:GetWidth() + 0.5), MIN_WINDOW_WIDTH, GetGuideWindowMaxWidth())
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
    db.windowWidth = Clamp(db.windowWidth or DEFAULT_WINDOW_WIDTH, MIN_WINDOW_WIDTH, GetGuideWindowMaxWidth())
    GuideWindow:SetSize(db.windowWidth, DEFAULT_WINDOW_HEIGHT)
    AttachGuideWindowToOverlayButton(db.windowWidth, DEFAULT_WINDOW_HEIGHT)
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

SetActiveGuide = function(guideKey, source, resetBossIndex)
    if guideKey and not GUIDE_DATA[guideKey] then
        guideKey = nil
    end

    local guideChanged = guideKey ~= activeGuideKey
    if guideChanged then
        activeGuideKey = guideKey
    end

    if guideKey then
        activeGuideSource = source or activeGuideSource or "manual"

        local guideData = GUIDE_DATA[guideKey]
        if guideData and guideData.type then
            selectedCategory = guideData.type
        end

        if guideChanged or resetBossIndex then
            activeBossIndex = 1
            GuideSectionExpansionState[string.format("%s:%d", guideKey, activeBossIndex)] = nil
        end
    else
        activeGuideSource = nil
        if guideChanged or resetBossIndex then
            activeBossIndex = 1
        end
    end

    return guideChanged
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
    btn.Text:SetTextColor(0.76, 0.78, 0.82, 1)
end

local function ApplyNavigationButtonVisual(btn)
    local isHovered = btn.isHovered == true

    btn.Bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.12 or 0)
    btn.Accent:Hide()
    btn.Text:SetTextColor(isHovered and 1.00 or 0.82, isHovered and 0.94 or 0.84, isHovered and 0.47 or 0.88, 1)
end

local SEP_ROLE = "|cFF2B6B5A" .. string.rep("-", 34) .. "|r"
local SEP_HC   = "|cFF444444" .. string.rep("-", 34) .. "|r"

local function TrimText(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SplitInstructionParts(text)
    local normalized = TrimText(text or "")
    return { normalized }
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

GetGuideSectionLabel = function(sectionKey)
    if sectionKey == "general" then
        return L("BOSS_GUIDES_SECTION_GENERAL")
    elseif sectionKey == "TANK" then
        return L("BOSS_GUIDES_LEGEND_TANK")
    elseif sectionKey == "DD" then
        return L("BOSS_GUIDES_LEGEND_DD")
    elseif sectionKey == "HEAL" then
        return L("BOSS_GUIDES_LEGEND_HEAL")
    elseif sectionKey == "HC" then
        return L("BOSS_GUIDES_LEGEND_HC")
    elseif sectionKey == "M" then
        return L("BOSS_GUIDES_LABEL_MYTHIC")
    end

    return tostring(sectionKey or "")
end

local function GetActiveGuideSectionState()
    if not activeGuideKey then
        return nil
    end

    local stateKey = string.format("%s:%d", activeGuideKey, activeBossIndex or 0)
    GuideSectionExpansionState[stateKey] = GuideSectionExpansionState[stateKey] or {}
    return GuideSectionExpansionState[stateKey]
end

IsGuideSectionExpanded = function(sectionKey)
    if sectionKey == "general" then
        return true
    end

    local state = GetActiveGuideSectionState()
    if not state then
        return false
    end

    return state[sectionKey] == true
end

SetGuideSectionExpanded = function(sectionKey, expanded)
    if not sectionKey or sectionKey == "general" then
        return
    end

    local state = GetActiveGuideSectionState()
    if not state then
        return
    end

    if expanded then
        state[sectionKey] = true
    else
        state[sectionKey] = nil
    end
end

ParseGuideBodySections = function(body)
    local sections = {}
    local currentSection
    local generalLabel = L("BOSS_GUIDES_SECTION_GENERAL")

    local function BeginSection(sectionKey, showHeader, collapsible)
        local section = {
            key = sectionKey,
            label = GetGuideSectionLabel(sectionKey),
            lines = {},
            collapsible = collapsible == true,
            showHeader = showHeader ~= false,
        }

        sections[#sections + 1] = section
        currentSection = section
        return section
    end

    for line in tostring(body or ""):gmatch("[^\n]+") do
        if line ~= SEP_ROLE and line ~= SEP_HC then
            local generalText = line:match("^" .. EscapeLuaPattern(generalLabel) .. ":%s*(.*)$")
            if generalText ~= nil then
                local section = BeginSection("general", true, false)
                generalText = TrimText(generalText)
                if generalText ~= "" then
                    section.lines[#section.lines + 1] = generalText
                end
            else
                local token, sectionText = line:match("^({[A-Z]+})%s*(.*)$")
                local sectionKey = token and token:match("{([A-Z]+)}")

                if sectionKey == "TANK" or sectionKey == "DD" or sectionKey == "HEAL" or sectionKey == "HC" or sectionKey == "M" then
                    local section = BeginSection(sectionKey, true, true)
                    sectionText = TrimText((sectionText or ""):gsub("^%b[]%s*", ""))
                    if sectionText ~= "" then
                        section.lines[#section.lines + 1] = sectionText
                    end
                else
                    if not currentSection then
                        currentSection = BeginSection("general", false, false)
                    end

                    currentSection.lines[#currentSection.lines + 1] = line
                end
            end
        end
    end

    return sections
end

local function GetContentScrollMax()
    if not ContentScrollFrame or not ContentScrollChild then
        return 0
    end

    return math.max(0, ContentScrollChild:GetHeight() - ContentScrollFrame:GetHeight())
end

AutoSizeGuideWindow = function()
    if not GuideWindow or not UIParent then
        return
    end

    local scale = GuideWindow:GetScale() or 1
    scale = math.max(scale, 0.01)

    local targetHeight
    if activeGuideKey then
        targetHeight = GUIDE_WINDOW_GUIDE_CHROME_HEIGHT + (BossMenuPanel and BossMenuPanel:GetHeight() or 0) + math.max(CurrentGuideContentHeight or 0, 120)
    else
        targetHeight = GUIDE_WINDOW_HOME_CHROME_HEIGHT + math.max(GuideHomeContentHeight or 0, 120)
    end

    local attachment = GetGuideWindowAttachment(GuideWindow:GetWidth() or DEFAULT_WINDOW_WIDTH, targetHeight)
    local maxHeight = attachment and attachment.maxHeight or math.max(MIN_WINDOW_HEIGHT, math.floor((UIParent:GetHeight() - 80) / scale))
    targetHeight = Clamp(math.floor(targetHeight + 0.5), MIN_WINDOW_HEIGHT, maxHeight)

    if math.abs((GuideWindow:GetHeight() or 0) - targetHeight) <= 1 then
        AttachGuideWindowToOverlayButton(GuideWindow:GetWidth() or DEFAULT_WINDOW_WIDTH, targetHeight)
        return
    end

    isAutoSizingGuideWindow = true
    GuideWindow:SetHeight(targetHeight)
    AttachGuideWindowToOverlayButton(GuideWindow:GetWidth() or DEFAULT_WINDOW_WIDTH, targetHeight)
    isAutoSizingGuideWindow = false
end

local function SyncContentScrollbar()
    if not ContentScrollFrame or not ContentScrollbar then
        return
    end

    local maxValue = GetContentScrollMax()
    local currentValue = math.min(ContentScrollFrame:GetVerticalScroll() or 0, maxValue)

    if maxValue <= 0 then
        ContentScrollFrame:SetVerticalScroll(0)
        ContentScrollbar:Hide()
        return
    end

    ContentScrollbar:Show()
    ContentScrollbar:SetMinMaxValues(0, maxValue)
    ContentScrollbar:SetValueStep(math.max(math.floor(maxValue / 20), 1))

    isUpdatingContentScrollbar = true
    ContentScrollbar:SetValue(currentValue)
    isUpdatingContentScrollbar = false
end

local function SetContentScrollOffset(value)
    if not ContentScrollFrame then
        return
    end

    local clampedValue = Clamp(tonumber(value) or 0, 0, GetContentScrollMax())
    ContentScrollFrame:SetVerticalScroll(clampedValue)
    SyncContentScrollbar()
end

UpdateGuideText = function()
    if not GuideWindow or not ContentText then
        return
    end

    local guideData = GetActiveGuideData()
    if not guideData then
        local emptyHeight = RenderGuideBody(L("BOSS_GUIDES_NO_GUIDE"))
        ContentText:SetHeight(emptyHeight)
        ContentScrollChild:SetHeight(200)
        CurrentGuideContentHeight = emptyHeight
        if AutoSizeGuideWindow then
            AutoSizeGuideWindow()
        end
        return
    end

    local bossData = guideData.bosses[activeBossIndex]
    if not bossData then
        local emptyHeight = RenderGuideBody(L("BOSS_GUIDES_NO_GUIDE"))
        ContentText:SetHeight(emptyHeight)
        ContentScrollChild:SetHeight(200)
        CurrentGuideContentHeight = emptyHeight
        if AutoSizeGuideWindow then
            AutoSizeGuideWindow()
        end
        return
    end

    local formattedBody = FormatRoleRows(GetBossBody(bossData))
    local expectedHeight = RenderGuideBody(formattedBody)
    ContentText:SetHeight(expectedHeight)
    local minHeight = math.max(ContentScrollFrame:GetHeight(), 220)
    ContentScrollChild:SetHeight(math.max(expectedHeight, minHeight))
    CurrentGuideContentHeight = expectedHeight
    SetContentScrollOffset(0)

    if AutoSizeGuideWindow then
        AutoSizeGuideWindow()
    end
end

local function AcquireBossMenuButton(buttonIndex)
    local tabButton = TabButtons[buttonIndex]
    if tabButton then
        return tabButton
    end

    tabButton = CreateFrame("Button", nil, BossMenuPanel)

    local bg = tabButton:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    tabButton.Bg = bg

    local accent = tabButton:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT", tabButton, "BOTTOMLEFT", 0, 0)
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
        self.isHovered = true
        if self.IsHomeButton then
            ApplyNavigationButtonVisual(self)
        elseif self.BossIndex ~= activeBossIndex then
            self.Bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.10)
        end
    end)

    tabButton:SetScript("OnLeave", function(self)
        self.isHovered = false
        if self.IsHomeButton then
            ApplyNavigationButtonVisual(self)
        else
            ApplyBossButtonVisual(self, self.BossIndex == activeBossIndex)
        end
    end)

    tabButton:SetScript("OnClick", function(self)
        if self.IsHomeButton then
            SetActiveGuide(nil, nil, true)
            UpdateGuideUi()
            return
        end

        if activeGuideKey and self.BossIndex then
            GuideSectionExpansionState[string.format("%s:%d", activeGuideKey, self.BossIndex)] = nil
        end

        activeBossIndex = self.BossIndex
        for _, button in ipairs(TabButtons) do
            if button:IsShown() then
                if button.IsHomeButton then
                    ApplyNavigationButtonVisual(button)
                else
                    ApplyBossButtonVisual(button, button.BossIndex == activeBossIndex)
                end
            end
        end
        UpdateGuideText()
    end)

    TabButtons[buttonIndex] = tabButton
    return tabButton
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

    local homeButton = AcquireBossMenuButton(1)
    homeButton.IsHomeButton = true
    homeButton.BossIndex = nil
    homeButton.Text:SetText("<")

    local homeButtonWidth = math.max(homeButton.Text:GetStringWidth() + 18, 28)
    homeButton:ClearAllPoints()
    homeButton:SetPoint("TOPLEFT", BossMenuPanel, "TOPLEFT", rowX, rowY)
    homeButton:SetHeight(BTN_H)
    homeButton:SetWidth(homeButtonWidth)
    homeButton:Show()
    ApplyNavigationButtonVisual(homeButton)

    rowX = rowX + homeButtonWidth + BTN_GAP

    for bossIndex, bossData in ipairs(guideData.bosses) do
        local tabButton = AcquireBossMenuButton(bossIndex + 1)

        tabButton.IsHomeButton = false
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

UpdateGuideUi = function()
    local guideData = GetActiveGuideData()

    if GuideWindowTitleText then
        GuideWindowTitleText:SetText(guideData and GetGuideTitle(guideData) or "")
    end

    RefreshWindowDropdowns()

    if activeGuideKey then
        if GuideHomePanel then
            GuideHomePanel:Hide()
        end

        if BossMenuPanel then
            BossMenuPanel:Show()
        end

        if LegendBar then
            LegendBar:Show()
        end

        if ContentScrollFrame then
            ContentScrollFrame:Show()
        end

        RebuildBossMenu()
        UpdateGuideText()
    else
        HideGuideContentWidgets()

        if BossMenuPanel then
            BossMenuPanel:Hide()
        end

        if LegendBar then
            LegendBar:Hide()
        end

        if ContentScrollFrame then
            ContentScrollFrame:Hide()
        end

        if ContentScrollbar then
            ContentScrollbar:Hide()
        end

        if GuideHomePanel then
            local maxHomeWidth = GetGuideWindowMaxWidth()
            local minHomeWidth = math.min(HOME_WINDOW_MIN_WIDTH, maxHomeWidth)
            local homeWidth = Clamp(HOME_WINDOW_PREFERRED_WIDTH, minHomeWidth, maxHomeWidth)
            if GuideWindow and math.abs((GuideWindow:GetWidth() or 0) - homeWidth) > 1 then
                isAutoSizingGuideWindow = true
                GuideWindow:SetWidth(homeWidth)
                AttachGuideWindowToOverlayButton(homeWidth, GuideWindow:GetHeight() or DEFAULT_WINDOW_HEIGHT)
                isAutoSizingGuideWindow = false
            end

            GuideHomePanel:Show()
            LayoutGuideHome()
        end
    end

    if OverlayButton and OverlayButton.RefreshVisual then
        OverlayButton:RefreshVisual()
    end
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
        if currentGuideKey then
            if currentGuideKey ~= activeGuideKey or activeGuideSource ~= "auto" then
                SetActiveGuide(currentGuideKey, "auto", true)
                UpdateGuideUi()
            end
        elseif activeGuideSource == "auto" then
            SetActiveGuide(nil, nil, true)
            UpdateGuideUi()
        end

        OverlayButton:Show()
    else
        OverlayButton:Hide()

        if GuideWindow then
            GuideWindow:Hide()
        end

        if activeGuideSource == "auto" then
            SetActiveGuide(nil, nil, true)
        end
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
        local maxWidth = GetGuideWindowMaxWidth()
        if GuideWindow:GetWidth() > maxWidth then
            GuideWindow:SetWidth(maxWidth)
            SaveGuideWindowGeometry()
        end
        AttachGuideWindowToOverlayButton()
        if GuideWindow:IsShown() and AutoSizeGuideWindow then
            AutoSizeGuideWindow()
        end
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
        if activeGuideKey then
            RebuildBossMenu()
        end
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

    db.windowWidth    = DEFAULT_WINDOW_WIDTH
    db.windowHeight   = DEFAULT_WINDOW_HEIGHT

    ApplyOverlayButtonGeometry()
    ApplyGuideWindowGeometry()
end

local function CreateOverlayFrames()
    if OverlayButton and GuideWindow then
        return
    end

    OverlayButton = CreateFrame("Button", "BeavisQoLBossGuidesToggle", UIParent)
    OverlayButton:SetSize(156, 28)
    OverlayButton:SetClampedToScreen(true)
    OverlayButton:SetMovable(true)
    OverlayButton:EnableMouse(true)
    OverlayButton:RegisterForDrag("LeftButton")
    OverlayButton:SetFrameStrata("HIGH")

    local buttonBg = OverlayButton:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints()

    local buttonGlow = OverlayButton:CreateTexture(nil, "BORDER")
    buttonGlow:SetPoint("TOPLEFT", OverlayButton, "TOPLEFT", 0, 0)
    buttonGlow:SetPoint("TOPRIGHT", OverlayButton, "TOPRIGHT", 0, 0)
    buttonGlow:SetHeight(14)

    local buttonBorderTop = OverlayButton:CreateTexture(nil, "ARTWORK")
    buttonBorderTop:SetPoint("TOPLEFT", OverlayButton, "TOPLEFT", 0, 0)
    buttonBorderTop:SetPoint("TOPRIGHT", OverlayButton, "TOPRIGHT", 0, 0)
    buttonBorderTop:SetHeight(1)

    local buttonBorderBottom = OverlayButton:CreateTexture(nil, "ARTWORK")
    buttonBorderBottom:SetPoint("BOTTOMLEFT", OverlayButton, "BOTTOMLEFT", 0, 0)
    buttonBorderBottom:SetPoint("BOTTOMRIGHT", OverlayButton, "BOTTOMRIGHT", 0, 0)
    buttonBorderBottom:SetHeight(1)

    local buttonAccent = OverlayButton:CreateTexture(nil, "ARTWORK")
    buttonAccent:SetPoint("TOPLEFT", OverlayButton, "TOPLEFT", 0, 0)
    buttonAccent:SetPoint("BOTTOMLEFT", OverlayButton, "BOTTOMLEFT", 0, 0)
    buttonAccent:SetWidth(2)

    local buttonConnector = OverlayButton:CreateTexture(nil, "ARTWORK")
    buttonConnector:SetPoint("BOTTOMLEFT", OverlayButton, "BOTTOMLEFT", 10, 0)
    buttonConnector:SetPoint("BOTTOMRIGHT", OverlayButton, "BOTTOMRIGHT", -10, 0)
    buttonConnector:SetHeight(1)
    buttonConnector:Hide()

    local buttonLabel = OverlayButton:CreateFontString(nil, "OVERLAY")
    buttonLabel:SetPoint("LEFT", OverlayButton, "LEFT", 12, 0)
    buttonLabel:SetPoint("RIGHT", OverlayButton, "RIGHT", -22, 0)
    buttonLabel:SetJustifyH("LEFT")
    buttonLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    buttonLabel:SetText(L("BOSS_GUIDES_BUTTON"))

    local buttonIndicator = OverlayButton:CreateFontString(nil, "OVERLAY")
    buttonIndicator:SetPoint("RIGHT", OverlayButton, "RIGHT", -8, 0)
    buttonIndicator:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    OverlayButton.RefreshVisual = function(self)
        local isOpen = GuideWindow and GuideWindow:IsShown()
        local isHovered = self.isHovered == true

        if isOpen then
            buttonBg:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.92)
            buttonGlow:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.12 or 0.08)
            buttonBorderTop:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.82)
            buttonBorderBottom:Hide()
            buttonAccent:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.88)
            buttonConnector:Show()
            buttonLabel:SetTextColor(1.00, 0.96, 0.82, 1)
            buttonIndicator:SetText("v")
            buttonIndicator:SetTextColor(0.82, 0.84, 0.88, 1)
            return
        end

        buttonBg:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, isHovered and 0.88 or 0.80)
        buttonGlow:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.10 or 0.04)
        buttonBorderTop:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.70 or 0.48)
        buttonBorderBottom:Show()
        buttonBorderBottom:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.34 or 0.18)
        buttonAccent:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, isHovered and 0.82 or 0.62)
        buttonConnector:Hide()
        buttonLabel:SetTextColor(isHovered and 1.00 or 0.94, isHovered and 0.95 or 0.90, isHovered and 0.78 or 0.72, 1)
        buttonIndicator:SetText(">")
        buttonIndicator:SetTextColor(isHovered and 0.84 or 0.72, isHovered and 0.86 or 0.76, isHovered and 0.90 or 0.80, 1)
    end

    OverlayButton:SetScript("OnEnter", function(self)
        self.isHovered = true
        if self.RefreshVisual then
            self:RefreshVisual()
        end
    end)

    OverlayButton:SetScript("OnLeave", function(self)
        self.isHovered = false
        if self.RefreshVisual then
            self:RefreshVisual()
        end
    end)

    OverlayButton:SetScript("OnDragStart", function(self)
        if BossGuidesModule.IsOverlayLocked() then return end
        self:StartMoving()
    end)
    OverlayButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveOverlayButtonGeometry()
        AttachGuideWindowToOverlayButton()
    end)

    GuideWindow = CreateFrame("Frame", "BeavisQoLBossGuidesWindow", UIParent)
    GuideWindow:SetSize(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT)
    GuideWindow:SetClampedToScreen(true)
    GuideWindow:SetMovable(true)
    GuideWindow:SetResizable(true)
    GuideWindow:SetResizeBounds(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)
    GuideWindow:EnableMouse(true)
    GuideWindow:SetFrameStrata("DIALOG")
    GuideWindow:Hide()

    GuideWindow:SetScript("OnShow", function()
        AttachGuideWindowToOverlayButton()
        if OverlayButton and OverlayButton.RefreshVisual then
            OverlayButton:RefreshVisual()
        end
    end)

    GuideWindow:SetScript("OnHide", function()
        if OverlayButton and OverlayButton.RefreshVisual then
            OverlayButton:RefreshVisual()
        end
    end)

    GuideWindow:SetScript("OnSizeChanged", function(self)
        if self:IsShown() then
            local maxWidth = GetGuideWindowMaxWidth()
            if self:GetWidth() > maxWidth + 1 then
                self:SetWidth(maxWidth)
                return
            end

            SaveGuideWindowGeometry()
            AttachGuideWindowToOverlayButton(self:GetWidth(), self:GetHeight())
            if not isAutoSizingGuideWindow then
                UpdateGuideUi()
            else
                SyncContentScrollbar()
            end
        end
    end)

    local bg = GuideWindow:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.82)

    -- 1px Teal-Linie oben
    local lineTop = GuideWindow:CreateTexture(nil, "ARTWORK")
    lineTop:SetPoint("TOPLEFT", GuideWindow, "TOPLEFT", 0, 0)
    lineTop:SetPoint("TOPRIGHT", GuideWindow, "TOPRIGHT", 0, 0)
    lineTop:SetHeight(1)
    lineTop:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.72)

    -- 1px Teal-Linie unten
    local lineBottom = GuideWindow:CreateTexture(nil, "ARTWORK")
    lineBottom:SetPoint("BOTTOMLEFT", GuideWindow, "BOTTOMLEFT", 0, 0)
    lineBottom:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 0)
    lineBottom:SetHeight(1)
    lineBottom:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.30)

    -- Kopfzeile: kompakt, ohne Dropdowns im Viewer
    local headerRow = CreateFrame("Frame", nil, GuideWindow)
    headerRow:SetPoint("TOPLEFT", GuideWindow, "TOPLEFT", 0, -2)
    headerRow:SetPoint("TOPRIGHT", GuideWindow, "TOPRIGHT", 0, -2)
    headerRow:SetHeight(28)

    CategoryDropdown = nil
    InstanceDropdown = nil

    GuideWindowTitleText = headerRow:CreateFontString(nil, "OVERLAY")
    GuideWindowTitleText:SetPoint("LEFT", headerRow, "LEFT", 12, 0)
    GuideWindowTitleText:SetPoint("RIGHT", headerRow, "RIGHT", -82, 0)
    GuideWindowTitleText:SetJustifyH("LEFT")
    GuideWindowTitleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    GuideWindowTitleText:SetTextColor(1.00, 0.96, 0.82, 1)
    GuideWindowTitleText:SetText("")

    -- Header-Buttons rechts: Einstellungen | Pin | Schließen
    local function MakeHeaderIconBtn(parent, texturePath, offsetX)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(20, 20)
        btn:SetPoint("RIGHT", parent, "RIGHT", offsetX, 0)
        btn:SetHitRectInsets(-2, -2, -2, -2)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0)
        btn.Bg = bg

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetSize(14, 14)
        icon:SetTexture(texturePath)
        icon:SetVertexColor(0.75, 0.75, 0.75, 1)
        btn.Icon = icon

        btn:SetScript("OnEnter", function(self)
            self.Bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.16)
            self.Icon:SetVertexColor(0.86, 0.88, 0.92, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self.Bg:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0)
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
    menuSep:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.26)

    -- Legende unten (kein eigener Hintergrund)
    LegendBar = CreateFrame("Frame", nil, GuideWindow)
    LegendBar:SetPoint("BOTTOMLEFT",  GuideWindow, "BOTTOMLEFT",  0, 2)
    LegendBar:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 2)
    LegendBar:SetHeight(18)

    local legendItems = {
        { role = "TANK", label = L("BOSS_GUIDES_LEGEND_TANK") },
        { role = "DD",   label = L("BOSS_GUIDES_LEGEND_DD") },
        { role = "HEAL", label = L("BOSS_GUIDES_LEGEND_HEAL") },
        { role = "HC",   label = L("BOSS_GUIDES_LEGEND_HC") },
        { role = "M",    label = L("BOSS_GUIDES_LEGEND_M") },
    }

    local xOff = 8
    for _, item in ipairs(legendItems) do
        local legendEntry = LegendBar:CreateFontString(nil, "OVERLAY")
        legendEntry:SetPoint("LEFT", LegendBar, "LEFT", xOff, 0)
        legendEntry:SetFont(FONT_PATH, math.max(DEFAULT_FONT_SIZE - 1, MIN_FONT_SIZE), "")
        legendEntry:SetTextColor(0.55, 0.55, 0.55, 1)
        legendEntry:SetText(GetRoleIcon(item.role, 11) .. " " .. item.label)
        xOff = xOff + legendEntry:GetStringWidth() + 14
        table.insert(LegendFontStrings, legendEntry)
    end

    -- Content-Bereich unterhalb der Tab-Leiste und oberhalb der Legende
    ContentScrollFrame = CreateFrame("ScrollFrame", nil, GuideWindow)
    ContentScrollFrame:SetPoint("TOPLEFT",     BossMenuPanel, "BOTTOMLEFT",  10, -4)
    ContentScrollFrame:SetPoint("BOTTOMRIGHT", LegendBar,     "TOPRIGHT",   -(10 + CONTENT_SCROLLBAR_WIDTH + CONTENT_SCROLLBAR_GAP), 4)
    ContentScrollFrame:EnableMouseWheel(true)
    ContentScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local step    = 38
        local cur     = self:GetVerticalScroll()
        local maxVal  = GetContentScrollMax()
        local nextVal = cur - (delta * step)
        if nextVal < 0 then nextVal = 0 elseif nextVal > maxVal then nextVal = maxVal end
        SetContentScrollOffset(nextVal)
    end)

    ContentScrollChild = CreateFrame("Frame", nil, ContentScrollFrame)
    ContentScrollChild:SetSize(ContentScrollFrame:GetWidth(), 1)
    ContentScrollFrame:SetScrollChild(ContentScrollChild)

    ContentScrollFrame:SetScript("OnSizeChanged", function(self)
        ContentScrollChild:SetWidth(self:GetWidth())
        if ContentText then
            ContentText:SetWidth(math.max(self:GetWidth() - 8, 40))
            if GuideWindow and GuideWindow:IsShown() then
                UpdateGuideText()
            end
        end
        SyncContentScrollbar()
    end)

    ContentScrollbar = CreateFrame("Slider", nil, GuideWindow)
    ContentScrollbar:SetOrientation("VERTICAL")
    ContentScrollbar:SetPoint("TOPLEFT", ContentScrollFrame, "TOPRIGHT", CONTENT_SCROLLBAR_GAP, 0)
    ContentScrollbar:SetPoint("BOTTOMLEFT", ContentScrollFrame, "BOTTOMRIGHT", CONTENT_SCROLLBAR_GAP, 0)
    ContentScrollbar:SetWidth(CONTENT_SCROLLBAR_WIDTH)
    ContentScrollbar:SetObeyStepOnDrag(true)
    ContentScrollbar:Hide()

    local scrollbarTrack = ContentScrollbar:CreateTexture(nil, "BACKGROUND")
    scrollbarTrack:SetAllPoints()
    scrollbarTrack:SetColorTexture(GUIDE_BG_R, GUIDE_BG_G, GUIDE_BG_B, 0.88)

    local scrollbarBorder = ContentScrollbar:CreateTexture(nil, "ARTWORK")
    scrollbarBorder:SetAllPoints()
    scrollbarBorder:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.24)

    local scrollbarThumb = ContentScrollbar:CreateTexture(nil, "OVERLAY")
    scrollbarThumb:SetColorTexture(GUIDE_ACCENT_R, GUIDE_ACCENT_G, GUIDE_ACCENT_B, 0.92)
    scrollbarThumb:SetSize(CONTENT_SCROLLBAR_WIDTH, 36)
    ContentScrollbar:SetThumbTexture(scrollbarThumb)

    ContentScrollbar:SetScript("OnValueChanged", function(_, value)
        if isUpdatingContentScrollbar or not ContentScrollFrame then
            return
        end

        ContentScrollFrame:SetVerticalScroll(value)
    end)

    ContentText = CreateFrame("Frame", nil, ContentScrollChild)
    ContentText:SetPoint("TOPLEFT",  ContentScrollChild, "TOPLEFT",  4, -4)
    ContentText:SetPoint("TOPRIGHT", ContentScrollChild, "TOPRIGHT", -4, -4)
    ContentText:SetWidth(math.max(ContentScrollFrame:GetWidth() - 8, 40))
    ContentText:SetHeight(220)

    GuideHomePanel = CreateFrame("Frame", nil, GuideWindow)
    GuideHomePanel:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 12, -12)
    GuideHomePanel:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", -12, 10)
    GuideHomePanel:Hide()

    GuideHomeEmptyText = GuideHomePanel:CreateFontString(nil, "OVERLAY")
    GuideHomeEmptyText:SetPoint("TOPLEFT", GuideHomePanel, "TOPLEFT", 0, 0)
    GuideHomeEmptyText:SetPoint("RIGHT", GuideHomePanel, "RIGHT", 0, 0)
    GuideHomeEmptyText:SetJustifyH("LEFT")
    GuideHomeEmptyText:SetJustifyV("TOP")
    GuideHomeEmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    GuideHomeEmptyText:SetTextColor(0.78, 0.80, 0.82, 1)
    GuideHomeEmptyText:SetText(L("BOSS_GUIDES_HOME_EMPTY"))
    GuideHomeEmptyText:Hide()

    OverlayButton:SetScript("OnClick", function()
        if GuideWindow:IsShown() then
            GuideWindow:Hide()
        else
            UpdateGuideUi()
            GuideWindow:Show()
        end
    end)

    -- Resize-Griff unten rechts
    local resizeGrip = CreateFrame("Button", nil, GuideWindow)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", GuideWindow, "BOTTOMRIGHT", 0, 0)
    resizeGrip:SetFrameLevel(GuideWindow:GetFrameLevel() + 10)
    local gripTxt = resizeGrip:CreateFontString(nil, "OVERLAY")
    gripTxt:SetAllPoints()
    gripTxt:SetFont(FONT_PATH, 14, "")
    gripTxt:SetText(">")
    gripTxt:SetJustifyH("RIGHT")
    gripTxt:SetJustifyV("BOTTOM")
    gripTxt:SetTextColor(0.60, 0.60, 0.64, 0.45)
    resizeGrip:SetScript("OnEnter",    function() gripTxt:SetTextColor(0.82, 0.84, 0.88, 0.90) end)
    resizeGrip:SetScript("OnLeave",    function() gripTxt:SetTextColor(0.60, 0.60, 0.64, 0.45) end)
    resizeGrip:SetScript("OnMouseDown", function()
        if BossGuidesModule.IsOverlayLocked() then return end
        GuideWindow:StartSizing("RIGHT")
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
    SyncContentScrollbar()
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

    local INTRO_PANEL_MIN_HEIGHT = 108
    local SETTINGS_PANEL_MIN_HEIGHT = 296

    local introPanel = CreateFrame("Frame", nil, PageBossGuides)
    introPanel:SetPoint("TOPLEFT", PageBossGuides, "TOPLEFT", 20, -20)
    introPanel:SetPoint("TOPRIGHT", PageBossGuides, "TOPRIGHT", -20, -20)
    introPanel:SetHeight(INTRO_PANEL_MIN_HEIGHT)

    local introBg = introPanel:CreateTexture(nil, "BACKGROUND")
    introBg:SetAllPoints()
    introBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

    local introBorder = introPanel:CreateTexture(nil, "ARTWORK")
    introBorder:SetPoint("BOTTOMLEFT", introPanel, "BOTTOMLEFT", 0, 0)
    introBorder:SetPoint("BOTTOMRIGHT", introPanel, "BOTTOMRIGHT", 0, 0)
    introBorder:SetHeight(1)
    introBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

    local introTitle = introPanel:CreateFontString(nil, "OVERLAY")
    introTitle:SetPoint("TOPLEFT", introPanel, "TOPLEFT", 18, -14)
    introTitle:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
    introTitle:SetTextColor(1, 0.88, 0.62, 1)
    introTitle:SetText(BeavisQoL.GetModulePageTitle("BossGuides", L("BOSS_GUIDES")))

    local introText = introPanel:CreateFontString(nil, "OVERLAY")
    introText:SetPoint("TOPLEFT", introTitle, "BOTTOMLEFT", 0, -10)
    introText:SetPoint("RIGHT", introPanel, "RIGHT", -18, 0)
    introText:SetJustifyH("LEFT")
    introText:SetJustifyV("TOP")
    introText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    introText:SetTextColor(0.95, 0.91, 0.85, 1)
    introText:SetText(L("BOSS_GUIDES_DESC"))

    local settingsPanel = CreateFrame("Frame", nil, PageBossGuides)
    settingsPanel:SetPoint("TOPLEFT", introPanel, "BOTTOMLEFT", 0, -18)
    settingsPanel:SetPoint("TOPRIGHT", introPanel, "BOTTOMRIGHT", 0, -18)
    settingsPanel:SetHeight(SETTINGS_PANEL_MIN_HEIGHT)

    local settingsBg = settingsPanel:CreateTexture(nil, "BACKGROUND")
    settingsBg:SetAllPoints()
    settingsBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

    local settingsBorder = settingsPanel:CreateTexture(nil, "ARTWORK")
    settingsBorder:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT", 0, 0)
    settingsBorder:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", 0, 0)
    settingsBorder:SetHeight(1)
    settingsBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

    local settingsTitle = settingsPanel:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 18, -14)
    settingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    settingsTitle:SetTextColor(1, 0.88, 0.62, 1)
    settingsTitle:SetText(L("BOSS_GUIDES_SETTINGS"))

    ShowOverlayCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
    ShowOverlayCheckbox:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", -4, -10)

    local showOverlayLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    showOverlayLabel:SetPoint("LEFT", ShowOverlayCheckbox, "RIGHT", 6, 0)
    showOverlayLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    showOverlayLabel:SetTextColor(0.95, 0.91, 0.85, 1)
    showOverlayLabel:SetText(L("BOSS_GUIDES_SHOW_OVERLAY"))

    local overlayModeLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    overlayModeLabel:SetPoint("TOPLEFT", ShowOverlayCheckbox, "BOTTOMLEFT", 34, -8)
    overlayModeLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    overlayModeLabel:SetTextColor(1, 0.88, 0.62, 1)
    overlayModeLabel:SetText(L("BOSS_GUIDES_OVERLAY_MODE"))

    OverlayModeDropdown = CreateFrame("Frame", "BeavisQoLBossGuidesOverlayModeDropdown", settingsPanel, "UIDropDownMenuTemplate")
    OverlayModeDropdown:SetPoint("TOPLEFT", overlayModeLabel, "BOTTOMLEFT", -18, -2)
    UIDropDownMenu_SetWidth(OverlayModeDropdown, 200)

    LockOverlayCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
    LockOverlayCheckbox:SetPoint("TOPLEFT", OverlayModeDropdown, "BOTTOMLEFT", 18, -4)

    local lockOverlayLabel = settingsPanel:CreateFontString(nil, "OVERLAY")
    lockOverlayLabel:SetPoint("LEFT", LockOverlayCheckbox, "RIGHT", 6, 0)
    lockOverlayLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    lockOverlayLabel:SetTextColor(0.95, 0.91, 0.85, 1)
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
    CurrentInstanceText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    CurrentInstanceText:SetTextColor(0.78, 0.74, 0.69, 1)

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

    local function RefreshSettingsLayout()
        local introTop = introPanel:GetTop()
        local introTextBottom = introText:GetBottom()
        if introTop and introTextBottom then
            local introHeight = math.ceil(introTop - introTextBottom + 18)
            introPanel:SetHeight(math.max(INTRO_PANEL_MIN_HEIGHT, introHeight))
        end

        local settingsTop = settingsPanel:GetTop()
        local currentInstanceBottom = CurrentInstanceText:GetBottom()
        if settingsTop and currentInstanceBottom then
            local settingsHeight = math.ceil(settingsTop - currentInstanceBottom + 22)
            settingsPanel:SetHeight(math.max(SETTINGS_PANEL_MIN_HEIGHT, settingsHeight))
        end
    end

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
        RefreshSettingsLayout()
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

