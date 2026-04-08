local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.Logging = BeavisQoL.Logging or {}
local Logging = BeavisQoL.Logging

--[[
Logging.lua ist ein Sammelmodul für mehrere Gold- und Handelsprotokolle.

Die Datei besteht grob aus drei Schichten:
1. Datenspeicherung und Aufräumen
2. Laufzeit-Erkennung von Geld- und Item-Änderungen
3. Darstellung im Logging-Modul des Hauptfensters

Beim Lesen am besten in genau dieser Reihenfolge vorgehen.
]]

local GetCoinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")
local GetCurrencyInfoValue = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo or nil
local GetCurrencyListSizeValue = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize or nil
local GetCurrencyListInfoValue = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo or nil
local GetItemDetails = (C_Item and C_Item.GetItemInfo) or rawget(_G, "GetItemInfo")

local SECONDS_PER_DAY = 86400
local SALES_LOG_RETENTION_SECONDS = 30 * SECONDS_PER_DAY
local REPAIR_LOG_RETENTION_SECONDS = 30 * SECONDS_PER_DAY
local MONEY_LOG_RETENTION_SECONDS = 365 * SECONDS_PER_DAY
local CURRENCY_LOG_RETENTION_SECONDS = 365 * SECONDS_PER_DAY

local MAX_SALES_LOG_ENTRIES = 10000
local MAX_REPAIR_LOG_ENTRIES = 10000
local MAX_MONEY_LOG_ENTRIES = 50000
local MAX_CURRENCY_LOG_ENTRIES = 30000
local MAX_REPAIR_DAY_ENTRIES = 400
local OVERVIEW_LOG_ENTRY_COUNT = 10
local OVERVIEW_SEARCH_MATCH_LIMIT = 25
local HISTORY_PAGE_SIZE = 100
local HISTORY_CONTENT_WIDTH = 680
local LOGGING_INTRO_PANEL_HEIGHT = 154
local LOGGING_PANEL_GAP = 12
local LOGGING_PANEL_ROW_START_Y = -44
local LOGGING_MIN_ROW_HEIGHT = 12
local LOGGING_ROW_SPACING = 2
local LOGGING_ROW_TEXT_GAP = 10
local LOGGING_ROW_RIGHT_TEXT_MIN_WIDTH = 44
local LOGGING_ROW_RIGHT_TEXT_MAX_WIDTH_FACTOR = 0.38
local HISTORY_TAB_KEYS = {
    "income",
    "expense",
    "repairs",
    "currency",
}

local PageLogging

local IncomePanel
local ExpensePanel
local RepairPanel
local CurrencyPanel
local CleanupPopup
local HistoryPopup
local HistoryButton
local isQuickViewMode = false
local HistoryTabButtons = {}
local HistoryActiveTabKey = "income"
local HistoryLoadedCountByTab = {
    income = HISTORY_PAGE_SIZE,
    expense = HISTORY_PAGE_SIZE,
    repairs = HISTORY_PAGE_SIZE,
    currency = HISTORY_PAGE_SIZE,
}

local LoggingState = {
    trackedMoney = nil,
    trackedCurrencies = {},
    lastRepairAllCostSeen = 0,
    isMerchantOpen = false,
    isMailOpen = false,
    isAuctionOpen = false,
    isTradeOpen = false,
    isTaxiOpen = false,
    isTrainerOpen = false,
    recentQuestUntil = 0,
    recentLootUntil = 0,
    recentTaxiUntil = 0,
    recentTaxiNpcName = nil,
    moneySuppressions = {},
    pendingAuctionPost = {
        timestamp = 0,
        amount = 0,
        note = nil,
        items = nil,
    },
    pendingVendorSale = {
        entries = {},
    },
    merchantBagSnapshot = nil,
    recentAuctionMailLoot = {
        index = 0,
        expiresAt = 0,
    },
    expandedIncomeEntries = {},
    expandedExpenseEntries = {},
    expandedCurrencyEntries = {},
    expandedRepairDays = {},
}
Logging._pendingVendorMoneySale = Logging._pendingVendorMoneySale or {
    entries = {},
}
Logging._pendingVendorExpense = Logging._pendingVendorExpense or {
    entries = {},
}
local QueuePendingVendorSaleItem
local DetermineMoneyCategory

local function GetTimestamp()
    -- Bevorzugt Serverzeit, damit die Logzeiten nicht von der lokalen
    -- Rechneruhr des Spielers abhängen.
    if GetServerTime then
        return GetServerTime()
    end

    return time()
end

local function GetNow()
    if GetTime then
        return GetTime()
    end

    return 0
end

local function FormatCoins(amount)
    if not amount or amount <= 0 then
        return "0"
    end

    if GetCoinText then
        return GetCoinText(amount)
    end

    return tostring(amount)
end

local function FormatTimestamp(timestamp)
    return date("%d.%m.%Y %H:%M", timestamp or GetTimestamp())
end

local function FormatDayKey(dayKey)
    local year, month, day = string.match(dayKey or "", "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not year then
        return dayKey or "-"
    end

    return string.format("%s.%s.%s", day, month, year)
end

local function FormatClockTime(timestamp)
    return date("%H:%M", timestamp or GetTimestamp())
end

local function FormatOverviewTimestamp(timestamp)
    return date("%d.%m %H:%M", timestamp or GetTimestamp())
end

local function GetDayKey(timestamp)
    return date("%Y-%m-%d", timestamp or GetTimestamp())
end

local function TrimArray(array, maxEntries)
    while #array > maxEntries do
        table.remove(array, 1)
    end
end

local function PruneTimestampedEntries(entries, cutoffTimestamp)
    if type(entries) ~= "table" then
        return
    end

    for index = #entries, 1, -1 do
        local entry = entries[index]
        if type(entry) ~= "table" or type(entry.timestamp) ~= "number" or entry.timestamp < cutoffTimestamp then
            table.remove(entries, index)
        end
    end
end

local function RequestLoggingPageRefresh()
    if PageLogging and PageLogging.RefreshState and PageLogging:IsShown() then
        PageLogging:RefreshState()
    end
end

local function ClearExpandedLoggingRows()
    LoggingState.expandedIncomeEntries = {}
    LoggingState.expandedExpenseEntries = {}
    LoggingState.expandedCurrencyEntries = {}
    LoggingState.expandedRepairDays = {}
end

local function RebuildRepairDailyTotalsFromLog(db)
    db.repairDailyTotals = {}

    for _, entry in ipairs(db.repairLog) do
        local dayKey = GetDayKey(entry.timestamp)

        db.repairDailyTotals[dayKey] = db.repairDailyTotals[dayKey] or {
            total = 0,
            personal = 0,
        }

        db.repairDailyTotals[dayKey].total = db.repairDailyTotals[dayKey].total + (entry.amount or 0)

        if (entry.source or L("LOGGING_OWN_GOLD")) ~= L("LOGGING_GUILD") then
            db.repairDailyTotals[dayKey].personal = db.repairDailyTotals[dayKey].personal + (entry.amount or 0)
        end
    end
end

local function PruneRepairDailyTotals(db)
    local keys = {}
    local oldestAllowedDayKey = GetDayKey(GetTimestamp() - REPAIR_LOG_RETENTION_SECONDS)

    for dayKey in pairs(db.repairDailyTotals) do
        if dayKey < oldestAllowedDayKey then
            db.repairDailyTotals[dayKey] = nil
        else
            keys[#keys + 1] = dayKey
        end
    end

    table.sort(keys)

    while #keys > MAX_REPAIR_DAY_ENTRIES do
        db.repairDailyTotals[keys[1]] = nil
        table.remove(keys, 1)
    end
end

local function NormalizeAndPruneDB(db)
    -- Alle automatischen Aufraeumregeln laufen zentral hier zusammen.
    local now = GetTimestamp()

    PruneTimestampedEntries(db.salesLog, now - SALES_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.repairLog, now - REPAIR_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.incomeLog, now - MONEY_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.expenseLog, now - MONEY_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.currencyLog, now - CURRENCY_LOG_RETENTION_SECONDS)

    TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
    TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)
    TrimArray(db.incomeLog, MAX_MONEY_LOG_ENTRIES)
    TrimArray(db.expenseLog, MAX_MONEY_LOG_ENTRIES)
    TrimArray(db.currencyLog, MAX_CURRENCY_LOG_ENTRIES)

    RebuildRepairDailyTotalsFromLog(db)
    PruneRepairDailyTotals(db)
end

function Logging.ClearLogsOlderThanDays(days)
    -- Manueller Aufräumbefehl für das Popup auf der Logging-Seite.
    local db = Logging.GetDB()

    if days == "all" or days == 0 then
        db.salesLog = {}
        db.repairLog = {}
        db.incomeLog = {}
        db.expenseLog = {}
        db.currencyLog = {}
        db.repairDailyTotals = {}
    else
        local numericDays = tonumber(days)
        if not numericDays or numericDays < 0 then
            return
        end

        local cutoffTimestamp = GetTimestamp() - (numericDays * SECONDS_PER_DAY)

        PruneTimestampedEntries(db.salesLog, cutoffTimestamp)
        PruneTimestampedEntries(db.repairLog, cutoffTimestamp)
        PruneTimestampedEntries(db.incomeLog, cutoffTimestamp)
        PruneTimestampedEntries(db.expenseLog, cutoffTimestamp)
        PruneTimestampedEntries(db.currencyLog, cutoffTimestamp)

        TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
        TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)
        TrimArray(db.incomeLog, MAX_MONEY_LOG_ENTRIES)
        TrimArray(db.expenseLog, MAX_MONEY_LOG_ENTRIES)
        TrimArray(db.currencyLog, MAX_CURRENCY_LOG_ENTRIES)

        RebuildRepairDailyTotalsFromLog(db)
        PruneRepairDailyTotals(db)
    end

    ClearExpandedLoggingRows()
    RequestLoggingPageRefresh()
end

function Logging.GetDB()
    -- Zentraler Einstieg für die Logging-SavedVariables.
    -- Diese Funktion sorgt dafür, dass alle benötigten Tabellen existieren,
    -- bevor andere Funktionen auf sie zugreifen.
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.logging = BeavisQoLCharDB.logging or {}

    local db = BeavisQoLCharDB.logging

    if type(db.salesLog) ~= "table" then
        db.salesLog = {}
    end

    if type(db.repairLog) ~= "table" then
        db.repairLog = {}
    end

    if type(db.incomeLog) ~= "table" then
        db.incomeLog = {}
    end

    if type(db.expenseLog) ~= "table" then
        db.expenseLog = {}
    end

    if type(db.currencyLog) ~= "table" then
        db.currencyLog = {}
    end

    if type(db.repairDailyTotals) ~= "table" then
        db.repairDailyTotals = {}
    end

    NormalizeAndPruneDB(db)
    return db
end

local function AddMoneySuppression(direction, amount)
    -- Manche Aktionen erzeugen erst einen gezielten Logeintrag und kurz danach
    -- noch ein allgemeines PLAYER_MONEY-Ereignis. Diese kurze Sperre verhindert
    -- doppelte Erfassung desselben Geldbetrags.
    if amount <= 0 then
        return
    end

    LoggingState.moneySuppressions[#LoggingState.moneySuppressions + 1] = {
        direction = direction,
        amount = amount,
        expiresAt = GetNow() + 2.0,
    }
end

local function ConsumeMoneySuppression(direction, amount)
    local now = GetNow()

    for index = #LoggingState.moneySuppressions, 1, -1 do
        local entry = LoggingState.moneySuppressions[index]

        if now >= entry.expiresAt then
            table.remove(LoggingState.moneySuppressions, index)
        elseif entry.direction == direction and math.abs(entry.amount - amount) <= 1 then
            table.remove(LoggingState.moneySuppressions, index)
            return true
        end
    end

    return false
end

local function ShouldSkipAuctionMailLog(index)
    local now = GetNow()

    if LoggingState.recentAuctionMailLoot.index == index and now < LoggingState.recentAuctionMailLoot.expiresAt then
        return true
    end

    LoggingState.recentAuctionMailLoot.index = index
    LoggingState.recentAuctionMailLoot.expiresAt = now + 1.0
    return false
end

local function GetItemDisplayName(itemReference, fallbackName)
    if type(fallbackName) == "string" and fallbackName ~= "" then
        return fallbackName
    end

    if GetItemDetails and itemReference ~= nil then
        local itemName = GetItemDetails(itemReference)
        if type(itemName) == "string" and itemName ~= "" then
            return itemName
        end
    end

    if type(itemReference) == "number" and C_Item and C_Item.GetItemNameByID then
        local itemName = C_Item.GetItemNameByID(itemReference)
        if type(itemName) == "string" and itemName ~= "" then
            return itemName
        end
    end

    if type(itemReference) == "string" and itemReference ~= "" then
        local bracketName = string.match(itemReference, "%[(.-)%]")
        if bracketName and bracketName ~= "" then
            return bracketName
        end

        return itemReference
    end

    return L("UNKNOWN_ITEM")
end

function Logging._CanUseItemReferenceAPI(itemReference)
    local referenceType = type(itemReference)

    if referenceType == "number" then
        return itemReference > 0
    end

    if referenceType == "table" then
        return true
    end

    if referenceType == "string" and itemReference ~= "" then
        if itemReference:find("|Hitem:", 1, true) then
            return true
        end

        if itemReference:match("^item:%d+") then
            return true
        end

        local numericItemID = tonumber(itemReference)
        return numericItemID ~= nil and numericItemID > 0
    end

    return false
end

function Logging._CanUseItemLocationAPI(itemReference)
    if type(itemReference) ~= "table" or type(itemReference.IsValid) ~= "function" then
        return false
    end

    local ok, isValid = pcall(itemReference.IsValid, itemReference)
    return ok and isValid == true
end

function Logging._GetItemReferenceLink(itemReference)
    if type(itemReference) == "string" and itemReference ~= "" and itemReference:find("|Hitem:", 1, true) then
        return itemReference
    end

    if GetItemDetails and type(itemReference) == "string" and itemReference ~= "" then
        local _, itemLink = GetItemDetails(itemReference)
        if type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
    end

    if C_Item and C_Item.GetItemLink and Logging._CanUseItemLocationAPI(itemReference) then
        local itemLink = C_Item.GetItemLink(itemReference)
        if type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
    end

    if GetItemDetails and itemReference ~= nil then
        local _, itemLink = GetItemDetails(itemReference)
        if type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
    end

    return nil
end

function Logging._GetItemReferenceID(itemReference)
    if type(itemReference) == "number" and itemReference > 0 then
        return itemReference
    end

    if type(itemReference) == "string" and itemReference ~= "" then
        local itemID = tonumber(itemReference:match("item:(%d+)"))
        if itemID and itemID > 0 then
            return itemID
        end
    end

    if type(itemReference) == "table" then
        local itemID = tonumber(itemReference.itemID or itemReference.id)
        if itemID and itemID > 0 then
            return itemID
        end
    end

    if C_Item and C_Item.GetItemID and Logging._CanUseItemLocationAPI(itemReference) then
        local itemID = tonumber(C_Item.GetItemID(itemReference))
        if itemID and itemID > 0 then
            return itemID
        end
    end

    if C_Item and C_Item.GetItemInfoInstant and Logging._CanUseItemReferenceAPI(itemReference) then
        local itemID = tonumber(C_Item.GetItemInfoInstant(itemReference))
        if itemID and itemID > 0 then
            return itemID
        end
    end

    local itemLink = Logging._GetItemReferenceLink(itemReference)
    if type(itemLink) == "string" then
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        if itemID and itemID > 0 then
            return itemID
        end
    end

    return nil
end

local function BuildItemText(itemReference, quantity, fallbackName)
    local itemName = GetItemDisplayName(itemReference, fallbackName)
    local itemQuantity = math.max(1, tonumber(quantity) or 1)
    local itemLink = Logging._GetItemReferenceLink(itemReference)
    local itemID = Logging._GetItemReferenceID(itemReference)

    return {
        label = itemName,
        quantity = itemQuantity,
        itemLink = itemLink,
        itemID = itemID,
    }
