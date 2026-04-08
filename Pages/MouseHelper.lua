-- Hinweistext zu Blizzard-Limitierung bei Cursorgrößen
local MouseHelper
local CursorSizeDropdown

local function ShowCursorSizeInfoLabel()
    if not MouseHelper or not CursorSizeDropdown then
        return
    end

    if not MouseHelper.CursorSizeInfoLabel then
        MouseHelper.CursorSizeInfoLabel = CursorSizeDropdown:CreateFontString(nil, "OVERLAY")
        MouseHelper.CursorSizeInfoLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
        MouseHelper.CursorSizeInfoLabel:SetTextColor(1, 0.82, 0, 0.85)
        MouseHelper.CursorSizeInfoLabel:SetPoint("TOPLEFT", CursorSizeDropdown, "BOTTOMLEFT", 0, -4)
        MouseHelper.CursorSizeInfoLabel:SetWidth(260)
        MouseHelper.CursorSizeInfoLabel:SetJustifyH("LEFT")
    end
    MouseHelper.CursorSizeInfoLabel:SetText("Hinweis: 96x96 und 128x128 werden von Blizzard aktuell identisch dargestellt. Dies ist eine Limitierung des Spiels.")
end
local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.MouseHelper = BeavisQoL.MouseHelper or {}
MouseHelper = BeavisQoL.MouseHelper

local GetCVarValue = (C_CVar and C_CVar.GetCVar) or rawget(_G, "GetCVar")
local SetCVarValue = (C_CVar and C_CVar.SetCVar) or rawget(_G, "SetCVar")
local OpacitySliderFrameRef = rawget(_G, "OpacitySliderFrame")

local COLOR_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local DEFAULT_TRAIL_STYLE = "lightning_storm"
local TRAIL_SAMPLE_INTERVAL = 0.010
local TRAIL_RENDER_INTERVAL = 0.016
local TRAIL_IDLE_FADE_INTERVAL = 0.024
local CAST_RING_SEGMENT_COUNT = 96
local TRAIL_STYLE_OPTIONS = {
    { value = "lightning_storm", textKey = "MOUSE_HELPER_TRAIL_STYLE_LIGHTNING" },
    { value = "holy_light", textKey = "MOUSE_HELPER_TRAIL_STYLE_HOLY" },
    { value = "arc_ribbons", textKey = "MOUSE_HELPER_TRAIL_STYLE_ARC" },
    { value = "clean_streak", textKey = "MOUSE_HELPER_TRAIL_STYLE_CLEAN" },
}

local isRefreshing = false
local sliderCounter = 0

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function CopyColor(color)
    color = color or {}
    return {
        r = Clamp(tonumber(color.r) or 1, 0, 1),
        g = Clamp(tonumber(color.g) or 0.82, 0, 1),
        b = Clamp(tonumber(color.b) or 0, 0, 1),
        a = Clamp(tonumber(color.a) or 0.9, 0, 1),
    }
end

local function GetPlayerClassColor()
    if type(UnitClass) ~= "function" then
        return nil
    end

    local _, classFile = UnitClass("player")
    if type(classFile) ~= "string" or classFile == "" then
        return nil
    end

    local function ReadColor(color)
        if not color then
            return nil
        end

        if type(color.GetRGB) == "function" then
            local red, green, blue = color:GetRGB()
            if type(red) == "number" and type(green) == "number" and type(blue) == "number" then
                return Clamp(red, 0, 1), Clamp(green, 0, 1), Clamp(blue, 0, 1)
            end
        end

        local red = tonumber(color.r or color.red or color.R)
        local green = tonumber(color.g or color.green or color.G)
        local blue = tonumber(color.b or color.blue or color.B)
        if red and green and blue then
            return Clamp(red, 0, 1), Clamp(green, 0, 1), Clamp(blue, 0, 1)
        end

        return nil
    end

    if C_ClassColor and C_ClassColor.GetClassColor then
        local red, green, blue = ReadColor(C_ClassColor.GetClassColor(classFile))
        if red and green and blue then
            return red, green, blue
        end
    end

    local classColors = rawget(_G, "CUSTOM_CLASS_COLORS") or rawget(_G, "RAID_CLASS_COLORS")
    return ReadColor(classColors and classColors[classFile] or nil)
end

local function GetTrailColorComponents(db)
    local trailColor = db and db.trailColor or nil
    local red = Clamp(tonumber(trailColor and trailColor.r) or 1, 0, 1)
    local green = Clamp(tonumber(trailColor and trailColor.g) or 0.62, 0, 1)
    local blue = Clamp(tonumber(trailColor and trailColor.b) or 0.1, 0, 1)
    local alpha = Clamp(tonumber(trailColor and trailColor.a) or 0.75, 0, 1)

    if db and db.trailUseClassColor == true then
        local classRed, classGreen, classBlue = GetPlayerClassColor()
        if classRed and classGreen and classBlue then
            red = classRed
            green = classGreen
            blue = classBlue
        end
    end

    return red, green, blue, alpha
end

local function GetCircleColorComponents(db)
    local circleColor = db and db.circleColor or nil
    local red = Clamp(tonumber(circleColor and circleColor.r) or 1, 0, 1)
    local green = Clamp(tonumber(circleColor and circleColor.g) or 0.82, 0, 1)
    local blue = Clamp(tonumber(circleColor and circleColor.b) or 0, 0, 1)
    local alpha = Clamp(tonumber(circleColor and circleColor.a) or 0.9, 0, 1)

    if db and db.circleUseClassColor == true then
        local classRed, classGreen, classBlue = GetPlayerClassColor()
        if classRed and classGreen and classBlue then
            red = classRed
            green = classGreen
            blue = classBlue
        end
    end

    return red, green, blue, alpha
end

local function GetCircleDisplayColor(db)
    local red, green, blue, alpha = GetCircleColorComponents(db)
    return {
        r = red,
        g = green,
        b = blue,
        a = alpha,
    }
end

local function GetTrailDisplayColor(db)
    local red, green, blue, alpha = GetTrailColorComponents(db)
    return {
        r = red,
        g = green,
        b = blue,
        a = alpha,
    }
end

local function IsValidTrailStyle(value)
    for _, option in ipairs(TRAIL_STYLE_OPTIONS) do
        if option.value == value then
            return true
        end
    end

    return false
end

local function Lerp(fromValue, toValue, ratio)
    return fromValue + ((toValue - fromValue) * ratio)
end

function MouseHelper.GetDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.mouseHelper = BeavisQoLDB.mouseHelper or {}

    local db = BeavisQoLDB.mouseHelper

    if db.enabled == nil then
        db.enabled = false
    end

    if db.blizzardCursorSize == nil then
        if db.blizzardLargeCursor == true then
            db.blizzardCursorSize = "64"
        else
            db.blizzardCursorSize = "default"
        end
    end

    if db.blizzardCursorSize ~= "default"
        and db.blizzardCursorSize ~= "32"
        and db.blizzardCursorSize ~= "48"
        and db.blizzardCursorSize ~= "64"
        and db.blizzardCursorSize ~= "96"
        and db.blizzardCursorSize ~= "128"
    then
        db.blizzardCursorSize = "default"
    end

    if db.circleEnabled == nil then
        db.circleEnabled = true
    end

    if db.circleCombatOnly == nil then
        db.circleCombatOnly = false
    end

    if db.circleUseClassColor == nil then
        db.circleUseClassColor = false
    end

    if db.castRingEnabled == nil then
        db.castRingEnabled = true
    end

    db.circleSize = Clamp(tonumber(db.circleSize) or 64, 24, 180)
    db.circleThickness = Clamp(tonumber(db.circleThickness) or 6, 2, 20)

    db.circleColor = CopyColor(db.circleColor or { r = 1, g = 0.82, b = 0, a = 0.9 })
    db.castRingColor = CopyColor(db.castRingColor or { r = 1, g = 0.9, b = 0.22, a = 0.95 })

    if db.trailEnabled == nil then
        db.trailEnabled = true
    end

    if db.trailUseClassColor == nil then
        db.trailUseClassColor = false
    end

    db.trailLength = Clamp(math.floor(tonumber(db.trailLength) or 20), 6, 60)
    db.trailSize = Clamp(tonumber(db.trailSize) or 10, 3, 28)
    db.trailColor = CopyColor(db.trailColor or { r = 1, g = 0.62, b = 0.1, a = 0.75 })

    if db.trailStyle == "gold_lightning" then
        db.trailStyle = "lightning_storm"
    elseif db.trailStyle == "arcane_flux" then
        db.trailStyle = "holy_light"
    end

    if not IsValidTrailStyle(db.trailStyle) then
        db.trailStyle = DEFAULT_TRAIL_STYLE
    end

    -- Entfernt: db.enabled wird nicht mehr automatisch auf true gesetzt, wenn circleEnabled oder trailEnabled aktiv sind
    -- Die Aktivierung erfolgt nur noch explizit durch den Nutzer

    return db
