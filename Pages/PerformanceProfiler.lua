local ADDON_NAME, BeavisQoL = ...

local unpackValues = (type(table) == "table" and rawget(table, "unpack")) or rawget(_G, "unpack")
local SAMPLE_INTERVAL_SECONDS = 2
local MAX_STORED_SAMPLES = 180
local MAX_SAMPLE_ENTRIES = 6
local MAX_REPORT_ENTRIES = 10
local MAX_ADDON_SAMPLE_ENTRIES = 20
local REPORT_WINDOW_WIDTH = 760
local REPORT_WINDOW_HEIGHT = 520

BeavisQoL.PerformanceProfiler = BeavisQoL.PerformanceProfiler or {}
local Profiler = BeavisQoL.PerformanceProfiler

local WrappedOwners = setmetatable({}, { __mode = "k" })
local intervalElapsed = 0
local intervalStats = {}
local intervalTotalMs = 0
local intervalCallCount = 0
local lastObservedAddonCpuMs = nil
local ReportFrame
local ReportTitleText
local ReportEditBox
local ReportScrollFrame
local BuildRecentAggregate
local FlushCurrentInterval

local SamplerFrame = CreateFrame("Frame")
SamplerFrame:Hide()

local AddOnsAPI = rawget(_G, "C_AddOns")
local legacyGetNumAddOns = rawget(_G, "GetNumAddOns")
local legacyGetAddOnInfo = rawget(_G, "GetAddOnInfo")
local legacyIsAddOnLoaded = rawget(_G, "IsAddOnLoaded")

local function TrimText(text)
    return tostring(text or ""):match("^%s*(.-)%s*$") or ""
end

local function PrintProfilerMessage(messageText)
    local finalText = string.format("|cffffd200[BeavisQoL CPU]|r %s", tostring(messageText or ""))

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(finalText)
        return
    end

    print(finalText)
end

local function PrintBeavisMessage(messageText)
    local finalText = string.format("|cff66d9efBeavisQoL:|r %s", tostring(messageText or ""))

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(finalText)
        return
    end

    print(finalText)
end