end

local function GetCurrentNpcName()
    local npcName = UnitName and UnitName("npc")
    if type(npcName) == "string" and npcName ~= "" then
        return npcName
    end

    local targetName = UnitName and UnitName("target")
    if type(targetName) == "string" and targetName ~= "" then
        return targetName
    end

    return nil
end

local function BuildNamedContextLabel(baseLabel, npcName)
    if type(npcName) == "string" and npcName ~= "" then
        return string.format("%s: %s", baseLabel, npcName)
    end

    return baseLabel
end

local function GetMerchantContextLabel()
    return BuildNamedContextLabel(L("LOGGING_VENDOR"), GetCurrentNpcName())
end

local function GetFlightMasterContextLabel()
    return BuildNamedContextLabel(L("LOGGING_FLIGHTMASTER"), LoggingState.recentTaxiNpcName or GetCurrentNpcName())
end

local function RefreshTaxiContext(duration)
    local npcName = GetCurrentNpcName()
    if npcName then
        LoggingState.recentTaxiNpcName = npcName
    end

    LoggingState.recentTaxiUntil = math.max(LoggingState.recentTaxiUntil, GetNow() + (duration or 3))
end

local function NormalizeItemTexts(items)
    -- Die UI soll später immer mit derselben Item-Struktur arbeiten können.
    -- Deshalb normalisieren wir freie Texte und Tabellen direkt beim Speichern.
    if type(items) ~= "table" then
        return nil
    end

    local normalized = {}

    for _, itemData in ipairs(items) do
        if type(itemData) == "string" then
            local trimmed = string.match(itemData, "^%s*(.-)%s*$")

            if trimmed and trimmed ~= "" then
                local normalizedEntry = {
                    label = string.sub(trimmed, 1, 140),
                    quantity = 1,
                }

                local itemLink = Logging._GetItemReferenceLink(trimmed)
                local itemID = Logging._GetItemReferenceID(trimmed:gsub("%s+[xX]%d+$", ""))
                if type(itemLink) == "string" and itemLink ~= "" then
                    normalizedEntry.itemLink = itemLink
                end
                if type(itemID) == "number" and itemID > 0 then
                    normalizedEntry.itemID = itemID
                end

                normalized[#normalized + 1] = normalizedEntry
            end
        elseif type(itemData) == "table" then
            local label = itemData.label or itemData.name or itemData.text
            if type(label) == "string" then
                label = string.match(label, "^%s*(.-)%s*$")
            else
                label = nil
            end

            if label and label ~= "" then
                local quantity = math.max(1, tonumber(itemData.quantity) or 1)
                local amount = math.max(0, math.floor((tonumber(itemData.amount) or 0) + 0.5))
                local unitAmount = tonumber(itemData.unitAmount)
                local itemLink = Logging._GetItemReferenceLink(itemData.itemLink or itemData.link or itemData.itemReference)
                local itemID = Logging._GetItemReferenceID(itemData.itemID or itemData.id or itemLink or itemData.itemReference)

                if unitAmount and unitAmount > 0 then
                    unitAmount = math.floor(unitAmount + 0.5)
                else
                    unitAmount = nil
                end

                if not itemLink then
                    itemLink = Logging._GetItemReferenceLink(label:gsub("%s+[xX]%d+$", ""))
                end
                if not itemID then
                    itemID = Logging._GetItemReferenceID(label:gsub("%s+[xX]%d+$", ""))
                end

                local normalizedEntry = {
                    label = string.sub(label, 1, 140),
                    quantity = quantity,
                    amount = amount > 0 and amount or nil,
                    unitAmount = unitAmount,
                }

                if type(itemLink) == "string" and itemLink ~= "" then
                    normalizedEntry.itemLink = itemLink
                end
                if type(itemID) == "number" and itemID > 0 then
                    normalizedEntry.itemID = itemID
                end

                normalized[#normalized + 1] = normalizedEntry
            end
        end
    end

    if #normalized == 0 then
        return nil
    end

    return normalized
end

local function GetLogItemLabel(itemData)
    if type(itemData) == "table" then
        local label = itemData.label or itemData.name or itemData.text
        if type(label) == "string" and label ~= "" then
            return label
        end
    elseif type(itemData) == "string" and itemData ~= "" then
        return itemData
    end

    return L("UNKNOWN_ITEM")
end

local function GetLogItemQuantity(itemData)
    if type(itemData) == "table" then
        return math.max(1, tonumber(itemData.quantity) or 1)
    end

    return 1
end

local function GetLogItemAmount(itemData)
    if type(itemData) == "table" then
        local amount = tonumber(itemData.amount) or 0
        if amount > 0 then
            return math.floor(amount + 0.5)
        end
    end

    return nil
end

local function GetLogItemUnitAmount(itemData)
    if type(itemData) == "table" then
        local unitAmount = tonumber(itemData.unitAmount) or 0
        if unitAmount > 0 then
            return math.floor(unitAmount + 0.5)
        end
    end

    return nil
end

function Logging._GetLogItemLink(itemData)
    if type(itemData) == "table" then
        local itemLink = itemData.itemLink or itemData.link
        if type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
    end

    return nil
end

function Logging._GetLogItemID(itemData)
    if type(itemData) == "table" then
        local itemID = tonumber(itemData.itemID or itemData.id)
        if itemID and itemID > 0 then
            return itemID
        end
    end

    return nil
end

function Logging._ResolveLogItemTooltipLink(itemData)
    local itemLink = Logging._GetLogItemLink(itemData)
    if itemLink then
        return itemLink
    end

    local itemID = Logging._GetLogItemID(itemData)
    if itemID then
        return string.format("item:%d", itemID)
    end

    local lookupLabel = GetLogItemLabel(itemData)
    if type(lookupLabel) == "string" and lookupLabel ~= "" then
        lookupLabel = lookupLabel:gsub("%s+[xX]%d+$", "")
        itemLink = Logging._GetItemReferenceLink(lookupLabel)
        if itemLink then
            return itemLink
        end

        itemID = Logging._GetItemReferenceID(lookupLabel)
        if itemID then
            return string.format("item:%d", itemID)
        end
    end

    return nil
end

local function GetLogItemSummary(itemData)
    local label = GetLogItemLabel(itemData)
    local quantity = GetLogItemQuantity(itemData)

    if quantity > 1 then
        return string.format("%s x%d", label, quantity)
    end

    return label
end

function Logging._BuildExpandedItemLine(itemData)
    local quantity = GetLogItemQuantity(itemData)
    local amount = GetLogItemAmount(itemData)
    local unitAmount = GetLogItemUnitAmount(itemData)
    local baseText = GetLogItemSummary(itemData)

    if unitAmount and unitAmount > 0 then
        if quantity > 1 and amount and amount > 0 then
            baseText = string.format("%s | %s pro Item | %s gesamt", baseText, FormatCoins(unitAmount), FormatCoins(amount))
        else
            baseText = string.format("%s | %s pro Item", baseText, FormatCoins(unitAmount))
        end
    elseif amount and amount > 0 then
        baseText = string.format("%s | %s", baseText, FormatCoins(amount))
    end

    return baseText
end

local function BuildItemListSummary(items)
    if type(items) ~= "table" or #items == 0 then
        return nil
    end

    local itemTexts = {}

    for _, itemData in ipairs(items) do
        itemTexts[#itemTexts + 1] = GetLogItemSummary(itemData)
    end

    return table.concat(itemTexts, ", ")
end

local function BuildExpandedItemText(items)
    if type(items) ~= "table" or #items == 0 then
        return nil
    end

    local lines = {}

    for _, itemData in ipairs(items) do
        lines[#lines + 1] = "- " .. Logging._BuildExpandedItemLine(itemData)
    end

    return table.concat(lines, "\n")
end

local function AppendSalesLog(amount, itemCount, source, timestamp, items)
    -- Verkaufslog und Geldlog bleiben getrennt:
    -- Das Verkaufslog zeigt die Item-Sicht, das Geldlog spaeter die Kategorie-Sicht.
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    db.salesLog[#db.salesLog + 1] = {
        timestamp = timestamp or GetTimestamp(),
        amount = amount,
        itemCount = itemCount or 0,
        source = source or L("LOGGING_SALE"),
        items = NormalizeItemTexts(items),
    }

    TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
end

local function AppendMoneyLog(direction, category, amount, note, timestamp, items)
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    local list = direction == "income" and db.incomeLog or db.expenseLog
    list[#list + 1] = {
        timestamp = timestamp or GetTimestamp(),
        amount = amount,
        category = category or L("LOGGING_MISC"),
        note = note,
        items = NormalizeItemTexts(items),
    }

    TrimArray(list, MAX_MONEY_LOG_ENTRIES)
end

local function AppendCurrencyLog(direction, currencyID, amount, name, iconFileID, category, note, timestamp)
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    db.currencyLog[#db.currencyLog + 1] = {
        timestamp = timestamp or GetTimestamp(),
        direction = direction == "expense" and "expense" or "income",
        currencyID = type(currencyID) == "number" and currencyID or nil,
        amount = math.max(1, math.floor((tonumber(amount) or 0) + 0.5)),
        name = type(name) == "string" and name or L("LOGGING_MISC"),
        iconFileID = type(iconFileID) == "number" and iconFileID or nil,
        category = category or L("LOGGING_MISC"),
        note = note,
    }

    TrimArray(db.currencyLog, MAX_CURRENCY_LOG_ENTRIES)
end

local function GetCurrencySnapshotInfo(currencyID)
    if type(GetCurrencyInfoValue) ~= "function" or type(currencyID) ~= "number" then
        return nil
    end

    local currencyInfo = GetCurrencyInfoValue(currencyID)
    if type(currencyInfo) ~= "table" then
        return nil
    end

    local quantity = tonumber(currencyInfo.quantity or currencyInfo["count"])
    if quantity == nil then
        return nil
    end

    return {
        currencyID = currencyID,
        quantity = math.max(0, math.floor(quantity + 0.5)),
        name = currencyInfo.name,
        iconFileID = currencyInfo.iconFileID or currencyInfo["icon"],
    }
end

local function BuildTrackedCurrencySnapshot()
    local snapshot = {}

    if type(GetCurrencyListSizeValue) == "function" and type(GetCurrencyListInfoValue) == "function" then
        for index = 1, (GetCurrencyListSizeValue() or 0) do
            local currencyInfo = GetCurrencyListInfoValue(index)
            local currencyID = type(currencyInfo) == "table" and (currencyInfo["currencyTypesID"] or currencyInfo["currencyID"]) or nil
            local quantity = type(currencyInfo) == "table" and tonumber(currencyInfo.quantity or currencyInfo["count"]) or nil

            if type(currencyID) == "number"
                and quantity ~= nil
                and not currencyInfo.isHeader
                and not currencyInfo["isHeaderWithChild"]
            then
                snapshot[currencyID] = {
                    quantity = math.max(0, math.floor(quantity + 0.5)),
                    name = currencyInfo.name,
                    iconFileID = currencyInfo.iconFileID or currencyInfo["icon"],
                }
            end
        end
    end

    return snapshot
end

local function RefreshTrackedCurrencies()
    LoggingState.trackedCurrencies = BuildTrackedCurrencySnapshot()
end

local function RecordTrackedCurrencyChange(currencyID, previousEntry, currentEntry)
    local previousQuantity = type(previousEntry) == "table" and tonumber(previousEntry.quantity) or nil
    local currentQuantity = type(currentEntry) == "table" and tonumber(currentEntry.quantity) or nil

    if previousQuantity == nil or currentQuantity == nil then
        return
    end

    local delta = currentQuantity - previousQuantity
    if delta == 0 then
        return
    end

    local direction = delta > 0 and "income" or "expense"
    local category, note = DetermineMoneyCategory(direction)
    AppendCurrencyLog(
        direction,
        currencyID,
        math.abs(delta),
        currentEntry.name or previousEntry.name,
        currentEntry.iconFileID or previousEntry.iconFileID,
        category,
        note,
        GetTimestamp()
    )
end

local function ProcessCurrencyDisplayUpdate(currencyID)
    if type(currencyID) == "number" then
        local currentEntry = GetCurrencySnapshotInfo(currencyID)
        local previousEntry = LoggingState.trackedCurrencies[currencyID]

        if currentEntry then
            if previousEntry then
                RecordTrackedCurrencyChange(currencyID, previousEntry, currentEntry)
            end
            LoggingState.trackedCurrencies[currencyID] = currentEntry
        elseif previousEntry then
            LoggingState.trackedCurrencies[currencyID] = nil
        end

        return
    end

    local nextSnapshot = BuildTrackedCurrencySnapshot()

    for trackedCurrencyID, currentEntry in pairs(nextSnapshot) do
        local previousEntry = LoggingState.trackedCurrencies[trackedCurrencyID]
        if previousEntry then
            RecordTrackedCurrencyChange(trackedCurrencyID, previousEntry, currentEntry)
        end
    end

    LoggingState.trackedCurrencies = nextSnapshot
end

local function AppendRepairLog(amount, source, timestamp)
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    local entryTimestamp = timestamp or GetTimestamp()
    local dayKey = GetDayKey(entryTimestamp)

    db.repairLog[#db.repairLog + 1] = {
        timestamp = entryTimestamp,
        amount = amount,
        source = source or L("LOGGING_OWN_GOLD"),
    }

    TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)

    db.repairDailyTotals[dayKey] = db.repairDailyTotals[dayKey] or {
        total = 0,
        personal = 0,
    }

    db.repairDailyTotals[dayKey].total = db.repairDailyTotals[dayKey].total + amount

    if source ~= L("LOGGING_GUILD") then
        db.repairDailyTotals[dayKey].personal = db.repairDailyTotals[dayKey].personal + amount
    end

    PruneRepairDailyTotals(db)
end

DetermineMoneyCategory = function(direction)
    -- Wir leiten Kategorien über den zuletzt beobachteten Kontext ab:
    -- Händler offen, Post offen, Quest eben abgegeben usw.
    local now = GetNow()

    if direction == "income" then
        if LoggingState.isMerchantOpen then
            return L("LOGGING_SALE"), GetMerchantContextLabel()
        end

        if LoggingState.isMailOpen then
            return L("LOGGING_MAIL"), L("LOGGING_MAILBOX")
        end

        if LoggingState.isAuctionOpen then
            return L("LOGGING_AUCTIONHOUSE"), L("LOGGING_AUCTIONHOUSE")
        end

        if LoggingState.isTradeOpen then
            return L("LOGGING_TRADE"), L("LOGGING_TRADE")
        end

        if LoggingState.recentQuestUntil > now then
            return L("LOGGING_QUEST"), L("LOGGING_QUEST_REWARD")
        end

        if LoggingState.recentLootUntil > now then
            return L("LOGGING_LOOT"), L("LOGGING_PICKED_UP")
        end

        return L("LOGGING_MISC"), nil
    end

    if LoggingState.isTaxiOpen or LoggingState.recentTaxiUntil > now or (UnitOnTaxi and UnitOnTaxi("player")) then
        return L("LOGGING_FLIGHTMASTER"), GetFlightMasterContextLabel()
    end

    if LoggingState.isMerchantOpen then
        return L("LOGGING_VENDOR"), GetMerchantContextLabel()
    end

    if LoggingState.isMailOpen then
        return L("LOGGING_MAIL"), nil
    end

    if LoggingState.isAuctionOpen then
        return L("LOGGING_AUCTIONHOUSE"), nil
    end

    if LoggingState.isTradeOpen then
        return L("LOGGING_TRADE"), nil
    end

    if LoggingState.isTrainerOpen then
        return L("LOGGING_TRAINER"), nil
    end

    return L("LOGGING_MISC"), nil
end

local function RefreshRepairCostSnapshot()
    if not LoggingState.isMerchantOpen or not CanMerchantRepair or not CanMerchantRepair() then
        LoggingState.lastRepairAllCostSeen = 0
        return
    end

    local repairCost, canRepair = GetRepairAllCost()
    if canRepair and repairCost and repairCost > 0 then
        LoggingState.lastRepairAllCostSeen = repairCost
    else
        LoggingState.lastRepairAllCostSeen = 0
    end
end

local function CaptureMerchantBagSnapshot()
    local snapshot = {}

    if not C_Container
        or type(C_Container.GetContainerNumSlots) ~= "function"
        or type(C_Container.GetContainerItemInfo) ~= "function"
    then
        return snapshot
    end

    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0

        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            if itemInfo and itemInfo.hyperlink then
                local itemName, _, _, _, _, _, _, _, _, _, sellPrice = GetItemDetails(itemInfo.hyperlink)

                if type(sellPrice) == "number" and sellPrice > 0 then
                    local quantity = math.max(1, tonumber(itemInfo.stackCount) or 1)
                    local itemKey = string.format("%s|%d", itemInfo.hyperlink, sellPrice)
                    local existing = snapshot[itemKey]

                    if existing then
                        existing.quantity = existing.quantity + quantity
                    else
                        snapshot[itemKey] = {
                            itemReference = itemInfo.hyperlink,
                            fallbackName = itemName,
                            quantity = quantity,
                            unitAmount = sellPrice,
                        }
                    end
                end
            end
        end
    end

    return snapshot
end

local function RefreshMerchantBagSnapshot()
    LoggingState.merchantBagSnapshot = CaptureMerchantBagSnapshot()
end

local function QueuePendingVendorSalesFromBagDiff(previousSnapshot, currentSnapshot)
    if type(previousSnapshot) ~= "table" then
        return
    end

    for itemKey, previousEntry in pairs(previousSnapshot) do
        local currentEntry = type(currentSnapshot) == "table" and currentSnapshot[itemKey] or nil
        local removedQuantity = (previousEntry.quantity or 0) - ((currentEntry and currentEntry.quantity) or 0)

        if removedQuantity > 0 then
            QueuePendingVendorSaleItem(
                previousEntry.itemReference,
                removedQuantity,
                previousEntry.unitAmount,
                previousEntry.fallbackName
            )
        end
    end
end

local function UpdatePendingVendorSalesFromBags()
    local currentSnapshot = CaptureMerchantBagSnapshot()

    if not Logging.suspendMerchantCapture then
        QueuePendingVendorSalesFromBagDiff(LoggingState.merchantBagSnapshot, currentSnapshot)
    end

    LoggingState.merchantBagSnapshot = currentSnapshot
end

local function ClearPendingVendorSales()
    wipe(LoggingState.pendingVendorSale.entries)
end

function Logging._ClearPendingVendorMoneySales()
    wipe(Logging._pendingVendorMoneySale.entries)
end

local function TrimPendingVendorSales()
    local now = GetNow()

    for index = #LoggingState.pendingVendorSale.entries, 1, -1 do
        local entry = LoggingState.pendingVendorSale.entries[index]
        if now >= (entry.expiresAt or 0) then
            table.remove(LoggingState.pendingVendorSale.entries, index)
        end
    end
end

local function MergePendingVendorItems(targetItems, sourceItems)
    if type(sourceItems) ~= "table" then
        return
    end

    local lookup = {}

    for _, itemData in ipairs(targetItems) do
        local key = string.format(
            "%s|%s",
            GetLogItemLabel(itemData),
            tostring(GetLogItemUnitAmount(itemData) or GetLogItemAmount(itemData) or 0)
        )
        lookup[key] = itemData
    end

    for _, itemData in ipairs(sourceItems) do
        local key = string.format(
            "%s|%s",
            GetLogItemLabel(itemData),
            tostring(GetLogItemUnitAmount(itemData) or GetLogItemAmount(itemData) or 0)
        )
        local existing = lookup[key]

        if existing then
            existing.quantity = GetLogItemQuantity(existing) + GetLogItemQuantity(itemData)

            local existingAmount = GetLogItemAmount(existing) or 0
            local addedAmount = GetLogItemAmount(itemData) or 0
            if existingAmount > 0 or addedAmount > 0 then
                existing.amount = existingAmount + addedAmount
            end

            local unitAmount = GetLogItemUnitAmount(existing) or GetLogItemUnitAmount(itemData)
            if unitAmount and unitAmount > 0 then
                existing.unitAmount = unitAmount
            end

            if not Logging._GetLogItemLink(existing) and Logging._GetLogItemLink(itemData) then
                existing.itemLink = Logging._GetLogItemLink(itemData)
            end

            if not Logging._GetLogItemID(existing) and Logging._GetLogItemID(itemData) then
                existing.itemID = Logging._GetLogItemID(itemData)
            end
        else
            local normalizedItems = NormalizeItemTexts({ itemData })
            if normalizedItems and normalizedItems[1] then
                local newEntry = normalizedItems[1]
                targetItems[#targetItems + 1] = newEntry
                lookup[key] = newEntry
            end
        end
    end
end

QueuePendingVendorSaleItem = function(itemReference, quantity, unitAmount, fallbackName)
    local cleanUnitAmount = math.max(0, math.floor((tonumber(unitAmount) or 0) + 0.5))
    if cleanUnitAmount <= 0 then
        return
    end

    local cleanQuantity = math.max(1, tonumber(quantity) or 1)
    local itemEntry = BuildItemText(itemReference, cleanQuantity, fallbackName)
    itemEntry.amount = cleanUnitAmount * cleanQuantity
    itemEntry.unitAmount = cleanUnitAmount
    local normalizedItems = NormalizeItemTexts({
        itemEntry,
    })

    if not normalizedItems or not normalizedItems[1] then
        return
    end

    TrimPendingVendorSales()
    LoggingState.pendingVendorSale.entries[#LoggingState.pendingVendorSale.entries + 1] = {
        expiresAt = GetNow() + 2.0,
        amount = cleanUnitAmount * cleanQuantity,
        itemCount = 1,
        items = normalizedItems,
    }
end

function Logging._QueuePendingVendorMoneySale(amount, note, timestamp)
    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    if cleanAmount <= 0 then
        return
    end

    Logging._pendingVendorMoneySale.entries[#Logging._pendingVendorMoneySale.entries + 1] = {
        amount = cleanAmount,
        note = note,
        timestamp = timestamp or GetTimestamp(),
    }
end

function Logging._ClearPendingVendorExpenses()
    wipe(Logging._pendingVendorExpense.entries)
end

function Logging._TrimPendingVendorExpenses()
    local now = GetNow()

    for index = #Logging._pendingVendorExpense.entries, 1, -1 do
        local entry = Logging._pendingVendorExpense.entries[index]
        if now >= (entry.expiresAt or 0) then
            table.remove(Logging._pendingVendorExpense.entries, index)
        end
    end
end

function Logging._QueuePendingVendorExpense(amount, note, items)
    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    local normalizedItems = NormalizeItemTexts(items)

    if cleanAmount <= 0 or not normalizedItems or not normalizedItems[1] then
        return
    end

    Logging._TrimPendingVendorExpenses()
    Logging._pendingVendorExpense.entries[#Logging._pendingVendorExpense.entries + 1] = {
        expiresAt = GetNow() + 2.0,
        amount = cleanAmount,
        note = note,
        items = normalizedItems,
    }
end

function Logging._ConsumePendingVendorExpense(amount)
    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))

    Logging._TrimPendingVendorExpenses()

    if cleanAmount <= 0 then
        return nil
    end

    local totalAmount = 0
    local consumedIndices = {}
    local mergedItems = {}
    local resolvedNote = nil

    for index, entry in ipairs(Logging._pendingVendorExpense.entries) do
        totalAmount = totalAmount + (entry.amount or 0)
        consumedIndices[#consumedIndices + 1] = index
        resolvedNote = resolvedNote or entry.note
        MergePendingVendorItems(mergedItems, entry.items)

        if math.abs(totalAmount - cleanAmount) <= 1 then
            for removeIndex = #consumedIndices, 1, -1 do
                table.remove(Logging._pendingVendorExpense.entries, consumedIndices[removeIndex])
            end

            return {
                amount = totalAmount,
                note = resolvedNote,
                items = #mergedItems > 0 and mergedItems or nil,
            }
        end

        if totalAmount > cleanAmount then
            break
        end
    end

    return nil
end

local function ConsumePendingVendorSale(amount)
    -- Versucht, vorher gemerkte Einzelverkaeufe zu einem passenden
    -- Gesamtbetrag aus PLAYER_MONEY zusammenzusetzen.
    TrimPendingVendorSales()

    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    if cleanAmount <= 0 or #LoggingState.pendingVendorSale.entries == 0 then
        return nil
    end

    local totalAmount = 0
    local totalItemCount = 0
    local consumedIndices = {}
    local mergedItems = {}

    for index, entry in ipairs(LoggingState.pendingVendorSale.entries) do
        totalAmount = totalAmount + (entry.amount or 0)
        totalItemCount = totalItemCount + (entry.itemCount or 0)
        consumedIndices[#consumedIndices + 1] = index
        MergePendingVendorItems(mergedItems, entry.items)

        if math.abs(totalAmount - cleanAmount) <= 1 then
            for removeIndex = #consumedIndices, 1, -1 do
                table.remove(LoggingState.pendingVendorSale.entries, consumedIndices[removeIndex])
            end

            return {
                amount = totalAmount,
                itemCount = totalItemCount,
                items = #mergedItems > 0 and mergedItems or nil,
            }
        end

        if totalAmount > cleanAmount then
            break
        end
    end

    return nil
end

function Logging._AppendResolvedVendorSale(amount, sourceText, timestamp, pendingSale)
    AppendMoneyLog("income", L("LOGGING_SALE"), amount, sourceText, timestamp, pendingSale and pendingSale.items)
    AppendSalesLog(amount, pendingSale and pendingSale.itemCount or 0, sourceText, timestamp, pendingSale and pendingSale.items)
end

function Logging._TryResolvePendingVendorMoneySales()
    if #Logging._pendingVendorMoneySale.entries == 0 then
        return false
    end

    local resolvedAny = false
    local index = 1

    while index <= #Logging._pendingVendorMoneySale.entries do
        local entry = Logging._pendingVendorMoneySale.entries[index]
        local pendingSale = ConsumePendingVendorSale(entry.amount)

        if pendingSale then
            Logging._AppendResolvedVendorSale(entry.amount, entry.note or L("LOGGING_VENDOR_SALE"), entry.timestamp, pendingSale)
            table.remove(Logging._pendingVendorMoneySale.entries, index)
            resolvedAny = true
        else
            index = index + 1
        end
    end

    if resolvedAny then
        RequestLoggingPageRefresh()
    end

    return resolvedAny
end

function Logging._FlushPendingVendorMoneySales()
    if #Logging._pendingVendorMoneySale.entries == 0 then
        return
    end

    for _, entry in ipairs(Logging._pendingVendorMoneySale.entries) do
        local pendingSale = ConsumePendingVendorSale(entry.amount)
        Logging._AppendResolvedVendorSale(entry.amount, entry.note or L("LOGGING_VENDOR_SALE"), entry.timestamp, pendingSale)
    end

    Logging._ClearPendingVendorMoneySales()
    RequestLoggingPageRefresh()
end

function Logging.RecordVendorSale(amount, itemCount, source, items)
    -- Öffentliche Schnittstelle für itemisierte Händlerverkäufe,
    -- z. B. aus Auto Sell Junk oder unseren Vendor-Hooks.
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    local sourceText = source or GetMerchantContextLabel()

    AppendSalesLog(amount, itemCount, sourceText, timestamp, items)
    AppendMoneyLog("income", L("LOGGING_SALE"), amount, sourceText, timestamp, items)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

local function RecordAuctionHouseIncome(amount, note, items)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    AppendMoneyLog("income", L("LOGGING_AUCTIONHOUSE"), amount, note or L("LOGGING_SALE"), timestamp, items)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

local function RecordAuctionHouseExpense(amount, note, items)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    AppendMoneyLog("expense", L("LOGGING_AUCTIONHOUSE"), amount, note or L("LOGGING_COSTS"), timestamp, items)
    AddMoneySuppression("expense", amount)
    RequestLoggingPageRefresh()
end

local function NormalizeRepairSourceLabel(source)
    if source == L("LOGGING_GUILD") then
        return L("LOGGING_GUILD")
    end

    return L("LOGGING_SELF_PAID")
end

local function RecordRepair(amount, source)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    local sourceText = NormalizeRepairSourceLabel(source)

    AppendRepairLog(amount, sourceText, timestamp)

    if sourceText ~= L("LOGGING_GUILD") then
        AppendMoneyLog("expense", L("LOGGING_REPAIR"), amount, sourceText, timestamp)
        AddMoneySuppression("expense", amount)
    end

    RequestLoggingPageRefresh()
end

local function RecordQuestReward(amount, questTitle)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()

    AppendMoneyLog("income", L("LOGGING_QUEST"), amount, questTitle or L("LOGGING_QUEST_REWARD"), timestamp)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

function Logging.GetSalesLog()
    return Logging.GetDB().salesLog
end

function Logging.GetRepairLog()
    return Logging.GetDB().repairLog
end

function Logging.GetIncomeLog()
    return Logging.GetDB().incomeLog
end

function Logging.GetExpenseLog()
    return Logging.GetDB().expenseLog
end

function Logging.GetCurrencyLog()
    return Logging.GetDB().currencyLog
end

function Logging.GetRepairDailyTotals()
    return Logging.GetDB().repairDailyTotals
end

local MoneyWatcher = CreateFrame("Frame")
MoneyWatcher:RegisterEvent("PLAYER_LOGIN")
MoneyWatcher:RegisterEvent("PLAYER_MONEY")
MoneyWatcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
MoneyWatcher:RegisterEvent("QUEST_TURNED_IN")
MoneyWatcher:RegisterEvent("LOOT_OPENED")
MoneyWatcher:RegisterEvent("LOOT_CLOSED")
MoneyWatcher:RegisterEvent("MERCHANT_SHOW")
MoneyWatcher:RegisterEvent("MERCHANT_CLOSED")
MoneyWatcher:RegisterEvent("MERCHANT_UPDATE")
MoneyWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
MoneyWatcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
MoneyWatcher:RegisterEvent("MAIL_SHOW")
MoneyWatcher:RegisterEvent("MAIL_CLOSED")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_CLOSED")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
MoneyWatcher:RegisterEvent("TRADE_SHOW")
MoneyWatcher:RegisterEvent("TRADE_CLOSED")
MoneyWatcher:RegisterEvent("TAXIMAP_OPENED")
MoneyWatcher:RegisterEvent("TAXIMAP_CLOSED")
MoneyWatcher:RegisterEvent("TRAINER_SHOW")
MoneyWatcher:RegisterEvent("TRAINER_CLOSED")

MoneyWatcher:SetScript("OnEvent", function(_, event, ...)
    -- Dieser Watcher ist der Laufzeit-Sensor des Logging-Moduls.
    -- Er merkt sich Kontexte und verteilt Geldänderungen danach in die
    -- richtigen Logs, sobald genug Informationen vorliegen.
    if event == "PLAYER_LOGIN" then
        Logging.GetDB()
        LoggingState.trackedMoney = GetMoney and GetMoney() or 0
        RefreshTrackedCurrencies()
        RefreshRepairCostSnapshot()
        return
    end

    if event == "CURRENCY_DISPLAY_UPDATE" then
        ProcessCurrencyDisplayUpdate(...)
        RequestLoggingPageRefresh()
        return
    end

    if event == "QUEST_TURNED_IN" then
        local questID, _, moneyReward = ...
        LoggingState.recentQuestUntil = GetNow() + 2.5

        if type(moneyReward) == "number" and moneyReward > 0 then
            local questTitle = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
            RecordQuestReward(moneyReward, questTitle)
        end

        return
    end

    if event == "LOOT_OPENED" then
        LoggingState.recentLootUntil = GetNow() + 2.5
        return
    end

    if event == "LOOT_CLOSED" then
        LoggingState.recentLootUntil = math.max(LoggingState.recentLootUntil, GetNow() + 0.5)
        return
    end

    if event == "MERCHANT_SHOW" then
        LoggingState.isMerchantOpen = true
        RefreshRepairCostSnapshot()
        Logging._ClearPendingVendorMoneySales()
        Logging._ClearPendingVendorExpenses()
        RefreshMerchantBagSnapshot()
        return
    end

    if event == "MERCHANT_CLOSED" then
        LoggingState.isMerchantOpen = false
        LoggingState.lastRepairAllCostSeen = 0
        LoggingState.merchantBagSnapshot = nil
        Logging._TryResolvePendingVendorMoneySales()
        Logging._FlushPendingVendorMoneySales()
        ClearPendingVendorSales()
        Logging._ClearPendingVendorMoneySales()
        Logging._ClearPendingVendorExpenses()
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        if LoggingState.isMerchantOpen then
            UpdatePendingVendorSalesFromBags()
            Logging._TryResolvePendingVendorMoneySales()
        end

        return
    end

    if event == "MERCHANT_UPDATE" or event == "UPDATE_INVENTORY_DURABILITY" then
        RefreshRepairCostSnapshot()
        return
    end

    if event == "MAIL_SHOW" then
        LoggingState.isMailOpen = true
        return
    end

    if event == "MAIL_CLOSED" then
        LoggingState.isMailOpen = false
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        LoggingState.isAuctionOpen = true
        return
    end

    if event == "AUCTION_HOUSE_CLOSED" then
        LoggingState.isAuctionOpen = false
        return
    end

    if event == "AUCTION_HOUSE_AUCTION_CREATED" then
        if GetNow() - (LoggingState.pendingAuctionPost.timestamp or 0) <= 5 then
            RecordAuctionHouseExpense(
                LoggingState.pendingAuctionPost.amount or 0,
                LoggingState.pendingAuctionPost.note,
                LoggingState.pendingAuctionPost.items
            )
        end

        LoggingState.pendingAuctionPost.timestamp = 0
        LoggingState.pendingAuctionPost.amount = 0
        LoggingState.pendingAuctionPost.note = nil
        LoggingState.pendingAuctionPost.items = nil
        return
    end

    if event == "TRADE_SHOW" then
        LoggingState.isTradeOpen = true
        return
    end

    if event == "TRADE_CLOSED" then
        LoggingState.isTradeOpen = false
        return
    end

    if event == "TAXIMAP_OPENED" then
        LoggingState.isTaxiOpen = true
        RefreshTaxiContext(4)
        return
    end

    if event == "TAXIMAP_CLOSED" then
        LoggingState.isTaxiOpen = false
        RefreshTaxiContext(4)
        return
    end

    if event == "TRAINER_SHOW" then
        LoggingState.isTrainerOpen = true
        return
    end

    if event == "TRAINER_CLOSED" then
        LoggingState.isTrainerOpen = false
        return
    end

    if event == "PLAYER_MONEY" then
        local newMoney = GetMoney and GetMoney() or 0

        if LoggingState.trackedMoney == nil then
            LoggingState.trackedMoney = newMoney
            return
        end

        local delta = newMoney - LoggingState.trackedMoney
        LoggingState.trackedMoney = newMoney

        if delta == 0 then
            return
        end

        local direction = delta > 0 and "income" or "expense"
        local amount = math.abs(delta)

        if ConsumeMoneySuppression(direction, amount) then
            return
        end

        local category, note = DetermineMoneyCategory(direction)
        local timestamp = GetTimestamp()

        if direction == "income" and category == L("LOGGING_SALE") then
            local pendingSale = ConsumePendingVendorSale(amount)
            if pendingSale then
                local sourceText = note or L("LOGGING_VENDOR_SALE")
                Logging._AppendResolvedVendorSale(amount, sourceText, timestamp, pendingSale)
                RequestLoggingPageRefresh()
                return
            end

            Logging._QueuePendingVendorMoneySale(amount, note or L("LOGGING_VENDOR_SALE"), timestamp)
            return
        end

        if direction == "expense" and category == L("LOGGING_VENDOR") then
            local pendingExpense = Logging._ConsumePendingVendorExpense(amount)
            if pendingExpense then
                AppendMoneyLog(direction, category, amount, pendingExpense.note or note, timestamp, pendingExpense.items)
                RequestLoggingPageRefresh()
                return
            end
        end

        AppendMoneyLog(direction, category, amount, note, timestamp)

        if direction == "income" and category == L("LOGGING_SALE") then
            AppendSalesLog(amount, 0, note or L("LOGGING_VENDOR_SALE"), timestamp)
        end

        RequestLoggingPageRefresh()
    end
end)

local function SetPendingAuctionPost(amount, note, items)
    LoggingState.pendingAuctionPost.timestamp = GetNow()
    LoggingState.pendingAuctionPost.amount = amount or 0
    LoggingState.pendingAuctionPost.note = note
    LoggingState.pendingAuctionPost.items = items
end

local function TryRecordAuctionSaleMail(index)
    if ShouldSkipAuctionMailLog(index) then
        return
    end

    local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, count = GetInboxInvoiceInfo(index)
    if invoiceType ~= "seller" then
        return
    end

    local _, _, _, subject, money = GetInboxHeaderInfo(index)
    local amount = money or math.max(0, (bid or 0) + (deposit or 0) - (consignment or 0))
    local saleTarget = playerName and playerName ~= "" and L("LOGGING_SALE_TO"):format(playerName) or L("LOGGING_SALE")
    local items = { BuildItemText(nil, count or 1, itemName or subject) }
    RecordAuctionHouseIncome(amount, saleTarget, items)
end

local function InstallInboxMoneyHooks()
    if type(TakeInboxMoney) == "function" then
        local originalTakeInboxMoney = TakeInboxMoney
        TakeInboxMoney = function(index, ...)
            TryRecordAuctionSaleMail(index)
            return originalTakeInboxMoney(index, ...)
        end
    end

    if type(AutoLootMailItem) == "function" then
        local originalAutoLootMailItem = AutoLootMailItem
        AutoLootMailItem = function(index, ...)
            TryRecordAuctionSaleMail(index)
            return originalAutoLootMailItem(index, ...)
        end
    end
end

local function HookAuctionHouseActions()
    if not hooksecurefunc or not C_AuctionHouse then
        return
    end

    if C_AuctionHouse.PostItem then
        hooksecurefunc(C_AuctionHouse, "PostItem", function(itemLocation, duration, quantity)
            if not C_AuctionHouse.CalculateItemDeposit then
                return
            end

            local deposit = C_AuctionHouse.CalculateItemDeposit(itemLocation, duration, quantity) or 0
            local itemLink = Logging._GetItemReferenceLink(itemLocation)
            local items = { BuildItemText(itemLink, quantity) }
            SetPendingAuctionPost(deposit, "Einstellgebühr", items)
        end)
    end

    if C_AuctionHouse.PostCommodity then
        hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemLocation, duration, quantity)
            if not C_AuctionHouse.CalculateCommodityDeposit then
                return
            end

            local itemID = tonumber(Logging._GetItemReferenceID(itemLocation))
            if not itemID or itemID <= 0 then
                return
            end

            local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity) or 0
            local itemLink = Logging._GetItemReferenceLink(itemLocation)
            local items = { BuildItemText(itemLink, quantity) }
            SetPendingAuctionPost(deposit, "Einstellgebühr", items)
        end)
    end

    if C_AuctionHouse.PlaceBid then
        hooksecurefunc(C_AuctionHouse, "PlaceBid", function(auctionID, bidPlaced)
            if not C_AuctionHouse.GetAuctionInfoByID then
                return
            end

            local info = C_AuctionHouse.GetAuctionInfoByID(auctionID)
            if type(info) ~= "table" then
                return
            end

            local buyout = info.buyoutAmount or 0
            if buyout <= 0 or bidPlaced ~= buyout then
                return
            end

            local quantity = rawget(info, "quantity") or 1
            local items = { BuildItemText(info.itemLink or (info.itemKey and info.itemKey.itemID), quantity) }
            RecordAuctionHouseExpense(bidPlaced, "Kauf", items)
        end)
    end

    if C_AuctionHouse.ConfirmCommoditiesPurchase then
        hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, quantity)
            local remaining = quantity or 0
            local totalPrice = 0

            if not C_AuctionHouse.GetNumCommoditySearchResults or not C_AuctionHouse.GetCommoditySearchResultInfo then
                return
            end

            for index = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
                local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
                if type(info) == "table" then
                    local availableQuantity = math.max(0, (info.quantity or 0) - (info.numOwnerItems or 0))
                    local boughtQuantity = math.min(remaining, availableQuantity)

                    if boughtQuantity > 0 then
                        totalPrice = totalPrice + (boughtQuantity * (info.unitPrice or 0))
                        remaining = remaining - boughtQuantity
                    end
                end

                if remaining <= 0 then
                    break
                end
            end

            if remaining > 0 or totalPrice <= 0 then
                return
            end

            local items = { BuildItemText(itemID, quantity) }
            RecordAuctionHouseExpense(totalPrice, "Kauf", items)
        end)
    end

    if TakeInboxMoney then
        hooksecurefunc("TakeInboxMoney", function(index)
            TryRecordAuctionSaleMail(index)
        end)
    end

    if AutoLootMailItem then
        hooksecurefunc("AutoLootMailItem", function(index)
            TryRecordAuctionSaleMail(index)
        end)
    end