end

local function IsCursorSizeCVarSupported(cvarName)
    if type(GetCVarValue) ~= "function" then
        return false
    end

    local value = GetCVarValue(cvarName)
    return value ~= nil
end

local function IsAnyCursorSizeSupported()
    return IsCursorSizeCVarSupported("cursorSizePreferred") or IsCursorSizeCVarSupported("gxCursorSize")
end

local function ApplyBlizzardCursorSize()
    local db = MouseHelper.GetDB()
    local preset = db.blizzardCursorSize or "default"
    local preferredMap = {
        ["default"] = "0",
        ["32"] = "0",
        ["48"] = "1",
        ["64"] = "2",
        ["96"] = "3",
        ["128"] = "4", -- 128x128 wird auf 96x96 gemappt, da Blizzard nur 0-4 nutzt
    }

    if type(SetCVarValue) ~= "function" then
        return
    end

    if IsCursorSizeCVarSupported("cursorSizePreferred") then
        local preferredValue = preferredMap[preset] or "0"
        SetCVarValue("cursorSizePreferred", preferredValue)
        -- Kein Chat- oder CVar-Refresh-Spam mehr
    end

    if IsCursorSizeCVarSupported("gxCursorSize") then
        local legacyValue = (preset == "default") and "0" or "1"
        SetCVarValue("gxCursorSize", legacyValue)
        -- Kein Chat-Spam mehr
    end
end

local RuntimeFrame = CreateFrame("Frame", nil, UIParent)
RuntimeFrame:SetAllPoints(UIParent)
RuntimeFrame:SetFrameStrata("TOOLTIP")
RuntimeFrame:EnableMouse(false)

local CursorCircleFrame = CreateFrame("Frame", nil, RuntimeFrame)
CursorCircleFrame:SetFrameStrata("FULLSCREEN_DIALOG")
CursorCircleFrame:SetFrameLevel(200)
CursorCircleFrame:Hide()

local CastRingFrame = CreateFrame("Frame", nil, RuntimeFrame)
CastRingFrame:SetFrameStrata("FULLSCREEN_DIALOG")
CastRingFrame:SetFrameLevel(210)
CastRingFrame:Hide()

local TrailFrame = CreateFrame("Frame", nil, RuntimeFrame)
TrailFrame:SetFrameStrata("FULLSCREEN_DIALOG")
TrailFrame:SetFrameLevel(180)
TrailFrame:Hide()

local castRingSegments = {}
local trailCoreLines = {}
local trailGlowLines = {}
local trailAccentLines = {}
local trailBranchLines = {}
local trailPoints = {}
local smoothTrailPoints = {}
local sampleAccumulator = 0
local trailRenderAccumulator = 0
local trailFadeAccumulator = 0
local ringDots = {}
local lastCastRingRenderKey = nil
local lastRingRenderKey = nil
local lastTrailSampleX = nil
local lastTrailSampleY = nil
local MouseHelperRuntimeOnUpdate

local function EnsureRingDots(count)
    for index = #ringDots + 1, count do
        local dot = CursorCircleFrame:CreateTexture(nil, "ARTWORK")
        dot:SetColorTexture(1, 1, 1, 1)
        dot:SetBlendMode("BLEND")
        dot:Hide()
        ringDots[index] = dot
    end
end

local function DrawRing(size, thickness, color)
    local baseRadius = math.max(4, (size * 0.5) - (thickness * 0.5))
    local laneCount = Clamp(math.floor((thickness * 1.25) + 0.5), 2, 14)
    local totalDotCount = 0

    for laneIndex = 1, laneCount do
        local laneFactor
        if laneCount == 1 then
            laneFactor = 0
        else
            laneFactor = ((laneIndex - 1) / (laneCount - 1)) - 0.5
        end

        local laneRadius = baseRadius + (laneFactor * thickness)
        local laneCircumference = 2 * math.pi * laneRadius
        totalDotCount = totalDotCount + Clamp(math.floor(laneCircumference * 3.6), 120, 1800)
    end

    EnsureRingDots(totalDotCount)

    local dotIndex = 0
    for laneIndex = 1, laneCount do
        local laneFactor
        if laneCount == 1 then
            laneFactor = 0
        else
            laneFactor = ((laneIndex - 1) / (laneCount - 1)) - 0.5
        end

        local laneRadius = baseRadius + (laneFactor * thickness)
        local laneCircumference = 2 * math.pi * laneRadius
        local segmentCount = Clamp(math.floor(laneCircumference * 3.6), 120, 1800)
        local laneAlphaFactor = 1 - (math.abs(laneFactor) * 0.35)
        local dotSize = math.max(1.0, (thickness / laneCount) * 1.15)

        for segmentIndex = 1, segmentCount do
            dotIndex = dotIndex + 1
            local dot = ringDots[dotIndex]
            local angle = ((segmentIndex - 1) / segmentCount) * (math.pi * 2)
            local x = math.cos(angle) * laneRadius
            local y = math.sin(angle) * laneRadius

            dot:ClearAllPoints()
            dot:SetPoint("CENTER", CursorCircleFrame, "CENTER", x, y)
            dot:SetSize(dotSize, dotSize)
            dot:SetColorTexture(color.r, color.g, color.b, color.a * laneAlphaFactor)
            dot:Show()
        end
    end

    for index = dotIndex + 1, #ringDots do
        ringDots[index]:Hide()
    end
end

local function EnsureCastRingSegments(count)
    for index = #castRingSegments + 1, count do
        local segment = CastRingFrame:CreateTexture(nil, "OVERLAY")
        segment:SetTexture(COLOR_TEXTURE)
        segment:SetBlendMode("ADD")
        segment:Hide()
        castRingSegments[index] = segment
    end
end

local function HideCastRing()
    lastCastRingRenderKey = nil
    CastRingFrame:Hide()

    for index = 1, #castRingSegments do
        castRingSegments[index]:Hide()
    end
end

local function EnsureTrailLines(count)
    for index = #trailCoreLines + 1, count do
        local coreLine = TrailFrame:CreateLine(nil, "ARTWORK")
        coreLine:SetThickness(2)
        coreLine:Hide()
        trailCoreLines[index] = coreLine

        local glowLine = TrailFrame:CreateLine(nil, "BORDER")
        glowLine:SetThickness(4)
        glowLine:Hide()
        trailGlowLines[index] = glowLine

        local accentLine = TrailFrame:CreateLine(nil, "ARTWORK")
        accentLine:SetThickness(2)
        accentLine:Hide()
        trailAccentLines[index] = accentLine

        local branchLine = TrailFrame:CreateLine(nil, "OVERLAY")
        branchLine:SetThickness(1)
        branchLine:Hide()
        trailBranchLines[index] = branchLine
    end
end

local function ClearTrail()
    for index = 1, #trailPoints do
        trailPoints[index] = nil
    end

    lastTrailSampleX = nil
    lastTrailSampleY = nil
    sampleAccumulator = 0
    trailRenderAccumulator = 0
    trailFadeAccumulator = 0

    for index = 1, #trailCoreLines do
        trailCoreLines[index]:Hide()
    end

    for index = 1, #trailGlowLines do
        trailGlowLines[index]:Hide()
    end

    for index = 1, #trailAccentLines do
        trailAccentLines[index]:Hide()
    end

    for index = 1, #trailBranchLines do
        trailBranchLines[index]:Hide()
    end
end

local function GetCursorUiPosition()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    return cursorX / scale, cursorY / scale
end

local function ApplyCircleVisual(db)
    CursorCircleFrame:SetSize(db.circleSize, db.circleSize)
    local circleColor = GetCircleDisplayColor(db)

    local renderKey = string.format(
        "%d|%d|%.3f|%.3f|%.3f|%.3f",
        math.floor((db.circleSize or 0) + 0.5),
        math.floor((db.circleThickness or 0) + 0.5),
        circleColor.r or 0,
        circleColor.g or 0,
        circleColor.b or 0,
        circleColor.a or 0
    )

    if renderKey ~= lastRingRenderKey then
        DrawRing(db.circleSize, db.circleThickness, circleColor)
        lastRingRenderKey = renderKey
    end