local function AppendLine(lines, text)
    lines[#lines + 1] = tostring(text or "")
end

local function PackResults(...)
    return {
        n = select("#", ...),
        ...
    }
end

local function GetAddOnCount()
    local getNumAddOns = (AddOnsAPI and AddOnsAPI.GetNumAddOns) or legacyGetNumAddOns
    if type(getNumAddOns) ~= "function" then
        return 0
    end

    return math.max(0, tonumber(getNumAddOns()) or 0)
end

local function GetAddOnInfoCompat(index)
    local getAddOnInfo = (AddOnsAPI and AddOnsAPI.GetAddOnInfo) or legacyGetAddOnInfo
    if type(getAddOnInfo) ~= "function" then
        return nil, nil
    end

    local info1, info2 = getAddOnInfo(index)
    if type(info1) == "table" then
        return info1.name or info1.Name, info1.title or info1.Title
    end

    return info1, info2
end

local function IsAddOnLoadedCompat(index, addonName)
    local isAddOnLoaded = (AddOnsAPI and AddOnsAPI.IsAddOnLoaded) or legacyIsAddOnLoaded
    if type(isAddOnLoaded) ~= "function" then
        return true
    end

    if type(addonName) == "string" and addonName ~= "" then
        return isAddOnLoaded(addonName) == true
    end

    return isAddOnLoaded(index) == true
end

local function GetProfilerDB()
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.performanceProfiler = BeavisQoLCharDB.performanceProfiler or {}

    local db = BeavisQoLCharDB.performanceProfiler

    if db.enabled == nil then
        db.enabled = false
    end

    if type(db.samples) ~= "table" then
        db.samples = {}
    end

    if type(db.totals) ~= "table" then
        db.totals = {}
    end

    if type(db.addonTotals) ~= "table" then
        db.addonTotals = {}
    end

    return db
end

local function IsScriptProfilingEnabled()
    if C_CVar and C_CVar.GetCVarBool then
        return C_CVar.GetCVarBool("scriptProfile") == true
    end

    local getCVarBool = rawget(_G, "GetCVarBool")
    if type(getCVarBool) == "function" then
        return getCVarBool("scriptProfile") == true
    end

    local getCVar = rawget(_G, "GetCVar")
    if type(getCVar) == "function" then
        return tostring(getCVar("scriptProfile")) == "1"
    end

    return false
end

local function ResetCurrentInterval()
    intervalElapsed = 0
    intervalStats = {}
    intervalTotalMs = 0
    intervalCallCount = 0
end

local function ResetAddonCpuBaseline()
    lastObservedAddonCpuMs = nil

    if not IsScriptProfilingEnabled()
        or type(UpdateAddOnCPUUsage) ~= "function"
        or type(GetAddOnCPUUsage) ~= "function"
        or GetAddOnCount() <= 0
    then
        return
    end

    UpdateAddOnCPUUsage()

    lastObservedAddonCpuMs = {}
    for index = 1, GetAddOnCount() do
        local addonName = GetAddOnInfoCompat(index)
        local isLoaded = IsAddOnLoadedCompat(index, addonName)

        if isLoaded and type(addonName) == "string" and addonName ~= "" then
            local currentCpuMs = tonumber(GetAddOnCPUUsage(index)) or 0
            lastObservedAddonCpuMs[addonName] = currentCpuMs
        end
    end
end

local function BuildTimestampLabel()
    if date then
        return date("%H:%M:%S")
    end

    if GetTime then
        return string.format("%.1f", GetTime())
    end

    return "?"
end

local function SortStats(statsByLabel)
    local entries = {}

    for label, stats in pairs(statsByLabel or {}) do
        entries[#entries + 1] = {
            label = label,
            totalMs = tonumber(stats.totalMs) or 0,
            calls = tonumber(stats.calls) or 0,
            maxMs = tonumber(stats.maxMs) or 0,
        }
    end

    table.sort(entries, function(left, right)
        if left.totalMs == right.totalMs then
            return tostring(left.label) < tostring(right.label)
        end

        return left.totalMs > right.totalMs
    end)

    return entries
end

local function SortAddonStats(statsByLabel)
    local entries = {}

    for label, stats in pairs(statsByLabel or {}) do
        entries[#entries + 1] = {
            label = label,
            totalMs = tonumber(stats.totalMs) or 0,
            samples = tonumber(stats.samples) or 0,
            maxMs = tonumber(stats.maxMs) or 0,
        }
    end

    table.sort(entries, function(left, right)
        if left.totalMs == right.totalMs then
            return tostring(left.label) < tostring(right.label)
        end

        return left.totalMs > right.totalMs
    end)

    return entries
end

local function CaptureAddonCpuInterval()
    local addonEntries = {}
    local observedAddonCpuMs = 0

    if not IsScriptProfilingEnabled()
        or type(UpdateAddOnCPUUsage) ~= "function"
        or type(GetAddOnCPUUsage) ~= "function"
        or GetAddOnCount() <= 0
    then
        return 0, 0, addonEntries
    end

    UpdateAddOnCPUUsage()

    local previousSnapshot = lastObservedAddonCpuMs or {}
    local nextSnapshot = {}

    for index = 1, GetAddOnCount() do
        local addonName = GetAddOnInfoCompat(index)
        local isLoaded = IsAddOnLoadedCompat(index, addonName)

        if isLoaded and type(addonName) == "string" and addonName ~= "" then
            local currentCpuMs = tonumber(GetAddOnCPUUsage(index)) or 0
            nextSnapshot[addonName] = currentCpuMs

            local previousCpuMs = tonumber(previousSnapshot[addonName])
            if previousCpuMs then
                local deltaMs = math.max(0, currentCpuMs - previousCpuMs)
                if deltaMs > 0 then
                    observedAddonCpuMs = observedAddonCpuMs + deltaMs
                    addonEntries[#addonEntries + 1] = {
                        label = addonName,
                        totalMs = deltaMs,
                        samples = 1,
                        maxMs = deltaMs,
                    }
                end
            end
        end
    end

    lastObservedAddonCpuMs = nextSnapshot

    table.sort(addonEntries, function(left, right)
        if left.totalMs == right.totalMs then
            return tostring(left.label) < tostring(right.label)
        end

        return left.totalMs > right.totalMs
    end)

    local storedEntries = {}
    for index = 1, math.min(MAX_ADDON_SAMPLE_ENTRIES, #addonEntries) do
        storedEntries[#storedEntries + 1] = addonEntries[index]
    end

    local addonCpuMs = 0
    for _, entry in ipairs(addonEntries) do
        if entry.label == ADDON_NAME then
            addonCpuMs = entry.totalMs
            break
        end
    end

    return addonCpuMs, observedAddonCpuMs, storedEntries, addonEntries
end

local function UpdateAddonTotals(entries)
    local addonTotals = GetProfilerDB().addonTotals

    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" and type(entry.label) == "string" and entry.label ~= "" then
            local totalEntry = addonTotals[entry.label]
            if not totalEntry then
                totalEntry = {
                    totalMs = 0,
                    samples = 0,
                    maxMs = 0,
                }
                addonTotals[entry.label] = totalEntry
            end

            totalEntry.totalMs = totalEntry.totalMs + (tonumber(entry.totalMs) or 0)
            totalEntry.samples = totalEntry.samples + 1
            totalEntry.maxMs = math.max(totalEntry.maxMs, tonumber(entry.maxMs) or 0)
        end
    end
end

local function BuildReportData()
    local db = GetProfilerDB()

    if Profiler.IsEnabled() then
        FlushCurrentInterval()
    end

    return {
        db = db,
        recent = BuildRecentAggregate(30),
        totals = SortStats(db.totals),
        addonTotals = SortAddonStats(db.addonTotals),
        timestamp = BuildTimestampLabel(),
        scriptProfileEnabled = IsScriptProfilingEnabled(),
    }
end

local function BuildReportLines(reportData)
    local recent = reportData.recent
    local totalEntries = reportData.totals
    local totalAddonEntries = reportData.addonTotals
    local lines = {}

    AppendLine(lines, "BeavisQoL CPU Report")
    AppendLine(lines, string.format("Zeit: %s", reportData.timestamp))
    AppendLine(lines, string.format("scriptProfile: %s", reportData.scriptProfileEnabled and "an" or "aus"))
    AppendLine(lines, string.format(
        "Samples: %d | gemessen: %.1f ms | Calls: %d | BeavisQoL CPU: %.1f ms | Beobachtete Addons: %.1f ms",
        recent.sampleCount,
        recent.measuredMs,
        recent.calls,
        recent.addonCpuMs,
        recent.observedAddonCpuMs
    ))
    AppendLine(lines, "")

    if recent.sampleCount <= 0 then
        AppendLine(lines, "Noch keine Daten vorhanden.")
        AppendLine(lines, "Nutze '/beavis cpu start', reproduziere das Problem und danach '/beavis cpu report'.")
        return lines
    end

    if reportData.scriptProfileEnabled then
        AppendLine(lines, "Addons letzte Samples:")
        if #recent.addonEntries > 0 then
            for index = 1, math.min(MAX_REPORT_ENTRIES, #recent.addonEntries) do
                local entry = recent.addonEntries[index]
                AppendLine(lines, string.format(
                    "%d. %s - %.1f ms | max %.1f ms | %d Samples",
                    index,
                    entry.label,
                    entry.totalMs,
                    entry.maxMs,
                    entry.samples
                ))
            end
        else
            AppendLine(lines, "Keine Addon-Vergleichsdaten in den letzten Samples.")
        end

        AppendLine(lines, "")
        AppendLine(lines, "Addons gesamte Session:")
        if #totalAddonEntries > 0 then
            for index = 1, math.min(MAX_REPORT_ENTRIES, #totalAddonEntries) do
                local entry = totalAddonEntries[index]
                AppendLine(lines, string.format(
                    "%d. %s - %.1f ms | max %.1f ms | %d Samples",
                    index,
                    entry.label,
                    entry.totalMs,
                    entry.maxMs,
                    entry.samples
                ))
            end
        else
            AppendLine(lines, "Noch keine Addon-Vergleichsdaten vorhanden.")
        end

        AppendLine(lines, "")
    else
        AppendLine(lines, "Addon-Vergleich nur mit '/console scriptProfile 1' und '/reload' verfügbar.")
        AppendLine(lines, "")
    end

    AppendLine(lines, "BeavisQoL Hotspots letzte Samples:")
    for index = 1, math.min(MAX_REPORT_ENTRIES, #recent.entries) do
        local entry = recent.entries[index]
        AppendLine(lines, string.format(
            "%d. %s - %.1f ms | %d Calls | max %.1f ms",
            index,
            entry.label,
            entry.totalMs,
            entry.calls,
            entry.maxMs
        ))
    end

    AppendLine(lines, "")
    AppendLine(lines, "BeavisQoL Hotspots gesamte Session:")
    for index = 1, math.min(MAX_REPORT_ENTRIES, #totalEntries) do
        local entry = totalEntries[index]
        AppendLine(lines, string.format(
            "%d. %s - %.1f ms | %d Calls | max %.1f ms",
            index,
            entry.label,
            entry.totalMs,
            entry.calls,
            entry.maxMs
        ))
    end

    return lines
end

local function EnsureReportWindow()
    if ReportFrame then
        return
    end

    ReportFrame = CreateFrame("Frame", "BeavisQoLPerformanceProfilerReportFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    ReportFrame:SetSize(REPORT_WINDOW_WIDTH, REPORT_WINDOW_HEIGHT)
    ReportFrame:SetPoint("CENTER")
    ReportFrame:SetFrameStrata("DIALOG")
    ReportFrame:SetClampedToScreen(true)
    ReportFrame:SetMovable(true)
    ReportFrame:SetToplevel(true)
    ReportFrame:EnableMouse(true)
    ReportFrame:RegisterForDrag("LeftButton")
    ReportFrame:SetBackdrop({
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
    ReportFrame:SetBackdropColor(0.03, 0.03, 0.04, 0.96)
    ReportFrame:SetBackdropBorderColor(1.00, 0.82, 0.00, 0.42)
    ReportFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    ReportFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    ReportFrame:Hide()

    local topGlow = ReportFrame:CreateTexture(nil, "BORDER")
    topGlow:SetPoint("TOPLEFT", ReportFrame, "TOPLEFT", 0, 0)
    topGlow:SetPoint("TOPRIGHT", ReportFrame, "TOPRIGHT", 0, 0)
    topGlow:SetHeight(28)
    topGlow:SetColorTexture(1, 0.82, 0, 0.08)

    ReportTitleText = ReportFrame:CreateFontString(nil, "OVERLAY")
    ReportTitleText:SetPoint("TOPLEFT", ReportFrame, "TOPLEFT", 16, -14)
    ReportTitleText:SetPoint("RIGHT", ReportFrame, "RIGHT", -48, 0)
    ReportTitleText:SetJustifyH("LEFT")
    ReportTitleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    ReportTitleText:SetTextColor(1, 0.88, 0.62, 1)
    ReportTitleText:SetText("BeavisQoL CPU Report")

    local closeButton = CreateFrame("Button", nil, ReportFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("TOPRIGHT", ReportFrame, "TOPRIGHT", -10, -10)
    closeButton:SetText("X")
    if closeButton.GetFontString then
        closeButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    closeButton:SetScript("OnClick", function()
        ReportFrame:Hide()
    end)

    ReportScrollFrame = CreateFrame("ScrollFrame", nil, ReportFrame, "UIPanelScrollFrameTemplate")
    ReportScrollFrame:SetPoint("TOPLEFT", ReportFrame, "TOPLEFT", 16, -42)
    ReportScrollFrame:SetPoint("BOTTOMRIGHT", ReportFrame, "BOTTOMRIGHT", -32, 16)
    ReportScrollFrame:EnableMouseWheel(true)
    ReportScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local step = 32
        local nextValue = current - (delta * step)
        if nextValue < 0 then
            nextValue = 0
        end
        self:SetVerticalScroll(nextValue)
    end)

    ReportEditBox = CreateFrame("EditBox", nil, ReportScrollFrame)
    ReportEditBox:SetMultiLine(true)
    ReportEditBox:SetAutoFocus(false)
    ReportEditBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    ReportEditBox:SetWidth(REPORT_WINDOW_WIDTH - 72)
    ReportEditBox:SetTextInsets(8, 8, 8, 8)
    ReportEditBox:SetScript("OnEscapePressed", function()
        ReportFrame:Hide()
    end)
    ReportEditBox:SetScript("OnCursorChanged", function(self, _, y, _, height)
        local scroll = ReportScrollFrame
        local offset = y + height
        local scrollTop = scroll:GetVerticalScroll()
        local scrollBottom = scrollTop + scroll:GetHeight()

        if offset > scrollBottom then
            scroll:SetVerticalScroll(offset - scroll:GetHeight())
        elseif y < scrollTop then
            scroll:SetVerticalScroll(y)
        end
    end)
    ReportEditBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local _, lineBreakCount = string.gsub(text, "\n", "\n")
        local _, fontHeight = self:GetFont()
        local lineHeight = (tonumber(fontHeight) or 12) + 4
        local totalHeight = ((lineBreakCount + 1) * lineHeight) + 16
        self:SetHeight(math.max(totalHeight, ReportScrollFrame:GetHeight()))
    end)

    ReportScrollFrame:SetScrollChild(ReportEditBox)
end

local function ShowReportWindow(reportText, reportTitle)
    EnsureReportWindow()

    ReportTitleText:SetText(reportTitle or "BeavisQoL CPU Report")
    ReportEditBox:SetText(reportText or "")
    ReportEditBox:SetCursorPosition(0)
    ReportEditBox:HighlightText()
    ReportScrollFrame:SetVerticalScroll(0)
    ReportFrame:Show()

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if ReportFrame and ReportFrame:IsShown() and ReportEditBox then
                ReportEditBox:SetFocus()
                ReportEditBox:HighlightText()
                ReportEditBox:SetCursorPosition(0)
            end
        end)
    else
        ReportEditBox:SetFocus()
    end
end

BuildRecentAggregate = function(sampleCount)
    local db = GetProfilerDB()
    local sampleBuffer = db.samples
    local startIndex = math.max(1, #sampleBuffer - (sampleCount or #sampleBuffer) + 1)
    local aggregate = {}
    local addonAggregate = {}
    local measuredMs = 0
    local addonCpuMs = 0
    local observedAddonCpuMs = 0
    local calls = 0
    local usedSamples = 0

    for index = startIndex, #sampleBuffer do
        local sample = sampleBuffer[index]
        if type(sample) == "table" then
            usedSamples = usedSamples + 1
            measuredMs = measuredMs + (tonumber(sample.measuredMs) or 0)
            addonCpuMs = addonCpuMs + (tonumber(sample.addonCpuMs) or 0)
            observedAddonCpuMs = observedAddonCpuMs + (tonumber(sample.observedAddonCpuMs) or 0)
            calls = calls + (tonumber(sample.calls) or 0)

            for _, entry in ipairs(sample.top or {}) do
                if type(entry) == "table" and type(entry.label) == "string" and entry.label ~= "" then
                    local aggregateEntry = aggregate[entry.label]

                    if not aggregateEntry then
                        aggregateEntry = {
                            label = entry.label,
                            totalMs = 0,
                            calls = 0,
                            maxMs = 0,
                        }
                        aggregate[entry.label] = aggregateEntry
                    end

                    aggregateEntry.totalMs = aggregateEntry.totalMs + (tonumber(entry.totalMs) or 0)
                    aggregateEntry.calls = aggregateEntry.calls + (tonumber(entry.calls) or 0)
                    aggregateEntry.maxMs = math.max(aggregateEntry.maxMs, tonumber(entry.maxMs) or 0)
                end
            end

            for _, entry in ipairs(sample.addons or {}) do
                if type(entry) == "table" and type(entry.label) == "string" and entry.label ~= "" then
                    local aggregateEntry = addonAggregate[entry.label]

                    if not aggregateEntry then
                        aggregateEntry = {
                            label = entry.label,
                            totalMs = 0,
                            samples = 0,
                            maxMs = 0,
                        }
                        addonAggregate[entry.label] = aggregateEntry
                    end

                    aggregateEntry.totalMs = aggregateEntry.totalMs + (tonumber(entry.totalMs) or 0)
                    aggregateEntry.samples = aggregateEntry.samples + (tonumber(entry.samples) or 0)
                    aggregateEntry.maxMs = math.max(aggregateEntry.maxMs, tonumber(entry.maxMs) or 0)
                end
            end
        end
    end

    return {
        sampleCount = usedSamples,
        measuredMs = measuredMs,
        addonCpuMs = addonCpuMs,
        observedAddonCpuMs = observedAddonCpuMs,
        calls = calls,
        entries = SortStats(aggregate),
        addonEntries = SortAddonStats(addonAggregate),
    }
end

local function PushSample(sample)
    local db = GetProfilerDB()
    local sampleBuffer = db.samples

    sampleBuffer[#sampleBuffer + 1] = sample

    while #sampleBuffer > MAX_STORED_SAMPLES do
        table.remove(sampleBuffer, 1)
    end
end

local function SnapshotInterval()
    local canCaptureAddonCpu = IsScriptProfilingEnabled()
        and type(UpdateAddOnCPUUsage) == "function"
        and type(GetAddOnCPUUsage) == "function"
        and GetAddOnCount() > 0

    if intervalCallCount <= 0 and intervalTotalMs <= 0 and not canCaptureAddonCpu then
        ResetCurrentInterval()
        ResetAddonCpuBaseline()
        return
    end

    local addonCpuDeltaMs, observedAddonCpuMs, storedAddonEntries, allAddonEntries = CaptureAddonCpuInterval()

    local topEntries = SortStats(intervalStats)
    local storedEntries = {}

    for index = 1, math.min(MAX_SAMPLE_ENTRIES, #topEntries) do
        storedEntries[#storedEntries + 1] = topEntries[index]
    end

    PushSample({
        timestamp = BuildTimestampLabel(),
        measuredMs = intervalTotalMs,
        addonCpuMs = addonCpuDeltaMs,
        observedAddonCpuMs = observedAddonCpuMs,
        calls = intervalCallCount,
        top = storedEntries,
        addons = storedAddonEntries,
    })

    UpdateAddonTotals(allAddonEntries)

    ResetCurrentInterval()
end

FlushCurrentInterval = function()
    local canCaptureAddonCpu = IsScriptProfilingEnabled()
        and type(UpdateAddOnCPUUsage) == "function"
        and type(GetAddOnCPUUsage) == "function"
        and GetAddOnCount() > 0

    if intervalCallCount > 0 or intervalTotalMs > 0 or canCaptureAddonCpu then
        SnapshotInterval()
    end
end

local function EnsureWrappedOwner(owner)
    local wrappedKeys = WrappedOwners[owner]

    if not wrappedKeys then
        wrappedKeys = {}
        WrappedOwners[owner] = wrappedKeys
    end

    return wrappedKeys
end

local function WrapFunction(owner, key, label)
    local ownerType = type(owner)
    if (ownerType ~= "table" and ownerType ~= "userdata") or type(key) ~= "string" or type(label) ~= "string" then
        return
    end

    local original = owner[key]
    if type(original) ~= "function" then
        return
    end

    local wrappedKeys = EnsureWrappedOwner(owner)
    if wrappedKeys[key] == true then
        return
    end

    wrappedKeys[key] = true

    owner[key] = function(...)
        if not Profiler.IsEnabled() then
            return original(...)
        end

        local sampleToken = Profiler.BeginSample()
        local results = PackResults(original(...))
        Profiler.EndSample(label, sampleToken)
        return unpackValues(results, 1, results.n)
    end
end

local function InstallWrappers()
    WrapFunction(BeavisQoL, "RefreshLocale", "Core.RefreshLocale")
    WrapFunction(BeavisQoL, "UpdateUI", "Core.UpdateUI")
    WrapFunction(BeavisQoL, "UpdateTree", "Core.UpdateTree")
    WrapFunction(BeavisQoL, "UpdateHome", "Core.UpdateHome")
    WrapFunction(BeavisQoL, "UpdateVersion", "Core.UpdateVersion")
    WrapFunction(BeavisQoL, "UpdateSettings", "Core.UpdateSettings")
    WrapFunction(BeavisQoL, "UpdateLevelTime", "Core.UpdateLevelTime")
    WrapFunction(BeavisQoL, "UpdateItemLevelGuide", "Core.UpdateItemLevelGuide")
    WrapFunction(BeavisQoL, "UpdateQuestCheck", "Core.UpdateQuestCheck")
    WrapFunction(BeavisQoL, "UpdateQuestAbandon", "Core.UpdateQuestAbandon")
    WrapFunction(BeavisQoL, "UpdateFishing", "Core.UpdateFishing")
    WrapFunction(BeavisQoL, "UpdateStreamerPlanner", "Core.UpdateStreamerPlanner")
    WrapFunction(BeavisQoL, "UpdatePortalViewer", "Core.UpdatePortalViewer")

    if BeavisQoL.Pages then
        WrapFunction(BeavisQoL.Pages.Misc, "RefreshState", "Page.Misc.RefreshState")
        WrapFunction(BeavisQoL.Pages.StreamerPlanner, "RefreshState", "Page.StreamerPlanner.RefreshState")
        WrapFunction(BeavisQoL.Pages.WeeklyKeys, "RefreshState", "Page.WeeklyKeys.RefreshState")
        WrapFunction(BeavisQoL.Pages.Stats, "RefreshState", "Page.Stats.RefreshState")
        WrapFunction(BeavisQoL.Pages.Logging, "RefreshState", "Page.Logging.RefreshState")
        WrapFunction(BeavisQoL.Pages.Checklist, "RefreshState", "Page.Checklist.RefreshState")
        WrapFunction(BeavisQoL.Pages.MouseHelper, "RefreshState", "Page.MouseHelper.RefreshState")
        WrapFunction(BeavisQoL.Pages.LFG, "RefreshState", "Page.LFG.RefreshState")
    end

    WrapFunction(BeavisQoL.Checklist, "RefreshTrackerWindow", "Checklist.RefreshTrackerWindow")
    WrapFunction(BeavisQoL.Checklist, "RefreshAllViews", "Checklist.RefreshAllViews")
    WrapFunction(BeavisQoL.WeeklyKeysModule, "RefreshOverlayWindow", "WeeklyKeys.RefreshOverlayWindow")
    WrapFunction(BeavisQoL.StatsModule, "RefreshOverlayWindow", "Stats.RefreshOverlayWindow")
    WrapFunction(BeavisQoL.PortalViewerModule, "RefreshWindow", "PortalViewer.RefreshWindow")
end

function Profiler.IsEnabled()
    return GetProfilerDB().enabled == true
end

function Profiler.BeginSample()
    if not Profiler.IsEnabled() or type(debugprofilestop) ~= "function" then
        return nil
    end

    return debugprofilestop()
end

function Profiler.EndSample(label, sampleToken)
    if sampleToken == nil or type(label) ~= "string" or label == "" or type(debugprofilestop) ~= "function" then
        return
    end

    local elapsedMs = debugprofilestop() - sampleToken
    if elapsedMs < 0 then
        elapsedMs = 0
    end

    local currentStats = intervalStats[label]
    if not currentStats then
        currentStats = {
            totalMs = 0,
            calls = 0,
            maxMs = 0,
        }
        intervalStats[label] = currentStats
    end

    currentStats.totalMs = currentStats.totalMs + elapsedMs
    currentStats.calls = currentStats.calls + 1
    currentStats.maxMs = math.max(currentStats.maxMs, elapsedMs)

    intervalTotalMs = intervalTotalMs + elapsedMs
    intervalCallCount = intervalCallCount + 1

    local totals = GetProfilerDB().totals
    local totalStats = totals[label]

    if not totalStats then
        totalStats = {
            totalMs = 0,
            calls = 0,
            maxMs = 0,
        }
        totals[label] = totalStats
    end

    totalStats.totalMs = totalStats.totalMs + elapsedMs
    totalStats.calls = totalStats.calls + 1
    totalStats.maxMs = math.max(totalStats.maxMs, elapsedMs)
end

function Profiler.Reset()
    local db = GetProfilerDB()
    db.samples = {}
    db.totals = {}
    db.addonTotals = {}
    ResetCurrentInterval()
    ResetAddonCpuBaseline()
end

function Profiler.SetEnabled(enabled)
    local db = GetProfilerDB()

    if db.enabled and enabled ~= true then
        FlushCurrentInterval()
    end

    db.enabled = enabled == true

    ResetCurrentInterval()
    ResetAddonCpuBaseline()

    if db.enabled then
        SamplerFrame:Show()
    else
        SamplerFrame:Hide()
    end
end

function Profiler.PrintStatus()
    local db = GetProfilerDB()
    local scriptProfileState = IsScriptProfilingEnabled() and "an" or "aus"
    PrintProfilerMessage(string.format(
        "Status: %s | scriptProfile: %s | Samples: %d",
        db.enabled and "aktiv" or "inaktiv",
        scriptProfileState,
        #db.samples
    ))

    if not IsScriptProfilingEnabled() then
        PrintProfilerMessage("Hinweis: Addon-Gesamt-CPU ist erst mit '/console scriptProfile 1' und '/reload' sichtbar.")
    end
end

function Profiler.PrintReport()
    local reportData = BuildReportData()
    local reportLines = BuildReportLines(reportData)
    ShowReportWindow(table.concat(reportLines, "\n"), string.format("BeavisQoL CPU Report - %s", reportData.timestamp))
    PrintProfilerMessage("CPU-Report im Kopierfenster geöffnet.")
end

function Profiler.PrintReportToChat()
    local reportLines = BuildReportLines(BuildReportData())
    for _, line in ipairs(reportLines) do
        PrintProfilerMessage(line)
    end
end

local function PrintProfilerHelp()
    PrintProfilerMessage("Befehle: /beavis cpu start | stop | reset | status | report | chat")
end

local function PrintDebugHelp()
    PrintBeavisMessage("Befehle: /beavis debug open [modul]")
end

SamplerFrame:SetScript("OnUpdate", function(_, elapsed)
    if not Profiler.IsEnabled() then
        return
    end

    intervalElapsed = intervalElapsed + (elapsed or 0)
    if intervalElapsed < SAMPLE_INTERVAL_SECONDS then
        return
    end

    intervalElapsed = 0
    SnapshotInterval()
end)

function BeavisQoL.HandleSlashCommand(msg)
    local trimmedMessage = TrimText(msg)
    if trimmedMessage == "" then
        return false
    end

    local commandName, commandAction = trimmedMessage:match("^(%S+)%s*(.-)$")
    commandName = string.lower(tostring(commandName or ""))
    commandAction = TrimText(commandAction)

    if commandName == "debug" then
        local debugAction, debugTarget = commandAction:match("^(%S+)%s*(.-)$")
        debugAction = string.lower(tostring(debugAction or ""))
        debugTarget = TrimText(debugTarget)

        if debugAction == "" or debugAction == "help" then
            PrintDebugHelp()
            return true
        end

        if debugAction == "open" then
            if BeavisQoL.DebugConsole and BeavisQoL.DebugConsole.Open then
                BeavisQoL.DebugConsole.Open(debugTarget ~= "" and debugTarget or nil)
            else
                PrintBeavisMessage("Debug-Konsole ist aktuell nicht verfügbar.")
            end
            return true
        end

        PrintDebugHelp()
        return true
    end

    commandAction = string.lower(commandAction)

    if commandName ~= "cpu" and commandName ~= "perf" and commandName ~= "profile" then
        return false
    end

    if commandAction == "" or commandAction == "help" then
        PrintProfilerHelp()
        return true
    end

    if commandAction == "start" or commandAction == "on" then
        Profiler.Reset()
        Profiler.SetEnabled(true)
        PrintProfilerMessage("CPU-Logging aktiviert. Problem reproduzieren und danach '/beavis cpu report' ausfuehren.")
        if not IsScriptProfilingEnabled() then
            PrintProfilerMessage("Optional für Addon-Gesamt-CPU: '/console scriptProfile 1' und danach '/reload'.")
        end
        return true
    end

    if commandAction == "stop" or commandAction == "off" then
        Profiler.SetEnabled(false)
        PrintProfilerMessage("CPU-Logging deaktiviert.")
        return true
    end

    if commandAction == "reset" then
        Profiler.Reset()
        PrintProfilerMessage("CPU-Logging-Daten zurückgesetzt.")
        return true
    end

    if commandAction == "status" then
        Profiler.PrintStatus()
        return true
    end

    if commandAction == "report" or commandAction == "dump" or commandAction == "window" then
        Profiler.PrintReport()
        return true
    end

    if commandAction == "chat" then
        Profiler.PrintReportToChat()
        return true
    end

    PrintProfilerHelp()
    return true
end

InstallWrappers()

if GetProfilerDB().enabled then
    ResetAddonCpuBaseline()
    SamplerFrame:Show()
end