end

local function HookVendorSaleActions()
    -- Vendor-Verkäufe werden sicher über Bag-Diffs erkannt, damit keine
    -- geschützten Container-Funktionen ersetzt werden müssen.
    -- Käufe werden dagegen nur vorgemerkt und erst beim tatsächlichen
    -- Geldabzug verbucht, damit Fehlklicks nichts ins Log schreiben.
    if not hooksecurefunc then
        return
    end

    local buyMerchantItemValue = rawget(_G, "BuyMerchantItem")
    local getMerchantItemLinkValue = rawget(_G, "GetMerchantItemLink")
    local merchantFrameAPI = rawget(_G, "C_MerchantFrame")

    if type(buyMerchantItemValue) == "function"
        and type(getMerchantItemLinkValue) == "function"
        and type(merchantFrameAPI) == "table"
        and type(merchantFrameAPI.GetItemInfo) == "function"
    then
        hooksecurefunc("BuyMerchantItem", function(index, quantity)
            local itemInfo = merchantFrameAPI.GetItemInfo(index)
            if type(itemInfo) ~= "table" then
                return
            end

            local itemName = itemInfo.name
            local itemPrice = itemInfo.price
            local stackSize = itemInfo.stackCount
            local cleanPrice = math.max(0, math.floor((tonumber(itemPrice) or 0) + 0.5))
            if cleanPrice <= 0 then
                return
            end

            local purchaseCount = math.max(1, tonumber(quantity) or 1)
            local itemCount = math.max(1, tonumber(stackSize) or 1) * purchaseCount
            local totalAmount = cleanPrice * purchaseCount
            local itemEntry = BuildItemText(getMerchantItemLinkValue(index), itemCount, itemName)

            itemEntry.amount = totalAmount

            if itemCount > 0 and (totalAmount % itemCount) == 0 then
                itemEntry.unitAmount = totalAmount / itemCount
            end

            Logging._QueuePendingVendorExpense(totalAmount, GetMerchantContextLabel(), { itemEntry })
        end)
    end

    if BuybackItem and GetBuybackItemInfo and GetBuybackItemLink then
        hooksecurefunc("BuybackItem", function(index)
            local itemName, _, itemPrice, itemCount = GetBuybackItemInfo(index)
            local cleanPrice = math.max(0, math.floor((tonumber(itemPrice) or 0) + 0.5))
            if cleanPrice <= 0 then
                return
            end

            local quantity = math.max(1, tonumber(itemCount) or 1)
            local itemEntry = BuildItemText(GetBuybackItemLink(index), quantity, itemName)

            itemEntry.amount = cleanPrice

            if quantity > 0 and (cleanPrice % quantity) == 0 then
                itemEntry.unitAmount = cleanPrice / quantity
            end

            Logging._QueuePendingVendorExpense(cleanPrice, GetMerchantContextLabel(), { itemEntry })
        end)
    end