end

local function GetCastRingProgress()
    if type(UnitCastingInfo) == "function" then
        local _, _, _, startTimeMS, endTimeMS = UnitCastingInfo("player")
        if startTimeMS and endTimeMS and endTimeMS > startTimeMS then
            local nowMS = ((GetTimePreciseSec and GetTimePreciseSec()) or GetTime()) * 1000
            return Clamp((nowMS - startTimeMS) / (endTimeMS - startTimeMS), 0, 1)
        end
    end

    if type(UnitChannelInfo) == "function" then
        local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")
        if startTimeMS and endTimeMS and endTimeMS > startTimeMS then
            local nowMS = ((GetTimePreciseSec and GetTimePreciseSec()) or GetTime()) * 1000
            return Clamp((endTimeMS - nowMS) / (endTimeMS - startTimeMS), 0, 1)
        end
    end

    return nil
end

local function DrawCastRing(db, progress)
    if not db or not progress then
        HideCastRing()
        return
    end

    local segmentCount = Clamp(math.floor(((db.circleSize or 64) * 1.5) + 0.5), 72, CAST_RING_SEGMENT_COUNT)
    local litSegmentCount = Clamp(math.floor((progress * segmentCount) + 0.5), 0, segmentCount)
    if litSegmentCount <= 0 then
        HideCastRing()
        return
    end

    local color = db.castRingColor or db.circleColor or { r = 1, g = 0.9, b = 0.22, a = 0.95 }
    local radius = math.max(10, (db.circleSize * 0.5) + (db.circleThickness * 0.95))
    local ringThickness = Clamp((db.circleThickness * 0.72) + 1, 2, 12)
    local segmentLength = math.max(4, ((2 * math.pi * radius) / segmentCount) * 0.82)
    local pulse = 0.84 + (0.16 * math.sin((GetTime() or 0) * 12))
    local renderKey = string.format(
        "%d|%d|%d|%.3f|%.3f|%.3f|%.3f|%.3f",
        math.floor((db.circleSize or 0) + 0.5),
        math.floor((db.circleThickness or 0) + 0.5),
        litSegmentCount,
        color.r or 0,
        color.g or 0,
        color.b or 0,
        color.a or 0,
        pulse
    )

    CastRingFrame:SetSize((radius * 2) + (ringThickness * 4), (radius * 2) + (ringThickness * 4))

    if renderKey == lastCastRingRenderKey and CastRingFrame:IsShown() then
        return
    end

    lastCastRingRenderKey = renderKey
    EnsureCastRingSegments(segmentCount)

    -- Inspired by cursor-ring addons: render a separate progress arc instead of replacing the base cursor ring.
    for index = 1, segmentCount do
        local segment = castRingSegments[index]
        local angle = (-math.pi * 0.5) + (((index - 1) / segmentCount) * (math.pi * 2))
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        segment:ClearAllPoints()
        segment:SetPoint("CENTER", CastRingFrame, "CENTER", x, y)
        segment:SetSize(segmentLength, ringThickness)
        segment:SetRotation(angle + (math.pi * 0.5))

        if index <= litSegmentCount then
            local alphaRatio = 0.42 + (0.58 * (index / math.max(1, litSegmentCount)))
            local alpha = (color.a or 1) * alphaRatio
            if index == litSegmentCount then
                alpha = Clamp(alpha * pulse, 0, 1)
            end

            segment:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, alpha)
            segment:Show()
        else
            segment:Hide()
        end
    end

    for index = segmentCount + 1, #castRingSegments do
        castRingSegments[index]:Hide()
    end

    CastRingFrame:Show()
end

local function BuildSmoothedTrailPoints(sourceCount)
    for index = 1, #smoothTrailPoints do
        smoothTrailPoints[index] = nil
    end

    if sourceCount < 2 then
        return 0
    end

    local insertIndex = 0
    for index = 1, sourceCount - 1 do
        local p0 = trailPoints[(index > 1) and (index - 1) or index]
        local p1 = trailPoints[index]
        local p2 = trailPoints[index + 1]
        local p3 = trailPoints[(index + 2 <= sourceCount) and (index + 2) or (index + 1)]

        local dx = p2.x - p1.x
        local dy = p2.y - p1.y
        local distance = math.sqrt((dx * dx) + (dy * dy))
        local steps = Clamp(math.floor(distance / 8), 1, 3)

        for step = 0, steps - 1 do
            local t = step / steps
            local t2 = t * t
            local t3 = t2 * t

            local x = 0.5 * (
                (2 * p1.x)
                + ((-p0.x + p2.x) * t)
                + ((2 * p0.x - (5 * p1.x) + (4 * p2.x) - p3.x) * t2)
                + ((-p0.x + (3 * p1.x) - (3 * p2.x) + p3.x) * t3)
            )

            local y = 0.5 * (
                (2 * p1.y)
                + ((-p0.y + p2.y) * t)
                + ((2 * p0.y - (5 * p1.y) + (4 * p2.y) - p3.y) * t2)
                + ((-p0.y + (3 * p1.y) - (3 * p2.y) + p3.y) * t3)
            )

            insertIndex = insertIndex + 1
            smoothTrailPoints[insertIndex] = { x = x, y = y }
        end
    end

    local lastPoint = trailPoints[sourceCount]
    insertIndex = insertIndex + 1
    smoothTrailPoints[insertIndex] = { x = lastPoint.x, y = lastPoint.y }

    return insertIndex
end

local function DrawTrail(db)
    local sourceCount = math.min(#trailPoints, db.trailLength)
    local smoothPointCount = BuildSmoothedTrailPoints(sourceCount)
    local segmentCount = smoothPointCount - 1
    if segmentCount <= 0 then
        for index = 1, #trailCoreLines do
            trailCoreLines[index]:Hide()
        end
        for index = 1, #trailGlowLines do
            trailGlowLines[index]:Hide()
        end
        for index = 1, #trailAccentLines do
            trailAccentLines[index]:Hide()
        end
        for index = 1, #trailBranchLines do
            trailBranchLines[index]:Hide()
        end
        return
    end

    EnsureTrailLines(segmentCount)

    local timeNow = GetTime() or 0
    local style = db.trailStyle or DEFAULT_TRAIL_STYLE
    local useClassColor = db.trailUseClassColor == true
    local trailRed, trailGreen, trailBlue, trailAlpha = GetTrailColorComponents(db)

    for index = 1, segmentCount do
        local p1 = smoothTrailPoints[index]
        local p2 = smoothTrailPoints[index + 1]
        local coreLine = trailCoreLines[index]
        local glowLine = trailGlowLines[index]
        local accentLine = trailAccentLines[index]
        local branchLine = trailBranchLines[index]

        if p1 and p2 then
            local dx = p2.x - p1.x
            local dy = p2.y - p1.y
            local distance = math.sqrt((dx * dx) + (dy * dy))

            if distance > 0.35 then
                local ratio = 1 - ((index - 1) / math.max(1, segmentCount))
                local alpha = trailAlpha * ratio * ratio
                local coreThickness = math.max(1.0, db.trailSize * (0.16 + (ratio * 0.42)))
                local glowThickness = coreThickness * 2.6
                local coreRed = trailRed
                local coreGreen = trailGreen
                local coreBlue = trailBlue
                local glowRed = coreRed
                local glowGreen = coreGreen
                local glowBlue = coreBlue
                local glowAlpha = alpha * 0.28
                local strandOffsetA = 0
                local strandOffsetB = 0
                local strandAlpha = alpha * 0.38
                local strandOffsetC = 0
                local strandAlphaC = alpha * 0.32

                local waveA = math.sin((timeNow * 3.6) + (index * 0.24))
                local waveB = math.cos((timeNow * 2.9) + (index * 0.31))
                local baseOffset = db.trailSize * (0.24 + (0.68 * ratio))

                if style == "holy_light" then
                    local pulse = 0.5 + (math.sin((timeNow * 4.8) + (index * 0.34)) * 0.5)
                    if useClassColor then
                        coreRed = Lerp(coreRed, 1.0, 0.34)
                        coreGreen = Lerp(coreGreen, 0.95, 0.22)
                        coreBlue = Lerp(coreBlue, 0.72, 0.14)
                    else
                        coreRed = Lerp(coreRed, 1.0, 0.68)
                        coreGreen = Lerp(coreGreen, 0.95, 0.58)
                        coreBlue = Lerp(coreBlue, 0.72, 0.54)
                    end
                    coreThickness = coreThickness * (1.10 + (pulse * 0.10))
                    glowThickness = coreThickness * 3.1
                    if useClassColor then
                        glowRed = Lerp(coreRed, 1.0, 0.18)
                        glowGreen = Lerp(coreGreen, 0.93, 0.18)
                        glowBlue = Lerp(coreBlue, 0.72, 0.14)
                    else
                        glowRed = 1.0
                        glowGreen = 0.93
                        glowBlue = 0.72
                    end
                    glowAlpha = alpha * (0.40 + (pulse * 0.16))
                    strandOffsetA = baseOffset * (0.32 + (0.22 * waveA))
                    strandOffsetB = -baseOffset * (0.30 + (0.20 * waveB))
                    strandAlpha = alpha * (0.30 + (pulse * 0.12))
                    strandOffsetC = strandOffsetB
                    strandAlphaC = strandAlpha * 0.8
                elseif style == "arc_ribbons" then
                    local flow = 0.5 + (math.sin((timeNow * 1.9) + (index * 0.18)) * 0.5)
                    if useClassColor then
                        coreRed = Lerp(coreRed, 0.74, 0.12)
                        coreGreen = Lerp(coreGreen, 0.86, 0.12)
                        coreBlue = Lerp(coreBlue, 1.0, 0.18)
                    else
                        coreRed = 0.74
                        coreGreen = 0.86
                        coreBlue = 1.0
                    end
                    coreThickness = math.max(1.0, coreThickness * 0.88)
                    glowThickness = coreThickness * 1.7
                    if useClassColor then
                        glowRed = Lerp(coreRed, 0.68, 0.16)
                        glowGreen = Lerp(coreGreen, 0.82, 0.16)
                        glowBlue = Lerp(coreBlue, 1.0, 0.18)
                    else
                        glowRed = 0.68
                        glowGreen = 0.82
                        glowBlue = 1.0
                    end
                    glowAlpha = alpha * 0.18

                    local arcBase = db.trailSize * (0.80 + (1.95 * ratio))
                    strandOffsetA = arcBase * (0.95 + (0.34 * waveA))
                    strandOffsetB = -arcBase * (0.58 + (0.28 * waveB))
                    strandOffsetC = arcBase * (1.90 + (0.45 * flow))
                    strandAlpha = alpha * 0.46
                    strandAlphaC = alpha * 0.34
                elseif style == "clean_streak" then
                    coreRed = Lerp(coreRed, 1.0, 0.10)
                    coreGreen = Lerp(coreGreen, 0.98, 0.10)
                    coreBlue = Lerp(coreBlue, 0.95, 0.10)
                    coreThickness = coreThickness * 1.05
                    glowThickness = coreThickness * 1.9
                    glowRed = Lerp(coreRed, 1.0, 0.15)
                    glowGreen = Lerp(coreGreen, 0.95, 0.15)
                    glowBlue = Lerp(coreBlue, 0.82, 0.10)
                    glowAlpha = alpha * 0.23
                    strandOffsetA = 0
                    strandOffsetB = 0
                    strandAlpha = 0
                    strandOffsetC = 0
                    strandAlphaC = 0
                else
                    if useClassColor then
                        coreRed = Lerp(coreRed, 0.70, 0.24)
                        coreGreen = Lerp(coreGreen, 0.86, 0.24)
                        coreBlue = Lerp(coreBlue, 1.0, 0.28)
                    else
                        coreRed = Lerp(coreRed, 0.70, 0.62)
                        coreGreen = Lerp(coreGreen, 0.86, 0.62)
                        coreBlue = Lerp(coreBlue, 1.0, 0.76)
                    end
                    coreThickness = coreThickness * 1.03
                    glowThickness = coreThickness * 2.4
                    if useClassColor then
                        glowRed = Lerp(coreRed, 0.72, 0.18)
                        glowGreen = Lerp(coreGreen, 0.84, 0.18)
                        glowBlue = Lerp(coreBlue, 1.0, 0.22)
                    else
                        glowRed = 0.72
                        glowGreen = 0.84
                        glowBlue = 1.0
                    end
                    glowAlpha = alpha * 0.36
                    strandOffsetA = baseOffset * (0.52 + (0.24 * waveA))
                    strandOffsetB = -baseOffset * (0.64 + (0.30 * waveB))
                    strandAlpha = alpha * 0.44
                    strandOffsetC = strandOffsetB
                    strandAlphaC = strandAlpha * 0.84
                end

                local nx = -dy / distance
                local ny = dx / distance
                local x1 = p1.x
                local y1 = p1.y
                local x2 = p2.x
                local y2 = p2.y

                coreLine:SetStartPoint("BOTTOMLEFT", UIParent, x1, y1)
                coreLine:SetEndPoint("BOTTOMLEFT", UIParent, x2, y2)
                coreLine:SetThickness(coreThickness)
                coreLine:SetColorTexture(coreRed, coreGreen, coreBlue, alpha)
                coreLine:Show()

                glowLine:SetStartPoint("BOTTOMLEFT", UIParent, x1, y1)
                glowLine:SetEndPoint("BOTTOMLEFT", UIParent, x2, y2)
                glowLine:SetThickness(glowThickness)
                glowLine:SetColorTexture(glowRed, glowGreen, glowBlue, glowAlpha)
                glowLine:Show()

                if style == "clean_streak" then
                    accentLine:Hide()
                    branchLine:Hide()
                else
                    local ax1 = x1 + (nx * strandOffsetA)
                    local ay1 = y1 + (ny * strandOffsetA)
                    local ax2 = x2 + (nx * strandOffsetA)
                    local ay2 = y2 + (ny * strandOffsetA)

                    local bx1 = x1 + (nx * strandOffsetB)
                    local by1 = y1 + (ny * strandOffsetB)
                    local bx2 = x2 + (nx * strandOffsetB)
                    local by2 = y2 + (ny * strandOffsetB)

                    local cx1 = x1 + (nx * strandOffsetC)
                    local cy1 = y1 + (ny * strandOffsetC)
                    local cx2 = x2 + (nx * strandOffsetC)
                    local cy2 = y2 + (ny * strandOffsetC)

                    accentLine:SetStartPoint("BOTTOMLEFT", UIParent, ax1, ay1)
                    accentLine:SetEndPoint("BOTTOMLEFT", UIParent, ax2, ay2)
                    accentLine:SetThickness(math.max(1.0, coreThickness * 0.72))
                    accentLine:SetColorTexture(glowRed, glowGreen, glowBlue, strandAlpha)
                    accentLine:Show()

                    if style == "arc_ribbons" then
                        branchLine:SetStartPoint("BOTTOMLEFT", UIParent, cx1, cy1)
                        branchLine:SetEndPoint("BOTTOMLEFT", UIParent, cx2, cy2)
                        branchLine:SetThickness(math.max(1.0, coreThickness * 0.56))
                        branchLine:SetColorTexture(0.80, 0.90, 1.0, strandAlphaC)
                        branchLine:Show()
                    else
                        branchLine:SetStartPoint("BOTTOMLEFT", UIParent, bx1, by1)
                        branchLine:SetEndPoint("BOTTOMLEFT", UIParent, bx2, by2)
                        branchLine:SetThickness(math.max(1.0, coreThickness * 0.52))
                        branchLine:SetColorTexture(glowRed, glowGreen, glowBlue, strandAlpha * 0.84)
                        branchLine:Show()
                    end
                end
            else
                coreLine:Hide()
                glowLine:Hide()
                accentLine:Hide()
                branchLine:Hide()
            end
        else
            coreLine:Hide()
            glowLine:Hide()
            accentLine:Hide()
            branchLine:Hide()
        end
    end

    for index = segmentCount + 1, #trailCoreLines do
        trailCoreLines[index]:Hide()
    end

    for index = segmentCount + 1, #trailGlowLines do
        trailGlowLines[index]:Hide()
    end

    for index = segmentCount + 1, #trailAccentLines do
        trailAccentLines[index]:Hide()
    end

    for index = segmentCount + 1, #trailBranchLines do
        trailBranchLines[index]:Hide()
    end
end

local function IsVisualFeatureEnabled(db)
    if db.enabled ~= true then
        return false
    end

    return db.circleEnabled == true or db.trailEnabled == true or db.castRingEnabled == true
end

local function ShouldShowCircle(db)
    if db.enabled ~= true or db.circleEnabled ~= true then
        return false
    end

    if db.circleCombatOnly == true then
        return InCombatLockdown and InCombatLockdown() or false
    end

    return true
end

local function ShouldShowCastRing(db)
    return db.enabled == true and db.castRingEnabled == true
end

local function ApplyVisualState()
    local db = MouseHelper.GetDB()
    local shouldRunRuntime = db.enabled == true and (db.trailEnabled == true or ShouldShowCircle(db) or ShouldShowCastRing(db))

    if not IsVisualFeatureEnabled(db) or not shouldRunRuntime then
        RuntimeFrame:SetScript("OnUpdate", nil)
        RuntimeFrame:Hide()
        CursorCircleFrame:Hide()
        HideCastRing()
        if db.trailEnabled ~= true then
            TrailFrame:Hide()
            ClearTrail()
        end
        return
    end

    RuntimeFrame:SetScript("OnUpdate", MouseHelperRuntimeOnUpdate)
    RuntimeFrame:Show()

    if ShouldShowCircle(db) then
        ApplyCircleVisual(db)
        CursorCircleFrame:Show()
    else
        CursorCircleFrame:Hide()
    end

    if ShouldShowCastRing(db) then
        CastRingFrame:Show()
    else
        HideCastRing()
    end

    if db.trailEnabled == true then
        TrailFrame:Show()
    else
        TrailFrame:Hide()
        ClearTrail()
    end
end

local function PushTrailPoint(cursorX, cursorY, maxCount)
    lastTrailSampleX = cursorX
    lastTrailSampleY = cursorY
    table.insert(trailPoints, 1, { x = cursorX, y = cursorY })

    while #trailPoints > maxCount do
        table.remove(trailPoints)
    end
end

local function HandleMouseHelperRuntimeUpdate(_, elapsed)
    local db = MouseHelper.GetDB()

    if not IsVisualFeatureEnabled(db) then
        return
    end

    local cursorX, cursorY = GetCursorUiPosition()

    if ShouldShowCircle(db) then
        ApplyCircleVisual(db)
        CursorCircleFrame:ClearAllPoints()
        CursorCircleFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX, cursorY)
        CursorCircleFrame:Show()
    else
        CursorCircleFrame:Hide()
    end

    if ShouldShowCastRing(db) then
        local castProgress = GetCastRingProgress()
        if castProgress ~= nil then
            CastRingFrame:ClearAllPoints()
            CastRingFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX, cursorY)
            DrawCastRing(db, castProgress)
        else
            HideCastRing()
        end
    else
        HideCastRing()
    end

    if db.trailEnabled ~= true then
        return
    end

    trailRenderAccumulator = trailRenderAccumulator + elapsed
    sampleAccumulator = sampleAccumulator + elapsed
    while sampleAccumulator >= TRAIL_SAMPLE_INTERVAL do
        sampleAccumulator = sampleAccumulator - TRAIL_SAMPLE_INTERVAL
        local deltaX = cursorX - (lastTrailSampleX or cursorX)
        local deltaY = cursorY - (lastTrailSampleY or cursorY)
        local movedEnough = ((deltaX * deltaX) + (deltaY * deltaY)) >= 1

        if movedEnough or #trailPoints == 0 then
            trailFadeAccumulator = 0
            PushTrailPoint(cursorX, cursorY, db.trailLength + 4)
        elseif #trailPoints > 0 then
            trailFadeAccumulator = trailFadeAccumulator + TRAIL_SAMPLE_INTERVAL
            while trailFadeAccumulator >= TRAIL_IDLE_FADE_INTERVAL and #trailPoints > 0 do
                trailFadeAccumulator = trailFadeAccumulator - TRAIL_IDLE_FADE_INTERVAL
                table.remove(trailPoints)
            end
        end
    end

    if trailRenderAccumulator >= TRAIL_RENDER_INTERVAL then
        trailRenderAccumulator = trailRenderAccumulator - TRAIL_RENDER_INTERVAL
        DrawTrail(db)
    end