end

InstallInboxMoneyHooks()
HookAuctionHouseActions()
HookVendorSaleActions()

if hooksecurefunc and RepairAllItems then
    hooksecurefunc("RepairAllItems", function(useGuildBank)
        if LoggingState.lastRepairAllCostSeen and LoggingState.lastRepairAllCostSeen > 0 then
            RecordRepair(
                LoggingState.lastRepairAllCostSeen,
                useGuildBank and L("LOGGING_GUILD") or L("LOGGING_OWN_GOLD")
            )
            LoggingState.lastRepairAllCostSeen = 0
        end
    end)
end

local function CreateLogPanel(parent, anchorFrame, titleText, hintText)
    -- Alle vier Logging-Bereiche teilen sich absichtlich denselben Aufbau.
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -18)
    panel:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, -18)
    panel:SetHeight(190)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

    local border = panel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.82)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -12)
    title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    title:SetTextColor(1, 0.88, 0.62, 1)
    title:SetWordWrap(false)
    title:SetText(titleText)
    panel.Title = title

    local hint = panel:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    hint:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hint:SetTextColor(0.78, 0.74, 0.69, 1)
    hint:SetWordWrap(false)
    hint:SetText(hintText)
    panel.Hint = hint

    panel.SummaryLines = {}
    panel.Rows = {}

    local emptyText = panel:CreateFontString(nil, "OVERLAY")
    emptyText:SetJustifyH("LEFT")
    emptyText:SetJustifyV("TOP")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    emptyText:SetTextColor(0.75, 0.75, 0.75, 1)
    emptyText:SetText(L("NO_ENTRIES"))
    emptyText:Hide()
    panel.EmptyText = emptyText

    return panel
end

local function GetOrCreateSummaryLine(panel, index)
    local line = panel.SummaryLines[index]
    if line then
        return line
    end

    line = panel:CreateFontString(nil, "OVERLAY")
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    line:SetTextColor(0.88, 0.88, 0.88, 1)
    panel.SummaryLines[index] = line
    return line
end

local function GetOrCreateLogRow(panel, index)
    local row = panel.Rows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, panel)
    row:SetHeight(14)
    row:EnableMouse(true)

    local leftText = row:CreateFontString(nil, "OVERLAY")
    leftText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    leftText:SetJustifyH("LEFT")
    leftText:SetJustifyV("TOP")
    leftText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    leftText:SetTextColor(0.95, 0.91, 0.85, 1)
    leftText:SetWordWrap(false)
    if leftText.SetNonSpaceWrap then
        leftText:SetNonSpaceWrap(false)
    end
    row.LeftText = leftText

    local rightText = row:CreateFontString(nil, "OVERLAY")
    rightText:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    rightText:SetJustifyH("RIGHT")
    rightText:SetJustifyV("TOP")
    rightText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    rightText:SetTextColor(1, 0.88, 0.62, 1)
    rightText:SetWordWrap(false)
    if rightText.SetNonSpaceWrap then
        rightText:SetNonSpaceWrap(false)
    end
    row.RightText = rightText

    local detailText = row:CreateFontString(nil, "OVERLAY")
    detailText:SetJustifyH("LEFT")
    detailText:SetJustifyV("TOP")
    detailText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    detailText:SetTextColor(0.78, 0.78, 0.78, 1)
    detailText:Hide()
    row.DetailText = detailText
    row.DetailItemButtons = {}

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.04)
    row.Highlight = highlight

    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 1, 1, 0.04)
    row.Divider = divider

    row:SetScript("OnMouseUp", function(self)
        if self.expandable and type(self.OnRowClick) == "function" then
            self.OnRowClick(self)
        end
    end)

    panel.Rows[index] = row
    return row
end

function Logging._HideDetailItemButtons(buttons)
    if type(buttons) ~= "table" then
        return
    end

    for _, button in ipairs(buttons) do
        button.tooltipLink = nil
        button.itemData = nil
        button:Hide()
    end
end