end

MouseHelperRuntimeOnUpdate = function(_, elapsed)
    local profiler = BeavisQoL.PerformanceProfiler
    local sampleToken = profiler and profiler.BeginSample and profiler.BeginSample()
    HandleMouseHelperRuntimeUpdate(_, elapsed)
    if profiler and profiler.EndSample then
        profiler.EndSample("MouseHelper.OnUpdate", sampleToken)
    end
end

RuntimeFrame:SetScript("OnUpdate", MouseHelperRuntimeOnUpdate)

function MouseHelper.SetEnabled(enabled)
    MouseHelper.GetDB().enabled = enabled == true
    ApplyVisualState()
end

function MouseHelper.SetBlizzardLargeCursor(enabled)
    MouseHelper.GetDB().blizzardCursorSize = (enabled == true) and "64" or "default"
    ApplyBlizzardCursorSize()
end

function MouseHelper.GetBlizzardLargeCursorState()
    local db = MouseHelper.GetDB()
    return db.blizzardCursorSize == "64"
end

function MouseHelper.SetBlizzardCursorSize(preset)
    local db = MouseHelper.GetDB()
    if preset ~= "default"
        and preset ~= "32"
        and preset ~= "48"
        and preset ~= "64"
        and preset ~= "96"
        and preset ~= "128"
    then
        preset = "default"
    end

    db.blizzardCursorSize = preset
    ApplyBlizzardCursorSize()
end

function MouseHelper.GetBlizzardCursorSize()
    return MouseHelper.GetDB().blizzardCursorSize
end

function MouseHelper.SetTrailStyle(style)
    local db = MouseHelper.GetDB()
    if not IsValidTrailStyle(style) then
        style = DEFAULT_TRAIL_STYLE
    end

    db.trailStyle = style
    ApplyVisualState()
end

function MouseHelper.SetTrailUseClassColor(enabled)
    MouseHelper.GetDB().trailUseClassColor = enabled == true
    ApplyVisualState()
end

function MouseHelper.SetCircleUseClassColor(enabled)
    MouseHelper.GetDB().circleUseClassColor = enabled == true
    ApplyVisualState()
end

function MouseHelper.SetCircleCombatOnly(enabled)
    MouseHelper.GetDB().circleCombatOnly = enabled == true
    ApplyVisualState()
end

function MouseHelper.SetCastRingEnabled(enabled)
    MouseHelper.GetDB().castRingEnabled = enabled == true
    ApplyVisualState()
end

local function RefreshPageIfVisible()
    local page = BeavisQoL.Pages and BeavisQoL.Pages.MouseHelper
    if page and page:IsShown() and page.RefreshState then
        page:RefreshState()
    end
end

local LoginWatcher = CreateFrame("Frame")
LoginWatcher:RegisterEvent("PLAYER_LOGIN")
LoginWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
LoginWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
LoginWatcher:SetScript("OnEvent", function()
    MouseHelper.GetDB()
    ApplyBlizzardCursorSize()
    ApplyVisualState()
    RefreshPageIfVisible()
end)

local PageMouseHelper = CreateFrame("Frame", nil, Content)
PageMouseHelper:SetAllPoints()
PageMouseHelper:Hide()

local PageScrollFrame = CreateFrame("ScrollFrame", nil, PageMouseHelper, "UIPanelScrollFrameTemplate")
PageScrollFrame:SetPoint("TOPLEFT", PageMouseHelper, "TOPLEFT", 0, 0)
PageScrollFrame:SetPoint("BOTTOMRIGHT", PageMouseHelper, "BOTTOMRIGHT", -28, 0)
PageScrollFrame:EnableMouseWheel(true)

local PageContent = CreateFrame("Frame", nil, PageScrollFrame)
PageContent:SetSize(1, 1)
PageScrollFrame:SetScrollChild(PageContent)

local function FormatValue(value)
    if math.abs(value - math.floor(value)) < 0.01 then
        return tostring(math.floor(value))
    end

    return string.format("%.1f", value)
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step)
    sliderCounter = sliderCounter + 1
    local sliderName = "BeavisQoLMouseHelperSlider" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetWidth(320)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.Text = _G[sliderName .. "Text"]
    slider.Low = _G[sliderName .. "Low"]
    slider.High = _G[sliderName .. "High"]

    slider.Text:SetText(labelText)
    slider.Text:SetTextColor(1, 0.88, 0.62, 1)
    slider.Low:SetText(FormatValue(minValue))
    slider.High:SetText(FormatValue(maxValue))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(0.95, 0.91, 0.85, 1)

    slider:SetScript("OnValueChanged", function(self, value)
        self.ValueText:SetText(FormatValue(value))

        if isRefreshing or not self.ApplyValue then
            return
        end

        self:ApplyValue(value)
    end)

    return slider
end

local function OpenColorPicker(initialColor, onChanged)
    initialColor = CopyColor(initialColor)

    local function ReadCurrentColor()
        local red, green, blue = ColorPickerFrame:GetColorRGB()
        local opacity = 0

        if ColorPickerFrame.GetColorAlpha then
            local info = ColorPickerFrame:GetColorAlpha()
            if type(info) == "table" then
                red = info.r or red
                green = info.g or green
                blue = info.b or blue
                opacity = info.opacity or 0
            end
        elseif OpacitySliderFrameRef then
            opacity = OpacitySliderFrameRef:GetValue() or 0
        end

        return red, green, blue, 1 - opacity
    end

    local function ApplyCurrentColor()
        local red, green, blue, alpha = ReadCurrentColor()
        onChanged(red, green, blue, alpha)
    end

    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = initialColor.r,
            g = initialColor.g,
            b = initialColor.b,
            opacity = 1 - initialColor.a,
            hasOpacity = true,
            swatchFunc = function()
                local red, green, blue, alpha = ReadCurrentColor()
                onChanged(red, green, blue, alpha)
            end,
            opacityFunc = function()
                local red, green, blue, alpha = ReadCurrentColor()
                onChanged(red, green, blue, alpha)
            end,
            cancelFunc = function(previous)
                if type(previous) ~= "table" then
                    return
                end

                onChanged(previous.r, previous.g, previous.b, 1 - (previous.opacity or 0))
            end,
        })
        return
    end

    ColorPickerFrame.func = ApplyCurrentColor
    ColorPickerFrame.opacityFunc = ApplyCurrentColor
    ColorPickerFrame.cancelFunc = function(previous)
        if type(previous) ~= "table" then
            return
        end

        onChanged(previous.r, previous.g, previous.b, 1 - (previous.opacity or 0))
    end
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - initialColor.a
    ColorPickerFrame:SetColorRGB(initialColor.r, initialColor.g, initialColor.b)
    ColorPickerFrame.previousValues = {
        r = initialColor.r,
        g = initialColor.g,
        b = initialColor.b,
        opacity = 1 - initialColor.a,
    }
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local function CreateColorButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(140, 24)

    button.Swatch = button:CreateTexture(nil, "ARTWORK")
    button.Swatch:SetSize(16, 16)
    button.Swatch:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    button.Swatch:SetTexture(COLOR_TEXTURE)

    return button
end

local IntroPanel = CreateFrame("Frame", nil, PageContent)
IntroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(126)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
IntroTitle:SetTextColor(1, 0.88, 0.62, 1)

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)

local GeneralPanel = CreateFrame("Frame", nil, PageContent)
GeneralPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
GeneralPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
GeneralPanel:SetHeight(176)

local GeneralBg = GeneralPanel:CreateTexture(nil, "BACKGROUND")
GeneralBg:SetAllPoints()
GeneralBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local GeneralBorder = GeneralPanel:CreateTexture(nil, "ARTWORK")
GeneralBorder:SetPoint("BOTTOMLEFT", GeneralPanel, "BOTTOMLEFT", 0, 0)
GeneralBorder:SetPoint("BOTTOMRIGHT", GeneralPanel, "BOTTOMRIGHT", 0, 0)
GeneralBorder:SetHeight(1)
GeneralBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local GeneralTitle = GeneralPanel:CreateFontString(nil, "OVERLAY")
GeneralTitle:SetPoint("TOPLEFT", GeneralPanel, "TOPLEFT", 18, -14)
GeneralTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
GeneralTitle:SetTextColor(1, 0.88, 0.62, 1)

local GeneralEnableCheckbox = CreateFrame("CheckButton", nil, GeneralPanel, "UICheckButtonTemplate")
GeneralEnableCheckbox:SetPoint("TOPLEFT", GeneralTitle, "BOTTOMLEFT", -4, -10)

local GeneralEnableLabel = GeneralPanel:CreateFontString(nil, "OVERLAY")
GeneralEnableLabel:SetPoint("LEFT", GeneralEnableCheckbox, "RIGHT", 6, 0)
GeneralEnableLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
GeneralEnableLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local BlizzardCursorCheckbox = CreateFrame("CheckButton", nil, GeneralPanel, "UICheckButtonTemplate")
BlizzardCursorCheckbox:SetPoint("TOPLEFT", GeneralEnableCheckbox, "BOTTOMLEFT", 0, -14)
BlizzardCursorCheckbox:Hide()

local BlizzardCursorLabel = GeneralPanel:CreateFontString(nil, "OVERLAY")
BlizzardCursorLabel:SetPoint("LEFT", BlizzardCursorCheckbox, "RIGHT", 6, 0)
BlizzardCursorLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
BlizzardCursorLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local BlizzardCursorHint = GeneralPanel:CreateFontString(nil, "OVERLAY")
BlizzardCursorHint:SetPoint("TOPLEFT", BlizzardCursorCheckbox, "BOTTOMLEFT", 34, -44)
BlizzardCursorHint:SetPoint("RIGHT", GeneralPanel, "RIGHT", -18, 0)
BlizzardCursorHint:SetJustifyH("LEFT")
BlizzardCursorHint:SetJustifyV("TOP")
BlizzardCursorHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
BlizzardCursorHint:SetTextColor(0.78, 0.74, 0.69, 1)

local CursorSizeLabel = GeneralPanel:CreateFontString(nil, "OVERLAY")
CursorSizeLabel:SetPoint("TOPLEFT", GeneralEnableCheckbox, "BOTTOMLEFT", 34, -8)
CursorSizeLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CursorSizeLabel:SetTextColor(1, 0.88, 0.62, 1)

CursorSizeDropdown = CreateFrame("Frame", "BeavisQoLMouseHelperCursorSizeDropdown", GeneralPanel, "UIDropDownMenuTemplate")
CursorSizeDropdown:SetPoint("TOPLEFT", CursorSizeLabel, "BOTTOMLEFT", -18, -2)
UIDropDownMenu_SetWidth(CursorSizeDropdown, 150)

local CirclePanel = CreateFrame("Frame", nil, PageContent)
CirclePanel:SetPoint("TOPLEFT", GeneralPanel, "BOTTOMLEFT", 0, -18)
CirclePanel:SetPoint("TOPRIGHT", GeneralPanel, "BOTTOMRIGHT", 0, -18)
CirclePanel:SetHeight(362)

local CircleBg = CirclePanel:CreateTexture(nil, "BACKGROUND")
CircleBg:SetAllPoints()
CircleBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local CircleBorder = CirclePanel:CreateTexture(nil, "ARTWORK")
CircleBorder:SetPoint("BOTTOMLEFT", CirclePanel, "BOTTOMLEFT", 0, 0)
CircleBorder:SetPoint("BOTTOMRIGHT", CirclePanel, "BOTTOMRIGHT", 0, 0)
CircleBorder:SetHeight(1)
CircleBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local CircleTitle = CirclePanel:CreateFontString(nil, "OVERLAY")
CircleTitle:SetPoint("TOPLEFT", CirclePanel, "TOPLEFT", 18, -14)
CircleTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CircleTitle:SetTextColor(1, 0.88, 0.62, 1)

local CircleCheckbox = CreateFrame("CheckButton", nil, CirclePanel, "UICheckButtonTemplate")
CircleCheckbox:SetPoint("TOPLEFT", CircleTitle, "BOTTOMLEFT", -4, -10)

local CircleLabel = CirclePanel:CreateFontString(nil, "OVERLAY")
CircleLabel:SetPoint("LEFT", CircleCheckbox, "RIGHT", 6, 0)
CircleLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CircleLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local CircleCombatOnlyCheckbox = CreateFrame("CheckButton", nil, CirclePanel, "UICheckButtonTemplate")
CircleCombatOnlyCheckbox:SetPoint("TOPLEFT", CircleCheckbox, "BOTTOMLEFT", 0, -10)