function Logging._GetOrCreateDetailItemButton(parent, buttonStore, index)
    local button = buttonStore[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, parent)
    button:SetHeight(12)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    text:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    text:SetTextColor(0.80, 0.80, 0.82, 1)
    text:SetWordWrap(false)
    if text.SetNonSpaceWrap then
        text:SetNonSpaceWrap(false)
    end
    button.Text = text

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.04)

    button:SetScript("OnEnter", function(self)
        local tooltipLink = self.tooltipLink
        if type(tooltipLink) ~= "string" and self.itemData ~= nil then
            tooltipLink = Logging._ResolveLogItemTooltipLink(self.itemData)
            self.tooltipLink = tooltipLink
        end

        local gameTooltip = rawget(_G, "GameTooltip")
        if type(tooltipLink) ~= "string"
            or type(gameTooltip) ~= "table"
            or type(gameTooltip.SetOwner) ~= "function"
            or type(gameTooltip.SetHyperlink) ~= "function" then
            return
        end

        gameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        gameTooltip:SetHyperlink(tooltipLink)
        gameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        local gameTooltip = rawget(_G, "GameTooltip")
        if type(gameTooltip) == "table" and type(gameTooltip.Hide) == "function" then
            gameTooltip:Hide()
        end
    end)

    buttonStore[index] = button
    return button
end

function Logging._LayoutDetailItemButtons(parent, buttonStore, anchorFrame, xOffset, yOffset, width, items)
    Logging._HideDetailItemButtons(buttonStore)

    if type(items) ~= "table" or #items == 0 then
        return 0
    end

    local previousButton = nil
    local usedHeight = 0

    for index, itemData in ipairs(items) do
        local button = Logging._GetOrCreateDetailItemButton(parent, buttonStore, index)
        button:ClearAllPoints()

        if previousButton then
            button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -2)
            usedHeight = usedHeight + 2
        else
            button:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", xOffset, yOffset)
            usedHeight = usedHeight + math.abs(yOffset)
        end

        button:SetWidth(width)
        button.Text:SetWidth(width)
        button.Text:SetText("- " .. Logging._BuildExpandedItemLine(itemData))
        button.itemData = itemData
        button.tooltipLink = Logging._ResolveLogItemTooltipLink(itemData)
        button:EnableMouse(itemData ~= nil)

        local buttonHeight = math.max(12, math.ceil(button.Text:GetStringHeight()) + 2)
        button:SetHeight(buttonHeight)
        button:Show()

        usedHeight = usedHeight + buttonHeight
        previousButton = button
    end

    return usedHeight
end

local function ResetPanelEntries(panel)
    for _, line in ipairs(panel.SummaryLines) do
        line:Hide()
    end

    for _, row in ipairs(panel.Rows) do
        row.expandable = false
        row.OnRowClick = nil
        Logging._HideDetailItemButtons(row.DetailItemButtons)
        row:Hide()
    end

    panel.EmptyText:Hide()
end

local function LayoutSummaryLine(panel, index, currentY, text)
    local line = GetOrCreateSummaryLine(panel, index)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
    line:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    line:SetText(text)
    line:Show()

    return currentY - math.max(14, math.ceil(line:GetStringHeight()) + 2)
end

local function LayoutLogRow(panel, index, currentY, leftText, rightText, options)
    -- Eine Zeile kann optional aufklappbar sein.
    -- Genau das nutzen wir für Verkaufseinträge und Reparaturtage.
    local panelWidth = math.max(280, panel:GetWidth())
    local row = GetOrCreateLogRow(panel, index)
    local settings = options or {}
    local isExpandable = settings.expandable == true
    local isExpanded = settings.expanded == true
    local detailsText = settings.detailsText
    local detailItems = settings.detailItems

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
    row:SetPoint("RIGHT", panel, "RIGHT", -18, 0)

    row.expandable = isExpandable
    row.OnRowClick = settings.onClick
    row.Highlight:SetShown(isExpandable)
    Logging._HideDetailItemButtons(row.DetailItemButtons)

    row.RightText:SetText(rightText or "")
    local rightWidth = LOGGING_ROW_RIGHT_TEXT_MIN_WIDTH
    if row.RightText.GetUnboundedStringWidth then
        rightWidth = math.ceil(row.RightText:GetUnboundedStringWidth()) + 12
    elseif row.RightText.GetStringWidth then
        rightWidth = math.ceil(row.RightText:GetStringWidth()) + 12
    end
    rightWidth = math.min(
        math.max(LOGGING_ROW_RIGHT_TEXT_MIN_WIDTH, math.floor(panelWidth * LOGGING_ROW_RIGHT_TEXT_MAX_WIDTH_FACTOR)),
        math.max(LOGGING_ROW_RIGHT_TEXT_MIN_WIDTH, rightWidth)
    )
    row.RightText:ClearAllPoints()
    row.RightText:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    row.RightText:SetWidth(rightWidth)
    row.LeftText:ClearAllPoints()
    row.LeftText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.LeftText:SetPoint("TOPRIGHT", row.RightText, "TOPLEFT", -LOGGING_ROW_TEXT_GAP, 0)
    local detailWidth = math.max(120, panelWidth - 34)
    local detailItemWidth = math.max(180, panelWidth - 34)
    if isExpandable then
        row.LeftText:SetText(string.format("%s %s", isExpanded and "[-]" or "[+]", leftText or ""))
    else
        row.LeftText:SetText(leftText or "")
    end

    if isExpandable and isExpanded and type(detailsText) == "string" and detailsText ~= "" then
        row.DetailText:ClearAllPoints()
        row.DetailText:SetPoint("TOPLEFT", row.LeftText, "BOTTOMLEFT", 16, -4)
        row.DetailText:SetWidth(detailWidth)
        row.DetailText:SetText(detailsText)
        row.DetailText:Show()
    else
        row.DetailText:SetText("")
        row.DetailText:Hide()
    end

    local detailButtonsHeight = 0
    if isExpandable and isExpanded then
        if row.DetailText:IsShown() then
            detailButtonsHeight = Logging._LayoutDetailItemButtons(row, row.DetailItemButtons, row.DetailText, 0, -6, detailItemWidth, detailItems)
        else
            detailButtonsHeight = Logging._LayoutDetailItemButtons(row, row.DetailItemButtons, row.LeftText, 16, -4, detailItemWidth, detailItems)
        end
    end

    local rowHeight = math.max(LOGGING_MIN_ROW_HEIGHT, math.ceil(math.max(row.LeftText:GetStringHeight(), row.RightText:GetStringHeight()) + 2))
    if row.DetailText:IsShown() then
        rowHeight = rowHeight + math.ceil(row.DetailText:GetStringHeight()) + 6
    end
    if detailButtonsHeight > 0 then
        rowHeight = rowHeight + detailButtonsHeight
    end

    row:SetHeight(rowHeight)
    row:Show()

    return currentY - rowHeight - LOGGING_ROW_SPACING
end

local function SumAmounts(entries)
    local total = 0

    for _, entry in ipairs(entries) do
        total = total + (entry.amount or 0)
    end

    return total
end

local function BuildSalesEntryKey(entry, index)
    return string.format(
        "%s|%s|%s|%s",
        tostring(index or 0),
        tostring(entry.timestamp or 0),
        tostring(entry.source or ""),
        tostring(entry.amount or 0)
    )
end

local function BuildMoneyEntryKey(sectionKey, entry, index)
    return string.format(
        "%s|%s|%s|%s|%s|%s",
        tostring(sectionKey or "money"),
        tostring(index or 0),
        tostring(entry.timestamp or 0),
        tostring(entry.category or ""),
        tostring(entry.note or ""),
        tostring(entry.amount or 0)
    )
end

local function SalesEntryHasDetails(entry)
    return type(entry.items) == "table" and #entry.items > 0
end

local function BuildSalesEntrySummary(entry)
    local details = entry.source or L("LOGGING_SALE")
    local itemCount = math.max(0, tonumber(entry.itemCount) or 0)

    if itemCount > 0 then
        details = string.format("%s | %d %s", details, itemCount, itemCount == 1 and L("LOGGING_ITEM") or L("LOGGING_ITEMS"))
    end

    return details
end

local function BuildSalesEntryExpandedText(entry)
    if not SalesEntryHasDetails(entry) then
        return nil
    end

    return BuildExpandedItemText(entry.items)
end

local function BuildRepairDayKey(dayEntry)
    return tostring(dayEntry.dayKey or "")
end

local function BuildRepairDaySummary(dayEntry)
    local repairCount = type(dayEntry.entries) == "table" and #dayEntry.entries or 0
    local summary = FormatDayKey(dayEntry.dayKey)

    if repairCount > 0 then
        summary = string.format("%s | %d %s", summary, repairCount, repairCount == 1 and L("LOGGING_REPAIR") or L("LOGGING_REPAIRS"))
    end

    if (dayEntry.personal or 0) < (dayEntry.total or 0) then
        summary = string.format("%s | %s: %s", summary, L("LOGGING_SELF_PAID"), FormatCoins(dayEntry.personal or 0))
    end

    return summary
end

local function BuildRepairDayExpandedText(dayEntry)
    if type(dayEntry.entries) ~= "table" or #dayEntry.entries == 0 then
        return nil
    end

    local lines = {}

    for _, entry in ipairs(dayEntry.entries) do
        lines[#lines + 1] = string.format(
            "- %s | %s | %s",
            FormatClockTime(entry.timestamp),
            entry.source or L("LOGGING_REPAIR"),
            FormatCoins(entry.amount or 0)
        )
    end

    return table.concat(lines, "\n")
end