local CircleCombatOnlyLabel = CirclePanel:CreateFontString(nil, "OVERLAY")
CircleCombatOnlyLabel:SetPoint("LEFT", CircleCombatOnlyCheckbox, "RIGHT", 6, 0)
CircleCombatOnlyLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CircleCombatOnlyLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local CastRingCheckbox = CreateFrame("CheckButton", nil, CirclePanel, "UICheckButtonTemplate")
CastRingCheckbox:SetPoint("TOPLEFT", CircleCombatOnlyCheckbox, "BOTTOMLEFT", 0, -10)

local CastRingLabel = CirclePanel:CreateFontString(nil, "OVERLAY")
CastRingLabel:SetPoint("LEFT", CastRingCheckbox, "RIGHT", 6, 0)
CastRingLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CastRingLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local CircleClassColorCheckbox = CreateFrame("CheckButton", nil, CirclePanel, "UICheckButtonTemplate")
CircleClassColorCheckbox:SetPoint("TOPLEFT", CastRingCheckbox, "BOTTOMLEFT", 0, -10)

local CircleClassColorLabel = CirclePanel:CreateFontString(nil, "OVERLAY")
CircleClassColorLabel:SetPoint("LEFT", CircleClassColorCheckbox, "RIGHT", 6, 0)
CircleClassColorLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CircleClassColorLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local CircleSizeSlider = CreateValueSlider(CirclePanel, "", 24, 180, 1)
CircleSizeSlider:SetPoint("TOPLEFT", CircleClassColorCheckbox, "BOTTOMLEFT", 10, -24)

local CircleThicknessSlider = CreateValueSlider(CirclePanel, "", 2, 20, 1)
CircleThicknessSlider:SetPoint("TOPLEFT", CircleSizeSlider, "BOTTOMLEFT", 0, -48)

local CircleColorButton = CreateColorButton(CirclePanel)
CircleColorButton:SetPoint("TOPLEFT", CircleThicknessSlider, "BOTTOMLEFT", -10, -20)

local CastRingColorButton = CreateColorButton(CirclePanel)
CastRingColorButton:SetPoint("LEFT", CircleColorButton, "RIGHT", 14, 0)

local TrailPanel = CreateFrame("Frame", nil, PageContent)
TrailPanel:SetPoint("TOPLEFT", CirclePanel, "BOTTOMLEFT", 0, -18)
TrailPanel:SetPoint("TOPRIGHT", CirclePanel, "BOTTOMRIGHT", 0, -18)
TrailPanel:SetHeight(340)

local TrailBg = TrailPanel:CreateTexture(nil, "BACKGROUND")
TrailBg:SetAllPoints()
TrailBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local TrailBorder = TrailPanel:CreateTexture(nil, "ARTWORK")
TrailBorder:SetPoint("BOTTOMLEFT", TrailPanel, "BOTTOMLEFT", 0, 0)
TrailBorder:SetPoint("BOTTOMRIGHT", TrailPanel, "BOTTOMRIGHT", 0, 0)
TrailBorder:SetHeight(1)
TrailBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local TrailTitle = TrailPanel:CreateFontString(nil, "OVERLAY")
TrailTitle:SetPoint("TOPLEFT", TrailPanel, "TOPLEFT", 18, -14)
TrailTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
TrailTitle:SetTextColor(1, 0.88, 0.62, 1)

local TrailCheckbox = CreateFrame("CheckButton", nil, TrailPanel, "UICheckButtonTemplate")
TrailCheckbox:SetPoint("TOPLEFT", TrailTitle, "BOTTOMLEFT", -4, -10)

local TrailLabel = TrailPanel:CreateFontString(nil, "OVERLAY")
TrailLabel:SetPoint("LEFT", TrailCheckbox, "RIGHT", 6, 0)
TrailLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrailLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local TrailLengthSlider = CreateValueSlider(TrailPanel, "", 6, 60, 1)
TrailLengthSlider:SetPoint("TOPLEFT", TrailCheckbox, "BOTTOMLEFT", 10, -24)

local TrailSizeSlider = CreateValueSlider(TrailPanel, "", 3, 28, 1)
TrailSizeSlider:SetPoint("TOPLEFT", TrailLengthSlider, "BOTTOMLEFT", 0, -48)

local TrailStyleLabel = TrailPanel:CreateFontString(nil, "OVERLAY")
TrailStyleLabel:SetPoint("TOPLEFT", TrailSizeSlider, "BOTTOMLEFT", -10, -14)
TrailStyleLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrailStyleLabel:SetTextColor(1, 0.88, 0.62, 1)

local TrailStyleDropdown = CreateFrame("Frame", "BeavisQoLMouseHelperTrailStyleDropdown", TrailPanel, "UIDropDownMenuTemplate")
TrailStyleDropdown:SetPoint("TOPLEFT", TrailStyleLabel, "BOTTOMLEFT", -18, -2)
UIDropDownMenu_SetWidth(TrailStyleDropdown, 170)

local TrailClassColorCheckbox = CreateFrame("CheckButton", nil, TrailPanel, "UICheckButtonTemplate")
TrailClassColorCheckbox:SetPoint("TOPLEFT", TrailStyleDropdown, "BOTTOMLEFT", 18, -6)

local TrailClassColorLabel = TrailPanel:CreateFontString(nil, "OVERLAY")
TrailClassColorLabel:SetPoint("LEFT", TrailClassColorCheckbox, "RIGHT", 6, 0)
TrailClassColorLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
TrailClassColorLabel:SetTextColor(0.95, 0.91, 0.85, 1)

local TrailColorButton = CreateColorButton(TrailPanel)
TrailColorButton:SetPoint("TOPLEFT", TrailClassColorCheckbox, "BOTTOMLEFT", 10, -10)

local function SetButtonSwatchColor(button, color)
    button.Swatch:SetVertexColor(color.r, color.g, color.b, color.a)
end

local function SetControlsEnabled(masterEnabled, db)
    CircleCheckbox:SetEnabled(masterEnabled)
    CircleCombatOnlyCheckbox:SetEnabled(masterEnabled and CircleCheckbox:GetChecked())
    CastRingCheckbox:SetEnabled(masterEnabled)
    CircleClassColorCheckbox:SetEnabled(masterEnabled and CircleCheckbox:GetChecked())
    CircleSizeSlider:SetEnabled(masterEnabled)
    CircleThicknessSlider:SetEnabled(masterEnabled)
    CircleColorButton:SetEnabled(masterEnabled and db.circleUseClassColor ~= true)
    CastRingColorButton:SetEnabled(masterEnabled and db.castRingEnabled == true)

    TrailCheckbox:SetEnabled(masterEnabled)
    TrailClassColorCheckbox:SetEnabled(masterEnabled)
    TrailLengthSlider:SetEnabled(masterEnabled)
    TrailSizeSlider:SetEnabled(masterEnabled)
    TrailColorButton:SetEnabled(masterEnabled and db.trailUseClassColor ~= true)

    if masterEnabled then
        UIDropDownMenu_EnableDropDown(TrailStyleDropdown)
    else
        UIDropDownMenu_DisableDropDown(TrailStyleDropdown)
    end
end

function PageMouseHelper:RefreshState()
    local db = MouseHelper.GetDB()
    isRefreshing = true

    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("MouseHelper", L("MOUSE_HELPER")))
    IntroText:SetText(L("MOUSE_HELPER_DESC"))

    GeneralTitle:SetText(L("MOUSE_HELPER_SETTINGS"))
    GeneralEnableLabel:SetText(L("MOUSE_HELPER_ENABLE"))
    CursorSizeLabel:SetText(L("MOUSE_HELPER_CURSOR_SIZE"))
    if IsAnyCursorSizeSupported() then
        UIDropDownMenu_EnableDropDown(CursorSizeDropdown)
    else
        UIDropDownMenu_DisableDropDown(CursorSizeDropdown)
    end

    CircleTitle:SetText(L("MOUSE_HELPER_CIRCLE_TITLE"))
    CircleLabel:SetText(L("MOUSE_HELPER_CIRCLE_ENABLE"))
    CircleCombatOnlyLabel:SetText(L("MOUSE_HELPER_CIRCLE_COMBAT_ONLY"))
    CastRingLabel:SetText(L("MOUSE_HELPER_CAST_RING_ENABLE"))
    CircleClassColorLabel:SetText(L("MOUSE_HELPER_CIRCLE_CLASS_COLOR"))
    CircleSizeSlider.Text:SetText(L("MOUSE_HELPER_CIRCLE_SIZE"))
    CircleThicknessSlider.Text:SetText(L("MOUSE_HELPER_CIRCLE_THICKNESS"))
    CircleColorButton:SetText(L("MOUSE_HELPER_COLOR_PICK"))
    CastRingColorButton:SetText(L("MOUSE_HELPER_CAST_RING_COLOR"))

    TrailTitle:SetText(L("MOUSE_HELPER_TRAIL_TITLE"))
    TrailLabel:SetText(L("MOUSE_HELPER_TRAIL_ENABLE"))
    TrailLengthSlider.Text:SetText(L("MOUSE_HELPER_TRAIL_LENGTH"))
    TrailSizeSlider.Text:SetText(L("MOUSE_HELPER_TRAIL_SIZE"))
    TrailStyleLabel:SetText(L("MOUSE_HELPER_TRAIL_STYLE"))
    TrailClassColorLabel:SetText(L("MOUSE_HELPER_TRAIL_CLASS_COLOR"))
    TrailColorButton:SetText(L("MOUSE_HELPER_COLOR_PICK"))

    GeneralEnableCheckbox:SetChecked(db.enabled)
    CircleCheckbox:SetChecked(db.circleEnabled)
    CircleCombatOnlyCheckbox:SetChecked(db.circleCombatOnly)
    CastRingCheckbox:SetChecked(db.castRingEnabled)
    CircleClassColorCheckbox:SetChecked(db.circleUseClassColor)
    TrailCheckbox:SetChecked(db.trailEnabled)
    TrailClassColorCheckbox:SetChecked(db.trailUseClassColor)

    CircleSizeSlider:SetValue(db.circleSize)
    CircleThicknessSlider:SetValue(db.circleThickness)
    TrailLengthSlider:SetValue(db.trailLength)
    TrailSizeSlider:SetValue(db.trailSize)

    UIDropDownMenu_SetSelectedValue(CursorSizeDropdown, db.blizzardCursorSize)
    if db.blizzardCursorSize == "48" then
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_48"))
    elseif db.blizzardCursorSize == "64" then
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_64"))
    elseif db.blizzardCursorSize == "32" then
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_32"))
    elseif db.blizzardCursorSize == "96" then
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_96"))
    elseif db.blizzardCursorSize == "128" then
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_128"))
    else
        UIDropDownMenu_SetText(CursorSizeDropdown, L("MOUSE_HELPER_CURSOR_SIZE_DEFAULT"))
    end

    UIDropDownMenu_SetSelectedValue(TrailStyleDropdown, db.trailStyle)
    for _, option in ipairs(TRAIL_STYLE_OPTIONS) do
        if option.value == db.trailStyle then
            UIDropDownMenu_SetText(TrailStyleDropdown, L(option.textKey))
            break
        end
    end

    SetButtonSwatchColor(CircleColorButton, GetCircleDisplayColor(db))
    SetButtonSwatchColor(CastRingColorButton, db.castRingColor)
    SetButtonSwatchColor(TrailColorButton, GetTrailDisplayColor(db))
    SetControlsEnabled(db.enabled == true, db)

    isRefreshing = false
end

function PageMouseHelper:UpdateScrollLayout()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + GeneralPanel:GetHeight()
        + 18 + CirclePanel:GetHeight()
        + 18 + TrailPanel:GetHeight()
        + 20

    PageContent:SetWidth(contentWidth)
    PageContent:SetHeight(contentHeight)
end

PageScrollFrame:SetScript("OnSizeChanged", function()
    PageMouseHelper:UpdateScrollLayout()
end)

PageScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
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

GeneralEnableCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetEnabled(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

BlizzardCursorCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetBlizzardLargeCursor(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

UIDropDownMenu_Initialize(CursorSizeDropdown, function(_, level)
    local options = {
        { text = L("MOUSE_HELPER_CURSOR_SIZE_DEFAULT"), value = "default" },
        { text = L("MOUSE_HELPER_CURSOR_SIZE_32"), value = "32" },
        { text = L("MOUSE_HELPER_CURSOR_SIZE_48"), value = "48" },
        { text = L("MOUSE_HELPER_CURSOR_SIZE_64"), value = "64" },
        { text = L("MOUSE_HELPER_CURSOR_SIZE_96"), value = "96" },
        { text = L("MOUSE_HELPER_CURSOR_SIZE_128"), value = "128" },
    }

    for _, option in ipairs(options) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.func = function()
            MouseHelper.SetBlizzardCursorSize(option.value)
            UIDropDownMenu_SetSelectedValue(CursorSizeDropdown, option.value)
            PageMouseHelper:RefreshState()
        end
        info.checked = (MouseHelper.GetBlizzardCursorSize() == option.value)
        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_Initialize(TrailStyleDropdown, function(_, level)
    for _, option in ipairs(TRAIL_STYLE_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = L(option.textKey)
        info.value = option.value
        info.func = function()
            MouseHelper.SetTrailStyle(option.value)
            UIDropDownMenu_SetSelectedValue(TrailStyleDropdown, option.value)
            PageMouseHelper:RefreshState()
        end
        info.checked = (MouseHelper.GetDB().trailStyle == option.value)
        UIDropDownMenu_AddButton(info, level)
    end
end)

CircleCheckbox:SetScript("OnClick", function(self)
    local db = MouseHelper.GetDB()
    db.circleEnabled = self:GetChecked() == true
    ApplyVisualState()
    PageMouseHelper:RefreshState()
end)

CircleCombatOnlyCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetCircleCombatOnly(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

CastRingCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetCastRingEnabled(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

CircleClassColorCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetCircleUseClassColor(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

CircleSizeSlider.ApplyValue = function(_, value)
    MouseHelper.GetDB().circleSize = Clamp(value, 24, 180)
    ApplyVisualState()
end

CircleThicknessSlider.ApplyValue = function(_, value)
    MouseHelper.GetDB().circleThickness = Clamp(value, 2, 20)
    ApplyVisualState()
end

CircleColorButton:SetScript("OnClick", function()
    local db = MouseHelper.GetDB()
    OpenColorPicker(db.circleColor, function(red, green, blue, alpha)
        db.circleColor = CopyColor({ r = red, g = green, b = blue, a = alpha })
        ApplyVisualState()
        PageMouseHelper:RefreshState()
    end)
end)

CastRingColorButton:SetScript("OnClick", function()
    local db = MouseHelper.GetDB()
    OpenColorPicker(db.castRingColor, function(red, green, blue, alpha)
        db.castRingColor = CopyColor({ r = red, g = green, b = blue, a = alpha })
        ApplyVisualState()
        PageMouseHelper:RefreshState()
    end)
end)

TrailCheckbox:SetScript("OnClick", function(self)
    local db = MouseHelper.GetDB()
    db.trailEnabled = self:GetChecked() == true
    ApplyVisualState()
    PageMouseHelper:RefreshState()
end)

TrailClassColorCheckbox:SetScript("OnClick", function(self)
    MouseHelper.SetTrailUseClassColor(self:GetChecked())
    PageMouseHelper:RefreshState()
end)

TrailLengthSlider.ApplyValue = function(_, value)
    MouseHelper.GetDB().trailLength = Clamp(math.floor(value), 6, 60)
    ApplyVisualState()
end

TrailSizeSlider.ApplyValue = function(_, value)
    MouseHelper.GetDB().trailSize = Clamp(value, 3, 28)
    ApplyVisualState()
end

TrailColorButton:SetScript("OnClick", function()
    local db = MouseHelper.GetDB()
    OpenColorPicker(db.trailColor, function(red, green, blue, alpha)
        db.trailColor = CopyColor({ r = red, g = green, b = blue, a = alpha })
        ApplyVisualState()
        PageMouseHelper:RefreshState()
    end)
end)

PageMouseHelper:SetScript("OnShow", function()
    PageMouseHelper:RefreshState()
    PageMouseHelper:UpdateScrollLayout()
    PageScrollFrame:SetVerticalScroll(0)
end)

PageMouseHelper:UpdateScrollLayout()
PageMouseHelper:RefreshState()

BeavisQoL.Pages.MouseHelper = PageMouseHelper