local function BuildMoneyEntryContextText(entry)
    if type(entry) ~= "table" then
        return L("LOGGING_ENTRY")
    end

    local category = type(entry.category) == "string" and entry.category ~= "" and entry.category or L("LOGGING_ENTRY")
    local note = type(entry.note) == "string" and entry.note ~= "" and entry.note or nil

    if category == L("LOGGING_REPAIR") then
        if note then
            return string.format("%s: %s", category, note)
        end

        return category
    end

    if note then
        if note == category then
            return note
        end

        if note:sub(1, #category + 2) == category .. ": " then
            return note
        end

        return string.format("%s | %s", category, note)
    end

    return category
end

local function BuildMoneyEntryItemSummary(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return BuildItemListSummary(entry.items)
end

local function BuildMoneyEntryDetails(entry)
    local details = BuildMoneyEntryContextText(entry)
    local itemSummary = BuildMoneyEntryItemSummary(entry)
    if itemSummary then
        details = string.format("%s\n%s: %s", details, L("ITEMS_LABEL"), itemSummary)
    end

    return details
end

local function BuildMoneyEntryPrimaryText(entry)
    local contextText = BuildMoneyEntryContextText(entry)
    local itemSummary = BuildMoneyEntryItemSummary(entry)

    if itemSummary then
        return string.format("%s | %s", contextText, itemSummary)
    end

    return contextText
end

local function BuildMoneyEntryExpandedText(entry)
    local itemDetails = BuildExpandedItemText(entry.items)
    if itemDetails then
        return itemDetails
    end

    local details = BuildMoneyEntryDetails(entry)
    if details == BuildMoneyEntryPrimaryText(entry) then
        return nil
    end

    if entry.category == L("LOGGING_SALE") then
        return nil
    end

    return details
end

local function BuildMoneyEntrySearchText(entry)
    local primaryText = BuildMoneyEntryPrimaryText(entry)
    local detailsText = BuildMoneyEntryDetails(entry)

    if detailsText == primaryText then
        return primaryText
    end

    return string.format("%s\n%s", primaryText, detailsText)
end

local function FormatSignedQuantity(amount)
    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    return cleanAmount > 0 and string.format("+%d", cleanAmount) or "0"
end

local function FormatCurrencyLabel(name, iconFileID)
    if type(iconFileID) == "number" and iconFileID > 0 then
        return string.format("|T%d:0|t %s", iconFileID, name or L("LOGGING_MISC"))
    end

    return name or L("LOGGING_MISC")
end

local function BuildCurrencyTotals(entries)
    local buckets = {}

    for _, entry in ipairs(entries) do
        local bucketKey = tostring(entry.currencyID or entry.name or "")
        buckets[bucketKey] = buckets[bucketKey] or {
            name = entry.name or L("LOGGING_MISC"),
            iconFileID = entry.iconFileID,
            income = 0,
            expense = 0,
            count = 0,
            lastTimestamp = 0,
        }

        if entry.direction == "expense" then
            buckets[bucketKey].expense = buckets[bucketKey].expense + (entry.amount or 0)
        else
            buckets[bucketKey].income = buckets[bucketKey].income + (entry.amount or 0)
        end

        buckets[bucketKey].count = buckets[bucketKey].count + 1
        buckets[bucketKey].lastTimestamp = math.max(buckets[bucketKey].lastTimestamp, entry.timestamp or 0)
    end

    local ordered = {}
    for _, bucket in pairs(buckets) do
        ordered[#ordered + 1] = bucket
    end

    table.sort(ordered, function(left, right)
        if left.lastTimestamp == right.lastTimestamp then
            return left.name < right.name
        end

        return left.lastTimestamp > right.lastTimestamp
    end)

    return ordered
end

local function BuildCurrencyEntryDetails(entry)
    local details = entry.category or L("LOGGING_MISC")

    if type(entry.note) == "string" and entry.note ~= "" then
        details = string.format("%s | %s", details, entry.note)
    end

    return details
end

local function BuildCurrencyEntryPrimaryText(entry)
    local primaryText = FormatCurrencyLabel(entry.name, entry.iconFileID)

    if type(entry.note) == "string" and entry.note ~= "" then
        primaryText = string.format("%s | %s", primaryText, entry.note)
    end

    return primaryText
end

local function BuildCurrencyEntryExpandedText(entry)
    local detailsText = BuildCurrencyEntryDetails(entry)
    local comparablePrimaryText = tostring(entry.name or L("LOGGING_MISC"))

    if type(entry.note) == "string" and entry.note ~= "" then
        comparablePrimaryText = string.format("%s | %s", comparablePrimaryText, entry.note)
    end

    if detailsText == comparablePrimaryText then
        return nil
    end

    return detailsText
end

local function BuildCurrencyEntryKey(entry, index)
    return string.format(
        "%s|%s|%s|%s|%s|%s",
        tostring(index or 0),
        tostring(entry.timestamp or 0),
        tostring(entry.currencyID or 0),
        tostring(entry.name or ""),
        tostring(entry.note or ""),
        tostring(entry.amount or 0)
    )
end

local function BuildCurrencyEntrySearchText(entry)
    local primaryText = tostring(entry.name or L("LOGGING_MISC"))
    local detailsText = BuildCurrencyEntryDetails(entry)

    if type(entry.note) == "string" and entry.note ~= "" then
        primaryText = string.format("%s | %s", primaryText, entry.note)
    end

    if detailsText == primaryText then
        return primaryText
    end

    return string.format("%s\n%s", primaryText, detailsText)
end

local function BuildRepairDaySearchText(dayEntry)
    local summaryText = BuildRepairDaySummary(dayEntry)
    local detailsText = BuildRepairDayExpandedText(dayEntry)

    if type(detailsText) == "string" and detailsText ~= "" then
        return string.format("%s\n%s", summaryText, detailsText)
    end

    return summaryText
end

local function NormalizeLoggingSearchText(text)
    local normalized = tostring(text or ""):lower()
    normalized = normalized:gsub("%s+", " ")
    return normalized:match("^%s*(.-)%s*$") or ""
end

local function MatchesLoggingSearch(searchText, text)
    if searchText == "" then
        return true
    end

    return NormalizeLoggingSearchText(text):find(searchText, 1, true) ~= nil
end

local function CollectOverviewEntries(entries, searchText, buildSearchText)
    local ordered = {}

    if type(entries) ~= "table" then
        return ordered
    end

    if searchText == "" then
        for index = #entries, math.max(1, #entries - (OVERVIEW_LOG_ENTRY_COUNT - 1)), -1 do
            ordered[#ordered + 1] = {
                entry = entries[index],
                index = index,
            }
        end

        return ordered
    end

    for index = #entries, 1, -1 do
        local entry = entries[index]
        if MatchesLoggingSearch(searchText, buildSearchText(entry)) then
            ordered[#ordered + 1] = {
                entry = entry,
                index = index,
            }
            if #ordered >= OVERVIEW_SEARCH_MATCH_LIMIT then
                break
            end
        end
    end

    return ordered
end

local function CollectOverviewRepairDays(repairDays, searchText)
    local ordered = {}

    if type(repairDays) ~= "table" then
        return ordered
    end

    if searchText == "" then
        for index = 1, math.min(OVERVIEW_LOG_ENTRY_COUNT, #repairDays) do
            ordered[#ordered + 1] = {
                entry = repairDays[index],
                index = index,
            }
        end

        return ordered
    end

    for index = 1, #repairDays do
        local dayEntry = repairDays[index]
        if MatchesLoggingSearch(searchText, BuildRepairDaySearchText(dayEntry)) then
            ordered[#ordered + 1] = {
                entry = dayEntry,
                index = index,
            }
            if #ordered >= OVERVIEW_SEARCH_MATCH_LIMIT then
                break
            end
        end
    end

    return ordered
end

local function ShowPanelEmptyText(panel, searchText)
    panel.EmptyText:ClearAllPoints()
    panel.EmptyText:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, LOGGING_PANEL_ROW_START_Y)
    panel.EmptyText:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    panel.EmptyText:SetText(searchText ~= "" and L("LOGGING_OVERVIEW_NO_MATCHES") or L("NO_ENTRIES"))
    panel.EmptyText:Show()
end

local function BuildCategoryTotals(entries)
    local buckets = {}

    for _, entry in ipairs(entries) do
        local category = entry.category or L("LOGGING_MISC")

        buckets[category] = buckets[category] or {
            category = category,
            total = 0,
            count = 0,
            lastTimestamp = 0,
        }

        buckets[category].total = buckets[category].total + (entry.amount or 0)
        buckets[category].count = buckets[category].count + 1
        buckets[category].lastTimestamp = math.max(buckets[category].lastTimestamp, entry.timestamp or 0)
    end

    local ordered = {}
    for _, bucket in pairs(buckets) do
        ordered[#ordered + 1] = bucket
    end

    table.sort(ordered, function(a, b)
        if a.total == b.total then
            return a.category < b.category
        end

        return a.total > b.total
    end)

    return ordered
end

local function BuildDailyRepairTotals()
    local groupedByDay = {}
    local orderedDays = {}

    for dayKey, totals in pairs(Logging.GetRepairDailyTotals()) do
        groupedByDay[dayKey] = {
            dayKey = dayKey,
            total = totals.total or 0,
            personal = totals.personal or 0,
            entries = {},
            hasStoredTotals = true,
        }
        orderedDays[#orderedDays + 1] = dayKey
    end

    for _, entry in ipairs(Logging.GetRepairLog()) do
        local dayKey = GetDayKey(entry.timestamp)
        local dayEntry = groupedByDay[dayKey]

        if not dayEntry then
            dayEntry = {
                dayKey = dayKey,
                total = 0,
                personal = 0,
                entries = {},
                hasStoredTotals = false,
            }
            groupedByDay[dayKey] = dayEntry
            orderedDays[#orderedDays + 1] = dayKey
        end

        dayEntry.entries[#dayEntry.entries + 1] = entry
        if not dayEntry.hasStoredTotals then
            dayEntry.total = dayEntry.total + (entry.amount or 0)

            if (entry.source or L("LOGGING_OWN_GOLD")) ~= L("LOGGING_GUILD") then
                dayEntry.personal = dayEntry.personal + (entry.amount or 0)
            end
        end
    end

    local dayEntries = {}
    local seenDays = {}

    for _, dayKey in ipairs(orderedDays) do
        if not seenDays[dayKey] then
            local dayEntry = groupedByDay[dayKey]
            if dayEntry then
                table.sort(dayEntry.entries, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)

                dayEntries[#dayEntries + 1] = dayEntry
                seenDays[dayKey] = true
            end
        end
    end

    table.sort(dayEntries, function(a, b)
        return a.dayKey > b.dayKey
    end)

    return dayEntries
end

PageLogging = CreateFrame("Frame", nil, Content)
PageLogging:SetAllPoints()
PageLogging:Hide()

local PageLoggingScrollFrame = CreateFrame("ScrollFrame", nil, PageLogging, "UIPanelScrollFrameTemplate")
PageLoggingScrollFrame:SetPoint("TOPLEFT", PageLogging, "TOPLEFT", 0, 0)
PageLoggingScrollFrame:SetPoint("BOTTOMRIGHT", PageLogging, "BOTTOMRIGHT", -28, 0)
PageLoggingScrollFrame:EnableMouseWheel(true)

local PageLoggingContent = CreateFrame("Frame", nil, PageLoggingScrollFrame)
PageLoggingContent:SetSize(1, 1)
PageLoggingScrollFrame:SetScrollChild(PageLoggingContent)

local IntroPanel = CreateFrame("Frame", nil, PageLoggingContent)
IntroPanel:SetPoint("TOPLEFT", PageLoggingContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageLoggingContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(LOGGING_INTRO_PANEL_HEIGHT)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 16, -12)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
IntroTitle:SetTextColor(1, 0.88, 0.62, 1)
IntroTitle:SetText(BeavisQoL.GetModulePageTitle("Logging", L("GOLDAUSWERTUNG")))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -6)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -16, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
IntroText:SetText(L("LOGGING_DESC"))

local CleanupButton = CreateFrame("Button", nil, IntroPanel, "UIPanelButtonTemplate")
CleanupButton:SetSize(134, 22)
CleanupButton:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", -16, 10)
CleanupButton:SetText(L("LOGGING_CLEANUP"))

local RetentionHint = IntroPanel:CreateFontString(nil, "OVERLAY")
RetentionHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
RetentionHint:SetPoint("RIGHT", CleanupButton, "LEFT", -12, 0)
RetentionHint:SetJustifyH("LEFT")
RetentionHint:SetJustifyV("TOP")
RetentionHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
RetentionHint:SetTextColor(0.78, 0.74, 0.69, 1)
RetentionHint:SetText(L("LOGGING_RETENTION_HINT"))

local LoggingMinimapContextCheckbox = CreateFrame("CheckButton", nil, IntroPanel, "UICheckButtonTemplate")
LoggingMinimapContextCheckbox:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 12, 8)
LoggingMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("logging") or true)
LoggingMinimapContextCheckbox:SetScript("OnClick", function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("logging", self:GetChecked())
    end
end)

local LoggingMinimapContextLabel = IntroPanel:CreateFontString(nil, "OVERLAY")
LoggingMinimapContextLabel:SetPoint("LEFT", LoggingMinimapContextCheckbox, "RIGHT", 6, 0)
LoggingMinimapContextLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
LoggingMinimapContextLabel:SetTextColor(0.95, 0.91, 0.85, 1)
LoggingMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))

IntroPanel.OverviewSearchBox = CreateFrame("EditBox", nil, IntroPanel, "InputBoxTemplate")
IntroPanel.OverviewSearchBox:SetSize(236, 24)
IntroPanel.OverviewSearchBox:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", -16, 42)
IntroPanel.OverviewSearchBox:SetAutoFocus(false)
IntroPanel.OverviewSearchBox:SetMaxLetters(64)
IntroPanel.OverviewSearchBox:SetScript("OnTextChanged", function()
    RequestLoggingPageRefresh()
end)
IntroPanel.OverviewSearchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

IntroPanel.OverviewSearchBox.Label = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroPanel.OverviewSearchBox.Label:SetPoint("BOTTOMLEFT", IntroPanel.OverviewSearchBox, "TOPLEFT", 4, 6)
IntroPanel.OverviewSearchBox.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroPanel.OverviewSearchBox.Label:SetTextColor(1, 0.88, 0.62, 1)

local function CreateCleanupChoiceButton(parent, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(126, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

CleanupPopup = CreateFrame("Frame", nil, PageLogging, BackdropTemplateMixin and "BackdropTemplate")
CleanupPopup:SetSize(312, 184)
CleanupPopup:SetPoint("CENTER", PageLogging, "CENTER", 0, 20)
CleanupPopup:SetFrameStrata("DIALOG")
CleanupPopup:EnableMouse(true)
CleanupPopup:SetClampedToScreen(true)
CleanupPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
CleanupPopup:SetBackdropColor(0.05, 0.05, 0.05, 0.96)
CleanupPopup:SetBackdropBorderColor(1, 0.82, 0, 0.95)
CleanupPopup:Hide()

local CleanupPopupTitle = CleanupPopup:CreateFontString(nil, "OVERLAY")
CleanupPopupTitle:SetPoint("TOPLEFT", CleanupPopup, "TOPLEFT", 16, -14)
CleanupPopupTitle:SetPoint("RIGHT", CleanupPopup, "RIGHT", -16, 0)
CleanupPopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CleanupPopupTitle:SetTextColor(1, 0.88, 0.62, 1)
CleanupPopupTitle:SetText(L("LOGGING_CLEANUP_TITLE"))

local CleanupPopupHint = CleanupPopup:CreateFontString(nil, "OVERLAY")
CleanupPopupHint:SetPoint("TOPLEFT", CleanupPopupTitle, "BOTTOMLEFT", 0, -10)
CleanupPopupHint:SetPoint("RIGHT", CleanupPopup, "RIGHT", -16, 0)
CleanupPopupHint:SetJustifyH("LEFT")
CleanupPopupHint:SetJustifyV("TOP")
CleanupPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
CleanupPopupHint:SetTextColor(0.85, 0.85, 0.85, 1)
CleanupPopupHint:SetText(L("LOGGING_CLEANUP_HINT"))

local function CloseCleanupPopup()
    if CleanupPopup then
        CleanupPopup:Hide()
    end
end

local function ApplyCleanupRange(days)
    Logging.ClearLogsOlderThanDays(days)
    CloseCleanupPopup()
end

local CleanupSevenDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_7"), function()
    ApplyCleanupRange(7)
end)
CleanupSevenDaysButton:SetPoint("TOPLEFT", CleanupPopupHint, "BOTTOMLEFT", 0, -16)

local CleanupThirtyDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_30"), function()
    ApplyCleanupRange(30)
end)
CleanupThirtyDaysButton:SetPoint("LEFT", CleanupSevenDaysButton, "RIGHT", 10, 0)

local CleanupNinetyDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_90"), function()
    ApplyCleanupRange(90)
end)
CleanupNinetyDaysButton:SetPoint("TOPLEFT", CleanupSevenDaysButton, "BOTTOMLEFT", 0, -10)

local CleanupOneYearButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_365"), function()
    ApplyCleanupRange(365)
end)
CleanupOneYearButton:SetPoint("LEFT", CleanupNinetyDaysButton, "RIGHT", 10, 0)

local CleanupAllButton = CreateCleanupChoiceButton(CleanupPopup, L("ALL"), function()
    ApplyCleanupRange("all")
end)
CleanupAllButton:SetPoint("TOPLEFT", CleanupNinetyDaysButton, "BOTTOMLEFT", 0, -10)

local CleanupCancelButton = CreateCleanupChoiceButton(CleanupPopup, L("CANCEL"), CloseCleanupPopup)
CleanupCancelButton:SetPoint("LEFT", CleanupAllButton, "RIGHT", 10, 0)

local function CloseHistoryPopup()
    if HistoryPopup then
        HistoryPopup:Hide()
    end
end

local function GetOverviewSearchText()
    if not IntroPanel or not IntroPanel.OverviewSearchBox or not IntroPanel.OverviewSearchBox.GetText then
        return ""
    end

    return NormalizeLoggingSearchText(IntroPanel.OverviewSearchBox:GetText())
end

local function GetHistorySearchText()
    if not HistoryPopup or not HistoryPopup.SearchBox or not HistoryPopup.SearchBox.GetText then
        return ""
    end

    return NormalizeLoggingSearchText(HistoryPopup.SearchBox:GetText())
end

local function ResetHistoryLoadedCount(tabKey)
    if type(tabKey) == "string" and HistoryLoadedCountByTab[tabKey] then
        HistoryLoadedCountByTab[tabKey] = HISTORY_PAGE_SIZE
        return
    end

    for _, key in ipairs(HISTORY_TAB_KEYS) do
        HistoryLoadedCountByTab[key] = HISTORY_PAGE_SIZE
    end
end

local function GetHistoryTabTitle(tabKey)
    if tabKey == "income" then
        return L("LOGGING_HISTORY_TAB_INCOME")
    end

    if tabKey == "expense" then
        return L("LOGGING_HISTORY_TAB_EXPENSE")
    end

    if tabKey == "repairs" then
        return L("LOGGING_HISTORY_TAB_REPAIRS")
    end

    return L("LOGGING_HISTORY_TAB_CURRENCY")
end

local function GetHistoryEntriesForTab(tabKey)
    if tabKey == "income" then
        return Logging.GetIncomeLog()
    end

    if tabKey == "expense" then
        return Logging.GetExpenseLog()
    end

    if tabKey == "repairs" then
        return Logging.GetRepairLog()
    end

    return Logging.GetCurrencyLog()
end

local function BuildHistoryRecordForTab(tabKey, entry)
    local record = {
        timestampText = FormatTimestamp(entry.timestamp),
        primaryText = L("LOGGING_ENTRY"),
        secondaryText = nil,
        detailText = nil,
        detailItems = nil,
        amountText = "",
        amountRed = 1,
        amountGreen = 0.82,
        amountBlue = 0,
        searchText = "",
    }

    if tabKey == "income" or tabKey == "expense" then
        local contextText = BuildMoneyEntryContextText(entry)
        local itemSummary = BuildMoneyEntryItemSummary(entry)

        record.primaryText = contextText
        if itemSummary then
            record.secondaryText = itemSummary
        end

        if type(entry.items) == "table" and #entry.items > 0 then
            record.detailItems = entry.items
        else
            record.detailText = BuildMoneyEntryExpandedText(entry)
        end
        record.amountText = FormatCoins(entry.amount)
        if tabKey == "income" then
            record.amountRed = 0.34
            record.amountGreen = 0.84
            record.amountBlue = 0.42
        else
            record.amountRed = 0.95
            record.amountGreen = 0.40
            record.amountBlue = 0.32
        end
        record.searchText = string.format(
            "%s\n%s\n%s\n%s",
            record.timestampText,
            record.primaryText or "",
            record.secondaryText or "",
            BuildMoneyEntrySearchText(entry)
        )
        return record
    end

    if tabKey == "repairs" then
        record.primaryText = entry.source or L("LOGGING_REPAIR")
        record.secondaryText = L("LOGGING_REPAIR")
        record.amountText = FormatCoins(entry.amount or 0)
        record.amountRed = 1
        record.amountGreen = 0.82
        record.amountBlue = 0
        record.searchText = string.format(
            "%s\n%s\n%s",
            record.timestampText,
            record.primaryText or "",
            record.secondaryText or ""
        )
        return record
    end

    record.primaryText = FormatCurrencyLabel(entry.name, entry.iconFileID)

    local secondaryParts = {}
    if type(entry.category) == "string" and entry.category ~= "" and entry.category ~= (entry.name or "") then
        secondaryParts[#secondaryParts + 1] = entry.category
    end
    if type(entry.note) == "string" and entry.note ~= "" then
        secondaryParts[#secondaryParts + 1] = entry.note
    end
    if #secondaryParts > 0 then
        record.secondaryText = table.concat(secondaryParts, " | ")
    end

    record.amountText = string.format("%s%d", entry.direction == "expense" and "-" or "+", entry.amount or 0)
    if entry.direction == "expense" then
        record.amountRed = 0.95
        record.amountGreen = 0.40
        record.amountBlue = 0.32
    else
        record.amountRed = 0.34
        record.amountGreen = 0.84
        record.amountBlue = 0.42
    end
    record.searchText = string.format(
        "%s\n%s\n%s\n%s",
        record.timestampText,
        tostring(entry.name or L("LOGGING_MISC")),
        record.secondaryText or "",
        BuildCurrencyEntrySearchText(entry)
    )
    return record
end

local function CollectHistoryRecords()
    local tabKey = HistoryActiveTabKey or "income"
    local entries = GetHistoryEntriesForTab(tabKey)
    local searchText = GetHistorySearchText()
    local entryLimit = HistoryLoadedCountByTab[tabKey] or HISTORY_PAGE_SIZE
    local visibleRecords = {}
    local visibleCount = 0
    local hasMore = false

    if searchText == "" then
        local startIndex = math.max(1, (#entries - entryLimit) + 1)
        for index = #entries, startIndex, -1 do
            visibleRecords[#visibleRecords + 1] = BuildHistoryRecordForTab(tabKey, entries[index])
            visibleCount = visibleCount + 1
        end

        hasMore = #entries > entryLimit
    else
        for index = #entries, 1, -1 do
            local record = BuildHistoryRecordForTab(tabKey, entries[index])
            if MatchesLoggingSearch(searchText, record.searchText) then
                if visibleCount < entryLimit then
                    visibleRecords[#visibleRecords + 1] = record
                    visibleCount = visibleCount + 1
                else
                    hasMore = true
                    break
                end
            end
        end
    end

    if visibleCount == 0 then
        if searchText ~= "" then
            return visibleRecords, 0, false, L("LOGGING_HISTORY_NO_MATCHES")
        end

        return visibleRecords, 0, false, L("LOGGING_HISTORY_EMPTY")
    end

    return visibleRecords, visibleCount, hasMore, nil
end

local function GetOrCreateHistoryRow(index)
    local row = HistoryPopup.Rows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, HistoryPopup.Content)
    row:SetHeight(54)

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(1, 1, 1, 0.025)
    row.Background = background

    local accent = row:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(3)
    row.Accent = accent

    local timestampText = row:CreateFontString(nil, "OVERLAY")
    timestampText:SetJustifyH("LEFT")
    timestampText:SetJustifyV("TOP")
    timestampText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    timestampText:SetTextColor(0.70, 0.70, 0.74, 1)
    row.TimestampText = timestampText

    local amountText = row:CreateFontString(nil, "OVERLAY")
    amountText:SetJustifyH("RIGHT")
    amountText:SetJustifyV("TOP")
    amountText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    amountText:SetWordWrap(false)
    if amountText.SetNonSpaceWrap then
        amountText:SetNonSpaceWrap(false)
    end
    row.AmountText = amountText

    local primaryText = row:CreateFontString(nil, "OVERLAY")
    primaryText:SetJustifyH("LEFT")
    primaryText:SetJustifyV("TOP")
    primaryText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    primaryText:SetTextColor(0.96, 0.96, 0.96, 1)
    row.PrimaryText = primaryText

    local secondaryText = row:CreateFontString(nil, "OVERLAY")
    secondaryText:SetJustifyH("LEFT")
    secondaryText:SetJustifyV("TOP")
    secondaryText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    secondaryText:SetTextColor(1, 0.82, 0, 0.92)
    row.SecondaryText = secondaryText

    local detailText = row:CreateFontString(nil, "OVERLAY")
    detailText:SetJustifyH("LEFT")
    detailText:SetJustifyV("TOP")
    detailText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    detailText:SetTextColor(0.80, 0.80, 0.82, 1)
    row.DetailText = detailText
    row.DetailItemButtons = {}

    local divider = row:CreateTexture(nil, "BORDER")
    divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 0)
    divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 1, 1, 0.05)
    row.Divider = divider

    HistoryPopup.Rows[index] = row
    return row
end

local function LayoutHistoryRow(index, currentY, record)
    local row = GetOrCreateHistoryRow(index)
    local contentWidth = HISTORY_CONTENT_WIDTH
    local amountWidth = 168
    local leftWidth = math.max(180, contentWidth - amountWidth - 34)

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", HistoryPopup.Content, "TOPLEFT", 0, currentY)
    row:SetWidth(contentWidth)
    row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.035 or 0.02)
    row.Accent:SetColorTexture(record.amountRed or 1, record.amountGreen or 0.82, record.amountBlue or 0, 0.95)

    row.TimestampText:ClearAllPoints()
    row.TimestampText:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -10)
    row.TimestampText:SetWidth(leftWidth)
    row.TimestampText:SetText(record.timestampText or "")

    row.AmountText:ClearAllPoints()
    row.AmountText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -14, -10)
    row.AmountText:SetWidth(amountWidth)
    row.AmountText:SetTextColor(record.amountRed or 1, record.amountGreen or 0.82, record.amountBlue or 0, 1)
    row.AmountText:SetText(record.amountText or "")

    row.PrimaryText:ClearAllPoints()
    row.PrimaryText:SetPoint("TOPLEFT", row.TimestampText, "BOTTOMLEFT", 0, -4)
    row.PrimaryText:SetWidth(leftWidth)
    row.PrimaryText:SetText(record.primaryText or L("LOGGING_ENTRY"))

    local anchorText = row.PrimaryText

    if type(record.secondaryText) == "string" and record.secondaryText ~= "" then
        row.SecondaryText:ClearAllPoints()
        row.SecondaryText:SetPoint("TOPLEFT", row.PrimaryText, "BOTTOMLEFT", 0, -2)
        row.SecondaryText:SetWidth(leftWidth)
        row.SecondaryText:SetText(record.secondaryText)
        row.SecondaryText:Show()
        anchorText = row.SecondaryText
    else
        row.SecondaryText:SetText("")
        row.SecondaryText:Hide()
    end

    if type(record.detailText) == "string" and record.detailText ~= "" then
        row.DetailText:ClearAllPoints()
        row.DetailText:SetPoint("TOPLEFT", anchorText, "BOTTOMLEFT", 0, -6)
        row.DetailText:SetWidth(contentWidth - 28)
        row.DetailText:SetText(record.detailText)
        row.DetailText:Show()
    else
        row.DetailText:SetText("")
        row.DetailText:Hide()
    end

    Logging._HideDetailItemButtons(row.DetailItemButtons)
    local detailButtonsHeight = 0
    if row.DetailText:IsShown() then
        detailButtonsHeight = Logging._LayoutDetailItemButtons(row, row.DetailItemButtons, row.DetailText, 0, -6, contentWidth - 28, record.detailItems)
    else
        detailButtonsHeight = Logging._LayoutDetailItemButtons(row, row.DetailItemButtons, anchorText, 0, -6, contentWidth - 28, record.detailItems)
    end

    local rowHeight = 20
        + math.ceil(row.TimestampText:GetStringHeight())
        + 4
        + math.ceil(row.PrimaryText:GetStringHeight())

    if row.SecondaryText:IsShown() then
        rowHeight = rowHeight + 2 + math.ceil(row.SecondaryText:GetStringHeight())
    end

    if row.DetailText:IsShown() then
        rowHeight = rowHeight + 6 + math.ceil(row.DetailText:GetStringHeight())
    end
    if detailButtonsHeight > 0 then
        rowHeight = rowHeight + detailButtonsHeight
    end

    row:SetHeight(math.max(54, rowHeight))
    row:Show()

    return currentY - row:GetHeight() - 8
end

local function RefreshHistoryPopup(keepScrollPosition)
    if not HistoryPopup or not HistoryPopup.Content then
        return
    end

    local previousScroll = 0
    if keepScrollPosition and HistoryPopup.ScrollFrame and HistoryPopup.ScrollFrame.GetVerticalScroll then
        previousScroll = HistoryPopup.ScrollFrame:GetVerticalScroll() or 0
    end

    HistoryPopup.Title:SetText(L("LOGGING_HISTORY_TITLE"))
    HistoryPopup.Hint:SetText(L("LOGGING_HISTORY_HINT"))
    HistoryPopup.CloseButton:SetText(L("CANCEL"))
    if HistoryPopup and HistoryPopup.SearchBox and HistoryPopup.SearchBox.Label then
        HistoryPopup.SearchBox.Label:SetText(L("LOGGING_HISTORY_SEARCH"))
    end
    if HistoryPopup and HistoryPopup.LoadMoreButton then
        HistoryPopup.LoadMoreButton:SetText(L("LOGGING_HISTORY_LOAD_MORE"))
    end

    for tabKey, button in pairs(HistoryTabButtons) do
        button:SetText(GetHistoryTabTitle(tabKey))
        button:SetEnabled(tabKey ~= HistoryActiveTabKey)
    end

    local visibleRecords, visibleCount, hasMore, emptyText = CollectHistoryRecords()

    for _, row in ipairs(HistoryPopup.Rows) do
        row:Hide()
    end

    local currentY = -8
    if emptyText then
        HistoryPopup.EmptyText:ClearAllPoints()
        HistoryPopup.EmptyText:SetPoint("TOPLEFT", HistoryPopup.Content, "TOPLEFT", 10, currentY - 10)
        HistoryPopup.EmptyText:SetPoint("RIGHT", HistoryPopup.Content, "RIGHT", -10, 0)
        HistoryPopup.EmptyText:SetText(emptyText)
        HistoryPopup.EmptyText:Show()
        currentY = currentY - 56
    else
        HistoryPopup.EmptyText:Hide()
        for index, record in ipairs(visibleRecords) do
            currentY = LayoutHistoryRow(index, currentY, record)
        end
    end

    HistoryPopup.Content:SetHeight(math.max(1, -currentY + 12))

    local maxScroll = math.max(0, HistoryPopup.Content:GetHeight() - HistoryPopup.ScrollFrame:GetHeight())
    HistoryPopup.ScrollFrame:SetVerticalScroll(math.min(keepScrollPosition and previousScroll or 0, maxScroll))

    if HistoryPopup and HistoryPopup.StatusText then
        if hasMore then
            HistoryPopup.StatusText:SetText(L("LOGGING_HISTORY_SHOWING_MORE"):format(visibleCount))
        else
            HistoryPopup.StatusText:SetText(L("LOGGING_HISTORY_SHOWING"):format(visibleCount))
        end
    end

    if HistoryPopup and HistoryPopup.LoadMoreButton then
        HistoryPopup.LoadMoreButton:SetShown(hasMore)
        HistoryPopup.LoadMoreButton:SetEnabled(hasMore)
    end
end

CleanupButton:SetScript("OnClick", function()
    if CleanupPopup:IsShown() then
        CleanupPopup:Hide()
    else
        CleanupPopup:Show()
    end
end)

HistoryPopup = CreateFrame("Frame", nil, PageLogging, BackdropTemplateMixin and "BackdropTemplate")
HistoryPopup:SetSize(760, 520)
HistoryPopup:SetPoint("CENTER", PageLogging, "CENTER", 0, 10)
HistoryPopup:SetFrameStrata("DIALOG")
HistoryPopup:EnableMouse(true)
HistoryPopup:SetClampedToScreen(true)
HistoryPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
HistoryPopup:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
HistoryPopup:SetBackdropBorderColor(1, 0.82, 0, 0.95)
HistoryPopup:Hide()

HistoryPopup.Title = HistoryPopup:CreateFontString(nil, "OVERLAY")
HistoryPopup.Title:SetPoint("TOPLEFT", HistoryPopup, "TOPLEFT", 16, -14)
HistoryPopup.Title:SetPoint("RIGHT", HistoryPopup, "RIGHT", -16, 0)
HistoryPopup.Title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
HistoryPopup.Title:SetTextColor(1, 0.88, 0.62, 1)

HistoryPopup.Hint = HistoryPopup:CreateFontString(nil, "OVERLAY")
HistoryPopup.Hint:SetPoint("TOPLEFT", HistoryPopup.Title, "BOTTOMLEFT", 0, -10)
HistoryPopup.Hint:SetPoint("RIGHT", HistoryPopup, "RIGHT", -16, 0)
HistoryPopup.Hint:SetJustifyH("LEFT")
HistoryPopup.Hint:SetJustifyV("TOP")
HistoryPopup.Hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
HistoryPopup.Hint:SetTextColor(0.85, 0.85, 0.85, 1)

HistoryPopup.TabRow = CreateFrame("Frame", nil, HistoryPopup)
HistoryPopup.TabRow:SetPoint("TOPLEFT", HistoryPopup.Hint, "BOTTOMLEFT", 0, -12)
HistoryPopup.TabRow:SetPoint("RIGHT", HistoryPopup, "RIGHT", -16, 0)
HistoryPopup.TabRow:SetHeight(24)

do
    for index = 1, #HISTORY_TAB_KEYS do
        local tabButton = CreateFrame("Button", nil, HistoryPopup.TabRow, "UIPanelButtonTemplate")
        tabButton:SetSize(104, 22)
        if index > 1 then
            tabButton:SetPoint("LEFT", HistoryTabButtons[HISTORY_TAB_KEYS[index - 1]], "RIGHT", 6, 0)
        else
            tabButton:SetPoint("LEFT", HistoryPopup.TabRow, "LEFT", 0, 0)
        end
        tabButton.tabKey = HISTORY_TAB_KEYS[index]
        tabButton:SetScript("OnClick", function(self)
            HistoryActiveTabKey = self.tabKey
            ResetHistoryLoadedCount(self.tabKey)
            RefreshHistoryPopup()
        end)
        HistoryTabButtons[tabButton.tabKey] = tabButton
    end
end

HistoryPopup.SearchBox = CreateFrame("EditBox", nil, HistoryPopup, "InputBoxTemplate")
HistoryPopup.SearchBox:SetSize(208, 24)
HistoryPopup.SearchBox:SetPoint("TOPRIGHT", HistoryPopup.TabRow, "BOTTOMRIGHT", -16, -12)
HistoryPopup.SearchBox:SetAutoFocus(false)
HistoryPopup.SearchBox:SetMaxLetters(64)
HistoryPopup.SearchBox:SetScript("OnTextChanged", function(_, userInput)
    if userInput then
        ResetHistoryLoadedCount(HistoryActiveTabKey)
    end
    RefreshHistoryPopup()
end)
HistoryPopup.SearchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

HistoryPopup.SearchBox.Label = HistoryPopup:CreateFontString(nil, "OVERLAY")
HistoryPopup.SearchBox.Label:SetPoint("BOTTOMLEFT", HistoryPopup.SearchBox, "TOPLEFT", 4, 6)
HistoryPopup.SearchBox.Label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
HistoryPopup.SearchBox.Label:SetTextColor(1, 0.88, 0.62, 1)

HistoryPopup.CloseButton = CreateFrame("Button", nil, HistoryPopup, "UIPanelButtonTemplate")
HistoryPopup.CloseButton:SetSize(96, 24)
HistoryPopup.CloseButton:SetPoint("BOTTOMRIGHT", HistoryPopup, "BOTTOMRIGHT", -16, 16)
HistoryPopup.CloseButton:SetScript("OnClick", CloseHistoryPopup)

HistoryPopup.LoadMoreButton = CreateFrame("Button", nil, HistoryPopup, "UIPanelButtonTemplate")
HistoryPopup.LoadMoreButton:SetSize(108, 24)
HistoryPopup.LoadMoreButton:SetPoint("BOTTOMLEFT", HistoryPopup, "BOTTOMLEFT", 16, 16)
HistoryPopup.LoadMoreButton:SetScript("OnClick", function()
    local tabKey = HistoryActiveTabKey or "income"
    HistoryLoadedCountByTab[tabKey] = (HistoryLoadedCountByTab[tabKey] or HISTORY_PAGE_SIZE) + HISTORY_PAGE_SIZE
    RefreshHistoryPopup(true)
end)

HistoryPopup.StatusText = HistoryPopup:CreateFontString(nil, "OVERLAY")
HistoryPopup.StatusText:SetPoint("LEFT", HistoryPopup.LoadMoreButton, "RIGHT", 12, 0)
HistoryPopup.StatusText:SetPoint("RIGHT", HistoryPopup.CloseButton, "LEFT", -12, 0)
HistoryPopup.StatusText:SetJustifyH("LEFT")
HistoryPopup.StatusText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
HistoryPopup.StatusText:SetTextColor(0.82, 0.82, 0.84, 1)

HistoryPopup.ScrollFrame = CreateFrame("ScrollFrame", nil, HistoryPopup, "UIPanelScrollFrameTemplate")
HistoryPopup.ScrollFrame:SetPoint("TOPLEFT", HistoryPopup.TabRow, "BOTTOMLEFT", 0, -42)
HistoryPopup.ScrollFrame:SetPoint("BOTTOMRIGHT", HistoryPopup.CloseButton, "TOPRIGHT", -28, 14)

HistoryPopup.Content = CreateFrame("Frame", nil, HistoryPopup.ScrollFrame)
HistoryPopup.Content:SetWidth(HISTORY_CONTENT_WIDTH)
HistoryPopup.Content:SetHeight(1)
HistoryPopup.Rows = {}

HistoryPopup.EmptyText = HistoryPopup.Content:CreateFontString(nil, "OVERLAY")
HistoryPopup.EmptyText:SetJustifyH("LEFT")
HistoryPopup.EmptyText:SetJustifyV("TOP")
HistoryPopup.EmptyText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
HistoryPopup.EmptyText:SetTextColor(0.78, 0.78, 0.80, 1)
HistoryPopup.EmptyText:Hide()

HistoryPopup.ScrollFrame:SetScrollChild(HistoryPopup.Content)

HistoryButton = CreateFrame("Button", nil, IntroPanel, "UIPanelButtonTemplate")
HistoryButton:SetSize(96, 22)
HistoryButton:SetPoint("RIGHT", CleanupButton, "LEFT", -8, 0)
HistoryButton:SetScript("OnClick", function()
    if HistoryPopup:IsShown() then
        HistoryPopup:Hide()
    else
        ResetHistoryLoadedCount()
        RefreshHistoryPopup()
        HistoryPopup:Show()
    end
end)

RetentionHint:ClearAllPoints()
RetentionHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
RetentionHint:SetPoint("RIGHT", IntroPanel.OverviewSearchBox, "LEFT", -14, 0)

local function ApplyLoggingIntroLayout()
    local showExtendedIntro = not isQuickViewMode

    IntroTitle:SetShown(showExtendedIntro)
    IntroText:SetShown(showExtendedIntro)
    CleanupButton:SetShown(showExtendedIntro)
    HistoryButton:SetShown(showExtendedIntro)
    RetentionHint:SetShown(showExtendedIntro)
    LoggingMinimapContextCheckbox:SetShown(showExtendedIntro)
    LoggingMinimapContextLabel:SetShown(showExtendedIntro)

    IntroPanel:SetHeight(showExtendedIntro and LOGGING_INTRO_PANEL_HEIGHT or 78)

    IntroPanel.OverviewSearchBox:ClearAllPoints()
    if showExtendedIntro then
        IntroPanel.OverviewSearchBox:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", -16, 42)
    else
        IntroPanel.OverviewSearchBox:SetPoint("TOPRIGHT", IntroPanel, "TOPRIGHT", -16, -34)
    end

    IntroPanel.OverviewSearchBox.Label:ClearAllPoints()
    IntroPanel.OverviewSearchBox.Label:SetPoint("BOTTOMLEFT", IntroPanel.OverviewSearchBox, "TOPLEFT", 4, 6)
end

IncomePanel = CreateLogPanel(
    PageLoggingContent,
    IntroPanel,
    L("LOGGING_INCOME_TITLE"),
    L("LOGGING_INCOME_HINT")
)

ExpensePanel = CreateLogPanel(
    PageLoggingContent,
    IncomePanel,
    L("LOGGING_EXPENSE_TITLE"),
    L("LOGGING_EXPENSE_HINT")
)

RepairPanel = CreateLogPanel(
    PageLoggingContent,
    ExpensePanel,
    L("LOGGING_REPAIRS_TITLE"),
    L("LOGGING_REPAIRS_HINT")
)

CurrencyPanel = CreateLogPanel(
    PageLoggingContent,
    RepairPanel,
    L("LOGGING_CURRENCY_TITLE"),
    L("LOGGING_CURRENCY_HINT")
)

IncomePanel:ClearAllPoints()
IncomePanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -12)
IncomePanel:SetPoint("RIGHT", PageLoggingContent, "CENTER", -9, 0)

ExpensePanel:ClearAllPoints()
ExpensePanel:SetPoint("TOPLEFT", IncomePanel, "TOPRIGHT", 18, 0)
ExpensePanel:SetPoint("RIGHT", PageLoggingContent, "RIGHT", -20, 0)

RepairPanel:ClearAllPoints()
RepairPanel:SetPoint("TOPLEFT", IncomePanel, "BOTTOMLEFT", 0, -12)
RepairPanel:SetPoint("TOPRIGHT", IncomePanel, "BOTTOMRIGHT", 0, -12)

CurrencyPanel:ClearAllPoints()
CurrencyPanel:SetPoint("TOPLEFT", ExpensePanel, "BOTTOMLEFT", 0, -12)
CurrencyPanel:SetPoint("TOPRIGHT", ExpensePanel, "BOTTOMRIGHT", 0, -12)

function PageLogging:RefreshState()
    -- Baut die komplette Logging-Seite aus den gespeicherten Daten neu auf.
    local repairLog = Logging.GetRepairLog()
    local incomeLog = Logging.GetIncomeLog()
    local expenseLog = Logging.GetExpenseLog()
    local currencyLog = Logging.GetCurrencyLog()
    local repairDays = BuildDailyRepairTotals()
    local currencyTotals = BuildCurrencyTotals(currencyLog)
    local overviewSearchText = GetOverviewSearchText()
    local visibleIncomeEntries = CollectOverviewEntries(incomeLog, overviewSearchText, BuildMoneyEntrySearchText)
    local visibleExpenseEntries = CollectOverviewEntries(expenseLog, overviewSearchText, BuildMoneyEntrySearchText)
    local visibleRepairDays = CollectOverviewRepairDays(repairDays, overviewSearchText)
    local visibleCurrencyEntries = CollectOverviewEntries(currencyLog, overviewSearchText, BuildCurrencyEntrySearchText)

    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("Logging", L("GOLDAUSWERTUNG")))
    IntroText:SetText(L("LOGGING_DESC"))
    CleanupButton:SetText(L("LOGGING_CLEANUP"))
    HistoryButton:SetText(L("LOGGING_HISTORY"))
    RetentionHint:SetText(L("LOGGING_RETENTION_HINT"))
    if IntroPanel and IntroPanel.OverviewSearchBox and IntroPanel.OverviewSearchBox.Label then
        IntroPanel.OverviewSearchBox.Label:SetText(L("LOGGING_HISTORY_SEARCH"))
    end
    LoggingMinimapContextLabel:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    LoggingMinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("logging") or true)
    CleanupPopupTitle:SetText(L("LOGGING_CLEANUP_TITLE"))
    CleanupPopupHint:SetText(L("LOGGING_CLEANUP_HINT"))
    CleanupSevenDaysButton:SetText(L("DAYS_7"))
    CleanupThirtyDaysButton:SetText(L("DAYS_30"))
    CleanupNinetyDaysButton:SetText(L("DAYS_90"))
    CleanupOneYearButton:SetText(L("DAYS_365"))
    CleanupAllButton:SetText(L("ALL"))
    CleanupCancelButton:SetText(L("CANCEL"))
    IncomePanel.Title:SetText(L("LOGGING_INCOME_TITLE"))
    IncomePanel.Hint:SetText(L("LOGGING_INCOME_HINT"))
    IncomePanel.EmptyText:SetText(L("NO_ENTRIES"))
    ExpensePanel.Title:SetText(L("LOGGING_EXPENSE_TITLE"))
    ExpensePanel.Hint:SetText(L("LOGGING_EXPENSE_HINT"))
    ExpensePanel.EmptyText:SetText(L("NO_ENTRIES"))
    RepairPanel.Title:SetText(L("LOGGING_REPAIRS_TITLE"))
    RepairPanel.Hint:SetText(L("LOGGING_REPAIRS_HINT"))
    RepairPanel.EmptyText:SetText(L("NO_ENTRIES"))
    CurrencyPanel.Title:SetText(L("LOGGING_CURRENCY_TITLE"))
    CurrencyPanel.Hint:SetText(L("LOGGING_CURRENCY_HINT"))
    CurrencyPanel.EmptyText:SetText(L("NO_ENTRIES"))

    ResetPanelEntries(IncomePanel)
    ResetPanelEntries(ExpensePanel)
    ResetPanelEntries(RepairPanel)
    ResetPanelEntries(CurrencyPanel)

    do
        local currentY = LOGGING_PANEL_ROW_START_Y
        local rowIndex = 0

        for _, match in ipairs(visibleIncomeEntries) do
            local entry = match.entry
            local rowKey = BuildMoneyEntryKey("income", entry, match.index)
            local detailItems = type(entry.items) == "table" and #entry.items > 0 and entry.items or nil
            local detailsText = nil
            if detailItems == nil then
                detailsText = BuildMoneyEntryExpandedText(entry)
            end
            local isExpandable = detailItems ~= nil or (type(detailsText) == "string" and detailsText ~= "")
            local isExpanded = isExpandable and LoggingState.expandedIncomeEntries[rowKey] == true

            rowIndex = rowIndex + 1

            currentY = LayoutLogRow(
                IncomePanel,
                rowIndex,
                currentY,
                string.format("%s | %s", FormatOverviewTimestamp(entry.timestamp), BuildMoneyEntryPrimaryText(entry)),
                FormatCoins(entry.amount),
                {
                    expandable = isExpandable,
                    expanded = isExpanded,
                    detailsText = detailsText,
                    detailItems = detailItems,
                    onClick = function()
                        LoggingState.expandedIncomeEntries[rowKey] = not LoggingState.expandedIncomeEntries[rowKey]
                        PageLogging:RefreshState()
                    end,
                }
            )
        end

        if rowIndex == 0 then
            ShowPanelEmptyText(IncomePanel, overviewSearchText)
            currentY = currentY - 26
        end

        IncomePanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = LOGGING_PANEL_ROW_START_Y
        local rowIndex = 0

        for _, match in ipairs(visibleExpenseEntries) do
            local entry = match.entry
            local rowKey = BuildMoneyEntryKey("expense", entry, match.index)
            local detailItems = type(entry.items) == "table" and #entry.items > 0 and entry.items or nil
            local detailsText = nil
            if detailItems == nil then
                detailsText = BuildMoneyEntryExpandedText(entry)
            end
            local isExpandable = detailItems ~= nil or (type(detailsText) == "string" and detailsText ~= "")
            local isExpanded = isExpandable and LoggingState.expandedExpenseEntries[rowKey] == true

            rowIndex = rowIndex + 1

            currentY = LayoutLogRow(
                ExpensePanel,
                rowIndex,
                currentY,
                string.format("%s | %s", FormatOverviewTimestamp(entry.timestamp), BuildMoneyEntryPrimaryText(entry)),
                FormatCoins(entry.amount),
                {
                    expandable = isExpandable,
                    expanded = isExpanded,
                    detailsText = detailsText,
                    detailItems = detailItems,
                    onClick = function()
                        LoggingState.expandedExpenseEntries[rowKey] = not LoggingState.expandedExpenseEntries[rowKey]
                        PageLogging:RefreshState()
                    end,
                }
            )
        end

        if rowIndex == 0 then
            ShowPanelEmptyText(ExpensePanel, overviewSearchText)
            currentY = currentY - 26
        end

        ExpensePanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = LOGGING_PANEL_ROW_START_Y
        local rowIndex = 0

        if #visibleRepairDays == 0 then
            ShowPanelEmptyText(RepairPanel, overviewSearchText)
            currentY = currentY - 26
        else
            for _, match in ipairs(visibleRepairDays) do
                local dayEntry = match.entry
                local rowKey = BuildRepairDayKey(dayEntry)
                local detailsText = BuildRepairDayExpandedText(dayEntry)
                local isExpandable = type(detailsText) == "string" and detailsText ~= ""
                local isExpanded = isExpandable and LoggingState.expandedRepairDays[rowKey] == true

                rowIndex = rowIndex + 1
                currentY = LayoutLogRow(
                    RepairPanel,
                    rowIndex,
                    currentY,
                    BuildRepairDaySummary(dayEntry),
                    FormatCoins(dayEntry.total),
                    {
                        expandable = isExpandable,
                        expanded = isExpanded,
                        detailsText = detailsText,
                        onClick = function()
                            LoggingState.expandedRepairDays[rowKey] = not LoggingState.expandedRepairDays[rowKey]
                            PageLogging:RefreshState()
                        end,
                    }
                )
            end
        end

        RepairPanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = LOGGING_PANEL_ROW_START_Y
        local rowIndex = 0

        for _, match in ipairs(visibleCurrencyEntries) do
            local entry = match.entry
            local primaryText = BuildCurrencyEntryPrimaryText(entry)
            local detailsText = BuildCurrencyEntryExpandedText(entry)
            local rowKey = BuildCurrencyEntryKey(entry, match.index)
            local isExpandable = type(detailsText) == "string" and detailsText ~= ""
            local isExpanded = isExpandable and LoggingState.expandedCurrencyEntries[rowKey] == true

            rowIndex = rowIndex + 1
            currentY = LayoutLogRow(
                CurrencyPanel,
                rowIndex,
                currentY,
                string.format("%s | %s", FormatOverviewTimestamp(entry.timestamp), primaryText),
                string.format("%s%d", entry.direction == "expense" and "-" or "+", entry.amount or 0),
                {
                    expandable = isExpandable,
                    expanded = isExpanded,
                    detailsText = detailsText,
                    onClick = function()
                        LoggingState.expandedCurrencyEntries[rowKey] = not LoggingState.expandedCurrencyEntries[rowKey]
                        PageLogging:RefreshState()
                    end,
                }
            )
        end

        if rowIndex == 0 then
            ShowPanelEmptyText(CurrencyPanel, overviewSearchText)
            currentY = currentY - 26
        end

        CurrencyPanel:SetHeight((-currentY) + 18)
    end

    if HistoryPopup and HistoryPopup:IsShown() then
        RefreshHistoryPopup(true)
    end

    ApplyLoggingIntroLayout()
    self:UpdateScrollLayout()
end

function PageLogging:UpdateScrollLayout()
    -- Die Scrollhoehe richtet sich nach den echten Hoehen der vier Bereiche.
    local contentWidth = math.max(1, PageLoggingScrollFrame:GetWidth())
    local firstRowHeight = math.max(IncomePanel:GetHeight(), ExpensePanel:GetHeight())
    local secondRowHeight = math.max(RepairPanel:GetHeight(), CurrencyPanel:GetHeight())
    local contentHeight = 16
        + IntroPanel:GetHeight()
        + LOGGING_PANEL_GAP + firstRowHeight
        + LOGGING_PANEL_GAP + secondRowHeight
        + 16

    PageLoggingContent:SetWidth(contentWidth)
    PageLoggingContent:SetHeight(contentHeight)

    local maxScroll = math.max(0, PageLoggingContent:GetHeight() - PageLoggingScrollFrame:GetHeight())
    if PageLoggingScrollFrame:GetVerticalScroll() > maxScroll then
        PageLoggingScrollFrame:SetVerticalScroll(maxScroll)
    end
end

PageLoggingScrollFrame:SetScript("OnSizeChanged", function()
    PageLogging:RefreshState()
end)

PageLoggingScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageLoggingContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

function PageLogging:SetQuickViewMode(enabled)
    isQuickViewMode = enabled == true
    if isQuickViewMode then
        CloseCleanupPopup()
        CloseHistoryPopup()
    end
    ApplyLoggingIntroLayout()
    self:RefreshState()
end

PageLogging:SetScript("OnShow", function()
    ApplyLoggingIntroLayout()
    PageLogging:RefreshState()
    PageLoggingScrollFrame:SetVerticalScroll(0)
end)

PageLogging:HookScript("OnHide", function()
    CloseCleanupPopup()
    CloseHistoryPopup()
end)

ApplyLoggingIntroLayout()
PageLogging:RefreshState()

BeavisQoL.Pages.Logging = PageLogging

